---
title: How I Evolved My Homelab Reverse Proxy Strategy (And Why L4 Passthrough Won)
date: 2026-02-08T15:59:58+10:00
draft: false
tags: []
---
Over the past few years, my approach to exposing homelab services to the internet has gone through four distinct phases. Each one solved a real problem and created a new one. If you're self-hosting services and trying to figure out the "right" way to handle ingress, TLS, and reverse proxying, this might save you some time.

## Phase 1: Port Forwarding with DDNS

The simplest thing that works. I forwarded ports on my router to services like Nextcloud, Bitcoin Core, and LND, and used No-IP for dynamic DNS so the world could find my changing residential IP.

Later I replaced No-IP with scripts that automatically updated DNS records when my home IP changed — one fewer dependency, same result.

This setup is straightforward and costs nothing beyond your existing internet connection. But it has obvious drawbacks: your home IP address is right there in your DNS records for anyone to see, you're reliant on your ISP not blocking inbound ports or sticking you behind CGNAT, and every service you expose is another port punched through your router's firewall.

It worked fine for a while. But I wanted my home IP hidden, and I wanted a cleaner way to manage TLS certificates across multiple services.

## Phase 2: L7 Reverse Proxy on a VPS

I spun up a small VPS and installed Caddy as a Layer 7 reverse proxy. Caddy's appeal is hard to overstate: its configuration syntax is remarkably simple, and it autoprovisions TLS certificates from Let's Encrypt with zero configuration. DNS pointed to the VPS, Caddy terminated TLS and obtained certs automatically, and traffic was forwarded to my home services across a Tailscale tunnel.

This solved the IP exposure problem and centralised certificate management. But it introduced a new concern: my VPS was now terminating TLS, which meant all my traffic was decrypted on a machine I didn't physically control. If that VPS were compromised, an attacker could see everything — credentials, API tokens, personal data, all of it in plaintext.

It also meant my routing configuration lived on the VPS. Every time I added or changed a service, I had to SSH into the VPS and edit configs there.

## Phase 3: The Awkward Hybrid

Not all services speak HTTP. Electrs (an Electrum server for Bitcoin) communicates over raw TCP — and Caddy, being fundamentally an HTTP reverse proxy, simply couldn't handle it. There's a community Layer 4 plugin for Caddy (caddy-l4), but I didn't trust it for production use. So I brought in NGINX to handle the TCP stream proxying for electrs, with NGINX also terminating TLS for that connection on the VPS.

This worked, but it was an awkward split. Two different proxies on the VPS, two different config syntaxes, and an unclear boundary between what NGINX handled and what Caddy handled. NGINX was terminating TLS for the TCP services, Caddy was terminating TLS for the HTTP services, and my VPS was still decrypting traffic either way.

The hybrid phase made one thing clear: I wanted *all* my traffic — HTTP and raw TCP alike — to pass through the VPS encrypted, with TLS termination happening on hardware I controlled. It was time to commit to that model fully.

## Phase 4: Full L4 Passthrough with HAProxy

I set up a new VPS with HAProxy doing nothing but Layer 4 passthrough. HAProxy is widely regarded as the king of Layer 4 proxying — it's what it was originally built for, and its TCP proxying capabilities are battle-tested at enormous scale. For a role that would be exclusively L4, it was the obvious choice.

The VPS now does exactly one thing: it inspects the SNI (Server Name Indication) field in the TLS ClientHello, and forwards the entire encrypted TCP stream to the appropriate backend based on that hostname. It never sees a decrypted byte.

TLS termination shifted to where it belongs — as close to the backend as possible. For most services, this means a Caddy stack that runs alongside application containers. The stack includes Caddy itself, a Tailscale sidecar (so Caddy is a node on my tailnet), and oauth2-proxy for authentication. I've open-sourced a [template for this Caddy + oauth2-proxy pattern](https://github.com/AusDavo/caddy-oauth2-proxy-auth-template) and shared an [authentication template with the Caddy community](https://caddy.community/t/oauth2-authentication-template-with-group-checks-using-oauth2-proxy-and-self-hosted-oidc/31611) that includes group-based access control using a self-hosted OIDC provider. Containers that need to be proxied are added to Caddy's Docker network, and Caddy can also reach other Tailscale backends across the tailnet if required. The VPS running HAProxy reaches Caddy across this same tailnet — encrypted end to end.

Services sophisticated enough to manage their own certificates (like Proxmox VE and Proxmox BS) handle ACME directly and receive passthrough traffic from HAProxy without Caddy in the middle. For services only accessible within my tailnet, Caddy's Tailscale integration can automatically provision trusted HTTPS certificates for tailnet machine names — these are still Let's Encrypt certificates under the hood, but Tailscale handles the provisioning seamlessly.

Once everything was migrated, I decommissioned the L7 VPS entirely.

## Why This Architecture Works

The final setup has a clean separation of concerns:

- **HAProxy on the VPS** does SNI-based routing. It's a dumb, hardened pipe. Its config rarely changes. It reaches the home network via Tailscale.
- **A Caddy stack at home** handles ACME, TLS termination, and authentication. It runs with a Tailscale sidecar and oauth2-proxy. Application containers join Caddy's Docker network for proxying, and Caddy can also reach other backends across the tailnet.
- **The services themselves** just serve their application, unaware of how traffic reached them.

The VPS has a minimal attack surface. If it's compromised, the attacker sees only encrypted TCP streams — no plaintext, no certificates, no routing logic. All the interesting configuration lives on hardware I physically control.

Adding a new service means spinning up a container and attaching it to Caddy's Docker network. The VPS gets a one-line SNI route added, if that. Most of the time the VPS config doesn't change at all if I'm using wildcard routing.

And crucially, the ingress method is now decoupled from the routing logic. If I ever want to ditch the VPS — because my ISP gives me a static IP, or I move somewhere with better connectivity — I just update DNS to point at my home IP, forward ports 443 and 80 on my router, and I'm done. My entire proxy configuration at home stays identical. Five-minute migration.

The reverse is also true: if I'm suddenly behind CGNAT or my ISP blocks ports, I spin up a cheap VPS, point DNS at it, and set up L4 passthrough. The home side doesn't care how the traffic arrived.

## Comparing the Three Strategies

Here's how the approaches stack up across the dimensions that matter most:

### Security

| | L7 on VPS | L4 VPS → L7 Home | Port Forward + DDNS |
|---|---|---|---|
| TLS termination | On VPS (remote machine) | At home (your hardware) | At home (your hardware) |
| VPS compromise impact | High — attacker sees plaintext | Low — only encrypted TCP visible | N/A — no VPS |
| Home IP exposure | Hidden behind VPS | Hidden behind VPS | Exposed in DNS |
| Attack surface | Full L7 stack on exposed VPS | Minimal L4 config on VPS | L7 proxy directly on internet |

### Operations

| | L7 on VPS | L4 VPS → L7 Home | Port Forward + DDNS |
|---|---|---|---|
| Config management | Split across VPS and home | Centralised at home | Centralised at home |
| Cert management | Certs on remote machine | Certs on your hardware | Certs on your hardware |
| Adding a new service | Edit VPS proxy config | Edit home proxy only | Edit home proxy only |
| Ongoing cost | ~$3–6/mo for VPS | ~$3–6/mo for VPS | Free |

### Network & Performance

| | L7 on VPS | L4 VPS → L7 Home | Port Forward + DDNS |
|---|---|---|---|
| TLS handshake latency | Low (terminates at edge) | +20–50ms (round-trips home) | Depends on connection |
| Bandwidth | All traffic via VPS | All traffic via VPS | Direct, no middleman |
| Works behind CGNAT | Yes (outbound tunnel) | Yes (outbound tunnel) | No (needs inbound ports) |

### Flexibility

| | L7 on VPS | L4 VPS → L7 Home | Port Forward + DDNS |
|---|---|---|---|
| Migrate to port forwarding | Hard — rebuild proxy at home | Trivial — update DNS, done | Already there |
| Migrate to VPS tunnel | Already there | Already there | Easy — add VPS, repoint DNS |
| Swap transport method | Hard — routing tied to VPS | Easy — transport decoupled | Easy |

The L4 VPS → L7 Home approach wins on most dimensions. The small latency penalty (~20–50ms on TLS handshake) and the VPS cost (~$3–6/month) are a worthwhile trade for the security and flexibility you get.

## What's Next

### Traefik

I've used Caddy extensively and like it a lot — the simple config syntax and automatic Let's Encrypt integration are hard to beat for the L7/TLS termination role. NGINX is also solid and handles both L7 and L4 natively, though it leaves you to sort out certificates separately (typically with certbot). HAProxy is the L4 king, which is why I chose it for the edge proxy role that's exclusively Layer 4.

But I'm increasingly interested in Traefik. It handles both Layer 4 and Layer 7 natively, supports automatic TLS provisioning from Let's Encrypt (like Caddy), and — most appealing to me — it has built-in service discovery that can automatically detect and route to Docker containers as they come and go. For a homelab that's constantly evolving, having the proxy automatically pick up new services without manual config changes sounds compelling.

Whether Traefik could eventually replace both HAProxy on the edge *and* Caddy at home is something I want to explore. The idea of a single proxy platform handling L4 passthrough on the VPS and L7 termination at home, with automatic Docker endpoint discovery, is attractive. But HAProxy has earned its place at the edge by being exceptionally good at one thing, and there's something to be said for keeping it there.

### Load Balancing and Redundancy

The current setup has obvious single points of failure: one VPS, one Caddy stack, one home internet connection. Everything works until it doesn't, and when it doesn't, everything goes down at once.

I'd like to explore adding redundancy at multiple levels. At the edge, that could mean running HAProxy on two or more VPS instances behind DNS round-robin or a healthchecked DNS provider, so that if one VPS goes down traffic automatically routes to the other. At home, load balancing across multiple instances of a service — or across multiple machines — would improve both resilience and capacity. HAProxy and Traefik are both well-suited to this; health checks, failover, and weighted load balancing are core features of both.

There's also the question of redundancy for the home connection itself. A secondary WAN link (a cheap mobile data connection, for instance) with automatic failover at the router would protect against ISP outages. Combined with multiple VPS entry points, the whole path from client to service could tolerate a failure at any single point.

This is the natural next step once the basic proxying architecture is solid — and it's where tools like HAProxy and Traefik really start to justify their complexity over simpler alternatives.

More to come as I experiment.

---

*Published on [blog.dpinkerton.com](https://blog.dpinkerton.com)*
