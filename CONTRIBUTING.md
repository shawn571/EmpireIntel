# Contributing to EmpireIntel

The project follows the governance in `EmpireIntel_Docs/Project_Bible.md`. In short:

1. **Planning before code.** Code is accepted only for a phase that `EmpireIntel_Docs/TODO.md` marks as approved.
2. **Decisions are recorded.** Architecture changes need a `Decisions.md` entry (why, affected modules, migration).
3. **Evidence over assumption.** Client facts carry a tag ([file], [reported], [inferred], [assumed], [inherited]).
4. **Boundaries.** WoW API calls only in `Platform/`; calls to other addons (DataStore) only in `Bridge/`.
5. **Lua 5.1, ASCII, modern API only.** The static tests enforce the file rules.
6. **No third-party code.** DataStore, AddonFactory and Altoholic are All Rights Reserved: do not paste or adapt their code.
7. **Privacy (public repository).** Never commit or attach SavedVariables, WTF folders, character names, GUIDs,
   account names or balances. Test fixtures must be synthetic or anonymized.

By contributing you agree that your contribution is licensed under the MIT License.
