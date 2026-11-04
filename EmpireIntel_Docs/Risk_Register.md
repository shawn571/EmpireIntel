# EmpireIntel Risk Register

DOC VERSION: 1.1.0  |  DATE: 2026-11-03 (S-002)  |  Reviewed at every phase gate. L = likelihood, I = impact (H/M/L).

| ID | Risk | L | I | Mitigation | Phase |
|---|---|---|---|---|---|
| R-01 | The launch build (2026-11-04) changes APIs or the interface number measured in beta | M | H | TP-1 runs on the launch build; GoldIntel re-verification protocol; TOC interface on the release checklist | 1 |
| R-02 | A pre-modern global reappears in a patch and switches DataStore onto an old code path (`GetSpellInfo or C_Spell...` pattern) | L | M | TP-1 T2 records pre-modern presence; re-run after every patch | 1, ongoing |
| R-03 | Realm text changes at launch, so DataStore re-keys characters and beta records duplicate | M | M | GUID identity (D-004); DataStore key stored as an attribute; TP-1 T3/T6 | 1, 3 |
| R-04 | Forever returns "Unknown" as a character name (reported by the Altoholic author) | M | M | Never key by name; flag and never overwrite a known name; de-duplicate by GUID | 3, 4 |
| R-05 | DataStore API drift: one author, no published contract, frequent releases | M | M | Bridge checks every method's presence at load; each call in pcall; TP-1 method list re-run per DataStore release | 3 |
| R-06 | DataStore's license forbids bundling, so many users will not have it | H | M | Self snapshots cover every character the user logs in with EmpireIntel installed; coverage shown per line | 3 |
| R-07 | The DataStore review is static only; behavior in the live client is unverified | M | H | TP-1 T5 cross-checks money, level and an item count against live values | 1 |
| R-08 | Stale alt data is read as current | H | M | `asOf` on every value; ages shown; totals show their oldest part | 4 |
| R-09 | Private data leaks into the repository (public at the time of writing, private per the user) | M | H | D-007, `.gitignore`, anonymized fixtures, review before every commit | all |
| R-10 | Porting GoldIntel code publishes private work | L | M | Resolved by the user (private repository); confirm the GitHub visibility | 2 |
| R-11 | Bank reads need the bank frame open; no verified bank event | H | L | Poll the frame (GoldIntel MailFrame pattern); TP-1 T7 | 1, 3 |
| R-12 | **The client exposes no Legacy data to addons.** Run 1: none by name, and the system is locked until a character reaches 25 (EI-E-02, EI-E-03); the docs are the next step | M | H | TP-1 verdict; Estimator fallback (lower bound from class levels and crafting skill); perks and spent points then shown as unknown | 1, 3 |
| R-13 | The challenge rules from fan guides are wrong or change (65 vs 66 challenges; cap 16 vs beta 30) | M | M | Rules in one data table; cap read from the client or the plan; estimates always labelled; Q-9 to check Blizzard's article | 1, 3 |
| R-14 | A discovered getter is protected and shows an ADDON_ACTION_FORBIDDEN popup | L | M | D-013 rules: getters only, out of combat, once per session, popup watcher; Q-7 lets the user choose names only | 1 |
| R-15 | Legacy data loads lazily (only after the pane opens) | M | M | L-6 pane hook compares values before and after opening | 1 |
| R-16 | `GetXPExhaustion` returns 0 or nil unreliably (DataStore comment); rest rates differ on Forever | M | L | nil stored as unknown; projection checked against the next login's measurement | 1, 3 |
| R-17 | The plan file has errors or names an unknown character | H | L | Validation at load; each bad goal reported and skipped | 4 |
| R-18 | Launch-week patches change the API between TP-1 and Phase 2 | M | M | Re-run TP-1 after each patch (it is passive and cheap) | all |
| R-19 | Legacy cannot be verified until a character reaches level 25 | H | M | The docs search finds the API names now; the value check waits for level 25 | 1 |
| R-20 | Each check run stores about 75 KB, so the cap keeps only 2 to 3 runs and older evidence is lost | H | M | Fix 4 of the TP-1 report (discovery once per build): needs approval as a saved-data format change | 1 |
