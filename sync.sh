#!/bin/bash
set -uo pipefail

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="$XC_DIR/UserData"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Counters
UPDATED=0
UP_TO_DATE=0
MISSING=0
CHANGES=()

print_updated() {
    echo -e "${GREEN}[↑]${NC} $1"
    ((UPDATED++))
    CHANGES+=("$1")
}

print_ok() {
    echo -e "${CYAN}[✓]${NC} $1"
    ((UP_TO_DATE++))
}

print_missing() {
    echo -e "${YELLOW}[−]${NC} $1"
    ((MISSING++))
}

print_status() {
    echo -e "${CYAN}[*]${NC} $1"
}

# Compare and sync a single file
# Returns 0 if updated, 1 if up-to-date, 2 if source missing
sync_file() {
    local source="$1"
    local dest="$2"
    local label="$3"

    if [[ ! -f "$source" ]]; then
        print_missing "$label (not installed)"
        return 2
    fi

    if [[ ! -f "$dest" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp "$source" "$dest"
        print_updated "$label (new file)"
        return 0
    fi

    if ! diff -q "$source" "$dest" &>/dev/null; then
        cp "$source" "$dest"
        print_updated "$label"
        return 0
    fi

    print_ok "$label"
    return 1
}

# Compare and sync a directory
sync_dir() {
    local source="$1"
    local dest="$2"
    local label="$3"

    if [[ ! -d "$source" ]] || [[ -z "$(ls -A "$source" 2>/dev/null)" ]]; then
        print_missing "$label (not installed)"
        return 2
    fi

    local dir_updated=false

    for file in "$source"/*; do
        local filename
        filename="$(basename "$file")"

        if [[ -d "$file" ]]; then
            sync_dir "$file" "$dest/$filename" "$label/$filename"
            [[ $? -eq 0 ]] && dir_updated=true
        else
            sync_file "$file" "$dest/$filename" "$label/$filename"
            [[ $? -eq 0 ]] && dir_updated=true
        fi
    done

    $dir_updated && return 0 || return 1
}

# Sync Xcode themes
sync_themes() {
    print_status "Checking Xcode themes..."
    local theme_dir="$XC_USER_DATA/FontAndColorThemes"

    if [[ -d "$theme_dir" ]] && ls "$theme_dir"/*.xccolortheme &>/dev/null; then
        for theme in "$theme_dir"/*.xccolortheme; do
            local name
            name="$(basename "$theme")"
            sync_file "$theme" "$REPO_DIR/Themes/$name" "Theme: $name"
        done
    else
        print_missing "No Xcode themes installed"
    fi
}

# Sync Xcode header template
sync_header() {
    print_status "Checking Xcode header template..."
    sync_file "$XC_USER_DATA/IDETemplateMacros.plist" "$REPO_DIR/Headers/IDETemplateMacros.plist" "Header template"
}

# Sync Xcode templates
sync_templates() {
    print_status "Checking Xcode templates..."
    local templates_dir="$XC_DIR/Templates"
    sync_dir "$templates_dir" "$REPO_DIR/Templates" "Templates"
}

# Sync custom scripts
sync_scripts() {
    print_status "Checking custom scripts..."
    local scripts_dir="$HOME/Developer/bin"

    if [[ -d "$scripts_dir" ]] && ls "$scripts_dir"/*.sh &>/dev/null; then
        for script in "$scripts_dir"/*.sh; do
            local name
            name="$(basename "$script")"
            sync_file "$script" "$REPO_DIR/scripts/$name" "Script: $name"
        done
    else
        print_missing "No custom scripts installed"
    fi
}

# Sync .zshrc aliases
sync_aliases() {
    print_status "Checking aliases..."
    local zshrc="$HOME/.zshrc"
    local dest="$REPO_DIR/config/aliases.zsh"

    if [[ -f "$zshrc" ]] && grep -q "# Git aliases" "$zshrc" 2>/dev/null; then
        local tmp
        tmp="$(mktemp)"
        awk '/^# Git aliases/,/^alias dl=/' "$zshrc" > "$tmp" 2>/dev/null

        if [[ -s "$tmp" ]]; then
            if ! diff -q "$tmp" "$dest" &>/dev/null; then
                cp "$tmp" "$dest"
                print_updated "Aliases"
            else
                print_ok "Aliases"
            fi
        else
            print_missing "No aliases section found in .zshrc"
        fi
        rm -f "$tmp"
    else
        print_missing "No aliases section found in .zshrc"
    fi
}

# Sync Claude Code configuration
sync_claude() {
    print_status "Checking Claude Code configuration..."
    sync_file "$HOME/.claude/CLAUDE.md" "$REPO_DIR/claude/CLAUDE.md" "Claude: CLAUDE.md"
    sync_file "$HOME/.claude/settings.json" "$REPO_DIR/claude/settings.json" "Claude: settings.json"

    # Sync agents
    local agents_dir="$HOME/.claude/agents"
    if [[ -d "$agents_dir" ]] && [[ -n "$(ls -A "$agents_dir" 2>/dev/null)" ]]; then
        for agent in "$agents_dir"/*.md; do
            local name
            name="$(basename "$agent")"
            sync_file "$agent" "$REPO_DIR/claude/agents/$name" "Claude agent: $name"
        done
    else
        print_missing "No Claude agents installed"
    fi
}

# Sync SwiftFormat configuration
sync_swiftformat() {
    print_status "Checking SwiftFormat configuration..."
    sync_file "$HOME/.swiftformat" "$REPO_DIR/config/swiftformat.txt" "SwiftFormat config"
}

# Print summary and suggest commit
print_summary() {
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}Backup Summary${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}↑ Updated:${NC}    $UPDATED"
    echo -e "  ${CYAN}✓ Up to date:${NC} $UP_TO_DATE"
    echo -e "  ${YELLOW}− Missing:${NC}    $MISSING"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [[ $UPDATED -gt 0 ]]; then
        echo -e "${GREEN}Configuration updated!${NC} Run the following to save your changes:"
        echo ""
        echo -e "  ${WHITE}git add -A && git commit -m \"Update configuration backup\" && git push${NC}"
        echo ""
    else
        echo -e "${CYAN}Everything is up to date. No changes needed.${NC}"
    fi
}

# Main execution
echo -e "${WHITE}"
echo "╔════════════════════════════════════════════════════╗"
echo "║          🔄 Configuration Sync Script              ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

sync_themes
sync_header
sync_templates
sync_scripts
sync_aliases
sync_claude
sync_swiftformat

print_summary
