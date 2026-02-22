---
title: SeaDrive Doesn't Play Nice With Git or Obsidian
date: 2026-02-22T22:50:43+10:00
draft: false
tags: []
---
If you use Seafile and you've tried working with a git repo or an Obsidian vault on a SeaDrive-mounted library, you've probably noticed things going wrong. Slow operations, missing files, sync conflicts. The kind of problems that don't surface immediately but erode your trust in the setup over time.

The issue isn't Seafile. It's SeaDrive specifically, and understanding why will save you a lot of debugging.

## The Problem

SeaDrive is a virtual drive. Files aren't stored locally — they're fetched on demand when you access them. For browsing documents, opening the occasional spreadsheet, or pulling up reference material, this is great. It saves disk space and works transparently.

But git and Obsidian don't access files the way a human does. They expect the entire working tree to be present on disk at all times.

Git's `status`, `diff`, and `log` commands stat hundreds or thousands of files in the `.git` directory on every invocation. When those files live behind a virtual filesystem, each stat call becomes a network fetch. What should take milliseconds takes seconds. On larger repos, it becomes unusable.

Obsidian has a similar problem. It indexes your entire vault on startup, watches for filesystem events, and reads files constantly as you navigate between notes. A virtual filesystem introduces latency into every one of those operations, and file-watching events may not fire reliably — or at all.

There's also the write side. Both tools do rapid, small writes across many files. SeaDrive's sync logic wasn't designed for that pattern, and you'll eventually hit conflicts or corruption that's hard to diagnose.

## The Fix

Use the **Seafile Sync Client** instead of SeaDrive for any library that contains a git repo or an Obsidian vault.

The Sync Client does a full local sync — files live on your disk, and changes are synced to the Seafile server in the background. Git and Obsidian see a normal local directory. No virtual filesystem, no on-demand fetching, no broken file watchers.

You don't have to choose one or the other globally. Run both:

- **SeaDrive** for your general-purpose libraries — documents, media, archives, anything you access occasionally.
- **Seafile Sync Client** for libraries where tools expect a real local filesystem.

They coexist without issues. You just need to make sure you're not pointing both at the same library.

For git repos specifically, you're better off using a proper remote — GitHub, Gitea, Forgejo, whatever fits your setup. Syncing `.git` directories through *any* file sync service is asking for trouble. The internal structure of a git repo is not designed to be merged by an external sync engine.

For Obsidian, the Sync Client works well. If you want something independent of Seafile, Syncthing is the community favourite — peer-to-peer, open source, handles the many-small-files pattern without drama. And if you'd rather not think about it at all, Obsidian Sync is the paid option that just works.

## The Rule of Thumb

If the tool you're using expects to own a directory tree — indexing it, watching it, reading and writing rapidly across many files — don't put that directory on SeaDrive. Use a full local sync instead.

SeaDrive is a great tool for what it's designed for. The mistake is assuming it's a drop-in replacement for the Sync Client in every scenario. It isn't, and Seafile's documentation doesn't make this particularly clear.
