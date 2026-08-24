# AI bots, crawler classes, and robots.txt policy (Aug 2026)

## Three classes — decide policy per class, not per vendor

| Class | What blocking costs you | Honours robots.txt? |
|---|---|---|
| **Training crawlers** | Nothing visible: excluded from future model weights only | Mostly yes (Bytespider, some CN bots: no) |
| **Search/index crawlers** | You disappear from that assistant's answers and citations | Yes |
| **User-triggered fetchers** | A human asked their agent for your page; blocking = broken UX for them | Often *no* by design (ChatGPT-User, Perplexity-User documented as ignoring) |

## User-agent tokens

| Token | Operator | Class | IP list / verify |
|---|---|---|---|
| GPTBot | OpenAI | training | openai.com/gptbot.json |
| OAI-SearchBot | OpenAI | search (ChatGPT search) | openai.com/searchbot.json |
| ChatGPT-User | OpenAI | user | openai.com/chatgpt-user.json; `Signature-Agent: https://chatgpt.com` |
| OAI-AdsBot | OpenAI | ads landing check | openai.com/adsbot.json |
| ClaudeBot | Anthropic | training | claude.com/crawling/bots.json |
| Claude-SearchBot | Anthropic | search | same |
| Claude-User | Anthropic | user | same |
| anthropic-ai, Claude-Web | Anthropic (legacy) | — | keep in lists |
| Googlebot | Google | search + **AI Overviews + AI Mode** | rDNS |
| Google-Extended | Google | *token*: opts out of Gemini training/grounding; does NOT remove you from AI Overviews | — |
| GoogleAgent-Mariner, Google-NotebookLM, GoogleAgent-URLContext | Google | user | Web Bot Auth `https://agent.bot.goog` |
| Bingbot | Microsoft | search → Bing, **Copilot, ChatGPT search, DuckDuckGo** | rDNS |
| PerplexityBot | Perplexity | search | perplexity.com/perplexitybot.json |
| Perplexity-User | Perplexity | user (ignores robots) | perplexity.com/perplexity-user.json |
| Applebot | Apple | search (Siri/Spotlight; renders JS) | rDNS |
| Applebot-Extended | Apple | training token | — |
| CCBot | Common Crawl | training dataset | — |
| Bytespider, TikTokSpider | ByteDance | training (ignores robots) | — |
| Amazonbot | Amazon | Alexa/Rufus + training | — |
| meta-externalagent | Meta | training/index | — |
| meta-externalfetcher | Meta | user | — |
| meta-webindexer | Meta | search | — |
| DuckAssistBot | DuckDuckGo | answers (no training) | — |
| MistralAI-User / -Index / -Training | Mistral | user / search / training | mistral.ai/*-ips.json |
| YouBot | You.com | search | — |
| cohere-ai, cohere-training-data-crawler | Cohere | user / training | — |
| Ai2Bot, Ai2Bot-Dolma | Ai2 | training | — |
| Diffbot, ImagesiftBot, Timpibot, Webzio-Extended, omgili | data brokers | resale | — |
| DeepSeekBot, PanguBot, TongyiBot, YiyanBot, Kimi-User | CN labs | training/user | — |
| Claude-Code, Cursor, opencode, Devin, Manus-User, Operator | coding/browser agents | user | — |

Full community list (~200 tokens): github.com/ai-robots-txt/ai.robots.txt

## Which index feeds which assistant
Bing → ChatGPT search, Copilot, DuckDuckGo · Google → Gemini, AI Mode, AI Overviews · Brave → Claude · Perplexity → own index · Mistral → MistralAI-Index.
So: **Bing Webmaster Tools + IndexNow** matter as much as Google Search Console.

## robots.txt template — "cite me, don't train on me"
```
# Content Signals Policy (https://contentsignals.org)
User-agent: *
Content-Signal: search=yes, ai-input=yes, ai-train=no
Allow: /
Disallow: /api/internal/
Disallow: /admin/

# Training-only crawlers (blocking these does NOT affect AI search answers)
User-agent: GPTBot
User-agent: ClaudeBot
User-agent: Google-Extended
User-agent: Applebot-Extended
User-agent: CCBot
User-agent: Bytespider
User-agent: Amazonbot
User-agent: meta-externalagent
User-agent: anthropic-ai
User-agent: cohere-training-data-crawler
User-agent: Ai2Bot
Disallow: /

# Search + user-triggered agents stay allowed via * above:
# OAI-SearchBot, ChatGPT-User, Claude-SearchBot, Claude-User, PerplexityBot,
# Perplexity-User, Bingbot, Googlebot, Applebot, DuckAssistBot, MistralAI-User, meta-webindexer

Sitemap: https://example.com/sitemap.xml
```
"Train on me too" variant: drop the training block and set `ai-train=yes`.

## Cloudflare gotchas
- Managed robots.txt ("block AI training") injects a block that Disallows GPTBot, ClaudeBot, Google-Extended, CCBot, Amazonbot, Bytespider, Applebot-Extended, meta-externalagent and adds `Content-Signal: search=yes,ai-train=no` — but **no `ai-input`**. It lives outside your repo; document it in `AGENT-DX.md`.
- AI Crawl Control "Block AI bots" one-click blocks *retrieval and user* bots too. New default from **15 Sept 2026**: Agent bots blocked on ad-monetised pages.
- Markdown for Agents auto-sets `Content-Signal: ai-train=yes, search=yes, ai-input=yes` unless origin sends its own header — set yours.
- Bot Fight Mode / Super Bot Fight Mode challenges break ChatGPT-User/Claude-User. WAF skip rule: `(cf.bot_management.verified_bot and cf.verified_bot_category in {"AI Assistant" "AI Search" "Search Engine Crawler"})`.

## Vercel gotchas
- "AI Bots" managed ruleset in Deny blocks GPTBot, ClaudeBot **and ChatGPT-User**; set to Log. Attack Challenge Mode passes verified bots only.

## Other signals
- `X-Robots-Tag: noai, noimageai` (DeviantArt convention), `nosnippet`/`max-snippet` (only page-level control over Google AI Overviews).
- IETF AIPREF (draft): `Content-Usage: train-ai=n, search=y` header — watch, don't ship yet.
- TDMRep: `/.well-known/tdmrep.json`, `tdm-reservation: 1` header — EU Art. 4 reservation.
- Web Bot Auth (RFC 9421): `Signature-Agent`, `Signature-Input`, `Signature`; keys at `/.well-known/http-message-signatures-directory`.
