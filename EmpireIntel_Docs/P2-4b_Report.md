# P2-4b Report: the plan window (EmpireIntel 0.7.0)

DOC VERSION: 1.0.0  |  DATE: 2026-11-08 (S-062)  |  STATUS: **Built, not merged, waiting for the live gate.** Approved by the user (D-060 mockup, D-061 plan with the fill path); build choices in D-062. Branch `p2-4b-window`.

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
