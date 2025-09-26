# My Config

*Backup of my Xcode configuration, shell aliases, and various development settings*

![Alfredo](./alfredo_hdz.png)

## Contents

- **Xcode Configuration**
  - Color themes (7 custom themes)
  - Default [header file template](https://oleb.net/blog/2017/07/xcode-9-text-macros/)
  - Test templates (XCTest and Swift Testing)
- **Shell Configuration**
  - Git aliases for common operations
  - Xcode aliases for SPM operations
  - Enhanced `ls` commands using [eza](https://formulae.brew.sh/formula/eza#default)
  - Custom script aliases
- **Custom Scripts**
  - `deeplink.sh` - Open deeplinks in iOS Simulator

## Installation

The `install.sh` script will automatically:

1. **Install Homebrew** (if not present)
2. **Install eza** (modern `ls` replacement)
3. **Add shell aliases** to your `.zshrc`
4. **Install custom scripts** to `~/Developer/bin/`
5. **Install Xcode templates and themes**

### Quick Start

```bash
# Clone the repository
git clone git@github.com:AlfredoHernandez/my-config.git
cd my-config

# Install everything
./install.sh

# Restart terminal or reload shell
source ~/.zshrc
```

## Usage

### Install

```bash
./install.sh
```

### Backup

```bash
./backup.sh
```

## Available Aliases

### Git Aliases
- `gl` - git pull
- `gd` - git diff
- `gp` - git push
- `gst` - git status
- `ga` - git add .
- `gc` - git commit
- `gca` - git commit --amend --no-edit
- `glog` - git log
- `gcp` - git cherry-pick
- `cleanup` - Delete merged branches
- `grh` - git reset --soft HEAD~1

### Xcode Aliases
- `spm` - Resolve SPM dependencies

### Enhanced ls Commands (using eza)
- `ls` - Grid view with icons and colors
- `ll` - Long format with icons
- `la` - Grid view with hidden files
- `lla` - Long format with hidden files

### Custom Scripts
- `dl <deeplink>` - Open deeplink in iOS Simulator

## Requirements

- macOS
- Xcode
- zsh shell
- Internet connection (for Homebrew and eza installation)


