# EmpireIntel

A **WoW Forever** addon (client 1.60.x, Interface 16001) that tracks the **Legacy system** across your characters:
Legacy points and challenges, perks spent per character against the cap, rested XP and professions, plus a
"what next" list driven by a plan file you write.

**Status:** Phase 1. `EmpireIntelCheck/` is Test Package 1, a passive in-client check (see its README.txt). EmpireIntel itself is not built yet. The v1 design is in
[`EmpireIntel_Docs/Architecture.md`](EmpireIntel_Docs/Architecture.md) and is waiting for approval. The first package is a passive in-client check that discovers what the Legacy API exposes.

## Alt data
EmpireIntel reads alt data (level, class, rested XP, professions) from [DataStore](https://github.com/Thaoky/DataStore) when you
have it installed (Altoholic users already do), and from its own per-character snapshots otherwise. DataStore is a separate addon by its own author
under its own license; EmpireIntel never bundles or copies it.

## Layout
- `EmpireIntelCheck/` Test Package 1 (throwaway, read-only). `Tests/` offline suite: `lua5.1 Tests/run.lua` and `lua5.3 Tests/run.lua`.
- `tools/build_package.py` builds and verifies `dist/EmpireIntelCheck_AddOns.zip`.
- `EmpireIntel_Docs/` governance (start with `Project_Bible.md`), requirements, decisions, architecture, compatibility notes, risks,
  the GoldIntel reuse audit and the DataStore/Altoholic review.

## Contributing
See `CONTRIBUTING.md`. Never attach SavedVariables files, character names or account details to issues or pull requests.

Licensed under the MIT License (see `LICENSE`).
