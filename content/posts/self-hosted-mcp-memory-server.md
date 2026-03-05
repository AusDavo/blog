---
title: Building a Self-Hosted Memory Layer for Claude Code
date: 2026-03-04T10:32:00+10:00
draft: false
tags:
  - ai
  - self-hosting
  - mcp
  - docker
---
Most AI tools have some form of memory now — Claude Code has its `CLAUDE.md` files, ChatGPT remembers things between sessions, Cursor has rules files. But these memory systems are siloed to one tool, stored as flat text, and not searchable by meaning. You can't query "what did I decide about authentication last month?" and get a useful answer. Your context doesn't travel between tools, and there's no structure beyond what you manually write.

Nate B Jones has been [talking about this problem](https://youtu.be/2JiMmye2ezg) under the banner of "Open Brain" — the idea that your AI memory should be portable, searchable, and owned by you. His [guide](https://natesnewsletter.substack.com/p/every-ai-you-use-forgets-you-heres) walks through building a semantic memory system using Supabase and OpenRouter. It's well put together and worth watching if the concept is new to you.

I liked the concept but wanted something fully self-hosted. No managed database, no third-party API gateway for the core infrastructure. Just a Docker Compose stack on my existing server, behind my existing reverse proxy, using tools I already run. So I took the ideas from Nate's guide and rebuilt it my way.

## What I Built

A Docker Compose stack with two containers:

1. **Postgres with pgvector** — stores memories as text alongside 1536-dimension vector embeddings
2. **Python MCP server** — [FastMCP](https://github.com/jlowin/fastmcp) exposing six tools and two prompts over Streamable HTTP with Bearer token auth, plus a REST webhook for external capture

The core tools:

| Tool            | What it does                                                                                     |
| --------------- | ------------------------------------------------------------------------------------------------ |
| `store_memory`  | Saves text with an auto-generated vector embedding and AI-extracted metadata, plus optional tags |
| `search_memory` | Finds memories by meaning using cosine similarity — not keyword matching                         |
| `list_recent`   | Returns the last N memories, optionally filtered by source                                       |
| `delete_memory` | Removes a memory by UUID                                                                         |
| `weekly_review` | Summarizes the last N days of memories grouped by date, type, tags, and action items             |
| `memory_stats`  | Aggregate statistics — totals, source distribution, top tags, daily activity                     |

Claude Code (or any MCP client) connects over HTTPS. I store a memory by just telling Claude to remember something. Search happens semantically — I can ask "what are my deployment patterns?" and it'll surface relevant memories even if none of them contain that exact phrase.

## The Stack

```
Claude Code ──HTTPS──▶ Caddy ──proxy──▶ FastMCP server ──▶ Postgres + pgvector
                          ▲                │
Phone/browser ──HTTPS─────┘                ▼
  (capture form,              OpenAI API
   OAuth2 + Pocket ID)   (embeddings + GPT-4o-mini)
```

- **Embeddings**: OpenAI `text-embedding-3-small` at 1536 dimensions. Cheap — roughly $0.01/month at my usage. I'd like to move to a local model eventually, but this gets the job done today.
- **Transport**: Streamable HTTP (not SSE, which is deprecated in Claude Code). FastMCP serves at `/mcp` and handles the MCP protocol negotiation.
- **Auth**: A Bearer token validated at the HTTP layer via Starlette middleware. The token is generated with `openssl rand -hex 32` and passed as an HTTP header.
- **Reverse proxy**: Caddy handles TLS termination. The MCP server container joins my existing `caddy_rev-proxy` Docker network so Caddy can reach it by container name. No ports exposed to the host.

## Key Implementation Details

### HNSW Over IVFFlat

The pgvector guide most people follow suggests IVFFlat indexing. That fails on empty tables — you get an error at `CREATE INDEX` time because IVFFlat needs existing data to build its clusters. HNSW works on empty tables and is generally better for small-to-medium datasets anyway:

```sql
CREATE INDEX idx_memories_embedding
    ON memories USING hnsw (embedding vector_cosine_ops);
```

### Bearer Auth Middleware

I originally used FastMCP's built-in middleware system to validate the Bearer token on each tool call. That worked during initial testing but broke in production — FastMCP's `get_http_headers()` [doesn't reliably propagate headers](https://github.com/jlowin/fastmcp/issues/1233) into the tool execution context with the Streamable HTTP transport. Every tool call returned "Unauthorized" even though the client was sending the correct header.

The fix was moving auth down to the Starlette layer, where headers are always available:

```python
class BearerAuthMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        if request.method == "OPTIONS":
            return await call_next(request)

        auth_header = request.headers.get("authorization", "")
        if not auth_header.startswith("Bearer "):
            return JSONResponse(
                {"error": "Unauthorized"}, status_code=401
            )

        token = auth_header.removeprefix("Bearer ").strip()
        if token != os.environ["MCP_API_KEY"]:
            return JSONResponse(
                {"error": "Unauthorized"}, status_code=401
            )

        return await call_next(request)
```

This is arguably more correct anyway — auth belongs at the transport layer, not the application layer. The middleware is passed to FastMCP's `run()` method via the `middleware` parameter, so it wraps the entire ASGI app.

### Connecting Claude Code

```bash
claude mcp add memory-server \
    --transport http \
    --scope user \
    --header "Authorization: Bearer <your-token>" \
    -- https://your-domain.example.com/mcp
```

The `--scope user` flag means the server is available across all projects, not just one. After restarting Claude Code, the four memory tools appear alongside any other MCP tools you have configured.

## Docker Compose

The full `docker-compose.yml` is straightforward:

```yaml
services:
  db:
    image: pgvector/pgvector:pg17
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 5

  server:
    build: .
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_URL: ${DATABASE_URL}
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      MCP_API_KEY: ${MCP_API_KEY}
    networks:
      - default
      - caddy_rev-proxy

volumes:
  pgdata:

networks:
  caddy_rev-proxy:
    external: true
```

The database container stays on the default network only — it's not reachable from outside the stack. The server container bridges both networks so Caddy can reach it while still talking to Postgres.

## Backups

A simple bash script runs via cron at 3am daily:

```bash
docker exec mcp-memory-db pg_dump -U memory memory \
    | gzip > "$BACKUP_DIR/memory-$(date +%Y%m%d-%H%M%S).sql.gz"
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +14 -delete
```

14-day retention. At current usage, each backup compresses to under 1KB. Even with years of accumulated memories, pgvector at 1536 dimensions uses roughly 6KB per row — 10,000 memories would be about 60MB.

## Phase 2: AI Metadata and Multi-Source Capture

After using the basic system for a while, three gaps became obvious: memories had no structure beyond what I manually tagged, there was no way to capture thoughts outside of an MCP client, and there were no tools for reviewing what had accumulated.

### Automatic Metadata Extraction

Every `store_memory` call now runs GPT-4o-mini in parallel with the embedding generation to extract structured metadata:

- **Type classification** — `observation`, `task`, `idea`, `reference`, or `person_note`
- **Topic tags** — 1–3 kebab-case tags, appended to any user-supplied tags and deduplicated
- **Entity extraction** — people, places, and organizations mentioned
- **Action items** — anything actionable pulled out into a list

The extraction runs concurrently with the embedding call via `asyncio.gather`, so there's no latency increase. It's also best-effort — if the LLM call fails for any reason, the memory still gets stored with whatever tags and metadata were provided manually.

AI-generated metadata lives under `metadata.ai` in the JSONB column, so it never conflicts with user-supplied fields. The extracted `topic_tags` get merged with user tags rather than stored separately, which means they're immediately useful for tag-based filtering.

### Mobile Capture Form

I wanted to capture thoughts from my phone without needing a terminal. I initially tried building a capture service around SimpleX Chat's CLI WebSocket API, but it turned out to be unreliable — the CLI wasn't designed for programmatic message monitoring and message delivery was inconsistent.

The simpler solution: a mobile-friendly web form at `memory.dpinkerton.com/capture`. It's a static HTML page with a textarea, optional tags and source fields, and a submit button. It POSTs to a `/webhook/capture` endpoint on the memory server, which runs the same storage pipeline — embedding, metadata extraction, database insert.

Authentication is handled entirely by Caddy. The form is behind my existing OAuth2 setup (oauth2-proxy + [Pocket ID](https://github.com/pocket-id/pocket-id) as the OIDC provider), gated to a specific group. Caddy injects the Bearer token when proxying form submissions to the webhook, so the API key never leaves the server and the form's JavaScript doesn't need to know it. The MCP endpoint at `/mcp` remains separately accessible with its own Bearer token auth for Claude Code.

After storing, the form shows a confirmation with the AI-classified type and tags: `Stored (task) [meeting, acme-corp, proposal]`. Type a quick thought from your phone, see it classified and tagged in a second or two.

### Review and Stats Tools

Two new tools help make sense of accumulated memories:

- **`weekly_review`** — queries the last N days of memories, groups them by date, tallies type and tag distributions, and collects all action items. Hand this to an LLM and it can synthesize themes and surface forgotten commitments.
- **`memory_stats`** — aggregate dashboard: total memory count, source distribution, top 20 tags, and daily capture activity for the last 30 days.

### MCP Prompts

FastMCP supports [prompts](https://spec.modelcontextprotocol.io/specification/2025-03-26/server/prompts/) — reusable instruction templates that MCP clients can offer to users. I added two:

- **`memory_migration`** — tells the LLM to review the current conversation and store every meaningful piece of information as individual memories. Useful when you've had a long session and want to preserve the context.
- **`quick_capture`** — takes raw text and optional context, has the LLM determine optimal phrasing, source, tags, and metadata, then stores it. A more refined version of just calling `store_memory` directly.

## What's Next

- **Local embeddings** — replacing the OpenAI dependency with something like `sentence-transformers` running in the container. Removes the external API call and the (tiny) cost.
- **Memory consolidation** — a tool that identifies near-duplicate or related memories and suggests merging them.

## Credit

The concept and motivation came directly from [Nate B Jones](https://www.youtube.com/@NateBJones) and his [Open Brain guide](https://natesnewsletter.substack.com/p/every-ai-you-use-forgets-you-heres). His approach uses Supabase and OpenRouter — managed services that are faster to set up and probably the right choice for most people. I just happen to already run the infrastructure that makes self-hosting straightforward.

The [source code](https://github.com/AusDavo/mcp-memory-server) is on GitHub if you want to adapt it for your own setup.