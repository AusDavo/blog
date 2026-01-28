---
title: Letting the Market Rebalance My Lightning Channels
date: 2026-01-28T14:30:01+10:00
draft: false
tags: []
---
An experiment in using negative inbound fees and automated fee management to let routing incentives do the work.

## The Setup

I run a small Lightning node with three channels, each around 5M sats capacity. Like many node operators, I found myself with imbalanced channels - some nearly depleted, others stuffed with liquidity. The conventional wisdom says to use circular rebalancing or paid rebalancing services. I wanted to try something different: let the market fix it.

The core idea is simple. If a channel is depleted, make it expensive to drain further and cheap (even profitable for routers) to refill. If a channel is overflowing, make it dirt cheap to drain.

### The Tools

- **charge-lnd**: Automated fee management that adjusts channel fees based on local balance ratios
- **Systemd timers**: Running charge-lnd every 6 hours
- **Custom weekly tuning script**: Analyzes whether channels are actually rebalancing and adjusts the aggressiveness of discounts

### The Fee Policy

I created five tiers based on channel balance:

| State | Local Balance | Outbound Fee | Inbound Fee |
|-------|---------------|--------------|-------------|
| Depleted | <15% | 500 ppm | -300 ppm (discount) |
| Low | 15-35% | 350 ppm | -150 ppm (discount) |
| Balanced | 35-65% | 150 ppm | 0 |
| High | 65-85% | 75 ppm | 0 |
| Heavy | >85% | 25 ppm | 0 |

The key insight: **negative inbound fees** on depleted channels. When someone routes through my node and the payment *enters* through a depleted channel, they get a discount. This should attract traffic that naturally refills my empty channels.

For heavy channels, the outbound fee is near-zero. I'm practically giving away that liquidity to encourage drainage.

## The Rationale

### Why Not Just Rebalance Manually?

Circular rebalancing has costs - you pay routing fees to move your own sats around the network. Sometimes significant fees. And it's artificial; you're fighting the market rather than working with it.

If my channel is depleted because traffic naturally flows in one direction, maybe that's just... the direction traffic flows. Forcing it the other way costs money and may not stick.

### The Market-Based Approach

By offering discounts for "helpful" traffic (traffic that rebalances my channels), I'm:

1. Letting price discovery happen naturally
2. Only paying for rebalancing when someone actually wants to route that direction
3. Making my node more attractive for routes that benefit my liquidity position

If nobody wants to route in a certain direction even at zero cost, that tells me something about network demand. No point forcing it.

### Capital Efficiency Consideration

A depleted channel isn't tying up my capital - the sats are on the peer's side. An overflowing channel *is* tying up my capital. This asymmetry matters when deciding how aggressive to be.

## Initial Results (First 48 Hours)

The early data is encouraging:

- **43 forwarding events**
- **~850 sats in routing fees**
- **~3.1M sats routed through the node**
- **Bidirectional flow observed** on the main routing pair

Most importantly: traffic is flowing in both directions. The depleted channels are seeing some refill traffic, not just continued drainage. The negative inbound fees appear to be working as intended.

The fee breakdown shows the policy in action:
- Traffic draining depleted channels: 17-89 sats per forward (high fees discouraging further drain)
- Traffic refilling depleted channels: 4 sats per forward (cheap, as intended)
- Heavy channel finally routing outbound after being mostly dormant

### A Failed HTLC Tells a Story

I noticed a failed routing attempt - someone tried to route ~21k sats through a channel that only had ~18k available. The channel was too depleted to handle the payment. This is lost revenue and a sign that extreme imbalance has real costs beyond just "aesthetics."

## The Plan Ahead

### Week 1-2: Observation

The weekly tuning script runs every Sunday. It compares channel ratios week-over-week:
- If depleted channels are getting worse despite discounts, increase the discount
- If depleted channels are improving, gradually reduce the discount (no need to give away more than necessary)

The script caps discounts at -500 ppm to avoid going too deep.

### Month 1: Evaluate

Key questions to answer:
- Are channels trending toward balance or staying stuck?
- Is routing volume increasing as the node becomes more competitively priced?
- What's the net revenue after accounting for inbound discounts?

### Longer Term

If a channel remains stuck at extreme imbalance (say, <5% local) for weeks despite maximum discounts, that's a signal. Either:
- The peer's position in the network doesn't generate reverse flow
- The channel should be closed and the capacity redeployed

But I'm not rushing to that conclusion. Markets take time.

## Expectations

### Optimistic Case

Channels gradually drift toward balance. Routing volume increases as the node becomes known for competitive fees in certain directions. The weekly tuning finds an equilibrium discount level. Monthly routing revenue grows.

### Realistic Case

Some channels balance out, others don't. The heavy channel drains to a reasonable level because ultra-low fees attract bargain-hunting routers. The depleted channels partially refill but remain somewhat imbalanced - that's just the natural flow direction. Revenue stays modest but capital efficiency improves.

### Pessimistic Case

Discounts attract no meaningful reverse flow. Channels stay stuck. The depleted channels continue losing the few sats they have left. Eventually close channels and try different peers.

Even the pessimistic case provides valuable information at low cost - I'm not spending sats on circular rebalancing, just foregoing some potential revenue.

## Closing Thoughts

Running a Lightning node profitably is hard. The network is still young, routing demand is unpredictable, and channel management is more art than science.

This experiment is my attempt to let market forces do the heavy lifting. Set the incentives, automate the adjustments, and see what happens. If it works, I've got a low-maintenance node that self-balances. If it doesn't, I've learned something about how traffic actually flows through my corner of the network.

Either way, it's more interesting than manually babysitting channels.

---

*This is an ongoing experiment. I'll update with results after more data accumulates.*
