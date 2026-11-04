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
| Q-9 | Allow web hosts to check the Legacy rules | The user allowed all domains, but this session still could not resolve worldofwarcraft.blizzard.com or forg.gg. The setting probably applies to new sessions only. Rules stay unverified |
