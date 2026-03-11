---
title: You Don't Need a VPN App
date: 2026-03-11T14:00:00+10:00
draft: false
tags:
  - wireguard
  - vpn
  - self-hosting
  - privacy
  - linux
summary: Your Linux machine already has everything it needs to run a VPN — no app required. WireGuard is built into the kernel, and setup takes five minutes.
---

Most VPN providers want you to install their app. It's a branded desktop client with a server picker, a kill switch toggle, and maybe a cartoon map of the world. It works. But on Linux, it's completely unnecessary.

WireGuard has been built into the Linux kernel since version 5.6. Your machine already has everything it needs. One config file, one command, and you're connected — with full integration into your system's network settings. No app, no tray icon, no account dashboard polling in the background.

Here's how it works, and why it's worth knowing about.

## The Setup

Any VPN provider that supports WireGuard will let you generate a config file from their dashboard. TorGuard, Mullvad, IVPN, AzireVPN — they all offer this. You're looking for a WireGuard config generator, usually under your account settings.

The config file looks something like this:

```ini
[Interface]
PrivateKey = <your-private-key>
Address = 10.13.113.109/24
DNS = 10.13.0.1

[Peer]
PublicKey = <server-public-key>
Endpoint = us-server.example.com:51820
AllowedIPs = 0.0.0.0/0
```

That's the entire VPN definition. The `[Interface]` section is your end of the tunnel. The `[Peer]` section is the server. `AllowedIPs = 0.0.0.0/0` means "route everything through this tunnel."

Install the WireGuard tools if you haven't already:

```bash
sudo apt install wireguard
```

Drop the config file into place and bring it up:

```bash
sudo cp ~/Downloads/your-config.conf /etc/wireguard/torguard.conf
sudo wg-quick up torguard
```

That's it. All your traffic is now exiting from a server in another country. Verify at [whatismyipaddress.com](https://whatismyipaddress.com) — you should see the VPN server's location, not yours.

To disconnect:

```bash
sudo wg-quick down torguard
```

## How It Routes Everything

When you run `wg-quick up`, it does something clever. Because `AllowedIPs` is set to `0.0.0.0/0`, it creates a catch-all route that sends all traffic through the WireGuard interface. But WireGuard's own encrypted packets need to reach the real server, so it marks them with a firewall mark (`fwmark`) to bypass the tunnel. Without this, you'd get an infinite loop — tunnelled traffic trying to enter the tunnel.

It also creates a separate routing table so your normal routes aren't disturbed. When you bring the tunnel down, everything is cleanly removed. No residue.

## The System Toggle

Here's the part most people don't know about. You can import the WireGuard config into NetworkManager, and it appears as a regular VPN in your system settings:

```bash
nmcli connection import type wireguard file /etc/wireguard/torguard.conf
```

Now it shows up in your desktop's network panel alongside Wi-Fi and Ethernet. Click to connect, click to disconnect. No app needed — just native OS integration.

If you don't want it connecting automatically on boot:

```bash
nmcli connection modify torguard connection.autoconnect no
```

This is arguably a better experience than most VPN apps. It's faster to connect, uses fewer resources, and integrates with your desktop environment rather than fighting it.

## Why This Matters

The entire WireGuard codebase is roughly 4,000 lines of code. OpenVPN, the protocol most VPN apps have traditionally used, is closer to 100,000. WireGuard was designed by Jason Donenfeld to be as simple and auditable as SSH. It's fast, it's lean, and it's already in your kernel.

When you install a VPN provider's app, what you're mostly getting is a wrapper around this same mechanism — plus a server picker UI, telemetry, auto-update logic, and whatever else they've bundled in. If you already know which server you want, the native approach is lighter and more transparent.

## Be Your Own VPN

This is where it gets interesting. The same WireGuard config that connects you to TorGuard's server can connect you to *your own* server. If you have a cheap VPS — even a $5/month one — you can run WireGuard on it and use it as your exit node.

The setup on the VPS side is straightforward. Install WireGuard, enable IP forwarding, and configure a peer for each device:

```ini
# /etc/wireguard/wg0.conf on your VPS

[Interface]
PrivateKey = <vps-private-key>
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# Your laptop
PublicKey = <your-public-key>
AllowedIPs = 10.0.0.2/32

[Peer]
# A friend
PublicKey = <friend-public-key>
AllowedIPs = 10.0.0.3/32
```

Enable forwarding and bring it up:

```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
sudo systemctl enable --now wg-quick@wg0
```

Now your traffic exits from the VPS's IP address. No VPN company involved. No logs policy to trust — you control the server. And you can add peers for friends or family by generating a key pair and adding another `[Peer]` block.

Each person gets a client config pointing at your VPS:

```ini
[Interface]
PrivateKey = <friend-private-key>
Address = 10.0.0.3/24
DNS = 1.1.1.1

[Peer]
PublicKey = <vps-public-key>
Endpoint = your-vps-ip:51820
AllowedIPs = 0.0.0.0/0
```

A $5 VPS in the US, shared between a few people, costs almost nothing per person and gives you a US exit point that you fully control.

## Choosing a Provider

If you'd rather not run your own server, any WireGuard-compatible VPN provider works with this approach. I use [TorGuard](https://torguard.net), partly because they were one of the first VPN providers to accept payment over Bitcoin's Lightning Network — which aligns with the same ethos of cutting out unnecessary intermediaries. Pay privately for a privacy service.

Most established VPN providers now support WireGuard configs. Check your provider's dashboard — if they offer WireGuard, you can ditch their app today.

## WebRTC: One Thing to Watch

Even with a VPN active, your browser can leak your real IP through WebRTC (the protocol used for video calls and peer-to-peer connections). In Firefox, you can prevent this:

1. Navigate to `about:config`
2. Set `media.peerconnection.enabled` to `false`

This disables WebRTC entirely. If you use browser-based video calls, you'll need to toggle it back on for those sessions.

## The Takeaway

Your Linux machine has a production-grade VPN client built into the kernel. It takes five minutes to set up, integrates natively with your desktop, and works with any WireGuard-compatible provider — or your own server. The app was never necessary.
