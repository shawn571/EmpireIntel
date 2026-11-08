# EmpireIntel Session Handoff

Append the newest section at the TOP. The newest section wins.

---

## S-041 | 2026-11-08 | Claude

**Phase and increment:** unchanged from S-040: P3-1 built as EmpireIntel 0.5.1, waiting for the `/ei legacy all` look, then Q-P3-1c; P2-3 built as 0.4.0, waiting for the formal inn test, then Q-P2-3c.

**Done (docs only):** new session verified the repository against S-040: branch heads, TOC versions (EmpireIntel 0.5.1, EmpireIntelCheck 0.1.8-tp1 on `p3-1-legacy`; 0.3.1 and 0.1.5-tp1 on main), main at S-022 docs, repository private, no pull requests, 321 tests pass under Lua 5.1 and 5.3. No conflict found other than the one below, now settled. D-040: Project_Bible.md section 5 follows D-034 (v1.2.0); paraphrased early rules in CODE_STANDING_ORDERS.md section 7 accepted.

**Approved:** as S-040, plus D-040.

**Pending (the user decides):** Q-P3-1c, Q-P2-3c, Q-T4, P3-2 and P3-3 (locked), Stage 1 (not authorized), merges (none without approval; order `p2-3-views`, `tp1-legacy-read`, `p3-1-legacy`).

**Branches:** as S-040, except `p3-1-legacy` head is this push. No pull requests.

**Installed (as the user has said):** EmpireIntel 0.5.0 (0.5.1 delivered, not yet confirmed); EmpireIntelCheck 0.1.8-tp1.

**Open questions:** Q-P3-1c, Q-P2-3c, Q-T4. No open doc conflict.

**User's next step:** as S-040: install 0.5.1 with `/reload`, type `/ei legacy all`, say whether it reads well (Q-P3-1c); run the formal inn test, then decide Q-P2-3c.

## S-040 | 2026-11-08 | Claude

**Phase and increment:** Phase 3, increment P3-1 (`/ei legacy`), built as EmpireIntel 0.5.1; waiting for the user's look at `/ei legacy all`, then Q-P3-1c. Phase 2 increment P2-3 (views) built as 0.4.0; views check passed; formal inn test pending, then Q-P2-3c. TP-1 (EmpireIntelCheck) at 0.1.8-tp1, the Legacy read proven (runs 6-15).

**Approved:**
- Phase 2 (pre-25 features; D-027): P2-1 closed (D-029), P2-2 closed (D-032), P2-3 built (D-033).
- Phase 3, P3-1 only (D-037), with no saved crash guard (Q-P3-1a).
- Q-T7, Q-T8 and Q-T9 (check Legacy reads).
- The standing orders (D-039).

**Pending (the user decides):**
- Q-P3-1c: close P3-1, after a look at 0.5.1.
- Q-P2-3c: close P2-3, after the formal inn test.
- Q-T4: trait-system reads, after P3-1 passes its live gate.
- P3-2 and P3-3: locked.
- Release pipeline Stage 1: not authorized.
- Merges: none without approval. The order is `p2-3-views`, then `tp1-legacy-read`, then `p3-1-legacy`.

**Branches** (no pull requests exist):

| Branch | Head | Holds | Matches main? |
|---|---|---|---|
| main | 83b3574 | EmpireIntel 0.3.1, EmpireIntelCheck 0.1.5-tp1, docs to S-022 | is main |
| p2-1-foundation | ca0d2b6 | merged earlier (P2-1) | contained in main |
| p2-2-alts | 83b3574 | P2-2 | identical to main |
| p2-3-views | 257c2bb | EmpireIntel 0.4.0 (P2-3) | no: ahead of main, unmerged |
| tp1-legacy-read | 1544eb5 | p2-3-views plus EmpireIntelCheck 0.1.6-0.1.8 and docs | no: ahead, unmerged |
| p3-1-legacy | this push | tp1-legacy-read plus EmpireIntel 0.5.0-0.5.1 and the newest docs | no: ahead, unmerged |

**Installed (as the user has said):**
- EmpireIntel 0.5.0 (0.5.1 delivered; installation not yet confirmed).
- EmpireIntelCheck 0.1.8-tp1.
- GoldIntel and DataStore/Altoholic also installed.
- The user will delete the stale beta Shaman in Altoholic.

**Open questions:** Q-P3-1c, Q-P2-3c, Q-T4. Conflict to confirm: Project_Bible.md section 5 restart rule vs D-034 (see D-039).

**User's next step:**
1. Install 0.5.1 with `/reload`, open the Legacy window, type `/ei legacy all`, and say whether it reads well (Q-P3-1c).
2. Run the formal inn test from the P2-3 README, then decide Q-P2-3c.

## S-039 | 2026-11-08 | Claude

- **Done:** P3-1 live test 1 recorded; 0.5.1 fixes the `/ei legacy all` order and the Explorer wording.
- **WAITING FOR:** a look at `/ei legacy all` on 0.5.1, then Q-P3-1c; the formal inn test, then Q-P2-3c.

## S-038 | 2026-11-08 | Claude

- **Done:** built P3-1 as EmpireIntel 0.5.0 on branch `p3-1-legacy` (D-038). `dist/EmpireIntel_AddOns_v0.5.0.zip`.
- **Branch stack:** `p3-1-legacy` is built on `tp1-legacy-read`, which is built on `p2-3-views`. Nothing is merged; merge order on approval: P2-3, then TP-1, then P3-1.
- **WAITING FOR:** the P3-1 live gate, then Q-P3-1c; the formal inn test, then Q-P2-3c.

## S-037 | 2026-11-08 | Claude

- **Done:** run 15 recorded (TP1_Report_Run1.md section 22, EI-E-27); P2-3_Report.md; D-037 (Phase 3, P3-1 only).
- **NEXT:** build P3-1 as 0.5.0 on branch `p3-1-legacy`.
- **WAITING FOR:** the formal inn test, then Q-P2-3c.

## S-036 | 2026-11-08 | Claude

- **Done:** spentInTree inventory (TP1_Report_Run1.md section 21); `/ei legacy` plan (Phase3_Legacy_Plan.md). No code.
- **WAITING FOR:** Q-P3, Q-P3-1, Q-P3-1a; the P2-3 views check and the inn test, then Q-P2-3c; optionally the spentInTree screenshot test.

## S-035 | 2026-11-08 | Claude

- **Done:** run 14 recorded: the second point came from Novice Spelunker (Excavation Site: Wetlands).
- **Open for the user:** spentInTree (leave out, or Q-T4); whether to plan `/ei legacy` (Phase 3, not authorized); P2-3 confirmation and the inn test, then Q-P2-3c.

## S-034 | 2026-11-08 | Claude

- **Done:** recorded run 13 (TP1_Report_Run1.md section 19, EI-E-26). Available, spent and earned are settled; spentInTree is unexplained.
- **Open for the user:** keep spentInTree out (recommended), or approve Q-T4 to read the trees; the file showing which challenge gave point 2; P2-3 confirmation and the inn test.

## S-033 | 2026-11-08 | Claude

- **Done:** recorded run 12 (TP1_Report_Run1.md section 18, EI-E-25).
- **WAITING FOR:** the staging test now that a point is available (place without Apply, read, Apply, read); the file, to see which challenge gave the second point.

## S-032 | 2026-11-08 | Claude

- **Done:** recorded run 11 (TP1_Report_Run1.md section 17). spentInTree stays 0 with the pane open.
- **WAITING FOR:** which tree each read was on; which tree and perk hold the spent point; the staging test at the next available point; P2-3 confirmation and the inn test.

## S-031 | 2026-11-08 | Claude

- **Done:** recorded run 10 (TP1_Report_Run1.md sections 15 and 16, EI-E-24, Legacy_Rules.md section 4). No code changed; 0.1.8-tp1 stays current.
- **WAITING FOR:**
  - which tree and perk the point went into;
  - the selected-tree test for spentInTree;
  - the next earned point;
  - a read on a second character;
  - P2-3 confirmation and the inn test, then Q-P2-3c.

## S-030 | 2026-11-08 | Claude

- **Done:** read run 9 (TP1_Report_Run1.md section 14, EI-E-23). The check reads the challenges, steps and points correctly.
- **Open for the user:**
  - the P2-3 confirmation and the inn test, then Q-P2-3c;
  - the next step for Legacy data in EmpireIntel itself: Phase 3 is not authorized, and Phase 2 uses no Legacy API (D-027);
  - Q-T4 (trees) is still unapproved.

## S-029 | 2026-11-08 | Claude

- **Done:** built EmpireIntelCheck 0.1.8-tp1 (Q-T9, D-036). 283 tests; 38/38 mutants. `dist/EmpireIntelCheck_AddOns_v0.1.8-tp1.zip` (sha256 below in the package block).
- **WAITING FOR:** the 0.1.8 file and line; the user's check of the Explorer grouping in the pane; the P2-3 live and inn tests, then Q-P2-3c.

## S-028 | 2026-11-08 | Claude

- **Done:** read run 8 (TP1_Report_Run1.md section 13, EI-E-22, Legacy_Rules.md 1b). Proposed Q-T9 (0.1.8). No code changed.
- **WAITING FOR:** Q-T9; the P2-3 live and inn tests, then Q-P2-3c.

## S-027 | 2026-11-08 | Claude

- **Done:** built EmpireIntelCheck 0.1.7-tp1 (Q-T8, D-035) on `tp1-legacy-read`. 274 tests; all mutants caught. `dist/EmpireIntelCheck_AddOns_v0.1.7-tp1.zip` (sha256 c71ba1b5...).
- **WAITING FOR:** the 0.1.7 file and the Legacy read line; the P2-3 live and inn tests, then Q-P2-3c.

## S-026 | 2026-11-08 | Claude

- **Done:** read run 7 (TP1_Report_Run1.md section 12, EI-E-20/21, Legacy_Rules.md 1a). Proposed Q-T8 (0.1.7 fixes defects 13 and 14). No code changed.
- **WAITING FOR:** Q-T8; the P2-3 live and inn tests, then Q-P2-3c.

## S-024 | 2026-11-08 | Claude

- **Done:** built P2-3 as EmpireIntel 0.4.0 on branch `p2-3-views` (D-033). 244 tests pass under 5.1 and 5.3; 16 of 16 mutants caught. `dist/EmpireIntel_AddOns_v0.4.0.zip` (sha256 9ae2ac1b...).
- **WAITING FOR:** the P2-3 live test and the inn test, then Q-P2-3c. Also the EmpireIntelCheck 0.1.6 file and the user's Legacy Points line (sent as before: the file attached in chat, the line pasted).

## S-023 | 2026-11-08 | Claude

- **Done:** P2-3 plan, Phase2_Plan.md section 6, on branch `p2-3-views`. No code.
- **WAITING FOR:** Q-P2-3 (with a and b); the EmpireIntelCheck 0.1.6 run with the pane open, plus the user's Legacy Points line.

## S-022 | 2026-11-08 | Claude

- **Done:** P2-2 closed (D-032); `p2-2-alts` merged into main (fast-forward).
- **NEXT:** the P2-3 plan for approval (no code). **WAITING FOR:** the EmpireIntelCheck 0.1.6 run with the pane open, plus the user's Legacy Points line.

## S-021 | 2026-11-07 | Claude

- **Done:** Q-T7 approved; built EmpireIntelCheck 0.1.6-tp1 on branch `tp1-legacy-read` (stacked on `p2-2-alts`). Legacy_Rules.md written. 238 tests; 15/15 mutants. `dist/EmpireIntelCheck_AddOns_v0.1.6-tp1.zip`.
- **WAITING FOR:** the 0.1.6 run (full restart, pane opened, `/eicheck legacy`, file); the `/ei alts` lines on 0.3.1, then Q-P2-2c.
- **Open:** tree node names need the trait system (Q-T4) or tooltips; not part of Q-T7.

## S-020 | 2026-11-07 | Claude

- **Done:** read run 6 (the level-25 run, build 70862) and the EmpireIntel file as data. TP1_Report_Run1.md section 11; EI-E-15..17; Q-T7 proposed (achievement and currency getters). P2-2_Report.md section 4. No code changed.
- **WAITING FOR:** Q-T7; the Legacy point number from the pane plus a screenshot; `/ei alts` lines on 0.3.1 with DataStore on, then Q-P2-2c.

## S-019 | 2026-11-06 | Claude

- **Done:** read the 0.3.0 file and chat as data (P2-2_Report.md). The DataStore-off gate passed; format 1 is unchanged. D2 wording fixed in 0.3.1 (`/reload`).
- **WAITING FOR:** `/ei alts` with DataStore on, on 0.3.1, and the user's confirmation that it matches; then Q-P2-2c. Remind: install EmpireIntelCheck 0.1.5 before the level-25 run.

## S-018 | 2026-11-06 | Claude

- **Done:** Q-P2-2 approved. Built P2-2 as EmpireIntel 0.3.0 on branch `p2-2-alts` (D-030). 211 tests pass under 5.1 and 5.3; 13 of 13 guard mutants caught. Package `dist/EmpireIntel_AddOns_v0.3.0.zip` built and verified.
- **Not done, on purpose:** not merged to main; P2-2 not closed (Q-P2-2c). P2-3 not started.
- **WAITING FOR:** the P2-2 live test (full restart; `/ei alts` with DataStore on and off; saved file), then Q-P2-2c. Later: the level-25 run and Q-T4.

## S-017 | 2026-11-05 | Claude

- **Done:** P2-1 closed (D-029); branch merged into main (fast-forward). P2-2 written out in Phase2_Plan.md section 5.
- **WAITING FOR:** Q-P2-2. Later: the level-25 run and Q-T4.

## S-016 | 2026-11-05 | Claude

- **Done:** read the 0.2.1 file. D1 fix confirmed (true and false both stored); level, XP, profession and rested changes recorded correctly; the logout guard fired for both characters. P2-1_Report.md section 2.
- **WAITING FOR:** the user's confirmation that `/ei` matched the game, then Q-P2-1c.

## S-015 | 2026-11-05 | Claude

- **Done:** read the user's P2-1 file as data. Two records correct; meta exact; logout guard fired once as designed. Defect D1 (resting false lost) fixed in 0.2.1, `/reload` only, on branch `p2-1-foundation`.
- **WAITING FOR:** the 0.2.1 file, the user's confirmation that `/ei` matched the game, and Q-P2-1c.

## S-014 | 2026-11-05 | Claude

- **Done:** built P2-1 on branch `p2-1-foundation` (D-028): EmpireIntel 0.2.0, ported Platform and Store layers, own snapshot (format 1 with realm, no P_TICK), `/ei` commands. 178 tests pass under 5.1 and 5.3. Package `dist/EmpireIntel_AddOns_v0.2.0.zip` built and verified.
- **Not done, on purpose:** not merged to main; P2-1 is not closed (separate user approval). P2-2 not started.
- **WAITING FOR:** the user's live test (two characters, `/ei` against the game) and the saved file `EmpireIntel.lua`.

## S-013 | 2026-11-05 | Claude

- **Done:** Q-T5 (C_Reincarnation uncalled; whole-word blocklist with the Reincarnat stem) built as 0.1.5-tp1, with 99 tests passing and the mutation check holding. Phase 2 authorized for the pre-25 features only (D-027). Wrote Phase2_Plan.md: four increments and saved-data format 1.
- **Not authorized:** Stage 1; Q-T4 (after the level-25 run).
- **WAITING FOR:** Q-P2-1 (approve P2-1 including format 1); later the level-25 run.
- **NEXT RECOMMENDED TASK:** on approval, build P2-1: port Platform, Core and Store from GoldIntel a21e071 read-only, own snapshot, `/ei`. Full client restart.

## S-012 | 2026-11-05 | Claude

- **Done:** read run 5. `/eicheck undoc` called only `C_Seasons` (0, false); `C_Trophy` had no allowed names; `C_Reincarnation`'s 4 functions shown to the user, none called. Crash guard clean.
- **Conclusion:** before level 25, no Legacy data is reachable. TP-1 discovery is done until the unlock run.
- **OPEN:** Q-T5 (Reincarnation, recommend leave uncalled), Q-T6 (authorize Phase 2 and/or Stage 1), Q-T4 after level 25. Defect 11 is wording only, so it waits for the next build.

## S-011 | 2026-11-05 | Claude

- **Done:** Q-T3 approved with the user's limits (D-025). Built 0.1.4-tp1. 94 tests pass under 5.1 and 5.3. Each new guard, when disabled, fails the suite.
- **Told the user plainly:** an addon cannot write anything that survives a hard client crash, so the calls start only on the user's command and the marker covers disconnects, reloads and errors.
- **WAITING FOR:** the 0.1.4 file after `/eicheck undoc`. Then show the user C_Reincarnation's function list before anything is called there.

## S-010 | 2026-11-05 | Claude

- **Done:** read run 4 (0.1.3) as data. The docs survived (all 410 systems indexed, 14 matched). No Legacy system is documented; the 3 "Legacy" matches are retail enum fields (defect 10, not yet fixed). Comparing live namespaces with the docs found 20 undocumented ones (C_Seasons, C_Reincarnation, C_Trophy look Forever-related). Trait-system lead from the "Legacy" talent-frame tab and the CamelotCombat config type.
- **Not done, on purpose:** no code. Both next steps widen what the check calls (Q-T3, Q-T4).
- **NEXT RECOMMENDED TASK:** if Q-T3 is approved, build 0.1.4 (defect 10 + undocumented-namespace listing and guarded zero-argument calls for the three namespaces), `/reload` only.

## S-009 | 2026-11-05 | Claude

- **Done:** run 3 showed the docs run worked (14 of 410 systems matched) but the saved docs were dropped by the size cap. Built 0.1.3-tp1 with a docs budget and a docs-last trim order (D-024). 86 tests pass under 5.1 and 5.3. Mutation check: the guards are caught except "no save-time budget", which the trim covers anyway (near-equivalent).
- **WAITING FOR:** a 0.1.3 run with `/eicheck docs`. The user offered to paste text where it saves an upload. The docs need the file; the `/eicheck report` copy window was offered and not taken up.
- **NEXT RECOMMENDED TASK:** read the docs systems and look for the Legacy data API.

## S-008 | 2026-11-05 | Claude

- **Done:** read run 2 as data. Migration fine; no errors from EmpireIntelCheck or GoldIntel (T8); defect 8 found and fixed in 0.1.2-tp1 (82 tests pass under 5.1 and 5.3; run 2 re-classified as PANE ONLY). Recorded the user's scope point as FR-PRE-1..4 (D-022): EmpireIntel must guide progress before the Legacy unlock.
- **WAITING FOR:** the 0.1.2 run with `/eicheck docs` (not run so far).
- **NEXT RECOMMENDED TASK:** read the docs results; then the user decides D-012 and whether to authorize Stage 1 and Phase 2.

## S-007 | 2026-11-04 | Claude

- **Done:** the user approved Q-T1 and Q-T2. Built EmpireIntelCheck 0.1.1-tp1 (D-021): 82 tests pass under Lua 5.1 and 5.3; 21 guard mutants all caught; the user's run 1 re-classified offline reads PANE ONLY, provisional (locked). Package rebuilt and delivered.
- **UNEXPECTED / OPEN ISSUES:** the user was not sure whether errors appeared in game; T8 now reads BugSack's own error list, so the next file answers it. The pipeline stays at Stage 0.
- **WAITING FOR:** the user's 0.1.1 run with `/eicheck docs`; later a run after a character reaches level 25.
- **NEXT RECOMMENDED TASK:** read the docs results and look for the Legacy data API (look first at C_Traits and the CamelotCombat config type); report; then the Stage 1 and D-012 decisions.

## S-006 | 2026-11-04 | Claude

- **Done:** read the user's launch-build file as data (loaded with no globals and a time limit, outside the repo) and wrote TP1_Report_Run1.md with aliases only. Evidence EI-E-01..08.
- **Key facts:** the Legacy system is locked until the account's first character reaches level 25; no Legacy data API by name; the client text confirms the three trees, a points counter and a seasonal cap; docs are installed; DataStore matched live values.
- **UNEXPECTED:** the check reported FOUND on retail raid-difficulty getters (false positive); a hidden guild frame counted as "pane seen"; logout values were wrong; 6 of 8 runs were dropped by the size cap.
- **Not done, on purpose:** no code change. Fix 4 changes the check's saved-data format and needs approval (Q-T1). The pipeline stays at Stage 0.
- **NEXT RECOMMENDED TASK:** if Q-T1 is approved, build 0.1.1-tp1 (`/reload` only) with zip, steps and tests; then the docs run.

## S-005 | 2026-11-03 | Claude

- **Done:** recorded the approval of D-018 as a design only, the amendments and the answers (D-020). Release_Pipeline.md 0.2.0. Docs only.
- **Not done, on purpose:** no pipeline implementation; no change to EmpireIntelCheck; nothing about GoldIntel.
- **OPEN ISSUES:** the report task does not exist and has no owner yet (Release_Pipeline section 13).
- **BLOCKERS / WAITING FOR:** the user's launch-build run of EmpireIntelCheck 0.1.0-tp1 (TODO 1.5): `EmpireIntelCheck.lua` from SavedVariables plus a Legacy pane screenshot, sent by hand.
- **NEXT RECOMMENDED TASK:** when the files arrive, write the TP-1 report (verdict, result codes, unexpected conditions, evidence EI-E-01..). Commit only sanitized findings. Then the user decides D-012, D-005 and whether to authorize Stage 1.

## S-004 | 2026-11-03 | Claude

- **Done:** designed the EmpireIntel release pipeline (Release_Pipeline.md, D-018 Proposed) and recorded the user's executive roles (D-019). Docs only.
- **Not done, on purpose:** no implementation (needs approval); nothing changed in EmpireIntelCheck or the launch-build check; nothing about GoldIntel.
- **UNEXPECTED / OPEN ISSUES:** approvals and unpause can only be audited, not enforced, from the cloud side while Claude uses the user's GitHub identity (Q-R3). The game process names and the launch folder name are unknown until launch.
- **BLOCKERS:** user approval of D-018; Q-R1..Q-R6.
- **NEXT RECOMMENDED TASK:** the launch-build check results first. Then, if approved, pipeline stage 1 implementation.

## S-003 | 2026-11-03 | Claude

- **Done:** recorded the user's limits in Architecture 2.1.0 before coding. Built EmpireIntelCheck 0.1.0-tp1 and its offline suite: 65 tests pass under Lua 5.1 and 5.3. Each of the 13 safety guards was disabled once (mutation check) and the suite caught every one. Package `dist/EmpireIntelCheck_AddOns.zip` (8 files) built and verified.
- **Bugs found and fixed while testing:** an unrelated retail name (`C_Loot.IsLegacyLootModeEnabled`) made a clean client read NAMES ONLY; the pre-modern baseline check missed a single reappearing global; a multiple-return slip broke the DataStore cross-check; `off` during a run left the session stuck; `on` after an OFF login never started; the bounded dump had no total byte limit.
- **UNEXPECTED / OPEN ISSUES:** (1) The web hosts are still blocked in this session although the user allowed all domains (probably needs a new session), so the Legacy rules stay unverified (Q-9). (2) Blizzard UI addons cannot be listed by index on the modern client, so a Legacy pane that lives in a load-on-demand addon whose name has no Legacy term is caught only by the light rescan after any Blizzard addon loads, or by `/eicheck pane`. (3) The launch interface number may differ from 16001; the README tells the user to tick "Load out of date AddOns".
- **BLOCKERS:** the user's launch-build run (TODO 1.5).
- **NEXT RECOMMENDED TASK:** read the returned `EmpireIntelCheck.lua` and the pane screenshot; write the TP-1 report (verdict, every result code, unexpected conditions, evidence EI-E-01..); the user decides D-012 and D-005.

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
