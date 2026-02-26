---
title: Exchange Statements vs Cryptographic Proof — Why the Evidence Standard Matters
date: 2026-02-26T13:53:00+11:00
draft: false
tags:
  - smsf
  - bitcoin
  - audit
  - certainkey
---
*This is the second post in a series about SMSF Bitcoin audit evidence. The first post, [Your SMSF Holds Bitcoin — What Does Your Auditor Actually Need?](/posts/smsf-bitcoin-audit-what-your-auditor-needs/), covered what auditors need to verify and why most of what trustees currently provide falls short. This post goes deeper into the evidence itself — what makes some forms of evidence stronger than others, and why it matters.*

---

Auditing is fundamentally about evidence. An auditor's job is to assess whether the evidence supporting a claim is sufficient and appropriate. For most financial assets, this is well-trodden ground. Bank statements, share registries, property titles — each comes from a recognised institution with its own governance and reporting obligations. The auditor evaluates the source, assesses the risk, and forms a conclusion.

Bitcoin complicates this. Not because the evidence is weaker — in fact, the opposite is true — but because the evidence looks unfamiliar. And when something looks unfamiliar, the tendency is to fall back on whatever feels closest to normal.

This post walks through the evidence hierarchy for Bitcoin holdings, from weakest to strongest, and explains why the strongest form — cryptographic proof — is not only available today but is a higher standard than what auditors receive for almost any other asset in a fund.

## The evidence hierarchy

Not all evidence is created equal. For Bitcoin held in an SMSF, the evidence available to an auditor ranges from essentially meaningless to mathematically certain. It is worth understanding where each form sits.

### Screenshots and printouts

At the bottom of the hierarchy are screenshots of wallet balances and printouts from block explorer websites. These are visual records of what a screen displayed at a particular moment. They prove nothing. A screenshot can be altered in seconds with browser developer tools. A block explorer printout shows what a third-party website reported, but the auditor has no way to verify the data is accurate, nor to confirm the address belongs to the fund.

No auditor would accept a screenshot of an online banking portal as evidence of a cash balance. The same standard should apply to Bitcoin.

### Trustee declarations

A signed statutory declaration — "I, as trustee, declare that the fund holds X Bitcoin at the following addresses" — carries legal weight. If the declaration turns out to be false, there are consequences. But a declaration is a statement of fact by an interested party. It is an attestation, not evidence. The auditor is trusting the trustee to report accurately, with no independent means of verification.

Declarations are a necessary part of the audit process for many things, but they sit near the bottom of the evidence hierarchy when used as the primary proof that a digital asset exists and is controlled by the fund.

### Exchange statements

Exchange statements are the standard that most auditors are comfortable with, and for good reason. An exchange statement is an institutional attestation. The exchange is a regulated entity (in Australia, registered with AUSTRAC) confirming that a customer holds a specific balance. It looks and feels like a bank statement, and auditors know how to work with it.

For exchange-held Bitcoin, this is perfectly adequate. The exchange acts as custodian, the statement confirms the holding, and the auditor can file it alongside the fund's other third-party confirmations.

But it is worth understanding what an exchange statement actually is. It is not independent verification. It is the exchange telling you what its internal database says. The auditor is trusting the exchange to report accurately — trusting its systems, its internal controls, and its solvency.

For most regulated exchanges, this trust is reasonable. But it is trust nonetheless. And for the most part, Australian crypto exchanges do not produce GS007 or ASAE 3402 reports — the assurance reports that auditors typically rely on when evaluating controls at a third-party service organisation. The auditor is accepting the statement at face value, without the independent assurance framework that exists for banks and major custodians.

This is not a criticism of exchange statements. It is an observation about where they sit in the evidence hierarchy: above declarations, below independent verification.

The FTX collapse in 2022 is the starkest demonstration of what happens when trust-based evidence fails. Customers had account balances. They had statements. They had holdings confirmed by the exchange's own systems. The assets did not exist. FTX's internal records bore no relationship to its actual reserves. The trust model — customers trusting the exchange to accurately report their holdings — broke down completely.

FTX was an extreme case, and it would be wrong to tar all exchanges with the same brush. But it demonstrated a structural limitation: when the evidence is an institution telling you what it holds on your behalf, the evidence is only as good as the institution.

### Cryptographic proof

At the top of the hierarchy sits cryptographic proof: evidence that is independently verifiable, mathematically certain, and does not require trust in any party.

Cryptographic proof of Bitcoin holdings has two components, each addressing one of the auditor's core questions.

**Does the Bitcoin exist?** The Bitcoin blockchain is a public ledger maintained by tens of thousands of nodes worldwide. The balance of any wallet at any point in time is a deterministic fact — it is computed directly from the blockchain data. Given a wallet descriptor (a standardised text string that defines which keys control a wallet), any party running a Bitcoin node can compute the exact balance at a specific block height. There is no ambiguity, no discretion, no interpretation. Two different people querying two different nodes on opposite sides of the world will get the same number. The balance is not an assertion. It is a mathematical fact derived from a public dataset.

**Does the fund control it?** Bitcoin's cryptography includes a mechanism for proving you hold a private key without revealing it or moving any funds: message signing. A key holder takes a challenge string — an arbitrary message, often including the date and the purpose of the verification — and signs it with their private key using their hardware wallet. The resulting digital signature can be verified by anyone who has the corresponding public key. Either the signature is valid or it is not. There is no grey area, no judgement call, no room for fabrication.

For multisig wallets, each key holder signs independently with their own key. This actually provides stronger assurance than a spending transaction, which only proves that enough keys to meet the signing threshold are present — not that every key holder has access.

## Why this standard matters

The distinction between trust-based and verification-based evidence is not academic. It changes what the auditor is actually signing off on.

When an auditor accepts an exchange statement, they are forming a conclusion based on trust in a third party. When an auditor accepts a cryptographic proof, they are forming a conclusion based on mathematics that they — or any qualified party — can independently verify.

This is not a novel or experimental standard. It is the same standard that underpins digital signatures in commercial law, TLS certificates that secure every online banking session, and the Bitcoin network itself. Every time you see the padlock icon in your browser, you are relying on the same cryptographic principles. Every time a court accepts a digitally signed document, it is accepting the same form of evidence. Cryptographic verification is one of the most battle-tested proof mechanisms in modern technology.

The difference is that for Bitcoin audit evidence, the tools to apply this standard have not been widely available — until recently.

## The self-custody gap

For exchange-held Bitcoin, auditors at least have something familiar: a statement from an institution. It is trust-based, but it is structured and recognisable.

For self-custody Bitcoin — hardware wallets, multisig, cold storage — auditors do not even get that. There is no institution to produce a statement. What they receive instead is typically a combination of trustee declarations and screenshots. The auditor is left relying on the weakest forms of evidence for an asset class that supports the strongest.

This is the gap that cryptographic proof fills. It gives auditors working with self-custody Bitcoin evidence that is not only stronger than declarations and screenshots, but stronger than the exchange statements they accept for custodied holdings. The balance is derived from the blockchain, not from a screenshot. The key control is proven with digital signatures, not with a statutory declaration.

## What independent verifiability means in practice

A CertainKey report includes everything needed for an auditor — or any third party — to reproduce and verify each claim independently:

- The wallet descriptor, from which the balance can be recomputed using any Bitcoin node
- The block height and timestamp of the balance snapshot
- The challenge strings and cryptographic signatures, which can be verified using Bitcoin Core's `verifymessage` command or open-source tools like Sparrow Wallet
- The AUD valuation source and date

The report does not require trust in CertainKey. If CertainKey disappeared tomorrow, the evidence in the report would still be verifiable. This is deliberate. Audit evidence should not depend on the continued existence of the entity that produced it.

An [auditor guide](https://app.certainkey.dpinkerton.com/auditor-guide.pdf) is available that explains the verification process in plain language, designed to sit alongside the report in audit working papers.

## The bar can be higher

This post is not an argument that exchange statements are bad or that auditors who accept them are doing something wrong. Exchange statements are the accepted standard, and for exchange-held assets, they work.

The argument is simpler than that: the bar can be higher. The tools exist to produce Bitcoin audit evidence that is independently verifiable, mathematically certain, and does not depend on trusting any institution — including the one that produced the report. For self-custody holdings, where auditors currently rely on declarations and screenshots, this is not just a higher standard. It is the first real standard.

For an asset class built entirely on cryptographic proof, it is the evidence standard that should have existed from the beginning.

---

*Every claim in a CertainKey report can be independently verified using open-source tools. No reliance on CertainKey or any single institution. See for yourself: [example report](https://app.certainkey.dpinkerton.com/example-report.pdf).*

*This is the second post in a series on SMSF Bitcoin audit evidence. The first post covers [what your auditor actually needs](/posts/smsf-bitcoin-audit-what-your-auditor-needs/).*
