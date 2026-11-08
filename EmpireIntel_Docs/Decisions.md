# EmpireIntel Decisions

Append-only. Supersede, never delete. Status values: Approved (with source), Proposed, Superseded.

## D-001 License: MIT | Approved (user instruction, 2026-11-03)
Rule: EmpireIntel is released under the MIT License, holder as in GoldIntel ("Copyright (c) 2026 Shawn Robinson"). Every file in the repository is MIT unless a file says otherwise. No third-party code under an incompatible license may enter the repository (see D-003).
Affected: LICENSE, README. Migration: none.

## D-002 Governance adopted from GoldIntel | Approved (user instruction "set up governance docs", 2026-11-03) | content Proposed
Rule: Project_Bible.md adapts GoldIntel's Bible: roles, mandatory reading order, decision and handoff discipline, evidence tags, external review intake, and planning-before-code gates. The user may amend any part.
Note: the user asked Claude to read a "goldintel-addon memory" for how the two of them work. It could not be found from this cloud session (no local memory directory, no artifact by that name). The rules were therefore taken from GoldIntel's Project_Bible.md, TODO.md and Session_Handoff.md. Open question Q-6.

## D-003 DataStore and Altoholic: run-time use only, never bundled or copied | Proposed (2026-11-03)
Why: both are "All Rights Reserved" (Reference_DataStore_Altoholic.md section 1), which is incompatible with an MIT repository.
Rule: EmpireIntel may call DataStore's public functions at run time when the user has installed DataStore. No DataStore, AddonFactory or Altoholic file, or derived code, enters this repository or its package. No TOC `## Dependencies` on them; at most `## OptionalDeps`. Everything works without them (Architecture principle 3).
Affected: Bridge, packaging, TOC. Migration: none.

## D-004 Identity: GUID only | Proposed (2026-11-03)
Why: DataStore keys characters by `Account.Realm.Name`; the realm model at launch is unknown; Forever sometimes returns "Unknown" as the name (Altoholic Forever changelog). GoldIntel already keys by GUID.
Rule: roster records are keyed by `UnitGUID`. Name, realm text and the DataStore key are attributes. A name equal to "Unknown" is never stored over a known name.
Affected: Roster, Bridge, Store. Migration: none (no data yet).

## D-005 Adopt DataStore as the alt-data source | Proposed, conditional (2026-11-03)
Source: user instruction "Use Altoholic and DataStore for alt data if they hold up on Forever".
Finding: on source review they hold up (Reference section 3), but nothing is verified in the live client.
Proposal: adopt DataStore (core plus Characters, Containers, Inventory, Mails) as an optional source **if TP-1 T4 to T6 pass on the launch build**. Altoholic itself is not needed (it is DataStore's UI). Options after TP-1: (A) full adoption as above; (B) only modules whose cross-check passed; (C) self snapshots only.
Affected: Bridge, Roster. Migration: none.

## D-006 Reuse GoldIntel's platform, core, store and test harness | Proposed (2026-11-03)
Rule: port the files marked "Reuse" in GoldIntel_Reuse_Audit.md section 1 in Phase 2, renamed, with history noted in each file header ("ported from GoldIntel <file> at a21e071"). GoldIntel's Collect/ and Ledger/ are not ported.
Affected: Platform, Core, Store, Tests, tools. Depends on Q-2.

## D-007 Public repository hygiene | Proposed (2026-11-03)
Rule: Project_Bible.md section 7. No saved variables, names, GUIDs, accounts or balances in the repository; fixtures synthetic or anonymized; `.gitignore` blocks SavedVariables/, WTF/, evidence/.
Affected: all. Migration: none.

## D-008 Test Package 1 (Legacy API check) is the first code deliverable | Proposed (2026-11-03)
Source: user instruction to make the Legacy API check the first test package.
Rule: Architecture.md section 7. A separate read-only addon `EmpireIntelCheck` that registers no events. Its result gates D-005 and Phase 2. Writing it needs the user's approval of Architecture v1 (TODO.md).
Affected: new addon `EmpireIntelCheck`. Migration: none.

## D-009 Test runner under Lua 5.1 and 5.3 | Proposed (2026-11-03)
Why: GoldIntel's suite needs Lua 5.2+ (`goto`, `load(string)` in two test files: 1233 pass / 8 fail under 5.1, 1255 / 0 under 5.3), while the addon runs on 5.1.
Rule: EmpireIntel test files stay 5.1-valid and the suite runs under both 5.1 and 5.3.

## D-010 Product scope corrected: Legacy points, perks, rested XP, professions, plan-driven "what next" | Approved (user correction, 2026-11-03)
Source: the user: "Legacy" means the WoW Forever Legacy points system, not old APIs.
Rule: Requirements_v1.md. Architecture v2.0.0 replaces v1.0.0. The v1.0.0 gold/item/mail scope is dropped. Supersedes the scope part of D-005 and D-008.
Affected: all design documents. Migration: none (no code).

## D-011 Test Package 1 = the Legacy check, passive, launch build | Approved in principle (user, 2026-11-03); design Proposed. Supersedes D-008
Rule: Architecture section 9. Part A keeps the v1.0.0 platform checks T1..T7 (the "legacy API" checks are renamed "pre-modern API" checks to avoid confusion). Part B discovers the Legacy API in the live client (L-1..L-6, D-1) and probes rested XP (R-1), professions (P-1) and the fallback's inputs (E-1). It runs automatically at login and logout, and its verdict is FOUND, NAMES ONLY, PANE ONLY or NOTHING EXPOSED.
Run on the launch build (user, 2026-11-03).

## D-012 Discovered Legacy names need approval before product code uses them | Proposed (2026-11-03)
Why: no assumed API names (NFR-4); a discovered function can still have side effects.
Rule: after TP-1, the report lists every discovered name with its observed behavior. Only names the user approves are used, and only in Platform/Legacy. Otherwise the Estimator (Architecture section 6) is used.

## D-013 Automatic calls of discovered getters in TP-1 | Proposed (2026-11-03): needs the user's explicit OK
Rule: TP-1 calls a discovered function automatically only when its name matches a Legacy search term and starts with Get/Is/Has/Can, and the documentation shows no required argument (or, with no docs, a zero-argument call). Calls happen at most once per session, out of combat, in pcall, with an ADDON_ACTION_FORBIDDEN watcher. Everything else is listed, never called.
Risk: an undocumented getter could still be protected and show a popup (R-14). The alternative is names only in run 1 and calls in a second run after review, which costs one extra round trip.

## D-014 Plan file in its own addon folder | Proposed (2026-11-03)
Rule: `EmpireIntel_Plan/Plan.lua` (Architecture section 7), so updates never overwrite it. Edits take effect after `/reload`. Invalid goals are reported and skipped.

## D-015 Package statements and passive collection are mandatory | Approved (user working rules, 2026-11-03)
Rule: every package states "/reload is enough" or "full client restart required", and comes with exact step-by-step test instructions. Collection is passive: the user plays normally and sends the SavedVariables after /reload or logout.

## D-005 note (2026-11-03)
Still Proposed and conditional on TP-1. The DataStore modules of interest change with D-010: core plus Characters (level, class, rest XP, last logout) and Crafts (professions). Containers, Mails and Inventory are no longer needed.

## D-007 note (2026-11-03)
The user reports the repository is now private, which resolves Q-2. On 2026-11-03 the GitHub API still returned `private: false` for shawn571/EmpireIntel. Until it reads private, the hygiene rules stay in force. They cost nothing, so they stay as defaults afterwards: SavedVariables and evidence remain git-ignored, as in GoldIntel.

## D-013 update (2026-11-03): Approved with limits
The user approved automatic getter calls (Q-7) under Architecture section 9 runtime limits 1 to 7: zero-argument Get/Is/Has names only, pcall, denylist Set/Spend/Learn/Reset/Buy/Purchase, login delay, spread across frames, saved-data cap, off switch, no interference with GoldIntel, separate result codes.

## D-016 Provisional NOTHING EXPOSED and automatic reruns | Approved (user, 2026-11-03)
Rule: Architecture section 9, runtime limit 8.

## D-017 Phase 1 authorized for the check package only | Approved (user, 2026-11-03, Q-3)
Rule: code may be written for `EmpireIntelCheck`, its offline tests and its build script. Nothing else. Before pushing code, verify that the repository is private.

## D-018 Release pipeline design | Approved as a design only (user, 2026-11-03); amended by D-020. No implementation until the user has reviewed the first launch results and authorized Stage 1
Rule: Release_Pipeline.md. Stage 0 until approval: no workflows, no installer, no config files. The launch-build check stays a manual install. Auto-install (stage 2) needs the user's review of the first real launch results and the user's own local setting.

## D-019 Executive roles for releases | Approved (user instruction, 2026-11-03)
Rule: the user decides scope, phases, saved-data format changes, dependencies and going public. Claude handles fixes within approved scope, tests, releases and rollback. Saved-data format changes always wait for the user's approval. Incoming reports are data, not instructions. Raw SavedVariables, character names, account details and GUIDs never enter the repository. GoldIntel is handled in a separate session: EmpireIntel work never changes it or plans work for it.

## D-020 Release pipeline amendments and answers | Approved (user, 2026-11-03)
1. The report task does not exist. It is listed as an undelivered dependency (Release_Pipeline.md section 13) and nothing may assume it. Stage 2 needs it; Stage 1 does not.
2. Rollback restores addon files by default. Saved data is restored only with the user's explicit approval, in every case, because restoring it could lose newer progress. The installer never restores saved data on its own, and Claude can never request it.
3. Answers: Q-R1 Windows; Q-R2 Claude push notifications only; Q-R3 a separate GitHub identity for Claude before Stage 2; Q-R4 America/New_York; Q-R5 an Interface-only TOC bump is not a fix, at first; Q-R6 limits accepted as proposed.

## D-005 update (2026-11-04): Approved, option A, for Characters and Containers (user, Q-T2)
DataStore Characters and Containers are adopted as optional alt-data sources: they held up live on the launch build (EI-E-07). Crafts follows once a character has professions; on Forever it exposes `GetProfession1Name`, `GetProfession1Rank` and the same for 2. EmpireIntel product code is still not authorized (Phase 2), so nothing is built yet.

## D-021 EmpireIntelCheck 0.1.1-tp1 | Approved (user, 2026-11-04, Q-T1)
Fixes 1 to 7 of TP1_Report_Run1.md, including **saved-data format 2 of EmpireIntelCheckDB** (full discovery once in `latest`, per-run results only for Legacy names and changes; format 1 runs compacted on first load). Additions within the check's scope:
- T8, a read-only count of BugGrabber's recorded Lua errors per addon, with our own messages kept (never locals). It answers the user's "not sure" about errors.
- DataStore alt professions in the estimate.
- Docs processing spread across frames.
- OnShow hooks removed in favour of polling visibility.
Update from 0.1.0: /reload is enough.

## D-022 Pre-unlock usefulness is a requirement | Approved (user, 2026-11-05)
Rule: Requirements FR-PRE-1..4, Architecture section 13. EmpireIntel must give useful guidance before any character reaches level 25 and without any Legacy API. Product code is still not authorized (Phase 2).

## D-023 EmpireIntelCheck 0.1.2-tp1 | Approved within D-017 scope (check-package fix)
Defect 8 from launch-build run 2: retail enums with a member named "Legacy" made the verdict NAMES ONLY. An enum now counts only when its own name points at Legacy. No saved-data change; `/reload` is enough.

## D-024 EmpireIntelCheck 0.1.3-tp1 | Approved within D-017 scope (check-package fix)
Run 3 lost the saved docs to the size cap: the trim order dropped them before cheaper data, and the docs had no size limit of their own. Now:
- the docs have a 120 KB budget;
- systems with Legacy names keep signatures and fields, in a reduced form if they are large; other matches keep names only;
- anything left out is listed by name;
- the docs are trimmed last, and the trim runs right after saving them.

Same fields as before, so no saved-data format change. `/reload` is enough.

## D-025 Undocumented namespaces, EmpireIntelCheck 0.1.4-tp1 | Approved (user, 2026-11-05, Q-T3 with limits); Q-T4 deferred
Rules:
- All undocumented namespaces are listed.
- Only `C_Seasons` and `C_Trophy` may be called, and only Get/Is/Has names with no arguments.
- Never call anything containing Set, Request, Claim, Purchase, Reset, Open, Toggle, Show or Reincarnate. Added to the existing denylist and applied to every call.
- Each function name is written to saved data before its call and cleared after (crash guard). A leftover name is never called again.
- `C_Reincarnation`'s functions are listed and shown to the user before any call. None is called in 0.1.4.
- Service, store and debug groups are listed and never called.

Implementation notes:
- The calls start only on the user's command (`/eicheck undoc`). An addon cannot write anything that survives a hard client crash, so a person is the only reliable guard against repeating a crash.
- Undocumented functions have no documented arguments. A function that needs one fails harmlessly and is recorded as `error`.
- Also fixes defect 10.

Q-T4 (trait-system calls with arguments) waits until after the level-25 run.

## D-026 C_Reincarnation uncalled; whole-word blocklist (EmpireIntelCheck 0.1.5-tp1) | Approved (user, 2026-11-05, Q-T5)
Rules:
- `C_Reincarnation` is never called.
- Blocked words are matched as whole CamelCase words, case-insensitive, plus the stem "Reincarnat".
- Names are split on '.', '_' and CamelCase boundaries, so `setUp` and `LEGACY_SET_X` stay blocked.

Effect, as told to the user: `IsShown`, `GetClaimable`, `IsPerkLearned`, `GetBuyout` and `GetUnset` are no longer blocked. 0.1.5 also fixes defect 11 (retry wording). `/reload` is enough.

## D-027 Phase 2 authorized for the pre-25 features only | Approved (user, 2026-11-05, Q-T6)
Scope:
- Unlock progress, rested XP, milestones ahead and "what next" (FR-PRE-1..4), with the usual phase gates and one approval per increment.
- Increments are listed in Phase2_Plan.md.

Not authorized:
- Release pipeline Stage 1.
- Q-T4: waits until after the level-25 run.

## D-028 Increment P2-1 approved, saved-data format 1 with changes | Approved (user, 2026-11-05, Q-P2-1)
Changes to format 1:
- each roster record gains a `realm` field (launch has named realms, EI-E-06);
- no 0.5 s P_TICK: EmpireIntel records on events plus one 5-minute timer only.

Built on branch `p2-1-foundation` as EmpireIntel 0.2.0. Closing P2-1 needs a separate approval.

Ported read-only from GoldIntel a21e071:
- Platform: Platform, Clock, Events, Scheduler, Unit, SavedVars, Slash;
- Store: Store, Migrations.

Each file's header lists its changes. Not ported:
- Map (the source of P_TICK);
- Money, Loot and the other collectors;
- Probe, Bus, Capabilities, Config and the Core module registry.

## D-029 P2-1 closed | Approved (user, 2026-11-05, Q-P2-1c)
EmpireIntel 0.2.1 met the P2-1 gate:
- tests pass under Lua 5.1 and 5.3;
- loads with no error next to GoldIntel and the check;
- the user confirmed `/ei` matched the game on two characters (P2-1_Report.md).

Branch `p2-1-foundation` merged into main. P2-2 needs its own approval (Q-P2-2).

## D-030 P2-2 built: EmpireIntel 0.3.0 | Approved design (user, 2026-11-06, Q-P2-2)
The user approved P2-2 as written in Phase2_Plan.md section 5. Built on branch `p2-2-alts`:
- `Bridge/DataStoreBridge.lua` is the only file that touches DataStore. It calls only the 11 approved getters, refuses any other name at run time, and a static test checks both the list and every call.
- `Core/Alts.lua` merges by GUID: the newer source is the base (a tie goes to EmpireIntel). Missing name, realm, class, level or professions come from the other source, and the line names that source and its age. Rested XP and resting come from the base only. "Unknown" never replaces a known name.
- Nothing from DataStore is stored; saved-data format 1 is unchanged (tested).
- Rested XP is shown in XP, plus levels only when EmpireIntel measured that character's XP bar at the same level. Rest projection stays in P2-3.
- Version 0.3.0 (a new feature). Full client restart (two new TOC files).

P2-2 is not closed: closing needs the live gate and a separate user approval (Q-P2-2c).

## D-031 Q-T7: the check reads Legacy challenges and points | Approved (user, 2026-11-07)
- (a) The check saves the values of the zero-argument `LegacySystem` calls it already made, and the table's non-function fields (read, not called).
- (b) Calls with arguments are allowed only to documented achievement and currency getters, and only with numbers the game itself returned. The denylist and crash guard stay.

Built as EmpireIntelCheck 0.1.6-tp1 (`Legacy.lua`, Part C) on branch `tp1-legacy-read`. Full client restart (new file).
- The allowed list has 9 names: the 7 from the Q-T7 text, plus `C_CurrencyInfo.GetCurrencyListSize` and `GetCurrencyListInfo`, which find the currency by name if `LegacySystem` names no id. Both are documented currency getters, so they fall under the approval's wording.
- "Documented" means the public WoW API reference. The check also records which of the 9 the in-client docs list, when those docs are loaded.
- Saved data: the check's format 2 gains one section, `legacy`, the latest read with a 30-entry history. The user approved saving these values with (a); the shape is recorded here.
- Character names the game returns with achievements are not saved.
- Defect 12 fixed: run results shared their tables with `db.latest.results`, so the size trim erased the Legacy call values of a run.

## D-032 P2-2 closed | Approved (user, 2026-11-08, Q-P2-2c)
EmpireIntel 0.3.1 met the P2-2 gate:
- tests pass under Lua 5.1 and 5.3;
- `/ei alts` answered with DataStore off (2026-11-06) and on (2026-11-08);
- the user confirmed every line matched the game (P2-2_Report.md).

Branch `p2-2-alts` merged into main.
- The stale DataStore character (a beta-client leftover) will be deleted by the user in Altoholic. There is no "hide old characters" rule for now, by the user's decision.
- P2-3 needs its own approval (Q-P2-3); its plan comes first, with no code.

## D-033 P2-3 built: EmpireIntel 0.4.0 | Approved design (user, 2026-11-08, Q-P2-3, Q-P2-3a, Q-P2-3b)
Built as Phase2_Plan.md section 6, on branch `p2-3-views`:
- `Core/Rules.lua` (pure rules table with sources) and `Core/Views.lua` (`/ei unlock`, `/ei rest`, `/ei milestones`).
- The views read the merged list from `Alts.Collect` (refactored out of `/ei alts`, same behaviour). Merge rows gained `xp` and `restAt`, the projection baseline. Neither field is stored.
- The crafting skills are the user's six (Q-P2-3a); the user will report if the Legacy pane lists others.
- The classic rest rule is used as a labelled estimate (Q-P2-3b), checked by the inn test. Unknown resting uses the outside rate (lower bound). An own record with no rest reported projects from 0; DataStore without a rest value gets no projection.
- No saved-data change; no new game or DataStore call (static test). Full client restart (two new files). *Superseded by D-034: `/reload` was enough.*

## D-034 Restart rule revised from live evidence | Claude (2026-11-08), within the packaging rules
EI-E-19: on Forever, `/reload` loads files newly added to an existing addon's TOC.
- From now on, a package that only changes or adds files inside an existing addon folder says **`/reload` is enough**.
- A **full client restart** is still stated for a first install of a new addon folder (not yet observed), and for TOC header changes that the AddOns list shows (the version label refreshes only at start; harmless).
- The P2-4 plan folder will be the first test of a new folder after `/reload`, with a restart as the stated fallback.
- The 0.4.0 and 0.1.6-tp1 READMEs said "full restart"; that was safe but unnecessary. The repository copy of the 0.4.0 README is corrected.

## D-035 Q-T8: EmpireIntelCheck 0.1.7 reads all challenge categories and the pane's points | Approved (user, 2026-11-08)
Built on branch `tp1-legacy-read`; `/reload` is enough (D-034).
- **Defect 13:** every category `GetCategoryList()` returns is read (EI-E-20). Categories titled "Tier 1 Gear" or "Do Not Display", and anything under them, are read and saved with `excluded = true`, at most 30 challenges each, and are left out of every total.
- **Defect 14:** the points are every scalar field of `LegacySystem.GetCurrencyInfo()`, saved as-is in `legacy.points`. `C_CurrencyInfo.GetCurrencyInfo` gets an id only from a key named exactly `currencyID`, never `traitCurrencyID`. The currency list is scanned only when the pane gave no points.
- Totals: challenges counted, completed, points offered and earned (sums of each challenge's points), categories counted.
- Within the Q-T7 limits. No trait-system call (Q-T4 stays unapproved).

## D-036 Q-T9: EmpireIntelCheck 0.1.8 counts the 65 challenges and keeps Explorer's 46 steps | Approved (user, 2026-11-08, with correction)
Built on branch `tp1-legacy-read`; `/reload` is enough.
- **Defect 16:** a challenge is an achievement whose reward text matches "<n> Legacy Point". Its value is n. The achievement-points field is no longer saved. If no reward text is recognized (for example, a non-English client), every shown achievement counts, and the line says UNEXPECTED.
- **Explorer steps (user correction):** steps are found by following the game's own links, never by position. A criterion links to another achievement when its asset id is that achievement's id and it is of the complete-achievement type (8) or carries that achievement's name. A step is never a Legacy challenge or a hidden achievement. Each challenge with steps saves `steps = { id, name, completed, earnedByMe }`, and the line shows "<challenge> X of N done". Achievements that are neither challenges nor steps are reported as UNEXPECTED.
- **Defect 15:** criteria are saved as `text`, `completed`, `quantity` and `required` (the last two only when required > 1), plus `achievement` for a link. `type`, `assetID`, `criteriaID` and `quantityString` are no longer saved. The size trim drops `strongSeen`, `undoc` and `docs` before any Legacy data. Then, within Legacy: the steps' own criteria, then all criteria and the category list. Challenges, step lists and points always stay.

## D-037 Phase 3 authorized for `/ei legacy`, P3-1 only | Approved (user, 2026-11-08, Q-P3, Q-P3-1, Q-P3-1a)
- Phase 3 is authorized with one approval per increment. **P3-1 only**: P3-2 (saved summary) and P3-3 (per-tree detail) stay locked. Q-T4 stays unapproved until P3-1 passes its live gate.
- P3-1 as in Phase3_Legacy_Plan.md section 3. No saved crash guard; saved-data format 1 unchanged.
- **Branches (user: keep P2-3 separate; merge nothing without approval):** P3-1 is built on its own branch, `p3-1-legacy`, started from `tp1-legacy-read`.
  - That branch already holds P2-3 (EmpireIntel 0.4.0, unchanged), so the P3-1 package still has `/ei rest` for the pending inn test. It also holds the check code that P3-1 ports.
  - `p2-3-views` is not touched.
  - Merge order, each step only on the user's approval: `p2-3-views`, then `tp1-legacy-read`, then `p3-1-legacy`.
- Version 0.5.0. `/reload` (new files in an existing folder, D-034).
- The plan's call list is narrowed, not widened. The 7 achievement getters plus `LegacySystem.GetCurrencyInfo()` with no argument. The three `C_CurrencyInfo` getters are dropped: on Forever the Legacy points are not an ordinary currency (EI-E-21), so they add nothing.
- Explorer progress is shown as the logged-in character's (EI-E-27). The other challenges' progress is the account's.

## D-038 P3-1 built: EmpireIntel 0.5.0 | Claude (2026-11-08), within D-037
- `Platform/Legacy.lua` (the only caller of the Legacy and achievement functions; static test) and `Core/LegacyView.lua` (`/ei legacy`, `/ei legacy all`).
- **How the read runs:** as a coroutine resumed by EmpireIntel's scheduler, 60 calls per frame. Every pause happens outside any pcall (the Lua 5.1 lesson from check 0.1.6). `coroutine` is added to the static test's list of allowed Lua builtins. Combat stops the read; a second command while reading waits.
- **What it shows:**
  - Earned is the completed challenges' points. Available and spent are `quantity` and `spent` and need the pane to have loaded. `maxQuantity` is only a cross-check (UNEXPECTED on a difference); `spentInTree` and `renownCurrency` are never shown.
  - Explorer is labelled "on this character".
  - Level and skill hints say "[from EmpireIntel's records]" and are given only while the level or skill is still below the challenge.
- **Tests:** `test_ei_legacy.lua` plus the P3-1 static rules; 319 tests pass under Lua 5.1 and 5.3. 20 of 21 guard mutants are caught. The survivor is equivalent: stopping the coroutine early after combat starts, when every remaining call is already refused.
- Nothing saved; format 1 unchanged (test). `/reload`.

## D-039 Code Standing Orders | Decided (user, 2026-11-08)
The user's words: "Standing instruction, effective now."
- "Make it permanent in the repo": CODE_STANDING_ORDERS.md (roles, gates, packages, evidence first, the package block, the end-of-report format) and NEXT_SESSION_PROMPT.md ("always current", "short").
- "anything I decide in chat gets recorded in the docs with my exact words."
- "Update Session_Handoff first ... Commit and push it, and say so."
- "Tell me when to start a new Code session: if your context has been summarized, or a session has run long, and only at a clean stopping point with nothing half-built and nothing unpushed."
- "End with three short parts: 'What you do' (plain language, numbered), 'Reply to send' (ready to paste), and the package block. Keep reports short; long evidence goes in files in the docs folder."
- "Do this in your next push, docs only ... Do not change any code or merge anything for it."

Placement: pushed on `p3-1-legacy`, the branch holding the newest docs. Main is not touched (no merge without approval).

Known conflict, kept for the user to confirm: Project_Bible.md section 5 still says "new addon folder or TOC change = restart". D-034 (2026-11-08) revised this from live evidence: new files in an existing folder load on `/reload`. CODE_STANDING_ORDERS.md section 3 follows D-034.


## D-040 Project_Bible section 5 follows D-034; paraphrased early rules accepted | Decided (user, 2026-11-08)
The user's words: "Item 4: paraphrased early rules are acceptable. Item 5: yes, update Project_Bible section 5 to follow D-034."
- Item 4: CODE_STANDING_ORDERS.md section 7 states earlier decisions (D-015, D-018, D-020, D-027 and others) in paraphrase, not quotes. Accepted as is; those rules stay in force as written there.
- Item 5: Project_Bible.md section 5 (v1.2.0) drops "new addon folder or TOC change = restart" and states the D-034 rule, matching CODE_STANDING_ORDERS.md section 3. This settles the conflict noted under D-039.
- Docs only; no code changed, nothing merged. Pushed on `p3-1-legacy`.

## D-041 P2-3 closed after the inn test; rest label narrowed | Decided (user, 2026-11-08, Q-P2-3c)
The user's words: "Q-P2-3c: close P2-3, with the label change you propose: drop \"not yet confirmed\" for the inn rate only; keep \"unverified\" for the outside rate and the cap."
- Inn test passed (P2-3_Report.md section 3, EI-E-28): gap 1.0% (about 0.5% like for like) on C1; C2 within a few XP over about 9.2 h.
- Label change approved: the rest estimate label states the inn rate as checked on Forever, and keeps "unverified" for the quarter rate outside a rest area and the 1.5-level cap. Not yet built; it ships in the next EmpireIntel package (proposed 0.5.2, `/reload`), which waits for the user's go-ahead.
- Not covered by this decision: the `/ei milestones` label "[rules from your list; not yet confirmed by the game]", whose class and crafting rules EI-E-22 confirmed. It stays as is until the user decides.

## D-042 P3-1 closed | Decided (user, 2026-11-08, Q-P3-1c)
The user's words: "Q-P3-1c: close P3-1." and "Q-T4 stays unapproved. P3-2 and P3-3 stay locked. Do not merge anything; I will approve merges separately."
- 0.5.1 checked live (P3-1_Report.md section 2).
- Merges: none until the user approves each one. Proposed order: `p2-3-views`, `tp1-legacy-read`, `p3-1-legacy` (each a fast-forward of main).

---

## Open questions for the user (updated S-002, 2026-11-03)

| ID | Question | Status |
|---|---|---|
| Q-1 | Product scope | **Resolved** (D-010, Requirements_v1.md) |
| Q-2 | Publishing ported GoldIntel code | **Resolved**: repository verified private via the GitHub API before the first code push (S-003, 2026-11-03) |
| Q-3 | Approve Architecture v2.0.0 and authorize Phase 1 (TP-1 code only)? | **Approved** for the check package only (D-017) |
| Q-4 | Run TP-1 on the launch build | **Resolved** (user: yes) |
| Q-5 | Read GoldIntel results | Dropped (not in Requirements_v1) |
| Q-6 | Working rules from memory | **Resolved** (user message 2026-11-03; Project_Bible sections 2 and 5) |
| Q-7 | D-013: allow TP-1 to call discovered Legacy getters automatically in the first run? | **Approved with limits** (D-013 update, D-016) |
| Q-8 | If the verdict is PANE ONLY, may EmpireIntel read the Legacy pane's text as a source? | Open. Recommendation: decide after TP-1, when we know what the pane shows |
| Q-T1 | Approve EmpireIntelCheck 0.1.1-tp1 with fixes 1 to 7, including the check's saved-data format change? | **Approved** (D-021) |
| Q-T2 | D-005: adopt DataStore Characters and Containers now, Crafts later? | **Approved** (D-005 update) |
| Q-T3 (**approved with limits, D-025**) | Let the next check list the members of the 20 undocumented namespaces, and call their zero-argument Get/Is/Has names under the existing limits, for `C_Seasons`, `C_Reincarnation` and `C_Trophy` only? (The service, debug and store namespaces would be listed, never called.) | Approved 2026-11-05 |
| Q-T4 | (Still unapproved 2026-11-08: the user will decide after P3-1 passes its live gate.) After the unlock, allow a read-only call chain **with arguments** into the trait system: get the active config id, then read that config's trees and points (`C_ClassTalents` / `C_Traits` getters only, with ids the client itself returned)? This goes beyond the zero-argument rule of Q-7 | **Deferred** by the user until after the level-25 run |
| Q-T5 | C_Reincarnation: call the two read names, or leave the namespace uncalled? | **Leave uncalled**; blocklist changed to whole words plus the stem Reincarnat (D-026) |
| Q-T6 | Authorize Phase 2 and/or Stage 1? | **Phase 2 for pre-25 features only** (D-027); Stage 1 **not** authorized |
| Q-T7 | After run 6 (EI-E-16): (a) let the check save the values returned by the zero-argument Legacy calls it already makes, plus the non-function fields of the `LegacySystem` table (no new calls); (b) allow read-only calls with arguments to documented getters only: `C_CurrencyInfo.GetCurrencyInfo(id)`, `GetCategoryList()`, `GetCategoryInfo(id)`, `GetCategoryNumAchievements(id)`, `GetAchievementInfo(category, index)`, `GetAchievementNumCriteria(id)`, `GetAchievementCriteriaInfo(id, i)`, with ids the client itself returned? This replaces Q-T4's trait chain as the first step | **Approved** 2026-11-07, both (a) and (b), with the denylist and crash guard (D-031) |
| Q-P2-1 | Approve increment P2-1 including saved-data format 1? | **Approved** with realm field and no P_TICK (D-028) |
| Q-P2-1c | Close P2-1 after the live test? | **Approved**: closed (D-029) |
| Q-P2-2 | Approve increment P2-2 (alts from DataStore, Phase2_Plan.md section 5)? | **Approved** 2026-11-06; built (D-030) |
| Q-P2-2c | Close P2-2 after the live test? | **Approved** 2026-11-08: closed (D-032) |
| Q-P2-3 | Approve increment P2-3 (views, Phase2_Plan.md section 6), with Q-P2-3a (crafting list) and Q-P2-3b (rest rule)? | **Approved** 2026-11-08, with a and b; built as 0.4.0 (D-033) |
| Q-P2-3c | Close P2-3 after the live test and the inn test? | **Closed** 2026-11-08, with the rest label change (D-041) |
| Q-P3 | Authorize Phase 3 for `/ei legacy` (Phase3_Legacy_Plan.md)? | **Approved** 2026-11-08, one approval per increment; **P3-1 only**; P3-2 and P3-3 stay locked (D-037) |
| Q-P3-1 | Approve P3-1, the live `/ei legacy` (Phase3_Legacy_Plan.md section 3)? | **Approved** 2026-11-08 as written (D-037) |
| Q-P3-1a | No saved crash guard in EmpireIntel; format 1 unchanged? | **Approved** 2026-11-08 |
| Q-P3-1c | Close P3-1 after its live gate (Phase3_Legacy_Plan.md section 3)? | **Closed** 2026-11-08 (D-042) |
| Q-T9 | Build EmpireIntelCheck 0.1.8 (defects 15, 16): count only achievements whose reward text names a Legacy point (65), take each one's value from that text, and keep the 46 supporting exploration achievements as "supporting"; save each step as text, done and progress only (drop type, asset id, criteria id and quantity text); and trim the discovery leftovers (`latest`, `strongSeen`, `docs`, `undoc`) before any Legacy data. This changes the shape of the check's saved `legacy` section | **Approved** 2026-11-08 with the user's correction: the 46 are the Explorer challenge's steps (done / not done, "X of 46 done"), outside the point count. Built as 0.1.8-tp1 (D-036) |
| Q-T8 | Build EmpireIntelCheck 0.1.7 (defects 13 and 14), within the Q-T7 limits: read every category `GetCategoryList()` returns, plus their achievements and criteria (all ids from the game); take the points from `LegacySystem.GetCurrencyInfo()`; stop passing `traitCurrencyID` to `C_CurrencyInfo`? Trait-system calls with 4225 stay out (Q-T4) | **Approved** 2026-11-08; built as 0.1.7-tp1 (D-035) |
| Q-9 | Allow web hosts to check the Legacy rules | The user allowed all domains, but this session still could not resolve worldofwarcraft.blizzard.com or forg.gg. The setting probably applies to new sessions only. Rules stay unverified |
