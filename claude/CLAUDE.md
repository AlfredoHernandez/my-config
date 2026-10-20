# Language
- I'm learning English so sometimes I don't catch some sentences that you say, so please when I ask in Spanish answer in Spanish, then we can continue the conversation in English
- Use short sentences and simple words, and explain technical terms the first time they appear

# Git & Commits
- When a branch is merged, switch to the repo's default branch and update it. Then delete the merged branch. If git says the branch is not fully merged (squash merges look unmerged), check the merged PR before forcing the delete
- Never add "Co-Authored-By" trailers to commit messages
- Do not add "Made by Claude", "Generated with [Claude Code](https://claude.com/claude-code)" or something like that in the commit messages or PR descriptions
- After completing changes, generate the commit message using the `git-commit-messages` agent
- Commit atomically while working, but push the branch only when the feature is ready, not after each atomic commit

# Pull Requests
- When creating a PR, assign it to me (`gh pr create --assignee @me`)
- Add the labels that fit the change, chosen from the repo's existing labels (`gh label list`); don't invent new ones unless asked

# Releases
- Create the `release/X.Y.Z` branch, make all the release changes on it (CHANGELOG entry, README.md updates, etc.), and only then push it
- Don't merge the release PR into main until the store (App Store / Google Play) has approved and published that version
- While a release is in progress, don't merge other PRs into main until the release PR is integrated into main
- Create the release tag (and GitHub release) from the exact commit that was uploaded to the store / built for the release (the release branch head), not from main, because main may have advanced in parallel

# Simulators
- Use only the simulators already installed; don't create special ones to test a feature
- If a new simulator is really needed, ask first and explain why. When the task is done, ask whether to delete the simulators I created

# Code Quality

- Make sure the code follows SOLID principles, clean code, clean architecture and established design patterns
- Prefer composition over inheritance
- Keep functions small and focused on a single responsibility
- Tests must be deterministic: no real `sleep`, control concurrency with injected clocks/schedulers
- When a feature is finished, run the `code-review` agent and fix the real findings before opening the PR

# Development Workflow

- Run the tests locally only when the feature is ready and before creating the PR, not after each commit or step
- When fixing a bug, write a failing test first, then fix it

# Comments

- Default to zero comments. Code must read cleanly on its own; identifiers carry the meaning.
- Never write a comment that paraphrases the next line or narrates what the code does.
- Add a comment only when the WHY is non-obvious: a hidden constraint, a workaround for a specific bug, behavior that would surprise a reader. Keep it short and state it once, not in every file that touches it.
- KDoc/docstrings on public APIs only when they document a contract (invariants, edge cases), never to restate the signature.

## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
