# Agent DX checklist — 120 checks across 6 pillars

Each check: **ID** · what to detect (codebase and/or live) · score ladder (0→max, partial credit for each rung) · fix · verify.
Weight column is the pillar weight; within a pillar, checks are equal unless marked ★ (double) or ☆ (half).
**Gate** = blocking: any FAIL on a gate caps the total score at 59 (F) regardless of everything else.

Pillars & weights (sum 100):
| # | Pillar | Question an agent asks | Weight |
|---|---|---|---|
| A | Access & Discovery | Can I reach and find your content at all? | 25 |
| B | Machine-Readable Content | Can I read it cheaply and accurately? | 20 |
| C | Structure & Semantics | Can I understand what each page *is*? | 15 |
| D | Answerability & Trust | Can I quote you as a source and trust the facts? | 15 |
| E | Agent Interfaces | Can I *act* — call an API, tool, or checkout? | 15 |
| F | Operability & Observability | Can I complete tasks, and do you know I was here? | 10 |

---

## A. Access & Discovery (25)

| ID | Check | Ladder | Fix | Verify |
|---|---|---|---|---|
| A1 ★ **Gate** | Retrieval & user-triggered bots get 200 (OAI-SearchBot, ChatGPT-User, Claude-SearchBot, Claude-User, PerplexityBot, Perplexity-User, Bingbot, Googlebot) | any 403/503/challenge=0 · all 200=max | Cloudflare: AI Crawl Control → allow those UAs; WAF skip rule for `cf.verified_bot_category in {"AI Assistant","AI Search","Search Engine Crawler"}`; Vercel: AI Bots ruleset → Log; remove Bot Fight Mode challenge on public GET | `probe.sh` access.* all PASS |
| A2 ★ **Gate** | robots.txt exists, `text/plain`, parses; does not `Disallow: /` for `*` or for search/user bots | missing=0 · exists but blocks search/user bots=0 · exists, allows=max | Write policy per bot class (see bots.md); on Cloudflare check "managed robots.txt" block matches intent | probe `robots.search`, `robots.user` no BLOCKED |
| A3 | Training-crawler policy is *deliberate* (GPTBot, ClaudeBot, Google-Extended, CCBot, Bytespider, Amazonbot, meta-externalagent, Applebot-Extended) | unlisted (default allow by accident)=half · explicit allow or disallow=max | Explicit UA groups; note blocking GPTBot/ClaudeBot does not affect ChatGPT search / Claude answers (those use OAI-SearchBot / Claude-SearchBot / Brave) | probe `robots.train` shows explicit verdicts |
| A4 | `Content-Signal:` line in robots.txt (`search=yes, ai-input=yes|no, ai-train=yes|no`) | none=0 · present=max | Add under `User-agent: *` group; `ai-input=yes` if you want to be cited | probe `robots.content-signal` |
| A5 ★ **Gate** | XML sitemap exists, is XML (not SPA HTML), referenced from robots.txt `Sitemap:` | missing/HTML=0 · exists=half · +in robots=max | Framework sitemap integration; `Sitemap:` line | probe `sitemap`, `sitemap.in-robots` |
| A6 | Sitemap `<lastmod>` present and **truthful** (from content dates, not build time) | none=0 · all same timestamp=quarter · real=max | Feed `updated`/git date into sitemap serializer | probe `sitemap.lastmod`; diff two builds |
| A7 | Sitemap URLs all 200, canonical form (no redirects, no 404s) — AI crawlers already see ~35% 404s | any 404/301=0 per 10% | Filter drafts/redirects; run link check in CI | probe `pages.status` |
| A8 | Sitemap excludes junk (tag pages, pagination, search, 404, HTML sitemap page) unless valuable | junk present=half | `filter()` in sitemap config | inspect |
| A9 | Canonical `<link>` on every page, absolute, self-referencing, resolves 200 | none=0 · present=half · resolves=max | Layout head; per-page (SPAs often ship homepage canonical everywhere) | curl each page |
| A10 | Real 404 status for missing pages (no soft-404) | soft=0 · real=max | Framework 404 route returns 404 | probe `http.404` |
| A11 | No redirect chains; http→https single hop; www/non-www canonical | chains=half | Host config | `curl -I` |
| A12 | TTFB < 1 s on HTML; total < 2 s | >3s=0 · 1–3s=half · <1s=max | Cache HTML at edge; SSG | probe `home.ttfb` |
| A13 | `ETag`/`Last-Modified` on HTML and .md → conditional fetches | none=0 | Enable on host/CDN (Cloudflare strips on md-conversion) | probe `hdr.cache` |
| A14 | HTTPS + HSTS + basic security headers (domain trust signal) | no HSTS=half | Host config | probe `hdr.hsts` |
| A15 | `/.well-known/security.txt` (RFC 9116: `Contact:`, `Expires:`) served `text/plain` | missing=0 · HTML fallback=0 · ok=max | `public/.well-known/security.txt` | probe `security.txt` |
| A16 | Feeds: RSS/Atom (and JSON Feed) exist, are XML/JSON, `<link rel=alternate>` in head, listed in llms.txt | none=0 · exists=half · +head link=max | `@astrojs/rss`, `feed` npm, jekyll-feed… | probe `feed`, `feed.link` |
| A17 | IndexNow key file + ping on publish (Bing index → ChatGPT search, Copilot, DuckDuckGo) | none=0 · key=half · pings on deploy=max | `/{key}.txt`, POST api.indexnow.org in deploy hook | `curl /{key}.txt` |
| A18 ☆ | Registered in Bing Webmaster Tools, Google Search Console; submitted to Brave (Claude's index) | unknown=INFO | Manual — report as TODO | — |
| A19 ☆ | No `Crawl-delay` that starves search bots; rate limits exempt verified bots | — | WAF rule | logs |
| A20 ☆ | `humans.txt`/`/about` with real org identity (name, address, founders) reachable without JS | — | static page | curl |

## B. Machine-Readable Content (20)

| ID | Check | Ladder | Fix | Verify |
|---|---|---|---|---|
| B1 ★ **Gate** | Primary content is in the initial HTML (SSR/SSG) — GPTBot, ClaudeBot, PerplexityBot, Meta do not execute JS | <800 chars text=0 · partial (hero only)=half · full=max | SSG/SSR the route; pre-rendered `<article>` block + `<noscript>` for SPAs | probe `render.ssr`; `curl -A GPTBot` and read |
| B2 ★ | `/llms.txt` exists, spec-exact: `# Title`, `> summary`, `## sections` of `- [title](url.md): note`, `## Optional` | missing=0 · malformed=quarter · valid=half · +links resolve+.md targets=max | Generate from sitemap/content collection at build; never hand-maintain | probe `llms.*` |
| B3 | `/llms-full.txt` (all content concatenated, with per-doc metadata headers) — fetched 2× more than llms.txt by agents | missing=0 · present=max | Build-time concat of source markdown | curl size > 0, starts with `#` |
| B4 ★ | Every content page has a Markdown twin at `<url>.md` (or `/index.md`), `Content-Type: text/markdown; charset=utf-8` | 0%=0 · some=prorated · all=max | Endpoint returning source markdown with frontmatter (title, canonical, updated) — never HTML→MD if source exists | probe `md.suffix` |
| B5 | `Accept: text/markdown` negotiation on HTML URLs (Claude Code, Cursor, OpenCode send it) with `Vary: Accept` | none=0 · yes w/o Vary=quarter · yes+Vary=max | Middleware/worker/rewrite (frameworks.md §2b); or Cloudflare Markdown for Agents (Pro+) | probe `md.negotiate`, `md.vary` |
| B6 | Markdown twins are `X-Robots-Tag: noindex` and carry canonical → HTML (cloaking safety) | missing=half | `_headers` / route headers | `curl -I page.md` |
| B7 | `<link rel="alternate" type="text/markdown" href>` in every page head; `Link:` header with `rel="llms-txt"`, `rel="llms-full-txt"` | none=0 · head link=half · +header=max | Layout + host headers | probe `md.link`, `hdr.link` |
| B8 | Markdown output keeps: title, description, dates, author, canonical URL, headings, tables, code fences, image alt, links absolute | missing fields=prorated | Template the frontmatter block | read one .md |
| B9 | Markdown twin token count is ≤ 25% of HTML token count (else it's not clean) | — | Strip nav/footer/boilerplate | `x-markdown-tokens` or wc |
| B10 | Homepage / landing page also has a markdown twin (`/index.md`) and appears in llms.txt | missing=0 | Same endpoint | curl |
| B11 | Pricing page has plain-text/table pricing and a `/pricing.md` (plan, price, currency, period, limits, trial, last-updated) | JS slider/image only=0 · table=half · +md=max | Author `/pricing.md`; render table from same data | curl |
| B12 | Docs site exposes `/docs/llms.txt` scoped index (if docs are large) | — | Plugin option | curl |
| B13 ☆ | No content behind tabs/accordions/carousels/infinite-scroll/"read more" that require JS to reveal | hidden=half | Render all; progressive enhancement | diff `curl` vs browser text |
| B14 ☆ | No cookie/consent wall or interstitial in initial HTML that pushes content below noise | wall=half | Gate visually, not in DOM order; or skip for verified bots | curl text head |
| B15 ☆ | Text is text — no headings/pricing/CTAs as images or SVG-only | — | Replace | inspect |
| B16 ☆ | Reasonable page size (< 2 MB HTML; Cloudflare converter limit) | >2MB=0 | Trim | `curl -w size` |

## C. Structure & Semantics (15)

| ID | Check | Ladder | Fix | Verify |
|---|---|---|---|---|
| C1 ★ | JSON-LD on every page: site-level `@graph` (Organization/Person + WebSite [+SearchAction]) and page-type node (Article/BlogPosting, Product/Offer, SoftwareApplication, FAQPage, HowTo, Event, LocalBusiness, Dataset). JSON-LD survives Cloudflare's markdown conversion — it is the one script that reaches agents | none=0 · site-level only=quarter · +page type=half · +complete required props=max | Layout + per-template schema components (frameworks.md §5) | probe `schema.present`, `pages.schema`; validator.schema.org |
| C2 | Organization node: `name, url, logo, sameAs[]` (LinkedIn, GitHub, X, Wikipedia/Wikidata, Crunchbase), `contactPoint`, `foundingDate`, `address` | prorated by fields | Fill | inspect |
| C3 | Article nodes: `headline, datePublished, dateModified, author{Person,url,sameAs}, publisher, image, mainEntityOfPage, wordCount, keywords` | prorated | Fill | inspect |
| C4 | Authorship: Person author with `url`+`sameAs` (verified > unverified person > org > string > none) | ladder as listed | Author pages + schema | inspect |
| C5 | `BreadcrumbList` JSON-LD (structured > ARIA-only > CSS-only > none) | ladder | Add | inspect |
| C6 | Exactly one `<h1>`; no skipped heading levels; headings phrased as the question the section answers where natural | multi-h1/skips=half | Templates | probe `pages.h1`; heading outline |
| C7 | Landmarks: `<main>`, `<article>`, `<nav>`, `<header>`, `<footer>`, `<aside>` so converters trim boilerplate | none=0 | Templates | probe `html.main` |
| C8 | Tables as `<table>` (cited ~4× more than prose); lists as `<ul>/<ol>`; code in `<pre><code>`; quotes in `<blockquote>` | div-tables=half | Rewrite | inspect converters' output |
| C9 | Every `<img>` has descriptive `alt`; diagrams have text alternative; `<figure>/<figcaption>` | missing alt=prorated | Fix | probe `html.alt` |
| C10 | `<time datetime>` for dates; visible "Updated on" on content pages | none=half | Template | inspect |
| C11 | `<html lang>`, `hreflang` alternates if multilingual, consistent canonical per language | — | Head | probe `html.lang` |
| C12 | Open Graph + Twitter card complete (title, description, image 1200×630, url, type, site_name) — first thing link fetchers extract | prorated | Metadata API | probe `meta.og` |
| C13 | `<title>` and `meta description` unique, descriptive, ≤ 60/160 chars, contain the entity name | weak/dup=half | Per page | inspect |
| C14 ☆ | Internal linking: every page reachable ≤ 3 clicks from home via real `<a href>`; no orphan pages; no link rot | broken links=prorated | Link check in CI | crawler |
| C15 ☆ | License/usage signals in schema (`license`, `usageInfo`, `copyrightHolder`) consistent with robots Content-Signal and footer text | contradictory=0 | Align | inspect |

## D. Answerability & Trust (15)

| ID | Check | Ladder | Fix | Verify |
|---|---|---|---|---|
| D1 ★ | Homepage first 300 words state, in plain prose: **who/what you are, for whom, what you do, where, since when** ("X is a … that …") — 44% of citations come from the first 30% of a page | vague=0 · clear=max | Rewrite hero copy; add definitional sentence | read `curl` text |
| D2 | Each key page opens with a direct answer/definition before narrative; question-shaped H2s followed by 40–120-word answer paragraphs | — | Editorial | inspect |
| D3 | Facts are explicit and quotable: numbers, dates, named entities, comparisons in words ("includes API access on the $29 tier") not adjectives/checkmarks | — | Editorial | inspect |
| D4 | Freshness: content pages show `dateModified` and are actually maintained; sitemap lastmod agrees | stale >12mo on key pages=half | Review cadence | compare dates |
| D5 | FAQ section on landing/pricing/product pages with real questions (+ FAQPage schema, still valid though Google dropped rich result) | none=0 | Add | inspect |
| D6 | Comparison / "alternatives" / "vs" pages with a table near the top and a "when to choose a competitor" section (top B2B citation asset) | — | Content plan (report as TODO) | — |
| D7 | Entity consistency: name, tagline, pricing, founding facts identical across site, JSON-LD, llms.txt, OG, and (report) LinkedIn/G2/Wikipedia/GitHub | contradictions=0 | Single source of truth in config | grep |
| D8 | About/Team/Contact/Legal pages exist, are static HTML, and are linked in footer and llms.txt | missing=0 | Add | curl |
| D9 | Author pages with bio, credentials, `sameAs` (E-E-A-T) | — | Add | curl |
| D10 | Citations/sources in content (outbound links to primary sources, statistics with attribution) — +30–40% citation likelihood | — | Editorial | inspect |
| D11 ☆ | Reviews/testimonials as text with names and dates (count matters more than stars) | — | — | inspect |
| D12 ☆ | Off-site presence checklist reported (not scored): listicles, Reddit, YouTube, Wikipedia/Wikidata entity, G2/Capterra, GitHub org — where 70%+ of AI citations actually come from | INFO | Report as TODO | — |
| D13 ☆ | Pricing/plan facts in JSON-LD `Offer`s match the pricing page | mismatch=0 | Generate both from one data file | diff |

## E. Agent Interfaces (15) — score only what applies; "no API product" ⇒ E1–E6 become N/A and weight redistributes

| ID | Check | Ladder | Fix | Verify |
|---|---|---|---|---|
| E1 ★ | OpenAPI 3.1 spec published at a stable URL (`/openapi.json`), linked from llms.txt and `Link: rel="service-desc"`; `/.well-known/api-catalog` (RFC 9727) | none=0 · spec=half · +catalog+links=max | Generate from router (zod-openapi, FastAPI, etc.) | curl + validate |
| E2 ★ | Remote MCP server (Streamable HTTP) exposing search/read/act tools; `/.well-known/mcp/server-card.json` (+ `mcp.json` alias); listed in MCP Registry | none=0 · card only=quarter · server=half · +registry=max | `mcp-handler` (Vercel), Cloudflare `McpAgent`, Mintlify auto | MCP `initialize` POST |
| E3 | Agent-friendly auth: OAuth 2.1 + RFC 8414/9728 well-known metadata, or API keys obtainable without CAPTCHA/email-verify loops; scoped tokens | — | Auth server metadata | curl well-known |
| E4 | API errors are structured (`application/problem+json` or `{code,message,next_steps}`), include `Retry-After`/rate-limit headers, disclose limits in docs or health endpoint | — | Error middleware | curl bad request |
| E5 | Idempotency keys on mutating endpoints; versioned API (`/v1`, `API-Version` header); deprecation headers | — | — | docs |
| E6 | Webhooks/events for state changes; batch endpoints; pagination documented | — | — | docs |
| E7 | Commerce: schema.org `Product/Offer` complete; ACP product feed (OpenAI/Stripe) and/or `/.well-known/ucp` (Google/Shopify) if selling | N/A if no commerce | Feed + well-known | curl |
| E8 | A2A `/.well-known/agent-card.json` **only if** you run an A2A agent (else omit — empty cards hurt trust) | present w/o endpoint=0 | — | curl |
| E9 | `Content-Signal` HTTP header on responses; `/.well-known/tdmrep.json` if EU rights reservation matters | INFO | Host header | curl -I |
| E10 ☆ | Skills/agent instructions for your product: `/skills.md` or `/.well-known/agent-skills/index.json`; "Instructions for agents" section in llms.txt (Stripe pattern) | — | Author | curl |
| E11 ☆ | Web Bot Auth: verify `Signature-Agent` at edge and allow signed agents through challenges; if you run agents, sign requests | INFO | WAF rule | logs |
| E12 ☆ | Health endpoint (`/api/health`) public, JSON, includes rate-limit policy | — | Add | curl |

## F. Operability & Observability (10)

| ID | Check | Ladder | Fix | Verify |
|---|---|---|---|---|
| F1 ★ **Gate** | No CAPTCHA / JS challenge / MFA on public GET paths or on the primary conversion path (signup, contact, docs) — agents abandon on challenge | challenge on public GET=0 | WAF exemptions; Turnstile only on POST after failure | probe `access.*`; walk signup with curl |
| F2 | Forms: native `<form>` with `<label for>`, stable `name`/`id`, server-side validation messages in HTML, no email-verification gate before value | — | Rebuild form | inspect |
| F3 | Interactive elements are real `<a href>` / `<button>` (not div+onClick); actions reflected in DOM/URL; stable layout | — | Fix | accessibility tree |
| F4 | WCAG basics pass (axe: labels, contrast, roles) — the accessibility tree is what browser agents drive | — | Fix | axe |
| F5 | URL navigability: state in URL (query params for filters/search), deep links work, no session-only routes | — | Router | curl deep link |
| F6 | Error pages are useful: 404/500 include search, nav, and a machine-readable hint; markdown 404 for `.md` requests | — | Templates | curl |
| F7 | Bot/agent traffic is observable: CDN logs or analytics segment by bot class (train/search/user), AI referrers tracked (chatgpt.com, perplexity.ai, claude.ai, gemini.google.com, copilot.microsoft.com), `/llms.txt` and `.md` hits counted | none=0 · logs=half · dashboard=max | Cloudflare AI Crawl Control / Vercel bot analytics / log query | show report |
| F8 | Citation monitoring: a fixed prompt panel run monthly against ChatGPT/Perplexity/Claude/Gemini, or a tool (Otterly/Peec/Profound) | INFO | Report as TODO | — |
| F9 ☆ | Rate limiting exempts verified bots; `Retry-After` on 429 | — | WAF | curl |
| F10 ☆ | `robots.txt`, `llms.txt`, sitemap, feeds regenerate automatically on every deploy (no hand-maintained copies) | manual=half | Build pipeline | inspect source |

---

## Critical-failure shortlist (instant F regardless of score)
1. Search/user bots blocked at WAF or robots (A1/A2)
2. JS-only shell with no content in HTML (B1)
3. Sitemap missing or returns HTML (A5)
4. CAPTCHA/challenge on public GET (F1)
5. Contradictory signals: site serves llms.txt/.md *and* blocks the bots that would read them (A2×B2)

## Grades
A+ 90–100 · A 80–89 · B 70–79 · C 60–69 · F <60 (or any gate failed)
