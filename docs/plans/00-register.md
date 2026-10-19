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
| D3 | proposed | MVP | "Keep dock awake" is an IOPMLib `PreventUserIdleSystemSleep` assertion owned by the app process. Not `pmset`, not root, not `PreventSystemSleep`. It targets the observed mechanism (every charger drop happened in idle sleep), leaves display sleep alone, and dies with the app. Note for ratification (F3 review): the SDK header marks `PreventSystemSleep` deprecated and unsupported, so it was never an alternative; and no assertion type stops a lid-close sleep (RR1). |
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
| D16 | ratified 2026-10-18 | MVP | The menu bar icon is the owner's hue ring, regenerated as a continuous sweep and drawn in code so it can turn (F7). Owner: "menubar icon is ratified. excellent!" |
| D17 | ratified 2026-10-18 | v1.5 | Users can choose the menu bar icon. Owner: "in v1.5 allow for users to select the icon." |
| D18 | ratified | MVP | **Dark wakes are not observable from a user-space app.** xnu sends the legacy-app power messages only when graphics come up, so the sleep/dark-wake loop the spec describes leaves no trace in the app's log. The `system.darkwake` kind is dropped; `system.wake` means a full wake; `pmset -g log` stays the record for dark wakes (RR3), and F4's "wakes" counter counts full wakes. Found by the F2 review from `IOPMrootDomain.cpp`. |
| D19 | ratified 2026-10-18 | MVP | Build order after F2 is F3, then F6, then F5, then F4. Owner: "begin work on f3" after "then begin f6"; supersedes the order in D9 from F3 onward. |
| D20 | proposed | MVP | Icon motion policy for F7, as amended after the F7 review: the hue ring is still by default; while the hold is in force it turns once a minute **at one frame a second** and shows a **filled hub**, so FR1's held state reads in a still glance as well as in motion; a dock connect or disconnect is one quick turn that lands at home; releasing the hold turns the ring home; with Reduce Motion on, nothing moves and the hub alone marks the hold. Rationale: an always-animating menu bar icon spends CPU around the clock, against the app's purpose; measured held cost with the bar showing is 1.3 %. |
| D21 | proposed | MVP | The log gains `hold.on` and `hold.off` lines when the sleep assertion is taken and released, so the overnight charger-drop comparison (F3 evidence, RR4) can be read against exactly when the hold was in force. Two kinds beyond FR3's list; the owner ratifies or they go. |
| D22 | ratified 2026-10-18 | v1.5 | **Alert when something drops alone.** A device or volume on the dock detaching while the dock itself stays attached raises an alert; a whole-dock disconnect does not raise one per device. Owner: "v1.5: if something drops alone, we need an alert." Implication for F4 (MVP, FR6): its loss notifier must already tell a lone drop from a dock pull, so that this alert has a definition to build on. |
| D23 | proposed | MVP | The menu's "Eject" is a DiskArbitration **unmount** of the volume, never a whole-disk `DADiskEject`: the disk stays attached, so a remount needs no replug, which suits a dock whose drives come and go. Finder's eject detaches the disk until it is replugged. A whole-disk eject is a v1.5 option. From the F6 review, finding 6. |
| D24 | proposed | MVP | Under App Sandbox the log lives in the app's container: `~/Library/Containers/com.martingleason.dockwatch/Data/Library/Logs/DockWatch/events.jsonl`. "Open Log" in the menu is the way to it; commands in O12/O13 use that path for the installed app. The bare `swift run` binary keeps writing to `~/Library/Logs/DockWatch/`. |
| D25 | ratified 2026-10-18 | MVP | **Under App Sandbox a busy eject cannot name its blocker**: the sandbox denies `proc_listpidspath` (RR12). Proposed: MVP accepts the wording "In use by another process; the sandbox cannot say which", and naming holders goes to v1.5, either outside the sandbox (direct distribution, notarized) or through a privileged helper. The alternative is dropping the sandbox now, which unwinds D15. From the F5 review. Owner: "d25 & d26 are approved." |
| D26 | ratified 2026-10-18 | MVP | The Finder and Dock icon is a flat `.icns` for now, which macOS 26 shows inside a grey tile with the ring inset. The edge-to-edge Icon Composer `.icon` of the ring lands with F7, the icon feature. From the F5 review. Owner: "d25 & d26 are approved." |
| D27 | proposed | MVP | Loss notifications are coalesced for two seconds after the first loss, so a whole-dock pull is one notification ("Dock disconnected: 17 devices, 4 volumes") and a lone drop is its own (D22's definition, built now). The two-second wait is a one-shot delay started by an event, not a poll (NFR2). Notification permission is requested once, at the first launch of the installed app; a `swift run` binary cannot post notifications (RR6) and logs that instead. |
| D28 | proposed | MVP | The menu's 24-hour counters: devices lost = `usb.detached` on dock devices; volumes lost = `volume.disappeared` (unclean) on dock volumes; charger drops = `power.disconnected` not marked initial; wakes = `system.wake` (full wakes only, D18). The counters line says that sleep-time charger drops are in the system power log (RR3). |
| D29 | proposed | MVP | NFR2 reading for F7: the ring's frame timer is an animation clock that exists only while the ring is moving **and the status item is visible** (an auto-hidden or occluded menu bar stops it), at the motion's own rate, and is destroyed when either stops; at rest the app has no timer. It polls nothing; device, volume, power and sleep state still arrive only through callbacks. |
| D30 | proposed | v1.5 | Sign with a Developer ID and notarize before any distribution and before Launch at Login is offered as a default. The ad-hoc signature's designated requirement is a bare cdhash, so a re-signed tampered bundle verifies and inherits the app's approved login item (security review 2026-10-18, finding 1). Until then the build is for the owner's own machine and Launch at Login stays off. |
| D31 | proposed | v1.5 | Identify the dock by its IORegistry Thunderbolt ancestry as well as its vendor and product IDs, and judge membership below that node rather than by the controller byte alone, so a USB device advertising the dock's IDs on a built-in port cannot pass as the dock (security review 2026-10-18, finding 5). |

## Risks (RR)

| ID | Risk | Status | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|---|

| RR1 | An idle-sleep assertion does not stop lid-close sleep on battery without an external display, nor an explicit Sleep command. | open | Medium | The hold is silently absent in those states. | Menu wording says "idle sleep"; F3 evidence includes the lid test. | agent |
| RR2 | A docked Mac held awake around the clock: no overnight sleep, idle energy use. | open | Certain when on | Owner may not want it. | Toggle defaults off (D10); schedule window is a v1.1 candidate (`O3`). | human |
| RR3 | A user-space app observes nothing while the Mac sleeps, so sleep-time charger drops never reach the app log. | open | Certain | F4 counters undercount against `pmset -g log`. | The power log stays the ground truth for sleep-time events, dark wakes included (D18); the menu says so. | agent |
| RR4 | The hypothesis is wrong: devices keep dropping with the Mac awake. | open | Low to medium | The hold is useless; the log is still the diagnostic. | F3's evidence row compares the charger-detach count after one night held against the prior nights. | agent |
| RR5 | Due end of day 2026-10-18. | resolved 2026-10-18 — MVP built by end of day: C1, F1–F7, F4b, C3 merged | High | F4 or F5 unbuilt tonight. | Order D9; F4 cut first. | human |
| RR6 | `UNUserNotificationCenter` crashes in a binary that is not an app bundle. | open | Certain under `swift run` | F4-T3 cannot be verified until a bundle exists. | F5-T1 lands before F4; notifications gated on `Bundle.main.bundleIdentifier`. | agent |
| RR7 | The JMicron enclosure reports a 130 PB disk size; any capacity display would be absurd. | open | Certain | Confusing UI. | Never show sizes. | agent |
| RR8 | IOKit and DiskArbitration callbacks run on the main run loop; a slow menu rebuild delays them. | open | Low | Late or coalesced events. | Callbacks only enqueue; the menu is rebuilt on open. | agent |
| RR9 | No CI yet: every check runs only where somebody remembers to run it. Found by `detect_risks.py` (`ls .github/workflows` → none). | resolved 2026-10-18 — `.github/workflows/ci.yml` since PR #2; required check since the ruleset change | Certain until pushed | A red test blocks nothing. | C1-T3 pre-commit now; C1-T6 GitHub Actions once `O6` closes. | agent |
| RR10 | `docs/plans/00-status.md` is generated and nothing yet regenerates it, so it will go stale and be believed. Found by `detect_risks.py`. | resolved 2026-10-18 — pre-commit refuses a stale status page (`gen_status.py --check`) | Certain until C1 | A stale status page. | C1-T3 pre-commit runs `gen_status.py --check`; H6 in CI. | agent |
| RR11 | ~~[tests-collect-zero] pytest collects no tests.~~ Rejected 2026-10-18: this is a Swift project; the runner is `swift test` (SPEC § Stack), and pytest is not part of the stack. Kept so the detector does not re-propose it. | rejected | — | — | — | agent |
| RR12 | App Sandbox and the app's calls. **Answered by sandboxed probes (F5 review):** IOKit USB notifications and registry reads, the IOMedia parent walk, `IOPMAssertionCreateWithName`, `IORegisterForSystemPower`, `DADiskUnmount` (a real unmount), `SMAppService` and Open Log all work; **`proc_listpidspath` is denied (EPERM)**, so the installed app can never name a blocker. Still unproven with the dock itself: its USB descriptors end to end, the hold on arrival, a dock unmount (A1). | open | Certain (lookup) | Busy ejects read "another process; the sandbox cannot say which". | D25 for the owner; A1 for the rest. | agent |
| RR13 | Time Machine holds `Backups` open during a backup, so "Eject All" is refused for it. A non-root app cannot name root processes, and the sandboxed app cannot name any (RR12), so the installed app's row reads "In use by another process; the sandbox cannot say which". | open | Certain during a backup | One volume stays mounted; the blocker is unnamed. | Honest wording in the menu; the app never forces an unmount. Naming blockers is D25. | agent |
| RR14 | The identifying USB device `0x1532:0x122E` sits on the dock's USB 2 chain, the chain the spec says drops unevenly. If it terminates while the dock stays attached, the app shows "not connected" and F3 would release the hold. Found by the F1 review. | open | Unknown | A gap in the hold during the fault it exists to prevent. | Policy set in F3's plan: the hold follows the tracker exactly. A flicker costs a gap of seconds, and idle sleep needs the Mac idle for at least its one-minute setting, so a gap of seconds cannot start the loop; `hold.off`/`hold.on` lines (D21) will show it if it happens. | agent |
| RR15 | libproc's header calls its interfaces "private … subject to change" although it ships in the SDK and `lsof` uses it; NFR1 does not list it. | open | Low | The blocker lookup stops compiling or returns nothing on a future macOS. | One call site; the menu degrades to "In use by a system process". From the F6 review. | agent |
| RR16 | Two sessions in one working tree: the author switched the shared checkout to another branch while the F7 review ran there; one of the reviewer's runs executed the wrong tree before it moved to a clean clone. | open | Medium | Review evidence taken from the wrong code. | Reviews run from a clean clone; the author uses a separate worktree for any work started while a review is running. Second instance 2026-10-18 20:00: the C3 reviewer left the shared checkout on `main`; the brief now says never to run `git checkout` in the original. | agent |
| RR17 | Two branches merged in parallel each appended a row to the same tables (`scripts/mutate.sh`, the mutation register); the hand-resolved merge of PR #8 kept one row and dropped the other, so `scripts/mutate.sh M14` answered "no row" on main. | open | Medium | A mutation silently leaves the table and its test can decay unnoticed. | Restored the same evening. After any merge of parallel branches: run every row in the mutation table and diff each parent's removed lines against the merge before trusting it. | agent |
| RR18 | The installed bundle is ad-hoc signed in a user-writable path; same-user code can replace the binary, re-sign, and pass `codesign --verify`, riding the app's approved login item for persistence under DockWatch's name. | open | Low (needs same-user code execution) | High: disguised, pre-trusted persistence. | D30 for v1.5; Launch at Login off until then (O17). Security review 2026-10-18. | owner |
| RR19 | Running a pull-request branch locally runs its code: tests spawn processes, hooks live in the repo (`core.hooksPath=.githooks`), scripts are shell, and the upstream `check_harness.py --run` executes the `run:` bullet of `docs/conventions-local.md` through a shell even after its static check fails. | open | Low today (one collaborator, every PR the owner's own) | High: code execution as the owner. | Review `Tests/`, `scripts/`, `.githooks/`, `.claude/`, `CLAUDE.md`, `docs/conventions-local.md` as code; fork PRs run in CI before checkout (O18); upstream fix A2. Security review 2026-10-18. | agent |
| RR20 | Dock identity is vendor and product ID only and membership is the controller byte, never cleared; a programmable USB device with the dock's IDs makes the app docked: indefinite idle-sleep hold with the toggle on, false loss counts, unrelated drives offered under Dock Volumes. | open | Low (physical access; eject still needs a click, never forced) | Medium: battery and wrong counts; a wrong unmount needs the owner's click. | D31 for v1.5; C3-T3 clears the remembered controller. Security review 2026-10-18. | agent |
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
| O7 | Ratify the proposed decisions the build rests on: D1–D5, D7, D9, D10, D20, D21, D23, D24, D27, D28, D29. | P1 | open |
| O8 | With the app running, pull the dock's Thunderbolt cable and plug it back; paste the stderr lines. Closes F1's live FR1/FR2 check. | P1 | closed 2026-10-18 — owner: "I did the test. it works beautifully." |
| O9 | The vision sentence is now D11's and it adds FR9; the agent does not edit `SPEC.md`. Paste the sentence and FR9 into the spec, or tell the agent to. | P1 | closed 2026-10-18 — "paste the rewritten vision"; pasted by the agent on that instruction |
| O10 | Gate F6 (eject dock volumes), proposed after F5 and before F4 in today's order. | P1 | closed 2026-10-18 — "you can begin f6" |
| O11 | Which menu bar icon (D16)? An SF Symbol name, or an image file in `Resources/`. Until answered the connector symbols stay. | P2 | closed 2026-10-18 — the owner's hue ring, regenerated as a continuous sweep; motion policy is D20, built as F7 |
| O12 | F2 and F3 live checks only the owner can do, with the app running and Keep Dock Awake on: close the lid for a minute (expect `system.sleep` then `system.wake`); unplug the dock's cable from the Mac for ten seconds (expect `power.disconnected` with `lastWatts`, four `volume.disappeared`, seventeen `usb.detached`, and `hold.off` within five seconds of the pull; then the reverse as `power.connected`, `usb.attached`, `volume.mounted`, and `hold.on`); click Open Log (Finder shows the file). | P1 | open |
| O13 | **The experiment.** With the app running and the dock attached, turn on **Keep Dock Awake** in the menu (its ⌘K works only while the menu is open). Leave the lid **open** overnight: an idle-sleep assertion does not stop a lid-close sleep (RR1), and a `system.sleep` line after `hold.on` in `events.jsonl` invalidates the night. Next morning count charger drops **from the `hold.on` timestamp**, and compare with the same clock window on earlier nights, not with their day totals (the loop runs all day, so a morning-only count against a day total would flatter a partial result). The installed app's log is the file **Open Log** reveals, inside the app's container (D24): `L=~/Library/Containers/com.martingleason.dockwatch/Data/Library/Logs/DockWatch/events.jsonl; H=$(grep '"hold.on"' "$L" \| tail -1 \| sed -E 's/.*"ts":"([^"]+)".*/\\1/')` then `pmset -g log \| grep acdetach \| awk -v h="$H" '$1" "$2 >= substr(h,1,19)' \| wc -l`, beside `pmset -g log \| grep acdetach \| awk '{print $1}' \| sort \| uniq -c` for the earlier nights. Zero is unambiguous; anything else is read against the matching window. Lid check separately (NFR8): with the toggle on, close the lid for a minute, reopen, and look for `hold.on … reapplied=true` in the log and a fresh age on the assertion in `pmset -g assertions`. | P0 | open |
| O14 | F6 live checks only the owner can do, with the dock plugged back in: eject one volume from the menu and reopen the menu within a minute — its row stays, greyed, reading “Ejected”; remount it (`diskutil mount disk5s2`) and reopen — the “Ejected” is gone. Then “Eject All Dock Volumes”: Backups reads “In use by a system process” if a backup is running (Time Machine runs as root and cannot be named), the others “Ejected”. Remount with `diskutil mountDisk disk5` / `disk6` / `disk7` or by replugging. | P1 | open |
| O15 | F4 live checks only the owner can do, from the installed app with the dock attached: allow notifications when asked at first launch; unplug the keyboard — one notification "Dropped from the dock: Das Keyboard" and the counters line reads 1 device lost; pull the dock's cable — one notification "Dock disconnected: N devices and M volumes went with it", not one per device. | P1 | open |
| O16 | F7 live checks only the owner can do, from a rebuilt installed app (`scripts/build-app.sh --install`): the ring in the menu bar, grey without the dock and in colour with it; one quick turn when the dock is plugged in; a slow turn (one a minute) while Keep Dock Awake is holding; still otherwise. The Finder icon is the ring, edge to edge. | P1 | open |
| O17 | Confirm in System Settings › General › Login Items whether DockWatch is listed under Open at Login. Background Task Management records the item as enabled at `~/Applications/DockWatch.app` while launchd shows no job; the setting should be off until D30 (security review 2026-10-18, finding 1). | P1 | closed 2026-10-18 — owner ran the runbook; `sfltool dumpbtm` → `Disposition: [enabled, disallowed, notified]`; the item stays disallowed until D30 |
| O18 | Repository settings only the owner can change (security review 2026-10-18, findings 2–4): in the "Rebase-n-Merge" ruleset require a pull request and the `ci / test` status check; set Actions fork-PR approval to all outside collaborators; enable secret scanning and push protection. `gh api -X PUT repos/martin-gleason/dockwatch/actions/permissions/workflow -f default_workflow_permissions=read` is already the state; the rest is in Settings › Rules, Settings › Actions, Settings › Code security. | P1 | closed 2026-10-18 — owner ran the runbook; `gh api …/rulesets/25349652` → `deletion`, `non_fast_forward`, `pull_request` (rebase only), `required_status_checks` (`test`); `…/fork-pr-contributor-approval` → `all_external_contributors`; non-provider patterns left off (optional) |
| O19 | Personal-data posture for a public repository (security review 2026-10-18, finding 9): the commit author email on every commit, the machine model and versions, the owner's volume names and disk identifiers in `docs/plans/F2.md` and `F6.md`, and the product names in the recorded-pull fixture. Decide whether to switch to a noreply address for future commits and whether the agent should scrub the volume and product names; the fixture needs only its locationIDs. | P2 | open |
| O20 | Gate C3, the security hardening chore (`docs/plans/C3.md`): six tasks, no feature change. | P1 | closed 2026-10-18 — owner: "begin c3 hardening" |

Questions for O1–O6 are laid out in `docs/handoffs/2026-10-18-planning-questions.md`.

## Agent items (A)

Outstanding items only the agent can close: defects in its own work, findings it owes a fix.

| ID | Item | P | Status |
|---|---|---|---|
| A1 | Finish the dock half of RR12 once the dock is plugged back in: from the installed bundle, confirm the dock's USB devices are logged at launch, the hold is taken with the toggle on, and an eject from the menu unmounts a dock volume. (Blocker naming is settled: denied by the sandbox, D25.) Record each in `docs/plans/F5.md`. | P0 | open |
| A2 | Promote upstream to turing-review: `scripts/check_harness.py --run` executes a declared command through `shell=True` even after its static check has failed; it should skip execution after a static failure and accept only a whitelist of exact commands without a shell (security review 2026-10-18, finding 2). | P1 | open |

## Chores (C)

`conventions.md`: *a chore gets a file only when it has tasks and a verification
step; a one-line chore lives in the register.* This is that register. A chore with
its own plan file is listed here too, with a link, so one read gives all of them —
the absence of that read is how a chore killed by a ratified delta stayed open for
days on the owner's track.

| ID | Chore | P | Status | Owner | Plan |
|---|---|---|---|---|---|
| C1 | Build the harness: run, count, floor, mutate, pre-commit; CI once pushed. | P0 | done 2026-10-18 — harness, hooks, CI all proven by breaking; closed late, the row was never updated | agent | `docs/plans/C1.md` |
| C2 | Stamps: every Created/Edited line comes from the clock or git, never typed; correct the files whose stamps run ahead of their commits (F1 review, finding 4). | P2 | open | agent | — |
| C3 | Security hardening from the black-hat review of 2026-10-18: O_NOFOLLOW and a regular-file check on the log, tail trimming that cannot blank the seed, forget the dock controller when empty, a broader secret scan in the hook and CI, plain-text device names, pinned least-privilege CI. | P1 | done 2026-10-18 — PR #11 merged | agent | `docs/plans/C3.md` |

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
| G4 | F3 keep the dock awake | done (crossed) | 2026-10-18 | 2026-10-18 | "begin work on f3" |
| G5 | F5 installable app and launch at login | done (crossed) | 2026-10-18 | 2026-10-18 | "#5 is merged. begin f5" |
| G6 | F4 timeline, counters, notifications | done (crossed) | 2026-10-18 | 2026-10-18 | "#6 is merged. begin f4" |
| G7 | F6 eject dock volumes | done (crossed) | 2026-10-18 | 2026-10-18 | "#4 is merged. you can begin f6" |
| G8 | F7 the hue ring icon | done (crossed) | 2026-10-18 | 2026-10-18 | "#7 is merged. begin f7" |

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
| M1 | `Sources/DockCore/HoldPolicy.swift` | Keep holding after the dock is removed | `HoldPolicyTests.testUndockReleasesHold` | killed 2026-10-18: 2 failures / 1 test (`scripts/mutate.sh M1`) |
| M2 | `Sources/DockCore/HoldPolicy.swift` | Hold while the toggle is off | `HoldPolicyTests.testToggleOffNeverHolds` | killed 2026-10-18: 3 failures / 1 test (`scripts/mutate.sh M2`) |
| M3 | `Sources/DockCore/EventStore.swift` | Open the log with truncate instead of append | `EventStoreTests.testAppendPreservesPriorLines` | killed 2026-10-18: 4 failures / 1 test (`scripts/mutate.sh M3`) |
| M4 | `Sources/DockCore/DockIdentity.swift` | Match on vendor ID alone | `DockIdentityTests.testRazerMouseIsNotTheDock` and `testChromaControllerIsNotTheDock` (both share the dock's vendor ID) | killed 2026-10-18: 1 failure / 1 test (`scripts/mutate.sh M4`) |
| M5 | `Sources/DockCore/EventQuery.swift` | Compute the 24-hour window by insertion order, not timestamp | `EventQueryTests.testWindowExcludesOldEvents` | killed 2026-10-18: 1 failure / 1 test (`scripts/mutate.sh M5`) |
| M6 | `Sources/DockCore/HoldPolicy.swift` | Ignore the wake input | `HoldPolicyTests.testWakeWhileDockedReasserts` | killed 2026-10-18: 1 failure / 1 test (`scripts/mutate.sh M6`) |
| M7 | `Sources/DockCore/DockMembership.swift` | Compare the whole location ID instead of the controller byte | `DockMembershipTests.testSiblingHubIsOnTheDock` | killed 2026-10-18: 2 failures / 1 test (`scripts/mutate.sh M7`) |
| M8 | `Sources/DockCore/EventStore.swift` | Delete the log at rotation instead of moving it aside | `EventStoreTests.testRotationKeepsExactlyOnePreviousFile` | killed 2026-10-18: 3 failures / 1 test (`scripts/mutate.sh M8`) |
| M9 | `Sources/DockCore/VolumeEjector.swift` | Never read a dissenter as busy (every refusal becomes "failed") | `VolumeEjectorLiveTests.testBusyVolumeIsRefusedAndNamed_thenEjectsWhenFree` (live, on a disk image) | killed 2026-10-18: 1 failure / 1 test (`scripts/mutate.sh M9`; re-run after the class was renamed) |
| M10 | `Sources/DockCore/EjectMenuModel.swift` | Drop a result the moment its volume unmounts (a successful eject shows nothing) | `EjectMenuModelTests.testSuccessfulEjectStaysVisibleAfterUnmount` | killed 2026-10-18: 2 failures / 1 test (`scripts/mutate.sh M10`) |
| M11 | `Sources/DockCore/EjectMenuModel.swift` | Keep a result after its volume mounts again (“Ejected” beside a mounted drive) | `EjectMenuModelTests.testRemountClearsResult` | killed 2026-10-18: 1 failure / 1 test (`scripts/mutate.sh M11`) |
| M12 | `Sources/DockCore/LossCoalescer.swift` | Ignore that the dock itself detached (a dock pull becomes seventeen notifications) | `LossCoalescerTests.testDockPullIsOneSummary` | killed 2026-10-18: 1 failure / 1 test (`scripts/mutate.sh M12`) |
| M13 | `Sources/DockCore/RingMotion.swift` | Report the ring as moving while idle (a timer that never stops) | `RingMotionTests.testStillByDefault` | killed 2026-10-18: 1 failure / 1 test (`scripts/mutate.sh M13`) |
| M14 | `Sources/DockCore/DockState.swift` | Forget the dock's controller on undock (children terminating after the dock device stop counting) | `DockPullFixtureTests.testRecordedPullCountsEveryChild` | killed 2026-10-18: 2 failures / 1 test (`scripts/mutate.sh M14`) |
| M15 | `Sources/DockCore/EventStore.swift` | Follow a symlink planted at the log path (drop `O_NOFOLLOW`) | `EventStoreTests.testSymlinkAtLogPathIsRefusedNotFollowed` | killed 2026-10-18: 4 failures / 1 test (`scripts/mutate.sh M15`) |
| M16 | `Sources/DockCore/EventStore.swift` | Append onto an unterminated line left by someone else, so the next event is swallowed into it | `EventStoreTests.testOversizedTrailingLineDoesNotBlankTheTail` | killed 2026-10-18: 1 failure / 1 test (`scripts/mutate.sh M16`) |
| M17 | `Sources/DockCore/DockState.swift` | Never forget the dock's controller once nothing remains on it | `DockPullFixtureTests.testControllerIsForgottenOnceEmpty` | killed 2026-10-18: 2 failures / 1 test (`scripts/mutate.sh M17`) |
| M18 | `Sources/DockCore/Event.swift` | Log and show a device name with its control and bidi characters intact | `EventStoreTests.testSubjectsAreMadePlainOnWriteAndOnRead` | killed 2026-10-18: 4 failures / 1 test (`scripts/mutate.sh M18`) |
| M19 | `Sources/DockCore/EventStore.swift` | Block on a FIFO planted at the log path (drop `O_NONBLOCK`), so the first `tail` at launch never returns | `EventStoreTests.testFifoAtLogPathIsRefusedWithoutBlocking` | killed 2026-10-18: 4 failures / 1 test (`scripts/mutate.sh M19`) |

-----

#AI/Claude
