---
title: "Talk Into Your Phone, Get a Blog Post: Building a Voice-to-Post Pipeline"
date: 2026-03-08T14:30:00+10:00
draft: false
tags:
  - ai
  - n8n
  - self-hosting
  - automation
  - hugo
summary: A self-hosted pipeline that turns Telegram voice messages into draft blog posts — Whisper for transcription, Claude for writing, GitHub for commits, all wired together in n8n.
---
A mate of mine, Aaron, runs a personal training business in Brisbane. He's been at it for over twenty years, knows his craft inside out, and has a lot worth sharing — training philosophy, rehab approaches, programming for older clients, the kind of hard-won knowledge that doesn't make it into certification courses. He's also building his personal brand and thinking about product offerings down the track: branded gear, training plans, that sort of thing. Blogging would help with all of it.

The problem is he doesn't like sitting at a computer, and his days are packed with clients. He's not going to open a text editor and write a thousand words on progressive overload. But put him in a conversation about training and he'll talk your ear off — articulately, with structure, with real insight. The content is there. It just needs a different way in.

We were having lunch together and the conversation kept landing on topics I thought would make great posts. That's when the idea clicked: what if he could just talk into his phone on the drive home and have a blog post waiting by the time he parked?

So I built it.

## How It Works

The pipeline runs on [n8n](https://n8n.io/), self-hosted on the same server that hosts Aaron's site. Six steps, fully automated:

```
Voice message → Telegram Bot API → Whisper → Claude → GitHub → Telegram reply
```

1. **Telegram trigger** — A voice message sent to a Telegram bot fires the workflow. n8n listens via webhook.
2. **Download audio** — The workflow fetches the voice file from Telegram's API using the `file_id`.
3. **Whisper transcription** — The audio goes to OpenAI's `whisper-1` model. Telegram voice messages are OGG/Opus, which Whisper handles natively.
4. **Claude blog post** — The transcript is sent to `claude-sonnet-4-20250514` with a system prompt that instructs it to turn raw spoken thoughts into a structured post — introduction, headings, conclusion, reference links, and Hugo-compatible front matter with `draft: true`.
5. **GitHub commit** — The markdown file is committed to `content/posts/` via the GitHub Contents API. Commit message: `draft: add {{title}} via voice post`.
6. **Telegram reply** — A confirmation message comes back with a direct link to the new file on GitHub.

If any step fails, a separate error-handler workflow catches it and sends a Telegram message naming the failed node and the error detail.

## The System Prompt Does the Heavy Lifting

The interesting part isn't really the plumbing — it's the system prompt. That's where you define what kind of writer Claude is, and it's where the quality of the output lives or dies.

The prompt instructs Claude to:

- Write an introduction and conclusion
- Organise content under clear headings
- Expand on spoken points naturally (spoken thoughts are compressed — you skip context that's obvious to you but not to a reader)
- Weave in 3–5 relevant reference links as markdown hyperlinks
- Return a JSON object with `title`, `filename` (slugified), and `content` (full Hugo markdown with front matter)

This is the most tuneable part of the whole system. Want shorter posts? Say so. Want a specific tone — say, motivational and direct, suited to a fitness audience? Describe it. Want every post to end with a call to action linking to a shop? Add it to the prompt. The pipeline doesn't change — just the instructions.

For Aaron's use case, the prompt will be dialled in for fitness content: practical training advice, product context where relevant, and a voice that sounds like a coach talking to a client, not a copywriter filling a content calendar.

## Why n8n

I could have built this as a script. A bash pipeline that chains `curl` calls would technically work. But n8n gives me a few things that matter:

- **Visual debugging** — when the GitHub commit step failed because the JSON body had unescaped newlines, I could see exactly which node failed and inspect its input/output. That's harder to do in a script.
- **Error handling** — the error workflow is a separate n8n workflow that fires on any failure. It extracts the chat ID from the failed execution data and sends a Telegram message. Setting that up in a script means writing your own try/catch and notification logic.
- **Credential management** — API keys for Telegram, OpenAI, Anthropic, and GitHub are stored as n8n credentials, not hardcoded in a script.
- **It was already running** — I use n8n for other automations. Adding a workflow is easier than maintaining another standalone service.

I also enjoy building these workflows. There's something satisfying about wiring together APIs that were never designed to talk to each other and watching data flow through them. The AI integration — having Claude sit in the middle of a pipeline and do the creative work — is a genuinely new capability that makes automations like this possible where they weren't a couple of years ago.

## Testing on My Own Blog First

Before setting it up for Aaron, I did a quick test on my own site. I rambled into Telegram about a trip to a local nursery — maybe two minutes of unstructured thoughts, the kind of thing you'd say to a friend in the car. Claude turned it into a 900-word post with five sections, an introduction that set the scene, a conclusion that tied it together, and a handful of links to the places mentioned. It committed as a draft, so I could review before publishing.

The front matter it generates looks like this:

```yaml
---
title: "A Rainy Day Adventure to Brookfield Traders"
date: 2026-03-08T10:00:00+10:00
draft: true
tags:
  - brookfield
  - chickens
  - gardening
summary: "A rainy day trip turns into a treasure hunt..."
---
```

Drafts don't appear on the live site until you flip `draft: false` and push. So there's always a review step — the pipeline doesn't publish anything that hasn't been looked at.

## Setting Up Aaron's Blog

His website was a single static HTML page — no blog at all. In one session I:

- Scaffolded a Hugo site with PaperMod at [blog.acpt.com.au](https://blog.acpt.com.au)
- Created a GitHub repo, webhook, and auto-deploy container on my server
- Added a Caddy site block with automatic TLS
- Linked the blog from his main site's navigation

The voice pipeline is a clone of mine with a different system prompt, a different GitHub repo, and his own Telegram bot. The infrastructure is identical. The personality lives in the prompt.

## What's Next

**Social distribution.** Once the blog pipeline is proven and Aaron's using it, the natural next step is automating social posts. LinkedIn and Facebook are straightforward API integrations. Instagram needs an image for each post — a branded card with the title — which adds a generation step but is doable. Each platform would be a separate branch in the workflow so failures are independent.

**Local transcription.** I'm currently sending audio to OpenAI's Whisper API. It works, but Whisper runs fine locally and I have the compute for it. Swapping to a self-hosted instance removes the external dependency.

**Editing loop.** Right now it's one-shot: record, commit, done. It would be useful to have a follow-up interaction — "make the intro shorter" or "add a section about X" — that amends the draft in place. That's a future iteration.

**Structured output.** Claude occasionally wraps its JSON response in a markdown code fence. The Code node handles this with a regex fallback, but using Claude's tool use or structured output mode would guarantee the response shape.

## The Stack

| Component | Service |
|-----------|---------|
| Workflow engine | n8n (self-hosted) |
| Transcription | OpenAI Whisper (`whisper-1`) |
| Writing | Claude Sonnet (`claude-sonnet-4-20250514`) |
| Version control | GitHub Contents API |
| Static site | Hugo + PaperMod |
| Hosting | Caddy + Docker on home server |
| Trigger & notifications | Telegram Bot API |

Everything self-hosted except the AI APIs. Total cost per post is a few cents — a Whisper transcription plus a Claude generation. The real cost is the lunch where you get the idea.
