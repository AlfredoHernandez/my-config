#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
source "$REPO_DIR/lib/common.sh"
source "$REPO_DIR/lib/claude-settings.sh"
source "$REPO_DIR/lib/retired-entries.sh"
source "$REPO_DIR/lib/config-install.sh"

# Error handler
trap 'echo "Error: Command failed at line $LINENO. Exit code: $?" >&2' ERR

# Flags
CHECK_ONLY=false
DRY_RUN=false
UPDATE_ALL=true
UPDATE_REPO=false
UPDATE_TOOLS=false
UPDATE_CONFIG=false
UPDATE_FONT=false
REPO_CHANGED=false
REPO_PREVIOUS_COMMIT=""

print_check() { echo -e "${CYAN}[CHECK]${NC} $1"; }

report_unchanged() { SKIPPED=$((SKIPPED + 1)); }
report_changed() { print_updated "$1"; }
report_planned() { print_check "$1"; }
report_warning() { print_warning "$1"; }
report_failure() { print_fail "$1"; }

show_help() {
    echo "Usage: ./update.sh [OPTIONS]"
    echo ""
    echo "Update installed components to their latest versions."
    echo ""
    echo "Options:"
    echo "  --check, -c       Show what's outdated without updating"
    echo "  --repo            Update repository only (git pull)"
    echo "  --tools           Update Homebrew packages only"
    echo "  --config          Sync configuration files only"
    echo "  --font            Update Nerd Font only"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./update.sh              # Update everything"
    echo "  ./update.sh --check      # Preview what would be updated"
    echo "  ./update.sh --tools      # Only update Homebrew packages"
}

ORIGINAL_ARGS=("$@")

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --check|-c)
            CHECK_ONLY=true
            shift
            ;;
        --repo)
            UPDATE_ALL=false
            UPDATE_REPO=true
            shift
            ;;
        --tools)
            UPDATE_ALL=false
            UPDATE_TOOLS=true
            shift
            ;;
        --config)
            UPDATE_ALL=false
            UPDATE_CONFIG=true
            shift
            ;;
        --font)
            UPDATE_ALL=false
            UPDATE_FONT=true
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

# Set only by the restart below; cleared so the processes this run starts don't inherit it
RESTARTED_FROM="${MY_CONFIG_UPDATE_RESTARTED_FROM:-}"
unset MY_CONFIG_UPDATE_RESTARTED_FROM

# Update repository
update_repo() {
    print_header "Repository Update"
    if ! cd "$SCRIPT_DIR"; then
        print_fail "Cannot enter $SCRIPT_DIR"
        return 1
    fi

    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    if [[ "$current_branch" != "main" ]]; then
        print_skip "Repository is on '$current_branch', not main: skipping pull"
        return 0
    fi

    local current_commit

    current_commit=$(git rev-parse HEAD)

    if $CHECK_ONLY; then
        git fetch origin main --quiet 2>/dev/null || true
        local behind
        behind=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo "0")
        if [[ "$behind" -gt 0 ]]; then
            print_check "Repository is $behind commit(s) behind origin/main"
        else
            print_info "Repository is up to date"
        fi
        return 0
    fi

    print_status "Pulling latest changes..."
    if git pull --ff-only origin main; then
        local new_commit
        new_commit=$(git rev-parse HEAD)
        if [[ "$current_commit" != "$new_commit" ]]; then
            print_updated "Repository updated"
            REPO_CHANGED=true
            REPO_PREVIOUS_COMMIT="$current_commit"
        else
            print_skip "Repository already up to date"
        fi
    else
        print_fail "Failed to update repository"
    fi
}

# The steps after the pull must run the code the pull brought, not the copy of this script and
# its libs already loaded in memory, so restart once with the same arguments
restart_if_repo_changed() {
    $REPO_CHANGED || return 0
    $UPDATE_ALL || $UPDATE_TOOLS || $UPDATE_CONFIG || $UPDATE_FONT || return 0
    if [[ ! -f "$SCRIPT_DIR/update.sh" ]]; then
        print_warning "update.sh not found after the pull: continuing with the loaded version"
        return 0
    fi
    print_info "Restarting with the updated update.sh"
    shopt -s execfail
    MY_CONFIG_UPDATE_RESTARTED_FROM="$REPO_PREVIOUS_COMMIT" \
        exec "$BASH" "$SCRIPT_DIR/update.sh" ${ORIGINAL_ARGS[@]+"${ORIGINAL_ARGS[@]}"}
    print_warning "Could not restart update.sh: continuing with the loaded version"
}

# True only in the run started by restart_if_repo_changed: the marker must name an older
# commit of the current HEAD, so a stale or hand-set value falls back to a normal pull
is_restarted_run() {
    [[ -n "$RESTARTED_FROM" ]] && ! $CHECK_ONLY || return 1
    [[ "$RESTARTED_FROM" != "$(git -C "$SCRIPT_DIR" rev-parse HEAD)" ]] &&
        git -C "$SCRIPT_DIR" merge-base --is-ancestor "$RESTARTED_FROM" HEAD 2>/dev/null
}

# Update Homebrew packages
update_tools() {
    print_header "Homebrew Packages"

    if ! command_exists brew; then
        print_skip "Homebrew not installed"
        return 0
    fi

    local brewfile="$REPO_DIR/Brewfile"

    if $CHECK_ONLY; then
        print_status "Checking for outdated packages..."
        local installed outdated formula version
        installed="$(installed_formulae)"
        outdated="$(outdated_brewfile_formulae "$brewfile")"
        for formula in $(brewfile_formulae "$brewfile"); do
            version="$(formula_version "$installed" "$formula")"
            if [[ -z "$version" ]]; then
                print_check "$formula not installed"
            elif grep -qxF "$formula" <<< "$outdated"; then
                print_check "$formula is outdated (current: $version)"
            else
                print_info "$formula is up to date"
            fi
        done
        return 0
    fi

    print_status "Updating Homebrew..."
    brew update --quiet || print_warning "brew update failed: upgrading with the current formulae"

    # Missing packages count too, such as ones added to the Brewfile on another Mac
    local pending
    pending="$( { missing_brewfile_formulae "$brewfile"; outdated_brewfile_formulae "$brewfile"; } | paste -sd ' ' -)"
    if [[ -z "$pending" ]]; then
        print_skip "Brewfile packages already up to date"
        return 0
    fi

    print_status "Upgrading from the Brewfile: $pending"
    if brew bundle install --file="$brewfile" --upgrade; then
        print_updated "Brewfile packages updated: $pending"
    else
        print_fail "brew bundle failed: run 'brew bundle install --file=$brewfile' to see why"
    fi
}

outdated_brewfile_formulae() {
    local outdated
    outdated="$(brew outdated --formula --quiet 2>/dev/null)" || true
    brewfile_formulae "$1" | grep -xF -f <(printf '%s\n' "$outdated") || true
}

# Update configuration files with the same steps install.sh runs
update_config() {
    install_swiftformat_config
    install_claude_config
    install_claude_agents
    install_claude_skills
    install_claude_settings
    install_custom_scripts
    install_xcode_templates
    install_xcode_themes
    install_xcode_header
}

# Update Nerd Font
update_font() {
    print_header "Nerd Font"

    if nerd_font_cask_installed; then
        if ! brew outdated --cask --quiet 2>/dev/null | grep -qxF "$NERD_FONT_CASK"; then
            print_skip "JetBrains Mono Nerd Font already up to date"
        elif $CHECK_ONLY; then
            print_check "JetBrains Mono Nerd Font is outdated"
        elif brew upgrade --cask "$NERD_FONT_CASK"; then
            print_updated "JetBrains Mono Nerd Font upgraded"
        else
            print_fail "Could not upgrade the $NERD_FONT_CASK cask"
        fi
        return 0
    fi

    if [[ -z "$(nerd_font_files)" ]]; then
        install_nerd_font
        return
    fi

    print_skip "JetBrains Mono Nerd Font installed by hand, so Homebrew can't upgrade it"
    print_info "To switch: delete its files from ~/Library/Fonts and run ./install.sh --only-font"
}

print_summary() {
    echo ""
    if $CHECK_ONLY; then
        print_title "Check Complete"
    else
        print_title "Update Summary"
        echo -e "  ${GREEN}↑ Updated:${NC} $UPDATED"
        echo -e "  ${YELLOW}− Skipped:${NC} $SKIPPED"
        echo -e "  ${RED}✗ Failed:${NC}  $FAILED"
        print_rule
    fi
    echo ""

    if $CHECK_ONLY; then
        echo -e "${CYAN}Run without --check to apply updates${NC}"
    elif [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}Update completed successfully!${NC}"
    else
        echo -e "${YELLOW}Update completed with $FAILED failure(s)${NC}"
    fi
}

# Main execution
if ! is_restarted_run; then
    print_banner "🔄 Configuration Update Script"
fi

DRY_RUN=$CHECK_ONLY

if $CHECK_ONLY; then
    echo -e "${CYAN}Running in check mode - no changes will be made${NC}\n"
fi

if $UPDATE_ALL || $UPDATE_REPO; then
    if is_restarted_run; then
        cd "$SCRIPT_DIR" || exit 1
        print_updated "Repository updated from $(git rev-parse --short "$RESTARTED_FROM") to $(git rev-parse --short HEAD), running its update.sh"
    else
        update_repo
        restart_if_repo_changed
    fi
fi

if $UPDATE_ALL || $UPDATE_TOOLS; then
    update_tools
fi

if $UPDATE_ALL || $UPDATE_CONFIG; then
    update_config
fi

if $UPDATE_ALL || $UPDATE_FONT; then
    update_font
fi

print_summary

if [[ $FAILED -gt 0 ]]; then
    exit 1
fi
