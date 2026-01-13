#!/bin/bash

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="$XC_DIR/UserData"

# Dry run mode (default: false)
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run, -n    Preview what would be installed without making changes"
            echo "  --help, -h       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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
print_info "Starting installation process..."

# Check and install Homebrew
install_homebrew

# Check and install eza
install_eza

# Check and install SwiftFormat
install_swiftformat

# Check and install JetBrains Mono Nerd Font
install_jetbrains_mono_nerd_font

# Install SwiftFormat configuration
install_swiftformat_config

# Install custom scripts
install_custom_scripts

# Add aliases to .zshrc
print_header "Shell Configuration"
add_aliases_to_zshrc

# XCode templates
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

# Xcode themes
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

# Xcode Header
print_header "Xcode Header Template"
if $DRY_RUN; then
    print_dry_run "Copy Headers/IDETemplateMacros.plist to $XC_USER_DATA"
else
    print_status "Installing header template..."
    cp ./Headers/IDETemplateMacros.plist "$XC_USER_DATA"
    print_success "Xcode header template installed successfully"
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