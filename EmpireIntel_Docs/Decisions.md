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

---

## Open questions for the user

| ID | Question | Recommendation |
|---|---|---|
| Q-1 | Is the v1 scope in Architecture section 1 right (account roster, gold and item totals, mail expiry, commands only)? | Confirm, or tell me what EmpireIntel is for |
| Q-2 | Copying GoldIntel code here publishes code that is private today. OK? | Yes for Platform/Core/Store/tests (generic, already MIT); keep Collect/Ledger private |
| Q-3 | Approve Architecture v1 and authorize Phase 1 (TP-1 code only)? | Yes |
| Q-4 | Run TP-1 on the launch build (2026-11-04 or later) rather than the beta? | Yes: launch may change realm and API |
| Q-5 | Should EmpireIntel later read GoldIntel's results (per-character income) when both are installed? | Defer to after Phase 4 |
| Q-6 | Where is the "goldintel-addon memory"? If it is a claude.ai project memory, please paste it so D-002 can be checked against it | — |
