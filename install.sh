#!/bin/bash

# 10x-claude installer
# Installs Claude Code configuration with agents, skills, commands, and tools

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backup-$(date +%Y%m%d-%H%M%S)"
BIN_DIR="$HOME/bin"

echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}              10x-claude Installer                  ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
  echo -e "${YELLOW}Warning:${NC} Claude Code CLI not found. Install it first:"
  echo "  npm install -g @anthropic-ai/claude-code"
  echo ""
fi

# Create .claude directory if it doesn't exist
if [ ! -d "$CLAUDE_DIR" ]; then
  echo -e "${YELLOW}Creating ~/.claude directory...${NC}"
  mkdir -p "$CLAUDE_DIR"
fi

# Backup existing configs
backup_needed=false
for item in agents skills commands statusline.sh; do
  if [ -e "$CLAUDE_DIR/$item" ] && [ ! -L "$CLAUDE_DIR/$item" ]; then
    backup_needed=true
    break
  fi
done

if [ "$backup_needed" = true ]; then
  echo -e "${YELLOW}Backing up existing configuration...${NC}"
  mkdir -p "$BACKUP_DIR"
  for item in agents skills commands statusline.sh; do
    if [ -e "$CLAUDE_DIR/$item" ] && [ ! -L "$CLAUDE_DIR/$item" ]; then
      cp -r "$CLAUDE_DIR/$item" "$BACKUP_DIR/"
      echo -e "  ${GREEN}✓${NC} Backed up $item"
    fi
  done
  echo -e "  Backup saved to: ${BLUE}$BACKUP_DIR${NC}"
  echo ""
fi

# Remove existing items (symlinks or directories)
echo -e "${YELLOW}Installing configuration...${NC}"
for item in agents skills commands; do
  if [ -L "$CLAUDE_DIR/$item" ]; then
    rm "$CLAUDE_DIR/$item"
  elif [ -d "$CLAUDE_DIR/$item" ]; then
    rm -rf "$CLAUDE_DIR/$item"
  fi
done

# Create symlinks for agents, skills, commands
ln -s "$SCRIPT_DIR/agents" "$CLAUDE_DIR/agents"
echo -e "  ${GREEN}✓${NC} Linked agents/ → ~/.claude/agents"

ln -s "$SCRIPT_DIR/skills" "$CLAUDE_DIR/skills"
echo -e "  ${GREEN}✓${NC} Linked skills/ → ~/.claude/skills"

ln -s "$SCRIPT_DIR/commands" "$CLAUDE_DIR/commands"
echo -e "  ${GREEN}✓${NC} Linked commands/ → ~/.claude/commands"

# Copy statusline.sh (we copy instead of symlink so users can customize)
cp "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh"
chmod +x "$CLAUDE_DIR/statusline.sh"
echo -e "  ${GREEN}✓${NC} Installed statusline.sh"

# Install work-tickets to ~/bin
echo ""
echo -e "${YELLOW}Installing work-tickets CLI...${NC}"
mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/bin/work-tickets" "$BIN_DIR/work-tickets"
chmod +x "$BIN_DIR/work-tickets"
echo -e "  ${GREEN}✓${NC} Installed work-tickets to ~/bin/"

# Check if ~/bin is in PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
  echo ""
  echo -e "${YELLOW}Note:${NC} ~/bin is not in your PATH. Add this to your shell config:"
  echo ""
  echo -e "  ${BLUE}export PATH=\"\$HOME/bin:\$PATH\"${NC}"
  echo ""
fi

# Merge settings.json
echo ""
echo -e "${YELLOW}Configuring settings...${NC}"
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  # Check if statusLine is already configured
  if grep -q '"statusLine"' "$CLAUDE_DIR/settings.json" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} settings.json already exists (statusLine configured)"
  else
    echo -e "  ${YELLOW}!${NC} settings.json exists but statusLine not configured"
    echo -e "    Add this to your settings.json to enable the custom statusline:"
    echo ""
    echo -e '    "statusLine": {'
    echo -e '      "type": "command",'
    echo -e "      \"command\": \"$HOME/.claude/statusline.sh\","
    echo -e '      "padding": 0'
    echo -e '    }'
  fi
else
  # Create minimal settings.json with statusline
  cat > "$CLAUDE_DIR/settings.json" << EOF
{
  "statusLine": {
    "type": "command",
    "command": "$HOME/.claude/statusline.sh",
    "padding": 0
  },
  "hooks": {
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Glass.aiff"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Glass.aiff"
          }
        ]
      }
    ]
  }
}
EOF
  echo -e "  ${GREEN}✓${NC} Created settings.json with statusline and notification hooks"
fi

# Print plugin installation instructions
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}              Required Plugins                     ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Install these plugins for full functionality:"
echo ""
echo -e "  ${YELLOW}claude plugins add ralph-loop@claude-plugins-official${NC}"
echo -e "  ${YELLOW}claude plugins add frontend-design@claude-plugins-official${NC}"
echo -e "  ${YELLOW}claude plugins add context7@claude-plugins-official${NC}"
echo -e "  ${YELLOW}claude plugins add feature-dev@claude-plugins-official${NC}"
echo -e "  ${YELLOW}claude plugins add code-review@claude-plugins-official${NC}"
echo -e "  ${YELLOW}claude plugins add linear@claude-plugins-official${NC}"
echo -e "  ${YELLOW}claude plugins add playwright@claude-plugins-official${NC}"
echo -e "  ${YELLOW}claude plugins add supabase@claude-plugins-official${NC}"
echo -e "  ${YELLOW}claude plugins add pr-review-toolkit@claude-plugins-official${NC}"
echo ""
echo -e "Or install all at once:"
echo ""
echo -e "  ${BLUE}claude plugins add ralph-loop@claude-plugins-official frontend-design@claude-plugins-official context7@claude-plugins-official feature-dev@claude-plugins-official code-review@claude-plugins-official linear@claude-plugins-official playwright@claude-plugins-official supabase@claude-plugins-official pr-review-toolkit@claude-plugins-official${NC}"
echo ""

echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}            Installation Complete!                 ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "What's installed:"
echo -e "  • ${BLUE}5 Custom Agents${NC}: backend-developer, frontend-developer, fullstack-developer, code-reviewer, project-manager"
echo -e "  • ${BLUE}5 Skills${NC}: ralph-workflow, react-best-practices, agent-identifier, skill-writer, web-design-guidelines"
echo -e "  • ${BLUE}4 Commands${NC}: /analyze-linear-ticket, /create-pr, /review-pr, /review-and-fix"
echo -e "  • ${BLUE}Custom Statusline${NC}: Git info, context usage, session stats"
echo -e "  • ${BLUE}work-tickets CLI${NC}: Process multiple Linear tickets in parallel"
echo ""
echo -e "Restart Claude Code to apply changes."
