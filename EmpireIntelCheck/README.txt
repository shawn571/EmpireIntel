EmpireIntelCheck 0.1.0-tp1 - EmpireIntel Test Package 1: the Legacy check

WHAT IT IS
  A throwaway, read-only, passive addon. It finds out what the WoW Forever client exposes about the
  Legacy system (points, challenges, perks, cap, trees), plus rested XP and professions, and saves it
  to SavedVariables. It is NOT EmpireIntel itself. Remove it when the test is over.

RESTART OR RELOAD?
  FULL CLIENT RESTART REQUIRED for the first install (a new addon folder is only loaded at game start).
  Later updates of this package that only change .lua files: /reload is enough (the notes will say so).

WHAT IT DOES TO YOUR GAME
  Nothing you need to do: it runs by itself 10 seconds after you enter the world, pauses in combat,
  spreads its work over many frames, and prints at most two chat lines per check.
  It never buys, spends, learns, resets or sets anything: it only calls functions whose names start with
  Get, Is or Has, with no arguments, and skips any name containing Set, Spend, Learn, Reset, Buy or Purchase.
  It does not touch GoldIntel or its data. It keeps its saved data under about 256 KB.
  Off switch: /eicheck off  (stays off on later logins; /eicheck on to re-enable)

TEST STEPS (launch build, about 10 minutes of normal play)
  1. Quit the game completely.
  2. Extract EmpireIntelCheck_AddOns.zip into the Forever game folder's Interface\AddOns\ folder
     (the same folder GoldIntel is in). You should then have Interface\AddOns\EmpireIntelCheck\EmpireIntelCheck.toc.
     Leave DataStore and Altoholic installed and enabled if you use them. GoldIntel can stay installed.
  3. Start the game. At the character screen, click AddOns and make sure EmpireIntelCheck is ticked.
     If it is listed as out of date, tick "Load out of date AddOns" (the launch build may have a new
     interface number).
  4. Log in to character 1. About 10 seconds after you are in the world, expect ONE chat line like:
       EmpireIntelCheck 0.1.0-tp1: LEGACY API: <verdict> ... Run 1 (login) ...
     A second line starting "UNEXPECTED" is possible: note it and keep playing. Note any red Lua
     error or any "addon blocked" popup (screenshot if you can) and keep playing.
  5. Open the Legacy pane once, the normal way the game opens it. Leave it open for about 5 seconds, then close it.
     If no new chat line appears within about 10 seconds, type  /eicheck pane  once (with the pane open
     if possible). This tells the check the pane was opened.
  6. Play normally for a few minutes. A level-up or a profession skill-up helps but is not required.
  7. Optional: open your bank once.
  8. Optional: only if the line in step 4 ended with "docs available: /eicheck docs", type  /eicheck docs
     and wait about 10 seconds for a new line.
  9. Log out to the character screen, log in to character 2 (ideally a different class), repeat steps 4 and 5.
 10. Exit the game completely (Exit Game, not just the character screen), so the data is written.
 11. Send me:
       WTF\Account\<your account>\SavedVariables\EmpireIntelCheck.lua
     plus a screenshot of the Legacy pane with points, challenges and perks visible (the ground truth).

VERDICTS
  FOUND            a Legacy getter returned data
  NAMES ONLY       Legacy-looking names exist, but no getter returned data
  PANE ONLY        a Legacy frame exists, but no data API was found
  NOTHING EXPOSED  nothing found. "(provisional: ...)" means the pane was not seen yet or no Legacy
                   point is expected yet; the check reruns by itself after those events.

COMMANDS (all optional)
  /eicheck        status       /eicheck off | on     /eicheck run    one more check now
  /eicheck pane   say "the Legacy pane is open"      /eicheck docs   save Blizzard's API docs, if present
