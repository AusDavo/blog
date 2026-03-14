---
title: "Building an AI Agent on White Noise with marmot-cli"
date: 2026-03-15
description: "How I connected an AI familiar to White Noise's end-to-end encrypted messaging using marmot-cli, Claude API, and a Python handler — and why I moved away from Telegram."
draft: false
tags:
  - nostr
  - whitenoise
  - mls
  - ai
---

I run an AI familiar called Klaw — spirit of a rooster, built on a friend's VPS, and until recently only reachable via Telegram. Telegram works. It's user-friendly. But I've never been fully comfortable with it. Telegram messages aren't end-to-end encrypted by default. Group chats are never encrypted. Metadata is visible to Telegram's servers. For an AI agent that I want to trust with personal context and semantic memory, that's not ideal.

I've [written before](/posts/simplex-chat-contribution/) about privacy-focused messaging and why protocols like SimpleX deserve more attention beyond person-to-person chat. SimpleX is working on bot support — there's a [Node.js client library](https://github.com/simplex-chat/simplex-chat/tree/stable/packages/simplex-chat-client/typescript) in the v6.5 beta that talks to the CLI over WebSocket. But it still requires running the full SimpleX CLI as a WebSocket server, and my [PR](https://github.com/simplex-chat/simplex-chat/pull/6609) to make that server bindable to more than localhost (essential for containerised deployments) has sat without review for six weeks. The bot story is coming along, but it's not quite there yet — and I didn't want to maintain a patched fork while waiting.

[White Noise](https://www.whitenoise.chat/) is the alternative I wanted. It's an encrypted messaging app built on MLS (Messaging Layer Security) over Nostr. Every message is end-to-end encrypted. There are no central servers — just Nostr relays as dumb transport. No phone number required. No metadata leakage. And because it uses the [Marmot protocol](https://github.com/marmot-protocol/marmot), any client that speaks MLS-over-Nostr can interoperate with the app.

So I built a bridge.

## What It Does

Klaw now listens for White Noise messages using [marmot-cli](https://github.com/kai-familiar/marmot-cli), a Rust CLI tool that wraps the same [MDK](https://github.com/parres-hq/mdk) library that powers the White Noise app. When a message arrives, a Python handler routes it to either DeepSeek (for general conversation, cheap) or Claude (for tool-calling, when memory operations are needed). The reply goes back through marmot-cli.

```
White Noise app → Nostr relays → marmot-cli listen → handler.py → Claude / DeepSeek
                                                          ↓
                                     marmot-cli send ← reply
```

The handler also connects to a self-hosted [MCP memory server](https://github.com/marmot-protocol/mdk) for semantic memory. When I say "remember that we discussed X," Klaw stores it. When I ask "what do you know about Y," Klaw searches. All memories are tagged with `source: "klaw"` so they're scoped to our conversations.

The whole thing runs as a systemd service. It uses about **23MB of RAM** — compared to the ~386MB that OpenClaw (Klaw's Telegram runtime) uses. That's a 17x reduction for a service running on a mate's hardware, which matters.

## What I Learned Along the Way

### Pin marmot-cli to the Latest MDK

This was the biggest time sink. Marmot-cli ships with a pinned MDK git revision in `Cargo.toml`. If that revision doesn't match what the current White Noise app expects, key packages will be incompatible and the MLS handshake will fail with cryptic errors.

The Marmot protocol went through a breaking encoding change (hex → base64 with explicit tags) driven by a security audit. If your CLI is on an old MDK and the app is on a new one, you'll see errors like:

- `MDK error: Invalid character 'S' at position 5` — the app is hex-decoding base64 content
- `MDK error: Missing required tag: i` — the app expects a tag the old MDK doesn't produce

The fix: update `Cargo.toml` to the latest MDK revision, delete `Cargo.lock`, and rebuild. Also check for any hardcoded encoding tags in the marmot-cli source — mine had a line that appended `["encoding", "hex"]` to key packages, conflicting with the MDK's own `["encoding", "base64"]`.

### Set HOME in the Systemd Service

Without `Environment=HOME=/root` in the service unit, marmot-cli creates its MLS database at `/.marmot-cli/marmot.db` instead of `~/.marmot-cli/marmot.db`. Then manual CLI commands and the service operate on different MLS state, and nothing works. A small thing that cost me an hour.

### MLS State Is Fragile

If you wipe `marmot.db`, all existing MLS sessions are gone. The other party needs to start a new chat. You can't just re-init — Welcomes are encrypted to specific key packages, and if the target key package no longer exists in your key store, the Welcome is unprocessable.

### Keep the White Noise App Updated

The app's source repo moved from `parres-hq/whitenoise_flutter` (now archived) to [marmot-protocol/whitenoise](https://github.com/marmot-protocol/whitenoise). If you're installing via Obtainium or similar, update the source URL. Older builds from the archived repo won't have critical encoding fixes.

### Owner Verification

The handler checks the sender's public key before engaging. Only my Nostr pubkey gets the full AI pipeline. Anyone else gets a polite redirect. Without this, anyone who discovers Klaw's npub could run up API costs.

## Why Not Just Use Telegram?

Telegram is polished. It's easy to set up a bot. OpenClaw made it trivial. But when your AI agent holds personal context — semantic memories about your projects, your contacts, your decisions — the transport layer matters.

**Telegram's encryption is opt-in and limited.** Regular chats and all group chats are server-side encrypted, meaning Telegram can read them. "Secret chats" offer E2E encryption but only for 1:1, only on mobile, and bots can't use them. Every message Klaw received on Telegram was readable by Telegram's servers.

**White Noise encrypts everything, always.** MLS provides forward secrecy and post-compromise security. Even if a key is compromised, past messages stay protected. Future messages are safe once the group state advances. There's no "opt-in" — it's the only mode.

**Identity without phone numbers.** Telegram requires a phone number. White Noise uses a Nostr keypair. No SIM-swapping risk, no KYC, no linking back to a real-world identity unless you choose to.

**Relays are dumb transport.** Nostr relays see encrypted blobs and public keys. They can't read message content or infer social graphs from it. You can run your own relay — I do. Telegram's servers see everything except secret chat content, including who's talking to whom and when.

**No central authority.** Telegram can comply with law enforcement requests, ban accounts, or shut down bots. Nostr relays can be swapped out. If one goes down or starts censoring, you just publish to another. The protocol doesn't depend on any single operator.

**Memory traffic stays private.** Klaw's MCP memory calls go directly from the handler to my self-hosted memory server over HTTPS. On Telegram, the message content transits Telegram's infrastructure before reaching Klaw. On White Noise, the only network hops are encrypted Nostr events and a direct HTTPS call to my own server.

The tradeoff is real — Telegram is far more polished, and MLS state management in marmot-cli is fragile. But for an AI agent that I'm asking to "remember" things about my life and work, I want the conversation to be between me and the agent. Not me, the agent, and a platform.

| | Telegram (OpenClaw) | White Noise (marmot-cli) |
|---|---|---|
| **Encryption** | Opt-in, DMs only, no bots | Always on, all chats |
| **Identity** | Phone number | Nostr keypair |
| **Server trust** | Telegram sees metadata + content | Relays see encrypted blobs only |
| **Forward secrecy** | Secret chats only | All messages (MLS) |
| **Central authority** | Telegram Inc. | None |
| **RAM** | ~386MB | ~23MB |
| **Dependencies** | Node.js, OpenClaw framework | Single Rust binary + Python script |
| **Setup complexity** | Low | Medium |

## The Stack

- **marmot-cli** — Rust CLI for MLS-over-Nostr, built against latest MDK
- **handler.py** — ~300 lines of Python, dual-model routing, MCP memory client
- **Claude** (claude-sonnet-4-6) — handles memory tool-calls via MCP
- **DeepSeek** (deepseek-chat) — handles general conversation, cheap
- **MCP memory server** — self-hosted semantic memory with scoped API keys
- **systemd** — keeps it running, auto-restarts on failure

Total cost: whatever DeepSeek and Claude API calls add up to for a casual messaging use case. The VPS was already running. The relays are public. The MCP server was already deployed.

Sometimes the best infrastructure is the kind you barely notice is there.
