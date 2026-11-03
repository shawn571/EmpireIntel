# EmpireIntel Requirements v1

DOC VERSION: 1.0.0  |  DATE: 2026-11-03  |  Source: user correction 2026-11-03 (D-010). Changed only by user decision. Wins over Architecture.md on scope.

| ID | Requirement |
|---|---|
| FR-LEG-1 | Show account-wide Legacy points earned and challenges completed, measured from the client when exposed |
| FR-LEG-2 | Show per character: perks spent (tree, perk), points spent, the per-character cap |
| FR-LEG-3 | If the client exposes no Legacy data, estimate points earned from character levels and professions, clearly labelled as an estimate and a lower bound |
| FR-REST-1 | Show rested XP per character: measured at last snapshot, plus a labelled projection to now |
| FR-PROF-1 | Show professions per character: name, skill, max skill |
| FR-PLAN-1 | Read a user-written plan file of ordered goals (level, profession skill, perk, account challenge count, rested XP) |
| FR-PLAN-2 | Produce a "what next" list: unmet goals in plan order with gap and next step |
| FR-ALT-1 | Use DataStore as an optional source for alts' level, class, rested XP and professions; work without it |
| NFR-1 | Passive collection: no required commands during play; data read from SavedVariables after `/reload` or logout |
| NFR-2 | Every value shows its source (client, datastore, estimate, plan) and age |
| NFR-3 | Unexpected conditions are surfaced visibly (chat line plus saved record), never silently ignored |
| NFR-4 | No assumed API names for Legacy: only names discovered in the live client and approved |
| NFR-5 | Lean scope: no feature without a requirement here |
| NFR-6 | Lua 5.1, modern API only, GoldIntel file rules; WoW API only in `Platform/` |

Out of scope v1: gold and item tracking, auction, mail, UI windows, guilds, multiple accounts.

Assumptions (to verify in TP-1): A-1 the challenge families in Architecture section 6; A-2 the cap of 16 at launch; A-3 the classic rested XP rates; A-4 one account per installation (DataStore's "Default" account).
