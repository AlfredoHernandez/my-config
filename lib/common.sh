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

# Can be set from outside, so tests can point the Xcode steps at a fake HOME
XC_DIR="${XC_DIR:-$HOME/Library/Developer/Xcode}"
XC_USER_DATA="${XC_USER_DATA:-$XC_DIR/UserData}"

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_info() { echo -e "${CYAN}[i]${NC} $1"; }
print_header() { echo -e "\n${WHITE}=== $1 ===${NC}"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}
