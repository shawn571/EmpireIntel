# EmpireIntel Requirements v1

DOC VERSION: 2.0.0  |  DATE: 2026-11-16 (S-068)  |  Source: user correction 2026-11-03 (D-010), FR-PRE (2026-11-05), and the user's later decisions as cited. Changed only by user decision. Wins over Architecture.md on scope.

Version 2.0.0 restates the requirements as the user has since decided them (D-072): the window, the route planner and the saved plan replaced the plan file (D-054, D-055), and the pre-launch assumptions are settled. No new scope.

## Functional requirements

| ID | Requirement | Status |
|---|---|---|
| FR-LEG-1 | Show account-wide Legacy points (earned, available, spent) and the 65 challenges with what is left, read from the client | Built (P3-1, `/ei legacy`) |
| FR-LEG-2 | Show per character: perks spent (tree, perk), points spent, the spending cap | Not built: needs the trait-system reads (Q-T4, unapproved). The cap of 16 is unverified (L-12) |
| FR-LEG-3 | Before the unlock or without a Legacy read, infer points earned from levels and professions, labelled as inferred | Built (route and `/ei milestones`) |
| FR-REST-1 | Show rested XP per character: measured at the last snapshot, plus a labelled projection to now | Built (P2-3, `/ei rest`) |
| FR-PROF-1 | Show professions per character: name, skill, max skill | Built (P2-1, P2-2) |
| FR-PLAN-1 | Plan the fastest route to a Legacy target (16, the next reward, or the next point), from the characters' real values, every time labelled as an estimate with the rules it uses | Built (P2-4a, P2-4b) |
| FR-PLAN-2 | Let the user keep their own ordered plan (levels, profession skills, challenges, rested XP), edited in the window, saved by character GUID, with prerequisites kept on every edit | Built (P2-4b) |
| FR-PLAN-3 | A window (Fastest and My plan, the Up next card, rows with tooltips, a minimap button) that works with and without ElvUI and in combat | Built (P2-4b, retest under way) |
| FR-ALT-1 | Use DataStore as an optional source for alts; work without it | Built (P2-2) |
| FR-PRE-1 | **Useful before the Legacy system unlocks** (user, 2026-11-05): no dependency on a Legacy API or on a character at level 25 | Built |
| FR-PRE-2 | Show progress to the unlock: the account's highest level against 25 (EI-E-02), the closest character, levels and XP to go | Built (`/ei unlock`) |
| FR-PRE-3 | Show the milestones ahead: per class the next level milestone, per crafting profession the next skill milestone; unconfirmed rules labelled | Built (`/ei milestones`) |
| FR-PRE-4 | Without a plan of the user's own, "what next" still gives the route | Built (Fastest) |

Approved for the next increments (Phase2_Plan.md sections 10-11; D-065, D-069, D-070): profession choices and a setup wizard, Options in the window (P2-4c); rested XP in the route (P2-4d); levelling time from quests and grinding (P2-4e); played time, gold, hearthstone location and zone per character (Q-P2-4f).

## Non-functional requirements

| ID | Requirement |
|---|---|
| NFR-1 | Passive collection: no required commands during play; data read from SavedVariables after `/reload` or logout |
| NFR-2 | Every value shows its source (game, own record, DataStore, estimate, plan) and age |
| NFR-3 | Unexpected conditions are surfaced visibly (a chat line starting `UNEXPECTED`), never silently ignored |
| NFR-4 | Only client functions proven on the live client (by the check or a live test) and approved are called |
| NFR-5 | Lean scope: no feature without a requirement here or an approved plan |
| NFR-6 | Lua 5.1, modern API only, GoldIntel file rules; WoW API only in `Platform/` |
| NFR-7 | Other add-ons are optional (D-068): every feature works without them, and the window says which add-on improves which feature |

## Out of scope

Auction, mail, item and bag tracking; guilds; more than one account per installation; PvP planning before level 60 (L-9); raid and Lord Valthalak planning until a time model exists (L-10).

## Settled assumptions

| ID | Assumption (2026-11-03) | Outcome |
|---|---|---|
| A-1 | The challenge families | Confirmed: 65 challenges as achievements (EI-E-20, EI-E-22, Legacy_Rules.md) |
| A-2 | A spending cap of 16 at launch | Open: client text says a seasonal cap (EI-E-04); 16 is unverified (L-12) |
| A-3 | The classic rested rates | Inn rate confirmed (EI-E-28); the outside rate and the 1.5-level cap unverified |
| A-4 | One account per installation (DataStore's "Default" account) | Holds |
