# agent-dx-harness

This repository provides one capability: an **agent DX review** — auditing a
codebase for things that make it hard for coding agents (Claude Code, Codex,
Cursor, Antigravity, Gemini CLI) to work in it effectively.

**When the user asks to review, audit, or find agent DX issues** (or invokes
`/agent-dx-review`), read and follow `skills/agent-dx-review/SKILL.md` exactly.

The skill is plain markdown in the Agent Skills format; there is no runtime,
no hooks, no dependencies. Any harness that can read `SKILL.md` can run it.

If this repo is itself the working directory, you are developing the harness,
not reviewing a project.
