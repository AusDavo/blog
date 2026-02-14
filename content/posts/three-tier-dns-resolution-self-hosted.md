---
title: "Three-Tier DNS: How I Route to My Homelab From Anywhere"
date: 2026-02-14T22:00:00+10:00
draft: false
tags:
  - self-hosted
  - dns
  - tailscale
  - adguard
---
If you self-host services behind a VPS, you've probably noticed the inefficiency: you set up `app.example.com` to point at your VPS, the VPS tunnels traffic home, everything works — but when you access it from your couch, the request still takes a round trip through a data centre to reach a server two metres away.

This post covers how I set up DNS so that traffic always takes the shortest path to my home server, regardless of where the request comes from.

## The Problem

I run services on a home server exposed to the internet via [L4 passthrough on a VPS](/posts/evolving-reverse-proxy-strategy/). The public DNS for `*.example.com` points at my VPS IP. HAProxy inspects the SNI header and forwards the encrypted stream home via Tailscale.

This works well from the outside. But from inside my network, a request to `photos.example.com` would:

1. Resolve to the VPS public IP
2. Leave my home network
3. Hit the VPS
4. Tunnel back home via Tailscale
5. Arrive at the server sitting on the same LAN

That's a round trip through a data centre and back to reach a machine on `192.168.1.x`. It works, but it adds unnecessary latency and wastes bandwidth on both ends.

Note that this isn't a hairpin NAT problem — the DNS doesn't resolve to the home router's WAN address, it resolves to the VPS. The traffic legitimately goes to the VPS and gets tunnelled back. It works fine. It's just an unnecessary round trip when the client and server are on the same network.

I wanted something more intentional: DNS that returns the right IP for where you are.

## The Three Tiers

There are three contexts a client might be connecting from:

| Context | DNS should resolve to | Why |
|---|---|---|
| On Tailscale (anywhere) | `100.x.x.x` (server's Tailscale IP) | Direct WireGuard tunnel, encrypted, works from any network |
| On the LAN (no Tailscale) | `192.168.1.x` (server's LAN IP) | Direct LAN connection, fastest possible path |
| External (neither) | `203.0.113.x` (VPS public IP) | HAProxy L4 passthrough to Caddy at home |

Each context gets the most direct route to the same server. No hairpin. No unnecessary hops.

## How It Works

### Tier 1: Tailscale — MagicDNS Split DNS

Tailscale's MagicDNS supports split DNS: you can configure specific domains to be resolved by specific nameservers. In the Tailscale admin console, I added a split DNS entry that routes `example.com` to my server's Tailscale address.

When any device on my tailnet queries `anything.example.com`, MagicDNS intercepts the query and resolves it to the server's Tailscale IP. The request then travels over the WireGuard tunnel directly to the server — encrypted end-to-end, no VPS involved.

This works whether I'm on my home LAN, at a coffee shop, or on mobile data. If Tailscale is running, DNS returns the Tailscale IP, and traffic goes direct.

### Tier 2: LAN — AdGuard Home with Client-Based Rewrites

Not every device on my network runs Tailscale. For those devices, I run [AdGuard Home](https://adguard.com/en/adguard-home/overview.html) as the network DNS server (assigned via DHCP).

AdGuard Home supports `$dnsrewrite` rules with a `client=` parameter. This is the key feature that makes single-instance split-horizon DNS possible:

```
||*.example.com^$dnsrewrite=NOERROR;A;192.168.1.x,client=192.168.1.0/24
||*.example.com^$dnsrewrite=NOERROR;A;100.x.x.x,client=100.64.0.0/10
```

The first rule: any client on the LAN (`192.168.1.0/24`) querying an `example.com` subdomain gets the server's LAN IP.

The second rule: any client in the CGNAT range (`100.64.0.0/10`, which covers Tailscale IPs) gets the server's Tailscale IP. This acts as a fallback for Tailscale devices that happen to query AdGuard directly rather than going through MagicDNS.

Any client that doesn't match either rule — which shouldn't happen on my network, but is a safe default — gets the real public DNS answer from upstream.

### Tier 3: External — Public DNS

For everyone else, `*.example.com` resolves normally via public DNS to the VPS IP. HAProxy does L4 passthrough based on SNI, and the encrypted stream reaches Caddy at home via Tailscale. This is the path described in my [reverse proxy strategy post](/posts/evolving-reverse-proxy-strategy/).

## The Result

From my desk (Tailscale running):

```
$ dig app.example.com +short
100.x.x.x
```

From a LAN device without Tailscale, using AdGuard as DNS:

```
$ dig app.example.com +short
192.168.1.x
```

From outside:

```
$ dig app.example.com +short
203.0.113.x
```

Same service, three different IPs, always the shortest path.

## Why Not Just Leave It?

Without DNS intervention, every client resolves to the VPS and traffic round-trips through it. This works. But it leaves efficiency on the table:

- **No context awareness.** The network doesn't know whether a client is on Tailscale, on the LAN without Tailscale, or connecting from outside. It treats them all the same.
- **Single path.** There's no way to prefer a direct WireGuard tunnel over the VPS path, or a LAN connection over either.
- **VPS dependency for local access.** If the VPS or your internet goes down, you can't reach services on your own LAN — even though the server is right there. Not a daily concern, but avoidable.

DNS-based routing gives you that context. Each client gets the most direct path available to it, and the three tiers operate independently.

## Why L4 Passthrough Makes This Cleaner

This DNS architecture works with any reverse proxy setup, but it's cleanest with Layer 4 passthrough on the VPS.

With an L7 proxy on the VPS, the VPS terminates TLS. When you then resolve `app.example.com` to a different IP — your Tailscale address or LAN IP — your home server also needs to terminate TLS for the same domain. Both the VPS and your home server run ACME, both provision certs for the same domains, and both renew independently. It works, but you've got two things managing the same certificates, with twice the surface area for renewal failures or rate-limit issues.

With L4 passthrough, the VPS never terminates TLS. It reads the SNI header from the TLS ClientHello and forwards the raw encrypted stream. TLS termination happens once, on your home server, regardless of how the traffic got there. The same Caddy instance, with the same certificate, handles requests whether they arrived via the VPS, the Tailscale tunnel, or the LAN.

L4 passthrough also decouples your routing from your DNS. The VPS is just a dumb pipe. It doesn't care what IP the client resolved, and your home server doesn't care how the traffic arrived. That clean separation is what makes DNS-based routing feel natural rather than bolted on.

## Setup Summary

The pieces:

1. **Tailscale admin console** — Split DNS entry: `example.com` → server's Tailscale IP
2. **AdGuard Home** — Two `$dnsrewrite` user rules with `client=` filters
3. **Public DNS** — A record for `*.example.com` → VPS IP (managed normally at your registrar)
4. **MagicDNS** — Enabled tailnet-wide so Tailscale devices use it automatically

The AdGuard `client=` parameter is the part I haven't seen documented well elsewhere. Most split-horizon DNS guides suggest running two DNS servers or using DNS views (a BIND feature). AdGuard's filtering rules achieve the same result from a single instance with two lines of config.

## Trade-offs

- **Tailscale is required for Tier 1.** If you don't use Tailscale (or another WireGuard mesh), you lose the remote-access tier. You could replace it with a VPN that provides its own DNS, but you'd need to wire up the equivalent split DNS yourself.
- **AdGuard must be the network DNS.** Devices that use a different DNS server (hardcoded `8.8.8.8`, for example) won't get the LAN rewrites. They'll resolve to the public IP and hairpin — or break. I enforce AdGuard as DNS via DHCP and don't override it on devices.
- **Three places to update.** Adding a new domain means updating the Tailscale split DNS, the AdGuard rules, and the public DNS. In practice, the wildcard rules mean I rarely touch the first two — only the public DNS needs a new record if I'm adding a completely new domain rather than a subdomain.

## What I'd Change

The AdGuard `$dnsrewrite` rules with `client=` work well but aren't discoverable. I initially set up DNS rewrites (the GUI feature) before finding the more powerful filtering rule syntax. If you're setting this up, skip the GUI rewrites and go straight to user rules — they're more flexible and the client-based matching is only available there.

I'd also like Tailscale to support split DNS responses directly (returning a specific IP for a domain, rather than forwarding to a nameserver). Currently the split DNS feature designates a nameserver to forward queries to, which means MagicDNS on the target node intercepts the query. This works in my case because MagicDNS returns the node's own Tailscale IP, but it's an indirect path to a simple result.

---

*This post is a companion to [How I Evolved My Homelab Reverse Proxy Strategy](/posts/evolving-reverse-proxy-strategy/), which covers the traffic routing side of the same architecture.*
