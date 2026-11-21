# Contributing to EmpireIntel

EmpireIntel is maintained by its owner with Claude (Claude Code) as the developer. The rules are in
`EmpireIntel_Docs/CODE_STANDING_ORDERS.md` and `EmpireIntel_Docs/Project_Bible.md`. In short:

1. **Approval first.** Every increment, fix and merge needs the owner's approval; work happens on work branches, never on `main`.
2. **Decisions are recorded** in `Decisions.md` with the owner's words.
3. **Evidence over assumption.** Client facts carry a tag ([file], [reported], [screenshot], [inferred], [assumed], [inherited]).
4. **Boundaries.** WoW API calls only in `Platform/` (window frames only in `Platform/UI.lua`); other addons only in `Bridge/`.
5. **Lua 5.1, ASCII, modern API only.** The static tests enforce the file rules; every change has tests under Lua 5.1 and 5.3.
6. **Third-party code (D-068).** Copy with credit only from MIT or CC BY sources (`THIRD_PARTY.md`, file headers). Never copy
   from GPL or All Rights Reserved sources (DataStore, Altoholic, Questie and others): write our own version.
7. **Privacy.** Never commit or attach SavedVariables, WTF folders, character names, GUIDs, account names or balances.
   Test fixtures are synthetic.

Contributions are licensed under the MIT License.
