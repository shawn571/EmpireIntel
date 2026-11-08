# EmpireIntel Phase 2 Plan: pre-25 features

DOC VERSION: 1.3.0  |  DATE: 2026-11-08  |  STATUS: **Phase 2 authorized for the pre-25 features only (D-027). P2-1 and P2-2 closed (D-029, D-032). P2-3 detailed in section 6, waiting for Q-P2-3.**

**Phase 2 builds EmpireIntel itself, limited to what works before any character reaches level 25:** unlock progress, rested XP, milestones ahead and "what next" (Requirements FR-PRE-1..4, FR-REST-1, FR-PROF-1, FR-ALT-1). It uses no Legacy API. Everything about Legacy points, perks and the cap waits for the level-25 run and Q-T4.

Out of scope for Phase 2: any Legacy API, trait-system calls, UI windows (commands only), the release pipeline (Stage 1 not authorized), GoldIntel (handled elsewhere).

## 1. Increments

| Increment | Delivers | Restart or reload | Gate (all must pass, then the user approves before the next one starts) |
|---|---|---|---|
| **P2-1 Foundation and own snapshot** | The `EmpireIntel` addon. Platform, Core and Store ported read-only from GoldIntel a21e071 (D-006; GoldIntel itself is not changed). A passive snapshot of the logged-in character: level, XP, rested XP, resting, professions. Taken at login, level-up, skill change, every 5 minutes and logout, with the TP-1 logout fallback (EI-E-08). Commands: `/ei` (this character), `/ei version`, `/ei off`, `/ei on`. **Saved-data format 1** (section 2) | **Full client restart** (new addon folder) | Tests pass under Lua 5.1 and 5.3. Static rules: WoW API only in `Platform/`, no third-party globals outside `Bridge/`, call denylist. Loads with no error next to GoldIntel and the check. `/ei` values equal what the game shows, on two characters |
| **P2-2 Alts from DataStore** | `Bridge/DataStoreBridge`, read-only: character list, level, class, rest XP, resting, last logout, the two primary professions with ranks. Merged with own snapshots by GUID (newest value wins, every value shows its source and age). Works without DataStore (own snapshots only). Command `/ei alts` | **Full client restart** (a new file in the TOC; corrected 2026-11-05) | Alts match DataStore and the live values (TP-1 T5 style). With DataStore disabled, `/ei alts` still answers. No change to saved-data format 1 (DataStore data is read live, never stored) |
| **P2-3 Views** | `/ei unlock`: highest level vs 25, closest character, levels to go. `/ei rest`: rested XP per character, measured and projected (projection labelled estimate). `/ei milestones`: next class milestone (25/45/60) per class and who is closest; crafting milestones (150/225/300) and gaps. Rules not confirmed by the client are labelled unverified | **Full client restart** (two new files; corrected 2026-11-08, see section 6) | Values match the game on two or more characters. Every estimate and unverified rule is labelled |
| **P2-4 What next** | `/ei next`: up to 10 suggestions. Without a plan file, the FR-PRE-4 defaults: reach 25 on the closest character, play rested characters, crafting milestones within reach. With `EmpireIntel_Plan/Plan.lua`, the plan's order wins. **The plan file format (Architecture section 7) is a contract and needs approval with this increment** | Full restart the first time the plan folder is added; `/reload` after edits | A 5-goal test plan gives the expected list. A plan with errors reports each bad goal and skips it |

Every increment ships as a zip, with the restart-or-reload statement and exact test steps in its README, as for the check. Collection stays passive: the user plays normally and sends the saved file after `/reload` or logout.

## 2. Saved-data format 1 (needs approval with P2-1)

One account-wide saved variable, `EmpireIntelDB`. No per-character file in Phase 2. Stored only on the user's computer and never committed.

```
EmpireIntelDB = {
  schema = 1,
  meta = { created = <time>, opens = <n>, version = '0.2.0', build = '1.60.1/70790' },
  off = nil | true,                          -- /ei off
  roster = {
    [<GUID>] = {
      name = 'First Last', realm = '<realm name>', class = 'PALADIN', level = 4,   -- realm added (user, Q-P2-1)
      xp = 86, xpMax = 2100,
      rest = 0 | nil,                         -- nil = unknown, never stored as 0 when the client returns nothing
      resting = false, restAt = <time>,       -- when rest was read (baseline for the projection)
      professions = { { name = 'Tailoring', skill = 75, max = 150, line = 197 } },
      lastSeen = <time>, src = 'self',
    },
  },
}
```

- Records are never deleted except by an explicit user command (a later increment, if wanted).
- Each later change to this shape is a format change and waits for the user's approval (D-019).
- Migrations use GoldIntel's copy-then-commit framework, starting at schema 1.

## 3. What the user will see (target output of P2-3 and P2-4; illustrative)

```
/ei unlock      Legacy unlock: C2 (Shaman) is level 9, 16 levels to go. Client rule: first character to 25.
/ei rest        C1 Paladin 4: 0 rested (measured now)  |  C2 Shaman 9: 1.2 levels (estimate, last seen 2 days ago)
/ei milestones  Next class milestone: Shaman 25 (C2, 16 levels), Paladin 25 (C1, 21 levels)  [rule unverified]
/ei next        1. Level C2: closest to 25 and rested.  2. ...
```

## 5. P2-2 in detail: alts from DataStore (for approval, Q-P2-2)

**P2-2 shows your other characters, read live from DataStore when it is installed, next to EmpireIntel's own records.** It adds no field to saved-data format 1: DataStore's values are read each time and never stored.

| Item | Design |
|---|---|
| New file | `Bridge/DataStoreBridge.lua`, the only file allowed to touch DataStore (static test) |
| DataStore calls (read-only getters only, all checked live by TP-1 T5/T6 on the launch build, EI-E-07) | `IterateCharacters`, `GetCharacterLevel`, `GetCharacterClass`, `GetRestXP`, `IsResting`, `GetLastLogout`, `GetModuleLastUpdateByKey`, `GetProfession1Name` / `GetProfession1Rank` / `GetProfession2Name` / `GetProfession2Rank`. The GUID comes from DataStore's own `DataStore_CharacterGUIDs` table, read only. Nothing that scans, sets or requests |
| Merge rule (per GUID) | EmpireIntel's own record wins when it is newer; DataStore's value is shown when it is newer or when EmpireIntel has never seen the character. Every value shows its source (`self` or `datastore`) and age. A DataStore name "Unknown" never replaces a known one. A character only DataStore knows is shown, not stored |
| Command | `/ei alts`: one line per character, newest first, e.g. `C2 Shaman 9 (Realm 7): rested 1.2 levels, 3 days ago [datastore]`. `/ei` (this character) is unchanged |
| Without DataStore | `/ei alts` lists EmpireIntel's own records only and says DataStore is not installed. Nothing fails |
| Faults | Any DataStore error is caught and shown as one "UNEXPECTED" line in `/ei alts`; the rest still answers |
| Install | Adding a file to the TOC needs a **full client restart** (the client reads the TOC only at start). The plan said `/reload`; that was wrong for a new file |
| Gate | Tests under Lua 5.1 and 5.3 (good, faulty and absent DataStore); live: `/ei alts` matches the game for every character you have, with DataStore on and off |

## 6. P2-3 in detail: views (for approval, Q-P2-3)

**P2-3 adds three read-only views over the characters `/ei alts` already lists: progress to the unlock, rested XP now, and the milestones ahead.** It adds no field to saved-data format 1 and makes no new game or DataStore call. Every number it works out, rather than reads, is labelled as an estimate.

What changed since section 1 was written: C1 reached level 25 on 2026-11-07, so the account has unlocked Legacy (EI-E-16). `/ei unlock` therefore reports the unlock first. The user's challenge list (Legacy_Rules.md) now gives the milestone rules, and EmpireIntelCheck 0.1.6 will confirm them from the game.

| Item | Design |
|---|---|
| New file `Core/Rules.lua` | One rules table, each rule tagged with its source: the 9 classes; class milestones 25 / 45 / 60; the 6 crafting skills by skill line id (Alchemy 171, Blacksmithing 164, Enchanting 333, Engineering 202, Leatherworking 165, Tailoring 197); craft milestones 150 / 225 / 300; the unlock level 25 [client, EI-E-02]; the rest rule (below). Ported from EmpireIntelCheck's own `Character.lua` rules (our code, not GoldIntel's) |
| New file `Core/Views.lua` | The three commands. The character list is the same merged list `/ei alts` uses (`Alts.Merge`: own records plus DataStore, newer value wins). No age filter (user, 2026-11-08) |
| `/ei unlock` | When a character is 25 or higher: "Legacy unlocked: C1 Paladin reached 25 (seen <date>)". Otherwise: the highest character against 25, the closest, the levels to go, and the XP left in its current level (exact; the XP for the whole climb needs the XP table, so it is not shown) |
| `/ei rest` | One line per character, as in the example below. **Measured:** the rested XP at the last reading, with its source and age. **Projected now:** measured + rate x time since, capped. Rate: 5% of the level's XP bar per 8 hours while resting, a quarter of that outside a rest area; cap 1.5 levels (classic rule, **unverified on Forever**, labelled "estimate"). Shown in XP and levels. The projection needs the XP bar at that level, measured by EmpireIntel. Without it the line says "no projection: XP bar not measured at level N". The character you are playing shows the live value, not a projection |
| `/ei milestones` | **Classes:** one line per class of the 9 (best character and level, next milestone, levels to go, "all done", or "no character yet"), with a count "N of 27 reached". **Crafting:** one line per crafting skill of the 6 (best character, skill and max skill, next milestone, gap, and "train to raise max" when the max skill blocks it), with "N of 18 reached". **Footer:** "About N Legacy points from these two groups (estimate). PvP, dungeons, raids and adventure (20 points) are not tracked in Phase 2." Gathering and secondary skills are not shown (they are not crafting milestones in the user's list) |
| Labels | Rules from the user's list read "[rule from your list; not yet confirmed by the game]" until a 0.1.6 read confirms them; then a later version changes the label only. Every projection or estimate says "estimate" |
| Not in P2-3 | Real Legacy values (points, challenges) in EmpireIntel: they need the Legacy reads the check is testing, and Phase 2 uses no Legacy API (D-027). The plan file and `/ei next`: P2-4 |
| Install | **Full client restart** (two new files in the TOC). Version 0.4.0 |
| Tests (Lua 5.1 and 5.3) | The rules table; each view with own records only, with DataStore, with a DataStore-only character, and with no characters. Rest projection: resting, not resting, the cap, unknown XP bar, a clock that went backwards (never negative), and the live character. Milestones: exactly on a milestone, between milestones, all done, max skill blocking. Every estimate line carries its label (test). Static: no new game call, no DataStore call outside the bridge, no saved-data write from the views |
| Gate | Tests pass. Live: (1) `/ei unlock`, `/ei milestones` and `/ei rest` match the game for every character. (2) Rest check: log out C2 in an inn and note `/ei rest`. After 8 hours or more, log in and compare the projection with the measured value. Within 10%: the rule is recorded as holding on Forever. Otherwise: the difference is recorded, and the label stays "unverified" |

Illustrative output (C1, C2 stand for character names):

```
/ei unlock      Legacy unlocked: C1 Paladin reached 25 (seen today). Next class milestone for C1: 45 (20 levels).
/ei rest        C2 Priest 6: measured 1506 XP (0.42 levels) 10 h ago, resting -> now about 1776 XP (0.49 levels) [estimate]
/ei milestones  Paladin: C1 25 -> next 45 (20 levels)  |  Priest: C2 6 -> next 25 (19 levels)  |  Warrior: no character yet
                Tailoring: C2 56/75 -> next 150 (94 to go; train to raise max 75)  ...  Classes 1 of 27, crafting 0 of 18
                About 1 Legacy point from these two groups (estimate). PvP, dungeons, raids and adventure (20) not tracked.
```

## 4. Questions for the user

| ID | Question | Recommendation |
|---|---|---|
| Q-P2-1 | Approve increment P2-1, including saved-data format 1 (section 2)? | **Approved**; P2-1 closed (D-029) |
| Q-P2-2 | Approve increment P2-2 as in section 5? | **Approved** 2026-11-06; built as 0.3.0 (D-030) |
| Q-P2-2c | Close P2-2 after the live test? | **Approved** 2026-11-08; closed (D-032) |
| Q-P2-3 | Approve increment P2-3 as in section 6? | Yes |
| Q-P2-3a | Are the 6 crafting skills Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking and Tailoring (no Jewelcrafting or Inscription on Forever)? | Yes, as far as known; the 0.1.6 read will show the game's own list |
| Q-P2-3b | Use the classic rest rule (5% of a level per 8 h resting, a quarter outside, cap 1.5 levels) as the labelled estimate, checked by the gate's rest test? | Yes |
