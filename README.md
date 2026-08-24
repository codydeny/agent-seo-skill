# agent-dx-harness

**Find what makes your repo hard for coding agents — before the agent finds out the expensive way.**

`/agent-dx-review` audits a repository from an agent's point of view (Claude Code,
Codex, Cursor, Antigravity, Gemini CLI) and returns a prioritized, evidence-backed
list of issues with concrete fixes: missing or contradictory `AGENTS.md`, no
one-shot test command, slow feedback loops, undocumented env, unguarded
destructive commands, and so on.

It is a single markdown skill. No runtime, no dependencies.

## Install

### Claude Code

```
/plugin marketplace add codydeny/agent-dx-harness
/plugin install agent-dx@agent-dx-harness
```

Local dev: `claude --plugin-dir ~/agent-dx-harness`.

### Cursor

Ships `.cursor-plugin/plugin.json`; `skills/` and `commands/` are auto-discovered.

```bash
git clone https://github.com/codydeny/agent-dx-harness
ln -sfn "$(pwd)/agent-dx-harness" ~/.cursor/plugins/local/agent-dx
```

Restart Cursor (or "Developer: Reload Window").

### Codex

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/codydeny/agent-dx-harness/main/.codex/INSTALL.md
```

(Clone + symlink `skills/agent-dx-review` into `~/.agents/skills/`.)

### Antigravity

Antigravity discovers skills from `.agent/skills/` (per-project) or the global
skills directory. Symlink the skill:

```bash
git clone https://github.com/codydeny/agent-dx-harness
mkdir -p .agent/skills
ln -s "$(pwd)/agent-dx-harness/skills/agent-dx-review" .agent/skills/agent-dx-review
```

For a `/agent-dx-review` slash command, copy `commands/agent-dx-review.md` to
`.agent/workflows/agent-dx-review.md` and change the file reference to
`.agent/skills/agent-dx-review/SKILL.md`.

### Gemini CLI

```bash
gemini extensions install https://github.com/codydeny/agent-dx-harness
```

### Any other agent

```bash
git clone https://github.com/codydeny/agent-dx-harness
```

Point the agent at `skills/agent-dx-review/SKILL.md`. Agents that read
`AGENTS.md` will find it on their own.

## Use

```
/agent-dx-review                  # review cwd, quick checklist pass
/agent-dx-review packages/api     # review a subdirectory
/agent-dx-review --deep           # also run install/test/lint and trace a task
/agent-dx-review --deep --write   # save report to docs/agent-dx-review.md
```

In Claude Code the namespaced form is `/agent-dx:agent-dx-review`.

## Layout

```
skills/agent-dx-review/SKILL.md   the review — single source of truth
commands/agent-dx-review.md       thin slash-command wrapper (Claude Code, Cursor)
AGENTS.md                         entry point for Codex / Antigravity / others
.claude-plugin/  .cursor-plugin/  .codex/  gemini-extension.json   per-harness install glue
```

## License

MIT
