#!/bin/bash

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="$XC_DIR/UserData"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Homebrew if not present
install_homebrew() {
    if ! command_exists brew; then
        echo "[*] Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        echo "[*] Homebrew installed successfully"
    else
        echo "[*] Homebrew already installed"
    fi
}

# Function to install eza if not present
install_eza() {
    if ! command_exists eza; then
        echo "[*] Installing eza..."
        brew install eza
        echo "[*] eza installed successfully"
    else
        echo "[*] eza already installed"
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
        echo "[*] Aliases already exist in .zshrc"
    else
        echo "[*] Adding aliases to .zshrc"
        echo "$aliases_section" >> "$zshrc_file"
        echo "[*] Aliases added successfully"
    fi
}

# Function to install custom scripts
install_custom_scripts() {
    local bin_dir="$HOME/Developer/bin"
    echo "[*] Installing custom scripts"
    mkdir -p "$bin_dir"
    cp scripts/deeplink.sh "$bin_dir/"
    chmod +x "$bin_dir/deeplink.sh"
    echo "[*] Custom scripts installed successfully"
}

# Main installation process
echo "[*] Starting installation process..."

# Check and install Homebrew
install_homebrew

# Check and install eza
install_eza

# Install custom scripts
install_custom_scripts

# Add aliases to .zshrc
add_aliases_to_zshrc

# XCode templates
echo "[*] Installing XCode templates"
XC_TEMPLATES_DIR="$XC_DIR/Templates"
mkdir -p $XC_TEMPLATES_DIR
cp -r Templates/ $XC_TEMPLATES_DIR
echo "[*] XCode templates installed successfully"

# Xcode themes
echo "[*] Installing XCode themes"
THEMES_DIR="$XC_USER_DATA/FontAndColorThemes/"
mkdir -p $THEMES_DIR
cp Themes/*.xccolortheme $THEMES_DIR
echo "[*] XCode Themes installed successfully"

# Xcode Header
echo '[*] Installing header template'
cp ./Headers/IDETemplateMacros.plist "$XC_USER_DATA"
echo "[*] XCode header template installed successfully"

echo "[*] Installation completed successfully!"
echo "[*] Please restart your terminal or run 'source ~/.zshrc' to use the new aliases"