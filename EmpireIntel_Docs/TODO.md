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
- [ ] 1.7 **User:** decide Q-T1 (0.1.1-tp1 fixes, including a check saved-data format change) and Q-T2 (DataStore); then the docs run, and a later run once a character is level 25
- Exit test: Architecture section 9 exit criteria.

## Release pipeline (Release_Pipeline.md): design APPROVED (D-018, D-020); implementation NOT authorized; stage 0
- [x] S-004: design written
- [x] S-005: user approved the design with two amendments (report task undelivered; saved-data restore only with explicit approval) and answered Q-R1..Q-R6
- [ ] **User:** review the first launch results, then decide whether to authorize Stage 1
- Undelivered dependencies: report task (does not exist), installer, Claude's separate GitHub identity (before Stage 2)
- Implementation tasks are listed only after Stage 1 is authorized.

## Phase 2..4: see Architecture.md section 10 (not approved)
