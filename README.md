# EmpireIntel

An account-wide intelligence addon for **WoW Forever** (client 1.60.x, Interface 16001). It shows all your characters
together: gold, items in bags and bank, mail about to expire, and how fresh each number is.

**Status:** planning (Phase 0). There is no addon code yet. The v1 design is in
[`EmpireIntel_Docs/Architecture.md`](EmpireIntel_Docs/Architecture.md) and is waiting for approval.

## Alt data
EmpireIntel reads alt data from [DataStore](https://github.com/Thaoky/DataStore) when you have it installed (Altoholic
users already do), and from its own per-character snapshots otherwise. DataStore is a separate addon by its own author
under its own license; EmpireIntel never bundles or copies it.

## Layout
- `EmpireIntel_Docs/` governance (start with `Project_Bible.md`), decisions, architecture, compatibility notes, risks,
  the GoldIntel reuse audit and the DataStore/Altoholic review.

## Contributing
See `CONTRIBUTING.md`. Never attach SavedVariables files, character names or account details to issues or pull requests.

Licensed under the MIT License (see `LICENSE`).
