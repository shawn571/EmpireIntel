EmpireIntelCheck 0.1.6-tp1 - EmpireIntel Test Package 1: the Legacy check

WHAT IT IS
  A throwaway, read-only, passive addon. It finds out what the WoW Forever client exposes about the
  Legacy system (points, challenges, perks, cap, trees), plus rested XP and professions, and saves it
  to SavedVariables. It is NOT EmpireIntel itself. Remove it when the test is over.

RESTART OR RELOAD?
  FULL CLIENT RESTART. 0.1.6 adds a new file (Legacy.lua); the game reads an addon's file list only at start.
  After a /reload alone the new reading would not run.

WHAT CHANGED IN 0.1.6 (your Q-T7 approval)
  - Once Legacy is unlocked, each check also reads the Legacy values the game shows:
      * the challenges, from the Legacy achievement category: name, completed or not, and each step
        (for example each dungeon of a Spelunker challenge) with its progress;
      * the Legacy points, from the currency the pane uses (amount and cap).
  - Calls with an argument go only to the game's achievement and currency getters (GetCategoryList, GetCategoryInfo,
    GetCategoryNumAchievements, GetAchievementInfo, GetAchievementNumCriteria, GetAchievementCriteriaInfo,
    C_CurrencyInfo.GetCurrencyInfo, GetCurrencyListSize, GetCurrencyListInfo), and only with numbers the game itself
    returned. Any other name or number is refused before the call. The blocked words still apply to every call.
  - Crash guard as before: each name is written to saved data during its call and cleared after.
  - Saves what the Legacy pane's own LegacySystem functions return when called with no argument (0.1.4 saved only
    "it answered"), and its constants (read, not called).
  - Fixed: the size limit could erase the values of the Legacy calls in a run (your level-25 file lost them).
  - Character names the game returns with achievements are not saved.
  - New command  /eicheck legacy : read again now (for example after opening the Legacy pane).

INSTALL AND TEST (about 5 minutes)
  1. Quit the game fully.
  2. Replace the folder Interface\AddOns\EmpireIntelCheck with the one in the zip.
  3. Start the game and log in on your level-25 character. Wait about 15 seconds.
     Expect two chat lines from EmpireIntelCheck 0.1.6-tp1. The second starts with "Legacy read:", e.g.
     "Legacy read: 65 challenges (1 completed) in N categories; Legacy Points 1/16".
     It may add "LegacySystem not loaded": that is fine for now.
  4. Open the Legacy window (the pane) and look at the Challenges and Progress Track pages for a moment.
  5. Type  /eicheck legacy   Expect "Legacy read: ..." again, now without "LegacySystem not loaded".
  6. Compare with the game: is the points number the same as the pane? Is the number of challenges and completed
     challenges plausible? Note any line starting with UNEXPECTED.
  7. Exit the game fully and send  WTF\Account\<your account>\SavedVariables\EmpireIntelCheck.lua
     and the two chat lines (or a screenshot).
  Any red Lua error or "addon blocked" popup: note it (BugSack shows the text) and tell me.

ROLLBACK (one step)
  Quit the game, put the 0.1.5 (or 0.1.4) folder back, start the game (addon files only; saved data stays as it is).
  To remove the check: quit the game, delete the folder Interface\AddOns\EmpireIntelCheck (or untick it).
  EmpireIntel, GoldIntel and DataStore are not affected either way.

WHAT CHANGED IN 0.1.5 (your Q-T5 rule)
  - Blocked words are matched as whole words: SetSeason, IsSeasonOpen, ShowFrame stay blocked; IsShown, GetClaimable,
    IsPerkLearned, GetBuyout, GetUnset are no longer blocked. Anything starting with "Reincarnat" is blocked.
  - /eicheck undoc typed too early now says "try again in about 10 seconds".
  - Nothing new to do: install it before the level-25 run.

WHAT CHANGED IN 0.1.4 (your Q-T3 limits)
  - Lists the 20 game API groups that are missing from Blizzard's documentation. Nothing in them is called on its own.
  - /eicheck undoc calls, once, only C_Seasons and C_Trophy functions whose names start with Get, Is or Has, with no
    arguments. Never anything containing Set, Spend, Learn, Reset, Buy, Purchase, Request, Claim, Open, Toggle, Show
    or Reincarnate (this list now applies to every call the check makes).
  - C_Reincarnation is listed for your review and never called. Service, store and debug groups are listed, never called.
  - Crash guard: each name is written to saved data before its call and cleared after. If it is still there at the
    next login, that name is never called again. A hard client crash writes nothing, so if the game crashes after
    /eicheck undoc, do not type it again; just tell me.
  - Retail settings with an option named "Legacy" no longer count in the API docs either.

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

TEST STEPS
  NOW (1 minute; nothing to send)
  1. Replace the EmpireIntelCheck folder in the Forever game folder's Interface\AddOns\ with the one in the zip.
  2. Type  /reload. About 10 seconds later the usual "LEGACY API: PANE ONLY (provisional: ...)" line appears. Done.

  LATER, when any character first reaches level 25
  3. Log in with that character. Open the Legacy pane the normal way and keep it open about 5 seconds. A new check
     line should appear within about 10 seconds; if not, type  /eicheck pane  with the pane open.
  4. Exit the game fully and send  WTF\Account\<your account>\SavedVariables\EmpireIntelCheck.lua  plus a screenshot
     of the pane showing points, challenges and perks.
  If the game crashes or disconnects at any point: tell me before typing any /eicheck command.

VERDICTS
  FOUND            a Legacy getter returned data
  NAMES ONLY       Legacy-looking names exist, but no getter returned data
  PANE ONLY        a Legacy frame exists, but no data API was found
  NOTHING EXPOSED  nothing found. "(provisional: ...)" means the pane was not seen yet or no Legacy
                   point is expected yet; the check reruns by itself after those events.

COMMANDS (all optional)
  /eicheck        status       /eicheck off | on     /eicheck run    one more check now
  /eicheck pane   say "the Legacy pane is open"      /eicheck docs   save Blizzard's API docs, if present
  /eicheck undoc  call the planned C_Seasons / C_Trophy getters once
