# P2-4b Report: the plan window (EmpireIntel 0.7.0)

DOC VERSION: 1.1.0  |  DATE: 2026-11-09 (S-063)  |  STATUS: **Live gate partly passed (D-063); 0.7.2 built for the one retest (D-065); not merged.** Approved by the user (D-060 mockup, D-061 plan with the fill path); build choices in D-062. Branch `p2-4b-window`.

## 1. What was built

| File | What it does |
|---|---|
| `Platform/UI.lua` (new) | The only file that names the game's UI globals or creates window frames (static test). Wrappers under `pcall`; **the one fill path** `UI.Fill` and its probe `UI.ProbeFill` (D-061); portrait, atlases, class colours, cursor, minimap shape, Escape, compartment, tooltip |
| `UI/Theme.lua` (new, pure) | Mockup colours, the game's built-in fonts (`FRIZQT__`, `ARIALN` for rows with a fallback), icon cells, the race-to-atlas map (`Scourge` -> `undead`, EI-E-30), window default 560 x 420 and limits 440 x 300 .. 900 x 800 |
| `Core/PlanView.lua` (new, pure) | The window's content from the route or my plan: header, card, rows (status, now, points, time, unverified dot, tooltip with sources), footer |
| `UI/Window.lua`, `UI/UpNext.lua`, `UI/Rows.lua`, `UI/Minimap.lua` (new) | The window, the card, the rows (own scrolling, drag, in-place edit, own right-click menu), the minimap button and the compartment entry |
| `Media/Icons.tga`, `Media/White8.tga`, `Media/Mark.tga` (new) | Our own icon sheet, the white texture for the fallback fill path, the compartment mark |
| `Bridge/DataStoreBridge.lua`, `Core/Alts.lua` | `GetCharacterFaction` (read only, only `Alliance`/`Horde`, never stored); the own record wins |
| `Core/Next.lua`, `Core/Commands.lua`, `Core/Plan.lua`, `Core/Boot.lua` | `/ei plan` opens the window, `/ei plan help`, `/ei minimap on/off`; window and minimap state (format 2 fields); the button and the compartment after login |

No saved-data format change; no TOC header change; `/reload` is enough.

## 2. The fill path (D-061)

At first open a hidden texture is filled with `SetColorTexture` and read back with `GetTexture`. If a value comes back, every fill uses `SetColorTexture`. Otherwise every fill uses `SetTexture` on `Media/White8` plus `SetVertexColor`, read back with `GetVertexColor`. If both fail: one `UNEXPECTED` line and a text-only window. **The path that ran is said in chat at first open ("window: fills: ...") and in `/ei plan help`.** On Forever this is not yet observed: the live gate's step 1 records it. Tests cover the colour path, the white path (no read-back, and `SetColorTexture` raising) and the double failure.

## 3. Tests

- **485 tests pass** under Lua 5.1 and 5.3 (408 before; 52 new in `test_ei_window.lua` with a shared strict fake UI layer, `Tests/helpers/fakeui.lua`; P2-4a tests adjusted: version, the DataStore list plus one getter, `/ei plan help`, the old "no window code" rule replaced by the P2-4b static rules).
- **Mutation check: 21 of 21 new guards caught** (both fill read-backs, the chosen path, the compartment once, the portrait crop, size limits, the normalised position, Escape, combat, the resize fallback, quiet reads, templates, Scourge -> undead, alt art, own faction first, faction values, edit checks, the edit box focus, Fastest read only, the square minimap, read-only saving); the 20 P2-4a mutants still caught.

## 4. Package

`EmpireIntel_AddOns_v0.7.0.zip`, 34 files, sha256 `b904675d8f67d68fffd8f0b2bf572003d1eff820419d33215928989051c87706`. `/reload` from 0.6.0. Rollback: the 0.6.0 folder and `/reload` (format 2 unchanged).

## 5. Live gate (the user's test, with ElvUI on and off; steps in the package README)

1. Open by `/ei plan`, the minimap button, the compartment; Escape closes; note the "window: fills:" line.
2. Both modes against the mockup; the played character's portrait; the other character's race and class icons.
3. My plan: drag, edit a target, Move to top, Remove; `/reload`: kept.
4. Resize and move, `/reload`: same size and place.
5. ElvUI on and off: same look; the button on the round and the square minimap edge.
6. Open in combat: no error, "from before combat".
7. `/ei alts`: an alt's faction from DataStore matches the game.
8. Screenshots of both modes, the saved file, any `UNEXPECTED` line or Lua error.

## 6. Live gate on 0.7.0 and the 0.7.1 retest build (S-063, D-063, D-064)

**Result [reported]:** steps 1 (`/ei plan`, the minimap button), 4 (resize and persistence), 5 (ElvUI on and off, minimap placement) and 7 (`/ei alts`) passed. Steps 2, 3, 6 and 8 are repeated on 0.7.1. One screenshot (Fastest) was received; the second could not be opened (HTTP 403). The user's words and files were read as data; C1 Paladin, C2 Priest, C3 the ignored character, C4 the Druid.

| # | Finding | Cause | 0.7.1 | Tests |
|---|---|---|---|---|
| 1 | My plan edits break prerequisites | edits had no prerequisite check | `Plan.MoveKeeping`, `RemoveKeeping`, `ReplaceKeeping`, `InsertKeeping`: the level step is carried (or added), a removal or lowering is refused; chat says which; an open gate shows as a gate | 11 |
| 2 | Add a skill step duplicates 150 | the next milestone came from the character's skill, not from the plan | `Plan.NextEntry`: the next milestone after everything planned; nothing after 300 | 3 |
| 3 | The note edit box covers the text; the note seems to vanish | the box was anchored on the step text; the note was appended to a fixed-width step column (cut off) | an edit bar below the rows; "(note)" mark, the note in the tooltip and on the card; leaving the box saves | 3 |
| 4 | Ignored character's steps stay in My plan | the ignore applied to Fastest only (Q-F4) | marked "(ignored)", greyed, never up next, counted in the footer; Unignore in the menu; chat says how many | 3 |
| 5 | The target button has no label | number only | "Cap 2/16", "Next reward 2/15", "Next point 2/3"; tooltip | 1 |
| 6 | "Normal" badge | it showed the ruleset (`IsHardcoreActive`) | the realm type from the end of the realm name [inferred]; evidence EI-E-32 | 2 |
| 7 | Red square for the Horde emblem | the `HordeEmblem` atlas draws a crest that reads as a red shield at 20 px (EI-E-32); 0.1.9 checked only that it exists | the game's faction icon file `UI-PVP-<faction>` (loads, EI-E-30), cropped [inferred], 26 px; atlas fallback | 1 |
| 8 | Combat line stays after combat | no refresh on combat end | an open window reads Legacy again on `PLAYER_REGEN_ENABLED` (through `P_COMBAT`) | 2 |
| 9 | "Account" vs the Paladin; NOW meanings differ | Fastest named the runner and showed the route's value | "Account" in both; NOW = today's value in both, the route's value in the tooltip; copying keeps the runner's level step | 3 |

**Tests:** 514 pass under Lua 5.1 and 5.3 (485 before; 29 new, 8 adjusted to the new labels and rules). **Mutation check: 22 of 22 new guards caught.**

**Package:** `EmpireIntel_AddOns_v0.7.1.zip`, 34 files, sha256 `937d51e9944ac7334cc3a118d15d6eb056091d969068396f9c561b1299120866`. `/reload` from 0.7.0. Rollback: the 0.7.0 folder and `/reload`. No saved-data format change.

**Retest:** gate steps 2, 3, 6 and 8 (the package README lists what to look for).

**My plan screenshot (0.7.0, received 2026-11-09 after the build) [screenshot]:** 20 steps, 0 met; it confirms items 2, 6, 7 and 9 as reported. Two more observations, not fixed in 0.7.1:
- **A duplicate already saved** (C2 Enchanting 150 twice, made by the item 2 fault). 0.7.1 adds no new duplicates but does not remove saved ones; the user removes it (Remove step) or copies the route again.
- **Finding 10 (new): My plan's TIME and PTS count from today, not from the step before.** Each row's time runs from the character's current value (C2 Level 20 ~9.1 h includes the ~1.3 h of Level 10; Enchanting 225 ~6.2 h includes Enchanting 150's ~3.2 h), so the times overlap and do not add up, unlike Fastest. The duplicate Enchanting 150 also shows +1 twice. Proposed fix (needs the user's go-ahead): time and points from the end of the earlier steps of the same character and profession; a step already reached by an earlier step shows "covered by step n".

**0.7.2 (D-065):** finding 10 fixed: each My plan row's time and points run from the end of the earlier steps of the same character (and profession); a step already reached reads "(covered by step n)", no time or points, never up next, counted in the footer; NOW stays today's value; several milestones in one step count `+2`. Repeated saved steps are removed about 3 seconds after login or `/reload` (the first kept, with a later copy's note when it had none; bad steps never removed as repeats; read-only: said, nothing changed); chat names them. 519 tests pass under Lua 5.1 and 5.3 (5 new); mutation check 8 of 9 caught, the ninth equivalent (a covered step always follows the open step that covers it, so it can never be the first open row). Package `EmpireIntel_AddOns_v0.7.2.zip`, 34 files, sha256 `07b2c0fcc0626bd3bf0214c8d57ceabb132942d3ea1084ccaac8db6ede5a3a70`; `/reload`; no format change. **The one retest:** gate steps 2, 3, 6 and 8 on 0.7.2.
