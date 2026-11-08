local ADDON, EI = ...
-- EmpireIntel / Core / Plan.lua                                          (Phase 2, increment P2-4a)
--
-- PURPOSE
--   The saved plan, EmpireIntelDB.plan (saved-data format 2, Phase2_Plan.md 8.7, approved D-055):
--     mode ('auto' | 'mine'), target (16 | 'reward' | 'next'), mine (the edited steps, in order), ignore (GUIDs left
--     out of auto mode, Q-F4), rates (measured XP per hour per GUID, Q-F2), window and minimap (P2-4b: the window's
--     size and position, the minimap button's angle and hidden flag).
--   Also: the step checks reused from #11 (kinds, ranges, character matching), and the XP-rate measurement.
--
-- RULES
--   * Characters are stored by GUID, never by name (8.7).
--   * A bad saved step is reported as one UNEXPECTED line naming its number, and skipped; never guessed (R-17).
--   * Nothing is written when the store is not writable (readonly or degraded); the caller says so.
--   * Rates (Q-F2): no new game call. The snapshot's own readings (level, XP, time) are compared within one login
--     session; after at least Plan.RATE_MIN_SECONDS and one level gained, the session's XP per logged-in hour is
--     saved (averaged with the earlier value). Logged-in time includes idle time, so the rate is cautious.

EI = EI or {}
local P = EI.Platform
local R = EI.Rules
local RR = EI.RouteRules
assert(P and R and RR and EI.Store, 'load order: Platform, Store, Rules, RouteRules, Plan')

local Plan = {}
EI.Plan = Plan

Plan.MODES = { auto = true, mine = true }
Plan.MAX_MINE = 100
Plan.RATE_MIN_SECONDS = 1800

-- profession names a skill step may use (the six crafts, the gathering skills and the secondary skills) (#11)
Plan.PROFESSIONS = { 'Alchemy', 'Blacksmithing', 'Enchanting', 'Engineering', 'Leatherworking', 'Tailoring',
  'Herbalism', 'Mining', 'Skinning', 'Cooking', 'First Aid', 'Fishing' }

local function isInt(v) return type(v) == 'number' and v == math.floor(v) end

function Plan.CanonicalProfession(name)
  if type(name) ~= 'string' then return nil end
  local n = string.lower(name)
  for _, p in ipairs(Plan.PROFESSIONS) do if string.lower(p) == n then return p end end
  return nil
end

---------------------------------------------------------------------------
-- the section
---------------------------------------------------------------------------

function Plan.Section() return EI.Store.Section('plan') end

function Plan.Mode()
  local m = Plan.Section().mode
  if Plan.MODES[m] then return m end
  return 'auto'
end

function Plan.Target()
  local t = Plan.Section().target
  if t == 'reward' or t == 'next' then return t end
  if isInt(t) and t >= 1 and t <= 65 then return t end
  return RR.DEFAULT_TARGET
end

local function sub(name)
  local s = Plan.Section()
  if type(s[name]) ~= 'table' then s[name] = {} end
  return s[name]
end
function Plan.Ignore() return sub('ignore') end
function Plan.Rates() return sub('rates') end
function Plan.Mine() return sub('mine') end

local function writable()
  if EI.Store.IsWritable() then return true end
  return nil, 'not saved: the saved data is read-only this session (/ei version)'
end

function Plan.SetMode(m)
  if not Plan.MODES[m] then return nil, 'mode must be auto or mine' end
  local ok, why = writable(); if not ok then return nil, why end
  Plan.Section().mode = m
  return true
end

function Plan.SetTarget(t)
  if t ~= 'reward' and t ~= 'next' then
    t = tonumber(t)
    if not isInt(t) or t < 1 or t > 65 then return nil, 'target must be a number 1 to 65, reward or next' end
  end
  local ok, why = writable(); if not ok then return nil, why end
  Plan.Section().target = t
  return true
end

function Plan.SetIgnored(guid, on)
  local ok, why = writable(); if not ok then return nil, why end
  Plan.Ignore()[guid] = on and true or nil
  return true
end

function Plan.SetMine(list)
  local ok, why = writable(); if not ok then return nil, why end
  Plan.Section().mine = list
  return true
end

--- The saved window geometry { point, x, y, w, h } or nil (format 2, plan.window).
function Plan.Window()
  local w = Plan.Section().window
  return type(w) == 'table' and w or nil
end

function Plan.SetWindow(g)
  local ok, why = writable(); if not ok then return nil, why end
  Plan.Section().window = { point = g.point, x = g.x, y = g.y, w = g.w, h = g.h }
  return true
end

--- The minimap button state { hide, angle } (format 2, plan.minimap); always a table.
function Plan.MinimapState()
  local m = Plan.Section().minimap
  if type(m) ~= 'table' then return {} end
  return m
end

function Plan.SetMinimap(m)
  local ok, why = writable(); if not ok then return nil, why end
  Plan.Section().minimap = { hide = m.hide and true or false, angle = tonumber(m.angle) }
  return true
end

---------------------------------------------------------------------------
-- characters (#11, Plan.MatchChar), by name; the plan stores the GUID
---------------------------------------------------------------------------

--- Finds the row for a name or 'Name-Realm' (case-insensitive). Returns row, or nil plus a reason.
function Plan.MatchChar(rows, char)
  if type(char) ~= 'string' or char == '' then return nil, 'no character name' end
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
  if not hits[1].guid then return nil, '"' .. char .. '" has no GUID (DataStore only), so it cannot be saved' end
  return hits[1]
end

---------------------------------------------------------------------------
-- step checks (reused from #11's goal checks; kinds of format 2)
---------------------------------------------------------------------------

local KEYS = {
  level = { kind = 1, guid = 1, level = 1, note = 1 },
  skill = { kind = 1, guid = 1, profession = 1, skill = 1, note = 1 },
  challenge = { kind = 1, id = 1, note = 1 },
  rested = { kind = 1, guid = 1, rested = 1, note = 1 },
}

--- Checks one saved step. Returns a checked copy (with .row for a character step), or nil plus the reason.
function Plan.Check(e, byGuid)
  if type(e) ~= 'table' then return nil, 'not a table' end
  local keys = KEYS[e.kind]
  if not keys then return nil, 'unknown kind "' .. tostring(e.kind) .. '"' end
  for k in pairs(e) do
    if not keys[k] then return nil, 'unknown key "' .. tostring(k) .. '"' end
  end
  if e.note ~= nil and type(e.note) ~= 'string' then return nil, '"note" must be text' end
  local out = { kind = e.kind, note = e.note }
  if e.kind == 'challenge' then
    if not isInt(e.id) or e.id < 1 then return nil, '"id" must be a challenge id' end
    out.id = e.id
    return out
  end
  if type(e.guid) ~= 'string' then return nil, 'no character' end
  local row = byGuid[e.guid]
  if not row then return nil, 'the character is no longer known' end
  out.guid, out.row = e.guid, row
  if e.kind == 'level' then
    if not isInt(e.level) or e.level < 2 or e.level > R.MAX_LEVEL then return nil, '"level" must be 2 to 60' end
    out.level = e.level
  elseif e.kind == 'skill' then
    local prof = Plan.CanonicalProfession(e.profession)
    if not prof then return nil, 'unknown profession "' .. tostring(e.profession) .. '"' end
    if not isInt(e.skill) or e.skill < 1 or e.skill > 300 then return nil, '"skill" must be 1 to 300' end
    out.profession, out.skill = prof, e.skill
  else
    if type(e.rested) ~= 'number' or e.rested < 0.05 or e.rested > R.REST.cap then return nil, '"rested" must be 0.05 to 1.5 levels' end
    out.rested = e.rested
  end
  return out
end

--- The saved steps, checked: { steps = {...}, problems = { UNEXPECTED lines }, total }.
function Plan.Load(rows)
  local byGuid = {}
  for _, r in ipairs(rows) do if r.guid then byGuid[r.guid] = r end end
  local res = { steps = {}, problems = {}, total = 0 }
  for i, e in ipairs(Plan.Mine()) do
    res.total = res.total + 1
    local ok, why = Plan.Check(e, byGuid)
    if ok then
      ok.n = i
      res.steps[#res.steps + 1] = ok
    else
      res.problems[#res.problems + 1] = 'UNEXPECTED plan step ' .. i .. ': ' .. why .. ' (skipped)'
    end
  end
  return res
end

--- Saved steps for a route (the auto plan copied into "my plan"). A dungeon or Explorer step is saved by its
-- challenge id; without a Legacy read the id is unknown and the step is left out (counted in `skipped`).
function Plan.FromRoute(steps)
  local list, skipped = {}, 0
  for _, s in ipairs(steps) do
    local guid = s.row and s.row.guid
    if s.kind == 'dungeon' or s.kind == 'explorer' then
      if s.id then list[#list + 1] = { kind = 'challenge', id = s.id } else skipped = skipped + 1 end
    elseif not guid then
      skipped = skipped + 1
    else
      for _, p in ipairs(s.parts) do
        if p.kind == 'level' then
          list[#list + 1] = { kind = 'level', guid = guid, level = p.to }
        elseif p.kind == 'skill' then
          list[#list + 1] = { kind = 'skill', guid = guid, profession = p.profession, skill = p.to }
        end
      end
    end
    if #list >= Plan.MAX_MINE then break end
  end
  return list, skipped
end

---------------------------------------------------------------------------
-- XP rate measurement (Q-F2)
---------------------------------------------------------------------------

local session = {}       -- guid -> { cum, t, level } at the first reading this login

local function cumulative(level, xp)
  local c = 0
  for l = 1, level - 1 do c = c + (RR.XP[l] or 0) end
  return c + (xp or 0)
end

--- Called by the snapshot with its own readings. Saves a rate when the rule above is met. Returns the rate saved, or nil.
function Plan.ObserveRate(guid, level, xp, t)
  if type(guid) ~= 'string' or not isInt(level) or type(xp) ~= 'number' or type(t) ~= 'number' then return nil end
  if level >= R.MAX_LEVEL then return nil end
  local base = session[guid]
  local cum = cumulative(level, xp)
  if not base or cum < base.cum then
    session[guid] = { cum = cum, t = t, level = level }
    return nil
  end
  local secs = t - base.t
  if secs < Plan.RATE_MIN_SECONDS or level <= base.level or not EI.Store.IsWritable() then return nil end
  local rate = (cum - base.cum) / secs * 3600
  if rate <= 0 then return nil end
  local rates = Plan.Rates()
  local old = type(rates[guid]) == 'table' and tonumber(rates[guid].xpPerHour) or nil
  if old and old > 0 then rate = (old + rate) / 2 end
  rate = math.floor(rate + 0.5)
  rates[guid] = { xpPerHour = rate, at = t }
  session[guid] = { cum = cum, t = t, level = level }
  return rate
end

--- Test helper.
function Plan.Reset() session = {} end
