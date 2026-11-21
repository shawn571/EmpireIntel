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

## D-043 EmpireIntel 0.5.2: both labels; merge 1 approved | Decided (user, 2026-11-08)
The user's words: "Build 0.5.2 with the rest label: yes, as worded. Milestones label: drop “not yet confirmed” for the class and crafting rules (EI-E-22), and keep [estimate] on the Legacy points line. Put both in 0.5.2. Merge 1 (p2-3-views): approved. Tell me when it’s done; merges 2 and 3 wait for separate approval."
- Built on `p3-1-legacy` as EmpireIntel 0.5.2 (`/reload`). Text only: `R.LABEL_REST` is "[estimate: 5% of a level per 8 h resting (inn rate checked on Forever); a quarter outside and the 1.5-level cap unverified]"; `R.LABEL_RULES` is "[class and crafting milestones confirmed by the game]". The Legacy points line keeps "[estimate]". No new call, saved data unchanged. This builds the D-041 label change.
- Tests: 321 pass under Lua 5.1 and 5.3; new assertions check both headers and that no view line says "not yet confirmed"; 3 of 3 label mutants caught.
- Merge 1 (`p2-3-views` into main, a fast-forward): approved. The first attempt was blocked by the session's auto-mode permission check (merge without review), so main is unchanged at 83b3574 until the user allows the push or merges it on GitHub.

## D-044 0.5.2 checked live; merge 1 by pull request | Decided (user, 2026-11-08)
The user's words: "0.5.2 is installed (the reviewer chat copied the files from d1ae945 into my Forever folder; all 20 match). Steps 2–5: match. Merge 1: open a PR p2-3-views → main and I’ll merge it on GitHub with a merge commit. Merges 2 and 3 still need separate approval."
- 0.5.2 live check passed (README steps 2-5) [reported].
- Pull request https://github.com/shawn571/EmpireIntel/pull/1 opened: `p2-3-views` (257c2bb) into main (83b3574). The user merges it on GitHub with a merge commit. Merges 2 and 3 wait for separate approval.
- Test count: still 321 because the test runner counts `T.it` blocks, not assertions; 0.5.2 added assertions inside the two existing label tests (each fails when its label is undone).
- Repair: the S-043 edit of this file dropped the "---" line and the "## Open questions for the user" heading before the table below; restored here (text only, no entry changed).

## D-045 Merge 2 approved | Decided (user, 2026-11-08)
The user's words: "PR 1 merged (merge commit). Check main and confirm it’s at 0.4.0 with 244 tests passing. Merge 2 (tp1-legacy-read): approved, open a PR. Merge 3 waits for separate approval."
- Checked on GitHub at S-045: pull request 1 is still **open, not merged**; main is 83b3574 (EmpireIntel 0.3.1, EmpireIntelCheck 0.1.5-tp1, 212 tests pass under Lua 5.1 and 5.3).
- The merge 2 pull request is held until pull request 1 is merged: opened now against main, it would also carry all of `p2-3-views`, and merging it first would do merges 1 and 2 at once.

## D-046 Merge 1 done; merge 2 pull request | Recorded (user, 2026-11-08)
The user's words: "PR 1 now shows Merged. Go ahead: check main and open the merge 2 PR."
- Checked: main is 634bd63, a merge commit (parents 83b3574 and 257c2bb), with the same tree as `p2-3-views`: EmpireIntel 0.4.0, EmpireIntelCheck 0.1.5-tp1; 244 tests pass under Lua 5.1 and 5.3.
- Pull request https://github.com/shawn571/EmpireIntel/pull/2 opened: `tp1-legacy-read` (1544eb5) into main; GitHub reports it mergeable, clean (22 commits, 18 files). Merge 3 waits for separate approval.

## D-047 Merge 2 done; merge 3 approved | Decided (user, 2026-11-08)
The user's words: "PR 2 shows Merged. Check main. Merge 3 (p3-1-legacy): [approved, open a PR" (the message ended there; read as the first option of the reply template, "approved, open a PR").
- Checked: main is e8a30b3, a merge commit (parents 634bd63 and 1544eb5), with the same tree as `tp1-legacy-read`: EmpireIntel 0.4.0, EmpireIntelCheck 0.1.8-tp1; 283 tests pass under Lua 5.1 and 5.3.
- Merge 3 pull request opened: `p3-1-legacy` into main (no conflicts, checked with `git merge-tree`). After it is merged, main holds EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1 and the newest docs, matching what the user has installed.

## D-048 All three merges done; next-session prompt points at main | Decided (user, 2026-11-08)
The user's words: "PR 3 shows Merged. Check main and point NEXT_SESSION_PROMPT at main."
- Checked: main is c5434a7, a merge commit (parents e8a30b3 and da98dca), with the same tree as `p3-1-legacy`: EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1; 321 tests pass under Lua 5.1 and 5.3. A zip built from main has the same files as the delivered 0.5.2 zip.
- NEXT_SESSION_PROMPT.md now names `main`. Pushing to main directly is blocked by the session's permission check, so this change is on branch `docs-after-merges`, opened as a pull request for the user to merge.
- The merged branches (`p2-3-views`, `tp1-legacy-read`, `p3-1-legacy`) take no new work; new work branches from main.

## D-049 Merge standing order and docs-only standing approval | Decided (user, 2026-11-08)
The user's words: "Standing order, effective now. Record it in CODE_STANDING_ORDERS.md and NEXT_SESSION_PROMPT.md with my words, and as a decision:"
“Once I approve a merge in chat, you merge it yourself through its pull request (gh pr merge <n> --merge; no squash, no rebase, no direct push to main), then check main and report the merge commit and the test result. Approval is still required for every merge except the docs-only standing approval. Commits and pushes to work branches need no approval. Never force-push or delete branches.”
"For EmpireIntel only, add the same docs-only standing approval GoldIntel has (D-105): you may merge docs-only pull requests that change only Session_Handoff.md, NEXT_SESSION_PROMPT.md, CODE_STANDING_ORDERS.md or the recording of my decisions; tell me each time."
"Also add .claude/settings.json with {"permissions":{"allow":["Bash(gh pr merge *)"]}} on a docs branch and open a PR. I’ll merge that one myself. If a merge is still blocked after that, tell me the exact message and don’t work around it."
"PR 4: I’ll merge it now. Next: nothing for now"
- Recorded in CODE_STANDING_ORDERS.md section 2 (v1.1.0) and NEXT_SESSION_PROMPT.md.
- GoldIntel is not changed (D-018/D-020); D-105 is cited only.
- Known limit: in Claude Code cloud sessions the `gh` CLI cannot use GitHub GraphQL, which `gh pr merge` uses; if the merge fails for that reason, the session reports the exact message and stops (the user's rule).

## D-050 Merge command: REST in place of gh pr merge | Decided (user, 2026-11-08)
The user's words: "Use the REST merge command (gh api -X PUT repos/shawn571/EmpireIntel/pulls/<n>/merge -f merge_method=merge) in place of gh pr merge: approved. Record it with my words in CODE_STANDING_ORDERS.md and NEXT_SESSION_PROMPT.md. Add its permission to #6: yes, replacing the gh pr merge rule: Bash(gh api -X PUT repos/shawn571/EmpireIntel/pulls/*/merge *). #5: you merge it with the REST command, then check main. I’ll merge #6 myself after you’ve updated it."
- Why: `gh pr merge 5 --merge` was refused with "403 Forbidden ... GitHub GraphQL is not available from Claude Code sessions; use the REST API" (S-049).
- The REST command makes the same merge commit through the pull request; the rest of D-049 is unchanged.
- `.claude/settings.json` (pull request 6) allows `Bash(gh api -X PUT repos/shawn571/EmpireIntel/pulls/*/merge *)` in place of `Bash(gh pr merge *)`.

## D-051 Docs-only standing approval extended to TODO.md and Changelog.md | Decided (user, 2026-11-08)
The user's words: "Extend the docs-only standing approval to also cover TODO.md and Changelog.md. Record it with my words, then update TODO.md now and merge it under that approval."
- The D-049 docs-only standing approval now covers pull requests that change only Session_Handoff.md, NEXT_SESSION_PROMPT.md, CODE_STANDING_ORDERS.md, Decisions.md (the recording of the user's decisions), TODO.md and Changelog.md. Claude tells the user each time.
- Recorded in CODE_STANDING_ORDERS.md section 2 and NEXT_SESSION_PROMPT.md. First use: this pull request.

## D-052 P2-4 approved with the Legacy lock rule | Approved (user, 2026-11-08, Q-P2-4, a-e)
The user's words: "Q-P2-4: approved, with one change. Add the Legacy lock rule to section 7 and to the tests: “Before any character on the account reaches 25, Legacy is not available: the challenges goal shows ‘Legacy not unlocked yet’ (never met) and the defaults lead with reach 25. Once any character has reached 25, Legacy is available on every character, including ones below 25.” Also fix the header lines that say Phase 2 uses no Legacy API. a: yes. b: yes, under that rule. c: yes. d: yes. e: yes. Merge #9: approved once those edits are in. Then build P2-4 as 0.6.0 plus EmpireIntel_Plan 1."
And: "Separately, plan only and no code: write a post-25 plan (Phase 3) covering P3-2 saved summary, P3-3 per-tree detail with what Q-T4 would need, and perk goals for the plan file, with questions for me. I’ll approve one increment at a time."
- Phase2_Plan.md section 7 (plan file format 1 is a contract), with the lock rule in 7.3, 7.4 and 7.7; header lines corrected: P2-1 to P2-3 use no Legacy API; P2-4 uses the P3-1 reads on command only. This narrows D-027 for P2-4 only.
- Unlocked = any known character at level 25 or higher (EI-E-02).

## D-054 P2-4 redirected: an in-game plan window and a route planner | Decided (user, 2026-11-08)
The user's words: "Direction change for P2-4. Don’t merge #11; keep the branch. I don’t want plans written in a text file. I want:
An in-game GUI (window opened by a command and optionally a minimap button, works with ElvUI) to view and edit the plan.
A default plan: the most efficient path to Legacy points across my characters. For example: level the main to 25, the main’s first Spelunker challenge, level the first alt to 25, and so on.
The plan informed by Legacy route guides (start with Method’s “Fastest Way to Get Legacy Points”; check what the Hated Legacy addon already does). Respect level-gated requirements (profession caps by character level) and things not worth doing before 60 (low-level PvP). Every rule is tagged with its source and labelled unverified until the game confirms it.
Two modes: my edited plan, or auto-adjust to whatever unlocks a Legacy point fastest from the characters’ current state.
Plan only, no code. Write it as a revised P2-4 (or a new increment if that fits better) with: what can be reused from #11; the GUI design and the API checks it needs first; the rules table and its sources; how “fastest” is measured and what the target is (16 spendable, the 15/25/40/55 rewards, or something else); the saved-data format change; restart or reload; questions for me."
- #11 (`p2-4-next`, 0.6.0 and EmpireIntel_Plan 1) is kept, not merged. Plan file format 1 is not adopted.
- The revised plan is Phase2_Plan.md section 8 (for approval, Q-P2-4r and the questions in 8.9). Section 7 is superseded.

## D-055 Revised P2-4 approved; rested fix; window design direction | Approved (user, 2026-11-08, Phase2_Plan.md 8.9)
The user's words: "Answers to section 8.9 (record with my words):
Q-P2-4r: yes. a: yes (format 2 for the plan; P3-2 becomes format 3). b: after Q-G1. Q-G1: yes, run the UI checks in EmpireIntelCheck alongside the P2-4a build. Q-G2: own minimap button plus the AddOn compartment. Q-G3: replaced by the design direction below. Q-F1: 16. Q-F2: yes. Q-F3: no PvP before 60; raids and Valthalak at 60; zone Explorer [after 50 / other]; Spelunker challenges are planned at any level. Q-F4: yes. Q-F5: yes.
Fix before building: section 8.5 counts rested XP “at half”. In Classic, a rested pool of R saves R of kill XP in full. Source it or fix it.
Design direction for the P2-4b window:
1. Unique to EmpireIntel. Own textures, no Blizzard templates that ElvUI reskins, so ElvUI doesn’t change our window.
2. Look and feel inspired by Linear: dark, dense, calm list rows with status icons; drag to reorder; click to edit; right-click actions; no forms. On top, an “Up Next” card: the next character’s portrait, class color, faction banner and ruleset badge, then the step, the points it earns and the estimated time, so I see what to play at a glance. Original art only, nothing from Linear’s branding.
3. Add to the Q-G1 UI checks: portrait drawing for the live character; race/gender portrait icons and class icons for logged-out alts; faction emblems; how to read each character’s ruleset/realm type (game or DataStore), with evidence.
4. Before any window code, give me a static mockup of the window (both modes plus the Up Next card) for approval.
Merge #12: approved after the 8.5 fix and the design direction are added to section 8. Then update the handoff and tell me when to start a new session."
- Approved: the revised direction; **P2-4a** (planner, saved-data format 2 for the plan); **Q-G1** (UI checks in EmpireIntelCheck 0.1.9-tp1, built alongside P2-4a). **P2-4b** waits for Q-G1's results and the approved mockup.
- P3-2's saved summary becomes format 3.
- 8.5 corrected: a rested pool of R saves R of kill XP in full (rule L-17, sourced; unverified on Forever, with a no-code check). The "at half" text was wrong.
- Spelunker challenges are planned at any level. Zone Explorer timing stays open: the answer kept the template "[after 50 / other]".
- Design direction recorded in Phase2_Plan.md 8.3.1-8.3.5; the Q-G1 checks extended (portraits, race/gender and class icons, faction emblems, ruleset and realm type). Roster records gain race, sex, faction and ruleset in format 2. L-18: Hardcore points are kept apart.

## D-056 P2-4a and EmpireIntelCheck 0.1.9-tp1 build approved; Q-F3 answered; docs fixes | Approved (user, 2026-11-08)
The user's words: "Approved: start P2-4a and EmpireIntelCheck 0.1.9-tp1 (UI checks) as planned in Phase2_Plan.md section 8.
Q-F3: zone Explorer after 50, counting zones already explored on the way. Spelunker stays at any level.
Rules for this build:
No window code before I approve the static mockup.
Each package ends with its own package block (reload or restart, exact test steps, rollback, file and sha256).
The UI checks report evidence (what the game returned), not assumptions.
Docs fixes under the docs-only approval:
Note in the handoff that there is no S-054.
In NEXT_SESSION_PROMPT.md, state the REST merge command (D-050) as the one to use, so gh pr merge isn't read as current.
When #10 is next edited, change P3-2 to format 3.
Q-P3-2a comes later."
- Approved: building **P2-4a** (EmpireIntel, Phase2_Plan.md 8.1, 8.4-8.7, saved-data format 2) and **EmpireIntelCheck 0.1.9-tp1** (the UI checks of 8.3.4). Merging either still needs the user's approval.
- **No window code** (P2-4b) before the user approves the static mockup (8.3.5).
- Each package (EmpireIntel, EmpireIntelCheck) gets its own package block.
- The UI checks record what the game returned (values, types, errors), never an assumed result.
- **Q-F3 closed:** zone Explorer is planned after a character reaches 50; zones already explored before 50 count toward it. Spelunker challenges stay at any level. Rule L-11's timing changes from [assumed] to the user's rule.
- Docs: the handoff notes that there is no S-054; NEXT_SESSION_PROMPT.md names the REST merge command (D-050) as current. When #10 is next edited, its P3-2 is changed to saved-data format 3 (D-055).
- Q-P3-2a: later.

## D-057 P2-4a and EmpireIntelCheck 0.1.9-tp1 built | Claude (2026-11-08), within D-055 and D-056
Built on branch `p2-4a-planner`, not merged (merging needs the user's approval). Report: P2-4a_Report.md.
Choices made within the approved scope, each open to the user's change:
- **Editing "my plan" in chat:** P2-4a has no window (D-056), so mine mode is edited with `/ei plan mode | target | copy | top | remove | clear | ignore | unignore`. The window (P2-4b) will edit the same saved plan. `/ei plan` alone shows the settings (P2-4b may later open the window from it).
- **`/ei rules`:** prints the 18 rules with status and source (the window's "Rules: 18, 11 unverified (hover)" in chat).
- **Default costs (L-16, [assumed]):** XP per hour by band 12000 / 18000 / 24000 / 30000 / 38000 / 45000 (levels 1-9 ... 50-59); hours per skill point 0.02 / 0.03 / 0.04 / 0.06 (to 75 / 150 / 225 / 300); 0.75 h per dungeon run; 1 h per Explorer zone. Classic XP table (L-15), the measured bar where seen.
- **Learning a craft** is planned only for a character with known professions and a free primary slot (L-6).
- **Dungeon levels (L-8):** the lowest level used is Novice 13, Experienced 20, Master 35 [inherited classic].
- **Raids and Valthalak (L-10)** are not planned yet (no time model); the route says how many points of the target are left to unplanned content.
- **Explorer (L-11, D-056):** a step only for the played character at 50 or more, from the game's per-character zone steps (EI-E-27); for another character the route says so.
- **Measured XP rate (Q-F2):** within one login session, after 30 minutes and a level gained, XP gained per logged-in hour (idle time included, so cautious), averaged with the earlier value; saved as `{ xpPerHour, at }` exactly as format 2 shows. No new game call.
- **Ruleset (L-18):** the plan uses the played character's recorded ruleset; a character whose recorded ruleset differs is left out and counted; unknown stays in. Ruleset from `C_GameRules.IsHardcoreActive()` (documented, EI-E-11), preset from `GetForeverExperiencePreset()` (EI-E-09); race and sex from `UnitRace`, `UnitSex`. These are new calls in EmpireIntel, named in 8.3.4/8.7; 0.1.9-tp1 records what they return on Forever.
- **DataStore faction for alts** (8.7 "or faction from DataStore meanwhile") is **not** read: it needs a new DataStore getter beyond the approved list (P2-2). 0.1.9-tp1 records whether DataStore has the getter; P2-4b can ask.
- **The check's texture:** `EmpireIntelCheck/Media/Test.tga`, an 8x8 flat-colour file of our own, so "SetTexture with a file in the addon folder" is tested for real. `tools/build_package.py` now ships `Media/*.tga` (at most 64 KB each) and prints the full sha256.

## D-058 P2-4a live tests; merge of #14 approved after the findings were answered | Approved (user, 2026-11-08)
The user's words: "Tested 0.6.0 and 0.1.9-tp1 on Paladin and Priest; files attached. 0.6.0: schema 2 migrated; both records have race, faction and ruleset; plan copy, mode and ignore work (the Shaman is ignored). UI checks ran on both characters, ElvUI off on the Paladin run and on for the Priest run. Findings:
(1) Before the ignore, the route spent 6 of 20 steps on the stale Shaman. Check /ei next now.
(2) The route had "Priest 45" but no "Paladin 45", although the Paladin is 18 levels away and the Priest 39. Explain or fix.
(3) atlas raceicon-scourge-* returns nothing on both characters (both Undead). Find the right name, likely raceicon-undead-*.
(4) SetColorTexture, SetTexCoord and SetPortraitTexture report "nothing"; setters normally return nothing, so is that a real failure or a labelling issue?
Q-P2-4a-1: yes. Q-P2-4a-2: merge #14 after (2)-(4) are answered. Q-P2-4a-3: decide with the results."
- Q-P2-4a-1 **yes**: "my plan" is edited in chat until the window exists.
- Q-P2-4a-2: **merge #14** once findings 2-4 are answered; answered in P2-4a_Report.md section 6 (2: greedy next cost, not a fault; 3: the atlas token is `undead`; 4: labelling, two setters proven by read-back, SetColorTexture not yet). Merged by Claude.
- Q-P2-4a-3: **open**, decided with the results (EI-E-31: DataStore has `GetCharacterFaction`, `GetCharacterRace`, `GetCharacterGender`).
- Evidence EI-E-29..31. P2-4a stays open until the user closes it.

## D-059 Merge #14; ElvUI correction; next check version; DataStore faction; mockup next | Approved (user, 2026-11-08)
The user's words: "Answers (1)-(4) accepted. I've read them: merge #14 now with the REST command. If it's refused again, quote the exact command and the message. ElvUI correction: the off run exists. The file the reviewer read at 15:04 (Paladin run at 15:03) shows "ElvUI global" absent and counts 111 present / 6 nothing / 4 absent; my later ElvUI-on run overwrote it. Record that in EI-E-31. Check update: yes, label setters "ok, no return value" and read back SetColorTexture, in the next check version only. Don't build it now. Q-P2-4a-3: yes, DataStore's faction getter (read-only) so alts show a faction before their next login. Next: the static window mockup (P2-4b) for my approval, with no window code."
- Merge #14 now (REST command, D-050).
- EI-E-31 corrected: the ElvUI-off run exists (C1, 15:03): ElvUI global absent, 111 / 6 / 4.
- **Next check version (not built now):** setters labelled "ok, no return value"; a `SetColorTexture` read-back. (Also noted: keep the full UI result per character.)
- **Q-P2-4a-3 yes:** DataStore's `GetCharacterFaction` (read-only) is added to the bridge's approved getters, so alts show a faction before their next login. Built with P2-4b (it is used by the window).
- **Next:** the static window mockup (P2-4b, Phase2_Plan.md 8.3.5) for approval; no window code.

## D-060 P2-4a closed; window mockup approved; emblems, fonts, window size; plan P2-4b | Approved (user, 2026-11-08)
The user's words: "Merge #15 under the docs-only approval. Close P2-4a. Mockup:approved. Faction emblems: the game's own. Font: the game's built-in fonts, none shipped. Window: resizable, size and position remembered, moderate default. After I approve the mockup, plan the P2-4b build for my approval: files, reload or restart, tests, and the DataStore faction getter. No window code until then."
- #15 merged (72f4192) under the docs-only standing approval.
- **P2-4a closed.**
- **Mockup approved** (https://claude.ai/artifact/GrBwFsCBY7uZssod6mkLA1, private).
- Faction: the game's emblem atlases (`HordeEmblem`, `AllianceEmblem`, EI-E-30). Fonts: the game's built-in fonts; no font shipped. Window: resizable, size and position remembered, moderate default (proposed 560 x 420).
- P2-4b build plan written for approval: Phase2_Plan.md section 9 (Q-P2-4b-1..4). **No window code until it is approved.**

## D-061 P2-4b plan approved with one addition (the fill path); build as 0.7.0 | Approved (user, 2026-11-08, Q-P2-4b-1..4)
The user's words: "Q-P2-4b-1: yes, with one addition: SetColorTexture isn't proven on Forever (no read-back yet). Draw fills through one path in Theme or UI, test SetColorTexture with a read-back at window creation, and if it fails, fall back to SetTexture on our own white texture plus SetVertexColor (proven by 0.1.9's texture). Report which path ran, and cover both in tests. 2: yes. 3: yes. 4: yes. Merge #16 and build P2-4b as EmpireIntel 0.7.0. End with the package block and the 8-step live gate. I'll test with ElvUI on and off."
- Q-P2-4b-1..4 **yes**. Merge #16; build P2-4b as EmpireIntel 0.7.0 (Phase2_Plan.md section 9 plus 9.9).
- **Fill path (9.9):** every colour fill goes through one function in `Platform/UI.lua`. At window creation it tests `SetColorTexture` with a read-back; if that fails, fills use `SetTexture` on our own white texture plus `SetVertexColor`. The path that ran is reported; tests cover both.

## D-062 P2-4b built: EmpireIntel 0.7.0 | Claude (2026-11-08), within D-060 and D-061
Built on branch `p2-4b-window`, not merged. Report: P2-4b_Report.md. Choices within the approved plan, open to the user's change:
- **Position saved as TOPLEFT against the screen** (from `GetLeft`/`GetTop`): the game may re-anchor a moved frame to another corner and format 2 keeps no relative point, so this is what restores exactly.
- **The window draws at once** with "Reading Legacy challenges..." and updates when the read finishes; the window's reads print no chat line.
- **"Add a step after"** is two menu items (a level step, a skill step) with the next milestone as the target, edited in place afterwards; no form.
- **Status icons:** a step is "blocked by a gate" when it starts with levelling for a training gate or a dungeon's level; training alone is not a gate.
- **The compartment** shows our own mark (`Media/Mark.tga`); the minimap button and the window use the same mark.
- **Faction from DataStore** is shown as "(DataStore)" next to the emblem on the card.

## D-063 P2-4b live gate: partial pass; fix items 1-9 for a retest; plan items 10-11 for approval | User (2026-11-09)
The user's exact words (character names replaced: C2 the Priest, C1 the Paladin, C3 the ignored character, C4 the Druid):
"P2-4b live gate results (screenshots of both modes attached). Passed: 1 (/ei plan and minimap button), 4 (resize and persistence), 5 (ElvUI on and off, minimap placement), 7 (/ei alts). Don't merge #17. Fix items 1–9, rebuild for a retest, and plan items 10–11 for my approval (no code for those until I approve):
1. My plan prerequisites: every edit (move, Move to top, drag, add, edit target) must keep prerequisites. Example: Enchanting 150 can't move above "Priest level 10" (gate L-4). Block the move, or move the prerequisite with it, and say which.
2. Add a skill step after: adding after Enchanting 150 creates a second Enchanting 150; adding after Enchanting 225 creates Enchanting 150. Offer the next milestone (225 after 150, 300 after 225) and never duplicate an existing step.
3. Notes: the edit box draws over the step text, and the note vanishes after editing. Give notes their own space (a second line or a tooltip), with the edit box clear of the text.
4. Ignore and My plan: steps for an ignored character ([C3]) stayed in My plan. On ignore, mark or remove its steps there and tell me.
5. Target button: it cycles 2/3, 2/16, 2/15 with no label. Label it ("Next point 2/3", "Cap 2/16", "Next reward 2/15") and add a tooltip.
6. Ruleset badge: "Normal" means nothing to me. Show the realm type: PvE, PvP, RP-PvE, RP-PvP, or Hardcore later. Our realm name ends in "PvE"; report with evidence how the type can be read (game call, realm name or DataStore).
7. Faction emblem: a red square shows instead of the Horde emblem. Find out why and check against the 0.1.9 evidence.
8. Combat footer: "Legacy not read (in combat), counts inferred" stays after combat until I reopen. Refresh when combat ends.
9. Consistency: Experienced Spelunker shows "Account" in My plan and the Paladin in Fastest; use one. NOW shows today's value in My plan but the expected value at that step in Fastest; label the difference or use one meaning.
10. Profession choices and a setup wizard (plan first): I don't know where [C4]'s Alchemy came from (the Druid has Alchemy 0). The route must not assume a profession a character hasn't learned. Add a first-run setup wizard (like ElvUI's install) that asks for preferences: each character's intended professions (or "let the planner choose"), the target, which characters to include, and similar. Everything can be changed later, and the wizard can be rerun from the add-on's options. Until a profession is chosen or learned, show "choose a profession" or "learn Alchemy (planner's choice)", never a silent assumption.
11. Rested XP in the route (plan first):
a. Leveling time must use rested XP. A character with a full rested pool levels faster until the pool runs out, so its time estimate is lower. Use the confirmed rule: a pool of R saves R of kill XP.
b. The 105% cap issue: in all versions of WoW, rested XP stops at 105% of a level, not 150%, if a character stays logged out in an inn without logging in until 105% has built up (about 7 days). It isn't confirmed on Forever. Label it unverified, and give me a simple test once my alt roster is set up. The plan should add a step "log in and out on <character>" when a resting character reaches about 90% (about 6 days), so the pool keeps growing to 150%.
c. A character at or near 150% gets priority in the default route: level it through its rested pool so nothing is wasted, even if that isn't up to a Legacy milestone. This is the usual alt-cycling strategy, rotating through characters by rested state, to reach 60 account-wide faster.
Each fix gets a test. End with the package block and only the gate steps to repeat."
Consequences: #17 stays unmerged; items 1-9 built as EmpireIntel 0.7.1 on `p2-4b-window` (D-064, P2-4b_Report.md section 6); items 10-11 planned in Phase2_Plan.md section 10 (Q-P2-4c), no code. Only one screenshot (Fastest) reached the session; the second, sent as an image address, could not be opened (HTTP 403).

## D-064 P2-4b retest built: EmpireIntel 0.7.1 | Claude (2026-11-09), within D-063
Choices within the user's items, open to change:
- **Item 1:** the prerequisite is carried, not blocked, for moves (the level step goes up with a skill step; a level step moved down takes its dependents); removing or lowering a needed level step is refused; adding or raising a skill target adds the missing level step before it. Gates that were already open before an edit are left as they are (shown as a gate), so an edit never moves unrelated steps.
- **Item 3:** one edit bar below the rows for notes and targets; Enter or leaving the box saves, Escape cancels; the note is in the row tooltip with a "(note)" mark, and on the Up next card.
- **Item 4:** the steps are marked, not removed (kept, greyed, never up next); Unignore in the row menu.
- **Item 6:** the realm type comes from the end of the realm name [inferred]; no game call gives it (EI-E-31, EI-E-32).
- **Item 7:** the emblem is `Interface\TargetingFrame\UI-PVP-<faction>` (EI-E-30), cropped to its icon [inferred crop]; the atlas is the fallback.
- **Item 9:** "Account" in both modes (L-7: the progress is account-wide); NOW means today's value in both modes; the character column shows today's level.

## D-065 Finding 10 and duplicates fixed in 0.7.2; Q-P2-4c and Q-P2-4d approved with conditions; one retest | User (2026-11-09)
The user's exact words:
"Finding 10: fix now in 0.7.2: each My plan row counts from the end of the earlier steps for the same character and profession; a step already reached shows “covered by step n” with no time or points. Also remove saved duplicate steps automatically on load (keep the first) and say so in chat. I’ll retest once, on 0.7.2: steps 2, 3, 6 and 8.
Q-P2-4c: yes. c-1: yes (inside format 2). c-2: yes; nothing is planned for a free slot until I choose a profession or pick “planner’s choice” in the wizard. c-3: yes, gathering skills appear in the wizard, marked as earning no Legacy points.
Q-P2-4d: yes. d-1: no, keep the rested rule unverified until I do the /ei rested-kill check on Forever. d-2: yes. d-3: yes (1.4 levels, 0.90).
Build P2-4c and P2-4d only after P2-4b closes, one increment at a time."
Consequences: EmpireIntel 0.7.2 built on `p2-4b-window` (P2-4b_Report.md section 6). P2-4c and P2-4d are approved as planned (Phase2_Plan.md section 10) with these answers, and are not started: P2-4c begins only after P2-4b closes, P2-4d after P2-4c. L-17 stays unverified (the rested-kill check, README 0.6.0 step 8). Claude's choices within the words: the first copy of a repeated step keeps a later copy's note when it has none; a saved step with an unknown key is never removed as a repeat (it stays an UNEXPECTED line); the repeat check runs about 3 seconds after login or `/reload`, after the first snapshot, so the chat line can name the character; `/ei next` in chat still counts each of my plan's steps from today (finding 10 was about the window's rows).

## D-066 Retest 0.7.2: steps 2 and 3 fail; fixes for 0.7.3; plan items 5-7 | User (2026-11-09)
The user's exact words:
"Retest 0.7.2 (screenshots of both modes attached). The removed-repeat line appeared. Step 6 passes. Steps 2 and 3 fail; don’t merge #17. Fix in 0.7.3:
Prerequisite chain: moving a step up must move its whole chain ahead of it, in order. Moving Enchanting 225 to the top must put Level 10, Enchanting 150 and Level 20 before it, not leave them below as “covered”.
Notes: a row only shows “(note)”, and the only way to read the note is to edit it again. Show the note text on hover and on the card when that row is selected.
Card follows the selected row: clicking any row (any character) shows that character on the card: portrait or race/class icon, faction, realm type.
Faction emblem: still too small. Draw it at a fixed size that matches the PvE badge.
Each fix gets a test. End with the package block and only the gate steps to repeat.
Plan only, no code, for my approval:
5. All options in the window: /ei opens the window, and everything the /ei commands do (mode, target, copy, ignore and unignore, rules, minimap on/off, alts, legacy, version, setup) is reachable there, through a settings or options panel and the row menus. The commands can stay as shortcuts, but nobody should need them. Fold this into the P2-4c setup wizard and options plan if that fits.
6. Realistic leveling time (new increment): 9 hours for 6 to 20 isn’t realistic, even speedrunning. The estimate must adjust per character: its own measured XP per hour (Q-F2), its rested pool (P2-4d), the quests in its quest log with their expected XP, including travel time to and from objectives, and pure mob grinding for anything beyond the quest log. Report with evidence what the game gives about quests in the log (XP, objectives, locations), what Questie’s database could add read-only (and its license), and why live Wowhead lookups aren’t possible in game. Label every estimate.
7. Captured at login: confirm what is saved for each character the first time it logs in with EmpireIntel running (race, sex, class, faction, realm, professions, rested). Portraits can’t be saved, so offline alts use race/class icons. Say if anything else useful can be captured."
Consequences: #17 stays unmerged; 0.7.3 built (D-067); items 5-7 planned in Phase2_Plan.md section 11 (Q-P2-4c-4, Q-P2-4e, Q-P2-4f), no code.

## D-067 Retest build: EmpireIntel 0.7.3 | Claude (2026-11-09), within D-066
Choices within the user's words, open to change:
- **The chain** of a step is every step of the same character it builds on: for a level step the lower level steps; for a skill step the lower steps of the same profession and the level steps up to the one that opens the highest training gate. Moving up brings the chain ahead in progression order (level, then the skills it opens); moving down takes the steps that build on it along, after it. Chat: "Moved with it, in order: ...".
- **Selecting:** a left click selects a row (the card shows it, the row is highlighted); a click on the selected row in My plan edits its target (also "Edit target" in the menu); clicking the card goes back to Up next; switching the mode clears the selection. An account row (dungeon challenge) shows "account-wide" with no badge.
- **Notes on hover:** row tooltips now open at the mouse pointer (ANCHOR_CURSOR). Inferred cause of the user's finding: the tooltip opened to the right of the full-width row, which can be off screen.
- **Size:** the badge is a fixed 22 px pill; the emblem texture is 28 px so its disc (about 0.77 of it, measured on the 0.7.2 screenshot [inferred]) is about 22 px.

## D-068 Standing order: third-party add-ons (copy and credit, clean room, optional plugins, cross-checks) | User (2026-11-14), standing order
The user's exact words: "New standing order (record with my words in CODE_STANDING_ORDERS.md, NEXT_SESSION_PROMPT.md and Decisions): We can copy and credit where it’s allowed. Where copying isn’t allowed and it’s a core function of what we’re trying to build, do the clean room thing. We can use addons to check our work too. Where it makes sense we will have some things be optional plugins and note that some features will be better if these addons are installed but our addon will still work without them."
"What this means in practice:
1. Copy and credit only from MIT or CC BY sources (for example Sharpie’s Gear Judge and its XP and Roster plugins, and pfQuest), with notices in THIRD_PARTY.md and file headers.
2. Clean room for GPL or All Rights Reserved sources (Polestar, LibForeverData, Altoholic and DataStore, Questie, ForeverXP Bar, Forever Planner, Profession Planner): you get hint notes from me (game functions, events, pitfalls, behaviour), never their code. Write your own version and record “approach informed by <add-on>, no code copied”. Never copy data tables.
3. Optional plugins: read another add-on’s data while the game runs only when it’s offered for that (LibForeverData, Auctionator’s interface). Every feature must work without it, and the window says which add-ons improve which features.
4. Cross-checks: use installed add-ons to check our numbers in live tests (ForeverXP Bar for XP per hour and time to level, Profession Planner for profession steps)."
Recorded in CODE_STANDING_ORDERS.md section 8 (with how Claude applies it) and NEXT_SESSION_PROMPT.md. **Supersedes D-003 in part:** copying with credit is now allowed from MIT and CC BY sources; D-003 stands for DataStore and Altoholic (All Rights Reserved). Project_Bible.md section 6 updated to match. THIRD_PARTY.md created (empty list). Licenses named by the user are confirmed from each source's own license file before anything is copied.

## D-069 Plan inputs for P2-4c, P2-4d, P2-4e and Q-P2-4f; answers to section 11.4 | User (2026-11-14)
The user's exact words:
"Plan inputs (no code):
* P2-4e: quest data from LibForeverData as an optional plugin, with pfQuest (MIT) as the bundled fallback. Quest XP uses the game’s quest-XP function, which Sharpie’s XP plugin (MIT) uses on Forever, so keep the 0.1.10 check short. Reuse Sharpie’s XP-per-hour and time-to-level code with credit.
* P2-4d: add Forever’s campfire buff (“Camp Benefits”) and sleeping-bag buff (“Well Rested”) as rested rules, labelled unverified.
* P2-4c and Q-P2-4f: from Sharpie’s Roster (MIT), flag characters not seen for 7 days or that need a login after an update, and show gold per character and the total. Capture played time with the game’s own request, plus gold, hearthstone location and zone, at login and on change, never during logout (EI-E-08). Prove with a test and a live step that everything works with DataStore and Altoholic disabled. The setup wizard tells me to log in once on each character.
* Section 11.4 answers: Q-P2-4c-4: yes. Q-P2-4c-5: two (0.8.0, then 0.8.1). Q-P2-4e: yes. e-1: Questie read only, nothing copied, and works without it. e-2: decide after the check. Q-P2-4f: yes, played time first.
I’ll install and retest 0.7.3 next. Start nothing new until P2-4b closes."
Also from the user's reviewer notes on the saved files: "Measured XP per hour now exists for 7 of 8 characters; use it in estimates. EmpireIntelCheck’s saved file is 232 KB against its 256 KB cap and marked truncated; trim it or plan a fix."
Consequences: Phase2_Plan.md 1.9.0 sections 10 and 11 updated (plan only). Nothing started. Two points need the user (Phase2_Plan.md 11.6): e-1 (reading Questie) conflicts with D-068 point 3, and pfQuest's bundled database comes from VMaNGOS (GPL v2), not only from pfQuest's MIT code.

## D-070 Retest 0.7.3: step 2 passed, step 3 partial; fixes 1, 2 and 4 in 0.7.4; Q-D068-1 and Q-D068-2 answered | User (2026-11-14)
The user's exact words (character names replaced: the Hunter, the Priest):
"Retest 0.7.3: step 2 pass; step 3 partial; step 8 screenshots attached (files after logout).
Each Legacy milestone is its own row. My plan shows “Alchemy 225” as +2 and hides Alchemy 150. Show 150, 225 and 300 as separate rows and steps (the Hunter is missing his 150 rows). Moving a 225 row up must bring the 150 row above it.
Points mismatch: the Hunter’s “Learn Alchemy, 0 → 225” shows +1 in Fastest but +2 in My plan.
The Priest’s Enchanting 225 wasn’t in my copied plan because the target is next reward (15). Not a bug, but I need a way to add any milestone row from the window (P2-4c options).
Emblems: make the faction emblem about the same size as the character portrait on the card.
The route assigns the Hunter both Alchemy and Blacksmithing although he has no professions. That’s P2-4c (setup wizard); confirm it’s covered.
Q-D068-1: yes, drop the Questie read. Q-D068-2: bundle no quest data; read LibForeverData while the game runs as an optional plugin, and pfQuest the same way if installed; with neither, estimates use grinding only, labelled. Fix 1, 2 and 4 in 0.7.4; don’t merge #17 yet."
Consequences: 0.7.4 built (P2-4b_Report.md section 6); #17 not merged. P2-4c gains "add any milestone row" (Phase2_Plan.md 10.2); the Hunter's two assumed crafts are covered by P2-4c's rule (10.2 points 1-2, c-2: nothing planned for a free slot until chosen). P2-4e: no Questie read, no bundled quest data; LibForeverData and an installed pfQuest read at run time as optional plugins; with neither, grinding only, labelled (Phase2_Plan.md 11.6).
Claude's choices within the words: a route step that passes several milestones becomes one step per milestone, each with its own training gate and its share of the time (exact: level time as differences from the same start); a milestone row the account already has, or that an earlier step earns, shows no point and says why; My plan counts points once per account in plan order (class per class, craft per craft, L-2, L-3), starting from the account's earned milestones (the game's Legacy read, else inferred), as Fastest does; saved plans get the missing milestone rows at login or `/reload` (chat names them), and a raised target gets its new milestone rows; the emblem's disc is about the portrait's 52 px (texture 66 px), level with the portrait, the badge to its left, the card title kept clear of it.

## D-071 Standing permissions for each session (pasted at the start of every session) | User (2026-11-14), standing
The user's exact words: "Standing permissions from me, for this whole session: you may edit code and docs, run tests, build packages, commit, and push to work branches without asking (never push to main, never force-push, never change permission settings files). When I approve an increment, fix or merge in this chat, that is my explicit approval to do it, including merging that pull request yourself with the REST merge command. Docs-only pull requests (Session_Handoff, NEXT_SESSION_PROMPT, CODE_STANDING_ORDERS, Decisions, TODO, Changelog) you may merge yourself under my standing approval. Add this paragraph, word for word, to the top of NEXT_SESSION_PROMPT.md as text I paste at the start of every session, and record it as a decision."
Recorded: the paragraph is the first paragraph of NEXT_SESSION_PROMPT.md, word for word. It restates D-049, D-050 and D-051 (merge only after approval in chat, the REST merge command, the docs-only standing approval) and adds: no push to main, no force-push, no change to permission settings files. Gates are unchanged: a new increment, a fix or a merge still needs the user's approval in chat (CODE_STANDING_ORDERS.md section 2).

## D-072 Documents brought up to date | User (2026-11-16)
The user's exact words: "Can you clean up the docs, I see some outdated stuff in them. For example it's not multi AI, it's just Claude. And some docs read like it's prelaunch and the game is launched. Just in general there is a bunch of outdated information that should be updated to reflect current reality"
Done (S-068), with no change of scope or of any decision:
- **Project_Bible.md 2.0.0:** roles are the user and Claude only (the multi-AI contract and external-review intake removed); session continuity for Claude Code sessions; reading order starts with CODE_STANDING_ORDERS.md; governance points to the standing orders (D-049, D-050, D-051, D-071); the third-party rule is D-068; the inventory separates living documents from records.
- **Architecture.md 3.0.0:** the design as built (layers, modules, saved-data format 2, the route, My plan, invariants, tests); the pre-launch design (v2.x) is left to the reports and git history.
- **Requirements_v1.md 2.0.0:** restates the requirements as the user decided them: the route planner, the saved plan and the window (D-054, D-055, D-060) replace the plan file and "no windows"; FR-LEG-2 waits for Q-T4; the pre-launch assumptions settled. This is the user's decision to update the requirements to current reality; it adds no scope.
- **Risk_Register.md 2.0.0:** closed risks moved to a closed list with their outcome; new R-21 (levelling estimates), R-22 (the check's file size), R-23 (third-party licenses), R-24 (other UI add-ons).
- **Compatibility_Notes.md 2.0.0:** the client profile from launch evidence; the pre-launch web summaries kept with how each turned out; EI-E-33 (build 70938).
- **Other updates:** README.md and CONTRIBUTING.md (current status, owner plus Claude, D-068); CODE_STANDING_ORDERS.md 1.3.0 (roles; D-071 in section 2; Q-T4 wording); NEXT_SESSION_PROMPT.md step 5 matches D-071; Legacy_Rules.md, Phase2_Plan.md, Phase3_Legacy_Plan.md and Release_Pipeline.md status lines; the two 2026-11-03 reviews marked as historical records; the bug-report template no longer says "public repository"; the empty `reviews/` folder removed (no review was ever stored).
- **Not changed:** Decisions.md and Changelog.md history (append-only), older handoff sections, and the phase reports (records).

## D-073 Build 71037 realm evidence recorded; realm-identity plan requested | User (2026-11-20)
The user's exact words (character names left out; C3 is the ignored beta character):
"Retest 0.7.4: the saved file shows [the Hunter]’s order Level 25 → Alchemy 150 → Alchemy 225 at the top, and the 150 rows above the 225 rows. Emblem and +1: [OK / issue]. Merge #17 and close P2-4b: [yes/no].
New evidence, record as EI-E entries:
1. Client build 1.60.1/71037 (dated Nov 18) returns “” from GetRealmName() and GetNormalizedRealmName(). EmpireIntelCheck caught it on [a Horde Warrior] (ds_guid_key_mismatch, ds_duplicate_guid). It may be a deliberate Blizzard change, not a bug, so don’t assume it will be fixed.
2. DataStore broke. It created blank-realm keys (“Default..Name”): duplicates for [two characters], and the only entry for characters created since. Altoholic showed only the current character until I added a workaround. Our roster was unaffected because Unit.lua drops empty realms and we identify characters by GUID.
3. Each realm has its own GUID server number: 6796 = CAMWOW US2 Realm 1 PvE, 6800 = PvP realm, 6928 = RP realm, 6935 = RP-PvP realm. 6933 was the Realm 7 PvE beta realm and no longer exists ([C3] is a leftover beta character). I created level-1 test characters [three, on 6800, 6928 and 6935]. All three have realm = nil and ruleset = “normal” in our roster, so the realm-type badge can’t tell them apart. No Hardcore realm is available yet.
4. Workaround installed, not part of our repo: a local addon “!RealmFix” 2.0 that loads before DataStore. When the game returns “”, it supplies the realm name from the GUID server number using a learned map, and leaves unknown numbers blank. It saves a log to RealmFixDB. While it’s installed, GetRealmName() returns the filled-in name for 6796, so EmpireIntelCheck no longer sees the raw “” on that realm. Treat realm values seen with the shim installed accordingly. EmpireIntel must not depend on the shim.
Propose, plan only, don’t build until I approve:
(a) Realm identity by GUID server number, with name and ruleset as labels learned whenever the game gives a name. Characters on an unknown server number show as “Unknown realm (number)”, never merged with other realms. Let me label an unknown realm once in the GUI. Rulesets aren’t unique, so don’t group by ruleset; show it as a label. Hardcore still comes from C_GameRules.
(b) How the plan, the Legacy points and the roster should treat test characters and characters on other realms: option to ignore them, and whether Legacy points are per account or per realm.
(c) The planned 0.1.10 trim of EmpireIntelCheck. Its file was at 248 KB of 256 KB and already dropping data."
Consequences: EI-E-34..38 recorded (EI-E-38: the race file "Skyborne", seen in the same file). Plan in Phase2_Plan.md section 12 (Q-R, Q-R-1..5), no code. **Not done:** the merge of #17 and closing P2-4b: the message kept the template placeholders "[OK / issue]" and "[yes/no]", so neither is approved yet. The 0.7.4 retest result recorded from the saved file: the Hunter's order and the 150-above-225 rows are as fixed [file].

## D-074 Repository public on purpose; Legacy points account-wide across normal realms; Hardcore its own pool; Skyborne by faction | User (2026-11-20)
The user's exact words:
"Repository: public is intended for now (my decision). Push. Update CODE_STANDING_ORDERS section 7 to say the repo is public on purpose, and keep checking every push for character names, GUIDs and account names. Docs-only, under standing approval."
"Cross-realm test: Legacy points are account-wide. My PvP-realm character shows the same points as my main realm. Record that.
Blizzard has stated this will not be the case for the Hardcore ruleset when it opens: Hardcore will have its own Legacy points. Record that as my statement, not tested yet. Plan for it: points account-wide across normal realms (PvE, PvP, RP, RP-PvP), and separate for Hardcore. Treat Hardcore as a separate points pool in the route and in Fastest/My plan."
"Skyborne (EI-E-38): Skyborne can be either faction. Horde Skyborne are the Windshaper, Alliance Skyborne are the High Order. [A Horde Druid] is a Horde Skyborne. The roster already records faction from UnitFactionGroup, so choose the race icon and label by race + faction: Skyborne + Horde = Windshaper, Skyborne + Alliance = High Order. Fall back to the class icon only when faction is unknown (e.g. a DataStore-only alt with no faction). Add this to the plan; it’s small, so it can go with P2-4r or the next UI increment."
(The message also kept the placeholders "Emblem and +1: [OK / issue: …]. Merge #17 and close P2-4b: [yes/no]."; neither is answered, so #17 stays unmerged and P2-4b open. A character name is replaced by its role.)
Consequences: CODE_STANDING_ORDERS.md section 7 (1.4.0), Project_Bible.md section 7 and R-09: the repository is public on purpose; every push is checked for character names, GUIDs and account names. EI-E-38 updated, EI-E-39 (account-wide across normal realms, the user's test) and EI-E-40 (Hardcore's own pool, the user's report of Blizzard's statement, untested). Phase2_Plan.md 12.2 (two pools: normal realms and Hardcore; new rule L-19 confirmed; L-18 sourced to the user's report, still unverified), 12.2b (Skyborne: Windshaper for Horde, High Order for Alliance; class icon when the faction is unknown), 12.3 (the check lists the Skyborne atlases). Q-R-5 answered by the test; Q-R-6 added.

## D-075 Emblem and +1 accepted; Q-R answers; route rules R-1..R-7 for the Fastest route | User (2026-11-20)
The user's exact words (character names replaced by roles):
"Emblem and +1: OK (emblem about portrait size; [the Hunter]’s Alchemy 225 shows +1 in both Fastest and My plan).
Merge #17 and close P2-4b: not yet. Wait until you’ve answered the route problems below and I’ve decided whether they’re fixed in P2-4b first.
Q-R: yes. Q-R-1: yes. Q-R-2: add the command. Q-R-3: yes, with a confirmation. Q-R-4: yes. Q-R-6: yes, once a Hardcore realm exists.
For P2-4r testing: I need a way to show any character’s card even when they have no plan steps (e.g. [the Skyborne Druid], my only Skyborne, who is too far down to earn a point before the milestones are done). Add that to the P2-4r test steps, for example a click on a character in /ei alts or a character picker on the card.
Fastest route problems (screenshot attached). Treat these as rules; record them and fix them in the route:
1. Never assume a profession will be learned. If no character has a profession, don’t plan “Learn X, 0 → 150” steps for it. [The Hunter] has no professions, so he shouldn’t get Alchemy or Blacksmithing steps at all.
2. Same profession on several characters: the highest skill is the path. Blacksmithing → [the Horde Warrior] (51), Enchanting → [the Priest] (47), Alchemy → [the Druid] (82), Leatherworking → [the Horde Rogue] (69, not [the Alliance Rogue] at 44), Engineering → [the Shaman] (1, not [the Horde Warrior] learning it). That character takes every milestone of that profession (150 and 225), unless it can’t reach the level needed. If so, show it rather than silently switching characters.
3. Tailoring is missing. [The Priest] has Tailoring 150/150, so his Tailoring 225 should be in the route.
4. [The RP-PvP test character] shouldn’t be in the route. Exclude him until Forget/ignore exists (Q-R-3).
5. Up next isn’t in the table ([the Paladin], Experienced Spelunker). Make it row 1, or say it’s shown separately.
6. Targets: 15 is the next reward, but 16 is the current per-character cap, and more than 16 can be earned. Plan up to the cap by default, and let me track beyond it. Don’t hard-code 15 or 16.
7. Rows with no point that unlock a later point should say so (“prerequisite for step n”).
Question: does Fastest pick the fastest character itself, or follow My plan’s assignments? [The Hunter] got Alchemy 225 and Blacksmithing 225 in Fastest even though he has no professions.
Fold these into the plan, and propose whether they go into P2-4b as a fix before closing, or into the next increment. Don’t build until I approve. Order after that stays as agreed: close P2-4b → EmpireIntelCheck 0.1.10 trim → P2-4r."
Consequences: emblem and the +1 match accepted (0.7.4); #17 not merged, P2-4b not closed ("not yet"). Q-R, Q-R-1, Q-R-3 (with a confirmation), Q-R-4 approved; Q-R-2: the `/ei realm` command; Q-R-6 yes once a Hardcore realm exists. P2-4r gains a character picker on the card for testing (Phase2_Plan.md 12.5). The seven route rules recorded as planner rules R-1..R-7 and planned in Phase2_Plan.md section 13, with the question answered there (Fastest picks characters itself; it never reads My plan). No code until approved.

## D-076 Route rules built as 0.7.5; prompt on main; personal-data scan | User (2026-11-20)
The user's exact words (character names replaced by roles):
"Q-R7: yes. Build 0.7.5 with R-1, R-2, R-3, R-5 and R-7 before closing P2-4b; R-6 in P2-4c (move the 16 into the rules table in 0.7.5). Q-R7-a: yes. Q-R7-b: only on a character I picked; the planner may suggest one, but doesn’t plan it until I pick. I’ve ignored my test characters.
Also, before building: put the standing-permissions paragraph at the top of NEXT_SESSION_PROMPT.md on main now, with a prompt-only docs PR under standing approval, so a new session started from main has it before #17 merges. And check the repo for the same kinds of personal data GoldIntel found (Battle.net account folder number, character GUIDs) and list what you find; don’t scrub until I approve.
Send 0.7.5 with the package block and test steps, including a check that Tailoring 225 now appears on [the Priest] and that [the Hunter] has no profession steps."
Done: #18 (prompt only, the D-071 paragraph at the top of NEXT_SESSION_PROMPT.md on main) merged under the docs-only standing approval (70f8062; 408 tests on main under Lua 5.1 and 5.3); main merged back into `p2-4b-window` (the prompt conflict kept the branch's fuller prompt). The personal-data scan of every branch's history found nothing of the GoldIntel kinds (Session_Handoff S-072 lists what it found); nothing scrubbed. EmpireIntel 0.7.5 built with R-1, R-2 (tie-break as Q-R7-a), R-3, R-5, R-7 and the cap in the rules table (P2-4b_Report.md section 6). Q-R7-b recorded for P2-4c (Phase2_Plan.md 13.4). **R-3 as built:** the Priest's Tailoring 225 is a planned step on him, but at about 19 h it follows cheaper points: in a replay of the user's saved file it is step 16, so it shows at a target of about 20, not at 15 or 16 [inferred, offline replay].

## D-077 0.7.5 passed; #17 merged; P2-4b closed; scan left as is; next the check's trim, then P2-4r; the target box redesign for P2-4c | User (2026-11-21)
The user's exact words (character names replaced by roles):
"0.7.5: steps 2, 3, 4, 5 pass. Test characters ignored (4 ignored, including the old beta character). /ei next shows the same route (17 steps to 20, ~178 h): [the Hunter] has only Level 25; Leatherworking is on [the Horde Rogue], Blacksmithing on [the Warrior], Engineering on [the Shaman], Alchemy on [the Druid], Enchanting on [the Priest]; no “Learn” steps; Tailoring is in the later steps.
Merge #17 and close P2-4b: yes. Scan findings: leave as is. Next: EmpireIntelCheck 0.1.10 trim, then P2-4r, as agreed.
For P2-4c (with R-6): the top-right box changes the target when clicked, but nothing shows it’s a button, and I’ve wondered more than once what its numbers mean. Split it into (1) plain progress text, e.g. “Legacy points: 3 · next reward at 15 (Air Rifle)”, and (2) a control that looks like a button or dropdown, e.g. “Plan to: Cap (16) ▾”, with a tooltip: “The route plans steps until this many points.” Propose the design in the P2-4c plan."
Consequences: P2-4b **closed** (EmpireIntel 0.7.5); #17 merged through the REST command (D-050). The scan findings stay as they are. Next, in order: EmpireIntelCheck 0.1.10-tp1 (the trim with realm and Skyborne probes, Phase2_Plan.md 12.3, approved as Q-R-4), then P2-4r (section 12), then P2-4c (with R-6 and the target box design, 10.4). Rule R-4 is met by the user ignoring the test characters.

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
