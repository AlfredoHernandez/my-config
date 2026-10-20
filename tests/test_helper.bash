# Every test gets its own fake HOME, so the scripts run for real without touching the machine.
# Tests that write into the repo (sync.sh) or pull it (update.sh) work on a copy of it.

REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

# Test files that define their own setup must call this first
sandbox_home() {
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    [[ $HOME == "$BATS_TEST_TMPDIR"/* ]] || { echo "HOME is not sandboxed" >&2; return 1; }

    # Git hooks export these, and they would point the tests' git commands at the real repo
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR
    unset MY_CONFIG_UPDATE_RESTARTED_FROM
    export XDG_CONFIG_HOME="$HOME/.config" GIT_CONFIG_NOSYSTEM=1

    # Homebrew and the font download are system-wide or networked: stubs log the call and fail
    STUB_LOG="$BATS_TEST_TMPDIR/stub-calls.log"
    mkdir -p "$BATS_TEST_TMPDIR/bin"
    local tool
    for tool in brew curl; do
        printf '#!/bin/bash\necho "%s $*" >> "%s"\nexit 1\n' "$tool" "$STUB_LOG" > "$BATS_TEST_TMPDIR/bin/$tool"
        chmod +x "$BATS_TEST_TMPDIR/bin/$tool"
    done
    export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

setup() {
    sandbox_home
}

# Read-only brew calls (the health check's) are fine; anything that changes the system is not
teardown() {
    if grep -qE '^brew (install|upgrade|uninstall|reinstall|tap)|^brew bundle( install| --|$)|^curl' "$STUB_LOG" 2>/dev/null; then
        echo "a system-wide step ran:" >&2
        cat "$STUB_LOG" >&2
        return 1
    fi
}

# Replaces the failing brew stub with one that succeeds and logs to $BREW_LOG, which teardown
# doesn't check. The arguments are the installed formulae as "name version" lines; installed
# casks go one per line in $BREW_CASKS
fake_brew() {
    BREW_LOG="$BATS_TEST_TMPDIR/brew.log"
    BREW_CASKS="$BATS_TEST_TMPDIR/brew-casks"
    local formulae="$BATS_TEST_TMPDIR/brew-formulae"
    printf '%s\n' "$@" > "$formulae"
    touch "$BREW_LOG" "$BREW_CASKS"
    cat > "$BATS_TEST_TMPDIR/bin/brew" <<EOF
#!/bin/bash
echo "brew \$*" >> "$BREW_LOG"
case "\$1 \$2" in
    "list --formula") cat "$formulae" ;;
    "list --cask") cat "$BREW_CASKS" ;;
esac
exit 0
EOF
}

# Like bats' run, with stderr merged into $output and colors removed
run_script() {
    run bash -c '"$@" 2>&1 | sed -E "s/\x1b\[[0-9;]*m//g"; exit "${PIPESTATUS[0]}"' _ "$@"
}

write_settings() {
    mkdir -p "$HOME/.claude"
    printf '%s\n' "$1" > "$HOME/.claude/settings.json"
}

# Copies the working tree with its git history, and commits any uncommitted changes in the copy,
# so `git status` there shows only what the test changed
copy_repo() {
    local dest="$BATS_TEST_TMPDIR/repo"
    git clone -q --no-hardlinks "$REPO_DIR" "$dest"
    rsync -a --exclude .git --exclude .codegraph "$REPO_DIR/" "$dest/"
    git -C "$dest" add -A
    git -C "$dest" -c user.name=test -c user.email=test@example.com -c core.hooksPath=/dev/null \
        commit -qm "working tree" --allow-empty
    echo "$dest"
}

# First agent the repo once shipped and later deleted; empty in a shallow clone
retired_agent() {
    source "$REPO_DIR/lib/retired-entries.sh"
    retired_repo_entries "$REPO_DIR" claude/agents | head -1
}

count_files() {
    find "$1" -maxdepth 1 -type f -name "$2" | wc -l | tr -d ' '
}

# A plain `! grep` never fails a bats test, because set -e ignores negated commands
# shellcheck disable=SC2154  # bats' run assigns $output
refute_output_matches() {
    if grep -qE "$1" <<< "$output"; then
        echo "output should not match: $1" >&2
        return 1
    fi
}

refute_brew_called() {
    if grep -qE "$1" "$BREW_LOG"; then
        echo "brew should not have been called with: $1" >&2
        cat "$BREW_LOG" >&2
        return 1
    fi
}
