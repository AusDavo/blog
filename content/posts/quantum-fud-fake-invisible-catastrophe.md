# Quantum FUD Is a Fake Invisible Catastrophe

Patrick Moore's 2021 book *Fake Invisible Catastrophes and Threats of Doom* makes a simple observation: most modern scare stories are built on phenomena that are either invisible, remote, or both. CO2. Radiation. Ocean acidification. Coral bleaching in reefs you'll never visit. The average person can't observe or verify any of it firsthand. They have to trust activists, media, politicians, and scientists — all of whom have financial or political skin in the game — to tell them the truth.

Moore's framework wasn't written with Bitcoin in mind. But it maps onto the quantum computing threat almost perfectly.

## The Criteria

Moore identifies two properties that make a claimed catastrophe resistant to scrutiny:

1. **Invisible.** The threat can't be directly seen or detected by ordinary people. You can't see CO2. You can't see radiation. You need specialised instruments and expertise to even confirm these things exist in the quantities claimed.

2. **Remote.** The threat is happening somewhere most people will never go. Polar bears in the Arctic. Coral reefs in the deep Pacific. Plastic in the middle of the ocean. You'll never see it yourself. You're relying on someone else's report.

When a claimed threat is both invisible *and* remote, the average person has no way to verify it. The information asymmetry is total. And that asymmetry is where exaggeration thrives.

## Apply It to Quantum

Now consider the quantum computing threat to Bitcoin.

**Invisible.** No ordinary person can observe a quantum computer breaking elliptic curve cryptography. Most people can't conceptualise what a qubit does, let alone evaluate whether Shor's algorithm running on a fault-tolerant quantum machine could derive a private key from an exposed public key. The entire threat model lives in abstract mathematics and theoretical physics. You can't see it, touch it, or verify it without years of specialised training.

**Remote.** The quantum computers capable of threatening Bitcoin don't exist. The most powerful machines currently have around 1,500 physical qubits. A 2017 Microsoft paper estimated you'd need roughly 2,330 *logical* qubits to break 256-bit elliptic curve cryptography — and with current error rates, about 1,000 physical qubits are needed to produce a single logical one. We're talking about machines that would need millions of physical qubits. The threat is remote in time, remote in physical access, and remote from anything resembling current engineering capability.

**Unverifiable.** Just as with Moore's environmental examples, people must rely on experts, media, and interested parties to tell them whether this threat is real. And the interested parties are everywhere. Post-quantum cryptography vendors selling solutions. Competing blockchains marketing themselves as "quantum-safe." Portfolio strategists at investment banks who need a thesis for why they trimmed their Bitcoin allocation. Researchers who need grant funding. Journalists who need clicks. Each has a reason to amplify the threat beyond what the evidence supports.

## The FUD Cycle in Practice

In January 2026, Jefferies removed Bitcoin from a key Asia-focused portfolio, citing long-term quantum risk. Christopher Wood, their global head of equity strategy, framed it as an existential technological threat. The move rattled markets.

Around the same time, headlines proliferated: "Bitcoin doesn't have 20 years." "Q-Day panic." "The quantum clock is ticking." Charles Hoskinson of Cardano warned about premature adoption of post-quantum cryptography. Various analysts published "Quantum Doomsday Clocks."

Meanwhile, Adam Back — the cypherpunk whose Hashcash proof-of-work system is cited in the Bitcoin whitepaper — has consistently argued that a cryptographically relevant quantum threat is 20 to 40 years away. Ark Invest, in a March 2026 report co-authored with Unchained, concluded that quantum computing is a long-term consideration, not an imminent threat. Galaxy Digital's head of research described market concerns as having "escalated beyond reasonable levels."

The pattern is familiar. An invisible, unverifiable threat is amplified by people with incentives to amplify it, while those closest to the actual technology say the timeline is measured in decades.

## Where the Analogy Holds

Moore's deeper point isn't that every invisible threat is fake. It's that invisibility and remoteness create an environment where exaggeration is easy and accountability is low. If you claim the coral reefs are dying and your audience has never seen a coral reef, who's going to check?

Quantum FUD works the same way. If you claim Bitcoin's cryptography will be broken by quantum computers and your audience can't evaluate post-quantum lattice-based signature schemes, who's going to push back? The information asymmetry does the heavy lifting. The audience has to take it on faith — and faith is a poor foundation for risk assessment.

The structural incentives amplify this. Every headline about Q-Day is a headline that gets clicks. Every investment bank that cites quantum risk has a narrative for a portfolio decision that might have been made for other reasons entirely. Every competing Layer 1 that calls itself "quantum-resistant" gets a marketing edge over Bitcoin — at least until someone asks whether their chain has the same decentralised governance challenges when it comes time to actually upgrade.

## Where It Breaks Down

Moore's framework isn't a perfect fit. There are a few honest differences.

Quantum computing progress is measurable. Qubit counts, error rates, and published benchmarks are public. You can track the gap between current hardware and what would be needed for a cryptographically relevant attack. The threat model is mathematically well-defined — Shor's algorithm isn't speculation, it's a proven algorithm that would work given sufficient hardware. The question is when, not whether, the maths holds.

Bitcoin's cryptographic assumptions are also genuinely worth examining. Around 25–35% of Bitcoin's supply sits in address types where the public key is already exposed on-chain. Legacy Pay-to-Public-Key addresses from the early Satoshi era, reused addresses, and certain multisig setups would all be vulnerable if a sufficiently powerful quantum machine existed. This isn't hand-waving — it's a real property of the protocol.

And Bitcoin's conservative governance model, while a strength in most contexts, does make large-scale cryptographic transitions slow. Jameson Lopp has estimated that a meaningful migration to post-quantum cryptography could take 5 to 10 years of coordination.

These are legitimate technical considerations. They deserve serious analysis. What they don't deserve is the breathless, unfalsifiable, faith-based panic that dominates the current discourse.

## The Test

Moore's implicit test is simple: **can you verify this yourself?**

Can you verify that a quantum computer will break Bitcoin's cryptography within a timeframe that matters to you? No. You're relying on someone else's projection, and that someone probably has a reason for the projection to be alarming.

Can you verify that the current generation of quantum hardware is anywhere close to the threshold? Yes, actually — the published benchmarks are clear, and the gap is enormous. This is the part of the story that the headlines tend to skip.

Can you verify that Bitcoin's protocol is incapable of upgrading? No — and historically, the network has adopted significant upgrades (SegWit, Taproot) through its consensus process. Slowly, yes. But the claim that Bitcoin *can't* adapt is itself unverified.

The quantum threat to Bitcoin is real in the same way that an asteroid impact is real: the physics checks out, the probability is non-zero, and the timeline is sufficiently distant that the people sounding the alarm today will never be held accountable for their predictions. That's the signature of a fake invisible catastrophe — not that the underlying science is wrong, but that the gap between evidence and alarm is filled by incentives rather than facts.

Run your own node. Verify your own transactions. And when someone tells you the sky is falling, ask whether they can show you the crack — or whether they're asking you to take their word for it.
