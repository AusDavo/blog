# blog.dpinkerton.com

Personal blog built with [Hugo](https://gohugo.io/) and the [PaperMod](https://github.com/adityatelange/hugo-PaperMod) theme.

## Setup

```bash
git clone --recurse-submodules git@github.com:AusDavo/blog.git
cd blog
```

Requires Hugo v0.146.0 or later. See [Hugo installation](https://gohugo.io/installation/).

## Usage

**Preview locally:**
```bash
hugo server
```

**Create a new post:**
```bash
hugo new posts/my-post.md
```

Or create a file in `content/posts/` with frontmatter:
```yaml
---
title: "Post Title"
date: 2026-01-28T10:00:00+10:00
draft: false
tags: []
---
```

**Publish:**
```bash
git add .
git commit -m "Add: Post title"
git push
```

Deployment is automated via webhook.

## Structure

```
├── content/posts/    # Blog posts (Markdown)
├── templates/        # Obsidian Templates
├── themes/PaperMod/  # Theme (git submodule)
├── hugo.toml         # Site configuration
└── update-hugo.sh    # Script to update Hugo
```

## License

Content is © David Pinkerton. Code and configuration are free to use as reference.
