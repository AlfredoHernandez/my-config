#!/bin/bash
# Shared by install.sh and sync.sh. The repo owns only these keys of
# ~/.claude/settings.json; everything else (hooks, autoMode, preferences) stays machine-local.
CLAUDE_SETTINGS_OWNED_PATHS='[
  ["env", "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"],
  ["attribution"],
  ["permissions", "allow"],
  ["permissions", "ask"]
]'

# For these objects the repo owns only the entries it lists, so plugins enabled on a single
# machine survive install.sh and are not copied back by sync.sh.
CLAUDE_SETTINGS_OWNED_ENTRY_PATHS='[
  ["enabledPlugins"],
  ["extraKnownMarketplaces"]
]'

claude_settings_owned_subset() {
    local installed="$1" repo="$2"
    jq -s --argjson paths "$CLAUDE_SETTINGS_OWNED_PATHS" \
          --argjson entry_paths "$CLAUDE_SETTINGS_OWNED_ENTRY_PATHS" '
        .[0] as $in
        | .[1] as $repo
        | reduce $paths[] as $path ({};
            ($in | getpath($path)) as $value
            | if $value == null then . else setpath($path; $value) end)
        | reduce $entry_paths[] as $path (.;
            ($repo | getpath($path) // {} | keys) as $tracked
            | ($in | getpath($path) // {}
                | with_entries(select(.key as $key | any($tracked[]; . == $key)))) as $value
            | if $value == {} then . else setpath($path; $value) end)
    ' "$installed" "$repo"
}

claude_settings_merge_owned() {
    local base="$1" owner="$2"
    jq -s --argjson paths "$CLAUDE_SETTINGS_OWNED_PATHS" \
          --argjson entry_paths "$CLAUDE_SETTINGS_OWNED_ENTRY_PATHS" '
        .[1] as $owner
        | reduce $paths[] as $path (.[0];
            ($owner | getpath($path)) as $value
            | if $value == null then delpaths([$path]) else setpath($path; $value) end)
        | reduce $entry_paths[] as $path (.;
            ($owner | getpath($path)) as $value
            | if $value == null then . else setpath($path; (getpath($path) // {}) + $value) end)
    ' "$base" "$owner"
}

claude_settings_equal() {
    [[ "$(jq -S . "$1")" == "$(jq -S . "$2")" ]]
}
