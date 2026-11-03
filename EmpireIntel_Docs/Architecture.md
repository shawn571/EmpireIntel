# EmpireIntel Architecture v1

DOC VERSION: 1.0.0  |  DATE: 2026-11-03  |  STATUS: **Proposed, awaiting the user's approval**  |  Decisions.md wins over this file; Compatibility_Notes.md wins on client facts

**EmpireIntel shows a WoW Forever player's whole account, all characters together.** It covers gold, carried and banked items, mail about to expire, and how fresh each number is. Alt data comes from DataStore when it is installed. Otherwise EmpireIntel uses its own snapshot of each character, taken at that character's last login. The design reuses GoldIntel's proven platform layer (GoldIntel_Reuse_Audit.md). **The first thing built is Test Package 1, the Legacy API check.** No other code is written until it has run in the live client and the user has reviewed the result.

The product scope in section 1 is an **assumption** made from the project name and the brief "use Altoholic and DataStore for alt data". Question Q-1 asks the user to confirm or correct it.

## 1. Scope v1 (assumed, Q-1)

In scope:
- An account roster: every character the account has played, keyed by GUID. For each: name, level, class, faction, gold, last seen, and the source and age of every value.
- Account totals: gold across characters, and item counts across bags and bank ("how many Linen Cloth do I own in total").
- Mail watch: mails that will expire or return soon, per character.
- Commands only (`/ei roster`, `/ei gold`, `/ei item <id|link>`, `/ei mail`, `/ei sources`, `/ei check`). No windows in v1.

Out of scope for v1: income attribution and GPH (GoldIntel's job), auction scanning or pricing, professions and recipes, cross-account or guild data, UI frames, sync between machines.

## 2. Principles (ordered; earlier wins)

1. **Correct over complete.** A number that cannot be sourced is shown as unknown, never as 0.
2. **Every value carries provenance:** `{ v, src, asOf, conf }`, where `src` is `self` or `datastore`. Totals list their parts and the oldest part's age.
3. **Third-party data is optional.** EmpireIntel works, with less coverage, when DataStore is absent, disabled, partly installed or broken (license, D-003).
4. **Two boundaries, each enforced by a static test:** only `Platform/` touches WoW globals (inherited invariant), and only `Bridge/` touches third-party addon globals (`DataStore`, `AddonFactory`, `Altoholic`).
5. **GUID is identity.** Names, realm text and DataStore keys are attributes (D-004).
6. **Read-only toward other addons.** EmpireIntel never writes to another addon's tables or saved variables and never calls their scan or request functions.
7. Modern API only, Lua 5.1, the GoldIntel file hygiene rules (C-1..C-6).

## 3. Layers

```
+--------------------------- Platform/ (only WoW API users; from GoldIntel) ----------------------------+
| Platform  Events  Clock  Scheduler  Unit  Money  Items  Bags  SavedVars  Slash  Probe                  |
+--------------------------------------------------------------------------------------------------------+
           | normalized events, plain tables                          (no WoW globals above this line)
           v
 +----------------+        +-----------------------------------------------+
 | Sources/Self   |        | Bridge/ (only third-party addon users; new)   |
 | snapshot of    |        |   DataStoreBridge: detect, version, method    |
 | the logged-in  |        |   check, read-only getters, error isolation   |
 | character      |        +-----------------------------------------------+
 +----------------+                         |
           \                                v
            +--------> Roster (merge by GUID, provenance, conflict rule) --> Aggregates --> Commands
                                    |
                     Store/ (EmpireIntelDB account, EmpireIntelCharDB; migrations; from GoldIntel)
                     Core/  (registry, bus, capability stages, config, boot; from GoldIntel)
```

| Module | Responsibility | Origin |
|---|---|---|
| Platform/* | WoW API access, capability registry, event allow-list, identity, money, bags | GoldIntel, renamed (audit section 1) |
| Core/* | Module registry, typed bus, capability stages, config, slash, boot | GoldIntel; `Slash.lua` rewritten |
| Store/* | Saved variables, schema, copy-then-commit migrations, pruning | GoldIntel; new chain from schema 1 |
| Sources/Self | On login and at `BAG_UPDATE_DELAYED` / `PLAYER_MONEY` (throttled), snapshot of the current character: identity, money, carried items; bank only while the bank is open (TP-1 confirms the read) | New, on GoldIntel adapters |
| Bridge/DataStoreBridge | Detects DataStore and its modules, checks that every method EmpireIntel uses exists, wraps each call in `pcall`, converts results to plain tables with `src = 'datastore'` and `asOf` from `GetModuleLastUpdate` | New |
| Roster | Merges both sources per GUID; applies the conflict rule (section 4); flags duplicates and "Unknown" names | New, pure Lua |
| Aggregates | Totals for gold and item counts, with parts and oldest age | New, pure Lua |
| Commands | `/ei ...` output | New |

## 4. Data model and merge rule

```
EmpireIntelDB (account)
  schema, meta, compat                      -- compat owned by Probe (GoldIntel rule)
  roster[guid] = {
    name = { v, src, asOf }, level = {...}, class = {...}, faction = {...},
    money = { v, src, asOf }, lastSeen = t,
    dsKey = 'Default.<Realm>.<First Last>' | nil,      -- attribute, never identity
    flags = { unknownName = bool, dsMissing = bool, duplicateOf = guid | nil },
    items = { [itemID] = { bags = n, bank = n, src, asOf } },   -- bounded, section 6
  }
EmpireIntelCharDB (per character): last self snapshot only
```

Merge rule per field: the **newest** `asOf` wins. On a tie, `self` beats `datastore`. For the logged-in character, `self` is live and always wins, and the DataStore value is kept only for the cross-check (section 7, T5). A character that DataStore no longer lists keeps its record with `dsMissing = true` (DataStore can delete keys itself, Reference section 4). Records are deleted only by an explicit user command.

## 5. Events

v1 registers only events GoldIntel proved live on Forever: `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_LOGOUT`, `PLAYER_MONEY`, `BAG_UPDATE_DELAYED`. Bank state is polled from the frame, the same way GoldIntel polls MailFrame (E-34 pattern), until a bank event is verified. Unproven events are never registered (inherited D-025).

## 6. Performance and storage

Handlers only enqueue. Snapshots run on the scheduler, at most once per 2 s. A bag scan costs under 1 ms (GoldIntel E-17: 44 slots in 0.74 ms). Item records are capped per character (proposal: 2,000 item ids), with the cap reported in `/ei sources`. Saved data stays within a 2 MB target.

## 7. Test Package 1: Legacy API check (first deliverable; design only)

**Purpose.** Before EmpireIntel depends on anything, measure on the live Forever client:
(a) which legacy APIs exist next to their modern replacements;
(b) whether DataStore's Forever path behaves as the source review says;
(c) whether the identity facts (GUID, two-part name, realm text) hold on the **launch** build.

Launch is 2026-11-04. GoldIntel's evidence is from beta builds 70338 to 70450, and launch may change the API, the realm model or the interface number (GoldIntel OI-11).

**Form.** A throwaway, read-only addon `EmpireIntelCheck` (slash `/eicheck`, saved variable `EmpireIntelCheckDB`). It is separate from EmpireIntel, like GoldIntel's `GIProbeLoot`, and is not part of the product. Packaged with the GoldIntel build tool (renamed).

**Safety rules (from GoldIntel's lab protocol):**
- It registers **no events**. It runs on `/eicheck run` after login.
- It never calls a function with side effects: no `Query*`, `Request*`, `Send*`, `Pickup*`, `Use*`, nothing that opens a frame, and no DataStore scan.
- Function presence is read with `type(_G[name])`; values are read only from pure getters, every call is wrapped in `pcall`, and every result goes through `issecretvalue` before use.
- Output is bounded and ASCII-only. It goes to the chat frame, a copy window, and `EmpireIntelCheckDB` (read back from the file after `/reload`).
- It writes to no other addon's tables. Lua 5.1, rules C-1..C-6.

**Tests:**

| ID | Question | Method | Pass rule | Baseline (GoldIntel evidence, [inherited]) |
|---|---|---|---|---|
| T1 | Client profile | `GetBuildInfo()`, `WOW_PROJECT_ID`, `WOW_PROJECT_CAMELOT`, Lua feature checks (`load`, `table.unpack`, `bit`) | Values recorded; differences from the baseline listed | 1.60.1 / Interface 16001 / project 18 / Lua 5.1 (E-01, E-04) |
| T2 | Legacy versus modern presence | `type(_G[x])` for each pair in the table below | Every row recorded as present, absent or unknown; any change from the baseline is a finding | See the table below |
| T3 | Identity | `UnitGUID`, both returns of `UnitName('player')`, `GetRealmName`, `GetNormalizedRealmName` | GUID present; the second name return is recorded; realm text recorded; any 'Unknown' name flagged | GUID `Player-<server>-<id>`; realm 'Classic Beta PvE' in beta (E-07) |
| T4 | DataStore presence | `C_AddOns.GetAddOnInfo` / `IsAddOnLoaded` for AddonFactory, DataStore and the 7 v1 modules; their `Version` metadata; `AddonFactory.isForever`, `isMainline`, `buildVersion` | Each addon: loaded / installed-not-loaded / missing; flags recorded | Source review: isForever = isMainline = true at 16001 |
| T5 | DataStore method surface and cross-check | `type(DataStore[m])` for every method in Reference section 4; then read-only calls: `GetCharacterIDByGUID(UnitGUID('player'))`, `GetCharacterKey`, `GetCharacters`, and for the current character `GetMoney` versus the live `GetMoney()`, `GetCharacterLevel` versus `UnitLevel`, plus `GetContainerItemCount` of one carried item versus a C_Container count | All methods exist; the GUID resolves to this character's key; **money and level equal the live values**; the item count matches | n/a (new) |
| T6 | Roster health | For each DataStore character: key, realm part, name equal to "Unknown", same GUID under two keys, `GetModuleLastUpdate` age | Recorded; duplicates and Unknown names counted | Altoholic notes the Unknown-name bug |
| T7 | Bank read | With the bank open (user step): `C_Container.GetContainerNumSlots` for the bank bag ids, `BankFrame:IsShown()` | Readable, non-secret | Not yet measured anywhere |

T2 pairs (legacy global, modern replacement):

| Family | Legacy global(s) | Modern | GoldIntel baseline |
|---|---|---|---|
| Containers | `GetContainerNumSlots`, `GetContainerItemInfo`, `GetContainerItemLink` | `C_Container.*` | legacy ABSENT, modern works (E-17) |
| Skill lines | `GetNumSkillLines`, `GetSkillLineInfo`, `ExpandSkillHeader` | `GetProfessions`, `GetProfessionInfo` | legacy ABSENT (E-05) |
| Trade skill / craft | `GetTradeSkillInfo`, `GetNumTradeSkills`, `GetCraftInfo` | `C_TradeSkillUI` | legacy ABSENT (E-05) |
| Auction | `QueryAuctionItems`, `GetAuctionItemInfo`, `GetNumAuctionItems` | `C_AuctionHouse` | legacy ABSENT (E-05) |
| Addon info | `GetAddOnInfo`, `GetAddOnMetadata`, `IsAddOnLoaded` | `C_AddOns.*` | `GetAddOnInfo` ABSENT (E-08); the other two unmeasured |
| Spell info | `GetSpellInfo` | `C_Spell.GetSpellName`, `C_Spell.GetSpellInfo` | `C_Spell.GetSpellName` works; global unmeasured. This is the DataStore fragile point (Reference section 3) |
| Item info | `GetItemInfo`, `GetItemInfoInstant` | `C_Item.*` | both present (E-17, E-30) |
| Quest log | `GetQuestLogTitle`, `GetNumQuestLogEntries` | `C_QuestLog.*` | modern present (E-18); legacy unmeasured |
| Reputation | `GetFactionInfo`, `GetNumFactions` | `C_Reputation.*` | unmeasured |
| Talents | `GetTalentInfo`, `GetNumTalentTabs` | `C_Talent*` / `C_ClassTalents` | unmeasured |
| Currency | `GetCurrencyInfo` | `C_CurrencyInfo.*` | unmeasured |
| Mail | `GetInboxHeaderInfo`, `TakeInboxMoney` (globals) | `C_Mail.*` | both present (E-29) |
| Played time | `RequestTimePlayed` (presence only, never called) | n/a | unmeasured |

**Offline test plan (before anything goes to the client):** the package runs in the reused GoldIntel harness against three fake clients: (1) the Forever beta profile built from GoldIntel's evidence; (2) the same with DataStore stubbed present and consistent; (3) DataStore present but with a missing method, a wrong money value and an "Unknown" duplicate. Expected: no error in any configuration; each fault is reported, not raised. Plus the static rules C-1..C-6, a check that the package contains no `RegisterEvent` call, and a check that it calls only allow-listed getters.

**Live run (user steps, about 5 minutes):** (1) install with DataStore and Altoholic Forever **disabled**, `/eicheck run`; (2) enable them, log in on two characters in turn, then `/eicheck run` on the second; (3) open the bank, `/eicheck bank`; (4) `/reload` and send `EmpireIntelCheck.lua` from SavedVariables. Run on the launch build.

**Exit criteria.** Every T-row has a recorded result. Every change from the baseline is filed in Compatibility_Notes.md with an evidence id (EI-E-nn). T5 money and level match exactly. The user then decides D-005 (adopt DataStore fully, for some modules only, or not at all) and whether Phase 2 begins.

## 8. Phases and gates

| Phase | Content | Gate |
|---|---|---|
| 0 | Governance, audit, reference review, this architecture | User approves this document (now) |
| 1 | Test Package 1 code, offline tests, live run, evidence | TP-1 exit criteria; user decides D-005 |
| 2 | Port Platform / Core / Store / harness from GoldIntel; static tests incl. the Bridge rule | Suite green under Lua 5.1 and 5.3; loads in the client with no error |
| 3 | Sources/Self and Bridge/DataStoreBridge | Live cross-check equals TP-1 T5 |
| 4 | Roster, Aggregates, Commands | Live session on three or more characters; totals explained part by part |
| 5 | UI (window, tooltip counts) | Separate scope decision |

## 9. Invariants (each gets an automated test)

1. No WoW global outside `Platform/`; no third-party addon global outside `Bridge/`.
2. A total equals the sum of its listed parts.
3. Every stored value has `src` and `asOf`.
4. A character record is never deleted except by an explicit user command.
5. EmpireIntel never writes to a table it does not own (checked with a fake DataStore that is frozen in tests).
6. With DataStore absent, every command still answers, with self data only.
