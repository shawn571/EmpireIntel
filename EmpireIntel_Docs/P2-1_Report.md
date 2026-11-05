# P2-1 Report: live test of EmpireIntel 0.2.0

DOC VERSION: 1.0.0  |  DATE: 2026-11-05  |  Source: the user's `EmpireIntel.lua`, sent by hand (not committed). Characters aliased C1 (Paladin) and C2 (Priest); no names, GUIDs or account details here.

**Result: P2-1 works on two characters, with one defect (D1), fixed in 0.2.1.** The user has not yet said whether `/ei` matched the game; that confirmation is part of the closing gate (Q-P2-1c).

| Check | Result |
|---|---|
| Records | 2, keyed by GUID; two-part names, realm (both on one named realm), class, level, XP, professions |
| meta | exactly `created`, `opens = 2`, `version 0.2.0`, `build 1.60.1/70790`; schema 1 |
| XP | xpMax 3600 at level 6 and 10100 at level 12, matching the classic XP table |
| Rested | C2: 414 XP while resting (inn). C1: none reported, stored as unknown, not 0 |
| Professions | C1: Mining 26/75, Skinning 50/75, Cooking 1/75. C2: Tailoring 38/75. Skill line ids Mining 186, Skinning 393, Cooking 185, Tailoring 197 (EI-E-14) |
| Logout guard | Fired once: C2's last reading is from about a minute before its logout, and only `lastSeen` moved at logout, so the logout values were rejected (EI-E-08 again). C1's logout reading was valid and was saved |
| **D1 (defect)** | C1 had **no `resting` field**. `Unit.Progress` used `(r == true or r == false) and r or nil`, which turns `false` into `nil`, so "not resting" was never stored, and `/ei` showed "not resting" for unknown too. **Fixed in 0.2.1**: explicit true/false/nil; `/ei` says "resting unknown" when unknown; 2 new tests; reintroducing the bug fails the suite |

Gate for closing P2-1: run 0.2.1, confirm "not resting" is saved, and confirm `/ei` matched the game on two characters.
