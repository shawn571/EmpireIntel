# EmpireIntel Project Bible

DOC VERSION: 1.0.0  |  DATE: 2026-11-03  |  PROJECT VERSION: 0.0.0-planning  |  STATUS: Active

> Read this file first. If another project document conflicts with it on governance, this file wins. On client facts, Compatibility_Notes.md wins. These rules are adopted from GoldIntel's Project Bible (v1.0.0, D-032 roles), which has worked through GoldIntel Phases 0 to 3b.

## 1. What EmpireIntel is

An account-wide intelligence addon for **World of Warcraft: Forever** (client 1.60.x, Interface 16001; launch 2026-11-04). It shows all of a player's characters together: gold, items, mail expiry, and how fresh each number is. Alt data comes from DataStore when installed, and from EmpireIntel's own per-character snapshots otherwise. Scope v1 is in Architecture.md section 1 and is an assumption until the user confirms it (Q-1).

Sibling project: GoldIntel (gold income analytics, private). EmpireIntel reuses GoldIntel's platform layer and evidence and does not duplicate its ledgers.

## 2. Roles and review model

| Role | Holder | Responsibilities |
|---|---|---|
| Project sponsor, project manager, client tester, final decision authority | User | Approves phases and decisions; runs the real client; resolves disagreements |
| Lead architect and developer; owner of architecture, contracts, code, changelog and governance documents | Claude | Source of truth for project artifacts |
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

1. Project_Bible.md  2. Decisions.md  3. TODO.md  4. latest Session_Handoff.md  5. Architecture.md  6. Compatibility_Notes.md  7. Risk_Register.md  8. GoldIntel_Reuse_Audit.md and Reference_DataStore_Altoholic.md

| Conflict | Winner |
|---|---|
| Decisions.md vs Architecture.md | Decisions.md |
| Compatibility_Notes.md vs Architecture.md on a client fact | Compatibility_Notes.md |
| Newer handoff vs older | Newer |
| Anything vs a direct, dated instruction from the user | The user (record it as a decision) |
| External review vs existing documents | Existing documents, until the finding is accepted |

A conflict the table cannot settle: stop, list it under OPEN ISSUES in the handoff, ask the user.

## 5. Governance rules

- **Planning is not implementation.** No addon code is written until TODO.md names a phase as approved for implementation. As of 2026-11-03 **no phase is approved for code**.
- One verified step at a time: each phase closes on live evidence and the user's approval before the next starts.
- A change to architecture needs, in order: why; affected modules; migration (saved variables, contracts, tests); a Decisions.md entry; the user's approval where scope or a phase changes.
- Decisions.md is append-only (supersede, never delete). Changelog.md is append-only. TODO.md is updated every session.
- Do not expand scope beyond the current phase.

## 6. Evidence discipline

- Every client fact carries a tag: **[file]** (in an evidence file), **[reported]** (the user said so), **[inferred]**, **[assumed]**, or **[inherited]** (measured by GoldIntel, cited by its E-id).
- Evidence files from the client are dated and kept **outside the public repository** (see section 7). The Compatibility_Notes ledger records each with an id `EI-E-nn`.
- Third-party addon source is read for behavior only. It is never copied (D-003).

## 7. Public repository hygiene (D-007)

The repository is public. Never commit SavedVariables, WTF folders, chat logs, screenshots with names, character names, GUIDs, account names or balances. Fixtures are synthetic or anonymized (names replaced, GUIDs rewritten, money rounded). `.gitignore` enforces the folder rules; review enforces the rest.

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
| TP-n | Test Package n: a throwaway, read-only in-client check that gates design choices |

## 10. Document inventory

| File | Purpose | Rule |
|---|---|---|
| Project_Bible.md | Governance | Changed only by user decision |
| Decisions.md | Decisions and open questions | Append-only |
| TODO.md | Phases, current phase, tasks | Every session |
| Session_Handoff.md | State transfer | Newest at top |
| Changelog.md | Changes to the repository | Append-only |
| Architecture.md | v1 design | Must agree with Decisions.md |
| Compatibility_Notes.md | Client facts with evidence tags | Wins on client facts |
| Risk_Register.md | Risks | Reviewed at every gate |
| GoldIntel_Reuse_Audit.md | What is reused from GoldIntel and how | Update when code is ported |
| Reference_DataStore_Altoholic.md | Source review of the alt-data providers | Update per DataStore release that matters |
| reviews/ | External reviews and their log | Documents stored unedited |
