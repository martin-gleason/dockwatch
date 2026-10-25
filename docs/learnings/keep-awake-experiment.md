# Keep Dock Awake — the overnight experiment

Created: 2026-10-19 08:48 -05:00 · Edited: 2026-10-25 13:05 -05:00

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

**The KVM (learned 2026-10-21).** The chain at `0x02143xxx` (USB2.1 Hub, USB2.0 Hub, Das
Keyboard, USB Receiver) sits behind the owner's KVM switch. Every detach of that chain on
record is either a dock pull or the KVM switching to another machine, including the
20:43:33 event on the evening of night one, which this document had called the only
spontaneous drop; it is now read as a probable KVM switch. The chain is excluded from
flap and loss counts. Night four showed that the two hubs at `0x02243000` and `0x02243200`
(USB3.1 Hub, USB3.0 Hub) leave and return with the chain every time: they are the KVM
hub's USB 3 personality, not dock hubs, and go with it. Also excluded: an iPhone on the
Mac's own port (controller `0x01`), and the T1000-E while it is on the dock.

**Foreign holders seen so far:** Siri AI `UIIntelligenceSupport` (night one, 23 h, cleared
by `killall`), coreaudiod audio contexts with Music open but silent (night three, all
night). An on night counts for R1 only when `pmset -g assertions` at bedtime shows no
`PreventUserIdleSystemSleep` holder but DockWatch and powerd's display-on line, so Music
and any call app are quit before bed and the snapshot is saved.

## Night two, and the word "drop" split in two

The off night produced the loop exactly as the earlier nights did, and the app, running
this time, saw what the loop does to the dock: **the USB 3 SATA bridge (Down Under's
enclosure) re-enumerated at nearly every cycle**, 198 times in 199 cycles, each time
gone for 2 to 21 ms and back, and Down Under never unmounted. Nothing else on the dock
moved. The held evening before it (15:09 → 22:40, hold on, 0 cycles) had no bridge event
at all, and neither had night one.

That is two different things the D35 definition had been calling a drop, so from here
the counts are kept apart (D35 amended, still proposed):

- **Flap** — a dock device detaches and re-attaches within 1 s with no volume change.
  Counted per device. The bridge's flaps are the loop's fingerprint.
- **Loss** — a dock device absent for 5 s or more, or a volume unmounted. The day run's
  USB 3 side (d1) is the only loss on record.

R2's λ applies to losses. Flaps get their own rule, **R4**: flaps per cycle, off nights
against on nights. One off night already gives 0.99 flaps per cycle with the app
watching; an on night by construction has no cycle, and night one and the held evening
had no flap in 19 hours. The hold's effect on the fingerprint is not in doubt. What the
remaining nights measure is whether the fingerprint and the loss share a cause: the
loss rate per cycle so far is 1 in 259 (d1's 60 cycles and night two's 199).

**Running score (D35), 2026-10-20 10:30:** on — 19.2 h held, 0 cycles, 0 flaps, 0 losses
(night one unattributable, RR21; the evening of 2026-10-19 had DockWatch as the only
holder). Off — 17.2 h, 366 cycles, 2 losses, both in daytime loops at a charger-drop dark
wake (d1 after 60 cycles, d2 after 52), bridge flaps at nearly every cycle wherever the app
watched. Per hour, the off rate is 2 losses in 17.2 h; the chance of 19.2 held hours showing
none at that rate is e^(−2.2) ≈ 0.11, so the loss claim is not yet at p < 0.05. One more
valid on night with no foreign holder (night three) and no loss brings it to ≈ 0.03; that
night also settles R1. **The owner pays one dock replug per loss**, so off days are the
expensive arm: the loop runs by day exactly as by night, and both losses came by day.

**Running score (D35), 2026-10-22 08:10.** Night four (on) is the first valid, attributable
on night: 22.2 h held, 0 cycles, 0 flaps, 0 losses, four of four volumes in the morning,
DockWatch the only idle-sleep holder from 22:06 to 08:06. **R1 is settled** by the pair
night two / night four: with the hold off the Mac looped 199 times and the bridge flapped
198 times; with the hold on it did neither. On — 41.4 h held, 0 cycles, 0 flaps, 0 losses.
Off — 17.2 h, 366 cycles, 2 losses. At the off rate of 2 losses in 17.2 h, the chance that
41.4 held hours show none is e^(−4.8) ≈ 0.008. The strict figure counts only hours in
which DockWatch was the sole holder (the evening of 2026-10-19, 7.5 h, and night four's
overnight, 10 h): 17.5 h, e^(−2.0) ≈ 0.13. A co-holder does not weaken the hold; it shares
the credit, so the strict figure is the one to quote if challenged. One more on night with
Music quit from the morning adds about 22 sole-holder hours and takes the strict figure
below 0.02; an off night adds nothing to that figure and risks a replug.

**Running score (D35 plus L1), 2026-10-23 08:50.** L1 (lid shut, off) lost the dock's USB 3
side at the third cycle, 68 seconds after the first sleep, where d1 took 60 cycles and d2
52. One night cannot say the lid hastens the loss, and nothing in the power log
distinguishes L1's sleeps from night two's; what it does say is that the lid neither
prevents the loop nor protects the drives, and that a loss can come in the first minute.
Off — 27.3 h, 583 cycles, **3 losses**, all at a charger-drop dark wake. Cycles to loss:
60, 52, 3, and one run of 199 without (night two), about one loss in a hundred cycles.
On — 41.4 h, 0 cycles, 0 flaps, 0 losses. At the off rate of 3 losses in 27.3 h the chance
of 41.4 held hours showing none is e^(−4.6) ≈ 0.01; on sole-holder hours alone, ≈ 0.15.
**Each off run has now cost a replug three times out of four.** The remaining question
is L2: whether the hold keeps the dock with the lid shut, which is how the owner lives.

**L2 answers it, 2026-10-25 10:30.** The same lid-shut configuration that lost the dock at
the third cycle with the hold off (L1) ran 24.8 hours with the hold on and never slept,
never flapped, never lost a volume. That is the O13 lid check: on the dock, with AC and
the Dell display, a shut lid is clamshell mode, idle sleep is the only sleep in play, and
the assertion stops it. RR1 still stands for the other case, lid shut off the dock on
battery, where the Mac sleeps on the lid and no assertion applies; that case has no dock
to lose. **Score.** On — 66.2 h held, 0 cycles, 0 flaps, 0 losses. Off — 27.3 h, 583 cycles,
3 losses. At the off rate the chance of 66.2 held hours showing none is e^(−7.3) ≈ 0.001;
on sole-holder hours alone (26.7 h) it is e^(−2.9) ≈ 0.05. R1 settled, R2 met on the full
count and at the threshold on the strict one, R4 0 flaps per cycle against 0.99. **The
series stops here** under D35's stop rule. What it leaves for the register: D35 ratified
as run, D36 (the hold on by default while docked) now carries L1 and L2 as its evidence,
and the hold should be read as the dock's protection, not a convenience.

**What d2 adds.** A second branch flaps, and it flapped only today: the dock's USB 2 root
hub (0x02100000) with its child hub, the watch cable and the T1000-E, 77 times from the
first wake after the 08:18 idle sleep, each absence seconds long and each return a
`USBWakeup` dark wake, so the dock was waking the Mac on its own schedule for an hour
before the USB 3 side went. Night two had the same devices attached and no such flap.

## The lid-shut arm (pre-registered 2026-10-22, before the night)

The owner's habit is the lid shut. D35 kept it open so that an idle-sleep assertion
would be the only thing between the Mac and sleep (RR1). The lid-shut arm asks whether
the lid changes anything, in two nights that are not D35 nights and are scored apart:

- **L1, lid shut, hold off**, app running. Prediction, written first: on the dock the Mac
  is on AC with the Dell display, so a shut lid is clamshell mode, not sleep. Every
  `Clamshell Sleep` in the power log (five, all 2026-10-18) says `Using Batt`: the Mac
  was off the dock each time. L1 should therefore idle-sleep after `sleep 1` exactly as
  night two did and run the loop: 50 or more cycles, the SATA bridge flapping about once
  a cycle. If a loss comes it is the third in an off run and costs a replug; if the night
  runs 150 cycles with none, the per-cycle loss rate is lower than d1 and d2 suggested.
  Valid as an off control by D35's rule (50 or more cycles, no foreign holder). The KVM
  stays on the Mac: switched away, the Mac has no display and a shut lid sleeps it at
  once, which is a different sleep and a different night.
- **L2, lid shut, hold on.** The product question, and the O13 lid check: RR1 says the
  hold is absent on battery with no external display; on the dock in clamshell it should
  hold, and nobody has watched it do so for a night. No replug risk. Prediction: 0 cycles.

**Foreign holders, added.** The Claude desktop app takes `NoIdleSleepAssertion "Electron"`
for minutes at a time while in use; coreaudiod takes aggregate-device and built-in
speaker and microphone contexts during a call. Both are daytime transients; Zoom and
Music quit at bedtime, and the snapshot decides.

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
| 2 | 2026-10-19 → 20 | off | **yes** (199 cycles, no foreign holder) | 199 | 197 | 135 | 47 | **0 lost; 198 flaps** of the USB3.0 SATA Bridge, each detach re-attached within 2–21 ms, 125 of them within 3 s of a dark wake and the rest after a full wake; no volume ever unmounted | 0 | 4 of 4 | none (backupd, transient) | window from `hold.off` 22:40:17; idle sleep 22:59:06; the T1000-E was back on the dock from 18:59 (owner); an iPhone on the Mac's own port came and went 19:39–23:12 and is not dock traffic |
| d2 | 2026-10-20 day, 08:10 → 10:24 | off | yes (loop ran, app watching) | 107 | 106 | 54 | 28 | **1 loss** at 09:24:18, at a charger-drop dark wake after 52 cycles: the USB 3 root hub and everything under it, plus the dock identity, keyboard, receiver and Chroma; the USB 2 side returned by itself at 09:37:44, the USB 3 side never did. Flaps: 53 of the SATA bridge, and 77 seconds-long ones on the USB 2 root-hub branch (hub 0x02100000, hub 0x02110000, watch cable, T1000-E) from 08:19:24, each re-attach a `USBWakeup` dark wake | 4 | 0 of 4 | none | owner away 08:10–10:24; idle sleep 08:18:15; diskarbitrationd removed the four disks 1.5 s after the USB terminations and unmounted their dangling volumes, which Finder reports as "not ejected properly"; the Mac then cycled 55 more times with wake storms until the owner sat down |
| 3 | 2026-10-20 → 21 | on | **invalid** | 0 | 0 | 0 | 0 | 0 on the dock; the keyboard chain detached 21:29:20 and returned 09:22:54, which is the owner's **KVM** switching (see below), excluded | 0 | 0 of 4 (none attached) | coreaudiod audio contexts for 19–23 h (Music open, nothing playing); Music playback 44 min in the morning | hold on from 16:03:08, but the dock's USB 3 side had never been replugged after d2's loss, so no drive was attached all night; no bedtime snapshot; a foreign holder all night (RR21 again). Replug 09:53:16–09:53:49 restored everything |
| 4 | 2026-10-21 → 22 | on | **yes**, and attributable overnight | 0 | 0 | 0 | 0 | 0 on the dock. Excluded: the KVM chain switched six times (15:26, 17:58, 18:48, 22:05, 22:07, 08:06); the T1000-E re-enumerated from its bootloader 18:19–18:35 while the owner worked on it; an iPhone on the Mac's own port 18:26–20:21 | 0 | 4 of 4 | coreaudiod (Music open) beside DockWatch by day until the owner quit it at 22:06:41; from then to the morning read DockWatch alone, with backupd's hourly transient and one `caffeinate` of two minutes at 23:02 | window from `hold.on` 09:53:24 after the replug, 22.2 h, one assertion id 0x1000080d8 throughout; bedtime snapshot `night-2026-10-21.txt` at 22:06 clean; TM ran. **Deviation:** the T1000-E was put back on the dock at 14:34:48 and stayed all night (D35 says off); it did nothing overnight. The SATA bridge, which flapped 198 times on night two, did not flap once |
| L1 | 2026-10-22 → 23, **lid shut** | off | **yes** as an off control (217 cycles, no foreign holder); not a D35 night | 217 | 217 | 138 | 58 | **1 loss** at 22:53:38, at the third cycle's charger-drop dark wake, 68 s after the first sleep: the whole USB tree of the dock (both root hubs, the dock identity, the Chroma, the LAN, the two-bay enclosure, the SATA bridge, the keyboard chain). The USB 2 root hub returned at 22:53:39 and flapped with its child hub and the watch cable until 22:55:19 (each return a `USBWakeup` dark wake, as on d2); the dock identity, Chroma and keyboard chain returned at 22:55:26; the USB 3 root hub never did. The dock re-identified itself once more at 07:40:49 at a wifibt dark wake, USB 3 side still absent. Bridge flaps before the loss: 2, one per cycle | 4 at 22:53:40 | 0 of 4 | none (powerd, backupd, runningboardd one summary each) | lid shut 22:34, hold off 22:34:02; the KVM switched at 22:34:14 (excluded); display off 22:45:06; idle sleep 22:52:30 (clamshell mode held the Mac awake 18 min, as predicted; no `Clamshell Sleep`); the Mac then cycled 214 more times with nothing left to lose; full wake 08:40:40. Finder reported four disks not ejected properly |
| L2 | 2026-10-24 → 25, **lid shut** | on | **yes**, attributable from midnight | 0 | 0 | 0 | 0 | 0 on the dock. Excluded: an iPhone on the Mac's own port 11:19–11:40, a USB serial adapter on the Mac's own port 14:53 | 0 | 4 of 4 | caffeinate in five-minute wrappers 20:00–23:30 and backupd's hourly minute; from 00:00 to 09:00 DockWatch alone | the owner re-docked 09:28:26 on 2026-10-24 (the replug), hold re-took itself, one assertion id 0x10000a01d for 24.8 h; the lid was shut overnight (powerd's `lidopen` assertion fires at 10:15:35 on opening, none between); last display-off 00:34:24. No bedtime snapshot was saved, so the 15-minute Summary lines stand in. Prediction (0 cycles) correct: **in clamshell mode on the dock the hold works** |
