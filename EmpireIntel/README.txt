EmpireIntel 0.7.2 - the plan window, your retest build (P2-4b)

WHAT 0.7.2 ADDS TO 0.7.1 (your decision D-065)
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
  Update from 0.7.1, 0.7.0 or 0.6.0: /RELOAD IS ENOUGH (changed files in the existing folder; the version label in
  the AddOns list refreshes at the next start, harmless). Saved data: unchanged format 2.

RETEST (once, on 0.7.2: gate steps 2, 3, 6 and 8; steps 1, 4, 5 and 7 passed on 0.7.0)
  Replace the folder Interface\AddOns\EmpireIntel with the one in the zip, then /reload. Type /ei version:
  expect "version 0.7.2, saved data schema 2 (ok)". About 3 seconds after the /reload, expect the chat line
  "plan: removed 1 repeated step ..." naming your second Enchanting 150 (it is the only repeat in your plan).
  2. Fastest and My plan against the mockup, and:
     a. the card's emblem is the Horde icon (not a red shield), next to a badge reading "PvE";
     b. the target button reads "Cap 2/16"; click it: "Next reward 2/15", then "Next point 2/3"; hover it;
     c. the Experienced Spelunker row says "Account" in both modes;
     d. in Fastest, NOW shows today's values (the Priest's Enchanting row 28/75, not 150/150);
     e. in My plan, Level 20 after Level 10 shows less time than before (about 7.8 h, not 9.1 h); the times
        no longer overlap.
  3. My plan:
     a. drag (or Move to top) an Enchanting 150 row above "Level 10" of the same Priest: both move, and chat
        says "Moved with it: ... Level 10";
     b. right-click Enchanting 150 > Add a skill step after: if Enchanting 225 is already in your plan, expect
        300 (or "nothing added: Enchanting 300 is already planned"), never a second 150; a missing level step
        is added before it (chat says so);
     c. right-click a row > Edit note: the bar opens below the rows; type a note, Enter: the row shows "(note)"
        and its tooltip shows the note;
     d. the rows of the character you ignored read "(ignored)"; right-click one: it offers "Unignore";
     e. /reload and open again: all kept.
  6. Enter combat, open the window: "Legacy not read (in combat)" (or "from before combat"). Leave combat
     with the window open: within a few seconds the line goes away.
  8. Send a screenshot of each mode (pasted as images), the saved file
       WTF\Account\<your account>\SavedVariables\EmpireIntel.lua
     and any line with UNEXPECTED or any red Lua error.

ROLLBACK TO 0.7.0 OR 0.7.1
  Put that folder back and /reload. Saved data is the same format (removed repeats stay removed).

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

