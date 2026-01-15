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

### 🤖 Claude Code Integration
- **Global Configuration** - Custom instructions for Claude Code in `~/.claude/CLAUDE.md`
- **Custom Agents** - Specialized AI assistants for common tasks:
  - `git-commit-messages` - Generates well-formatted commit messages
  - `swift-testing` - Expert in Swift Testing framework and TDD
  - `swift-docs` - Swift documentation specialist

### 🔤 Fonts
- **JetBrains Mono Nerd Font** - Programming font with ligatures and icons

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
4. **JetBrains Mono Nerd Font** - Installs programming font with ligatures and icons
5. **SwiftFormat Configuration** - Copies custom formatting rules to `~/.swiftformat`
6. **Claude Code Configuration** - Installs global instructions and custom agents to `~/.claude/`
7. **Shell Aliases** - Adds all aliases to your `.zshrc` file
8. **Script Installation** - Copies custom scripts to `~/Developer/bin/`
9. **Xcode Integration** - Installs templates and color themes

## 🎯 Usage

### Installation

#### Install Everything
```bash
./install.sh
```

#### Install Specific Components
```bash
# Install only Xcode themes
./install.sh --only-themes

# Install only development tools and font
./install.sh --only-tools --only-font

# Install only Claude Code configuration
./install.sh --only-claude

# Install all Xcode components
./install.sh --only-xcode
```

#### Skip Specific Components
```bash
# Install everything except Xcode components
./install.sh --skip-xcode

# Install everything except themes
./install.sh --skip-themes

# Skip Homebrew installation
./install.sh --skip-homebrew
```

#### Available Components
- `--only-homebrew` / `--skip-homebrew` - Homebrew package manager
- `--only-tools` / `--skip-tools` - Development tools (eza, SwiftFormat)
- `--only-font` / `--skip-font` - JetBrains Mono Nerd Font
- `--only-swiftformat-config` / `--skip-swiftformat-config` - SwiftFormat configuration
- `--only-aliases` / `--skip-aliases` - Shell aliases
- `--only-scripts` / `--skip-scripts` - Custom scripts
- `--only-xcode` / `--skip-xcode` - All Xcode components
- `--only-themes` / `--skip-themes` - Xcode color themes
- `--only-templates` / `--skip-templates` - Xcode templates
- `--only-header` / `--skip-header` - Xcode header template
- `--only-claude` / `--skip-claude` - Claude Code configuration

#### List Available Components
```bash
./install.sh --list
```

#### Preview Installation (Dry Run)
```bash
./install.sh --dry-run

# Preview specific components
./install.sh --dry-run --only-themes
```

### Health Check
```bash
./health-check.sh
```
Verifies that all components are properly installed and configured. The health check will:
- ✅ Check if all tools are installed (Homebrew, eza, SwiftFormat, fonts)
- ✅ Verify configuration files exist and are properly configured
- ✅ Validate Xcode themes, templates, and headers
- ✅ Check Claude Code configuration and agents
- ✅ Verify custom scripts are installed and executable
- ✅ Show version information for installed tools
- ✅ Detect outdated packages and suggest updates
- ✅ Provide a health score and recommendations

Run this periodically to ensure your development environment is in good shape!

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

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Happy coding! 🚀*


