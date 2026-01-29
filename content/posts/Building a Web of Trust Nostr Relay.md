---
title: "Building a Web of Trust Nostr Relay"
date: 2026-01-29T22:00:00+11:00
draft: false
tags: []
---
How I turned a misconfigured relay into a curated community resource using a simple web of trust model.

## The Problem with Open Relays

I've been running a Nostr relay (strfry) for a while. The intent was "community benefit" - a public good for the network. In practice, it was a mess.

The relay was configured to sync from other public relays (nos.lol, soloco.nl) and accept pretty much everything. The result:

- **~78,000 events** from random pubkeys
- **2 events** that were actually mine
- No clear purpose
- Just another mirror of data that already exists elsewhere

The "community benefit" was zero. Anyone wanting that content could get it from the source relays. I was just burning storage for no reason.

## The Web of Trust Model

Instead of "accept everything" or "accept nothing," I wanted a middle ground: **accept content from people I actually care about**.

The model is simple:

1. Start with my pubkey
2. Add everyone I follow (from my kind 3 contact list)
3. Accept events from any of these pubkeys
4. Accept replies and mentions that tag anyone in this group
5. Reject everything else

This creates a relay that stores content relevant to my social graph - my own posts, posts from people I follow, and conversations that involve us.

## Implementation

I'm running [strfry](https://github.com/hoytech/strfry), which supports write policies via plugins. The policy is a simple Python script - here's the core logic:

```python
def should_accept(event, web_of_trust):
    # Accept if author is in WoT
    if event.pubkey in web_of_trust:
        return True

    # Accept if it tags someone in WoT (replies, mentions)
    tagged_pubkeys = {t[1] for t in event.tags if t[0] == "p"}
    if web_of_trust & tagged_pubkeys:
        return True

    # Accept metadata and relay lists (useful for discovery)
    if event.kind in (0, 3, 10002):
        return True

    return False
```

The web of trust list is stored in a text file and refreshed daily via cron, pulling my latest follow list from the relay itself.

### The Sync Question

I still sync from nos.lol and soloco.nl, but now the write policy filters incoming events. Only content that passes the WoT check gets stored. This means:

- I automatically get my follows' content even if they don't use my relay
- Replies to my network from outside the network are captured
- Random spam and unrelated content is rejected

## The Numbers

After implementing this and pruning the old junk:

| Metric | Before | After |
|--------|--------|-------|
| Total events | 78,561 | 5,034 |
| Database size | 274 MB | 20 MB |
| Relevant to me | ~0.01% | 100% |

## Who Is This For?

This relay is now useful for:

1. **Me**: A reliable home relay that I control, storing my content and my network's content
2. **People I follow**: A backup relay they can add to their relay list
3. **Anyone in the conversation**: Replies to my network are preserved

It's explicitly *not* for random internet strangers. They'll get rejected. That's the point.

## Trade-offs

**Pros:**
- Storage stays manageable
- Content is curated and relevant
- Clear value proposition for the people it serves
- Automatic - follows my social graph as it evolves

**Cons:**
- Not a "public good" in the broad sense
- People outside my network can't use it
- Requires maintenance (though minimal)

I'm fine with these trade-offs. Not every relay needs to serve everyone. The Nostr network benefits from diversity - some relays are open, some are paid, some are curated. This one is curated around my social graph.

## For My Follows

If you're someone I follow on Nostr, feel free to add my relay to your relay list:

```
wss://nostr.dpinkerton.com
```

It accepts your posts (you're in the WoT), stores replies to you, and serves as a backup if other relays go down. The more of my network that uses it, the more useful it becomes for everyone in that network.

## Setup Details

For anyone wanting to replicate this:

1. **Relay**: strfry (lightweight, supports write policies)
2. **Policy**: Python script checking against a pubkey whitelist
3. **WoT refresh**: Daily cron job fetching my kind 3 contact list
4. **Sync**: strfry router pulling from other relays, filtered by policy

The write policy plugin is ~50 lines of Python. The refresh script is ~30 lines. Total maintenance: basically zero once set up.

### Gotcha: Verify It's Actually Filtering

After setup, check your logs for "blocked" messages:

```
docker logs strfry | grep blocked
```

If you see events flowing in without blocks, your policy isn't running. Common culprits: missing `ROUTER` env var, wrong file permissions on the policy script, or stale config persisted in Docker volumes.

## Closing Thoughts

"Community benefit" doesn't have to mean "open to everyone." A relay that reliably serves a specific community - even a small one - is more valuable than a relay that serves everyone poorly.

My relay now has a clear purpose: home base for my corner of Nostr. That's enough.

---

*Relay: wss://nostr.dpinkerton.com | NIP-11 info available at the root URL*
