#!/usr/bin/env bats

load test_helper

@test "installs the Claude configuration into an empty HOME" {
    run_script "$REPO_DIR/install.sh" --only-claude --no-verify

    [ "$status" -eq 0 ]
    cmp -s "$REPO_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    cmp -s "$REPO_DIR/claude/settings.json" "$HOME/.claude/settings.json"
    [ "$(count_files "$HOME/.claude/agents" '*.md')" -eq "$(count_files "$REPO_DIR/claude/agents" '*.md')" ]
}

@test "a second install changes nothing" {
    "$REPO_DIR/install.sh" --only-claude --only-xcode --only-scripts --no-verify >/dev/null 2>&1

    run_script "$REPO_DIR/install.sh" --only-claude --only-xcode --only-scripts --no-verify

    [ "$status" -eq 0 ]
    refute_output_matches '\[↑\]|installed$'
}

@test "dry run writes nothing" {
    run_script "$REPO_DIR/install.sh" --dry-run --only-claude --only-xcode

    [ "$status" -eq 0 ]
    [ ! -e "$HOME/.claude" ]
    [ ! -e "$HOME/Library" ]
}

@test "Xcode steps write under HOME" {
    run_script "$REPO_DIR/install.sh" --only-xcode --no-verify

    [ "$status" -eq 0 ]
    [ "$(count_files "$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes" '*.xccolortheme')" -gt 0 ]
    [ -f "$HOME/Library/Developer/Xcode/UserData/IDETemplateMacros.plist" ]
}

@test "works when run from another directory" {
    cd "$BATS_TEST_TMPDIR"

    run_script "$REPO_DIR/install.sh" --only-claude --no-verify

    [ "$status" -eq 0 ]
    refute_output_matches "source not found"
}

@test "settings merge keeps local keys and lists the replaced shared values" {
    write_settings '{"model":"opus","hooks":{"Stop":[]},"permissions":{"allow":["Bash(local:*)"],"defaultMode":"auto"}}'
    cp "$HOME/.claude/settings.json" "$BATS_TEST_TMPDIR/before.json"

    run_script "$REPO_DIR/install.sh" --only-claude --no-verify

    [ "$status" -eq 0 ]
    [ "$(jq -r .model "$HOME/.claude/settings.json")" = opus ]
    [ "$(jq -r .permissions.defaultMode "$HOME/.claude/settings.json")" = auto ]
    [ "$(jq -c .hooks "$HOME/.claude/settings.json")" = '{"Stop":[]}' ]
    [ "$(jq -c .permissions.allow "$HOME/.claude/settings.json")" = "$(jq -c .permissions.allow "$REPO_DIR/claude/settings.json")" ]
    grep -q 'Bash(local:\*)' <<< "$output"
    cmp -s "$BATS_TEST_TMPDIR/before.json" "$HOME/.claude/settings.json.bak"
}

@test "invalid local settings are left untouched and the install goes on" {
    write_settings '{"model":"opus",}'
    cp "$HOME/.claude/settings.json" "$BATS_TEST_TMPDIR/before.json"

    run_script "$REPO_DIR/install.sh" --only-claude --no-verify

    [ "$status" -eq 0 ]
    grep -q "Invalid JSON" <<< "$output"
    cmp -s "$BATS_TEST_TMPDIR/before.json" "$HOME/.claude/settings.json"
}

@test "a backup that can't be written stops the settings merge" {
    write_settings '{"model":"opus"}'
    cp "$HOME/.claude/settings.json" "$BATS_TEST_TMPDIR/before.json"
    echo stale > "$HOME/.claude/settings.json.bak"
    chmod 444 "$HOME/.claude/settings.json.bak"

    run_script "$REPO_DIR/install.sh" --only-claude --no-verify

    [ "$status" -ne 0 ]
    grep -q "Could not back up" <<< "$output"
    cmp -s "$BATS_TEST_TMPDIR/before.json" "$HOME/.claude/settings.json"
}

@test "agents deleted from the repo are removed and local agents are kept" {
    local retired
    retired="$(retired_agent)"
    [ -n "$retired" ] || skip "no deleted agents in the git history (shallow clone?)"
    mkdir -p "$HOME/.claude/agents"
    echo old > "$HOME/.claude/agents/$retired"
    echo mine > "$HOME/.claude/agents/my-local.md"

    run_script "$REPO_DIR/install.sh" --only-claude --no-verify

    [ "$status" -eq 0 ]
    [ ! -e "$HOME/.claude/agents/$retired" ]
    [ -f "$HOME/.claude/agents/my-local.md" ]
}

@test "the health check runs after an install" {
    run_script "$REPO_DIR/install.sh" --only-claude

    [ "$status" -eq 0 ]
    grep -q "Running post-installation verification" <<< "$output"
}

@test "--no-verify skips the health check" {
    run_script "$REPO_DIR/install.sh" --only-claude --no-verify

    [ "$status" -eq 0 ]
    refute_output_matches "Running post-installation verification"
}

@test "a dry run skips the health check" {
    run_script "$REPO_DIR/install.sh" --dry-run --only-claude

    [ "$status" -eq 0 ]
    refute_output_matches "Running post-installation verification"
}

@test "a failed config step is counted and the next steps still run" {
    echo "local style" > "$HOME/.swiftformat"
    chmod 444 "$HOME/.swiftformat"

    run_script "$REPO_DIR/install.sh" --only-swiftformat-config --only-claude --no-verify

    [ "$status" -eq 1 ]
    grep -q "1 step(s) failed" <<< "$output"
    [ -f "$HOME/.claude/CLAUDE.md" ]
}
