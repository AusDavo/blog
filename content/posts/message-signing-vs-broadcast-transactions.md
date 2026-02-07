---
title: Why Message Signing Beats Broadcast Transactions for Bitcoin Proof of Holdings
date: 2026-02-07T20:40:00+10:00
draft: false
tags: []
---
A few days ago I wrote about [shutting down CertainKey](/posts/certainkey-post-mortem/), my service for cryptographic verification of Bitcoin holdings. I'd built what I thought was the right tool, but couldn't find a market willing to pay for it.

Turns out I might have given up too early.

I recently had a conversation with an SMSF holder whose auditor was asking for proof of ownership and control over their Bitcoin. The auditor's initial suggestion? Broadcast a small transaction to prove control.

It's an intuitive idea. If you can spend from a wallet, you control it. But it's the wrong approach, and I want to explain why.

## The Problem With Broadcast Transactions

When an auditor asks you to send a small transaction to prove control, they're trying to answer a reasonable question: "Does this entity actually control these funds?" But a broadcast transaction is a blunt instrument for this purpose.

**On-chain footprint.** Every Bitcoin transaction is permanent and public. You're creating an indelible record just to satisfy an annual compliance requirement. Over time, this builds a trail of activity that serves no purpose other than proving something you could prove more elegantly.

**Transaction fees.** You're paying miners to include a transaction that has no economic purpose. It's not much, but it's not nothing—and you're doing it every year.

**Privacy leakage.** Transactions link addresses together. If you're sending from a cold storage wallet to an exchange deposit address "just to prove control," you've now linked those two things on-chain forever. Anyone analysing the blockchain can see that connection.

**Risk.** It's small, but non-zero. You're signing and broadcasting a real transaction. Wrong address, wrong fee, fat finger on the amount—these things happen. Why introduce that risk when you don't need to?

**Incomplete verification.** This is the subtle one. If you're using a 2-of-3 multisig (as many SMSFs should be), a broadcast transaction only proves that the *signing threshold* can be met. It doesn't prove that all three key holders have access to their respective keys. You might have two trustees sign while the third has lost their key entirely—and the auditor would never know.

## Message Signing: The Better Approach

Bitcoin has a built-in mechanism for proving control without moving funds: message signing. You take a message (any arbitrary string), sign it with a private key, and anyone with the corresponding public key can verify that signature.

No transaction. No fees. No on-chain footprint. No risk of fund loss.

For single-signature wallets, this is straightforward—most wallet software supports it directly. For multisig, it requires a bit more work: you issue a unique challenge to each key holder, and each one signs with their individual key. This actually gives you *better* assurance than a broadcast transaction, because you're verifying every key, not just enough to meet the spending threshold.

Here's the comparison:

|  | Broadcast Transaction | Message Signing |
|---|---|---|
| **On-chain footprint** | Permanent, visible | None |
| **Transaction fees** | Yes, every year | None |
| **Risk of fund loss** | Non-zero | Zero |
| **Privacy** | Links addresses, reveals activity | No leakage |
| **Key verification** | Only proves quorum can be met | Verifies each key individually |
| **UTXO impact** | Creates dust, fragments UTXOs | None |

## How This Actually Plays Out

Here's a real scenario I encountered recently. An SMSF holder's auditor asked for proof of ownership and control over their Bitcoin. The auditor's first request was exactly right: a signed message.

But the holder had their Bitcoin in a multisig wallet. They looked at their wallet software, couldn't find an obvious way to "sign a message" with a multisig, and told the auditor it wasn't possible.

The holder then suggested a signed-but-not-broadcast PSBT (a partially signed transaction that never hits the blockchain). The auditor wasn't familiar with PSBTs and came back with a simpler idea: just broadcast a small transaction. Send 0.00001 BTC somewhere, document it, done.

The holder wasn't keen. And rightly so—for all the reasons above.

This is where CertainKey comes in. The auditor's original instinct was correct. Message signing absolutely works with multisig; you just verify each key individually rather than signing with "the multisig" as a unit. Most wallet software doesn't make this obvious, but the cryptography is straightforward. Issue a challenge to each key holder, have them sign with their individual key, verify each signature.

The auditor wanted message signing from the start. They only fell back to broadcast transactions because everyone assumed multisig couldn't do it. This is a tooling and education gap, not a fundamental limitation.

## The Regulatory Context

For Australian SMSFs holding Bitcoin, auditors need to verify both the existence of assets and the fund's control over them. The ATO and ASIC don't prescribe exactly how this must be done, but they do require adequate evidence.

A properly documented message signing verification—with cryptographic challenges issued to each key holder, signatures verified against known public keys, and the whole process tied to a specific timestamp—provides stronger evidence of control than a broadcast transaction. It proves each trustee or key holder individually controls their portion of the custody arrangement.

## Where This Leaves CertainKey

When I wrote about [shutting down CertainKey](/posts/certainkey-post-mortem/), I thought I'd built something nobody wanted. Maybe I just hadn't found the right customers yet—the ones whose auditors ask hard questions and aren't satisfied with exchange screenshots.

If you're an SMSF holder getting pushback from your auditor about Bitcoin proof of holdings, or an auditor trying to figure out how to verify self-custodied crypto properly, feel free to [reach out](https://certainkey.dpinkerton.com).

The tools exist. The methodology is sound. It just needs more people to know about it.
