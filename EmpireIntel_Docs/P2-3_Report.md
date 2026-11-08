# P2-3 Report: views, live tests

DOC VERSION: 1.1.0  |  DATE: 2026-11-08  |  STATUS: **Closed (user, 2026-11-08, D-041).** Views check passed; formal inn test passed (section 3).

The user's chat lines were read as data; C1 (Paladin), C2 (Priest) and C3 (the stale beta Shaman) stand for the characters.

## 1. Views check (EmpireIntel 0.4.0, 2026-11-08 00:37 user time)

| Gate item | Result |
|---|---|
| `/ei version` | **Pass**: "version 0.4.0, saved data schema 1 (ok)" |
| `/ei unlock` | **Pass**: Legacy unlocked, C1 Paladin 26 reached 25 (C1 has since reached 26) |
| `/ei milestones` | **Pass** (user compared with the game): Paladin 26 -> next 45 (19 levels); Priest 6 -> next 25; Enchanting 28/75 and Tailoring 56/75 with "train to raise max 75"; "Classes 1 of 27, crafting 0 of 18, about 1 Legacy point [estimate]". The stale beta Shaman is still listed (to be deleted in Altoholic) |
| `/ei rest` | **Pass**: C1 live 52 XP, not resting, matches the game. C2 measured 1506 XP 14 h ago, resting, projected about 1835 XP [estimate] |
| Labels | Present on every estimate and on the rules line |

Note:
- The class and crafting rules that `/ei milestones` still labels "not yet confirmed by the game" have since been confirmed by the client (EI-E-22).
- Removing that label is a P2-3 change; it waits for the user's decision on P2-3.

## 2. Rest projection: supporting data point (not the formal inn test)

| | Value |
|---|---|
| Baseline | 1506 XP, from DataStore (C2's last logout, resting), 14 h before |
| Projection at 00:37 | about 1835 XP (0.51 levels) [estimate] |
| Live on C2 shortly after | 1844 XP (0.51 levels), resting |
| Difference | about 9 XP, 0.5% |

Recorded as **supporting, not a pass** (user):
- the baseline came from DataStore, not a live read at logout;
- the wait was 14 h, not a controlled 8 h;
- it is a single point.

The formal inn test (P2-3 README step 7) is pending.

## 3. Formal inn test (EmpireIntel 0.4.0 code in 0.5.0, 2026-11-08 01:42-09:59 user time)

Run on **C1 Paladin 27**, not C2, as the plan allowed (user: "formal run, Paladin (not the Priest, as the plan allowed)"). C1 logged out in an inn and was not logged in again until step c.

| Step | Chat line (names replaced) |
|---|---|
| a, 01:42:38, C1 in an inn | "C1 Paladin 27: now 2 XP (0.00 levels), resting [this character, live]" |
| a, same | "C2 Priest 6: measured 1842 XP (0.51 levels) 1 h ago, resting -> now about 1865 XP (0.52 levels) [estimate] [self]" |
| b, about 09:57, on C2 | "C1 Paladin 27: measured 0 XP (0.00 levels) 8 h ago, resting -> now about 1992 XP (0.05 levels) [estimate] [datastore]" |
| c, 09:59:19, C1 live | "C1 Paladin 27: now 2012 XP (0.05 levels), resting [this character, live]" |
| c, same | "C2 Priest 6: measured 2050 XP (0.57 levels) 5 min ago, resting -> now about 2052 XP (0.57 levels) [estimate] [self]" |
| c, same | "C3 Shaman 9: measured 0 XP 17 days ago, not resting -> no projection: XP bar not measured at level 9 [datastore]" |

**Result: pass (within the 10% line of Phase2_Plan.md section 6).**
- [O] C1: projected 1992 at step b, live 2012 at step c: gap 20 XP, 1.0%.
- [I] The two reads were about 2 minutes apart. At about 240 XP/h (1992 XP over about 8.25 h) that is about 9 XP, so the like-for-like gap is about 11 XP, about 0.5%. The user's reading ("the real gap is about 0.5%") agrees.
- [O] The base at step b was DataStore's logout value, 0 XP, not EmpireIntel's 2 XP at step a; a 2 XP difference, which does not change the result.
- [O, I] C2 (supporting point, logged out in an inn the whole time): 1842 XP at about 00:42 to 2050 XP at about 09:54, about 9.2 h. With C2's level-6 bar of 3600 XP (EI-E-14), the rule predicts 0.05 x 9.2 / 8 x 3600 = about 207 XP, so about 2049; measured 2050. The "1 h ago" and "5 min ago" ages are rounded, so the true gap is within about 10 XP either way.
- [O] C3's line: correct handling of a character with no measured XP bar (still the stale beta entry).
- **What this covers (user):** "resting in an inn for about 8-9 hours, at the full rate. It does not cover the outside-inn quarter rate, the 1.5-level cap, or very long gaps."

Also observed: EmpireIntel 0.5.1 installed over 0.5.0 at 09:50 with `/reload`; "/ei version, /ei legacy all and /gi version all gave the expected output" (user).

## 4. Closing P2-3 (Q-P2-3c)

**Closed** by the user, 2026-11-08: "Q-P2-3c: close P2-3, with the label change you propose: drop \"not yet confirmed\" for the inn rate only; keep \"unverified\" for the outside rate and the cap." (D-041)

The label change is approved but **not yet built**; it is a text change in `Core/Rules.lua` (`R.LABEL_REST`), shipped in the next EmpireIntel package (proposed 0.5.2, `/reload`).
