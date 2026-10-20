#!/bin/bash
# Shared by install.sh, update.sh, sync.sh and health-check.sh. Agents and skills deleted from
# the repo are read from git history, so every Mac removes them on its next install or update
# without a hand-kept list. Outside a git checkout it prints nothing.

# Prints the top-level names under <subdir> (e.g. claude/agents) that the repo once shipped
# and no longer has. Renames count as deletions, so the old name is retired too.
retired_repo_entries() {
    local repo_dir="$1"
    local subdir="$2"
    local name

    git -C "$repo_dir" log --no-renames --diff-filter=D --name-only --pretty=format: -- "$subdir" 2>/dev/null |
        sed -n "s|^$subdir/\([^/]*\).*|\1|p" |
        sort -u |
        while read -r name; do
            [[ -e "$repo_dir/$subdir/$name" ]] || echo "$name"
        done
}
