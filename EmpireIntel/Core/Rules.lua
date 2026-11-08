local ADDON, EI = ...
-- EmpireIntel / Core / Rules.lua                                         (Phase 2, increment P2-3)
--
-- PURPOSE
--   The one rules table the views use, each rule with its source (Phase2_Plan.md section 6, approved Q-P2-3).
--   Pure data and arithmetic: no game call, no saved data.
--
-- SOURCES
--   'game'   confirmed by the client (EI-E-02: the Legacy system unlocks when the first character reaches 25)
--   'user'   the user's challenge list (Legacy_Rules.md section 1); the class and crafting milestones are
--            confirmed by the game (EI-E-22, D-043)
--   'classic' the classic rest rule (Q-P2-3b): the inn rate is checked on Forever (EI-E-28, D-041); the quarter
--            rate outside a rest area and the 1.5-level cap are unverified
-- Ported from EmpireIntelCheck/Character.lua (Ch.RULES), our own code.

EI = EI or {}

local R = {}
EI.Rules = R

R.UNLOCK_LEVEL = 25                                    -- game
R.MAX_LEVEL = 60
R.CLASSES = { 'WARRIOR', 'PALADIN', 'HUNTER', 'ROGUE', 'PRIEST', 'SHAMAN', 'MAGE', 'WARLOCK', 'DRUID' }   -- user: 9 classes
R.CLASS_NAMES = { WARRIOR = 'Warrior', PALADIN = 'Paladin', HUNTER = 'Hunter', ROGUE = 'Rogue', PRIEST = 'Priest',
  SHAMAN = 'Shaman', MAGE = 'Mage', WARLOCK = 'Warlock', DRUID = 'Druid' }
R.CLASS_MILESTONES = { 25, 45, 60 }                    -- user
R.CRAFTS = {                                           -- user (Q-P2-3a): the six crafting skills, by skill line id
  { name = 'Alchemy', line = 171 }, { name = 'Blacksmithing', line = 164 }, { name = 'Enchanting', line = 333 },
  { name = 'Engineering', line = 202 }, { name = 'Leatherworking', line = 165 }, { name = 'Tailoring', line = 197 },
}
R.CRAFT_MILESTONES = { 150, 225, 300 }                 -- user
R.REST = { per8h = 0.05, outsideFactor = 0.25, cap = 1.5, period = 8 * 3600 }   -- classic; inn rate checked (EI-E-28), outside rate and cap unverified

R.LABEL_RULES = '[class and crafting milestones confirmed by the game]'
R.LABEL_REST = '[estimate: 5% of a level per 8 h resting (inn rate checked on Forever); a quarter outside and the 1.5-level cap unverified]'

--- The next milestone above value, and how many are reached. next is nil when all are reached.
function R.Next(milestones, value)
  local reached, nextM = 0, nil
  for _, m in ipairs(milestones) do
    if type(value) == 'number' and value >= m then reached = reached + 1 elseif not nextM then nextM = m end
  end
  return nextM, reached
end

--- The crafting skill a profession entry is, or nil (by skill line id, else by name).
function R.Craft(prof)
  if type(prof) ~= 'table' then return nil end
  for _, c in ipairs(R.CRAFTS) do
    if prof.line ~= nil and prof.line == c.line then return c.name end
  end
  if type(prof.name) == 'string' then
    local n = string.lower(prof.name)
    for _, c in ipairs(R.CRAFTS) do
      if n == string.lower(c.name) then return c.name end
    end
  end
  return nil
end

--- Projected rested XP now. rest: measured (nil = none, counts as 0 when noneIsZero); xpMax: the level's bar;
-- resting: true, false or nil (nil uses the outside rate); since, now: seconds.
-- Returns projected, capped (bool), or nil plus a reason.
function R.ProjectRest(rest, xpMax, resting, since, now, noneIsZero)
  if type(xpMax) ~= 'number' or xpMax <= 0 then return nil, 'no bar' end
  if rest == nil and noneIsZero then rest = 0 end
  if type(rest) ~= 'number' then return nil, 'no reading' end
  if type(since) ~= 'number' or type(now) ~= 'number' then return nil, 'no time' end
  local elapsed = now - since
  if elapsed < 0 then elapsed = 0 end                  -- a clock that went backwards never removes rest
  local rate = R.REST.per8h * xpMax / R.REST.period
  if resting ~= true then rate = rate * R.REST.outsideFactor end
  local cap = R.REST.cap * xpMax
  local p = rest + rate * elapsed
  if p >= cap then return math.floor(cap), true end
  return math.floor(p), false
end
