# Contributing to My Development Configuration

Thanks for your interest in contributing! While this is a personal configuration repository, suggestions and improvements are welcome.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if an issue already exists
2. Open a new issue with a clear description
3. Include steps to reproduce (for bugs)
4. Mention your macOS version and shell (zsh/bash)

### Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test your changes locally
5. Commit with a clear message (see commit guidelines below)
6. Open a pull request

### Commit Message Guidelines

Follow these conventions for commit messages:

- Use imperative mood: "Add feature" not "Added feature"
- Keep subject line under 50 characters
- Add a body for complex changes explaining the "why"
- Reference issues when applicable

Example:
```
Add checksum verification for font downloads

This prevents potential security issues from corrupted
or tampered downloads by verifying SHA256 checksums
before installing fonts.

Fixes #123
```

## Code Style

### Shell Scripts

- Use `#!/bin/bash` shebang
- Add `set -euo pipefail` for error handling. Scripts that must keep going after a failed step and report it at the end (`sync.sh`, `update.sh`, `uninstall.sh`) use `set -uo pipefail`; `health-check.sh` uses neither so every check runs
- `update.sh` restarts itself after a pull that brings new commits, passing the old version's arguments and `MY_CONFIG_UPDATE_RESTARTED_FROM`. Keep accepting the flags older versions pass, and keep reading that variable
- Quote all variables: `"$VAR"` not `$VAR`
- Use `[[ ]]` for conditionals (bash-specific)
- Add comments for non-obvious logic
- Use functions for reusable code blocks

### Naming Conventions

- Scripts: `lowercase-with-dashes.sh`
- Functions: `snake_case`
- Variables: `UPPER_CASE` for constants, `lower_case` for locals

## Project Structure

```
my-config/
├── install.sh           # Main installation script
├── update.sh            # Update tools and copy repo changes to the system
├── sync.sh              # Sync installed config back to repo
├── uninstall.sh         # Remove installed components
├── health-check.sh      # Verify installation status
├── lib/
│   ├── common.sh           # Colors, Xcode paths and output helpers shared by every script
│   ├── config-install.sh   # Configuration copy steps shared by install.sh and update.sh
│   ├── claude-settings.sh  # Claude settings merge shared by install.sh, update.sh and sync.sh
│   └── retired-entries.sh  # Agents and skills deleted from the repo, read from git history
├── config/              # Configuration files
│   ├── aliases.zsh      # Shell aliases
│   └── swiftformat.txt  # SwiftFormat configuration
├── scripts/             # Custom utility scripts
├── tests/               # bats tests (run with `bats tests`)
├── .github/workflows/   # CI: shellcheck and the bats tests on every pull request
├── claude/              # Claude Code configuration
│   ├── CLAUDE.md        # Global instructions
│   ├── settings.json    # Claude Code settings
│   ├── agents/          # Custom AI agents
│   └── skills/          # Optional, not tracked yet: custom skills (one directory per skill)
├── Themes/              # Xcode color themes
├── Templates/           # Xcode file templates
└── Headers/             # Xcode header templates
```

## Testing Changes

Before submitting:

1. Run the automated checks. CI runs the same ones on every pull request:

   ```bash
   brew install bats-core shellcheck
   bats tests
   shellcheck -S warning *.sh lib/*.sh scripts/*.sh tests/test_helper.bash tests/*.bats
   ```

   Each test runs the scripts for real in its own temporary `HOME`. Add a test for every bug fix and new behavior, in the matching file under `tests/`
2. Run `./install.sh --dry-run` to preview changes
3. Test on a clean environment. The configuration steps write only under `$HOME`, including the Xcode folders, so they run for real in a temporary `HOME` without touching your machine:

   ```bash
   SANDBOX="$(mktemp -d)"
   HOME="$SANDBOX" ./install.sh --skip-homebrew --skip-tools --skip-font
   HOME="$SANDBOX" ./health-check.sh
   ```

   Homebrew and tools steps are system-wide, `sync.sh` writes into the repo and `update.sh --repo` pulls it, so keep those out of the sandbox run
4. Run `./health-check.sh` on your machine to verify the real installation
5. Ensure scripts work on both Intel and Apple Silicon Macs

## Questions?

Feel free to open an issue for any questions about contributing.
