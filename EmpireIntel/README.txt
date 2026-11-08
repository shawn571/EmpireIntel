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

