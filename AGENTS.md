# agent-seo

This repository provides one capability: an **agent SEO review** for websites —
auditing and fixing how AI crawlers, answer engines (ChatGPT, Claude, Perplexity,
Gemini, Copilot) and user-driven agents discover, read, cite, and act on a site.

**When the user asks to make a site agent-ready / AI-readable, mentions agent SEO / agent DX,
AEO/GEO, llms.txt, markdown for agents, or invokes `/review`**, read and
follow `skills/review/SKILL.md` exactly.

Deterministic live checks live in `scripts/probe.sh` (bash + curl only). The
skill reads `skills/review/references/*.md` on demand:
`checklist.md` (120 checks, weights, gates) · `bots.md` (crawler classes,
robots policy) · `frameworks.md` (implementation per framework/host) ·
`evidence.md` (what is proven vs hype).

If this repo is itself the working directory, you are developing the harness,
not reviewing a site.
