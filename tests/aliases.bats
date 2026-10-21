#!/usr/bin/env bats

load test_helper

# A clone with three branches: "merged" was pushed and its remote branch deleted, as GitHub does
# after a squash merge; "open" is still on the remote; "local" was never pushed
setup() {
    sandbox_home
    git config --global user.name test
    git config --global user.email test@example.com
    git config --global init.defaultBranch main

    git init -q --bare "$BATS_TEST_TMPDIR/origin.git"
    CLONE="$BATS_TEST_TMPDIR/clone"
    git clone -q "$BATS_TEST_TMPDIR/origin.git" "$CLONE" 2>/dev/null
    git -C "$CLONE" commit -q --allow-empty -m initial
    git -C "$CLONE" push -q -u origin main

    local branch
    for branch in merged open; do
        git -C "$CLONE" checkout -q -b "$branch" main
        git -C "$CLONE" commit -q --allow-empty -m "$branch"
        git -C "$CLONE" push -q -u origin "$branch"
    done
    git -C "$CLONE" checkout -q -b local main
    git -C "$CLONE" checkout -q main
    git -C "$BATS_TEST_TMPDIR/origin.git" branch -q -D merged
}

run_cleanup() {
    run bash -c 'cd "$1" && echo "$2" | zsh -fc "source \"\$0\"; cleanup" "$3" 2>&1' _ \
        "$CLONE" "$1" "$REPO_DIR/config/aliases.zsh"
}

branches() {
    git -C "$CLONE" for-each-ref --format='%(refname:short)' refs/heads | paste -sd ' ' -
}

@test "cleanup deletes the branches whose remote branch is gone, after confirming" {
    run_cleanup y

    [ "$status" -eq 0 ]
    grep -q "merged" <<< "$output"
    [ "$(branches)" = "local main open" ]
}

@test "cleanup deletes nothing without confirmation" {
    run_cleanup n

    [ "$status" -eq 0 ]
    [ "$(branches)" = "local main merged open" ]
}

@test "cleanup keeps the current branch even when its remote branch is gone" {
    git -C "$CLONE" checkout -q merged

    run_cleanup y

    [ "$status" -eq 0 ]
    grep -q "No local branches" <<< "$output"
    [ "$(branches)" = "local main merged open" ]
}

@test "cleanup keeps a branch checked out in another worktree" {
    git -C "$CLONE" worktree add -q "$BATS_TEST_TMPDIR/worktree" merged

    run_cleanup y

    [ "$status" -eq 0 ]
    grep -q "No local branches" <<< "$output"
    [ "$(branches)" = "local main merged open" ]
}
