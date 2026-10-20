#!/usr/bin/env bats

load test_helper

setup() {
    sandbox_home
    REPO_COPY="$(copy_repo)"
    "$REPO_COPY/install.sh" --only-claude --no-verify >/dev/null 2>&1
}

@test "nothing is copied back right after an install" {
    run_script "$REPO_COPY/sync.sh"

    [ "$status" -eq 0 ]
    grep -qE "Updated: +0" <<< "$output"
    [ -z "$(git -C "$REPO_COPY" status --porcelain -- claude)" ]
}

@test "an installed agent edited later is copied back" {
    echo "local edit" >> "$HOME/.claude/agents/code-review.md"

    run_script "$REPO_COPY/sync.sh"

    [ "$status" -eq 0 ]
    tail -1 "$REPO_COPY/claude/agents/code-review.md" | grep -q "local edit"
}

@test "a repo file newer than its installed copy is not overwritten" {
    echo "older installed copy" > "$HOME/.claude/agents/code-review.md"
    touch -t 200001010000 "$HOME/.claude/agents/code-review.md"
    echo "newer repo edit" >> "$REPO_COPY/claude/agents/code-review.md"

    run_script "$REPO_COPY/sync.sh"

    [ "$status" -eq 0 ]
    grep -q "repo copy is newer" <<< "$output"
    tail -1 "$REPO_COPY/claude/agents/code-review.md" | grep -q "newer repo edit"
}

@test "an agent deleted from the repo is not copied back" {
    local retired
    retired="$(retired_agent)"
    [ -n "$retired" ] || skip "no deleted agents in the git history (shallow clone?)"
    echo old > "$HOME/.claude/agents/$retired"

    run_script "$REPO_COPY/sync.sh"

    [ "$status" -eq 0 ]
    grep -q "$retired (deleted from the repo" <<< "$output"
    [ ! -e "$REPO_COPY/claude/agents/$retired" ]
}

@test "invalid installed settings are not copied back" {
    printf '{"model":"opus",}\n' > "$HOME/.claude/settings.json"

    run_script "$REPO_COPY/sync.sh"

    [ "$status" -eq 0 ]
    grep -q "settings.json (shared keys) (invalid JSON)" <<< "$output"
    [ -z "$(git -C "$REPO_COPY" status --porcelain -- claude/settings.json)" ]
}
