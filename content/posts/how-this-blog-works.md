---
title: "How This Blog Works"
date: 2026-01-28T08:00:00+10:00
draft: false
tags: ["meta", "hugo", "obsidian", "self-hosted"]
---

I've tried various blogging setups over the years. This time I wanted something that felt right: write in a tool I enjoy, publish with a simple command, and keep everything under my control.

Here's what I landed on.

## The Stack

- **Writing:** Obsidian
- **Static site generator:** Hugo with the PaperMod theme
- **Hosting:** Self-hosted on my home server via Caddy
- **Deployment:** GitHub webhook triggers automatic rebuilds

## Why This Approach?

### Write Where It's Comfortable

I already use Obsidian for notes. Opening a separate app or web interface to write blog posts creates friction. By opening my Hugo site as an Obsidian vault, I write posts in the same environment as everything else.

The posts are just Markdown files with YAML frontmatter. Nothing proprietary.

### Static Sites Are Fast and Simple

Hugo generates plain HTML files. No database, no PHP, no server-side rendering on each request. The server just serves files. It's fast, secure, and there's almost nothing that can break.

Hugo itself builds the entire site in under 100ms. I've used Jekyll and others before—Hugo's speed is noticeable.

### Self-Hosted Because I Can

I already run a home server for various things. Adding a static site is trivial. Caddy handles HTTPS automatically. I'm not dependent on Netlify, Vercel, or GitHub Pages.

If any of those services changed their terms, pricing, or disappeared, I'd have to migrate. With self-hosting, I control the whole chain.

### Git for Version Control

Every post is a commit. I can see the history, revert changes, and work from multiple machines. If I write a draft on my laptop and want to continue on my desktop, I just pull.

### Automated Deployment

When I push to GitHub, a webhook notifies my server. A Docker container pulls the latest changes and rebuilds the site. The whole process takes a few seconds.

```
git push → GitHub webhook → server pulls → Hugo builds → site updated
```

No CI/CD service needed. No build minutes to worry about. Just a lightweight webhook receiver running in a container.

## The Workflow

1. Create a new post in Obsidian using a template (auto-fills the date)
2. Write
3. Preview locally with `hugo server` if I want to check formatting
4. Commit and push
5. Done—it's live

## Trade-offs

This setup isn't for everyone:

- **Requires a server:** If you don't already self-host, this adds complexity.
- **No CMS:** There's no web interface to write posts. It's just files and git.
- **Manual Hugo updates:** Hugo doesn't auto-update. I have a script to fetch the latest version when needed.

For me, these aren't problems. I already have the server. I prefer writing in a real editor. And I'd rather update Hugo once a year than deal with a managed platform's quirks.

## Source

The blog source is public: [github.com/AusDavo/blog](https://github.com/AusDavo/blog)

Feel free to look around or use it as a reference for your own setup.
