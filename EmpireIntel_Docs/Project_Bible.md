# EmpireIntel Project Bible

DOC VERSION: 1.2.0  |  DATE: 2026-11-08 (S-041)  |  PROJECT VERSION: 0.0.0-planning  |  STATUS: Active

> Read this file first. If another project document conflicts with it on governance, this file wins. On client facts, Compatibility_Notes.md wins. These rules are adopted from GoldIntel's Project Bible (v1.0.0, D-032 roles), which has worked through GoldIntel Phases 0 to 3b.

## 1. What EmpireIntel is

An addon for **World of Warcraft: Forever** (client 1.60.x, Interface 16001; launch 2026-11-04) that tracks the **Legacy system** across a player's characters. It covers Legacy points and challenges, perks spent per character against the cap, rested XP and professions. A "what next" list is driven by a plan file the user writes. DataStore is an optional source for alt data. Scope: Requirements_v1.md (D-010).

"Legacy" in this project always means the Forever Legacy points system. Old WoW APIs are called "pre-modern".

Sibling project: GoldIntel (gold income analytics). EmpireIntel reuses GoldIntel's platform layer, harness and evidence.

## 2. Roles and review model

| Role | Holder | Responsibilities |
|---|---|---|
| Project sponsor, project manager, client tester, final decision authority | User | Approves phases and decisions; runs the real client; resolves disagreements |
| Lead architect and developer | Claude | Source of truth for requirements, contracts, code, changelogs, architecture and governance documents |
| Independent reviewers (ChatGPT, Gemini, others) | Advisors | Advise; do not implement; cannot approve a gate |

External review intake follows GoldIntel's rules. Every finding gets a verdict (accepted, rejected or partially accepted) with a technical justification. A claim that cannot be verified becomes a probe, a risk or a question, never a design change. Review documents are stored unedited in `reviews/` and logged in `reviews/External_Review_Log.md` once the first one arrives.

## 3. Multi-AI collaboration contract

Any session can end at any time. Every AI must:
1. Assume nothing that is not in these documents or the user's message.
2. Read the documents in section 4 order before working.
3. State assumptions and record them (Decisions.md, or the open questions list).
4. End every session with a handoff entry at the top of Session_Handoff.md, and update Changelog.md and TODO.md.
5. Leave no hidden state in a conversation.

## 4. Mandatory reading order

1. Project_Bible.md  2. Requirements_v1.md  3. Decisions.md  4. TODO.md  5. latest Session_Handoff.md  6. Architecture.md  7. Compatibility_Notes.md  8. Risk_Register.md  9. GoldIntel_Reuse_Audit.md and Reference_DataStore_Altoholic.md

| Conflict | Winner |
|---|---|
| Requirements_v1.md vs any design | Requirements_v1.md |
| Decisions.md vs Architecture.md | Decisions.md |
| Compatibility_Notes.md vs Architecture.md on a client fact | Compatibility_Notes.md |
| Newer handoff vs older | Newer |
| Anything vs a direct, dated instruction from the user | The user (record it as a decision) |
| External review vs existing documents | Existing documents, until the finding is accepted |

A conflict the table cannot settle: stop, list it under OPEN ISSUES in the handoff, ask the user.

## 5. Governance rules

**Working rules (the user, 2026-11-03, D-015):**
- **Lean scope.** Build only what Requirements_v1.md asks for.
- **Surface unexpected conditions visibly:** in the addon (a chat line starting `UNEXPECTED` plus a saved record) and in every report to the user.
- **Every package states** whether a `/reload` is enough or a **full client restart** is required, and comes with **exact step-by-step test instructions**.
  - *Restart rule (D-034, D-040; supersedes "new addon folder or TOC change = restart"):* new or changed files inside an existing addon folder load on `/reload` (EI-E-19). A first install of a new addon folder still says full restart until it is seen to work with `/reload`. TOC header changes shown in the AddOns list (such as the version label) refresh only at start; harmless.
- **Passive collection.** The user plays normally; Claude reads the SavedVariables the user sends after `/reload` or logout. No required in-game commands, except an explicitly optional step.
- **Stop for the user's approval before writing code,** and at every phase gate.

- **Planning is not implementation.** No addon code is written until TODO.md names a phase as approved for implementation. As of 2026-11-03 **no phase is approved for code**.
- One verified step at a time: each phase closes on live evidence and the user's approval before the next starts.
- A change to architecture needs, in order: why; affected modules; migration (saved variables, contracts, tests); a Decisions.md entry; the user's approval where scope or a phase changes.
- Decisions.md is append-only (supersede, never delete). Changelog.md is append-only. TODO.md is updated every session.
- Do not expand scope beyond the current phase.

## 6. Evidence discipline

- Every client fact carries a tag: **[file]** (in an evidence file), **[reported]** (the user said so), **[inferred]**, **[assumed]**, or **[inherited]** (measured by GoldIntel, cited by its E-id).
- Evidence files from the client are dated and kept **outside the public repository** (see section 7). The Compatibility_Notes ledger records each with an id `EI-E-nn`.
- Third-party add-ons (D-068, standing order): copy and credit only from MIT or CC BY sources (THIRD_PARTY.md, file headers); clean room for GPL or All Rights Reserved sources (hint notes only, never their code or data tables); other add-ons' data read at run time only where offered for that, always optional; installed add-ons used to cross-check our numbers in live tests. DataStore and Altoholic: run-time public functions only (D-003).

## 7. Repository hygiene (D-007)

The user made the repository private on 2026-11-03 (GitHub still showed it public at the time of writing; see Decisions Q-2). These rules stay as defaults anyway. Never commit SavedVariables, WTF folders, chat logs, screenshots with names, character names, GUIDs, account names or balances. Fixtures are synthetic or anonymized (names replaced, GUIDs rewritten, money rounded). `.gitignore` enforces the folder rules; review enforces the rest.

## 8. Design principles (ordered)

1. Correctness: unknown is shown as unknown, never 0.
2. Provenance and freshness on every value.
3. Third-party data is optional; degrade, never crash.
4. Boundaries: WoW API only in `Platform/`; third-party addons only in `Bridge/`.
5. Testability: pure-Lua engines, offline tests, recorded fixtures.
6. Performance: handlers only enqueue.
7. Lua 5.1, modern API only, ASCII files (GoldIntel rules C-1..C-6).
8. AI-to-AI transferability and explicit assumptions.

## 9. Glossary

| Term | Meaning |
|---|---|
| Empire | All characters of one WoW account as seen by EmpireIntel |
| Roster | The per-GUID character records |
| Source | Where a value came from: `self` (EmpireIntel's own snapshot) or `datastore` |
| asOf | Time the source last observed the value |
| Bridge | The only layer allowed to call third-party addons |
| TP-n | Test Package n: a throwaway, read-only, passive in-client check that gates design choices |
| Legacy | The Forever account-wide points system: challenges earn points, perks spend them per character up to a cap |
| Estimate | A value computed by EmpireIntel's rules, not read from the client; always labelled |

## 10. Document inventory

| File | Purpose | Rule |
|---|---|---|
| Project_Bible.md | Governance | Changed only by user decision |
| Requirements_v1.md | What v1 must do | Changed only by user decision |
| Decisions.md | Decisions and open questions | Append-only |
| TODO.md | Phases, current phase, tasks | Every session |
| Session_Handoff.md | State transfer | Newest at top |
| Changelog.md | Changes to the repository | Append-only |
| Architecture.md | v1 design | Must agree with Decisions.md |
| Compatibility_Notes.md | Client facts with evidence tags | Wins on client facts |
| Risk_Register.md | Risks | Reviewed at every gate |
| GoldIntel_Reuse_Audit.md | What is reused from GoldIntel and how | Update when code is ported |
| Reference_DataStore_Altoholic.md | Source review of the alt-data providers | Update per DataStore release that matters |
| Phase2_Plan.md | Phase 2 increments and saved-data format 1 | One approval per increment |
| Release_Pipeline.md | Release, install and rollback design | Changes need the user's approval (pipeline code rule) |
| reviews/ | External reviews and their log | Documents stored unedited |
