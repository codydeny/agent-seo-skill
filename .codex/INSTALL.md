# Installing agent-seo for Codex

Codex discovers skills natively from `~/.agents/skills/`. Clone and symlink.

```bash
git clone https://github.com/codydeny/agent-seo-skill ~/.codex/agent-seo-skill
mkdir -p ~/.agents/skills
ln -s ~/.codex/agent-seo-skill/skills/review ~/.agents/skills/review
```

Restart Codex. Verify with `ls -la ~/.agents/skills/review`.

Update: `cd ~/.codex/agent-seo-skill && git pull` (symlink picks it up).
Uninstall: `rm ~/.agents/skills/review`.
