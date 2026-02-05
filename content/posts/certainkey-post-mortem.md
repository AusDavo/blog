---
title: I Built the Right Tool for a Market That Didn't Want It
date: 2026-02-05T21:43:04+10:00
draft: false
tags: []
---
Last year I launched **CertainKey**, a service offering balance attestations and cryptographic verification of bitcoin holdings. I built an open-source tool called [Gatekeeper](https://github.com/AusDavo/gatekeeper), put up a site, and went looking for customers.

I didn't find any.

There was a bit of interest — enough to keep me hopeful for a while — but nothing that converted into actual business. So I shut it down, and now I'm writing the post-mortem, because I think the story is worth telling. Not as a cautionary tale, but as a case study in the gap between *a real problem* and *a problem people will pay to solve*.

## The Problem Was Real

If you're an SMSF auditor or accountant in Australia and your client holds bitcoin directly, you've probably experienced some version of this: the client sends you a screenshot of a wallet balance. Maybe they paste an address into an email. You plug it into a block explorer — possibly a public one, in a normal browser, with no particular thought given to what you're doing with that data — and confirm the number looks about right.

That's your audit evidence. A screenshot and a search.

The security practices around this are, to put it gently, loose. Extended public keys and bitcoin addresses — sensitive, privacy-critical data — get transmitted over email, entered into public search engines, stored without retention policies, and disposed of without controls. Financial professionals who would never dream of emailing a client's bank password routinely handle cryptographic key material with no more care than a restaurant receipt.

I thought: someone should fix this. And then I thought: maybe that someone is me.

## What Gatekeeper Does

[Gatekeeper](https://gatekeeper.dpinkerton.com) is a browser-based tool for verifying bitcoin holdings cryptographically. It runs entirely in the browser — nothing is transmitted to a server, so the privacy problem is addressed by design. You can verify that a person controls certain addresses and confirm on-chain balances without exposing sensitive key material to third parties, email servers, or search engine logs.

The idea behind CertainKey as a service was to wrap this tool in a professional attestation workflow. An auditor or accountant could point their client to the process, get cryptographic proof of holdings, and have something far stronger than a screenshot to put in their working papers.

The tool is [open source on GitHub](https://github.com/AusDavo/gatekeeper) and you can [try it yourself](https://gatekeeper.dpinkerton.com).

## Why It Didn't Work

The short version: the people who needed it didn't want it, and the people who might have wanted it didn't need it yet.

**The target audience is inherently conservative.** SMSF auditors aren't early adopters. Many are already uncomfortable with crypto in their clients' portfolios. Their instinct is to minimise exposure to it — decline the client, or accept whatever evidence is easiest to obtain — not to invest in better tooling. Learning a new cryptographic verification workflow, explaining it to clients, and integrating it into existing processes is a real cost, and it's a cost they have to pay upfront.

**The existing approach hadn't hurt anyone yet.** Yes, relying on screenshots and unverified block explorer lookups is weak evidence. Yes, handling extended keys over email is a security problem. But the ATO hadn't come down hard on sloppy crypto verification for SMSFs, and no auditor had been burned badly enough to go looking for a better method. I was selling insurance against a risk that hadn't materialised.

**The addressable market was small and shrinking.** SMSFs holding bitcoin directly — not through an ETF or a managed fund, but on-chain, where you actually need to verify addresses and balances — is a niche within a niche. And with the arrival of spot bitcoin ETFs, more self-managed funds will likely hold bitcoin through conventional financial products with conventional audit trails, making cryptographic verification of direct holdings even less relevant.

**I was solving two problems at once.** Better audit evidence *and* better privacy and security practices. In theory those reinforce each other. In practice, auditors didn't perceive the privacy problem as theirs to solve, and clients didn't know enough to demand better handling of their key material.

## What I'd Tell Myself a Year Ago

The product was technically sound. The problem was genuine. But I mistook "this should exist" for "people will pay for this." Those are very different propositions, especially in professional services markets where switching costs are high and the consequences of the status quo are theoretical.

If I had the conversation again, I'd push harder on one question: *who is waking up at night because of this problem?* The honest answer was nobody. Auditors were mildly uneasy, at best. That's not enough to change behaviour in a conservative profession.

I'd also think harder about timing. The market might have been ready in a world where the ATO started rejecting screenshot-based evidence, or where a high-profile SMSF audit failure involving crypto made the news. But I can't build a business on "maybe the regulator will force people to care."

## The Tool Lives On

Gatekeeper is still available and still works. It's open source, it runs in your browser, and it doesn't send your data anywhere. If you're someone who holds bitcoin and needs to prove it — to an auditor, a counterparty, or anyone else — it's there for you.

I'm glad I built it. Not every project needs to become a business to have been worth doing. Sometimes you build the right thing at the wrong time, for an audience that isn't quite ready. That's not failure — it's just how markets work.

If you want to play with it: [gatekeeper.dpinkerton.com](https://gatekeeper.dpinkerton.com)

If you want to look under the hood: [github.com/AusDavo/gatekeeper](https://github.com/AusDavo/gatekeeper)
