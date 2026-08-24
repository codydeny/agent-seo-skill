# Installing agent-dx-harness (for agents to follow)

You are a coding agent installing this harness for the user. Do every step, verify, and report what you did. Do not skip verification.

## 0. Get the repo
If `~/agent-dx-harness` already exists and contains `skills/agent-dx-review/SKILL.md`, use it (`cd ~/agent-dx-harness && git pull` if it is a clone). Otherwise:
```bash
git clone https://github.com/codydeny/agent-dx-harness ~/agent-dx-harness
```
If the clone fails (private/offline), ask the user for the path to their copy and use that instead of `~/agent-dx-harness` below.
```bash
chmod +x ~/agent-dx-harness/scripts/*.sh
bash ~/agent-dx-harness/scripts/probe.sh https://example.com --pages 1 | head -3   # must print "# agent-dx probe of …"
```

## 1. Detect which agent harnesses are present
```bash
command -v claude >/dev/null && echo claude-code
[ -d ~/.cursor ] && echo cursor
[ -d ~/.codex ] && echo codex
command -v gemini >/dev/null && echo gemini-cli
[ -d ~/.gemini/antigravity ] || [ -d .agent ] && echo antigravity
```
Install for every harness found (and any the user names).

## 2. Claude Code
```bash
claude plugin marketplace add ~/agent-dx-harness          # registers marketplace "agent-dx-harness" (directory source)
claude plugin install agent-dx@agent-dx-harness
claude plugin list | grep -A3 'agent-dx@'                 # expect: Status: ✔ enabled
```
If `marketplace add` says it already exists: `claude plugin marketplace update agent-dx-harness`. If `install` says already installed: `claude plugin update agent-dx@agent-dx-harness`.
Verify: `claude plugin details agent-dx@agent-dx-harness` must show `Skills (1)  agent-dx-review` (a count of 2 means a stale duplicate — reinstall).
Tell the user: start a new session and run `/agent-dx:agent-dx-review`.

## 3. Cursor
```bash
mkdir -p ~/.cursor/plugins/local
ln -sfn ~/agent-dx-harness ~/.cursor/plugins/local/agent-dx
ls -la ~/.cursor/plugins/local/agent-dx/.cursor-plugin/plugin.json   # must resolve
```
Tell the user: reload Cursor ("Developer: Reload Window") and check the Customize page; skills/commands are auto-discovered from `.cursor-plugin/plugin.json`.

## 4. Codex
```bash
mkdir -p ~/.agents/skills
ln -sfn ~/agent-dx-harness/skills/agent-dx-review ~/.agents/skills/agent-dx-review
ls -la ~/.agents/skills/agent-dx-review/SKILL.md
```
Restart Codex.

## 5. Antigravity (per project)
```bash
mkdir -p .agent/skills .agent/workflows
ln -sfn ~/agent-dx-harness/skills/agent-dx-review .agent/skills/agent-dx-review
printf -- '---\ndescription: Audit and fix this website'"'"'s agent DX\n---\nRead and follow .agent/skills/agent-dx-review/SKILL.md exactly. Arguments: $ARGUMENTS\n' > .agent/workflows/agent-dx-review.md
```

## 6. Gemini CLI
```bash
gemini extensions install ~/agent-dx-harness || gemini extensions install https://github.com/codydeny/agent-dx-harness
```

## 7. Report
List each harness: installed / skipped (why), and the exact command the user should run next.

## Uninstall
```bash
claude plugin uninstall agent-dx@agent-dx-harness; claude plugin marketplace remove agent-dx-harness
rm -f ~/.cursor/plugins/local/agent-dx ~/.agents/skills/agent-dx-review
gemini extensions uninstall agent-dx 2>/dev/null
```
