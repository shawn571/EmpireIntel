EmpireIntel 0.2.1 - Phase 2 increment P2-1 (foundation and this character's snapshot)

WHAT CHANGED IN 0.2.1
  - "Not resting" is now saved (0.2.0 lost it, so a character outside an inn had no resting value).
  - /ei says "resting unknown" when the game gives no answer, instead of "not resting".
  Update from 0.2.0: /RELOAD IS ENOUGH (Lua files only; no files added or removed).

WHAT IT DOES
  Records, for each character you log in with: name, realm, class, level, XP, rested XP, resting or not, and
  professions with skill. It writes this about 2 seconds after login, on level-up, when a profession skill changes,
  every 5 minutes, and at logout. Nothing else: no Legacy data, no alts from DataStore yet (that is P2-2).
  It only reads; it never changes anything in the game. It does not touch GoldIntel or EmpireIntelCheck.
  /ei off stops all recording (also on later logins); /ei on resumes.

RESTART OR RELOAD?
  Update from 0.2.0: /reload is enough. First-ever install: FULL CLIENT RESTART (new addon folder).

UPDATE AND TEST (about 2 minutes)
  1. Replace the folder Interface\AddOns\EmpireIntel with the one in the zip (the game may be running).
  2. Type  /reload  and wait about 5 seconds.
  3. On a character standing OUTSIDE an inn or city, type  /ei
     Expect "... rested <amount or none reported>, not resting; ..." (0.2.0 could not save "not resting").
  4. Optional: walk into an inn, wait for the "resting" message, type  /ei  again: it should say "resting"
     after the next save (about 5 minutes, or at once after a /reload).
  5. Type  /ei version   Expect "version 0.2.1, saved data schema 1 (ok)".
  6. Exit the game fully and send  WTF\Account\<your account>\SavedVariables\EmpireIntel.lua
     and say whether /ei matched the game (level, XP bar numbers, rested XP, profession skills).
  Any red Lua error or "addon blocked" popup: note it (BugSack shows the text) and tell me.

ROLLBACK (one step)
  To 0.2.0: put the 0.2.0 folder back and /reload (addon files only; your saved data stays as it is).
  To no EmpireIntel at all: quit the game, then delete the folder Interface\AddOns\EmpireIntel (or untick it).
  Nothing else changes: GoldIntel and EmpireIntelCheck keep working. The saved file EmpireIntel.lua stays where it is
  and is ignored; it is only removed if you decide so.
