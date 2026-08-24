#!/usr/bin/env bash
# Detect what we're auditing: codebase? dev server already running? deployed URL from config?
# Prints key=value lines. Usage: detect-target.sh [repo-dir]
set -u
D="${1:-.}"; cd "$D" 2>/dev/null || { echo "codebase=no"; exit 0; }

# --- codebase + framework ---
FW=""; DEV=""; PORT=""; SITE=""
[ -f astro.config.mjs ] || [ -f astro.config.ts ] || [ -f astro.config.js ] && { FW=astro; PORT=4321; SITE=$(grep -ohE "site: *['\"][^'\"]+" astro.config.* | head -1 | sed -E "s/site: *['\"]//"); }
[ -f next.config.js ] || [ -f next.config.mjs ] || [ -f next.config.ts ] && { FW=nextjs; PORT=3000; }
[ -f nuxt.config.ts ] || [ -f nuxt.config.js ] && { FW=nuxt; PORT=3000; SITE=$(grep -ohE "url: *['\"]https?://[^'\"]+" nuxt.config.* | head -1 | sed -E "s/url: *['\"]//"); }
[ -f svelte.config.js ] && { FW=sveltekit; PORT=5173; }
[ -f react-router.config.ts ] || [ -f remix.config.js ] && { FW=remix; PORT=5173; }
{ [ -f hugo.toml ] || [ -f hugo.yaml ] || { [ -f config.toml ] && [ -d layouts ]; }; } && { FW=hugo; PORT=1313; SITE=$(grep -ohE '^baseURL *= *"[^"]+' hugo.toml config.toml 2>/dev/null | head -1 | sed -E 's/.*"//'); }
[ -f _config.yml ] && [ -d _posts ] && { FW=jekyll; PORT=4000; SITE=$(grep -oE '^url: *"?[^" ]+' _config.yml | head -1 | sed -E 's/url: *"?//'); }
{ [ -f eleventy.config.js ] || [ -f .eleventy.js ]; } && { FW=eleventy; PORT=8080; }
[ -f docusaurus.config.js ] || [ -f docusaurus.config.ts ] && { FW=docusaurus; PORT=3000; SITE=$(grep -ohE "url: *['\"]https?://[^'\"]+" docusaurus.config.* | head -1 | sed -E "s/url: *['\"]//"); }
[ -d .vitepress ] && { FW=vitepress; PORT=5173; }
[ -f docs.json ] || [ -f mint.json ] && { FW=mintlify; PORT=3000; }
[ -z "$FW" ] && [ -f package.json ] && FW=node-unknown
[ -z "$FW" ] && [ -f index.html ] && { FW=static; PORT=8000; }
[ -z "$FW" ] && { echo "codebase=no"; exit 0; }
echo "codebase=yes"; echo "framework=$FW"

# host
[ -f wrangler.toml ] || [ -f wrangler.jsonc ] || [ -f wrangler.json ] && echo "host=cloudflare"
[ -f vercel.json ] || [ -d .vercel ] && echo "host=vercel"
[ -f netlify.toml ] && echo "host=netlify"
[ -f public/_headers ] && echo "headers_file=public/_headers"

# deployed URL from config/env
[ -z "$SITE" ] && SITE=$(grep -ohE '(SITE_URL|NEXT_PUBLIC_SITE_URL|PUBLIC_SITE_URL|URL)=https?://[^ ]+' .env .env.local .env.production 2>/dev/null | head -1 | sed 's/.*=//')
[ -z "$SITE" ] && [ -f package.json ] && SITE=$(grep -oE '"homepage": *"https?://[^"]+' package.json | sed -E 's/.*"//')
[ -n "$SITE" ] && echo "deployed_url=${SITE%/}"

# dev script + port override
if [ -f package.json ]; then
  DEV=$(python3 -c "import json;s=json.load(open('package.json')).get('scripts',{});print(s.get('dev') or s.get('start') or '')" 2>/dev/null)
  [ -n "$DEV" ] && echo "dev_script=$DEV"
  P=$(echo "$DEV" | grep -oE -- '(--port|-p) *[0-9]+' | grep -oE '[0-9]+' | head -1); [ -n "$P" ] && PORT=$P
  PM=npm; [ -f pnpm-lock.yaml ] && PM=pnpm; [ -f yarn.lock ] && PM=yarn; [ -f bun.lockb ] || [ -f bun.lock ] && PM=bun
  echo "pkg_manager=$PM"
fi
[ -n "$PORT" ] && echo "expected_port=$PORT"

# --- already-running local servers ---
RUNNING=""
for p in ${PORT:-} 3000 4321 5173 8080 4000 1313 8000 3001 4173 8788 8787; do
  [ -z "$p" ] && continue
  code=$(curl -s -o /dev/null -m 2 -w '%{http_code}' "http://localhost:$p/" 2>/dev/null)
  case "$code" in 2*|3*|404) RUNNING="$RUNNING http://localhost:$p($code)";; esac
done
[ -n "$RUNNING" ] && echo "running_local=$RUNNING" || echo "running_local=none"

# is the running server *this* project? (title/generator match)
[ -n "$RUNNING" ] && for u in $(echo "$RUNNING" | grep -oE 'http://localhost:[0-9]+'); do
  g=$(curl -s -m 3 "$u/" | grep -oiE '<meta name="generator" content="[^"]+"|<title>[^<]*' | head -2 | tr '\n' ' ')
  echo "local_fingerprint $u=$g"
done
