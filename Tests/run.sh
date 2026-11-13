#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/tests
swiftc Sources/ScrollWheelMissionControl/ShortcutSequence.swift Tests/ShortcutSequenceTests.swift -o .build/tests/shortcut-sequence-tests
.build/tests/shortcut-sequence-tests
