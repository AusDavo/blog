---
title: What Should It Cost to Borrow Against Bitcoin?
date: 2026-02-25T21:30:00+10:00
draft: false
tags: []
---
The Bitcoin-backed lending market is growing. Products that let you deposit BTC as collateral and receive fiat or stablecoins — without selling, without triggering capital gains, while maintaining upside exposure — are increasingly common. But how do you know if the interest rate you're being offered is fair?

I think the answer is hiding in plain sight in the futures market. And it leads to a thought experiment that I find genuinely uncomfortable.

## The futures basis rate: the market's answer

Bitcoin futures contracts trade at a premium to the spot price. That premium, annualised, is called the fair basis rate.

Right now, we're in a weak stretch of the market cycle. Bitcoin has pulled back from its highs, sentiment is cautious, and the demand for leveraged long exposure has cooled considerably. You can see this reflected directly in the futures market: the [XBTU26 contract on BitMEX](https://www.bitmex.com/app/contract/XBTU26), expiring in late September 2026, currently carries a fair basis rate of around 4%. That's low by historical standards — during the 2021 bull run, annualised basis rates exceeded 40%.

What does that 4% represent? It's the market's consensus cost of Bitcoin exposure, made visible by the cash-and-carry trade. If you already hold 1 BTC, you can sell a futures contract against it and lock in the basis as risk-free yield. Hold spot, sell futures, pocket the premium. Institutions run this trade constantly, and in doing so, they arbitrage the basis rate toward an efficient equilibrium.

The flip side is just as important: if you *don't* hold BTC and want exposure, you can buy a futures contract instead of buying spot. The cost of that synthetic exposure is the basis premium — currently ~4% annualised.

This is why the basis rate matters for lending. A Bitcoin-collateralised loan gives you cash while maintaining BTC exposure — economically similar to selling your BTC and buying futures. The basis rate sets the market price for that exchange. It moves with sentiment — low in quiet markets, high in euphoric ones — but at any given moment, it's the closest thing to a "correct" price for what Bitcoin-backed loans are trying to sell you.

## A framework for fair lending rates

If the market says maintaining BTC exposure costs 4%, then a Bitcoin-collateralised loan is essentially selling you the same thing — exposure plus cash — with some added features. The interest rate should reflect the basis rate plus a premium for those features:

- **No margin call risk.** Futures positions can be liquidated on a sharp wick. A loan at 50% LTV has much more buffer. That's worth something.
- **Simplicity.** Not everyone can or wants to manage futures positions and rollovers.
- **Term certainty.** A multi-year loan locks in your cost. Rolling futures exposes you to basis rate fluctuation.
- **No tax triggering.** Depending on your jurisdiction, rolling futures may create taxable events.

A reasonable premium for these features might be 2-4%. Which puts a competitive Bitcoin-backed loan rate at roughly **6-8%** in the current environment, perhaps stretching to 10% for long-term, margin-call-free structures.

Any lender charging significantly above that needs to explain what they're offering that the futures market isn't.

## The thought experiment that should bother you

Now here's where it gets interesting — and where I had to confront my own inconsistency.

The basis rate doesn't just tell you what borrowing should cost. It tells you what *holding* costs.

At 4%, the opportunity cost of simply holding spot Bitcoin is modest. Easy to ignore. But cast your mind forward to the next euphoric phase. Bitcoin is ripping. The basis rate has blown out to 20%. Maybe 30%. We've seen it before — in 2021, annualised basis rates exceeded 40%.

Now ask yourself: **would you borrow money at 30% interest to buy Bitcoin?**

Most people — myself included — would say absolutely not. That's insane. No asset justifies a 30% cost of capital.

But here's the thing. If you're holding Bitcoin spot during that same period and *not* executing the cash-and-carry trade (hold spot, sell futures, pocket the basis), you are forgoing that yield. You are choosing to maintain unhedged Bitcoin exposure instead of collecting a risk-free 30% return. You're just not writing a cheque for it, so it doesn't feel like a cost.

The basis rate is the opportunity cost of holding spot. By not harvesting it, you're implicitly paying it.

Let me put that more concretely. Say you hold 2 BTC worth $200,000 and the annualised basis rate is 25%. You could:

**A) Keep holding.** You maintain your 2 BTC of unhedged long exposure. It feels free. It isn't. You're forgoing $50,000/year in basis yield.

**B) Hold your BTC and sell futures against it.** You still own 2 BTC, but your net price exposure is zero — the short futures offset the long spot. In return, you earn $50,000/year in basis yield, practically risk-free. You've turned your volatile Bitcoin position into a 25% yielding instrument.

The difference between A and B is $50,000/year. That's the implicit cost of staying long. If someone offered you a loan at 25% to buy Bitcoin, you'd laugh. But by choosing naked exposure over the cash-and-carry, you're accepting exactly that cost — you just can't see the invoice.

## Why lenders should be sharpening their pencils

With the basis at 4%, Bitcoin lenders have a serious competitive problem — and most of them don't seem to realise it.

The main selling point of a collateralised loan over futures is safety: no margin calls, no liquidation risk. But that advantage evaporates when you consider how futures actually work. A borrower who sells their BTC and buys futures doesn't have to use maximum leverage. They can deposit substantial margin — the same capital they would have locked as loan collateral — and make their futures position practically unliquidatable.

Consider: if you post 50% of the notional value as margin on a long futures contract, you can withstand a 50% drawdown before liquidation. That's the same buffer as a 50% LTV loan. The protection is equivalent — but the cost is 4%, not 10% or 20%.

So the "no margin call" pitch only works on borrowers who don't understand that they can achieve the same safety on a futures exchange by simply not maximising their leverage. That's a shrinking audience.

At a 4% basis rate, lenders should be asking themselves a hard question: **why would anyone borrow from us instead of buying futures?** If the answer is "because they don't know about futures," that's not a durable business model. If the answer is "because we offer genuine convenience and safety worth a premium," then that premium needs to be modest — a few percentage points, not a multiple of the basis rate.

This is the moment for lenders to compete on price. The ones who adjust now will build loan books. The ones who don't will find themselves pitching 15-20% rates to an increasingly educated market that can see the 4% number for themselves.

## Why this matters for borrowers

This framework gives you a simple test for any Bitcoin-backed loan product:

**Is the interest rate meaningfully higher than the current futures basis rate?**

If the basis is at 4% and someone wants to charge you 8%, you're paying a 4% convenience premium. That might be reasonable for a no-margin-call, multi-year term with none of the operational hassle of managing futures.

If they want to charge you 20%, you're paying a 16% premium over the market rate for synthetic exposure. At that point, you should be asking hard questions about what you're getting for that premium — and whether you'd be better off selling spot, buying futures with conservative margin, or even just selling and paying the capital gains tax.

For an Australian holder with long-held BTC, the maths can be stark. Selling $140,000 of BTC triggers a one-off capital gains tax bill of roughly $31,000 at the top marginal rate (after the 50% CGT discount for assets held over 12 months). A 20% loan on the same amount, even with a graduated disbursement structure, can easily cost $50,000+ in interest over its term — and you're locked in for years.

## Why this matters for hodlers

The thought experiment isn't an argument to sell your Bitcoin. It's an argument to be honest about what holding costs, and to make that an active choice rather than a passive default.

When the basis rate is at 3-4%, the opportunity cost of holding spot is low. The premium you'd earn from the cash-and-carry trade is modest, the operational friction is real, and the peace of mind of simply holding is worth something. Holding makes sense.

When the basis rate blows out to 20%+, you should at least feel the discomfort. You are choosing to maintain exposure at a cost that, if presented as a loan rate, you would reject. That doesn't mean you must act — there are legitimate reasons to prefer spot (counterparty risk on derivatives exchanges, tax implications of the trade, the complexity of managing rolls). But you should make that choice with open eyes.

The basis rate is a mirror. It shows you, in precise annualised terms, what the market is charging for the thing you already have. Whether you're evaluating a lending product or just sitting on your stack, it's the number that tells you what your conviction is actually costing.

## The bottom line

A fair rate for borrowing against Bitcoin is the futures basis rate plus a modest premium for convenience, safety, and simplicity. In the current subdued market, with the basis sitting around 4%, that means roughly 6-8%. In a raging bull market with the basis at 15-20%, fair lending rates would be correspondingly higher. The basis moves; the premium above it shouldn't be enormous.

Any product charging dramatically above the prevailing basis rate is either pricing in costs the borrower shouldn't be bearing, or relying on the borrower not knowing where to look.

And any hodler ignoring the basis rate entirely is paying a cost they can't see — one that, during periods of euphoria, can be eye-wateringly high.

The futures market is already telling you the answer. You just have to listen.