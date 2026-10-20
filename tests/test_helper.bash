# Every test gets its own fake HOME, so the scripts run for real without touching the machine.
# Tests that write into the repo (sync.sh) or pull it (update.sh) work on a copy of it.

REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
export HOMEBREW_NO_AUTO_UPDATE=1

setup() {
    export HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$HOME"
    unset MY_CONFIG_UPDATE_RESTARTED_FROM
}

# Like bats' run, with stderr merged into $output and colors removed
run_script() {
    run bash -c '"$@" 2>&1 | sed -E "s/\x1b\[[0-9;]*m//g"; exit "${PIPESTATUS[0]}"' _ "$@"
}

write_settings() {
    mkdir -p "$HOME/.claude"
    printf '%s\n' "$1" > "$HOME/.claude/settings.json"
}

# Copies the working tree, uncommitted changes and git history included
copy_repo() {
    local dest="$BATS_TEST_TMPDIR/repo"
    rsync -a --exclude .codegraph "$REPO_DIR/" "$dest/"
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
