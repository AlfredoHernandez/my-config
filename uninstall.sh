#!/bin/bash
set -uo pipefail

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="$XC_DIR/UserData"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

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

# Counters
REMOVED=0
SKIPPED=0
FAILED=0

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; ((REMOVED++)); }
print_skip() { echo -e "${YELLOW}[−]${NC} $1"; ((SKIPPED++)); }
print_fail() { echo -e "${RED}[✗]${NC} $1"; ((FAILED++)); }
print_info() { echo -e "${CYAN}[i]${NC} $1"; }
print_header() { echo -e "\n${WHITE}=== $1 ===${NC}"; }
print_dry_run() { echo -e "${YELLOW}[DRY-RUN]${NC} Would remove: $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

show_help() {
    echo "Usage: ./uninstall.sh [OPTIONS]"
    echo ""
    echo "Remove installed components from your system."
    echo ""
    echo "Options:"
    echo "  --dry-run, -n       Preview what would be removed"
    echo "  --force, -f         Skip confirmation prompts"
    echo "  --tools             Remove Homebrew packages (eza, swiftformat)"
    echo "  --font              Remove JetBrains Mono Nerd Font"
    echo "  --config            Remove SwiftFormat configuration"
    echo "  --aliases           Remove shell aliases from .zshrc"
    echo "  --scripts           Remove custom scripts"
    echo "  --xcode             Remove Xcode themes, templates, headers"
    echo "  --claude            Remove Claude configuration and agents"
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

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Remove Homebrew packages
remove_tools() {
    print_header "Homebrew Packages"

    if ! command_exists brew; then
        print_skip "Homebrew not installed"
        return 0
    fi

    local packages=("eza" "swiftformat")

    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            if $DRY_RUN; then
                print_dry_run "$pkg (brew uninstall)"
            else
                print_status "Removing $pkg..."
                if brew uninstall "$pkg" 2>/dev/null; then
                    print_success "Removed $pkg"
                else
                    print_fail "Failed to remove $pkg"
                fi
            fi
        else
            print_skip "$pkg not installed"
        fi
    done
}

# Remove JetBrains Mono Nerd Font
remove_font() {
    print_header "JetBrains Mono Nerd Font"

    local font_dir="$HOME/Library/Fonts"
    local fonts_found=false

    # Check for fonts
    if ls "$font_dir"/JetBrainsMonoNerdFont*.ttf &>/dev/null || \
       ls "$font_dir"/JetBrainsMonoNFM*.ttf &>/dev/null; then
        fonts_found=true
    fi

    if ! $fonts_found; then
        print_skip "Font not installed"
        return 0
    fi

    if $DRY_RUN; then
        local count=$(ls "$font_dir"/JetBrainsMonoNerdFont*.ttf "$font_dir"/JetBrainsMonoNFM*.ttf 2>/dev/null | wc -l | xargs)
        print_dry_run "JetBrains Mono Nerd Font ($count files)"
    else
        print_status "Removing font files..."
        rm -f "$font_dir"/JetBrainsMonoNerdFont*.ttf 2>/dev/null
        rm -f "$font_dir"/JetBrainsMonoNFM*.ttf 2>/dev/null
        print_success "Removed JetBrains Mono Nerd Font"
    fi
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

# Remove aliases from .zshrc
remove_aliases() {
    print_header "Shell Aliases"

    local zshrc_file="$HOME/.zshrc"

    if [[ ! -f "$zshrc_file" ]]; then
        print_skip ".zshrc not found"
        return 0
    fi

    if ! grep -q "# Git aliases" "$zshrc_file" 2>/dev/null; then
        print_skip "Aliases section not found in .zshrc"
        return 0
    fi

    if $DRY_RUN; then
        print_dry_run "Aliases section from .zshrc"
    else
        print_status "Removing aliases from .zshrc..."
        # Create backup
        cp "$zshrc_file" "$zshrc_file.backup"

        # Remove aliases section (from "# Git aliases" to "alias dl=...")
        sed -i '' '/^# Git aliases/,/^alias dl=/d' "$zshrc_file"

        print_success "Removed aliases (backup: .zshrc.backup)"
    fi
}

# Remove custom scripts
remove_scripts() {
    print_header "Custom Scripts"

    local bin_dir="$HOME/Developer/bin"
    local script_file="$bin_dir/deeplink.sh"

    if [[ -f "$script_file" ]]; then
        if $DRY_RUN; then
            print_dry_run "$script_file"
        else
            rm -f "$script_file"
            print_success "Removed deeplink.sh"
        fi
    else
        print_skip "deeplink.sh not found"
    fi

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

    # Themes
    local themes_dir="$XC_USER_DATA/FontAndColorThemes"
    if [[ -d "$themes_dir" ]] && ls "$themes_dir"/*.xccolortheme &>/dev/null; then
        if $DRY_RUN; then
            local count=$(ls "$themes_dir"/*.xccolortheme 2>/dev/null | wc -l | xargs)
            print_dry_run "Xcode themes ($count files)"
        else
            rm -f "$themes_dir"/*.xccolortheme
            print_success "Removed Xcode themes"
        fi
    else
        print_skip "No Xcode themes found"
    fi

    # Templates
    local templates_dir="$XC_DIR/Templates"
    if [[ -d "$templates_dir" ]] && [[ -n "$(ls -A "$templates_dir" 2>/dev/null)" ]]; then
        if $DRY_RUN; then
            print_dry_run "$templates_dir"
        else
            rm -rf "$templates_dir"
            print_success "Removed Xcode templates"
        fi
    else
        print_skip "No Xcode templates found"
    fi

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

    # Agents
    local agents_dir="$claude_dir/agents"
    if [[ -d "$agents_dir" ]] && [[ -n "$(ls -A "$agents_dir" 2>/dev/null)" ]]; then
        if $DRY_RUN; then
            local count=$(ls "$agents_dir"/*.md 2>/dev/null | wc -l | xargs)
            print_dry_run "Claude agents ($count files)"
        else
            rm -rf "$agents_dir"
            print_success "Removed Claude agents"
        fi
    else
        print_skip "No Claude agents found"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if $DRY_RUN; then
        echo -e "${WHITE}Dry Run Complete${NC}"
    else
        echo -e "${WHITE}Uninstall Summary${NC}"
    fi
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if ! $DRY_RUN; then
        echo -e "  ${GREEN}✓ Removed:${NC} $REMOVED"
        echo -e "  ${YELLOW}− Skipped:${NC} $SKIPPED"
        echo -e "  ${RED}✗ Failed:${NC}  $FAILED"
    fi

    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
echo -e "${WHITE}"
echo "╔════════════════════════════════════════════════════╗"
echo "║          🗑️  Configuration Uninstall Script         ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"

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

if ! $DRY_RUN && [[ $REMOVED -gt 0 ]]; then
    echo -e "\n${YELLOW}Note:${NC} Restart your terminal for alias changes to take effect."
fi
