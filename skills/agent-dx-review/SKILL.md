---
name: agent-dx-review
description: Use when the user wants their website / landing page / docs site to be discoverable, readable, citable, and operable by AI agents and LLM crawlers (ChatGPT, Claude, Perplexity, Gemini, Copilot, coding agents) — "agent DX", "AEO/GEO", "llms.txt", "markdown for agents", "agent-ready". Audits the live site AND the codebase, scores it across 6 pillars with blocking gates, then implements fixes in the repo and re-verifies.
argument-hint: "[--url https://site] [--fix] [--pillar A-F] [--deep] [--write]"
---

# Agent DX review — make a website work for agents

You are auditing and improving a **website's agent-facing surface**: what AI crawlers, answer engines, and user-driven agents see when they hit this site, and what they can do with it. You have the codebase in front of you, so you can both *detect* and *fix*. Detection is deterministic (a bash probe you cannot argue with); you supply judgment, code changes, and honest reporting.

Arguments: `$ARGUMENTS`

## Parse the request
- `--url URL` — the deployed site to probe. If omitted: read it from the framework config (`site:` in astro.config, `metadataBase`/`SITE_URL` in Next, `site.url` in Nuxt, `baseURL` in Hugo, `url:` in Jekyll) or ask. If no deploy exists, start the dev server and probe `http://localhost:<port>` (mark edge-dependent checks A1/A12/A13/A14 as "untestable locally").
- `--fix` — after the audit, implement fixes in the codebase (default: audit + report only; in fix mode still stop for anything listed under **Never do silently**).
- `--pillar X` — restrict to one pillar (A–F).
- `--deep` — also run the agent-task walkthrough (§4) and off-site presence review.
- `--write` — save the report as `AGENT-DX.md` at the repo root (default: print). In `--fix` mode always write it; it doubles as the status ledger.
- `status` — if `AGENT-DX.md` exists, re-probe, diff against the ledger, and report what moved. Stop.

Read the references you need as you go — do not load all of them up front:
`references/checklist.md` (the 120 checks, ladders, weights, gates) · `references/bots.md` (bot classes, robots.txt policy, CDN gotchas) · `references/frameworks.md` (how to implement each artifact per framework/host) · `references/evidence.md` (what is proven vs hype; numbers you may quote).

## Ground rules
- **The probe is the source of truth for live checks.** Run `bash "${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/../..}/scripts/probe.sh" <url>` (fallback: `scripts/probe.sh` next to this skill's repo). Never report a live check you did not run. Never "fix" a check without re-running the probe (or the equivalent `curl`) afterwards.
- **Codebase evidence for codebase checks.** Cite `file:line` for every codebase finding (sitemap config, layout head, robots source, content schema).
- **Every finding is a fix card** with exactly these fields — `ID · Title · Status (missing|detected|implemented|validated) · Evidence · Why it matters (cite evidence.md rating) · Fix (file + snippet or config step) · Verify (command)`. This is the shape Build Bridges' scanner uses and it is the shape an engineer can act on.
- **Honest impact.** Use the ratings in `evidence.md`. llms.txt is a cheap hedge, not a growth lever; unblocking retrieval bots and SSR are the levers. Say so.
- **Contradictions are P0.** A site that ships llms.txt and `.md` twins while its CDN blocks ClaudeBot/GPTBot, or that says `ai-train=no` in robots and CC-BY in JSON-LD, is sending mixed signals; resolve the *policy* with the user before touching files.
- **Never do silently:** change robots.txt bot policy (training allow/deny is a business decision — propose the template, ask), touch WAF/CDN settings (report exact steps instead), add `.well-known` cards for services that don't exist (agent-card, mcp server-card without an endpoint), rewrite marketing copy wholesale (propose the definitional sentence; the user owns voice), add analytics/tracking.

## 1. Orient (always, ≤ 5 min)
1. Detect framework + host from manifests (`references/frameworks.md` → Detection). Note content source (MD/MDX collections, CMS, hard-coded JSX).
2. Inventory agent-facing code: routes/files producing `robots.txt`, sitemap, feeds, `llms*.txt`, `.md` endpoints, JSON-LD components, `_headers`/`vercel.json`/`wrangler.*`/middleware, `public/.well-known/`, OpenAPI/MCP routes. Grep: `llms|robots|sitemap|ld\+json|text/markdown|well-known|Content-Signal|openapi|mcp`.
3. Classify the site: **content/personal**, **SaaS landing + docs**, **API product**, **commerce**. This decides which of pillar E applies (N/A checks redistribute weight).
4. Run the probe against the deployed URL. Save raw output to the scratchpad; you will paste the relevant lines as Evidence.

## 2. Audit (always)
Walk `references/checklist.md` pillar by pillar. For each check decide **PASS / PARTIAL / FAIL / N/A / UNTESTABLE** from probe output + codebase reading; record the ladder rung. Keep two lists as you go: **gates failed** and **contradictions**.

Then compute the score: per pillar, mean of check scores (★ double, ☆ half, N/A excluded) × pillar weight; sum. Apply gates: any gate FAIL → cap at 59 and grade F. Grades: A+ 90 · A 80 · B 70 · C 60 · F.

Do not pad. A personal blog will legitimately N/A most of pillar E; say that rather than inventing an MCP server.

## 3. Report
Emit exactly:
```
# Agent DX review — <site> (<date>)
Framework/host: … · Site type: … · Probe: <url> (<n> pages sampled) · Mode: audit|fix

## Score: NN/100 (<grade>)   Gates: <passed | FAILED: A1, B1>
| Pillar | Score | Weight | Notes |
…

## Contradictions (resolve first)
- …

## Fix cards (ranked: gates → P0 access/rendering → highest weight×gap)
### A2 · robots.txt blocks retrieval bots   [FAIL → gate]
Status: detected
Evidence: probe `robots.search OAI-SearchBot=BLOCKED`; Cloudflare managed block (not in repo)
Why: Proven — blocked = absent from ChatGPT search / Claude answers (evidence.md)
Fix: Cloudflare → Security → Bots → "Block AI training" keeps GPTBot/ClaudeBot blocked but you must remove OAI-SearchBot…; repo `public/robots.txt` template (bots.md)
Verify: scripts/probe.sh <url> | grep robots.search
…

## Already good (keep)
- …

## Not scored / for the humans
- Off-site: listicles, Reddit, Wikipedia entity, G2 … (D12)
- Bing Webmaster Tools / Search Console / Brave submit (A18)
- CDN settings I can't change from the repo: …
```
If `--write` or `--fix`: save as `AGENT-DX.md` with a `## Ledger` table (`ID | status | last verified <date> | verify command`) at the end.

## 4. Deep pass (`--deep`)
1. **Agent-task walkthrough**: pick 3 tasks an agent would attempt (e.g. "What does this company do and what does it cost?", "Find the API quickstart", "Sign up / contact sales"). For each, fetch only with `curl` (no browser) plus `r.jina.ai` and read what comes back. Note every point where the answer is missing, ambiguous, JS-gated, or contradicted elsewhere. Each becomes a fix card under D or F.
2. **Token audit**: compare `curl` HTML byte size vs `.md` size for 3 pages; report the ratio (target ≤ 25%).
3. **Off-site presence** (report only): search for the brand + "alternatives", check Wikipedia/Wikidata entity, GitHub org, LinkedIn — where citations actually come from.
4. **Traffic**: if CDN logs / Cloudflare AI Crawl Control / Vercel bot analytics are accessible via CLI, pull last 30 days of AI-bot hits by class and `/llms.txt`/`.md` hit counts. Else instruct how.

## 5. Fix (`--fix`)
Work the ranked fix cards top-down. For each:
1. Confirm status `detected` and that it isn't in **Never do silently**.
2. Implement using `references/frameworks.md` for this framework/host. Generate artifacts **from the content source at build/request time**; never commit hand-written llms.txt/sitemap copies. Keep one data source for facts that appear in several places (pricing, org identity → JSON-LD, llms.txt, OG, page copy).
3. Build locally; run the dev server; `curl` the artifact (content-type, status, body head). Mark `implemented`.
4. If the user deploys (or preview URLs exist), re-run the probe and mark `validated`; otherwise leave `implemented` with the verify command in the ledger.
5. Update `AGENT-DX.md` ledger and the fix card's Status. Commit per logical group with a message naming the check IDs (e.g. `agent-dx: B4 B7 markdown twins + alternate links`) — only if the user asked for commits.

Minimum viable set for a content site with nothing in place (in order): A2 robots policy (ask) → A5/A6 sitemap+lastmod → B2/B3 llms.txt+full → B4/B7 md twins + alternate link → C1–C3 JSON-LD → A16 feed → A15 security.txt → B5 negotiation (if host allows) → D1 definitional homepage sentence (propose) → F7 observability instructions.

## 6. Finish
Recap in ≤ 10 lines: score before → after (if fixed), gates status, what you changed (files), what needs a human (CDN toggles, policy decisions, off-site work), and the single command to re-verify (`scripts/probe.sh <url>`).
