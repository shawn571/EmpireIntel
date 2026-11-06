EmpireIntel 0.3.0 - Phase 2 increment P2-2 (your alts, read live from DataStore)

WHAT CHANGED IN 0.3.0
  - New command  /ei alts : one line per character, this character first, then newest first.
    Each line: name, class, level, realm, rested XP, resting, professions, how old the values are, and where
    they came from: [self] = EmpireIntel's own record, [datastore] = read from DataStore just now.
    When a value came from the other source, the line says so, e.g. "(professions from datastore, 3 days ago)".
  - DataStore is only read, only when you type /ei alts, and nothing from it is saved (saved data unchanged).
  - Without DataStore, /ei alts still works and lists the characters EmpireIntel has recorded itself.
  - A DataStore problem shows as a line starting with UNEXPECTED; the rest of the list still answers.
  - /ei, /ei version, /ei off, /ei on are unchanged.

RESTART OR RELOAD?
  FULL CLIENT RESTART. This version adds two new files, and the game only reads an addon's file list at start.
  A /reload is NOT enough: /ei alts would answer with the help line.

INSTALL AND TEST (about 5 minutes)
  1. Quit the game fully.
  2. Replace the folder Interface\AddOns\EmpireIntel with the one in the zip.
  3. Start the game and log in on any character. Wait about 5 seconds.
  4. Type  /ei version    Expect "version 0.3.0, saved data schema 1 (ok)".
  5. Type  /ei alts       Expect a first line "alts: N characters (...). DataStore read live, not stored."
     then one line per character. Check each line against the game and against Altoholic if you use it:
     level, class, realm, rested XP, professions with skill. The age shows when DataStore or EmpireIntel last saw it.
  6. Note any line that starts with UNEXPECTED or Note: and copy it to me.
  7. DataStore off test: at the character screen open AddOns, untick DataStore (all DataStore_* entries go with it),
     log in, type  /ei alts   Expect "DataStore is not installed: EmpireIntel records only." and your EmpireIntel
     characters still listed. Then tick DataStore again.
  8. Exit the game fully and send  WTF\Account\<your account>\SavedVariables\EmpireIntel.lua
     (it should look the same as before: P2-2 adds nothing to it) and the /ei alts lines, or a screenshot,
     and say whether they matched the game.
  Any red Lua error or "addon blocked" popup: note it (BugSack shows the text) and tell me.

ROLLBACK (one step)
  To 0.2.1: quit the game, put the 0.2.1 folder back, start the game (addon files only; saved data stays as it is).
  To no EmpireIntel at all: quit the game, then delete the folder Interface\AddOns\EmpireIntel (or untick it).
  Nothing else changes: GoldIntel, EmpireIntelCheck and DataStore keep working. The saved file EmpireIntel.lua
  stays where it is; it is only removed if you decide so.
