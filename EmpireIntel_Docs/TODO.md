# EmpireIntel TODO

DOC VERSION: 1.1.0  |  UPDATED: 2026-11-03 (session S-002)

```
CURRENT PHASE:            Phase 0: documentation baseline, revised for the Legacy scope (D-010). Awaiting the user's review.
IMPLEMENTATION APPROVED:  NONE. No addon code until the user approves Architecture v2.0.0 and authorizes Phase 1 (Q-3).
OPEN BLOCKERS:            Q-3 (approval), Q-7 (automatic getter calls in TP-1), visibility check for Q-2
```

Rules: work only on the current phase. A phase is complete only when its exit test passes. Mark tasks `[x]` with date and session.

## Phase 0: Documentation baseline

- [x] S-001: LICENSE (MIT), README, CONTRIBUTING, .gitignore, issue template; Bible, Decisions, TODO, Handoff, Changelog, Risks, Compatibility, reviews/; GoldIntel reuse audit; DataStore/Altoholic review
- [x] S-002: Requirements_v1.md (Legacy scope); Architecture v2.0.0 with TP-1 Legacy check; D-010..D-015; Bible working rules; wording "pre-modern API" vs "Legacy"
- [ ] **User:** answer Q-3, Q-7 (Q-8, Q-9 optional); confirm the repository shows as private
- Exit test: the user approves Architecture v2.0.0.

## Phase 1: Test Package 1, the Legacy check (NOT approved)

- [ ] 1.1 Port the GoldIntel test harness (runner, testlib, fake_wow, loader parameterized) and static rules C-1..C-6
- [ ] 1.2 Fake clients: beta profile without Legacy; fake Legacy namespace; failing or secret getters; faulty DataStore
- [ ] 1.3 `EmpireIntelCheck`: Part A T1..T7, Part B L-1..L-6, D-1, R-1, P-1, E-1, verdict line
- [ ] 1.4 Offline tests green under Lua 5.1 and 5.3; package built and verified; README with the restart statement and the steps of Architecture section 9
- [ ] 1.5 **User:** launch-build run (full client restart), two characters, Legacy pane opened, SavedVariables and a pane screenshot returned
- [ ] 1.6 Evidence EI-E-01..; TP-1 report with the verdict and every unexpected condition; user decides D-012, D-005
- Exit test: Architecture section 9 exit criteria.

## Phase 2..4: see Architecture.md section 10 (not approved)
