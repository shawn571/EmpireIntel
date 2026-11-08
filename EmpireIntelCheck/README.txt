EmpireIntelCheck 0.1.8-tp1 - EmpireIntel Test Package 1: the Legacy check

WHAT IT IS
  A throwaway, read-only, passive addon. It finds out what the WoW Forever client exposes about the
  Legacy system (points, challenges, perks, cap, trees), plus rested XP and professions, and saves it
  to SavedVariables. It is NOT EmpireIntel itself. Remove it when the test is over.

RESTART OR RELOAD?
  Update from 0.1.7: /RELOAD IS ENOUGH (files changed only).

WHAT CHANGED IN 0.1.8 (your Q-T9 approval with your Explorer correction; fixes from your 0.1.7 file)
  - Counts only the 65 Legacy challenges (the achievements whose reward says "Earn 1 Legacy Point."), each worth the
    points its reward names. 0.1.7 counted all 111 achievements and used the wrong points field.
  - The 46 exploration achievements are saved as the steps of the Explorer challenge, found through the game's own
    chain (Explorer -> Explore Azeroth -> Explore Eastern Kingdoms / Explore Kalimdor -> the zones), each done or not.
    They are not counted as points. The line shows "Explorer X of 46 done".
  - Each step of a challenge (dungeon, raid boss, zone area) is saved as its name, done or not, and its progress
    when it has a count.
  - Old test leftovers in the saved file (the discovery lists and the API docs) are dropped before any Legacy data,
    so the challenge steps are no longer lost to the size limit.
  - Same limits as before: only achievement and currency read functions, only numbers the game returned, blocked
    words and crash guard as before. No talent-tree (trait) calls.

UPDATE AND TEST (about 3 minutes)
  1. Replace the folder Interface\AddOns\EmpireIntelCheck with the one in the zip (the game may be running).
  2. Type  /reload  and wait about 15 seconds.
  3. Open the Legacy window (the pane) for a moment.
  4. Type  /eicheck legacy   Expect something like:
     "Legacy read: 65 challenges (1 completed, 1 of 65 Legacy points); Explorer 0 of 46 done; in 27 categories;
      Legacy points: maxQuantity 1, quantity 1, renownCurrency 1, spent 0, spentInTree 0"
     (Explorer may already show some zones done: the number counts zones the game marks as explored.)
  5. Compare with the pane: "1 of 65" should match "Legacy Points 1 / 65". Note any line with UNEXPECTED.
  6. Type  /reload  (this saves the file), or exit the game.
  7. Send  WTF\Account\<your account>\SavedVariables\EmpireIntelCheck.lua  and the "Legacy read:" line.
  Any red Lua error or "addon blocked" popup: note it (BugSack shows the text) and tell me.

ROLLBACK (one step)
  Put the 0.1.7 folder back and /reload (addon files only; saved data stays as it is).
  To remove the check: delete the folder Interface\AddOns\EmpireIntelCheck (or untick it) and /reload.
  EmpireIntel, GoldIntel and DataStore are not affected either way.

WHAT CHANGED IN 0.1.7 (your Q-T8 approval; fixes from your 0.1.6 file)
  - Reads every challenge category the game lists. On Forever these ARE the Legacy categories (Classes, Tradeskills,
    Player vs. Player, Adventure, Dungeons, Raids and their sub-groups); 0.1.6 wrongly looked for "Legacy" in a title.
  - "Tier 1 Gear" and "Do Not Display" (not shown in the pane) are read and saved but kept out of the totals.
  - Each challenge is saved with its steps (each dungeon, each raid boss) and whether each is done.
  - Legacy points come from the pane's own LegacySystem.GetCurrencyInfo(), all its fields saved as they are.
    The trait-currency number (4225) is no longer sent to the ordinary currency functions.
  - The same limits as 0.1.6: only achievement and currency read functions, only numbers the game returned,
    blocked words and crash guard as before. No talent-tree (trait) calls.

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
