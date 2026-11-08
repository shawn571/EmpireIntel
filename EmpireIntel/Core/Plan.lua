local ADDON, EI = ...
-- EmpireIntel / Core / Plan.lua                                          (Phase 2, increment P2-4)
--
-- PURPOSE
--   Reads and checks the user's plan file, EmpireIntel_Plan/Plan.lua, format 1 (Phase2_Plan.md section 7.3,
--   approved Q-P2-4, D-052). Pure: the two globals come in through P.PlanGlobals(); no game call, nothing saved.
--
-- RULES
--   * Each bad goal is reported as one UNEXPECTED line naming its number, and skipped; never guessed (R-17).
--   * Goal kinds: level, skill, rested, account challenges. A goal with 'perk' is "not supported yet (needs Q-T4)".
--   * Characters are matched by name (case-insensitive), or 'Name-Realm' when two share a name.

EI = EI or {}
local P = EI.Platform
assert(P and EI.Rules, 'load order: Platform, Rules, Plan')

local Plan = {}
EI.Plan = Plan

Plan.FORMAT = 1

-- profession names a skill goal may use (the six crafts, the gathering skills and the secondary skills)
Plan.PROFESSIONS = { 'Alchemy', 'Blacksmithing', 'Enchanting', 'Engineering', 'Leatherworking', 'Tailoring',
  'Herbalism', 'Mining', 'Skinning', 'Cooking', 'First Aid', 'Fishing' }

local KEYS = { char = 'string', level = 'number', profession = 'string', skill = 'number', rested = 'number',
  account = 'boolean', challenges = 'number', note = 'string', perk = 'any' }

local function isInt(v) return type(v) == 'number' and v == math.floor(v) end

local function canonicalProfession(name)
  local n = string.lower(name)
  for _, p in ipairs(Plan.PROFESSIONS) do if string.lower(p) == n then return p end end
  return nil
end

--- Finds the row for a plan's char value. Returns row, or nil plus a reason.
function Plan.MatchChar(rows, char)
  local name, realm = string.match(char, '^(.-)%-(.+)$')
  if not name or name == '' then name, realm = char, nil end
  local hits = {}
  for _, r in ipairs(rows) do
    if type(r.name) == 'string' and string.lower(r.name) == string.lower(name)
      and (realm == nil or (type(r.realm) == 'string' and string.lower(r.realm) == string.lower(realm))) then
      hits[#hits + 1] = r
    end
  end
  if #hits == 0 then return nil, 'no character named "' .. char .. '"' end
  if #hits > 1 then return nil, 'two characters are named "' .. char .. '"; write it as Name-Realm' end
  return hits[1]
end

-- one goal: returns a checked goal, or nil plus the reason it is skipped
local function check(g, rows)
  if type(g) ~= 'table' then return nil, 'not a table' end
  for k, v in pairs(g) do
    local want = KEYS[k]
    if not want then return nil, 'unknown key "' .. tostring(k) .. '"' end
    if want ~= 'any' and type(v) ~= want then return nil, '"' .. k .. '" must be a ' .. want end
  end
  if g.perk ~= nil then return nil, 'perk goals are not supported yet (needs Q-T4)' end
  local kinds = {}
  if g.level ~= nil and g.skill == nil then kinds[#kinds + 1] = 'level' end
  if g.profession ~= nil or g.skill ~= nil then kinds[#kinds + 1] = 'skill' end
  if g.rested ~= nil then kinds[#kinds + 1] = 'rested' end
  if g.challenges ~= nil or g.account ~= nil then kinds[#kinds + 1] = 'challenges' end
  if #kinds == 0 then return nil, 'no goal (level, profession and skill, rested, or account and challenges)' end
  if #kinds > 1 or (g.level ~= nil and g.skill ~= nil) then return nil, 'more than one goal in one entry' end
  local kind = kinds[1]
  local out = { kind = kind, note = g.note }
  if kind == 'challenges' then
    if g.account ~= true then return nil, 'a challenges goal needs account = true' end
    if g.char ~= nil then return nil, 'a challenges goal is for the account, not a character' end
    if not isInt(g.challenges) or g.challenges < 1 or g.challenges > 65 then return nil, '"challenges" must be 1 to 65' end
    out.challenges = g.challenges
    return out
  end
  if g.char == nil then return nil, 'no "char"' end
  if kind == 'level' then
    if not isInt(g.level) or g.level < 2 or g.level > EI.Rules.MAX_LEVEL then return nil, '"level" must be 2 to 60' end
    out.level = g.level
  elseif kind == 'skill' then
    if g.profession == nil or g.skill == nil then return nil, 'a skill goal needs both "profession" and "skill"' end
    local prof = canonicalProfession(g.profession)
    if not prof then return nil, 'unknown profession "' .. g.profession .. '"' end
    if not isInt(g.skill) or g.skill < 1 or g.skill > 300 then return nil, '"skill" must be 1 to 300' end
    out.profession, out.skill = prof, g.skill
  else
    if g.rested < 0.05 or g.rested > EI.Rules.REST.cap then return nil, '"rested" must be 0.05 to 1.5 levels' end
    out.rested = g.rested
  end
  local row, why = Plan.MatchChar(rows, g.char)
  if not row then return nil, why end
  out.row = row
  return out
end

--- Loads the plan. Returns a table:
--   state = 'none' (folder not installed) | 'broken' (folder present, Plan.lua did not load) | 'bad' (wrong version
--           or no goals table) | 'ok'
--   goals (checked goals, in order), total, skipped, problems (UNEXPECTED lines, in order)
function Plan.Load(rows)
  local plan, marker = P.PlanGlobals()
  local res = { goals = {}, problems = {}, total = 0, skipped = 0 }
  if plan == nil then
    res.state = marker ~= nil and 'broken' or 'none'
    if marker ~= nil then
      res.problems[1] = 'UNEXPECTED plan file did not load (a Lua error in Plan.lua; BugSack shows the line). Showing default suggestions.'
    end
    return res
  end
  if type(plan) ~= 'table' or plan.version ~= Plan.FORMAT or type(plan.goals) ~= 'table' then
    res.state = 'bad'
    local v = type(plan) == 'table' and plan.version or nil
    if type(plan) == 'table' and v ~= Plan.FORMAT then
      res.problems[1] = 'UNEXPECTED plan file: version ' .. tostring(v) .. ', this EmpireIntel reads version 1. Showing default suggestions.'
    else
      res.problems[1] = 'UNEXPECTED plan file: no goals table. Showing default suggestions.'
    end
    return res
  end
  res.state = 'ok'
  for i, g in ipairs(plan.goals) do
    res.total = res.total + 1
    local ok, why = check(g, rows)
    if ok then
      ok.n = i
      res.goals[#res.goals + 1] = ok
    else
      res.skipped = res.skipped + 1
      res.problems[#res.problems + 1] = 'UNEXPECTED plan goal ' .. i .. ': ' .. why .. ' (skipped)'
    end
  end
  return res
end
