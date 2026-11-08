# EmpireIntel Phase 2 Plan: pre-25 features

DOC VERSION: 1.4.0  |  DATE: 2026-11-08  |  STATUS: **Phase 2 authorized for the pre-25 features only (D-027). P2-1, P2-2 and P2-3 closed (D-029, D-032, D-041). P2-4 approved (section 7, D-052).**

**Phase 2 builds EmpireIntel's pre-25 features:** unlock progress, rested XP, milestones ahead and "what next" (Requirements FR-PRE-1..4, FR-REST-1, FR-PROF-1, FR-ALT-1). P2-1 to P2-3 use no Legacy API. **P2-4 uses the Legacy reads proven in P3-1, on command only, under the Legacy lock rule (section 7.3, D-052).** Perks and the per-character cap wait for Q-T4.

Out of scope for Phase 2: any Legacy call beyond the P3-1 reads (used by P2-4 only, D-052), trait-system calls, UI windows (commands only), the release pipeline (Stage 1 not authorized), GoldIntel (handled elsewhere).

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

## 7. P2-4 in detail: "What next" (for approval, Q-P2-4)

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
