---
title: "Self-Hosted SimpleX CLI in Docker: Private Notifications Without Big Tech"
date: 2026-02-01T00:19:03+10:00
draft: false
tags: []
---
Most bot and notification setups rely on Telegram or Signal. Both are fine, but they require trusting third-party infrastructure with your metadata. After reading about [OpenClawd](https://github.com/beratcmn/openclawd) and noticing the Telegram dependency, I decided to set up something more private.

SimpleX is a messaging protocol with no user identifiers - no phone numbers, no usernames, no accounts. Combined with a self-hosted relay server, you get end-to-end encrypted messaging where you control the infrastructure.

The code is on GitHub: [AusDavo/simplex-cli-docker](https://github.com/AusDavo/simplex-cli-docker)

## What I'm Building

- SimpleX CLI running in Docker with WebSocket API
- Connected to a self-hosted SMP relay server
- Accessible from other containers for bot integrations
- Private notifications to your phone

## Prerequisites

- Docker and Docker Compose
- A SimpleX SMP relay server (optional but recommended)
- SimpleX app on your phone

## The Docker Setup

### Dockerfile

```dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    libgmp10 \
    expect \
    socat \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash simplex && \
    mkdir -p /home/simplex/.simplex /home/simplex/bin && \
    chown -R simplex:simplex /home/simplex

WORKDIR /home/simplex
USER simplex

RUN curl -o- https://raw.githubusercontent.com/simplex-chat/simplex-chat/stable/install.sh | bash

ENV PATH="/home/simplex/.local/bin:${PATH}"

USER root
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chmod=755 init-user.exp /usr/local/bin/init-user.exp
USER simplex

ENV SIMPLEX_USER=SimplexBot

VOLUME ["/home/simplex/.simplex"]
EXPOSE 5225

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["-p", "5226"]
```

### The Tricky Part: User Initialization

SimpleX CLI requires an interactive terminal to create the initial user profile. In a Docker container without a TTY, this fails. The solution is an expect script that handles the interactive prompts:

**init-user.exp:**
```tcl
#!/usr/bin/expect -f

set timeout 30
set username [lindex $argv 0]

spawn simplex-chat

expect {
    "display name:" {
        send "$username\r"
    }
    "No user profiles found" {
        expect "display name:"
        send "$username\r"
    }
    timeout {
        puts "Timeout waiting for prompt"
        exit 1
    }
}

expect {
    -re "Welcome.*$username" {
        puts "User created successfully"
    }
    -re ">" {
        puts "User created"
    }
    timeout {
        puts "Timeout after username entry"
    }
}

send "/quit\r"
expect eof
```

### Another Gotcha: Localhost Binding

The SimpleX CLI WebSocket server binds to `127.0.0.1`, not `0.0.0.0`. This means other containers can't connect to it. The fix is socat:

**entrypoint.sh:**
```bash
#!/bin/bash
set -e

DB_DIR="/home/simplex/.simplex"
DB_FILE="$DB_DIR/simplex_v1_chat.db"
USER_NAME="${SIMPLEX_USER:-SimplexBot}"
INTERNAL_PORT=5226
EXTERNAL_PORT=5225

if [ -f "$DB_FILE" ]; then
    echo "Database exists, starting in API mode..."
else
    echo "First run detected. Creating user profile: $USER_NAME"
    /usr/local/bin/init-user.exp "$USER_NAME" || true

    if [ ! -f "$DB_FILE" ]; then
        echo "Warning: Database file not found, but continuing..."
    else
        echo "User profile created successfully!"
    fi
fi

echo "Starting socat proxy (0.0.0.0:$EXTERNAL_PORT -> 127.0.0.1:$INTERNAL_PORT)..."
socat TCP-LISTEN:$EXTERNAL_PORT,fork,reuseaddr TCP:127.0.0.1:$INTERNAL_PORT &

# Build command args
ARGS=("$@")

# Add SMP server if configured
if [ -n "$SMP_SERVER" ]; then
    echo "Using SMP server: $SMP_SERVER"
    ARGS+=("-s" "$SMP_SERVER")
fi

echo "Starting SimpleX CLI in API mode on internal port $INTERNAL_PORT..."
exec simplex-chat "${ARGS[@]}"
```

### Docker Compose

```yaml
services:
  simplex-cli:
    build: .
    container_name: simplex-cli
    expose:
      - "5225"
    volumes:
      - simplex-data:/home/simplex/.simplex
    restart: unless-stopped
    env_file:
      - path: .env
        required: false
    environment:
      - SIMPLEX_USER=${SIMPLEX_USER:-SimplexBot}
      - SMP_SERVER=${SMP_SERVER:-}

volumes:
  simplex-data:
```

Configure via `.env`:

```bash
SIMPLEX_USER=SimplexBot
SMP_SERVER=smp://YOUR_FINGERPRINT@your-relay.example.com
```

For external networks, use `docker-compose.override.yml`:

```yaml
services:
  simplex-cli:
    networks:
      - your-network

networks:
  your-network:
    external: true
```

## Configuring Your Relay

If you're running your own SMP server, configure the CLI to use it:

```bash
docker exec -it simplex-cli simplex-chat
```

Then:
```
/smp smp://YOUR_FINGERPRINT@your-relay.example.com
```

## Creating Your Contact Address

Generate an address that uses your relay:

```
/address
```

This produces a link you can convert to a QR code:

```bash
qrencode -t ANSIUTF8 "https://your-relay.example.com/a#..."
```

Scan with your SimpleX app to connect.

## WebSocket API

The CLI exposes a WebSocket API on port 5225 for programmatic access:

**Message format:**
```json
{"corrId": "1", "cmd": "/users"}
```

**Response:**
```json
{"corrId": "1", "resp": {...}}
```

**Sending a message:**
```json
{"corrId": "2", "cmd": "@'Contact Name' Hello from the bot!"}
```

## Privacy Comparison

| Service | Message Content | Metadata | Infrastructure |
|---------|----------------|----------|----------------|
| Telegram | Visible to Telegram | Fully exposed | Telegram servers |
| Signal | E2E encrypted | Phone numbers exposed | Signal servers |
| SimpleX (public) | E2E encrypted | Minimal | SimpleX servers |
| **SimpleX (self-hosted)** | E2E encrypted | **You control it** | **Your servers** |

## Use Cases

- Server monitoring alerts
- CI/CD notifications
- Home automation events
- Security alerts (failed logins, etc.)
- Personal reminders
- Anything you'd use Telegram bots for, but private

## Conclusion

It takes more effort than spinning up a Telegram bot, but if you care about metadata privacy, self-hosted SimpleX is worth it. Your notifications flow through infrastructure you control, with end-to-end encryption and no user identifiers.

The WebSocket API makes it straightforward to integrate with tools like n8n, Home Assistant, or custom scripts.

---

*Running SimpleX CLI v6.4.8.0 on Docker with Ubuntu 22.04 base image.*
