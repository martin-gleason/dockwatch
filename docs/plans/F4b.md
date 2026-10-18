# F4b — Membership after the dock is gone

Created: 2026-10-18 17:10 -05:00 · Edited: 2026-10-18 17:10 -05:00

**Status:** built 2026-10-18 · **Milestone:** MVP · **Owner:** agent · **Retrofit of:** F4 · **Delivers:** the counts and notifications FR4, FR6 and D28 already promise

A defect fix, no gate (CLAUDE.md § Authorization). Found by the F4 review after PR #7 merged.

## The defect

"On the dock" was judged from the tracker's live state. The moment the dock's own USB device terminates, that state is gone, so every child that terminates after it is neither counted as a device lost nor collected into the "dock disconnected" notification. In the one recorded pull the dock device was eleventh of eighteen; the review's replay of those lines gave "10 devices" and a count of 11, and with the dock line first, "0 devices". Volumes arrive even later, through DiskArbitration, so the "M volumes" count was always zero on a pull. The suite was green because the judgement lived in the executable and the tests hand-set `dock=true`.

## The fix

- `DockTracker` remembers the last dock location after the undock and offers `isOnDock(_:)`: the identifying device, or any device on the remembered controller. The judgement now lives in DockCore.
- The recorded eighteen lines are a test fixture, run in the recorded order and with the dock first: all eighteen judged the dock's, flush `dockDisconnected(devices: 17, volumes: 0)` both ways (M14).
- `LossCoalescer.dockDetached()` reports whether it opened the window, like `add`, so the app has one place that schedules the flush.
- Small things from the same review: launch-baseline power lines read "at launch" in the timeline; one shared time formatter; the RR3 note about sleep-time charger drops is a readable menu line, not a tooltip.

## Evidence (2026-10-18)

| Check | Result | How |
|---|---|---|
| Fixture, recorded order | **pass** — 18 of 18 judged the dock's; flush `dockDisconnected(devices: 17, volumes: 0)` | `swift test --filter DockPullFixtureTests` |
| Fixture, dock first | **pass** — same | same |
| M14 forget the controller on undock | **killed** — 2 failures / 1 test | `scripts/mutate.sh M14` |
| Whole suite | **pass** — `Executed 49 tests, with 0 failures` (4 fixture tests added on main's 45) | `swift test` |
| Timeline shows launch baselines as such | **pass** — rows read back: `… power.disconnected  Battery Power  at launch` | System Events |
| RR3 note readable | **pass** — menu item 3 reads `Charger drops during sleep are in the system power log, not here.` | System Events |

Live: the real pull and its notification remain `O15` (dock unplugged all afternoon).
