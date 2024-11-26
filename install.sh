#!/bin/bash

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="$XC_DIR/UserData"


# XCode templates
echo "[*] Installing XCode templates"
XC_TEMPLATES_DIR="$XC_DIR/Templates"
mkdir -p $XC_TEMPLATES_DIR
cp -r Templates/ $XC_TEMPLATES_DIR
echo "[*] XCode templates installed successfully"

# Xcode themes
echo "[*] Installing XCode themes"
THEMES_DIR="$XC_USER_DATA/FontAndColorThemes/"
mkdir -p $THEMES_DIR
cp Themes/*.xccolortheme $THEMES_DIR
echo "[*] XCode Themes installed successfully"

# Xcode Header
echo '[*] Installing header template'
cp ./Headers/IDETemplateMacros.plist "$XC_USER_DATA"
echo "[*] XCode header template installed successfully"