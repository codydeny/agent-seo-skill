# Installing agent-dx-harness for Codex

Codex discovers skills natively from `~/.agents/skills/`. Clone and symlink.

```bash
git clone https://github.com/codydeny/agent-dx-harness ~/.codex/agent-dx-harness
mkdir -p ~/.agents/skills
ln -s ~/.codex/agent-dx-harness/skills/agent-dx-review ~/.agents/skills/agent-dx-review
```

Restart Codex. Verify with `ls -la ~/.agents/skills/agent-dx-review`.

Update: `cd ~/.codex/agent-dx-harness && git pull` (symlink picks it up).
Uninstall: `rm ~/.agents/skills/agent-dx-review`.
