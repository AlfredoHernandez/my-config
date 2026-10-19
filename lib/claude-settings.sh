#!/bin/bash
# Shared by install.sh and sync.sh. The repo owns only these keys of
# ~/.claude/settings.json; everything else (hooks, autoMode, preferences) stays machine-local.
CLAUDE_SETTINGS_OWNED_PATHS='[
  ["attribution"],
  ["permissions", "allow"],
  ["permissions", "ask"],
  ["enabledPlugins"],
  ["extraKnownMarketplaces"]
]'

claude_settings_owned_subset() {
    jq --argjson paths "$CLAUDE_SETTINGS_OWNED_PATHS" '
        . as $in
        | reduce $paths[] as $path ({};
            ($in | getpath($path)) as $value
            | if $value == null then . else setpath($path; $value) end)
    ' "$1"
}

claude_settings_merge_owned() {
    local base="$1" owner="$2"
    jq -s --argjson paths "$CLAUDE_SETTINGS_OWNED_PATHS" '
        .[1] as $owner
        | reduce $paths[] as $path (.[0];
            ($owner | getpath($path)) as $value
            | if $value == null then delpaths([$path]) else setpath($path; $value) end)
    ' "$base" "$owner"
}

claude_settings_equal() {
    [[ "$(jq -S . "$1")" == "$(jq -S . "$2")" ]]
}
