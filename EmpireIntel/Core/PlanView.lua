local ADDON, EI = ...
-- EmpireIntel / Core / PlanView.lua                                      (Phase 2, increment P2-4b)
--
-- PURPOSE
--   The window's content as data (Phase2_Plan.md 9.1, the approved mockup D-060): the header numbers, the Up Next
--   card, the rows, the footer and each row's tooltip, from the route (Fastest) or the saved steps (My plan).
--   Pure: no game call, no saved data. The window (UI/*.lua) only draws what this returns.
--
-- RULES
--   * Unknown is never shown as met; every time is an estimate, and a row that uses an unverified rule has its dot.
--   * Card art (EI-E-30): the played character's live portrait; an alt's race icon (Scourge -> undead), else its
--     class icon. Faction: the own record's, else DataStore's (marked); no faction, no emblem.
--   * Text is ASCII ("->", not an arrow sign).

EI = EI or {}
local R, RR, T = EI.Rules, EI.RouteRules, EI.Theme
assert(R and RR and T and EI.Route and EI.Plan, 'load order: Rules, RouteRules, Route, Plan, Theme, PlanView')

local V = {}
EI.PlanView = V

local function className(c) return R.CLASS_NAMES[c] or tostring(c or 'class?') end
local function hours(h)
  if type(h) ~= 'number' then return '?' end
  if h < 1 then return string.format('~%d min', math.max(1, math.floor(h * 60 + 0.5))) end
  return string.format('~%.1f h', h)
end
V.Hours = hours

local function ago(t, now)
  if type(t) ~= 'number' or type(now) ~= 'number' then return 'seen: unknown' end
  local d = now - t
  if d < 3600 then return 'seen ' .. math.max(0, math.floor(d / 60)) .. ' min ago' end
  if d < 172800 then return 'seen ' .. math.floor(d / 3600) .. ' h ago' end
  return 'seen ' .. math.floor(d / 86400) .. ' days ago'
end

local function rulesetBadge(rs)
  if rs == 'normal' then return { text = 'Normal', kind = 'normal' } end
  if rs == 'hardcore' then return { text = 'Hardcore', kind = 'hard' } end
  return { text = 'Ruleset unknown', kind = 'unknown' }
end

--- The art and badges for a character row (EI-E-30, D-060).
function V.Who(row, now, level)
  local faction, fsrc = row.faction, row.faction and 'self' or nil
  if not faction and row.dsFaction then faction, fsrc = row.dsFaction, 'datastore' end
  local art
  if row.isPlayer then
    art = { kind = 'portrait' }
  else
    local ra = T.RaceAtlas(row.race, row.sex)
    if ra then art = { kind = 'race', atlas = ra } else art = { kind = 'class', atlas = T.ClassAtlas(row.class) } end
  end
  return {
    name = tostring(row.name or 'name unknown'), class = row.class, classText = className(row.class),
    level = level or row.level, isPlayer = row.isPlayer == true, guid = row.guid,
    art = art, classAtlas = T.ClassAtlas(row.class),
    faction = faction, factionSrc = fsrc, emblem = faction and T.EMBLEM[faction] or nil,
    ruleset = rulesetBadge(row.ruleset),
    seen = row.isPlayer and 'played now' or ago(row.at, now),
  }
end

local function tooltip(title, timeLine, ruleIds)
  local lines = { { text = title }, { text = timeLine } }
  for _, id in ipairs(ruleIds or {}) do
    local r = RR.BY_ID[id]
    if r then
      local un = RR.Unverified(id)
      lines[#lines + 1] = { text = id .. '  ' .. r.text .. '  (' .. r.src .. '; ' .. r.status .. ')',
        r = un and 0.88 or 0.62, g = un and 0.66 or 0.82, b = un and 0.23 or 0.66 }
    end
  end
  return lines
end

---------------------------------------------------------------------------
-- Fastest: one route step
---------------------------------------------------------------------------

local function dungeonCount(name)
  for _, d in ipairs(RR.DUNGEONS) do if d.name == name then return d.count end end
  return nil
end

--- step text, now text, status for a route step
function V.StepFacts(s)
  local parts, lastSkill, runs, zones, level = {}, nil, nil, nil, nil
  for _, p in ipairs(s.parts) do
    if p.kind == 'level' then level = p
    elseif p.kind == 'skill' then lastSkill = p
    elseif p.kind == 'runs' then runs = p
    elseif p.kind == 'zones' then zones = p end
  end
  local text, now, status
  if lastSkill then
    local sk = (lastSkill.learn and ('Learn ' .. lastSkill.profession .. ', ') or (lastSkill.profession .. ' '))
      .. lastSkill.from .. ' -> ' .. lastSkill.to
    if level then text = 'Level ' .. level.to .. ', then ' .. lastSkill.profession .. ' ' .. lastSkill.to else text = sk end
    now = tostring(lastSkill.from) .. (type(lastSkill.max) == 'number' and lastSkill.max > 0 and ('/' .. lastSkill.max) or '')
  elseif runs then
    local count = dungeonCount(runs.name) or runs.left
    text = (level and ('Level ' .. level.to .. ', then ') or '') .. runs.name
    now = runs.unknown and ('?/' .. count) or ((count - runs.left) .. '/' .. count)
    if runs.unknown then status = 'unknown' elseif runs.left < count then status = 'progress' end
  elseif zones then
    text = 'Explorer'
    now = (zones.total - zones.left) .. '/' .. zones.total
    if zones.left < zones.total then status = 'progress' end
  elseif level then
    text = 'Level ' .. level.to .. ' (' .. table.concat(s.earns, ', ') .. ')'
    now = tostring(level.from)
  end
  if not status then
    if level and (lastSkill or runs) then status = 'gate' else status = 'open' end     -- training alone is no gate
  end
  return text or '?', now or '', status
end

local function routeRow(s, i, now)
  local text, nowText, status = V.StepFacts(s)
  local un = EI.Route.UnverifiedRules(s)
  local who = V.Who(s.row, now, s.atLevel)
  local timeLine = hours(s.hours) .. ' [estimate]' .. (((s.restHours or 0) > 0.05) and (' - rest saves ' .. hours(s.restHours)) or '')
  return {
    index = i, who = who, step = text, now = nowText, pts = '+' .. (s.points or 1), time = hours(s.hours), status = status,
    unverified = #un > 0, kind = s.kind, guid = s.row and s.row.guid,
    tooltip = tooltip(who.name .. ' ' .. who.classText .. ' ' .. tostring(who.level) .. ': ' .. text, timeLine, s.rules),
    route = s,
  }
end

local function routeCard(s, now)
  local r = routeRow(s, 1, now)
  local title
  local level, skill = nil, nil
  for _, p in ipairs(s.parts) do if p.kind == 'level' then level = p elseif p.kind == 'skill' then skill = p end end
  if level and skill then
    title = 'Reach level ' .. level.to .. ', then ' .. skill.profession .. ' ' .. skill.from .. ' -> ' .. skill.to
  else
    title = r.step
  end
  local gate = nil
  if s.train then
    local tr
    for _, x in pairs(RR.TRAIN) do if x.rank == s.train then tr = x end end
    if tr then gate = 'gate: ' .. s.train .. ' needs level ' .. tr.level .. ' (L-4)' end
  end
  return { who = r.who, title = title, earns = '+' .. (s.points or 1) .. ' ' .. table.concat(s.earns, ', '),
    time = r.time, gate = gate, unverified = r.unverified, tooltip = r.tooltip }
end

---------------------------------------------------------------------------
-- My plan: one saved step
---------------------------------------------------------------------------

local function findProf(r, name)
  if type(r.professions) ~= 'table' then return nil end
  for _, p in ipairs(r.professions) do
    if type(p.name) == 'string' and string.lower(p.name) == string.lower(name) then return p end
  end
  return false
end

local function mineRow(g, ctx)
  local row = { index = g.n, pts = '', kind = g.kind, note = g.note, guid = g.guid, saved = g, editable = true }
  if g.kind == 'challenge' then
    row.who = { name = 'Account', classText = '', isPlayer = false }
    local ch = ctx.legacy and ctx.legacy.challengeById and ctx.legacy.challengeById[g.id]
    if not ctx.unlocked then
      row.step, row.status, row.now = 'Challenge ' .. g.id, 'unknown', 'locked'
    elseif not ch then
      row.step, row.status, row.now = 'Challenge ' .. g.id, 'unknown', '?'
    else
      row.step = tostring(ch.name)
      local d, n = 0, (type(ch.criteria) == 'table') and #ch.criteria or 0
      for _, c in ipairs(ch.criteria or {}) do if c.completed == true then d = d + 1 end end
      row.now = n > 0 and (d .. '/' .. n) or ''
      if ch.completed == true then row.status = 'done' elseif d > 0 then row.status = 'progress' else row.status = 'open' end
      if row.status ~= 'done' and n > 0 then row.hours = (n - d) * RR.HOURS_PER_RUN; row.pts = '+1' end
    end
    row.editable = false
    row.rules = { 'L-7', 'L-16' }
  else
    local r = g.row
    row.who = V.Who(r, ctx.now)
    if g.kind == 'level' then
      row.step, row.target, row.field = 'Level', g.level, 'level'
      if type(r.level) ~= 'number' then row.status, row.now = 'unknown', '?'
      else
        row.now = tostring(r.level)
        if r.level >= g.level then row.status = 'done'
        else
          row.status = 'open'
          row.hours = EI.Route.LevelHours(EI.Route.State(r, ctx.now, ctx.rates), g.level)
          for _, m in ipairs(R.CLASS_MILESTONES) do if m > r.level and m <= g.level then row.pts = '+1' end end
        end
      end
      row.rules = { 'L-15', 'L-16', 'L-17' }
    elseif g.kind == 'skill' then
      row.step, row.target, row.field = g.profession, g.skill, 'skill'
      local p = findProf(r, g.profession)
      if p == nil then row.status, row.now = 'unknown', '?'
      else
        local skill = p and p.skill or 0
        row.now = tostring(skill) .. ((p and type(p.max) == 'number' and p.max > 0) and ('/' .. p.max) or '')
        if skill >= g.skill then row.status = 'done'
        else
          row.status = (p and p.max and p.max < g.skill) and 'gate' or 'open'
          row.hours = EI.Route.SkillHours(skill, g.skill)
          if R.Craft({ name = g.profession }) then
            for _, m in ipairs(R.CRAFT_MILESTONES) do if m > skill and m <= g.skill then row.pts = '+1' end end
          end
        end
      end
      row.rules = { 'L-4', 'L-16' }
    else
      row.step, row.target, row.field = 'Rested', g.rested, 'rested'
      local v = EI.Next.RestLevels(r, ctx.now)
      if not v then row.status, row.now = 'unknown', '?'
      else
        row.now = string.format('%.2f', v)
        if v >= g.rested then row.status = 'done' else row.status = 'open'; row.hours = (g.rested - v) / R.REST.per8h * 8 end
      end
      row.rules = { 'L-14' }
    end
  end
  row.time = row.hours and hours(row.hours) or ''
  local un = {}
  for _, id in ipairs(row.rules or {}) do if RR.Unverified(id) then un[#un + 1] = id end end
  row.unverified = #un > 0 and row.status ~= 'done'
  local label = row.step .. (row.target and (' ' .. row.target) or '')
  row.tooltip = tooltip(row.who.name .. ': ' .. label, (row.time ~= '' and (row.time .. ' [estimate]') or row.status), row.rules)
  return row
end

local function mineCard(row)
  local title = row.step .. (row.target and (' ' .. row.target) or '') .. (row.now ~= '' and (' - now ' .. row.now) or '')
  return { who = row.who, title = title, earns = row.pts ~= '' and (row.pts .. ' Legacy point') or 'no Legacy point by itself',
    time = row.time, unverified = row.unverified, tooltip = row.tooltip, index = row.index }
end

---------------------------------------------------------------------------
-- the whole view
---------------------------------------------------------------------------

--- ctx: mode ('auto' | 'mine'), res (Route.Build), plan (Plan.Load), rows, now, rates, unlocked, legacy, legacyWhy
function V.Build(ctx)
  local res = ctx.res
  local view = { mode = ctx.mode, rows = {}, problems = ctx.plan and ctx.plan.problems or {} }
  local n, u = RR.Counts()
  view.target = res and (res.earned .. ' / ' .. res.target) or '?'
  view.targetKind = res and res.targetKind
  local reward = res and RR.NextReward(res.earned)
  view.footer = { reward = reward and ('Next reward at ' .. reward.at .. ': ' .. reward.name) or 'All rewards reached',
    rules = 'Rules: ' .. n .. ', ' .. u .. ' unverified' }
  if ctx.legacyWhy == 'reading' and ctx.unlocked then
    view.note = 'Reading Legacy challenges...'
  elseif ctx.legacyWhy == 'combat' then
    view.note = ctx.legacy and 'Legacy values from before combat' or 'Legacy not read (in combat): counts inferred'
  elseif ctx.legacyWhy == 'failed' then
    view.note = 'UNEXPECTED: the Legacy read failed; counts inferred'
  elseif res and res.earnedSrc == 'inferred' and res.unlocked then
    view.note = 'Counts inferred (no Legacy read)'
  elseif res and not res.unlocked then
    view.note = 'Legacy not unlocked yet'
  end
  if ctx.mode == 'mine' then
    local met = 0
    for _, g in ipairs(ctx.plan.steps) do
      local row = mineRow(g, ctx)
      if row.status == 'done' then met = met + 1 end
      view.rows[#view.rows + 1] = row
      if not view.card and row.status ~= 'done' then view.card = mineCard(row) end
    end
    view.footer.total = #ctx.plan.steps .. ' steps - ' .. met .. ' met' ..
      ((#view.problems > 0) and (' - ' .. #view.problems .. ' skipped (/ei next lists them)') or '')
    if ctx.plan.total == 0 then view.empty = 'My plan is empty: right-click a Fastest row, or /ei plan copy.' end
    if not view.card and ctx.plan.total > 0 then view.empty = 'Every step in my plan is met.' end
    return view
  end
  if not res or #res.states == 0 then view.empty = 'No characters known yet.'; return view end
  for i, s in ipairs(res.steps) do
    if i == 1 then view.card = routeCard(s, ctx.now) else view.rows[#view.rows + 1] = routeRow(s, i, ctx.now) end
  end
  local total = 0
  for _, s in ipairs(res.steps) do total = total + s.hours end
  if res.earned >= res.target then
    view.empty = 'Target reached: ' .. res.earned .. ' of ' .. res.target .. '.'
    view.footer.total = ''
  elseif res.left == 0 then
    view.footer.total = string.format('Route: %d steps, ~%.0f h', #res.steps, total)
  else
    view.footer.total = string.format('Route stops at %d of %d', res.reached, res.target)
  end
  return view
end
