# My Development Configuration

*A comprehensive collection of my personal development environment setup, including Xcode themes, shell aliases, and productivity tools for macOS development.*

![Alfredo](./alfredo_hdz.png)

## 🚀 Overview

This repository contains my personal development configuration that I use across different machines. It includes custom Xcode themes, shell aliases, productivity scripts, and development templates that streamline my daily workflow.

## 📦 What's Included

### 🎨 Xcode Configuration
- **7 Custom Color Themes** - Carefully crafted dark and light themes optimized for long coding sessions
- **Header Template** - Default [header file template](https://oleb.net/blog/2017/07/xcode-9-text-macros/) with author information
- **Test Templates** - Ready-to-use templates for both XCTest and Swift Testing frameworks

### 🐚 Shell Configuration
- **Git Aliases** - Shortcuts for common Git operations
- **Xcode Aliases** - Swift Package Manager and Xcode-specific commands
- **Enhanced File Listing** - Modern `ls` commands using [eza](https://formulae.brew.sh/formula/eza#default)
- **Custom Script Aliases** - Quick access to development utilities

### 🛠️ Custom Scripts
- **`deeplink.sh`** - Open deeplinks directly in iOS Simulator for testing

### 🎨 Code Formatting
- **SwiftFormat** - Automatic Swift code formatting with [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- **Custom Configuration** - Pre-configured formatting rules for consistent code style

## ⚡ Quick Installation

The installation process is fully automated and will set up everything you need:

```bash
# Clone the repository
git clone git@github.com:AlfredoHernandez/my-config.git
cd my-config

# Run the installation script
./install.sh

# Reload your shell configuration
source ~/.zshrc
```

## 📋 Installation Details

The `install.sh` script automatically handles:

1. **Homebrew Installation** - Installs Homebrew package manager if not present
2. **eza Installation** - Modern replacement for `ls` with better formatting and icons
3. **SwiftFormat Installation** - Installs SwiftFormat for automatic code formatting
4. **SwiftFormat Configuration** - Copies custom formatting rules to `~/.swiftformat`
5. **Shell Aliases** - Adds all aliases to your `.zshrc` file
6. **Script Installation** - Copies custom scripts to `~/Developer/bin/`
7. **Xcode Integration** - Installs templates and color themes

## 🎯 Usage

### Installation
```bash
./install.sh
```

### Backup Current Configuration
```bash
./backup.sh
```

## 📚 Available Aliases

### Git Operations
| Alias | Command | Description |
|-------|---------|-------------|
| `gl` | `git pull` | Pull latest changes |
| `gd` | `git diff` | Show differences |
| `gp` | `git push` | Push changes |
| `gst` | `git status` | Show repository status |
| `ga` | `git add .` | Stage all changes |
| `gc` | `git commit` | Commit changes |
| `gca` | `git commit --amend --no-edit` | Amend last commit |
| `glog` | `git log` | Show commit history |
| `gcp` | `git cherry-pick` | Cherry-pick commits |
| `cleanup` | Custom script | Delete merged branches |
| `grh` | `git reset --soft HEAD~1` | Soft reset last commit |

### Xcode & Swift
| Alias | Command | Description |
|-------|---------|-------------|
| `spm` | `xcodebuild -resolvePackageDependencies` | Resolve SPM dependencies |

### Enhanced File Listing (eza)
| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `eza --grid --icons --color=auto` | Grid view with icons and colors |
| `ll` | `eza --long --icons --color=auto` | Long format with icons |
| `la` | `eza --grid --icons --color=auto --all` | Grid view including hidden files |
| `lla` | `eza --long --icons --color=auto --all` | Long format including hidden files |

### Custom Scripts
| Alias | Command | Description |
|-------|---------|-------------|
| `dl <deeplink>` | `deeplink.sh <deeplink>` | Open deeplink in iOS Simulator |

## 🎨 SwiftFormat Configuration

This repository includes a comprehensive SwiftFormat configuration that provides:

### Key Features
- **160 character line width** for modern wide displays
- **Consistent code style** across all Swift projects
- **Automatic header insertion** with copyright information
- **Smart MARK comments** for better code organization
- **Optimized import grouping** with testable imports first

### Configuration Highlights
- **Allman braces disabled** - Uses standard Swift brace style
- **Some/Any syntax enabled** - Modern Swift type syntax
- **Smart wrapping** - Arguments and parameters wrap before first
- **Enhanced acronyms** - Proper capitalization for ID, URL, UUID
- **Blank lines** - Consistent spacing after switch cases

### Usage
After installation, SwiftFormat will automatically use the configuration from `~/.swiftformat`. You can:

```bash
# Format a single file
swiftformat MyFile.swift

# Format all Swift files in current directory
swiftformat .

# Format with specific options
swiftformat --config ~/.swiftformat MyProject/
```

For more information, visit the [SwiftFormat repository](https://github.com/nicklockwood/SwiftFormat).

## 🎨 Color Themes

The repository includes 7 carefully crafted color themes:

- **Alfred Dark** - Main dark theme with excellent contrast
- **Alfred Light** - Clean light theme for daytime coding
- **Alfred Mono (Dark)** - Monospace-focused dark theme
- **Alfred Mono (Light)** - Monospace-focused light theme
- **Alfred Mono Preso (Dark)** - Presentation-optimized dark theme
- **Alfred Mono Preso (Dark) basic** - Simplified presentation theme
- **Alfred Ultralarge (Dark)** - High-contrast theme for large displays

## 📋 Requirements

- **macOS** (tested on macOS 12+)
- **Xcode** (for templates and themes)
- **zsh shell** (default on modern macOS)
- **Internet connection** (for Homebrew and eza installation)

## 🤝 Contributing

This is a personal configuration repository, but suggestions and improvements are welcome! Feel free to:

- Open issues for bugs or suggestions
- Submit pull requests for improvements
- Share your own configurations

## 👨‍💻 Author

**Alfredo Hernández Alarcón**
- GitHub: [@AlfredoHernandez](https://github.com/AlfredoHernandez)
- Twitter: [@alfredohdzdev](https://twitter.com/alfredohdzdev)

---

*Happy coding! 🚀*


