# TP-1 Report, launch-build run 1

DOC VERSION: 1.0.0  |  DATE: 2026-11-04  |  Source: the user's `EmpireIntelCheck.lua` (EmpireIntelCheck 0.1.0-tp1), sent by hand. The raw file is **not** in the repository. Characters are aliased C1 and C2; no names, GUIDs or account details appear here.

> **Status 2026-11-04:** fixes 1 to 7 are built in EmpireIntelCheck 0.1.1-tp1 (D-021). Re-classified with the new rules, this run reads PANE ONLY, provisional (system locked), as expected.

**Result: the Legacy system is locked on this account, so no Legacy data could be read yet.** The client's own text says the system "becomes available when your first character reaches level 25". The highest character known is level 9. The check's automatic verdict, `LEGACY API: FOUND`, is a **false positive**: every "found" getter belongs to the retail legacy raid-difficulty menu, not to the Forever Legacy system. The correct reading is **NOTHING EXPOSED, provisional (system locked)**. Everything else held: no popup, no blocked call, no error in the check itself, and DataStore's data matched the live client exactly.

## 1. What ran

| Item | Value |
|---|---|
| Client | 1.60.1, build 70790 (Nov 3 2026), Interface 16001: the launch build. The interface number is unchanged from beta |
| Runs | 8 in total; only runs 7 (reason `pane`) and 8 (reason `login`) are saved. Runs 1 to 6 were dropped by the 256 KB cap (each run stores about 75 KB) |
| Characters | C1, level 1 to 2 during the runs, played with the check. C2, level 9, known only through DataStore |
| Calls | Run 8: 91 calls. 30 ok, 22 returned_nothing, 39 error (mostly UI mixin methods called without their object, plus functions that need an argument; expected and harmless). 73 skipped_denylist, 78 skipped_unrelated. **No `blocked`, no `unreadable`, no popup** |
| Scheduler | Up to 353 small steps per frame under the 2 ms budget; no stall reported |
| Optional steps | Bank not opened. `/eicheck docs` not run, although the docs are available |

## 2. Legacy findings (client facts, evidence EI-E-02 to EI-E-05)

**There is no data API by Legacy name.** No `C_` namespace or `Enum` is named for Legacy. The members that do mention it belong to retail features (legacy friends, legacy reputations, legacy loot, legacy raid difficulty). The namespace count is 272, the same as GoldIntel's beta count. The Legacy UI exists:

| Kind | Names found | Meaning |
|---|---|---|
| Functions | `ToggleLegacySystemUI`, `LegacySystemFrame_LoadUI`, `ToggleLegacyChallenges`, `ShowLegacyChallenge` | UI actions. **Never to be called** (they open or load UI) |
| Tables | `LegacyMicroButtonMixin` (`IsLegacySystemUnlocked` returned **false**), `LegacyChallengeViewedUtil` (`HasAnyUnviewedChallenges` returned false), `LegacyChallengesUnviewed` (empty) | The micro-menu button and a "challenge viewed" helper |
| Frame | `LegacyMicroButton` (a Button, shown) | The Legacy micro-menu button |
| Strings (client text) | `LEGACY_MICRO_BUTTON_LOCKED_TOOLTIP` = "This feature becomes available when your first character reaches level 25."; `LEGACY_POINTS_CURR_MAX` = "Legacy Points %d / %d"; `LEGACY_POINTS_AVAILABLE` = "Available points: %s"; `LEGACY_POINTS_SEASONAL_CAP` = "You can spend up to your current seasonal cap of %d Legacy Points in total."; `LEGACY_TREE_PROFESSIONS` / `LEGACY_TREE_ADVENTURE` / `LEGACY_TREE_PROGRESSION` = Professions / Adventure / **Resourcefulness**; `LEGACY_CHALLENGE_FRAME_TITLE` = "Legacy Challenges"; `LEGACY_TRACK_FRAME_TITLE` = "Progress Track"; `LEGACY_REWARD_TRACK_POINTS` = "Legacy Points"; `BINDING_NAME_TOGGLELEGACYSYSTEM` = "Toggle Legacy Pane"; `ERR_LEGACY_WIPE_ERROR_CLASS_POINTS` (a "Talented" Legacy perk grants class talent points) | Confirms the three trees, a points counter with a maximum, a **seasonal** spending cap, a reward track and challenges |
| Enum hint | `Enum.TraitConfigType.CamelotCombat = 4` | Forever has its own trait configuration type. Legacy perks may use the trait system (`C_Traits`); unverified |

What this means:
- **Unlock rule [file]:** the Legacy system unlocks account-wide when the first character reaches level 25. That is also the first class milestone, so the first Legacy point and the unlock should arrive together.
- **Cap [file]:** the client calls it a *seasonal* cap on Legacy Points spent "in total". Whether it is per character or per account is still open. The 16 from the fan guides is not confirmed.
- **The data API is probably in an existing namespace whose name does not say "Legacy"** (for example `C_Traits` or a currency), or it only appears once the UI loads (`LegacySystemFrame_LoadUI`). The client ships Blizzard's API documentation (`Blizzard_APIDocumentationGenerated` is present), which is the reliable way to find it without guessing.

## 3. Part A platform checks

| Check | Result |
|---|---|
| T1 profile | Project id 18 (`WOW_PROJECT_CAMELOT` = 18), Lua 5.1 |
| T2 pre-modern APIs | **All 13 families match the beta baseline.** Also measured for the first time: `GetSpellInfo`, `IsAddOnLoaded`, `GetAddOnMetadata`, the pre-modern quest-log, reputation, talent and currency globals are absent; `RequestTimePlayed` is present. The DataStore "fragile point" (`GetSpellInfo or C_Spell...`) cannot trigger |
| T3 identity | GUID present; two-part names confirmed. **Launch has named realms** of the form "CAMWOW US2 Realm N PvE", and C1 and C2 are on different realms |
| T4 add-ons | AddonFactory, DataStore and 7 modules loaded (2026.10.14); Altoholic 1.60.005; `isForever` and `isMainline` true; GoldIntel 0.5.1-passive loaded alongside, with no interference seen |
| T5 DataStore cross-check | **money, level, class and a carried item count all equal the live values.** Rest XP: DataStore 0, client nil (no rest). One false alarm, `ds_method_missing GetProfessionInfo`: that name is wrong in my method list for Forever |
| T6 roster | 2 characters across 2 realms, no "Unknown" names, no duplicate GUIDs |
| T7 bank | Not run (bank not opened) |

## 4. Rested XP and professions

- R-1: C1 had xp 86 / 900, `GetXPExhaustion` returned nothing (no rest), rest state "Normal". **Bug:** at `PLAYER_LOGOUT` the client reported level 1 and xpMax 0 for a level-2 character, so the logout baseline is unusable. The baseline must come from the last in-world snapshot instead.
- P-1: `GetProfessions` returned nothing; C1 has no professions yet. The skill parsing is untested live.
- E-1 estimate: 0 points (no character at 25). Consistent with the lock.

## 5. Defects in EmpireIntelCheck 0.1.0-tp1

| # | Defect | Effect | Fix |
|---|---|---|---|
| 1 | Verdict counts any "legacy"/"challenge"/"perk" name as Legacy data | FOUND on legacy raid-difficulty getters (false positive) | Count only names on a Legacy evidence list built from what this run found (`LegacyMicroButton*`, `LegacyChallenge*`, `LegacySystem*`, docs systems), and add the known retail families (legacy raid, legacy friends, guild challenges and perks, profession spec perks, challenge mode) to the unrelated list |
| 2 | Pane detection used `IsShown()` on any matching frame | A hidden guild-challenge frame counted as "Legacy pane seen" (run 7 reason `pane`) | Use `IsVisible()` and only the Legacy frames; record the lock state (`IsLegacySystemUnlocked`) and make "locked" a provisional reason |
| 3 | Logout baseline read at `PLAYER_LOGOUT` | Level 1 and xpMax 0 saved | Keep the last in-world snapshot as the baseline |
| 4 | Each run stores the full discovery (about 49 KB) | Only 2 of 8 runs kept | Store the discovery once per build and only differences per run (**saved-data format change of EmpireIntelCheckDB: needs approval**) |
| 5 | DataStore method list has `GetProfessionInfo` | False UNEXPECTED | Drop it; check the Forever Crafts method names from the source |
| 6 | Denylist matches "set" inside "Preset" | `C_GameRules.GetForeverExperiencePreset` not called | Match whole CamelCase words (`Set`, `Reset`, ...), not substrings |
| 7 | Docs matcher keeps only systems whose names match a term | A Legacy API in a neutrally named system would be missed | Also save an index of every docs system (name, namespace, function count) and match argument, return and event field names |

## 6. Recommendations (decisions for the user)

1. **D-005 DataStore: adopt option A for Characters and Containers.** They held up live on the launch build. Crafts waits for a character with professions.
2. **D-012 Legacy names: nothing to approve yet.** No Legacy data getter exists by name, and the UI functions must never be called.
3. **Next check, two options:**
   - (a) **No new install:** type `/eicheck docs` once in game with 0.1.0. The current matcher may miss a neutrally named system (defect 7), and the docs may push older runs out under the cap.
   - (b) **Recommended: EmpireIntelCheck 0.1.1-tp1** with fixes 1 to 7. It is a Lua-only update (**/reload is enough**), but fix 4 changes the check's saved-data format, so it waits for your approval. Then type `/eicheck docs` once. A second run after a character reaches level 25 confirms the unlock and reads real Legacy values.
4. **The release pipeline stays at Stage 0.** These results are the "first launch results" the Stage 1 decision depends on. Real Legacy data is not available until a character reaches 25.

## 7. Run 2 (0.1.1-tp1, 2026-11-04/05, C1 at level 3)

| Item | Result |
|---|---|
| Migration | Format 1 -> 2 worked: runs 9 and 10 (0.1.0) compacted, run 11 (0.1.1) stored in the new form; 216 KB in total |
| Verdict | `NAMES ONLY (provisional: locked; pane not seen; no point expected)`. **Defect 8:** five retail enums (NamePlateStyle, RespecType, RaidAuraOrganizationType, Itemsetflags, BnetAccountFlag) have a member called "Legacy". Fixed in 0.1.2; re-classified, the run reads **PANE ONLY**, as expected |
| Calls | Only 3 getters called (lock state false, unviewed challenges false, Forever experience preset = 1); 2 Set names skipped; 350 retail names skipped as unrelated. No blocked call, no error |
| Lock | `IsLegacySystemUnlocked` = false (as in run 1) |
| Logout baseline | Valid at logout this time (level 3, xpMax 1400, source `logout`) |
| **Errors (T8)** | BugGrabber had 11 errors recorded: TradeSkillMaster 199 (counted repeats), Accountant_Classic 6, ZygorGuidesViewerForever 4, !BugGrabber 4, Questie 2, TradeSkillMaster_AppHelper 1. **None from EmpireIntelCheck, and none from GoldIntel** |
| Docs | Not run: `/eicheck docs` is still the step that can find the Legacy data API before level 25 |

## 8. Run 3 (0.1.2-tp1, 2026-11-05, C1 at level 4)

- `/eicheck docs` worked in the client: **410 documented API systems, 14 matched** the search terms (the user's chat lines).
- **Defect 9:** the saved file holds no docs, only a "dropped: over size cap" marker. The 14 systems in full exceeded the 256 KB cap. The trim order dropped the docs before cheaper data, and only 1 run was left. Fixed in 0.1.3 (D-024).
- Otherwise as run 2: PANE ONLY (provisional: locked), 3 getters called, no blocked call, no errors from EmpireIntelCheck. The logout baseline was valid (level 4).

## 9. Run 4 (0.1.3-tp1, 2026-11-05): the API documentation

**Result: Blizzard's in-client API documentation has no Legacy system.** All 410 systems were indexed and 14 matched a term. None is the Forever Legacy system.

| Finding | Detail |
|---|---|
| The 3 "Legacy" matches are false positives (**defect 10**) | FriendList, KeyBindings and VoiceChat matched only through retail enum fields literally named "Legacy" (TurnStrafeStyle, VoiceProviderID); the same pattern as defect 8, inside the docs |
| The 11 other matches | Retail features: legacy raid difficulty, legacy loot, legacy reputations, legacy friends, guild challenges, challenge mode. Plus **GameRules** (C_GameRules, 30 functions), which holds Forever's own rules: `GetForeverExperiencePreset`, `IsHardcoreActive`, `IsSelfFoundAllowed`, game modes. Nothing about Legacy |
| **20 live namespaces are undocumented** | `C_AccountServices`, `C_ArrowCalloutManager`, `C_BlackMarket`, `C_CharacterServices`, `C_CharacterServicesPublic`, `C_Debug`, `C_FunctionContainers`, `C_Heirloom`, `C_PrototypeDialog`, **`C_Reincarnation`**, `C_Scenario`, **`C_Seasons`**, `C_SharedCharacterServices`, `C_SpectatingUI`, `C_ToyBox`, **`C_Trophy`**, `C_Widget`, `C_WoWLabsMatchmaking`, `C_WowLabsDataManager`, `C_WowTokenPublic`. The check never looked inside them: their names carry no search term |
| Trait-system lead [inferred] | The client text `TALENT_FRAME_TAB_LABEL_LEGACY` = "Legacy" (run 1) puts the Legacy trees on a tab of the talent frame. Forever has its own trait config type (`Enum.TraitConfigType.CamelotCombat = 4`, EI-E-04). The documented `C_Traits` (53 functions) and `C_TraitConfig` are therefore the most likely data path, but their getters need arguments (config and tree ids) |

What this means:
- **Pre-unlock features are unaffected.** FR-PRE-1..4 need no Legacy API.
- After the unlock, the Legacy values are most likely readable through the trait system, or through one of the undocumented namespaces (`C_Seasons` fits the client's "seasonal cap" wording).
- Both paths widen what the check calls, so both wait for the user (Q-T3, Q-T4).

## 10. Run 5 (0.1.4-tp1, 2026-11-05): undocumented namespaces

**Result: no Legacy data is reachable before the unlock by any route tried.** The routes were names, the API docs, and the undocumented namespaces.

| Namespace | Members | Outcome |
|---|---|---|
| `C_Seasons` | `GetActiveSeason`, `HasActiveSeason` | Both called (`/eicheck undoc`): **0** and **false**, so no active season. This looks like the classic seasonal-realm API, not Legacy |
| `C_Trophy` | 9 functions, all `Monument...` (retail garrison trophy monument) | None is a Get/Is/Has name, so nothing was called. Unrelated |
| `C_Reincarnation` | `GetReincarnatingCharacter`, `IsReincarnating`, `StartReincarnation`, `StopReincarnation` | Listed for the user, **not called**. Note: "Reincarnating" does not contain the blocked word "Reincarnate", so the two read names would pass the denylist; they stay uncalled under the review rule |
| 17 others | service, store, debug, retail UI | Listed, never called |

- The crash guard held: no leftover `inFlight`, empty `neverCall`. No unexpected conditions.
- **Defect 11 (wording):** `/eicheck undoc` typed before the first check of the session finished answered "nothing planned yet (wait for the next check line)". It should say to retry in about 10 seconds. To fix in the next build.
- **What remains:** the Legacy values themselves can only be checked after a character reaches level 25. That needs the pane run, and possibly the trait-system calls of Q-T4.
