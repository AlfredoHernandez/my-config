#!/bin/bash
# Shared by every script. Helpers that update a counter (print_success, print_fail, ...) stay in
# each script, because each one counts different things; a script may also redefine any helper here.

# shellcheck disable=SC2034  # the colors are used by the scripts that source this file
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

XC_DIR="$HOME/Library/Developer/Xcode"
XC_USER_DATA="$XC_DIR/UserData"

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_info() { echo -e "${CYAN}[i]${NC} $1"; }
print_header() { echo -e "\n${WHITE}=== $1 ===${NC}"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

NERD_FONT_CASK="font-jetbrains-mono-nerd-font"

brewfile_formulae() {
    sed -nE 's/^brew "([^"]+)".*/\1/p' "$1"
}

# "name version" lines; empty when Homebrew is missing
installed_formulae() {
    brew list --formula --versions 2>/dev/null || true
}

formula_version() {
    local installed="$1" name="$2"
    awk -v name="$name" '$1 == name {print $2; exit}' <<< "$installed"
}

missing_brewfile_formulae() {
    local installed formula
    installed="$(installed_formulae)"
    for formula in $(brewfile_formulae "$1"); do
        [[ -n "$(formula_version "$installed" "$formula")" ]] || echo "$formula"
    done
}

# Font files from the cask or from an older install that copied them by hand
nerd_font_files() {
    [[ $# -gt 0 ]] || set -- "$HOME/Library/Fonts" /Library/Fonts
    find "$@" -maxdepth 1 \( -name 'JetBrainsMonoNerdFont*.ttf' -o -name 'JetBrainsMonoNLNerdFont*.ttf' \
        -o -name 'JetBrainsMonoNFM*.ttf' \) 2>/dev/null || true
}

nerd_font_cask_installed() {
    brew list --cask 2>/dev/null | grep -qxF "$NERD_FONT_CASK"
}
