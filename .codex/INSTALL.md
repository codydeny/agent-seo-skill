# Installing agent-seo for Codex

Codex discovers skills natively from `~/.agents/skills/`. Clone and symlink.

```bash
git clone https://github.com/codydeny/agent-seo ~/.codex/agent-seo
mkdir -p ~/.agents/skills
ln -s ~/.codex/agent-seo/skills/review ~/.agents/skills/review
```

Restart Codex. Verify with `ls -la ~/.agents/skills/review`.

Update: `cd ~/.codex/agent-seo && git pull` (symlink picks it up).
Uninstall: `rm ~/.agents/skills/review`.
