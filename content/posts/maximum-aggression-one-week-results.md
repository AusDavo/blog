---
title: "Maximum Aggression: One Week Results"
date: 2026-02-07T12:00:00+10:00
draft: false
---
The results are in. One week of maximum aggression fee policy on my Lightning node. Here's what happened.

## The Baseline

When I [cranked the dial](/posts/maximum-aggression-liquidity-balancing/) on January 29, the channels looked like this:

| Channel | Local Balance | Ratio |
|---------|--------------|-------|
| triple_lightning | 99,335 sats | **1.8%** |
| Babylon-4a | 251,607 sats | **5.0%** |
| CLB | 4,943,843 sats | **98.9%** |

Three channels totalling 15.5M sats of capacity, almost all of it on the wrong side. The fee policy: deep inbound discounts on depleted channels (-2400 ppm), near-free outbound on overloaded ones (1 ppm), hourly updates via charge-lnd, and a weekly auto-tuning script to ratchet fees up or down based on observed movement.

## What Actually Happened

The first 24 hours were dramatic. By January 30:

| Channel | Baseline | Day 1 | Change |
|---------|----------|-------|--------|
| triple_lightning | 1.8% | 6.2% (+238k) | Climbed out of critical |
| Babylon-4a | 5.0% | 24.3% (+963k) | Massive inflow |
| CLB | 98.9% | 74.8% (-1.2M) | Finally draining |

Nearly a million sats flowed into Babylon-4a. CLB shed 1.2 million. The fee incentives clearly worked - someone out there saw the cheap routes and took them.

Then everything stopped.

## The Plateau

Here's the daily picture for the full week:

| Date | triple_lightning | Babylon-4a | CLB |
|------|-----------------|------------|-----|
| Jan 29 (baseline) | 1.8% | 5.0% | 98.9% |
| Jan 30 | 6.2% | 24.3% | 74.8% |
| Jan 31 | 6.2% | 24.3% | 74.8% |
| Feb 1 | 4.0% | 24.3% | 77.3% |
| Feb 2 | 4.0% | 24.3% | 77.3% |
| Feb 3 | 4.0% | 24.3% | 77.3% |
| Feb 4 | 2.2% | 24.2% | 79.2% |
| Feb 5 | 2.2% | 24.2% | 79.2% |
| Feb 6 | 2.2% | 24.2% | 79.2% |
| Feb 7 | 2.2% | 24.1% | 79.2% |

After that initial burst, nothing. Six days of near-total stasis, with a slow drift in the wrong direction. triple_lightning bled back from 6.2% to 2.2%. CLB crept from 75% back to 79%. Babylon-4a held steady - the one clear winner.

## The Auto-Tuner

The weekly tune script ran twice during the experiment:

**January 30:** triple_lightning was worsening, so the tuner escalated its inbound discount from -2400 to -2700 ppm and base from -5000 to -6200 msat. Babylon-4a's depleted tier was *improving*, so the tuner relaxed its discount from -600 to -550 ppm. Correct decisions in both cases.

**February 1:** Everything stable. No adjustments. Also correct - there was nothing to react to.

The auto-tuner worked as designed. The problem wasn't the tuning. It was that nobody was routing through these channels regardless of price.

## Routing Volume

This is the most telling metric:

| Period | Forwards | Fees Earned |
|--------|----------|-------------|
| Week before experiment (baseline) | 49 | 960 sats |
| Experiment week | 4 | 331 sats |

A 92% drop in forwarding events. The aggressive fee structure - high outbound on depleted channels, near-zero on overloaded ones - essentially made my node unattractive as a *through* route while offering discounts that nobody took up.

Those 4 forwards that did happen earned 331 sats. Not bad per-event, but the volume collapse tells the story.

## What I Learned

### Price discovery works - once

The initial burst proved the concept. When I offered deep discounts, someone found them and moved almost a million sats through my channels in one direction. That's real market-driven rebalancing. No circular rebalances, no fee payments to intermediaries, no wrestling with route-finding.

But it was a one-time event. The market moved, found a new equilibrium, and stopped.

### Topology is the bottleneck, not price

With only three channels, my node is a spoke, not a hub. For fee incentives to continuously attract traffic, routing nodes need *options* - multiple paths through my node that compete on price. With three channels, there's essentially one path in each direction. Either someone needs that path or they don't, and no discount changes the graph structure.

This was the prediction I made in the original post: "If routing nodes don't want to send traffic through my channels even with maximum discounts, that's information." The information is: my node position doesn't support sustained bidirectional flow at this scale.

### The strategy is sound, the node is small

I'm not going to do manual rebalancing. Circular rebalances are paying other nodes to move sats around in a circle - it's make-work. If my channels can't attract natural traffic flow, that's a topology problem, and the solution is topology: more channels, better-connected peers, a position in the graph that makes routing *through* me the obvious choice.

The fee policy itself is working correctly. Babylon-4a moved from 5% to 24% and held there. That's a channel that went from critical to depleted through pure market incentives. If I had ten channels instead of three, the odds of finding productive bidirectional flow would be much higher.

### Remote balance isn't "locked up"

It's worth noting: I don't think of the remote-heavy channels as wasted capital. I didn't put that capital there - my channel partners did. triple_lightning's 5.3M sats of remote balance is *their* liquidity pointed at me. If anything, it's inbound capacity I'm getting for free. The only capital I have at risk is my local balance, which at 5.3M sats across all three channels is a reasonable position.

## Current State

As of February 7, here's where things stand:

| Channel | Capacity | Local | Remote | Ratio | Fee Policy |
|---------|----------|-------|--------|-------|------------|
| triple_lightning | 5,485,069 | 119,962 | 5,363,198 | 2.2% | critical: 2000 ppm out, -2700 ppm in |
| Babylon-4a | 5,000,000 | 1,207,453 | 3,790,638 | 24.1% | depleted: 600 ppm out, -600 ppm in |
| CLB | 5,000,000 | 3,959,244 | 1,039,759 | 79.2% | high: 25 ppm out, 0 ppm in |

The charge-lnd timer continues running hourly. The weekly auto-tuner fires every Sunday at 3am.

## What's Next

The experiment answered the question I set out to answer: can pricing alone rebalance a small Lightning node? **Partially.** It works for the initial correction but can't sustain flow through a spoke node.

The path forward is more channels. Not right now - I'll wait for a period when on-chain fees are low and my local liquidity needs topping up anyway. When I do open new channels, I'll be deliberate about peer selection: well-connected nodes that give my node a reason to exist as a routing path, not just a dead end.

The charge-lnd policy and auto-tuner stay in place. They're doing their job. The node just needs a bigger graph to work with.

---

*Experiment started 2026-01-29. Results evaluated 2026-02-07. The automation continues.*
