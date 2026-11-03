# EmpireIntel TODO

DOC VERSION: 1.0.0  |  UPDATED: 2026-11-03 (session S-001)

```
CURRENT PHASE:            Phase 0: documentation baseline (complete, awaiting the user's review)
IMPLEMENTATION APPROVED:  NONE. No addon code may be written until the user approves Architecture v1 and authorizes Phase 1 (Q-3).
OPEN BLOCKERS:            Q-1 (scope), Q-2 (publishing ported GoldIntel code), Q-3 (approval), Q-4 (launch-build run)
```

Rules: work only on the current phase. A phase is complete only when its exit test passes. Mark tasks `[x]` with date and session.

## Phase 0: Documentation baseline (S-001, 2026-11-03)

- [x] MIT LICENSE, README, CONTRIBUTING, .gitignore, issue template
- [x] Project_Bible.md, Decisions.md, TODO.md, Session_Handoff.md, Changelog.md, Risk_Register.md, Compatibility_Notes.md, reviews/README.md
- [x] GoldIntel_Reuse_Audit.md (GoldIntel suite run: 1255 / 0 under Lua 5.3)
- [x] Reference_DataStore_Altoholic.md (source review; verdict: holds up on paper)
- [x] Architecture.md v1 with Test Package 1 (Legacy API check)
- [ ] **User:** review and answer Q-1..Q-6 (Decisions.md)
- Exit test: the user approves Architecture v1.

## Phase 1: Test Package 1, Legacy API check (NOT approved)

- [ ] 1.1 Port the GoldIntel test harness (runner, testlib, fake_wow, loader parameterized) and the static rules C-1..C-6
- [ ] 1.2 Fake clients: Forever beta profile; DataStore stub (consistent); DataStore stub (faulty)
- [ ] 1.3 `EmpireIntelCheck` addon: T1..T7 (Architecture section 7)
- [ ] 1.4 Offline tests green under Lua 5.1 and 5.3; package built and verified
- [ ] 1.5 **User:** live run on the launch build; return `EmpireIntelCheck.lua`
- [ ] 1.6 Evidence EI-E-01.. recorded; TP-1 report; user decides D-005
- Exit test: Architecture section 7 exit criteria.

## Phase 2..5: see Architecture.md section 8 (not approved)
