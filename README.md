# agent-dx-harness

**Make your website work for agents.** `/agent-dx-review` audits how AI crawlers,
answer engines (ChatGPT, Claude, Perplexity, Gemini, Copilot) and user-driven agents
discover, read, cite, and act on a site — then fixes it in the codebase.

Bots are now 57% of HTML traffic (Cloudflare, Jun 2026) and AI referrals convert
4–23× organic. Most sites are either invisible to the bots that matter (CDN blocks,
JS-only shells, broken sitemaps) or send contradictory signals (llms.txt + `.md`
twins *and* a robots.txt that blocks ClaudeBot). This harness finds both.

## What it does

```
/agent-dx-review --url https://example.com            # audit + scored report
/agent-dx-review --url https://example.com --fix      # audit, then implement fixes in this repo
/agent-dx-review --deep --write                       # + agent-task walkthrough, saves AGENT-DX.md
/agent-dx-review status                               # re-probe and diff against the ledger
```

1. **Probe** — `scripts/probe.sh` (bash + curl, no deps) runs ~40 deterministic live
   checks: bot access by UA, robots.txt per-bot verdicts and `Content-Signal`,
   sitemap/lastmod/404s, llms.txt validity + link rot, `.md` twins,
   `Accept: text/markdown` negotiation + `Vary`, JSON-LD, headings, alt text, feeds,
   `.well-known/*`, soft-404s, TTFB, caching headers.
2. **Audit** — the skill walks a 120-check list across 6 pillars, using probe output
   for live checks and `file:line` evidence for codebase checks. Blocking gates
   (bots blocked, JS-only shell, no sitemap, CAPTCHA on GET) cap the score at F.
3. **Report** — fix cards in the shape `ID · Status · Evidence · Why (evidence rating) ·
   Fix (file/snippet) · Verify (command)`, ranked gates → access → weight×gap.
4. **Fix** (`--fix`) — implements per framework (Astro, Next, Nuxt, SvelteKit, Remix,
   Hugo, Jekyll, Eleventy, Docusaurus, VitePress, Mintlify) and host (Cloudflare,
   Vercel, Netlify), then re-probes. Policy decisions (train-on-me or not, WAF
   changes, marketing copy) are proposed, never applied silently.

| Pillar | Weight | Question |
|---|---|---|
| A Access & Discovery | 25 | Can agents reach and find the content? |
| B Machine-Readable Content | 20 | Can they read it cheaply (SSR, llms.txt, `.md`, negotiation)? |
| C Structure & Semantics | 15 | Do they know what each page *is* (JSON-LD, headings, tables)? |
| D Answerability & Trust | 15 | Can they quote you (answer-first copy, dates, authors, facts)? |
| E Agent Interfaces | 15 | Can they act (OpenAPI, MCP, commerce protocols)? |
| F Operability & Observability | 10 | Can they complete tasks, and do you see them? |

The checklist is evidence-rated (`references/evidence.md`): unblocking retrieval bots
and SSR are *proven* levers; llms.txt is a cheap hedge with no measured citation lift;
JSON-LD is infrastructure. The report says which is which.

## Install

### Claude Code
```
/plugin marketplace add codydeny/agent-dx-harness
/plugin install agent-dx@agent-dx-harness
```
Local: `claude --plugin-dir ~/agent-dx-harness`, then `/agent-dx:agent-dx-review`.

### Cursor
```bash
git clone https://github.com/codydeny/agent-dx-harness
ln -sfn "$(pwd)/agent-dx-harness" ~/.cursor/plugins/local/agent-dx
```
Reload; `skills/` and `commands/` are auto-discovered.

### Codex
```
Fetch and follow instructions from https://raw.githubusercontent.com/codydeny/agent-dx-harness/main/.codex/INSTALL.md
```

### Antigravity
```bash
mkdir -p .agent/skills && ln -s "$(pwd)/agent-dx-harness/skills/agent-dx-review" .agent/skills/agent-dx-review
```
Optionally copy `commands/agent-dx-review.md` to `.agent/workflows/` and point it at `.agent/skills/agent-dx-review/SKILL.md`.

### Gemini CLI
```bash
gemini extensions install https://github.com/codydeny/agent-dx-harness
```

### Anything else
Clone and point the agent at `skills/agent-dx-review/SKILL.md`; `AGENTS.md` does that for agents that read it. The probe runs standalone: `scripts/probe.sh https://example.com`.

## Layout
```
scripts/probe.sh                          deterministic live checks (bash + curl)
skills/agent-dx-review/SKILL.md           the procedure: orient → audit → report → deep → fix
skills/agent-dx-review/references/
  checklist.md                            120 checks, ladders, weights, gates, grades
  bots.md                                 crawler classes, UA table, robots.txt template, CDN gotchas
  frameworks.md                           how to implement each artifact per framework/host
  evidence.md                             proven vs hype, numbers you may quote
commands/agent-dx-review.md               slash-command wrapper (Claude Code, Cursor)
AGENTS.md                                 entry point for Codex / Antigravity / others
.claude-plugin/ .cursor-plugin/ .codex/ gemini-extension.json   install glue
```

## Prior art
Build Bridges' ARI (5 pillars, blocking gates, `missing→detected→implemented→validated`),
Vercel's content-negotiation and bot-taxonomy posts, Cloudflare Markdown for Agents and
Content Signals, llmstxt.org, Mintlify's agent headers, and the Ahrefs / Seer / Indig
citation studies. See `references/evidence.md` for sources.

## License
MIT
