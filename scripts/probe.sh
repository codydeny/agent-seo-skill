#!/usr/bin/env bash
# agent-dx probe — deterministic live checks of a site's agent-facing surface.
# Usage: probe.sh <base-url> [--json] [--pages N]
# Requires: bash, curl. Optional: python3 (JSON-LD parsing), xmllint.
# Output: one line per check: <id>\t<status>\t<detail>   status ∈ PASS|WARN|FAIL|INFO
set -u
BASE="${1:?usage: probe.sh https://example.com [--pages N]}"
BASE="${BASE%/}"
PAGES=8
shift || true
while [ $# -gt 0 ]; do case "$1" in --pages) PAGES="$2"; shift;; esac; shift; done

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
LOCAL=0; echo "$BASE" | grep -qE '^https?://(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])' && LOCAL=1
UA_DEFAULT="Mozilla/5.0 (compatible; agent-dx-probe/0.1)"
CURL="curl -sS -L --max-time 20 --max-redirs 5"

out() { printf '%s\t%s\t%s\n' "$1" "$2" "$3"; }
fetch() { # fetch <url> <outfile> [extra curl args...] -> prints "code content-type time"
  local u="$1" f="$2"; shift 2
  $CURL -A "$UA_DEFAULT" "$@" -o "$f" -w '%{http_code} %{time_total} %{size_download} %{content_type}' "$u" 2>/dev/null || echo "000 0 0 -"
}
has_tag() { grep -qiE "$1" "$2"; }

echo "# agent-dx probe of $BASE — $(date -u +%Y-%m-%dT%H:%MZ)"
[ "$LOCAL" = 1 ] && echo "# LOCAL target: edge-dependent checks (bot access/WAF, HSTS, TTFB, CDN-managed robots, Cloudflare md conversion) are SKIP — re-run against the deployed URL for those"

# ---------- 1. Home page basics ----------
read -r HCODE HTIME HSIZE HTYPE <<<"$(fetch "$BASE/" "$T/home.html")"
[ "$HCODE" = 200 ] && out home.status PASS "$HCODE in ${HTIME}s, ${HSIZE}B" || out home.status FAIL "HTTP $HCODE"
if [ "$LOCAL" = 1 ]; then out home.ttfb SKIP "local"; elif awk -v t="$HTIME" 'BEGIN{exit !(t>1.0)}'; then out home.ttfb WARN "total ${HTIME}s (>1s; crawlers time out)"; else out home.ttfb PASS "${HTIME}s"; fi

# JS-only shell?
TEXT_LEN=$(sed -e 's/<script[^>]*>.*<\/script>//gI' -e 's/<style[^>]*>.*<\/style>//gI' -e 's/<[^>]*>//g' "$T/home.html" | tr -s ' \n\t' ' ' | wc -c | tr -d ' ')
if [ "$TEXT_LEN" -lt 800 ]; then out render.ssr FAIL "only ${TEXT_LEN} chars of visible text in initial HTML — likely JS-rendered shell (GPTBot/ClaudeBot/PerplexityBot do not run JS)"; else out render.ssr PASS "${TEXT_LEN} chars of text in initial HTML"; fi
H1N=$(grep -oiE '<h1[ >]' "$T/home.html" | wc -l | tr -d ' ')
[ "$H1N" = 1 ] && out html.h1 PASS "one <h1>" || out html.h1 WARN "$H1N <h1> tags"
has_tag '<main[ >]' "$T/home.html" && out html.main PASS "<main> present" || out html.main WARN "no <main> landmark"
has_tag '<meta name="description"' "$T/home.html" && out meta.description PASS "" || out meta.description FAIL "missing meta description"
has_tag '<link rel="canonical"' "$T/home.html" && out meta.canonical PASS "$(grep -oiE '<link rel="canonical"[^>]*href="[^"]*"' "$T/home.html" | head -1 | grep -oE 'href="[^"]*"')" || out meta.canonical FAIL "no canonical"
has_tag 'property="og:title"' "$T/home.html" && out meta.og PASS "" || out meta.og WARN "no Open Graph tags"
has_tag 'rel="alternate"[^>]*type="application/(rss|atom)\+xml' "$T/home.html" && out feed.link PASS "" || out feed.link WARN "no <link rel=alternate> to RSS/Atom"
has_tag 'rel="alternate"[^>]*type="text/markdown' "$T/home.html" && out md.link PASS "<link rel=alternate type=text/markdown>" || out md.link WARN "no <link rel=alternate type=text/markdown>"
has_tag 'application/ld\+json' "$T/home.html" && out schema.present PASS "$(grep -oE '"@type": *"[A-Za-z]+"' "$T/home.html" | sed 's/.*"\([A-Za-z]*\)"$/\1/' | sort -u | tr '\n' ',' )" || out schema.present FAIL "no JSON-LD"
IMGS=$(grep -oiE '<img[^>]*>' "$T/home.html" | wc -l | tr -d ' '); NOALT=$(grep -oiE '<img[^>]*>' "$T/home.html" | grep -viE 'alt="[^"]+"' | wc -l | tr -d ' ')
[ "$IMGS" -gt 0 ] && { [ "$NOALT" = 0 ] && out html.alt PASS "$IMGS imgs, all alt" || out html.alt WARN "$NOALT/$IMGS imgs missing alt"; }
has_tag '<noscript' "$T/home.html" && out html.noscript INFO "noscript present" || true
has_tag 'lang="' "$T/home.html" && out html.lang PASS "" || out html.lang WARN "no <html lang>"

# ---------- 2. Response headers ----------
$CURL -A "$UA_DEFAULT" -D "$T/h.txt" -o /dev/null "$BASE/" 2>/dev/null
hdr() { grep -i "^$1:" "$T/h.txt" | head -1 | tr -d '\r'; }
[ "$LOCAL" = 1 ] && out hdr.hsts SKIP "local" || { [ -n "$(hdr strict-transport-security)" ] && out hdr.hsts PASS "" || out hdr.hsts WARN "no HSTS"; }
[ -n "$(hdr content-signal)" ] && out hdr.content-signal INFO "$(hdr content-signal)" || true
[ -n "$(hdr link)" ] && out hdr.link INFO "$(hdr link | cut -c1-160)" || true
[ -n "$(hdr x-robots-tag)" ] && out hdr.x-robots INFO "$(hdr x-robots-tag)" || true
[ -n "$(hdr last-modified)" ] || [ -n "$(hdr etag)" ] && out hdr.cache PASS "etag/last-modified present" || out hdr.cache WARN "no ETag/Last-Modified (conditional fetches impossible)"

# ---------- 3. Discovery files ----------
check_file() { # id path expected-type-regex
  local id="$1" p="$2" want="$3" f
  f="$T/$(echo "$p" | tr '/.' '__')"
  read -r c t s ct <<<"$(fetch "$BASE$p" "$f")"
  if [ "$c" = 200 ] && echo "$ct" | grep -qiE "$want"; then out "$id" PASS "$c $ct ${s}B"
  elif [ "$c" = 200 ]; then out "$id" FAIL "200 but content-type '$ct' (wanted $want) — probably SPA shell/HTML fallback"
  else out "$id" FAIL "HTTP $c"; fi
  echo "$c" > "$f.code"
}
check_file robots.txt /robots.txt 'text/plain'
check_file llms.txt /llms.txt 'text/(plain|markdown)'
check_file llms-full.txt /llms-full.txt 'text/(plain|markdown)'
check_file security.txt /.well-known/security.txt 'text/plain'

# sitemap: robots.txt Sitemap: line, else /sitemap.xml, sitemap-index.xml, sitemap_index.xml
SM=$(grep -i '^sitemap:' "$T/_robots_txt" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '\r')
[ -z "$SM" ] && for cand in /sitemap.xml /sitemap-index.xml /sitemap_index.xml; do c=$($CURL -o /dev/null -w '%{http_code}' "$BASE$cand"); [ "$c" = 200 ] && SM="$BASE$cand" && break; done
if [ -n "$SM" ]; then
  read -r c t s ct <<<"$(fetch "$SM" "$T/sitemap.xml")"
  if [ "$c" = 200 ] && echo "$ct" | grep -qiE 'xml'; then
    N=$(grep -o '<loc>' "$T/sitemap.xml" | wc -l | tr -d ' '); LM=$(grep -o '<lastmod>' "$T/sitemap.xml" | wc -l | tr -d ' ')
    out sitemap PASS "$SM ($N loc, $LM lastmod)"
    [ "$LM" = 0 ] && [ "$N" -gt 0 ] && out sitemap.lastmod WARN "no <lastmod> — freshness is a strong citation signal"
    grep -q 'sitemapindex' "$T/sitemap.xml" && out sitemap.index INFO "sitemap index (children not expanded)"
  else out sitemap FAIL "$SM -> $c $ct (XML expected)"; fi
  [ -z "$(grep -i '^sitemap:' "$T/_robots_txt" 2>/dev/null)" ] && out sitemap.in-robots WARN "robots.txt has no Sitemap: line"
else out sitemap FAIL "no sitemap found"; fi

# feeds
for f in /rss.xml /feed.xml /atom.xml /feed /feed.json /index.xml; do c=$($CURL -o "$T/feed" -w '%{http_code} %{content_type}' "$BASE$f" 2>/dev/null); if echo "$c" | grep -qE '^200 .*(xml|json)'; then out feed PASS "$f ($c)"; FEEDOK=1; break; fi; done
[ -z "${FEEDOK:-}" ] && out feed WARN "no RSS/Atom/JSON feed at common paths"

# well-known / agent interfaces (INFO unless present)
for wk in /.well-known/mcp/server-card.json /.well-known/agent-card.json /.well-known/ai-catalog.json /.well-known/ucp /.well-known/tdmrep.json /.well-known/oauth-protected-resource /.well-known/http-message-signatures-directory /openapi.json /.well-known/openapi.json /api/openapi.json /mcp /ai.txt /humans.txt; do
  c=$($CURL -o "$T/wk" -w '%{http_code} %{content_type}' "$BASE$wk" 2>/dev/null)
  if echo "$c" | grep -qE '^200 .*(json|xml|plain|yaml|event-stream)'; then out "wellknown$(echo $wk | tr '/' '.')" PASS "$c"; fi
done

# ---------- 4. robots.txt analysis ----------
if [ -f "$T/_robots_txt" ] && [ "$(cat "$T/_robots_txt.code")" = 200 ]; then
  R="$T/_robots_txt"
  tr -d '\r' < "$R" > "$R.clean"; R="$R.clean"
  grep -qiE '^content-signal:' "$R" && out robots.content-signal INFO "$(grep -iE '^content-signal:' "$R" | head -1)" || out robots.content-signal INFO "no Content-Signal line"
  grep -qi 'BEGIN Cloudflare Managed' "$R" && out robots.cf-managed INFO "Cloudflare managed robots.txt block present (check its AI disallows match your intent)"
  # per-bot verdict: naive parse — bot disallowed if its UA group contains 'Disallow: /' alone
  verdict() { awk -v ua="$(echo "$1" | tr 'A-Z' 'a-z')" 'BEGIN{inb=0;dis=0;seen=0} {l=tolower($0)} l ~ /^user-agent:/{sub(/^user-agent:[ \t]*/,"",l); if(l==ua){inb=1;seen=1} else if(!prevua){inb=0}; prevua=1; next} {prevua=0} inb && l ~ /^disallow:[ \t]*\/[ \t]*$/{dis=1} END{print (seen? (dis?"BLOCKED":"allowed") : "unlisted")}' "$R"; }
  for grp in "search:OAI-SearchBot Claude-SearchBot PerplexityBot Bingbot Googlebot Applebot DuckAssistBot MistralAI-Index" "user:ChatGPT-User Claude-User Perplexity-User MistralAI-User" "train:GPTBot ClaudeBot Google-Extended CCBot Bytespider Amazonbot meta-externalagent Applebot-Extended"; do
    cls=${grp%%:*}; line=""
    for b in ${grp#*:}; do line="$line $b=$(verdict $b)"; done
    if [ "$cls" != train ] && echo "$line" | grep -q BLOCKED; then out "robots.$cls" FAIL "$line"; else out "robots.$cls" INFO "$line"; fi
  done
fi

# ---------- 5. Bot access (WAF/challenge) ----------
[ "$LOCAL" = 1 ] && out access.bots SKIP "local — WAF/CDN not in path" 
[ "$LOCAL" = 0 ] && for ua in "Mozilla/5.0 (compatible; GPTBot/1.0; +https://openai.com/gptbot)" "Mozilla/5.0 (compatible; ClaudeBot/1.0; +claudebot@anthropic.com)" "Mozilla/5.0 (compatible; ChatGPT-User/1.0; +https://openai.com/bot)" "Mozilla/5.0 (compatible; PerplexityBot/1.0; +https://perplexity.ai/perplexitybot)" "Mozilla/5.0 (compatible; OAI-SearchBot/1.0; +https://openai.com/searchbot)" "Claude-User/1.0"; do
  name=$(echo "$ua" | grep -oE '[A-Za-z-]+(Bot|User)' | head -1)
  c=$($CURL -A "$ua" -o "$T/ua.html" -w '%{http_code}' "$BASE/" 2>/dev/null)
  if [ "$c" = 200 ] && ! grep -qiE 'cf-challenge|Just a moment|Checking your browser|__cf_chl|captcha' "$T/ua.html"; then out "access.$name" PASS "200"; else out "access.$name" FAIL "HTTP $c or challenge page"; fi
done

# ---------- 6. Markdown negotiation ----------
c=$($CURL -H 'Accept: text/markdown, text/html;q=0.9' -D "$T/mdh.txt" -o "$T/md.txt" -w '%{http_code} %{content_type}' "$BASE/" 2>/dev/null)
if echo "$c" | grep -qi 'text/markdown'; then out md.negotiate PASS "$c; vary=$(grep -i '^vary:' "$T/mdh.txt" | tr -d '\r' | cut -d' ' -f2-)"; grep -qi '^vary:.*accept' "$T/mdh.txt" || out md.vary FAIL "text/markdown served without Vary: Accept (cache poisoning risk)"; else out md.negotiate WARN "Accept: text/markdown -> $c (Claude Code/Cursor/OpenCode send this header)"; fi
# .md suffix on a few sitemap/nav URLs
PAGELIST=$( { grep -o '<loc>[^<]*' "$T/sitemap.xml" 2>/dev/null | sed 's/<loc>//' ; grep -oiE 'href="(/[a-z0-9/_-]+)"' "$T/home.html" | sed -E 's/href="([^"]*)"/\1/' | sed "s|^|$BASE|"; } | grep -vE '\.(png|jpg|svg|css|js|xml|txt|pdf|ico|webp)$' | grep -vE '#|\?' | sort -u | head -"$PAGES")
MDOK=0; MDN=0; ERR404=0; N=0; NOLD=0; MULTIH1=0
for u in $PAGELIST; do
  [ "$u" = "$BASE" ] || [ "$u" = "$BASE/" ] && continue
  N=$((N+1))
  read -r c t s ct <<<"$(fetch "$u" "$T/p.html")"
  [ "$c" != 200 ] && ERR404=$((ERR404+1)) && continue
  grep -qi 'application/ld+json' "$T/p.html" || NOLD=$((NOLD+1))
  [ "$(grep -oiE '<h1[ >]' "$T/p.html" | wc -l | tr -d ' ')" != 1 ] && MULTIH1=$((MULTIH1+1))
  mu="${u%/}.md"; mc=$($CURL -o /dev/null -w '%{http_code} %{content_type}' "$mu" 2>/dev/null)
  MDN=$((MDN+1)); echo "$mc" | grep -qiE '^200 .*(markdown|plain)' && MDOK=$((MDOK+1))
done
[ "$N" -gt 0 ] && {
  out pages.sampled INFO "$N pages sampled from sitemap/nav"
  [ "$ERR404" = 0 ] && out pages.status PASS "all 200" || out pages.status FAIL "$ERR404/$N sampled URLs not 200 (AI crawlers already see ~35% 404s; stale sitemap makes it worse)"
  [ "$NOLD" = 0 ] && out pages.schema PASS "JSON-LD on all sampled" || out pages.schema WARN "$NOLD/$N sampled pages without JSON-LD"
  [ "$MULTIH1" = 0 ] && out pages.h1 PASS "" || out pages.h1 WARN "$MULTIH1/$N pages without exactly one <h1>"
  [ "$MDOK" -gt 0 ] && out md.suffix PASS "$MDOK/$MDN pages serve .md twin" || out md.suffix WARN "0/$MDN pages have a .md twin"
}

# ---------- 7. llms.txt format check ----------
if [ "$(cat "$T/_llms_txt.code" 2>/dev/null)" = 200 ]; then
  L="$T/_llms_txt"
  head -1 "$L" | grep -q '^# ' && out llms.h1 PASS "" || out llms.h1 FAIL "llms.txt must start with '# Title'"
  grep -q '^> ' "$L" && out llms.summary PASS "" || out llms.summary WARN "no '> summary' blockquote"
  grep -qE '^## ' "$L" && out llms.sections PASS "$(grep -cE '^## ' "$L") sections, $(grep -cE '^- \[' "$L") links" || out llms.sections WARN "no ## sections"
  # link rot inside llms.txt
  BROKEN=0; TOT=0
  for lu in $(grep -oE '\]\((https?://[^) ]+)\)' "$L" | sed -E 's/\]\((.*)\)/\1/' | head -25); do TOT=$((TOT+1)); c=$($CURL -o /dev/null -w '%{http_code}' "$lu"); [ "$c" != 200 ] && BROKEN=$((BROKEN+1)); done
  [ "$BROKEN" = 0 ] && out llms.links PASS "$TOT links ok" || out llms.links FAIL "$BROKEN/$TOT llms.txt links not 200"
fi

# ---------- 8. 404 behaviour ----------
c=$($CURL -o "$T/404.html" -w '%{http_code}' "$BASE/agent-dx-probe-$(date +%s)-does-not-exist" 2>/dev/null)
[ "$c" = 404 ] && out http.404 PASS "real 404" || out http.404 FAIL "missing page returns $c (soft-404 — every bad URL looks like content)"
echo "# done"
