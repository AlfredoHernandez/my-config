#!/bin/bash
set -uo pipefail

# Error handler
trap 'echo "Error: Command failed at line $LINENO. Exit code: $?" >&2' ERR

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="$XC_DIR/UserData"

# Configuration
NERD_FONT_VERSION="v3.4.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Flags
CHECK_ONLY=false
DRY_RUN=false
UPDATE_ALL=true
UPDATE_REPO=false
UPDATE_TOOLS=false
UPDATE_CONFIG=false
UPDATE_FONT=false

# Counters
UPDATED=0
SKIPPED=0
FAILED=0

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; UPDATED=$((UPDATED + 1)); }
print_skip() { echo -e "${YELLOW}[−]${NC} $1"; SKIPPED=$((SKIPPED + 1)); }
print_fail() { echo -e "${RED}[✗]${NC} $1"; FAILED=$((FAILED + 1)); }
print_info() { echo -e "${CYAN}[i]${NC} $1"; }
print_header() { echo -e "\n${WHITE}=== $1 ===${NC}"; }
print_check() { echo -e "${CYAN}[CHECK]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

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

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
source "$REPO_DIR/lib/claude-settings.sh"
source "$REPO_DIR/lib/retired-entries.sh"
source "$REPO_DIR/lib/config-install.sh"

# Update repository
update_repo() {
    print_header "Repository Update"
    cd "$SCRIPT_DIR"

    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    if [[ "$current_branch" != "main" ]]; then
        print_skip "Repository is on '$current_branch', not main: skipping pull"
        return 0
    fi

    local current_commit=$(git rev-parse HEAD)

    if $CHECK_ONLY; then
        git fetch origin main --quiet 2>/dev/null || true
        local behind=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo "0")
        if [[ "$behind" -gt 0 ]]; then
            print_check "Repository is $behind commit(s) behind origin/main"
        else
            print_info "Repository is up to date"
        fi
        return 0
    fi

    print_status "Pulling latest changes..."
    if git pull --ff-only origin main; then
        local new_commit=$(git rev-parse HEAD)
        if [[ "$current_commit" != "$new_commit" ]]; then
            print_success "Repository updated"
        else
            print_skip "Repository already up to date"
        fi
    else
        print_fail "Failed to update repository"
    fi
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
        local outdated=$(brew outdated 2>/dev/null)
        for pkg in "${packages[@]}"; do
            if echo "$outdated" | grep -q "^$pkg"; then
                local current=$(brew list --versions "$pkg" 2>/dev/null | awk '{print $2}')
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
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.zip"

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
echo -e "${WHITE}"
echo "╔════════════════════════════════════════════════════╗"
echo "║          🔄 Configuration Update Script            ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

DRY_RUN=$CHECK_ONLY

if $CHECK_ONLY; then
    echo -e "${CYAN}Running in check mode - no changes will be made${NC}\n"
fi

if $UPDATE_ALL || $UPDATE_REPO; then
    update_repo
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
