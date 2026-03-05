---
title: "I Installed 39 Custom Agents and Removed Them All"
date: 2026-03-05T15:27:13+10:00
draft: false
tags:
  - ai
  - claude-code
---
Early in my time with Claude Code, before I had any real sense of how I'd use it day to day, I found a repository of custom sub-agents called [Contains Studio Agents](https://github.com/contains-studio/agents). It promised 39 specialized agents — a backend architect, a TikTok strategist, a "whimsy injector," a joker for dad jokes. The install instructions were simple: clone the repo, copy the files to `~/.claude/agents/`, restart Claude Code. So I did.

Months later, I asked Claude to audit them. The verdict was immediate: remove them all.

## What Custom Agents Actually Are

Claude Code supports [custom sub-agents](https://docs.anthropic.com/en/docs/claude-code/sub-agents) — markdown files in `~/.claude/agents/` with YAML frontmatter defining a name, description, available tools, and a system prompt. When Claude Code starts a conversation, it reads these files and makes the agents available for delegation. You can think of them as specialist personas that the main agent can hand tasks off to.

Here's a simplified example of what one looks like:

```markdown
---
name: backend-architect
description: Use this agent when designing APIs or architecting backend systems.
tools: Write, Read, Bash, Grep
---

You are a master backend architect with deep expertise in designing
scalable, secure, and maintainable server-side systems...
```

When the main agent decides a task matches an agent's description, it spawns the sub-agent with its specialized system prompt and restricted tool set. The sub-agent does its work and returns the result.

## The Hidden Cost

Here's the thing I didn't understand when I installed them: every agent's description and examples get injected into the system prompt of **every conversation**. All 39 of them. Every time.

That's not free. The context window is finite. Every token spent on agent descriptions is a token not available for your actual work — your code, your files, your conversation history. With 39 agents, each with multiple usage examples, that's a meaningful chunk of context consumed before you've typed a word.

I ran `du -sh ~/.claude/agents/` — 396KB of markdown. Not all of that goes into the system prompt verbatim, but the descriptions and examples do, and they add up.

## The Wrong Agents for the Wrong Person

Beyond the context cost, these agents were designed for a mobile app studio running 6-day development sprints. The collection included:

- A **TikTok strategist** for viral marketing campaigns
- An **Instagram curator** for visual content
- A **Reddit community builder** for organic growth
- An **app store optimizer** for keyword research
- A **sprint prioritizer** for 6-day cycle planning
- A **whimsy injector** that would "proactively" add playful UI elements after any interface change

I write about Bitcoin custody, SMSF auditing, and server infrastructure. I was carrying 39 agents purpose-built for a workflow I don't have.

Even the engineering agents — backend architect, frontend developer, rapid prototyper — were redundant. Claude Code's built-in agents (`general-purpose`, `Explore`, `Plan`) already handle these cases well, and they don't need a 90-line system prompt about microservices and CQRS patterns to do it.

## The Fix

```bash
rm -rf ~/.claude/agents/
```

One command. The change takes effect on the next conversation.

## When Custom Agents Are Actually Worth Building

I don't think custom agents are a bad idea in principle. They're worth building when:

1. **You have a recurring, specific workflow** where a tailored system prompt would produce meaningfully different results than the general-purpose agent.
2. **You're invoking it often enough** that the context cost is justified by the time saved.
3. **The built-in agents genuinely can't do what you need** — which is a higher bar than most people think.

The signal to watch for: if you find yourself pasting the same instructions or context at the start of multiple conversations, that's a candidate for a custom agent. Or more likely, a project-level `CLAUDE.md` file, which gives you persistent instructions without the overhead of a full agent definition.

## The Broader Lesson

This is a pattern I see across AI tooling: the temptation to install everything available "just in case." More MCP servers, more plugins, more agents, more system prompt instructions. Each addition feels small. But context windows are zero-sum, and every tool you load that you don't use is competing with tools you do.

The best Claude Code setup I've found is a minimal one: a few well-chosen MCP servers for things I actually use, project-level `CLAUDE.md` files for project-specific context, and the built-in agents for everything else. No TikTok strategist required.
