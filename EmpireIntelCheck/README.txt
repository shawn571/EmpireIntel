EmpireIntelCheck 0.1.3-tp1 - EmpireIntel Test Package 1: the Legacy check

WHAT IT IS
  A throwaway, read-only, passive addon. It finds out what the WoW Forever client exposes about the
  Legacy system (points, challenges, perks, cap, trees), plus rested XP and professions, and saves it
  to SavedVariables. It is NOT EmpireIntel itself. Remove it when the test is over.

RESTART OR RELOAD?
  Update from 0.1.0, 0.1.1 or 0.1.2: /RELOAD IS ENOUGH (no files added or removed; the TOC changes only its Version line).
  The AddOns list keeps showing the old version until your next full restart; that is only the label.
  First-ever install (no EmpireIntelCheck folder yet): FULL CLIENT RESTART.

WHAT CHANGED IN 0.1.3
  - The saved API docs could be thrown away by the size limit (your last file). Now they are kept: Legacy systems
    first and in detail, other matches as names only, anything left out listed by name. They are trimmed last.

WHAT CHANGED IN 0.1.2
  - Retail settings that merely have an option called "Legacy" (nameplate style, respec type, ...) no longer count.

WHAT CHANGED IN 0.1.1 (fixes from your launch-build run)
  - Only names that point at the Forever Legacy system count; retail "legacy raid" and guild challenge names no longer do.
  - The Legacy lock is read and shown: while no character has reached level 25 the verdict says "locked".
  - The Legacy pane counts as opened only when a Legacy frame actually becomes visible. No script hooks any more.
  - Rested XP at logout falls back to the last in-world reading (the client gave wrong values at logout).
  - Saved data uses less space: the full discovery is kept once. Your old data is converted automatically.
  - If BugSack/BugGrabber is installed, the check reads its error list (read-only) and records which addons raised
    errors, so you do not need to copy errors by hand.

WHAT IT DOES TO YOUR GAME
  Nothing you need to do: it runs by itself 10 seconds after you enter the world, pauses in combat,
  spreads its work over many frames, and prints at most two chat lines per check.
  It never buys, spends, learns, resets or sets anything: it only calls functions whose names start with
  Get, Is or Has, with no arguments, and skips any name containing Set, Spend, Learn, Reset, Buy or Purchase.
  It does not touch GoldIntel or its data. It keeps its saved data under about 256 KB.
  Off switch: /eicheck off  (stays off on later logins; /eicheck on to re-enable)

TEST STEPS (about 2 minutes now, plus one short session after a character reaches level 25)
  NOW
  1. Extract EmpireIntelCheck_AddOns.zip into the Forever game folder's Interface\AddOns\ and let it REPLACE the
     existing EmpireIntelCheck folder (overwrite all files). The game may be running.
  2. In game, type  /reload
     About 10 seconds later expect one line like:
       EmpireIntelCheck 0.1.3-tp1: LEGACY API: PANE ONLY (provisional: Legacy system locked ...). Run 9 (login); docs available: /eicheck docs ...
     A second line starting "UNEXPECTED" is possible: note it and carry on.
  3. IMPORTANT, this is the step that can find the Legacy data before level 25 (run it again after updating):
     type  /eicheck docs  once. Expect "docs: loading ...", then within a few seconds "docs: saved ...", and a new
     verdict line about 10 seconds later ending "docs saved".
  4. Type  /reload  once more (writes the file and frees the memory the docs used).
  5. Exit the game fully and send me
       WTF\Account\<your account>\SavedVariables\EmpireIntelCheck.lua
  LATER, when any character first reaches level 25
  6. Log in with the check installed. Open the Legacy pane the normal way (it should now be unlocked) and keep it open
     about 5 seconds. A new line should appear within about 10 seconds; if not, type  /eicheck pane  with the pane open.
  7. Exit the game fully and send the same file again, plus a screenshot of the pane showing points and perks.

VERDICTS
  FOUND            a Legacy getter returned data
  NAMES ONLY       Legacy-looking names exist, but no getter returned data
  PANE ONLY        a Legacy frame exists, but no data API was found
  NOTHING EXPOSED  nothing found. "(provisional: ...)" means the pane was not seen yet or no Legacy
                   point is expected yet; the check reruns by itself after those events.

COMMANDS (all optional)
  /eicheck        status       /eicheck off | on     /eicheck run    one more check now
  /eicheck pane   say "the Legacy pane is open"      /eicheck docs   save Blizzard's API docs, if present
