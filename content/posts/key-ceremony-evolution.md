---
title: "Key Ceremony: From Feature Creep to Zero Trust"
date: 2026-03-01
draft: false
tags: ["bitcoin", "multisig", "open-source", "self-hosted"]
---
[Key Ceremony](https://ceremony.dpinkerton.com) is a free tool for documenting your Bitcoin multisig wallet setup. You record who holds each key, where devices and backups are stored, and how to recover. It generates a professional ceremony record as a PDF. That's it.

Getting to that simplicity took some work.

## Origin

The idea came from [Dale Warburton's](https://mybitcoinwill.com) Bitcoin self-custody quiz. Taking it highlighted real gaps in my own setup. Not in the keys themselves, but in the documentation around them. I knew where my keys were. I hadn't written down how someone else would find and use them if I couldn't.

I'd already built [CertainKey](https://certainkey.dpinkerton.com), a service that produces ownership and control verification reports for self-managed super funds holding bitcoin. CertainKey parses wallet descriptors, verifies message signatures against cosigner public keys, and generates auditable reports. Building Key Ceremony on the same codebase seemed like a natural extension — give bitcoiners a way to document their multisig setup with the same rigour.

## Too Much Carried Over

The first version of Key Ceremony inherited features that made sense in CertainKey but had no place in a personal documentation tool:

- **Wallet descriptor parsing and hashing** — CertainKey needs this to cryptographically bind a report to a specific wallet configuration. For a ceremony record that just documents who holds what, it's unnecessary complexity and a trust concern. Users shouldn't need to enter their descriptor into a web app.
- **Key verification via message signing** — in CertainKey, proving control of each key is the whole point. In Key Ceremony, you're documenting your own setup. You already know you control your keys.
- **Document hash retention and verification** — CertainKey stores report hashes so third parties can verify authenticity. A personal ceremony record doesn't need this.
- **Shareable links for collaborators** — useful when a fund administrator needs to coordinate with an auditor, wrong for a document you print and put in a safe.

Each of these features is valuable in CertainKey. In Key Ceremony they added friction, raised trust questions, and obscured the core value: just document your setup. So I stripped them all out and started over with a pure documentation tool.

## The Trust Problem

Even after simplification, there was a fundamental issue. The server still received plaintext ceremony data via form submissions, encrypted it at rest with a server-held key, and generated the PDF using headless Chromium. The encryption was real, but the server operator could read your data if they chose to. Or were compelled to. Or were compromised.

Dale put it well: "How can I verify that you can't do anything with that data?" He's right. Telling people their data is encrypted means nothing if the server holds the keys.

## Client-Side Encryption with WebAuthn PRF

The solution was to move all encryption to the browser using the [PRF extension](https://w3c.github.io/webauthn/#prf-extension) available on modern passkeys.

Here's how it works:

1. **Registration** — when you create a passkey, the browser requests a pseudorandom function (PRF) evaluation from the authenticator. The output is deterministic for that credential and salt, but unknown to the server.
2. **Key derivation** — the PRF output is fed through HKDF-SHA256 to produce an AES-256-GCM key encryption key (KEK).
3. **Data encryption key** — a random data encryption key (DEK) is generated in the browser. The DEK encrypts all ceremony data. The KEK wraps (encrypts) the DEK. Only the wrapped DEK is sent to the server.
4. **Login** — authenticating with your passkey produces the same PRF output, derives the same KEK, unwraps the DEK, and decrypts your data.

The server stores only opaque encrypted blobs. It never sees the PRF output, the KEK, or the DEK. It cannot decrypt your ceremony data even with full database access.

The PDF is also generated entirely in the browser using [pdfmake](https://pdfmake.github.io/docs/). The assembled document never touches the server.

This isn't just a messaging improvement. It's an architectural guarantee. The server literally cannot read your data.

## PRF Support Today

PRF is powerful but not yet universal. It works with YubiKeys (5 series and later), Windows Hello, and iCloud Keychain. Android support is still catching up, and not all browsers expose the extension.

For Key Ceremony, PRF's primary value is enabling **resumable sessions**. You can start documenting your setup, close the browser, come back later, and pick up where you left off — all without the server ever seeing your data in the clear. Without PRF, you'd either need to complete everything in one session or trust the server with your plaintext.

For anyone without a PRF-capable authenticator, or anyone who'd simply prefer not to enter sensitive information into a browser, there's a [printable blank PDF template](https://ceremony.dpinkerton.com/key-ceremony-blank-template.pdf) available directly from the landing page. No account required.

## What's There Now

Key Ceremony in its current form:

- Documents your multisig wallet setup: key count, quorum, key holders, device and backup locations, recovery instructions
- Encrypts everything client-side before it reaches the server
- Generates the PDF entirely in your browser
- Requires a single PRF-capable passkey (YubiKey, Windows Hello, iCloud Keychain)
- Is [open source](https://github.com/AusDavo/key-ceremony) and self-hostable

The server knows that a user exists, what workflow step they're on, and an encrypted blob it can't read. That's the extent of the trust requirement.

If you're running a multisig setup and haven't documented it properly — and most of us haven't — [give it a try](https://ceremony.dpinkerton.com).
