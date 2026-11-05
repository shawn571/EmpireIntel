# GoldIntel Reuse Audit for EmpireIntel

DOC VERSION: 1.0.0  |  DATE: 2026-11-03  |  Audited: shawn571/GoldIntel at commit a21e071 (0.5.1-passive, contract 1.9.0)

> **Update S-002 (2026-11-03):** EmpireIntel's scope is now the Forever Legacy system, rested XP and professions (D-010). The reuse verdicts below still hold. Money, Items and Bags are now needed only for TP-1's DataStore cross-check, not for the product. Section 3 is updated. Q-2 is resolved: the repository is private.

**Result:** EmpireIntel can take GoldIntel's platform layer, core, store, test harness, packaging tool, client evidence and governance almost unchanged. The money and item ledgers are GoldIntel's own product and stay there. The audit was a read of the source and docs. The test suite was also run: **1255 passed, 0 failed** under Lua 5.3, the runner the README names (`texlua`).

Nothing was copied in this session. Copying is a Phase 2 task that needs the user's approval (TODO.md), and it would put GoldIntel code, which is private today, into a public repository (see Q-2 in Decisions.md).

## 1. Verdict per area

| GoldIntel area | Files (lines) | Verdict | What changes for EmpireIntel |
|---|---|---|---|
| Platform core: env indirection, capability registry, diagnostics, lifecycle | `Platform/Platform.lua` (444) | **Reuse as is** | Rename the namespace header and version constants |
| Event routing: allow-list, `IsEventValid` check, `IsEventRegistered` verification, restricted-event refusal, quarantine | `Platform/Events.lua` (542) | **Reuse as is** | Replace the event allow-list. EmpireIntel v1 needs very few events (section 3) |
| Clock, Scheduler (C_Timer with OnUpdate fallback) | `Clock.lua` (81), `Scheduler.lua` (262) | **Reuse as is** | None |
| Unit identity (GUID, First-Last name, class, level, faction, professions via `GetProfessions`) | `Unit.lua` (256) | **Reuse as is** | Already modern-only (D-027). Matches the DataStore Forever path |
| Money, Items, Bags (C_Container, reagent bag 0..5) | `Money.lua` (133), `Items.lua` (53), `Bags.lua` (80) | **Reuse as is** | Used for the self-snapshot and the DataStore cross-check |
| SavedVariables and slash adapters | `SavedVars.lua` (49), `Slash.lua` (44) | **Reuse, rename** | SV names become `EmpireIntelDB` / `EmpireIntelCharDB`; slash becomes `/ei` |
| Capability probe and report | `Probe.lua` (335) | **Reuse, extend** | Becomes the base of Test Package 1 (Legacy check, platform section). The probe list is replaced |
| Map, Loot, Merchant, Quest, Trade, Chat, Mail, Auction adapters | 9 files (about 1,100) | **Not in v1** | GoldIntel-specific signal collection. Mail and Auction adapters may come back if EmpireIntel needs its own mail or AH scan |
| Core: module registry, typed bus, capability stages, config, slash, boot order | `Core/*.lua` (1,612) | **Reuse, trim** | `Core/Slash.lua` holds the GoldIntel command set (56 name references): rewrite it. The rest needs only a rename |
| Store: open outcomes (created/ok/migrated/readonly/degraded), copy-then-commit migrations, compat guarantee, pruner | `Store/*.lua` (597) | **Reuse as is** | Start a fresh migration chain at schema 1. GoldIntel's schema 2 ledger step is not taken |
| Collect/, Ledger/ (expectations, reconciler, lots, cash, trace) | 14 files | **Do not reuse** | GoldIntel's product. EmpireIntel may *read* GoldIntel's results later (Q-5), never re-implement them |
| Future/ stubs | 2 files | **Pattern only** | Same rule: placeholders return `NOT_IMPLEMENTED` |
| Test runner and helpers (`testlib`, `fake_wow`, `loader`, `svsim`) | `Tests/run.lua`, `helpers/*` (about 650) | **Reuse, rename** | `loader.lua` hard-codes `GoldIntel.toc` and the addon name: make both parameters |
| Static boundary tests C-1..C-6 (ASCII, no long brackets, `local ADDON, NS = ...`, minimal TOC, no WoW global outside Platform, only Events registers) | `Tests/test_platform_boundary.lua` | **Reuse, extend** | Add one rule: only `Bridge/` may touch third-party addon globals (DataStore, Altoholic) |
| Real-client fixtures (replay, migration, probe) | `Tests/fixtures/*` | **Selective** | The probe fixture pattern is reused. The files themselves contain character names and balances and must NOT go into the public repo |
| In-client lab and throwaway probes | `GoldIntelDiag/Lab.lua`, `GIProbeLoot` | **Pattern reuse** | Safety rules for TP-1: read-only, bounded output, issecretvalue before read, no probing by registration |
| Package builder (verifies every TOC file before zipping) | `tools/build_package.py` (114) | **Reuse, rename** | Addon list and zip names |
| Governance: Bible, decisions, handoffs, evidence tiers, external review intake | `GoldIntel_Docs/Project_Bible.md` and others | **Adopted** | See EmpireIntel `Project_Bible.md` |
| Client evidence E-01..E-45 | `Compatibility_Notes.md` | **Inherited by reference** | Facts carried over in EmpireIntel `Compatibility_Notes.md` with the tag [inherited]. Character names are not copied |

Estimated reusable code: about 4,500 of GoldIntel's addon lines (Platform core and identity adapters 2,279, Core 1,612, Store 597) and the whole test harness. That is the part GoldIntel spent Phases 1 and 2 proving in the live client.

## 2. Findings worth acting on

1. **The test runner needs Lua 5.2 or later; the addon is Lua 5.1.** Under `lua5.1` the suite gives 1233 passed and 8 failed. `test_item_sources.lua` calls `load(string)` and `test_replay_adapters.lua` uses `goto`. The production code is 5.1-clean (C-rules), so this is a harness choice, not a bug. EmpireIntel proposal: run the suite under 5.1 **and** 5.3 in CI, so a 5.2-only construct cannot slip into addon code through a shared helper.
2. **GoldIntel's evidence names real characters.** The beta characters' names and GUIDs appear in `Compatibility_Notes.md` and in the fixtures. GoldIntel is private, so that is fine there. EmpireIntel is public: carry evidence over by ID only.
3. **Pre-modern adapters are already gone (GoldIntel D-027; GoldIntel calls them "legacy", unrelated to the Forever Legacy points system).** EmpireIntel starts modern-only. TP-1 still measures the pre-modern API surface, because third-party addons (DataStore) decide at run time which path to take. A legacy global that comes back in a patch could switch them onto old code.
4. **The realm question is open in GoldIntel (OI-11) and matters more here.** GoldIntel keys by GUID and treats realm text as an attribute. DataStore keys characters as `Account.Realm.Name` (section 4 of Reference_DataStore_Altoholic.md). Launch is 2026-11-04, and the beta realm was 'Classic Beta PvE'. EmpireIntel must survive a realm-name change at launch.

## 3. What EmpireIntel v1 needs from the client (for the event allow-list)

Only events already proven on Forever (GoldIntel E-02, E-13, E-15): `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_LOGOUT`, `PLAYER_LEVEL_UP`, `SKILL_LINES_CHANGED`, `PLAYER_REGEN_DISABLED` / `ENABLED` (to stay out of combat). TP-1 uses the same list. A Legacy event found by discovery is recorded but not registered until a later, approved package verifies it (GoldIntel D-029 pattern). `Platform/Unit.lua` already reads level and `GetProfessions`; it needs `GetXPExhaustion` and `IsResting` added.

## 4. What P2-1 actually ported (2026-11-05, D-028)

| GoldIntel file | EmpireIntel | Changes |
|---|---|---|
| Platform/Platform.lua | ported | collector allow-list and adapters removed; TRUSTED_EVENTS reduced; fatal capability = frame only |
| Platform/Clock.lua, Scheduler.lua, SavedVars.lua, Slash.lua | ported | names; SavedVars is account-wide only |
| Platform/Events.lua | ported | events reduced to P_LEVEL, P_PROFS, P_COMBAT, P_LOGOUT; stages, counters and unit filter removed |
| Platform/Unit.lua | ported | two-part name, realm, XP and rested XP, professions with skill, max and line; cast tracking removed |
| Store/Store.lua, Migrations.lua | ported | no compat, no per-character table; format 1 sections (meta, roster); step 0 -> 1 |
| Platform/Map.lua (P_TICK), Money, Loot and the other collectors, Probe, Core/Bus, Capabilities, Config, Core.lua | **not ported** | not needed for P2-1; the 0.5 s tick is excluded by the user |

