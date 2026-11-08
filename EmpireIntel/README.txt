EmpireIntel 0.4.0 - Phase 2 increment P2-3 (views: unlock, rest, milestones)

WHAT CHANGED IN 0.4.0
  Three new commands, over the same characters /ei alts lists (EmpireIntel's records plus DataStore):
  - /ei unlock      Legacy unlocked or not: who reached 25, or the closest character, levels and XP to go.
  - /ei rest        Rested XP per character: what was measured, when, and an ESTIMATE of it now
                    (classic rule: 5% of a level per 8 h in an inn or city, a quarter of that outside, cap 1.5 levels;
                    not yet checked on Forever). The character you are playing shows the live value.
  - /ei milestones  For each of the 9 classes: the best character and the next level milestone (25, 45, 60).
                    For each of the 6 crafting skills: the best skill and the next milestone (150, 225, 300), with
                    "train to raise max" when the skill cap is in the way. Then an ESTIMATE of the Legacy points
                    from these two groups. Rules come from your list and are labelled as not yet confirmed by the game.
  Nothing new is saved, and no new game or DataStore function is called. /ei, /ei alts and the rest are unchanged.

RESTART OR RELOAD?
  FULL CLIENT RESTART. 0.4.0 adds two files (Core/Rules.lua, Core/Views.lua); the game reads an addon's file list
  only at start. After a /reload alone the new commands answer with the help line.

INSTALL AND TEST (about 5 minutes, plus the inn test over 8 hours or more)
  1. Quit the game fully.
  2. Replace the folder Interface\AddOns\EmpireIntel with the one in the zip.
  3. Start the game and log in on any character. Wait about 5 seconds.
  4. Type  /ei version      Expect "version 0.4.0, saved data schema 1 (ok)".
  5. Type  /ei unlock       Expect "Legacy is unlocked: <your Paladin> ... reached 25".
  6. Type  /ei milestones   Check one line per class and per crafting skill against your characters
                            (levels, skills, max skills), and the "About N Legacy points ... [estimate]" line.
  7. Type  /ei rest         Check the live line for this character, and the measured values of the others.
  8. Inn test (for the rest estimate):
     a. Log in on your Priest, stand in an inn until you see the "resting" message, type /ei rest and note its line,
        then log out there.
     b. After 8 hours or more, log in on ANOTHER character and type /ei rest: note the Priest's "now about ..." line.
     c. Log in on the Priest and type /ei rest: note its live value.
     Send me the three lines; if b and c differ by less than 10%, the rule holds on Forever.
  9. Copy the lines of steps 5 to 7 (or take screenshots) and say whether they match the game.
  Any red Lua error or "addon blocked" popup: note it (BugSack shows the text) and tell me.

ROLLBACK (one step)
  Quit the game, put the 0.3.1 folder back, start the game (addon files only; saved data stays as it is).
  To no EmpireIntel at all: quit the game, then delete the folder Interface\AddOns\EmpireIntel (or untick it).
  GoldIntel, EmpireIntelCheck and DataStore are not affected either way.

WHAT 0.3.0 AND 0.3.1 ADDED (P2-2)
  - New command  /ei alts : one line per character, this character first, then newest first.
    Each line: name, class, level, realm, rested XP, resting, professions, how old the values are, and where
    they came from: [self] = EmpireIntel's own record, [datastore] = read from DataStore just now.
    When a value came from the other source, the line says so, e.g. "(professions from datastore, 3 days ago)".
  - DataStore is only read, only when you type /ei alts, and nothing from it is saved (saved data unchanged).
  - Without DataStore, /ei alts still works and lists the characters EmpireIntel has recorded itself.
  - A DataStore problem shows as a line starting with UNEXPECTED; the rest of the list still answers.
  - /ei, /ei version, /ei off, /ei on are unchanged.

