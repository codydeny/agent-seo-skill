# What actually works vs. hype — evidence ratings (Aug 2026)

Use this to prioritise and to write honest "Impact" lines. Never claim a lift the evidence doesn't support.

| Tactic | Rating | Evidence |
|---|---|---|
| Unblock search/user bots at CDN/WAF; no challenge on public GET | **Proven** | Cloudflare default-blocks since Jul 2025; SEL ChatGPT-agent study: ~2/3 of visits abandoned on challenges/errors; multiple "we were invisible to ChatGPT" post-mortems |
| SSR/SSG — content in initial HTML | **Proven** | Vercel 500M-request study: OpenAI/Anthropic/Meta/Perplexity crawlers fetch JS but never execute it |
| Clean sitemap with truthful lastmod; no 404s | **Proven** | AI crawlers show 34–35% 404 rates; Seer/Ahrefs: 65–78% of cited content updated <12 mo |
| Bing Webmaster Tools + IndexNow | **Proven** | 87% of ChatGPT-search citations match Bing top results; ChatGPT agent used Bing in 92% of cases |
| Answer-first, definitional sentences, question H2s, entity-dense, tables, stats with sources | **Strong (correlational)** | Indig 1.2M responses: 44% of citations from first 30%; tables ~4× prose; Princeton GEO: stats +41%, quotes +28%, citations +115% |
| Off-site brand mentions, listicles, Reddit, Wikipedia, YouTube | **Strong (correlational)** | Ahrefs 75k brands r=0.664; vendor's own site cited only ~11.6% of the time |
| Visible dateModified + real maintenance | **Strong** | Seer 47k citations; Position.digital median cited page age 3.9 mo |
| Plain-text pricing tables, /pricing.md, comparison pages | **Practitioner consensus** | dev.to logs show ChatGPT-User pulling pricing pages into top-3; DataDab/devcommx guides |
| JSON-LD | **Mixed** | Google: "not required for AI"; Bing/Copilot: uses it; Cloudflare md converter preserves it; correlational 65–71% of cited pages have it; Ahrefs controlled: ≈0 |
| `.md` twins + `Accept: text/markdown` | **Proven for coding agents, none for search** | Claude Code, Cursor, OpenCode send the header; ChatGPT/Perplexity don't; 99% token reduction |
| llms.txt | **No citation effect; cheap hedge** | Ahrefs 137k domains: 97% zero fetches; MaxAEO +0.2pp (noise); Otterly dropped it; Mueller: "keywords meta tag". Spec author: it's for client agents, not crawlers. llms-full.txt fetched 2× more than llms.txt |
| Content-Signal / TDMRep / AIPREF | **Legal signal only** | No vendor has committed to honouring; creates EU Art. 4 record |
| MCP server / OpenAPI / A2A card | **Real for API products, irrelevant otherwise** | Coding agents and registries consume them; empty cards hurt trust |
| ACP feed / UCP | **Real if you sell** | ChatGPT shopping (ACP feed), Google AI Mode + Shopify (UCP) live |
| Chunking to 100–300 words | **Contested** | Google says unnecessary; plausible for RAG engines |
| "80% of web traffic will be agents" | **Unsourced** | No Gartner primary; Cloudflare: bots 57.5% of HTML requests (Jun 2026) |

## Numbers you may quote (with source)
- Bots 57.5% of HTML traffic (Cloudflare, Jun 2026); AI crawlers ≈27% of verified-bot traffic; purpose split 52% training / 36% mixed / 9% search.
- Crawl-to-refer (Jul 2026): ClaudeBot 2,237:1 · GPTBot 217:1 · PerplexityBot 111:1 · Google 5:1.
- AI referrals convert 4–23× organic (Semrush, Ahrefs, Seer) — small volume, high intent.
- TollBit: 13.3% of AI bot visits bypass robots.txt (Q2 2026).
- ChatGPT cites vendor's own domain 11.6%; listicle presence r=+0.64.

## Priorities that follow
1. Access (A1, A2, F1) and rendering (B1) — everything else is moot if these fail.
2. Sitemap/lastmod/404 hygiene, Bing+IndexNow (A5–A7, A17).
3. Content shape on homepage/pricing/docs (D1–D5, B11).
4. Markdown twins + negotiation + llms.txt (B2–B7) — cheap, real for coding agents.
5. JSON-LD completeness (C1–C5) — infrastructure, not a growth hack.
6. Agent interfaces (E) — only for API/commerce products.
7. Observability (F7) — so the next review is data-driven.
