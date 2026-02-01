---
title: "My First Open Source Contribution: SimpleX Chat WebSocket Binding"
date: 2026-02-01
tags: ["simplex", "open-source", "docker", "self-hosting"]
---

This is a follow-on to my [SimpleX CLI Docker Setup](/posts/simplex-cli-docker-setup/) post. If you read that, you might remember the socat workaround I used to get around the WebSocket server only binding to localhost:

```yaml
command: >
  sh -c "socat TCP-LISTEN:5225,fork,bind=0.0.0.0 TCP:127.0.0.1:5226 &
         simplex-chat -p 5226"
```

It worked, but it always felt like a hack. The underlying issue was that `simplex-chat` hardcodes the bind address to `127.0.0.1` when you use the `-p` flag.

## Understanding the Default

This localhost-only binding is a reasonable security decision. SimpleX is designed primarily for private communication between people on mobile devices - not for bots and automation. Binding to localhost means only local processes can connect to the WebSocket API, which is sensible when you're running the CLI directly on a machine you control.

But for those of us running SimpleX in containers, or interested in exploring its potential for automated messaging and notifications, this becomes a constraint.

## The Contribution

I'm fairly new to open source, but I figured I'd try submitting a small PR rather than maintaining my own patched binary. The change adds an optional `--chat-server-host` flag:

```bash
simplex-chat -p 5225 --chat-server-host 0.0.0.0
```

The secure default stays unchanged - without the flag, it still binds to `127.0.0.1`. The option just allows users who understand the implications to bind more broadly when their deployment requires it.

[PR #6609](https://github.com/simplex-chat/simplex-chat/pull/6609) is now open.

## Why I Care About This

I'd like to see more experimentation with SimpleX for bot and automation use cases. The protocol's privacy properties - no user identifiers, decentralised architecture, end-to-end encryption - seem valuable beyond just person-to-person chat. Notifications, alerts, home automation, CI/CD updates... there's potential here.

I recognise that's not the project's primary focus, and that's fine. But making the CLI a bit more container-friendly might lower the barrier for others who want to explore these ideas.

If the PR gets merged, I can finally remove the socat workaround from my Docker setup. If not, I've learned a lot from reading through the codebase. Either way, worth the attempt.
