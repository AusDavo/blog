---
title: "I Gave Claude Code Access to My Email"
date: 2026-03-16T12:00:00+10:00
draft: false
tags:
  - ai
  - self-hosting
  - mcp
  - docker
  - email
---

I've been running Claude Code as my primary development tool for months now. It writes code, reads docs, manages git — all from the terminal. But there's always been a gap: it can't see my email, my calendar, or my contacts. If I ask "what's on this week?" it has to guess. If I need to draft a reply to someone, I'm switching to the browser.

[Fastmail MCP Server](https://github.com/AusDavo/fastmail-mcp) fills that gap. MCP (Model Context Protocol) is a standard that lets AI tools call external services through a uniform interface — the AI discovers available tools, calls them with structured inputs, and gets structured outputs back. An MCP server is just a process that exposes those tools. This one connects to Fastmail's JMAP API and gives any MCP client access to 38 tools across email, contacts, and calendar.

## What It Can Do

The server exposes the full range of email operations you'd expect:

- List mailboxes, search emails, get full message content
- Send emails and reply with proper threading (In-Reply-To, References headers)
- Create and save drafts
- Bulk operations: mark read, move, delete, add/remove labels
- Download attachments
- Advanced search with filters for sender, date range, read status, attachments
- Contact search and calendar event management

The first thing I did after getting it running was ask Claude to review my last week of email and tell me what needs attention. It pulled 50 emails, categorised them, and flagged an overdue library book, an expiring GitHub token, and a meeting I had the next morning. That alone justified the setup.

## How It's Deployed

The architecture follows the same pattern as my [self-hosted memory server](/posts/self-hosted-mcp-memory-server/):

```
Claude Code ──HTTPS──▶ Caddy ──proxy──▶ MCP Server ──JMAP──▶ Fastmail API
```

- **MCP Server**: Node.js running in Docker, serving Streamable HTTP at `/mcp`
- **Auth**: Bearer token validated at the HTTP layer before requests reach the MCP protocol
- **Reverse proxy**: Caddy handles TLS termination. The container joins my existing `caddy_rev-proxy` Docker network — no ports exposed to the host
- **Transport**: Streamable HTTP, not the deprecated SSE transport

The `docker-compose.yml` is minimal:

```yaml
services:
  fastmail-mcp:
    build: .
    container_name: fastmail-mcp
    restart: unless-stopped
    expose:
      - "3000"
    environment:
      - FASTMAIL_API_TOKEN=${FASTMAIL_API_TOKEN}
      - MCP_AUTH_TOKEN=${MCP_AUTH_TOKEN}
      - MCP_HTTP_PORT=3000
    networks:
      - caddy_rev-proxy

networks:
  caddy_rev-proxy:
    external: true
```

Two tokens in the `.env` file: one for Fastmail's JMAP API, one as a Bearer token for the MCP endpoint itself. Caddy routes the subdomain to the container by name.

## The Transport Bug

The upstream server was written for single-connection use (stdio for Claude Desktop). When running over Streamable HTTP, each new client session calls `server.connect(transport)` on a shared `Server` instance. The MCP SDK doesn't allow that — you get:

```
Error: Already connected to a transport. Call close() before connecting
to a new transport, or use a separate Protocol instance per connection.
```

The first request works. The second crashes the container. Docker restarts it, the next first request works, and so on.

The fix was wrapping the server creation and handler registration in a factory function so each HTTP session gets its own `Server` instance:

```typescript
function createMcpServer() {
  const server = new Server(
    { name: 'fastmail-mcp', version: '1.7.1' },
    { capabilities: { tools: {} } }
  );

  server.setRequestHandler(ListToolsRequestSchema, async () => { /* ... */ });
  server.setRequestHandler(CallToolRequestSchema, async (request) => { /* ... */ });

  return server;
}
```

Then in the HTTP handler, each new session creates its own server:

```typescript
const sessionServer = createMcpServer();
await sessionServer.connect(transport);
```

The stdio path still works the same way — it just calls the factory once.

## API Token vs App Password

One gotcha during setup: Fastmail has two kinds of credentials and they look similar in the settings UI.

- **App passwords** (under Connected Apps) are for IMAP, SMTP, CardDAV, CalDAV. They're 16 characters.
- **API tokens** (under API tokens) are for the JMAP API. They're longer and have configurable scopes.

The MCP server needs an API token with Email, Email Submission, and Contacts scopes. Using an app password gives you a confusing "Unauthorized" error from the JMAP session endpoint with no further detail.

## What's Next

The immediate value is the daily email briefing — a quick "what did I miss overnight?" that flags actionable items. But the more interesting use cases come from combining this with other MCP servers. My memory server already stores context across conversations. Adding email means Claude can reference recent correspondence when I'm working on a project, or draft a follow-up email based on what we discussed in a previous session.

The [repo is public on GitHub](https://github.com/AusDavo/fastmail-mcp) if you want to run your own. It also works as a Claude Desktop Extension (DXT) if you don't want to self-host.
