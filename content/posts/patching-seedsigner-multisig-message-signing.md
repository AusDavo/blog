---
title: "Patching SeedSigner to Support Multisig Message Signing"
date: 2026-02-10
draft: false
tags: ["bitcoin", "seedsigner", "multisig", "open-source"]
---
I run [CertainKey](https://certainkey.dpinkerton.com), a service that provides ownership and control verification reports for self-managed super funds (SMSFs) holding bitcoin. Part of that process involves proving that the fund trustee controls specific keys in a multisig wallet — not by moving funds, but by signing a message with each key individually.

For this I built [Gatekeeper](https://gatekeeper.dpinkerton.com), a tool that verifies BIP-322 message signatures. The flow is simple: the customer signs a known message with their hardware wallet at the relevant derivation path, and Gatekeeper confirms the signature matches the expected public key from the wallet descriptor.

My default recommendations are Coldcard for the signing device and Nunchuk as the wallet coordinator — both handle multisig message signing without issues. But I want to fully support customers who use SeedSigner too, and that's where I hit a wall.

## The Error

A customer of mine was getting this when attempting to sign a message on their SeedSigner with a multisig derivation path (`m/48'/0'/0'/2'/0/0`):

```
System Error
Exception
embit_utils.py, 133, in parse_derivation_path
Not implemented
```

I updated to the latest firmware (v0.8.6), loaded it onto my own SeedSigner, and hit the same wall. Then I remembered — I'd actually [raised this exact issue](https://github.com/SeedSigner/seedsigner/issues/519) two years ago. No response, no fix.

There is a workaround: you can import each multisig cosigner seed into Sparrow Wallet as an individual wallet with a custom derivation path, then sign messages there. But that means the signing happens on the machine running Sparrow — which is typically internet-connected. The whole point of using a SeedSigner is to keep keys air-gapped. Asking a customer to take their keys hot to work around a software limitation defeats the purpose.

## Digging Into the Code

The message signing feature in SeedSigner uses two functions in `embit_utils.py`:

1. `parse_derivation_path()` — a UI helper that parses a derivation path string into metadata (script type, network, change/index)
2. `sign_message()` — the actual cryptographic signing function

Here's the thing: `sign_message()` already works with any derivation path. It takes the raw path string, derives the private key, and signs. No restrictions.

The block was entirely in `parse_derivation_path()`:

```python
if sections[1] == "48h":
    # So far this helper is only meant for single sig message signing
    raise Exception("Not implemented")
```

Three lines of code standing between multisig users and a working feature.

## The Fix

For single-sig paths like `m/84'/0'/0'/0/0`, the script type (native segwit, nested segwit, etc.) is encoded in the first level — `84h` means native segwit. The parser already handles this with a lookup table.

BIP48 multisig paths are slightly different. In `m/48'/0'/0'/2'/0/0`, the script type is at the fourth level: `1h` for nested segwit (p2sh-p2wsh), `2h` for native segwit (p2wsh).

The fix extends the parser to handle this:

```python
if sections[1] == "48h":
    bip48_script_types = {
        "1h": SettingsConstants.NESTED_SEGWIT,
        "2h": SettingsConstants.NATIVE_SEGWIT,
    }
    if len(sections) > 4:
        details["script_type"] = bip48_script_types.get(sections[4])
    else:
        details["script_type"] = None

    if not details["script_type"]:
        details["script_type"] = SettingsConstants.CUSTOM_DERIVATION
else:
    details["script_type"] = lookups["script_types"].get(sections[1])
    if not details["script_type"]:
        details["script_type"] = SettingsConstants.CUSTOM_DERIVATION
```

The rest of the function — network detection, change path, address index — already works correctly for BIP48 paths since they follow the same tail structure as single-sig.

One caveat: the address shown on the SeedSigner confirmation screen during signing is the individual cosigner's single-key address, not the full multisig address. Deriving the actual multisig address would require all cosigner xpubs, which the SeedSigner doesn't have in this flow. For verification purposes this doesn't matter — what matters is that the signature is made with the correct private key, and the verifier can match the recovered public key against the xpub in the wallet descriptor.

## Building a Patched Image

SeedSigner runs on a custom Linux image built with [Buildroot](https://buildroot.org/). The [seedsigner-os](https://github.com/SeedSigner/seedsigner-os) repo provides a Dockerised build system that cross-compiles everything for the Raspberry Pi.

To build with the patched code:

1. Clone both repos and check out the v0.8.6 tag of the app
2. Apply the patch to `src/seedsigner/helpers/embit_utils.py`
3. Copy the app source into the OS repo's `rootfs-overlay/opt/`
4. Build with `--skip-repo` so it uses your local code instead of cloning from GitHub

```bash
sudo SS_ARGS="--pi0 --skip-repo" docker compose up --force-recreate --build
```

The full build takes roughly an hour on a modern machine — it's cross-compiling a complete Linux system from scratch. The output is a ~50 MB image you `dd` onto a microSD card.

## The Result

Flashed, booted, scanned a QR code with `signmessage m/48'/0'/0'/2'/0/0 ascii:test message`, and got a valid signature back. Gatekeeper confirmed it matched the expected key. Done.

I've submitted the fix upstream as [PR #874](https://github.com/SeedSigner/seedsigner/pull/874). In the meantime, if you're a SeedSigner user who needs multisig message signing, there's a pre-built Pi Zero image on [my fork's releases page](https://github.com/AusDavo/seedsigner/releases/tag/0.8.6-multisig-msg-signing).

## Why This Matters

Hardware wallet message signing is the cleanest way to prove key ownership without touching funds. For multisig setups — increasingly common in SMSF custody and institutional bitcoin holdings — this is essential for auditing and compliance. Coldcard already supports it. SeedSigner's air-gapped, open-source design makes it a popular choice for multisig participants, but this gap meant they couldn't complete a key verification without switching devices.

Message signing as a way to prove key ownership and control is still emerging as a standard. The tooling isn't uniformly supported and edge cases like this are expected. I'm happy to be working through them — contributing fixes upstream and refining the process as it matures.
