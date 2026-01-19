#!/bin/bash

# 10x-claude uninstaller
# Removes installed symlinks and optionally restores backups

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
CLAUDE_DIR="$HOME/.claude"
BIN_DIR="$HOME/bin"

echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}             10x-claude Uninstaller                 ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# Remove symlinks
echo -e "${YELLOW}Removing installed configuration...${NC}"

for item in agents skills commands; do
  if [ -L "$CLAUDE_DIR/$item" ]; then
    rm "$CLAUDE_DIR/$item"
    echo -e "  ${GREEN}✓${NC} Removed symlink: ~/.claude/$item"
  elif [ -d "$CLAUDE_DIR/$item" ]; then
    echo -e "  ${YELLOW}!${NC} ~/.claude/$item is not a symlink (skipped)"
  else
    echo -e "  ${YELLOW}!${NC} ~/.claude/$item not found (skipped)"
  fi
done

# Remove statusline.sh
if [ -f "$CLAUDE_DIR/statusline.sh" ]; then
  rm "$CLAUDE_DIR/statusline.sh"
  echo -e "  ${GREEN}✓${NC} Removed statusline.sh"
fi

# Optionally remove work-tickets
echo ""
read -p "Remove work-tickets from ~/bin? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if [ -f "$BIN_DIR/work-tickets" ]; then
    rm "$BIN_DIR/work-tickets"
    echo -e "  ${GREEN}✓${NC} Removed ~/bin/work-tickets"
  else
    echo -e "  ${YELLOW}!${NC} ~/bin/work-tickets not found"
  fi
fi

# Check for backups
echo ""
backups=$(find "$CLAUDE_DIR" -maxdepth 1 -type d -name "backup-*" 2>/dev/null | sort -r)
if [ -n "$backups" ]; then
  echo -e "${YELLOW}Found backup(s):${NC}"
  echo "$backups" | while read -r backup; do
    echo -e "  ${BLUE}$(basename "$backup")${NC}"
  done
  echo ""

  latest_backup=$(echo "$backups" | head -1)
  read -p "Restore from latest backup ($(basename "$latest_backup"))? [y/N] " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    for item in agents skills commands statusline.sh; do
      if [ -e "$latest_backup/$item" ]; then
        cp -r "$latest_backup/$item" "$CLAUDE_DIR/$item"
        echo -e "  ${GREEN}✓${NC} Restored $item from backup"
      fi
    done
    echo ""
    echo -e "${GREEN}Backup restored!${NC}"
  fi
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}            Uninstall Complete!                    ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} Plugins were not removed. To remove them:"
echo -e "  claude plugins remove <plugin-name>"
echo ""
echo -e "Restart Claude Code to apply changes."
