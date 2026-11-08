# P3-1 Report: `/ei legacy`, live tests

DOC VERSION: 1.0.0  |  DATE: 2026-11-08  |  STATUS: **Closed (user, 2026-11-08, D-042).** Live test 1 passed on content; the two readability defects were fixed in 0.5.1, which the user checked.

The user's chat lines were read as data; C1 stands for the character.

## 1. Live test 1 (EmpireIntel 0.5.0, 2026-11-08 01:09-01:11 user time, C1 Paladin 26)

| Gate item | Result |
|---|---|
| `/ei version` | **Pass**: 0.5.0, schema 1 (ok) |
| Before the window was opened | **Pass**: "2 of 65 points earned; available and spent: open the Legacy window once this session.", with the groups and Closest lines |
| After the window was opened | **Pass**: "2 of 65 points earned; 0 available, 2 spent. [pane loaded]". The check's read at the same time gave quantity 0, spent 2, maxQuantity 2 |
| Group counts | **Pass**: Classes 1/27, Tradeskills 0/18, Dungeons 1/3, Raids 0/3, Player vs. Player 0/12, Adventure 0/2: 65 challenges, 2 done |
| Steps | **Pass**: Experienced Spelunker 1 of 10, Master Spelunker 0 of 17, Conqueror of the Wilds 0 of 13, of the Deeps 0 of 8, Explorer 0 of 46 on this character with 13 zones started. These agree with the check's reads (EI-E-23) |
| Hints | "Novice Shaman: <stale beta character> is 9 of 25" and "Journeyman Tailor: C2 is 56 of 150", both [from EmpireIntel's records]. The Shaman hint comes from the stale DataStore character that the user will delete; it is correct by the data |
| Against the panes | The user checked several panes, including Adventure, and reported no mismatch |
| UNEXPECTED, Lua errors | None |
| Side by side with EmpireIntelCheck | Both ran in the same session without conflict |

**Defects in `/ei legacy all` (readability), fixed in 0.5.1 (`/reload`):**
- **D1:** the lines came in the game's internal order (Druid, Alchemy, Ranks, Hunter, ...), mixing the groups. 0.5.1 sorts group by group, then by sub-group.
- **D2:** "[Adventure] Explorer: Explorer 0 of 46 ..." repeated the name.

Both have tests: a reversed category list keeps the order; 321 tests pass under Lua 5.1 and 5.3.

## 2. 0.5.1 check (2026-11-08 09:50 user time)

[O] The user installed 0.5.1 over 0.5.0 with `/reload` and reported: "/ei version, /ei legacy all and /gi version all gave the expected output". `/reload` was enough, as the package said (D-034).

## 3. Closing P3-1 (Q-P3-1c)

**Closed** by the user, 2026-11-08: "Q-P3-1c: close P3-1." (D-042). Q-T4 stays unapproved; P3-2 and P3-3 stay locked.
