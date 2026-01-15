#!/bin/bash
set -uo pipefail

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="/Users/$USER/Library/Developer/Xcode/UserData"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Counters
SUCCESS=0
FAILED=0
SKIPPED=0

# Create backup directory
mkdir -p "./backup"
DEST="./backup"

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((SUCCESS++))
}

print_fail() {
    echo -e "${RED}[✗]${NC} $1"
    ((FAILED++))
}

print_skip() {
    echo -e "${YELLOW}[−]${NC} $1"
    ((SKIPPED++))
}

print_status() {
    echo -e "${CYAN}[*]${NC} $1"
}

# Backup Xcode themes
backup_themes() {
    print_status "Backing up Xcode themes..."
    local theme_dir="$XC_USER_DATA/FontAndColorThemes"

    if [[ -d "$theme_dir" ]] && ls "$theme_dir"/*.xccolortheme &>/dev/null; then
        if cp "$theme_dir"/*.xccolortheme "$DEST" 2>/dev/null; then
            local count=$(ls "$DEST"/*.xccolortheme 2>/dev/null | wc -l | xargs)
            print_success "Backed up $count theme(s)"
        else
            print_fail "Failed to copy themes"
        fi
    else
        print_skip "No themes found to backup"
    fi
}

# Backup Xcode header template
backup_header() {
    print_status "Backing up Xcode header template..."
    local header_file="$XC_USER_DATA/IDETemplateMacros.plist"

    if [[ -f "$header_file" ]]; then
        if cp "$header_file" "$DEST" 2>/dev/null; then
            print_success "Backed up header template"
        else
            print_fail "Failed to copy header template"
        fi
    else
        print_skip "No header template found"
    fi
}

# Backup Xcode templates
backup_templates() {
    print_status "Backing up Xcode templates..."
    local templates_dir="$XC_DIR/Templates"

    if [[ -d "$templates_dir" ]] && [[ -n "$(ls -A "$templates_dir" 2>/dev/null)" ]]; then
        if cp -r "$templates_dir" "$DEST" 2>/dev/null; then
            print_success "Backed up Xcode templates"
        else
            print_fail "Failed to copy templates"
        fi
    else
        print_skip "No templates found to backup"
    fi
}

# Backup custom scripts
backup_scripts() {
    print_status "Backing up custom scripts..."
    local scripts_dir="$HOME/Developer/bin"

    if [[ -d "$scripts_dir" ]] && ls "$scripts_dir"/*.sh &>/dev/null; then
        mkdir -p "$DEST/scripts"
        if cp "$scripts_dir"/*.sh "$DEST/scripts/" 2>/dev/null; then
            local count=$(ls "$DEST/scripts"/*.sh 2>/dev/null | wc -l | xargs)
            print_success "Backed up $count script(s)"
        else
            print_fail "Failed to copy scripts"
        fi
    else
        print_skip "No custom scripts found"
    fi
}

# Backup .zshrc aliases
backup_aliases() {
    print_status "Backing up .zshrc aliases..."
    local zshrc="$HOME/.zshrc"

    if [[ -f "$zshrc" ]] && grep -q "# Git aliases" "$zshrc" 2>/dev/null; then
        if awk '/^# Git aliases/,/^alias dl=/' "$zshrc" > "$DEST/aliases_backup.txt" 2>/dev/null; then
            if [[ -s "$DEST/aliases_backup.txt" ]]; then
                print_success "Backed up aliases"
            else
                rm -f "$DEST/aliases_backup.txt"
                print_fail "Failed to extract aliases"
            fi
        else
            print_fail "Failed to backup aliases"
        fi
    else
        print_skip "No aliases section found in .zshrc"
    fi
}

# Backup Claude Code configuration
backup_claude_config() {
    print_status "Backing up Claude Code configuration..."
    local claude_config="$HOME/.claude/CLAUDE.md"

    if [[ -f "$claude_config" ]]; then
        mkdir -p "$DEST/claude"
        if cp "$claude_config" "$DEST/claude/" 2>/dev/null; then
            print_success "Backed up CLAUDE.md"
        else
            print_fail "Failed to copy CLAUDE.md"
        fi
    else
        print_skip "No CLAUDE.md found"
    fi
}

# Backup Claude agents
backup_claude_agents() {
    print_status "Backing up Claude agents..."
    local agents_dir="$HOME/.claude/agents"

    if [[ -d "$agents_dir" ]] && [[ -n "$(ls -A "$agents_dir" 2>/dev/null)" ]]; then
        mkdir -p "$DEST/claude/agents"
        if cp -r "$agents_dir"/* "$DEST/claude/agents/" 2>/dev/null; then
            local count=$(ls "$DEST/claude/agents"/*.md 2>/dev/null | wc -l | xargs)
            print_success "Backed up $count agent(s)"
        else
            print_fail "Failed to copy agents"
        fi
    else
        print_skip "No agents found"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}Backup Summary${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}✓ Successful:${NC} $SUCCESS"
    echo -e "  ${RED}✗ Failed:${NC}     $FAILED"
    echo -e "  ${YELLOW}− Skipped:${NC}    $SKIPPED"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${CYAN}Backup location:${NC} $DEST"
    echo ""

    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}Backup completed successfully!${NC}"
        return 0
    else
        echo -e "${YELLOW}Backup completed with $FAILED failure(s)${NC}"
        return 1
    fi
}

# Main execution
echo -e "${WHITE}"
echo "╔════════════════════════════════════════════════════╗"
echo "║          📦 Configuration Backup Script            ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

backup_themes
backup_header
backup_templates
backup_scripts
backup_aliases
backup_claude_config
backup_claude_agents

print_summary
