#!/usr/bin/env bats

load test_helper

# A bare origin and a clone of it on main, both built from the working tree, so update.sh can pull
make_fake_origin() {
    GIT_DIR_ROOT="$BATS_TEST_TMPDIR/git"
    mkdir -p "$GIT_DIR_ROOT/src"
    rsync -a --exclude .git --exclude .codegraph "$REPO_DIR/" "$GIT_DIR_ROOT/src/"
    git -C "$GIT_DIR_ROOT/src" init -q -b main
    git -C "$GIT_DIR_ROOT/src" add -A
    commit_src "initial"
    git init -q --bare "$GIT_DIR_ROOT/origin.git"
    push_src
    git clone -q --branch main "$GIT_DIR_ROOT/origin.git" "$GIT_DIR_ROOT/local"
    LOCAL_REPO="$GIT_DIR_ROOT/local"
    # The restart tests run the font step, which installs the font when it is missing
    fake_brew
}

commit_src() { git -C "$GIT_DIR_ROOT/src" -c user.name=test -c user.email=test@example.com commit -qam "$1"; }
push_src() { git -C "$GIT_DIR_ROOT/src" push -q "$GIT_DIR_ROOT/origin.git" main; }

# Pushes a commit whose update.sh prints $1 in its font step, to tell which version ran
push_update_with_marker() {
    sed -i.orig "s/^update_font() {\$/update_font() {\\
    echo \"$1\"/" "$GIT_DIR_ROOT/src/update.sh"
    rm "$GIT_DIR_ROOT/src/update.sh.orig"
    commit_src "$1"
    push_src
}

@test "update.sh --config merges the Claude settings" {
    write_settings '{"model":"opus","permissions":{"ask":["Bash(rm -rf:*)"]}}'

    run_script "$REPO_DIR/update.sh" --config

    [ "$status" -eq 0 ]
    [ "$(jq -c .permissions.ask "$HOME/.claude/settings.json")" = "$(jq -c .permissions.ask "$REPO_DIR/claude/settings.json")" ]
    [ "$(jq -r .model "$HOME/.claude/settings.json")" = opus ]
    grep -q "Update completed successfully" <<< "$output"
}

@test "update.sh --check changes nothing" {
    write_settings '{"model":"opus"}'
    cp "$HOME/.claude/settings.json" "$BATS_TEST_TMPDIR/before.json"

    run_script "$REPO_DIR/update.sh" --check --config

    [ "$status" -eq 0 ]
    grep -q "Merge shared keys" <<< "$output"
    cmp -s "$BATS_TEST_TMPDIR/before.json" "$HOME/.claude/settings.json"
    [ ! -e "$HOME/.claude/CLAUDE.md" ]
}

@test "a write that fails is reported and counted as a failure" {
    mkdir -p "$HOME/.claude"
    echo old > "$HOME/.claude/CLAUDE.md"
    chmod 444 "$HOME/.claude/CLAUDE.md"

    run_script "$REPO_DIR/update.sh" --config

    [ "$status" -eq 1 ]
    grep -q "Could not update CLAUDE.md" <<< "$output"
    refute_output_matches "Update completed successfully"
    refute_output_matches "Error: Command failed"
}

@test "a pull with new commits restarts into the new update.sh" {
    make_fake_origin
    push_update_with_marker NEW_VERSION

    run_script "$LOCAL_REPO/update.sh" --repo --font

    [ "$status" -eq 0 ]
    grep -q "Restarting with the updated update.sh" <<< "$output"
    grep -q "Repository updated from" <<< "$output"
    grep -q NEW_VERSION <<< "$output"
    [ "$(grep -c 'Configuration Update Script' <<< "$output")" -eq 1 ]
}

@test "no restart when only the repo step runs" {
    make_fake_origin
    push_update_with_marker NEW_VERSION

    run_script "$LOCAL_REPO/update.sh" --repo

    [ "$status" -eq 0 ]
    refute_output_matches "Restarting"
    [ "$(git -C "$LOCAL_REPO" rev-parse HEAD)" = "$(git -C "$GIT_DIR_ROOT/origin.git" rev-parse main)" ]
}

@test "a stale restart marker falls back to a normal pull" {
    make_fake_origin
    push_update_with_marker NEW_VERSION

    MY_CONFIG_UPDATE_RESTARTED_FROM=deadbeef run_script "$LOCAL_REPO/update.sh" --repo --font

    [ "$status" -eq 0 ]
    grep -q "Pulling latest changes" <<< "$output"
    [ "$(git -C "$LOCAL_REPO" rev-parse HEAD)" = "$(git -C "$GIT_DIR_ROOT/origin.git" rev-parse main)" ]
}

@test "a restart marker naming the current commit falls back to a normal pull" {
    make_fake_origin
    push_update_with_marker NEW_VERSION

    MY_CONFIG_UPDATE_RESTARTED_FROM="$(git -C "$LOCAL_REPO" rev-parse HEAD)" run_script "$LOCAL_REPO/update.sh" --repo --font

    [ "$status" -eq 0 ]
    grep -q "Pulling latest changes" <<< "$output"
    [ "$(git -C "$LOCAL_REPO" rev-parse HEAD)" = "$(git -C "$GIT_DIR_ROOT/origin.git" rev-parse main)" ]
}

@test "update.sh renamed by the pull: warns and finishes the run" {
    make_fake_origin
    git -C "$GIT_DIR_ROOT/src" mv update.sh update-all.sh
    commit_src rename
    push_src

    run_script "$LOCAL_REPO/update.sh" --repo --font

    [ "$status" -eq 0 ]
    grep -q "update.sh not found after the pull" <<< "$output"
    grep -q "Update completed" <<< "$output"
}
