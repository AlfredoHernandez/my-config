#!/bin/bash

# Verify that a parameter was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <deeplink>"
  exit 1
fi

DEEPLINK=$1

# Open the deeplink in the booted iOS Simulator
xcrun simctl openurl booted "$DEEPLINK"
