#!/usr/bin/env bats

load test_helper

@test "uninstall removes only the agents the repo ships" {
    "$REPO_DIR/install.sh" --only-claude --no-verify >/dev/null 2>&1
    echo mine > "$HOME/.claude/agents/my-local.md"

    run_script "$REPO_DIR/uninstall.sh" --claude --force

    [ "$status" -eq 0 ]
    [ "$(count_files "$HOME/.claude/agents" '*.md')" -eq 1 ]
    [ -f "$HOME/.claude/agents/my-local.md" ]
}

@test "uninstall dry run removes nothing" {
    "$REPO_DIR/install.sh" --only-claude --no-verify >/dev/null 2>&1

    run_script "$REPO_DIR/uninstall.sh" --dry-run --claude

    [ "$status" -eq 0 ]
    [ "$(count_files "$HOME/.claude/agents" '*.md')" -eq "$(count_files "$REPO_DIR/claude/agents" '*.md')" ]
}

@test "health check finds the Xcode files under HOME" {
    "$REPO_DIR/install.sh" --only-xcode --no-verify >/dev/null 2>&1

    run_script "$REPO_DIR/health-check.sh"

    grep -q "Xcode themes directory found" <<< "$output"
    grep -q "Xcode header template found" <<< "$output"
}

@test "health check warns about installed agents deleted from the repo" {
    local retired
    retired="$(retired_agent)"
    [ -n "$retired" ] || skip "no deleted agents in the git history (shallow clone?)"
    mkdir -p "$HOME/.claude/agents"
    echo old > "$HOME/.claude/agents/$retired"

    run_script "$REPO_DIR/health-check.sh"

    grep -q "deleted from the repo is still installed: $retired" <<< "$output"
}
