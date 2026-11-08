# WoW Forever Compatibility Notes (EmpireIntel)

DOC VERSION: 1.1.0  |  DATE: 2026-11-03 (S-002)  |  Wins over Architecture.md on client facts

EmpireIntel has no evidence of its own yet. Its ids will be `EI-E-nn`. The facts below are **[inherited]** from GoldIntel's evidence ledger (beta builds 70338 to 70450, client 1.60.1, Interface 16001, October 2026) and are cited by GoldIntel id. Names and GUIDs are left out on purpose (D-007). Everything here must be re-checked on the launch build (TP-1).

## 1. Client profile [inherited]

| Fact | Value | GoldIntel id |
|---|---|---|
| Version / interface | 1.60.1, Interface 16001 (= encoded version) | E-01 |
| Project id | `WOW_PROJECT_ID` 18; third-party code names it `WOW_PROJECT_CAMELOT` (unverified) | E-01; Reference_AccountantClassic |
| Lua | 5.1; `load`, `table.unpack` nil; `loadstring`, `bit` present | E-04 |
| Engine | Modern retail-engine API, 272 `C_` namespaces | E-05 |
| Realm (beta) | Named realm 'Classic Beta PvE'; launch model unknown | E-07 |
| Name | `UnitName('player')` has a second return: the surname ("First-Last" folders) | E-44; Reference_AccountantClassic |
| SavedVariables | Per-character file under `WTF\Account\<account>\<n>\<First-Last>\` | E-44 |

## 2. Pre-modern versus modern API [inherited] (not the Legacy points system; see section 6)

| Family | Pre-modern | Modern | GoldIntel id |
|---|---|---|---|
| Containers | `GetContainerNumSlots`, `GetContainerItemInfo` ABSENT | `C_Container` works, 44 slots scanned in 0.74 ms, non-secret | E-17 |
| Skill lines | `GetNumSkillLines`, `GetSkillLineInfo`, `ExpandSkillHeader` ABSENT | `GetProfessions` / `GetProfessionInfo` present | E-05 |
| Trade skills | pre-modern ABSENT | `C_TradeSkillUI` present | E-05 |
| Auction | `QueryAuctionItems` family ABSENT | `C_AuctionHouse` (85 functions) | E-05, E-35 |
| Addon info | global `GetAddOnInfo` ABSENT | `C_AddOns.GetAddOnInfo` (6 returns) | E-08 |
| Item info | `GetItemInfo` present (17 returns, cached items only) | `C_Item.*` present | E-17, E-30 |
| Mail | inbox globals present | `C_Mail` present | E-29 |

## 3. Events proven live [inherited]

`PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_LEAVING_WORLD`, `PLAYER_LOGOUT` (handlers can still write saved variables), `PLAYER_MONEY`, `BAG_UPDATE_DELAYED`, plus GoldIntel's collection events (E-13, E-15, E-32, GoldIntel Architecture AC-1). `COMBAT_LOG_EVENT_UNFILTERED` is never registered. Probing by registration is forbidden: a blocked registration shows a popup that pcall cannot hide (GoldIntel D-025).

## 4. Third-party facts (source reading, not verified)

- AddonFactory treats interface 16000..19999 as Forever and sets `isForever` and `isMainline` (Reference_DataStore_Altoholic.md section 3).
- The Altoholic Forever changelog reports that the client sometimes returns "Unknown" as the character name.

## 5. Legacy system: what is known before TP-1 (web search summaries, NOT verified)

The pages could not be opened from the session (network policy). These facts come from search-result summaries of [Blizzard's Legacy article](http://worldofwarcraft.blizzard.com/en-us/news/24307383), [forg.gg](https://forg.gg/en/forever/legacy), [Icy Veins](https://www.icy-veins.com/wow-forever/legacy-system), [LFCarry](https://lfcarry.com/guides/wow-forever-legacy-system), [TimeSaver](https://timesaver.gg/blog/wow-forever-legacy-system-explained) and [classicwowforever](https://classicwowforever.com/legacy/), searched 2026-11-03. Tag: [assumed] until TP-1 or the article confirms them.

| Fact | Value | Note |
|---|---|---|
| Challenges | 65, one point each, account-wide (66 if a beta-participation challenge is counted) | Sources disagree |
| Trees | Professions, Adventure, Resourcefulness; 21 perks (forg.gg) | |
| Per-character spend cap | 16 at launch; expected to rise later; one site says the beta used 30 | **Client text (EI-E-04): a *seasonal* cap on points spent "in total"; per character or per account still open** |
| One character alone | can earn up to 29 points | Blizzard, per summary |
| Class milestones | levels 25, 45, 60 per class, 9 classes = 27 | Basis of the Estimator |
| Crafting milestones | skill 150, 225, 300 in Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking, Tailoring = 18 | Gathering not included |
| Other challenges | about 20, kinds unknown | [inferred]: 3 + 6 + 20 = 29 matches the one-character figure |
| Points past the cap | feed a cosmetic reward track | |
| Addon API | **nothing found** in any source, and no third-party addon reviewed (DataStore, Altoholic Forever, Accountant Classic, Auctionator) reads Legacy data | TP-1 Part B |

Hint for discovery: the Forever Blizzard UI has `Camelot` folders (`Blizzard_AuctionHouseUI/Camelot/...`, cited in Altoholic Forever's source), so TP-1 also searches names for "camelot".

## 6. Evidence ledger (EmpireIntel)

| ID | Fact | Source |
|---|---|---|
| EI-E-01 | Launch build 1.60.1 / 70790 (Nov 3 2026), Interface still 16001, project id 18; all 13 pre-modern families as in beta; also absent: `GetSpellInfo`, `IsAddOnLoaded`, `GetAddOnMetadata`, pre-modern quest-log, reputation, talent and currency globals; `RequestTimePlayed` present | TP1_Report_Run1.md section 3 (user's file, 2026-11-04) [file] |
| EI-E-02 | **The Legacy system unlocks when the account's first character reaches level 25** (client string `LEGACY_MICRO_BUTTON_LOCKED_TOOLTIP`); `LegacyMicroButtonMixin.IsLegacySystemUnlocked()` returned false on an account whose highest character is level 9 | TP1_Report_Run1.md section 2 [file] |
| EI-E-03 | No Legacy-named `C_` namespace or Enum (272 namespaces, the beta count); the Legacy UI exists: `ToggleLegacySystemUI`, `LegacySystemFrame_LoadUI`, `ToggleLegacyChallenges`, `ShowLegacyChallenge`, `LegacyMicroButton`, `LegacyChallengeViewedUtil` | section 2 [file] |
| EI-E-04 | Client text confirms three trees (Professions, Adventure, Resourcefulness), "Legacy Points %d / %d", a **seasonal** spending cap on points "in total", a reward track and challenges; a "Talented" perk grants class talent points; `Enum.TraitConfigType.CamelotCombat = 4` | section 2 [file]; the trait link is [inferred] |
| EI-E-05 | `Blizzard_APIDocumentation` and `Blizzard_APIDocumentationGenerated` are installed (loadable on demand) | section 1 [file] |
| EI-E-06 | Launch has named realms ("CAMWOW US2 Realm N PvE"); one account's characters can sit on different realms | section 3 [file] |
| EI-E-07 | DataStore 2026.10.14 on the launch build: money, level, class and a carried item count equal the live values; the roster spans both realms; no "Unknown" names, no duplicate GUIDs | section 3 [file] |
| EI-E-09 | Retail enums with a member named "Legacy" exist (NamePlateStyle, RespecType, RaidAuraOrganizationType, Itemsetflags, BnetAccountFlag); `C_GameRules.GetForeverExperiencePreset()` returned 1 (`Enum.ForeverExperiencePreset`: Classic 0, Enhanced 1) | TP1_Report_Run1.md section 7 [file] |
| EI-E-10 | BugGrabber `GetDB()` is readable; on the user's setup the recorded errors came from TradeSkillMaster, Accountant_Classic, Zygor, Questie and BugGrabber, none from EmpireIntelCheck or GoldIntel | section 7 [file] |
| EI-E-11 | The in-client API documentation (`Blizzard_APIDocumentationGenerated`) lists 410 systems; none is the Forever Legacy system. `C_GameRules` documents Forever rules (`GetForeverExperiencePreset`, `IsHardcoreActive`, `IsSelfFoundAllowed`) | TP1_Report_Run1.md section 9 [file] |
| EI-E-12 | 20 live `C_` namespaces are undocumented, among them `C_Seasons`, `C_Reincarnation` and `C_Trophy`; the documentation covers 286 namespaces, 272 are live | section 9 [file] |
| EI-E-13 | `C_Seasons.GetActiveSeason()` = 0 and `HasActiveSeason()` = false on the user's realm; `C_Trophy` holds only `Monument...` functions; `C_Reincarnation` = `GetReincarnatingCharacter`, `IsReincarnating`, `StartReincarnation`, `StopReincarnation` (not called) | TP1_Report_Run1.md section 10 [file] |
| EI-E-14 | Profession skill line ids on Forever: Mining 186, Skinning 393, Cooking 185, Tailoring 197 (classic ids); a level-12 character has max XP 10100 and a level-6 one 3600 (classic table); `IsResting()` returns false outside a rest area | P2-1_Report.md [file] |
| EI-E-15 | Build 1.60.1/70862 (Nov 6 2026) replaced 70790; `C_Seasons` is gone; EmpireIntel and the check ran on it without errors; level-25 max XP is 34000 | TP1_Report_Run1.md section 11 [file] |
| EI-E-16 | At level 25 the Legacy system unlocks; `Blizzard_LegacySystem` loads on opening the pane. It defines the Lua table `LegacySystem` (`GetCurrencyInfo`, `GetFilteredChallenges`, `GetChallengeIndices`, `IsChallengeVisible`). The challenges are an achievement category (`GetCategoryNumAchievements`); the points are shown from currency info | section 11 [file] |
| EI-E-18 | Legacy window: Progress Track rewards at 15 / 25 / 40 / 55 points; three trees (Professions, Adventure, Resourcefulness), each 9 nodes and 25 ranks, two hidden "?" nodes each; "Available points" counter; "Apply Changes" commits | Legacy_Rules.md section 2 [screenshot] |
| EI-E-19 | **`/reload` loads new files added to an existing addon folder's TOC** (build 70862, 2026-11-08): EmpireIntel 0.4.0 (two new files) and EmpireIntelCheck 0.1.6 (one new file) both ran their new code after only a `/reload`. The old rule "a new TOC file needs a full restart" (inherited from classic clients) does not hold on Forever. Not yet observed: a **new addon folder** (for example the P2-4 plan folder) after `/reload` | user's chat lines, 2026-11-08 [file] |
| EI-E-20 | On Forever, `GetCategoryList()` returns the 29 Legacy challenge categories (ids from the client): Classes 15568 (Druid 15577, Hunter 15578, Mage 15579, Paladin 15580, Priest 15581, Rogue 15582, Shaman 15583, Warlock 15584, Warrior 15585); Tradeskills 15586 (Alchemy 15587, Blacksmithing 15588, Enchanting 15589, Engineering 15590, Leatherworking 15591, Tailoring 15592); Player vs. Player 15595 (Ranks 15597, Reputations 15598, Season Journey 15620); Adventure 15596 (Explorer 15607, Eastern Kingdoms 14777, Kalimdor 14778); Dungeons 15593; Raids 15594 (Tier 1 Gear 15626); Do Not Display 15425. No title contains "Legacy" | TP1_Report_Run1.md section 12 [file] |
| EI-E-21 | `LegacySystem.GetCurrencyInfo()` (no argument, available once the pane has loaded) returns `quantity`, `maxQuantity`, `renownCurrency`, `spent`, `spentInTree` and `traitCurrencyID` = 4225: the Legacy points are a trait currency. With 1 point earned and none spent, all three counts read 1, so which field is "earned" and which "available" is not yet known. The pane shows "Legacy Points 1 / 65" | section 12 [file] [screenshot] |
| EI-E-22 | The 65 Legacy challenges are achievements whose reward text is "Earn 1 Legacy Point." (English client). Ids: classes Warrior 61499-61501, Druid 61502-61504, Hunter 61989/61992/61993, Mage 61994-61996, Paladin 61997-61999, Priest 62000-62002, Rogue 62003-62005, Shaman 62006-62008, Warlock 62009-62011 (Novice 25 / Experienced 45 / Master 60, "for the first time on a <class>"); crafts Alchemy 62012-62014, Blacksmithing 62015-62017, Enchanting 62018-62020, Engineering 62021-62023, Leatherworking 62024-62026, Tailoring 62028-62030 (Journeyman 150 / Expert 225 / Artisan 300); Spelunkers 62031-62033 (6 / 10 / 17 steps); raids 62034 (13 steps), 62035 (8), 684 Onyxia; PvP ranks 62041-62045; battleground exalted 62046-62049 (Alterac Valley, Arathi Basin, Warsong Gulch, Darkspear Islands); Field of Honor weeks 4/7/10 63340-63342; Adventure 62054 (Lord Valthalak), 62382 (Explorer: "Have a character with the Explore Azeroth achievement"). 46 supporting achievements without a reward: Explore Azeroth 62053, Explore Eastern Kingdoms 62353 (23 zones), Explore Kalimdor 62355 (20 zones) and the zone achievements. The achievement-points field is not the Legacy value | TP1_Report_Run1.md section 13 [file] |
| EI-E-23 | Challenge steps from the client (run 9): Experienced Spelunker = City of Dalaran, Blackfathom Deeps, Gnomeregan, The Drowned City, Scarlet Monastery (Graveyard, Library, Armory, Cathedral), Razorfen Kraul, Krol'dok Stronghold. Master Spelunker = Razorfen Downs, Uldaman, Zul'Farrak, Maraudon, Alcaz Prison, The Temple of Atal'Hakkar, Blackrock Depths, Blackmaw Hold, Lower and Upper Blackrock Spire, Scholomance, Stratholme Live and Dead, **Dire Maul East, North and West**, The Shaper's Terrace. Novice's first step is "Ragefire Chasm or Hall of Thanes". The Explorer chain is complete-achievement links; zone sub-areas show partial progress on the logged-in character. The achievement data is available at login, without the pane | TP1_Report_Run1.md section 14 [file] |
| EI-E-24 | Spending 1 Legacy point (C1, 2026-11-08 04:04-04:09 UTC) changed `LegacySystem.GetCurrencyInfo()` from quantity 1 / spent 0 to **quantity 0 / spent 1**. maxQuantity 1, renownCurrency 1, spentInTree 0 and traitCurrencyID 4225 are unchanged. quantity + spent = maxQuantity in both reads. Challenge and step data did not change because of the spend. **Inferred (user and Claude), one data point each:** quantity = points available now; spent = points spent; maxQuantity and renownCurrency = points earned (indistinguishable so far; both equal the 1 completed challenge point). spentInTree: unexplained; it stayed 0 in four reads with the pane open (run 11, which tree each read was on is not recorded) (TP1_Report_Run1.md sections 16 and 17) | TP1_Report_Run1.md section 15 [file] |
| EI-E-25 | Earning a second Legacy point changed `GetCurrencyInfo()` to quantity 1, spent 1, maxQuantity 2, renownCurrency 2, spentInTree 0. **quantity = points available (confirmed: -1 on a spend, +1 on an earn).** spent = points spent (rose on the spend, unchanged on the earn). maxQuantity and renownCurrency both equal the points earned (still indistinguishable). quantity + spent = maxQuantity in all reads. spentInTree stayed 0 with the Adventure tree open, where the spent point is: it does not follow the selected tree | TP1_Report_Run1.md section 18 [chat line] |
| EI-E-26 | `LegacySystem.GetCurrencyInfo()` counts **applied** points only: a point placed in a tree but not applied left quantity 1 / spent 1; after "Apply Changes", quantity 0 / spent 2. **spent = points applied (confirmed: +1 on each of two spends, unchanged on an earn).** spentInTree stayed 0 in all 7 reads (with or without the spent tree open, placed or applied); it is not "placed but not applied" | TP1_Report_Run1.md section 19 [chat lines] |
| EI-E-27 | **spentInTree does not follow the selected tree:** 0 with the Adventure tree page open, whose counter shows 2, and 0 on every other tree (no-argument call). Closed as unusable without a tree argument. **Achievement progress scope:** completed challenges and their steps (for example dungeon steps) are account-wide; exploration areas (the Explorer chain's zone criteria) are per character | TP1_Report_Run1.md section 22 [file] [screenshot] |
| EI-E-28 | **Rested XP while logged out in an inn accrues at the classic full rate** (5% of a level per 8 h): C1 Paladin 27 projected 1992 XP after about 8.25 h, live 2012 (1.0%, about 0.5% allowing for the 2 minutes between reads); C2 Priest 6 predicted about 2049 XP over about 9.2 h, measured 2050. Not covered: the outside-rest-area quarter rate, the 1.5-level cap, very long gaps | P2-3_Report.md section 3 [chat lines] |
| EI-E-17 | On Forever, DataStore `GetModuleLastUpdateByKey('DataStore_Characters', key)` returns nil for every character; `/ei alts` then dates DataStore values by the last logout | section 11 [file] |
| EI-E-08 | At `PLAYER_LOGOUT`, `UnitLevel` and `UnitXPMax` returned 1 and 0 for a level-2 character: unit data is unreliable at logout | section 4 [file] |
