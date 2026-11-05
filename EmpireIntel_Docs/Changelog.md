# EmpireIntel Changelog

Append-only. Newest first.

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
