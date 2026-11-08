local ADDON, EI = ...
-- EmpireIntel / Core / Route.lua                                         (Phase 2, increment P2-4a)
--
-- PURPOSE
--   The route engine (Phase2_Plan.md sections 8.4-8.6, approved D-055, D-056): from the characters' real values,
--   the cheapest next Legacy point, applied and repeated until the target. Pure: no game call, no print, nothing
--   saved. The caller (Core/Next.lua) gathers the rows, the plan settings and an optional Legacy read.
--
-- RULES
--   * Unit: estimated play hours [estimate]. Every rule a step depends on is listed on the step (RouteRules ids).
--   * Greedy (8.5): take the cheapest next point including its gates, apply it, repeat. Ties: the character being
--     played first, then a step that levels a character (it opens gates for later points), then the list order.
--   * Rested XP (L-17, D-055): a pool of R saves R of kill XP in full; kills are assumed to give at least R of the
--     XP to go [assumed], so the saving is min(R, XP to go).
--   * Legacy lock (D-052, L-1): before any character reaches 25 the first step is a character to 25.
--   * Never mixes rulesets (L-18): characters whose recorded ruleset differs from the plan's are left out.
--   * Earned points: the game's count when a Legacy read is given (Q-F5: the game wins), else inferred from the
--     levels and skills recorded (class and craft challenges only), and labelled so.
--   * Not planned: PvP before 60 (L-9), raids and Valthalak (L-10), new characters; the result says how many points
--     of the target that leaves.

EI = EI or {}
local R = EI.Rules
local RR = EI.RouteRules
assert(R and RR, 'load order: Rules, RouteRules, Route')

local Route = {}
EI.Route = Route

local EPS = 1e-6

---------------------------------------------------------------------------
-- costs
---------------------------------------------------------------------------

local function band(list, value, field)
  for _, b in ipairs(list) do if value <= b.upTo then return b[field] end end
  return list[#list][field]
end

--- XP per hour for a character at a level: its measured rate (Q-F2) or the band default. Returns rate, measured.
function Route.Rate(st, level)
  if st.rate then return st.rate, true end
  return band(RR.XP_PER_HOUR, level, 'rate'), false
end

-- the bar of a level for this character: the measured bar at its recorded level (L-15), else the classic table
local function bar(st, level)
  if level == st.row.level and type(st.row.xpMax) == 'number' and st.row.xpMax > 0 then return st.row.xpMax end
  return RR.XP[level] or RR.XP[#RR.XP]
end

--- Hours to take a simulated character to `to`. Returns hours, restSavedHours, restUsed (XP), measuredBar (bool).
function Route.LevelHours(st, to)
  local hours, saved, used = 0, 0, 0
  local rest = st.rest or 0
  local tableUsed = false
  for level = st.level, to - 1 do
    local need = bar(st, level)
    if level ~= st.row.level or not (type(st.row.xpMax) == 'number' and st.row.xpMax > 0) then tableUsed = true end
    if level == st.level then need = need - (st.xp or 0) end
    if need < 0 then need = 0 end
    local rate = Route.Rate(st, level)
    local r = math.min(rest, need)
    rest, used = rest - r, used + r
    hours = hours + (need - r) / rate
    saved = saved + r / rate
  end
  return hours, saved, used, tableUsed
end

--- Hours of skill-ups from `from` to `to` (L-16 [assumed]).
function Route.SkillHours(from, to)
  local h = 0
  for s = from + 1, to do h = h + band(RR.HOURS_PER_SKILL, s, 'h') end
  return h
end

---------------------------------------------------------------------------
-- the starting state
---------------------------------------------------------------------------

local function primaryCount(profs)
  local n = 0
  for name in pairs(profs) do
    if RR.GATHERING[name] or R.Craft({ name = name }) then n = n + 1 end
  end
  return n
end

local function restNow(row, now)
  if row.liveRest then return type(row.rest) == 'number' and row.rest or 0 end
  local b = (type(row.xpMax) == 'number' and row.xpMax > 0) and row.xpMax or (type(row.level) == 'number' and RR.XP[row.level])
  local p = R.ProjectRest(row.rest, b, row.resting, row.restAt, now, row.src == 'self')
  return p or 0
end

local function newState(row, now, rates)
  local profs, known = {}, type(row.professions) == 'table'
  for _, p in ipairs(known and row.professions or {}) do
    if type(p.name) == 'string' and type(p.skill) == 'number' then
      local c = R.Craft(p) or p.name
      profs[c] = { skill = p.skill, max = p.max }
    end
  end
  local rate = rates and row.guid and type(rates[row.guid]) == 'table' and tonumber(rates[row.guid].xpPerHour) or nil
  if rate and rate <= 0 then rate = nil end
  return { row = row, level = row.level, xp = (type(row.xp) == 'number' and row.xpMax and row.xp) or 0,
    rest = restNow(row, now), profs = profs, profsKnown = known, primaries = primaryCount(profs), rate = rate }
end

--- A simulated character from a row (also used by /ei next for the estimates of "my plan" steps).
Route.State = newState

local function classKey(class, m) return 'class:' .. tostring(class) .. ':' .. m end
local function craftKey(craft, m) return 'craft:' .. craft .. ':' .. m end

local function classTitle(class, m) return R.CLASS_TITLES[m] .. ' ' .. (R.CLASS_NAMES[class] or tostring(class)) end
local function craftTitle(craft, m) return R.CRAFT_TITLES[m] .. ' ' .. (R.CRAFT_PERSON[craft] or craft) end

-- done challenges and earned points: from a Legacy read (the game) or inferred from the rows
local function startDone(states, legacy)
  local done, dungeonLeft, explorer = {}, {}, nil
  local s = legacy and not legacy.error and legacy.summary
  if s and s.recognized then
    local byName = {}
    for _, ch in ipairs(legacy.challenges or {}) do
      if ch.legacy and not ch.excluded and type(ch.name) == 'string' then byName[ch.name] = ch end
    end
    for _, class in ipairs(R.CLASSES) do
      for _, m in ipairs(R.CLASS_MILESTONES) do
        local ch = byName[classTitle(class, m)]
        if ch and ch.completed == true then done[classKey(class, m)] = true end
      end
    end
    for _, c in ipairs(R.CRAFTS) do
      for _, m in ipairs(R.CRAFT_MILESTONES) do
        local ch = byName[craftTitle(c.name, m)]
        if ch and ch.completed == true then done[craftKey(c.name, m)] = true end
      end
    end
    for _, d in ipairs(RR.DUNGEONS) do
      local ch = byName[d.name]
      if ch then
        if ch.completed == true then
          done['dungeon:' .. d.name] = true
        elseif type(ch.criteria) == 'table' and #ch.criteria > 0 then
          local left = 0
          for _, c in ipairs(ch.criteria) do if c.completed ~= true then left = left + 1 end end
          dungeonLeft[d.name] = { left = left, id = ch.id }
        else
          dungeonLeft[d.name] = { id = ch.id }
        end
      end
    end
    local ex = byName['Explorer']
    if ex then
      if ex.completed == true then
        done.explorer = true
      elseif type(ex.steps) == 'table' then
        -- zone steps: steps that do not link to another step (EI-E-23); per character (EI-E-27)
        local parents = {}
        for _, st in ipairs(ex.steps) do
          for _, c in ipairs(st.criteria or {}) do if c.type == 8 then parents[st.id] = true end end
        end
        local left, total = 0, 0
        for _, st in ipairs(ex.steps) do
          if not parents[st.id] then
            total = total + 1
            if st.completed ~= true then left = left + 1 end
          end
        end
        explorer = { left = left, total = total, id = ex.id }
      end
    end
    return done, s.earned or 0, 'game', dungeonLeft, explorer
  end
  local earned = 0
  for _, st in ipairs(states) do
    for _, m in ipairs(R.CLASS_MILESTONES) do
      local k = classKey(st.row.class, m)
      if st.row.class and type(st.level) == 'number' and st.level >= m and not done[k] then done[k] = true; earned = earned + 1 end
    end
    for craft, p in pairs(st.profs) do
      if R.Craft({ name = craft }) then
        for _, m in ipairs(R.CRAFT_MILESTONES) do
          local k = craftKey(craft, m)
          if p.skill >= m and not done[k] then done[k] = true; earned = earned + 1 end
        end
      end
    end
  end
  return done, earned, 'inferred', dungeonLeft, nil
end

---------------------------------------------------------------------------
-- candidates: each earns at least one point
---------------------------------------------------------------------------

local function addRule(list, id) for _, x in ipairs(list) do if x == id then return end end list[#list + 1] = id end

local function levelPart(st, to, c)
  if type(st.level) ~= 'number' or st.level >= to then return end
  local h, saved, used, tableUsed = Route.LevelHours(st, to)
  c.parts[#c.parts + 1] = { kind = 'level', from = st.level, to = to }
  c.hours = c.hours + h
  c.restHours = (c.restHours or 0) + saved
  c.restUsed = (c.restUsed or 0) + used
  c.levels = true
  addRule(c.rules, 'L-16')
  if tableUsed then addRule(c.rules, 'L-15') end
  if used > 0 then addRule(c.rules, 'L-17') end
  if st.rate then c.measured = true end
end

local function classCandidates(states, done, out, unlocked)
  for _, st in ipairs(states) do
    if st.row.class and type(st.level) == 'number' then
      for _, m in ipairs(R.CLASS_MILESTONES) do
        if not done[classKey(st.row.class, m)] then
          if st.level < m and (unlocked or m == R.UNLOCK_LEVEL) then
            local c = { st = st, kind = 'class', parts = {}, hours = 0, rules = { 'L-2' }, key = classKey(st.row.class, m),
              title = classTitle(st.row.class, m) }
            levelPart(st, m, c)
            out[#out + 1] = c
          end
          break
        end
      end
    end
  end
end

local function craftCandidates(states, done, out)
  for _, cr in ipairs(R.CRAFTS) do
    local m = nil
    for _, x in ipairs(R.CRAFT_MILESTONES) do if not done[craftKey(cr.name, x)] then m = x; break end end
    if m then
      for _, st in ipairs(states) do
        local p = st.profs[cr.name]
        local learn = false
        if not p and st.profsKnown and st.primaries < RR.PRIMARY_SLOTS then p = { skill = 0 }; learn = true end
        if p and type(st.level) == 'number' and p.skill < m then
          local c = { st = st, kind = 'craft', parts = {}, hours = 0, rules = { 'L-3' }, key = craftKey(cr.name, m),
            title = craftTitle(cr.name, m), craft = cr.name, learn = learn }
          local gate = RR.TRAIN[m]
          if gate and not (type(p.max) == 'number' and p.max >= m) then
            addRule(c.rules, 'L-4'); addRule(c.rules, 'L-5')
            if st.level < gate.level then levelPart(st, gate.level, c) end
            c.train = gate.rank
          end
          if learn then addRule(c.rules, 'L-6') end
          c.parts[#c.parts + 1] = { kind = 'skill', profession = cr.name, from = p.skill, to = m, learn = learn, max = p.max }
          c.hours = c.hours + Route.SkillHours(p.skill, m)
          addRule(c.rules, 'L-16')
          out[#out + 1] = c
        end
      end
    end
  end
end

local function dungeonCandidates(states, done, dungeonLeft, out)
  for _, d in ipairs(RR.DUNGEONS) do
    if not done['dungeon:' .. d.name] then
      local info = dungeonLeft[d.name]
      local left = info and info.left
      local unknown = left == nil
      if unknown then left = d.count end
      for _, st in ipairs(states) do
        if type(st.level) == 'number' then
          local c = { st = st, kind = 'dungeon', parts = {}, hours = 0, rules = { 'L-7', 'L-8', 'L-16' }, key = 'dungeon:' .. d.name,
            title = d.name, id = info and info.id, unknownProgress = unknown }
          if st.level < d.minLevel then levelPart(st, d.minLevel, c) end
          c.parts[#c.parts + 1] = { kind = 'runs', name = d.name, left = left, unknown = unknown }
          c.hours = c.hours + left * RR.HOURS_PER_RUN
          out[#out + 1] = c
        end
      end
    end
  end
end

local function explorerCandidates(states, done, explorer, out, notes)
  if done.explorer then return end
  for _, st in ipairs(states) do
    if type(st.level) == 'number' and st.level >= RR.EXPLORER_LEVEL then
      if st.row.isPlayer and explorer then
        local c = { st = st, kind = 'explorer', parts = {}, hours = explorer.left * RR.HOURS_PER_ZONE, rules = { 'L-11', 'L-16' },
          key = 'explorer', title = 'Explorer', id = explorer.id }
        c.parts[1] = { kind = 'zones', left = explorer.left, total = explorer.total }
        out[#out + 1] = c
      elseif not notes.explorer then
        notes.explorer = { row = st.row, inRoute = not (type(st.row.level) == 'number' and st.row.level >= RR.EXPLORER_LEVEL) }
      end
    end
  end
end

local function better(a, b)
  if math.abs(a.hours - b.hours) > EPS then return a.hours < b.hours end
  local pa, pb = a.st.row.isPlayer == true, b.st.row.isPlayer == true
  if pa ~= pb then return pa end
  local la, lb = a.levels == true, b.levels == true
  if la ~= lb then return la end
  return a.order < b.order
end

---------------------------------------------------------------------------
-- apply a chosen step to the simulation
---------------------------------------------------------------------------

local function apply(c, done, step)
  local st = c.st
  done[c.key] = true
  step.earns[#step.earns + 1] = c.title
  for _, p in ipairs(c.parts) do
    if p.kind == 'level' then
      st.level, st.xp = p.to, 0
      st.rest = math.max(0, (st.rest or 0) - (c.restUsed or 0))
      -- class challenges crossed on the way are earned too
      for _, m in ipairs(R.CLASS_MILESTONES) do
        local k = classKey(st.row.class, m)
        if st.row.class and p.to >= m and not done[k] then
          done[k] = true
          step.earns[#step.earns + 1] = classTitle(st.row.class, m)
        end
      end
    elseif p.kind == 'skill' then
      if p.learn then st.primaries = st.primaries + 1 end
      st.profs[p.profession] = { skill = p.to, max = math.max(p.to, tonumber(p.max) or 0) }
    end
  end
end

---------------------------------------------------------------------------
-- the route
---------------------------------------------------------------------------

--- in: rows, now, legacy (finished read or nil), target (number | 'reward' | 'next'), rates, ignore, ruleset
-- Returns { earned, earnedSrc, target, targetKind, steps, left, notes, states, excluded = { ignored, ruleset } }.
function Route.Build(input)
  local now = input.now or 0
  local res = { steps = {}, notes = {}, excluded = { ignored = 0, ruleset = 0 } }
  local states = {}
  local want = input.ruleset
  for _, row in ipairs(input.rows or {}) do
    if row.guid and input.ignore and input.ignore[row.guid] then
      res.excluded.ignored = res.excluded.ignored + 1
    elseif want and row.ruleset and row.ruleset ~= want then
      res.excluded.ruleset = res.excluded.ruleset + 1
    elseif type(row.level) == 'number' then
      states[#states + 1] = newState(row, now, input.rates)
    end
  end
  res.states = states
  local done, earned, src, dungeonLeft, explorer = startDone(states, input.legacy)
  res.earned, res.earnedSrc = earned, src
  local t = input.target
  if t == 'reward' then
    local r = RR.NextReward(earned)
    res.targetKind, res.target = 'reward', r and r.at or earned
    res.reward = r
  elseif t == 'next' then
    res.targetKind, res.target = 'next', earned + 1
  else
    res.targetKind, res.target = 'points', tonumber(t) or RR.DEFAULT_TARGET
  end
  local unlocked = false
  for _, st in ipairs(states) do if st.level >= R.UNLOCK_LEVEL then unlocked = true end end
  res.unlocked = unlocked
  local total = earned
  local notes = {}
  while total < res.target and #res.steps < RR.MAX_STEPS do
    local cands = {}
    classCandidates(states, done, cands, unlocked)
    if unlocked then
      craftCandidates(states, done, cands)
      dungeonCandidates(states, done, dungeonLeft, cands)
      explorerCandidates(states, done, explorer, cands, notes)
    end
    if #cands == 0 then break end
    local best = nil
    for i, c in ipairs(cands) do
      c.order = i
      if not best or better(c, best) then best = c end
    end
    local step = { row = best.st.row, kind = best.kind, parts = best.parts, hours = best.hours, restHours = best.restHours,
      rules = best.rules, earns = {}, id = best.id, craft = best.craft, train = best.train, learn = best.learn,
      unknownProgress = best.unknownProgress, measured = best.measured, atLevel = best.st.level }
    apply(best, done, step)
    step.points = #step.earns
    total = total + step.points
    step.total = total
    res.steps[#res.steps + 1] = step
    if best.st.level >= R.UNLOCK_LEVEL then unlocked = true end
  end
  res.left = math.max(0, res.target - total)
  res.reached = total
  if notes.explorer then
    res.notes[#res.notes + 1] = { kind = 'explorer', row = notes.explorer.row, inRoute = notes.explorer.inRoute }
  end
  return res
end

--- The rule ids of a step that are labelled unverified, in order.
function Route.UnverifiedRules(step)
  local out = {}
  for _, id in ipairs(step.rules or {}) do if RR.Unverified(id) then out[#out + 1] = id end end
  table.sort(out, function(a, b) return tonumber(string.match(a, '%d+')) < tonumber(string.match(b, '%d+')) end)
  return out
end
