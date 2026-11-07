# P2-2 Report: alts from DataStore, live tests

DOC VERSION: 1.0.0  |  DATE: 2026-11-06  |  STATUS: **Gate partly passed. DataStore off: pass. DataStore on: not yet seen.**

The user's saved file and chat lines were read as data. No names, GUIDs or account details are copied here: C1 and C2 stand for the two characters.

## 1. Live test 1 (EmpireIntel 0.3.0, launch build 1.60.1/70790)

| Gate item | Result |
|---|---|
| Loads with no error next to GoldIntel, EmpireIntelCheck and the user's other addons | **Pass** (no error reported; GoldIntel and the check both ran in the same session) |
| Saved-data format 1 unchanged by P2-2 | **Pass**. The file has only schema, meta (version 0.3.0, 23 opens, build 1.60.1/70790) and roster with the format 1 fields. No DataStore value and no new key |
| DataStore off: `/ei alts` still answers | **Pass**. "2 characters (2 recorded by EmpireIntel, 0 from DataStore only). DataStore is not installed: EmpireIntel records only." No UNEXPECTED line |
| Lines match the saved records | **Pass**. C1 Paladin 16 (this character, not resting, Mining 41/75, Skinning 77/150, Cooking 6/75). C2 Priest 6 (650 rested XP = 650/3600 = 0.18 levels, resting, Tailoring 55/75, Enchanting 19/75, 33 min ago) |
| DataStore on: `/ei alts` matches the game for every character | **Not seen yet**. The chat paste held only the DataStore-off run (the earlier scrollback was cut off) |

## 2. Defect D2 (wording), fixed in 0.3.1

C1's line said "rested unknown". In EmpireIntel's own record, an empty rest means the game reported no rested XP (`/ei` says "none reported"). `/ei alts` now says "rested none reported" for own records. "Rested unknown" is kept for DataStore values that are missing. Lua only, `/reload`. One test added; 212 pass under Lua 5.1 and 5.3.

## 3. Seen in passing

- The chat shows EmpireIntelCheck **0.1.4-tp1** still installed, not 0.1.5-tp1. This is harmless before level 25, but 0.1.5 should be installed before the level-25 run (whole-word blocklist and the Reincarnat stem, D-026).
- C1 is level 16: 9 levels to the Legacy unlock.

## 4. Seen in the 2026-11-07 files (DataStore on, still 0.3.0)

- DataStore knows 3 characters; EmpireIntel knows 2. C1 and C2 match between the two: level, class, and both primary professions with ranks. C3 (Shaman 9, Skinning 61/75) is known only to DataStore, so `/ei alts` should show it marked `[datastore]`.
- `GetModuleLastUpdateByKey` returned nil (EI-E-17). The bridge falls back to the last logout time, as designed, so ages still show.
- Saved data is still format 1 with no new key; `meta.version` = 0.3.0, so 0.3.1 was not installed yet.
- The `/ei alts` lines themselves were not sent.

## 5. Still needed to close P2-2 (Q-P2-2c)

`/ei alts` with DataStore ticked, on 0.3.1: every line copied or a screenshot, plus the user's word that the lines match the game.
