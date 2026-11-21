# EmpireIntel Architecture

DOC VERSION: 3.0.0  |  DATE: 2026-11-16 (S-068)  |  STATUS: **The design as built (EmpireIntel 0.7.4 on `p2-4b-window`; main has 0.6.0).** Requirements_v1.md wins on scope, Decisions.md on design, Compatibility_Notes.md on client facts.

This replaces the pre-launch design (v2.x, 2026-11-03), which planned a passive check first, a separate plan add-on and no windows. That history is in TP1_Report_Run1.md, the phase reports and git history.

## 1. What runs where

| Add-on | Purpose | Saved variables |
|---|---|---|
| `EmpireIntel/` | The product: records characters, reads Legacy, plans routes, the window | `EmpireIntelDB` (format 2) |
| `EmpireIntelCheck/` | Read-only check add-on (TP-1). Proves client behaviour before EmpireIntel relies on it; not needed for EmpireIntel to work | `EmpireIntelCheckDB` |

The user installs both folders in `Interface\AddOns\`. DataStore (with or without Altoholic) is optional.

## 2. Layers

```
 UI/ (window, card, rows, minimap)  ---  draws only what Core/PlanView returns; frames only through Platform/UI
      |
 Core/ (pure logic: no game call)   Commands  Snapshot  Alts  Views  LegacyView  Rules  RouteRules  Route  Plan  Next  PlanView  Boot
      |                                   |
 Store/ (EmpireIntelDB, migrations)      Bridge/DataStoreBridge (optional, read only)
      |
 Platform/ (the only WoW API users)   Platform  Clock  Events  Scheduler  Unit  SavedVars  Slash  Legacy  UI
```

Static tests enforce the boundaries: WoW globals only in `Platform/`; window frames and UI globals only in `Platform/UI.lua`; Legacy and achievement functions only in `Platform/Legacy.lua`; DataStore only in `Bridge/DataStoreBridge.lua`; `Core/` draws nothing; no Blizzard template anywhere.

## 3. Modules (TOC order)

| Module | Responsibility |
|---|---|
| Platform/Platform | Environment indirection (tests inject a fake client), capability registry, diagnostics, lifecycle |
| Platform/Clock, Events, Scheduler | Time; the one event frame (normalized `P_*` events, combat state); timers and spread-out work |
| Platform/Unit | The played character: identity, level, XP, rested XP, resting, professions, race, sex, faction, ruleset |
| Platform/SavedVars, Slash | The only access to the saved-variable globals and slash registration |
| Platform/Legacy | Reads Legacy points and the 65 challenges (achievement functions, `LegacySystem.GetCurrencyInfo`), on command, never in combat, spread over frames, allow-list and denylist (P3-1) |
| Platform/UI | Frames, textures, fonts, the fill path (`SetColorTexture` with a read-back, else our white texture), portraits, atlases, class colours, cursor, minimap shape, Escape, the AddOn compartment, tooltips |
| Store/Migrations, Store | `EmpireIntelDB`: open, migrate (format 1 to 2), validate; read-only when the file is newer than the add-on |
| Bridge/DataStoreBridge | Alts from DataStore: level, class, realm, rested XP, professions, faction; read only, approved getters only, never stored |
| Core/Rules, RouteRules | The rules tables: milestones, rested rates (Rules); planner rules L-1..L-18 with status and source, XP table, default costs, training gates, dungeons, rewards (RouteRules) |
| Core/Commands | `/ei` and its sub-commands |
| Core/Snapshot | Saves the played character 2 s after login, on level-up, on a profession change, every 5 minutes and (guarded) at logout; feeds the measured XP rate |
| Core/Alts, Views | The merged character list (own record vs DataStore, newer wins); `/ei alts`, `/ei unlock`, `/ei rest`, `/ei milestones` |
| Core/LegacyView | `/ei legacy` and `/ei legacy all` |
| Core/Route | The route engine (section 5) |
| Core/Plan | The saved plan (mode, target, my plan, ignored characters, measured rates, window and minimap state); step checks; prerequisites, chains and milestone rows for every edit; repeat removal |
| Core/Next | `/ei next`, `/ei plan ...`, `/ei rules`; gathers rows and the Legacy read for the route |
| Core/PlanView | The window's content as data: header, Up next card, rows, footer, tooltips; points counted once per account |
| UI/Theme, UpNext, Rows, Window, Minimap | The approved mockup (D-060): colours and sizes; the card; rows with scrolling, selection, drag, menus and the edit bar; the window (move, resize, Escape, combat refresh); the minimap button |
| Core/Boot | Last file: opens the store, starts the snapshot, checks the saved plan (repeats, milestone rows), makes the minimap button |

## 4. Saved data (format 2, D-055)

```
EmpireIntelDB = {
  schema = 2,
  meta   = { created, version, build, opens },
  roster = { [GUID] = { name, realm, class, level, xp, xpMax, rest, resting, restAt, professions = { { name, skill, max, line } },
                        race, sex, faction, ruleset, preset, lastSeen, src } },
  plan   = { mode = 'auto' | 'mine', target = 16 | 'reward' | 'next' | n,
             mine = { { kind = 'level' | 'skill' | 'challenge' | 'rested', guid, level | profession + skill | id | rested, note } },
             ignore = { [GUID] = true }, rates = { [GUID] = { xpPerHour, at } },
             window = { point, x, y, w, h }, minimap = { hide, angle } },
}
```

Characters are stored by GUID, never keyed by name. Nothing from DataStore is stored. Approved but not built: P2-4c's `plan.profs` and `plan.setup`, and Q-P2-4f's played time, gold, hearthstone location and zone, all inside format 2 (D-065, D-069). P3-2's saved Legacy summary will be format 3.

## 5. The route (Core/Route.lua, Phase2_Plan.md sections 8.4-8.6)

- **Input:** the merged rows (own records plus DataStore), the target, measured XP rates, ignored characters, and the Legacy read when the account is unlocked.
- **Earned so far:** the game's count from the Legacy read; without it, inferred from levels and skills (class and craft milestones only), and labelled.
- **Greedy:** take the cheapest next point including its gates (training levels, dungeon levels), apply it to the simulation, repeat. Ties: the played character, then a levelling step, then list order.
- **Costs [estimate]:** level time from the XP table (measured bar where seen) at the character's measured XP per hour or the band default; rested XP saves its amount of kill XP (L-17, unverified); skill and dungeon times from defaults (L-16).
- **One step per milestone (D-070):** a step that passes several milestones is split, each with its own gate and exact share of the time; a milestone the account already has is a step with no point.
- **Never:** mixes rulesets (L-18), plans PvP before 60, raids or Valthalak, or calls a Legacy function before the unlock (D-052).

## 6. My plan (Core/Plan.lua)

Every edit keeps the plan consistent (D-063, D-066, D-070): a skill step's training gate stays before it; moving a step up brings its chain (the lower steps it builds on) ahead of it in order; moving down takes the steps that build on it along; removing or lowering a needed level step is refused; adding gives the next milestone, never a duplicate; each milestone has its own row. At load, repeated steps are removed and missing milestone rows are added; chat says which. Rows count time and points from the end of the earlier steps, and each milestone once per account.

## 7. Invariants (each has an automated test)

1. No WoW global outside `Platform/`; no other add-on outside `Bridge/`; no Legacy call outside `Platform/Legacy`; no frame outside `Platform/UI`.
2. An estimate is never shown without "estimate" and its unverified rules.
3. Unknown is never shown as 0 or as met.
4. No Legacy function is called before the unlock or in combat.
5. A bad saved step is reported as one `UNEXPECTED` line and skipped; it never stops the add-on.
6. Nothing is written when the saved data is read-only; EmpireIntel never writes a table it does not own.

## 8. Tests and packaging

- `lua5.1 Tests/run.lua` and `lua5.3 Tests/run.lua`: the offline suite against a fake client (`Tests/helpers/fakeclient.lua`) and a strict fake UI (`fakeui.lua`); 536 tests on `p2-4b-window`. Each increment also gets a mutation check of its new guards.
- `python3 tools/build_package.py EmpireIntel` builds and verifies `dist/EmpireIntel_AddOns_v<version>.zip` (TOC files present, ASCII and LF, nothing outside the folder; it prints the sha256).

## 9. What comes next

Phase2_Plan.md sections 10 and 11 (approved, in order after P2-4b closes): P2-4c (profession choices and a setup wizard, 0.8.0; Options in the window, 0.8.1), P2-4d (rested XP in the route), P2-4e (levelling time from quests and grinding, with LibForeverData and pfQuest read when installed). Phase 3 (Phase3_Legacy_Plan.md): P3-2 and P3-3 locked.
