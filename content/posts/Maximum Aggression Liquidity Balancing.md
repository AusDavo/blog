---
title: "Maximum Aggression: Cranking Up the Lightning Liquidity Experiment"
date: 2026-01-29T21:30:00+11:00
draft: false
tags: []
---
A follow-up on the market-based rebalancing experiment. This time, we're not holding back.

## Previously

In my [last post](/posts/letting-the-market-rebalance-my-lightning-channels/), I set up an automated fee policy using charge-lnd to let market forces rebalance my Lightning channels. The approach was conservative: -300 ppm inbound discounts for depleted channels, 25 ppm for heavy ones. Early results were promising - bidirectional flow, 43 forwards in 48 hours, channels starting to move in the right direction.

But "starting to move" isn't the same as "balanced." After a week, the situation is stark:

| Channel | Local Balance | Ratio |
|---------|---------------|-------|
| triple_lightning | 99,335 sats | **1%** |
| Babylon-4a | 251,607 sats | **5%** |
| CLB | 4,943,843 sats | **98%** |

Two channels critically depleted. One overflowing. The conservative approach isn't cutting it fast enough.

Time to crank the dial.

## The Maximum Aggression Config

The original policy had five tiers. The new one has seven, with much more extreme values:

| State | Local Balance | Outbound Fee | Inbound Discount |
|-------|---------------|--------------|------------------|
| **Critical** | <10% | 5000 base / 1000 ppm | -5000 base / **-2400 ppm** |
| Severely Depleted | 10-20% | 2500 base / 600 ppm | -2500 base / -1200 ppm |
| Depleted | 20-35% | 1000 base / 350 ppm | -1000 base / -600 ppm |
| Balanced | 35-65% | 500 base / 100 ppm | -250 base / -100 ppm |
| High | 65-80% | 100 base / 25 ppm | 0 |
| Heavy | 80-90% | 0 base / 10 ppm | 0 |
| **Overloaded** | >90% | 0 base / **1 ppm** | 0 |

The key changes:

1. **Maximum inbound discount**: -2400 ppm on critical channels. This is aggressive - I'm paying routers 2400 ppm to send traffic INTO my depleted channels. That's 0.24% of the payment amount as a subsidy.

2. **Near-zero outbound on overloaded**: 1 ppm on CLB. Essentially free routing. Any bargain-hunter pathfinding algorithm should love this.

3. **More granular tiers**: Added "critical" (<10%) and "overloaded" (>90%) for extreme cases. These channels need extreme measures.

4. **Balanced channels get a small discount too**: Even the healthy 35-65% range now offers -100 ppm inbound. Keep the good times rolling.

## The Timer Debate

Originally, charge-lnd ran every 6 hours. I briefly changed it to 30 minutes, then thought better of it.

The problem: **gossip propagation**. When you update channel fees, that information needs to spread across the Lightning Network via gossip. This takes time - typically 10-30 minutes to reach most nodes. If you change fees faster than gossip can propagate:

- Routing nodes have stale fee data
- Payments fail unnecessarily
- Some pathfinding algorithms penalize "unstable" channels

The compromise: **1 hour**. Fast enough to react to significant liquidity shifts, slow enough for the network to keep up.

```
[Timer]
OnBootSec=2min
OnUnitActiveSec=1h
Persistent=true
```

## What I'm Watching

### The Hypothesis

If moderate discounts attract *some* reverse flow, maximum discounts should attract *more*. There's presumably a price at which it becomes profitable for routing nodes to specifically seek out paths through my discounted inbound channels.

At -2400 ppm, a 100k sat payment entering my depleted channel gives the router a 240 sat rebate. That's not nothing.

### The Risks

**Over-subsidization**: Am I giving away more than the rebalancing is worth? If I had to pay for circular rebalancing, what would it cost? Probably 500-2000 ppm depending on the route. So -2400 ppm isn't crazy - it's roughly competitive with what I'd pay anyway, except I only pay when someone actually *wants* to route that direction.

**Attracting low-quality traffic**: Ultra-cheap routing might attract probe traffic or payments that don't represent real economic activity. Though arguably, sats are sats - my channel doesn't care why it's being refilled.

**The CLB channel**: At 1 ppm, I'm practically donating routing capacity. If nobody wants to route through it even at this price, that tells me something about network topology. Maybe that peer isn't well-positioned for the traffic patterns I'm seeing.

### Metrics to Track

I've set up hourly logging to capture:
- Channel balances over time
- Forwarding events per hour
- Fees earned (or subsidies paid)
- Which direction traffic flows

The goal is to see whether the depleted channels actually improve, or whether they're structurally stuck regardless of incentives.

## Early Observations

Within minutes of applying the new config:

```
triple_lightning: base_fee_msat 2000 → 5000, fee_ppm 750 → 1000, inbound_fee_ppm -600 → -2400
Babylon-4a: base_fee_msat 1000 → 5000, fee_ppm 500 → 1000, inbound_fee_ppm -300 → -2400
CLB: base_fee_msat 250 → 0, fee_ppm 25 → 1
```

Now we wait.

The true test will be whether the ratio percentages change over the coming days. If triple_lightning climbs from 1% to even 10%, that's 500k sats of natural rebalancing I didn't have to pay for directly.

## The Philosophical Angle

There's something satisfying about this approach. Instead of fighting the market with forced circular rebalancing, I'm setting up incentives and letting participants make their own decisions.

If routing nodes don't want to send traffic through my channels even with maximum discounts, that's information. It means either:
1. My node's position in the graph doesn't make sense for reverse flow
2. The discounts aren't visible/trusted yet (gossip lag, pathfinding caches)
3. There simply isn't demand for routing in that direction at any price

All of those are useful to know. And I learn them for free - or rather, I learn them by *not* paying for artificial rebalancing.

## What's Next

I'll let this run for a week and report back. The hourly logging will show whether there's any meaningful change in channel ratios.

If after a week the channels are still stuck at 1% / 5% / 98%, I'll know that price isn't the bottleneck. At that point, the question becomes: are these channels worth keeping, or should that capital be deployed elsewhere?

But I'm not there yet. Maximum aggression first. Data second. Conclusions third.

---

*Baseline recorded 2026-01-29. Check back for results.*
