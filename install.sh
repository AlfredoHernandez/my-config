#!/bin/bash
set -euo pipefail

# Error handler - shows where the error occurred
trap 'echo "Error: Command failed at line $LINENO. Exit code: $?" >&2' ERR

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="$XC_DIR/UserData"

# Configuration
NERD_FONT_VERSION="v3.4.0"

# Installation flags (default: install everything)
DRY_RUN=false
VALIDATE_ONLY=false
INSTALL_ALL=true
INSTALL_HOMEBREW=false
INSTALL_TOOLS=false
INSTALL_FONT=false
INSTALL_SWIFTFORMAT_CONFIG=false
INSTALL_ALIASES=false
INSTALL_SCRIPTS=false
INSTALL_XCODE=false
INSTALL_THEMES=false
INSTALL_TEMPLATES=false
INSTALL_HEADER=false
INSTALL_CLAUDE=false

# Skip flags
SKIP_HOMEBREW=false
SKIP_TOOLS=false
SKIP_FONT=false
SKIP_SWIFTFORMAT_CONFIG=false
SKIP_ALIASES=false
SKIP_SCRIPTS=false
SKIP_XCODE=false
SKIP_THEMES=false
SKIP_TEMPLATES=false
SKIP_HEADER=false
SKIP_CLAUDE=false

# Function to show help
show_help() {
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "By default, installs all components. Use flags to customize installation."
    echo ""
    echo "General Options:"
    echo "  --dry-run, -n              Preview what would be installed without making changes"
    echo "  --validate, -v             Check system prerequisites before installing"
    echo "  --help, -h                 Show this help message"
    echo "  --list                     List all available components"
    echo ""
    echo "Install Specific Components (only installs selected components):"
    echo "  --only-homebrew            Install only Homebrew package manager"
    echo "  --only-tools               Install only development tools (eza, SwiftFormat)"
    echo "  --only-font                Install only JetBrains Mono Nerd Font"
    echo "  --only-swiftformat-config  Install only SwiftFormat configuration"
    echo "  --only-aliases             Install only shell aliases"
    echo "  --only-scripts             Install only custom scripts"
    echo "  --only-xcode               Install all Xcode components (themes, templates, headers)"
    echo "  --only-themes              Install only Xcode color themes"
    echo "  --only-templates           Install only Xcode templates"
    echo "  --only-header              Install only Xcode header template"
    echo "  --only-claude              Install only Claude Code configuration and agents"
    echo ""
    echo "Skip Specific Components (installs everything except specified):"
    echo "  --skip-homebrew            Skip Homebrew installation"
    echo "  --skip-tools               Skip development tools installation"
    echo "  --skip-font                Skip font installation"
    echo "  --skip-swiftformat-config  Skip SwiftFormat configuration"
    echo "  --skip-aliases             Skip shell aliases"
    echo "  --skip-scripts             Skip custom scripts"
    echo "  --skip-xcode               Skip all Xcode components"
    echo "  --skip-themes              Skip Xcode themes"
    echo "  --skip-templates           Skip Xcode templates"
    echo "  --skip-header              Skip Xcode header template"
    echo "  --skip-claude              Skip Claude Code configuration"
    echo ""
    echo "Examples:"
    echo "  ./install.sh                           # Install everything"
    echo "  ./install.sh --only-themes             # Install only Xcode themes"
    echo "  ./install.sh --only-tools --only-font  # Install only tools and font"
    echo "  ./install.sh --skip-xcode              # Install everything except Xcode components"
    echo "  ./install.sh --dry-run --only-themes   # Preview theme installation"
    echo ""
}

# Function to list components
list_components() {
    echo "Available Components:"
    echo ""
    echo "Development Tools:"
    echo "  • homebrew             - Homebrew package manager"
    echo "  • tools                - eza (modern ls) and SwiftFormat"
    echo "  • font                 - JetBrains Mono Nerd Font"
    echo "  • swiftformat-config   - SwiftFormat configuration file"
    echo ""
    echo "Shell Configuration:"
    echo "  • aliases              - Git, Xcode, and custom aliases"
    echo "  • scripts              - Custom development scripts"
    echo ""
    echo "Xcode Configuration:"
    echo "  • xcode                - All Xcode components (themes, templates, headers)"
    echo "  • themes               - Color themes"
    echo "  • templates            - File templates"
    echo "  • header               - Header template"
    echo ""
    echo "Claude Code:"
    echo "  • claude               - Configuration and custom agents"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        --list)
            list_components
            exit 0
            ;;
        --validate|-v)
            VALIDATE_ONLY=true
            shift
            ;;
        # Only flags
        --only-homebrew)
            INSTALL_ALL=false
            INSTALL_HOMEBREW=true
            shift
            ;;
        --only-tools)
            INSTALL_ALL=false
            INSTALL_TOOLS=true
            shift
            ;;
        --only-font)
            INSTALL_ALL=false
            INSTALL_FONT=true
            shift
            ;;
        --only-swiftformat-config)
            INSTALL_ALL=false
            INSTALL_SWIFTFORMAT_CONFIG=true
            shift
            ;;
        --only-aliases)
            INSTALL_ALL=false
            INSTALL_ALIASES=true
            shift
            ;;
        --only-scripts)
            INSTALL_ALL=false
            INSTALL_SCRIPTS=true
            shift
            ;;
        --only-xcode)
            INSTALL_ALL=false
            INSTALL_XCODE=true
            INSTALL_THEMES=true
            INSTALL_TEMPLATES=true
            INSTALL_HEADER=true
            shift
            ;;
        --only-themes)
            INSTALL_ALL=false
            INSTALL_THEMES=true
            shift
            ;;
        --only-templates)
            INSTALL_ALL=false
            INSTALL_TEMPLATES=true
            shift
            ;;
        --only-header)
            INSTALL_ALL=false
            INSTALL_HEADER=true
            shift
            ;;
        --only-claude)
            INSTALL_ALL=false
            INSTALL_CLAUDE=true
            shift
            ;;
        # Skip flags
        --skip-homebrew)
            SKIP_HOMEBREW=true
            shift
            ;;
        --skip-tools)
            SKIP_TOOLS=true
            shift
            ;;
        --skip-font)
            SKIP_FONT=true
            shift
            ;;
        --skip-swiftformat-config)
            SKIP_SWIFTFORMAT_CONFIG=true
            shift
            ;;
        --skip-aliases)
            SKIP_ALIASES=true
            shift
            ;;
        --skip-scripts)
            SKIP_SCRIPTS=true
            shift
            ;;
        --skip-xcode)
            SKIP_XCODE=true
            SKIP_THEMES=true
            SKIP_TEMPLATES=true
            SKIP_HEADER=true
            shift
            ;;
        --skip-themes)
            SKIP_THEMES=true
            shift
            ;;
        --skip-templates)
            SKIP_TEMPLATES=true
            shift
            ;;
        --skip-header)
            SKIP_HEADER=true
            shift
            ;;
        --skip-claude)
            SKIP_CLAUDE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Helper function to check if component should be installed
should_install() {
    local component=$1
    local install_flag=$2
    local skip_flag=$3
    
    # If skip flag is set, don't install
    if [ "$skip_flag" = true ]; then
        return 1
    fi
    
    # If install all is true and not skipped, install
    if [ "$INSTALL_ALL" = true ]; then
        return 0
    fi
    
    # Otherwise, check if specific component is requested
    if [ "$install_flag" = true ]; then
        return 0
    fi
    
    return 1
}

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[i]${NC} $1"
}

print_header() {
    echo -e "\n${WHITE}=== $1 ===${NC}"
}

print_dry_run() {
    echo -e "${YELLOW}[DRY-RUN]${NC} Would: $1"
}

print_pass() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_fail() {
    echo -e "${RED}[✗]${NC} $1"
}

print_updated() {
    echo -e "${GREEN}[↑]${NC} $1"
}

# Helper: install or update a single file
install_or_update_file() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [[ ! -f "$src" ]]; then
        print_warning "$label source not found: $src"
        return 1
    fi

    if [[ -f "$dest" ]]; then
        if diff -q "$src" "$dest" &>/dev/null; then
            print_success "$label already up to date"
            return 0
        fi
        if $DRY_RUN; then
            print_dry_run "Update $label"
        else
            cp "$src" "$dest"
            print_updated "$label updated"
        fi
    else
        if $DRY_RUN; then
            print_dry_run "Install $label"
        else
            mkdir -p "$(dirname "$dest")"
            cp "$src" "$dest"
            print_success "$label installed"
        fi
    fi
}

# Helper: install or update a directory
install_or_update_dir() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [[ ! -d "$src" ]]; then
        print_warning "$label source not found: $src"
        return 1
    fi

    mkdir -p "$dest"
    for file in "$src"/*; do
        local name
        name="$(basename "$file")"
        if [[ -d "$file" ]]; then
            install_or_update_dir "$file" "$dest/$name" "$label/$name"
        else
            install_or_update_file "$file" "$dest/$name" "$label: $name"
        fi
    done
}

# Validate system prerequisites
validate_prerequisites() {
    echo -e "${WHITE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              🔍 System Prerequisites Check                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    local passed=0
    local failed=0

    # Check macOS
    print_header "Operating System"
    if [[ "$(uname)" == "Darwin" ]]; then
        local macos_version=$(sw_vers -productVersion)
        print_pass "macOS detected (version $macos_version)"
        ((passed++))
    else
        print_fail "macOS required (detected: $(uname))"
        ((failed++))
    fi

    # Check architecture
    local arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        print_pass "Apple Silicon detected"
    else
        print_pass "Intel Mac detected"
    fi
    ((passed++))

    # Check Xcode Command Line Tools
    print_header "Development Tools"
    if xcode-select -p &>/dev/null; then
        print_pass "Xcode Command Line Tools installed"
        ((passed++))
    else
        print_fail "Xcode Command Line Tools not installed"
        print_info "  Install with: xcode-select --install"
        ((failed++))
    fi

    # Check Git
    if command -v git &>/dev/null; then
        local git_version=$(git --version | awk '{print $3}')
        print_pass "Git installed (version $git_version)"
        ((passed++))
    else
        print_fail "Git not installed"
        ((failed++))
    fi

    # Check curl
    if command -v curl &>/dev/null; then
        print_pass "curl installed"
        ((passed++))
    else
        print_fail "curl not installed (required for downloads)"
        ((failed++))
    fi

    # Check network connectivity
    print_header "Network"
    if curl -s --head --connect-timeout 5 https://github.com &>/dev/null; then
        print_pass "Network connectivity OK (github.com reachable)"
        ((passed++))
    else
        print_fail "Cannot reach github.com"
        print_info "  Check your internet connection"
        ((failed++))
    fi

    # Check disk space
    print_header "Disk Space"
    local available_space=$(df -g "$HOME" | awk 'NR==2 {print $4}')
    if [[ "$available_space" -ge 1 ]]; then
        print_pass "Sufficient disk space (${available_space}GB available)"
        ((passed++))
    else
        print_fail "Low disk space (${available_space}GB available, need at least 1GB)"
        ((failed++))
    fi

    # Check write permissions
    print_header "Permissions"
    if [[ -w "$HOME" ]]; then
        print_pass "Home directory writable"
        ((passed++))
    else
        print_fail "Cannot write to home directory"
        ((failed++))
    fi

    if [[ -w "$HOME/Library/Fonts" ]] || mkdir -p "$HOME/Library/Fonts" 2>/dev/null; then
        print_pass "Fonts directory accessible"
        ((passed++))
    else
        print_fail "Cannot access fonts directory"
        ((failed++))
    fi

    # Check shell
    print_header "Shell"
    local current_shell=$(basename "$SHELL")
    if [[ "$current_shell" == "zsh" ]]; then
        print_pass "Using zsh (recommended)"
        ((passed++))
    elif [[ "$current_shell" == "bash" ]]; then
        print_warning "Using bash (zsh recommended for aliases)"
        ((passed++))
    else
        print_info "Using $current_shell"
        ((passed++))
    fi

    # Summary
    echo ""
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}Validation Summary${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}✓ Passed:${NC} $passed"
    echo -e "  ${RED}✗ Failed:${NC} $failed"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}All prerequisites met! Ready to install.${NC}"
        echo -e "${CYAN}Run ./install.sh to begin installation.${NC}"
        return 0
    else
        echo -e "${RED}Some prerequisites are missing.${NC}"
        echo -e "${YELLOW}Please resolve the issues above before installing.${NC}"
        return 1
    fi
}

# Run validation if requested
if $VALIDATE_ONLY; then
    validate_prerequisites
    exit $?
fi

print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║           🚀 My Development Configuration Setup 🚀           ║"
    echo "║                                                              ║"
    echo "║    Setting up your macOS development environment with:       ║"
    echo "║    • Homebrew package manager                               ║"
    echo "║    • eza (modern ls replacement)                            ║"
    echo "║    • SwiftFormat (Swift code formatter)                     ║"
    echo "║    • JetBrains Mono Nerd Font                               ║"
    echo "║    • Claude Code configuration and agents                    ║"
    echo "║    • Custom shell aliases                                   ║"
    echo "║    • Xcode themes and templates                             ║"
    echo "║    • Development scripts                                    ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Homebrew if not present
install_homebrew() {
    print_header "Homebrew Installation"
    if ! command_exists brew; then
        if $DRY_RUN; then
            print_dry_run "Install Homebrew"
            [[ $(uname -m) == "arm64" ]] && print_dry_run "Add Homebrew to PATH for Apple Silicon"
        else
            print_status "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add Homebrew to PATH for Apple Silicon Macs
            if [[ $(uname -m) == "arm64" ]]; then
                print_info "Adding Homebrew to PATH for Apple Silicon"
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            print_success "Homebrew installed successfully"
        fi
    else
        print_success "Homebrew already installed"
    fi
}

# Function to install eza if not present
install_eza() {
    print_header "eza Installation"
    if ! command_exists eza; then
        if $DRY_RUN; then
            print_dry_run "Install eza via Homebrew"
        else
            print_status "Installing eza (modern ls replacement)..."
            brew install eza
            print_success "eza installed successfully"
        fi
    else
        print_success "eza already installed"
    fi
}

# Function to install SwiftFormat if not present
install_swiftformat() {
    print_header "SwiftFormat Installation"
    if ! command_exists swiftformat; then
        if $DRY_RUN; then
            print_dry_run "Install SwiftFormat via Homebrew"
        else
            print_status "Installing SwiftFormat (Swift code formatter)..."
            brew install swiftformat
            print_success "SwiftFormat installed successfully"
        fi
    else
        print_success "SwiftFormat already installed"
    fi
}

# Function to install JetBrains Mono Nerd Font
install_jetbrains_mono_nerd_font() {
    print_header "JetBrains Mono Nerd Font Installation"
    local font_dir="$HOME/Library/Fonts"
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/JetBrainsMono.zip"

    # Check if font is already installed
    if ls "$font_dir"/JetBrainsMonoNerdFont*.ttf &>/dev/null || \
       ls "$font_dir"/JetBrainsMonoNFM*.ttf &>/dev/null || \
       ls /Library/Fonts/JetBrainsMonoNerdFont*.ttf &>/dev/null || \
       ls /Library/Fonts/JetBrainsMonoNFM*.ttf &>/dev/null; then
        print_success "JetBrains Mono Nerd Font already installed"
        return 0
    fi

    if $DRY_RUN; then
        print_dry_run "Download JetBrains Mono Nerd Font from GitHub"
        print_dry_run "Install font files to $font_dir"
        return 0
    fi

    local temp_dir=$(mktemp -d)

    print_status "Downloading JetBrains Mono Nerd Font..."
    curl -fsSL "$font_url" -o "$temp_dir/JetBrainsMono.zip"

    if [[ $? -ne 0 ]]; then
        print_warning "Failed to download JetBrains Mono Nerd Font"
        rm -rf "$temp_dir"
        return 1
    fi

    print_status "Installing font..."
    unzip -q "$temp_dir/JetBrainsMono.zip" -d "$temp_dir/JetBrainsMono"
    mkdir -p "$font_dir"
    cp "$temp_dir/JetBrainsMono"/*.ttf "$font_dir/"

    rm -rf "$temp_dir"
    print_success "JetBrains Mono Nerd Font installed successfully"
}

# Function to install SwiftFormat configuration
install_swiftformat_config() {
    print_header "SwiftFormat Configuration"
    install_or_update_file "config/swiftformat.txt" "$HOME/.swiftformat" "SwiftFormat configuration"
}

# Function to add aliases to .zshrc
add_aliases_to_zshrc() {
    local zshrc_file="$HOME/.zshrc"
    local aliases_src="config/aliases.zsh"
    local source_line="source \"$HOME/.config/aliases.zsh\""

    # Install aliases file
    install_or_update_file "$aliases_src" "$HOME/.config/aliases.zsh" "Aliases file"

    # Add source line to .zshrc if not present
    if grep -q "source.*aliases.zsh" "$zshrc_file" 2>/dev/null; then
        print_success "Aliases already sourced in .zshrc"
    else
        if $DRY_RUN; then
            print_dry_run "Add source line for aliases to $zshrc_file"
        else
            print_status "Adding aliases source to .zshrc"
            echo "" >> "$zshrc_file"
            echo "# My config aliases" >> "$zshrc_file"
            echo "$source_line" >> "$zshrc_file"
            print_success "Aliases source added to .zshrc"
        fi
    fi
}

# Function to install Claude Code configuration
install_claude_config() {
    print_header "Claude Code Configuration"
    install_or_update_file "claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md" "CLAUDE.md"
}

# Function to install Claude Code settings
install_claude_settings() {
    print_header "Claude Code Settings"
    install_or_update_file "claude/settings.json" "$HOME/.claude/settings.json" "Claude settings"
}

# Function to install Claude agents
install_claude_agents() {
    print_header "Claude Agents Installation"
    install_or_update_dir "claude/agents" "$HOME/.claude/agents" "Agent"
}

# Function to install custom scripts
install_custom_scripts() {
    print_header "Custom Scripts Installation"
    local bin_dir="$HOME/Developer/bin"
    mkdir -p "$bin_dir"

    for script in scripts/*.sh; do
        local name
        name="$(basename "$script")"
        install_or_update_file "$script" "$bin_dir/$name" "Script: $name"
        $DRY_RUN || chmod +x "$bin_dir/$name"
    done
}

# Main installation process
print_banner
if $DRY_RUN; then
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                      DRY RUN MODE                            ║${NC}"
    echo -e "${YELLOW}║           No changes will be made to your system             ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
fi

# Show what will be installed
if ! $INSTALL_ALL; then
    print_info "Selective installation mode enabled"
    echo -e "${CYAN}Components to install:${NC}"
    $INSTALL_HOMEBREW && echo "  • Homebrew"
    $INSTALL_TOOLS && echo "  • Development tools (eza, SwiftFormat)"
    $INSTALL_FONT && echo "  • JetBrains Mono Nerd Font"
    $INSTALL_SWIFTFORMAT_CONFIG && echo "  • SwiftFormat configuration"
    $INSTALL_ALIASES && echo "  • Shell aliases"
    $INSTALL_SCRIPTS && echo "  • Custom scripts"
    $INSTALL_CLAUDE && echo "  • Claude Code configuration"
    $INSTALL_THEMES && echo "  • Xcode themes"
    $INSTALL_TEMPLATES && echo "  • Xcode templates"
    $INSTALL_HEADER && echo "  • Xcode header template"
    echo ""
fi

print_info "Starting installation process..."

# Check and install Homebrew
if should_install "homebrew" "$INSTALL_HOMEBREW" "$SKIP_HOMEBREW"; then
    install_homebrew
fi

# Check and install eza
if should_install "tools" "$INSTALL_TOOLS" "$SKIP_TOOLS"; then
    install_eza
fi

# Check and install SwiftFormat
if should_install "tools" "$INSTALL_TOOLS" "$SKIP_TOOLS"; then
    install_swiftformat
fi

# Check and install JetBrains Mono Nerd Font
if should_install "font" "$INSTALL_FONT" "$SKIP_FONT"; then
    install_jetbrains_mono_nerd_font
fi

# Install SwiftFormat configuration
if should_install "swiftformat-config" "$INSTALL_SWIFTFORMAT_CONFIG" "$SKIP_SWIFTFORMAT_CONFIG"; then
    install_swiftformat_config
fi

# Install Claude Code configuration
if should_install "claude" "$INSTALL_CLAUDE" "$SKIP_CLAUDE"; then
    install_claude_config
fi

# Install Claude agents
if should_install "claude" "$INSTALL_CLAUDE" "$SKIP_CLAUDE"; then
    install_claude_agents
fi

# Install Claude Code settings
if should_install "claude" "$INSTALL_CLAUDE" "$SKIP_CLAUDE"; then
    install_claude_settings
fi

# Install custom scripts
if should_install "scripts" "$INSTALL_SCRIPTS" "$SKIP_SCRIPTS"; then
    install_custom_scripts
fi

# Add aliases to .zshrc
if should_install "aliases" "$INSTALL_ALIASES" "$SKIP_ALIASES"; then
    print_header "Shell Configuration"
    add_aliases_to_zshrc
fi

# XCode templates
if should_install "templates" "$INSTALL_TEMPLATES" "$SKIP_TEMPLATES"; then
    print_header "Xcode Templates Installation"
    install_or_update_dir "Templates" "$XC_DIR/Templates" "Template"
fi

# Xcode themes
if should_install "themes" "$INSTALL_THEMES" "$SKIP_THEMES"; then
    print_header "Xcode Themes Installation"
    themes_dest="$XC_USER_DATA/FontAndColorThemes"
    mkdir -p "$themes_dest"
    for theme in Themes/*.xccolortheme; do
        name="$(basename "$theme")"
        install_or_update_file "$theme" "$themes_dest/$name" "Theme: $name"
    done
fi

# Xcode Header
if should_install "header" "$INSTALL_HEADER" "$SKIP_HEADER"; then
    print_header "Xcode Header Template"
    install_or_update_file "Headers/IDETemplateMacros.plist" "$XC_USER_DATA/IDETemplateMacros.plist" "Header template"
fi

# Final message
if $DRY_RUN; then
    print_header "Dry Run Complete!"
    echo -e "\n${YELLOW}🔍 This was a dry run - no changes were made${NC}"
    echo -e "\n${CYAN}📋 What would be installed:${NC}"
    echo -e "  ${YELLOW}○${NC} Homebrew package manager"
    echo -e "  ${YELLOW}○${NC} eza (modern ls replacement)"
    echo -e "  ${YELLOW}○${NC} SwiftFormat with custom configuration"
    echo -e "  ${YELLOW}○${NC} JetBrains Mono Nerd Font"
    echo -e "  ${YELLOW}○${NC} Claude Code configuration and agents"
    echo -e "  ${YELLOW}○${NC} Shell aliases for Git and development"
    echo -e "  ${YELLOW}○${NC} Xcode themes and templates"
    echo -e "  ${YELLOW}○${NC} Custom development scripts"
    echo -e "\n${GREEN}Run without --dry-run to install:${NC} ${WHITE}./install.sh${NC}"
else
    print_header "Installation Complete!"
    print_success "All components installed successfully!"

    echo -e "\n${GREEN}🎉 Your development environment is ready! 🎉${NC}"
    echo -e "\n${CYAN}📋 What was installed:${NC}"
    echo -e "  ${GREEN}✓${NC} Homebrew package manager"
    echo -e "  ${GREEN}✓${NC} eza (modern ls replacement)"
    echo -e "  ${GREEN}✓${NC} SwiftFormat with custom configuration"
    echo -e "  ${GREEN}✓${NC} JetBrains Mono Nerd Font"
    echo -e "  ${GREEN}✓${NC} Claude Code configuration and agents"
    echo -e "  ${GREEN}✓${NC} Shell aliases for Git and development"
    echo -e "  ${GREEN}✓${NC} Xcode themes and templates"
    echo -e "  ${GREEN}✓${NC} Custom development scripts"

    echo -e "\n${YELLOW}📝 Next steps:${NC}"
    echo -e "  1. Restart your terminal or run: ${WHITE}source ~/.zshrc${NC}"
    echo -e "  2. Try the new aliases: ${WHITE}gl${NC}, ${WHITE}gp${NC}, ${WHITE}gst${NC}, ${WHITE}ll${NC}"
    echo -e "  3. Format Swift code: ${WHITE}swiftformat .${NC}"
    echo -e "  4. Test deeplinks: ${WHITE}dl your-app://test${NC}"

    echo -e "\n${PURPLE}💡 Pro tip:${NC} Your SwiftFormat config is at ${WHITE}~/.swiftformat${NC}"
    echo -e "   You can customize it or use it in your projects!"

    echo -e "\n${GREEN}Happy coding! 🚀${NC}"

    # Run post-installation verification
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}Running post-installation verification...${NC}\n"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$SCRIPT_DIR/health-check.sh" ]]; then
        bash "$SCRIPT_DIR/health-check.sh"
    else
        echo -e "${YELLOW}health-check.sh not found, skipping verification${NC}"
    fi
fi