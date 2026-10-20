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

# Configuration
NERD_FONT_VERSION="v3.4.0"

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

# Counters
UPDATED=0
SKIPPED=0
FAILED=0

print_success() { echo -e "${GREEN}[✓]${NC} $1"; UPDATED=$((UPDATED + 1)); }
print_skip() { echo -e "${YELLOW}[−]${NC} $1"; SKIPPED=$((SKIPPED + 1)); }
print_fail() { echo -e "${RED}[✗]${NC} $1"; FAILED=$((FAILED + 1)); }
print_check() { echo -e "${CYAN}[CHECK]${NC} $1"; }

report_unchanged() { SKIPPED=$((SKIPPED + 1)); }
report_changed() { print_success "$1"; }
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
            print_success "Repository updated"
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

    local packages=("eza" "swiftformat")

    if $CHECK_ONLY; then
        print_status "Checking for outdated packages..."
        local outdated
        outdated=$(brew outdated 2>/dev/null) || true
        for pkg in "${packages[@]}"; do
            if echo "$outdated" | grep -q "^$pkg"; then
                local current
                current=$(brew list --versions "$pkg" 2>/dev/null | awk '{print $2}') || true
                print_check "$pkg is outdated (current: $current)"
            elif command_exists "$pkg"; then
                print_info "$pkg is up to date"
            fi
        done
        return 0
    fi

    print_status "Updating Homebrew..."
    brew update --quiet

    for pkg in "${packages[@]}"; do
        if command_exists "$pkg"; then
            if brew outdated | grep -q "^$pkg"; then
                print_status "Upgrading $pkg..."
                if brew upgrade "$pkg" 2>/dev/null; then
                    print_success "Updated $pkg"
                else
                    print_fail "Failed to update $pkg"
                fi
            else
                print_skip "$pkg already up to date"
            fi
        else
            print_info "$pkg not installed, skipping"
        fi
    done
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

    local font_dir="$HOME/Library/Fonts"

    # Check if font is installed
    if ! ls "$font_dir"/JetBrainsMonoNerdFont*.ttf &>/dev/null && \
       ! ls "$font_dir"/JetBrainsMonoNFM*.ttf &>/dev/null; then
        if $CHECK_ONLY; then
            print_check "JetBrains Mono Nerd Font not installed"
        else
            print_info "Font not installed, run install.sh to install"
        fi
        return 0
    fi

    if $CHECK_ONLY; then
        print_info "JetBrains Mono Nerd Font installed (version check requires reinstall)"
        print_info "Latest version in config: $NERD_FONT_VERSION"
        return 0
    fi

    print_info "Font reinstall not implemented (fonts don't have easy version detection)"
    print_info "To update: delete fonts from $font_dir and run install.sh"
    print_skip "Font update skipped"
}

print_summary() {
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if $CHECK_ONLY; then
        echo -e "${WHITE}Check Complete${NC}"
    else
        echo -e "${WHITE}Update Summary${NC}"
    fi
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if ! $CHECK_ONLY; then
        echo -e "  ${GREEN}✓ Updated:${NC} $UPDATED"
        echo -e "  ${YELLOW}− Skipped:${NC} $SKIPPED"
        echo -e "  ${RED}✗ Failed:${NC}  $FAILED"
    fi

    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
    echo -e "${WHITE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║          🔄 Configuration Update Script            ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
fi

DRY_RUN=$CHECK_ONLY

if $CHECK_ONLY; then
    echo -e "${CYAN}Running in check mode - no changes will be made${NC}\n"
fi

if $UPDATE_ALL || $UPDATE_REPO; then
    if is_restarted_run; then
        cd "$SCRIPT_DIR" || exit 1
        print_success "Repository updated from $(git rev-parse --short "$RESTARTED_FROM") to $(git rev-parse --short HEAD), running its update.sh"
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
