# Implementation cookbook — per framework and host

Detect the framework from the manifest, then use the matching recipe. Prefer **source markdown** over HTML→MD conversion whenever content is authored in MD/MDX/CMS. Every generated file must be produced at build/request time from the content source — never hand-maintained copies.

## Detection
| Signal | Framework |
|---|---|
| `astro.config.*` | Astro |
| `next.config.*` + `app/` | Next.js App Router |
| `nuxt.config.*` | Nuxt |
| `svelte.config.*` | SvelteKit |
| `react-router.config.*` / `remix.config.*` | Remix / RR7 |
| `hugo.toml|yaml|json` / `config.toml` + `layouts/` | Hugo |
| `_config.yml` + `_posts/` | Jekyll |
| `eleventy.config.*` / `.eleventy.js` | Eleventy |
| `docusaurus.config.*` | Docusaurus |
| `.vitepress/config.*` | VitePress |
| `docs.json` / `mint.json` | Mintlify (most of this is built in) |
| `wrangler.*` | Cloudflare Workers/Pages host |
| `vercel.json` / `.vercel/` | Vercel host |
| `netlify.toml` | Netlify host |

## 1. llms.txt + llms-full.txt
- **Next.js**: `app/llms.txt/route.ts` returning `text/plain; charset=utf-8` built from your content source (`export const dynamic = 'force-static'`). Packages: `@vllnt/next-llms` (`generateLlmsText`, `generateLlmsFullText`, `createMarkdownRoute`), `next-llms-txt`.
- **Astro**: `@4hse/astro-llms-txt` integration (`docSet` for full/small variants) or manual `src/pages/llms.txt.ts` using `getCollection()`.
- **Nuxt**: `nuxt-llms` (`llms: { domain, title, description, sections, full }`; auto-adds `@nuxt/content` collections, `/raw/*.md` links) or `nuxt-ai-ready` (also does .md routes + negotiation).
- **SvelteKit**: `src/routes/llms.txt/+server.ts` with `export const prerender = true`; `import.meta.glob('/src/content/**/*.md', {query:'?raw'})`.
- **Remix/RR7**: resource route `routes/llms[.]txt.tsx` loader returning `Response`.
- **Hugo**: custom output format `[outputFormats.llms] baseName="llms" mediaType="text/plain" isPlainText=true`, `outputs.home = ["HTML","RSS","llms"]`, template `layouts/_default/index.llms.txt`.
- **Jekyll**: root `llms.txt` with `layout: null` front matter and Liquid loop over `site.posts`; `include: [.well-known, llms.txt]`.
- **Eleventy**: `eleventy-plugin-llms` or `src/llms.njk` with `permalink: /llms.txt`.
- **Docusaurus**: `docusaurus-plugin-llms` (`generateLLMsTxt`, `generateLLMsFullTxt`, `generateMarkdownFiles`, `addMdExtension`) or `@signalwire/docusaurus-plugin-llms-txt`.
- **VitePress**: `vitepress-plugin-llms` (`generateLLMsFullTxt: true`).
- **Mintlify**: built in (`/llms.txt`, `/llms-full.txt`, `.md`, headers).

llms.txt body template:
```
# {Site name}

> {One paragraph: who/what/for whom.}

{2–4 sentences of context. For API products add an "Instructions for agents" paragraph.}

## {Section}
- [{Title}]({absolute url}.md): {one-line description}

## Optional
- [Full content](https://…/llms-full.txt): everything concatenated
- [Sitemap](https://…/sitemap.xml)
- [RSS](https://…/rss.xml)
```

## 2. Markdown twin per page
### 2a `.md` sibling routes (works everywhere, no header support needed)
- **Astro**: `src/pages/blog/[slug].md.ts` endpoint returning `entry.body` with a frontmatter block; or integration `@jdevalk/astro-markdown-alternate` (adds `<link rel=alternate>` + `_headers`), `astro-llms-md`, `astro-markdown-for-agents`.
- **Next.js**: route handler under a distinct folder, e.g. `app/md/[...slug]/route.ts`, plus `rewrites()` mapping `/:path*.md` → `/md/:path*` (`@vllnt/next-llms` `createMarkdownRoute`).
- **Nuxt**: `nuxt-llms` + `@nuxt/content` → `/raw/<path>.md`; `nuxt-ai-ready` emits `.md` routes.
- **SvelteKit**: `src/routes/[...path].md/+server.ts`.
- **Hugo**: `outputs.page = ["HTML","markdown"]` with `[outputFormats.markdown] baseName="index" mediaType="text/markdown" isPlainText=true` and `layouts/_default/single.md` printing front matter + `{{ .RawContent }}`; head: `{{ with .OutputFormats.Get "markdown" }}<link rel="alternate" type="text/markdown" href="{{ .Permalink }}">{{ end }}`.
- **Eleventy**: paginated template `permalink: '{{ post.url }}index.md'` outputting `{{ post.rawInput }}`; `_headers`: `/*.md → Content-Type: text/markdown; charset=utf-8` + `X-Robots-Tag: noindex`.
- **Jekyll**: duplicate page with `layout: null`, or link raw source.
- **Docusaurus**: `generateMarkdownFiles: true`.

Markdown twin template:
```
---
title: {title}
description: {description}
canonical: {html url}
published: {date}
updated: {date}
author: {name}
---
# {title}

> {description}

{body}
```
Headers on `.md`: `Content-Type: text/markdown; charset=utf-8`, `X-Robots-Tag: noindex`, `Vary: Accept` if negotiated, optional `x-markdown-tokens`.

### 2b `Accept: text/markdown` negotiation
Rule: serve markdown when `text/markdown` is acceptable with q>0 and q ≥ `text/html`; always append `Vary: Accept`; keep JSON-LD.
- **Next.js**: `next.config` `rewrites.beforeFiles` with `has: [{type:'header', key:'accept', value:'(.*)text/markdown(.*)'}]` → `/md/:path*` (Vercel's own approach); or `proxy.ts`/`middleware.ts` `NextResponse.rewrite`. Packages: `accept-md` (`npx accept-md@latest init`), `next-md-negotiate`.
- **Astro**: `src/middleware.ts` (`defineMiddleware`) — needs SSR (`output:'server'` or `prerender=false`) or push to the edge (Worker below).
- **Nuxt**: `server/middleware/markdown.ts` (`getRequestHeader(event,'accept')`, `setResponseHeaders`).
- **SvelteKit**: `src/hooks.server.ts` `handle` — check accept, return markdown `Response`, else `resolve(event)` + `Vary`.
- **Remix/RR7**: in the route `loader` or `entry.server.tsx`.
- **Cloudflare Worker over static assets** (`wrangler.jsonc` `assets.run_worker_first: ["*"]`): on `Accept: text/markdown`, `env.ASSETS.fetch(<path>/index.md)`; set `Content-Type`, `Vary`, `Content-Signal`; on HTML append `Link: </path/index.md>; rel="alternate"; type="text/markdown"`.
- **Cloudflare zone toggle** (Pro+): AI Crawl Control → Markdown for Agents, or `PATCH /zones/{id}/settings/content_converter {"value":"on"}`. Set your own `Content-Signal` header at origin first.
- **Vercel static**: `vercel.json` rewrite with `has` accept header → `/:path*.md`; `headers` for `.md`.
- **Netlify**: edge function (`config.header: {accept: 'text/markdown'}`) fetching the prebuilt `index.md`; `_redirects` can't match Accept.

Converters when no source markdown exists: `mdream` (fastest, Workers-safe), `turndown` + `@mozilla/readability`, `rehype-remark`, Cloudflare `env.AI.toMarkdown()`.

### 2c Discovery
Head: `<link rel="alternate" type="text/markdown" href="/path.md">`.
Headers (site-wide): `Link: </llms.txt>; rel="llms-txt", </llms-full.txt>; rel="llms-full-txt"` (+ `</openapi.json>; rel="service-desc"`, `</.well-known/mcp/server-card.json>; rel="mcp-server-card"` when they exist). Where: `_headers` (CF Pages/Netlify), `vercel.json headers`, `next.config headers()`, Nuxt `routeRules`, Astro middleware, Hugo/Jekyll via host.

## 3. robots.txt
- **Next.js**: `app/robots.ts` (`rules[].other: {'Content-Signal': '…'}` in ≥16.3; else static `public/robots.txt`).
- **Nuxt**: `@nuxtjs/robots` — do **not** use `blockAiBots: true` (it blocks ChatGPT-User); define `groups` manually.
- **Astro**: `public/robots.txt` or `astro-robots-txt`.
- **Hugo**: `enableRobotsTXT = true` + `layouts/robots.txt`.
- **Others**: static file in `public/` / `static/`.
- **Cloudflare managed robots.txt** is prepended outside the repo — record it in `AGENT-SEO.md` and make sure the repo file doesn't contradict it.

## 4. Sitemap & feeds
- **Next.js**: `app/sitemap.ts` (`lastModified` from content `updatedAt`); `generateSitemaps()` for >50k. `next-sitemap` only for `output:'export'`.
- **Astro**: `@astrojs/sitemap` with `serialize(item)` to set `lastmod` from frontmatter; `filter` junk; RSS via `@astrojs/rss` `src/pages/rss.xml.ts`.
- **Nuxt**: `@nuxtjs/sitemap` (`sources`, `defineSitemapEventHandler`).
- **SvelteKit**: `super-sitemap` or `sitemap.xml/+server.ts`.
- **Hugo**: built-in; `enableGitInfo = true` + `[frontmatter] lastmod = [":git","lastmod","date"]`.
- **Jekyll**: `jekyll-sitemap`, `jekyll-feed`, `jekyll-last-modified-at`.
- **Eleventy**: `@11ty/eleventy-plugin-rss`; `sitemap.njk` with `page.date`.
- **Docusaurus**: preset `sitemap: {lastmod:'date'}`, blog `feedOptions: {type:['rss','atom','json']}`.
- Generic feeds: `feed` npm (`rss2()`, `atom1()`, `json1()`).
- IndexNow: `public/{key}.txt`; deploy hook `POST https://api.indexnow.org/indexnow {host, key, urlList}`.

## 5. JSON-LD, OG, canonical
Pattern: one site-level `@graph` (Organization|Person, WebSite) in layout; page-type node per template; serialise with `JSON.stringify(x).replace(/</g,'\\u003c')`; type with `schema-dts`.
- **Next.js**: `generateMetadata` (`alternates.canonical`, `alternates.types['text/markdown']`, `openGraph`, `twitter`) + `<script type="application/ld+json">`; set `metadataBase`.
- **Astro**: `astro-seo` + `astro-seo-schema` or a `JsonLd.astro` with `set:html`.
- **Nuxt**: `@nuxtjs/seo` → `useSchemaOrg([defineArticle(…), defineBreadcrumb(…)])`, `useSeoMeta`.
- **SvelteKit**: `svelte-meta-tags` (`<MetaTags>`, `<JsonLd>`).
- **Remix**: `meta()` with `'script:ld+json'`.
- **Hugo**: partial with `dict … | jsonify | safeJS`; internal `_internal/opengraph.html`, `schema.html`.
- **Jekyll**: `jekyll-seo-tag` `{% seo %}`.
- **Eleventy**: `eleventy-plugin-schema` or partial.
- **Docusaurus**: `headTags` in config, `<Head>` per page.

## 6. /.well-known
Serve from `public/.well-known/` (Jekyll: `include: [.well-known]`; Eleventy: `addPassthroughCopy('.well-known')`). Ensure JSON → `application/json`, security.txt → `text/plain`, and that the host doesn't SPA-fallback these paths (verify with curl!).
- `security.txt`: `Contact:`, `Expires:` (required), `Canonical:`, `Policy:`.
- `mcp/server-card.json` (+ alias `mcp.json`): `{name (reverse-DNS), title, description, version, websiteUrl, remotes:[{type:'streamable-http', url}]}` — only if `/mcp` exists.
- `agent-card.json` (A2A): only if you run an A2A endpoint.
- `api-catalog` (RFC 9727 linkset) → `openapi.json`.
- `oauth-authorization-server` / `oauth-protected-resource` for MCP auth.
- `ucp` (commerce, Google/Shopify), ACP product feed (OpenAI/Stripe) if selling.
- `tdmrep.json` if EU rights reservation matters.

## 7. MCP server / API
- **Vercel-style (Next/SvelteKit/Nuxt/Hono)**: `mcp-handler@^2` + `@modelcontextprotocol/server@^2` — `createMcpHandler(server => server.registerTool(...))`, export as GET+POST at `/mcp`; `withMcpAuth` + RFC 9728 for auth.
- **Cloudflare**: `npm create cloudflare@latest -- my-mcp --template=cloudflare/ai/demos/remote-mcp-authless` (`McpAgent`, Durable Object) or stateless `createMcpHandler` from `agents/mcp`.
- **Mintlify**: auto at `/mcp`.
- Minimum useful tools for a content site: `search(query)`, `get_page(url)`, `list_pages()`, `get_site_info()`. Expose `llms.txt` as a resource.
- OpenAPI: serve `/openapi.json`, link from llms.txt + `Link: rel="service-desc"` + api-catalog.

## 8. Edge / WAF
- **Cloudflare**: AI Crawl Control allow ChatGPT-User, Claude-User, Claude-SearchBot, OAI-SearchBot, PerplexityBot; WAF *Skip* rule for `cf.bot_management.verified_bot and cf.verified_bot_category in {"AI Assistant" "AI Search" "Search Engine Crawler"}`; rate limit scoped to `not cf.bot_management.verified_bot`.
- **Vercel**: AI Bots managed ruleset → Log; custom rule Bypass for `Signature-Agent` present / known agent UAs; BotID `verifiedBotCategory` for forms.
- **Origin verification**: `web-bot-auth` npm `verify(request, verifierFromJWK)`.

## 9. Verification one-liners (also in scripts/probe.sh)
```
curl -sD - -o /dev/null -H "Accept: text/markdown" $SITE/page | grep -iE 'content-type|vary|x-markdown|link'
curl -sI $SITE/page.md
curl -s $SITE/page | grep -o '<link[^>]*text/markdown[^>]*>'
for UA in GPTBot/1.0 ChatGPT-User/1.0 ClaudeBot/1.0 Claude-User/1.0 PerplexityBot/1.0; do curl -s -o /dev/null -w "$UA %{http_code}\n" -A "Mozilla/5.0 (compatible; $UA)" $SITE/; done
curl -s $SITE/sitemap.xml | xmllint --noout - && curl -s $SITE/sitemap.xml | grep -c '<lastmod>'
curl -s $SITE/page | grep -o '<script type="application/ld+json">[^<]*' | sed 's/<script[^>]*>//' | jq .
curl -s "https://r.jina.ai/$SITE/page"          # page as an LLM reader sees it
npx @vercel/agent-readability $SITE/page          # Vercel's scorer
npx @modelcontextprotocol/inspector               # for /mcp
```
Validators: validator.schema.org · search.google.com/test/rich-results · llmstxtvalidator.dev · securitytxt.org · acceptmarkdown.com/status
