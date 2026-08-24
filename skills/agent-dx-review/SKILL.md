---
name: agent-dx-review
description: Use when the user wants their website / landing page / docs site to be discoverable, readable, citable, and operable by AI agents and LLM crawlers (ChatGPT, Claude, Perplexity, Gemini, Copilot, coding agents) — "agent DX", "AEO/GEO", "llms.txt", "markdown for agents", "agent-ready". Audits the live site AND the codebase, scores it across 6 pillars with blocking gates, then implements fixes in the repo and re-verifies.
argument-hint: "[--url https://site|http://localhost:PORT] [--fix] [--pillar A-F] [--deep] [--write] | status"
---

# Agent DX review — make a website work for agents

You are auditing and improving a **website's agent-facing surface**: what AI crawlers, answer engines, and user-driven agents see when they hit this site, and what they can do with it. You have the codebase in front of you, so you can both *detect* and *fix*. Detection is deterministic (a bash probe you cannot argue with); you supply judgment, code changes, and honest reporting.

Arguments: `$ARGUMENTS`

## Parse the request
- `--url URL` — a target to probe (deployed or local). Optional; see **Resolve the target**.
- `--fix` — after the audit, implement fixes in the codebase (default: audit + report only; in fix mode still stop for anything listed under **Never do silently**). Ignored in URL-only mode.
- `--pillar X` — restrict to one pillar (A–F).
- `--deep` — also run the agent-task walkthrough (§4) and off-site presence review.
- `--write` — save the report as `AGENT-DX.md` at the repo root (default: print). In `--fix` mode always write it; it doubles as the status ledger.
- `status` — if `AGENT-DX.md` exists, re-probe, diff against the ledger, and report what moved. Stop.

## Resolve the target (always first)
Run `bash "$HARNESS/scripts/detect-target.sh" .` where `$HARNESS` is this plugin's root (`${CLAUDE_PLUGIN_ROOT}` in Claude Code; otherwise the directory two levels above this SKILL.md). It prints `codebase=`, `framework=`, `host=`, `deployed_url=`, `dev_script=`, `expected_port=`, `running_local=`, and a `local_fingerprint` per open port. Then pick a mode:

**Mode 1 — codebase + live site (the normal case).** `codebase=yes`. Probe **both**:
- the deployed URL (`--url`, else `deployed_url=` from config; if neither, ask once) — this is where access/WAF/CDN/TTFB checks are real;
- a local build, so codebase fixes can be verified before deploy.
Local resolution order: (a) `--url http://localhost:…` given → use it; (b) a `running_local` port whose `local_fingerprint` matches this project (generator/title/site name) → use it and **tell the user which port you picked and why**; (c) a port is open but the fingerprint is a different project → do **not** use it, say so; (d) nothing running → start the dev server yourself in the background (`<pkg_manager> run dev` / `hugo server` / `jekyll serve`), wait for `expected_port` to answer, and confirm the fingerprint before probing. Stop it when done if you started it. For static-output frameworks prefer `build` + `preview` (Astro `astro preview`, Vite `vite preview`, Next `next start`) over `dev` when checking headers/`.md` routes — dev servers often skip `_headers`, middleware, or SSG outputs.
The probe auto-detects localhost and marks edge-only checks `SKIP`; never report those as PASS/FAIL from a local run. Where local and deployed disagree (e.g. `.md` route works locally, 404 in prod), that is itself a finding (deploy/adapter/CDN config).

**Mode 2 — URL only.** `codebase=no` (or the user says the code isn't here). Probe the deployed URL only. Audit everything the probe and `curl` can see; skip codebase-only checks (mark `UNKNOWN — needs source`). `--fix` becomes "emit the exact files/config to add, per `frameworks.md`, guessed from the `generator` meta / response headers / URL patterns" — say the framework guess is a guess. Never try to fix a site you can't build.

**Mode 3 — browser available.** If a browser automation tool is present (e.g. `mcp__claude-in-chrome__*` — load via ToolSearch first), use it **in addition**, never instead of `curl`, for what curl can't see:
- **JS-render gap (B1/B13):** compare visible text from `curl` vs the rendered page's `document.body.innerText`; anything only in the browser is invisible to GPTBot/ClaudeBot/PerplexityBot.
- **Challenge/CAPTCHA (A1/F1):** load the site and the signup/contact path; screenshot any interstitial, Turnstile, cookie wall, or MFA gate.
- **Network tab (F7/A13/B5):** read requests for cache headers, `Vary`, redirects, third-party bot scripts; console for hydration errors that would break SSR content.
- **Accessibility tree (F3/F4):** confirm interactive elements are real buttons/links with labels.
- **Dev-server hot path:** when a dev server is running, open it in a tab and watch console errors while you change templates.
Record browser evidence as `browser:` lines in fix cards (screenshot path or the exact DOM/network fact). If the browser isn't available, just note the checks that would have benefited.

State the resolved mode, framework, and targets in one line before auditing, e.g. `Mode 1 · astro on cloudflare · deployed https://x.com · local http://localhost:4321 (started by me)`.

Read the references you need as you go — do not load all of them up front:
`references/checklist.md` (the 120 checks, ladders, weights, gates) · `references/bots.md` (bot classes, robots.txt policy, CDN gotchas) · `references/frameworks.md` (how to implement each artifact per framework/host) · `references/evidence.md` (what is proven vs hype; numbers you may quote).

## Ground rules
- **The probe is the source of truth for live checks.** `scripts/probe.sh <url>` and `scripts/detect-target.sh` live in the harness root. Never report a live check you did not run. Never "fix" a check without re-running the probe (or the equivalent `curl`) afterwards.
- **Codebase evidence for codebase checks.** Cite `file:line` for every codebase finding (sitemap config, layout head, robots source, content schema).
- **Every finding is a fix card** with exactly these fields — `ID · Title · Status (missing|detected|implemented|validated) · Evidence · Why it matters (cite evidence.md rating) · Fix (file + snippet or config step) · Verify (command)`. This is the shape Build Bridges' scanner uses and it is the shape an engineer can act on.
- **Honest impact.** Use the ratings in `evidence.md`. llms.txt is a cheap hedge, not a growth lever; unblocking retrieval bots and SSR are the levers. Say so.
- **Contradictions are P0.** A site that ships llms.txt and `.md` twins while its CDN blocks ClaudeBot/GPTBot, or that says `ai-train=no` in robots and CC-BY in JSON-LD, is sending mixed signals; resolve the *policy* with the user before touching files.
- **Never do silently:** change robots.txt bot policy (training allow/deny is a business decision — propose the template, ask), touch WAF/CDN settings (report exact steps instead), add `.well-known` cards for services that don't exist (agent-card, mcp server-card without an endpoint), rewrite marketing copy wholesale (propose the definitional sentence; the user owns voice), add analytics/tracking.

## 1. Orient (always, ≤ 5 min)
1. Detect framework + host from manifests (`references/frameworks.md` → Detection). Note content source (MD/MDX collections, CMS, hard-coded JSX).
2. Inventory agent-facing code: routes/files producing `robots.txt`, sitemap, feeds, `llms*.txt`, `.md` endpoints, JSON-LD components, `_headers`/`vercel.json`/`wrangler.*`/middleware, `public/.well-known/`, OpenAPI/MCP routes. Grep: `llms|robots|sitemap|ld\+json|text/markdown|well-known|Content-Signal|openapi|mcp`.
3. Classify the site: **content/personal**, **SaaS landing + docs**, **API product**, **commerce**. This decides which of pillar E applies (N/A checks redistribute weight).
4. Run the probe against each resolved target (`bash "$HARNESS/scripts/probe.sh" <url>`; add `--pages N` for bigger samples). Save raw output to the scratchpad; paste the relevant lines as Evidence, labelled `deployed:` / `local:` / `browser:`.

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
