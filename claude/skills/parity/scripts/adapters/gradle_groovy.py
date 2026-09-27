"""Alias kept so a project can name its DSL explicitly in pair.json."""

from __future__ import annotations

import gradle_kts

NAME = "gradle_groovy"
MARKERS = ["settings.gradle"]
SOURCE_SUFFIXES = gradle_kts.SOURCE_SUFFIXES
DEFAULTS = gradle_kts.DEFAULTS
detect = gradle_kts.detect
modules = gradle_kts.modules
features = gradle_kts.features
strings = gradle_kts.strings
capabilities = gradle_kts.capabilities
