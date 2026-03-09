---
title: "Don't snap install Bitcoin Core"
date: 2026-03-09
draft: false
---
I asked Claude Code to fix a broken systemd service for Bitcoin Core. It migrated me from the snap to a tarball install, then ran `snap remove bitcoin-core --purge` — which deleted 750 GB of blockchain data that was still stored under `~/snap/`. Nothing was permanently lost, but the blockchain has to be downloaded and validated again from scratch. My Lightning node is offline for a few days while that happens.

Here's what led to it, why the snap is a poor fit for Bitcoin Core, and what to use instead.

## The Setup

I run Bitcoin Core on a dedicated machine. LND on a separate server connects to it via RPC and ZMQ. Electrs indexes the block data over an SSHFS mount. BTCPay Server stores use LND for payments. Real people use this for real transactions.

I originally installed Bitcoin Core as a snap back in 2024. Automatic updates, simple installation, no compiling — it seemed like the sensible choice. I didn't know what I was getting into.

```bash
sudo snap install bitcoin-core
```

It worked. For a while.

## The Problem

The snap doesn't register a systemd service. Running `snap services bitcoin-core` returns "has no services." So I wrote my own systemd unit file to manage it — and it never worked properly.

The snap wrapper (`/snap/bin/bitcoin-core.daemon`) forks the real `bitcoind` into a different cgroup than systemd can track. `Type=forking` fails because systemd can't follow the PID across the snap confinement boundary. The wrapper also exits with code 28 on success, which systemd interprets as failure. The service sat in a crash loop, restarting every 30 seconds, for months.

This isn't a new problem. [Issue #62](https://github.com/bitcoin-core/packaging/issues/62) has been open since February 2021. A [PR to add proper service support](https://github.com/bitcoin-core/packaging/pull/225) has been open since April 2024, still unmerged. One of the Bitcoin Core maintainers commented candidly:

> "I don't think any of the people who work on Bitcoin Core use snaps or are particularly familiar with them. While we provide a snap as a courtesy, they are not particularly well maintained."

## Claude Code Deleted the Blockchain

I asked Claude Code to migrate me from the snap to a tarball install. It installed v30.2, set up the systemd service, and symlinked `~/.bitcoin` to the snap's data directory at `~/snap/bitcoin-core/common/.bitcoin/`. Then it ran `snap remove bitcoin-core --purge` to clean up — not realising the symlink still pointed into the snap's data tree. The `--purge` flag deleted the entire `~/snap/bitcoin-core/` directory, taking 750 GB of blockchain data with it.

The data isn't gone forever — it's the Bitcoin blockchain, it can be downloaded again. But an initial block download on a 2-CPU machine takes a few days, and everything downstream is offline until it finishes.

The underlying issue is that `snap remove --purge` deletes user data stored under `~/snap/<name>/` with no confirmation. When your snap stores three-quarters of a terabyte there, that's a particularly easy mistake to make — whether it's you or an AI agent running the command.

## What Went Offline

Bitcoin Core back at block 0 meant everything downstream stopped:

- **LND** entered "waiting for chain backend to finish sync" — channels went offline
- **Electrs** lost its block data source over SSHFS
- **BTCPay Server stores** using LND couldn't process Lightning payments
- **charge-lnd** couldn't reach LND to manage channel fees

None of this is permanent. Once the blockchain resyncs, LND reconnects to peers and channels come back online. Lightning payments resume. But it's a few days of downtime that didn't need to happen.

## What You Should Use Instead

Install Bitcoin Core from the official tarball. It takes five minutes and gives you a binary that works with the upstream systemd service file the way it's designed to.

**Download and verify:**

```bash
VERSION=30.2
wget https://bitcoincore.org/bin/bitcoin-core-${VERSION}/bitcoin-${VERSION}-x86_64-linux-gnu.tar.gz
wget https://bitcoincore.org/bin/bitcoin-core-${VERSION}/SHA256SUMS
sha256sum --ignore-missing -c SHA256SUMS
tar xzf bitcoin-${VERSION}-x86_64-linux-gnu.tar.gz
sudo install -m 0755 -o root -g root bitcoin-${VERSION}/bin/* /usr/local/bin/
```

**Create a systemd service** at `/etc/systemd/system/bitcoind.service`:

```ini
[Unit]
Description=Bitcoin Core Daemon
After=network-online.target
Wants=network-online.target

[Service]
User=bitcoin
Type=notify
NotifyAccess=all
ExecStart=/usr/local/bin/bitcoind -conf=/home/bitcoin/.bitcoin/bitcoin.conf \
                                  -startupnotify='systemd-notify --ready' \
                                  -shutdownnotify='systemd-notify --stopping'
ExecStop=/usr/local/bin/bitcoin-cli stop
TimeoutStartSec=infinity
TimeoutStopSec=600
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
```

`Type=notify` with `startupnotify` and `shutdownnotify` is the correct integration. Systemd knows exactly when bitcoind is ready to serve RPCs and when it's shutting down. No PID file hacks, no exit code workarounds, no cgroup confusion.

**Enable and start:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now bitcoind.service
```

You get proper process tracking, automatic restart on failure, clean shutdown, and `systemctl status` that actually tells you what's happening.

## Updating

Without the snap's auto-update, you handle updates yourself. This is arguably better for Bitcoin Core — you want to review release notes before upgrading your node, not have it happen silently.

```bash
sudo systemctl stop bitcoind
# Download, verify, and install the new version as above
sudo systemctl start bitcoind
```

## The Lesson

Snaps optimise for easy installation. Bitcoin Core optimises for reliability. These goals conflict when the snap packaging isn't maintained by people who run Bitcoin nodes. The result is a package that installs easily but can't be managed as a service, stores hundreds of gigabytes in a directory that `snap remove` will delete, and hasn't had its service integration merged in two years of waiting.

If you're running Bitcoin Core with anything downstream that depends on it — Lightning, an indexer, a payment server — use the tarball and the upstream systemd unit. It's a few more commands to install, but you won't end up with 750 GB of blockchain data sitting in a directory that a package manager can silently delete.
