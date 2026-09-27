---
name: nightshift
description: Work on a ticket end-to-end — fetch, branch, implement, test, commit, and create PR following project conventions. Supports manual (default) and automatic (--auto) modes.
argument-hint: "<TICKET-ID> [--auto]"
user-invocable: true
---

# Ticket Workflow

You are executing a structured workflow to resolve a Linear ticket. Follow each phase in order. Read `CLAUDE.md` at the project root for all conventions before starting.

## Arguments

Parse the arguments provided by the user:
- **Ticket ID**: The Linear ticket identifier (e.g., `PROJ-68`)
- **`--auto` flag**: If present, run in automatic mode. Otherwise, run in manual mode.

**Modes:**
- **Manual (default)**: Pause before each commit and before creating the PR. Wait for user confirmation.
- **Automatic (`--auto`)**: Create atomic commits and PR without pausing for confirmation.

---

## Phase 1: Setup

1. **Fetch the ticket** from Linear using the `get_issue` MCP tool with the provided ticket ID.
2. **Display a summary** to the user:
   - Title, description, labels, priority
   - Indicate which mode is active (Manual / Automatic)
3. **Fetch project labels** from Linear using `list_issues` to understand the available labels in this project.
4. **Determine branch type** by matching the ticket's labels against the project's labels:
   - Feature / improvement / enhancement → `feature/{ticketId}`
   - Bug / defect → `bugfix/{ticketId}`
   - Hotfix / urgent fix / critical → `hotfix/{ticketId}`
   - Release / deploy / infra → `release/{ticketId}`
   - Chore / maintenance / refactor / tech-debt → `chore/{ticketId}`
   - Documentation / docs → `docs/{ticketId}`
   - Default (no matching label or unclear) → `feature/{ticketId}`
   - Use your best judgment to map the ticket's labels to the correct branch type. Do not hardcode specific label names — different projects may use different naming conventions.
5. **Prepare the branch:**
   ```
   git checkout main && git pull origin main
   ```
6. **Create the branch** using the determined naming convention.
7. **Move the ticket** to "In Progress" in Linear using `save_issue`.

---

## Phase 2: Implementation

1. **Analyze the ticket** description for:
   - Scope: which files need to change
   - Requirements: what the expected behavior is
   - Constraints: what should NOT change
2. **Explore the codebase** to understand existing patterns before writing code.
3. **Follow TDD** when the ticket involves new logic:
   - Write failing tests first
   - Implement the code to make tests pass
   - Refactor if needed



---

## Phase 3: Commit & PR

### Grouping commits

Organize changes into **atomic commits by area**. Common groups:
- **Domain/Logic**: models, validators, use cases
- **Tests**: test files
- **UI**: views, components
- **Infrastructure**: package dependencies, configuration files

### Creating commits

For each commit group:
1. Use the `git-commit-messages` agent to generate the commit message
2. Stage only the files for that group
3. Commit with the format `[{ticketId}] {message}`

### Manual mode (default)

- Present the proposed commit groups to the user
- Wait for user confirmation before creating each commit
- After all commits, suggest push + PR and wait for confirmation

### Automatic mode (`--auto`)

- Create all commits sequentially without pausing
- Push and create PR automatically after all commits

### PR creation

1. Push the branch: `git push -u origin <branch-name>`
2. Create PR with `gh pr create`:
   - Title: `[{ticketId}] {title}`
   - Base: `main`
   - Assignee: `@me`
   - Labels: select the best matching labels from the **GitHub repository's available labels** that correspond to the ticket's labels in Linear. Do not invent labels — only use labels that exist in the repo.
   - Body: summary of changes, test plan
   - **Never mention Claude, AI, or any AI tool**

### Important rules

- **Never move ticket to Done** — this happens automatically when the PR is merged
- **Never add Co-Authored-By trailers** to commit messages

---

## Phase 4: Next Ticket

After the PR is created:
1. Ask the user if they want to continue with another ticket
2. If yes, list available tickets from the Linear backlog using `list_issues`
3. Let the user choose the next ticket
4. Restart from Phase 1, preserving the same mode (manual/automatic)
5. If no, end the workflow
