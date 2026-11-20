# EmpireIntel Risk Register

DOC VERSION: 2.1.0  |  DATE: 2026-11-20 (S-069)  |  Reviewed at every increment gate. L = likelihood, I = impact (H/M/L).

## Open risks

| ID | Risk | L | I | Mitigation |
|---|---|---|---|---|
| R-02 | A patch brings back a pre-modern global and switches DataStore onto an old code path | L | M | The check records pre-modern presence; re-run after a patch |
| R-04 | Forever returns "Unknown" as a character name | M | M | Keyed by GUID; "Unknown" never replaces a known name (Alts merge rule) |
| R-05 | DataStore API drift (one author, no published contract) | M | M | The bridge checks each getter, calls it under pcall, counts errors as `UNEXPECTED`; works without DataStore |
| R-08 | Stale alt data is read as current | H | M | Every value carries its source and age; projections are labelled |
| R-09 | Private data leaks into the repository | L | H | Repository private (checked before every push); names written C1, C2; synthetic fixtures; review before commit (D-007) |
| R-13 | A planner rule is wrong (11 of 18 rules are unverified, for example the cap of 16, the training gates, the rested-kill rule) | M | M | Every rule has a status and source; estimates list the unverified rules they use; live checks confirm them one by one |
| R-14 | A Legacy or UI call is protected and shows a "blocked" popup | L | M | Only calls proven by the check; never in combat; reads on command only |
| R-16 | `GetXPExhaustion` returns nil or 0 unreliably | M | L | nil stored as "none reported", never as a measured 0 |
| R-17 | A saved plan step is bad or names an unknown character | M | L | Checked at load; each bad step one `UNEXPECTED` line and skipped |
| R-18 | A patch changes the API (builds 70790, 70862, 70938, 71037 so far; 71037 dropped realm names, EI-E-34) | M | M | The check re-runs passively; the build is recorded in `meta.build` |
| R-21 | Levelling-time estimates are far from real play (default rates, one measured rate for every level) | H | M | Measured XP per hour where it exists (7 of 8 characters); P2-4e adds quests and grinding; cross-check with ForeverXP Bar (D-068) |
| R-22 | The check's saved file reaches its 256 KB cap and drops data (about 248 KB on 2026-11-20, already dropping data) | H | L | 0.1.10 stops saving old discovery results; target under 128 KB (Phase2_Plan.md 11.5) |
| R-23 | A third-party source is copied under the wrong license | L | H | D-068: the license file is read before any copy and recorded in THIRD_PARTY.md; clean room otherwise; no data tables |
| R-25 | The game no longer gives realm names (build 71037, EI-E-34); characters on other realms or test realms get mixed into the route or the Legacy count | H | M | GUID server number as the realm identity; labels learned or set by the user; only the played realm planned until the cross-realm test (Phase2_Plan.md section 12) |
| R-26 | DataStore's data is wrong on 71037 (blank-realm keys, duplicates, missing alts) | H | M | Merge by GUID; own records win when newer; DataStore optional (EI-E-35) |
| R-24 | The window looks or behaves differently under ElvUI or other UI add-ons | M | L | No Blizzard templates; the fill path with a read-back; live gate with ElvUI on and off |

## Closed risks (kept for the record)

| ID | Risk | Outcome |
|---|---|---|
| R-01 | The launch build changes APIs | Launch build checked (EI-E-01); later builds re-checked (EI-E-15) |
| R-03 | Realm text changes at launch and DataStore re-keys characters | Characters keyed by GUID; launch realms recorded (EI-E-06) |
| R-06 | DataStore's license forbids bundling | Own records cover every character logged in with EmpireIntel; DataStore optional (D-003) |
| R-07 | The DataStore review was static only | Checked live (EI-E-07, P2-2) |
| R-10 | Porting GoldIntel code publishes private work | Repository private |
| R-11 | Bank reads need the bank open | Bank tracking out of scope |
| R-12 | The client exposes no Legacy data to add-ons | Legacy is readable: achievements and `LegacySystem.GetCurrencyInfo` (EI-E-16, EI-E-20..27) |
| R-15 | Legacy data loads lazily | Confirmed and handled: points need the pane loaded once; `/ei legacy` says so |
| R-19 | Legacy cannot be verified before level 25 | The account unlocked; read verified (P3-1) |
| R-20 | The check's runs crowd its saved file | Fixed in 0.1.1; see R-22 for the current size issue |
