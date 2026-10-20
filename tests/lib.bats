#!/usr/bin/env bats

load test_helper

setup() {
    sandbox_home
    source "$REPO_DIR/lib/claude-settings.sh"
    source "$REPO_DIR/lib/retired-entries.sh"
    cd "$BATS_TEST_TMPDIR" || return 1
    cat > repo.json <<'EOF'
{
  "attribution": {"commit": ""},
  "permissions": {"allow": ["Bash"], "ask": ["Bash(git push --force:*)"]},
  "enabledPlugins": {"shared@market": true}
}
EOF
    cat > local.json <<'EOF'
{
  "model": "opus",
  "hooks": {"Stop": []},
  "permissions": {"allow": ["Bash", "Bash(local:*)"], "deny": ["Read(.env)"], "defaultMode": "auto"},
  "enabledPlugins": {"local-only@market": true}
}
EOF
}

@test "merge takes shared keys from the repo and keeps local keys" {
    claude_settings_merge_owned local.json repo.json > merged.json

    [ "$(jq -c .permissions.allow merged.json)" = '["Bash"]' ]
    [ "$(jq -c .permissions.ask merged.json)" = '["Bash(git push --force:*)"]' ]
    [ "$(jq -c .attribution merged.json)" = '{"commit":""}' ]
    [ "$(jq -r .model merged.json)" = opus ]
    [ "$(jq -c .permissions.deny merged.json)" = '["Read(.env)"]' ]
    [ "$(jq -r .permissions.defaultMode merged.json)" = auto ]
    [ "$(jq -c .hooks merged.json)" = '{"Stop":[]}' ]
}

@test "merge adds the repo's plugins and keeps plugins enabled only on this machine" {
    claude_settings_merge_owned local.json repo.json > merged.json

    [ "$(jq -c '.enabledPlugins | keys' merged.json)" = '["local-only@market","shared@market"]' ]
}

@test "the subset copied back to the repo has only shared keys and repo-listed plugins" {
    claude_settings_owned_subset local.json repo.json > subset.json

    [ "$(jq -c 'keys' subset.json)" = '["permissions"]' ]
    [ "$(jq -c '.permissions | keys' subset.json)" = '["allow"]' ]
}

@test "replaced values lists local shared values the repo doesn't have" {
    run claude_settings_replaced_values local.json repo.json

    [ "$status" -eq 0 ]
    [ "$output" = 'permissions.allow[]: "Bash(local:*)"' ]
}

@test "replaced values reports a value that the merge moves to another key" {
    jq '.permissions.allow = ["Bash(git push --force:*)"] | .permissions.ask = ["Bash"]' repo.json > swapped.json

    run claude_settings_replaced_values swapped.json repo.json

    [ "$status" -eq 0 ]
    grep -qxF 'permissions.ask[]: "Bash"' <<< "$output"
    grep -qxF 'permissions.allow[]: "Bash(git push --force:*)"' <<< "$output"
}

@test "replaced values is empty when the installed file has no shared keys" {
    echo '{"model":"opus"}' > no-shared.json

    run claude_settings_replaced_values no-shared.json repo.json

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "replaced values ignores a value that only moved within a list" {
    jq '.permissions.allow = ["Bash(other:*)", "Bash"]' repo.json > reordered.json
    jq '.permissions.allow = ["Bash", "Bash(other:*)"]' repo.json > local-reordered.json

    run claude_settings_replaced_values local-reordered.json reordered.json

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "retired entries are empty outside a git checkout" {
    mkdir -p not-a-repo/claude/agents

    run retired_repo_entries "$BATS_TEST_TMPDIR/not-a-repo" claude/agents

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "retired entries never list an entry that is still in the repo" {
    run retired_repo_entries "$REPO_DIR" claude/agents

    [ "$status" -eq 0 ]
    local name
    for name in $output; do
        [ ! -e "$REPO_DIR/claude/agents/$name" ]
    done
}
