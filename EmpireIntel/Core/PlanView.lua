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

-- D-063 item 6: the badge shows the realm type. No game call names it (EI-E-31: none of the C_GameRules functions
-- called says it); the realm name ends with it ("... PvE", EI-E-06, EI-E-31), for the played character
-- (GetRealmName) and for DataStore's alts (the realm part of its key). Hardcore comes from the game
-- (C_GameRules.IsHardcoreActive, the ruleset field). The type is labelled [inferred] from the name.
V.REALM_TYPES = {
  { pat = 'rp%-?pvp$', text = 'RP-PvP', kind = 'pvp' }, { pat = 'rp%-?pve$', text = 'RP-PvE', kind = 'normal' },
  { pat = '[^%a]rp$', text = 'RP-PvE', kind = 'normal' }, { pat = 'pvp$', text = 'PvP', kind = 'pvp' },
  { pat = 'pve$', text = 'PvE', kind = 'normal' },
}

--- The realm-type badge { text, kind, why } from the realm name and the ruleset.
function V.RealmType(realm, ruleset)
  if ruleset == 'hardcore' then return { text = 'Hardcore', kind = 'hard', why = 'Hardcore: C_GameRules.IsHardcoreActive() [game]' } end
  if type(realm) == 'string' then
    local n = string.lower((string.gsub(realm, '%s+$', '')))
    for _, t in ipairs(V.REALM_TYPES) do
      if string.find(n, t.pat) then
        return { text = t.text, kind = t.kind, why = 'Realm type ' .. t.text .. ': from the realm name [inferred]; no game call gives it (EI-E-31)' }
      end
    end
  end
  return { text = 'Realm type ?', kind = 'unknown', why = 'Realm type unknown: the realm name does not end with PvE, PvP, RP or RP-PvP' }
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
    ruleset = V.RealmType(row.realm, row.ruleset),
    seen = row.isPlayer and 'played now' or ago(row.at, now),
  }
end

--- A selected card's tooltip plus how to go back to Up next (D-066).
function V.BackHint(tip)
  local out = {}
  for i, l in ipairs(tip or {}) do out[i] = l end
  out[#out + 1] = { text = 'Click the card to go back to Up next.', r = 0.65, g = 0.66, b = 1 }
  return out
end

--- A card tooltip plus the realm-type line (D-063 item 6).
function V.WithRealm(tip, who)
  if not (who and who.ruleset and who.ruleset.why) then return tip end
  local out = {}
  for i, l in ipairs(tip) do out[i] = l end
  out[#out + 1] = { text = who.ruleset.why }
  return out
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

-- D-063 item 9: NOW is today's value in both modes (the character's real level, skill or the account's dungeon
-- progress); the value at that point of the route is in the tooltip.
local function todayNow(s)
  local row = s.row or {}
  for i = #s.parts, 1, -1 do
    local p = s.parts[i]
    if p.kind == 'skill' then
      for _, x in ipairs(type(row.professions) == 'table' and row.professions or {}) do
        if type(x.name) == 'string' and (R.Craft(x) or x.name) == p.profession and type(x.skill) == 'number' then
          return tostring(x.skill) .. ((type(x.max) == 'number' and x.max > 0) and ('/' .. x.max) or '')
        end
      end
      return '-'                                         -- not learned yet
    end
  end
  for _, p in ipairs(s.parts) do if p.kind == 'runs' or p.kind == 'zones' then return nil end end   -- already today's
  return type(row.level) == 'number' and tostring(row.level) or '?'
end
V.TodayNow = todayNow

-- D-063 item 9: a dungeon challenge is account-wide (L-7): its row says "Account" in both modes; the character
-- the route runs it on is named in the step (when it must level first) and in the tooltip.
local ACCOUNT = { name = 'Account', classText = '', isPlayer = false, account = true }

local function firstName(row) return (string.match(tostring(row.name or '?'), '^(%S+)')) end

local function routeRow(s, i, now)
  local text, routeNow, status = V.StepFacts(s)
  local un = EI.Route.UnverifiedRules(s)
  local who = V.Who(s.row, now)
  local nowText = todayNow(s) or routeNow
  local timeLine = hours(s.hours) .. ' [estimate]' .. (((s.restHours or 0) > 0.05) and (' - rest saves ' .. hours(s.restHours)) or '')
  local title = who.name .. ' ' .. who.classText .. ' ' .. tostring(who.level) .. ': ' .. text
  local extra = {}
  if s.kind == 'dungeon' then
    local lvl, runs
    for _, p in ipairs(s.parts) do if p.kind == 'level' then lvl = p elseif p.kind == 'runs' then runs = p end end
    local name = runs and runs.name or text
    text = lvl and ('Level ' .. lvl.to .. ' on ' .. firstName(s.row) .. ', then ' .. name) or name
    extra[#extra + 1] = { text = 'Account-wide challenge (L-7); the route runs it on ' .. who.name .. ' ' .. who.classText .. ' ' .. tostring(who.level) }
    title = 'Account: ' .. text
    who = ACCOUNT
  end
  if nowText ~= routeNow and routeNow ~= '' then
    extra[#extra + 1] = { text = 'NOW is today\'s value; at this point of the route: ' .. routeNow }
  end
  local tip = tooltip(title, timeLine, s.rules)
  for k, l in ipairs(extra) do table.insert(tip, 1 + k, l) end
  return {
    index = i, who = who, step = text, now = nowText, pts = '+' .. (s.points or 1), time = hours(s.hours), status = status,
    unverified = #un > 0, kind = s.kind, guid = (s.kind ~= 'dungeon') and s.row and s.row.guid or nil,
    tooltip = tip, route = s,
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
  -- the card names the character to play, also for an account-wide dungeon challenge (its runner)
  local who = r.who.account and V.Who(s.row, now) or r.who
  return { who = who, title = title, earns = '+' .. (s.points or 1) .. ' ' .. table.concat(s.earns, ', '),
    time = r.time, gate = gate, unverified = r.unverified, tooltip = V.WithRealm(r.tooltip, who) }
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
    row.who = ACCOUNT
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
        -- D-065 finding 10: time and points from the end of this character's earlier level steps
        local prior = ctx.reach and ctx.reach.level[g.guid]
        local from = (prior and prior.v > r.level) and prior.v or r.level
        if r.level >= g.level then row.status = 'done'
        elseif from >= g.level then row.status, row.coveredBy = 'covered', prior.n
        else
          row.status = 'open'
          local st = EI.Route.State(r, ctx.now, ctx.rates)
          local h = EI.Route.LevelHours(st, g.level)
          if from > r.level then h = h - (EI.Route.LevelHours(st, from)) end
          row.hours = math.max(0, h)
          local n = 0
          for _, m in ipairs(R.CLASS_MILESTONES) do if m > from and m <= g.level then n = n + 1 end end
          if n > 0 then row.pts = '+' .. n end
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
        -- D-065 finding 10: time and points from the end of the earlier steps of this character and profession
        local prior = ctx.reach and ctx.reach.skill[g.guid .. '|' .. g.profession]
        local from = (prior and prior.v > skill) and prior.v or skill
        if skill >= g.skill then row.status = 'done'
        elseif from >= g.skill then row.status, row.coveredBy = 'covered', prior.n
        else
          row.status = (p and p.max and p.max < g.skill) and 'gate' or 'open'
          row.hours = EI.Route.SkillHours(from, g.skill)
          if R.Craft({ name = g.profession }) then
            local n = 0
            for _, m in ipairs(R.CRAFT_MILESTONES) do if m > from and m <= g.skill then n = n + 1 end end
            if n > 0 then row.pts = '+' .. n end
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
  -- D-065 finding 10: a step an earlier step already reaches
  if row.status == 'covered' then row.hours, row.pts = nil, '' end
  -- D-063 item 1: a skill step whose training gate has no level step before it in my plan
  local gateNeed = ctx.gates and ctx.gates[g.n]
  if gateNeed and row.status ~= 'done' and row.status ~= 'unknown' and row.status ~= 'covered' then row.status = 'gate' end
  -- D-063 item 4: a step of an ignored character stays in my plan, marked, and is not "up next"
  if g.guid and ctx.ignore and ctx.ignore[g.guid] then row.ignored, row.status, row.hours, row.pts = true, 'ignored', nil, '' end
  row.time = row.hours and hours(row.hours) or ''
  local un = {}
  for _, id in ipairs(row.rules or {}) do if RR.Unverified(id) then un[#un + 1] = id end end
  row.unverified = #un > 0 and row.status ~= 'done' and not row.ignored
  local label = row.step .. (row.target and (' ' .. row.target) or '')
  row.tooltip = tooltip(row.who.name .. ': ' .. label, (row.time ~= '' and (row.time .. ' [estimate]') or row.status), row.rules)
  local add = {}
  if row.ignored then add[#add + 1] = { text = 'Ignored: ' .. row.who.name .. ' is left out of Fastest. Right-click: Unignore, or Remove step.', r = 0.88, g = 0.66, b = 0.23 } end
  if gateNeed and row.status == 'gate' then
    add[#add + 1] = { text = 'Needs level ' .. gateNeed .. ' first (L-4); my plan has no level step for it before this one.', r = 0.88, g = 0.66, b = 0.23 }
  end
  if row.status == 'covered' then add[#add + 1] = { text = 'Covered by step ' .. tostring(row.coveredBy) .. ': that step already reaches this target; no time or points here.' } end
  if g.note and g.note ~= '' then add[#add + 1] = { text = 'Note: ' .. g.note, r = 1, g = 1, b = 1 } end
  for k, l in ipairs(add) do table.insert(row.tooltip, 1 + k, l) end
  return row
end

local function mineCard(row)
  local title = row.step .. (row.target and (' ' .. row.target) or '') .. (row.now ~= '' and (' - now ' .. row.now) or '')
  return { who = row.who, title = title, earns = row.pts ~= '' and (row.pts .. ' Legacy point') or 'no Legacy point by itself',
    time = row.time, unverified = row.unverified, tooltip = V.WithRealm(row.tooltip, row.who), index = row.index,
    gate = (row.note and row.note ~= '') and ('Note: ' .. row.note) or nil }
end

---------------------------------------------------------------------------
-- the whole view
---------------------------------------------------------------------------

-- D-063 item 5: the target button says what it counts toward; its tooltip explains the three choices.
function V.TargetLabel(res)
  local tip = { { text = 'Target' },
    { text = 'Next point: the route to your next Legacy point.' },
    { text = 'Cap: ' .. RR.DEFAULT_TARGET .. ' points, the spending cap per character (L-12, unverified).' },
    { text = 'Next reward: the next reward on the track (15 Air Rifle, 25 Spectral Bear Cub, 40 Tabard, 55 Reins; L-13).' },
    { text = 'Click to change: Cap -> Next reward -> Next point.', r = 0.65, g = 0.66, b = 1 } }
  if not res then return '?', tip end
  local nums = res.earned .. '/' .. res.target
  local label
  if res.targetKind == 'next' then label = 'Next point ' .. nums
  elseif res.targetKind == 'reward' then label = 'Next reward ' .. nums
  elseif res.target == RR.DEFAULT_TARGET then label = 'Cap ' .. nums
  else label = 'Target ' .. nums end
  tip[1] = { text = 'Target: ' .. label .. ' (' .. (res.earnedSrc == 'game' and 'earned points from the game' or 'earned points inferred') .. ')' }
  return label, tip
end

--- ctx: mode ('auto' | 'mine'), res (Route.Build), plan (Plan.Load), rows, now, rates, unlocked, legacy, legacyWhy
function V.Build(ctx)
  local res = ctx.res
  local view = { mode = ctx.mode, rows = {}, problems = ctx.plan and ctx.plan.problems or {} }
  local n, u = RR.Counts()
  view.target, view.targetTip = V.TargetLabel(res)
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
    local met, ignored = 0, 0
    local byGuid = {}
    for _, r in ipairs(ctx.rows or {}) do if r.guid then byGuid[r.guid] = r end end
    ctx.gates = {}
    for _, v in ipairs(EI.Plan.Violations(ctx.plan.steps, byGuid)) do ctx.gates[v.dep.n] = v.need end
    ctx.reach = { level = {}, skill = {} }
    local covered = 0
    for _, g in ipairs(ctx.plan.steps) do
      local row = mineRow(g, ctx)
      if row.status == 'done' then met = met + 1 end
      if row.status == 'covered' then covered = covered + 1 end
      -- what this step reaches, for the steps after it (an ignored character's steps are not planned)
      if not row.ignored and g.guid and (g.kind == 'level' or g.kind == 'skill') then
        local tbl, key, v = ctx.reach.level, g.guid, g.level
        if g.kind == 'skill' then tbl, key, v = ctx.reach.skill, g.guid .. '|' .. g.profession, g.skill end
        if not tbl[key] or v > tbl[key].v then tbl[key] = { v = v, n = g.n } end
      end
      if row.ignored then ignored = ignored + 1 end
      view.rows[#view.rows + 1] = row
      if not view.card and row.status ~= 'done' and row.status ~= 'covered' and not row.ignored then view.card = mineCard(row) end
      -- D-066: the card follows the selected row (any row, any character)
      if ctx.selected and ctx.selected.mode == 'mine' and ctx.selected.key == row.index then
        row.selected = true
        view.selectedCard = mineCard(row)
        view.selectedCard.label = 'SELECTED - MY PLAN STEP ' .. tostring(row.index)
        view.selectedCard.tooltip = V.BackHint(view.selectedCard.tooltip)
      end
    end
    view.footer.total = #ctx.plan.steps .. ' steps - ' .. met .. ' met' .. ((covered > 0) and (' - ' .. covered .. ' covered') or '')
      .. ((ignored > 0) and (' - ' .. ignored .. ' ignored') or '') ..
      ((#view.problems > 0) and (' - ' .. #view.problems .. ' skipped (/ei next lists them)') or '')
    if ctx.plan.total == 0 then view.empty = 'My plan is empty: right-click a Fastest row, or /ei plan copy.' end
    if not view.card and ctx.plan.total > 0 then view.empty = 'Every step in my plan is met.' end
    if view.selectedCard then view.card, view.selected = view.selectedCard, true end
    return view
  end
  if not res or #res.states == 0 then view.empty = 'No characters known yet.'; return view end
  for i, s in ipairs(res.steps) do
    if i == 1 then view.card = routeCard(s, ctx.now) else view.rows[#view.rows + 1] = routeRow(s, i, ctx.now) end
    if i > 1 and ctx.selected and ctx.selected.mode == 'auto' and ctx.selected.key == i then
      view.rows[#view.rows].selected = true
      view.selectedCard = routeCard(s, ctx.now)
      view.selectedCard.label = 'SELECTED - STEP ' .. i
      view.selectedCard.tooltip = V.BackHint(view.selectedCard.tooltip)
    end
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
  if res.excluded and res.excluded.ignored > 0 then
    view.footer.total = view.footer.total .. (view.footer.total ~= '' and ' - ' or '') .. res.excluded.ignored .. ' ignored'
  end
  if view.selectedCard then view.card, view.selected = view.selectedCard, true end
  return view
end
