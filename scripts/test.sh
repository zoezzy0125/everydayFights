#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
swiftc Sources/DayCountdown.swift Tests/main.swift -o "$TEMP_DIR/countdown-tests"
"$TEMP_DIR/countdown-tests"
swiftc -framework AppKit -framework EventKit Sources/L10n.swift Sources/Store.swift Tests/SubtaskMapping.swift -o "$TEMP_DIR/metadata-tests"
"$TEMP_DIR/metadata-tests"
