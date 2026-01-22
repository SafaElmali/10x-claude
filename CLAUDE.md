# 10x-claude

Claude Code extensions: custom agents, skills, commands, and tools.

## Project Structure

```
agents/           # Specialized AI agents (frontend, backend, fullstack)
skills/           # Reusable skills (ralph-linear, browser-automation, etc.)
commands/custom/  # Slash commands (analyze-linear-ticket, create-pr, review-and-fix)
bin/              # CLI tools (work-tickets)
```

## Key Files

- `install.sh` - Symlinks config to ~/.claude/
- `uninstall.sh` - Removes symlinks
- `statusline.sh` - Custom terminal statusline
- `settings.json.example` - Example settings

## Skills

| Skill | Purpose |
|-------|---------|
| `ralph-linear` | Full Linear ticket workflow |
| `browser-automation` | Browser testing with agent-browser |
| `react-best-practices` | React/Next.js performance rules |
| `web-design-guidelines` | UI/UX and accessibility |

## Commands

| Command | Purpose |
|---------|---------|
| `analyze-linear-ticket` | Fetch ticket, implement locally |
| `create-pr` | Branch, commit, push, create PR |
| `review-and-fix` | 6-agent review with auto-fix |

## Agents

| Agent | Scope |
|-------|-------|
| `frontend-developer` | UI/React/CSS |
| `backend-developer` | API/DB/server |
| `fullstack-developer` | Both |

## Conventions

- Skills go in `skills/<name>/SKILL.md`
- Commands go in `commands/custom/<name>.md`
- Agents go in `agents/<name>.md`
- Keep README.md updated when adding/removing features
- Test locally before pushing

## Development

When modifying:
1. Edit files in this repo
2. Changes auto-reflect in ~/.claude/ (symlinked)
3. Test with Claude Code
4. Commit and push
