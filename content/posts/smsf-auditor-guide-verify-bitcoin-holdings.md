---
title: "A Guide for SMSF Auditors: How to Verify Bitcoin Holdings Without Being a Cryptographer"
date: 2026-03-08T21:00:00+11:00
draft: false
tags:
  - smsf
  - bitcoin
  - audit
  - certainkey
---
*This is the fifth and final post in a series about SMSF Bitcoin audit evidence. The [first post](/posts/smsf-bitcoin-audit-what-your-auditor-needs/) covered what auditors need to verify. The [second](/posts/exchange-statements-vs-cryptographic-proof/) compared evidence standards. The [third](/posts/smsf-bitcoin-self-custody-regulatory-pressure/) covered the regulatory pressure making this urgent. The [fourth](/posts/why-your-smsf-auditor-needs-your-wallet-descriptor/) explained why auditors need the wallet descriptor.*

---

You've received a CertainKey report in an audit file. Maybe the trustee sent it unprompted. Maybe their accountant attached it. Either way, you're looking at a document full of terms like "wallet descriptor," "block height," and "BIP-322 message signature" — and you need to decide whether it's sufficient evidence.

It is. And you don't need to understand Bitcoin to rely on it. But here's enough context to know exactly what you're signing off on.

## What Bitcoin actually is (one paragraph)

Bitcoin is a public ledger maintained by tens of thousands of computers worldwide. Every transaction ever made is recorded on this ledger. Nobody controls it. Nobody can alter it retroactively. The balance at any address, at any point in time, is a deterministic fact — not an assertion by a counterparty. This is what makes Bitcoin fundamentally different from every other asset class you audit: the evidence comes from a public, tamper-proof source, not from an institution that could misrepresent it.

## What a CertainKey report proves

The report establishes two things:

**1. The fund holds the Bitcoin it claims to hold.**

The report states a balance in BTC at a specific block height (a point-in-time snapshot of the blockchain, analogous to a bank statement date). This balance is derived by querying the Bitcoin blockchain directly — not by asking the trustee or any intermediary.

**2. The fund's trustees control the keys to that Bitcoin.**

Each key holder signs a cryptographic challenge with their private key. This proves they possess the key without revealing it and without moving any funds. It's the digital equivalent of a bank requiring a signature specimen — except the signature is mathematically verifiable rather than visually compared.

For multisig wallets (where multiple key holders are required to authorise transactions), the report shows which individuals signed, their roles (Director, Trustee, Member), and whether the required quorum was met.

## What the report contains

A typical CertainKey report includes:

- **Entity details** — fund name, ABN, trustees
- **Verification date** — the block height and corresponding date/time
- **Balance** — total BTC held, derived from the blockchain
- **AUD valuation** — fiat value at the verification date, with the pricing source identified
- **Key control evidence** — which key holders signed, their roles, signature validity
- **Quorum assessment** — whether the spending threshold was met or exceeded
- **Overall verification result** — Pass or Fail
- **Wallet descriptor** — the technical key that enables independent verification (explained below)
- **Note to Auditors** — maps each finding to the relevant auditing standards

## The wallet descriptor: your path to independent verification

The wallet descriptor is a compact text string that defines which keys control a wallet and how addresses are derived from them. Think of it as a read-only account number — it lets you see everything in the wallet but doesn't let you spend anything.

With the descriptor, you (or your firm's IT team, or any competent third party) can:

1. Derive every address the wallet has ever used
2. Query the blockchain to confirm the balance at any historical date
3. Verify that the balance in the report matches what the blockchain shows

This is the critical point: **you don't need to trust CertainKey**. The descriptor gives you a direct path to the primary source — the blockchain itself. This satisfies ASA 500's preference for evidence obtained directly by the auditor from independent sources (paragraph A31).

Without the descriptor, you'd be relying on CertainKey's attestation. With it, you're performing your own substantive procedure using public data. The distinction matters for your working papers.

If a client provides a CertainKey report without the descriptor, ask for it. The [third post in this series](/posts/why-your-smsf-auditor-needs-your-wallet-descriptor/) explains the regulatory reasoning in detail.

## How to verify the report's authenticity

Every CertainKey report is hashed at generation using SHA-256. To confirm a report hasn't been altered:

1. Go to [app.certainkey.dpinkerton.com/verify](https://app.certainkey.dpinkerton.com/verify)
2. Drop the PDF onto the page
3. The page computes the hash locally — the file never leaves your browser
4. If the hash matches the stored record, the report is authentic

This takes ten seconds and confirms you're looking at the original document, not a modified version.

## How to independently verify the claims (if you want to go further)

You don't have to do this. The report and verification page may be sufficient for your purposes. But if you want to confirm the findings yourself — or if your firm's methodology requires it — there are two independent things you can check: the balance and the signatures. They address different audit assertions (existence/valuation and ownership/control respectively) and use different tools.

### Verifying the balance

The report states a BTC balance at a specific block height. To confirm this independently, you need the wallet descriptor from the report and access to the Bitcoin blockchain.

**Using Sparrow Wallet (graphical, no command line):**

[Sparrow Wallet](https://sparrowwallet.com) is free, open-source Bitcoin wallet software that runs on Windows, Mac, and Linux. You don't need to hold any Bitcoin to use it for verification.

1. Open Sparrow Wallet
2. Create a new wallet → choose "Import"
3. Paste the wallet descriptor from the report
4. Sparrow derives all addresses and queries the blockchain for balances
5. Compare the total balance against the report

This gives you an independent figure derived from the same public data, using software that has no relationship to CertainKey.

**Using any Bitcoin node:**

The blockchain is public. Any full node — whether run by your firm, a data analytics provider, or a public block explorer — can confirm the balance at the stated block height. The data is the same everywhere because it's a shared, immutable ledger.

### Verifying the signatures

The report includes cryptographic signatures proving each key holder controls their key. These are separate from the balance — a valid signature proves the person signed the challenge, regardless of how much Bitcoin the wallet holds.

**Using Bitcoin Core (command line):**

The report includes instructions for using Bitcoin Core's `verifymessage` command. For each signature in the report, the command takes the signer's address, the challenge message, and the signature, and returns `true` or `false`. Bitcoin Core is the reference implementation of Bitcoin, maintained by hundreds of developers worldwide.

**Using Sparrow Wallet:**

Sparrow can also verify message signatures via Tools → Verify Message. Paste in the address, message, and signature from the report. No command line required.

## How this maps to the auditing standards

The Note to Auditors section in each report maps specific findings to the relevant standards. Here's the summary:

| Standard | What it requires | How the report satisfies it |
|---|---|---|
| **ASA 500** (Audit Evidence) | Relevant, reliable evidence; preference for independent, direct sources | Balance derived from public blockchain; signatures independently verifiable; descriptor enables direct auditor verification |
| **ASA 402** (Service Organisations) | Evaluate controls of service organisations, or obtain ASAE 3402 report | Descriptor eliminates reliance on CertainKey — auditor can verify directly, bypassing the service organisation question |
| **GS 009** (Auditing SMSFs) | Substantive testing of investment existence and valuation | Balance at block height = existence; AUD valuation with identified source = valuation; key control signatures = ownership |
| **ATO Crypto Guidance** | "Additional objective, supportable evidence" beyond holding statements | Cryptographic proof of balance and key control, independently reproducible |
| **AASB 1056** (Superannuation Entities) | Fair value measurement for investments | AUD valuation sourced from Australian exchange pricing data, date-stamped |

The standard that matters most here is ASA 500. Paragraph A31 establishes a hierarchy of audit evidence reliability, and two of its generalisations are directly relevant:

> "The reliability of audit evidence is increased when it is obtained from independent sources outside the entity."

The Bitcoin blockchain is about as independent as it gets — no single party controls it, and a balance queried from a full node is a mathematical fact, not an attestation.

> "Audit evidence obtained directly by the auditor is more reliable than audit evidence obtained indirectly or by inference."

This is the critical provision. An auditor with the wallet descriptor can query the blockchain directly. An auditor without it must rely indirectly on CertainKey's attestation. ASA 500 is explicit about which is preferable. The descriptor is what moves the evidence from "indirect" to "direct" in ASA 500's terms.

For the full regulatory analysis with paragraph-level citations — including how GS 009 paragraphs 141–143 handle the service organisation question and how the ATO's October 2025 guidance creates qualification risk — see [Why your SMSF auditor needs the wallet descriptor](/posts/why-your-smsf-auditor-needs-your-wallet-descriptor/).

## What the report does NOT prove

Be clear about the report's scope in your working papers:

- **It does not prove the source of funds.** The report confirms what the fund holds now, not how it got there. Transaction history and acquisition evidence are separate.
- **It does not prove the Bitcoin wasn't moved after the verification date.** The report is a point-in-time snapshot. If the audit date is 30 June and the report was generated on 30 June, you have evidence as at that date. If there's a gap, consider whether additional procedures are needed.
- **It does not replace a comprehensive financial audit.** It covers one asset class — Bitcoin held in self-custody. Everything else in the fund still needs the usual treatment.
- **It does not constitute a GS 007 / ASAE 3402 report.** CertainKey is not itself audited. The report's strength is that it doesn't need to be — because the evidence is independently verifiable via the blockchain.

## Practical recommendations

**For your working papers:**
- Retain the PDF report and note the SHA-256 hash
- If you verified the hash via the verification page, document that
- If you independently confirmed the balance using Sparrow or a node, document the method and result
- Note the wallet descriptor was provided and enables independent verification

**For your clients:**
- If a trustee asks whether you'll accept a CertainKey report: yes, provided it includes the wallet descriptor
- Encourage trustees to generate the report as close to the audit date as possible (ideally on 30 June for EOFY audits)
- The process takes about 10 minutes and requires the trustee's hardware wallet

**For your firm:**
- Consider downloading Sparrow Wallet onto one machine as a verification tool — it's free, runs offline, and gives you independent confirmation capability
- The [auditor guide PDF](https://app.certainkey.dpinkerton.com/auditor-guide.pdf) is designed to sit alongside the report in your audit file

---

Self-custodied Bitcoin is the hardest crypto asset to audit because there's no institution to send a confirmation letter to. But it's also the easiest to verify — because the evidence is sitting on a public ledger, waiting for someone to look.

The wallet descriptor is the key. The CertainKey report is the map. And the blockchain is the source of truth that neither the trustee, nor CertainKey, nor anyone else can fabricate.

**[View an example report](https://app.certainkey.dpinkerton.com/example-report.pdf)** | **[Download the auditor guide](https://app.certainkey.dpinkerton.com/auditor-guide.pdf)** | **[Verify a report](https://app.certainkey.dpinkerton.com/verify)**

---

*This is the final post in a five-part series on SMSF Bitcoin audit evidence. The full series: [What does your auditor need?](/posts/smsf-bitcoin-audit-what-your-auditor-needs/) · [Exchange statements vs cryptographic proof](/posts/exchange-statements-vs-cryptographic-proof/) · [Regulatory pressure on self-custody](/posts/smsf-bitcoin-self-custody-regulatory-pressure/) · [Why your auditor needs the wallet descriptor](/posts/why-your-smsf-auditor-needs-your-wallet-descriptor/) · A guide for SMSF auditors (this post)*
