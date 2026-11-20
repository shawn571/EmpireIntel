EmpireIntel 0.7.5 - the plan window, the Fastest route's rules (P2-4b)

WHAT 0.7.5 CHANGES (your route rules, D-075, D-076)
  R-1  A profession is never assumed: a craft is planned only on characters that have it. No "Learn X" step.
       A craft no character has is not planned; the footer (and /ei next) says "Not planned: no character has ...".
  R-2  The highest skill is the path: each craft's milestones (150, 225, 300) go to the character with the highest
       skill (a tie goes to the higher level, then to the character you play), with its level gates.
  R-3  The Priest's Tailoring 225 is a planned step (on him, by R-2). It costs about 19 h (level 10 -> 20 first),
       so it comes after the cheaper points: it shows once the target reaches it (about 20 points today).
  R-5  Fastest's Up next is also row 1 (marked), and every row starts with its step number.
  R-7  A row with no point that opens a later point says "(prerequisite for step n)" (in both modes).
  The cap (16) now comes from the rules table, not from the window's code (R-6 itself comes with P2-4c).

WHAT 0.7.4 CHANGED (D-070)
  - Every Legacy milestone is its own row, in Fastest and in My plan. Learning Alchemy 0 -> 225 is two rows:
    "Learn Alchemy, 0 -> 150" and "Alchemy 150 -> 225", each with its own training gate and time. A milestone
    the account already has (or an earlier step earns) is a row with no point; hover it for why.
  - My plan: a saved step that passes a milestone without a row of its own gets that row, just before it, when
    you log in or /reload; chat says which (your Hunter gets "Alchemy 150" and "Blacksmithing 150").
    Raising a target past a milestone adds that milestone's row too.
  - Points are counted once per account in both modes: the Hunter's Alchemy 225 is +1 in My plan as in Fastest.
  - The faction emblem is about the size of the character portrait, level with it at the card's right; the realm
    badge sits to its left.

WHAT 0.7.3 CHANGED (D-066)
  - Moving a step up brings its whole chain ahead of it, in order: Enchanting 225 to the top puts Level 10,
    Enchanting 150 and Level 20 before it (chat: "Moved with it, in order: ..."). Moving a step down takes the
    steps that build on it along, after it. Nothing is left below as "covered".
  - Click a row to select it: the card shows that row's character (portrait for the one you play, else race and
    class icons), its faction and realm type, and the row's note. Click the card to go back to Up next.
    In My plan, click the selected row again (or right-click > Edit target) to edit its target.
  - Notes: hovering a row shows its note at the mouse pointer (tooltips now open at the pointer, so they cannot
    open off screen to the right of the window).
  - The faction emblem and the realm badge have fixed sizes: the emblem's disc is as high as the badge (22 px).

WHAT 0.7.2 ADDED (D-065)
  10. My plan counts each row from the end of the earlier steps of the same character (and profession):
      "Level 20" after "Level 10" shows only the time from 10 to 20; "Enchanting 225" after "Enchanting 150"
      only 150 to 225. A step an earlier step already reaches reads "(covered by step n)", greyed, with no
      time or points. NOW stays today's value. The footer counts covered steps.
  Repeated steps in My plan are removed when you log in or /reload (the first of each is kept, with a later
  copy's note if it had none); chat says which, for example
      "plan: removed 1 repeated step from my plan (the first of each is kept): step 9 <name> Enchanting 150."

WHAT 0.7.1 CHANGED (your findings 1 to 9, D-063)
  1. My plan keeps prerequisites (training gates, L-4). A move, Move to top or drag that would put a skill
     step above the level step it needs takes that level step along; moving a level step down takes the
     steps that need it along. Chat says what moved with it. Removing or lowering a level step that a later
     step needs is refused, with the reason. A skill step with no level step before it shows as a gate.
  2. Add a skill step after: the next milestone (150 -> 225 -> 300) after everything already planned for that
     character and profession, never a duplicate; its level step is added before it when missing.
     Add a level step after: the next class milestone after the levels already planned.
  3. Notes: Edit note (and clicking a target) opens an edit bar below the rows, clear of the text. Enter or
     clicking away saves, Escape cancels. A row with a note shows "(note)"; hover it to read the note; the
     Up next card shows it too.
  4. Ignore: the ignored character's steps stay in My plan, marked "(ignored)", greyed and never "up next";
     chat says how many. Right-click such a row: Unignore. Fastest's footer says how many are ignored.
  5. The target button says what it is: "Cap 2/16", "Next reward 2/15", "Next point 2/3"; hover explains.
  6. The badge shows the realm type (PvE, PvP, RP-PvE, RP-PvP; Hardcore from the game), read from the end
     of the realm name [inferred]; hover the card for the source.
  7. The faction emblem is the game's faction icon (the one the target frame uses), not the large crest.
  8. When combat ends, an open window reads Legacy again and the combat line goes away.
  9. A dungeon challenge says "Account" in both modes; the step names the character it runs on.
     NOW is today's value in both modes; in Fastest the value at that point of the route is in the tooltip.
     Copying the route keeps the runner's level step before a dungeon challenge.

RESTART OR RELOAD?
  Update from any 0.7.x or 0.6.0: /RELOAD IS ENOUGH (changed files in the existing folder; the version label in
  the AddOns list refreshes at the next start, harmless). Saved data: unchanged format 2.

TEST (about 5 minutes)
  1. Replace the folder Interface\AddOns\EmpireIntel with the one in the zip, then /reload.
     Type /ei version: expect "version 0.7.5, saved data schema 2 (ok)".
  2. Open the window (/ei plan), Fastest:
     a. row 1 is the Up next step (the same as the card), marked; every row starts with its number;
     b. your Hunter has no profession step at all (only his level step, "Level 25 (Novice Hunter)");
     c. Leatherworking is on your Horde Rogue (69), Engineering on your Shaman (1), Blacksmithing on your Warrior,
        Enchanting on your Priest, Alchemy on your Druid; no "Learn" step anywhere;
     d. the footer has no "Not planned" text (every craft has a character), unless one is ignored.
  3. Tailoring 225 on the Priest: type  /ei plan target 20  then open Fastest again: a row
     "<Priest> ... Tailoring 150 -> 225" is there. Click the target button to go back (Cap 2/16 or Next reward).
  4. Hover a row with no point (for example a "Level 10" step in My plan before its craft step): the row and the
     tooltip say "prerequisite for step n", and step n is the craft step.
  5. /ei next: the same route in chat; a "Not planned (R-1): ..." line only if a craft has no character.
  6. Send screenshots of Fastest (as images) and any line with UNEXPECTED or any red Lua error.

ROLLBACK TO 0.7.4 (OR EARLIER 0.7.x)
  Put that folder back and /reload. Saved data is the same format (added milestone rows and removed repeats
  stay as they are).

EmpireIntel 0.7.0 - the plan window (P2-4b)

WHAT 0.7.0 ADDS (your approval D-060, D-061; Phase2_Plan.md section 9; the approved mockup)
  /ei plan          opens or closes the plan window. /ei plan help: the settings in chat (what /ei plan did before).
  The window: Fastest / My plan, the target (click it: 16 -> next reward -> next point), the Up Next card
    (the played character's portrait; an alt's race icon with its class icon; the game's faction emblem; the
    ruleset), the steps with status icons, an amber dot for unverified rules, and a tooltip with each rule
    and its source. Escape closes it. Drag the title area to move it, the lower-right grip to resize it; size
    and place are kept. Default 560 x 420.
  My plan: drag a row to reorder; click a row to edit its target (Enter saves, Escape cancels); right-click:
    Move to top, Add a level or skill step after, Edit note, Ignore in Fastest, Remove step.
  Fastest: right-click: Copy the route to my plan, Ignore.
  The minimap button (our own mark): left-click opens the window, right-click switches the mode, drag moves it
    along the edge (round or ElvUI's square minimap). /ei minimap off | on.
  The AddOn compartment has an EmpireIntel entry.
  Alts show their faction from DataStore until they log in once with 0.7.0 (read only, never saved).
  In combat the window still works; it uses the last Legacy read and says "from before combat".
  The game's own fonts; no font is shipped. No Blizzard templates, so ElvUI does not restyle the window.
  Fills: the window tests SetColorTexture once, when it is first opened; if that does not read back, it uses
    its own white texture. The chat line "window: fills: ..." says which ran (also in /ei plan help).

RESTART OR RELOAD?
  Update from 0.6.0: /RELOAD IS ENOUGH (new files and textures in the existing folder; no TOC header change).
  Saved data: unchanged format 2 (the window's size and place and the minimap button use fields format 2
  already has).

UPDATE AND TEST (the live gate, about 10 minutes; once with ElvUI on and once with ElvUI off)
  1. Replace the folder Interface\AddOns\EmpireIntel with the one in the zip, then /reload.
     Open the window three ways: /ei plan, the minimap button, the AddOn compartment entry.
     Expect the window each time; Escape closes it. Note the chat line "window: fills: ...".
  2. Fastest: the card shows the character you play with its portrait. Log in on your other character (or
     /ei plan ignore <the played one>): the card shows the other one with its race icon and class icon.
     Compare both modes with the mockup.
  3. My plan (/ei plan copy first if it is empty): drag a row to a new place, click a row and change its target,
     right-click Move to top and Remove step. /reload and open again: the changes are kept.
  4. Resize the window with the lower-right grip and move it, /reload, open again: same size and place.
  5. With ElvUI on and with ElvUI off: the window looks the same; the minimap button sits on the edge of the
     round minimap and of ElvUI's square one; drag it along the edge.
  6. Open the window in combat: no error; the footer says "Legacy values from before combat".
  7. Type /ei alts on a character whose alt has not logged in since 0.7.0: that alt's faction comes from
     DataStore and matches the game (the window's card shows "(DataStore)" next to the emblem).
  8. Send a screenshot of each mode, the saved file
       WTF\Account\<your account>\SavedVariables\EmpireIntel.lua
     and any line with UNEXPECTED or any red Lua error.

ROLLBACK TO 0.6.0
  Put the 0.6.0 folder back and /reload. Saved data stays as it is (0.6.0 reads format 2 and ignores the
  window and minimap fields).

EmpireIntel 0.6.0 - the Legacy route planner in chat (P2-4a)

WHAT 0.6.0 ADDS (your approval D-055 and D-056; Phase2_Plan.md section 8)
  /ei next     The fastest route to your Legacy target, one step per line (up to 10), for example:
                 1. C2 Priest 6: level 10, then Tailoring 56 -> 150 (train Journeyman): +1 (Journeyman Tailor), ~4.1 h
                    [estimate; unverified: L-4 L-5 L-15 L-16 L-17]
               The header says the target (16 by default), how many points are earned ([game] after the Legacy read,
               or [inferred] before the unlock or in combat) and how many rules are unverified.
               Times are play-time ESTIMATES. Each step lists the unverified rules it depends on.
               After the unlock, /ei next reads the Legacy challenges (the same read as /ei legacy, about 2 seconds).
               Before any character reaches 25 it calls no Legacy function and starts with a character to 25.
  /ei rules    The 18 rules the planner uses, each with its status (confirmed, partly, user, unverified) and source.
  /ei plan     Your plan settings and commands:
                 /ei plan mode auto | mine     auto = the fastest route; mine = your own saved steps
                 /ei plan target 16 | reward | next
                 /ei plan copy                 copy the fastest route into your own plan
                 /ei plan top <n> | remove <n> | clear
                 /ei plan ignore <name> | unignore <name>   leave a character out of the fastest route
  Rested XP counts in full (a pool of R saves R of kill XP, L-17). Explorer is planned from level 50, counting zones
  explored before (D-056). PvP is not planned before 60; raids and Valthalak are not planned yet.
  Characters on another ruleset (Hardcore) are never mixed in (L-18).
  The window (P2-4b) is NOT in this version: it waits for the UI checks (EmpireIntelCheck 0.1.9-tp1) and your
  approval of the mockup.

SAVED DATA: FORMAT 2 (approved, D-055)
  The file gains a "plan" section (mode, target, your steps, ignored characters, measured XP rates). Characters are
  stored by GUID, never by name. Each character's record also gains race, sex, faction and ruleset at its next login.
  Your existing data is kept; nothing is converted. EmpireIntel 0.5.2 opens a format-2 file read-only (it saves
  nothing), so keep the backup from step 1 below if you may roll back.
  Measured XP rate (Q-F2): after 30 minutes played in one session with a level gained, EmpireIntel saves that
  character's XP per hour and uses it in place of the default. No new game call.

RESTART OR RELOAD?
  Update from 0.5.2: /RELOAD IS ENOUGH (new files in the existing folder load on /reload, EI-E-19).

UPDATE AND TEST (about 5 minutes)
  1. Exit to the character screen or close the game, then copy
       WTF\Account\<your account>\SavedVariables\EmpireIntel.lua
     to a safe place (the backup for rollback).
  2. Replace the folder Interface\AddOns\EmpireIntel with the one in the zip. Log in (or /reload).
  3. Type  /ei version      Expect "version 0.6.0, saved data schema 2 (migrated)" the first time,
                            "(ok)" after the next /reload.
  4. Type  /ei next         On an unlocked account expect "next: reading Legacy challenges (about 2 seconds)." then
                            "next (fastest route to 16 Legacy points; N earned [game]; 18 rules, 11 unverified: /ei rules):"
                            and up to 10 numbered steps. Check N against "Legacy Points N / 65" in the Legacy window.
  5. Type  /ei rules        Expect 19 lines: a header and L-1 to L-18.
  6. Type  /ei plan copy    Expect "plan: copied the fastest route into my plan: ... steps."
     Type  /ei plan mode mine   then  /ei next     Expect "next (my plan: ...)" and your steps with estimates.
     Type  /ei plan mode auto   to go back.
  7. Optional: /ei plan ignore <a character's name>, then /ei next: the header says "(1 character ignored)".
     /ei plan unignore <name> to undo.
  8. Optional rested check (L-17, no code): on a rested character note "/ei" (XP and rested), kill one monster,
     type "/ei" again. Expected: XP up by twice the kill's normal XP, rested down by the kill's normal XP.
  9. Type  /reload  (this saves the file), then send
       WTF\Account\<your account>\SavedVariables\EmpireIntel.lua
     and the chat lines of steps 3, 4 and 6. Note any line with UNEXPECTED or any red Lua error.

ROLLBACK TO 0.5.2
  1. Close the game (or exit to the character screen).
  2. Put the 0.5.2 folder back in Interface\AddOns\EmpireIntel.
  3. Put the backup EmpireIntel.lua from step 1 back in WTF\Account\<your account>\SavedVariables\.
  4. Log in. "/ei version" says "version 0.5.2, saved data schema 1 (ok)".
  Without the backup, 0.5.2 still runs but keeps the format-2 file read-only and saves nothing new.

EmpireIntel 0.5.2 - labels after the inn test (P2-3 and P3-1 closed)

WHAT CHANGED IN 0.5.2 (text only; no new reads, nothing new saved)
  - /ei rest header now reads:
      [estimate: 5% of a level per 8 h resting (inn rate checked on Forever); a quarter outside and the 1.5-level cap unverified]
    Your inn test matched the rule (EI-E-28). The outside rate and the cap are still unchecked.
  - /ei milestones header now reads:  [class and crafting milestones confirmed by the game]
    (the game's own challenge list confirmed them, EI-E-22). The Legacy points line keeps [estimate].
  Update from 0.5.1: /RELOAD IS ENOUGH.

UPDATE AND TEST (about 2 minutes)
  1. Replace the folder Interface\AddOns\EmpireIntel with the one in the zip (the game may be running).
  2. Type  /reload  and wait about 5 seconds.
  3. Type  /ei version      Expect "version 0.5.2, saved data schema 1 (ok)".
  4. Type  /ei rest         Expect the first line to end with the new [estimate: ... inn rate checked on Forever ...] label.
                            The character lines are unchanged.
  5. Type  /ei milestones   Expect the first line "milestones [class and crafting milestones confirmed by the game]:".
                            The last line still says "About N Legacy points from these two groups [estimate]."
  6. Type  /ei legacy       Expect the same output as 0.5.1.
  7. Say whether 3-6 match. Note any line with UNEXPECTED or any red Lua error.

ROLLBACK TO 0.5.1
  Put the 0.5.1 folder back and /reload. Saved data is unchanged between 0.5.1 and 0.5.2.

WHAT CHANGED IN 0.5.1 (from your 0.5.0 test)
  - /ei legacy all is listed group by group (all Classes, then Tradeskills, ...), sub-groups together.
    0.5.0 printed the game's internal order, which mixed the groups.
  - The Explorer line no longer repeats its name ("Explorer: 0 of 46 on this character ...").
  Update from 0.5.0: /RELOAD IS ENOUGH.

WHAT 0.5.0 ADDED
  New command  /ei legacy  (read only when you type it; nothing is saved):
    Legacy: <earned> of 65 points earned; <available> available, <spent> spent. [pane loaded]
    <group counts: Classes, Tradeskills, Dungeons, Raids, Player vs. Player, Adventure>
    Closest: the challenges with several steps that are furthest along, with what is left
             Explorer X of 46 on this character (zones started, the furthest ones)
             the nearest class level and crafting skill challenge, from EmpireIntel's records
  /ei legacy all   one line per challenge: done, what is left, or not done.
  - Earned comes from the completed challenges. Available and spent come from the Legacy window's own data, so open
    the Legacy window once each session; before that the line tells you so and the challenges still show.
  - Explorer progress is the character you are logged in on (the game keeps exploration per character).
  - It only reads: the same achievement read functions the check proved, and the Legacy window's points. No talent
    tree reads. No reads in combat. Spread over a second or two.
  Everything else (/ei, /ei alts, /ei unlock, /ei rest, /ei milestones) is unchanged from 0.4.0.

RESTART OR RELOAD?
  Update from 0.5.0 or 0.4.0: /RELOAD IS ENOUGH (new files load on /reload on WoW Forever, EI-E-19).

P3-1 LIVE TEST (0.5.0 and 0.5.1, passed; kept for reference)
  1. Replace the folder Interface\AddOns\EmpireIntel with the one in the zip (the game may be running).
  2. Type  /reload  and wait about 5 seconds.
  3. Type  /ei version          Expect "version 0.5.1, saved data schema 1 (ok)".
  4. BEFORE opening the Legacy window, type  /ei legacy
     Expect "Legacy: 2 of 65 points earned; available and spent: open the Legacy window once this session."
     and the group counts and Closest lines.
  5. Open the Legacy window (any page), then type  /ei legacy  again.
     Expect "Legacy: 2 of 65 points earned; 0 available, 2 spent. [pane loaded]" (with your current numbers).
  6. Compare with the window: earned with "Legacy Points 2 / 65", available with "Available points",
     the group counts with the Challenges list, and one challenge's steps (for example Experienced Spelunker).
  7. Type  /ei legacy all  and check a few lines against the window.
  8. Optional: log in on another character and type  /ei legacy : Explorer shows that character's zones.
  9. Copy the lines (or screenshots) and say whether they match. Note any line with UNEXPECTED.
  The inn test for P2-3 (/ei rest) works the same in 0.5.0.
  Any red Lua error or "addon blocked" popup: note it (BugSack shows the text) and tell me.

ROLLBACK (older versions)
  Put the 0.5.1, 0.5.0 (or 0.4.0) folder back and /reload (addon files only; saved data stays as it is).
  To no EmpireIntel at all: delete the folder Interface\AddOns\EmpireIntel (or untick it) and /reload.
  GoldIntel, EmpireIntelCheck and DataStore are not affected either way.

WHAT CHANGED IN 0.4.0
  Three new commands, over the same characters /ei alts lists (EmpireIntel's records plus DataStore):
  - /ei unlock      Legacy unlocked or not: who reached 25, or the closest character, levels and XP to go.
  - /ei rest        Rested XP per character: what was measured, when, and an ESTIMATE of it now
                    (classic rule: 5% of a level per 8 h in an inn or city, a quarter of that outside, cap 1.5 levels;
                    inn rate checked on Forever in 0.5.2). The character you are playing shows the live value.
  - /ei milestones  For each of the 9 classes: the best character and the next level milestone (25, 45, 60).
                    For each of the 6 crafting skills: the best skill and the next milestone (150, 225, 300), with
                    "train to raise max" when the skill cap is in the way. Then an ESTIMATE of the Legacy points
                    from these two groups. Rules come from your list and are labelled (confirmed by the game in 0.5.2).
  Nothing new is saved, and no new game or DataStore function is called. /ei, /ei alts and the rest are unchanged.

WHAT 0.3.0 AND 0.3.1 ADDED (P2-2)
  - New command  /ei alts : one line per character, this character first, then newest first.
    Each line: name, class, level, realm, rested XP, resting, professions, how old the values are, and where
    they came from: [self] = EmpireIntel's own record, [datastore] = read from DataStore just now.
    When a value came from the other source, the line says so, e.g. "(professions from datastore, 3 days ago)".
  - DataStore is only read, only when you type /ei alts, and nothing from it is saved (saved data unchanged).
  - Without DataStore, /ei alts still works and lists the characters EmpireIntel has recorded itself.
  - A DataStore problem shows as a line starting with UNEXPECTED; the rest of the list still answers.
  - /ei, /ei version, /ei off, /ei on are unchanged.

