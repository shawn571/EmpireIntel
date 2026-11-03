# WoW Forever Compatibility Notes (EmpireIntel)

DOC VERSION: 1.0.0  |  DATE: 2026-11-03  |  Wins over Architecture.md on client facts

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

## 2. Legacy versus modern API [inherited]

| Family | Legacy | Modern | GoldIntel id |
|---|---|---|---|
| Containers | `GetContainerNumSlots`, `GetContainerItemInfo` ABSENT | `C_Container` works, 44 slots scanned in 0.74 ms, non-secret | E-17 |
| Skill lines | `GetNumSkillLines`, `GetSkillLineInfo`, `ExpandSkillHeader` ABSENT | `GetProfessions` / `GetProfessionInfo` present | E-05 |
| Trade skills | legacy ABSENT | `C_TradeSkillUI` present | E-05 |
| Auction | `QueryAuctionItems` family ABSENT | `C_AuctionHouse` (85 functions) | E-05, E-35 |
| Addon info | global `GetAddOnInfo` ABSENT | `C_AddOns.GetAddOnInfo` (6 returns) | E-08 |
| Item info | `GetItemInfo` present (17 returns, cached items only) | `C_Item.*` present | E-17, E-30 |
| Mail | inbox globals present | `C_Mail` present | E-29 |

## 3. Events proven live [inherited]

`PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_LEAVING_WORLD`, `PLAYER_LOGOUT` (handlers can still write saved variables), `PLAYER_MONEY`, `BAG_UPDATE_DELAYED`, plus GoldIntel's collection events (E-13, E-15, E-32, GoldIntel Architecture AC-1). `COMBAT_LOG_EVENT_UNFILTERED` is never registered. Probing by registration is forbidden: a blocked registration shows a popup that pcall cannot hide (GoldIntel D-025).

## 4. Third-party facts (source reading, not verified)

- AddonFactory treats interface 16000..19999 as Forever and sets `isForever` and `isMainline` (Reference_DataStore_Altoholic.md section 3).
- The Altoholic Forever changelog reports that the client sometimes returns "Unknown" as the character name.

## 5. Evidence ledger (EmpireIntel)

| ID | Fact | Source |
|---|---|---|
| (none yet) | | |
