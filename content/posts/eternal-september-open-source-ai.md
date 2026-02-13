---
title: The Eternal September of Open Source
date: 2026-02-13
draft: false
tags:
  - open-source
  - ai
---
I recently submitted a [small PR to SeedSigner](https://github.com/SeedSigner/seedsigner/pull/874) — the multisig message signing fix I wrote about in my [previous post](/posts/patching-seedsigner-multisig-message-signing/). After opening it, I tagged two maintainers in a comment asking for feedback.

One of them, kdmukai, was not happy about that:

> I consider it rude to directly "@" reference any of us just to call for our attention. Notice that your "@" message adds nothing that is not already stated in the PR description. Reserve "@" call outs for when there are specific questions that the targeted person is the best resource and the discussion may be stalled until they weigh in.

My first reaction was surprise. In most professional contexts, tagging someone is just how you route a message — the equivalent of addressing an email. But his follow-up comment made the context clearer:

> This is a project run by volunteers who are contributing in their free time.

He also had concrete, constructive feedback: the PR needed tests, it should have been in draft state until those were ready, and he wanted to understand the real-world use case better. All fair. I apologised for the unnecessary tags, converted to draft, and pushed the tests.

The interaction stuck with me though — not because I thought he was wrong, but because I think his frustration points at something bigger than GitHub etiquette.

## The Asymmetry Problem

In February 2026, [GitHub started discussing a "kill switch" for pull requests](https://www.theregister.com/2026/02/03/github_kill_switch_pull_requests_ai/) — the ability for maintainers to disable external PRs entirely. The reason: a flood of low-quality, AI-generated contributions overwhelming volunteer maintainers.

The numbers are stark. Xavier Portilla Edo from Voiceflow estimated that only about 1 in 10 AI-generated PRs is legitimate. The curl project reported that around 20% of its bug bounty submissions appeared to be AI-generated slop. Projects like Ghostty and tldraw have restricted external contributions entirely.

The economics are brutal. It takes someone 60 seconds to prompt an AI to "fix typos and optimise loops" across a dozen files. It takes a maintainer an hour to review those changes, verify they don't break edge cases, and check they align with the project's direction. Every low-quality PR costs volunteer time that doesn't grow back.

To be clear — I don't think my PR falls into this category. It's a targeted fix for a real issue I raised two years ago, tested on hardware, with a clear use case. But I can see how, from a maintainer's perspective, the volume of notifications, tags, and demands for attention has shifted the baseline. The threshold for what feels like an imposition has dropped because the total load has gone up.

## Eternal September

The internet has a name for this dynamic. In the early Usenet days, every September brought a wave of university freshmen online. They didn't know the norms, clogged newsgroups with noise, and annoyed the regulars. But it was seasonal — by October, the newcomers either assimilated or left.

Then in 1993, AOL gave the general public access to Usenet, and September never ended.

AI tools are creating a similar dynamic in open source. The barrier to generating a plausible-looking PR has dropped dramatically. People who previously wouldn't have engaged with a codebase at all can now produce something that looks like a contribution but lacks the contextual understanding that makes it useful. The maintainers are experiencing a new kind of Eternal September — one where the "newcomers" might not even be learning, because the AI did the work and the human never engaged deeply with the code.

## What If AI Could Help the Other Side Too?

Most of the conversation about AI and open source focuses on the contributor side — people using AI to write code and submit PRs. But what about the maintainer side?

Angie Jones [made this argument well](https://angiejones.tech/stop-closing-the-door-fix-the-house/): instead of closing doors, fix the house. She proposes that projects create `AGENTS.md` files to guide AI tools on project conventions, use AI-powered code review as a first-pass filter, and strengthen test suites as safety nets against bad contributions. The point isn't to fight AI — it's to put it to work on both sides of the equation.

This resonates with what [Nate B Jones has been talking about](https://youtu.be/JKk77rzOL34) regarding Claude's role in software development. His argument is that the real leverage isn't in using AI to write more code faster — it's in organising teams that include both AI agents and people, where agents handle triage, planning, and documentation while humans focus on judgement calls and oversight.

Applied to open source maintenance, that could look like:

- **AI triage**: An agent that reviews incoming PRs against project guidelines, checks for test coverage, validates that the PR is in draft until ready, and provides initial feedback — before a human maintainer ever sees it.
- **Automated context checking**: Does this PR reference an existing issue? Does the contributor have any history with the project? Is the code consistent with the project's patterns?
- **Review assistance**: Not replacing human review, but surfacing the things a maintainer would want to know — what changed, what's tested, what's not, and what might break.

kdmukai's comment about being "fiercely protective of our volunteers' time" is exactly the right instinct. The question is whether AI tools can help protect that time, rather than only consuming it.

## The Contributor's Responsibility

None of this absolves contributors — AI-assisted or otherwise — from doing the work properly. Looking back at my PR interaction, kdmukai's feedback was right on every point:

- The PR should have been in draft state until tests were included.
- The @-mentions added no information and just created noise.
- Understanding the project's conventions before contributing is your job, not the maintainer's.

These are things I should have picked up from looking at the project's existing PRs and contribution patterns. The fact that I didn't is on me, not on any tool I used.

If AI makes it easier to write code, it should also make it easier to write tests, follow conventions, and submit complete, well-documented contributions. The bar for what constitutes a "ready" PR hasn't changed just because the code was faster to write.

## Where This Leads

The open source ecosystem is adapting to the same shift that every information-sharing community eventually faces when access scales faster than norms. Usenet survived the original Eternal September — but it was never quite the same. The communities that thrived were the ones that built better moderation tools, clearer guidelines, and more resilient cultures.

Open source will likely follow the same path. GitHub is already exploring better permission controls and AI-powered triage tools. Projects that invest in contributor documentation, CI quality gates, and first-pass automation will handle the volume better than those that rely purely on human gatekeeping.

For contributors, the lesson is simple: AI lowers the cost of writing code, but it doesn't lower the cost of understanding a project. Do the reading. Write the tests. Submit drafts. And save the @-mentions for when they're actually needed.
