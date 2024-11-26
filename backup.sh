#!/bin/bash

USER="$(whoami)"
XC_DIR="/Users/$USER/Library/Developer/Xcode"
XC_USER_DATA="/Users/$USER/Library/Developer/Xcode/UserData"

mkdir -p "./backup"
DEST="./backup"

cp "$XC_USER_DATA"/FontAndColorThemes/*.xccolortheme "$DEST"
cp "$XC_USER_DATA"/IDETemplateMacros.plist "$DEST"
cp -r "$XC_DIR"/Templates/ "$DEST"
# cp "$XC_USER_DATA"/KeyBindings/*.idekeybindings "$DEST"
# cp "$XC_USER_DATA"/xcdebugger/Breakpoints_v2.xcbkptlist "$DEST"