#!/bin/bash

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="$XC_DIR/UserData"

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
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            print_info "Adding Homebrew to PATH for Apple Silicon"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        print_success "Homebrew installed successfully"
    else
        print_success "Homebrew already installed"
    fi
}

# Function to install eza if not present
install_eza() {
    print_header "eza Installation"
    if ! command_exists eza; then
        print_status "Installing eza (modern ls replacement)..."
        brew install eza
        print_success "eza installed successfully"
    else
        print_success "eza already installed"
    fi
}

# Function to install SwiftFormat if not present
install_swiftformat() {
    print_header "SwiftFormat Installation"
    if ! command_exists swiftformat; then
        print_status "Installing SwiftFormat (Swift code formatter)..."
        brew install swiftformat
        print_success "SwiftFormat installed successfully"
    else
        print_success "SwiftFormat already installed"
    fi
}

# Function to install SwiftFormat configuration
install_swiftformat_config() {
    print_header "SwiftFormat Configuration"
    print_status "Installing SwiftFormat configuration..."
    cp scripts/.swiftformat ~/.swiftformat
    print_success "SwiftFormat configuration installed to ~/.swiftformat"
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
        print_status "Adding aliases to .zshrc"
        echo "$aliases_section" >> "$zshrc_file"
        print_success "Aliases added successfully"
    fi
}

# Function to install custom scripts
install_custom_scripts() {
    print_header "Custom Scripts Installation"
    local bin_dir="$HOME/Developer/bin"
    print_status "Installing custom scripts to $bin_dir"
    mkdir -p "$bin_dir"
    cp scripts/deeplink.sh "$bin_dir/"
    chmod +x "$bin_dir/deeplink.sh"
    print_success "Custom scripts installed successfully"
}

# Main installation process
print_banner
print_info "Starting installation process..."

# Check and install Homebrew
install_homebrew

# Check and install eza
install_eza

# Check and install SwiftFormat
install_swiftformat

# Install SwiftFormat configuration
install_swiftformat_config

# Install custom scripts
install_custom_scripts

# Add aliases to .zshrc
print_header "Shell Configuration"
add_aliases_to_zshrc

# XCode templates
print_header "Xcode Templates Installation"
print_status "Installing Xcode templates..."
XC_TEMPLATES_DIR="$XC_DIR/Templates"
mkdir -p $XC_TEMPLATES_DIR
cp -r Templates/ $XC_TEMPLATES_DIR
print_success "Xcode templates installed successfully"

# Xcode themes
print_header "Xcode Themes Installation"
print_status "Installing Xcode color themes..."
THEMES_DIR="$XC_USER_DATA/FontAndColorThemes/"
mkdir -p $THEMES_DIR
cp Themes/*.xccolortheme $THEMES_DIR
print_success "Xcode themes installed successfully"

# Xcode Header
print_header "Xcode Header Template"
print_status "Installing header template..."
cp ./Headers/IDETemplateMacros.plist "$XC_USER_DATA"
print_success "Xcode header template installed successfully"

# Final success message
print_header "Installation Complete!"
print_success "All components installed successfully!"

echo -e "\n${GREEN}🎉 Your development environment is ready! 🎉${NC}"
echo -e "\n${CYAN}📋 What was installed:${NC}"
echo -e "  ${GREEN}✓${NC} Homebrew package manager"
echo -e "  ${GREEN}✓${NC} eza (modern ls replacement)"
echo -e "  ${GREEN}✓${NC} SwiftFormat with custom configuration"
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