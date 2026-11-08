# EmpireIntel TODO

DOC VERSION: 1.2.0  |  UPDATED: 2026-11-03 (session S-003)

```
CURRENT PHASE:            Phase 1: Test Package 1 built (0.1.0-tp1); waiting for the user's launch-build run (task 1.5).
IMPLEMENTATION APPROVED:  Phase 1, the check package only (D-017). Nothing else.
OPEN BLOCKERS:            task 1.5 (live run); Q-9 (web hosts still blocked in this session)
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
- [ ] 1.20 **User:** a read after the next earned point; a read on a second character
- [ ] 1.21 **User:** decide what comes after TP-1 (see the S-030 handoff)
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
- [ ] **User:** P2-3 live test and inn test, then Q-P2-3c
- [ ] P2-4 What next and the plan file (plan format needs approval)

## Later phases: see Architecture.md section 10 (not approved)
