# 10x-claude

Supercharge your Claude Code with custom agents, skills, commands, and parallel ticket processing. Ship faster.

## Quick Install

```bash
git clone https://github.com/SafaElmali/10x-claude.git
cd 10x-claude
./install.sh
```

## What's Included

### Custom Agents

Specialized AI agents for different development tasks:

| Agent | Description |
|-------|-------------|
| `backend-developer` | API design, database work, server-side logic, authentication |
| `frontend-developer` | React/Next.js components, state management, accessibility |
| `fullstack-developer` | End-to-end feature development spanning frontend and backend |

### Skills

Reusable skills that Claude can invoke:

| Skill | Command | Description |
|-------|---------|-------------|
| Ralph Linear | `/ralph-linear` | Comprehensive Linear ticket workflow (auto-applies quality checks for frontend) |
| React Best Practices | `/react-best-practices` | 40+ performance optimization rules (auto-applied in ralph-linear) |
| Web Design Guidelines | `/web-design-guidelines` | UI/UX review against best practices (auto-applied in ralph-linear) |
| Browser Automation | `/browser-automation` | Browser automation for testing and scraping |

#### agent-browser vs Playwright MCP

| | **agent-browser CLI** | **Playwright MCP** |
|---|---|---|
| **Speed** | Faster for simple tasks | More overhead |
| **Best for** | Screenshots, quick checks | Complex multi-step flows |
| **State** | Stateless between commands | Maintains browser session |

```
Need a screenshot?           → agent-browser
Testing a user flow?         → Playwright MCP
Simple click + verify?       → agent-browser
Login → do stuff → verify?   → Playwright MCP
```

### Commands

Custom slash commands for common workflows:

| Command | Description |
|---------|-------------|
| `/review-pr` | Review PR with inline GitHub comments (human-tone feedback) |
| `/analyze-linear-ticket` | Fetch and analyze a Linear ticket |
| `/create-pr` | Create branch, commit, and PR from Linear ticket |
| `/review-and-fix` | Comprehensive code review with auto-fix using 6 agents |

### Tools

#### work-tickets CLI

Process multiple Linear tickets in parallel with dedicated worktrees:

```bash
# Single ticket
work-tickets WEB-5503

# Multiple tickets (opens in split panes)
work-tickets WEB-5503 WEB-5563 WEB-5905

# Use Ralph workflow for iterative development
work-tickets --ralph WEB-5503

# Cleanup when done
work-tickets --cleanup
```

### Custom Statusline

A rich statusline showing:
- Current model and working directory
- Git repo, branch, and commit info
- Uncommitted changes indicator
- Lines added/removed
- Context window usage (visual bricks)
- Session duration and cost

## Required Plugins

After running the install script, install these plugins:

```bash
claude plugins add ralph-loop@claude-plugins-official
claude plugins add frontend-design@claude-plugins-official
claude plugins add context7@claude-plugins-official
claude plugins add feature-dev@claude-plugins-official
claude plugins add linear@claude-plugins-official
claude plugins add playwright@claude-plugins-official
claude plugins add supabase@claude-plugins-official
claude plugins add pr-review-toolkit@claude-plugins-official
claude plugins add github@claude-plugins-official
claude plugins add agent-sdk-dev@claude-plugins-official
claude plugins add plugin-dev@claude-plugins-official
```

Or all at once:

```bash
claude plugins add ralph-loop@claude-plugins-official frontend-design@claude-plugins-official context7@claude-plugins-official feature-dev@claude-plugins-official linear@claude-plugins-official playwright@claude-plugins-official supabase@claude-plugins-official pr-review-toolkit@claude-plugins-official github@claude-plugins-official agent-sdk-dev@claude-plugins-official plugin-dev@claude-plugins-official
```

## Manual Installation

If you prefer manual setup:

1. **Symlink directories** to `~/.claude/`:
   ```bash
   ln -s /path/to/repo/agents ~/.claude/agents
   ln -s /path/to/repo/skills ~/.claude/skills
   ln -s /path/to/repo/commands ~/.claude/commands
   ```

2. **Copy statusline**:
   ```bash
   cp statusline.sh ~/.claude/statusline.sh
   chmod +x ~/.claude/statusline.sh
   ```

3. **Install work-tickets**:
   ```bash
   cp bin/work-tickets ~/bin/
   chmod +x ~/bin/work-tickets
   ```

4. **Configure settings.json** (see `settings.json.example`):
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/statusline.sh",
       "padding": 0
     }
   }
   ```

5. **Add ~/bin to PATH** (if not already):
   ```bash
   export PATH="$HOME/bin:$PATH"
   ```

## Uninstall

```bash
./uninstall.sh
```

This will:
- Remove symlinks from `~/.claude/`
- Optionally remove `work-tickets` from `~/bin/`
- Optionally restore from backup (if one exists)

## Customization

### Adding Custom Agents

Create a new `.md` file in `agents/`:

```markdown
---
name: my-agent
description: What this agent does
model: inherit
color: blue
---

Your agent's system prompt here...
```

### Adding Custom Skills

Create a new directory in `skills/` with a `SKILL.md` file. See existing skills for examples.

### Modifying Statusline

Edit `~/.claude/statusline.sh` after installation (it's copied, not symlinked, so your changes persist).

## Repository Structure

```
10x-claude/
├── README.md                    # This file
├── install.sh                   # Installer script
├── uninstall.sh                 # Uninstaller script
├── settings.json.example        # Example settings
├── statusline.sh                # Custom statusline script
├── bin/
│   └── work-tickets             # Multi-ticket CLI tool
├── agents/
│   ├── backend-developer.md
│   ├── frontend-developer.md
│   └── fullstack-developer.md
├── skills/
│   ├── browser-automation/
│   ├── ralph-linear/
│   ├── react-best-practices/
│   └── web-design-guidelines/
└── commands/
    └── custom/
        ├── analyze-linear-ticket.md
        ├── create-pr.md
        ├── review-and-fix.md
        └── review-pr.md
```

## License

MIT
