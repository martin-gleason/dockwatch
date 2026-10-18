#!/bin/zsh
# Created: 2026-10-18 11:14 -05:00 · Edited: 2026-10-18 12:56 -05:00
# Harness `mutate` (C1-T4): apply a named break from the register, run the test that must
# catch it, restore the file. Exit 0 = caught (the test went red), 1 = ESCAPED (stayed
# green), 2 = the mutation could not be applied.
#
# Usage: scripts/mutate.sh M4
#
# The table below is kept in step with docs/plans/00-register.md § Mutations (M).
# Columns: id | file | sed expression that applies the break | swift test --filter
set -u
cd "$(dirname "$0")/.."
id=${1:?usage: scripts/mutate.sh <M-id>}

table='
M1|Sources/DockCore/HoldPolicy.swift|s/docked = present/docked = true/|HoldPolicyTests/testUndockReleasesHold
M2|Sources/DockCore/HoldPolicy.swift|s/toggle && docked/docked/|HoldPolicyTests/testToggleOffNeverHolds
M3|Sources/DockCore/EventStore.swift|s/O_APPEND/O_TRUNC/|EventStoreTests/testAppendPreservesPriorLines
M4|Sources/DockCore/DockIdentity.swift|s/ && device.productID == productID//|DockIdentityTests/testRazerMouseIsNotTheDock
M5|Sources/DockCore/EventQuery.swift|s/\$0.timestamp >= cutoff/true/|EventQueryTests/testWindowExcludesOldEvents
M6|Sources/DockCore/HoldPolicy.swift|s/reapply: true\)/reapply: false)/|HoldPolicyTests/testWakeWhileDockedReasserts
M8|Sources/DockCore/EventStore.swift|s/try FileManager.default.moveItem\(at: url, to: rotatedURL\)/try FileManager.default.removeItem(at: url)/|EventStoreTests/testRotationKeepsExactlyOnePreviousFile
'

row=$(printf '%s\n' "$table" | grep -E "^${id}\|")
if [[ -z "$row" ]]; then echo "mutate: no row for $id in scripts/mutate.sh"; exit 2; fi
file=$(printf '%s' "$row" | cut -d'|' -f2)
expr=$(printf '%s' "$row" | cut -d'|' -f3)
filter=$(printf '%s' "$row" | cut -d'|' -f4)
if [[ ! -f "$file" ]]; then echo "mutate: $id names $file, which does not exist yet"; exit 2; fi

backup=$(mktemp)
cp "$file" "$backup"
# Restore the source AND rebuild: `swift test` rebuilt every target with the break in it, and
# a restored tree over a mutated .build/ is how a vendor-only binary once ran as "F1 evidence".
restore() { cp "$backup" "$file"; rm -f "$backup"; swift build >/dev/null 2>&1; }
trap restore EXIT INT TERM

sed -i '' -E "$expr" "$file"
if cmp -s "$backup" "$file"; then
  echo "mutate: $id did not change $file — the sed expression no longer matches the code"
  exit 2
fi
echo "mutate: applied $id to $file; running $filter"
out=$(swift test --filter "$filter" 2>&1); rc=$?
summary=$(printf '%s\n' "$out" | grep -E "Executed [0-9]+ tests?" | tail -1)
if [[ $rc -ne 0 ]]; then
  echo "mutate: $id CAUGHT — ${summary:-test run failed}"
  exit 0
else
  echo "mutate: $id ESCAPED — the named test stayed green: ${summary:-no summary}"
  exit 1
fi
