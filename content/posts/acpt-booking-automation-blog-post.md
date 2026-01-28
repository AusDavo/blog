---
title: Automating Client Onboarding for a Personal Trainer with Self-Hosted Tools
date: 2026-01-28T22:55:01+10:00
draft: false
tags: []
---
A friend of mine, Aaron, is an experienced and popular personal trainer. He needed a way for clients to book sessions online and automatically receive a health screening form before their first appointment. Instead of paying for expensive SaaS subscriptions, we built the whole thing with self-hosted, open-source tools.

## The Problem

When a new client wants to book a PT session, Aaron needs them to:
1. Pick a time that works with his schedule
2. Complete a health screening questionnaire and waiver
3. Have that form signed by both parties before the first session

Doing this manually means chasing emails, sending PDFs, and hoping people complete paperwork before they show up. We wanted it automated.

## The Stack

Everything runs on a single server:

- **[Cal.com](https://cal.com)** — Open-source Calendly alternative for appointment scheduling
- **[Docuseal](https://www.docuseal.co/)** — Open-source DocuSign alternative for document signing
- **[n8n](https://n8n.io)** — Open-source workflow automation (like Zapier)
- **Docker + Portainer** — Container management
- **Caddy** — Reverse proxy with automatic HTTPS

Total monthly cost: whatever you're already paying for your server.

## The Flow

```
Client books via Cal.com
        ↓
Webhook fires to n8n
        ↓
n8n checks: Has this client signed the health form before?
        ↓
    NO → Send health form via Docuseal
    YES → Do nothing (they're a returning client)
        ↓
Client receives email with form link
        ↓
After client signs, Aaron gets notified to countersign
```

## The Interesting Bits

### Cal.com + Google Calendar

Cal.com needs OAuth credentials to sync with Google Calendar. This means creating a project in Google Cloud Console, enabling the Calendar API, and formatting the credentials as a specific JSON structure. The gotcha: the JSON must be on a single line with no extra whitespace, and needs a `{"web": {...}}` wrapper that matches Google's download format.

### Docuseal's Search API

Docuseal's API has a `q` parameter for searching submissions, but it's a fuzzy full-text search — not an exact email filter. If you search for `john@example.com`, you might get results for anyone with "john" in their submission.

The fix: fetch all submissions for the template and filter client-side. In n8n, a Code node handles this:

```javascript
const clientEmail = $('Extract Client Info').first().json.clientEmail.toLowerCase();
const submissions = $input.first().json.data || [];

const hasExisting = submissions.some(sub =>
  sub.submitters.some(s =>
    s.role === 'Client' && s.email.toLowerCase() === clientEmail
  )
);

return { isNewClient: !hasExisting, clientEmail, clientName };
```

### n8n Webhook Quirks

When you create or update an n8n workflow via API, the webhook doesn't automatically register. You need to toggle the workflow off and on in the UI. Also, webhook payload data lives in `$json.body`, not `$json` directly — easy to miss.

## What's Next

The booking link will be embedded in automated emails sent to leads who fill out an interest form (using Formbricks, another self-hosted tool). Eventually, completed health forms could trigger a welcome email sequence or populate a client database.

## Was It Worth It?

Setting this up took an afternoon of debugging OAuth credentials and n8n quirks. But now Aaron has a professional booking system with automated paperwork — hosted on my server as a favour for a mate who's been generous with his time as a training guide over the years. I also recently built his website at [acpt.com.au](https://acpt.com.au).

The tools are all open-source, the whole stack runs alongside my other self-hosted services, and we can extend it however we want. For a small business just getting started, that's a pretty good deal.

---

*Tools used: Cal.com, Docuseal, n8n, Docker, Caddy, Portainer*
