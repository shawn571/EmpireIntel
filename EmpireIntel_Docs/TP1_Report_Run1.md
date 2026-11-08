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

## 11. Run 6 (0.1.4-tp1, 2026-11-07): the level-25 run

C1 (Paladin) reached level 25 on client build **1.60.1/70862** (Nov 6; new since run 5). The run was triggered by `Blizzard_LegacySystem` loading when the user opened the pane.

- **Unlocked:** `LegacyMicroButtonMixin.IsLegacySystemUnlocked` reports unlocked. Verdict: **PANE ONLY**. No data function exists by name, and no namespace was added. `C_Seasons` is gone in 70862.
- **The pane's own Lua code (zero-argument Get/Is/Has calls, denylist applied; 63 calls, 0 own errors):**
  - A Lua table **`LegacySystem`** holds `GetCurrencyInfo` (answered with one value), `GetFilteredChallenges` (one value), `GetChallengeIndices` and `IsChallengeVisible` (both errored for lack of arguments).
  - `GetChallengeIndices` failed inside **`GetCategoryNumAchievements(categoryID, ...)`**: the Legacy challenges are **achievements in a category**.
  - `LegacyChallengePointSummaryMixin.SetCurrencyInfo` (not called, denylisted): Legacy points are shown from **currency info**.
  - Trees: `LegacyTreeTraitPanelMixin` and `TalentButtonLegacyMixin` (trait UI, as in run 4). A reward track: `LegacyRewardTrackPageMixin`.
  - Mixin methods called without a frame fail with "self is nil", as expected.
- **Gap:** 0.1.4 records only the result codes and value counts of these calls, not the values. So the currency info that `LegacySystem.GetCurrencyInfo` returned is not in the file.
- **The estimate fallback says 1 point (lower bound)**. The real number shown in the pane is not known yet.
- DataStore T5 matches live (level, class, money, items). T6: 3 characters, no "Unknown", no duplicate GUID. **`GetModuleLastUpdateByKey` returned nil for all 3** (EI-E-17).
- BugGrabber: 34 entries, none from EmpireIntel or the check.

**Lead for the next step (Q-T7):** the Legacy values look readable through two documented, read-only APIs: achievements (the challenges) and `C_CurrencyInfo` (the points). Both need an id argument, which the zero-argument rule does not allow.

## 12. Run 7 (0.1.6-tp1, 2026-11-08): the first Legacy read

The user installed 0.1.6 with a `/reload` (EI-E-19), opened the pane, typed `/eicheck legacy` and sent the file and two screenshots of the Challenges page.

- **Result:** "0 challenges in 0 categories; points not found" before and after the pane opened. 32 calls, all ok; no error, no refusal, no crash-guard hit.
- **The points are there (EI-E-21):** `LegacySystem.GetCurrencyInfo()` (zero-argument, approved) returned `{ quantity = 1, maxQuantity = 1, renownCurrency = 1, spent = 0, spentInTree = 0, traitCurrencyID = 4225 }`. The Legacy points are a **trait currency** (4225), not a `C_CurrencyInfo` currency. So `C_CurrencyInfo.GetCurrencyInfo(4225)` gave nothing, and the currency list holds no Legacy entry (size 0).
- **The challenges are there (EI-E-20):** `GetCategoryList()` returned 29 categories, and they are exactly the pane's groups. On Forever the achievement categories **are** the Legacy challenge categories. None has "Legacy" in its title, so the 0.1.6 matcher (title contains "legacy") selected none.
- `LegacySystem.GetFilteredChallenges()` returned an empty table (it likely depends on the pane's filter state). `LegacySystem` has no plain fields; its functions are `GetChallengeIndices`, `GetCurrencyInfo`, `GetFilteredChallenges`, `IsChallengeVisible`, `RegisterCurrencyInfoCallback` and `UpdateCurrencyInfo`.
- **Screenshots:** "Legacy Points 1 / 65"; the group list matches the categories exactly; the Adventure page shows "Lord Valthalak Laid to Rest" and "Explorer" ("Have a character with the Explore Azeroth achievement"), 1 point each.

**Check defects found:**
- **Defect 13:** the category matcher assumed a "Legacy" title.
- **Defect 14:** the points were not taken from `LegacySystem.GetCurrencyInfo`, and `traitCurrencyID` was wrongly passed to `C_CurrencyInfo`.

Fix proposed as 0.1.7 (Q-T8), within the Q-T7 limits.

## 13. Run 8 (0.1.7-tp1, 2026-11-08): the full challenge list

The user installed 0.1.7 with `/reload`, opened the pane and typed `/eicheck legacy`. 955 calls, all ok; no error, no refusal.

- **All 65 Legacy challenges are readable (EI-E-22).** The 27 shown categories hold 111 achievements. Exactly **65** have the reward text "Earn 1 Legacy Point." The other **46** have no reward: Explore Azeroth, Explore Eastern Kingdoms, Explore Kalimdor, and the 43 "Explore <zone>" achievements that make up the Explorer challenge.
- **Completed:** 1 (Novice Paladin), which matches the pane's "Legacy Points 1 / 65". "Tier 1 Gear" and "Do Not Display" hold no achievements.
- **Points:** `LegacySystem.GetCurrencyInfo()` gave the same six fields as run 7 (quantity 1, maxQuantity 1, renownCurrency 1, spent 0, spentInTree 0, traitCurrencyID 4225).
- **Defect 15 (size):** the read did not fit under the 256 KB cap. The trim removed every challenge's steps and the category list. The largest sections are now discovery leftovers: `latest` 42 KB, `strongSeen` 39 KB, `docs` 24 KB, `undoc` 11 KB.
- **Defect 16 (totals):** 0.1.7 counted all 111 achievements and summed the achievement-points field. That field is not the Legacy value (only Onyxia, id 684, carries 1), so the line said "111 challenges, 0 of 1 points" instead of "65 challenges, 1 of 65 points".

Fix proposed as 0.1.8 (Q-T9).

## 14. Run 9 (0.1.8-tp1, 2026-11-08): the Legacy read is complete

The user installed 0.1.8 with `/reload`, opened the pane and typed `/eicheck legacy`. 955 calls, all ok. Nothing was trimmed (file 233 KB of the 256 KB cap).

- **The line matches the pane:** "65 challenges (1 completed, 1 of 65 Legacy points); Explorer 0 of 46 done". No achievement left unlinked; the reward text was recognized.
- **Explorer's 46 steps** were linked through the game's own chain: Explorer, then Explore Azeroth (2 steps), then Explore Eastern Kingdoms (23 zones) and Explore Kalimdor (20 zones). This matches the grouping the user asked about.
- **Zone progress (current character):** 11 zones partly explored, for example Silverpine Forest 13/15, Tirisfal Glades 13/16 and The Barrens 15/25. No zone is complete yet.
- **Dungeons:**
  - Novice Spelunker has 5 of 6 done; only Excavation Site: Wetlands is missing.
  - Experienced Spelunker has Blackfathom Deeps done.
  - The game's Master Spelunker list names **Dire Maul East, North and West**, which settles the web guides' disagreement.
- Lord Valthalak, Conqueror of the Lair, PvP ranks and Explorer have no counted steps of their own; reputations and Field of Honor have one each.

**TP-1 status:** the client now answers the Legacy data questions:
- **Points:** `LegacySystem.GetCurrencyInfo()`, available once the pane has loaded.
- **Challenges, their steps and their completion:** the achievement functions, from login.

Still open:
- what `quantity`, `maxQuantity` and `renownCurrency` each mean, which needs a run after spending or earning a point;
- the tree perks (Q-T4, not approved);
- whether zone progress is per character.

## 15. Run 10 (0.1.8-tp1, 2026-11-08 04:09 UTC = 2026-11-07 23:09 user time): after spending the first point

The user spent 1 Legacy point in a tree on C1 (Paladin 25). The check's next read used the same zero-argument call as before, with no new call.

| Field of `LegacySystem.GetCurrencyInfo()` | Before (run 9, 04:02 UTC) | After (run 10, 04:09 UTC) |
|---|---|---|
| quantity | 1 | **0** |
| maxQuantity | 1 | 1 |
| renownCurrency | 1 | 1 |
| spent | 0 | **1** |
| spentInTree | 0 | 0 |
| traitCurrencyID | 4225 | 4225 |

- **Raw result:** saved as-is in `legacy.system.GetCurrencyInfo.values[1]`: six numeric fields, none truncated, nothing secret. `legacy.points` holds the same six plus the `source` label.
- **The spend happened** between the 04:04:26 and 04:09:37 reads (from `legacy.history`).
- **Challenges and steps:** all 111 achievements were compared field by field with run 9. 65 challenges, 1 completed, Explorer 0 of 46, categories identical. The only differences are two zone sub-areas explored while playing between the reads: Thoradin's Wall (Arathi Highlands) and Durnholde Keep (Hillsbrad Foothills). Nothing changed because of the spend.
- **Size:** 229 KB, nothing trimmed. 955 calls, all ok.
- **spentInTree** stayed 0 after a spend. See section 16.

## 16. Why spentInTree is 0 (analysis, not confirmed)

The file cannot settle this.
- **No tree is recorded:** the check makes no trait-system call (Q-T4), so the file has no record of which tree the point went into. The user's message left the tree and perk blank.
- **No parameter list:** `LegacySystem` is pane Lua code, not a documented API. WoW's Lua 5.1 cannot report a Lua function's parameter count, so the file cannot say whether `GetCurrencyInfo` takes a tree argument.

What the file does show:
- **Zero arguments work:** `GetCurrencyInfo()` called with no argument succeeds every time and returns a number for `spentInTree`.
- **It looks like a cache:** `LegacySystem` also has `UpdateCurrencyInfo` and `RegisterCurrencyInfoCallback`, never called by the check. That suggests `GetCurrencyInfo` returns a table the pane keeps up to date: it holds data only once the pane has loaded, and it changed after the spend.

Leading hypothesis: `spentInTree` is the points spent in the tree the pane currently has selected (or was given when the pane updated), and 0 when that tree has none or none is selected. A tree argument is possible but unproven.

**Test without any new call:** open the pane on the tree where the point was spent, leave it open, and type `/eicheck legacy`. Then do the same on another tree.
- spentInTree 1, then 0: it follows the selected tree.
- 0 both times: it needs something the pane does not pass to `GetCurrencyInfo()`, such as a tree argument. Calling it with one stays under Q-T4 and needs the user's approval.

## 17. Run 11 (0.1.8-tp1, 2026-11-07 23:15-23:16 user time): the selected-tree test

Chat lines only (no file):
- two automatic reads when the pane loaded;
- two `/eicheck legacy` reads at 23:15:54 and 23:16:08, which the user ran as the test from section 16.

All four reads were identical: maxQuantity 1, quantity 0, renownCurrency 1, spent 1, **spentInTree 0**. The lines do not say which tree was open for each read, or whether a tree page (not Challenges) was showing.

**Provisional reading:** if the 23:15:54 read was on the tree holding the spent point, spentInTree does **not** follow the pane's selected tree when `GetCurrencyInfo()` is called with no argument. The leading hypothesis of section 16 then fails.

Remaining hypotheses:
- (a) It counts points placed in a tree but **not yet applied** ("Apply Changes" commits; `spent` counts committed points). Testable without new calls once a point is available: place it, read, apply, read.
- (b) It needs a tree argument. Testing that is a call with an argument, under Q-T4, which is unapproved.
- (c) The pane refreshes the field through `UpdateCurrencyInfo`, which the check never calls, and it was stale.

## 18. Run 12 (0.1.8-tp1, 2026-11-08 00:16 user time): the second earned point

Chat line only: "65 challenges (2 completed, 2 of 65 Legacy points); Explorer 0 of 46 done; Legacy points: maxQuantity 2, quantity 1, renownCurrency 2, spent 1, spentInTree 0". The new point is unspent. The user ran the read with the **Adventure** tree open; the first point had been spent in Adventure.

| Field | Run 9 (earned 1, spent 0) | Run 10 (spent 1) | Run 12 (earned 2) |
|---|---|---|---|
| quantity | 1 | 0 | **1** |
| spent | 0 | 1 | 1 |
| maxQuantity | 1 | 1 | **2** |
| renownCurrency | 1 | 1 | **2** |
| spentInTree | 0 | 0 | 0 |
| completed challenge points | 1 | 1 | **2** |

- **Available:** `quantity` is the points available to spend. It fell by 1 on a spend and rose by 1 on an earn. **Confirmed** by two opposite moves.
- **Spent:** `spent` is the points spent. It rose on the spend and did not move on the earn. Consistent; one move observed.
- **Earned:** `maxQuantity` and `renownCurrency` are both the points earned, and both equal the completed challenges' points in all three reads. Still **indistinguishable**.
- **Invariant:** quantity + spent = maxQuantity held in all three reads.
- **spentInTree:** 0 with the Adventure tree open, although the spent point is in Adventure. The selected-tree hypothesis (section 16) **fails**. Remaining hypotheses: (a) points placed but not applied; (b) a tree argument (Q-T4); (c) a stale value. The user now has an unspent point, so (a) can be tested now.
- Which challenge gave the second point is not in the chat line; the saved file would show it.

## 19. Run 13 (0.1.8-tp1, 2026-11-08 00:19-00:20 user time): placed but not applied, then applied

Chat lines only. Per the test steps, the first read was taken with the point placed and not applied, the second after "Apply Changes".

| Field | Placed, not applied (00:19:49) | Applied (00:20:05) |
|---|---|---|
| quantity | 1 | **0** |
| spent | 1 | **2** |
| maxQuantity | 2 | 2 |
| renownCurrency | 2 | 2 |
| spentInTree | 0 | 0 |

- **Committed points only:** `GetCurrencyInfo()` does not see a placed point until it is applied.
- **Hypothesis (a) fails:** spentInTree is not "placed but not applied".
- **Spent confirmed:** `spent` rose by exactly one on each applied spend, two moves, and never moved on an earn.
- **Invariant:** quantity + spent = maxQuantity held in every read (5 reads).
- **spentInTree:** 0 in every read, with the spent tree open or not, placed or applied. Remaining explanations:
  - (b) it needs a tree argument;
  - (c) it is filled only by the pane's own `UpdateCurrencyInfo`, never called by the check;
  - it may also be unused on Forever.

Testing (b) needs a tree id from the game, which only the trait system gives (Q-T4, unapproved). The check has no game-returned tree id to pass, so even an approved argument call would first need Q-T4.
