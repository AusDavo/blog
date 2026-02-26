---
title: Mining Your Own Timesheet Data
date: 2026-02-26T12:00:00+10:00
draft: false
tags:
  - contracting
  - data
  - kimai
  - self-hosting
---
Ask a contractor what they've worked on in the last year and you'll get a vague answer. Something like "infrastructure, some web stuff, bit of everything really." Ask me and I'll give you a categorised breakdown of 489 logged tasks across 560 hours — because I tracked all of it.

## Why Track at This Level

I use [Kimai](https://www.kimai.org/), an open-source time tracker I self-host. Every task gets a description. Not "did some work" — an actual note. *Migrated LND wallet to new channel database. Configured Caddy reverse proxy with mTLS passthrough. Wrote Python script to reconcile UTXO set against xpub descriptors.* That kind of thing.

I didn't start doing this for any strategic reason. It's just how I work. But recently I pointed Claude Code at the Kimai API and asked it to pull and categorise everything I'd logged over the past 11 months. A temporary API token, some paginated queries, and a bit of inline Python later — I had a complete inventory of what I'd actually built, configured, debugged, and deployed.

The result surprised me.

## What I Found

The breadth was wider than I remembered. Across 11 months of contract work, the entries spanned:

- **Infrastructure** — Proxmox virtualisation, LXC containers, Docker Compose stacks, systemd service management, kernel upgrades, disk provisioning
- **Networking** — Tailscale mesh configuration, HAProxy L4 passthrough, Caddy TLS termination, UFW rules, DNS management, nginx stream proxying
- **Bitcoin** — Full node operation, Lightning (LND) channel management, wallet architecture, BIP-322 message signing, descriptor-based address derivation, UTXO verification
- **Security** — Passkey (WebAuthn) authentication, encrypted-at-rest blob storage, API token lifecycle management, SSH hardening, backup verification
- **Web development** — SvelteKit applications, REST API design, SQLite schemas, responsive UI, dark mode implementation
- **Monitoring & ops** — Cron job auditing, log analysis, backup automation, disk space management, service health checks
- **Compliance & reporting** — PDF generation pipelines (Pandoc + LaTeX), automated report templating, audit trail design

That's not a list I could have written from memory. I'd have missed half of it, or been vague about the specifics. But with 489 documented entries, each with a description, the data writes the list for you.

## From Timesheets to Capability Statement

Here's what I didn't expect: a well-maintained timesheet is essentially a first draft of your professional portfolio.

When every entry has a description, you can query your own history and answer questions like:

- *What networking technologies have I configured in production?* — Tailscale, HAProxy, Caddy, nginx, UFW. Not "I've done some networking."
- *How deep is my Bitcoin infrastructure experience?* — 200+ hours across node operations, Lightning channel management, and wallet tooling. Not "I know a bit about Bitcoin."
- *Can I do full-stack web development?* — Here are the SvelteKit apps I built, the API endpoints I designed, the SQLite schemas I wrote. Not "I've done some web stuff."

The specificity matters. Anyone can claim broad competence. But being able to say "I've spent 73 hours in a single month on infrastructure work, and here's what that included" is a different kind of statement. It's verifiable, it's precise, and it's convincing.

## The Technical Side

The reason this works is that Kimai exposes a REST API. A web dashboard shows you your hours. But when you want to categorise, cross-reference, and summarise a year of entries, you need programmatic access.

The query was straightforward — paginated GET requests to `/api/timesheets` with date range filters, joined against `/api/activities` and `/api/projects` for metadata. Claude Code handled the aggregation: grouping by activity type, calculating hours per category, extracting the description text for pattern analysis.

Self-hosting matters here. The data lives on my server, in my database. No export limitations, no vendor lock-in, no wondering whether the SaaS will still exist when I need the data in three years. Kimai runs in Docker and the API is clean. If you contract and you don't already track your time at this resolution — this is the tool.

## Bottom Line

Your timesheet isn't just a billing record. Maintained with enough detail, it becomes a searchable, queryable log of everything you've actually done — the kind of evidence that lets you describe your capabilities with specificity instead of hand-waving.

Track your time. Write descriptions. Self-host the data. You'll be surprised what it tells you about yourself.