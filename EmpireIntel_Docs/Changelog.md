# EmpireIntel Changelog

Append-only. Newest first.

## 2026-11-08 | S-043 | EmpireIntel 0.5.2: labels after the inn test (/reload; branch p3-1-legacy)
- `/ei rest` label: inn rate checked on Forever; outside rate and 1.5-level cap unverified (D-041). `/ei milestones` label: class and crafting milestones confirmed by the game (EI-E-22); the Legacy points line keeps [estimate] (D-043). Text only. 321 tests pass under Lua 5.1 and 5.3; 3 of 3 label mutants caught.

## 2026-11-08 | S-042 | Inn test passed; P2-3 and P3-1 closed (documentation only)
- P2-3_Report.md section 3 (inn test, EI-E-28) and section 4; P3-1_Report.md sections 2 and 3; D-041 (P2-3 closed, rest label narrowed, not yet built) and D-042 (P3-1 closed). No code changed, nothing merged.

## 2026-11-08 | S-041 | Project_Bible 1.2.0: restart rule follows D-034 (documentation only)
- Project_Bible.md section 5 states the `/reload` rule of D-034; D-040 records the user's approval, and that the paraphrased early rules in CODE_STANDING_ORDERS.md section 7 are accepted. No code changed.

## 2026-11-08 | S-039 | EmpireIntel 0.5.1 (/reload; branch p3-1-legacy)
- P3-1 live test 1 passed on content (P3-1_Report.md). Fixed: `/ei legacy all` is ordered group by group (D1), and the Explorer line no longer repeats its name (D2). 321 tests pass under Lua 5.1 and 5.3.

## 2026-11-08 | S-038 | EmpireIntel 0.5.0, increment P3-1 (/reload; branch p3-1-legacy)
- `/ei legacy` and `/ei legacy all`: earned (from the challenges), available and spent (from the pane), group counts, the closest challenges with what is left, Explorer per character, and level and skill hints from EmpireIntel's records. Read on command, spread over frames, never in combat, nothing saved (D-037, D-038).
- `Platform/Legacy.lua` is the only caller of the 7 achievement getters and `LegacySystem.GetCurrencyInfo()`. 319 tests pass under Lua 5.1 and 5.3; 20 of 21 guard mutants caught (one equivalent).

## 2026-11-08 | S-037 | Run 15; P2-3 views check; Phase 3 approvals (documentation only)
- spentInTree closed as unusable without a tree argument (counter 2 on the open tree, value 0). Exploration areas are per character; challenges and dungeon steps are account-wide (EI-E-27).
- P2-3_Report.md: the views check passed; the rest projection was within 0.5% (supporting, not the formal inn test).
- Q-P3, Q-P3-1 and Q-P3-1a approved: Phase 3, P3-1 only (D-037).

## 2026-11-08 | S-036 | spentInTree inventory; `/ei legacy` plan (documentation only)
- TP1_Report_Run1.md section 21: spentInTree was 0 in all 14 known reads. No file records which tree was open. One single test settles it: a read with the tree page open on a tree whose counter is 1 or more, plus a screenshot.
- Phase3_Legacy_Plan.md 0.1.0: P3-1 `/ei legacy` (live, on command, no saved data), P3-2 saved summary (optional, needs format approval), P3-3 per-tree detail (needs Q-T4; can wait). Questions Q-P3, Q-P3-1, Q-P3-1a. No code. Phase 3 not authorized.

## 2026-11-08 | S-035 | Run 14: the second point was Novice Spelunker (documentation only)
- Excavation Site: Wetlands completed Novice Spelunker, the step the read had shown as missing. TP1_Report_Run1.md section 20. No code changed.

## 2026-11-08 | S-034 | Run 13: unapplied placement test (documentation only)
- GetCurrencyInfo counts applied points only; spent is confirmed (EI-E-26). spentInTree is not an unapplied placement; it stays unexplained and is left out of `/ei legacy`. No code changed.

## 2026-11-08 | S-033 | Run 12: the second earned point (documentation only)
- quantity is confirmed as "available"; spent is consistent with "spent"; maxQuantity and renownCurrency both track earned (EI-E-25). spentInTree stays 0 with the spent tree open, so the selected-tree hypothesis fails. No code changed.

## 2026-11-08 | S-032 | Run 11: spentInTree stays 0 with the pane open (documentation only)
- Four reads with the pane open, all spentInTree 0. The selected-tree hypothesis likely fails (which tree each read was on is not recorded). Next test: an unapplied placement once a point is available. No code changed.

## 2026-11-08 | S-031 | Run 10: the first point spent (documentation only)
- After one spend, quantity went from 1 to 0 and spent from 0 to 1; the other fields were unchanged (EI-E-24). Field meanings are recorded as inferred. Challenge and step data did not change because of the spend (two zone sub-areas were explored in between). spentInTree is analysed, not explained (TP1_Report_Run1.md section 16). Legacy_Rules.md section 4: the `/ei legacy` plan note. No code changed.

## 2026-11-08 | S-030 | Run 9: the Legacy read is complete (documentation only)
- 0.1.8 matches the pane: 65 challenges, 1 of 65 points, Explorer 0 of 46, nothing trimmed, nothing unlinked. The game's dungeon lists confirm the web lists, and the master list has Dire Maul East, North and West (EI-E-23). TP1_Report_Run1.md section 14. No code changed.

## 2026-11-08 | S-029 | EmpireIntelCheck 0.1.8-tp1 (/reload; branch tp1-legacy-read)
- Q-T9 with the user's correction (D-036): counts the 65 challenges by their Legacy reward. Explorer's 46 exploration achievements are saved as its steps, linked through the game's own chain, and shown as "X of 46 done". Criteria are saved compactly. The discovery leftovers are trimmed before any Legacy data.
- The fixture models the Explorer chain, including an area id that equals an achievement id. 283 tests pass under Lua 5.1 and 5.3; 38 of 38 guard mutants caught across the three Legacy sets.

## 2026-11-08 | S-028 | Run 8, all 65 challenges read (documentation only)
- 0.1.7 read 111 achievements: the 65 Legacy challenges (reward "Earn 1 Legacy Point.") and 46 supporting exploration achievements. 1 completed, which matches the pane (EI-E-22). Defects 15 (the size cap dropped the steps) and 16 (wrong totals). The class and crafting rules are confirmed by the game. Q-T9 proposed. No code changed.

## 2026-11-08 | S-027 | EmpireIntelCheck 0.1.7-tp1 (/reload; branch tp1-legacy-read)
- Q-T8 (D-035). Defect 13: reads every category the game lists. "Tier 1 Gear" and "Do Not Display" (and children) are saved but left out of the totals. Defect 14: the points come from `LegacySystem.GetCurrencyInfo()`, all fields as-is, and the trait currency is never sent to `C_CurrencyInfo`. The chat line shows the points earned of those offered.
- The fixture now mirrors run 7. 274 tests pass under Lua 5.1 and 5.3; 11 of 11 new and 13 of 13 earlier guard mutants caught.

## 2026-11-08 | S-026 | Run 7, the first Legacy read (documentation only)
- On Forever, the achievement categories are the 29 Legacy challenge categories (EI-E-20). The points are a trait currency, read by `LegacySystem.GetCurrencyInfo()` (EI-E-21). Check defects 13 and 14 (title matcher; points source). The pane confirms the six crafts and the 65 total. Q-T8 proposed. No code changed.

## 2026-11-08 | S-025 | Restart rule revised (documentation only)
- EI-E-19: `/reload` loads new TOC files on Forever (0.4.0 and 0.1.6 both worked after a reload). D-034: packages that change or add files in an existing addon say `/reload`; a new addon folder still says restart until observed. The repository's 0.4.0 README is corrected; the zip is unchanged.

## 2026-11-08 | S-024 | EmpireIntel 0.4.0, increment P2-3 (FULL CLIENT RESTART; branch p2-3-views)
- New `Core/Rules.lua` and `Core/Views.lua`: `/ei unlock`, `/ei rest` (measured, plus a projected value under the classic rule, labelled estimate), `/ei milestones` (9 classes, 6 crafting skills, estimated Legacy points from both groups).
- `Alts.Collect` shared by `/ei alts` and the views; merge rows gained `xp` and `restAt` (not stored). No saved-data change.
- Tests: `test_ei_views.lua` plus static rules. 244 tests pass under Lua 5.1 and 5.3; all 16 guard mutants caught. D-033.

## 2026-11-08 | S-023 | P2-3 plan for approval (documentation only)
- Phase2_Plan.md 1.3.0 section 6: `/ei unlock`, `/ei rest`, `/ei milestones`; Core/Rules.lua and Core/Views.lua; no format change; full restart (corrected from /reload). Questions Q-P2-3, Q-P2-3a, Q-P2-3b. No code.

## 2026-11-08 | S-022 | P2-2 closed; branch merged
- The user confirmed `/ei alts` matched the game with DataStore on and approved closing P2-2 (D-032). `p2-2-alts` merged into main. No hide-old-characters rule (user).

## 2026-11-07 | S-021 | EmpireIntelCheck 0.1.6-tp1 (FULL CLIENT RESTART; branch tp1-legacy-read)
- Q-T7 approved (D-031). New Part C, `Legacy.lua`: reads the Legacy challenges (achievement category, with criteria) and points (currency) once unlocked. Arguments are allowed only from the game's own answers, to 9 allowed getters. Denylist and crash guard stay. New command `/eicheck legacy`.
- Saves the values of the `LegacySystem` zero-argument calls and its constants. Defect 12 fixed (the size trim erased a run's Legacy call values).
- Legacy_Rules.md: the user's challenge list (65 points), screenshot facts (EI-E-18), web lists marked provisional.
- 238 tests pass under Lua 5.1 and 5.3; 15 of 15 guard mutants caught.

## 2026-11-07 | S-020 | Run 6, the level-25 run (documentation only)
- Legacy unlocked on build 70862. `LegacySystem` Lua table found; the challenges are an achievement category and the points come from currency info (EI-E-16). DataStore last-update time is nil on Forever (EI-E-17). Q-T7 proposed. No code changed.

## 2026-11-06 | S-019 | EmpireIntel 0.3.1 (/reload; branch p2-2-alts)
- Live test 1 of 0.3.0: format 1 unchanged; the DataStore-off path passed. The DataStore-on output is not received yet. P2-2_Report.md.
- D2: `/ei alts` said "rested unknown" for an own record with no rested XP. It now says "rested none reported", as `/ei` does. 212 tests pass under Lua 5.1 and 5.3.

## 2026-11-06 | S-018 | EmpireIntel 0.3.0, increment P2-2 (FULL CLIENT RESTART; branch p2-2-alts)
- New `Bridge/DataStoreBridge.lua`: reads characters from DataStore live, with the 11 approved read-only getters only. Any other name is refused at run time, and every error is caught.
- New `Core/Alts.lua` and `/ei alts`: merges own records with DataStore by GUID. The newer source wins, and each line shows its source and age. Works without DataStore. Faults show as UNEXPECTED lines. Nothing is stored; format 1 is unchanged.
- Fixed before release: one unprintable DataStore key could stop the whole list.
- Tests: `test_ei_alts.lua` covers DataStore good, faulty, erroring, without a character list, without Crafts, and absent, plus the static bridge rules. 211 tests pass under Lua 5.1 and 5.3. All 13 guard mutants are caught. D-030.

## 2026-11-05 | S-017 | P2-1 closed; branch merged; P2-2 detailed for approval
- The user confirmed `/ei` matched the game and approved closing P2-1 (D-029). `p2-1-foundation` merged into main.
- Phase2_Plan.md section 5: P2-2 in detail (DataStore methods, merge rule, `/ei alts` output, gate). Waiting for Q-P2-2. No code.

## 2026-11-05 | S-015 | EmpireIntel 0.2.1 (/reload; branch p2-1-foundation)
- D1 from the live test: "not resting" was never saved (an and/or pattern turned false into nil). Fixed. `/ei` says "resting unknown" when the game gives no answer. 180 tests pass under Lua 5.1 and 5.3. P2-1_Report.md; EI-E-14.

## 2026-11-05 | S-014 | EmpireIntel 0.2.0, increment P2-1 (FULL CLIENT RESTART; branch p2-1-foundation)
- New addon `EmpireIntel/`:
  - Platform, Clock, Events, Scheduler, Unit, SavedVars, Slash, Store and Migrations ported from GoldIntel a21e071, with their changes listed in each header;
  - new Core/Snapshot, Core/Commands, Core/Boot.
- Saved-data format 1 with realm: records on login (+2 s), level-up, profession change, every 5 minutes and at logout, with the logout guard. No P_TICK.
- `/ei`, `/ei version`, `/ei off`, `/ei on`.
- Tests: `test_ei_static.lua`, `test_ei.lua`. 178 tests in total pass under Lua 5.1 and 5.3. Mutation check: every guard is caught except one equivalent case (the commit clears keys that the only migration never removes).
- `tools/build_package.py EmpireIntel` builds the versioned `dist/EmpireIntel_AddOns_v0.2.0.zip`. D-028.

## 2026-11-05 | S-013 | EmpireIntelCheck 0.1.5-tp1 (/reload) and Phase 2 plan
- Blocklist matched as whole CamelCase words plus the stem Reincarnat; C_Reincarnation stays uncalled; defect 11 wording. 99 tests pass under Lua 5.1 and 5.3. D-026.
- Phase 2 authorized for pre-25 features only (D-027). Phase2_Plan.md: increments P2-1..P2-4 and saved-data format 1, waiting for approval of P2-1 (Q-P2-1). No EmpireIntel code yet.

## 2026-11-05 | S-012 | Run 5 undocumented-namespace results (documentation only)
- TP1_Report_Run1.md section 10, EI-E-13: no Legacy data before the unlock by any route tried; C_Seasons inactive; C_Trophy unrelated; C_Reincarnation listed, not called. Defect 11 (retry wording) noted. Questions Q-T5, Q-T6. No code changed.

## 2026-11-05 | S-011 | EmpireIntelCheck 0.1.4-tp1 (/reload)
- Undocumented namespaces listed passively; `/eicheck undoc` calls the planned zero-argument Get/Is/Has names of C_Seasons and C_Trophy once; C_Reincarnation listed for review; service, store and debug groups never called.
- Denylist extended with Request, Claim, Open, Toggle, Show, Reincarnate for every call; crash guard (`inFlight` / `neverCall`) on every call. Defect 10 fixed. 94 tests pass under Lua 5.1 and 5.3. D-025.

## 2026-11-05 | S-010 | Run 4 docs results (documentation only)
- TP1_Report_Run1.md section 9: no Legacy system in the 410 documented systems; 20 undocumented live namespaces (C_Seasons, C_Reincarnation, C_Trophy among them); trait-system lead; defect 10 (enum fields named "Legacy" in docs). EI-E-11, EI-E-12; questions Q-T3, Q-T4. No code changed.

## 2026-11-05 | S-009 | EmpireIntelCheck 0.1.3-tp1 (/reload)
- Defect 9: the saved docs have their own budget and survive the size cap. Legacy systems are kept first with details, reduced if large; other matches keep names only; omissions are listed; the docs are trimmed last; the trim runs after saving them. Argument-count map capped at 600 entries. 86 tests pass under Lua 5.1 and 5.3. D-024.

## 2026-11-05 | S-008 | EmpireIntelCheck 0.1.2-tp1 (/reload) and pre-unlock requirements
- Defect 8: enums count only when their own name points at Legacy (retail enums with a "Legacy" member made run 2 read NAMES ONLY).
- Requirements FR-PRE-1..4 and Architecture section 13: EmpireIntel guides progress before the Legacy unlock. D-022, D-023. Run 2 findings in TP1_Report_Run1.md section 7; EI-E-09, EI-E-10.

## 2026-11-04 | S-007 | EmpireIntelCheck 0.1.1-tp1 (/reload is enough when updating from 0.1.0)
- Fixes 1 to 7 of TP1_Report_Run1.md: Legacy-only verdict with data/UI layers and lock state, visibility-based pane detection without hooks, valid logout baseline, saved-data format 2 with migration, corrected DataStore methods, exact-wording denylist, docs index and field matching.
- Added: T8 read-only BugGrabber error counts; DataStore alt professions in the estimate; docs processing spread across frames.
- Tests: 82 pass under Lua 5.1 and 5.3; new fixtures mirror the launch-build run. D-005 update, D-021.

## 2026-11-04 | S-006 | TP-1 launch-build results (documentation only)
- TP1_Report_Run1.md: Legacy system locked until the first character reaches 25; automatic FOUND verdict was a false positive; 7 check defects listed; DataStore matched live. Evidence EI-E-01..08; risks R-19, R-20; questions Q-T1, Q-T2. No code changed.

## 2026-11-03 | S-005 | Release pipeline design approved with amendments (documentation only)
- Release_Pipeline.md 0.2.0: report task listed as an undelivered dependency (new section 13); rollback restores addon files by default, saved data only with explicit approval; push-only notifications; America/New_York cap day; Stage 1 entry after the launch-results review and authorization; Stage 2 needs Claude's separate identity and the report task. D-018 status, D-020.

## 2026-11-03 | S-004 | Release pipeline design (documentation only)
- Release_Pipeline.md (Proposed, D-018); D-019 executive roles. No workflow, script or config added. EmpireIntelCheck unchanged.

## 2026-11-03 | S-003 | Test Package 1 built: EmpireIntelCheck 0.1.0-tp1 (FULL CLIENT RESTART for first install)
- Architecture 2.1.0: runtime limits 1 to 8 from the user (zero-argument Get/Is/Has calls with denylist, login delay, frame spreading, 256 KB cap, off switch, no GoldIntel interference, separate result codes, provisional verdict with automatic reruns). Decisions D-013 update, D-016, D-017.
- New addon `EmpireIntelCheck/` (Util, Core, PartA, Character, Discover, Run; TOC Interface 16001; README with steps).
- Tests: `Tests/run.lua`, `test_static.lua`, `test_check.lua`, helpers `testlib.lua` (ported) and `fakeclient.lua`; 65 pass under Lua 5.1 and 5.3.
- `tools/build_package.py` builds and verifies `dist/EmpireIntelCheck_AddOns.zip` (dist/ ignored).

## 2026-11-03 | S-002 | Scope corrected to the Forever Legacy system (documentation only, no addon code)
- Requirements_v1.md (new): Legacy points, challenges, perks and cap per character, rested XP, professions, plan-driven "what next", DataStore optional, passive collection.
- Architecture v2.0.0 replaces v1.0.0: Platform/Legacy contract, Estimator fallback (class levels, crafting skill), plan file contract (EmpireIntel_Plan/Plan.lua), Planner; TP-1 = Legacy check with Part A platform checks (kept) and Part B discovery (L-1..L-6, D-1, R-1, P-1, E-1), a verdict line, a restart statement and step-by-step launch-build instructions.
- Decisions D-010..D-015, notes on D-005 and D-007; questions updated (Q-1, Q-2, Q-4, Q-6 resolved; Q-7..Q-9 new).
- Project_Bible 1.1.0: the user's working rules; "pre-modern API" wording so "Legacy" means only the points system.
- Risk_Register R-12..R-18; Compatibility_Notes section 5 (Legacy facts from web summaries, unverified); audit and DataStore review updated.

## 2026-11-03 | S-001 | Repository setup (documentation only, no addon code)
- MIT LICENSE, README, CONTRIBUTING, `.gitignore` (blocks SavedVariables, WTF, evidence, zips), bug-report issue template.
- Governance: Project_Bible, Decisions (D-001..D-009, Q-1..Q-6), TODO, Session_Handoff, Risk_Register (R-01..R-11), Compatibility_Notes (inherited GoldIntel facts), reviews/README.
- GoldIntel_Reuse_Audit.md, Reference_DataStore_Altoholic.md, Architecture.md v1 (Proposed) with Test Package 1 (Legacy API check).
