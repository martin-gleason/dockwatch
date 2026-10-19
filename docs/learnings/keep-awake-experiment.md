# Keep Dock Awake — the overnight experiment

Created: 2026-10-19 08:48 -05:00 · Edited: 2026-10-19 15:43 -05:00

**What this is.** The record of every night the hold is tested, the protocol the nights
follow (D35), and the rule that decides what the nights mean, written down before the
nights are run so the reading cannot be fitted to the result. One night is logged below.
The project's reason to exist is the number in the "charger drops" column; the question
the owner asked after night one, *is the tool working or was it chance*, is really two
questions, and they need different evidence:

1. **Mechanism** — does the hold keep the Mac out of the sleep / dark-wake loop? This is
   a deterministic claim about an API (FR5, F3) and needs one honest pair of nights.
2. **Outcome** — does keeping the Mac out of the loop stop devices dropping? This is a
   claim about the dock, and it needs a base rate nobody has measured yet.

## Night one — 2026-10-18 → 2026-10-19

**The hold.** `hold.on` 20:45:12 (the owner's toggle, O13 start); released 20:54:29 by the
owner's dock pull and re-taken 20:55:15 on the replug. From 20:55:15 to the morning read
at 08:37:29 one assertion (`id 0x100009cc3`) was in force without a gap: powerd summarised
it every 15 minutes, 49 times. The window below runs from that second `hold.on`.

**The power log, same clock window (20:55:15 → 08:37:29), every night the log holds.**
Counted from `pmset -g log` lines that carry a timestamp; continuation lines are skipped.
"wifibt" is the other dark-wake reason on this machine, worth counting because night
13→14 had its whole loop from it and none from the charger.

| Night | Sleep entries | Dark wakes | Charger drops (`acdetach`) | wifibt wakes | Idle-sleep holders |
|---|---|---|---|---|---|
| 12→13 | 150 | 150 | 77 | 41 | none |
| 13→14 | 127 | 127 | 0 | 103 | none |
| 14→15 | 7 | 6 | 4 | — | none (Mac mostly off the dock) |
| 15→16 | 217 | 213 | 150 | 39 | none |
| 16→17 | 196 | 196 | 122 | 58 | none |
| 17→18 | 255 | 255 | 153 | 85 | none |
| **18→19, held** | **0** | **0** | **0** | **0** | DockWatch 49 summaries; **Siri AI 49 summaries** |

**The app's log.** After the replug settled (last line 20:55:42, Backups mounted) the log
has no line at all until the morning: no detach, no unmount, no power change. All four
dock volumes were mounted at 08:37. Time Machine ran all night to the dock's Backups
volume (backupd released idle-sleep assertions at 21:17, 22:33, 23:34, 00:38, 00:47,
01:32, 02:32, 03:28, 04:24, 04:46, 05:20, 06:24 and three more), which is a working drive,
not only a present one. The display slept 21:24→22:59 and 00:43→08:32; display sleep
did not disturb the dock.

**Drops that night, by the D35 definition (a dock device detaching while the dock's own
device stays and no charger loss within 2 s):** none in the window. The same evening,
before the window, there were three, and they are the only spontaneous drops on record:

| When | What | Context |
|---|---|---|
| 20:43:33 | Das Keyboard, USB Receiver, USB2.0 Hub, USB2.1 Hub, USB3.0 Hub, USB3.1 Hub — the USB 2 chain and its hubs; back at 20:49:38 | 82 s after a wake: clamshell sleep 20:41:05 on battery (23 %), dark wake 20:42:08 "USB-C_plug" (the dock plugged into a sleeping Mac), full wake 20:42:11. Hold off. |
| 20:51:27 | Apple Watch Magnetic Charging Cable | the owner's hand (O15 notification check) |
| 20:51:40–44 | T1000_E_BOOT, three times in four seconds | hold on, Mac awake. A board sitting in its bootloader; it re-enumerates on its own |

## What night one proves, and what it does not

**Proven.** The hold holds: one assertion, eleven hours forty-two minutes, through two
display sleeps and a Time Machine run. A night with no sleep cycle was a night with no
drop and no charger loss, against five earlier nights of 150 to 255 cycles each. The
toggle, the log, the counters and the eject all behaved from the installed bundle.

**Not proven, 1: that DockWatch is what kept the Mac awake.** A second process held the
same assertion all night. `pmset -g assertions` at 08:37 lists
`pid 1192(Siri AI) … 23:17:13 PreventUserIdleSystemSleep named: "UIIntelligenceSupport"`:
taken about 09:20 on 2026-10-18, still held, and summarised beside DockWatch's in every
15-minute block. No earlier night in the log has it. With the toggle off, that assertion
alone would have kept the lid-open Mac from idle sleep last night. So night one cannot
tell the two holders apart (RR21). `pmset -g` this morning says it plainly:
`sleep 1 (sleep prevented by DockWatch, caffeinate, Siri AI, powerd)`.

**Not proven, 2: that sleep cycles are what drop the devices.** Nothing recorded dock
devices before 2026-10-18 10:30, so the drop rate per night is unknown. The only clean
spontaneous drop on record (20:43:33) came 82 s after a wake, which fits RR4's hypothesis
and is also one event. A night with zero drops is consistent with "the hold stopped them"
and with "most nights have none".

**Not proven, 3: chance.** Without a base rate there is no probability to attach to one
clean night. The protocol below is how the base rate gets measured.

## The protocol (D35, proposed)

Alternate nights: **off, on, off, on, off, on** — three pairs. Night two (2026-10-19) is
**off**, so the first thing learned is whether the Mac sleeps at all without the hold,
which settles RR21 before anything else is counted.

Every night, the same conditions:

- Lid open, dock attached as the Mac's charger, the same devices on it every night. Unplug
  the T1000-E for the series: a device re-enumerating from its bootloader is noise in the
  drop count and may reset its hub.
- DockWatch running (it logs either way). **Keep Dock Awake** set for the night before
  21:00 and left alone until morning. On an **on** night the ring's hub is filled.
- At bedtime: `pmset -g assertions > ~/Desktop/night-$(date +%F).txt`. On an **off**
  night, if that file lists any `PreventUserIdleSystemSleep` other than powerd's
  display-on one, log out and back in (or restart) and take the file again — a stuck
  holder makes the night an invalid control, not a result.
- No agent session overnight: Claude Code wraps each of its commands in
  `caffeinate -i -t 300`, five minutes of idle-sleep hold each.
- Morning, before anything is touched: the report (below), and `ls /Volumes`.

**Measures per night:** sleep entries, dark wakes, charger drops, wifibt wakes, idle-sleep
holders (all from `pmset -g log`); drops by device, volumes that disappeared, volumes
mounted in the morning (from the app's log and `/Volumes`).

**Validity.** An **on** night counts only if sleep entries are 0 and one DockWatch
assertion id spans the window. An **off** night counts only if the Mac slept at least
50 times in the window; an off night that never slept is recorded with its holders and
is not a control.

**Decision rules, fixed now.**

- **R1, mechanism.** Every valid on night: 0 sleep entries, DockWatch the only holder.
  Every valid off night: the loop (≥ 50 cycles). One valid pair settles it; two confirm.
- **R2, outcome.** Let λ be drops per valid off night (all off nights pooled). The chance
  that m on nights show no drop if the hold does nothing is e^(−λm):

  | λ (drops per off night) | on nights for p < 0.05 |
  |---|---|
  | 2 | 2 |
  | 1 | 3 |
  | 0.5 | 6 |
  | 0.25 | 12 |

  Three pairs decide at λ ≥ 1. Below that the series cannot decide inside a week.
- **R3, the base rate is too low for nights.** If three valid off nights show no drop,
  the rate is under about one a night (upper 95 % bound for 0 of 3) and the question moves
  to a **dose test**: an off day. Hold off, lid open, dock attached, Mac left idle from
  the morning; with `sleep 1` after a ten-minute display sleep it enters the loop within
  a quarter of an hour and the day of 2026-10-18 shows 62 cycles between 08:37 and 20:55.
  Count drops per cycle. A rate per cycle, not per night, is what RR4 actually claims.
- **Stop.** After three pairs, or as soon as R2 is met.

**What would falsify the hold.** A valid on night with a drop. A valid off night with
≥ 50 cycles and no drops, three times (the hold then prevents the loop but the loop was
not the problem, and RR4 is the finding).

## The morning report

Until the script lands (C4), these are the commands. The window starts at the last
`hold.on` on an on night and at 21:00 on an off night.

```sh
L=~/Library/Containers/com.martingleason.dockwatch/Data/Library/Logs/DockWatch/events.jsonl
pmset -g log > /tmp/pmset.log
# sleep / dark-wake / charger counts inside the window, timestamped lines only
awk -v s="2026-10-19 21:00:00" -v e="2026-10-20 08:00:00" \
  '/^20[0-9][0-9]-/ { t=$1" "$2; if (t>=s && t<e) { if ($5=="Sleep") sl++; if ($5=="DarkWake") dw++; if (/acdetach/) ac++; if (/wifibt/) wb++ } }
   END { print "sleep="sl+0, "darkwake="dw+0, "acdetach="ac+0, "wifibt="wb+0 }' /tmp/pmset.log
# who held idle sleep
grep -E "Summary PreventUserIdleSystemSleep" /tmp/pmset.log | awk '$1" "$2 >= "2026-10-19 21:00:00"' | sed -E 's/.*PID [0-9]+\(([^)]*)\).*/\1/' | sort | uniq -c
# the app's night
grep -E '"ts":"2026-10-2[0]T0[0-9]|"ts":"2026-10-20T0[2-9]' "$L" | grep -E 'detached|disappeared|unmounted|power\.' ; ls /Volumes
```

The classifier that produced the drop table above (two-second grouping, dock pull and
charger loss excluded) is what C4 turns into `scripts/night_report.sh`.

## Questions for the owner

1. At 20:49:38 the six USB 2 devices came back. Did you re-seat the keyboard's hub, or did
   they return on their own? (It decides whether that drop self-heals.)
2. Is the T1000-E dispensable for the series? If it must stay, its lines are excluded from
   the drop count and it is noted every night.

## Nights

Append-only. "Valid" is by the rules above.

| # | Night | Mode | Valid | Sleep | Dark wakes | Charger drops | wifibt | Drops (devices) | Volumes gone | Morning volumes | Holders besides DockWatch | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-10-18 → 19 | on | yes as an on night; **unattributable** (RR21) | 0 | 0 | 0 | 0 | 0 | 0 | 4 of 4 | Siri AI (UIIntelligenceSupport, 23 h) | window from 20:55:15; T1000-E attached; TM ran |
| d1 | 2026-10-19 day, 09:15 → 15:01 | off | **off-run valid for the power log; the app was not running** (A4) | 73 | 68 | 35 | 0 | **1** — the dock's whole USB 3 side at 14:53:54–14:54:13: SATA bridge, two-bay enclosure, LAN, USB 3 hubs; USB 2 side and the Thunderbolt link stayed up | 4 | 0 of 4 at 15:02 | none; Siri AI cleared by `killall` at 09:0x | the owner's dose day. Idle sleep 09:18:07. First disks removed 14:53:54 with the Mac awake and the display dark since 14:47:44, the rest at the 14:54:13 charger-drop dark wake, after 60 cycles and 29 charger drops. Dock lighting flashing purple. The owner found the **MacBook's built-in keyboard** dead on sitting down, the first time it has ever failed (not the Das Keyboard on the dock, which was enumerated throughout). The power log shows the 15:01:11 full wake came from the internal trackpad/keyboard and that the vanished disks' SCSI driver was still acknowledging sleep and wake slowly (763 ms) through the loop, so a Mac-side stall during that wake is the leading reading; it is a separate symptom from the dock's USB 3 side dropping and is recorded as one. Recovery: app relaunched, cable replugged 15:08, all four volumes back by 15:09:03 |
