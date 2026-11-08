local ADDON, EI = ...
-- EmpireIntel / Core / Next.lua                                          (Phase 2, increment P2-4)
--
-- PURPOSE
--   /ei next: up to 10 suggestions, from the user's plan (Core/Plan.lua) or, without one, the FR-PRE-4 defaults
--   (Phase2_Plan.md section 7, approved Q-P2-4 a-e, D-052).
--
-- RULES
--   * The characters are the ones /ei alts lists (Views.Collect: own records, DataStore, the player's live values).
--   * Legacy lock rule (D-052): before any known character reaches 25, Legacy is not available: a challenges goal
--     shows "Legacy not unlocked yet" (never met), no Legacy function is called, and the defaults lead with reach 25.
--     Once any character has reached 25, Legacy is available on every character, including ones below 25.
--   * The only Legacy reads are P3-1's (Platform/Legacy.lua), on command, and only for an account challenges goal.
--   * Unknown is never shown as met. Every projection says [estimate]. Nothing is saved.

EI = EI or {}
local P = EI.Platform
local R = EI.Rules
assert(P and P.Legacy and R and EI.Plan and EI.Views and EI.Commands and EI.LegacyView,
  'load order: Platform/Legacy, Rules, Commands, Views, LegacyView, Plan, Next')

local N = {}
EI.Next = N

N.MAX_LINES = 10
N.REST_MIN = 0.5            -- default: characters with at least this many levels of rested XP (Q-P2-4d)
N.CRAFT_WITHIN = 25         -- default: crafting milestones within this many skill points (Q-P2-4d)
N.CLASS_LINES = 3           -- default: class milestones shown after the unlock (Q-P2-4e)

local function className(c) return R.CLASS_NAMES[c] or tostring(c or 'class?') end
local function plural(n, word) return n .. ' ' .. word .. (n == 1 and '' or 's') end

local function head(r)
  return string.format('%s %s %s', tostring(r.name or 'name unknown'), className(r.class), tostring(r.level or '?'))
end

local function srcTag(r)
  if r.src == 'datastore' then return ' [datastore, ' .. EI.Commands.Ago(r.at) .. ']' end
  return ''
end

--- Unlocked = any known character at level 25 or higher (EI-E-02, the /ei unlock test).
function N.Unlocked(rows)
  for _, r in ipairs(rows) do
    if type(r.level) == 'number' and r.level >= R.UNLOCK_LEVEL then return true end
  end
  return false
end

--- Rested XP now, in levels: value, estimated (bool); or nil plus a reason.
function N.RestLevels(r, now)
  if type(r.level) == 'number' and r.level >= R.MAX_LEVEL then return nil, 'max level, no rested XP' end
  local bar = r.xpMax
  if type(bar) ~= 'number' or bar <= 0 then
    return nil, 'XP bar not measured at level ' .. tostring(r.level or '?')
  end
  if r.liveRest then return (type(r.rest) == 'number' and r.rest or 0) / bar, false end
  local p = R.ProjectRest(r.rest, bar, r.resting, r.restAt, now, r.src == 'self')
  if not p then return nil, 'no rested XP reading' end
  return p / bar, true
end

local function restText(v, est)
  if est then return string.format('about %.2f levels rested [estimate]', v) end
  return string.format('%.2f levels rested now', v)
end

-- the account's best level per class and best skill per craft (account-wide challenges, EI-E-27)
local function bests(rows)
  local lvl, craft = {}, {}
  for _, r in ipairs(rows) do
    if r.class and type(r.level) == 'number' and (not lvl[r.class] or r.level > lvl[r.class].level) then lvl[r.class] = r end
    for _, p in ipairs(type(r.professions) == 'table' and r.professions or {}) do
      local c = R.Craft(p)
      if c and type(p.skill) == 'number' and (not craft[c] or p.skill > craft[c].skill) then
        craft[c] = { row = r, skill = p.skill, max = p.max }
      end
    end
  end
  return lvl, craft
end

-- the milestones between the account's best and the target, not yet earned: ' -> earns A, B (2 Legacy points)'
local function earns(milestones, titles, best, target, what)
  local names = {}
  for _, m in ipairs(milestones) do
    if m > (best or 0) and m <= target then names[#names + 1] = titles[m] .. ' ' .. what end
  end
  if #names == 0 then return '' end
  return ' -> earns ' .. table.concat(names, ', ') .. ' (' .. plural(#names, 'Legacy point') .. ')'
end

local function findProf(r, name)
  if type(r.professions) ~= 'table' then return nil, 'professions not recorded' end
  for _, p in ipairs(r.professions) do
    if type(p.name) == 'string' and string.lower(p.name) == string.lower(name) then return p end
  end
  if r.src == 'datastore' then return nil, 'DataStore keeps primary professions only' end
  return false
end

local function withNote(text, g)
  if g.note then return text .. ' (note: ' .. g.note .. ')' end
  return text
end

---------------------------------------------------------------------------
-- one plan goal: returns 'met' | line (unmet or unknown)
---------------------------------------------------------------------------
local function goalLine(g, ctx)
  if g.kind == 'challenges' then
    local t = 'Account -> ' .. plural(g.challenges, 'Legacy challenge') .. ': '
    if not ctx.unlocked then return withNote(t .. 'Legacy not unlocked yet', g) end
    local out = ctx.legacy
    if ctx.legacyWhy == 'combat' or (out and out.combat) then return withNote(t .. 'not read (in combat); try /ei next again after combat', g) end
    if ctx.legacyWhy == 'busy' then return withNote(t .. 'not read (a Legacy read is already running); try /ei next again', g) end
    local s = out and out.summary
    if not s or out.error then return withNote(t .. 'unknown (the Legacy read failed)', g) end
    if not s.recognized then return withNote(t .. 'unknown (no Legacy reward text recognized)', g) end
    if s.completed >= g.challenges then return 'met' end
    local closest, explorer = EI.LegacyView.Closest(out, 1)
    t = t .. string.format('%d done, %d to go', s.completed, g.challenges - s.completed)
    if closest[1] then t = t .. '; closest: ' .. closest[1] end
    return withNote(t, g)
  end
  local r = g.row
  local h = head(r) .. ' -> '
  if g.kind == 'level' then
    h = h .. 'level ' .. g.level .. ': '
    if type(r.level) ~= 'number' then return withNote(h .. 'unknown (level not recorded)', g) .. srcTag(r) end
    if r.level >= g.level then return 'met' end
    local t = h .. plural(g.level - r.level, 'level') .. ' to go'
    local v, est = N.RestLevels(r, ctx.now)
    if v then t = t .. '; ' .. restText(v, est) end
    local best = r.class and ctx.bestLevel[r.class]
    t = t .. earns(R.CLASS_MILESTONES, R.CLASS_TITLES, best and best.level, g.level, className(r.class))
    return withNote(t, g) .. srcTag(r)
  elseif g.kind == 'skill' then
    h = h .. g.profession .. ' ' .. g.skill .. ': '
    local p, why = findProf(r, g.profession)
    if p == nil then return withNote(h .. 'unknown (' .. why .. ')', g) .. srcTag(r) end
    local skill = p and p.skill or 0
    if p and type(skill) ~= 'number' then return withNote(h .. 'unknown (skill not recorded)', g) .. srcTag(r) end
    if skill >= g.skill then return 'met' end
    local t
    if not p then
      t = h .. 'not learned yet; ' .. g.skill .. ' to go'
    else
      t = h .. 'now ' .. skill .. ((type(p.max) == 'number' and p.max > 0) and ('/' .. p.max) or '') .. ', ' .. (g.skill - skill) .. ' to go'
      if type(p.max) == 'number' and p.max > 0 and p.max < g.skill then t = t .. '; train to raise max ' .. p.max end
    end
    if R.Craft({ name = g.profession }) then
      local best = ctx.bestCraft[g.profession]
      t = t .. earns(R.CRAFT_MILESTONES, R.CRAFT_TITLES, best and best.skill, g.skill, R.CRAFT_PERSON[g.profession] or g.profession)
    end
    return withNote(t, g) .. srcTag(r)
  else
    h = h .. string.format('rested %.2f levels: ', g.rested)
    local v, est = N.RestLevels(r, ctx.now)
    if not v then return withNote(h .. 'unknown (' .. tostring(est) .. ')', g) .. srcTag(r) end
    if v >= g.rested then return 'met' end
    local hours = (g.rested - v) / R.REST.per8h * 8
    hours = math.max(1, math.floor(hours + 0.5))
    local t = h .. (est and string.format('about %.2f now [estimate]', v) or string.format('%.2f now', v))
      .. string.format('; about %d h more in an inn [estimate]', hours)
    return withNote(t, g) .. srcTag(r)
  end
end

---------------------------------------------------------------------------
-- the defaults (FR-PRE-4)
---------------------------------------------------------------------------
local function defaults(ctx)
  local list = {}
  local rows = ctx.rows
  if not ctx.unlocked then
    local best = nil
    for _, r in ipairs(rows) do
      if type(r.level) == 'number' and (not best or r.level > best.level) then best = r end
    end
    if best then
      list[#list + 1] = string.format('Reach 25: %s -> 25 (%s to go) unlocks Legacy for the account', head(best),
        plural(R.UNLOCK_LEVEL - best.level, 'level')) .. srcTag(best)
    end
  else
    local cand = {}
    for c, r in pairs(ctx.bestLevel) do
      local nextM = R.Next(R.CLASS_MILESTONES, r.level)
      if nextM then cand[#cand + 1] = { r = r, m = nextM, gap = nextM - r.level, c = c } end
    end
    table.sort(cand, function(a, b) if a.gap ~= b.gap then return a.gap < b.gap end return a.c < b.c end)
    for i = 1, math.min(N.CLASS_LINES, #cand) do
      local x = cand[i]
      list[#list + 1] = string.format('Class milestone: %s -> %d (%s) -> %s %s (1 Legacy point)', head(x.r), x.m,
        plural(x.gap, 'level'), R.CLASS_TITLES[x.m], className(x.r.class)) .. srcTag(x.r)
    end
  end
  local rested = {}
  for _, r in ipairs(rows) do
    local v, est = N.RestLevels(r, ctx.now)
    if v and v >= N.REST_MIN then rested[#rested + 1] = { r = r, v = v, est = est } end
  end
  table.sort(rested, function(a, b) return a.v > b.v end)
  for _, x in ipairs(rested) do
    list[#list + 1] = string.format('Rested: %s has %s: play it next', head(x.r), restText(x.v, x.est)) .. srcTag(x.r)
  end
  local near, closest = {}, nil
  for _, c in ipairs(R.CRAFTS) do
    local b = ctx.bestCraft[c.name]
    if b then
      local nextM = R.Next(R.CRAFT_MILESTONES, b.skill)
      if nextM then
        local s = string.format('%s %s %d%s -> %d (%d to go', tostring(b.row.name), c.name, b.skill,
          (type(b.max) == 'number' and b.max > 0) and ('/' .. b.max) or '', nextM, nextM - b.skill)
        if type(b.max) == 'number' and b.max > 0 and b.max < nextM then s = s .. '; train to raise max ' .. b.max end
        s = s .. ')'
        local x = { s = s, gap = nextM - b.skill, title = R.CRAFT_TITLES[nextM] .. ' ' .. (R.CRAFT_PERSON[c.name] or c.name) }
        if x.gap <= N.CRAFT_WITHIN then near[#near + 1] = x end
        if not closest or x.gap < closest.gap then closest = x end
      end
    end
  end
  table.sort(near, function(a, b) return a.gap < b.gap end)
  for _, x in ipairs(near) do list[#list + 1] = 'Crafting: ' .. x.s .. ' -> ' .. x.title .. ' (1 Legacy point)' end
  if #near == 0 then
    if closest then
      list[#list + 1] = 'Crafting: nothing within ' .. N.CRAFT_WITHIN .. ' points of a milestone (closest: ' .. closest.s .. ')'
    else
      list[#list + 1] = 'Crafting: no crafting skill recorded yet'
    end
  end
  return list
end

---------------------------------------------------------------------------
-- the whole answer (pure: no game call, no print)
---------------------------------------------------------------------------
local function limited(lines, list)
  for i, s in ipairs(list) do
    if i > N.MAX_LINES then
      lines[#lines + 1] = '... and ' .. (#list - N.MAX_LINES) .. ' more'
      break
    end
    lines[#lines + 1] = i .. '. ' .. s
  end
end

--- ctx: rows, plan (Plan.Load), unlocked, now, legacy (a finished read or nil), legacyWhy ('busy' | 'combat' | nil)
function N.Lines(ctx)
  local lines = {}
  ctx.bestLevel, ctx.bestCraft = bests(ctx.rows)
  local plan = ctx.plan
  for _, p in ipairs(plan.problems) do lines[#lines + 1] = p end
  local lockNote = ctx.unlocked and '' or '; Legacy not unlocked yet'
  if plan.state == 'ok' and plan.total > 0 then
    local list, met = {}, 0
    for _, g in ipairs(plan.goals) do
      local l = goalLine(g, ctx)
      if l == 'met' then met = met + 1 else list[#list + 1] = l end
    end
    lines[#lines + 1] = string.format('next (your plan: %s; %d met, %d skipped%s):', plural(plan.total, 'goal'), met,
      plan.skipped, lockNote)
    if #list == 0 then
      if met == plan.total then
        lines[#lines + 1] = 'All ' .. plural(plan.total, 'goal') .. ' in your plan are met.'
      else
        lines[#lines + 1] = 'No goals left to show.'
      end
    end
    limited(lines, list)
    return lines
  end
  if plan.state == 'ok' then lines[#lines + 1] = 'Your plan has no goals.' end
  if #ctx.rows == 0 then
    lines[#lines + 1] = 'next: no characters known yet.'
    return lines
  end
  lines[#lines + 1] = 'next (' .. (plan.state == 'none' and 'no plan file: ' or '') .. 'default suggestions' .. lockNote .. '):'
  limited(lines, defaults(ctx))
  if plan.state == 'none' then lines[#lines + 1] = 'Add EmpireIntel_Plan\\Plan.lua to set your own order (README).' end
  return lines
end

--- /ei next
function N.Command()
  local rows = EI.Views.Collect()
  local plan = EI.Plan.Load(rows)
  local ctx = { rows = rows, plan = plan, unlocked = N.Unlocked(rows), now = (P.Now()) }
  local function emit() for _, l in ipairs(N.Lines(ctx)) do P.Print(l) end end
  local wantsLegacy = false
  if plan.state == 'ok' and ctx.unlocked then
    for _, g in ipairs(plan.goals) do if g.kind == 'challenges' then wantsLegacy = true end end
  end
  if not wantsLegacy then emit(); return end
  local ok, why = P.Legacy.Read(function(out) ctx.legacy = out; emit() end)
  if not ok then
    ctx.legacyWhy = why
    emit()
  elseif P.Legacy.busy then
    P.Print('next: reading Legacy challenges (about 2 seconds).')
  end
end
