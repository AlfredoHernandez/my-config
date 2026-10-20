#!/bin/bash
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/lib/common.sh"
source "$REPO_DIR/lib/claude-settings.sh"
source "$REPO_DIR/lib/retired-entries.sh"

# Compare and sync a single file
# Returns 0 if updated, 1 if up-to-date, 2 if source missing, 3 if the repo copy is newer
sync_file() {
    local source="$1"
    local dest="$2"
    local label="$3"

    if [[ ! -f "$source" ]]; then
        print_skip "$label (not installed)"
        return 2
    fi

    if [[ ! -f "$dest" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp "$source" "$dest"
        print_updated "$label (new file)"
        return 0
    fi

    if ! diff -q "$source" "$dest" &>/dev/null; then
        if [[ "$dest" -nt "$source" ]]; then
            print_warning "$label (repo copy is newer: run ./install.sh first)"
            return 3
        fi
        cp "$source" "$dest"
        print_updated "$label"
        return 0
    fi

    print_success "$label"
    return 1
}

# Compare and sync a directory
sync_dir() {
    local source="$1"
    local dest="$2"
    local label="$3"

    if [[ ! -d "$source" ]] || [[ -z "$(ls -A "$source" 2>/dev/null)" ]]; then
        print_skip "$label (not installed)"
        return 2
    fi

    local dir_updated=false

    for file in "$source"/*; do
        local filename
        filename="$(basename "$file")"
        [[ "$filename" == "__pycache__" ]] && continue

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
        print_skip "No Xcode themes installed"
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
        print_skip "No custom scripts installed"
    fi
}

# Sync aliases from the installed location back into the repo
sync_aliases() {
    print_status "Checking aliases..."
    local zshrc="$HOME/.zshrc"
    local aliases_file="$HOME/.config/aliases.zsh"
    local dest="$REPO_DIR/config/aliases.zsh"

    if [[ -f "$aliases_file" ]]; then
        sync_file "$aliases_file" "$dest" "Aliases"
        return
    fi

    if [[ ! -f "$zshrc" ]] || ! grep -q "# Git aliases" "$zshrc" 2>/dev/null; then
        print_skip "No aliases found in ~/.config/aliases.zsh or .zshrc"
        return
    fi

    local tmp
    tmp="$(mktemp)"
    awk '/^# Git aliases/,/^alias dl=/' "$zshrc" > "$tmp" 2>/dev/null

    if [[ -s "$tmp" ]]; then
        if ! diff -q "$tmp" "$dest" &>/dev/null; then
            cp "$tmp" "$dest"
            print_updated "Aliases (legacy inline .zshrc block)"
        else
            print_success "Aliases"
        fi
    else
        print_skip "No aliases section found in .zshrc"
    fi
    rm -f "$tmp"
}

# Copy only the repo-owned keys of the installed settings into the repo file
sync_claude_settings() {
    local installed="$HOME/.claude/settings.json"
    local repo_file="$REPO_DIR/claude/settings.json"
    local label="Claude: settings.json (shared keys)"

    if [[ ! -f "$installed" ]]; then
        print_skip "$label (not installed)"
        return
    fi
    if ! command -v jq &>/dev/null; then
        print_skip "$label (jq not installed)"
        return
    fi

    [[ -f "$repo_file" ]] || echo '{}' > "$repo_file"
    if ! jq empty "$installed" "$repo_file" 2>/dev/null; then
        print_skip "$label (invalid JSON)"
        return
    fi

    local owned merged
    owned="$(mktemp)"
    merged="$(mktemp)"
    if ! claude_settings_owned_subset "$installed" "$repo_file" > "$owned" ||
       ! claude_settings_merge_owned "$repo_file" "$owned" > "$merged"; then
        print_skip "$label (merge failed)"
        rm -f "$owned" "$merged"
        return
    fi

    if claude_settings_equal "$merged" "$repo_file"; then
        print_success "$label"
    else
        cp "$merged" "$repo_file"
        print_updated "$label"
    fi
    rm -f "$owned" "$merged"
}

# Sync Claude Code configuration
sync_claude() {
    print_status "Checking Claude Code configuration..."
    sync_file "$HOME/.claude/CLAUDE.md" "$REPO_DIR/claude/CLAUDE.md" "Claude: CLAUDE.md"
    sync_claude_settings

    # Sync agents
    local agents_dir="$HOME/.claude/agents"
    if [[ -d "$agents_dir" ]] && [[ -n "$(ls -A "$agents_dir" 2>/dev/null)" ]]; then
        local retired
        retired="$(retired_repo_entries "$REPO_DIR" "claude/agents")"
        for agent in "$agents_dir"/*.md; do
            local name
            name="$(basename "$agent")"
            if grep -qxF "$name" <<< "$retired"; then
                print_warning "Claude agent: $name (deleted from the repo: run ./install.sh to remove it)"
                continue
            fi
            sync_file "$agent" "$REPO_DIR/claude/agents/$name" "Claude agent: $name"
        done
    else
        print_skip "No Claude agents installed"
    fi

    sync_claude_skills
}

# Sync only the skills already tracked in the repo, so skills installed by other tools stay out
sync_claude_skills() {
    local skills_dir="$HOME/.claude/skills"
    local tracked=false

    for skill in "$REPO_DIR"/claude/skills/*/; do
        [[ -d "$skill" ]] || continue
        local name
        name="$(basename "$skill")"
        tracked=true
        if [[ -f "$skills_dir/$name/SKILL.md" ]]; then
            sync_dir "$skills_dir/$name" "${skill%/}" "Claude skill: $name"
        else
            print_skip "Claude skill: $name (not installed)"
        fi
    done

    $tracked || print_success "No Claude skills tracked in the repo"
}

# Sync SwiftFormat configuration
sync_swiftformat() {
    print_status "Checking SwiftFormat configuration..."
    sync_file "$HOME/.swiftformat" "$REPO_DIR/config/swiftformat.txt" "SwiftFormat config"
}

# Print summary and suggest commit
print_summary() {
    echo ""
    print_title "Backup Summary"
    echo -e "  ${GREEN}↑ Updated:${NC}       $UPDATED"
    echo -e "  ${GREEN}✓ Up to date:${NC}    $SUCCEEDED"
    echo -e "  ${YELLOW}− Missing:${NC}       $SKIPPED"
    echo -e "  ${YELLOW}! Newer in repo:${NC} $WARNINGS"
    print_rule
    echo ""

    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${RED}Some files were skipped because this Mac is behind the repo.${NC}"
        echo -e "Run ${WHITE}./install.sh${NC} to bring it in sync, then sync again."
        echo ""
    fi

    if [[ $UPDATED -gt 0 ]]; then
        echo -e "${GREEN}Configuration updated!${NC} Review the changes, then stage and commit them by path:"
        echo ""
        echo -e "  ${WHITE}git status && git diff${NC}"
        echo ""
    else
        echo -e "${CYAN}Everything is up to date. No changes needed.${NC}"
    fi
}

# Main execution
print_banner "🔄 Configuration Sync Script"

sync_themes
sync_header
sync_templates
sync_scripts
sync_aliases
sync_claude
sync_swiftformat

print_summary
