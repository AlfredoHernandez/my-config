# My Development Configuration

*A comprehensive collection of my personal development environment setup, including Xcode themes, shell aliases, and productivity tools for macOS development.*

![Alfredo](./alfredo_hdz.png)

## 🚀 Overview

This repository contains my personal development configuration that I use across different machines. It includes custom Xcode themes, shell aliases, productivity scripts, and development templates that streamline my daily workflow.

## 📦 What's Included

### 🎨 Xcode Configuration
- **8 Color Themes** - Carefully crafted dark and light themes optimized for long coding sessions
- **Header Template** - Default [header file template](https://oleb.net/blog/2017/07/xcode-9-text-macros/) with author information
- **Test Templates** - Ready-to-use templates for both XCTest and Swift Testing frameworks

### 🐚 Shell Configuration
- **Git Aliases** - Shortcuts for common Git operations
- **Xcode Aliases** - Swift Package Manager and Xcode-specific commands
- **Claude Code Aliases** - Launch Claude Code with preset models and effort levels
- **Enhanced File Listing** - Modern `ls` commands using [eza](https://formulae.brew.sh/formula/eza#default)
- **Custom Script Aliases** - Quick access to development utilities

### 🛠️ Custom Scripts
- **`deeplink.sh`** - Open deeplinks directly in iOS Simulator for testing

### 🎨 Code Formatting
- **SwiftFormat** - Automatic Swift code formatting with [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- **Custom Configuration** - Pre-configured formatting rules for consistent code style

### 🤖 Claude Code Integration
- **Global Configuration** - Custom instructions for Claude Code in `~/.claude/CLAUDE.md`
- **Settings** - Shared permissions, attribution, plugins, the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var, the auto mode trust context and allow rules (`autoMode.environment`, `autoMode.allow`), and the unattended-work options (`autoContinueAtUsageLimit`, `inputNeededNotifEnabled`, `askUserQuestionTimeout`). `install.sh` and `update.sh` merge only these keys into `~/.claude/settings.json` (backup in `settings.json.bak`), keep local keys such as hooks and preferences, and list any local values of these keys that the repo replaces; `sync.sh` copies only these keys back. For plugins and marketplaces the repo owns only the entries it lists, so a plugin enabled on one machine is kept there and is not copied back. The merge needs [jq](https://formulae.brew.sh/formula/jq), which the `Brewfile` installs (macOS 15 and later also ship it); without it the merge is skipped
- **Custom Agents** - Specialized AI assistants for common tasks:
  - `code-review` - Read-only senior code reviewer that reports findings and hand-offs
  - `design-patterns` - GoF design patterns expert
  - `git-commit-messages` - Writes atomic commit messages
  - `pr-description` - Writes PR titles and bodies (Why / Use cases / What changed)
  - `release-notes` - Writes user-facing release notes from commits
  - `swift-tdd-architect` - Builds Swift / Apple-platform features test-first, commits and reviews
  - `swift-testing` - Swift Testing framework and TDD expert
  - `swift-test-doubles-architect` - Test double design for Swift
  - `swift-docs` - Documents Swift API contracts
  - `kotlin-tdd-architect` - Builds Kotlin / Android features test-first, commits and reviews
  - `kotlin-testing` - Kotlin / Android testing expert
  - `kotlin-test-doubles-architect` - Test double design for Kotlin
- **Custom Skills** - Skill directories (each with a `SKILL.md`) installed to `~/.claude/skills/`; none are tracked yet
- **Deleted agents and skills** - When an agent or skill is deleted from the repo (or renamed), `install.sh` and `update.sh` remove it from `~/.claude`, so every Mac stays in sync. The list comes from git history, so agents and skills that never were in the repo are kept. `sync.sh` does not copy them back, and `health-check.sh` warns if one is still installed

### 🍺 Homebrew Packages
- **`Brewfile`** - The command-line tools every Mac gets: [jq](https://formulae.brew.sh/formula/jq), [eza](https://formulae.brew.sh/formula/eza), [SwiftFormat](https://formulae.brew.sh/formula/swiftformat) and [herdr](https://herdr.dev), which keeps coding agents such as Claude Code running in the background and shows which ones are working, blocked or idle. `install.sh` installs the missing ones with `brew bundle`, `update.sh` upgrades them and installs any new entry, and `health-check.sh` and `uninstall.sh` read the same list. To add a tool on every Mac, add a `brew "<name>"` line

### 🔤 Fonts
- **JetBrains Mono Nerd Font** - Programming font with ligatures and icons, installed from the [`font-jetbrains-mono-nerd-font`](https://formulae.brew.sh/cask/font-jetbrains-mono-nerd-font) cask. A copy installed by hand is kept, but `update.sh` can upgrade only the cask

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
2. **Brewfile Tools** - Installs the missing `Brewfile` packages with `brew bundle`
3. **JetBrains Mono Nerd Font** - Installs the font cask, unless the font is already installed
4. **SwiftFormat Configuration** - Copies custom formatting rules to `~/.swiftformat`
5. **Claude Code Configuration** - Installs global instructions, custom agents and skills to `~/.claude/`
6. **Shell Aliases** - Installs `~/.config/aliases.zsh` and sources it from your `.zshrc`
7. **Script Installation** - Copies custom scripts to `~/Developer/bin/`
8. **Xcode Integration** - Installs templates and color themes

### ⚠️ Manual step: select the font in your terminal

Installing the font does not make your terminal use it. The `ls`/`ll`/`la` aliases
run `eza --icons`, so without a Nerd Font selected in your terminal profile the
icons render as boxes or question marks.

After installing, set the font manually in your terminal's profile preferences:

| Terminal | Where |
|----------|-------|
| Terminal.app | Settings → Profiles → Text → Font |
| iTerm2 | Settings → Profiles → Text → Font |
| Ghostty | `font-family = JetBrainsMono Nerd Font` in `~/.config/ghostty/config` |
| VS Code | `"terminal.integrated.fontFamily": "JetBrainsMono Nerd Font"` |

Pick **JetBrainsMono Nerd Font** (or *JetBrainsMono Nerd Font Mono* for strict
monospacing).

## 🎯 Scripts

### `install.sh` - Installation

Installs or updates all components from the repo to your system. If a file already exists and differs, it gets updated automatically.

```bash
./install.sh              # Install everything
./install.sh --dry-run    # Preview without making changes
./install.sh --validate   # Check system prerequisites
./install.sh --list       # List available components
./install.sh --no-verify  # Skip the health check that runs after installing
```

#### Install Specific Components

```bash
./install.sh --only-themes             # Install only Xcode themes
./install.sh --only-tools --only-font  # Install only tools and font
./install.sh --only-claude             # Install only Claude Code configuration
./install.sh --only-xcode             # Install all Xcode components
```

#### Skip Specific Components

```bash
./install.sh --skip-xcode     # Install everything except Xcode components
./install.sh --skip-themes    # Install everything except themes
./install.sh --skip-homebrew  # Skip Homebrew installation
```

#### Available Component Flags

| Flag | Component |
|------|-----------|
| `--only-homebrew` / `--skip-homebrew` | Homebrew package manager |
| `--only-tools` / `--skip-tools` | `Brewfile` tools |
| `--only-font` / `--skip-font` | JetBrains Mono Nerd Font |
| `--only-swiftformat-config` / `--skip-swiftformat-config` | SwiftFormat configuration |
| `--only-aliases` / `--skip-aliases` | Shell aliases |
| `--only-scripts` / `--skip-scripts` | Custom scripts |
| `--only-xcode` / `--skip-xcode` | All Xcode components |
| `--only-themes` / `--skip-themes` | Xcode color themes |
| `--only-templates` / `--skip-templates` | Xcode templates |
| `--only-header` / `--skip-header` | Xcode header template |
| `--only-claude` / `--skip-claude` | Claude Code configuration, agents and skills |

### `update.sh` - Update

Updates installed components to their latest versions. Fast-forwards `main` from `origin/main` (skipped on any other branch); when the pull brings new commits, it restarts itself once so the remaining steps run the new version of the scripts. It then upgrades the `Brewfile` packages and installs any that are missing, upgrades the font cask, and applies the repo's configuration with the same steps as `install.sh` (shared in `lib/config-install.sh`): SwiftFormat config, `CLAUDE.md`, Claude agents, skills and settings, custom scripts, Xcode templates, themes and the header template. Missing files are installed too, including components skipped at install time, so every Mac ends up with the same configuration. Aliases are not updated, because they also change `~/.zshrc`; run `install.sh --only-aliases` for those.

```bash
./update.sh            # Update everything
./update.sh --check    # Show what's outdated without updating
./update.sh --repo     # Update repository only (git pull)
./update.sh --tools    # Update the Brewfile packages only
./update.sh --config   # Sync configuration files only
./update.sh --font     # Update Nerd Font only
```

### `sync.sh` - Sync

Compares installed files on your system against the repo and copies any changes back. Useful for capturing configuration changes made outside the repo (e.g., editing Xcode themes directly). If updates are found, it asks you to review them with `git status` and `git diff` and commit them by path.

```bash
./sync.sh
```

**Direction:** System → Repo (opposite of `install.sh` and `update.sh`)

If a repo file is newer than its installed copy (for example after a `git pull` without `./install.sh`), `sync.sh` skips it instead of overwriting it, and reports it as skipped. Run `./install.sh`, then sync again.

Claude skills are synced from `~/.claude/skills/<name>/` only for the skills already in `claude/skills/`; to track a new skill, copy it there once. Skills managed by the Claude app (`~/.claude/skills/synced/`) and `__pycache__` folders are ignored.

### `health-check.sh` - Health Check

Verifies that all components are properly installed and configured.

```bash
./health-check.sh
```

- Checks if Homebrew, every `Brewfile` package and the font are installed
- Verifies configuration files exist and are properly configured
- Validates Xcode themes, templates, and headers
- Checks Claude Code configuration, agents and skills
- Verifies custom scripts are installed and executable
- Shows version information for installed tools
- Detects outdated packages and suggests updates
- Provides a health score and recommendations

### `uninstall.sh` - Uninstall

Removes installed components from your system.

```bash
./uninstall.sh              # Remove everything (with confirmation)
./uninstall.sh --dry-run    # Preview what would be removed
./uninstall.sh --force      # Skip confirmation prompts
```

#### Uninstall Specific Components

```bash
./uninstall.sh --tools      # Remove the Brewfile packages
./uninstall.sh --font       # Remove JetBrains Mono Nerd Font
./uninstall.sh --config     # Remove SwiftFormat configuration
./uninstall.sh --aliases    # Remove shell aliases
./uninstall.sh --scripts    # Remove custom scripts
./uninstall.sh --xcode      # Remove Xcode themes, templates, headers
./uninstall.sh --claude     # Remove Claude configuration, agents and repo skills
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
| `cleanup` | `git fetch --prune`, then `git branch -D` on the branches marked `[gone]` | Delete the local branches whose remote branch was deleted (after a squash merge, for example). Lists them and asks first; keeps the current branch |
| `grh` | `git reset --soft HEAD~1` | Soft reset last commit |

### Xcode & Swift
| Alias | Command | Description |
|-------|---------|-------------|
| `spm` | `xcodebuild -resolvePackageDependencies -scmProvider system` | Resolve SPM dependencies with the system Git |

### Claude Code
| Alias | Command | Description |
|-------|---------|-------------|
| `cl` | `CLAUDE_CODE_SUBAGENT_MODEL=sonnet claude --model opus --effort high --advisor opus --fallback-model sonnet` | Default session. Subagents without `model:` use Sonnet |
| `clx` | `CLAUDE_CODE_SUBAGENT_MODEL=opus claude --model opus --effort xhigh --advisor opus` | Hard work: architecture, big refactors, hard bugs. Subagents without `model:` use Opus |
| `clq` | `CLAUDE_CODE_SUBAGENT_MODEL=haiku claude --model sonnet --effort medium` | Quick questions and exploration. Subagents without `model:` use Haiku |

The custom agents in `claude/agents/` set their own `model:` and `effort:` in the frontmatter. Since Claude Code v2.1.251, `model:` wins over `CLAUDE_CODE_SUBAGENT_MODEL`, and `effort:` wins over the session's `--effort`. So the alias only changes the main session and the subagents that don't set these fields, like the built-in `general-purpose`.

### Enhanced File Listing (eza)
| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `eza --grid --color auto --icons --sort=type` | Grid view with icons, directories first |
| `ll` | `eza --long --color always --icons --sort=type` | Long format with icons |
| `la` | `eza --grid --all --color auto --icons --sort=type` | Grid view including hidden files |
| `lla` | `eza --long --all --color auto --icons --sort=type` | Long format including hidden files |

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

The repository includes 8 color themes:

- **Alfred Dark** - Main dark theme with excellent contrast
- **Alfred Light** - Clean light theme for daytime coding
- **Alfred Mono (Dark)** - Monospace-focused dark theme
- **Alfred Mono (Light)** - Monospace-focused light theme
- **Alfred Mono Preso (Dark)** - Presentation-optimized dark theme
- **Alfred Mono Preso (Dark) basic** - Simplified presentation theme
- **Alfred Ultralarge (Dark)** - High-contrast theme for large displays
- **Default (Light)** - Customized default light theme

## 📋 Requirements

- **macOS** (tested on macOS 12+)
- **Xcode** (for templates and themes)
- **zsh shell** (default on modern macOS)
- **Internet connection** (for Homebrew and the `Brewfile` packages)

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


