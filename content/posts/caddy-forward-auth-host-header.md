---
title: "Caddy forward_auth to an External oauth2-proxy: The Host Header Gotcha"
date: 2026-01-31
draft: false
---
I run multiple Caddy instances across separate networks, all using a shared oauth2-proxy for authentication. The setup worked fine when Caddy and oauth2-proxy were on the same network. When I moved some services to a different network and had Caddy call oauth2-proxy over its public HTTPS endpoint, group-based authorization broke silently.

Users could log in. The cookie was valid. But every request failed with "Access denied: No group membership found."

## The Setup

Two Caddy instances. One shares a Docker network with oauth2-proxy and calls it directly:

```caddy
forward_auth oauth2-proxy:4180 {
    uri /oauth2/auth
    copy_headers X-Auth-Request-Groups
}
```

The other is on a separate network and must go through the public URL:

```caddy
forward_auth https://oauth2-proxy.example.com {
    uri /oauth2/auth
    copy_headers X-Auth-Request-Groups
}
```

Both use the same `copy_headers` directive. Both should behave identically. They didn't.

## The Symptom

The internal setup worked. Group memberships flowed through, access control worked as expected.

The external setup authenticated users correctly but never passed group information. The `X-Auth-Request-Groups` header that `copy_headers` was supposed to grab simply wasn't there — even though oauth2-proxy was definitely returning it.

## Debugging

I tested each layer with curl.

Hitting oauth2-proxy directly on its internal address with a valid cookie returned all the expected headers:

```
X-Auth-Request-User: user-uuid
X-Auth-Request-Email: user@example.com
X-Auth-Request-Groups: infra,all_team,security
```

Hitting the same endpoint through the public Caddy reverse proxy returned the same headers. So Caddy wasn't stripping them on the way back.

The problem was in how `forward_auth` made the request when targeting an external HTTPS URL.

## The Fix

Adding an explicit Host header to the `forward_auth` block solved it:

```caddy
forward_auth https://oauth2-proxy.example.com {
    uri /oauth2/auth
    copy_headers X-Auth-Request-Groups
    header_up Host oauth2-proxy.example.com
}
```

That's it. One line.

## Why This Happens

When `forward_auth` makes a subrequest to an internal address like `oauth2-proxy:4180`, the Host header is straightforward.

When it makes a subrequest to an external HTTPS URL, Caddy appears to use the original request's Host header (e.g., `protected-app.example.com`) rather than the oauth2-proxy hostname. oauth2-proxy uses the Host header when validating the session cookie. If the Host doesn't match what it expects, the cookie validation behaves differently — in this case, returning a valid 202 but without the `X-Auth-Request-*` headers.

## Is This Documented?

Not really. Caddy's `forward_auth` documentation doesn't mention this behaviour. oauth2-proxy's docs assume you're running it on the same network as your reverse proxy. The interaction between the two across network boundaries is an edge case that you discover the hard way.

## The Takeaway

If you're using Caddy's `forward_auth` with an external HTTPS endpoint — whether that's oauth2-proxy, Authelia, or anything else — and your auth headers aren't coming through, check your Host header first.

```caddy
header_up Host your-auth-server.example.com
```

It's a one-line fix to a problem that can cost you an afternoon.