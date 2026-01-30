---
title: I Built a Demo to Pitch My VPS Provider on Passkeys
date: 2026-01-30T22:36:14+10:00
draft: false
tags: []
---
I wanted to spin up a VPS this evening. My provider, Binary Lane, has a password-based login with SMS 2FA. My phone was already off and across the house. The friction was enough that I didn't bother.

Instead, I started thinking about passkeys — and how much smoother that login could be.

Binary Lane is a solid Australian VPS provider. Good pricing, a Brisbane datacenter, no-nonsense approach. I've used them for business customers for a while. But their auth is dated. Passkeys have been a viable standard since 2022. Apple, Google, and Microsoft are all pushing them. And yet most infrastructure providers — who probably should have been early adopters — are still on passwords.

I figured someone should say something. So I threw together a demo to see if they'd be interested.

## The login problem

Here's what logging into most VPS dashboards looks like:

1. Type email
2. Type password
3. Dig out your phone for 2FA
4. Hope you didn't fat-finger something

Here's what it could look like:

1. Click "Sign in"
2. Touch your fingerprint sensor

Not revolutionary. Just better.

## How passkeys actually work

WebAuthn (the spec behind passkeys) uses public-key cryptography. No shared secrets cross the network. Nothing gets stored that's useful to attackers on its own.

**Registration:**

1. Server generates a random challenge
2. Browser calls `navigator.credentials.create()` with that challenge
3. The authenticator (Touch ID, Windows Hello, a hardware key) generates a key pair
4. Private key stays on the device, never leaves
5. Public key and credential ID come back to the server
6. Store them against the user account

**Authentication:**

1. Server generates a new challenge
2. Browser calls `navigator.credentials.get()`
3. Authenticator signs the challenge with the private key
4. Signature comes back to the server
5. Server verifies it against the stored public key
6. Done

The critical insight: even if your database leaks, attackers get public keys. Useless without the private keys, which never left users' devices.

## The implementation

I wanted something clickable rather than a slide deck. The stack:

- Node.js with Express
- [SimpleWebAuthn](https://simplewebauthn.dev/) for the heavy lifting
- SQLite for storage
- Vanilla HTML/CSS frontend

SimpleWebAuthn handles the encoding quirks — WebAuthn uses a lot of ArrayBuffers and base64url, which is fiddly to get right. The library gives you `generateRegistrationOptions()`, `verifyRegistrationResponse()`, and equivalents for authentication. You bring the storage.

I stripped the demo down to the minimum viable surface:

- No email required to sign up
- No email required to sign in
- Just "Register" and "Sign in" buttons

Whether that's elegant or lazy depends on your perspective. But it makes the point: passkeys don't need the scaffolding passwords require. No hashing, no reset flows, no email verification. You store a public key and a credential ID. That's it.

The main gotcha I hit: resident keys vs non-resident keys. For a "usernameless" flow (where the authenticator remembers which credential to use), you need to request a resident key during registration. SimpleWebAuthn handles this, but you need to set `residentKey: 'required'` in the options.

## The pitch

I'm not suggesting Binary Lane tear out their existing auth and invite chaos. The ask is smaller: add passkeys as an option. Users who want it can enable it. Everyone else carries on.

Potential upsides for them:

- Fewer password reset tickets
- Phishing-resistant auth
- Maybe a little good press

I've sent the pitch. Might hear back, might not. They may have bigger priorities.

## We'll see

If nothing comes of it, at least I learned more about WebAuthn than I expected to. The spec is cleaner than password auth done properly. The browser APIs are well-designed. The main barrier is just inertia.

The demo exists if anyone else wants to poke at it.

---

*Demo's at [passkey-demo.dpinkerton.com](https://passkey-demo.dpinkerton.com). There's a [technical page](https://passkey-demo.dpinkerton.com/implementation.html) with code snippets and the full registration/authentication flow.*
