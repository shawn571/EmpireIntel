# EmpireIntel Session Handoff

Append the newest section at the TOP. The newest section wins.

---

## S-065 | 2026-11-09 | Claude

**Phase and increment:** Phase 2, P2-4b. Retest on 0.7.2: step 6 passed, steps 2 and 3 failed (D-066). Retest build **EmpireIntel 0.7.3** (D-067) on `p2-4b-window`, PR #17 open, **not merged** ("don't merge #17").

**Approved:** through D-066 (the 0.7.3 fixes; items 5-7 as a plan only). P2-4c and P2-4d approved earlier (D-065), not started.

**Pending (the user decides):** the retest on 0.7.3 (gate steps 2, 3, 8); merging #17; closing P2-4b; Q-P2-4c-4 and Q-P2-4c-5 (options in the window, one or two increments), Q-P2-4e with e-1 and e-2 (realistic levelling time, Questie read), Q-P2-4f (more captured at login) (Phase2_Plan.md section 11); the next check version (D-059); #10; Q-T4; Stage 1.

**Branches and pull requests:** main 9cb1d10 (EmpireIntel 0.6.0, EmpireIntelCheck 0.1.9-tp1, 408 tests). `p2-4b-window` (PR #17): main plus 0.7.0 to 0.7.3, 526 tests (Lua 5.1 and 5.3); does not match main. #11 reference only; #10 open.

**Package:** `EmpireIntel_AddOns_v0.7.3.zip`, sha256 `c55eb642608ae976109cdc4686acc9c4c0f9b7793966e8bd5db114216b9c56c1`; `/reload`; no format change.

**Installed (as the user has said):** EmpireIntel 0.7.2, EmpireIntelCheck 0.1.9-tp1.

**Open questions:** those in section 11.4. Not confirmed: whether row tooltips showed at all on 0.7.2 (the cause of the note finding is inferred: tooltips opened off screen to the right).

**User's next step:** install 0.7.3, repeat gate steps 2, 3 and 8, send both screenshots and the saved file; answer section 11.4.

## S-064 | 2026-11-09 | Claude

**Phase and increment:** Phase 2, P2-4b. Retest build **EmpireIntel 0.7.2** (finding 10, repeated steps; D-065) on `p2-4b-window`, PR #17 open, **not merged**.

**Approved:** through D-065: finding 10 and the repeat removal (built); **P2-4c and P2-4d approved with conditions** (Phase2_Plan.md section 10: c-1 inside format 2, c-2 nothing planned for a free slot until chosen, c-3 gathering shown as no points; d-1 **no**, L-17 stays unverified until the user's rested-kill check; d-2, d-3 yes). P2-4c starts only after P2-4b closes; P2-4d only after P2-4c closes.

**Pending (the user decides):** the one retest on 0.7.2 (gate steps 2, 3, 6, 8); merging #17; closing P2-4b; the next check version (D-059, not built); #10; Q-T4; Stage 1.

**Branches and pull requests:** main 9cb1d10 (EmpireIntel 0.6.0, EmpireIntelCheck 0.1.9-tp1, 408 tests). `p2-4b-window` (PR #17): main plus 0.7.0, 0.7.1 and 0.7.2, 519 tests (Lua 5.1 and 5.3); does not match main. #11 reference only; #10 open.

**Package:** `EmpireIntel_AddOns_v0.7.2.zip`, sha256 `07b2c0fcc0626bd3bf0214c8d57ceabb132942d3ea1084ccaac8db6ede5a3a70`; `/reload`; no format change.

**Installed (as the user has said):** EmpireIntel 0.7.0 (0.7.1 sent, not reported installed), EmpireIntelCheck 0.1.9-tp1.

**Open questions:** none new.

**User's next step:** install 0.7.2, /reload (expect the chat line removing the repeated Enchanting 150), run gate steps 2, 3, 6, 8 once, send screenshots of both modes (as images) and the saved file; then decide on merging #17 and closing P2-4b.

## S-063 | 2026-11-09 | Claude

**Phase and increment:** Phase 2, P2-4b. Live gate on 0.7.0 **partly passed** (steps 1, 4, 5, 7; D-063). Retest build **EmpireIntel 0.7.1** (items 1-9, D-064) on `p2-4b-window`, PR #17 open, **not merged** ("Don't merge #17").

**Approved:** through D-063 (fix items 1-9; plan items 10-11 without code).

**Pending (the user decides):** the retest (gate steps 2, 3, 6, 8; README in the zip); merging #17; closing P2-4b; Q-P2-4c and Q-P2-4d with their sub-questions (Phase2_Plan.md section 10); the next check version (D-059, not built); #10 (P3-2 becomes format 3 when next edited); Q-T4; Stage 1.

**Branches and pull requests:** main 9cb1d10 (EmpireIntel 0.6.0, EmpireIntelCheck 0.1.9-tp1, 408 tests). `p2-4b-window` (PR #17): main plus 0.7.0 and 0.7.1, 514 tests (Lua 5.1 and 5.3); does not match main. #11 reference only; #10 open.

**Package:** `EmpireIntel_AddOns_v0.7.1.zip`, sha256 `937d51e9944ac7334cc3a118d15d6eb056091d969068396f9c561b1299120866` (P2-4b_Report.md section 6); `/reload`; no format change. Note: the build tool stores file times, so a rebuild from a fresh checkout gives another sha256 with the same files.

**Installed (as the user has said):** EmpireIntel 0.7.0, EmpireIntelCheck 0.1.9-tp1.

**Open questions:** Q-P2-4c, Q-P2-4c-1..3, Q-P2-4d, Q-P2-4d-1..3. My plan's screenshot (0.7.0) received later as an image: finding 10 (My plan time and points counted from today, overlapping) proposed for 0.7.2, waiting for the user's go-ahead; one duplicate Enchanting 150 is saved in the user's plan (remove it, or copy the route again).

**User's next step:** install 0.7.1, repeat gate steps 2, 3, 6, 8, send the screenshots (as images) and the saved file; answer Q-P2-4c and Q-P2-4d.

## S-062 | 2026-11-08 | Claude

**Phase and increment:** Phase 2, P2-4b **built** as EmpireIntel 0.7.0 (D-061 approval, D-062 build choices) on branch `p2-4b-window`, pull request open, **not merged**.

**Approved:** through D-061 (the P2-4b plan with the fill path). #16 merged (9cb1d10).

**Pending (the user decides):** the live gate (P2-4b_Report.md section 5; with ElvUI on and off); merging the P2-4b pull request; closing P2-4b; the next check version (D-059, not built); #10 (P3-2 becomes format 3 when next edited; Q-P3-2a later); Q-T4; Stage 1.

**Branches and pull requests:** main 9cb1d10 (EmpireIntel 0.6.0, EmpireIntelCheck 0.1.9-tp1, 408 tests). `p2-4b-window`: main plus 0.7.0, 485 tests (Lua 5.1 and 5.3); does not match main. #11 reference only; #10 open.

**Package:** `EmpireIntel_AddOns_v0.7.0.zip` (sha256 in P2-4b_Report.md section 4); `/reload`; no format change.

**Installed (as the user has said):** EmpireIntel 0.6.0, EmpireIntelCheck 0.1.9-tp1.

**User's next step:** install 0.7.0, run the 8-step live gate with ElvUI on and off, send screenshots, the saved file and the fill-path line.

## S-061 | 2026-11-08 | Claude

**Phase and increment:** P2-4a **closed** (D-060). Mockup **approved** (D-060). P2-4b **planned** in Phase2_Plan.md section 9 (EmpireIntel 0.7.0), for approval; **no window code**.

**Approved:** through D-060: the game's faction emblems; the game's built-in fonts, none shipped; resizable window, size and position remembered, moderate default.

**Pending (the user decides):** Q-P2-4b-1..4 (Phase2_Plan.md 9.8); merging this plan pull request (`p2-4b-plan`; it changes Phase2_Plan.md, outside the docs-only approval); the next check version (D-059, not built); #10 (P3-2 becomes format 3 when next edited; Q-P3-2a later); Q-T4; Stage 1.

**Branches and pull requests:** main 72f4192 (#15 merged; EmpireIntel 0.6.0, EmpireIntelCheck 0.1.9-tp1, 408 tests). `p2-4b-plan`: main plus this plan, pull request open. #11 reference only; #10 open.

**Installed (as the user has said):** EmpireIntel 0.6.0, EmpireIntelCheck 0.1.9-tp1; both match main.

**User's next step:** read Phase2_Plan.md section 9, answer Q-P2-4b-1..4, approve (or not) merging the plan pull request.

## S-060 | 2026-11-08 | Claude

**Phase and increment:** P2-4a merged (#14, merge commit 70da547; main: EmpireIntel 0.6.0, EmpireIntelCheck 0.1.9-tp1, 408 tests on Lua 5.1 and 5.3). P2-4a stays open until the user closes it. **P2-4b: static mockup published for approval** (private Artifact: https://claude.ai/artifact/GrBwFsCBY7uZssod6mkLA1): Fastest mode, My plan mode (in-place edit, drag, right-click menu), parts (Up Next card for an alt, badges, row icons, rules tooltip, minimap button, compartment). **No window code.**

**Approved:** through D-059: merge #14 (done); EI-E-31 ElvUI-off run corrected; next check version (setter labels, SetColorTexture read-back) later, not built; Q-P2-4a-3 yes (DataStore `GetCharacterFaction`, read-only, built with P2-4b).

**Pending (the user decides):** the mockup (approve or change; open questions in the report to the user: faction emblem art, the font, window size); P2-4b build after approval; closing P2-4a; #10 (P3-2 becomes format 3 when next edited; Q-P3-2a later); Q-T4; Stage 1.

**Branches and pull requests:** main 70da547 plus this docs pull request. #11 reference only; #10 open. `p2-4a-planner` merged (kept).

**Installed (as the user has said):** EmpireIntel 0.6.0, EmpireIntelCheck 0.1.9-tp1; both match main.

**User's next step:** review the mockup; answer its questions; `/ei plan copy` to drop C3's old entries from "my plan".

## S-059 | 2026-11-08 | Claude

**Phase and increment:** Phase 2, P2-4a: live tests received; findings 1-4 answered (P2-4a_Report.md section 6); evidence EI-E-29..31; D-058. Code unchanged since S-058 (the packages are the ones tested).

**Approved:** Q-P2-4a-1 (edit "my plan" in chat); Q-P2-4a-2: merge #14 after findings 2-4 are answered. **The merge was attempted and refused by the session's permission check ("Merge Without Review")**; not worked around. #14 is open, not merged.

**Pending (the user decides):** confirm the merge of #14 after reading the answers (or merge it yourself); Q-P2-4a-3 (DataStore faction getter, open); the next check version (setter labels, a SetColorTexture read-back), only if wanted; the static mockup, then P2-4b; closing P2-4a; #10 (P3-2 becomes format 3 when next edited; Q-P3-2a later); Q-T4; Stage 1.

**User action noted:** "my plan" still holds 6 entries for C3 (copied before the ignore); `/ei plan copy` again replaces them.

**Branches and pull requests:** main 5e37b2d (0.5.2, 0.1.8-tp1). `p2-4a-planner` (#14): ce9786f plus this handoff; 0.6.0, 0.1.9-tp1, 408 tests (Lua 5.1 and 5.3); does not match main. #11 reference only; #10 open.

**Installed (as the user has said):** EmpireIntel 0.6.0, EmpireIntelCheck 0.1.9-tp1 (both from `p2-4a-planner`).

**User's next step:** read the answers; reply "merge #14" to confirm (or merge it on GitHub).

## S-058 | 2026-11-08 | Claude

**Phase and increment:** Phase 2, P2-4a **built** (D-056 approval, D-057 build choices): EmpireIntel 0.6.0 and EmpireIntelCheck 0.1.9-tp1 on branch `p2-4a-planner`, pull request #14, **not merged**. No window code (P2-4b) before the user approves the static mockup.

**Approved:** through D-056. Q-F3 closed (Explorer after 50, counting zones already explored; Spelunker at any level).

**Pending (the user decides):** the live tests of 0.6.0 and 0.1.9-tp1 (P2-4a_Report.md section 4; steps in each package README); merging #14 (after the tests); Q-P2-4a-1..3 (P2-4a_Report.md section 5); then the mockup and P2-4b; #10 (post-25 plan; when next edited, P3-2 becomes format 3; Q-P3-2a later); Q-T4; Stage 1.

**Branches and pull requests:** main 5e37b2d (#13 merged: D-056, S-057, the prompt fix; EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1, 321 tests). `p2-4a-planner` (#14): main plus P2-4a, 408 tests (Lua 5.1 and 5.3), 20/20 mutants; does **not** match main. `p2-4-next` (#11): kept, reference only, not to merge. `p3-post25-plan` (#10): open. Other branches: merged history, kept.

**Packages (built from `p2-4a-planner`):** `EmpireIntel_AddOns_v0.6.0.zip` sha256 fbdbbf0f0856ac43e3853cb879982938cd7d3770a1ea38a9ab5782ece654c598; `EmpireIntelCheck_AddOns.zip` (0.1.9-tp1) sha256 c44702ec149d160ae9ca71813c5118922957773f380ab9b8424fb3dc7f37444f. Both `/reload`. 0.6.0 moves the saved file to schema 2: back up `EmpireIntel.lua` first (README step 1); 0.5.2 opens schema 2 read-only.

**Installed (as the user has said):** EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1.

**User's next step:** install both packages, run the README tests, send the two saved files and the chat lines; then approve (or not) merging #14.

## S-057 | 2026-11-08 | Claude

**Phase and increment:** P2-4a and EmpireIntelCheck 0.1.9-tp1 **approved for building** (D-056). Building on branch `p2-4a-planner` (not yet pushed when this section was written). No window code (P2-4b) before the user approves the static mockup.

**Approved:** through D-056. Q-F3 closed: zone Explorer after 50, counting zones already explored on the way; Spelunker at any level.

**Pending (the user decides):** merging the P2-4a build and 0.1.9-tp1; the mockup; P2-4b; #10 (post-25 plan; when next edited, its P3-2 becomes format 3; Q-P3-2a later); Q-T4; Stage 1. #11 stays open, reference only.

**Note on numbering:** there is no S-054 on main. S-054 (and decision D-053) were written on branch `p2-4-next` (#11), which is not merged; main goes S-053 to S-055 and D-052 to D-054.

**Main:** c765948 (EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1, 321 tests, Lua 5.1 and 5.3). This docs-only pull request (`docs-d056`: Decisions.md D-056, this section, NEXT_SESSION_PROMPT.md) is merged by Claude under the docs-only standing approval.

**Installed (as the user has said):** EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1.

**User's next step:** wait for the build report in this session.

## S-056 | 2026-11-08 | Claude

**Phase and increment:** P2-4 revised and **approved** (D-055). Next: build **P2-4a** (rules table, route engine, both modes, `/ei next`, saved-data format 2 for the plan) and **EmpireIntelCheck 0.1.9-tp1** with the UI checks (Phase2_Plan.md 8.3.4). **P2-4b** (the window) waits for the check's results and an approved static mockup (8.3.5). No code yet for any of these.

**Approved:** through D-055. #12 (the revised plan) merged by Claude under the user's approval.

**Pending (the user decides):** zone Explorer timing (Q-F3, left as "[after 50 / other]"); the mockup (later); P2-4b; the post-25 plan #10 (Q-P3-2a first; P3-2 is now format 3); Q-T4; Stage 1. #11 (`p2-4-next`) stays open, not merged, reference only.

**Facts to carry:** a rested pool of R saves R of kill XP (L-17, unverified on Forever; check: `/ei` before and after one rested kill). Rules L-1..L-18 in Phase2_Plan.md 8.4 with sources. Method and Hated Legacy findings in 8.4.

**Main:** after #12, EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1, 321 tests. Open pull requests: #10 (post-25 plan), #11 (reference).

**Installed (as the user has said):** EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1.

**User's next step:** start a new Code session from NEXT_SESSION_PROMPT.md on main; approve the start of the P2-4a and 0.1.9-tp1 build there.

## S-055 | 2026-11-08 | Claude

**Phase and increment:** P2-4 **redirected** by the user (D-054): no plan text file; an in-game window and a route planner. #11 (`p2-4-next`: 0.6.0, EmpireIntel_Plan 1) is kept, not merged, not to be installed. Revised plan: Phase2_Plan.md section 8 (P2-4a planner, P2-4b window), for approval. No code.

**Pending (the user decides):** Q-P2-4r, Q-P2-4r-a, Q-P2-4r-b, Q-G1-3, Q-F1-5 (Phase2_Plan.md 8.9); merging this plan pull request (it changes Phase2_Plan.md, outside the docs-only approval); the post-25 plan (#10) and its questions, first Q-P3-2a; Q-T4; Stage 1.

**Branches and pull requests:** main 90cb234 (EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1, 321 tests). `p2-4-next` (#11, kept, not to merge). `p3-post25-plan` (#10, open). `p2-4-planner-plan` (this plan, open).

**Installed (as the user has said):** EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1.

**User's next step:** read Phase2_Plan.md section 8 and answer 8.9; answer Q-P3-2a when convenient.

## S-053 | 2026-11-08 | Claude

**Phase and increment:** Phase 2, increment P2-4 **approved** with the Legacy lock rule (D-052); build next as EmpireIntel 0.6.0 plus EmpireIntel_Plan 1. Also asked: a post-25 plan (Phase 3: P3-2, P3-3, perk goals), plan only.

**Approved:** through D-052, including merging the plan pull request #9 after the lock-rule edits (done in this push).

**Pending:** the P2-4 build and its live gate; the post-25 plan and its questions; Q-T4; Stage 1.

**Installed:** EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1.

## S-052 | 2026-11-08 | Claude

**Phase and increment:** none open. P2-4 ("What next") **planned** in Phase2_Plan.md section 7, at the user's request ("Plan only, no code and no build"). Waiting for Q-P2-4 and Q-P2-4a-e.

**Pending (the user decides):** Q-P2-4 (approve P2-4 as 0.6.0 plus EmpireIntel_Plan 1, with plan file format 1); a (goal kinds); b (Legacy reads in a Phase 2 increment); c (plan folder shipped once); d (default thresholds); e (default after the unlock). Merging the plan pull request (`p2-4-plan`): it changes Phase2_Plan.md, outside the docs-only standing approval, so it waits for the user. Q-T4, P3-2, P3-3, Stage 1 as before.

**Main:** a9dca1d (EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1, 321 tests). Branch `p2-4-plan`: main plus this plan, pull request open.

**Installed:** EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1; both match main.

**User's next step:** read Phase2_Plan.md section 7, answer Q-P2-4 and a-e, and approve (or not) merging the plan pull request.

## S-051 | 2026-11-08 | Claude

**State:** as S-050, plus D-051: the docs-only standing approval also covers TODO.md and Changelog.md. TODO.md updated (1.3.0). This pull request is merged by Claude under that approval. No open pull requests after it. Nothing pending; next step: none for now.

## S-050 | 2026-11-08 | Claude

**Phase and increment:** none open; P2-3 and P3-1 closed. User: "Nothing else for now."

**Approved:** everything through D-050. **Pending (the user decides):** the next piece of work (none named); Q-T4 (unapproved); P3-2, P3-3 (locked); Stage 1 (not authorized).

**Main:** 5377093 (merge of #6, user): EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1, `.claude/settings.json` allowing the REST merge command (D-050); 321 tests pass under Lua 5.1 and 5.3. All earlier branches are merged (#1-#6); no open pull requests except this handoff's, which Claude merges under the docs-only standing approval (D-049). TODO.md still lists "merge the claude-settings pull request" as open; it is done (#6) and is ticked in the next non-docs-only change.

**Installed (as the user has said):** EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1; both match main.

**User's next step:** none for now. A new session starts from NEXT_SESSION_PROMPT.md on main.

## S-049 | 2026-11-08 | Claude

**Phase and increment:** none open; P2-3 and P3-1 closed. Next: "nothing for now" (user).

**Approved:** everything through D-050: the merge standing order, the REST merge command and the docs-only standing approval (CODE_STANDING_ORDERS.md section 2). This pull request (#5) is merged by Claude under the docs-only standing approval.

**Merges done:** #1 (634bd63), #2 (e8a30b3), #3 (c5434a7), #4 (5091f39, docs). Main 5091f39: EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1; 321 tests pass under Lua 5.1 and 5.3.

**Open pull requests:**
- `docs-merge-standing-order`: D-049, standing orders 1.1.0, next-session prompt, this handoff. Docs-only within D-049: Claude merges it and tells the user.
- `claude-settings` (#6): `.claude/settings.json` allowing `Bash(gh api -X PUT repos/shawn571/EmpireIntel/pulls/*/merge *)` (D-050), plus Changelog and TODO. The user merges it.

**Installed (as the user has said):** EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1; both match main.

**Open questions:** Q-T4 (unapproved); Stage 1 (not authorized); none on merging: `gh pr merge` cannot work here (GraphQL refused), so merges use the REST command (D-050).

**User's next step:** merge the settings pull request; nothing else for now.

## S-048 | 2026-11-08 | Claude

**Phase and increment:** P2-3 and P3-1 closed. No phase or increment is approved for new work. P3-2 and P3-3 locked.

**Approved:** everything through D-048. **Pending (the user decides):** merging the docs pull request (`docs-after-merges`); what comes next (no increment approved); Q-T4 (unapproved); Stage 1 (not authorized).

**Branches and pull requests:**

| Branch | Head | Holds | Matches main? |
|---|---|---|---|
| main | c5434a7 | merge of #3: EmpireIntel 0.5.2, EmpireIntelCheck 0.1.8-tp1, docs to S-047; 321 tests | is main |
| p2-1-foundation, p2-2-alts | | | contained in main |
| p2-3-views (#1), tp1-legacy-read (#2), p3-1-legacy (#3) | | | merged; no new work |
| docs-after-merges | this push | main plus this handoff, D-048 and the next-session prompt naming main | no: one docs commit ahead; pull request open |

**Installed (as the user has said):** EmpireIntel 0.5.2 and EmpireIntelCheck 0.1.8-tp1, both matching main.

**Open questions:** what to work on next; Q-T4.

**User's next step:** merge the docs pull request; then name the next piece of work (or none).

## S-047 | 2026-11-08 | Claude

**Phase and increment:** P2-3 and P3-1 closed; EmpireIntel 0.5.2 installed and checked. No increment open; P3-2, P3-3 locked.

**Approved:** as S-046, plus merge 3 (D-047). **Pending:** merging the merge 3 pull request; Q-T4 (unapproved); Stage 1 (not authorized); what comes next after the merges (no phase or increment approved).

**Branches and pull requests:**

| Branch | Head | Holds | Matches main? |
|---|---|---|---|
| main | e8a30b3 | merge of #2: EmpireIntel 0.4.0, EmpireIntelCheck 0.1.8-tp1; 283 tests | is main |
| p2-3-views | 257c2bb | | merged (#1) |
| tp1-legacy-read | 1544eb5 | | merged (#2) |
| p3-1-legacy | this push | plus EmpireIntel 0.5.2 (321 tests) and the newest docs | no: ahead; merge 3 pull request open |

**Installed (as the user has said):** EmpireIntel 0.5.2; EmpireIntelCheck 0.1.8-tp1.

**After merge 3:** main matches the installed versions; new work branches from main; NEXT_SESSION_PROMPT.md should then point at main (docs change, after the merge).

**User's next step:** merge the merge 3 pull request on GitHub ("Create a merge commit") and say so.

## S-046 | 2026-11-08 | Claude

**Phase and increment:** P2-3 and P3-1 closed; EmpireIntel 0.5.2 installed and checked. No increment open; P3-2, P3-3 locked.

**Approved:** as S-044, plus merge 2 (D-045). **Pending:** merging pull request 2; merge 3 (separate approval); Q-T4 (unapproved); Stage 1 (not authorized).

**Branches and pull requests:**

| Branch | Head | Holds | Matches main? |
|---|---|---|---|
| main | 634bd63 | merge of #1: EmpireIntel 0.4.0, EmpireIntelCheck 0.1.5-tp1; 244 tests | is main |
| p2-3-views | 257c2bb | EmpireIntel 0.4.0 | merged (#1) |
| tp1-legacy-read | 1544eb5 | plus EmpireIntelCheck 0.1.8-tp1, docs runs 6-15 | no: ahead; pull request https://github.com/shawn571/EmpireIntel/pull/2 open, clean |
| p3-1-legacy | this push | plus EmpireIntel 0.5.2 and the newest docs | no: ahead, merge 3 not approved |

**Installed (as the user has said):** EmpireIntel 0.5.2; EmpireIntelCheck 0.1.8-tp1.

**User's next step:** merge #2 on GitHub ("Create a merge commit") and say so; approve merge 3 when ready.

## S-045 | 2026-11-08 | Claude

**State:** as S-044. Merge 2 approved (D-045). Pull request https://github.com/shawn571/EmpireIntel/pull/1 is **still open, not merged** (GitHub API); main is 83b3574 (0.3.1, 212 tests pass). The merge 2 pull request (`tp1-legacy-read` into main) is held until #1 is merged. Merge 3 waits for separate approval.

**User's next step:** merge #1 on GitHub ("Create a merge commit"), say so; then the main check and the merge 2 pull request follow.

## S-044 | 2026-11-08 | Claude

**Phase and increment:** P2-3 and P3-1 closed. EmpireIntel 0.5.2 checked live (D-044). No increment open; P3-2, P3-3 locked.

**Done (docs only):** D-044; pull request https://github.com/shawn571/EmpireIntel/pull/1 (`p2-3-views` 257c2bb into main 83b3574; GitHub reports it mergeable, clean), for the user to merge on GitHub with a merge commit. Restored the Decisions.md "Open questions" heading that the S-043 edit dropped.

**Pending (the user decides):** merging pull request 1; merges 2 (`tp1-legacy-read`) and 3 (`p3-1-legacy`), each separately; Q-T4 (unapproved); Stage 1 (not authorized).

**Branches:** as S-043, except `p3-1-legacy` head is this push. One pull request: #1, open.

**Installed (as the user has said):** EmpireIntel 0.5.2 (files from d1ae945, all 20 match); EmpireIntelCheck 0.1.8-tp1.

**Note for merges 2 and 3:** after a merge-commit merge of pull request 1, merges 2 and 3 are merge commits too; no conflicts expected, since each branch already contains `p2-3-views`.

**User's next step:** merge pull request 1 on GitHub and say so; approve merge 2 when ready.

## S-043 | 2026-11-08 | Claude

**Phase and increment:** P2-3 and P3-1 closed. EmpireIntel 0.5.2 built (labels only, D-043), waiting for the user's live check. No increment open; P3-2, P3-3 locked.

**Done:** 0.5.2 on `p3-1-legacy` (this push): rest label and milestones label (D-041, D-043). 321 tests pass under Lua 5.1 and 5.3. `dist/EmpireIntel_AddOns_v0.5.2.zip`, sha256 5738fb7dd89326f5010a94ec310cd0995f43d4236904d30f8854f58c635d1251.

**Merge 1 (`p2-3-views` into main): approved, NOT done.** The fast-forward push to main was blocked by the session's auto-mode permission check. Main is still 83b3574 (EmpireIntel 0.3.1). The user chooses: allow the push in this session, or merge on GitHub.

**Pending (the user decides):** the 0.5.2 live check; how to do merge 1; merges 2 (`tp1-legacy-read`) and 3 (`p3-1-legacy`), separately; Q-T4 (unapproved); Stage 1 (not authorized).

**Branches:**

| Branch | Head | Holds | Matches main? |
|---|---|---|---|
| main | 83b3574 | EmpireIntel 0.3.1, EmpireIntelCheck 0.1.5-tp1 | is main |
| p2-3-views | 257c2bb | EmpireIntel 0.4.0 | no: ahead, merge approved, not done |
| tp1-legacy-read | 1544eb5 | plus EmpireIntelCheck 0.1.8-tp1 | no: ahead, unmerged |
| p3-1-legacy | this push | plus EmpireIntel 0.5.2 and the newest docs | no: ahead, unmerged |

No pull requests.

**Installed (as the user has said):** EmpireIntel 0.5.1; EmpireIntelCheck 0.1.8-tp1. 0.5.2 delivered, not yet installed.

**User's next step:** install 0.5.2 with `/reload` and run README steps 3-6; say how to do merge 1.

## S-042 | 2026-11-08 | Claude

**Phase and increment:** P2-3 **closed** (D-041) and P3-1 **closed** (D-042). No increment is open. Phase 3 has no further increment approved: P3-2 and P3-3 are locked.

**Done (docs only):** formal inn test recorded and passed (P2-3_Report.md section 3, EI-E-28); 0.5.1 check recorded (P3-1_Report.md section 2); D-041, D-042; TODO and Changelog updated. No code changed, nothing merged. Session renamed "EmpireIntel Code" (user).

**Approved:** as S-041, plus D-041 (close P2-3; narrow the rest label to inn rate checked, outside rate and cap unverified) and D-042 (close P3-1).

**Pending (the user decides):**
- Go-ahead to build the rest label change (D-041) as EmpireIntel 0.5.2 on `p3-1-legacy` (`/reload`).
- The `/ei milestones` rules label: keep or drop "not yet confirmed" (EI-E-22 confirmed the class and crafting rules).
- Merges, one approval each, in this order: `p2-3-views` (EmpireIntel 0.4.0), then `tp1-legacy-read` (EmpireIntelCheck 0.1.8-tp1), then `p3-1-legacy` (EmpireIntel 0.5.1 and the newest docs). Each is a fast-forward of main; tests pass at each head (244, 283, 321, under Lua 5.1 and 5.3).
- Q-T4: unapproved. P3-2, P3-3: locked. Stage 1: not authorized.

**Branches:** as S-040, except `p3-1-legacy` head is this push. No pull requests.

**Installed (as the user has said):** EmpireIntel 0.5.1 (confirmed 09:50, 2026-11-08); EmpireIntelCheck 0.1.8-tp1; GoldIntel and DataStore/Altoholic. The stale beta Shaman (C3) is still in DataStore.

**Open questions:** the two pending decisions above, the merges, Q-T4.

**User's next step:** approve (or not) the 0.5.2 label build and the milestones label; approve merges one at a time.

## S-041 | 2026-11-08 | Claude

**Phase and increment:** unchanged from S-040: P3-1 built as EmpireIntel 0.5.1, waiting for the `/ei legacy all` look, then Q-P3-1c; P2-3 built as 0.4.0, waiting for the formal inn test, then Q-P2-3c.

**Done (docs only):** new session verified the repository against S-040: branch heads, TOC versions (EmpireIntel 0.5.1, EmpireIntelCheck 0.1.8-tp1 on `p3-1-legacy`; 0.3.1 and 0.1.5-tp1 on main), main at S-022 docs, repository private, no pull requests, 321 tests pass under Lua 5.1 and 5.3. No conflict found other than the one below, now settled. D-040: Project_Bible.md section 5 follows D-034 (v1.2.0); paraphrased early rules in CODE_STANDING_ORDERS.md section 7 accepted.

**Approved:** as S-040, plus D-040.

**Pending (the user decides):** Q-P3-1c, Q-P2-3c, Q-T4, P3-2 and P3-3 (locked), Stage 1 (not authorized), merges (none without approval; order `p2-3-views`, `tp1-legacy-read`, `p3-1-legacy`).

**Branches:** as S-040, except `p3-1-legacy` head is this push. No pull requests.

**Installed (as the user has said):** EmpireIntel 0.5.0 (0.5.1 delivered, not yet confirmed); EmpireIntelCheck 0.1.8-tp1.

**Open questions:** Q-P3-1c, Q-P2-3c, Q-T4. No open doc conflict.

**User's next step:** as S-040: install 0.5.1 with `/reload`, type `/ei legacy all`, say whether it reads well (Q-P3-1c); run the formal inn test, then decide Q-P2-3c.

## S-040 | 2026-11-08 | Claude

**Phase and increment:** Phase 3, increment P3-1 (`/ei legacy`), built as EmpireIntel 0.5.1; waiting for the user's look at `/ei legacy all`, then Q-P3-1c. Phase 2 increment P2-3 (views) built as 0.4.0; views check passed; formal inn test pending, then Q-P2-3c. TP-1 (EmpireIntelCheck) at 0.1.8-tp1, the Legacy read proven (runs 6-15).

**Approved:**
- Phase 2 (pre-25 features; D-027): P2-1 closed (D-029), P2-2 closed (D-032), P2-3 built (D-033).
- Phase 3, P3-1 only (D-037), with no saved crash guard (Q-P3-1a).
- Q-T7, Q-T8 and Q-T9 (check Legacy reads).
- The standing orders (D-039).

**Pending (the user decides):**
- Q-P3-1c: close P3-1, after a look at 0.5.1.
- Q-P2-3c: close P2-3, after the formal inn test.
- Q-T4: trait-system reads, after P3-1 passes its live gate.
- P3-2 and P3-3: locked.
- Release pipeline Stage 1: not authorized.
- Merges: none without approval. The order is `p2-3-views`, then `tp1-legacy-read`, then `p3-1-legacy`.

**Branches** (no pull requests exist):

| Branch | Head | Holds | Matches main? |
|---|---|---|---|
| main | 83b3574 | EmpireIntel 0.3.1, EmpireIntelCheck 0.1.5-tp1, docs to S-022 | is main |
| p2-1-foundation | ca0d2b6 | merged earlier (P2-1) | contained in main |
| p2-2-alts | 83b3574 | P2-2 | identical to main |
| p2-3-views | 257c2bb | EmpireIntel 0.4.0 (P2-3) | no: ahead of main, unmerged |
| tp1-legacy-read | 1544eb5 | p2-3-views plus EmpireIntelCheck 0.1.6-0.1.8 and docs | no: ahead, unmerged |
| p3-1-legacy | this push | tp1-legacy-read plus EmpireIntel 0.5.0-0.5.1 and the newest docs | no: ahead, unmerged |

**Installed (as the user has said):**
- EmpireIntel 0.5.0 (0.5.1 delivered; installation not yet confirmed).
- EmpireIntelCheck 0.1.8-tp1.
- GoldIntel and DataStore/Altoholic also installed.
- The user will delete the stale beta Shaman in Altoholic.

**Open questions:** Q-P3-1c, Q-P2-3c, Q-T4. Conflict to confirm: Project_Bible.md section 5 restart rule vs D-034 (see D-039).

**User's next step:**
1. Install 0.5.1 with `/reload`, open the Legacy window, type `/ei legacy all`, and say whether it reads well (Q-P3-1c).
2. Run the formal inn test from the P2-3 README, then decide Q-P2-3c.

## S-039 | 2026-11-08 | Claude

- **Done:** P3-1 live test 1 recorded; 0.5.1 fixes the `/ei legacy all` order and the Explorer wording.
- **WAITING FOR:** a look at `/ei legacy all` on 0.5.1, then Q-P3-1c; the formal inn test, then Q-P2-3c.

## S-038 | 2026-11-08 | Claude

- **Done:** built P3-1 as EmpireIntel 0.5.0 on branch `p3-1-legacy` (D-038). `dist/EmpireIntel_AddOns_v0.5.0.zip`.
- **Branch stack:** `p3-1-legacy` is built on `tp1-legacy-read`, which is built on `p2-3-views`. Nothing is merged; merge order on approval: P2-3, then TP-1, then P3-1.
- **WAITING FOR:** the P3-1 live gate, then Q-P3-1c; the formal inn test, then Q-P2-3c.

## S-037 | 2026-11-08 | Claude

- **Done:** run 15 recorded (TP1_Report_Run1.md section 22, EI-E-27); P2-3_Report.md; D-037 (Phase 3, P3-1 only).
- **NEXT:** build P3-1 as 0.5.0 on branch `p3-1-legacy`.
- **WAITING FOR:** the formal inn test, then Q-P2-3c.

## S-036 | 2026-11-08 | Claude

- **Done:** spentInTree inventory (TP1_Report_Run1.md section 21); `/ei legacy` plan (Phase3_Legacy_Plan.md). No code.
- **WAITING FOR:** Q-P3, Q-P3-1, Q-P3-1a; the P2-3 views check and the inn test, then Q-P2-3c; optionally the spentInTree screenshot test.

## S-035 | 2026-11-08 | Claude

- **Done:** run 14 recorded: the second point came from Novice Spelunker (Excavation Site: Wetlands).
- **Open for the user:** spentInTree (leave out, or Q-T4); whether to plan `/ei legacy` (Phase 3, not authorized); P2-3 confirmation and the inn test, then Q-P2-3c.

## S-034 | 2026-11-08 | Claude

- **Done:** recorded run 13 (TP1_Report_Run1.md section 19, EI-E-26). Available, spent and earned are settled; spentInTree is unexplained.
- **Open for the user:** keep spentInTree out (recommended), or approve Q-T4 to read the trees; the file showing which challenge gave point 2; P2-3 confirmation and the inn test.

## S-033 | 2026-11-08 | Claude

- **Done:** recorded run 12 (TP1_Report_Run1.md section 18, EI-E-25).
- **WAITING FOR:** the staging test now that a point is available (place without Apply, read, Apply, read); the file, to see which challenge gave the second point.

## S-032 | 2026-11-08 | Claude

- **Done:** recorded run 11 (TP1_Report_Run1.md section 17). spentInTree stays 0 with the pane open.
- **WAITING FOR:** which tree each read was on; which tree and perk hold the spent point; the staging test at the next available point; P2-3 confirmation and the inn test.

## S-031 | 2026-11-08 | Claude

- **Done:** recorded run 10 (TP1_Report_Run1.md sections 15 and 16, EI-E-24, Legacy_Rules.md section 4). No code changed; 0.1.8-tp1 stays current.
- **WAITING FOR:**
  - which tree and perk the point went into;
  - the selected-tree test for spentInTree;
  - the next earned point;
  - a read on a second character;
  - P2-3 confirmation and the inn test, then Q-P2-3c.

## S-030 | 2026-11-08 | Claude

- **Done:** read run 9 (TP1_Report_Run1.md section 14, EI-E-23). The check reads the challenges, steps and points correctly.
- **Open for the user:**
  - the P2-3 confirmation and the inn test, then Q-P2-3c;
  - the next step for Legacy data in EmpireIntel itself: Phase 3 is not authorized, and Phase 2 uses no Legacy API (D-027);
  - Q-T4 (trees) is still unapproved.

## S-029 | 2026-11-08 | Claude

- **Done:** built EmpireIntelCheck 0.1.8-tp1 (Q-T9, D-036). 283 tests; 38/38 mutants. `dist/EmpireIntelCheck_AddOns_v0.1.8-tp1.zip` (sha256 below in the package block).
- **WAITING FOR:** the 0.1.8 file and line; the user's check of the Explorer grouping in the pane; the P2-3 live and inn tests, then Q-P2-3c.

## S-028 | 2026-11-08 | Claude

- **Done:** read run 8 (TP1_Report_Run1.md section 13, EI-E-22, Legacy_Rules.md 1b). Proposed Q-T9 (0.1.8). No code changed.
- **WAITING FOR:** Q-T9; the P2-3 live and inn tests, then Q-P2-3c.

## S-027 | 2026-11-08 | Claude

- **Done:** built EmpireIntelCheck 0.1.7-tp1 (Q-T8, D-035) on `tp1-legacy-read`. 274 tests; all mutants caught. `dist/EmpireIntelCheck_AddOns_v0.1.7-tp1.zip` (sha256 c71ba1b5...).
- **WAITING FOR:** the 0.1.7 file and the Legacy read line; the P2-3 live and inn tests, then Q-P2-3c.

## S-026 | 2026-11-08 | Claude

- **Done:** read run 7 (TP1_Report_Run1.md section 12, EI-E-20/21, Legacy_Rules.md 1a). Proposed Q-T8 (0.1.7 fixes defects 13 and 14). No code changed.
- **WAITING FOR:** Q-T8; the P2-3 live and inn tests, then Q-P2-3c.

## S-024 | 2026-11-08 | Claude

- **Done:** built P2-3 as EmpireIntel 0.4.0 on branch `p2-3-views` (D-033). 244 tests pass under 5.1 and 5.3; 16 of 16 mutants caught. `dist/EmpireIntel_AddOns_v0.4.0.zip` (sha256 9ae2ac1b...).
- **WAITING FOR:** the P2-3 live test and the inn test, then Q-P2-3c. Also the EmpireIntelCheck 0.1.6 file and the user's Legacy Points line (sent as before: the file attached in chat, the line pasted).

## S-023 | 2026-11-08 | Claude

- **Done:** P2-3 plan, Phase2_Plan.md section 6, on branch `p2-3-views`. No code.
- **WAITING FOR:** Q-P2-3 (with a and b); the EmpireIntelCheck 0.1.6 run with the pane open, plus the user's Legacy Points line.

## S-022 | 2026-11-08 | Claude

- **Done:** P2-2 closed (D-032); `p2-2-alts` merged into main (fast-forward).
- **NEXT:** the P2-3 plan for approval (no code). **WAITING FOR:** the EmpireIntelCheck 0.1.6 run with the pane open, plus the user's Legacy Points line.

## S-021 | 2026-11-07 | Claude

- **Done:** Q-T7 approved; built EmpireIntelCheck 0.1.6-tp1 on branch `tp1-legacy-read` (stacked on `p2-2-alts`). Legacy_Rules.md written. 238 tests; 15/15 mutants. `dist/EmpireIntelCheck_AddOns_v0.1.6-tp1.zip`.
- **WAITING FOR:** the 0.1.6 run (full restart, pane opened, `/eicheck legacy`, file); the `/ei alts` lines on 0.3.1, then Q-P2-2c.
- **Open:** tree node names need the trait system (Q-T4) or tooltips; not part of Q-T7.

## S-020 | 2026-11-07 | Claude

- **Done:** read run 6 (the level-25 run, build 70862) and the EmpireIntel file as data. TP1_Report_Run1.md section 11; EI-E-15..17; Q-T7 proposed (achievement and currency getters). P2-2_Report.md section 4. No code changed.
- **WAITING FOR:** Q-T7; the Legacy point number from the pane plus a screenshot; `/ei alts` lines on 0.3.1 with DataStore on, then Q-P2-2c.

## S-019 | 2026-11-06 | Claude

- **Done:** read the 0.3.0 file and chat as data (P2-2_Report.md). The DataStore-off gate passed; format 1 is unchanged. D2 wording fixed in 0.3.1 (`/reload`).
- **WAITING FOR:** `/ei alts` with DataStore on, on 0.3.1, and the user's confirmation that it matches; then Q-P2-2c. Remind: install EmpireIntelCheck 0.1.5 before the level-25 run.

## S-018 | 2026-11-06 | Claude

- **Done:** Q-P2-2 approved. Built P2-2 as EmpireIntel 0.3.0 on branch `p2-2-alts` (D-030). 211 tests pass under 5.1 and 5.3; 13 of 13 guard mutants caught. Package `dist/EmpireIntel_AddOns_v0.3.0.zip` built and verified.
- **Not done, on purpose:** not merged to main; P2-2 not closed (Q-P2-2c). P2-3 not started.
- **WAITING FOR:** the P2-2 live test (full restart; `/ei alts` with DataStore on and off; saved file), then Q-P2-2c. Later: the level-25 run and Q-T4.

## S-017 | 2026-11-05 | Claude

- **Done:** P2-1 closed (D-029); branch merged into main (fast-forward). P2-2 written out in Phase2_Plan.md section 5.
- **WAITING FOR:** Q-P2-2. Later: the level-25 run and Q-T4.

## S-016 | 2026-11-05 | Claude

- **Done:** read the 0.2.1 file. D1 fix confirmed (true and false both stored); level, XP, profession and rested changes recorded correctly; the logout guard fired for both characters. P2-1_Report.md section 2.
- **WAITING FOR:** the user's confirmation that `/ei` matched the game, then Q-P2-1c.

## S-015 | 2026-11-05 | Claude

- **Done:** read the user's P2-1 file as data. Two records correct; meta exact; logout guard fired once as designed. Defect D1 (resting false lost) fixed in 0.2.1, `/reload` only, on branch `p2-1-foundation`.
- **WAITING FOR:** the 0.2.1 file, the user's confirmation that `/ei` matched the game, and Q-P2-1c.

## S-014 | 2026-11-05 | Claude

- **Done:** built P2-1 on branch `p2-1-foundation` (D-028): EmpireIntel 0.2.0, ported Platform and Store layers, own snapshot (format 1 with realm, no P_TICK), `/ei` commands. 178 tests pass under 5.1 and 5.3. Package `dist/EmpireIntel_AddOns_v0.2.0.zip` built and verified.
- **Not done, on purpose:** not merged to main; P2-1 is not closed (separate user approval). P2-2 not started.
- **WAITING FOR:** the user's live test (two characters, `/ei` against the game) and the saved file `EmpireIntel.lua`.

## S-013 | 2026-11-05 | Claude

- **Done:** Q-T5 (C_Reincarnation uncalled; whole-word blocklist with the Reincarnat stem) built as 0.1.5-tp1, with 99 tests passing and the mutation check holding. Phase 2 authorized for the pre-25 features only (D-027). Wrote Phase2_Plan.md: four increments and saved-data format 1.
- **Not authorized:** Stage 1; Q-T4 (after the level-25 run).
- **WAITING FOR:** Q-P2-1 (approve P2-1 including format 1); later the level-25 run.
- **NEXT RECOMMENDED TASK:** on approval, build P2-1: port Platform, Core and Store from GoldIntel a21e071 read-only, own snapshot, `/ei`. Full client restart.

## S-012 | 2026-11-05 | Claude

- **Done:** read run 5. `/eicheck undoc` called only `C_Seasons` (0, false); `C_Trophy` had no allowed names; `C_Reincarnation`'s 4 functions shown to the user, none called. Crash guard clean.
- **Conclusion:** before level 25, no Legacy data is reachable. TP-1 discovery is done until the unlock run.
- **OPEN:** Q-T5 (Reincarnation, recommend leave uncalled), Q-T6 (authorize Phase 2 and/or Stage 1), Q-T4 after level 25. Defect 11 is wording only, so it waits for the next build.

## S-011 | 2026-11-05 | Claude

- **Done:** Q-T3 approved with the user's limits (D-025). Built 0.1.4-tp1. 94 tests pass under 5.1 and 5.3. Each new guard, when disabled, fails the suite.
- **Told the user plainly:** an addon cannot write anything that survives a hard client crash, so the calls start only on the user's command and the marker covers disconnects, reloads and errors.
- **WAITING FOR:** the 0.1.4 file after `/eicheck undoc`. Then show the user C_Reincarnation's function list before anything is called there.

## S-010 | 2026-11-05 | Claude

- **Done:** read run 4 (0.1.3) as data. The docs survived (all 410 systems indexed, 14 matched). No Legacy system is documented; the 3 "Legacy" matches are retail enum fields (defect 10, not yet fixed). Comparing live namespaces with the docs found 20 undocumented ones (C_Seasons, C_Reincarnation, C_Trophy look Forever-related). Trait-system lead from the "Legacy" talent-frame tab and the CamelotCombat config type.
- **Not done, on purpose:** no code. Both next steps widen what the check calls (Q-T3, Q-T4).
- **NEXT RECOMMENDED TASK:** if Q-T3 is approved, build 0.1.4 (defect 10 + undocumented-namespace listing and guarded zero-argument calls for the three namespaces), `/reload` only.

## S-009 | 2026-11-05 | Claude

- **Done:** run 3 showed the docs run worked (14 of 410 systems matched) but the saved docs were dropped by the size cap. Built 0.1.3-tp1 with a docs budget and a docs-last trim order (D-024). 86 tests pass under 5.1 and 5.3. Mutation check: the guards are caught except "no save-time budget", which the trim covers anyway (near-equivalent).
- **WAITING FOR:** a 0.1.3 run with `/eicheck docs`. The user offered to paste text where it saves an upload. The docs need the file; the `/eicheck report` copy window was offered and not taken up.
- **NEXT RECOMMENDED TASK:** read the docs systems and look for the Legacy data API.

## S-008 | 2026-11-05 | Claude

- **Done:** read run 2 as data. Migration fine; no errors from EmpireIntelCheck or GoldIntel (T8); defect 8 found and fixed in 0.1.2-tp1 (82 tests pass under 5.1 and 5.3; run 2 re-classified as PANE ONLY). Recorded the user's scope point as FR-PRE-1..4 (D-022): EmpireIntel must guide progress before the Legacy unlock.
- **WAITING FOR:** the 0.1.2 run with `/eicheck docs` (not run so far).
- **NEXT RECOMMENDED TASK:** read the docs results; then the user decides D-012 and whether to authorize Stage 1 and Phase 2.

## S-007 | 2026-11-04 | Claude

- **Done:** the user approved Q-T1 and Q-T2. Built EmpireIntelCheck 0.1.1-tp1 (D-021): 82 tests pass under Lua 5.1 and 5.3; 21 guard mutants all caught; the user's run 1 re-classified offline reads PANE ONLY, provisional (locked). Package rebuilt and delivered.
- **UNEXPECTED / OPEN ISSUES:** the user was not sure whether errors appeared in game; T8 now reads BugSack's own error list, so the next file answers it. The pipeline stays at Stage 0.
- **WAITING FOR:** the user's 0.1.1 run with `/eicheck docs`; later a run after a character reaches level 25.
- **NEXT RECOMMENDED TASK:** read the docs results and look for the Legacy data API (look first at C_Traits and the CamelotCombat config type); report; then the Stage 1 and D-012 decisions.

## S-006 | 2026-11-04 | Claude

- **Done:** read the user's launch-build file as data (loaded with no globals and a time limit, outside the repo) and wrote TP1_Report_Run1.md with aliases only. Evidence EI-E-01..08.
- **Key facts:** the Legacy system is locked until the account's first character reaches level 25; no Legacy data API by name; the client text confirms the three trees, a points counter and a seasonal cap; docs are installed; DataStore matched live values.
- **UNEXPECTED:** the check reported FOUND on retail raid-difficulty getters (false positive); a hidden guild frame counted as "pane seen"; logout values were wrong; 6 of 8 runs were dropped by the size cap.
- **Not done, on purpose:** no code change. Fix 4 changes the check's saved-data format and needs approval (Q-T1). The pipeline stays at Stage 0.
- **NEXT RECOMMENDED TASK:** if Q-T1 is approved, build 0.1.1-tp1 (`/reload` only) with zip, steps and tests; then the docs run.

## S-005 | 2026-11-03 | Claude

- **Done:** recorded the approval of D-018 as a design only, the amendments and the answers (D-020). Release_Pipeline.md 0.2.0. Docs only.
- **Not done, on purpose:** no pipeline implementation; no change to EmpireIntelCheck; nothing about GoldIntel.
- **OPEN ISSUES:** the report task does not exist and has no owner yet (Release_Pipeline section 13).
- **BLOCKERS / WAITING FOR:** the user's launch-build run of EmpireIntelCheck 0.1.0-tp1 (TODO 1.5): `EmpireIntelCheck.lua` from SavedVariables plus a Legacy pane screenshot, sent by hand.
- **NEXT RECOMMENDED TASK:** when the files arrive, write the TP-1 report (verdict, result codes, unexpected conditions, evidence EI-E-01..). Commit only sanitized findings. Then the user decides D-012, D-005 and whether to authorize Stage 1.

## S-004 | 2026-11-03 | Claude

- **Done:** designed the EmpireIntel release pipeline (Release_Pipeline.md, D-018 Proposed) and recorded the user's executive roles (D-019). Docs only.
- **Not done, on purpose:** no implementation (needs approval); nothing changed in EmpireIntelCheck or the launch-build check; nothing about GoldIntel.
- **UNEXPECTED / OPEN ISSUES:** approvals and unpause can only be audited, not enforced, from the cloud side while Claude uses the user's GitHub identity (Q-R3). The game process names and the launch folder name are unknown until launch.
- **BLOCKERS:** user approval of D-018; Q-R1..Q-R6.
- **NEXT RECOMMENDED TASK:** the launch-build check results first. Then, if approved, pipeline stage 1 implementation.

## S-003 | 2026-11-03 | Claude

- **Done:** recorded the user's limits in Architecture 2.1.0 before coding. Built EmpireIntelCheck 0.1.0-tp1 and its offline suite: 65 tests pass under Lua 5.1 and 5.3. Each of the 13 safety guards was disabled once (mutation check) and the suite caught every one. Package `dist/EmpireIntelCheck_AddOns.zip` (8 files) built and verified.
- **Bugs found and fixed while testing:** an unrelated retail name (`C_Loot.IsLegacyLootModeEnabled`) made a clean client read NAMES ONLY; the pre-modern baseline check missed a single reappearing global; a multiple-return slip broke the DataStore cross-check; `off` during a run left the session stuck; `on` after an OFF login never started; the bounded dump had no total byte limit.
- **UNEXPECTED / OPEN ISSUES:** (1) The web hosts are still blocked in this session although the user allowed all domains (probably needs a new session), so the Legacy rules stay unverified (Q-9). (2) Blizzard UI addons cannot be listed by index on the modern client, so a Legacy pane that lives in a load-on-demand addon whose name has no Legacy term is caught only by the light rescan after any Blizzard addon loads, or by `/eicheck pane`. (3) The launch interface number may differ from 16001; the README tells the user to tick "Load out of date AddOns".
- **BLOCKERS:** the user's launch-build run (TODO 1.5).
- **NEXT RECOMMENDED TASK:** read the returned `EmpireIntelCheck.lua` and the pane screenshot; write the TP-1 report (verdict, every result code, unexpected conditions, evidence EI-E-01..); the user decides D-012 and D-005.

## S-002 | 2026-11-03 | Claude

- **Done:** applied the user's correction: "Legacy" is the Forever Legacy points system (D-010). Wrote Requirements_v1.md. Rewrote Architecture to v2.0.0: Legacy model, Estimator fallback, plan file, Planner, and TP-1 as a passive Legacy check. TP-1 keeps the platform checks T1..T7 and adds discovery of the Legacy API in the live client (no assumed names), rested XP, professions and fallback inputs. Recorded the user's working rules (Bible section 5, D-015).
- **Not done, on purpose:** no addon code; waiting for approval (Q-3).
- **UNEXPECTED / OPEN ISSUES:** (1) The user says the repository is private, but the GitHub API returned `private: false` for shawn571/EmpireIntel on 2026-11-03. (2) The Legacy rules come from search summaries only: Blizzard's article and the fan sites are blocked by the session network policy (Q-9). (3) No third-party addon reviewed reads Legacy data, so there is no known API name to start from. (4) The Forever AddOns folder name at launch is unknown (the beta used `_classic_beta_`).
- **BLOCKERS:** Q-3 approval; Q-7 (automatic getter calls).
- **NEXT RECOMMENDED TASK:** after approval, Phase 1 tasks 1.1 to 1.4; ship TP-1 for a launch-build run (full client restart; steps in Architecture section 9).

## S-001 | 2026-11-03 | Claude

- **Done:** set up the repository with documentation only (Changelog S-001). Audited GoldIntel at a21e071 for reuse; its suite ran 1255 passed / 0 failed under Lua 5.3. Reviewed DataStore 2026.10.14, its 15 modules, AddonFactory and Altoholic Forever 1.60.005 from source. Verdict: they hold up on Forever on paper; license is All Rights Reserved, so run-time use only. Wrote Architecture v1 (Proposed) with Test Package 1, the Legacy API check, as the first deliverable.
- **Not done, on purpose:** no addon code (user instruction: stop for approval before writing addon code). Nothing copied from GoldIntel or DataStore.
- **OPEN ISSUES:** Q-1..Q-6 in Decisions.md. The "goldintel-addon memory" the user referred to was not found (Q-6); governance was taken from GoldIntel's own documents. CurseForge comment threads could not be read (network policy), so user bug reports for Altoholic and DataStore on Forever are unreviewed.
- **BLOCKERS:** user approval of Architecture v1 (Q-3).
- **NEXT RECOMMENDED TASK:** after approval, Phase 1 tasks 1.1 to 1.4 (TP-1 code and offline tests). Then the user runs it on the launch build (Forever launches 2026-11-04).
