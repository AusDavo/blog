---
title: "MCP Memory Server: One Month In"
date: 2026-03-31T23:50:00+11:00
draft: false
tags:
  - ai
  - self-hosting
  - mcp
  - docker
---
A month ago I wrote about [building a self-hosted memory layer](/posts/self-hosted-mcp-memory-server/) for Claude Code. The system has been running continuously since then — 194 memories stored, mostly from Claude Code sessions across a dozen projects. This post covers what I learned from actual usage and the changes I made as a result.

## What Changed After Real Use

The original system worked. Search found relevant memories, AI metadata extraction added useful structure, and the mobile capture form let me save thoughts from my phone. But a month of daily use exposed friction points that weren't obvious during initial development.

I spent a week working on systems that didn't have the memory server connected and genuinely felt hamstrung. Context I'd built up over weeks — deployment paths, infrastructure decisions, people and their roles — wasn't available. I kept having to re-explain things that the memory server would have surfaced automatically. That confirmed the system was pulling its weight; it also motivated me to go back and improve it.

### Tag Inconsistency

The `memory_stats` dashboard showed both `mhub` (75 memories) and `mHub` (11 memories) as separate tags. Same project, different casing, depending on whether I or the AI typed the tag. Multiply that across dozens of tags and the filtering becomes unreliable.

The fix was trivial — lowercase and strip all tags on ingestion:

```python
tags = [t.lower().strip() for t in (tags or [])]
```

Applied to both user-supplied tags and AI-extracted tags. A one-time migration normalized the existing 194 rows:

```sql
UPDATE memories SET tags = (
    SELECT array_agg(DISTINCT lower(trim(t))) FROM unnest(tags) AS t
) WHERE tags != '{}';
```

After migration, `mhub` consolidated to 79 entries. Small change, meaningful improvement in tag-based filtering.

### Near-Duplicate Memories

When Claude Code stores memories across multiple sessions about the same topic, the content often overlaps significantly. I'd find three memories about the same deployment path with slightly different phrasing. Not a crisis with 194 memories, but it would become one at 1,000.

Now `store_memory` checks the nearest existing memory by cosine similarity before inserting. If the similarity exceeds a configurable threshold (default 0.95), it returns a `duplicate_detected` response with the existing memory's ID instead of creating a new entry:

```python
existing = await db.fetchrow(
    """
    SELECT id, content, created_at,
           1 - (embedding <=> $1::vector) AS similarity
    FROM memories
    ORDER BY embedding <=> $1::vector
    LIMIT 1
    """,
    str(embedding),
)
if existing and float(existing["similarity"]) >= DUPLICATE_THRESHOLD:
    return {
        "status": "duplicate_detected",
        "existing_id": str(existing["id"]),
        "similarity": round(float(existing["similarity"]), 4),
    }
```

The threshold of 0.95 is deliberately aggressive — it catches near-identical content without flagging merely related memories. A `force` parameter bypasses the check when you explicitly want to store regardless.

### Search Was Missing Exact Matches

The original search was pure vector similarity. Semantic search is powerful — querying "deployment patterns" surfaces memories about Docker Compose configurations even if they never use the word "pattern." But it also means searching for "Caddy restart" might not prioritize the one memory that literally contains that phrase.

The database already had a full-text search index that wasn't being used:

```sql
CREATE INDEX idx_memories_content_fts
    ON memories USING GIN (to_tsvector('english', content));
```

I added a hybrid scoring approach: fetch 3x the requested candidates by vector similarity, then re-rank using a weighted combination of vector score and full-text search score:

```sql
WITH candidates AS (
    SELECT id, content, source, tags, metadata, created_at,
           1 - (embedding <=> $1::vector) AS vector_score,
           ts_rank_cd(
               to_tsvector('english', content),
               plainto_tsquery('english', $3)
           ) AS fts_score
    FROM memories
    ORDER BY embedding <=> $1::vector
    LIMIT $2 * 3
)
SELECT *,
       vector_score * 0.7 + fts_score * 0.3 AS combined_score
FROM candidates
ORDER BY combined_score DESC
LIMIT $2
```

Vector similarity remains the primary signal (70% weight) with FTS as a boost (30%). The HNSW index drives the initial candidate selection, keeping it fast. Results now include both scores, so you can see exactly what's driving the ranking.

## New Capabilities

### Editing Memories

Previously, correcting a memory meant deleting it and re-creating it. Now there's an `update_memory` tool that handles partial updates intelligently:

- **Content changes** trigger re-embedding and fresh metadata extraction in parallel, just like initial storage
- **Tag updates** replace the existing set (normalized to lowercase)
- **Metadata updates** shallow-merge with existing fields, so you can add a key without losing the AI-extracted metadata

The `updated_at` column was already in the schema from day one but never used. Now it is.

### Multi-Key Authentication

The original server had a single Bearer token shared across all clients. After connecting an external service (an automation tool that captures memories from other sources), I needed per-client source attribution without trusting clients to set their own `source` field.

The solution: scoped API keys via environment variables. `MCP_API_KEY` remains the primary key with no source override. Additional keys follow the pattern `MCP_API_KEY_<NAME>`, where `<NAME>` becomes the forced source:

```python
TOKEN_SOURCE_MAP: dict[str, str | None] = {}

_primary_key = os.environ.get("MCP_API_KEY", "")
if _primary_key:
    TOKEN_SOURCE_MAP[_primary_key] = None

for key, value in os.environ.items():
    if key.startswith("MCP_API_KEY_") and value:
        source_name = key.removeprefix("MCP_API_KEY_").lower()
        TOKEN_SOURCE_MAP[value] = source_name
```

A `contextvars.ContextVar` carries the source override from the middleware into the storage function, so the forced source is applied regardless of what the client sends. Adding a new client is just adding an environment variable and restarting.

### Configurable Embedding Provider

The embedding generation was hardcoded to OpenAI's API. Now it's configurable via environment variables:

```
EMBEDDING_API_KEY    # defaults to OPENAI_API_KEY
EMBEDDING_API_URL    # defaults to https://api.openai.com/v1/embeddings
EMBEDDING_MODEL      # defaults to text-embedding-3-small
```

Any provider that implements the OpenAI-compatible embeddings API works — Ollama, vLLM, LiteLLM, Azure OpenAI, Mistral. The metadata extraction (GPT-4o-mini) still uses OpenAI directly, but the embedding path is now decoupled. This is the first step toward the local embeddings goal from the original post.

One important caveat: changing embedding providers or dimensions invalidates all existing vectors. There's no way around this — the new embeddings live in a different vector space. Switching requires re-embedding everything.

## Performance Improvement

A small but worthwhile change: the original code created a new `httpx.AsyncClient` for every OpenAI API call. Since `store_memory` calls both the embeddings API and GPT-4o-mini in parallel, that was two new TCP connections and TLS handshakes per memory stored.

Now a single shared client handles all outbound HTTP, with connection pooling and keepalive:

```python
_http_client: httpx.AsyncClient | None = None

def get_http_client() -> httpx.AsyncClient:
    global _http_client
    if _http_client is None:
        _http_client = httpx.AsyncClient(
            headers={"Content-Type": "application/json"},
            timeout=30.0,
        )
    return _http_client
```

Same lazy-init pattern as the database pool. Authorization headers are passed per-request rather than baked into the client, which keeps it usable across different API keys (embedding provider vs OpenAI for metadata).

## By the Numbers

After one month:

- **194 memories** stored
- **93% from Claude Code** (180), the rest from manual entry (8), mobile capture (2), and external services (2)
- **Top tags**: `mhub` (79), `certainkey` (46), `deployment` (28), `infrastructure` (27), `bitcoin` (21)
- **Busiest day**: 53 memories on March 4 (initial setup and bulk migration)
- **Steady state**: 5–12 memories per day during active development
- **Storage cost**: still under $0.02/month for OpenAI API calls

The tag distribution mirrors where I've been spending time. The source distribution confirms that Claude Code is doing the heavy lifting — which makes sense, since the CLAUDE.md instructions tell it to store memories proactively.

## What's Next

The original post listed local embeddings and memory consolidation as future goals. Local embeddings are now unblocked — the configurable provider means I can point at an Ollama instance whenever I'm ready to commit to a re-embedding migration.

Memory consolidation (identifying and merging near-duplicates) is partially addressed by the duplicate detection, but a proper consolidation tool that finds related-but-different memories and suggests merges would be valuable as the corpus grows.

The [source code](https://github.com/AusDavo/mcp-memory-server) remains on GitHub.
