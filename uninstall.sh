#!/bin/bash
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/lib/common.sh"

# Flags
DRY_RUN=false
FORCE=false
REMOVE_ALL=true
REMOVE_TOOLS=false
REMOVE_FONT=false
REMOVE_CONFIG=false
REMOVE_ALIASES=false
REMOVE_SCRIPTS=false
REMOVE_XCODE=false
REMOVE_CLAUDE=false

print_dry_run() { echo -e "${YELLOW}[DRY-RUN]${NC} Would remove: $1"; }

show_help() {
    echo "Usage: ./uninstall.sh [OPTIONS]"
    echo ""
    echo "Remove installed components from your system."
    echo ""
    echo "Options:"
    echo "  --dry-run, -n       Preview what would be removed"
    echo "  --force, -f         Skip confirmation prompts"
    echo "  --tools             Remove the Brewfile packages"
    echo "  --font              Remove JetBrains Mono Nerd Font"
    echo "  --config            Remove SwiftFormat configuration"
    echo "  --aliases           Remove shell aliases"
    echo "  --scripts           Remove custom scripts"
    echo "  --xcode             Remove Xcode themes, templates, headers"
    echo "  --claude            Remove Claude configuration, agents and skills"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./uninstall.sh --dry-run     # Preview all removals"
    echo "  ./uninstall.sh --aliases     # Only remove aliases"
    echo "  ./uninstall.sh --force       # Remove all without prompts"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --tools)
            REMOVE_ALL=false
            REMOVE_TOOLS=true
            shift
            ;;
        --font)
            REMOVE_ALL=false
            REMOVE_FONT=true
            shift
            ;;
        --config)
            REMOVE_ALL=false
            REMOVE_CONFIG=true
            shift
            ;;
        --aliases)
            REMOVE_ALL=false
            REMOVE_ALIASES=true
            shift
            ;;
        --scripts)
            REMOVE_ALL=false
            REMOVE_SCRIPTS=true
            shift
            ;;
        --xcode)
            REMOVE_ALL=false
            REMOVE_XCODE=true
            shift
            ;;
        --claude)
            REMOVE_ALL=false
            REMOVE_CLAUDE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

confirm() {
    if $FORCE || $DRY_RUN; then
        return 0
    fi

    local prompt="$1 [y/N] "
    read -r -p "$prompt" response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Remove Homebrew packages
remove_tools() {
    print_header "Homebrew Packages"

    if ! command_exists brew; then
        print_skip "Homebrew not installed"
        return 0
    fi

    local installed formula
    installed="$(installed_formulae)"

    for formula in $(brewfile_formulae "$REPO_DIR/Brewfile"); do
        if [[ -z "$(formula_version "$installed" "$formula")" ]]; then
            print_skip "$formula not installed"
        elif $DRY_RUN; then
            print_dry_run "$formula (brew uninstall)"
        else
            print_status "Removing $formula..."
            if brew uninstall "$formula" 2>/dev/null; then
                print_success "Removed $formula"
            else
                print_fail "Failed to remove $formula"
            fi
        fi
    done
}

# Remove JetBrains Mono Nerd Font
remove_font() {
    print_header "JetBrains Mono Nerd Font"

    if nerd_font_cask_installed; then
        if $DRY_RUN; then
            print_dry_run "JetBrains Mono Nerd Font (brew uninstall --cask $NERD_FONT_CASK)"
        elif brew uninstall --cask "$NERD_FONT_CASK"; then
            print_success "Removed JetBrains Mono Nerd Font"
        else
            print_fail "Failed to remove the $NERD_FONT_CASK cask"
        fi
        return 0
    fi

    local files
    files="$(nerd_font_files "$HOME/Library/Fonts")"
    if [[ -z "$files" ]]; then
        print_skip "Font not installed"
        return 0
    fi

    if $DRY_RUN; then
        print_dry_run "JetBrains Mono Nerd Font ($(wc -l <<< "$files" | xargs) files)"
        return 0
    fi

    print_status "Removing font files..."
    local file
    while IFS= read -r file; do
        rm -f "$file" || print_fail "Failed to remove $file"
    done <<< "$files"
    print_success "Removed JetBrains Mono Nerd Font"
}

# Remove SwiftFormat configuration
remove_config() {
    print_header "SwiftFormat Configuration"

    local config_file="$HOME/.swiftformat"

    if [[ -f "$config_file" ]]; then
        if $DRY_RUN; then
            print_dry_run "$config_file"
        else
            rm -f "$config_file"
            print_success "Removed .swiftformat"
        fi
    else
        print_skip ".swiftformat not found"
    fi
}

# Remove aliases file and its .zshrc source line
remove_aliases() {
    print_header "Shell Aliases"

    local zshrc_file="$HOME/.zshrc"
    local aliases_file="$HOME/.config/aliases.zsh"
    local removed_any=false

    if [[ -f "$aliases_file" ]]; then
        removed_any=true
        if $DRY_RUN; then
            print_dry_run "$aliases_file"
        else
            rm -f "$aliases_file"
            print_success "Removed ~/.config/aliases.zsh"
        fi
    fi

    if [[ ! -f "$zshrc_file" ]]; then
        $removed_any || print_skip ".zshrc not found"
        return 0
    fi

    if grep -q "aliases.zsh" "$zshrc_file" 2>/dev/null; then
        removed_any=true
        if $DRY_RUN; then
            print_dry_run "Aliases source line from .zshrc"
        else
            cp "$zshrc_file" "$zshrc_file.backup"
            sed -i '' '/^# My config aliases$/d; /source.*aliases\.zsh/d' "$zshrc_file"
            print_success "Removed aliases source line (backup: .zshrc.backup)"
        fi
    fi

    if grep -q "# Git aliases" "$zshrc_file" 2>/dev/null; then
        removed_any=true
        if $DRY_RUN; then
            print_dry_run "Legacy inline aliases section from .zshrc"
        else
            [[ -f "$zshrc_file.backup" ]] || cp "$zshrc_file" "$zshrc_file.backup"
            sed -i '' '/^# Git aliases/,/^alias dl=/d' "$zshrc_file"
            print_success "Removed legacy inline aliases (backup: .zshrc.backup)"
        fi
    fi

    $removed_any || print_skip "Aliases not installed"
    return 0
}

# Remove custom scripts
remove_scripts() {
    print_header "Custom Scripts"

    local bin_dir="$HOME/Developer/bin"

    for script in "$REPO_DIR"/scripts/*.sh; do
        local name
        name="$(basename "$script")"
        if [[ -f "$bin_dir/$name" ]]; then
            if $DRY_RUN; then
                print_dry_run "$bin_dir/$name"
            else
                rm -f "$bin_dir/$name"
                print_success "Removed $name"
            fi
        else
            print_skip "$name not found"
        fi
    done

    # Remove empty bin directory
    if [[ -d "$bin_dir" ]] && [[ -z "$(ls -A "$bin_dir" 2>/dev/null)" ]]; then
        if $DRY_RUN; then
            print_dry_run "$bin_dir (empty directory)"
        else
            rmdir "$bin_dir" 2>/dev/null && print_info "Removed empty bin directory"
        fi
    fi
}

# Remove Xcode customizations
remove_xcode() {
    print_header "Xcode Customizations"

    remove_repo_entries "$REPO_DIR/Themes" "$XC_USER_DATA/FontAndColorThemes" "Xcode theme"
    remove_repo_entries "$REPO_DIR/Templates" "$XC_DIR/Templates" "Xcode template"

    # Header template
    local header_file="$XC_USER_DATA/IDETemplateMacros.plist"
    if [[ -f "$header_file" ]]; then
        if $DRY_RUN; then
            print_dry_run "$header_file"
        else
            rm -f "$header_file"
            print_success "Removed Xcode header template"
        fi
    else
        print_skip "No Xcode header template found"
    fi
}

# Remove Claude configuration
remove_claude() {
    print_header "Claude Configuration"

    local claude_dir="$HOME/.claude"

    # CLAUDE.md
    if [[ -f "$claude_dir/CLAUDE.md" ]]; then
        if $DRY_RUN; then
            print_dry_run "$claude_dir/CLAUDE.md"
        else
            rm -f "$claude_dir/CLAUDE.md"
            print_success "Removed CLAUDE.md"
        fi
    else
        print_skip "CLAUDE.md not found"
    fi

    remove_repo_entries "$REPO_DIR/claude/agents" "$claude_dir/agents" "Claude agent"
    remove_repo_entries "$REPO_DIR/claude/skills" "$claude_dir/skills" "Claude skill"
}

# Only entries shipped by this repo are removed, so themes, templates, agents and skills
# added by the user or other tools are left alone
remove_repo_entries() {
    local repo_dir="$1"
    local installed_dir="$2"
    local label="$3"
    local removed=0

    for entry in "$repo_dir"/*; do
        [[ -e "$entry" ]] || continue
        local name
        name="$(basename "$entry")"
        [[ -e "$installed_dir/$name" ]] || continue
        if $DRY_RUN; then
            print_dry_run "$label: $name"
        else
            rm -rf "${installed_dir:?}/$name"
            print_success "Removed $label: $name"
        fi
        removed=$((removed + 1))
    done

    [[ $removed -gt 0 ]] || print_skip "No ${label}s found"
}

# Print summary
print_summary() {
    echo ""
    if $DRY_RUN; then
        print_title "Dry Run Complete"
    else
        print_title "Uninstall Summary"
        echo -e "  ${GREEN}✓ Removed:${NC} $SUCCEEDED"
        echo -e "  ${YELLOW}− Skipped:${NC} $SKIPPED"
        echo -e "  ${RED}✗ Failed:${NC}  $FAILED"
        print_rule
    fi
    echo ""

    if $DRY_RUN; then
        echo -e "${CYAN}Run without --dry-run to remove components${NC}"
    elif [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}Uninstall completed successfully!${NC}"
    else
        echo -e "${YELLOW}Uninstall completed with $FAILED failure(s)${NC}"
    fi
}

# Main execution
print_banner "🗑️  Configuration Uninstall Script"

if $DRY_RUN; then
    echo -e "${CYAN}Running in dry-run mode - no changes will be made${NC}\n"
fi

# Confirmation for full uninstall
if $REMOVE_ALL && ! $DRY_RUN && ! $FORCE; then
    echo -e "${YELLOW}This will remove all installed components.${NC}"
    if ! confirm "Are you sure you want to continue?"; then
        echo "Uninstall cancelled."
        exit 0
    fi
    echo ""
fi

if $REMOVE_ALL || $REMOVE_TOOLS; then
    remove_tools
fi

if $REMOVE_ALL || $REMOVE_FONT; then
    remove_font
fi

if $REMOVE_ALL || $REMOVE_CONFIG; then
    remove_config
fi

if $REMOVE_ALL || $REMOVE_ALIASES; then
    remove_aliases
fi

if $REMOVE_ALL || $REMOVE_SCRIPTS; then
    remove_scripts
fi

if $REMOVE_ALL || $REMOVE_XCODE; then
    remove_xcode
fi

if $REMOVE_ALL || $REMOVE_CLAUDE; then
    remove_claude
fi

print_summary

if ! $DRY_RUN && [[ $SUCCEEDED -gt 0 ]]; then
    echo -e "\n${YELLOW}Note:${NC} Restart your terminal for alias changes to take effect."
fi
