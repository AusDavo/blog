---
title: "LNbits Settings: The Database Always Wins"
date: 2026-02-21T14:00:00+10:00
draft: false
tags:
  - lightning
  - lnbits
  - docker
  - self-hosting
---

My LNbits instance stopped working. No config changes, no updates I'd triggered intentionally. Just VoidWallet errors where there used to be a functioning Lightning wallet.

The fix took an embarrassingly long time to find, not because it was complicated, but because the failure mode was completely misleading. If you're running LNbits in Docker with the Admin UI enabled, this will probably bite you too.

## The Symptom

LNbits was falling back to VoidWallet on every startup:

```
Connecting to backend LndWallet...
Error connecting to LndWallet: 'created_time'
Retrying connection to backend in 0.5 seconds... (1/4)
...
Fallback to VoidWallet, because the backend for LndWallet isn't working properly
```

The error `'created_time'` is a Python KeyError. It tells you nothing useful. It's not a missing field in a database, not a bad config key. It's a gRPC response parsing failure caused by a TLS mismatch — the kind of thing that only surfaces as a cryptic KeyError because the underlying exception gets swallowed somewhere deep in the stack.

## The Actual Problem

My LND node had switched from a self-signed TLS certificate to a Let's Encrypt cert for `lnd.dpinkerton.com`. The old self-signed cert only covered `localhost` and a Tailscale IP. The new cert only covered the `lnd.dpinkerton.com` hostname.

LNbits was still configured to connect to `192.168.1.103` with the old self-signed cert. Hostname didn't match, root CA didn't match — the gRPC connection was doomed.

Easy fix, right? Update the Docker Compose environment variables:

```yaml
environment:
  - LND_GRPC_ENDPOINT=lnd.dpinkerton.com
  - LND_GRPC_CERT=/etc/ssl/certs/ca-certificates.crt
```

Restarted the container. Same error.

## The Database Always Wins

This is where I lost time. The environment variables were correct. The gRPC connection worked when tested manually from inside the container. But LNbits kept failing.

The culprit was the `system_settings` table in LNbits' SQLite database:

```sql
SELECT id, value FROM system_settings WHERE id LIKE 'lnd_grpc%';
```

```
lnd_grpc_endpoint = "127.0.0.1"
lnd_grpc_cert     = "/app/tls.cert"
lnd_grpc_port     = 10009
```

When the Admin UI is enabled, LNbits persists every setting to this table. From that point on, **database values override environment variables**. Your Docker Compose file becomes decorative. You can change `LND_GRPC_ENDPOINT` all day — LNbits will read `127.0.0.1` from the database and ignore you.

This isn't a bug. It's by design. The Admin UI is meant to be the source of truth once it's active. But if you're used to Docker-style configuration where env vars are king, it's a trap.

## The Fix

Update the database directly:

```python
import sqlite3

conn = sqlite3.connect('/app/data/database.sqlite3')
cur = conn.cursor()

cur.execute(
    "UPDATE system_settings SET value = ? WHERE id = ?",
    ('"lnd.dpinkerton.com"', 'lnd_grpc_endpoint')
)

cur.execute(
    "UPDATE system_settings SET value = ? WHERE id = ?",
    ('"/etc/ssl/certs/ca-certificates.crt"', 'lnd_grpc_cert')
)

conn.commit()
```

Note the double-quoting: the `value` column stores JSON-encoded strings, so the value needs to be `'"lnd.dpinkerton.com"'` — a JSON string inside a SQL string.

Restart the container:

```
✔️ Backend LndWallet connected and with a balance of 5190090000 msat.
LNbits started in 0.28 seconds.
```

You can also fix this through the Admin UI itself if you can log in — go to the funding source settings and update the values there. But if LNbits is stuck on VoidWallet, you might not have a functioning instance to log into, which makes the direct database approach necessary.

## Why the Error Was Misleading

The `'created_time'` KeyError deserves its own explanation because it'll send you down the wrong rabbit hole.

When LNbits connects to LND over gRPC, it uses a TLS certificate you provide as the root CA. If that cert doesn't match what LND is actually serving, the gRPC connection fails. But the failure doesn't surface as a clean TLS error. Instead, it gets caught by a generic exception handler, and the error that bubbles up is a KeyError from somewhere in the gRPC response parsing — in this case, `'created_time'`.

When I changed the endpoint to a hostname that didn't match the cert at all, the error changed to `'grpc_message'` — a different KeyError from a different failure path in the same gRPC internals. Neither error tells you "your TLS certificate is wrong." You have to figure that out yourself.

## Lessons

**Test the connection directly.** Before debugging LNbits config, verify the gRPC connection works from inside the container:

```python
import grpc

cert = open('/etc/ssl/certs/ca-certificates.crt', 'rb').read()
macaroon = open('/app/admin.macaroon', 'rb').read().hex()

creds = grpc.ssl_channel_credentials(cert)
auth = grpc.metadata_call_credentials(
    lambda _, cb: cb([('macaroon', macaroon)], None)
)
channel = grpc.secure_channel(
    'lnd.dpinkerton.com:10009',
    grpc.composite_channel_credentials(creds, auth)
)

from lnbits.wallets.lnd_grpc_files.lightning_pb2 import ChannelBalanceRequest
from lnbits.wallets.lnd_grpc_files.lightning_pb2_grpc import LightningStub

stub = LightningStub(channel)
print(stub.ChannelBalance(ChannelBalanceRequest()))
```

If this works but LNbits doesn't, the problem is in the settings, not the connection.

**Check the database, not just env vars.** If you have the Admin UI enabled, always verify what's actually in `system_settings`:

```bash
docker exec lnbits uv run python3 -c "
import sqlite3
conn = sqlite3.connect('/app/data/database.sqlite3')
cur = conn.cursor()
cur.execute(\"SELECT id, value FROM system_settings WHERE id LIKE 'lnd%'\")
for row in cur.fetchall():
    print(f'{row[0]} = {row[1]}')
"
```

**Don't trust the error message.** If you see `'created_time'` or `'grpc_message'` KeyErrors from LNbits, think TLS first. Check that your cert matches what LND is serving, and that the endpoint hostname matches the cert's SAN.
