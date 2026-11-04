# EmpireIntel Architecture v1

DOC VERSION: 2.2.0  |  DATE: 2026-11-03  |  STATUS: **Section 9 (TP-1) approved by the user for implementation (Q-3, Q-7); the rest Proposed**  |  Requirements_v1.md wins on scope, Decisions.md on design, Compatibility_Notes.md on client facts

**EmpireIntel tracks the WoW Forever Legacy system across a player's characters.** For each character it shows Legacy points and perks, rested XP and professions. It also gives a "what next" list driven by a plan file the user writes. Alt data comes from EmpireIntel's own snapshots and, optionally, from DataStore.

**The Legacy API is not documented.** Nothing in this document assumes a function or event name for it. Test Package 1 discovers what the live launch client exposes. If nothing is exposed, EmpireIntel falls back to estimating points from levels and professions, and labels the result as an estimate (section 6).

v2.0.0 replaces v1.0.0. That version misread "Legacy" as old APIs and designed an account wealth tracker (D-010).

## 1. Scope v1 (Requirements_v1.md; confirmed by the user 2026-11-03)

- **Legacy, account-wide:** points earned, challenges completed, points not yet spent.
- **Legacy, per character:** perks spent (tree and perk), points spent versus the per-character cap (16 at launch, expected to rise; read from the client if exposed, else from config).
- **Rested XP per character:** the value at last logout, resting state, and a projection to now.
- **Professions per character:** name, skill and max skill.
- **"What next":** an ordered list of the plan's unmet goals with the next step for each, e.g. "Char2: level 45 (now 41), earns Warrior milestone".
- Output: slash commands only (`/ei`, `/ei legacy`, `/ei next`, `/ei char <name>`). No windows in v1.
- **Passive collection:** the player plays normally. EmpireIntel records at login, on level-up, on profession change, at logout, and when the Legacy pane opens (if one is found). The user sends the SavedVariables after `/reload` or logout.

Out of scope: gold and item tracking (v1.0.0 idea, dropped), auction, mail, UI frames, guilds, more than one account.

## 2. Principles (ordered; earlier wins)

1. **Measured beats estimated beats unknown,** and every value says which it is: `{ v, src, asOf, conf }`, where `src` is `client`, `datastore`, `estimate` or `plan`.
2. **No assumed API names.** Legacy access goes only through names that TP-1 discovered and the user approved (D-012).
3. **Surface unexpected conditions visibly:** a single chat line starting `EmpireIntel: UNEXPECTED`, plus a saved record. Nothing fails silently.
4. **DataStore is optional** (license, D-003). EmpireIntel works without it.
5. **Boundaries:** WoW API only in `Platform/`; third-party addons only in `Bridge/` (static tests).
6. **GUID is identity** (D-004).
7. **Lean:** no feature without a requirement. Lua 5.1, modern API, GoldIntel file rules C-1..C-6.

## 3. Layers

```
+------------------------------- Platform/ (only WoW API users; ported from GoldIntel) -------------------------------+
| Platform  Events  Clock  Scheduler  Unit(+XP, rest, professions)  SavedVars  Slash  Probe  Legacy (adapter, section 5) |
+----------------------------------------------------------------------------------------------------------------------+
        | plain tables                                                         (no WoW globals above this line)
        v
 Sources/Self ----+                 Bridge/DataStoreBridge (optional: level, class, rest XP, professions of alts)
 (snapshot of the  \                         |
  logged-in char)   v                        v
                 Roster (per GUID; merge by asOf; provenance) ---> Legacy model (measured | estimated) ---+
                                                                                                         v
 Plan (EmpireIntel_Plan addon: Plan.lua, user-edited) ------------------------------------------> Planner ("what next")
                                                                                                         v
                                                                                                    Commands
 Core/ (registry, bus, capability stages, config, boot)   Store/ (EmpireIntelDB, EmpireIntelCharDB, migrations)
```

| Module | Responsibility |
|---|---|
| Platform/Legacy | The only code that touches the Legacy API. Built from TP-1's discovered names. Absent or unapproved names mean `available = false` |
| Platform/Unit (extended) | Level, XP, `GetXPExhaustion`, `IsResting`, `GetProfessions` / `GetProfessionInfo`. Names are re-confirmed by TP-1 |
| Sources/Self | Snapshots at login, `PLAYER_LEVEL_UP`, `SKILL_LINES_CHANGED`, logout, Legacy pane open. Events from GoldIntel's proven list only |
| Bridge/DataStoreBridge | Alt level, class, rest XP and professions when DataStore is installed. Each value carries `asOf` from DataStore |
| Roster | Per-GUID merge; newest `asOf` wins; `client` beats `datastore` on a tie; "Unknown" names never overwrite known ones |
| Legacy model | Account and per-character Legacy state, from Platform/Legacy when available, else from the Estimator |
| Estimator | Section 6 |
| Plan + Planner | Sections 7 and 8 |
| Commands | `/ei` output, including source and age for every line |

## 4. Rested XP

Measured at each snapshot (`GetXPExhaustion`, `IsResting`, `UnitXPMax`). DataStore warns that `GetXPExhaustion` sometimes returns 0 or nil, so a nil is stored as unknown, never as 0. For alts, the projection to now uses the last logout time and resting state. **The rates are an assumption** (classic rules: 5% of a level's XP per 8 hours rested, a quarter of that outside a rest area, capped at 150% of a level). TP-1 compares a projection with a measured value on the next login. Projections are labelled `estimate`.

## 5. Legacy access (filled in after TP-1)

Platform/Legacy exposes one contract, whatever the client turns out to offer:

```
Legacy.Available()            -> true | false, reason
Legacy.Account()              -> { earned, spent?, challenges = { [id] = { name, done, category? } } } | nil
Legacy.Character()            -> { spent, cap, perks = { [id] = { name, tree, rank? } }, trees = {...} } | nil
```

Each field is filled only from approved discovered names. Each field is `nil` when not exposed. The design does not depend on any field existing. If TP-1 finds a Legacy pane but no data API, the fallback is a snapshot of what the pane shows. That needs a separate decision, because reading UI text is fragile (Q-8).

## 6. Fallback: estimate from levels and professions

Used when Platform/Legacy is not available, or for the parts it does not cover. **The challenge families below come from fan guides that could not be opened from this session. They are unverified** (Compatibility_Notes section 5):
- **Class milestones:** levels 25, 45 and 60 for each of 9 classes, once per account: up to 27 points.
- **Crafting milestones:** skill 150, 225 and 300 in Alchemy, Blacksmithing, Enchanting, Engineering, Leatherworking and Tailoring, once per account: up to 18 points.
- **The other ~20 challenges** (65 total) are of unknown kinds and are **not estimated**.

Rule: for each class, the highest level any known character of that class has reached gives its milestones. Professions work the same way with skill. The result is a **lower bound**: "at least N of 65 (estimated from class levels and crafting skill; 20 challenges not covered)". Characters never seen by EmpireIntel or DataStore are missing, and deleted characters are missing. Perks spent cannot be estimated and are shown as unknown. The thresholds live in a data table (`Data/LegacyRules.lua`) so a correction is a one-line change.

## 7. Plan file (contract; moves to Contracts.md when code starts)

The plan lives in a separate addon folder, `EmpireIntel_Plan/Plan.lua`, so that updating EmpireIntel never overwrites it. The user edits it with a text editor. **Editing an existing Plan.lua takes effect after `/reload`; adding the folder the first time needs a full client restart.**

```lua
EmpireIntelPlan = {
  version = 1,
  cap = 16,                                   -- per-character spend cap if the client does not expose it
  goals = {                                   -- order = priority
    { char = 'Char1', level = 60 },
    { char = 'Char2', profession = 'Tailoring', skill = 300 },
    { char = 'Char1', perk = 'Some Perk Name' },        -- matched to discovered perk names, else 'unverified'
    { account = true, challenges = 30 },                -- account-wide Legacy target
    { char = 'Char3', restedBefore = 'level', level = 40 }, -- 'rested XP covers the next level'
  },
}
```

Validation at load: unknown keys, wrong types and unknown character names are each reported as one `UNEXPECTED` line naming the goal number. The goal is then skipped, never guessed. Characters are matched by name only to find the GUID: the first match is used, and two characters with the same name are reported.

## 8. "What next" (Planner)

For each goal in order: is it met (yes, no, unknown); its gap (e.g. 4 levels, 37 skill points); the Legacy points it would earn (from the rules table, labelled estimate); and one next step. Output is limited to the first 10 unmet goals. Unknown is never shown as met.

## 9. Test Package 1: the Legacy check (first deliverable; design only)

A throwaway addon `EmpireIntelCheck`, separate from EmpireIntel. **It is passive:** it runs by itself at login and logout, prints one summary line, and writes everything to `EmpireIntelCheckDB`. It has no required commands. It runs on the **launch build**.

**Runtime limits (the user, 2026-11-03, Q-7 and D-016; binding for every TP-1 build):**
1. **Calls:** only names that start with `Get`, `Is` or `Has`, called with **zero arguments**, each inside `pcall`. A name containing `Set`, `Spend`, `Learn`, `Reset`, `Buy` or `Purchase` is never called. The match is case-insensitive, so it also skips harmless names such as `GetAssetInfo`; each skip is recorded as `skipped_denylist`. If the API documentation (L-5) lists a required argument, the call is skipped as `skipped_args`.
2. **Login delay:** nothing heavy runs until 10 s after `PLAYER_ENTERING_WORLD`.
3. **Spread across frames:** all scanning and calling runs as a queue with a budget of about 2 ms per frame (item count as a fallback where no precise timer exists). It pauses in combat.
4. **Saved data cap:** `EmpireIntelCheckDB` stays under about 256 KB (estimated while writing). Older runs are dropped first, and truncation is marked where it happens.
5. **Off switch:** `/eicheck off` stops all work at once and on later logins (one line at login says it is off); `/eicheck on` re-enables it. Disabling the addon at the character screen also works.
6. **No interference with GoldIntel:** EmpireIntelCheck's only globals are `EmpireIntelCheckDB`, `SLASH_EMPIREINTELCHECK1` and its `SlashCmdList` entry. It never reads or writes `GoldIntelDB` or `GoldIntelCharDB`, never hooks a global function, only hooks `OnShow` of frames it discovered by Legacy terms, prints at most two lines per run, and uses its own unnamed event frame. A test checks the global footprint.
7. **Separate result codes** for every probed name: `ok`, `not_found`, `returned_nothing`, `blocked`, `unreadable`, plus `error`, `skipped_denylist`, `skipped_args`, `skipped_unrelated`, `skipped_cap`. `blocked` = an `ADDON_ACTION_FORBIDDEN` / `ADDON_ACTION_BLOCKED` for EmpireIntelCheck during the call, or an error naming a protected or forbidden action. `unreadable` = a secret value (`issecretvalue`) or an opaque value (userdata, thread). `returned_nothing` = no return values or only nil.
8. **Provisional verdict:** NOTHING EXPOSED is **provisional** while the Legacy pane has not been seen opening, or while no Legacy point is expected yet (estimate 0). The label says which. The check **reruns by itself** when: a Blizzard UI addon loads after login (likely the pane); a discovered frame is shown; a level reaches 25, 45 or 60; a crafting skill reaches 150, 225 or 300. There are at most 4 automatic runs per session.

**Safety rules (GoldIntel lab protocol, plus discovery rules):**
- It registers only events GoldIntel proved safe (`PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_LOGOUT`, `PLAYER_LEVEL_UP`, `SKILL_LINES_CHANGED`, `PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED`). It also registers three that GoldIntel's own lab used or that every addon uses: `ADDON_LOADED`, `ADDON_ACTION_FORBIDDEN`, `ADDON_ACTION_BLOCKED`. Each is name-checked with `IsEventValid` first. Discovered event names are checked with `C_EventUtils.IsEventValid` and recorded, **never registered**.
- **Discovery lists names. It never calls an unknown function** with one exception: D-1 below, under its rules.
- Out of combat only (`InCombatLockdown()` false). Every call is in `pcall`; every value goes through `issecretvalue`; output is bounded (depth 4, 200 entries per table, 120 characters per string, ASCII).
- It never writes to Blizzard or other addon tables, and it never loads a Blizzard addon on its own (the docs load in L-5 waits for the user's go-ahead).

**Part A: platform checks (kept from v1.0.0).** T1 client profile; T2 pre-modern versus modern API presence (13 families, Compatibility_Notes section 2 baseline); T3 identity (GUID, both `UnitName` returns, realm text); T4 DataStore presence and AddonFactory flags; T5 DataStore method surface plus cross-check of level, money and one item count against live values; T6 DataStore roster health ("Unknown" names, duplicate GUIDs, ages); T7 bank read with the bank open.

**Part B: Legacy discovery (new).** Search terms, case-insensitive: `legacy`, `perk`, `challenge`, `camelot`, `forever`. `camelot` is included because the Forever Blizzard UI has `Camelot` folders (seen in Altoholic Forever's source).

| ID | Question | Method (read only) | Result recorded |
|---|---|---|---|
| L-1 | Which API namespaces and globals exist? | Walk `_G` once at login: every `C_*` table with its member names; every global function, table or Enum whose name matches a term. Saves the full `C_*` namespace list plus a diff against GoldIntel's beta list (272 namespaces, E-05), so new namespaces show even if their name does not match | Names and types only |
| L-2 | Enums and constants | Every `Enum.*` whose name or member names match; every global constant (number or string) whose name matches | Names and values |
| L-3 | Blizzard UI addons and frames | Enumerate every addon with `C_AddOns.GetNumAddOns` / `GetAddOnInfo` (names, load-on-demand, loaded); every global frame whose name matches | Names; is the Legacy pane an addon, is it loaded |
| L-4 | Events | Event names from L-5 (if run) and from discovered `Enum` or constant names, checked with `IsEventValid` | Valid or invalid; never registered |
| L-5 | Official API documentation, if the client ships it (opt-in) | If L-3 finds a Blizzard API-documentation addon, `/eicheck docs` loads it and saves each system whose name matches a term: functions with argument and return names, events with payloads, tables | Documented signatures. This is the most reliable discovery path, and it only runs when the user types the command |
| D-1 | What do discovered getters return? | Under runtime limit 1: functions in matched namespaces and matched global functions. Known unrelated retail names (C_ChallengeMode, C_PerksProgram, C_PerksActivities, `IsLegacyLootModeEnabled`) are recorded but not called (`skipped_unrelated`) and do not count toward the verdict. At most 300 calls per run, once per run, out of combat. A call that errors is not repeated in that session | Result code (limit 7) and bounded return values; blocked-action events seen |
| L-6 | Pane snapshot | If L-3 finds a matching frame: `HookScript('OnShow')` (taint-safe) re-runs D-1 when the player opens the Legacy pane in normal play | Values before and after opening; shows whether data loads lazily |
| R-1 | Rested XP | `GetXPExhaustion`, `UnitXP`, `UnitXPMax`, `IsResting`, `GetRestState` (presence first, then values) at login and logout; time and resting state saved | Lets the next login test the projection rule (section 4) |
| P-1 | Professions | `GetProfessions` (all returns, including the Forever order prof1, prof2, firstAid, fish, cook seen in DataStore) and `GetProfessionInfo` for each; `SKILL_LINES_CHANGED` re-snapshot | Name, skill, max, skill line id |
| E-1 | Fallback inputs | Class, level, profession skills of this character, plus DataStore's other characters if present | The Estimator's inputs and its estimate, compared with L/D results if any |

**The Legacy probes the user asked for, mapped:** points earned, challenges, perks spent, per-character cap and tree data are all searched for by L-1..L-3 and L-5, read by D-1 and L-6, and compared with E-1. Rested XP is R-1; professions are P-1.

**Verdict line.** Matches on `challenge` and `perk` that belong to known retail systems are excluded (D-1). At the end of each run TP-1 sets exactly one of:
- `LEGACY API: FOUND` (at least one getter returned Legacy data);
- `LEGACY API: NAMES ONLY` (names found, nothing returned data);
- `LEGACY API: PANE ONLY` (a frame, no data API);
- `LEGACY API: NOTHING EXPOSED`.

The verdict is printed in chat (`EmpireIntelCheck: LEGACY API: NOTHING EXPOSED, see EmpireIntelCheckDB`) and saved. NOTHING EXPOSED carries `(provisional: ...)` under runtime limit 8. **Only a final NOTHING EXPOSED switches EmpireIntel to the section 6 fallback.**

**Package statement.** New addon folder: **full client restart required** (a `/reload` does not load a new addon). Later TP-1 updates that only change Lua files need just a `/reload`.

**Test instructions (launch build, about 10 minutes of normal play).** The authoritative copy is `EmpireIntelCheck/README.txt` in the package. It adds a fallback `/eicheck pane` in step 5 for when no frame is detected, and says to exit the game fully so the file is written. Summary:
1. Quit the game completely.
2. Extract `EmpireIntelCheck_AddOns.zip` into the Forever game folder's `Interface\AddOns\` (the same folder GoldIntel is in; the beta used `_classic_beta_`, and the launch folder name is not known yet). Leave DataStore and Altoholic installed and enabled if you use them.
3. Start the game. At the character screen, open AddOns and confirm `EmpireIntelCheck` is enabled (tick "Load out of date AddOns" if it is listed as out of date).
4. Log in to character 1 and wait until you are in the world. Expect one chat line `EmpireIntelCheck <version>: LEGACY API: <verdict> ...`. Any `UNEXPECTED` line, or any red error or popup: note it, keep playing.
5. Open the Legacy pane once (however the game opens it), look at it for a few seconds, close it.
6. Play normally for a few minutes. A level-up or profession skill-up is useful but not required.
7. Optional: open your bank once.
8. Optional, only if step 4 said `docs available`: type `/eicheck docs`, wait for `docs saved`.
9. Log out to the character screen, log in to character 2, repeat steps 4 to 5, then log out completely (`/camp` or Exit Game).
10. Send `WTF\Account\<account>\SavedVariables\EmpireIntelCheck.lua`, plus a screenshot of the Legacy pane with points and perks visible (this is the ground truth TP-1's values are checked against).

**Exit criteria.** Part A rows recorded. A verdict recorded on two characters. If FOUND, D-1 values equal the pane screenshot. R-1 and P-1 values match what the game shows. Every unexpected condition listed in the TP-1 report. Then the user decides D-012 (which discovered names Platform/Legacy may use) and D-005 (DataStore), and whether Phase 2 starts.

**Offline tests (before shipping):** the GoldIntel harness against four fake clients: (1) the beta profile with no Legacy anything (expect NOTHING EXPOSED, no error); (2) a fake `C_ForeverLegacy`-style namespace with getters (expect FOUND); (3) getters that error or return secret values (expect recorded, no throw); (4) DataStore present but faulty. Static checks: no `RegisterEvent` outside the allow-list, no call to a non-getter name, Lua 5.1 and C-1..C-6. The fake namespace names are test fixtures only and never appear in shipped code.

## 10. Phases and gates

| Phase | Content | Gate |
|---|---|---|
| 0 | Requirements, governance, audit, reviews, this architecture | User approves (now) |
| 1 | TP-1 code, offline tests, launch-build run, evidence, report | Section 9 exit criteria; D-012, D-005 |
| 2 | Port Platform / Core / Store / harness; Platform/Legacy from approved names or the fallback; Unit extension | Suite green under 5.1 and 5.3; loads with no error |
| 3 | Sources/Self, Roster, DataStoreBridge, Estimator | Live: values match the game and the pane on two characters |
| 4 | Plan + Planner + Commands | Live: `/ei next` correct for a test plan of 5 goals |

## 11. Invariants (each gets an automated test)

1. No WoW global outside `Platform/`; no third-party addon global outside `Bridge/`; no Legacy name outside `Platform/Legacy`.
2. Every stored value has `src` and `asOf`; an estimate is never shown without the word "estimate".
3. Unknown is never displayed as 0 or as "met".
4. The estimated earned points never exceed the rule table's maximum (45) and are never shown as the account total.
5. A plan error skips that goal and is reported; it never stops the addon.
6. EmpireIntel never writes to a table it does not own.

## 12. TP-1 amendments for 0.1.1 (D-021, after launch-build run 1)

- **Legacy names only:** a name counts toward the verdict only if it contains "legacy" and is not a known retail feature (`U.strong`). "challenge", "perk", "camelot" and "forever" matches are recorded but never counted.
- **Layers:**
  - FOUND needs meaningful data from the game API layer: `C_` functions, Enum, documented functions, or global read-style functions.
  - Legacy UI (frames, mixins, UI functions) gives PANE ONLY.
  - UI actions (`Toggle...`, `Show...`, `..._LoadUI`) are never called.
- **Lock state:** read from `LegacyMicroButtonMixin.IsLegacySystemUnlocked` (EI-E-02). Every verdict other than FOUND is provisional while the system is locked, the pane has not been seen, or no point is expected.
- **Pane:** seen when a Legacy frame goes from not visible to visible (`IsVisible`, polled once per second), or when a Blizzard addon with a Legacy name loads. No script hooks.
- **Logout baseline:** the logout reading is used only when it is valid; otherwise the last in-world reading, refreshed every 5 minutes (EI-E-08).
- **Storage format 2:** the full discovery and call results are kept once in `latest`. Each run keeps its verdict, the results for Legacy names, and the names and codes that changed. Up to 20 runs. Format 1 runs are compacted.
- **Denylist:** applied exactly as worded by the user: capitalized `Set`, `Spend`, `Learn`, `Reset`, `Buy`, `Purchase` anywhere in the name, plus lower-case at the start of a name segment.
- **Docs:** an index of every documented system, plus matching on argument, return, event, payload, table and field names. Processing is spread across frames.
- **T8:** read-only count of BugGrabber/BugSack errors per addon. Our own messages are kept with GUIDs and paths removed; locals are never copied.
