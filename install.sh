#!/bin/bash

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="$XC_DIR/UserData"

# Installation flags (default: install everything)
DRY_RUN=false
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
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"

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
    if $DRY_RUN; then
        print_dry_run "Copy scripts/.swiftformat to ~/.swiftformat"
    else
        print_status "Installing SwiftFormat configuration..."
        cp scripts/.swiftformat ~/.swiftformat
        print_success "SwiftFormat configuration installed to ~/.swiftformat"
    fi
}

# Function to add aliases to .zshrc
add_aliases_to_zshrc() {
    local zshrc_file="$HOME/.zshrc"
    local aliases_section="
# Git aliases
alias gl='git pull'
alias gd='git diff'
alias gp='git push'
alias gst='git status'
alias ga='git add .'
alias gc='git commit'
alias gca='git commit --amend --no-edit'
alias glog='git log'
alias gcp='git cherry-pick'
alias cleanup='git branch --merged | grep -Ev \"(^\*|master|main|develop)\" | xargs git branch -d'
alias grh='git reset --soft HEAD~1'

# Xcode aliases
alias spm='xcodebuild -resolvePackageDependencies -scmProvider system'

# ls improvements with eza
alias ls='eza --grid --color auto --icons --sort=type'
alias ll='eza --long --color always --icons --sort=type'
alias la='eza --grid --all --color auto --icons --sort=type'
alias lla='eza --long --all --color auto --icons --sort=type'

# Custom scripts
alias dl=\"~/Developer/bin/deeplink.sh\"
"

    # Check if aliases section already exists
    if grep -q "# Git aliases" "$zshrc_file" 2>/dev/null; then
        print_success "Aliases already exist in .zshrc"
    else
        if $DRY_RUN; then
            print_dry_run "Add shell aliases to $zshrc_file"
        else
            print_status "Adding aliases to .zshrc"
            echo "$aliases_section" >> "$zshrc_file"
            print_success "Aliases added successfully"
        fi
    fi
}

# Function to install Claude Code configuration
install_claude_config() {
    print_header "Claude Code Configuration"
    local claude_dir="$HOME/.claude"

    if $DRY_RUN; then
        print_dry_run "Create directory $claude_dir"
        print_dry_run "Copy claude/CLAUDE.md to $claude_dir/CLAUDE.md"
    else
        print_status "Installing Claude Code configuration..."
        mkdir -p "$claude_dir"
        cp claude/CLAUDE.md "$claude_dir/CLAUDE.md"
        print_success "Claude Code configuration installed to $claude_dir/CLAUDE.md"
    fi
}

# Function to install Claude agents
install_claude_agents() {
    print_header "Claude Agents Installation"
    local agents_src="claude/agents"
    local agents_dest="$HOME/.claude/agents"

    if [[ ! -d "$agents_src" ]]; then
        print_warning "No agents directory found in $agents_src, skipping..."
        return 0
    fi

    if $DRY_RUN; then
        print_dry_run "Create directory $agents_dest"
        print_dry_run "Copy $agents_src/ to $agents_dest/"
    else
        print_status "Installing Claude agents..."
        mkdir -p "$agents_dest"
        cp -r "$agents_src"/* "$agents_dest/" 2>/dev/null || {
            print_warning "No agents found to install"
            return 0
        }
        print_success "Claude agents installed to $agents_dest"
    fi
}

# Function to install custom scripts
install_custom_scripts() {
    print_header "Custom Scripts Installation"
    local bin_dir="$HOME/Developer/bin"
    if $DRY_RUN; then
        print_dry_run "Create directory $bin_dir"
        print_dry_run "Copy scripts/deeplink.sh to $bin_dir/"
    else
        print_status "Installing custom scripts to $bin_dir"
        mkdir -p "$bin_dir"
        cp scripts/deeplink.sh "$bin_dir/"
        chmod +x "$bin_dir/deeplink.sh"
        print_success "Custom scripts installed successfully"
    fi
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
    XC_TEMPLATES_DIR="$XC_DIR/Templates"
    if $DRY_RUN; then
        print_dry_run "Create directory $XC_TEMPLATES_DIR"
        print_dry_run "Copy Templates/ to $XC_TEMPLATES_DIR"
    else
        print_status "Installing Xcode templates..."
        mkdir -p $XC_TEMPLATES_DIR
        cp -r Templates/ $XC_TEMPLATES_DIR
        print_success "Xcode templates installed successfully"
    fi
fi

# Xcode themes
if should_install "themes" "$INSTALL_THEMES" "$SKIP_THEMES"; then
    print_header "Xcode Themes Installation"
    THEMES_DIR="$XC_USER_DATA/FontAndColorThemes/"
    if $DRY_RUN; then
        print_dry_run "Create directory $THEMES_DIR"
        print_dry_run "Copy Themes/*.xccolortheme to $THEMES_DIR"
    else
        print_status "Installing Xcode color themes..."
        mkdir -p $THEMES_DIR
        cp Themes/*.xccolortheme $THEMES_DIR
        print_success "Xcode themes installed successfully"
    fi
fi

# Xcode Header
if should_install "header" "$INSTALL_HEADER" "$SKIP_HEADER"; then
    print_header "Xcode Header Template"
    if $DRY_RUN; then
        print_dry_run "Copy Headers/IDETemplateMacros.plist to $XC_USER_DATA"
    else
        print_status "Installing header template..."
        cp ./Headers/IDETemplateMacros.plist "$XC_USER_DATA"
        print_success "Xcode header template installed successfully"
    fi
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
fi