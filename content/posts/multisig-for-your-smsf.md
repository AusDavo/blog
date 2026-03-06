---
title: Multisig for Your SMSF — How to Prove Multiple Key Holders Control the Fund
date: 2026-03-06T12:00:00+11:00
draft: false
tags:
  - smsf
  - bitcoin
  - audit
  - certainkey
  - multisig
---
*This is the fourth post in a series about SMSF Bitcoin audit evidence. The [first post](/posts/smsf-bitcoin-audit-what-your-auditor-needs/) covered what auditors need to verify. The [second post](/posts/exchange-statements-vs-cryptographic-proof/) compared evidence standards. The [third post](/posts/smsf-bitcoin-self-custody-regulatory-pressure/) covered the regulatory pressure making all of this urgent. This post covers multisig — why it's best practice for SMSF custody, and why it creates a new audit evidence challenge.*

---

If you're holding Bitcoin in your SMSF with a single key, you have a single point of failure. One lost seed phrase, one compromised device, and the fund's assets are gone. No insurance, no recovery, no phone number to call.

Multisig fixes this. And if you're running a corporate trustee structure with multiple directors, it maps perfectly to how your fund already works.

But multisig creates a new problem at audit time: how do you prove that each key holder actually controls their key?

## Why multisig makes sense for SMSFs

A standard SMSF has two members, often with a corporate trustee. The corporate trustee has two directors. Both are responsible for the fund's assets.

With a single-signature wallet, one person holds all the keys. The other trustee has no cryptographic relationship to the Bitcoin at all. If the key holder dies, gets incapacitated, or goes rogue, the fund has a serious problem — and the remaining trustee may have no way to recover the assets.

A 2-of-3 multisig changes this:

- **Key 1:** Trustee A (e.g. hardware wallet at home)
- **Key 2:** Trustee B (e.g. hardware wallet at their location)
- **Key 3:** Backup key (e.g. in a safety deposit box, or held by a collaborative custody provider)

Any two of the three keys can spend. No single person can move funds unilaterally. If one key is lost or compromised, the other two can recover. This mirrors the dual-signatory controls that auditors expect for significant fund assets.

## The audit evidence gap

Here's where it gets interesting. Your auditor needs to verify two things: that the Bitcoin exists, and that the fund controls it.

For a single-sig wallet, proving control means one person signs a message. Done.

For multisig, the question becomes: who exactly controls this wallet? Can the required quorum of key holders actually sign? Does each trustee have access to their key, or has one of them lost it without telling anyone?

A broadcast transaction — sending a small amount to prove control — only proves the spending threshold can be met. Two of the three keys signed, the transaction went through, job done. But which two? Does the third key holder still have access? The auditor can't tell.

This is a meaningful gap. An auditor's job is to verify that the fund's governance structure is functioning as documented. If your investment strategy says "2-of-3 multisig held by Director A, Director B, and a backup key," the auditor should be able to verify that claim — not just that *someone* can spend.

## How individual key verification works

The answer is message signing — but done per key, not per wallet.

Instead of asking "can this wallet spend?" (which only requires a quorum), you ask each key holder individually: "prove you control your key."

The process:

1. **Each key holder receives a unique cryptographic challenge** — a random string tied to the verification date and the wallet descriptor.
2. **Each key holder signs the challenge with their individual key** using their hardware wallet. No funds move. No private keys are exposed.
3. **Each signature is verified against the corresponding public key** in the wallet descriptor. Either the math checks out, or it doesn't.

This gives the auditor something a broadcast transaction never could: verification of each key holder individually. You can see that Trustee A signed with Key 1, Trustee B signed with Key 2, and the backup key was not used (or was, if all three chose to sign).

The report maps each signature to a named key holder and their role. The auditor can see at a glance whether the quorum was met and who participated.

## Remote signing

Key holders don't need to be in the same room. In fact, they shouldn't be — the whole point of multisig is geographic distribution.

CertainKey generates a unique signing link for each key holder. They open it on their device, plug in their hardware wallet, sign the challenge, and they're done. The signatures are collected and verified independently.

This matters for SMSFs where trustees live in different cities, or where a key ceremony needs to happen around busy schedules. Each person signs at their convenience. The process doesn't require coordination beyond "please sign before this date."

## What the report shows

The verification report includes:

- **Wallet descriptor** — the full technical specification of the multisig setup (m-of-n threshold, derivation paths, extended public keys)
- **On-chain balance** at a specific block height, independently verifiable against the Bitcoin blockchain
- **Key control verification for each signer** — who signed, which key they used, their role in the fund
- **Quorum status** — whether the required threshold was met or exceeded
- **AUD valuation** at the verification date
- **SHA-256 hash** of the PDF for tamper detection

Every claim in the report can be independently verified. The wallet descriptor lets any party with a Bitcoin node reproduce the exact same balance. The signatures can be checked against the public keys. Nothing relies on trusting CertainKey.

## The comparison

|  | Broadcast Transaction | Statutory Declaration | Per-Key Message Signing |
|---|---|---|---|
| **Proves each key holder has access** | No — only proves quorum | No — just a promise | Yes — cryptographic proof per key |
| **On-chain footprint** | Permanent | None | None |
| **Transaction fees** | Yes | None | None |
| **Risk of fund loss** | Non-zero | None | None |
| **Independently verifiable** | Partially | No | Fully |
| **Maps to fund governance** | No | Somewhat | Directly |

A statutory declaration signed by both directors says "we control this Bitcoin." Per-key message signing proves it.

## If you're setting up multisig for your SMSF

A few practical points:

- **Document your setup in your investment strategy.** Your auditor needs to know the custody arrangement — how many keys, who holds them, what the spending threshold is. This isn't optional; SISR 4.09 requires the investment strategy to address risk management.
- **Use a standard descriptor format.** CertainKey works with standard output descriptors that any Bitcoin wallet software can produce. Sparrow Wallet, Electrum, and Coldcard all support this.
- **Label your keys.** When you set up the wallet, record which extended public key belongs to which trustee. You'll need this at verification time, and your auditor will want to see the mapping.
- **Test your backup key.** If you have a 2-of-3 and you've never actually signed with the third key, you don't know it works. Verify all three during your first CertainKey verification — it takes minutes and gives you confidence that your recovery path is real.

## The bottom line

Multisig is best practice for securing significant Bitcoin holdings. For SMSFs, it aligns with the governance structure auditors already expect — multiple responsible parties, no single point of failure, documented controls.

But multisig without proper verification is just a claim. Your auditor shouldn't have to take your word for it that both directors can sign. Per-key cryptographic verification turns that claim into evidence.

If you're holding Bitcoin in a multisig SMSF and want to see what a verification report looks like, there's an [example report](https://app.certainkey.dpinkerton.com/example-report.pdf) on the site.

[app.certainkey.dpinkerton.com](https://app.certainkey.dpinkerton.com)
