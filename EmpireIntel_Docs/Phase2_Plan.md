# EmpireIntel Phase 2 Plan: characters, views and the route planner

DOC VERSION: 1.14.0  |  DATE: 2026-11-20 (S-072)  |  STATUS: **Phase 2 authorized for the pre-25 features only (D-027). P2-1, P2-2, P2-3 and P2-4a closed (D-029, D-032, D-041, D-060). Section 7 superseded (D-054). Section 8 approved (D-055, D-056); the window mockup approved (D-060). Section 9 approved (D-061), built as 0.7.0, retest 0.7.1 (D-063, D-064). Section 10: P2-4c and P2-4d approved with conditions (D-065); each starts only after the one before closes (P2-4b, then P2-4c). Section 11: the user's items 5-7 of D-066, answered (D-069) with plan inputs under D-068 (third-party add-ons); nothing started until P2-4b closes.**

**Where to look (2026-11-16):** sections 1-8 are the history of P2-1 to P2-4a (all closed or superseded); **section 9** is P2-4b, the plan window (built, in its live retest as 0.7.4); **sections 10 and 11** are the approved next increments P2-4c, P2-4d and P2-4e and their inputs; **section 12** is the realm-identity plan after build 71037 (P2-4r, approved D-075); **section 13** is the Fastest route's rules R-1..R-7 (D-075, for approval).

**Phase 2 builds EmpireIntel's character views and the Legacy route planner:** unlock progress, rested XP, milestones ahead, the route and the plan window (Requirements FR-PRE-1..4, FR-REST-1, FR-PROF-1, FR-ALT-1, FR-PLAN-1..3). P2-1 to P2-3 use no Legacy API. **P2-4 uses the Legacy reads proven in P3-1, on command only, under the Legacy lock rule (section 7.3, D-052).** Perks and the per-character cap wait for Q-T4. (It was first authorized for "pre-25 features" only, D-027; the account has since unlocked Legacy, and the planner was approved on top, D-054, D-055.)

Out of scope for Phase 2: any Legacy call beyond the P3-1 reads (used by P2-4 only, D-052), trait-system calls, the release pipeline (Stage 1 not authorized), GoldIntel (handled elsewhere). (The 2026-11-05 text also excluded UI windows; the window was approved later, D-054, D-055, D-060.)

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
| Not in P2-3 | Real Legacy values (points, challenges) in EmpireIntel: they need the Legacy reads the check is testing, and P2-1 to P2-3 use no Legacy API (D-027; P2-4 uses the P3-1 reads, D-052). The plan file and `/ei next`: P2-4 |
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
| Q-P2-3 | Approve increment P2-3 as in section 6? | **Approved** 2026-11-08 (D-033) |
| Q-P2-3a | Are the 6 crafting skills Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking and Tailoring (no Jewelcrafting or Inscription on Forever)? | **Approved** 2026-11-08; the user will report if the pane lists others |
| Q-P2-3b | Use the classic rest rule (5% of a level per 8 h resting, a quarter outside, cap 1.5 levels) as the labelled estimate, checked by the gate's rest test? | **Approved** 2026-11-08 |
| Q-P2-3c | Close P2-3? | **Closed** 2026-11-08 (D-041) |
| Q-P2-4, a-e | P2-4 "What next": see section 7.8 | **Approved** 2026-11-08, with the Legacy lock rule (D-052) |

## 7. P2-4 in detail: "What next" (for approval, Q-P2-4) -- SUPERSEDED by section 8 (D-054)

**Approved 2026-11-08 with the Legacy lock rule (D-052); built as EmpireIntel 0.6.0 plus EmpireIntel_Plan 1.** Requirements: FR-PLAN-1, FR-PLAN-2, FR-PRE-4, NFR-2, NFR-3. Replaces the draft in Architecture.md section 7 on approval (that draft had a `cap` field, perk goals and `restedBefore`, which this plan drops or defers).

### 7.1 What P2-4 adds

| Part | What it does |
|---|---|
| `/ei next` | Up to 10 suggestions, one line each: the goal, where the character is now, the gap, the next step, and what it earns. Read on command only. Nothing is saved |
| Plan file | A separate addon folder, `EmpireIntel_Plan`, holding `Plan.lua`, which the user edits with a text editor. EmpireIntel updates never touch it (D-014) |
| Defaults | Without a plan file, the FR-PRE-4 suggestions (7.4) |
| Validation | Each bad goal is reported as one `UNEXPECTED` line naming its number, and skipped; never guessed (R-17) |
| Versions | EmpireIntel 0.6.0. EmpireIntel_Plan 1 (format 1). EmpireIntelCheck unchanged |

No new game call: `/ei next` uses the same records as `/ei alts`, `/ei rest` and `/ei milestones` (EmpireIntel's own records plus DataStore through the bridge), and, for the challenges goal, the Legacy reads of P3-1 (`Platform/Legacy.lua`, on command only; Q-P2-4b approved under the lock rule). Saved-data format 1 is unchanged.

### 7.2 The plan folder

```
Interface\AddOns\EmpireIntel_Plan\
  EmpireIntel_Plan.toc   shipped; never edited
  Marker.lua             shipped; one line: EmpireIntelPlanFolder = 1
  Plan.lua               yours; the only file you edit
```

- The TOC loads `Marker.lua`, then `Plan.lua`. It has `## Interface: 16001` and no dependency on EmpireIntel, so either addon works alone.
- EmpireIntel reads the global `EmpireIntelPlan` only when you type `/ei next`, so load order does not matter.
- The marker tells two cases apart without any new game call: marker present but no `EmpireIntelPlan` means Plan.lua did not load (a Lua error in the file); no marker means the folder is not installed.
- Plan.lua is Lua that the game runs. Only the `EmpireIntelPlan` table is read; anything else in the file is ignored by EmpireIntel.
- Character names in your Plan.lua stay on your computer. The repository holds only the example with placeholders.

### 7.3 Plan file format 1 (a contract; needs approval)

```lua
-- EmpireIntel_Plan/Plan.lua: your goals, most important first. Save, then /reload.
EmpireIntelPlan = {
  version = 1,
  goals = {
    { char = 'C1', level = 45, note = 'Experienced Paladin' },
    { char = 'C2', level = 25 },
    { char = 'C2', profession = 'Tailoring', skill = 150 },
    { char = 'C2', rested = 1.0 },
    { account = true, challenges = 5 },
  },
}
```

| Goal kind | Keys | Met when | Next step shown |
|---|---|---|---|
| Level | `char`, `level` (2-60) | the character's level >= level | levels and XP to go; rested XP now [estimate] |
| Skill | `char`, `profession` (name as the game shows it), `skill` (1-300) | that profession's skill >= skill | points to go; "train to raise max N" when the cap is in the way |
| Rested | `char`, `rested` (levels, 0.05-1.5) | rested XP now (live, or the projection) >= rested | about how many hours more in an inn [estimate] |
| Challenges | `account = true`, `challenges` (1-65) | Legacy challenges completed >= challenges | how many to go and the closest challenges (as `/ei legacy`) |

**Legacy lock rule (user, 2026-11-08, D-052):** “Before any character on the account reaches 25, Legacy is not available: the challenges goal shows ‘Legacy not unlocked yet’ (never met) and the defaults lead with reach 25. Once any character has reached 25, Legacy is available on every character, including ones below 25.”
- Unlocked means: any character EmpireIntel or DataStore knows is level 25 or higher (the same test as `/ei unlock`, EI-E-02).
- Locked: a challenges goal prints `Legacy not unlocked yet` and is never counted as met; `/ei next` makes no Legacy read.
- Unlocked: the challenges goal is read and shown on any character, whatever its level.

Rules:
- **Order is priority.** Goals already met are counted in the header, not listed.
- `char` is a character name, or `Name-Realm` when two characters share a name. Two matches without a realm: `UNEXPECTED`, goal skipped.
- `note` (optional, any goal): your own text, shown at the end of the line.
- A goal whose state cannot be known (for example a DataStore character without that profession recorded) is listed as **unknown**, never as met.
- **Reported and skipped**, one `UNEXPECTED` line each: an unknown key, a wrong type or out-of-range value, no goal kind or two kinds in one goal, an unknown character, an unknown profession name.
- **Not in format 1:** perk goals (they need the trait-system reads, Q-T4, unapproved) and per-character spend caps. A goal with `perk` is reported "not supported yet (needs Q-T4)" and skipped. The `version` field lets a later format add them.
- `version` other than 1, or no `goals` table: one `UNEXPECTED` line; the defaults are shown instead.

### 7.4 What `/ei next` prints

All examples use today's characters (C1 Paladin 27, C2 Priest 6, C3 the stale beta Shaman), illustrative only. Exact wording is fixed in the tests.

**With the example plan above:**

```
EmpireIntel next (your plan: 5 goals; 0 met, 0 skipped):
1. C1 Paladin 27 -> level 45: 18 levels to go -> earns Experienced Paladin (1 Legacy point). Experienced Paladin
2. C2 Priest 6 -> level 25: 19 levels to go; about 0.57 levels rested [estimate] -> earns Novice Priest (1 Legacy point)
3. C2 Priest 6 -> Tailoring 150: now 56/75, 94 to go; train to raise max 75 -> earns Journeyman Tailor (1 Legacy point)
4. C2 Priest 6 -> rested 1.00 levels: about 0.57 now; about 69 h more in an inn [estimate]
5. Account -> 5 Legacy challenges: 2 done, 3 to go; closest: Experienced Spelunker 1 of 10
```

**With errors in the plan** (goal 2 has `skil = 150`, goal 4 names nobody):

```
UNEXPECTED plan goal 2: unknown key "skil" (skipped)
UNEXPECTED plan goal 4: no character named "C9" (skipped)
EmpireIntel next (your plan: 5 goals; 0 met, 2 skipped):
1. ...
```

**Without a plan file, before the unlock** (no character at 25 yet; Legacy not available):

```
EmpireIntel next (no plan file: default suggestions; Legacy not unlocked yet):
1. Reach 25: C1 Paladin 22 -> 25 (3 levels to go; illustrative) unlocks Legacy for the account
2. Rested: ...
3. Crafting: ...
```

With a plan before the unlock, a challenges goal reads: `5. Account -> 5 Legacy challenges: Legacy not unlocked yet`.

**Without a plan file, after the unlock** (today; the FR-PRE-4 defaults, in this order, at most 10 lines):

```
EmpireIntel next (no plan file: default suggestions):
1. Class milestone: C3 Shaman 9 -> 25 (16 levels) -> Novice Shaman (1 Legacy point) [datastore, 17 days ago]
2. Class milestone: C1 Paladin 27 -> 45 (18 levels) -> Experienced Paladin (1 Legacy point)
3. Class milestone: C2 Priest 6 -> 25 (19 levels) -> Novice Priest (1 Legacy point)
4. Rested: C2 Priest 6 has about 0.57 levels rested [estimate]: play it next
5. Crafting: nothing within 25 points of a milestone (closest: C2 Tailoring 56/75 -> 150, 94 to go; train to raise max 75)
Add EmpireIntel_Plan\Plan.lua to set your own order (README).
```

- Class milestones: once the account has reached 25 (true now), "reach 25 on the closest character" becomes **the class milestones not yet earned, closest first, at most 3 lines**, for classes that have a character (a new class to 25 is a Novice challenge too) (Q-P2-4e). C3 comes first here because DataStore still lists the stale beta Shaman; once it is deleted in Altoholic, it drops out.
- Default 3: characters with at least 0.5 levels of rested XP now (live or projected), not at level 60, most rested first (Q-P2-4d).
- Default 4: crafting milestones (150/225/300) within 25 skill points; when none, one line naming the closest (Q-P2-4d).

**Other cases:**

| Case | Output |
|---|---|
| Plan folder installed, Plan.lua has a Lua error | `UNEXPECTED plan file did not load (a Lua error in Plan.lua; BugSack shows the line). Showing default suggestions.` then the defaults |
| Plan with no goals | `Your plan has no goals.` then the defaults |
| Every goal met | `All 5 goals in your plan are met.` |
| More than 10 unmet goals | the first 10, then `... and N more` |
| A goal on a character only DataStore knows | as usual, with `[datastore]` and its age |

### 7.5 Restart or reload

| Change | Needed | Basis |
|---|---|---|
| EmpireIntel 0.5.2 -> 0.6.0 | `/reload` is enough | existing folder, new or changed files (EI-E-19, D-034) |
| **First install of the `EmpireIntel_Plan` folder** | **full client restart** (stated) | a new addon folder; never observed with `/reload` (D-034). The test tries `/reload` first and records what happens; if `/ei next` still says "no plan file", restart |
| Editing Plan.lua afterwards | `/reload` | an existing folder's file [inferred from EI-E-19] |
| Removing the plan folder | `/reload` | [inferred]; `/ei next` then shows the defaults |

If the test shows a new folder loads after `/reload`, D-034's open point closes and later packages say `/reload` for new folders too.

### 7.6 Packaging

- `EmpireIntel_AddOns_v0.6.0.zip`: the EmpireIntel folder only, as before.
- `EmpireIntel_Plan_v1.zip`: shipped **once**, with `Plan.lua` holding the example above (placeholders C1, C2). Later EmpireIntel packages never contain the plan folder, so your Plan.lua is never overwritten (Q-P2-4c).
- The README gives the format, the example and the error messages.

### 7.7 Tests (Lua 5.1 and 5.3) and live gate

- **Validator:** each goal kind; each error kind (unknown key, wrong type, out of range, no kind, two kinds, unknown character, duplicate name with and without realm, unknown profession, `perk`); version other than 1; no goals.
- **Planner:** met, not met and unknown for each kind; order kept; met goals counted and not listed; the 10-line limit; the live character versus records; DataStore-only characters.
- **Legacy lock rule (D-052):** before the unlock, the challenges goal shows "Legacy not unlocked yet", is never met, and no Legacy function is called; the defaults lead with reach 25. After the unlock (one character at 25 or higher, from EmpireIntel's records or DataStore), the challenges goal is read and shown when typed on a character below 25 as well.
- **Defaults:** before and after the unlock; rested threshold; crafting within 25; nothing to suggest.
- **Plan folder:** marker without plan (load error); no marker; the example Plan.lua loads in the test harness and validates with no errors.
- **Static:** no new game call; no saved-data write from `/ei next`; EmpireIntel_Plan's only globals are `EmpireIntelPlan` and `EmpireIntelPlanFolder`; ASCII files.
- **Live gate:** (1) `/ei next` without the plan folder shows the defaults, matching `/ei rest` and `/ei milestones`. (2) Install the plan folder, try `/reload` (record whether it loads), restart if needed; with a 5-goal plan of your own, every line matches the game. (3) A plan with two deliberate errors: each reported and skipped, the rest listed.

### 7.8 Questions for the user

| ID | Question | Recommendation |
|---|---|---|
| Q-P2-4 | Approve increment P2-4 as in this section, built as EmpireIntel 0.6.0 plus EmpireIntel_Plan 1, including plan file format 1 (7.3) as a contract? | Approve; **approved** 2026-11-08 |
| Q-P2-4a | Goal kinds in format 1: level, skill, rested and account challenges; perk goals reported "not supported yet" until Q-T4? | Yes; **approved** 2026-11-08 |
| Q-P2-4b | May `/ei next` use P3-1's Legacy reads (already approved code, on command only) for the account challenges goal and the closest challenges? This uses a Legacy read inside a Phase 2 increment (D-027 said Phase 2 uses none). If no, that goal kind is left out of format 1 | Yes: no new call, the reads are proven (P3-1 closed); **approved** 2026-11-08 |
| Q-P2-4c | Ship the plan folder once, as its own zip with the example plan, and never in EmpireIntel packages? | Yes; **approved** 2026-11-08 |
| Q-P2-4d | Default thresholds: rested at least 0.5 levels; crafting within 25 skill points; at most 10 lines? | Yes; one-line changes later; **approved** 2026-11-08 |
| Q-P2-4e | After the unlock, the "reach 25" default becomes "class milestones not yet earned, closest first" (at most 3, classes with a character only)? | Yes; **approved** 2026-11-08 |

## 8. P2-4 revised: the Legacy route planner (approved 2026-11-08, D-055; P2-4b after Q-G1 and the mockup)

**Build status (S-058):** P2-4a built as EmpireIntel 0.6.0 and the UI checks as EmpireIntelCheck 0.1.9-tp1 on branch `p2-4a-planner` (D-057, P2-4a_Report.md), not merged. No window code (D-056).

The user's direction (2026-11-08, D-054): no plan text file; an in-game window to view and edit the plan; a default plan that is the most efficient path to Legacy points across the characters; rules from route guides, each with its source and labelled unverified until the game confirms it; two modes, the user's edited plan or automatic. Branch `p2-4-next` (pull request #11) is kept, not merged.

### 8.1 Proposed split

| Increment | Delivers | Why separate |
|---|---|---|
| **P2-4a Planner** | The rules table, the route engine (8.4, 8.5), the saved plan (format 2, 8.7), both modes, and `/ei next` in chat | Testable offline; no new UI calls |
| **P2-4b Plan window** | The window to view and edit the plan, the optional minimap button, ElvUI support (8.3) | Needs the UI API checks first (8.3.4); its own live test |

One approval each (Q-P2-4r-a, Q-P2-4r-b). P2-4a is useful on its own; P2-4b reads and writes the same saved plan.

### 8.2 What is reused from #11 (`p2-4-next`)

| From #11 | In the revised plan |
|---|---|
| `Core/Next.lua` goal lines: gap, rested now, "earns ...", unknown never met, the 10-line limit, `[datastore, age]` | **Reused** for each step of the route, in chat and in the window |
| The Legacy lock rule (D-052) and its tests | **Reused unchanged** |
| `Core/Plan.lua` goal checks (kinds, ranges, character matching, perk "not supported yet") | **Reused** to check each edited step before it is saved; the text-file loader is dropped |
| `LegacyView.Closest`, the challenge-name tables (`CLASS_TITLES`, `CRAFT_TITLES`, `CRAFT_PERSON`) | **Reused** |
| `/ei next` defaults (class milestones, rested, crafting within 25) | **Replaced** by the route engine (auto mode) |
| The `EmpireIntel_Plan` folder, `Marker.lua`, plan file format 1, `P.PlanGlobals` | **Dropped** (never merged or installed) |
| Tests (43) | About 30 carry over (goal lines, lock rule, checks); the file-loading tests are dropped |

### 8.3 The plan window (P2-4b)

#### 8.3.1 Design direction (the user, 2026-11-08, D-055)

1. **Unique to EmpireIntel.** Own textures and fonts on plain frames; **no Blizzard templates** (no `BackdropTemplate`, `UIPanelButtonTemplate`, scroll-frame or dropdown templates), so ElvUI, which reskins Blizzard templates, does not change the window. Art is original: flat colour fills, our own small icon sheet shipped in the EmpireIntel folder. Nothing from Linear's branding.
2. **Look and feel inspired by Linear:** dark, dense, calm list rows with status icons; drag to reorder; click to edit in place; right-click for actions; **no forms**.
3. **"Up Next" card on top:** the next character's portrait, class colour, faction banner and ruleset badge; then the step, the points it earns and the estimated time, so the user sees what to play at a glance.
4. **A static mockup first** (8.3.5): no window code until the user approves it.

#### 8.3.2 Layout (to be refined in the mockup)

```
+-------------------------------------------------------------------------+
|  EmpireIntel        [ Fastest | My plan ]           2 / 16   x          |
|  +-------------------------------------------------------------------+  |
|  | UP NEXT                                                           |  |
|  | [portrait]  C2  Priest 6        [Alliance banner] [Normal]        |  |
|  |  (class-     Reach level 10, then Tailoring 150                   |  |
|  |   coloured   +1 Legacy point (Journeyman Tailor)   ~2 h [estimate]|  |
|  |   ring)      gate: Journeyman needs level 10  [web, unverified]   |  |
|  +-------------------------------------------------------------------+  |
|   o  C2 Priest 6      Enchanting 150            28/75   +1   ~3 h     |
|   o  C1 Paladin 27    Experienced Spelunker      1/10    +1   ~9 h     |
|   o  C2 Priest 6      Level 25                   6       +1   ~6 h     |
|   *  C1 Paladin 27    Level 45                   27      +1   ~14 h    |
|   ...                                                                   |
|  Next reward 15: Air Rifle          Rules: 18, 12 unverified (hover)    |
+-------------------------------------------------------------------------+
```

- **Rows:** one line each, about 22 px high: a status icon (open, in progress, done, blocked by a gate, unknown), the character in class colour, the step, now, points, estimated time. Unverified rules show a small dot; hover shows the rules and their sources.
- **Fastest mode:** read only; rows cannot be dragged. Right-click: "Copy to my plan", "Ignore this character".
- **My plan mode:** drag a row to reorder; click a cell to edit it in place (a target number, a note); right-click: move to top, remove, ignore character, add a step after (character, kind and target chosen from a short inline list, not a form).
- **Open:** `/ei plan`, the minimap button, or the AddOn compartment if present. Escape closes it; position and size are remembered (format 2).
- **Combat:** works in combat (not a secure frame), with no Legacy read in combat ("values from before combat").
- **Saved:** edits are saved by the game at `/reload` or logout; the window says once that a crash loses edits since the last `/reload`.

#### 8.3.3 Minimap button and AddOn compartment (Q-G2: own button plus the compartment)

- Our own round button with our own icon: left-click opens the window, right-click switches the mode, drag moves it along the edge; `/ei minimap off` hides it.
- Placed using `GetMinimapShape` when present, so it sits on the edge of ElvUI's square minimap too.
- An AddOn compartment entry if the client has one (8.3.4).
- **ElvUI:** because the window uses no Blizzard templates, ElvUI leaves it alone; no call into ElvUI is needed. Live test with ElvUI on and off.

#### 8.3.4 API checks needed first (a check package, Q-G1)

No UI code has run in EmpireIntel yet; GoldIntel's evidence covers events and frames for data, not windows. **Approved (Q-G1, D-055):** EmpireIntelCheck 0.1.9-tp1 runs these checks alongside the P2-4a build. Existence checks, plus hidden test frames and textures inside `pcall`, hidden and never shown. Each result is recorded as present, absent or failed, with evidence (the value, or a screenshot the user sends):

| Check | Why |
|---|---|
| Plain widgets with no template: `Frame`, `Button`, `EditBox`, `ScrollFrame`; `Texture:SetColorTexture`, `SetTexture` with a file in the addon folder, `SetTexCoord`; `CreateFont` / `SetFont`; `SetMovable`, `RegisterForDrag`, `StartMoving`, mouse wheel | the window, rows, in-place edit, drag to reorder, own scrolling (no templates, 8.3.1) |
| **Portrait of the live character:** `SetPortraitTexture(texture, 'player')` | the Up Next card |
| **Race and gender icons for logged-out alts:** `UnitRace('player')`, `UnitSex('player')` and their ids for the live character (to record per character); the race-icon art (atlas names such as `raceicon-<race>-<gender>` via `C_Texture.GetAtlasInfo`, or the classic race-icon texture and coordinates) | a portrait stand-in for alts, which the game cannot draw |
| **Class icons:** `CLASS_ICON_TCOORDS` with the class-icon texture, or atlas `classicon-<class>`; class colours: `C_ClassColor.GetClassColor` or `RAID_CLASS_COLORS` | the card and the rows |
| **Faction emblems:** `UnitFactionGroup('player')`; emblem art (atlas or `Interface\TargetingFrame\UI-PVP-<Faction>`) | the faction banner |
| **Ruleset and realm type, per character:** `C_GameRules.IsHardcoreActive()`, `GetForeverExperiencePreset()` (EI-E-09, EI-E-11 [file]), `IsSelfFoundAllowed()`; the realm name and, if exposed, its type; and what DataStore keeps (faction yes, ruleset unknown, Reference_DataStore_Altoholic.md) | the ruleset badge, and L-18 (never mix Hardcore and normal points) |
| `UISpecialFrames` | Escape closes the window |
| `AddonCompartmentFrame` and the TOC fields `AddonCompartmentFunc` | the compartment entry, as Hated Legacy uses |
| `Minimap`, `GetMinimapShape`, `GetCursorPosition` | the minimap button and dragging |
| `GameTooltip` | row tooltips |
| `C_AddOns.IsAddOnLoaded('ElvUI')` and ElvUI's global `ElvUI` (presence only) | the ElvUI look |

No other call. The results decide which art the card can show for alts; anything absent falls back to the class icon and class colour.

#### 8.3.5 Static mockup before any window code

Before P2-4b code: a static mockup (an image or page, not the addon) of the window in both modes, with the Up Next card, built from today's characters (names replaced) and the P2-4a route. The user approves it, or asks for changes, before any window code is written.

### 8.4 The rules table and its sources

Every rule has an id, its source tags (Project_Bible section 6: [file], [reported], [inferred], [assumed], [inherited], plus [web: site, date]), and a status: **confirmed** (the client or the user showed it) or **unverified**. Unverified rules are labelled in chat and in the window. A rule becomes confirmed only by a game read or a user report, recorded in Compatibility_Notes.md.

| Id | Rule | Source | Status |
|---|---|---|---|
| L-1 | The first character to 25 unlocks Legacy for the account; after that, Legacy is available on every character (D-052) | EI-E-02 [file]; user (D-052) | confirmed |
| L-2 | Class challenges at 25, 45, 60 per class, once per account; a second character of the same class earns nothing | EI-E-22 [file]; [web: warcraft.wiki.gg, 2026-11-02] | confirmed (ids); "nothing for a second" [web] unverified |
| L-3 | Craft challenges at 150, 225, 300 for the six crafts; gathering and secondary skills give none | EI-E-22 [file] | confirmed |
| L-4 | Training gates: Journeyman needs character level 10, Expert level 20, Artisan level 35 | [web: wow-professions.com, epiccarry.com]; [inherited] classic | unverified |
| L-5 | Skill needed to train the next rank: 50 / 125 / 200 (sources disagree: 75 / 150 / 225) | [web: epiccarry.com, wow-professions.com; rankedboost.com] | unverified, conflicting |
| L-6 | Two primary professions per character, so all six crafts at 225 need three characters at level 20 or more | [inherited] classic; matches Method's "3 level 20 characters" [web: method.gg, 2026-10-08] | unverified |
| L-7 | Dungeon challenges: Novice 6, Experienced 10, Master 17 dungeons (the game's lists); progress is account-wide | EI-E-23, EI-E-27 [file] | confirmed |
| L-8 | Dungeon level ranges (for example Experienced: Blackfathom Deeps, Gnomeregan, Scarlet Monastery, Razorfen Kraul at about 24-45) | [inherited] classic levels; Forever's new dungeons (Hall of Thanes, Ruins of Lordaeron, Krol'dok Stronghold, ...) have no known ranges | unverified |
| L-9 | PvP challenges (ranks 3/7/10/13/14, four battleground reputations, Field of Honor weeks 4/7/10) are **not planned before level 60** | user (D-054); Method suggests Rank 3 or 7 early [web: method.gg] | user rule; Method's view noted |
| L-10 | Raids (Hyjal Summit, Barrow Deeps, Onyxia) and Lord Valthalak are level-60 content | [web: warcraft.wiki.gg "[60D]"]; [inherited] | unverified |
| L-11 | Explorer needs one character to explore every zone; long; planned after a character reaches 50, counting zones already explored on the way (D-056) | EI-E-22 [file] for the requirement; the timing is the user's rule (D-056) | requirement confirmed; timing: user rule |
| L-12 | Spending cap: 16 points per character at launch; trees are per character, points account-wide | [web: warcraft.wiki.gg, icy-veins.com, method.gg]; client text says a seasonal cap "in total" (EI-E-04) [file]; Hated Legacy shows spending per character [web: curseforge.com] | unverified (Q-P3-2a checks per character) |
| L-13 | Reward track: 15 Air Rifle, 25 Spectral Bear Cub, 40 Spectral Bear Tabard, 55 Reins of the Spectral Bear | Legacy_Rules.md section 2 [screenshot]; [web: warcraft.wiki.gg] | confirmed |
| L-14 | Rested XP: 5% of a level per 8 h in an inn | EI-E-28 [file] | confirmed (inn rate only) |
| L-15 | XP per level (the bar) | EI-E-14 for the levels measured [file]; [inherited] classic table for the rest | partly confirmed |
| L-16 | Time costs (8.5): hours per level by level band, per 25 skill points, per dungeon run | [assumed] defaults, tuned by the user's own measured rates where available | unverified (estimates) |
| L-17 | While rested, kills give double XP and the pool drops by the bonus given, so a pool of R saves R of kill XP; quest and exploration XP get no bonus | [web: warcraft.wiki.gg "Experience": "double XP from killing monsters", quests not listed]; [web: wowhead.com classic rested guide: kills use the pool, other XP does not]; [inherited] classic server behaviour: the bonus taken from the pool equals the bonus given; the user's statement (D-055). Accrual matches the Classic display (EI-E-28) | unverified on Forever. **Check (no code):** note `/ei` (XP and rested) before and after one kill while rested: XP should rise by twice the kill's normal XP and rested should fall by the kill's normal XP |
| L-18 | Hardcore characters' Legacy points are kept apart from the normal ruleset's | [web: warcraft.wiki.gg "account-wide, with the exception of Hardcore characters"; warcrafttavern.com "Legacy Rewards Will Be Separate on the WoW Forever Hardcore Ruleset"] | unverified; the planner never mixes rulesets (8.3.4 reads each character's ruleset) |

**What the guides say (inputs, not rules):**
- **Method**, "The Fastest Way to Get Legacy Points in WoW Forever" (Old Guardian, 2026-10-08): "It is faster to use multiple characters." Multi-character route to 16: level 60 on the first character (3), two alts of other classes to 25 (2), PvP Rank 3 (1), four crafts to 225 (8), Novice and Experienced Spelunker (2). It also says all crafts at 225 "gives you 12", which contradicts its own list (8); the plan uses the rules above, not the guide's totals.
- **Hated Legacy** (HatedGaming, v0.1.0-forever, 2026-10-10, All Rights Reserved): shows challenges, a zone-based "Here & Now" list, closest challenges, per-character perk spending and the reward track. **It does not plan routes**, and has no minimap button (it uses the AddOn compartment). Its source is not read or copied (D-003); its overlap with `/ei legacy` is noted.
- Icy Veins and Mobalytics refused automated reading (HTTP 403); not used.

### 8.5 How "fastest" is measured

- **Unit: estimated play hours** to the next Legacy point, labelled [estimate].
- **Leveling:** (XP to go - XP saved by rest) divided by an XP-per-hour rate for that level band. Default rates are [assumed]; once EmpireIntel has seen a character gain levels across sessions, it uses that character's measured rate (Q-F2, approved).
- **Rested XP (corrected, D-055):** a rested pool of R saves **R of kill XP in full**, not half (L-17). While rested, each kill gives its XP twice and the pool drops by the bonus; so the pool lasts until R bonus XP has been given, and the time to level falls by R / (XP per hour). Quest and exploration XP get no bonus, so the saving is min(R, the kill XP still needed); without a measured kill share, the plan assumes kills give at least R of the XP to go [assumed] and says so on the row.
- **Professions:** skill points to go times hours per point for that band [assumed], plus any level gate (L-4) first.
- **Dungeon challenges:** planned at any level (D-055): dungeons left times hours per run [assumed]. The level ranges (L-8) only pick which character fits a dungeon best and raise the estimate for a character far outside the range.
- **Rules that make a step impossible now** (a gate, PvP before 60 under L-9, level-60 content) are not counted; the gate itself (for example "C2 to level 10") becomes the step.
- **Auto mode** is greedy: from the current state, take the cheapest next point (including its gates), apply it, repeat until the target. It is recomputed from the real values every time, so it adjusts as the user plays.
- **Ties:** prefer steps on the character being played; then a step that also opens a gate for later points.

### 8.6 The target

| Option | Meaning | Recommendation |
|---|---|---|
| **A. 16 earned** | Enough for one character to fill the launch cap (L-12); passes the 15 reward on the way | **Default** |
| B. Next reward | 15, then 25, 40, 55 (L-13) | Selectable in the window |
| C. Next point only | Just the cheapest next point | Selectable |

The window shows the target and the progress to it ("2 of 16; next reward at 15").

**Illustrative auto route** from today's values (C1 Paladin 27 with Mining and Skinning; C2 Priest 6 with Tailoring 56/75 and Enchanting 28/75; 2 earned; C3 ignored); the order and hours depend on L-4, L-5 and L-16, all unverified:

1. C2 to level 10 (gate for Journeyman, L-4), then Tailoring to 150: +1 (Journeyman Tailor)
2. C2 Enchanting to 150: +1 (Journeyman Enchanter)
3. C1 Experienced Spelunker (9 dungeons left, in level range now, L-8): +1
4. C2 to 25: +1 (Novice Priest)
5. C1 to 45: +1 (Experienced Paladin)
6. C2 Tailoring and Enchanting to 225 (gate: level 20): +2
7. ... until 16

### 8.7 Saved-data format change (format 2; needs approval, D-019)

```
EmpireIntelDB = {
  schema = 2,
  ...                                        -- format 1, unchanged
  plan = {                                   -- new
    mode = 'auto' | 'mine',
    target = 16 | 'reward' | 'next',
    mine = {                                 -- the edited plan, in order
      { kind = 'level', guid = '<GUID>', level = 25, note = 'optional' },
      { kind = 'skill', guid = '<GUID>', profession = 'Tailoring', skill = 150 },
      { kind = 'challenge', id = 62032 },    -- a challenge by its game id (for example Experienced Spelunker)
      { kind = 'rested', guid = '<GUID>', rested = 1.0 },
    },
    ignore = { ['<GUID>'] = true },          -- characters left out of auto mode
    rates = { ['<GUID>'] = { xpPerHour = <n>, at = <time> } },   -- measured, only if Q-F2 is approved
    window = { point = 'CENTER', x = 0, y = 0, w = 520, h = 360 },
    minimap = { hide = false, angle = 225 },
  },
}
```

- **Roster records gain** `race`, `sex`, `faction` and `ruleset` (`normal` / `hardcore` / unknown, and the experience preset), recorded for the live character at each snapshot (8.3.4 decides the calls). Alts get them at their next login, or `faction` from DataStore meanwhile.
- Characters are stored by GUID, never by name, so a rename does not break the plan. GUIDs stay on the user's computer, as now.
- **Format numbering (D-055):** this is format 2; P3-2's saved summary becomes format 3.
- Migration 1 to 2 adds an empty `plan`; nothing is converted. Opening format 2 with 0.5.2 or 0.6.x: the Store's readonly state leaves it untouched (already built and tested).

### 8.8 Restart or reload

| Change | Needed | Basis |
|---|---|---|
| P2-4a (new Lua files in EmpireIntel) | `/reload` | EI-E-19, D-034 |
| P2-4b window code and any embedded libraries (files in the EmpireIntel folder) | `/reload` | EI-E-19 |
| P2-4b adding TOC header fields (`AddonCompartmentFunc`, `IconTexture`) | **full client restart** stated, `/reload` tried first | TOC headers may be read only at start [inferred]; never observed |
| The check package for 8.3.4 (EmpireIntelCheck, existing folder) | `/reload` | EI-E-19 |

No new addon folder.

### 8.9 Questions for the user

| ID | Question | Recommendation |
|---|---|---|
| Q-P2-4r | Approve the revised direction: the plan lives in saved data and the window, plan file format 1 and the `EmpireIntel_Plan` folder are retired, and #11 stays unmerged as reference? | **Yes** (D-055) |
| Q-P2-4r-a | Approve P2-4a (rules table, route engine, both modes, `/ei next` in chat) with saved-data format 2 (8.7)? | **Yes**, format 2 for the plan; P3-2 becomes format 3 (D-055) |
| Q-P2-4r-b | Approve P2-4b (window, minimap button, ElvUI) after the UI checks? | **After Q-G1** (D-055) |
| Q-G1 | Let EmpireIntelCheck 0.1.9-tp1 run the UI checks of 8.3.4 (existence checks and hidden test frames only)? | **Yes**, in EmpireIntelCheck alongside the P2-4a build; checks extended in 8.3.4 (D-055) |
| Q-G2 | Minimap button: our own (no dependency), or embedded LibDataBroker and LibDBIcon (a dependency, license to be checked)? Plus the AddOn compartment if present | **Own button plus the AddOn compartment** (D-055) |
| Q-G3 | Do you use ElvUI on Forever? Should the window take ElvUI's look when it is loaded, or stay plain? | **Replaced** by the design direction, 8.3.1 (D-055) |
| Q-F1 | Target: 16 earned (default), with next reward and next point selectable? | **16** (D-055) |
| Q-F2 | Cost model: assumed hours per level, skill and dungeon, labelled [estimate]; may EmpireIntel learn each character's own XP-per-hour from the levels it sees across sessions (no new game call; saved in `plan.rates`)? | **Yes** (D-055) |
| Q-F3 | PvP not planned before 60 (your rule), raids and Valthalak at 60, Explorer after a character reaches 50? | **No PvP before 60; raids and Valthalak at 60; Spelunker challenges at any level** (D-055). Zone Explorer: **after 50, counting zones already explored on the way; Spelunker stays at any level** (D-056) |
| Q-F4 | Ignore characters in auto mode (for example the stale beta Shaman), saved per GUID? | **Yes** (D-055) |
| Q-F5 | When a guide and the game disagree, the game wins and the rule is marked confirmed with the game's value; when two guides disagree (L-5), the plan uses the more cautious value until the game confirms? | **Yes** (D-055) |

Sources: [Method](https://www.method.gg/wow-forever/the-fastest-way-to-get-legacy-points-in-wow-forever), [Hated Legacy on CurseForge](https://www.curseforge.com/wow/addons/hated-legacy), [warcraft.wiki.gg Legacy System](https://warcraft.wiki.gg/wiki/Legacy_System), [wow-professions.com trainers](https://www.wow-professions.com/forever/blacksmithing-trainers), [epiccarry.com tailoring](https://epiccarry.com/blogs/wow-forever-tailoring-guide/), [rankedboost.com](https://rankedboost.com/world-of-warcraft/forever/professions/blacksmithing-leveling/).


## 9. P2-4b build plan: the plan window (for approval, Q-P2-4b; mockup approved D-060)

The approved mockup (D-060): https://claude.ai/artifact/GrBwFsCBY7uZssod6mkLA1 (private; Fastest mode, My plan mode, parts). The user's rules (D-060): **faction emblems are the game's own** (atlases `HordeEmblem`, `AllianceEmblem`, EI-E-30); **fonts are the game's built-in fonts, none shipped**; the window is **resizable, size and position remembered, moderate default**. No window code before this plan is approved.

### 9.1 What P2-4b delivers (EmpireIntel 0.7.0)

- The plan window as in the mockup: header (route mark, Fastest / My plan switch, target, close), the **Up Next** card, the route or my-plan rows, the footer (next reward, rules count, route total).
- **Up Next card:** the played character gets its live portrait (`SetPortraitTexture`, EI-E-30); an alt gets its race icon (`raceicon-<race>-<sex>` atlas; race file `Scourge` maps to `undead`, EI-E-30) with a small class icon (`classicon-<class>`), in a class-coloured ring (`C_ClassColor`, EI-E-30). No race recorded: the class icon alone. Faction: the game's emblem atlas; ruleset badge Normal / Hardcore / unknown.
- **Rows:** status icon (open, in progress, done, blocked by a gate, unknown), character in class colour, step, now, points, time; the amber dot for unverified rules; hover shows the tooltip with each rule, its source and status.
- **Fastest mode:** read only. Right-click: Copy to my plan, Ignore this character.
- **My plan mode:** drag a row to reorder; click a target or a note to edit it in place (Enter saves, Escape cancels, each edit checked by `Plan.Check`); right-click: Move to top, Add a step after (character, kind and target from a short inline list), Edit note, Ignore in Fastest, Remove.
- **Window:** movable, **resizable** (own grip in the lower right), position and size saved in `plan.window` (format 2, already approved, 8.7). Default **560 x 420**; limits 440 x 300 to 900 x 800; kept on screen. Escape closes it (`UISpecialFrames`, EI-E-29). Works in combat (not a secure frame); no Legacy read in combat (the last read is shown, labelled "from before combat").
- **Minimap button** (our own route mark): left-click opens, right-click switches the mode, drag moves it along the edge (`GetMinimapShape`: round, or square under ElvUI, EI-E-31); angle and hidden state in `plan.minimap` (format 2); `/ei minimap on|off`.
- **AddOn compartment:** registered at run time with `AddonCompartmentFrame:RegisterAddon` (present, EI-E-29), so **no TOC header change**.
- **DataStore faction for alts (Q-P2-4a-3, D-059):** see 9.4.
- **No Blizzard templates** anywhere (8.3.1): plain `Frame`, `Button`, `EditBox`, `ScrollFrame`, own textures and colour fills; ElvUI leaves the window alone.

### 9.2 Files

| File | New / changed | What it does |
|---|---|---|
| `Platform/UI.lua` | new | **The only file that creates frames, textures and font strings or names a UI call** (static test): thin wrappers under `pcall` for `CreateFrame`, `SetPortraitTexture`, `C_Texture.GetAtlasInfo`, `GetCursorPosition`, `GetMinimapShape`, `UISpecialFrames`, `AddonCompartmentFrame:RegisterAddon`, `GameTooltip`. A call that fails gives one `UNEXPECTED` line and a plain fallback (for example a fixed-size window if resizing fails) |
| `Core/PlanView.lua` | new, pure | The window's view model from the route or my plan: the card, the rows, the footer, the tooltip lines, the art to use (portrait / race atlas / class icon; emblem). Offline-testable; the window only draws what it returns |
| `UI/Theme.lua` | new, pure data | Colours from the mockup, sizes, the built-in font paths (`Fonts\FRIZQT__.TTF`, checked in EI-E-29; `Fonts\ARIALN.TTF` for the dense rows, falling back to FRIZQT if `SetFont` refuses it), the race-to-atlas map |
| `UI/Window.lua` | new | Frame, header, mode switch, target, close, resize grip, saving position and size, Escape |
| `UI/UpNext.lua` | new | The Up Next card |
| `UI/Rows.lua` | new | Row pool, own scrolling (mouse wheel, no scroll-frame template), status icons, tooltip, drag to reorder, in-place edit, the right-click menu (our own, not the dropdown template) |
| `UI/Minimap.lua` | new | Minimap button and the compartment entry |
| `Media/Icons.tga` | new | Our own small icon sheet (route mark, status icons, drag handle, close, resize grip, menu check); flat shapes, original |
| `Bridge/DataStoreBridge.lua` | changed | `GetCharacterFaction` added to the approved getters (9.4) |
| `Core/Alts.lua` | changed | Faction: the own record's, else DataStore's, marked "from datastore" |
| `Core/Next.lua`, `Core/Commands.lua` | changed | `/ei plan` alone opens or closes the window; the settings text moves to `/ei plan help` (Q-P2-4b-2); `/ei minimap on|off` |
| `EmpireIntel.toc` | changed | New files listed; version 0.7.0; **no new header fields** |
| `tools/build_package.py` | none | Already ships `Media/*.tga` |

### 9.3 Restart or reload

| Change | Needed | Basis |
|---|---|---|
| New Lua files in the EmpireIntel folder | `/reload` | EI-E-19, D-034 |
| New texture file `Media/Icons.tga` in the existing folder | `/reload` | EI-E-29: the check's new `Media/Test.tga` loaded after a `/reload` |
| TOC header fields | none (the compartment is registered at run time) | 9.1 |

**`/reload` is enough.** No new addon folder.

### 9.4 The DataStore faction getter (Q-P2-4a-3, approved D-059)

- `GetCharacterFaction` joins the bridge's approved read-only getters (P2-2 list plus one). It exists on the user's client (EI-E-31, presence only; never called yet). DataStore keeps the faction the game reported for that character (Reference_DataStore_Altoholic.md) [inferred from the source, unverified on Forever].
- Read only in `/ei alts` and when the window opens, like the other DataStore values; **never stored** (the P2-2 rule). Accepted only as `Alliance` or `Horde`; anything else is ignored and counted in the existing `UNEXPECTED` DataStore line.
- The own record's faction (recorded at the character's own login) wins; DataStore's is used until then and shown as "faction from DataStore" (the dashed badge in the mockup).
- The live test compares it with the faction each character records at its next login.

### 9.5 Saved data

**No format change.** `plan.window` and `plan.minimap` are already in format 2 (8.7). Nothing from DataStore is stored.

### 9.6 Tests (Lua 5.1 and 5.3; target about 60 new)

- A shared fake UI layer (`Tests/helpers/fakeui.lua`, from the 0.1.9 tests): widgets with their methods, atlases, colours, portrait, compartment, minimap shape, tooltip; it records shows, anchors, sizes and saves.
- **PlanView (pure):** the played character's card uses the portrait, an alt's the race atlas (`Scourge` to `undead`), unknown race the class icon; emblem by faction, none when unknown; ruleset badge; row statuses (open, in progress from the game's steps, done, gate, unknown); unverified dots and tooltip lines with sources; both modes; empty plan; Legacy not unlocked yet; "from before combat".
- **Window:** made once and hidden until opened; Escape registration; position and size saved, restored, clamped to the limits and the screen; resizing refused by the client falls back to a fixed size with one `UNEXPECTED` line; mode switch; reorder by drag writes `plan.mine`; in-place edit saves only a valid value (`Plan.Check`); right-click actions; edits refused and said when the store is read-only; works in combat without a Legacy read.
- **Minimap and compartment:** angle saved; round and square placement; hidden by `/ei minimap off`; compartment registered once; nothing breaks when it is absent.
- **DataStore faction:** the allowed list is exactly the P2-2 list plus `GetCharacterFaction`; only `Alliance` or `Horde` accepted; the own record wins; nothing stored.
- **Static rules:** only `Platform/UI.lua` creates frames or names UI calls; no `Template` argument and no Blizzard template name anywhere; no TOC header change; Core files stay free of UI calls.
- A mutation check over the new guards, as for P2-4a.

### 9.7 Live gate (the user's test)

1. `/ei plan`, the minimap button and the compartment each open the window; Escape closes it.
2. Both modes match the mockup; the card shows the played character's portrait; on the other character it shows the race icon and class icon.
3. My plan: drag a row, edit a target, right-click Move to top and Remove; `/reload`; the changes are kept.
4. Resize and move the window, `/reload`: same size and place.
5. With ElvUI on and off: the window looks the same; the minimap button sits on the edge of the round and the square minimap.
6. Open the window in combat: no error, "from before combat" shown.
7. `/ei alts` on a character whose other character has not logged in since 0.7.0: its faction shows "from datastore" and matches the game.
8. A screenshot of each mode; the saved file; any `UNEXPECTED` line or Lua error.

### 9.8 Questions for the user

| ID | Question | Recommendation |
|---|---|---|
| Q-P2-4b-1 | Approve this build plan (EmpireIntel 0.7.0, 9.1-9.7)? | Yes |
| Q-P2-4b-2 | `/ei plan` alone opens the window, and the settings text moves to `/ei plan help`? | Yes (8.3.2 already names `/ei plan` as the way to open it) |
| Q-P2-4b-3 | The compartment registered at run time, not through TOC fields (so `/reload` is enough)? | Yes |
| Q-P2-4b-4 | Default 560 x 420, limits 440 x 300 to 900 x 800? | Yes |

### 9.9 The fill path (D-061)

- Every colour fill (window, card, rows, badges, menu) goes through **one function**, `UI.Fill`, in `Platform/UI.lua`.
- At window creation a hidden test texture is filled with `SetColorTexture` and read back (`GetTexture` must return a value, and no error). If the read-back passes, fills use `SetColorTexture`.
- Otherwise fills use `SetTexture` on our own `Media/White8.tga` (an 8x8 white file; our shipped texture loaded in 0.1.9, EI-E-29) plus `SetVertexColor`, read back with `GetVertexColor`. If both fail: one `UNEXPECTED` line, and the window still opens with text only.
- The path that ran is reported: once in chat when the window first opens, and in `/ei plan help`. Not saved (no format change).
- Tests cover both paths and the double failure.

## 10. P2-4c and P2-4d: profession choices with a setup wizard, and rested XP in the route (approved D-065; D-063 items 10 and 11; not started)

**Answers (D-065):** Q-P2-4c yes; c-1 yes, inside format 2; c-2 yes, nothing is planned for a free slot until the user chooses a profession or "planner's choice" in the wizard; c-3 yes, gathering skills appear, marked as earning no Legacy points. Q-P2-4d yes; **d-1 no: L-17 stays unverified until the user's rested-kill check on Forever**; d-2 yes; d-3 yes (1.4 levels, 0.90). Order: P2-4c after P2-4b closes, P2-4d after P2-4c, one increment at a time.

Two increments, one approval each, both after P2-4b closes. Proposed order: **P2-4c first** (it removes a wrong assumption from today's route), then P2-4d.

### 10.1 Why the route showed Alchemy for C4 (item 10) [file: code; screenshot]

`Core/Route.lua` lets a character with a free primary slot (fewer than two, L-6) **learn** any craft when that is the cheapest next point (`learn = true`). C4 Druid has no Alchemy and a free slot, so the route chose "learn Alchemy". In chat the step says "learn Alchemy"; **in the window the word was lost**: `PlanView.StepFacts` writes "Level 10, then Alchemy 150" when a level part comes first. Both are wrong by the user's rule: a profession a character has not learned is never assumed.

### 10.2 P2-4c: what it delivers (EmpireIntel 0.8.0)

1. **Profession choices per character.** For each character: its learned professions (read, as now) plus, for each free primary slot, one of: a profession the user picks, **"let the planner choose"**, or **"none"**.
2. **The route uses only** learned professions, the user's picks, and, where the user said "let the planner choose", the planner's pick. With no answer for a free slot, the route assumes nothing: that character's craft points are not planned, and **one row says "C4: choose a profession (1 free slot)"** (no time, no points). A planner's pick is written **"learn Alchemy (planner's choice)"**, in chat, the window and the card. The window never drops "learn" again (test).
3. **A first-run setup wizard** (in the spirit of ElvUI's install; our own frames and look, no templates, D-060). It opens the first time the window opens after 0.8.0, and never again unless asked. Pages, each with Back, Next and Skip:
   1. Welcome: what EmpireIntel plans, and that every answer can be changed later.
   2. Characters to include: every known character with a tick (unticked = ignored, the same list as `/ei plan ignore`).
   3. Professions: per included character, its learned professions (read only) and a choice per free slot (the six crafts, the three gathering skills, "let the planner choose", "none").
   4. Target: Cap 16, next reward or next point.
   5. Default view and the minimap button: Fastest or My plan; button on or off.
   6. Done: a summary; Finish saves everything at once.
4. **Rerun:** `/ei setup`, a "Setup..." button in the window's header, and an entry in the game's AddOns options **if the client has the options API** (checked at run time under `pcall`; if absent, one `UNEXPECTED` line and the other two ways still work). Every answer is also changeable later in the window (right-click a character's row: "Professions...", "Include / Ignore").
5. **Saved data (needs approval, Q-P2-4c-1):** in the `plan` section, new fields `profs = { ['<GUID>'] = { 'Alchemy', 'auto' } }` (a profession name, `'auto'` = planner's choice, or `'none'`, one per free slot) and `setup = { done = '0.8.0', at = <time> }`. Nothing is converted; older versions ignore the fields. Characters stay stored by GUID.
6. **Tests** (about 40): no assumed profession anywhere (route, chat, window); planner's choice labelled; the "choose" row; each wizard page; Skip and Back; rerun; read-only saved data; the options-panel probe absent and present. **Package** 0.8.0, `/reload`.

### 10.3 P2-4d: rested XP in the route (EmpireIntel 0.9.0)

**What 0.7.x already does [file: code]:** every levelling estimate already spends the character's projected rested pool (L-17: a pool of R saves R of kill XP; saving = min(R, XP to go)), and the tooltip says "rest saves ~X h". What is missing:

1. **(a) The pool grows during the route.** Today the pool is the one projected for *now*. P2-4d projects each character's pool to the moment its step starts: while the user plays other characters (the route's earlier steps, in play hours), a character logged out in an inn gains 5% of a level per 8 h (EI-E-28, confirmed). Assumption to approve (Q-P2-4d-2): **one character is played at a time and the others rest in an inn.** Each step's time then uses the pool it will have, and its row shows the pool ("rested 1.2 lv").
2. **(b) The 105% rule (new rule L-19, unverified).** As the user describes it: a character that stays logged out in an inn without logging in stops gaining rested XP at 105% of a level (about 7 days at 5% per 8 h) instead of 150%. Not confirmed on Forever, so it is **labelled unverified** wherever it is used. The projection caps an untouched pool at 1.05 levels; **the route adds a step "log in and out on C<n>"** when a resting character reaches about 0.90 levels (about 6 days), after which the pool can grow to 1.5. A time line says when ("in about 2 days").
3. **(c) Rested priority (alt cycling).** In the default route, a character at or near the cap (1.4 levels or more, or due to reach the cap before its next step) gets a step **"play C<n>: about X h at double XP (rested pool 1.5 lv)"**, placed before the cheapest Legacy step, even when it does not reach a Legacy milestone. Such a step earns 0 points; the route shows it as rested use, and the time to 60 account-wide is the measure. A switch in the wizard and the window, "Rested priority: on" (default on, as asked).
4. **Saved data:** none beyond P2-4c's (the switch is one field `restPriority` in `plan`, with Q-P2-4c-1).
5. **Tests** (about 30): pool growth across steps; the 1.05 cap without a login and 1.5 after one; the login step at 0.90; priority ordering and its switch; no change when every pool is empty. **Package** 0.9.0, `/reload`.

**The 105% test for the user (once the alt roster is set up; no code):**
1. Pick two alts with little or no rested XP, both logged out in an inn on the same day. Note `/ei rest` for both.
2. Alt A: do not log in for 8 days. Alt B: log in once on day 6 (just log in and out), then leave it.
3. On day 8 or later, log in on each and type `/ei rest`. Send both lines.
4. If A shows about 1.05 levels and B about 1.2 or more, the 105% rule holds on Forever (L-19 becomes confirmed). If both show about the same (about 1.2 or more), there is no 105% stop and L-19 is dropped.

### 10.4 Questions for the user

| ID | Question | Recommendation |
|---|---|---|
| Q-P2-4c | Approve P2-4c as in 10.2 (EmpireIntel 0.8.0)? | Yes, after P2-4b closes |
| Q-P2-4c-1 | Approve the saved fields `plan.profs`, `plan.setup` (and `plan.restPriority` for P2-4d), additive inside format 2 (no number change, since P3-2 keeps format 3)? | Yes |
| Q-P2-4c-2 | With no answer for a free slot, plan nothing for it and show "choose a profession" (fewer points planned until you answer)? | Yes |
| Q-P2-4c-3 | Gathering skills in the wizard's choices (they give no points, L-3, but use a slot, L-6)? | Yes |
| Q-P2-4d | Approve P2-4d as in 10.3 (EmpireIntel 0.9.0)? | Yes, after P2-4c |
| Q-P2-4d-1 | Record your words "Use the confirmed rule: a pool of R saves R of kill XP" as confirming L-17 (status user-confirmed, D-063), so it loses its unverified label? | Yes |
| Q-P2-4d-2 | Assume one character played at a time, the others resting in an inn, for the pool growth? | Yes |
| Q-P2-4d-3 | Thresholds: rested priority at 1.4 levels or more; the login step at 0.90 levels? | Yes |

## 11. Items 5-7 of D-066 (for approval; no code)

### 11.1 All options in the window (item 5): folded into P2-4c

It fits P2-4c: the wizard asks the questions once, and the same pages stay open as the window's **Options**. Proposal (Q-P2-4c-4):

- **`/ei` opens the window** (today it prints a status line; that line moves to the Options' About page and to `/ei status`). Every command stays as a shortcut.
- **A gear button in the header** opens Options inside the window (our own frames, D-060), with pages:

| Page | What it holds | Replaces |
|---|---|---|
| General | Mode (Fastest / My plan), target, the minimap button on/off, recording on/off, "Run setup again" | `/ei plan mode`, `/ei plan target`, `/ei minimap`, `/ei off` / `on`, `/ei setup` |
| Characters | One line per character: class, level, realm and realm type, faction, rested now, professions, last seen, source; Include / Ignore; "Professions..." | `/ei alts`, `/ei rest`, `/ei unlock`, `/ei plan ignore` / `unignore` |
| Professions | The wizard's page: learned professions and the choice per free slot (gathering marked "no Legacy points") | (new, P2-4c) |
| Legacy | Earned, available, spent; the closest challenges; read on opening the page, never in combat | `/ei legacy`, `/ei milestones` |
| Rules | L-1..L-n with status and source | `/ei rules` |
| About | Version, saved-data schema and state, the fill path, the last UNEXPECTED lines | `/ei version`, `/ei plan help` |

- **Row menus** keep the per-step actions (move, add, note, target, ignore, copy the route).
- The game's AddOns options entry, if the client has the options API (P2-4c point 4), opens the same page.
- No saved field beyond P2-4c's. Tests: every command's action reachable from the window (one test per row of the table).
- Size: this roughly doubles P2-4c. **Q-P2-4c-5:** one increment (0.8.0), or two (0.8.0 professions and wizard; 0.8.1 Options)? Recommendation: two, so each has a short live gate.

### 11.2 Realistic levelling time (item 6): new increment P2-4e, after P2-4d

**Why 9 h for C2 6 -> 20 today [file: code]:** the time is the XP from 6 to 20 by the classic table (about 159,600 XP, L-15) divided by the default XP per hour by band (12,000 below 10, 18,000 from 10, L-16 [assumed]) minus the rested saving. No character has a measured rate yet (Q-F2 needs 30 minutes played in one session with a level gained). The defaults are the guess; P2-4e replaces them.

**What the game gives about quests in the log** [inherited from the classic and modern API documentation; **not yet observed on Forever**, so a check comes first]:
- the list: `GetNumQuestLogEntries`, `GetQuestLogTitle(i)` (title, quest level, headers, complete flag, quest id), or `C_QuestLog.GetInfo(i)` on newer clients;
- objectives: `GetNumQuestLeaderBoards(i)` and `GetQuestLogLeaderBoard(n, i)` (text such as "Kobold killed: 3/10", type, done), or `C_QuestLog.GetQuestObjectives(id)`;
- XP: `GetQuestLogRewardXP()` for the selected quest on clients that have it (absent on some classic builds);
- locations: **classic clients give no objective locations** (no quest map points); that is why Questie exists. The player's own position (`C_Map.GetBestMapForUnit`, `C_Map.GetPlayerMapPosition`) is available. Travel time therefore needs a database of where objectives are.

**What Questie's database could add, read only** [file: Questie's LICENSE.md, fetched 2026-11-09; content inferred from its public structure, to be checked]: quest starters, finishers and objective spawn coordinates (NPCs, objects, items), quest levels and required levels, and (for classic) quest XP. It would be read at run time from an installed Questie through a new Bridge, like DataStore: optional, read only, never stored, degrade when absent. **License:** Questie's LICENSE.md says "when in doubt consider Questie as 'all rights reserved'"; the team tolerates GPLv3 copying but "can not promise all contributors are" fine with it. EmpireIntel is MIT: **no Questie code or data is copied into the repository or the zip** (D-003); only an installed Questie is read in game. Risks: its internal tables are not a public API and can change; its data is classic's, and Forever's quests may differ.

**Why live Wowhead lookups are impossible** [inherited]: addons run in a sandbox with no network and no file access; the only output is the SavedVariables file written at logout. An offline copy of Wowhead's data would mean scraping it, which its terms forbid; not proposed.

**The model (every part labelled):** per character, time to the target level = quest part + grind part.
- Quest part: for each quest in its log at a fitting level, its XP (game or Questie, labelled which) and its time (objectives x minutes per objective [assumed, then measured] + travel between objectives and to the turn-in from Questie's coordinates at a riding or running speed [assumed]).
- Grind part: the XP left after the quests, at the character's measured kill rate, or the classic mob-XP formula and kills per hour [assumed], doubled while rested (P2-4d, L-17 unverified).
- The measured XP per hour (Q-F2) calibrates both when it exists.
- Quests completed while the user plays are seen at the next snapshot; the estimate updates.

**Steps:** (1) a check, EmpireIntelCheck 0.1.10-tp1: which quest-log functions exist and what they return for the user's log; whether `GetQuestLogRewardXP` exists; the player position; whether Questie is loaded and the shape (names, counts) of its quest tables, nothing copied. (2) Then P2-4e, built on what the check shows. Saved data: a per-character quest summary (ids, levels, XP, objective counts), which is a format change (Q-P2-4e-2).

### 11.3 What is captured at login (item 7) [file: Core/Snapshot.lua, Platform/Unit.lua]

Saved for each character the first time it logs in with EmpireIntel running, and updated at each level, profession change, timer and logout:

| Saved | From | Since |
|---|---|---|
| name (with surname), realm, class | `UnitName`, `GetRealmName`, `UnitClass` | format 1 |
| level, XP, XP to next level | `UnitLevel`, `UnitXP`, `UnitXPMax` | format 1 |
| rested XP and resting (in an inn or city), and when | `GetXPExhaustion`, `IsResting` | format 1 |
| professions: name, skill, max, skill line | `GetProfessions`, `GetProfessionInfo` | format 1 |
| race, sex, faction, ruleset (hardcore or normal), experience preset | `UnitRace`, `UnitSex`, `UnitFactionGroup`, `C_GameRules` | format 2 |
| measured XP per hour (after 30 minutes with a level gained) | the snapshots themselves | format 2 (`plan.rates`) |

So **race, sex, class, faction, realm, professions and rested are all saved**, as the user listed. **Portraits are not** (the game draws them only for a unit in view, EI-E-30); offline alts show their race and class icons, as now.

**Other useful things that could be captured** (each needs a check probe first, then the user's approval as a format change, Q-P2-4f):
1. **Bind location** (`GetBindLocation`): the inn the hearthstone is set to. Shows whether the character rests where it logs out.
2. **Logout zone and resting at logout**: already saved as "resting"; the zone name would make the rested projection's assumption visible.
3. **Played time** (`RequestTimePlayed`, the `TIME_PLAYED_MSG` event: total and this level): a much better measured rate than login sessions, and it needs no 30-minute session.
4. **The quest log summary** of 11.2 (for P2-4e).
5. Not proposed: money, gear, talents, bags (not needed for the plan).

### 11.4 Questions for the user

| ID | Question | Recommendation |
|---|---|---|
| Q-P2-4c-4 | Fold "all options in the window" (11.1) into P2-4c, with `/ei` opening the window? | Yes |
| Q-P2-4c-5 | Build it as two increments (0.8.0 professions and wizard; 0.8.1 Options) instead of one? | Two |
| Q-P2-4e | Approve P2-4e (11.2): first the check 0.1.10-tp1, then the quest-and-grind model, after P2-4d? | Yes |
| Q-P2-4e-1 | Read an installed Questie at run time (optional Bridge, nothing copied, license as quoted)? | Yes, read only |
| Q-P2-4e-2 | Save a per-character quest summary (a format change, inside format 2)? | Decide after the check |
| Q-P2-4f | Capture bind location, logout zone and played time (11.3, after a check probe; a format change inside format 2)? | Yes, played time first |

### 11.5 Answers and plan inputs (D-068, D-069; still no code)

**Answers:** Q-P2-4c-4 yes (options in the window, `/ei` opens it). Q-P2-4c-5: two increments, **0.8.0** (profession choices and the wizard), then **0.8.1** (Options). Q-P2-4e yes. e-1: Questie read only, nothing copied, works without it (but see 11.6). e-2: decided after the check. Q-P2-4f yes, played time first.

**Order:** P2-4b closes -> P2-4c (0.8.0, then 0.8.1) -> P2-4d -> P2-4e. One increment at a time; each starts after the one before closes.

**P2-4c and Q-P2-4f (into 0.8.0, with the user's inputs):**
- Captured per character **at login and on change, never during logout** (unit data is unreliable then, EI-E-08): played time with the game's own request (`RequestTimePlayed`, answered by `TIME_PLAYED_MSG`, total and this level), **gold** (`GetMoney`), **hearthstone location** (`GetBindLocation`) and **zone**. New roster fields inside format 2 (approved: Q-P2-4f, D-069). The request prints the game's own "Total time played" chat lines; the plan is to ask once per login and on level-up only.
- Roster flags, **approach from Sharpie's Roster (MIT, copied and credited only after its license file is read; else written fresh)**: a character not seen for 7 days, and a character that needs a login after an EmpireIntel update (its record lacks a field the new version captures). Gold per character and the account total on the Characters page.
- The wizard's last page tells the user to log in once on each character (and lists the ones that need it).
- **Works without DataStore and Altoholic:** a test runs the whole window with them absent, and a live step repeats it with both disabled.
- Measured XP per hour: already used in every estimate since 0.6.0 (`Route.Rate`: a character's measured rate replaces the band default). The user's saved file has rates for 7 of 8 characters (the level-1 Hunter has none) [file]. Limit: one rate per character, measured at its current levels, is used for every level ahead; P2-4e refines it with played time and the quest model.

**P2-4d (rested):** two more rested rules, **labelled unverified**: Forever's campfire buff "Camp Benefits" and sleeping-bag buff "Well Rested" (the user's hint; how each changes rested gain is to be checked live: the plan adds one check step per buff, and the rules stay unverified until the user's observation). L-17 stays unverified until the user's rested-kill check (D-065).

**P2-4e (levelling time):**
- Quest data: **LibForeverData as an optional plugin** (read while the game runs, it is offered for that; never copied: clean room for its code), with **pfQuest as the bundled fallback** (see 11.6 for its data's license).
- Quest XP: the game's own quest-XP function, which Sharpie's XP plugin uses on Forever (the user's hint): the 0.1.10 check confirms it in one line and stays short (function present, a value for one quest in the log; the player position; whether LibForeverData and pfQuest are loaded).
- XP per hour and time to level: **reuse Sharpie's XP plugin code with credit** (MIT, after its license file is read), feeding the estimates; cross-checked live against ForeverXP Bar (D-068 point 4).
- Every estimate labelled with its source (game, LibForeverData, pfQuest, measured, assumed).

**The check's saved file (EmpireIntelCheck 0.1.10, with the short quest check):** the user's file is about 252 KB by Lua's own count against the 256 KB cap (`C.DB_LIMIT`), and the cap's cascade is already dropping documented systems ("size cap") [file]. The largest parts: the Legacy challenges about 101 KB, `latest` (the old discovery results) about 45 KB, `uiLatest` about 41 KB (each atlas's raw size table about 0.5 KB), `docs` about 26 KB, `undoc` about 12 KB. Fix in 0.1.10: stop saving the discovery leftovers no later phase uses (`latest.results`, `docs`, `undoc`, `strongSeen`), keep only names and present/absent in `uiLatest` (no raw size tables), and keep only the Legacy challenges' done/progress text (as D-036 intended). Target: under 128 KB, so the cap is never reached. No change to EmpireIntel itself.

### 11.6 Two points for the user

| ID | Point | Recommendation |
|---|---|---|
| Q-D068-1 | e-1 says "Questie read only", but D-068 point 3 allows reading another add-on's data only "when it's offered for that". Questie's quest database is internal to Questie, not offered to other add-ons, and its license is "when in doubt ... all rights reserved" (its LICENSE.md). Drop the Questie read and use LibForeverData (offered) and pfQuest instead? | Yes, drop the Questie read |
| Q-D068-2 | pfQuest's code is MIT (its LICENSE file, read 2026-11-14), but its README says the vanilla database is "powered by the database of VMaNGOS", whose core repository is GPL v2. Bundling pfQuest's data tables may therefore not be "copy and credit from MIT". Options: (a) do not bundle; read an installed pfQuest's data at run time as an optional plugin instead (if it offers it), (b) bundle only pfQuest's MIT code paths, no data, (c) you check the data's license and decide. pfQuest's data is also vanilla's, not Forever's | (a), until the data's license is clear |

### 11.7 Decided (D-070)

- **Q-D068-1: the Questie read is dropped.** P2-4e reads no Questie data.
- **Q-D068-2: no quest data is bundled.** P2-4e reads **LibForeverData** while the game runs as an optional plugin, and **pfQuest the same way if installed**. With neither, the levelling estimate uses **grinding only, labelled** ("[estimate: grinding only; no quest data add-on]").
- **P2-4c also covers** (the user's 0.7.3 notes): (1) **add any milestone row from the window** (a row menu "Add milestone..." and the Options page: any class level 25/45/60 or craft 150/225/300 for any included character, never a duplicate, with its prerequisites, D-063 item 1, D-070); (2) **no profession assumed**: the route gave the level-1 Hunter, who has no professions, both Alchemy and Blacksmithing; under 10.2 points 1-2 and c-2 nothing is planned for his free slots until the user chooses one or "planner's choice" in the wizard.

## 12. Realms after build 71037: identity by GUID server, other realms and test characters, the check's trim (for approval; D-073; no code)

**Why:** since build 71037 the game returns "" for the realm name (EI-E-34); DataStore broke on it (EI-E-35); each realm has its own GUID server number (EI-E-36). EmpireIntel's roster survived (GUID keys; an empty realm is dropped, the last name kept), but new characters have no realm, and the realm-type badge cannot tell the PvP, RP and RP-PvP test characters apart. EmpireIntel must work without the user's "!RealmFix" shim (EI-E-37).

### 12.1 (a) Realm identity by GUID server number

- **The realm is the GUID's server number** (`Player-<server>-<id>`), read from the character's GUID, which the game always gives. It is never guessed from a name.
- **Name and type are labels on that number**, learned whenever the game gives a non-empty realm name for the played character: name as given, type from the end of the name (PvE, PvP, RP-PvE, RP-PvP; the 0.7.1 rule). Stored once per server number:
  ```
  EmpireIntelDB.realms = { ['6796'] = { name = 'CAMWOW US2 Realm 1 PvE', type = 'PvE', src = 'game' | 'user', at = <time> } }
  ```
  A new section inside format 2 (additive; older versions ignore it): **Q-R-1, a saved-data change**. The existing roster `realm` field stays as the character's last known name.
- **A name seen while a realm add-on such as !RealmFix is loaded** cannot be told apart from the game's. Proposal: learn it, mark the source "game or a realm add-on" when such an add-on is loaded (checked by name at run time, read only), and let the user overwrite any label. EmpireIntel never reads the shim's data.
- **Unknown server number:** shown as **"Unknown realm (6800)"**, never merged with another realm (the GUID differs, so records never merge; views group by server number).
- **Label it once in the window:** the Options' Characters page (P2-4c 0.8.1) gets a "Realms" list: each server number, its learned or user label, a name field and a type choice (PvE, PvP, RP-PvE, RP-PvP). Until 0.8.1, `/ei realm <number> <type> <name>` (Q-R-2: or wait for the window).
- **Realm type is a label, never a group.** The badge shows the realm type from the server's label; Hardcore still comes from `C_GameRules.IsHardcoreActive()` per character (the `ruleset` field) and decides the points pool (12.2).

### 12.2 (b) Other realms and test characters in the plan, the Legacy points and the roster

**Answered (D-074):** Legacy points are **account-wide across the normal realms** (PvE, PvP, RP, RP-PvP): the user's PvP-realm character shows the main realm's points (EI-E-39). **Hardcore will have its own points** (Blizzard's statement, reported by the user, untested, EI-E-40). Rules: **new L-19, confirmed** "Legacy points are shared by all normal realms" (src: EI-E-39); **L-18** ("Hardcore characters' Legacy points are kept apart") gets the user's report of Blizzard's statement as its source and stays labelled unverified until a Hardcore realm opens (EI-E-40). (Numbering: the 105% rule and the camp buffs planned in 10.3 and 11.5 become L-20, L-21 and L-22.)

**Two pools, one window:**

| | Normal pool (all normal realms) | Hardcore pool |
|---|---|---|
| Characters | every included character whose ruleset is normal, on any normal realm | characters whose `C_GameRules.IsHardcoreActive()` was true (the `ruleset` field) |
| Earned points | the game's Legacy read on a normal character | the game's read on a Hardcore character (separate) |
| Route (Fastest) | planned when a normal character is played | planned when a Hardcore character is played |
| My plan | steps of normal characters | steps of Hardcore characters are marked "Hardcore pool" and skipped while a normal character is played (and the other way round) |
| Header and card | the target counts the pool being played; the footer names it ("normal realms" or "Hardcore") | the same |

0.7.x already applies L-18 by leaving out any character whose ruleset differs from the played one; the behaviour stays, the pool is now named, and a later switch in the window shows the other pool's route without logging in on it (Q-R-6). Realm types never split the normal pool.

**Test characters and characters to leave out:**
- **Ignore per character** already exists (row menu, `/ei plan ignore`); the wizard's character page (P2-4c) lists every character with a tick.
- **Ignore a whole realm** (new): one tick per realm on the Realms list, for test realms. Ignored characters stay in the roster, marked; nothing is deleted.
- **Forget a character** (new, optional, **Q-R-3**): removes its record from EmpireIntel's saved data after a confirmation, for deleted or throwaway characters. A deletion of saved data, so it needs the user's approval as a feature.
- **Roster and `/ei alts`:** keep every character, show its realm label (or "Unknown realm (n)") and ruleset label; DataStore's blank-realm duplicates are already merged by GUID (EI-E-35), and the bridge treats an empty realm part of a DataStore key as unknown, never as a realm named "".

### 12.2b Skyborne icons and labels (D-074; small, goes with P2-4r)

- **Race plus faction picks the race icon and label:** Skyborne + Horde = **Windshaper**, Skyborne + Alliance = **High Order** (EI-E-38). The card and the Characters page show that label (for example "Windshaper Druid").
- **The icon:** the atlas names for the two are not known yet; the check (12.3) lists which `raceicon-...` atlases exist for "skyborne", "windshaper" and "highorder" (male and female). EmpireIntel uses the one the check proves; until then, or if none exists, the class icon, as now.
- **Faction unknown** (for example a DataStore-only alt without a faction): the class icon, and the label "Skyborne".
- Tests: both factions, faction unknown, the atlas present and absent.

### 12.3 (c) EmpireIntelCheck 0.1.10-tp1: the trim, brought forward

The check's file is about 248 KB of its 256 KB cap [reported; 234 KB on disk in the 2026-11-20 file, file], and it is already dropping data: its own `calls` and `partA` results are "dropped: over size cap" [file]. The trim planned in 11.5 is brought forward as its own small build, **right after P2-4b closes, before P2-4c** (Q-R-4), with no new probes except realm ones:
- stop saving the old discovery results no later phase uses (`latest.results`, `docs`, `undoc`, `strongSeen`) and the atlas raw-size tables in `uiLatest`; keep the Legacy challenges' done and progress text only; target under 128 KB;
- add realm probes: `GetRealmName()`, `GetNormalizedRealmName()`, the GUID server number, whether a realm add-on (for example "!RealmFix") is loaded, and `GetRealmID()` if the client has it (presence first, zero-argument call, under the existing limits);
- the Skyborne atlases (12.2b): which `raceicon-<skyborne | windshaper | highorder>-<male | female>` exist;
- the short quest check of 11.5 stays with P2-4e.

### 12.5 Approved (D-075) and the test addition

Q-R, Q-R-1 (the saved `realms` section inside format 2), Q-R-2 (`/ei realm <number> <type> <name>`), Q-R-3 ("Forget a character", after a confirmation), Q-R-4 (the check's trim right after P2-4b) approved; Q-R-6 yes once a Hardcore realm exists.

**Any character on the card (for P2-4r's tests and in general):** a click on the card's name opens our own list of every known character (grouped by realm label, ignored ones marked); picking one shows it on the card (portrait for the played character, else race and class icons, the Skyborne label, faction, realm type) without a plan step. Another click on the card goes back to Up next. P2-4r's live steps use it to show the Skyborne Druid, the PvP, RP and RP-PvP test characters, and a character with no faction. (`/ei alts` lines are plain chat text and cannot be clicked without game hyperlinks, so the picker is on the card.)

### 12.4 Order and questions

Proposed order: P2-4b closes -> **check 0.1.10-tp1 (trim and realm probes)** -> **P2-4r realm identity (12.1, 12.2; EmpireIntel 0.7.5 or folded into 0.8.0)** -> P2-4c (0.8.0, 0.8.1) -> P2-4d -> P2-4e.

| ID | Question | Recommendation |
|---|---|---|
| Q-R | Approve the realm plan (12.1, 12.2, 12.2b) as increment P2-4r, before P2-4c? | Yes |
| Q-R-1 | Approve the saved `realms` section inside format 2 (server number -> name, type, source, time)? | Yes |
| Q-R-2 | A `/ei realm <number> <type> <name>` command until the Options page exists, or wait for 0.8.1? | The command (small, removable) |
| Q-R-3 | Add "Forget a character" (deletes its record after a confirmation)? | Yes, with a confirmation |
| Q-R-4 | Bring the check's trim (0.1.10-tp1) forward to right after P2-4b? | Yes |
| Q-R-5 | (answered by the cross-realm test, D-074: no longer needed) | - |
| Q-R-6 | A switch in the window to show the other pool's route (Hardcore or normal) without logging in on it? | Yes, once a Hardcore realm exists |

## 13. The Fastest route's rules (D-075; for approval, no code)

### 13.1 The user's question: does Fastest follow My plan?

**No. Fastest picks characters itself; it never reads My plan** [file: `Core/Route.lua`]. Each round it lists every way to earn the next point (each character's next class milestone, each craft's next milestone on any character, each dungeon challenge) and takes the cheapest in estimated hours. My plan is the user's own list and is only ever filled from Fastest by "Copy the route to my plan".

**Why the Hunter got Alchemy and Blacksmithing** [file: code; replay of the user's 2026-11-20 saved file, offline, inferred]: the engine lets any character with a free primary slot (fewer than two, L-6) learn any craft from 0 (`learn = true`). Once its route takes the Hunter to 25 for Novice Hunter, he needs no level for a training gate, so "learn Alchemy 0 -> 150 -> 225" is cheaper than other characters' gates. The same happens to the level-1 test characters.

**Why Tailoring 225 is missing (R-3):** not a dropped step. The Priest's Tailoring 225 needs level 20 (Expert, L-4): about 16 h of levelling from 10 at his measured 8,205 XP per hour, plus about 3 h of skill, about 19 h. The route to "next reward" needed 12 more points and found 12 cheaper ones (mostly the "learn" steps of R-1). With R-1 and R-2 below, the learn steps go and Tailoring 225 comes in.

### 13.2 The rules (recorded as planner rules R-1..R-7, status "user")

| Rule | The user's rule | What the route does |
|---|---|---|
| **R-1** | Never assume a profession will be learned | A craft is planned only on characters that have it (or, from P2-4c, that the user chose for it in the wizard). A craft no character has is not planned; the footer says "not planned: no character has Engineering" (and so on). No "Learn X" step ever appears without the user's choice |
| **R-2** | The highest skill is the path | Per craft, the **path character** is the one with the highest skill (a tie goes to the higher level, then the played character). It takes every milestone of that craft (150, 225, 300), including its level gates. If it cannot reach a gate's level within the route (for example a gate above the target's horizon), the step shows "blocked: needs level n (L-4)" for that character; the route never switches to another character silently. From P2-4c the user can choose another path character |
| **R-3** | Tailoring 225 must be in the route | Follows from R-1 and R-2 (13.1); a test checks the user's case |
| **R-4** | Leave the RP-PvP test character out | Today: right-click his row > Ignore, or `/ei plan ignore <name>` (exists since 0.6.0; no build needed). P2-4r adds ignore per realm and "Forget a character" (Q-R-3) |
| **R-5** | Up next must be in the table | Step 1 becomes row 1 in Fastest too, highlighted as Up next (as in My plan), so the rows count every step |
| **R-6** | Targets: plan to the cap by default, track beyond it; no hard-coded 15 or 16 | Targets: **Cap** (default), **Next reward**, **Next point**, **A number** (1 to 65), and **All 65**. The cap and the reward track come from the rules table (L-12 cap 16, unverified; L-13 rewards 15/25/40/55, confirmed by screenshot), never from code; the cap is editable (Options, P2-4c; `/ei plan cap <n>` until then) because the game gives no cap value (Legacy_Rules.md section 3). Beyond the cap the header says "earned 17 of 65 (cap 16: points over the cap are earned but cannot be spent)" [inferred from EI-E-04 "seasonal cap"; to be confirmed] |
| **R-7** | A row with no point that unlocks a later point says so | Such a row shows "prerequisite for step n" in the PTS column's place (tooltip: what it unlocks); a level step for a gate, a 150 step before a 225, a dungeon's level step |

### 13.3 Where they go: proposal

| Part | Proposal | Why |
|---|---|---|
| R-1, R-2, R-3, R-5, R-7 | **P2-4b fix 0.7.5, before closing** | They decide whether the window's route is right; P2-4b's gate is the window showing the route. Each is small and pure (Route, PlanView); about 15 tests |
| R-4 | **Nothing to build now**; ignore him in the window today; P2-4r adds realm ignore and Forget | The feature exists |
| R-6 targets and an editable cap | **P2-4c** (with Options) | It needs a saved setting (`plan.cap`, a format change inside format 2) and the Options page; until then the target button keeps Cap 16, Next reward, Next point, and the 16 moves from code into the rules table in 0.7.5 so nothing is hard-coded twice |

Order after that, as agreed: close P2-4b -> EmpireIntelCheck 0.1.10 trim -> P2-4r -> P2-4c -> P2-4d -> P2-4e.

| ID | Question | Recommendation |
|---|---|---|
| Q-R7 | Build R-1, R-2, R-3, R-5 and R-7 as P2-4b fix 0.7.5 before closing; R-6 in P2-4c; R-4 by ignoring him now? | Yes |
| Q-R7-a | R-2 tie-break: highest skill, then higher level, then the played character? | Yes |
| Q-R7-b | R-1 with P2-4c: once the wizard exists, a craft no character has can be planned only on a character the user picked for it (or "planner's choice")? | Yes |

### 13.4 Decided and built (D-076)

- Q-R7 yes: **R-1, R-2, R-3, R-5, R-7 built as P2-4b fix 0.7.5**; the cap moved into the rules table (`RouteRules.CAP`, L-12); R-6 (targets and an editable cap) goes to P2-4c. Q-R7-a yes (highest skill, then level, then the played character).
- **Q-R7-b (for P2-4c):** a craft no character has is planned only on a character the user picked for it; the planner may **suggest** one (for example in the wizard: "suggested: the Hunter, a free slot"), but it plans nothing until the user picks. This replaces the "planner's choice" option of 10.2 for crafts no character has.
- **R-3 as built:** the Priest's Tailoring 225 is planned on him (R-2), but it costs about 19 h (levels 10 -> 20 first), so in the user's data it is the 16th cheapest step and appears at a target of about 20 [inferred, offline replay of the user's 2026-11-20 file]. R-6's "All 65" and "track beyond the cap" (P2-4c) will show it without changing the target.
- The user has ignored the test characters (R-4).
