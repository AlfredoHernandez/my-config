#!/bin/bash

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="/Users/$USER/Library/Developer/Xcode/UserData"

mkdir -p "./backup"
DEST="./backup"

# Backup Xcode themes
echo "[*] Backing up Xcode themes..."
cp "$XC_USER_DATA"/FontAndColorThemes/*.xccolortheme "$DEST" 2>/dev/null || echo "[!] No themes found to backup"

# Backup Xcode header template
echo "[*] Backing up Xcode header template..."
cp "$XC_USER_DATA"/IDETemplateMacros.plist "$DEST" 2>/dev/null || echo "[!] No header template found to backup"

# Backup Xcode templates
echo "[*] Backing up Xcode templates..."
cp -r "$XC_DIR"/Templates/ "$DEST" 2>/dev/null || echo "[!] No templates found to backup"

# Backup custom scripts
echo "[*] Backing up custom scripts..."
if [ -d "$HOME/Developer/bin" ]; then
    mkdir -p "$DEST/scripts"
    cp "$HOME/Developer/bin"/*.sh "$DEST/scripts/" 2>/dev/null || echo "[!] No custom scripts found to backup"
else
    echo "[!] No custom scripts directory found to backup"
fi

# Backup .zshrc aliases (extract only our aliases section)
echo "[*] Backing up .zshrc aliases..."
if [ -f "$HOME/.zshrc" ]; then
    # Extract aliases section from .zshrc
    awk '/^# Git aliases/,/^alias dl=/' "$HOME/.zshrc" > "$DEST/aliases_backup.txt" 2>/dev/null || echo "[!] No aliases found to backup"
else
    echo "[!] No .zshrc file found to backup"
fi

# Backup Claude Code configuration
echo "[*] Backing up Claude Code configuration..."
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
    mkdir -p "$DEST/claude"
    cp "$HOME/.claude/CLAUDE.md" "$DEST/claude/" 2>/dev/null || echo "[!] Failed to backup CLAUDE.md"
else
    echo "[!] No CLAUDE.md found to backup"
fi

# Backup Claude agents
echo "[*] Backing up Claude agents..."
if [ -d "$HOME/.claude/agents" ]; then
    mkdir -p "$DEST/claude/agents"
    cp -r "$HOME/.claude/agents"/* "$DEST/claude/agents/" 2>/dev/null || echo "[!] No agents found to backup"
else
    echo "[!] No agents directory found to backup"
fi

echo "[*] Backup completed successfully!"
# cp "$XC_USER_DATA"/KeyBindings/*.idekeybindings "$DEST"
# cp "$XC_USER_DATA"/xcdebugger/Breakpoints_v2.xcbkptlist "$DEST"