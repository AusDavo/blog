---
title: "Building a Pub Darts App With Claude as My Pair Programmer"
date: 2026-02-05
draft: true
---

A few of us play darts remotely — I'm in Brisbane, Thomas is in Dubbo, others are scattered around Australia. We jump on a voice chat, call out our throws, and each keep score on whatever's handy. I use a notepad. Some of the others use chalkboards. It works, but someone always loses track of who's closed what, and there's no record of the game afterwards.

So I built [Good Grouping](https://darts.dpinkerton.com) — a self-hosted live darts scoring app. One person enters the throws, everyone sees the board update in real time over WebSockets. Passkey auth, crown tracking for bragging rights, the works.

It works. But last night Thomas and I played a proper best-of-three series, and within five minutes we had a list of things that didn't feel right. The scoreboard was horizontal when it should be vertical. Numbers were in the wrong order. You couldn't tell what you'd thrown this turn. There was no series tracking. The cricket win logic let you win on a tie.

Six features and a couple of bug fixes. I wanted to ship them before our next game.

## Claude Code as a development partner

I've been using [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — Anthropic's CLI tool — and this session was a good stress test. I wrote up the six changes as a plan, handed it over, and let it work through the implementation while I reviewed.

The changes touched nine files across the stack: SQLite schema migrations, Express routes, EJS templates, and client-side JavaScript. Claude handled the boring-but-error-prone parts well — wiring up new database tables, adding prepared statements, keeping the WebSocket state format consistent. It built the traditional three-column cricket scoreboard (the pub chalk layout: your marks, the number, their marks) without me having to explain what that looks like.

Where it needed steering was the game logic. The first cricket win condition it inherited from the existing code treated a points tie as a win for whoever closed first. Thomas and I discovered this mid-game when the app declared a winner at 0-0. That's not how cricket works — you need to be strictly ahead, or both players close everything and highest points wins. I described the correct rule in plain English, Claude fixed `checkCricketComplete`, and we rebuilt the container.

Same with "mugs away" — I said the loser should go first in the next game, and the implementation was straightforward. The value isn't that Claude knows darts rules. It's that the feedback loop is fast: describe what's wrong, get a fix, rebuild, test it live.

## What shipped

- **Best-of-N series** with win tracking, next-game and extend buttons
- **Traditional cricket scoreboard** — three-column pub layout for two players, horizontal fallback for three or more
- **Volley display** showing each dart thrown this turn
- **Player reorder** in the lobby before starting
- **Mugs away** — loser goes first next game
- **Cricket win fix** — tied points no longer counts as a win
- **Photo uploads** bumped to 20 MB

The whole session — plan, implement, test, fix, ship — took an evening. The container rebuilds in about a minute. The database migrations run on startup. No downtime for the three of us who use it.

## The bit that surprised me

The most useful part wasn't code generation. It was having something that holds the entire codebase in context while I focused on what the app should *do*. I could say "the loser should go first" without specifying which file, which query, which route. The mapping from intent to implementation is where Claude saved the most time.

It's not magic. I still had to catch the cricket win bug by actually playing. But for a self-hosted side project where I'm the only developer, having a pair programmer that never loses context on a nine-file change is genuinely useful.

The app is at [darts.dpinkerton.com](https://darts.dpinkerton.com) and the source is on [GitHub](https://github.com/AusDavo/good-grouping). Next session is Friday. I want to win that cricket crown from Thomas!
