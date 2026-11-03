# EmpireIntel Session Handoff

Append the newest section at the TOP. The newest section wins.

---

## S-002 | 2026-11-03 | Claude

- **Done:** applied the user's correction: "Legacy" is the Forever Legacy points system (D-010). Wrote Requirements_v1.md. Rewrote Architecture to v2.0.0: Legacy model, Estimator fallback, plan file, Planner, and TP-1 as a passive Legacy check. TP-1 keeps the platform checks T1..T7 and adds discovery of the Legacy API in the live client (no assumed names), rested XP, professions and fallback inputs. Recorded the user's working rules (Bible section 5, D-015).
- **Not done, on purpose:** no addon code; waiting for approval (Q-3).
- **UNEXPECTED / OPEN ISSUES:** (1) The user says the repository is private, but the GitHub API returned `private: false` for shawn571/EmpireIntel on 2026-11-03. (2) The Legacy rules come from search summaries only: Blizzard's article and the fan sites are blocked by the session network policy (Q-9). (3) No third-party addon reviewed reads Legacy data, so there is no known API name to start from. (4) The Forever AddOns folder name at launch is unknown (the beta used `_classic_beta_`).
- **BLOCKERS:** Q-3 approval; Q-7 (automatic getter calls).
- **NEXT RECOMMENDED TASK:** after approval, Phase 1 tasks 1.1 to 1.4; ship TP-1 for a launch-build run (full client restart; steps in Architecture section 9).

## S-001 | 2026-11-03 | Claude

- **Done:** set up the repository with documentation only (Changelog S-001). Audited GoldIntel at a21e071 for reuse; its suite ran 1255 passed / 0 failed under Lua 5.3. Reviewed DataStore 2026.10.14, its 15 modules, AddonFactory and Altoholic Forever 1.60.005 from source. Verdict: they hold up on Forever on paper; license is All Rights Reserved, so run-time use only. Wrote Architecture v1 (Proposed) with Test Package 1, the Legacy API check, as the first deliverable.
- **Not done, on purpose:** no addon code (user instruction: stop for approval before writing addon code). Nothing copied from GoldIntel or DataStore.
- **OPEN ISSUES:** Q-1..Q-6 in Decisions.md. The "goldintel-addon memory" the user referred to was not found (Q-6); governance was taken from GoldIntel's own documents. CurseForge comment threads could not be read (network policy), so user bug reports for Altoholic and DataStore on Forever are unreviewed.
- **BLOCKERS:** user approval of Architecture v1 (Q-3).
- **NEXT RECOMMENDED TASK:** after approval, Phase 1 tasks 1.1 to 1.4 (TP-1 code and offline tests). Then the user runs it on the launch build (Forever launches 2026-11-04).
