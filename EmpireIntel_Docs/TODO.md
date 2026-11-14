# EmpireIntel TODO

DOC VERSION: 1.5.0  |  UPDATED: 2026-11-09 (session S-063)

```
CURRENT PHASE:            Phase 2, increment P2-4b: live gate partly passed (D-063); retest 0.7.2: 2 and 3 failed (D-066); 0.7.3 on p2-4b-window, not merged.
IMPLEMENTATION APPROVED:  P2-4b (D-061), its fixes 1-9 (D-063) and finding 10 (D-065). P2-4c, then P2-4d: approved (D-065), start only after the one before closes.
OPEN BLOCKERS:            the user's retest on 0.7.3 (gate steps 2, 3, 8); merge approval; closing P2-4b; Q-D068-1, Q-D068-2
```

Rules: work only on the current phase. A phase is complete only when its exit test passes. Mark tasks `[x]` with date and session.

## Phase 0: Documentation baseline

- [x] S-001: LICENSE (MIT), README, CONTRIBUTING, .gitignore, issue template; Bible, Decisions, TODO, Handoff, Changelog, Risks, Compatibility, reviews/; GoldIntel reuse audit; DataStore/Altoholic review
- [x] S-002: Requirements_v1.md (Legacy scope); Architecture v2.0.0 with TP-1 Legacy check; D-010..D-015; Bible working rules; wording "pre-modern API" vs "Legacy"
- [x] S-003: user approved Q-3 (check package only) and Q-7 with limits; Architecture 2.1.0 runtime limits 1 to 8 (D-013 update, D-016, D-017)
- Exit test: PASSED (approval 2026-11-03).

## Phase 1: Test Package 1, the Legacy check (APPROVED for the check package only, D-017)

- [x] 1.1 Test harness: testlib ported from GoldIntel a21e071; own runner and fake client; static rules C-1..C-6 plus a bytecode global check (S-003)
- [x] 1.2 Fake clients: beta profile without Legacy; fake Legacy namespace with every result case; docs; good and faulty DataStore (S-003)
- [x] 1.3 `EmpireIntelCheck` 0.1.0-tp1: Part A T1..T7, Part B L-1..L-6, D-1, R-1, P-1, E-1, verdict and provisional rule, runtime limits 1 to 8 (S-003)
- [x] 1.4 65 tests green under Lua 5.1 and 5.3; 13 guard mutants all caught; `tools/build_package.py` builds and verifies `dist/EmpireIntelCheck_AddOns.zip`; package README with the restart statement and steps (S-003)
- [x] 1.5 Launch-build run received 2026-11-04 (one character played; the pane could not be opened: the system is locked until level 25)
- [x] 1.6 TP1_Report_Run1.md and EI-E-01..08 (S-006)
- [x] 1.7 User approved Q-T1 and Q-T2 (2026-11-04)
- [x] 1.8 EmpireIntelCheck 0.1.1-tp1 built: 82 tests pass under Lua 5.1 and 5.3; 21 guard mutants caught; run 1 re-classified correctly (S-007)
- [x] 1.9 0.1.1 run received 2026-11-05 (migration fine, no own errors; docs not run; defect 8)
- [x] 1.9a 0.1.2-tp1 built (defect 8), FR-PRE-1..4 recorded (S-008)
- [x] 1.9b 0.1.2 docs run: 14 of 410 systems matched, but the saved docs were dropped by the size cap (defect 9)
- [x] 1.9c 0.1.3-tp1 built (defect 9; 86 tests pass) (S-009)
- [x] 1.9d 0.1.3 docs run: 410 systems, no Legacy system; 20 undocumented namespaces; trait-system lead; defect 10 (S-010)
- [x] 1.9e User approved Q-T3 with limits; Q-T4 deferred (2026-11-05)
- [x] 1.9f 0.1.4-tp1 built: undocumented namespaces, /eicheck undoc, crash guard, defect 10 (94 tests pass) (S-011)
- [x] 1.9g 0.1.4 run: C_Seasons no active season; C_Trophy unrelated; C_Reincarnation list shown to the user (S-012)
- [x] 1.9h Q-T5 and Q-T6 decided (2026-11-05); 0.1.5-tp1 built (whole-word blocklist, Reincarnat stem, defect 11) (S-013)
- [x] 1.10 Level-25 run received 2026-11-07 (pane opened; build 70862); TP1_Report_Run1.md section 11 (S-020)
- [x] 1.11 Q-T7 approved; screenshots received (1 point; Legacy_Rules.md) (2026-11-07)
- [x] 1.12 EmpireIntelCheck 0.1.6-tp1 built: Part C Legacy read, defect 12 (S-021)
- [x] 1.13 0.1.6 run received (run 7): categories and points found; defects 13, 14 (S-026)
- [x] 1.14 Q-T8 approved; EmpireIntelCheck 0.1.7-tp1 built (S-027, D-035)
- [x] 1.15 0.1.7 run received (run 8): 65 challenges and 46 exploration achievements; defects 15, 16 (S-028)
- [x] 1.16 Q-T9 approved with correction; EmpireIntelCheck 0.1.8-tp1 built (S-029, D-036)
- [x] 1.17 0.1.8 run (run 9): matches the pane; all 46 Explorer steps linked; nothing trimmed (S-030)
- [x] 1.18 Run 10 after the first spend recorded (S-031)
- [x] 1.19 Selected-tree test run (run 11): spentInTree 0 in all reads; which tree each read was on is not recorded (S-032)
- [x] 1.19a Unapplied placement test (run 13): not counted until applied; spentInTree still 0 (S-034)
- [x] 1.20 Second earned point (run 12) and a second character (run 15) read (S-037)
- [x] 1.21 Phase 3 authorized for P3-1 (D-037)

## Phase 3: Legacy in EmpireIntel (AUTHORIZED for P3-1 only, D-037; Phase3_Legacy_Plan.md)
- [x] P3-1 built: EmpireIntel 0.5.0 on branch `p3-1-legacy` (S-038, D-038)
- [x] P3-1 live gate passed; 0.5.1 checked; **closed** (D-042)
- [ ] P3-2 saved summary: locked (needs approval and a format change)
- [ ] P3-3 per-tree detail: locked (needs Q-T4)
- Exit test: Architecture section 9 exit criteria.

## Release pipeline (Release_Pipeline.md): design APPROVED (D-018, D-020); implementation NOT authorized; stage 0
- [x] S-004: design written
- [x] S-005: user approved the design with two amendments (report task undelivered; saved-data restore only with explicit approval) and answered Q-R1..Q-R6
- [ ] **User:** review the first launch results, then decide whether to authorize Stage 1
- Undelivered dependencies: report task (does not exist), installer, Claude's separate GitHub identity (before Stage 2)
- Implementation tasks are listed only after Stage 1 is authorized.

## Phase 2: pre-25 features (AUTHORIZED, D-027; one approval per increment; Phase2_Plan.md)
- [x] Q-P2-1 approved with realm field and no P_TICK (D-028)
- [x] P2-1 Foundation and own snapshot: EmpireIntel 0.2.1, closed by the user 2026-11-05 (D-029)
- [x] Q-P2-2 approved 2026-11-06
- [x] P2-2 built: EmpireIntel 0.3.0 on branch `p2-2-alts` (full client restart), 211 tests pass (S-018, D-030)
- [x] P2-2 live test 1 (0.3.0): DataStore off passed, format 1 unchanged; D2 fixed in 0.3.1 (S-019)
- [x] P2-2 live test 2 passed (DataStore on); P2-2 closed by the user 2026-11-08 (D-032)
- [x] P2-3 plan written: Phase2_Plan.md section 6 (S-023)
- [x] Q-P2-3, Q-P2-3a, Q-P2-3b approved 2026-11-08
- [x] P2-3 built: EmpireIntel 0.4.0 on branch `p2-3-views`, 244 tests, 16/16 mutants (S-024, D-033)
- [x] P2-3 live test and inn test passed; **closed** (D-041)
- [x] Rest and milestones labels built as EmpireIntel 0.5.2 (D-041, D-043)
- [x] 0.5.2 live check passed (D-044)
- [x] Merge 1 `p2-3-views` into main: merged (634bd63, D-046)
- [x] Merge 2 `tp1-legacy-read`: merged (e8a30b3, D-047)
- [x] Merge 3 `p3-1-legacy`: merged (c5434a7, D-048). Main matches the installed versions
- [x] Docs pull request (`docs-after-merges`): merged as #4 (5091f39)
- [x] Merge standing order and docs-only standing approval recorded (D-049); REST merge command (D-050); #5 merged
- [x] `.claude/settings.json` (REST merge permission, D-050): merged by the user as #6 (5377093)
- [x] Handoff S-050 merged as #7 (b681e42) under the docs-only standing approval
- [x] Docs-only standing approval extended to TODO.md and Changelog.md (D-051)
- [x] P2-4 plan written: Phase2_Plan.md section 7 (S-052); no code
- [x] Q-P2-4, a-e approved with the Legacy lock rule (D-052)
- [ ] P2-4 build: EmpireIntel 0.6.0 plus EmpireIntel_Plan 1
- [x] Post-25 plan written (Phase3_Legacy_Plan.md sections 7-12, #10)
- [x] P2-4 redirected (D-054): #11 kept, not merged
- [x] Revised P2-4 plan written: Phase2_Plan.md section 8 (route planner and plan window)
- [x] Q-P2-4r, a, b (after Q-G1), Q-G1, Q-G2, Q-F1-F5 answered (D-055); 8.5 rested fix; window design direction
- [x] P2-4a and 0.1.9-tp1 approved; Q-F3 answered: Explorer after 50, counting zones already explored (D-056)
- [x] P2-4a built: EmpireIntel 0.6.0 (format 2) and EmpireIntelCheck 0.1.9-tp1 on branch `p2-4a-planner`; 408 tests, 20/20 mutants (S-058, D-057)
- [x] Live tests of 0.6.0 and 0.1.9-tp1 received; findings answered; #14 merged (70da547, D-058, D-059)
- [x] Static mockup of the window (both modes, Up Next card, parts) published for approval (S-060)
- [x] Mockup approved; P2-4a **closed** (D-060)
- [x] P2-4b build plan written: Phase2_Plan.md section 9 (S-061)
- [x] Q-P2-4b-1..4 approved with the fill path (D-061); #16 merged (9cb1d10)
- [x] P2-4b built: EmpireIntel 0.7.0 on branch `p2-4b-window`; 485 tests, 21/21 mutants (S-062, D-062)
- [x] Live gate on 0.7.0: steps 1, 4, 5, 7 passed; findings 1-11 (D-063, 2026-11-09)
- [x] 0.7.1 built for the retest (items 1-9): 514 tests, 22/22 mutants (S-063, D-064)
- [x] P2-4c and P2-4d planned: Phase2_Plan.md section 10 (S-063)
- [x] Finding 10 and repeated steps fixed: 0.7.2, 519 tests (S-064, D-065)
- [x] Q-P2-4c and Q-P2-4d answered (D-065): approved with conditions; L-17 stays unverified
- [x] Retest on 0.7.2: step 6 passed; 2 and 3 failed (D-066)
- [x] 0.7.3 built: chains, selection card, notes on hover, emblem size; 526 tests, 15/15 mutants (S-065, D-067)
- [x] Items 5-7 planned: Phase2_Plan.md section 11 (S-065)
- [ ] **User:** retest gate steps 2, 3, 8 on 0.7.3; merge approval for #17; close P2-4b
- [x] Section 11.4 answered; plan inputs and standing order D-068 recorded (S-066, D-068, D-069)
- [ ] **User:** Q-D068-1 (drop the Questie read?), Q-D068-2 (pfQuest's data license)
- [ ] EmpireIntelCheck 0.1.10-tp1 (short quest check, file under 128 KB): with P2-4e, not before
- [ ] P2-4c (profession choices, setup wizard), only after P2-4b closes
- [ ] P2-4d (rested XP in the route), only after P2-4c closes
- [ ] **User (any time):** the rested-kill check for L-17 (README 0.6.0 step 8); the 105% test for L-19 once the alts are set up (Phase2_Plan.md 10.3)
- [ ] Next check version (setter labels "ok, no return value", SetColorTexture read-back, full UI result per character): not built yet (D-059)
- [ ] P2-4 old build line above (0.6.0 plus EmpireIntel_Plan 1): superseded by D-054; #11 stays unmerged, reference only
- [ ] When #10 is next edited: P3-2 becomes saved-data format 3 (D-055, D-056); Q-P3-2a later

## Later phases: see Architecture.md section 10 (not approved)
