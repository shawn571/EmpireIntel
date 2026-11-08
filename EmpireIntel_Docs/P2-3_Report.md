# P2-3 Report: views, live tests

DOC VERSION: 1.0.0  |  DATE: 2026-11-08  |  STATUS: **Views check passed. Formal inn test pending. Q-P2-3c open (the user decides after the inn test).**

The user's chat lines were read as data; C1 and C2 stand for the characters.

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

## 3. Closing P2-3 (Q-P2-3c)

Waiting for the formal inn test. The user decides Q-P2-3c after it.
