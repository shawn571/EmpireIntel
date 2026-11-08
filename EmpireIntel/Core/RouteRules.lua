local ADDON, EI = ...
-- EmpireIntel / Core / RouteRules.lua                                    (Phase 2, increment P2-4a)
--
-- PURPOSE
--   The planner's rules table (Phase2_Plan.md section 8.4, rules L-1..L-18) and the numbers the route engine uses
--   (section 8.5). Pure data: no game call, no saved data.
--
-- STATUS VALUES
--   confirmed   the client or the user showed it (Compatibility_Notes.md)
--   partly      part confirmed, part not (the text says which)
--   user        the user's own rule (a decision, not a game fact)
--   unverified  from guides or classic; labelled wherever it is used
--   A rule becomes confirmed only by a game read or a user report recorded in Compatibility_Notes.md (Q-F5, D-055).

EI = EI or {}

local RR = {}
EI.RouteRules = RR

RR.LIST = {
  { id = 'L-1', status = 'confirmed', text = 'The first character to 25 unlocks Legacy for the account; then every character has it', src = 'EI-E-02 [file]; user (D-052)' },
  { id = 'L-2', status = 'partly', text = 'Class challenges at 25, 45, 60, once per class per account (a second character of a class earns nothing: unverified)', src = 'EI-E-22 [file]; [web: warcraft.wiki.gg]' },
  { id = 'L-3', status = 'confirmed', text = 'Craft challenges at 150, 225, 300 for the six crafts; gathering and secondary skills give none', src = 'EI-E-22 [file]' },
  { id = 'L-4', status = 'unverified', text = 'Training gates: Journeyman needs level 10, Expert level 20, Artisan level 35', src = '[web: wow-professions.com, epiccarry.com]; [inherited] classic' },
  { id = 'L-5', status = 'unverified', text = 'Skill to train the next rank: the cautious value 75 / 150 / 225 is used (guides say 50 / 125 / 200 or 75 / 150 / 225)', src = '[web: epiccarry.com, wow-professions.com, rankedboost.com]' },
  { id = 'L-6', status = 'unverified', text = 'Two primary professions per character', src = '[inherited] classic; [web: method.gg]' },
  { id = 'L-7', status = 'confirmed', text = 'Dungeon challenges: Novice 6, Experienced 10, Master 17 dungeons; progress is account-wide', src = 'EI-E-23, EI-E-27 [file]' },
  { id = 'L-8', status = 'unverified', text = 'Dungeon level ranges (lowest level used: Novice 13, Experienced 20, Master 35)', src = '[inherited] classic levels' },
  { id = 'L-9', status = 'user', text = 'PvP challenges are not planned before level 60', src = 'user (D-054, D-055)' },
  { id = 'L-10', status = 'unverified', text = 'Raids and Lord Valthalak are level-60 content (not planned: no time model yet)', src = '[web: warcraft.wiki.gg]; [inherited]' },
  { id = 'L-11', status = 'user', text = 'Explorer: one character explores every zone; planned after a character reaches 50, counting zones explored before', src = 'EI-E-22 [file]; user (D-056)' },
  { id = 'L-12', status = 'unverified', text = 'Spending cap 16 points per character at launch', src = '[web: warcraft.wiki.gg, icy-veins.com, method.gg]; EI-E-04 [file]' },
  { id = 'L-13', status = 'confirmed', text = 'Reward track: 15 Air Rifle, 25 Spectral Bear Cub, 40 Spectral Bear Tabard, 55 Reins of the Spectral Bear', src = 'Legacy_Rules.md [screenshot]' },
  { id = 'L-14', status = 'confirmed', text = 'Rested XP: 5% of a level per 8 h in an inn', src = 'EI-E-28 [file]' },
  { id = 'L-15', status = 'partly', text = 'XP per level: measured bar where seen (levels 6 and 12 match classic), classic table for the rest', src = 'EI-E-14 [file]; [inherited]' },
  { id = 'L-16', status = 'unverified', text = 'Time costs: hours per level band, per skill point, per dungeon run (defaults, or the character\'s measured XP per hour)', src = '[assumed]; Q-F2 (D-055)' },
  { id = 'L-17', status = 'unverified', text = 'While rested, kills give double XP; a pool of R saves R of kill XP; quest and exploration XP get no bonus', src = '[web: warcraft.wiki.gg, wowhead.com]; [inherited]' },
  { id = 'L-18', status = 'unverified', text = 'Hardcore characters\' Legacy points are kept apart; the planner never mixes rulesets', src = '[web: warcraft.wiki.gg, warcrafttavern.com]' },
}
RR.BY_ID = {}
for _, r in ipairs(RR.LIST) do RR.BY_ID[r.id] = r end

--- Is a rule labelled where it is used (anything not confirmed and not the user's own rule)?
function RR.Unverified(id)
  local r = RR.BY_ID[id]
  return r ~= nil and r.status ~= 'confirmed' and r.status ~= 'user'
end

--- counts: total, unverified (partly + unverified)
function RR.Counts()
  local n, u = 0, 0
  for _, r in ipairs(RR.LIST) do
    n = n + 1
    if RR.Unverified(r.id) then u = u + 1 end
  end
  return n, u
end

-- L-15: XP to the next level, classic table [inherited]; the measured bar replaces it where seen (EI-E-14).
RR.XP = { 400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600, 8800, 10100, 11400, 12900, 14400, 16000, 17700,
  19400, 21300, 23200, 25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400, 50800, 54500, 58600, 62800,
  67100, 71600, 76100, 80800, 85700, 90700, 95800, 101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200,
  147500, 153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800 }

-- L-16: default XP per played hour by level band [assumed]; replaced by a character's measured rate (Q-F2).
RR.XP_PER_HOUR = { { upTo = 9, rate = 12000 }, { upTo = 19, rate = 18000 }, { upTo = 29, rate = 24000 },
  { upTo = 39, rate = 30000 }, { upTo = 49, rate = 38000 }, { upTo = 59, rate = 45000 } }

-- L-16: hours per skill point by skill band [assumed]
RR.HOURS_PER_SKILL = { { upTo = 75, h = 0.02 }, { upTo = 150, h = 0.03 }, { upTo = 225, h = 0.04 }, { upTo = 300, h = 0.06 } }

-- L-16: hours per dungeon run, including the group and travel [assumed]
RR.HOURS_PER_RUN = 0.75

-- L-4 (level to train) and L-5 (skill needed, the cautious value, Q-F5) for the rank that raises the cap to `cap`
RR.TRAIN = { [150] = { rank = 'Journeyman', level = 10, skill = 75 }, [225] = { rank = 'Expert', level = 20, skill = 150 },
  [300] = { rank = 'Artisan', level = 35, skill = 225 } }

-- L-6: primary professions (crafts plus gathering) and the slots per character
RR.GATHERING = { Herbalism = true, Mining = true, Skinning = true }
RR.PRIMARY_SLOTS = 2

-- L-7 (counts, game) and L-8 (lowest level, unverified)
RR.DUNGEONS = {
  { name = 'Novice Spelunker', count = 6, minLevel = 13 },
  { name = 'Experienced Spelunker', count = 10, minLevel = 20 },
  { name = 'Master Spelunker', count = 17, minLevel = 35 },
}

-- L-11 (D-056): Explorer is planned after a character reaches this level
RR.EXPLORER_LEVEL = 50
RR.HOURS_PER_ZONE = 1.0                                 -- [assumed]

-- L-13: the reward track
RR.REWARDS = { { at = 15, name = 'Air Rifle' }, { at = 25, name = 'Spectral Bear Cub' }, { at = 40, name = 'Spectral Bear Tabard' },
  { at = 55, name = 'Reins of the Spectral Bear' } }
RR.DEFAULT_TARGET = 16                                  -- Q-F1 (D-055); L-12
RR.MAX_STEPS = 60

--- The next reward above `earned`, or nil.
function RR.NextReward(earned)
  for _, r in ipairs(RR.REWARDS) do if r.at > (earned or 0) then return r end end
  return nil
end
