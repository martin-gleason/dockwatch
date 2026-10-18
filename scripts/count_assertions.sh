#!/bin/zsh
# Created: 2026-10-18 11:25 -05:00 · Edited: 2026-10-18 11:25 -05:00
# Harness `count` (C1-T2): prints one integer — the tests XCTest actually executed.
#
# XCTest does not report an assertion count, so the executed-test count is the number the
# floor protects. It still catches the failure the floor exists for: a suite that reports
# green having run less than it used to.
#
# NOT `set -e`: a red suite still ran its tests, and a lower count on failure would make
# a break look like shrinkage. `swift test` decides pass or fail; this only counts.
set -u
cd "$(dirname "$0")/.."
out=$(swift test 2>&1)
# Per-suite lines come first; the overall summary is the last "Executed N tests" line.
n=$(printf '%s\n' "$out" | grep -E "Executed [0-9]+ tests?" | tail -1 | sed -E 's/.*Executed ([0-9]+) tests?.*/\1/')
echo "${n:-0}"
