---
title: How Claude Code Fixed My Lightning Channel in Minutes (Not by Knowing Everything, but by Figuring It Out)
date: 2026-02-23T07:15:59+10:00
draft: false
tags: []
---
I run a Bitcoin Lightning node called WinThistle. A few days ago I noticed my channel to [mineracks](https://amboss.space) had gone inactive. I knew something was wrong but hadn't had a chance to dig into it. So I asked Claude Code.

What happened next was a masterclass in iterative problem-solving — not because Claude knew the answer immediately, but because it *didn't*, and that turned out not to matter.

## The Problem

My channel to mineracks was showing `active: false`. Payments couldn't route through it. I had 882,000 sats of liquidity sitting idle.

## The Diagnosis

Claude's first move was to check my LND setup. It found `lncli`, hit a TLS certificate mismatch (my node uses a custom cert for `lnd.dpinkerton.com`), adapted by reading my `lnd.conf` to find the right cert path, and got in.

From there it pulled the channel list and the gossip graph data for mineracks. The finding was clear: mineracks was advertising **only** a Tor `.onion` address. My node had no Tor configuration. I couldn't dial out to them — the channel only came alive when *they* happened to connect to *me*.

## The Conversation

This is where it got interesting. I pushed back: "I thought mineracks was a hybrid node." Claude didn't dismiss me — it acknowledged that the gossip data showed otherwise *right now*, but that the node may have changed. It suggested the operator might have lost their clearnet address after a restart.

I asked about adding Tor. Claude laid out honest pros and cons — reliability issues, latency, attack surface — without overselling it. When I asked if I could use Tor for outbound connections only, without advertising a `.onion` address, it confirmed that was possible and sketched out the config.

## The Implementation (Where It Gets Real)

Here's where the iterative nature really shone. Claude didn't execute a perfect script. It hit problems, learned from each one, and kept moving:

**Attempt 1:** Installed Tor, added a `[Tor]` section to `lnd.conf`, restarted LND. Result: LND crash-looped. The logs showed it was trying to connect to Tor's **control port** (9051), which wasn't enabled. Claude had only checked that the SOCKS port (9050) was up.

**Attempt 2:** Enabled the control port and cookie authentication in `/etc/tor/torrc`, added `stacker` to the `debian-tor` group so LND could read the auth cookie, added `tor.control` to `lnd.conf`. Also tried `tor.noonion=true` to prevent advertising a hidden service. Result: config parse error — `tor.noonion` doesn't exist in LND 0.18.4.

**Attempt 3:** Removed the invalid option, restarted. Result: success. The logs showed an immediate outbound connection to mineracks over Tor:

```
Established connection to: 021140eb...@4x56wagezqi...onion:9735
```

All four channels came up active. Total elapsed time from first command to working fix: about five minutes.

## What I Took Away

Claude Code didn't have a pre-baked "add Tor to LND" recipe. It made three attempts. It hit a missing control port, a permissions issue, and an invalid config option. Each time, it read the error, understood the cause, and fixed it in the next iteration.

This mirrors how an experienced sysadmin works — you don't memorise every config option for every daemon. You try the reasonable thing, read what breaks, and adjust. The difference is speed. What would have cost me an evening of trawling GitHub issues and Reddit threads took minutes, because Claude could read logs, check ports, edit configs, and restart services in rapid succession, all while explaining what it was doing and why.

The other thing worth noting: it was honest about uncertainty. It didn't pretend to know that `tor.noonion` was valid — it tried it, got an error, and removed it. It didn't pretend mineracks had always been Tor-only — it acknowledged my experience while showing me what the current data said. That kind of intellectual honesty makes it a tool I trust to operate on a live Lightning node with real sats at stake.

## The Final Config

For anyone in the same situation — a clearnet LND node that needs to reach Tor-only peers — here's what worked:

**`/etc/tor/torrc`** (enable control port):
```
ControlPort 9051
CookieAuthentication 1
```

**`lnd.conf`** (add Tor section):
```ini
[Tor]
tor.active=true
tor.v3=true
tor.socks=127.0.0.1:9050
tor.control=127.0.0.1:9051
tor.skip-proxy-for-clearnet-targets=true
```

**Permissions:**
```bash
sudo usermod -aG debian-tor <your-lnd-user>
```

Then restart Tor and LND. Your node will use Tor to reach `.onion` peers and clearnet for everything else. No hidden service advertised.

---

*Written with the help of [Claude Code](https://claude.ai/claude-code), which did the work while I watched and asked questions.*
