#!/bin/bash
# Copies the repo's configuration to the system. Shared by install.sh and update.sh so both
# apply exactly the same files. Callers must source lib/common.sh and define REPO_DIR,
# DRY_RUN (true/false) and these reporters:
#   report_unchanged  already matches the repo
#   report_changed    installed, updated or removed
#   report_planned    what DRY_RUN would change
#   report_warning    a step that was skipped on purpose
#   report_failure    a step that failed; the function then returns 1
# Every write is checked because update.sh runs without set -e.
# Requires lib/claude-settings.sh and lib/retired-entries.sh.

install_or_update_file() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [[ ! -f "$src" ]]; then
        report_failure "$label source not found: $src"
        return 1
    fi

    if [[ -f "$dest" ]] && diff -q "$src" "$dest" &>/dev/null; then
        report_unchanged "$label already up to date"
    elif $DRY_RUN; then
        [[ -f "$dest" ]] && report_planned "Update $label" || report_planned "Install $label"
    elif [[ -f "$dest" ]]; then
        if ! cp "$src" "$dest"; then
            report_failure "Could not update $label"
            return 1
        fi
        report_changed "$label updated"
    else
        if ! { mkdir -p "$(dirname "$dest")" && cp "$src" "$dest"; }; then
            report_failure "Could not install $label"
            return 1
        fi
        report_changed "$label installed"
    fi
}

install_or_update_dir() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [[ ! -d "$src" ]]; then
        report_failure "$label source not found: $src"
        return 1
    fi

    $DRY_RUN || mkdir -p "$dest"
    local file name
    for file in "$src"/*; do
        name="$(basename "$file")"
        if [[ -d "$file" ]]; then
            install_or_update_dir "$file" "$dest/$name" "$label/$name"
        else
            install_or_update_file "$file" "$dest/$name" "$label: $name"
        fi
    done
}

remove_retired_entries() {
    local subdir="$1"
    local dest="$2"
    local label="$3"
    local name

    while read -r name; do
        [[ -e "$dest/$name" ]] || continue
        if $DRY_RUN; then
            report_planned "Remove $label deleted from the repo: $name"
        elif rm -rf "${dest:?}/${name:?}"; then
            report_changed "Removed $label deleted from the repo: $name"
        else
            report_failure "Could not remove $label deleted from the repo: $name"
        fi
    done < <(retired_repo_entries "$REPO_DIR" "$subdir")
}

install_swiftformat_config() {
    print_header "SwiftFormat Configuration"
    install_or_update_file "$REPO_DIR/config/swiftformat.txt" "$HOME/.swiftformat" "SwiftFormat configuration"
}

install_claude_config() {
    print_header "Claude Code Configuration"
    install_or_update_file "$REPO_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md" "CLAUDE.md"
}

install_claude_settings() {
    print_header "Claude Code Settings"
    local src="$REPO_DIR/claude/settings.json"
    local dest="$HOME/.claude/settings.json"

    if [[ ! -f "$dest" ]]; then
        install_or_update_file "$src" "$dest" "Claude settings"
        return
    fi

    if ! command -v jq &>/dev/null; then
        report_warning "jq not found: skipping Claude settings merge (brew install jq)"
        return
    fi

    if ! jq empty "$dest" "$src" 2>/dev/null; then
        report_warning "Invalid JSON in Claude settings: skipping merge (fix $dest)"
        return
    fi

    # Created next to the destination so the final mv is an atomic replace
    local merged
    merged="$(mktemp "$dest.XXXXXX")"
    if ! claude_settings_merge_owned "$dest" "$src" > "$merged"; then
        report_failure "Claude settings merge failed"
        rm -f "$merged"
        return 1
    fi

    if claude_settings_equal "$merged" "$dest"; then
        report_unchanged "Claude settings already up to date"
        rm -f "$merged"
        return
    fi

    local replaced
    replaced="$(claude_settings_replaced_values "$dest" "$src")"
    if $DRY_RUN; then
        report_planned "Merge shared keys into Claude settings (local keys are kept)"
        print_replaced_settings "$replaced" "would be replaced"
        rm -f "$merged"
        return
    fi

    if ! cp "$dest" "$dest.bak"; then
        report_failure "Could not back up $dest: skipping Claude settings merge"
        rm -f "$merged"
        return 1
    fi
    if ! mv "$merged" "$dest"; then
        report_failure "Could not write $dest"
        rm -f "$merged"
        return 1
    fi
    report_changed "Claude settings merged (backup: $dest.bak)"
    print_replaced_settings "$replaced" "replaced, kept in the backup"
}

print_replaced_settings() {
    local replaced="$1"
    local outcome="$2"

    [[ -n "$replaced" ]] || return 0
    print_info "Local values of shared keys $outcome:"
    sed 's/^/      /' <<< "$replaced"
}

install_claude_agents() {
    print_header "Claude Agents Installation"
    install_or_update_dir "$REPO_DIR/claude/agents" "$HOME/.claude/agents" "Agent"
    remove_retired_entries "claude/agents" "$HOME/.claude/agents" "Agent"
}

# Each skill is a directory owned by the repo, so it is synced as a whole tree and files
# deleted from the repo are deleted from the installed copy too
install_claude_skills() {
    print_header "Claude Skills Installation"
    local src="$REPO_DIR/claude/skills"
    local dest="$HOME/.claude/skills"

    remove_retired_entries "claude/skills" "$dest" "Skill"
    if [[ ! -d "$src" ]]; then
        print_info "No skills in this repo"
        return 0
    fi

    local skill name
    for skill in "$src"/*/; do
        [[ -d "$skill" ]] || continue
        name="$(basename "$skill")"
        if diff -rq -x __pycache__ -x .DS_Store "$skill" "$dest/$name" &>/dev/null; then
            report_unchanged "Skill: $name already up to date"
        elif $DRY_RUN; then
            report_planned "Sync skill: $name"
        elif mkdir -p "$dest" && rsync -a --delete --exclude __pycache__ --exclude .DS_Store "$skill" "$dest/$name/"; then
            report_changed "Skill: $name synced"
        else
            report_failure "Could not sync skill: $name"
        fi
    done
}

install_custom_scripts() {
    print_header "Custom Scripts Installation"
    local bin_dir="$HOME/Developer/bin"
    local script name

    for script in "$REPO_DIR"/scripts/*.sh; do
        name="$(basename "$script")"
        install_or_update_file "$script" "$bin_dir/$name" "Script: $name"
        $DRY_RUN || chmod +x "$bin_dir/$name"
    done
}

install_xcode_templates() {
    print_header "Xcode Templates Installation"
    install_or_update_dir "$REPO_DIR/Templates" "$XC_DIR/Templates" "Template"
}

install_xcode_themes() {
    print_header "Xcode Themes Installation"
    local dest="$XC_USER_DATA/FontAndColorThemes"
    local theme name

    for theme in "$REPO_DIR"/Themes/*.xccolortheme; do
        name="$(basename "$theme")"
        install_or_update_file "$theme" "$dest/$name" "Theme: $name"
    done
}

install_xcode_header() {
    print_header "Xcode Header Template"
    install_or_update_file "$REPO_DIR/Headers/IDETemplateMacros.plist" "$XC_USER_DATA/IDETemplateMacros.plist" "Header template"
}
