#!/usr/bin/env bats

load test_helper

BREWFILE_INSTALL="bundle install --file=$REPO_DIR/Brewfile"
FONT_CASK=font-jetbrains-mono-nerd-font

install_font_by_hand() {
    mkdir -p "$HOME/Library/Fonts"
    touch "$HOME/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf"
}

@test "the Brewfile formulae are read without calling brew" {
    source "$REPO_DIR/lib/common.sh"
    printf '%s\n' '# tools' 'brew "jq"' 'brew "eza", args: ["HEAD"]' 'cask "some-app"' > "$BATS_TEST_TMPDIR/Brewfile"

    run brewfile_formulae "$BATS_TEST_TMPDIR/Brewfile"

    [ "$output" = "$(printf 'jq\neza')" ]
}

@test "the repo Brewfile has jq, eza, swiftformat and herdr" {
    source "$REPO_DIR/lib/common.sh"

    run brewfile_formulae "$REPO_DIR/Brewfile"

    [ "$output" = "$(printf 'jq\neza\nswiftformat\nherdr')" ]
}

@test "install runs the Brewfile when a package is missing" {
    fake_brew "eza 0.23.0"

    run_script "$REPO_DIR/install.sh" --only-tools --no-verify

    [ "$status" -eq 0 ]
    grep -q "jq swiftformat" <<< "$output"
    grep -qxF "brew $BREWFILE_INSTALL --no-upgrade" "$BREW_LOG"
}

@test "install skips the Brewfile when every package is installed" {
    fake_brew "jq 1.8.1" "eza 0.23.0" "swiftformat 0.58.0" "herdr 0.9.5"

    run_script "$REPO_DIR/install.sh" --only-tools --no-verify

    [ "$status" -eq 0 ]
    grep -q "Brewfile packages already installed" <<< "$output"
    refute_brew_called "bundle"
}

@test "an install dry run lists the missing packages" {
    run_script "$REPO_DIR/install.sh" --dry-run --only-tools

    [ "$status" -eq 0 ]
    grep -q "Would: Install from the Brewfile: jq eza swiftformat herdr" <<< "$output"
}

@test "install gets the font from its Homebrew cask" {
    fake_brew

    run_script "$REPO_DIR/install.sh" --only-font --no-verify

    [ "$status" -eq 0 ]
    grep -qxF "brew install --cask $FONT_CASK" "$BREW_LOG"
}

@test "install keeps a font installed by hand" {
    fake_brew
    install_font_by_hand

    run_script "$REPO_DIR/install.sh" --only-font --no-verify

    [ "$status" -eq 0 ]
    grep -q "JetBrains Mono Nerd Font already installed" <<< "$output"
    refute_brew_called "cask"
}

@test "update upgrades the Brewfile packages and installs the missing ones" {
    fake_brew "jq 1.8.1"

    run_script "$REPO_DIR/update.sh" --tools

    [ "$status" -eq 0 ]
    grep -qxF "brew update --quiet" "$BREW_LOG"
    grep -qxF "brew $BREWFILE_INSTALL --upgrade" "$BREW_LOG"
}

@test "update --check lists the missing packages and changes nothing" {
    fake_brew "jq 1.8.1"

    run_script "$REPO_DIR/update.sh" --check --tools

    [ "$status" -eq 0 ]
    grep -q "eza not installed" <<< "$output"
    grep -q "swiftformat not installed" <<< "$output"
    refute_brew_called "bundle|upgrade|brew update"
}

@test "update upgrades the font cask" {
    fake_brew
    install_font_by_hand
    echo "$FONT_CASK" > "$BREW_CASKS"

    run_script "$REPO_DIR/update.sh" --font

    [ "$status" -eq 0 ]
    grep -qxF "brew upgrade --cask $FONT_CASK" "$BREW_LOG"
}

@test "update leaves a font installed by hand alone" {
    fake_brew
    install_font_by_hand

    run_script "$REPO_DIR/update.sh" --font

    [ "$status" -eq 0 ]
    grep -q "installed by hand" <<< "$output"
    refute_brew_called "upgrade"
}

@test "the health check reports each Brewfile package" {
    fake_brew "jq 1.8.1" "eza 0.23.0"

    run_script "$REPO_DIR/health-check.sh"

    grep -q "jq installed (1.8.1)" <<< "$output"
    grep -q "eza installed (0.23.0)" <<< "$output"
    grep -q "swiftformat not installed" <<< "$output"
}

@test "uninstall removes only the installed Brewfile packages" {
    fake_brew "jq 1.8.1" "git 2.51.0"

    run_script "$REPO_DIR/uninstall.sh" --tools --force

    [ "$status" -eq 0 ]
    grep -qxF "brew uninstall jq" "$BREW_LOG"
    refute_brew_called "uninstall (git|eza|swiftformat)"
}

@test "uninstall removes the font through its cask" {
    fake_brew
    install_font_by_hand
    echo "$FONT_CASK" > "$BREW_CASKS"

    run_script "$REPO_DIR/uninstall.sh" --font --force

    [ "$status" -eq 0 ]
    grep -qxF "brew uninstall --cask $FONT_CASK" "$BREW_LOG"
}

@test "install ends with an error when a step fails" {
    fake_brew
    sed -i '' 's/^exit 0$/exit 1/' "$BATS_TEST_TMPDIR/bin/brew"

    run_script "$REPO_DIR/install.sh" --only-font --no-verify

    [ "$status" -eq 1 ]
    grep -q "1 step(s) failed" <<< "$output"
    refute_output_matches "installed successfully"
}
