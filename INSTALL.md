# Installing agent-seo (for agents to follow)

You are a coding agent installing this harness for the user. Do every step, verify, and report what you did. Do not skip verification.

## 0. Get the repo
If `~/agent-seo-skill` already exists and contains `skills/review/SKILL.md`, use it (`cd ~/agent-seo-skill && git pull` if it is a clone). Otherwise:
```bash
git clone https://github.com/codydeny/agent-seo-skill ~/agent-seo-skill
```
If the clone fails (private/offline), ask the user for the path to their copy and use that instead of `~/agent-seo-skill` below.
```bash
chmod +x ~/agent-seo-skill/scripts/*.sh
bash ~/agent-seo-skill/scripts/probe.sh https://example.com --pages 1 | head -3   # must print "# agent-seo probe of …"
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
claude plugin marketplace add ~/agent-seo-skill          # registers marketplace "agent-seo-skill" (directory source)
claude plugin install agent-seo@agent-seo-skill
claude plugin list | grep -A3 'agent-seo@'                 # expect: Status: ✔ enabled
```
If `marketplace add` says it already exists: `claude plugin marketplace update agent-seo-skill`. If `install` says already installed: `claude plugin update agent-seo@agent-seo-skill`. **Note:** Claude Code caches a copy per version; edits to the repo only reach the installed copy when `.claude-plugin/plugin.json` `version` changes (or via `claude plugin uninstall` + `install`). For live development use `claude --plugin-dir ~/agent-seo-skill` instead.
Verify: `claude plugin details agent-seo@agent-seo-skill` must show `Skills (1)  review` (a count of 2 means a stale duplicate — reinstall).
Tell the user: start a new session and run `/agent-seo:review`.

## 3. Cursor
```bash
mkdir -p ~/.cursor/plugins/local
ln -sfn ~/agent-seo-skill ~/.cursor/plugins/local/agent-seo
ls -la ~/.cursor/plugins/local/agent-seo/.cursor-plugin/plugin.json   # must resolve
```
Tell the user: reload Cursor ("Developer: Reload Window") and check the Customize page; skills/commands are auto-discovered from `.cursor-plugin/plugin.json`.

## 4. Codex
```bash
mkdir -p ~/.agents/skills
ln -sfn ~/agent-seo-skill/skills/review ~/.agents/skills/review
ls -la ~/.agents/skills/review/SKILL.md
```
Restart Codex.

## 5. Antigravity (per project)
```bash
mkdir -p .agent/skills .agent/workflows
ln -sfn ~/agent-seo-skill/skills/review .agent/skills/review
printf -- '---\ndescription: Audit and fix this website'"'"'s agent SEO\n---\nRead and follow .agent/skills/review/SKILL.md exactly. Arguments: $ARGUMENTS\n' > .agent/workflows/review.md
```

## 6. Gemini CLI
```bash
gemini extensions install ~/agent-seo-skill || gemini extensions install https://github.com/codydeny/agent-seo-skill
```

## 7. Report
List each harness: installed / skipped (why), and the exact command the user should run next.

## Uninstall
```bash
claude plugin uninstall agent-seo@agent-seo-skill; claude plugin marketplace remove agent-seo-skill
rm -f ~/.cursor/plugins/local/agent-seo ~/.agents/skills/review
gemini extensions uninstall agent-seo 2>/dev/null
```
