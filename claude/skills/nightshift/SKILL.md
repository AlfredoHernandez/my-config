---
name: nightshift
description: Work on a feature, fix, release or chore end-to-end — branch, use cases, implement, test, review, commit, and create PR following project conventions. Supports manual (default) and automatic (--auto) modes.
argument-hint: "<feature|bug|hotfix|release|chore|docs> \"<description>\" [--auto]"
user-invocable: true
allowed-tools: Bash(git:*), Bash(gh:*), Read, Edit, Write, Grep, Glob, Agent
---

# Work Item Workflow

You are executing a structured workflow to deliver one unit of work (a feature, fix, release, etc.). Follow each phase in order. Read the project's `CLAUDE.md` before starting: its conventions (branch names, commit format, test commands) win over the defaults below. The global `CLAUDE.md` rules for commits and PRs (no attribution lines, no Co-Authored-By, assignee, labels) always apply.

## Arguments

- **Type**: `feature`, `bug`, `hotfix`, `release`, `chore` or `docs`. If missing or unclear, infer it from the description.
- **Description**: what needs to be done, in the user's words.
- **`--auto` flag**: run in automatic mode. Otherwise run in manual mode.

**Modes:**
- **Manual (default)**: pause before each commit and before creating the PR. Wait for user confirmation.
- **Automatic (`--auto`)**: create atomic commits and the PR without pausing for confirmation.

If the description is too vague to define scope or expected behavior:
- Manual: ask the user the missing questions.
- Automatic: stop and report what is missing. Never guess.

---

## Phase 1: Setup

1. **Summarize** the work to the user: type, description, active mode.
2. **Check the working tree.** If there are uncommitted changes, stop and ask what to do with them.
3. **Detect the default branch** with `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` (fall back to `git symbolic-ref refs/remotes/origin/HEAD`). Never assume `main`.
4. **Name the branch** `{type}/{short-kebab-description}` (e.g. `feature/offline-cache`, `bug/crash-on-empty-list`, `release/2.4.0`). Releases use the version number. If the branch already exists locally or on the remote, stop and ask.
5. **Create the branch** from the updated default branch:
   ```
   git checkout <default> && git pull origin <default>
   git checkout -b <branch>
   ```

---

## Phase 2: Use Cases

Skip this phase for `release`, `chore` and `docs`.

Use cases live in the app, one `.md` file per feature, and describe the behavior the code must satisfy.

1. **Locate the use cases folder.** Look for an existing `UseCases/` (or `docs/use-cases/`) folder. If none exists, create `UseCases/` at the root of the app's source folder.
2. **Find or create the feature file**: `UseCases/<FeatureName>.md`. Read it first if it exists; extend it instead of rewriting it.
3. **Write or update the use cases** for this work. Each use case has:
   - **Name** and the **actor** who triggers it
   - **Preconditions**
   - **Main flow**: numbered steps
   - **Alternative / error flows**
   - **Expected result**
4. For a `bug`, add or correct the use case that was violated, so the fix has a written expectation.
5. In manual mode, show the use cases and wait for confirmation before implementing.

The use cases are the source for the tests in the next phase.

---

## Phase 3: Implementation

1. **Analyze the work** for scope (which files change), requirements (expected behavior) and constraints (what must NOT change).
2. **Explore the codebase** to understand existing patterns before writing code.
3. **Follow TDD** when the work involves logic: write a failing test per use case (for a bug, a test that reproduces it first), make it pass, then refactor.
4. **For a `release`**: follow the global release rules (CHANGELOG entry and README updates on the release branch) instead of TDD.
5. **Run the project's tests and build** and make sure they pass. If they fail, fix them. In automatic mode, if they still fail after a reasonable attempt, stop and report: never commit, push or open a PR with failing tests.

---

## Phase 4: Code Review

Skip for trivial `docs` changes.

1. Run the `code-review` agent on the branch changes.
2. Fix the findings that are real issues. Skip the ones that conflict with the use cases or the project conventions and tell the user why.
3. Re-run the tests. Repeat the review up to 3 rounds, or until it reports no relevant findings.

---

## Phase 5: Commit & PR

### Grouping commits

Organize changes into **atomic commits by area**. Common groups:
- **Domain/Logic**: models, validators, use cases
- **Tests**: test files
- **UI**: views, components
- **Infrastructure**: package dependencies, configuration files
- **Docs**: use cases `.md` files, CHANGELOG, README

### Creating commits

For each commit group:
1. Use the `git-commit-messages` agent to generate the commit message
2. Stage only the files for that group
3. Commit with that message, unless the project's `CLAUDE.md` defines another format

### Manual mode (default)

- Present the proposed commit groups to the user
- Wait for confirmation before creating each commit
- After all commits, suggest push + PR and wait for confirmation

### Automatic mode (`--auto`)

- Create all commits sequentially without pausing
- Push and create the PR automatically after all commits
- Never force-push

### PR creation

1. Push the branch: `git push -u origin <branch-name>`
2. Create the PR with `gh pr create`:
   - Title: short, descriptive, in the same style as the commit messages
   - Base: the default branch detected in Phase 1
   - Assignee: `@me`
   - Labels: run `gh label list` and choose the ones that fit the change. Never invent labels.
   - Body, with these sections:
     - **Why**: the problem or need that motivates the change
     - **Use cases**: the use cases it covers (name each one, or link the `UseCases/<Feature>.md` file)
     - **What changed**: a high-level explanation of the feature / fix / release, not a file-by-file list

---

## Phase 6: Next Work Item

After the PR is created:
1. Ask the user if they want to continue with another feature / fix / release / etc.
2. If yes, ask for its type and description, then restart from Phase 1 from the updated default branch, never from the previous branch. Keep the same mode.
3. In automatic mode, stop after each PR unless the user explicitly asked to continue.
4. If no, end the workflow.

When the user says a PR was merged, follow the global rule: switch to the default branch, update it, and delete the merged branch.
