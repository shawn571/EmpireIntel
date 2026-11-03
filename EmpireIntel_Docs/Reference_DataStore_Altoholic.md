# Reference review: DataStore and Altoholic on WoW Forever

DOC VERSION: 1.0.0  |  DATE: 2026-11-03  |  Method: source read only, nothing copied, nothing run in a client

> **Update S-002 (2026-11-03):** with the Legacy scope (D-010), the DataStore modules that matter are core, **Characters** (level, class, `GetRestXP`, `GetRestXPRate`, `IsResting`, last logout) and **Crafts** (`GetProfessions`, `GetProfessionInfo`). Containers, Mails and Inventory are no longer needed. **No DataStore module and no Altoholic file reads Forever Legacy data.** DataStore_Achievements' `Legacy*` ids are retail achievement categories, unrelated, and that module has no Forever TOC. DataStore_Characters notes that `GetXPExhaustion` 'is not reliable (sometimes returns 0)'.

**Verdict: they hold up on Forever on paper. Use DataStore as an optional run-time data source; Altoholic itself is not needed.** Both have maintained Forever builds, and the Forever code paths avoid the pre-modern APIs the Forever client lacks. Nothing here is verified in the live client yet: Test Package 1 (Architecture.md section 7) makes that check before any EmpireIntel code depends on them.

Sources read (public GitHub, shallow clones, 2026-11-03): [Thaoky/DataStore](https://github.com/Thaoky/DataStore) (version 2026.10.14), the 15 `Thaoky/DataStore_*` module repositories, `Thaoky/AddonFactory`, `Thaoky/Altoholic_Forever` (1.60.005, commit 8739698, 2026-10-14). Release dates were cross-checked against [DataStore pull request 18](https://github.com/Thaoky/DataStore/pull/18) (merged 2026-09-30, "Update for Altoholic Forever 1.60.001"). The CurseForge pages and their comment threads could not be read from this session (blocked by the network policy), so user bug reports are **not** reviewed.

## 1. License: runtime use only

| Project | License | Consequence for MIT EmpireIntel |
|---|---|---|
| DataStore and every DataStore_* module | "All Rights Reserved unless otherwise explicitly stated" | No code copied, no files bundled, no modified copies in the repo or the package |
| Altoholic (Forever) | "All Rights Reserved" | Same |
| AddonFactory (DataStore's base library) | All Rights Reserved header | Same |

EmpireIntel may call their public functions at run time when the user has installed them, as any addon calls another addon's API. That is the only form of use (Decisions D-003). This review describes behavior in our own words, the same way GoldIntel's Accountant Classic and Auctionator reviews do.

## 2. Forever support status

- DataStore core TOC: `## Interface: 120105, 50504, 20505, 11509, 16001` (16001 = Forever 1.60.1). Changelog: Forever support since 2026-09-30, version detection centralized in AddonFactory on 2026-10-02.
- Altoholic Forever is a separate addon line (TOC `## Interface: 16001`, 1.60.001 to 1.60.005, 2026-09-30 to 2026-10-14). The author's note in the changelog: it is based on the retail version "since the game uses the same engine, and mostly the same API", and he saw no Lua errors.
- Altoholic Forever depends on 14 DataStore modules plus AddonFactory.

| DataStore module | Forever TOC | EmpireIntel v1 interest |
|---|---|---|
| DataStore (core) | yes | required if DataStore is used: character list, keys, GUID lookup |
| Characters | yes | **yes**: level, class, faction, money, played time, last logout, location |
| Containers | yes | **yes**: bags, bank, reagent bag, item counts |
| Inventory | yes | yes: equipment, average item level |
| Mails | yes | yes: mail counts, expiry |
| Auctions | yes | later: owned auctions and bids |
| Crafts | yes | later: professions and ranks |
| Currencies | yes | later |
| Quests, Reputations, Spells, Talents, Stats, Agenda | yes | not in v1 |
| Achievements, Pets | **no** | not needed |

## 3. Does the Forever code path use pre-modern APIs?

GoldIntel measured these pre-modern APIs (GoldIntel calls them "legacy"; unrelated to the Forever Legacy points system) as ABSENT on Forever: skill lines (`GetNumSkillLines`, `GetSkillLineInfo`, `ExpandSkillHeader`), the legacy auction family (`QueryAuctionItems`, `GetAuctionItemInfo` and related), legacy trade skills, global `GetAddOnInfo`, global `GetContainerNumSlots` / `GetContainerItemInfo` (E-05, E-08, E-17 [inherited]).

How DataStore picks a path: AddonFactory reads `select(4, GetBuildInfo())`. An interface from 16000 to 19999 sets `isForever = true` **and** `isMainline = true`, so Forever takes the retail ("mainline") branches.

| Area | Pre-modern calls present in the source? | On the Forever path? | Evidence (file, our reading) |
|---|---|---|---|
| Addon metadata | `GetAddOnMetadata` | No: `C_AddOns.GetAddOnMetadata` is preferred, global only as fallback | DataStore.lua line 19 |
| Spell names | `GetSpellInfo` | Classic only; Forever uses `C_Spell.GetSpellName` (Enum.lua line 7). Some Crafts lines write `GetSpellInfo or C_Spell.GetSpellName`, which uses the pre-modern global **if it exists** | Enum.lua, Crafts_Retail.lua line 20 |
| Auctions | `GetNumAuctionItems`, `GetAuctionItemInfo`, `GetAuctionItemLink` | No: `isMainline` selects `C_AuctionHouse` | DataStore_Auctions.lua lines 19 to 20 |
| Professions | `GetNumSkillLines`, `GetSkillLineInfo`, `ExpandSkillHeader` | No: `ScanProfessionLinks` takes a Forever branch that calls `GetProfessions` with a Forever-specific return order (prof1, prof2, firstAid, fish, cook) | Crafts_Retail.lua lines 301 to 330 |
| Trade-skill recipes | `GetTradeSkillInfo`, `GetNumTradeSkills`, `GetCraftInfo` | No: `isMainline` selects the C_TradeSkillUI scan | Crafts_Retail.lua line 646 |
| Containers | No bare pre-modern calls: every bag and bank read is `C_Container.*` (the only pre-modern name is in a comment) | n/a | DataStore_Containers.lua lines 100 to 201, API/PlayerBank.lua, API/ReagentBank.lua |
| Character name | `UnitName('player')` | Replaced by `AddonFactory:GetPlayerName()`, which returns "First Last" on Forever (two-part names) | Tools.lua line 122 |

Our reading: no pre-modern-only call sits on a Forever code path. **Fragile point:** the `GetSpellInfo or C_Spell.GetSpellName` pattern. If a Forever patch adds a global `GetSpellInfo` with the classic return shape, behavior changes silently. TP-1 records whether that global exists.

## 4. Data model facts that shape EmpireIntel

- **Character key = `Account.Realm.Name`**, with `Account = "Default"`, `Realm = GetRealmName()`, Name = "First Last" on Forever (DataStore.lua lines 22 to 26). The key contains the realm text.
- **GUID lookup exists**: `DataStore:GetCharacterIDByGUID(guid)` and `GetCharacterKey(id)`. EmpireIntel keys by GUID (as GoldIntel does) and stores the DataStore key as an attribute.
- **`SanitizeCharacters()`** (2026-10-02) deletes character keys DataStore judges invalid. Characters can therefore disappear from DataStore. EmpireIntel must not treat a missing key as a deleted character.
- **Known Forever client bug (from the Altoholic Forever changelog, 1.60.001):** the game sometimes returns "Unknown" as the character name, so a character can appear twice. Not verified by us. Consequence: never key by name; flag names equal to "Unknown"; de-duplicate by GUID.
- **Freshness:** data for a character is as old as that character's last login (or the last time a window was opened, for bank and mail). Each module keeps a last-update time (`GetModuleLastUpdate`). EmpireIntel shows the age with every number.
- Public getters EmpireIntel v1 would call (names from the source; signatures to be confirmed by TP-1): core `GetCharacters`, `GetCharacterIDByGUID`, `GetCharacterKey`, `GetModuleLastUpdate`; Characters `GetCharacterName`, `GetCharacterLevel`, `GetCharacterClass`, `GetCharacterFaction`, `GetMoney`, `GetPlayTime`, `GetLastLogout`, `GetLocation`; Containers `GetContainerItemCount`, `GetNumBagSlots`, `GetNumFreeBagSlots`, `IterateBags`; Mails `GetNumMails`, `GetNumExpiredMails`, `GetClosestReturnsOnExpiry`; Inventory `GetAverageItemLevel`.

## 5. Risks this review creates (also in Risk_Register.md)

R-03 launch realm change re-keys DataStore characters; R-04 "Unknown" name duplicates; R-05 DataStore API drift (single author, no published API contract); R-06 license forbids bundling, so EmpireIntel must work without DataStore; R-07 static reading only, no live verification.

## 6. Altoholic itself

Altoholic is the UI that sits on top of DataStore. EmpireIntel needs the data, not the UI, so v1 depends on neither. If Altoholic is installed, it simply shares the same DataStore tables. EmpireIntel never reads Altoholic's own saved variables.
