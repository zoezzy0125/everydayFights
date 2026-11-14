#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
SOURCES=()
for file in Sources/*.swift; do
  [[ "$file" == "Sources/main.swift" ]] || SOURCES+=("$file")
done
swiftc -swift-version 5 -framework Cocoa -framework SwiftUI -framework EventKit -framework Carbon -framework Speech -framework AVFoundation "${SOURCES[@]}" Tests/RowMenu.swift -o "$TEMP_DIR/row-tests"
"$TEMP_DIR/row-tests"
