# CLAUDE.md — DockWatch

Created: 2026-10-18 10:55 -05:00 · Edited: 2026-10-18 10:55 -05:00

DockWatch is a Mac menu bar tool that logs what the Thunderbolt 4 dock does and keeps it from falling asleep.

@docs/conventions.md

---

## The documents

| Artifact | Role | Path |
|---|---|---|
| **CLAUDE.md** | standing rules. Loaded every session. | root |
| **conventions.md** | the grammar: axes, IDs, merge discipline. Vendored + pinned. | `docs/conventions.md` |
| **conventions-local.md** | this project's harness commands and stack. | `docs/conventions-local.md` |
| **intent.md** | the proto-spec: problem, outcome, constraints, rejected framings. Baseline. | `docs/intents/intent.md` |
| **SPEC.md** | the contract. Vision sentence, `FR`/`NFR`. **Immutable.** | `docs/specs/SPEC.md` |
| **Register** | `D` · `RR` · `O` · `H` · `M` | `docs/plans/00-register.md` |
| **Status** | the project as one chart. **Generated, never hand-edited.** | `docs/plans/00-status.md` |
| **Plan / Review** | per unit, at the gate / after | `docs/plans/F<N>.md` · `docs/reviews/F<N>.md` |

Where the spec and the register conflict, **the register wins**.

---

## Non-negotiable

- **Scope is `SPEC.md` FR1–FR8 plus ratified deltas (D11 adds FR9, eject).** Eject-before-sleep, auto-remount, schedules, dock pickers, hub port power cycling and lighting are future milestones. Do not build or stub them; open a `D<n>` and stop.
- **Never claim control the API does not give.** The app holds a power assertion on the Mac. It cannot power-cycle, renegotiate or wake the dock, and no menu text, log line or PR may say it does.
- **`DockCore` never imports AppKit.** Hold policy, dock matcher, event model and queries are pure and tested offline.
- **No polling timers.** Device, volume, power and sleep state arrive through system callbacks (NFR2).
- **No third-party dependencies** without a ratified `D<n>`.
- **The agent never edits `SPEC.md`.** Propose deltas; the owner ratifies.

---

## Authorization

1. Specs and plans are context, not work orders.
2. Work begins only when Marty gives explicit instruction in the current session.
3. Passing tests inside a feature loop authorizes completing **that loop**, nothing more.
4. **Gates need a verbal yes.** Every feature and milestone boundary is a gate.
5. **Defect fixes proceed without a gate.** Everything else waits.

---

## Learning level: 5% (locked 2026-10-18, D6)

The agent authors everything; Marty reviews every PR, does not write Swift, and adds a "what I learned" comment to each. **Every PR description is written for a reviewer who can read code but not Swift**: what changed, why, what to test, what could break, and a closing **For the review** section naming the one or two things worth learning from the change. The dial is the `owner` field on every task.

---

## Workflow

1. **Gate → plan.** Ultrathink. Re-read `SPEC.md` and the register, write `docs/plans/F<N>.md`, wait for the yes.
2. **Build.** Branch `F<N>/<slug>`, conventional commits with the structural ID in scope, never a register ID. Units with two or more independent tasks run as a Workflow (ultracode); strictly sequential units run serially and the plan says so.
3. **Adversarial review** with `.claude/agents/adversarial-reviewer.md` at the end of every feature and the start of every session. Never resume blind.
4. **Verify with evidence.** `swift test` output in the PR, plus the manual check the plan names, with the command that proves it (`pmset -g assertions`, the log file, `footprint`). Assertions are not evidence; a mutation row is `run` only after its test was seen red.
5. **PR.** Rebase-and-merge only.

**Read before you overwrite.** Never use shell redirection to get past the Write tool's guard.

**The shell monitor at `~/dockwatch` is the control instrument until F2.** Its `~/Library/Logs/dockwatch/events.log` and `pmset -g log` are the ground truth the app's log is checked against; once they agree, F2 removes it (D13).

**Ask Marty only when all three hold:** not already answered in the spec, the register, or the plan · the answer changes what gets built · it cannot be resolved by investigation. Otherwise decide, say so plainly, and let him overturn.

---

## Hooks

| Hook | Surface | Status |
|---|---|---|
| `swift test` passes | pre-commit + CI | built (C1-T3, C1-T6) |
| Assertion count not below `Tests/ASSERTION_FLOOR` | pre-commit + CI | built (C1-T3, C1-T6) |
| No register ID in a commit, branch, or PR title | commit-msg | built (C1-T3) |
| Secret scan | pre-commit | built, pre-commit only (C1-T3) |
| Status page regenerates clean | pre-commit (needs the upstream generator) | built locally (C1-T3); not in CI |

**Prove every hook by breaking it first.**

---

## Stack

Swift 5.9 language mode on the Swift 6.4 toolchain (Xcode 27.1) · SwiftPM · AppKit · macOS 14+ · SwiftLint available at `/opt/homebrew/bin/swiftlint`, not yet configured · license MPL-2.0 (D14) · App Sandbox and hardened runtime from F5 (D15). Layout: `DockCore` library + `DockWatch` executable + `DockCoreTests`; `scripts/build-app.sh` wraps the binary as an ad-hoc signed `.app` (mirrors HueBar).

-----
2026-10-18

#AI/Claude
