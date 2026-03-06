---
title: The IPTV Setting That Has Nothing to Do With TV
date: 2026-03-07T08:19:03+10:00
draft: false
tags:
  - nbn
  - network
  - tpg
  - router
---
If you've just spent an hour and a half on the phone with TPG support trying to get a new router working on HFC broadband, and nobody has yet mentioned the IPTV setting — this post is for you.

## How We Got Here

Our previous router, the VX220-G2v TPG supplied when we moved to HFC, had developed an annoying habit of dropping WiFi to certain devices a few times a week. Not catastrophic, just the kind of persistent low-grade friction that eventually tips you into replacing the hardware. So I picked up a TP-Link AX4200.

The timing was awkward. Our NBN connection had been deteriorating for about a week — slower, flakier, harder to pin down. TPG's status page showed an outage. Neighbours were having the same problems. So I knew the NBN was the culprit, not the router, and I held off on the full setup until it was worth attempting.

This morning the status page showed the issue resolved. That was the cue to dig in and get the new router properly connected — with the NBN actually working, I could at least trust what I was seeing.

As a precaution, I'd also installed a Telstra MF833V 4G USB dongle as a failover option. It cost $60, plus $180 for 70GB with a one-year expiry. It's there for emergencies, but at that price per gigabyte I'd rather not lean on it. Getting the NBN connection confirmed and stable was the priority.

## The 90-Minute Call

I called TPG. What followed was one of those troubleshooting sessions that makes you question your life choices.

The quick setup wizard. Didn't work. Hard reset the router. Wizard again. Nothing. Remove the dongle — maybe that's confusing things. Disable dual WAN. Power cycle the NBN modem. Power cycle the router. Power cycle both together. Wait. Try again. Still nothing.

I have genuine sympathy for the TPG tech on the other end. At least I could see the screen. Troubleshooting a router configuration over the phone, talking someone through menus you can't see, on a connection that may or may not be the problem — it's agony for everyone involved. They were patient. I was fraying.

Eventually, buried in the router's Advanced settings, we found it: **Advanced → Network → IPTV/VLAN**. Enabled the IPTV setting. Connection came up immediately.

Ninety minutes. One setting.

## Why That Setting?

I don't have an IPTV service. I'm not watching live TV over the internet. So why did an IPTV setting fix my broadband?

The label is misleading. On TP-Link routers, the IPTV/VLAN section isn't only for TV services — it also controls how the router handles the WAN port and incoming traffic from the NBN box. On some configurations, enabling it is simply what tells the router to correctly manage that connection. Nothing to do with television.

TPG HFC is straightforward on the internet side — plain DHCP, no PPPoE credentials, no special tagging. But the router still needs to know how to handle the port. That's what the IPTV setting does here.

The VX220-G2v never needed this configured because it was TPG's own supplied hardware, pre-configured for their network out of the box. Switch to a third-party router and you're on your own.

## The Short Version

If you're setting up a new router on TPG HFC and can't get a connection:

- Go to **Advanced → Network → IPTV/VLAN**
- Enable the IPTV setting
- Try the connection again

Do that before you call. You're welcome.
