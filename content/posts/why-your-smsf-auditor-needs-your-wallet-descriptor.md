---
title: Why Your SMSF Auditor Needs Your Wallet Descriptor
date: 2026-03-03T18:00:00+11:00
draft: false
tags: []
---
An SMSF auditor recently reviewed a CertainKey report — the standard version, which includes a cryptographic proof of holdings but withholds the wallet descriptor for privacy. Their response was instructive:

> 1. Is this product audited? I doubt it. If it doesn't have the equivalent of a GS007 audit report then GS009 says, I cannot rely on it alone without a Part A qualification or sourcing additional evidence.
>
> 2. If I can independently verify the holding balances using information that is either publicly available or can be obtained from the blockchain, which appears to be possible based on this report, then I should be able to rely on that.

Two sentences. The entire regulatory argument distilled. Let me unpack what they're saying and why it matters for every SMSF that holds Bitcoin in self-custody.

## The auditor's dilemma

When an SMSF auditor receives a report from a third party — any third party — they need to decide: can I rely on this?

The answer depends on the standards. The relevant ones are ASA 500 (Audit Evidence), ASA 402 (Service Organisations), and AUASB GS 009 (Auditing Self-Managed Superannuation Funds). Together, they create a framework that the auditor in question applied instinctively: if you can't independently verify the evidence, you need to evaluate the provider. And if the provider hasn't been audited to ASAE 3402 (the standard for service organisation assurance reports), you can't rely on them without qualification or additional evidence.

CertainKey doesn't have an ASAE 3402 Type 2 report. Neither does any other Bitcoin verification service. So from the auditor's perspective, a report from CertainKey that they can't independently verify is functionally equivalent to a custodian statement from an unaudited custodian — they'd need to qualify Part A or find other evidence.

But here's where Bitcoin is different from every other asset class: the evidence is publicly available on the blockchain. The auditor doesn't need to trust CertainKey, or the trustee, or anyone else. They just need the right key to unlock the data.

That key is the wallet descriptor.

## What the descriptor actually is

A wallet descriptor is a compact string that encodes everything needed to derive a wallet's addresses. For a multisig wallet, it contains:

- The extended public keys (xpubs) for each signer
- The derivation paths used to generate addresses
- The quorum configuration (e.g., 2-of-3)
- The script type (e.g., native SegWit)

With the descriptor and access to a Bitcoin node (or compatible wallet software like Sparrow Wallet), anyone can:

1. Derive every address the wallet has ever used or will use
2. Query the blockchain for balances at any historical block height
3. Verify the wallet's total holdings at a specific point in time

Without the descriptor, the auditor has a report that says "the balance was X at block height Y" — but no way to confirm that independently. They're trusting whoever produced the report.

## What the regulations actually say

The framework is principles-based — there's no single sentence saying "the SMSF auditor must obtain the wallet descriptor." But the principles are clear and they all point in one direction.

### ASA 500: Direct evidence beats indirect evidence

Paragraph A31 of ASA 500 establishes a hierarchy of audit evidence reliability. Two of the five generalisations are directly relevant:

> "The reliability of audit evidence is increased when it is obtained from independent sources outside the entity."

The Bitcoin blockchain is about as independent as it gets. No single party controls it. The data is publicly verifiable. A balance queried from a full node is not an attestation — it's a mathematical fact.

> "Audit evidence obtained directly by the auditor is more reliable than audit evidence obtained indirectly or by inference."

This is the critical provision. An auditor who has the wallet descriptor can query the blockchain directly. An auditor who has only a hash must rely indirectly on CertainKey's attestation. ASA 500 is explicit about which is preferable.

Paragraph 7 reinforces this with a mandatory requirement: the auditor "shall consider the relevance and reliability of the information to be used as audit evidence, including information obtained from an external information source." A CertainKey report is an external information source. The auditor has an affirmative obligation to evaluate its reliability — they cannot simply accept it at face value.

### ASA 402: The service organisation problem

If CertainKey is treated as a service organisation (which it is, functionally), ASA 402 applies. The auditor needs to evaluate CertainKey's controls and may need an ASAE 3402 Type 2 report to rely on the service.

GS 009 — the SMSF-specific guidance — makes this concrete:

- **Paragraph 141:** A Type 1 report "cannot be relied on to reduce the level of substantive audit testing."
- **Paragraph 142:** Type 2 reports "may be used in some circumstances to reduce the level of substantive testing."
- **Paragraph 143:** When custodians lack ASAE 3402 reports, "the SMSF auditor may need to conduct additional procedures."

CertainKey has no Type 2 report. So the auditor "may need to conduct additional procedures." The wallet descriptor is the additional procedure — it eliminates the need to rely on CertainKey at all, because it gives the auditor a path to the blockchain, which is the primary source.

### ATO guidance: Statements alone are not sufficient

The ATO has published specific guidance for SMSF auditors on crypto assets. One provision stands out:

> "Holding statements or investment summaries alone are not sufficient to confirm market value. You must obtain additional objective, supportable evidence."

A CertainKey report without the descriptor is, functionally, a holding statement. It states the balance. It doesn't enable the auditor to verify it. The ATO expects "additional objective, supportable evidence." The blockchain is objective and supportable — but only if the auditor has the descriptor to query it.

The ATO also explicitly addresses custody:

> When crypto is held by a custodian, "you should obtain a Type 2 report if available and perform further substantive testing to confirm the holding statement is correct."

Note the "and" — even with a Type 2 report, substantive testing is expected. For self-custody Bitcoin, the descriptor enables that substantive testing.

### The qualification risk

If an auditor cannot verify that a crypto asset exists, belongs to the fund, or is reported at market value, the ATO requires them to qualify both Part A and Part B of the audit report. An auditor with only a hash and no way to independently verify is at real risk of needing to qualify. An auditor with the descriptor can avoid qualification entirely by performing their own verification.

## The privacy tradeoff

The descriptor reveals all wallet addresses and the complete on-chain transaction history. This is a legitimate privacy concern and the reason CertainKey initially withheld it by default.

But consider the audience. The report goes to the trustee and their appointed auditor — both of whom have fiduciary and professional obligations around confidentiality. The auditor already sees the fund's bank statements, tax records, and investment portfolio. The descriptor is arguably less sensitive than much of what they already receive.

The appropriate mitigation is not withholding the evidence, but framing the sensitivity correctly. The descriptor should be treated with the same confidentiality as a bank account number — it doesn't enable spending, but it does enable surveillance. CertainKey's enhanced reports now include a confidentiality notice to this effect in both the Note to Auditors section and the appendix containing the descriptor.

## What this means in practice

CertainKey now includes the wallet descriptor and cryptographic signatures by default. Customers can still opt out for privacy, but they should understand what that means: their auditor will need to either trust CertainKey's attestation (which requires evaluating CertainKey as a service organisation, which CertainKey cannot currently support with a Type 2 report) or source additional evidence independently.

For most SMSF audits, the enhanced report — with the descriptor included — is the only version that gives the auditor everything they need to sign off without qualification. The standard report is available for trustees who have a specific privacy requirement and are prepared to work with their auditor to satisfy the evidence requirements through other means.

The auditor who reviewed our report understood this immediately. Their second point said it all: "If I can independently verify the holding balances using information that is either publicly available or can be obtained from the blockchain, then I should be able to rely on that."

The descriptor is what makes that possible.

## References

- **ASA 500** — Audit Evidence (December 2022), particularly paragraph 7 (mandatory reliability evaluation) and paragraph A31 (hierarchy of evidence reliability)
- **ASA 402** — Audit Considerations Relating to an Entity Using a Service Organisation (December 2023)
- **ASA 505** — External Confirmations (December 2021)
- **AUASB GS 009** — Auditing Self-Managed Superannuation Funds (June 2020), particularly paragraphs 141–144 on service organisations
- **ATO** — Auditing SMSFs with Crypto Assets
- **ASAE 3402** — Assurance Reports on Controls at a Service Organisation
