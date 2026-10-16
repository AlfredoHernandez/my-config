# Language
- I'm learning English so sometimes I don't catch some sentences that you say, so please when I ask in Spanish answer in Spanish, then we can continue the conversation in English

# Git & Commits
- When a branch is merged, switch to the main branch and update it. Then delete the merged branch
- Never add "Co-Authored-By" trailers to commit messages
- After completing changes, generate the commit message using the `git-commit-messages` agent

# Pull Requests
- When creating a PR, assign it to me (`gh pr create --assignee @me`)
- Add the labels that fit the change, chosen from the repo's existing labels (`gh label list`); don't invent new ones unless asked
- Do not add "Made by Claude", "Generated with [Claude Code](https://claude.com/claude-code)" or something like that in the PRs/commit messages

# Releases
- When creating a `release/X.Y.Z` branch, add the CHANGELOG entry and update the README.md files if needed, on that release branch
- Don't merge the release PR into main until the store (App Store / Google Play) has approved and published that version
- While a release is in progress, don't merge other PRs into main until the release PR is integrated into main
- Create the release tag (and GitHub release) from the exact commit that was uploaded to the store / built for the release (the release branch head), not from main, because main may have advanced in parallel

# Simulators
- For mobile simulators do no create special simulators to test a specific feature
- Try to use always the only the available simulators installed
- In case to be necessary, ask for create a new simualtor and specify why, after doing the task, delete the created simulator.

# Code Quality

- Follow SOLID principles, clean architecture, and established design patterns
- Prefer composition over inheritance
- Keep functions small and focused on a single responsibility
- Tests must be deterministic: no real `sleep`, control concurrency with injected clocks/schedulers
- When finish a feature, always implement a code-review

# Development Workflow

- Run related tests after refactors to verify nothing is broken
- When fixing a bug, write a failing test first, then fix it

# Comments

- Default to zero comments. Code must read cleanly on its own; identifiers carry the meaning.
- Never write a comment that paraphrases the next line or narrates what the code does.
- Add a comment only when the WHY is non-obvious: a hidden constraint, a workaround for a specific bug, behavior that would surprise a reader. Keep it short and state it once, not in every file that touches it.
- KDoc/docstrings on public APIs only when they document a contract (invariants, edge cases), never to restate the signature.

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
