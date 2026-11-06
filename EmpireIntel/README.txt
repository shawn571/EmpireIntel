EmpireIntel 0.3.1 - Phase 2 increment P2-2 (your alts, read live from DataStore)

WHAT CHANGED IN 0.3.1
  - /ei alts says "rested none reported" (as /ei does) for a character the game reported no rested XP for.
    0.3.0 said "rested unknown" there. "rested unknown" now only means DataStore gave no value.
  Update from 0.3.0: /RELOAD IS ENOUGH (Lua files only; no files added or removed).

WHAT 0.3.0 ADDED
  - New command  /ei alts : one line per character, this character first, then newest first.
    Each line: name, class, level, realm, rested XP, resting, professions, how old the values are, and where
    they came from: [self] = EmpireIntel's own record, [datastore] = read from DataStore just now.
    When a value came from the other source, the line says so, e.g. "(professions from datastore, 3 days ago)".
  - DataStore is only read, only when you type /ei alts, and nothing from it is saved (saved data unchanged).
  - Without DataStore, /ei alts still works and lists the characters EmpireIntel has recorded itself.
  - A DataStore problem shows as a line starting with UNEXPECTED; the rest of the list still answers.
  - /ei, /ei version, /ei off, /ei on are unchanged.

RESTART OR RELOAD?
  Update from 0.3.0: /reload is enough (Lua files only; no files added or removed).
  From 0.2.1 or older: FULL CLIENT RESTART (0.3.0 added two files; the game reads an addon's file list only at start).

UPDATE AND TEST FROM 0.3.0 (about 3 minutes)
  1. Make sure DataStore is ticked in AddOns (it was off for the last test).
  2. Replace the folder Interface\AddOns\EmpireIntel with the one in the zip (the game may be running).
  3. Type  /reload  and wait about 5 seconds.
  4. Type  /ei version    Expect "version 0.3.1, saved data schema 1 (ok)".
  5. Type  /ei alts       Expect a first line ending "DataStore read live, not stored." (not "not installed"),
     then one line per character, including characters EmpireIntel has never seen, marked [datastore].
     Check each line against the game and Altoholic: level, class, realm, rested XP, professions with skill.
     A character with no rested XP should say "rested none reported".
  6. Copy every /ei alts line (or take a screenshot), including any line starting with UNEXPECTED or Note:.
  7. Exit the game fully and send  WTF\Account\<your account>\SavedVariables\EmpireIntel.lua
     (it should look the same as before: P2-2 adds nothing to it) and say whether the lines matched the game.
  Any red Lua error or "addon blocked" popup: note it (BugSack shows the text) and tell me.

ROLLBACK (one step)
  To 0.3.0: put the 0.3.0 folder back and /reload. To 0.2.1: quit the game, put the 0.2.1 folder back, start the game (addon files only; saved data stays as it is).
  To no EmpireIntel at all: quit the game, then delete the folder Interface\AddOns\EmpireIntel (or untick it).
  Nothing else changes: GoldIntel, EmpireIntelCheck and DataStore keep working. The saved file EmpireIntel.lua
  stays where it is; it is only removed if you decide so.
