# Handoff — planning questions for the owner, 2026-10-18

Created: 2026-10-18 10:55 -05:00 · Edited: 2026-10-18 10:55 -05:00

Written instead of a numbered wall in the terminal. Each question is also an `O<n>` in the register; answering here or in chat closes it. **Where no answer arrives before the gate, the agent proceeds on the stated default and says so in the PR.**

---

## Q1 — The vision sentence (`O1`, P0)

> DockWatch is a Mac menu bar tool that logs what the Thunderbolt 4 dock does and keeps it from falling asleep.

Your words from the session, in one sentence. Ratify, or rewrite it here: DockWatch is a native Mac Menu Bar tool that logs the activity of the thunderbolt 4 dock, keeps it from falling asleep, and lets you eject or remove conneted devices quickly and safely.

_Answer:_
Your words from the session, in one sentence. Ratify, or rewrite it here: DockWatch is a native Mac Menu Bar tool that logs the activity of the thunderbolt 4 dock, keeps it from falling asleep, and lets you eject or remove conneted devices quickly and safely.
## Q2 — Learning level (`O2`, P1)

Proposed **5%**: the agent authors everything, you review every PR, and PR descriptions are written for a reader who does not write Swift. Reason: due today. Lock, or name a different level:

_Answer:_
5% is good. Review PRs and add "what I learned" to each. as a comment.

## Q3 — Holding the Mac awake around the clock (`O3`, P1)

With the toggle on and the dock attached, the Mac will not idle-sleep at night or while you are away. The display sleeps; the fans and energy use are those of an idle Mac. A schedule window ("hold only 07:00 to 23:00") is out of scope for MVP. Acceptable for MVP, or should the schedule move in?

Default if unanswered: acceptable; the toggle ships **off** so nothing changes until you turn it on.

_Answer:_
For MVP: No scheduling. We will add that in v1.5
## Q4 — Gate for C1 and F1 (`O4`, P0)

Build order proposed for today: C1 (harness, T1–T5) → F1 → F2 → F3 → F5 → F4. F4 is cut first if the day runs out. A yes here opens C1 and F1 only; F2 onward each get their own yes.

_Answer:_
Yes.
## Q5 — The shell monitor (`O5`, P2)

`~/dockwatch` keeps running as the control instrument during the MVP. Once F2's log is shown to agree with it, should the app replace it, or do both stay?

Default if unanswered: both stay until you say otherwise.

_Answer:_
Replace. it's a real test.
## Q6 — GitHub (`O6`, P2)

Repository name `dockwatch` under your account, private until you say public, pushed when you say. C1-T6 (CI and branch protection) waits on this.

_Answer:_
Public, copy left and appropriate for uploading ot the mac os app store.