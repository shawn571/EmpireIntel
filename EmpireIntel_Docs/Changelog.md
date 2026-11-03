# EmpireIntel Changelog

Append-only. Newest first.

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
