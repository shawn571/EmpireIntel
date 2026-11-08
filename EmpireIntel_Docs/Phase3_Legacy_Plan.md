# EmpireIntel Phase 3 Plan: `/ei legacy`

DOC VERSION: 0.2.0  |  DATE: 2026-11-08  |  STATUS: **P3-1 closed (D-042). Post-25 plan in sections 7-12 (plan only, no code; the user approves one increment at a time). P3-2, P3-3 and P3-4 locked; Q-T4 unapproved.**

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

---

# Post-25 plan (S-054, plan only)

Written at the user's request (2026-11-08): "plan only and no code: write a post-25 plan (Phase 3) covering P3-2 saved summary, P3-3 per-tree detail with what Q-T4 would need, and perk goals for the plan file, with questions for me. I’ll approve one increment at a time." Nothing here is approved. Sections 1-6 above are the P3-1 plan as approved and built.

## 7. Where things stand, and what is not known

**Done:** P3-1 `/ei legacy` (0.5.0-0.5.2, closed). P2-4 `/ei next` with plan file format 1 (built as 0.6.0, D-053), whose challenges goal uses the P3-1 reads under the Legacy lock rule (D-052).

**Facts the later increments depend on:**

| Question | What is known | Matters for |
|---|---|---|
| Are **available** and **spent** per character or per account? | Read only on C1 so far (EI-E-24 to EI-E-26). Client text: a *seasonal* cap on points spent "in total" (EI-E-04) [file]; per character or per account is **not known** | P3-2 (where to store points), P3-4 (whose points a perk goal spends) |
| The spending cap | 16 at launch [web, unconfirmed]; not seen in any read | P3-4 |
| Tree contents | Three trees (Professions, Adventure, Resourcefulness), 9 visible nodes each, 25 ranks per tree (Legacy_Rules.md section 2) [screenshot]; perk names only from web sources | P3-3, P3-4 |
| How the trees are read | Not at all yet. Points are a trait currency (4225, EI-E-21); a Forever trait config type exists (`Enum.TraitConfigType.CamelotCombat = 4`, EI-E-04). That the trees are a `C_Traits` config is **[inferred]** | P3-3 |

**A no-code check settles the first question** (section 12, Q-P3-2a): open the Legacy window on C2, type `/ei legacy`, and compare "available" and "spent" with C1's. Same numbers on both: account-wide. Different: per character.

## 8. Order of the increments

| Step | What | Needs first |
|---|---|---|
| 1 | The C2 pane check (no code) | nothing |
| 2 | **P3-2 Saved Legacy summary** (saved-data format 2) | step 1; Q-P3-2 |
| 3 | **Q-T4 discovery** in EmpireIntelCheck (a test package, not EmpireIntel) | Q-T4a, then Q-T4b |
| 4 | **P3-3 Per-tree detail** in EmpireIntel | step 3's evidence; Q-P3-3 |
| 5 | **P3-4 Perk goals** (plan file format 2) | P3-3, and step 1 for whose points |

Each step is approved on its own. P3-2 does not depend on Q-T4 and can come first or not at all.

## 9. P3-2 Saved Legacy summary (for a later approval, Q-P3-2)

**Purpose:** remember the last Legacy read, so that:
- `/ei legacy` can show the last-known points before the window is opened this session ("last read 3 h ago: 0 available, 2 spent");
- `/ei next` can answer a challenges goal from the last read, labelled with its age, when a new read is not possible (in combat, or a read already running).

**Saved-data format 2 (proposal; a format change needs the user's approval, D-019):**

```
EmpireIntelDB = {
  schema = 2,
  ...                                         -- everything in format 1, unchanged
  legacy = {                                  -- new: account-wide, from the last /ei legacy or /ei next read
    at = <time>, earned = 2, offered = 65,
    completed = { 61997, 62031 },             -- ids of the completed challenges (at most 65 numbers)
    groups = { [<group id>] = { done = 1, total = 27 }, ... },
  },
  roster = {
    [<GUID>] = {
      ...                                     -- format 1 fields, unchanged
      legacyPoints = { available = 0, spent = 2, at = <time> },   -- new, only if step 1 shows points are per character
    },
  },
}
```

- If step 1 shows the points are account-wide, `available` and `spent` go into `legacy` instead, and roster records are unchanged.
- **When it writes:** only after a read the user started (`/ei legacy`, or `/ei next` with a challenges goal). No login read and no timer, as in P3-1 (Q-P3-2b).
- **What it never stores:** step names, criteria, Explorer zones, `spentInTree`, `maxQuantity`, or anything from the trait system.
- **Size:** under 2 KB.
- **Migration:** 1 to 2 adds the empty `legacy` section; nothing is converted. GoldIntel's copy-then-commit framework, as for format 1.
- **Rollback:** 0.6.x opening format-2 data sees a newer schema and leaves it untouched, using a private copy for that session (Store `readonly` state, already built and tested). Nothing is lost, but 0.6.x records nothing new until the newer version is back. The README will say so.
- **Restart or reload:** `/reload` (existing folder).
- **Tests:** migration 1 to 2, and 2 opened by the old version (readonly); writes only after a user-started read; last-known lines with their age; nothing outside the listed fields is saved (static test).
- **Live gate:** after `/ei legacy` with the window open, `/reload`, then `/ei legacy` without opening it: the last-known line matches. The SavedVariables file shows only the listed fields.

## 10. Q-T4 and P3-3 per-tree detail

### 10.1 What Q-T4 would need

Q-T4 has been open since 2026-11-03: "a read-only call chain **with arguments** into the trait system". Below are the limits it would run under and the two approval steps proposed for it. Every function name below is **[assumed]** (from the retail game's documentation) until the check lists it on Forever (NFR-4: only names discovered in the live client).

**Q-T4a, discovery (list, no calls):** EmpireIntelCheck 0.1.9-tp1 lists the members of `C_Traits`, `C_TraitConfig` and `C_ClassTalents`, and the values of `Enum.TraitConfigType` and `Enum.TraitSystem` (if present). Only listing, as Q-T3 did for 20 namespaces. This shows which getters exist on Forever.

**Q-T4b, the read (only after Q-T4a's list has been reviewed):** a call chain in which every argument is an id the game itself returned in the same read:

| Step | Call [assumed name] | Argument from |
|---|---|---|
| 1 | config id for the Legacy system (for example `C_Traits.GetConfigIDBySystemID`, or `C_TraitConfig` getters) | a system id or config type the client lists (Q-T4a) |
| 2 | `C_Traits.GetConfigInfo(configID)`: its tree ids | step 1 |
| 3 | `C_Traits.GetTreeCurrencyInfo(configID, treeID)`: points per tree; and `LegacySystem.GetCurrencyInfo(treeID)`, which may make `spentInTree` mean something | steps 1-2 |
| 4 | `C_Traits.GetTreeNodes(treeID)`: node ids | step 2 |
| 5 | `C_Traits.GetNodeInfo(configID, nodeID)`: ranks bought and maximum, entry ids, whether visible | steps 1, 4 |
| 6 | `C_Traits.GetEntryInfo(configID, entryID)`, then `C_Traits.GetDefinitionInfo(definitionID)`: the perk's spell id and name | step 5 |
| 7 | the perk's name and description from its spell id (a spell getter, for example `C_Spell.GetSpellName`) | step 6 |

**The limits (the same as Q-T7 to Q-T9, plus):**
- Getters only: `Get` / `Is` / `Has` names. The denylist adds `Commit`, `Stage`, `Purchase`, `Refund`, `Cascade`, `Rollback`, `Reset`, `Load`, `Save` and `Upgrade` to the existing words.
- Every argument is a number the game returned in the same read; nothing is typed in or saved between sessions.
- Out of combat; `pcall`; secret values skipped; spread over frames; at most 3 trees, 40 nodes per tree and 4 entries per node.
- On command, or at most once per login after the window has loaded (the check's existing rerun rule).
- A call that returns nothing, or errors, is recorded and the chain stops at that step for that id.
- **Taint risk:** a read on the talent frame's data could, in theory, taint the frame if done during its setup. Mitigation: no hooks on the talent or Legacy frames, never read while the frame is opening (one second after its OnShow), and stop on the first `ADDON_ACTION_BLOCKED`.

**What Q-T4 would show:** points per tree; ranks per node (for example 2/5); the perk names and what they do; which nodes can be bought now; perhaps what `spentInTree` means (with a tree argument).

**What it does not need:** any write, spend or "Apply Changes" call; any saved data in EmpireIntel. The check saves its reads in its own SavedVariables, as before.

### 10.2 P3-3 Per-tree detail in EmpireIntel (for a later approval, Q-P3-3, after Q-T4b's runs)

- `/ei legacy trees`: one line per tree ("Adventure: 2 spent; Well Rested 2/5, Thrill of Adventure 0/3, ..."), and one line per node with `/ei legacy trees all`.
- Read on command only, through `Platform/Legacy.lua`, with exactly the getters Q-T4b proved, under the same limits. Nothing saved, unless P3-2 exists and the user approves adding per-tree ranks to it (format 3).
- **Restart or reload:** `/reload`.
- **Gate:** each tree's spent counter and two nodes' ranks match the window, on two characters.
- Its exact design waits for Q-T4b's evidence, which may show that the trees work differently from the retail trait system.

## 11. P3-4 Perk goals in the plan file (for a later approval, Q-P3-4, after P3-3)

**Plan file format 2:** format 1, plus two goal kinds. EmpireIntel reads both version 1 and version 2 files, so no one has to edit their plan.

```lua
EmpireIntelPlan = {
  version = 2,
  goals = {
    { char = 'C1', perk = 'Well Rested', rank = 3 },   -- a perk at a rank, on a character
    { char = 'C1', spent = 16 },                        -- spend points up to a total (the cap)
    { char = 'C1', level = 45 },                        -- every format 1 goal still works
  },
}
```

| Goal kind | Met when | Next step shown |
|---|---|---|
| Perk | that perk's rank (from P3-3's read) >= rank | "Adventure tree: Well Rested 1/5; 2 points available; open the Legacy window and apply 2" |
| Spent | points spent >= spent | "2 of 16 spent; 0 available: earn N more (closest challenges ...)" |

- Perk names are matched without case to the names P3-3 reads; an unknown name is `UNEXPECTED` and the goal is skipped. Until P3-3 exists, perk goals keep the format 1 answer: "not supported yet (needs Q-T4)".
- If step 1 shows the points are account-wide, the `char` key is dropped from both kinds (`{ account = true, perk = ... }`), so the format is fixed only after step 1.
- **EmpireIntel never spends a point:** it only says what to buy; you buy it in the Legacy window.
- The Legacy lock rule applies: before the unlock, both kinds say "Legacy not unlocked yet".
- **Restart or reload:** `/reload` for EmpireIntel; editing Plan.lua: `/reload`.

## 12. Questions for the user

| ID | Question | Recommendation |
|---|---|---|
| Q-P3-2a | Before P3-2: open the Legacy window on C2, type `/ei legacy`, and send the points line (no code), to learn whether available and spent are per character? | Yes, first |
| Q-P3-2 | Approve P3-2 (section 9), including saved-data format 2, in the shape step 1 points to? | After Q-P3-2a |
| Q-P3-2b | P3-2 writes only after a read you started (no login read, no timer)? | Yes |
| Q-T4a | Let EmpireIntelCheck 0.1.9-tp1 list (not call) the members of `C_Traits`, `C_TraitConfig` and `C_ClassTalents`, and the two enums? | Yes, when you want tree detail at all |
| Q-T4b | After reviewing Q-T4a's list: allow the read-only call chain of section 10.1, with game-returned ids only, under those limits? | Decide after Q-T4a |
| Q-P3-3 | P3-3 per-tree detail in EmpireIntel, designed from Q-T4b's evidence? | Later |
| Q-P3-4 | P3-4 perk and spent goals (plan file format 2)? | Later, after P3-3 and Q-P3-2a |
| Q-P3-5 | Retire EmpireIntelCheck (section 4) once Q-T4 is decided, or keep it as the test tool? | Keep it while Q-T4 runs |

