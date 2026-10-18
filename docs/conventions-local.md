# Local conventions — DockWatch

Created: 2026-10-18 10:55 -05:00 · Edited: 2026-10-18 10:55 -05:00

## Harness

Declared by `C1`. Until `C1` closes, `check_harness.py` reports this project as undeclared, which is correct.

- run: `swift test`
- count: `scripts/count_assertions.sh`
- floor: `Tests/ASSERTION_FLOOR`
- mutate: `scripts/mutate.sh <M-id>` (applies the named break, runs the catching test, restores)
- precommit: `.githooks/pre-commit`

| Purpose | Command |
|---|---|
| Build | `swift build` |
| Offline tests | `swift test` |
| Assertion count | `scripts/count_assertions.sh` (parses `Executed N tests` from `swift test`) |
| App bundle | `scripts/build-app.sh` (add `--install` for `~/Applications`) |
| Manual hold check | `pmset -g assertions \| grep DockWatch` |
| Control instrument | `~/dockwatch/dockwatch.sh report` |

Stack: Swift 5.9 language mode, SwiftPM, AppKit, macOS 14+. No lint configured yet.

## Layout

```
Sources/DockCore/      no AppKit. DockIdentity, HoldPolicy, Event, EventStore, EventQuery,
                       USBMonitor, VolumeMonitor, PowerMonitor, SleepMonitor, AssertionController
Sources/DockWatch/     AppKit status item, menu, notifications, launch-at-login
Tests/DockCoreTests/   offline tests; every test cites an FR or D in its name or a comment
Resources/             Info.plist (LSUIElement), entitlements, AppIcon.icon
scripts/               build-app.sh, count_assertions.sh, mutate.sh
.githooks/             pre-commit, commit-msg
```

## Commit and branch grammar

`<type>(<F|C id>): <description>` · branch `F<N>/<slug>` · never a `D`, `RR`, `O`, `H` or `M` id in a commit, branch or PR title.
