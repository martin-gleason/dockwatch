# Register — dockwatch

Every register for this project, one `##` per register. This is the
"where are we" read.

**This register is new and mostly empty. That means nobody has written these
down yet — not that this project has made no decisions.** Everything decided
before it existed lives in plans, reviews and conversations. Entries arrive
here as they are made from now on; backfilling is a deliberate act, not a
thing to do casually, because a transcribed guess reads exactly like a
recorded fact.

---

## Decisions (D)

ADR-style: numbered, dated, **immutable once ratified**. A decision is never edited —
it is superseded by a later entry that links back. A rejected decision stays, struck
through, so it is not re-proposed.

**One intake path.** Anything that changes scope enters as a `D<n>`. An item with no
number has not been decided, however clearly it was said aloud.

| ID | Status | Milestone | Decision |
|---|---|---|---|
| D1 | proposed | MVP | The project is **DockWatch**, at `~/Local_Dev_Projects/dockwatch`. It is distinct from the shell monitor at `~/dockwatch`, which keeps its name and job (see D8). |
| D2 | proposed | MVP | Layout mirrors HueBar: `DockCore` library (no AppKit, fully testable) + `DockWatch` AppKit executable + `DockCoreTests`. SwiftPM, no Xcode project. |
| D3 | proposed | MVP | "Keep dock awake" is an IOPMLib `PreventUserIdleSystemSleep` assertion owned by the app process. Not `pmset`, not root, not `PreventSystemSleep`. It targets the observed mechanism (every charger drop happened in idle sleep), leaves display sleep alone, and dies with the app. |
| D4 | proposed | MVP | The dock is identified by USB vendor:product `0x1532:0x122E` (macOS name "Thunderbolt 4 Dock"). The Chroma controller `0x1532:0x0F21` on the same dock shares the vendor ID and is not the dock (ID corrected 2026-10-18 from IOKit; an earlier listing misread it). No picker UI in MVP. |
| D5 | proposed | MVP | The log is JSON Lines at `~/Library/Logs/DockWatch/events.jsonl`, opened for append, rotated at 20 MB keeping one previous file. |
| D6 | ratified 2026-10-18 | MVP | Learning level **5%**: the agent authors, the owner reviews. Reason: due 2026-10-18. Owner (handoff Q2): "5% is good. Review PRs and add 'what I learned' to each as a comment." |
| D7 | proposed | MVP | macOS 14 minimum, matching HueBar. Built with Xcode 27.1 on macOS 27. Apple silicon only is verified. |
| D8 | superseded by D13 | MVP | The shell monitor at `~/dockwatch` (LaunchAgent `com.marty.dockwatch`) stays running as the control instrument. Agreement between its `events.log` and the app's log is F2's acceptance evidence. |
| D9 | proposed | MVP | Build order for 2026-10-18: C1 → F1 → F2 → F3 → F5 → F4. F4 is cut first if the day runs out. |
| D10 | proposed | MVP | The "Keep dock awake" toggle defaults **off**. First launch changes nothing until the owner turns it on. |
| D11 | ratified 2026-10-18 | MVP | **Supersedes the vision sentence in `SPEC.md`.** Owner's rewrite (handoff Q1): "DockWatch is a native Mac Menu Bar tool that logs the activity of the thunderbolt 4 dock, keeps it from falling asleep, and lets you eject or remove connected devices quickly and safely." Adds **FR9**: any volume on a disk attached through the dock can be ejected from the menu, singly or all at once, and the result is reported (done, or blocked and by what). No macOS API ejects a non-storage device; for those, "remove" means the log confirms the device is gone. Built as F6. |
| D12 | ratified 2026-10-18 | v1.5 | A schedule window for the hold is parked to v1.5. Owner (Q3): "For MVP: No scheduling. We will add that in v1.5". |
| D13 | ratified 2026-10-18 | MVP | **Supersedes D8.** Once F2's log is shown to agree with the shell monitor, the monitor's LaunchAgent is removed; replacing it is the test. Owner (Q5): "Replace. it's a real test." F2 gains a task for the removal. |
| D14 | proposed | MVP | License **MPL-2.0**: file-level copyleft whose terms the Mac App Store permits; GPL's do not, and the owner asked for both (Q6). `LICENSE` added. |
| D15 | proposed | v1.5 | Mac App Store distribution is a v1.5 goal (Q6). MVP therefore adopts App Sandbox and hardened runtime from F5, ad-hoc signed until a Developer ID exists, so nothing built now has to be unbuilt. |
| D16 | proposed | MVP | The menu bar icon changes from the SF Symbol connector set to a symbol the owner picks. Owner 2026-10-18: "I do want to change the icon"; which one is `O11`. |
| D17 | ratified 2026-10-18 | v1.5 | Users can choose the menu bar icon. Owner: "in v1.5 allow for users to select the icon." |

## Risks (RR)

| ID | Risk | Status | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|---|

| RR1 | An idle-sleep assertion does not stop lid-close sleep on battery without an external display, nor an explicit Sleep command. | open | Medium | The hold is silently absent in those states. | Menu wording says "idle sleep"; F3 evidence includes the lid test. | agent |
| RR2 | A docked Mac held awake around the clock: no overnight sleep, idle energy use. | open | Certain when on | Owner may not want it. | Toggle defaults off (D10); schedule window is a v1.1 candidate (`O3`). | human |
| RR3 | A user-space app observes nothing while the Mac sleeps, so sleep-time charger drops never reach the app log. | open | Certain | F4 counters undercount against `pmset -g log`. | The power log stays the ground truth for sleep-time events; the menu says so. | agent |
| RR4 | The hypothesis is wrong: devices keep dropping with the Mac awake. | open | Low to medium | The hold is useless; the log is still the diagnostic. | F3's evidence row compares the charger-detach count after one night held against the prior nights. | agent |
| RR5 | Due end of day 2026-10-18. | open | High | F4 or F5 unbuilt tonight. | Order D9; F4 cut first. | human |
| RR6 | `UNUserNotificationCenter` crashes in a binary that is not an app bundle. | open | Certain under `swift run` | F4-T3 cannot be verified until a bundle exists. | F5-T1 lands before F4; notifications gated on `Bundle.main.bundleIdentifier`. | agent |
| RR7 | The JMicron enclosure reports a 130 PB disk size; any capacity display would be absurd. | open | Certain | Confusing UI. | Never show sizes. | agent |
| RR8 | IOKit and DiskArbitration callbacks run on the main run loop; a slow menu rebuild delays them. | open | Low | Late or coalesced events. | Callbacks only enqueue; the menu is rebuilt on open. | agent |
| RR9 | No CI yet: every check runs only where somebody remembers to run it. Found by `detect_risks.py` (`ls .github/workflows` → none). | proposed | Certain until pushed | A red test blocks nothing. | C1-T3 pre-commit now; C1-T6 GitHub Actions once `O6` closes. | agent |
| RR10 | `docs/plans/00-status.md` is generated and nothing yet regenerates it, so it will go stale and be believed. Found by `detect_risks.py`. | proposed | Certain until C1 | A stale status page. | C1-T3 pre-commit runs `gen_status.py --check`; H6 in CI. | agent |
| RR11 | ~~[tests-collect-zero] pytest collects no tests.~~ Rejected 2026-10-18: this is a Swift project; the runner is `swift test` (SPEC § Stack), and pytest is not part of the stack. Kept so the detector does not re-propose it. | rejected | — | — | — | agent |
| RR12 | App Sandbox may refuse DiskArbitration unmount (FR9) or IOKit matching notifications; unverified on this stack. | open | Medium | F6 or F1 silently broken inside the sandboxed bundle. | F5-T1 runs both under the entitlements and records the result before F6 is built. | agent |
| RR13 | Time Machine holds `Backups` open during a backup, so "Eject all" will report it blocked by `backupd`. | open | Certain during a backup | One volume stays mounted. | The message names the process; the app never forces an unmount. | agent |
| RR14 | The identifying USB device `0x1532:0x122E` sits on the dock's USB 2 chain, the chain the spec says drops unevenly. If it terminates while the dock stays attached, the app shows "not connected" and F3 would release the hold. No evidence either way yet (control log has zero LOST lines). Found by the F1 review. | open | Unknown | The hold drops during exactly the fault it exists to prevent. | F2's log will show whether `0x122E` ever terminates alone; F3's plan must decide the policy before building. | agent |
## Owner items (O)

Outstanding items only the owner can close.

| ID | Item | P | Status |
|---|---|---|---|
| O1 | Ratify or rewrite the vision sentence in `docs/specs/SPEC.md`. | P0 | closed 2026-10-18 — owner: "vision is ratified" |
| O2 | Lock the learning level. Agent proposes 5% (D6). | P1 | closed 2026-10-18 — "5% is good" |
| O3 | Accept a round-the-clock hold while docked for MVP, or pull the schedule window into scope. Default if silent: accept. | P1 | closed 2026-10-18 — no scheduling in MVP, v1.5 (D12) |
| O4 | Gate C1 and F1: the yes that opens today's build. | P0 | closed 2026-10-18 — owner: "begin c1 and f1" |
| O5 | Decide whether the app replaces the shell monitor once F2's log agrees with it. Default if silent: both stay. | P2 | closed 2026-10-18 — "Replace. it's a real test." (D13) |
| O6 | Create the GitHub repository and push. C1-T6 waits on it. | P2 | closed 2026-10-18 — public at github.com/martin-gleason/dockwatch, created by the owner |
| O7 | Ratify D1–D10. | P1 | open |
| O8 | With the app running, pull the dock's Thunderbolt cable and plug it back; paste the stderr lines. Closes F1's live FR1/FR2 check. | P1 | open |
| O9 | The vision sentence is now D11's and it adds FR9; the agent does not edit `SPEC.md`. Paste the sentence and FR9 into the spec, or tell the agent to. | P1 | closed 2026-10-18 — "paste the rewritten vision"; pasted by the agent on that instruction |
| O10 | Gate F6 (eject dock volumes), proposed after F5 and before F4 in today's order. | P1 | open |
| O11 | Which menu bar icon (D16)? An SF Symbol name, or an image file in `Resources/`. Until answered the connector symbols stay. | P2 | open |

Questions for O1–O6 are laid out in `docs/handoffs/2026-10-18-planning-questions.md`.

## Chores (C)

`conventions.md`: *a chore gets a file only when it has tasks and a verification
step; a one-line chore lives in the register.* This is that register. A chore with
its own plan file is listed here too, with a link, so one read gives all of them —
the absence of that read is how a chore killed by a ratified delta stayed open for
days on the owner's track.

| ID | Chore | P | Status | Owner | Plan |
|---|---|---|---|---|---|
| C1 | Build the harness: run, count, floor, mutate, pre-commit; CI once pushed. | P0 | open | agent | `docs/plans/C1.md` |
| C2 | Stamps: every Created/Edited line comes from the clock or git, never typed; correct the files whose stamps run ahead of their commits (F1 review, finding 4). | P2 | open | agent | — |

## Gates (G)

A gate is an **event**, not a place — but the event has to be recorded somewhere or it
exists only in the conversation where it happened. It is not inferable from the
filesystem: the first attempt flagged six features as awaiting a gate and all six were
already built.

| ID | Gate | Status | Plan written | Crossed | What the owner said |
|---|---|---|---|---|---|
| G1 | C1 harness | done (crossed) | 2026-10-18 | 2026-10-18 | "begin c1 and f1" |
| G2 | F1 menu bar presence and dock detection | done (crossed) | 2026-10-18 | 2026-10-18 | "begin c1 and f1" |
| G3 | F2 event log | done (crossed) | 2026-10-18 | 2026-10-18 | "start f2" |
| G4 | F3 keep the dock awake | open (awaiting the gate) | 2026-10-18 | — | — |
| G5 | F5 installable app and launch at login | open (awaiting the gate) | 2026-10-18 | — | — |
| G6 | F4 timeline, counters, notifications | open (awaiting the gate) | 2026-10-18 | — | — |
| G7 | F6 eject dock volumes | open (awaiting the gate) | 2026-10-18 | — | — |

## Hooks (H)

Deterministic enforcement. Prose is advisory; hooks are not. An `H<n>` is a plan-local
label and **never appears in a commit, branch, or PR title**.

| ID | Hook | Surface | Protects | Status |
|---|---|---|---|---|
| H1 | `swift test` passes | pre-commit + CI | the test gate | built — pre-commit proven 2026-10-18 (C1-T3); CI run 39145745024 green on PR #2 (C1-T6) |
| H2 | Assertion count not below `Tests/ASSERTION_FLOOR` | pre-commit + CI | a suite that silently shrank | built — refused a floor of 2 against 1 (C1-T3); CI step `executed=1 floor=1` (C1-T6) |
| H3 | No register ID in a commit, branch or PR title | commit-msg | the two-tier grammar | built — refused `D1` in a subject, and refused the agent's own `FR9` later the same day (C1-T3) |
| H4 | Harness declared and its commands run | upstream `check_harness.py --run` | an undeclared or dead harness | built — reports `ok dockwatch` (C1-T5) |
| H5 | Every FR has a test or a named manual check with evidence | plan review checklist | drift, both directions | open (manual checklist, no mechanism) |
| H6 | Status page regenerates clean | CI | a stale status page | not built (C1-T6) |

## Mutations (M)

Named ways to break the code, each paired with the test that must catch it.
A test is not evidence until a mutation proves it can fail.

| ID | File | Mutation | Caught by | Status |
|---|---|---|---|---|
| M1 | `Sources/DockCore/HoldPolicy.swift` | Keep holding after the dock is removed | `HoldPolicyTests.testUndockReleasesHold` | proposed |
| M2 | `Sources/DockCore/HoldPolicy.swift` | Hold while the toggle is off | `HoldPolicyTests.testToggleOffNeverHolds` | proposed |
| M3 | `Sources/DockCore/EventStore.swift` | Open the log with truncate instead of append | `EventStoreTests.testAppendPreservesPriorLines` | proposed |
| M4 | `Sources/DockCore/DockIdentity.swift` | Match on vendor ID alone | `DockIdentityTests.testRazerMouseIsNotTheDock` and `testChromaControllerIsNotTheDock` (both share the dock's vendor ID) | killed 2026-10-18: 1 failure / 1 test (`scripts/mutate.sh M4`) |
| M5 | `Sources/DockCore/EventQuery.swift` | Compute the 24-hour window by insertion order, not timestamp | `EventQueryTests.testWindowExcludesOldEvents` | proposed |
| M6 | `Sources/DockCore/HoldPolicy.swift` | Ignore the wake input | `HoldPolicyTests.testWakeWhileDockedReasserts` | proposed |
| M7 | `Sources/DockCore/DockMembership.swift` | Compare the whole location ID instead of the controller byte | `DockMembershipTests.testSiblingHubIsOnTheDock` | proposed |

-----

#AI/Claude
