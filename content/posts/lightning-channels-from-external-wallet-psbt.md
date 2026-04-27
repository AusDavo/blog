---
title: Opening Lightning Channels Directly From an External Wallet
date: 2026-04-27T20:18:51+10:00
draft: false
tags: []
---
ZEUS published a report this month called *Lightning Economics: The Bridge Between Bitcoin's Two Identities*. The summary line that stopped me:

> "Professionally managed operators report 5-6% gross annualised returns."

ZEUS's own routing node, Olympus, delivers a 5.58% gross ROIC on its routing-allocated capital over the trailing twelve months — broken down as 8.62 bps effective fee rate × 64.7x capital velocity. The report's most useful framing: **static capital bias**. Most analysts model Lightning as a static yield instrument, look at thin per-transaction fees, and conclude the returns are tiny. They miss that the same capital cycles through productive use dozens of times a year. As the report puts it:

> "An 8 basis point fee on capital that turns over 65 times annually is not 8 basis points. It is 520 basis points."

I read it and felt deflated. My node is small, I run it as a hobby, and my mental model has long been "this is lucky to pay for the odd middy." 5-6% sounded like a different sport entirely.

So I ran the numbers.

## What I'm actually getting

I'd recently fixed a real bug in my automated fee-adjustment strategy. The underlying philosophy hasn't changed: I [don't run direct rebalancing](/posts/maximum-aggression-one-week-results/) — no circular payments, no Lightning Pool subscriptions, no paying to move my own liquidity. Instead, I let fee asymmetries induce peers to rebalance me for free. Channels that need outbound liquidity get deep negative inbound discounts (peers can route *into* them cheaper than free); channels that are over-full get cheap outbound *and* a positive inbound penalty (peers should route *out* of them, not into them, and no one should make the over-full state worse). Both halves matter. The earlier posts in that series ([initial setup](/posts/letting-the-market-rebalance-my-lightning-channels/), [cranking it up](/posts/maximum-aggression-liquidity-balancing/), [one-week results](/posts/maximum-aggression-one-week-results/)) describe how I got there.

The bug: LND doesn't accept positive inbound fees by default. There's an `accept-positive-inbound-fees=true` config flag that has to be set explicitly, and I'd never set it. My charge-lnd config had been *trying* to apply positive inbound penalties on the full side of every weekly tune since the strategy was designed, and LND had been silently rejecting every one of them with `positive values for inbound fee rate ppm are not supported`. The discount side worked. The penalty side was a no-op. The asymmetry that's supposed to drive flow was running at half strength.

I added the flag on April 23. The first weekly tune that ran after that, on April 26, was the first time the full strategy actually applied — overloaded channels finally repelling flow they shouldn't accept, on top of the discounts pulling flow through depleted ones.

Curious whether those changes had moved the needle, I pulled forwarding history and on-chain costs week by week.

Annualised, the last four weeks come out to **roughly 3.5% gross**. That's against my deployed routing capital, calculated the same way ZEUS calculates Olympus's headline figure: gross fees divided by deployed channel capacity, annualised.

3.5% is not 5-6%. But it's in the ball park. For comparison, ZEUS's report cites River's passive-node baseline at approximately 1%. I'm running a few times that with no professional infrastructure, no rebalancing pool subscription, and (until very recently) some real flaws in my fee strategy. The gap between 3.5% and 6% feels closeable.

## The demand signal nobody told me about

Then I noticed something else. Four unsolicited channel opens to my node in the last 48 hours. Not channels I requested — peers I'd never heard of opening sizeable inbound capacity to me, unprompted. That hadn't happened in months.

The timing isn't a coincidence. Last week I migrated my reverse-proxy VPS from IONOS (Kansas DC) to Binary Lane (Sydney). The IONOS box had been a quiet thorn — high latency, periodic packet loss, a Tailscale link that kept falling back to DERP relay and never properly stabilised. From my LND node's perspective, my external endpoint was the slow part of every routed payment: every HTLC update, every commitment signature, every channel re-establishment paid that latency tax twice.

The Binary Lane box is in Sydney with a clean public-IP path and stable Tailscale. Latency from any peer in the Asia-Pacific region collapsed. The Tailscale connection went from DERP-relayed to direct. From the network's perspective, my node went from "slow and flaky" to "fast and reliable" overnight.

Routing nodes operated by anyone optimising their channel selection — and that's increasingly automated, with bots actively probing latency and reliability — would notice exactly that change. Four nodes did notice, and they opened to me. That's a strong "we want to route through you" signal.

## So I added liquidity

Encouraged by the return calculation and the demand signal, I decided to add 0.1 BTC of outbound capacity. My node had been heavily inbound-skewed (about 3:1, inbound:outbound), so the new channels were chosen as outbound — me opening *to* peers, not the other way around — split into two 0.05 BTC channels for diversification.

I wanted to do this elegantly: open both channels in a single on-chain transaction, funded directly from my BTCPay Server hot wallet, with no intermediate hop into LND's on-chain wallet.

The mechanism for that is **PSBT channel funding**. LND's `openchannel --psbt` flag lets an external wallet build and sign the funding transaction; LND just generates the channel funding output address and waits for you to provide the signed tx. With multiple channels, you can batch them into one transaction by using `--no_publish` for all but the last.

It took me three hours and three bugs to make it work. Here's the recipe and the failure modes I hit, in case you're attempting something similar.

## The flow, when it works

Each channel needs its own `lncli openchannel --psbt` session, kept alive throughout. tmux is the natural fit:

```bash
# Pane 1 — first channel, will not publish (--no_publish)
lncli openchannel --node_key=PEER1_PUBKEY --local_amt=5000000 --psbt --no_publish

# Pane 2 — second channel, this is the one that broadcasts
lncli openchannel --node_key=PEER2_PUBKEY --local_amt=5000000 --psbt
```

Both commands print a unique funding address and pause waiting for input. You build a single PSBT in your external wallet that pays each funding address, plus change. Submit the **funded but unsigned** PSBT to both panes — each verifies its own funding output exists. Sign in your external wallet. Submit the signed tx (or signed PSBT) to both panes. The pane without `--no_publish` triggers broadcast.

When everything cooperates, this is clean and fast.

## Bug 1: anchor reserve

LND keeps a reserve on its on-chain wallet, roughly 10,000 satoshis per anchor channel, available to fee-bump force-closes. Adding new anchor channels increases the requirement. My LND wallet had 40,000 sats; with eight existing anchor channels, it already wanted 80,000 reserved.

When I submitted the PSBT, LND refused:

```
reserved wallet balance invalidated: transaction would leave insufficient funds 
for fee bumping anchor channel closings (see debug log for details)
```

This check fires even though the PSBT spends from an external wallet — LND looks at the post-state and sees that opening two more anchor channels makes the reserve gap wider, not narrower.

The fix: include a small topup output to a fresh LND address in the same PSBT. I added 300,000 sats to a fresh `lncli newaddress p2tr` output. Same single transaction, just three outputs instead of two, and now the reserve is satisfied. Bonus: you no longer have an LND wallet that's structurally below its own anchor reserve.

## Bug 2: BTCPay's PSBT signer

BTCPay Server v2.3.3 has a quietly broken PSBT signer. When you build a transaction in BTCPay's Send screen, click "Sign transaction", and export the signed PSBT, it produces a PSBT where SegWit (P2WPKH) inputs have signatures placed in `scriptSig` rather than the witness — the legacy P2PKH format. This is invalid for SegWit consensus rules.

LND happily verifies this PSBT (the funding output is correct), accepts the signed version, marks both channels pending, then tries to broadcast. Bitcoin Core rejects:

```
mempool-script-verify-flag-failed (Witness requires empty scriptSig)
```

The pending channels are now in a dead state — LND is waiting for a transaction that can never confirm. Recovery is `lncli abandonchannel --i_know_what_i_am_doing` for each pending channel. No funds are at risk; the funding tx never made it to the mempool.

I went down a rabbit hole on this one. Decoded the bad PSBT — confirmed sigs were in `scriptSig`. Verified the input UTXOs were P2WPKH (matches the wallet's bc1q receive addresses). Audited BTCPay's release notes from v2.3.4 through v2.3.9 (latest as of late April 2026). No mention of any PSBT signing fix. No matching GitHub issue. The bug appears to be in NBitcoin's PSBT signer's input-type detection, surfacing through BTCPay.

The workaround: don't sign in BTCPay. Build the unsigned PSBT in BTCPay (that part works fine), then sign in Sparrow. Or — what I ended up doing — build the whole transaction in Sparrow with the BTCPay wallet loaded.

**Always run `bitcoin-cli testmempoolaccept` on a signed tx before submitting it to LND.** It's the cheapest insurance against landing in this state again. If `allowed: false`, fix the signer; don't feed the bad tx to LND.

## Bug 3: Sparrow gap limit

Loaded the BTCPay wallet's seed into Sparrow, pointed it at my home-server electrs, and... balance showed wrong. Recent BTCPay deposits invisible.

Sparrow's default gap limit is 20 — it scans 20 unused addresses ahead of the last used one before giving up. BTCPay generates a fresh receive address for every invoice; if you've issued more than 20 invoices that didn't all receive payments, recent deposits land on addresses Sparrow stops scanning.

Settings → Advanced → Gap Limit → 200. Sparrow re-scans automatically. (Note for anyone else: that's the Settings panel in Sparrow's *left toolbar*, not the File menu.)

## Gotcha: Sparrow shows signed transactions as raw hex, not PSBT

After signing in Sparrow, the signed result is shown as **raw transaction hex** in a copy-paste text section at the bottom of the GUI — not as a PSBT. The unsigned PSBT *is* a PSBT, exported through Sparrow's normal save mechanism. The signed output is the finalised tx, ready for any consumer that takes raw hex.

That's a perfectly reasonable design — there's nothing left to do with the PSBT once it's signed and finalised, and most consumers want hex anyway. (My early confusion came from saving the copied hex to a file I called `*.psbt`. That was on me, not Sparrow.)

It matters because LND's `openchannel --psbt` flow has two prompts:

1. First prompt wants a **PSBT** specifically. Submit raw hex and it errors with `psbt decode failed: not a PSBT`.
2. Second prompt (after PSBT verification) accepts either signed PSBT or raw hex.

So the working sequence with Sparrow as the signer is:

1. Build tx in Sparrow, save the **unsigned PSBT** (Sparrow's normal export)
2. Submit unsigned PSBT to both LND panes (prompt 1) → verified
3. Sign in Sparrow; copy the **signed transaction hex** from the GUI's text section
4. Submit signed hex to both LND panes (prompt 2) → broadcast

If you do save things to files for staging, a quick sanity check before submitting: `head -c 30 file | xxd` — `psbt` magic bytes mean it's a PSBT (use it for prompt 1), `02000000…` hex means it's a raw tx (use it for prompt 2).

## What it looks like end-to-end

After backtracking from BTCPay's signing bug, the final working flow:

```bash
# 1. Set up tmux with two panes for the openchannel sessions
tmux new-session -d -s lndopen
tmux send-keys -t lndopen "lncli openchannel --node_key=PEER1 --local_amt=5000000 --psbt --no_publish" C-m
tmux new-window -t lndopen
tmux send-keys -t lndopen "lncli openchannel --node_key=PEER2 --local_amt=5000000 --psbt" C-m

# 2. Each pane prints its funding address. Note them.

# 3. Generate an LND topup address for the anchor reserve fix
lncli newaddress p2tr  # save the resulting bc1p... address

# 4. In Sparrow, build a transaction with three outputs:
#    - 0.05 BTC to PEER1's funding address
#    - 0.05 BTC to PEER2's funding address  
#    - 0.003 BTC to LND topup address
#    Sign it. Export unsigned PSBT and signed transaction (separately).

# 5. Submit unsigned PSBT to both lncli panes — both verify their output

# 6. testmempoolaccept the signed transaction:
bitcoin-cli testmempoolaccept '["<rawtxhex>"]'
# Confirm allowed: true before proceeding.

# 7. Submit signed hex to both lncli panes
#    The pane without --no_publish broadcasts.

# 8. Check pending channels:
lncli pendingchannels
```

Both channels show up sharing the same funding txid and different output indices. That's the elegance: one on-chain transaction, two channels, atomic.

## Why bother

The single-tx PSBT approach has three properties the two-step path doesn't:

1. **One on-chain transaction**, not two — fewer bytes paid for in fees.
2. **Atomic**: either both channels open or neither does. No half-state where the funds landed in LND but a channel open then failed for some reason.
3. **Funds never touch LND's on-chain wallet**. For people who keep their funding tightly compartmentalised — multisig hot wallets, HSM-backed wallets, hardware wallets — that property matters.

The cost is operational complexity. The flow has more moving parts: live tmux sessions with timers, two distinct prompts per session, a signed/unsigned PSBT distinction, and an anchor reserve check that doesn't exist in the simpler flow.

For a one-off open with a hot wallet, the two-step approach is honestly simpler. For a routing-node operator who opens channels routinely from a specific funding source, the PSBT path is worth knowing — and once the gotchas are catalogued, it's not much harder than a regular send.

## The nine things I'd hand to someone trying this

1. Use tmux. The `lncli openchannel --psbt` sessions must stay alive across the whole flow, which can take many minutes if you're navigating signer issues.
2. Channel negotiation has a 10-minute peer-side timer. If you blow through it, the open is cancelled and you restart with fresh funding addresses.
3. If LND is short on its anchor reserve, include a topup output for itself in the PSBT.
4. Don't sign in BTCPay. Use Sparrow.
5. Run `testmempoolaccept` on every signed tx before letting LND see it.
6. The lncli prompts are different: prompt 1 is PSBT-only, prompt 2 accepts either format.
7. Sparrow shows signed transactions as raw hex in a copy box, not as a PSBT — that's the format you paste into LND's second prompt.
8. Default Sparrow gap limit of 20 is too low for BTCPay-style use; raise it before importing.
9. Pending channels stuck on a non-broadcastable tx are recovered with `lncli abandonchannel --i_know_what_i_am_doing` per channel — no funds at risk, since the tx never reached the mempool.

## First contact

Update from a few hours later: both channels confirmed at 1.37 sat/vB, show up correctly in Zeus, and the on-chain balance reconciled cleanly in both Sparrow and BTCPay. Then this happened, fast:

| Channel | Local at open | Local 3.5 hours later | Tier classification |
|---|---|---|---|
| Himawari | 5,000,000 (100%) | 4,999,056 (100%) | overloaded |
| LNBiG [Hub-1] | 5,000,000 (100%) | **50,809 (1%)** | critical |

LNBiG drained 99% of the channel within hours of confirmation. That's not background trickle — that's an exchange-class routing operator pulling a one-shot 4.95M sats through me as soon as the channel was usable. Exactly the property I picked them for.

The first scheduled charge-lnd tick after confirmation reclassified both channels correctly:

- Himawari → "overloaded" tier (0 ppm out, +500 ppm inbound penalty — repels further inbound, encourages drainage)
- LNBiG → "critical" tier (3000 ppm out, **−3000 ppm inbound discount** — peers can route into me cheaper than free, making rebalancing happen for free)

The strategy is doing exactly what it's supposed to. Same tune log shows two of my pre-existing channels also self-correcting since the April 23 inbound-fee fix: Babylon-4a moved from depleted all the way to overloaded, and CLB recovered from severely-depleted to depleted. The asymmetric pricing actually drives flow in the direction the channels need.

### The instant-drain gap

There's a discovered gotcha here worth flagging. There's a window between channel confirmation and the first charge-lnd run where new channels sit at LND's defaults — base 1000 msat + 1 ppm outbound. For a normal channel partner that's harmless. For a high-volume routing node like LNBiG, "1 ppm outbound on 5M sats" is an obvious cheap path, and they'll grab the whole thing in minutes. My LNBiG channel emptied for ~5 sats of fee revenue.

It's not exactly a problem — the channel is still usable in both directions, the rebalancing economics now work *better* with one side depleted, and 5 sats of foregone fee on what's a long-term position is rounding error. But for routing-node operators it's worth noting. Options to close that gap:

1. **Manually trigger charge-lnd** right after the channel confirms (`systemctl start charge-lnd.service` for me) — quickest, no automation work
2. **Pre-set fees with `lncli updatechanpolicy`** the moment the channel opens
3. **Add a charge-lnd rule** matching `chan.age < 1h` that applies a defensive default — high outbound, slight inbound penalty — until the real tier classifier takes over on the next cycle
4. **Use LND startup flags** to bias defaults higher node-wide

Option 3 is the cleanest fix for an automated setup. I'll probably build it as a follow-up.

## What I'm watching

May. The Zeus report's static-capital-bias insight is sticky — the difference between a 1% passive node and a 6% professional operator is not better fees or more flow, it's velocity. Velocity comes from positioning, pricing, and the kind of operational hygiene I've been quietly improving over the last few weeks. If the changes I've made — [fee-induced rebalancing](/posts/maximum-aggression-one-week-results/), latency improvement, this liquidity addition — compound, I should see the trailing return drift up from 3.5% toward something closer to ZEUS's 5-6% range. If they don't, that tells me something specific about which of those levers actually moves the number.

3.5% consistently would already be a strong outcome — well above the ~1% passive-node baseline the report cites. Anything above that is gravy.

The capability I documented above is real. The elegance is genuine. The rough edges are mostly tooling that hasn't been exercised hard enough at the layer where external wallets meet LND. Worth doing once just to understand the flow; worth knowing about anytime you'd rather not move funds through an intermediate wallet.

The economics, it turns out, are also more real than I thought.
