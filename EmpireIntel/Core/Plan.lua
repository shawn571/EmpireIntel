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

--- How many saved steps of "my plan" belong to a character (D-063 item 4).
function Plan.StepsOf(guid)
  local n = 0
  for _, e in ipairs(Plan.Mine()) do if type(e) == 'table' and e.guid == guid then n = n + 1 end end
  return n
end

--- The chat text after an ignore or unignore (D-063 item 4): what happens in Fastest and in my plan.
function Plan.IgnoreText(name, guid, on)
  local n = Plan.StepsOf(guid)
  local steps = n .. ' step' .. (n == 1 and '' or 's')
  if on then
    return tostring(name) .. ' is left out of the fastest route.' .. (n > 0 and (' Its ' .. steps .. ' in my plan are kept, marked "ignored" and skipped for Up next (Remove step deletes one; Unignore brings them back).') or '')
  end
  return tostring(name) .. ' is back in the fastest route.' .. (n > 0 and (' Its ' .. steps .. ' in my plan are active again.') or '')
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
      -- the level the route takes the runner to first is kept as its own step (D-063 item 1: a prerequisite)
      for _, p in ipairs(s.parts) do
        if p.kind == 'level' and guid then list[#list + 1] = { kind = 'level', guid = guid, level = p.to } end
      end
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
-- prerequisites (P2-4b retest, D-063 item 1): every edit of "my plan" keeps them
---------------------------------------------------------------------------
-- A skill step needs the level of the training gate it passes (L-4, RouteRules.TRAIN), unless the character is
-- already at that level or already has the rank (its max skill is at or above the target). The prerequisite is
-- met by the character's level, or by a level step of the same character, at that level or higher, earlier in
-- the list. Gates that were already open before an edit are left as they are (the row shows them as a gate).

--- The level a skill target needs (L-4), or nil.
function Plan.GateLevel(skill)
  local need = nil
  for cap, g in pairs(RR.TRAIN) do
    if type(skill) == 'number' and skill > cap - 75 and (not need or g.level > need) then need = g.level end
  end
  return need
end

local function profOf(row, name)
  for _, p in ipairs(row and type(row.professions) == 'table' and row.professions or {}) do
    if type(p.name) == 'string' and string.lower(p.name) == string.lower(name) then return p end
  end
  return nil
end

--- The level an entry needs before it, or nil when it needs none.
function Plan.Needs(e, byGuid)
  if type(e) ~= 'table' or e.kind ~= 'skill' or type(e.guid) ~= 'string' then return nil end
  local need = Plan.GateLevel(e.skill)
  if not need then return nil end
  local row = byGuid[e.guid]
  if row and type(row.level) == 'number' and row.level >= need then return nil end
  local p = row and type(e.profession) == 'string' and profOf(row, e.profession)
  if p and type(p.max) == 'number' and p.max >= e.skill then return nil end
  return need
end

local function meets(x, e, need) return x.kind == 'level' and x.guid == e.guid and type(x.level) == 'number' and x.level >= need end

--- Steps whose prerequisite is not met before them: { dep, need, sat (the first level step after it, or nil) }.
function Plan.Violations(list, byGuid)
  local out = {}
  for i, e in ipairs(list) do
    local need = Plan.Needs(e, byGuid)
    if need then
      local ok = false
      for j = 1, i - 1 do if meets(list[j], e, need) then ok = true; break end end
      if not ok then
        local sat = nil
        for j = i + 1, #list do if meets(list[j], e, need) then sat = list[j]; break end end
        out[#out + 1] = { dep = e, need = need, sat = sat }
      end
    end
  end
  return out
end

local function indexOf(list, e) for i, x in ipairs(list) do if x == e then return i end end return nil end

local function openGates(list, byGuid)
  local set = {}
  for _, v in ipairs(Plan.Violations(list, byGuid)) do set[v.dep] = true end
  return set
end

--- A step's short name for messages: "Name Level 10", "Name Enchanting 150", "challenge 123".
function Plan.Label(e, byGuid)
  if e.kind == 'challenge' then return 'challenge ' .. tostring(e.id) end
  local row = byGuid[e.guid]
  local who = row and row.name and (tostring(row.name) .. ' ') or ''
  if e.kind == 'level' then return who .. 'Level ' .. tostring(e.level) end
  if e.kind == 'skill' then return who .. tostring(e.profession) .. ' ' .. tostring(e.skill) end
  return who .. 'Rested ' .. tostring(e.rested)
end

local function gateText(need)
  local rank
  for _, g in pairs(RR.TRAIN) do if g.level == need then rank = g.rank end end
  return (rank or 'training') .. ' needs level ' .. need .. ', L-4'
end

-- After an edit: every gate that was open before stays as it was; a new one is fixed by carrying the level step
-- (moved = the step the user moved: if it is the level step, its dependents follow it down instead), or, when no
-- level step exists, by `missing` ('insert' a level step before it, or 'block'); 'blockAll' refuses any new gate.
-- Returns list, carried (entries moved or inserted, each with .why), or nil plus the reason.
local function keep(list, old, byGuid, moved, missing)
  local carried = {}
  for _ = 1, #list + 1 do
    local fix
    for _, v in ipairs(Plan.Violations(list, byGuid)) do if not old[v.dep] then fix = v; break end end
    if not fix then return list, carried end
    local di = indexOf(list, fix.dep)
    if missing == 'blockAll' then
      return nil, Plan.Label(fix.dep, byGuid) .. ' needs level ' .. fix.need .. ' first (' .. gateText(fix.need) .. ')'
    end
    if fix.sat then
      -- a level step the user moved down takes its dependents with it, even when another level step would do
      if moved and meets(moved, fix.dep, fix.need) and (indexOf(list, moved) or 0) > di then fix.sat = moved end
      local si = indexOf(list, fix.sat)
      if fix.sat == moved then
        table.remove(list, di); table.insert(list, si, fix.dep)
        carried[#carried + 1] = { e = fix.dep, why = 'needs ' .. Plan.Label(fix.sat, byGuid) .. ' first (' .. gateText(fix.need) .. ')' }
      else
        table.remove(list, si); table.insert(list, di, fix.sat)
        carried[#carried + 1] = { e = fix.sat, why = 'prerequisite of ' .. Plan.Label(fix.dep, byGuid) .. ' (' .. gateText(fix.need) .. ')' }
      end
    elseif missing == 'insert' then
      local lv = { kind = 'level', guid = fix.dep.guid, level = fix.need }
      table.insert(list, di, lv)
      carried[#carried + 1] = { e = lv, why = 'prerequisite of ' .. Plan.Label(fix.dep, byGuid) .. ' (' .. gateText(fix.need) .. ')', added = true }
    else
      return nil, Plan.Label(fix.dep, byGuid) .. ' needs level ' .. fix.need .. ' first (' .. gateText(fix.need) .. ')'
    end
  end
  return nil, 'the prerequisites could not be kept'
end

local function copyList(list) local o = {}; for i, x in ipairs(list) do o[i] = x end; return o end

local function carriedText(carried, byGuid)
  local chain, moved, added = {}, {}, {}
  for _, c in ipairs(carried) do
    if c.chain then chain[#chain + 1] = Plan.Label(c.e, byGuid)
    else
      local t = Plan.Label(c.e, byGuid) .. ' (' .. c.why .. ')'
      if c.added then added[#added + 1] = t else moved[#moved + 1] = t end
    end
  end
  local out = ''
  if #chain > 0 then out = out .. ' Moved with it, in order: ' .. table.concat(chain, ', ') .. '.' end
  if #moved > 0 then out = out .. ' Moved with it: ' .. table.concat(moved, '; ') .. '.' end
  if #added > 0 then out = out .. ' Added before it: ' .. table.concat(added, '; ') .. '.' end
  return out
end
Plan.CarriedText = carriedText

-- D-066: a step's chain is every step of the same character it builds on: for a level step, the lower level
-- steps; for a skill step, the lower steps of the same profession and, for each of them and itself, the level
-- step that opens its training gate (L-4) with every level step up to it. Moving a step up brings its whole chain
-- ahead of it, in order; moving a step down takes every step that builds on it along, after it, in order. So no
-- step is left below as "covered".

local function rank(e)
  if e.kind == 'level' then return e.level, 0, 0 end
  if e.kind == 'skill' then return Plan.GateLevel(e.skill) or 0, 1, e.skill end
  return 0, 2, 0
end
local function before(a, b)
  local a1, a2, a3 = rank(a)
  local b1, b2, b3 = rank(b)
  if a1 ~= b1 then return a1 < b1 end
  if a2 ~= b2 then return a2 < b2 end
  return a3 < b3
end

--- The steps of `list` that `e` builds on (a set: entry -> true).
function Plan.Chain(list, e, byGuid)
  local set = {}
  if type(e) ~= 'table' or (e.kind ~= 'level' and e.kind ~= 'skill') or type(e.guid) ~= 'string' then return set end
  local topLevel = (e.kind == 'level') and (e.level - 1) or 0
  if e.kind == 'skill' then
    local prof = Plan.CanonicalProfession(e.profession)
    local skills = { e }
    for _, x in ipairs(list) do
      if x ~= e and x.kind == 'skill' and x.guid == e.guid and Plan.CanonicalProfession(x.profession) == prof
        and type(x.skill) == 'number' and x.skill < e.skill then
        set[x] = true; skills[#skills + 1] = x
      end
    end
    local gate = 0
    for _, x in ipairs(skills) do local n = Plan.Needs(x, byGuid); if n and n > gate then gate = n end end
    if gate > 0 then
      topLevel = gate
      -- the level step that meets the highest gate (the smallest planned level at or above it)
      local sat
      for _, x in ipairs(list) do
        if x.kind == 'level' and x.guid == e.guid and type(x.level) == 'number' and x.level >= gate and (not sat or x.level < sat) then sat = x.level end
      end
      if sat then topLevel = sat end
    end
  end
  for _, x in ipairs(list) do
    if x ~= e and x.kind == 'level' and x.guid == e.guid and type(x.level) == 'number' and x.level <= topLevel then set[x] = true end
  end
  return set
end

-- e placed at its new index in out: bring its chain ahead (moving up) or its dependents after it (moving down)
local function chainMove(out, e, byGuid, up, carried)
  if up then
    local chain = Plan.Chain(out, e, byGuid)
    local anchor = indexOf(out, e)
    local members = {}
    for i, x in ipairs(out) do if chain[x] then members[#members + 1] = x; if i < anchor then anchor = i end end end
    local moved = false
    for _, x in ipairs(members) do if indexOf(out, x) > indexOf(out, e) then moved = true end end
    if not moved then return end
    table.sort(members, before)
    local block = {}
    for _, x in ipairs(members) do block[#block + 1] = x end
    block[#block + 1] = e
    local rest = {}
    for _, x in ipairs(out) do if not chain[x] and x ~= e then rest[#rest + 1] = x end end
    for i = #out, 1, -1 do out[i] = nil end
    for i = 1, anchor - 1 do out[#out + 1] = rest[i] end
    for _, x in ipairs(block) do out[#out + 1] = x end
    for i = anchor, #rest do out[#out + 1] = rest[i] end
    for _, x in ipairs(members) do carried[#carried + 1] = { e = x, why = 'part of its chain', chain = true } end
  else
    local deps = {}
    local ei = indexOf(out, e)
    for i = 1, ei - 1 do
      local x = out[i]
      if Plan.Chain(out, x, byGuid)[e] then deps[#deps + 1] = x end
    end
    if #deps == 0 then return end
    table.sort(deps, before)
    for _, x in ipairs(deps) do table.remove(out, indexOf(out, x)) end
    local at = indexOf(out, e)
    for k, x in ipairs(deps) do table.insert(out, at + k, x); carried[#carried + 1] = { e = x, why = 'builds on it', chain = true } end
  end
end

--- Moves step `from` to position `to`, keeping prerequisites and chains (D-066). Returns list, carried, or nil
-- plus the reason.
function Plan.MoveKeeping(list, from, to, byGuid)
  local e = list[from]
  if not e then return nil, 'no step ' .. tostring(from) end
  local old = openGates(list, byGuid)
  local out = copyList(list)
  table.remove(out, from)
  to = math.max(1, math.min(to, #out + 1))
  table.insert(out, to, e)
  local carried = {}
  chainMove(out, e, byGuid, to < from, carried)
  local res, more = keep(out, old, byGuid, e, 'block')
  if not res then return nil, more end
  for _, c in ipairs(more) do carried[#carried + 1] = c end
  return res, carried
end

--- Removes step n unless a later step needs it. Returns list, or nil plus the reason.
function Plan.RemoveKeeping(list, n, byGuid)
  if not list[n] then return nil, 'no step ' .. tostring(n) end
  local old = openGates(list, byGuid)
  local out = copyList(list)
  table.remove(out, n)
  local res, why = keep(out, old, byGuid, nil, 'blockAll')      -- a removal never carries
  if not res then return nil, 'not removed: ' .. why .. '; remove that step first' end
  return res
end

--- Replaces step n with e2, keeping prerequisites (a skill target that now needs a level step gets one before it;
-- a level step lowered below what a later step needs is refused). Returns list, carried, or nil plus the reason.
function Plan.ReplaceKeeping(list, n, e2, byGuid)
  if not list[n] then return nil, 'no step ' .. tostring(n) end
  local old = openGates(list, byGuid)
  -- a gate that was open stays accepted when the edit does not change what the step needs (a note, say)
  if old[list[n]] and Plan.Needs(e2, byGuid) == Plan.Needs(list[n], byGuid) then old[e2] = true end
  local out = copyList(list)
  out[n] = e2
  local res, carried = keep(out, old, byGuid, nil, e2.kind == 'skill' and 'insert' or 'blockAll')
  if not res then return nil, carried end
  -- a raised target that now passes a milestone gets that milestone's own row (D-070)
  local filled, added = Plan.FillMilestones(res, byGuid)
  if not filled then return nil, added end
  for _, x in ipairs(added) do carried[#carried + 1] = { e = x, why = 'its own milestone row', added = true } end
  return filled, carried
end

--- Inserts e after step n (at the end when n is past it), keeping prerequisites (a missing level step is added
-- before it). Returns list, carried, or nil plus the reason.
function Plan.InsertKeeping(list, n, e, byGuid)
  local old = openGates(list, byGuid)
  local out = copyList(list)
  table.insert(out, math.max(0, math.min(n, #out)) + 1, e)
  return keep(out, old, byGuid, nil, 'insert')
end

--- The next step to add after a step (D-063 item 2): the next milestone above the character's value and every
-- step already planned for it, so no step is ever duplicated. kind 'level' (class milestones) or 'skill' (craft
-- milestones of `prof`). Returns the entry, or nil plus the reason.
function Plan.NextEntry(list, kind, guid, row, prof)
  if kind == 'level' then
    local base = (row and type(row.level) == 'number') and row.level or 1
    for _, x in ipairs(list) do if x.kind == 'level' and x.guid == guid and type(x.level) == 'number' and x.level > base then base = x.level end end
    local m = R.Next(R.CLASS_MILESTONES, base)
    if not m then return nil, 'level ' .. R.MAX_LEVEL .. ' is already planned' end
    return { kind = 'level', guid = guid, level = m }
  end
  prof = Plan.CanonicalProfession(prof)
  if not prof then return nil, 'no profession' end
  local p = profOf(row, prof)
  local base = (p and type(p.skill) == 'number') and p.skill or 0
  for _, x in ipairs(list) do
    if x.kind == 'skill' and x.guid == guid and Plan.CanonicalProfession(x.profession) == prof and type(x.skill) == 'number' and x.skill > base then base = x.skill end
  end
  local m = R.Next(R.CRAFT_MILESTONES, base)
  if not m then return nil, prof .. ' 300 is already planned' end
  return { kind = 'skill', guid = guid, profession = prof, skill = m }
end

---------------------------------------------------------------------------
-- one row per milestone (D-070)
---------------------------------------------------------------------------

--- Adds the milestone steps a step passes without a row of its own: before "Alchemy 225" a missing "Alchemy 150"
-- (above the character's skill today), before "Level 60" a missing "Level 45" (above its level today), each just
-- before the step that passes it; a training gate it then needs gets its level step (as InsertKeeping does).
-- Returns list, added (entries), or nil plus the reason.
function Plan.FillMilestones(list, byGuid)
  local old = openGates(list, byGuid)
  local out, added = {}, {}
  local have = {}
  for _, e in ipairs(list) do
    if type(e) == 'table' and e.kind == 'level' then have['l|' .. tostring(e.guid) .. '|' .. tostring(e.level)] = true end
    if type(e) == 'table' and e.kind == 'skill' then have['s|' .. tostring(e.guid) .. '|' .. tostring(Plan.CanonicalProfession(e.profession)) .. '|' .. tostring(e.skill)] = true end
  end
  for _, e in ipairs(list) do
    local row = type(e) == 'table' and type(e.guid) == 'string' and byGuid[e.guid]
    if row and e.kind == 'skill' and type(e.skill) == 'number' and Plan.CanonicalProfession(e.profession) then
      local prof = Plan.CanonicalProfession(e.profession)
      local p = profOf(row, prof)
      local now = (p and type(p.skill) == 'number') and p.skill or 0
      for _, m in ipairs(R.CRAFT_MILESTONES) do
        local k = 's|' .. e.guid .. '|' .. prof .. '|' .. m
        if m > now and m < e.skill and not have[k] then
          local x = { kind = 'skill', guid = e.guid, profession = prof, skill = m }
          out[#out + 1] = x; added[#added + 1] = x; have[k] = true
        end
      end
    elseif row and e.kind == 'level' and type(e.level) == 'number' and type(row.level) == 'number' then
      for _, m in ipairs(R.CLASS_MILESTONES) do
        local k = 'l|' .. e.guid .. '|' .. m
        if m > row.level and m < e.level and not have[k] then
          local x = { kind = 'level', guid = e.guid, level = m }
          out[#out + 1] = x; added[#added + 1] = x; have[k] = true
        end
      end
    end
    out[#out + 1] = e
  end
  if #added == 0 then return list, added end
  local res, carried = keep(out, old, byGuid, nil, 'insert')
  if not res then return nil, carried end
  for _, c in ipairs(carried) do if c.added then added[#added + 1] = c.e end end
  return res, added
end

--- Saves FillMilestones' result. Returns added, or nil plus the reason (read-only).
function Plan.FillSaved(byGuid)
  local mine = Plan.Section().mine
  if type(mine) ~= 'table' then return {} end
  local list, added = Plan.FillMilestones(mine, byGuid)
  if not list then return nil, added end
  if #added == 0 then return added end
  local ok, why = writable()
  if not ok then return nil, why end
  Plan.Section().mine = list
  return added
end

function Plan.FillText(added, why, byGuid)
  if added == nil then return 'my plan has milestones without their own row; ' .. tostring(why) end
  if #added == 0 then return nil end
  local parts = {}
  for _, e in ipairs(added) do parts[#parts + 1] = Plan.Label(e, byGuid or {}) end
  return 'added ' .. #added .. ' milestone step' .. (#added == 1 and '' or 's') .. ' to my plan, each before the step that passes it: '
    .. table.concat(parts, ', ') .. '.'
end

---------------------------------------------------------------------------
-- duplicates (D-065): removed from the saved plan at load, the first kept
---------------------------------------------------------------------------

local function stepKey(e)
  if type(e) ~= 'table' or not KEYS[e.kind] then return nil end
  for k in pairs(e) do if not KEYS[e.kind][k] then return nil end end      -- a bad step stays, reported by Load
  if e.kind == 'challenge' then return 'c|' .. tostring(e.id) end
  if e.kind == 'level' then return 'l|' .. tostring(e.guid) .. '|' .. tostring(e.level) end
  if e.kind == 'skill' then return 's|' .. tostring(e.guid) .. '|' .. string.lower(tostring(e.profession)) .. '|' .. tostring(e.skill) end
  if e.kind == 'rested' then return 'r|' .. tostring(e.guid) .. '|' .. tostring(e.rested) end
  return nil
end

--- Removes saved steps that repeat an earlier one (same kind, character and target; the first is kept, and keeps
-- a later copy's note when it has none). Returns removed { { n, e } }, or nil plus the reason (read-only).
-- Removing a later copy never breaks a prerequisite: the kept one is earlier.
function Plan.Dedupe()
  local mine = Plan.Section().mine
  if type(mine) ~= 'table' then return {} end
  local seen, list, removed = {}, {}, {}
  for i, e in ipairs(mine) do
    local k = stepKey(e)
    local first = k and seen[k]
    if first then
      removed[#removed + 1] = { n = i, e = e }
      if (first.note == nil or first.note == '') and type(e.note) == 'string' and e.note ~= '' then first.carryNote = e.note end
    else
      if k then seen[k] = { e = e, note = e.note } end
      list[#list + 1] = e
    end
  end
  if #removed == 0 then return removed end
  local ok, why = writable()
  if not ok then return nil, why end
  for _, f in pairs(seen) do if f.carryNote then f.e.note = f.carryNote end end
  Plan.Section().mine = list
  return removed
end

--- The chat line after Dedupe, or nil when nothing was found.
function Plan.DedupeText(removed, why, byGuid)
  if removed == nil then return 'my plan has repeated steps; ' .. tostring(why) end
  if #removed == 0 then return nil end
  local parts = {}
  for _, x in ipairs(removed) do parts[#parts + 1] = 'step ' .. x.n .. ' ' .. Plan.Label(x.e, byGuid or {}) end
  return 'removed ' .. #removed .. ' repeated step' .. (#removed == 1 and '' or 's') .. ' from my plan (the first of each is kept): '
    .. table.concat(parts, ', ') .. '.'
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
