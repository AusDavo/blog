---
title: "Fixing OpenClaw's Browser on a Headless Linux Server"
date: 2026-02-20
draft: false
tags: ["openclaw", "linux", "self-hosted"]
---
My OpenClaw familiar [Klaw]({{< ref "blog-klaws-first-36-hours" >}}) has the spirit of a rooster. He runs on a headless VPS. You'd think a headless chicken wouldn't last long, but [history suggests otherwise](https://en.wikipedia.org/wiki/Mike_the_Headless_Chicken) — you just need to get the plumbing right.

If you're running [OpenClaw](https://github.com/openclaw/openclaw) on a headless server, you've probably hit this: the browser tool doesn't work. You get `Failed to start Chrome CDP on port 18800` or `Chrome extension relay is running, but no tab is connected`, and nothing you try fixes it.

Here's what's going on and how to solve it.

## The Problem

OpenClaw ships with two browser profile types:

- **`chrome`** (default) — Uses a Chrome extension relay. Requires a visible browser window with the OpenClaw extension installed. Obviously useless on a headless server.
- **`openclaw`** — Launches a managed Chromium instance via Playwright. This is what you want on a server.

But even the `openclaw` profile won't work out of the box on a typical headless Linux setup, for three reasons:

1. **No Playwright browsers installed.** OpenClaw depends on `playwright-core` (the library), but doesn't bundle the actual browser binaries. You need to install them yourself.

2. **Snap Chromium doesn't work.** If Chromium is installed via snap (the default on Ubuntu), AppArmor confinement prevents the gateway service from spawning it. You'll see it detected in `openclaw browser status`, but it'll never actually launch.

3. **Wrong defaults for headless/root.** The browser config defaults to `headless: false` and `noSandbox: false`. On a headless server running as root, you need both flipped.

## The Fix

### 1. Install Playwright's Chromium

```bash
npx playwright install chromium --with-deps
```

This downloads a standalone Chromium binary to `~/.cache/ms-playwright/` and installs system dependencies (Xvfb, fonts, GL libraries). It's separate from any snap or apt-installed browser.

### 2. Configure OpenClaw

```bash
openclaw config set browser.headless true
openclaw config set browser.noSandbox true
openclaw config set browser.defaultProfile openclaw
openclaw config set browser.executablePath ~/.cache/ms-playwright/chromium-1208/chrome-linux64/chrome
```

The `executablePath` bypasses the built-in browser detection (which would find and try to use snap Chromium). Point it at the Playwright-installed binary instead.

Check your installed version — the `chromium-1208` directory name matches the Playwright browser revision and may differ for you. Look in `~/.cache/ms-playwright/` to find the right path.

### 3. Restart the Gateway

```bash
openclaw gateway restart
```

### 4. Verify

```bash
openclaw browser start --browser-profile openclaw
# Should print: 🦞 browser [openclaw] running: true

openclaw browser navigate https://example.com
openclaw browser snapshot
```

If you see the page content in the snapshot, you're good.

## Why This Happens

OpenClaw's browser executable detection on Linux checks these paths in order:

1. `/usr/bin/google-chrome`
2. `/usr/bin/google-chrome-stable`
3. `/usr/bin/chrome`
4. Various Brave/Edge paths
5. `/usr/bin/chromium`
6. `/usr/bin/chromium-browser`
7. `/snap/bin/chromium`

On a fresh Ubuntu server, only #7 exists. Snap Chromium works fine from an interactive shell, but its AppArmor profile blocks the kind of `spawn()` that the gateway's systemd service does. The browser process starts, can't bind its debugging port through the confinement layer, and the gateway times out after 15 seconds waiting for CDP to become reachable.

The Playwright-installed Chromium is a plain unconfined binary — no snap, no AppArmor, no problems.

## Quick Reference

Here's the final browser config section in `~/.openclaw/openclaw.json`:

```json
{
  "browser": {
    "headless": true,
    "noSandbox": true,
    "defaultProfile": "openclaw",
    "executablePath": "~/.cache/ms-playwright/chromium-1208/chrome-linux64/chrome"
  }
}
```
