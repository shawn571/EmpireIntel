# EmpireIntel Risk Register

DOC VERSION: 1.0.0  |  DATE: 2026-11-03  |  Reviewed at every phase gate. L = likelihood, I = impact (H/M/L).

| ID | Risk | L | I | Mitigation | Phase |
|---|---|---|---|---|---|
| R-01 | The launch build (2026-11-04) changes APIs or the interface number measured in beta | M | H | TP-1 runs on the launch build; GoldIntel re-verification protocol; TOC interface on the release checklist | 1 |
| R-02 | A legacy global reappears in a patch and switches DataStore onto an old code path (`GetSpellInfo or C_Spell...` pattern) | L | M | TP-1 T2 records legacy presence; re-run after every patch | 1, ongoing |
| R-03 | Realm text changes at launch, so DataStore re-keys characters and beta records duplicate | M | M | GUID identity (D-004); DataStore key stored as an attribute; TP-1 T3/T6 | 1, 3 |
| R-04 | Forever returns "Unknown" as a character name (reported by the Altoholic author) | M | M | Never key by name; flag and never overwrite a known name; de-duplicate by GUID | 3, 4 |
| R-05 | DataStore API drift: one author, no published contract, frequent releases | M | M | Bridge checks every method's presence at load; each call in pcall; TP-1 method list re-run per DataStore release | 3 |
| R-06 | DataStore's license forbids bundling, so many users will not have it | H | M | Self snapshots cover every character the user logs in with EmpireIntel installed; coverage shown in `/ei sources` | 3 |
| R-07 | The DataStore review is static only; behavior in the live client is unverified | M | H | TP-1 T5 cross-checks money, level and an item count against live values | 1 |
| R-08 | Stale alt data is read as current | H | M | `asOf` on every value; ages shown; totals show their oldest part | 4 |
| R-09 | Private data leaks into the public repository | M | H | D-007, `.gitignore`, anonymized fixtures, review before every commit | all |
| R-10 | Porting GoldIntel code publishes private work | — | M | Q-2: the user decides; only generic layers proposed | 2 |
| R-11 | Bank reads need the bank frame open; no verified bank event | H | L | Poll the frame (GoldIntel MailFrame pattern); TP-1 T7 | 1, 3 |
