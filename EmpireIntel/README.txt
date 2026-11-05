EmpireIntel 0.2.0 - Phase 2 increment P2-1 (foundation and this character's snapshot)

WHAT IT DOES
  Records, for each character you log in with: name, realm, class, level, XP, rested XP, resting or not, and
  professions with skill. It writes this about 2 seconds after login, on level-up, when a profession skill changes,
  every 5 minutes, and at logout. Nothing else: no Legacy data, no alts from DataStore yet (that is P2-2).
  It only reads; it never changes anything in the game. It does not touch GoldIntel or EmpireIntelCheck.
  /ei off stops all recording (also on later logins); /ei on resumes.

RESTART OR RELOAD?
  FULL CLIENT RESTART REQUIRED (a new addon folder is only loaded at game start).

INSTALL AND TEST (about 5 minutes)
  1. Quit the game completely.
  2. Extract the zip into the Forever game folder's Interface\AddOns\ folder. You should then have
     Interface\AddOns\EmpireIntel\EmpireIntel.toc. Leave EmpireIntelCheck and GoldIntel where they are.
  3. Start the game. At the character screen click AddOns and make sure EmpireIntel is ticked
     (tick "Load out of date AddOns" if it is listed as out of date).
  4. Log in to character 1 and wait about 5 seconds. Type  /ei
     Expect one line like:
       EmpireIntel: First Last (PALADIN 4, <realm>): XP 86/2100, rested none reported, not resting;
       professions: none. Saved just now. 1 characters known.
     Compare with the game: level, the XP bar numbers (hover the XP bar), rested XP (the XP bar shows it when you
     have any), and your profession skill numbers (Professions / Skills window). Note any difference.
  5. Type  /ei version   Expect: "version 0.2.0, saved data schema 1 (created)" the first time.
  6. Log out to the character screen, log in to character 2, wait 5 seconds, type  /ei  and compare the same way.
     It should now say "2 characters known".
  7. Exit the game fully (this writes the file) and send
       WTF\Account\<your account>\SavedVariables\EmpireIntel.lua
     plus a note of anything /ei showed that differs from the game.
  Any red Lua error or "addon blocked" popup: note it (BugSack shows the text) and tell me.

ROLLBACK (one step)
  Quit the game, then delete the folder Interface\AddOns\EmpireIntel (or untick EmpireIntel in the AddOns list).
  Nothing else changes: GoldIntel and EmpireIntelCheck keep working. The saved file EmpireIntel.lua stays where it is
  and is ignored; it is only removed if you decide so.
