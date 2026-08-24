---
name: agent-dx-review
description: Use when the user asks to review, audit, or find "agent DX" issues — anything that makes a repository hard for coding agents (Claude Code, Codex, Cursor, Antigravity, Gemini CLI) to work in. Produces a prioritized, evidence-backed list of issues with concrete fixes.
argument-hint: "[path] [--quick|--deep] [--write]"
---

# Agent DX review

Audit a repository from the point of view of a coding agent that has just been
dropped into it with no context. Find the things that will make it waste
tokens, guess wrong, break the build, or silently do the wrong thing — then
report them ranked by impact, with a concrete fix for each.

Arguments: `$ARGUMENTS`

- `path` (optional) — subdirectory or repo root to review. Default: cwd.
- `--quick` — checklist pass only (§1–§3), no deep reads. Default when the repo is large (>2k files).
- `--deep` — also do §4–§5: actually run the commands and trace one real task.
- `--write` — save the report to `docs/agent-dx-review.md` (create dir if missing). Default: print only.

## Ground rules

- **Evidence, not vibes.** Every issue cites a file path, a command you ran, or
  a specific missing artifact. If you didn't verify it, don't report it.
- **Agent's eye view.** Judge from what an agent sees on first entry: the root
  listing, the instruction files, the first commands it would run. Humans have
  tribal knowledge; agents have only what's in the repo.
- **Do not fix anything** during this review. Report only. The user decides.
- Keep the report short. 5–15 issues is normal. Merge duplicates, drop trivia.

## 1. Orientation (always)

Read, in this order, noting what exists and what is missing:

1. Root listing (`ls -la`) and top-level directory structure (depth 2).
2. Agent instruction files: `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`,
   `.cursorrules`, `GEMINI.md`, `.github/copilot-instructions.md`,
   `.claude/`, `.agent/`, `.codex/`.
3. Project manifests: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`,
   `Makefile`, `justfile`, `Taskfile`, `docker-compose*`.
4. `README.md` — only the setup / run / test sections.
5. CI config (`.github/workflows/*`, etc.) — what is *actually* run to validate.

## 2. Checklist — score each item ✅ / ⚠️ / ❌

**Instructions & context**
- Is there a single canonical agent instruction file (`AGENTS.md` or `CLAUDE.md`)? Do the others reference it rather than duplicate/contradict it?
- Does it state, in ≤ 1 screen: how to install, build, test, lint, run — as literal commands?
- Does it say what *not* to touch (generated files, vendored code, secrets, migrations)?
- Is it under ~150 lines? (Longer files get skimmed, not followed.)
- Are there stale instructions (commands that no longer exist, paths that moved)?

**Commands & feedback loops**
- One command to run all tests? To run one test file? Documented?
- Do tests finish in < 2 min? If not, is there a fast subset?
- Is lint/format/typecheck one command, and does it auto-fix?
- Does `install` work from a clean clone without manual steps or secrets?
- Are error messages actionable, or do failures dump 500-line stack traces?

**Repository shape**
- Is the source tree discoverable (clear top-level dirs, no `misc/`, `utils2/`)?
- Are generated / vendored / build artifacts committed or otherwise indistinguishable from source?
- Are there huge files (>2k lines) an agent would have to read to change anything?
- Are secrets or env vars needed, and is there a `.env.example`?
- Is the `.gitignore` sane (no `node_modules`, `.venv`, build outputs committed)?

**Verification & safety**
- Can an agent verify a change end-to-end without a human (tests, typecheck, a smoke run)?
- Are destructive commands (db reset, deploy, publish) clearly flagged or gated?
- Is CI's validation reproducible locally with the same command?

**Tooling for agents**
- Are skills / commands / hooks present for repeated workflows? Do they work?
- MCP or tool configs (`.mcp.json`, etc.) — are they documented and non-secret?

## 3. Report (always)

Output exactly this structure:

```
# Agent DX review — <repo name> (<date>)

Scope: <path> · Mode: quick|deep · Agents considered: Claude Code, Codex, Cursor, Antigravity

## Top issues (ranked by impact on agents)

### 1. <one-line issue title>  [P0|P1|P2]
Evidence: <file:line, command + output snippet, or "missing: X">
Impact: <what an agent will do wrong / waste because of this>
Fix: <concrete, smallest change that resolves it>

### 2. ...

## Checklist summary
<table: item · status · note>

## What's already good
<3–5 bullets — keep it honest, agents should preserve these>
```

Priorities: **P0** — agent will fail or do damage (no test command, destructive
default, contradictory instructions). **P1** — agent will waste significant
effort or guess (no AGENTS.md, slow tests, undocumented env). **P2** — friction.

If `--write`: save to `docs/agent-dx-review.md` and tell the user the path.

## 4. Deep pass — run the loop (`--deep` only)

Actually execute, in a way that cannot mutate shared state:

1. Install from the documented command. Record time and any manual intervention needed.
2. Run the documented test command. Record time, pass/fail, and noise level.
3. Run lint/typecheck. Same.
4. Make a trivial safe change (e.g., add a comment), run the fastest verification, revert.

Any mismatch between "what the docs say" and "what happened" is a P0/P1 issue.

## 5. Deep pass — trace one real task (`--deep` only)

Pick one small, plausible task from open issues / TODOs / the README roadmap.
Walk through how an agent would attempt it: which files it must find, what
context it lacks, where it would guess. Do **not** implement it. Each point of
guessing becomes an issue with the context that would have prevented it.

## Cross-agent notes

The same repo is read differently by different harnesses; call out when a fix
should be mirrored:

- **Claude Code** reads `CLAUDE.md` (and `AGENTS.md` if referenced), `.claude/` skills/commands/hooks.
- **Codex** reads `AGENTS.md`, skills from `~/.agents/skills/` and `.agents/skills/`.
- **Cursor** reads `.cursor/rules/*.mdc`, `AGENTS.md`, plugin `skills/`.
- **Antigravity** reads `AGENTS.md`, `.agent/rules/`, `.agent/skills/`, `.agent/workflows/`.
- **Gemini CLI** reads `GEMINI.md` (or the extension's `contextFileName`).

Recommended baseline: one `AGENTS.md` as source of truth; `CLAUDE.md` and
`GEMINI.md` contain a single line pointing at it.
