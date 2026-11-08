# P2-4a Report: the route planner (EmpireIntel 0.6.0) and the UI checks (EmpireIntelCheck 0.1.9-tp1)

DOC VERSION: 1.0.0  |  DATE: 2026-11-08 (S-058)  |  STATUS: **Built, not merged, waiting for the live tests.** Approved by the user (D-056); build choices in D-057. Branch `p2-4a-planner`.

## 1. What was built

**EmpireIntel 0.6.0 (P2-4a, Phase2_Plan.md 8.1, 8.4-8.7):**

| File | What it does |
|---|---|
| `Core/RouteRules.lua` (new, pure) | Rules L-1..L-18 with status and source; the XP table (L-15), the default costs (L-16), training gates (L-4, L-5), dungeon counts and levels (L-7, L-8), Explorer level (L-11, D-056), the reward track (L-13) |
| `Core/Route.lua` (new, pure) | The greedy route engine: cheapest next point including its gates, applied and repeated until the target; rested XP saves R in full (L-17); Legacy lock (D-052); rulesets never mixed (L-18); the game's count when a Legacy read is given (Q-F5) |
| `Core/Plan.lua` (new) | The saved plan (format 2): mode, target, my steps, ignored characters, measured XP rates (Q-F2); the step checks reused from #11 |
| `Core/Next.lua` (new) | `/ei next` (auto or mine), `/ei plan ...`, `/ei rules`; goal lines reused from #11 |
| `Store/Migrations.lua` | Step 1 -> 2: adds an empty `plan` section; nothing converted |
| `Platform/Unit.lua`, `Core/Snapshot.lua` | Roster records gain race, sex, faction, ruleset, preset (live character, each snapshot); the snapshot feeds the XP-rate measurement |
| `Core/Alts.lua`, `Core/Views.lua`, `Core/Rules.lua`, `Core/Commands.lua` | Merge carries the new fields from the own record; `Views.Collect` exported; challenge-name tables (#11); command routing |

No window code (D-056): a static test checks that no EmpireIntel file creates frames (outside the event and scheduler frames) or names a UI call, and that the TOC has no P2-4b header.

**EmpireIntelCheck 0.1.9-tp1 (Q-G1, 8.3.4):** `UI.lua` (new) runs the UI checks in every check run (not in combat) and on `/eicheck ui`. Each result is what the game returned: present (with the value), nothing (the function exists but returned nothing), absent, or failed (with the error). Test widgets are made once per session under one parent that is hidden at once; nothing is shown, anchored, sized or moved; the EditBox cannot take the keyboard. `Media/Test.tga` (8x8, our own flat colour) tests "SetTexture with a file in the addon folder". Saved: `uiLatest` (full), counts per run, `uiChars[GUID]` (identity values, no names).

**Tooling:** `tools/build_package.py` ships `Media/*.tga` and prints the full sha256.

## 2. Tests

- **408 tests pass** under Lua 5.1 and Lua 5.3 (321 before; 49 new for P2-4a, 18 for the UI checks; P2-1 tests updated to format 2).
- **Mutation check: 20 of 20 guards caught** (lock rule twice, rest at half, rulesets mixed, ignore, learn without a slot, Explorer before 50, tie order, game count, Legacy read before the unlock, rate before 30 min, read-only write, unknown GUID, migration converting, ruleset guessed, parent not hidden, EditBox focus, UI in combat, "nothing" counted as present, widgets every run).

## 3. What `/ei next` shows on a synthetic copy of today's account

C1 Paladin 27 (Mining, Skinning), C2 Priest 6 (Tailoring 56/75, Enchanting 28/75), played on C2, no Legacy read (the fake client has none). [inferred] from the test client, not the game:

```
next (fastest route to 16 Legacy points; 1 earned [inferred from levels and skills: class and craft challenges only]; 18 rules, 11 unverified: /ei rules):
1. Cee Two Priest 6: level 10, then Tailoring 56 -> 150 (train Journeyman): +1 (Journeyman Tailor), ~4.1 h (rest saves ~9 min) [estimate; unverified: L-4 L-5 L-15 L-16 L-17]
2. Cee Two Priest 10 (in this route): Enchanting 28 -> 150 (train Journeyman): +1 (Journeyman Enchanter), ~3.2 h [estimate; unverified: L-4 L-5 L-16]
3. Cee One Paladin 27: Novice Spelunker: 6 dungeons, progress not read: +1 (Novice Spelunker), ~4.5 h [estimate; unverified: L-8 L-16]
...
```

This matches the illustrative order in 8.6 (C2 to 10 then Tailoring 150, then Enchanting 150). On the live account the Legacy read replaces "[inferred]" with "[game]" and the dungeon counts with the game's steps.

## 4. Live gate (the user's tests; steps in each package README)

| Package | Item | Expected |
|---|---|---|
| EmpireIntel 0.6.0 | `/ei version` | "version 0.6.0, saved data schema 2 (migrated)", then "(ok)" |
| | `/ei next` | the route; earned [game] matches "Legacy Points N / 65" |
| | `/ei rules` | 19 lines |
| | `/ei plan copy`, `mode mine`, `/ei next`, `mode auto` | my plan shown, then the route again |
| | saved file | `schema = 2`, a `plan` section, the played character's `race`, `sex`, `faction`, `ruleset`, `preset` |
| EmpireIntelCheck 0.1.9-tp1 | `/eicheck ui` on two characters | one "UI checks:" line each; `uiLatest` and `uiChars` in the saved file |
| Both | | no UNEXPECTED, no Lua error, nothing appears on screen |

## 5. Open questions for the user

| ID | Question | Recommendation |
|---|---|---|
| Q-P2-4a-1 | Keep editing "my plan" in chat (`/ei plan ...`) until the window exists (D-057)? | Yes |
| Q-P2-4a-2 | Merge `p2-4a-planner` after the live tests pass? | After the live tests |
| Q-P2-4a-3 | Later, for P2-4b: allow DataStore's faction getter (if 0.1.9 finds it) so alts show a faction before their next login? | Decide with the 0.1.9 results |
