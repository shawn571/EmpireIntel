# EmpireIntel Phase 3 Plan: `/ei legacy`

DOC VERSION: 0.1.0  |  DATE: 2026-11-08  |  STATUS: **Plan for the user's approval. Phase 3 is NOT authorized. No code.**

**Phase 3 would let EmpireIntel itself show the Legacy values that EmpireIntelCheck has proven readable (TP-1 runs 6-14):** points earned, available and spent, and every challenge with its steps and what is left. It reuses the check's proven calls and limits (Q-T7, Q-T8, Q-T9). Per-tree detail is not in the first version: it needs the trait system (Q-T4), which is unapproved and can wait (section 5).

## 1. What is proven (the check, runs 6-14)

| Value | Source | Needs the pane? | Status |
|---|---|---|---|
| The 65 challenges, done or not | Achievement getters: `GetCategoryList`, `GetCategoryInfo`, `GetCategoryNumAchievements`, `GetAchievementInfo`. A challenge is an achievement whose reward text names a Legacy point | No, available at login | Confirmed (EI-E-22) |
| Each challenge's steps, done or not, with progress counts | `GetAchievementNumCriteria`, `GetAchievementCriteriaInfo` | No | Confirmed (EI-E-23) |
| Explorer's 46 steps (Explore Azeroth, 2 roll-ups, 43 zones) and each zone's areas | The game's own achievement links | No | Confirmed (run 9) |
| **Earned** points | Sum of completed challenges' reward points | No | Confirmed (matches the pane, runs 8-14) |
| **Available** points | `LegacySystem.GetCurrencyInfo().quantity` | **Yes**, filled once the pane has loaded that session | Confirmed: -1 per applied spend, +1 per earn (EI-E-25) |
| **Spent** points | `LegacySystem.GetCurrencyInfo().spent` | Yes | Confirmed: +1 per applied spend; unapplied placements are not counted (EI-E-26) |
| `maxQuantity`, `renownCurrency` | same call | Yes | Both equal earned; not shown separately (only a cross-check) |
| `spentInTree` | same call | Yes | **Unexplained; left out** (user, 2026-11-08) |
| Tree contents (nodes, ranks, perks) | Trait system | n/a | **Not read** (Q-T4 unapproved) |

## 2. Increments

| Increment | Delivers | Reload or restart | Gate |
|---|---|---|---|
| **P3-1 `/ei legacy` (live)** | The command below, read on demand, nothing stored | `/reload` (new files in the existing folder, D-034) | Tests under Lua 5.1 and 5.3 with fixtures built from runs 8-14. Live: points, challenge counts and the Spelunker and Explorer steps match the pane, with the pane loaded and not loaded |
| P3-2 Saved Legacy summary (optional, later) | A small saved record (points, completed challenge ids, time), so `/ei legacy` can show the last-known points before the pane is opened, and P2-4 "what next" can use challenges. **Saved-data format 2: needs separate approval** | `/reload` | Migration tests; format approval |
| P3-3 Per-tree detail (only if Q-T4 is approved) | Points per tree, ranks per node, perk names; explains `spentInTree` | `/reload` | Q-T4 first; its own plan |

P2-4 (plan file, "what next") stays where it is in Phase 2. Once P3-1 exists, it could also suggest the closest challenges, for example "Novice Spelunker: 1 dungeon left".

## 3. P3-1 in detail (for approval, Q-P3-1)

| Item | Design |
|---|---|
| New file `Platform/Legacy.lua` | The only file that calls the Legacy and achievement functions (static test), ported from EmpireIntelCheck `Legacy.lua`: the same 9-name allowlist, numeric arguments only when the game returned them, the denylist, the combat skip, and the scheduler spreading the work over frames. `LegacySystem.GetCurrencyInfo()` with no argument only. No trait-system call, and no `UpdateCurrencyInfo` or `RegisterCurrencyInfoCallback` |
| New file `Core/LegacyView.lua` | Builds and prints `/ei legacy` from the read |
| When it reads | **Only when the user types `/ei legacy`.** No login read, no timer. About 950 calls spread over frames: the answer arrives in a second or two |
| Crash guard | The check writes each name to saved data during its call. In EmpireIntel that would add a field to saved-data format 1. Proposal: **no saved guard**. Reads happen only on the user's command, so a crash is seen by the user, who does not repeat it. This is the same reasoning the user accepted for `/eicheck undoc` (Q-T3). See Q-P3-1a |
| Saved data | **None.** Format 1 unchanged. The read result lives only until the next `/ei legacy` |
| Labels | Earned, available and spent are shown without "estimate". Steps show their progress. If the pane is not loaded: "points: open the Legacy window once this session". If the pane's earned count (maxQuantity) differs from the challenge sum: one UNEXPECTED line. If no reward text is recognized (a non-English client): one UNEXPECTED line, and challenges are not counted |
| Combat | No call in combat; the command says "try again after combat" |

Illustrative output (C1 stands for a character name; values from run 14):

```
/ei legacy
Legacy: 2 of 65 points earned; 0 available, 2 spent. [pane loaded]
Classes 1/27 | Tradeskills 0/18 | PvP 0/12 | Adventure 0/2 | Dungeons 1/3 | Raids 0/3
Closest: Experienced Spelunker 1 of 10 dungeons (left: City of Dalaran, Gnomeregan, The Drowned City, +6)
         Explorer 0 of 46 (11 zones started; furthest: Silverpine Forest 13/15 areas, Tirisfal Glades 13/16)
         Experienced Paladin: C1 is 25 of 45 [from EmpireIntel's records]
/ei legacy all     one line per challenge, done or with what is left (long)
```

| Gate | Pass when |
|---|---|
| Tests | Lua 5.1 and 5.3. Fixtures from runs 8-14 (65 challenges, the Explorer chain, the six point fields before and after spends and earns). Pane not loaded. Combat. A thrown error. Non-English reward text. Static: game calls only in `Platform/Legacy.lua`; no saved-data write |
| Live | Earned, available and spent match the pane. The group counts match the pane's lists. One challenge's steps match the pane (for example Experienced Spelunker). With the pane not yet opened, the line says so and challenges still show |

## 4. What stays with EmpireIntelCheck

The check stays the test tool. After P3-1 passes, the user may retire it (a separate decision).

## 5. Per-tree detail and Q-T4

- **Not needed for P3-1.** The pane's own header shows available and spent for the whole account; `/ei legacy` shows the same.
- **Needs Q-T4:** which tree and perk the points are in, ranks per node, and what `spentInTree` means. This means reading the trait system with ids the game returns (the Legacy trait currency is 4225, EI-E-21). It would be P3-3, with its own plan, after the user decides Q-T4.

## 6. Questions for the user

| ID | Question | Recommendation |
|---|---|---|
| Q-P3 | Authorize Phase 3 for `/ei legacy`, with one approval per increment, as in Phase 2? | Your decision |
| Q-P3-1 | Approve P3-1 as in section 3? | Yes |
| Q-P3-1a | No saved crash guard in EmpireIntel (reads only on command), so saved-data format 1 is unchanged? | Yes |
| Q-T4 | Trait-system reads for per-tree detail | Can wait; decide after P3-1 |
