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
- Add `set -euo pipefail` for error handling
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
├── backup.sh            # Backup existing configurations
├── health-check.sh      # Verify installation status
├── scripts/             # Custom utility scripts
├── claude/              # Claude Code configuration
│   ├── CLAUDE.md        # Global instructions
│   └── agents/          # Custom AI agents
├── Themes/              # Xcode color themes
├── Templates/           # Xcode file templates
└── Headers/             # Xcode header templates
```

## Testing Changes

Before submitting:

1. Run `./install.sh --dry-run` to preview changes
2. Test on a clean environment if possible
3. Run `./health-check.sh` to verify installation
4. Ensure scripts work on both Intel and Apple Silicon Macs

## Questions?

Feel free to open an issue for any questions about contributing.
