# EmpireIntel

A **World of Warcraft: Forever** addon (client 1.60.x, Interface 16001) for the **Legacy system**: it tracks your characters,
reads your Legacy points and challenges, and plans the fastest way to your next Legacy points.

**Status (2026-11-16):** EmpireIntel 0.6.0 is on `main`. EmpireIntel 0.7.x (the plan window) is on branch `p2-4b-window`
(pull request #17), in its live retest. The current state is always in
[`EmpireIntel_Docs/Session_Handoff.md`](EmpireIntel_Docs/Session_Handoff.md).

## What it does
- Records each character you play: level, XP, rested XP, professions, race, faction, realm. Alts not yet logged in come
  from [DataStore](https://github.com/Thaoky/DataStore) if you have it (Altoholic users do); it works without it.
- Reads the account's Legacy points (earned, available, spent) and the 65 challenges with what is left, after the unlock.
- Plans a route to a Legacy target (Fastest) or follows your own plan (My plan), in a window with a minimap button,
  and in chat. Every time is a labelled estimate, with the unverified rules it uses.
- Chat commands: `/ei`, `/ei alts`, `/ei unlock`, `/ei rest`, `/ei milestones`, `/ei legacy`, `/ei next`, `/ei plan`,
  `/ei rules`, `/ei version`, `/ei off`, `/ei on`.

## Layout
- `EmpireIntel/` the addon (its `README.txt` has install, test and rollback steps for the current version).
- `EmpireIntelCheck/` a read-only check addon used to prove client behaviour before EmpireIntel relies on it.
- `Tests/` the offline suite: `lua5.1 Tests/run.lua` and `lua5.3 Tests/run.lua`.
- `tools/build_package.py` builds and verifies the zip: `python3 tools/build_package.py EmpireIntel`.
- `EmpireIntel_Docs/` the project documents (start with `CODE_STANDING_ORDERS.md` and `Project_Bible.md`).
- `THIRD_PARTY.md` third-party sources (copied with credit, informed by, or read at run time).

## Privacy
Never attach SavedVariables files, character names or account details to issues or pull requests.

Licensed under the MIT License (see `LICENSE`).
