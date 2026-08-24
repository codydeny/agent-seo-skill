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
/agent-dx-review                                      # in a site repo: detects framework, deployed URL, dev server
/agent-dx-review --url https://example.com            # audit a deployed site (works with no codebase too)
/agent-dx-review --url http://localhost:4321          # audit a local build (edge checks auto-SKIP)
/agent-dx-review --fix                                # audit, then implement fixes in this repo, re-verify
/agent-dx-review --deep --write                       # + agent-task walkthrough, saves AGENT-DX.md
/agent-dx-review status                               # re-probe and diff against the ledger
```

Three modes, resolved automatically by `scripts/detect-target.sh`:
- **Codebase + live site** (default) — probes the deployed URL *and* a local build; finds or starts the
  dev/preview server and fingerprint-confirms it is this project before trusting it.
- **URL only** — no source: audit what curl sees, emit the files to add per framework guess.
- **Browser available** — uses browser automation (e.g. Claude in Chrome) on top of curl for the
  JS-render gap, CAPTCHA/interstitials, network headers, and the accessibility tree.

1. **Detect** — `scripts/detect-target.sh` reports framework, host, deployed URL from config, dev script, and
   which local ports are serving *this* project.
2. **Probe** — `scripts/probe.sh` (bash + curl, no deps) runs ~40 deterministic live
   checks: bot access by UA, robots.txt per-bot verdicts and `Content-Signal`,
   sitemap/lastmod/404s, llms.txt validity + link rot, `.md` twins,
   `Accept: text/markdown` negotiation + `Vary`, JSON-LD, headings, alt text, feeds,
   `.well-known/*`, soft-404s, TTFB, caching headers.
3. **Audit** — the skill walks a 120-check list across 6 pillars, using probe output
   for live checks and `file:line` evidence for codebase checks. Blocking gates
   (bots blocked, JS-only shell, no sitemap, CAPTCHA on GET) cap the score at F.
4. **Report** — fix cards in the shape `ID · Status · Evidence · Why (evidence rating) ·
   Fix (file/snippet) · Verify (command)`, ranked gates → access → weight×gap.
5. **Fix** (`--fix`) — implements per framework (Astro, Next, Nuxt, SvelteKit, Remix,
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

### Auto-install (paste into your agent)
Paste this into Claude Code, Cursor, Codex, Gemini CLI, or Antigravity:

```
Fetch and follow the instructions in https://raw.githubusercontent.com/codydeny/agent-dx-harness/main/INSTALL.md
```

Already have a local copy? Paste this instead:

```
Read and follow ~/agent-dx-harness/INSTALL.md — install for every agent harness on this machine and verify each one.
```

`INSTALL.md` detects which harnesses are present, installs for each, verifies, and reports.

### Manual install

**Claude Code**
```bash
git clone https://github.com/codydeny/agent-dx-harness ~/agent-dx-harness
claude plugin marketplace add ~/agent-dx-harness
claude plugin install agent-dx@agent-dx-harness
```
Then in a new session: `/agent-dx:agent-dx-review`. (One-off without installing: `claude --plugin-dir ~/agent-dx-harness`.)

**Cursor**
```bash
git clone https://github.com/codydeny/agent-dx-harness ~/agent-dx-harness
ln -sfn ~/agent-dx-harness ~/.cursor/plugins/local/agent-dx
```
Reload Cursor ("Developer: Reload Window"); `skills/` is auto-discovered.

**Codex**
```bash
git clone https://github.com/codydeny/agent-dx-harness ~/.codex/agent-dx-harness
mkdir -p ~/.agents/skills && ln -s ~/.codex/agent-dx-harness/skills/agent-dx-review ~/.agents/skills/agent-dx-review
```

**Antigravity** (per project)
```bash
mkdir -p .agent/skills && ln -s ~/agent-dx-harness/skills/agent-dx-review .agent/skills/agent-dx-review
```
Optionally add `.agent/workflows/agent-dx-review.md` containing: `Read and follow .agent/skills/agent-dx-review/SKILL.md. Arguments: $ARGUMENTS`.

**Gemini CLI**
```bash
gemini extensions install https://github.com/codydeny/agent-dx-harness
```

**Anything else** — clone and point the agent at `skills/agent-dx-review/SKILL.md`; `AGENTS.md` does that for agents that read it. The probe runs standalone: `scripts/probe.sh https://example.com`.

### Uninstall
```bash
claude plugin uninstall agent-dx@agent-dx-harness && claude plugin marketplace remove agent-dx-harness
rm ~/.cursor/plugins/local/agent-dx ~/.agents/skills/agent-dx-review
```

## Layout
```
scripts/detect-target.sh                  codebase? framework? host? deployed URL? dev server running?
scripts/probe.sh                          deterministic live checks (bash + curl); localhost-aware
skills/agent-dx-review/SKILL.md           the procedure: resolve target → orient → audit → report → deep → fix
skills/agent-dx-review/references/
  checklist.md                            120 checks, ladders, weights, gates, grades
  bots.md                                 crawler classes, UA table, robots.txt template, CDN gotchas
  frameworks.md                           how to implement each artifact per framework/host
  evidence.md                             proven vs hype, numbers you may quote
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
