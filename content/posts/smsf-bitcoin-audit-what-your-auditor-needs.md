---
title: Your SMSF Holds Bitcoin — What Does Your Auditor Actually Need?
date: 2026-02-20T12:00:00+10:00
draft: false
tags: []
---
If your self-managed super fund holds Bitcoin in self-custody, you will eventually have a conversation with your auditor that goes something like this:

"Can you provide evidence of the fund's Bitcoin holdings?"

What happens next depends on whether you're holding on an exchange or in your own wallet. If you're on an exchange, this is straightforward — the exchange issues a statement, the auditor files it, everyone moves on. The auditor may not love that your super fund holds Bitcoin, but at least the evidence trail looks like something they're used to.

If you self-custody — hardware wallet, multisig, cold storage — there is no statement. There's no institution to call. The Bitcoin sits on a public ledger that your auditor has probably never interacted with, secured by cryptographic keys they've never heard of. And they still need to sign off on it.

This post is about what "sign off on it" actually requires, and why most of what trustees currently provide falls short.

## What the auditor needs to verify

Your SMSF auditor needs evidence of two things:

1. **The Bitcoin exists.** The fund holds a specific amount of Bitcoin at the reporting date (usually 30 June).
2. **The fund controls it.** The fund's trustees actually hold the keys that can spend that Bitcoin.

These are separate questions. A balance on a screen proves neither. An exchange statement proves both — but only for exchange-held assets, and only if you trust the exchange. For self-custody, the trustee has to produce evidence of each independently.

The ATO and ASIC don't prescribe exactly how this evidence must be produced, but they do require it to be adequate. AASB 1056 requires superannuation entities to report assets at fair value. The auditor needs to be satisfied that the asset exists, that the fund controls it, and that the valuation is reasonable.

## What trustees typically provide

In practice, most self-custody SMSF trustees provide some combination of:

- A screenshot of their wallet balance
- A list of Bitcoin addresses pasted into an email
- A signed statutory declaration saying "I hold X Bitcoin"
- A block explorer printout

These are all attestations. The trustee is saying "trust me." The auditor, who likely can't independently verify any of it, either accepts it or pushes back — and most accept it, because there hasn't been a better option.

The problems with this approach:

**Screenshots are trivially fakeable.** Anyone with developer tools in a browser can change a displayed balance. No auditor would accept a screenshot of a bank balance as evidence of a cash holding. Bitcoin shouldn't be different.

**Address lists leak privacy.** Every Bitcoin address has a publicly visible transaction history. Emailing addresses to an auditor — who may store them indefinitely, forward them to colleagues, or look them up on a public block explorer — exposes the fund's entire financial activity on that address. Extended public keys are worse: they reveal every address the wallet has ever used or will use.

**Statutory declarations prove nothing.** A signed declaration is a promise. It carries legal weight if it turns out to be false, but it doesn't provide evidence that the Bitcoin exists or that the signer controls it. It's the weakest form of evidence an auditor can accept.

**Block explorer printouts are unverified.** A printout from blockchain.com shows what that website displayed at a particular moment. It doesn't prove the address belongs to the fund, and the auditor has no way to verify the data is accurate without running their own Bitcoin node.

None of these approaches are independently verifiable. The auditor is trusting the trustee at every step.

## What strong evidence actually looks like

Bitcoin is a system built on cryptographic proof. The irony of the current situation is that trustees are providing the weakest possible evidence for an asset class that supports the strongest.

Strong evidence of Bitcoin holdings has two components:

**Balance derived from the blockchain.** Not a screenshot or a block explorer lookup, but a balance computed by querying the Bitcoin network directly — against a specific block height, at a specific point in time. Anyone with a Bitcoin node and the wallet's public descriptor can reproduce the exact same figure. It's deterministic. There's no discretion or interpretation involved.

**Key control proven via cryptographic signatures.** Bitcoin has a built-in mechanism for proving you hold a private key without revealing it or moving any funds: [message signing](/posts/message-signing-vs-broadcast-transactions/). Each key holder signs a challenge string with their hardware wallet. The resulting signature can be verified by anyone against the corresponding public key. It either passes or it doesn't.

Together, these two pieces of evidence prove that a specific amount of Bitcoin existed at a specific time and that the fund's key holders controlled it. The verification is mathematical. It doesn't depend on trusting the trustee, the auditor, or any third party — including whoever produced the report.

This is a higher standard of evidence than a bank statement. A bank statement is an attestation from an institution — you're trusting the bank to report your balance accurately. A cryptographic proof doesn't require trust in anyone. Any qualified party can verify it independently using open-source tools.

## The AUD valuation

The auditor also needs a fiat valuation. AASB 1056 requires assets to be reported at fair value, and AASB 13 defines fair value as the price in an orderly transaction between market participants.

In practice, this means: the BTC balance multiplied by the AUD closing price on the reporting date, from a recognised pricing source. The source should be named and the date should be stated. An Australian exchange's daily closing price is appropriate.

## What this means for you

If your SMSF holds Bitcoin in self-custody and you're approaching an audit cycle, you have a choice. You can provide your auditor with the same screenshots and declarations that everyone else provides and hope it's enough. Or you can provide evidence that is cryptographically verifiable, independently reproducible, and stronger than what your auditor receives for any other asset in the fund.

I built [CertainKey](https://app.certainkey.com.au) to make the second option easy. It's a self-service tool that walks you through the process: you provide your wallet descriptor, each key holder signs a challenge with their hardware wallet, and CertainKey generates an audit-ready PDF report with the blockchain-derived balance, cryptographic signatures, AUD valuation, and everything your auditor needs to sign off. The whole process takes minutes. No funds are moved, no sensitive data is retained after the report is generated, and every claim in the report can be independently verified.

If you want to see what the output looks like: [example report](https://app.certainkey.com.au/example-report.pdf). There's also a [guide written specifically for auditors](https://app.certainkey.com.au/auditor-guide.pdf) that explains the methodology and how to verify the findings independently — designed to sit alongside the report in your auditor's working papers.
