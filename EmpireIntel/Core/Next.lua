local ADDON, EI = ...
-- EmpireIntel / Core / Next.lua                                          (Phase 2, increment P2-4a)
--
-- PURPOSE
--   /ei next     the plan in chat: the fastest route (auto mode, Core/Route.lua) or the user's own steps (mine mode)
--   /ei plan     opens or closes the plan window (P2-4b, Q-P2-4b-2); /ei plan help: the settings in chat
--   /ei plan ... the plan settings in chat (mode, target, copy, remove, top, clear, ignore, unignore)
--   /ei rules    the planner's rules with their sources and status (Core/RouteRules.lua)
--   Phase2_Plan.md 8.1, 8.4-8.7 (approved D-055, D-056). The window (P2-4b) is not built here.
--
-- RULES
--   * The characters are the ones /ei alts lists (Views.Collect: own records, DataStore, the player's live values).
--   * Legacy lock rule (D-052): before any known character reaches 25 no Legacy function is called and the route
--     starts with a character to 25. After the unlock, /ei next reads the Legacy challenges with P3-1's read
--     (Platform/Legacy.lua), on command, never in combat; without a read the route says its counts are inferred.
--   * Unknown is never shown as met. Every time is labelled [estimate] with the unverified rules it uses.
--   * Saved only through Core/Plan.lua (format 2), and only on a /ei plan command.
--   The step lines of "my plan" reuse #11's goal lines (gap, rested now, "earns ...", [datastore, age]).

EI = EI or {}
local P = EI.Platform
local R = EI.Rules
local RR = EI.RouteRules
assert(P and P.Legacy and R and RR and EI.Route and EI.Plan and EI.Views and EI.Commands,
  'load order: Platform/Legacy, Rules, RouteRules, Route, Plan, Commands, Views, Next')

local N = {}
EI.Next = N

N.MAX_LINES = 10

local function className(c) return R.CLASS_NAMES[c] or tostring(c or 'class?') end
local function plural(n, word) return n .. ' ' .. word .. (n == 1 and '' or 's') end
local function hoursText(h)
  if h < 1 then return string.format('~%d min', math.max(1, math.floor(h * 60 + 0.5))) end
  return string.format('~%.1f h', h)
end

local function head(r, level)
  return string.format('%s %s %s', tostring(r.name or 'name unknown'), className(r.class), tostring(level or r.level or '?'))
end

local function srcTag(r)
  if r.src == 'datastore' then return ' [datastore, ' .. EI.Commands.Ago(r.at) .. ']' end
  return ''
end

local function rulesTag(ids)
  if #ids == 0 then return ' [estimate]' end
  return ' [estimate; unverified: ' .. table.concat(ids, ' ') .. ']'
end

--- Unlocked = any known character at level 25 or higher (EI-E-02, the /ei unlock test).
function N.Unlocked(rows)
  for _, r in ipairs(rows) do
    if type(r.level) == 'number' and r.level >= R.UNLOCK_LEVEL then return true end
  end
  return false
end

--- Rested XP now, in levels: value, estimated (bool); or nil plus a reason. (#11)
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

-- the plan's ruleset: the played character's (L-18); nil when not recorded yet
local function playerRuleset(rows)
  for _, r in ipairs(rows) do if r.isPlayer then return r.ruleset end end
  return nil
end

---------------------------------------------------------------------------
-- auto mode: the route
---------------------------------------------------------------------------

local function partsText(s)
  local out = {}
  for _, p in ipairs(s.parts) do
    if p.kind == 'level' then
      out[#out + 1] = 'level ' .. p.to
    elseif p.kind == 'skill' then
      local t = (p.learn and ('learn ' .. p.profession .. ', ') or (p.profession .. ' ')) .. p.from .. ' -> ' .. p.to
      if s.train then t = t .. ' (train ' .. s.train .. ')' end
      out[#out + 1] = t
    elseif p.kind == 'runs' then
      out[#out + 1] = p.name .. ': ' .. (p.unknown and (p.left .. ' dungeons, progress not read') or plural(p.left, 'dungeon') .. ' left')
    elseif p.kind == 'zones' then
      out[#out + 1] = 'Explorer: ' .. plural(p.left, 'zone') .. ' left of ' .. p.total
    end
  end
  return table.concat(out, ', then ')
end

function N.StepLine(s)
  -- the level at this point of the route (earlier steps may have levelled the character)
  local t = head(s.row, s.atLevel) .. (s.atLevel ~= s.row.level and ' (in this route)' or '') .. ': ' .. partsText(s) .. ': +' .. s.points .. ' (' .. table.concat(s.earns, ', ') .. '), '
    .. hoursText(s.hours)
  if (s.restHours or 0) > 0.05 then t = t .. ' (rest saves ' .. hoursText(s.restHours) .. ')' end
  if s.measured then t = t .. ' (measured XP rate)' end
  return t .. rulesTag(EI.Route.UnverifiedRules(s)) .. srcTag(s.row)
end

local function targetText(res)
  if res.targetKind == 'reward' and res.reward then return 'the next reward (' .. res.reward.at .. ' points: ' .. res.reward.name .. ')' end
  if res.targetKind == 'next' then return 'the next point' end
  return res.target .. ' Legacy points'
end

local function excludedText(res, ruleset)
  local parts = {}
  if res.excluded.ignored > 0 then parts[#parts + 1] = plural(res.excluded.ignored, 'character') .. ' ignored' end
  if res.excluded.ruleset > 0 then
    parts[#parts + 1] = res.excluded.ruleset .. ' on another ruleset (not mixed with ' .. tostring(ruleset) .. ', L-18)'
  end
  if #parts == 0 then return '' end
  return ' (' .. table.concat(parts, '; ') .. ')'
end

--- Lines for auto mode. ctx: res (Route.Build), ruleset, legacyWhy. Pure.
function N.AutoLines(ctx)
  local res = ctx.res
  local lines = {}
  local n, u = RR.Counts()
  local earned
  if res.earnedSrc == 'game' then
    earned = res.earned .. ' earned [game]'
  else
    earned = res.earned .. ' earned [inferred from levels and skills: class and craft challenges only]'
  end
  local lock = res.unlocked and '' or '; Legacy not unlocked yet'
  lines[1] = string.format('next (fastest route to %s; %s%s; %d rules, %d unverified: /ei rules)%s:', targetText(res), earned,
    lock, n, u, excludedText(res, ctx.ruleset))
  if ctx.legacyWhy == 'combat' then lines[#lines + 1] = 'Legacy not read (in combat): counts are inferred; try /ei next after combat.' end
  if ctx.legacyWhy == 'busy' then lines[#lines + 1] = 'Legacy not read (a read is already running): counts are inferred; try /ei next again.' end
  if ctx.legacyWhy == 'failed' then lines[#lines + 1] = 'UNEXPECTED: the Legacy read failed; counts are inferred.' end
  if #res.states == 0 then
    lines[#lines + 1] = 'next: no characters known yet.'
    return lines
  end
  if res.earned >= res.target then
    lines[#lines + 1] = 'Target reached: ' .. res.earned .. ' of ' .. res.target .. '. /ei plan target to set another.'
    return lines
  end
  local total = 0
  for i, s in ipairs(res.steps) do
    total = total + s.hours
    if i <= N.MAX_LINES then lines[#lines + 1] = i .. '. ' .. N.StepLine(s) end
  end
  if #res.steps > N.MAX_LINES then
    lines[#lines + 1] = '... and ' .. plural(#res.steps - N.MAX_LINES, 'more step') .. ' (/ei plan copy keeps the whole route)'
  end
  if res.left == 0 then
    lines[#lines + 1] = string.format('Route: %s to %d, about %.0f h in all [estimate].', plural(#res.steps, 'step'), res.target, total)
  else
    lines[#lines + 1] = string.format('Route stops at %d of %d: %s content not planned (PvP before 60, raids and Valthalak, new characters).',
      res.reached, res.target, res.left == 1 and 'the last point needs' or ('the other ' .. res.left .. ' points need'))
  end
  for _, note in ipairs(res.notes) do
    if note.kind == 'explorer' then
      local who = tostring(note.row.name or 'a character') .. (note.inRoute and (' reaches ' .. RR.EXPLORER_LEVEL .. ' in this route')
        or (' is ' .. RR.EXPLORER_LEVEL .. ' or more'))
      lines[#lines + 1] = 'Explorer (planned from level ' .. RR.EXPLORER_LEVEL .. ', L-11): ' .. who
        .. '; its zones left are read only while it is played (/ei next on it), so the route does not count it yet.'
    end
  end
  local reward = RR.NextReward(res.earned)
  if reward and res.targetKind ~= 'reward' then lines[#lines + 1] = 'Next reward at ' .. reward.at .. ': ' .. reward.name .. '.' end
  return lines
end

---------------------------------------------------------------------------
-- mine mode: the user's steps (goal lines reused from #11)
---------------------------------------------------------------------------

-- the account's best level per class and best skill per craft (account-wide challenges, EI-E-27) (#11)
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

local function challengeLine(g, ctx)
  local t = 'Account -> challenge ' .. g.id .. ': '
  if not ctx.unlocked then return withNote(t .. 'Legacy not unlocked yet', g) end
  if ctx.legacyWhy == 'combat' then return withNote(t .. 'not read (in combat); try /ei next again after combat', g) end
  if ctx.legacyWhy == 'busy' then return withNote(t .. 'not read (a Legacy read is already running); try /ei next again', g) end
  local out = ctx.legacy
  if not out or out.error or not (out.summary and out.summary.recognized) then return withNote(t .. 'unknown (the Legacy read failed)', g) end
  local ch = out.challengeById and out.challengeById[g.id]
  if not ch then return withNote(t .. 'unknown (not in the Legacy challenges read)', g) end
  if ch.completed == true then return 'met' end
  t = 'Account -> ' .. tostring(ch.name) .. ': '
  if type(ch.criteria) == 'table' and #ch.criteria > 0 then
    local d = 0
    for _, c in ipairs(ch.criteria) do if c.completed == true then d = d + 1 end end
    t = t .. string.format('%d of %d done, ~%.1f h [estimate; unverified: L-16]', d, #ch.criteria, (#ch.criteria - d) * RR.HOURS_PER_RUN)
  else
    t = t .. 'not done'
  end
  return withNote(t, g)
end

-- one saved step: 'met' or a line (unmet or unknown)
local function stepLine(g, ctx)
  if g.kind == 'challenge' then return challengeLine(g, ctx) end
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
    local hours = EI.Route.LevelHours(EI.Route.State(r, ctx.now, ctx.rates), g.level)
    t = t .. '; ' .. hoursText(hours) .. ' [estimate; unverified: L-15 L-16 L-17]'
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
    t = t .. '; ' .. hoursText(EI.Route.SkillHours(skill, g.skill)) .. ' [estimate; unverified: L-16]'
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

--- Lines for mine mode. ctx: rows, plan (Plan.Load), unlocked, now, rates, legacy, legacyWhy. Pure.
function N.MineLines(ctx)
  local lines = {}
  ctx.bestLevel, ctx.bestCraft = bests(ctx.rows)
  local plan = ctx.plan
  for _, p in ipairs(plan.problems) do lines[#lines + 1] = p end
  local lock = ctx.unlocked and '' or '; Legacy not unlocked yet'
  if plan.total == 0 then
    lines[#lines + 1] = 'next (my plan: no steps' .. lock .. '). /ei plan copy copies the fastest route; /ei plan mode auto shows it.'
    return lines
  end
  local list, met = {}, 0
  for _, g in ipairs(plan.steps) do
    local l = stepLine(g, ctx)
    if l ~= 'met' and g.guid and ctx.ignore and ctx.ignore[g.guid] then l = '(ignored) ' .. l end   -- D-063 item 4
    if l == 'met' then met = met + 1 else list[#list + 1] = { n = g.n, s = l } end
  end
  lines[#lines + 1] = string.format('next (my plan: %s; %d met, %d skipped%s):', plural(plan.total, 'step'), met,
    plan.total - #plan.steps, lock)
  if #list == 0 then lines[#lines + 1] = 'All steps in my plan are met.' end
  for i, x in ipairs(list) do
    if i > N.MAX_LINES then
      lines[#lines + 1] = '... and ' .. (#list - N.MAX_LINES) .. ' more'
      break
    end
    lines[#lines + 1] = x.n .. '. ' .. x.s
  end
  return lines
end

---------------------------------------------------------------------------
-- commands
---------------------------------------------------------------------------

local function needsRead(rows, mode, plan)
  if not N.Unlocked(rows) then return false end      -- the lock rule: no Legacy call before the unlock
  if mode == 'auto' then return true end
  for _, g in ipairs(plan.steps) do if g.kind == 'challenge' then return true end end
  return false
end

local function routeFor(rows, legacy, now)
  local ruleset = playerRuleset(rows)
  local res = EI.Route.Build({ rows = rows, now = now, legacy = legacy, target = EI.Plan.Target(), rates = EI.Plan.Rates(),
    ignore = EI.Plan.Ignore(), ruleset = ruleset })
  return res, ruleset
end

-- gathers rows (and a Legacy read when allowed), then calls fn(rows, legacy, why, now)
local function withData(forRoute, fn, quiet)
  local rows = EI.Views.Collect()
  local now = (P.Now())
  local mode = EI.Plan.Mode()
  local plan = EI.Plan.Load(rows)
  if not needsRead(rows, forRoute and 'auto' or mode, plan) then fn(rows, nil, nil, now, plan); return end
  local ok, why = P.Legacy.Read(function(out)
    local w = nil
    if out.combat then w = 'combat' elseif out.error or not (out.summary and out.summary.recognized) then w = 'failed' end
    -- the read calls this under pcall, which would hide an error: say it instead
    local okFn, err = pcall(fn, rows, (w == nil) and out or nil, w, now, plan)
    if not okFn then P.Print('UNEXPECTED: /ei next failed: ' .. tostring(err)) end
  end)
  if not ok then
    fn(rows, nil, why, now, plan)
  elseif P.Legacy.busy and not quiet then
    P.Print('next: reading Legacy challenges (about 2 seconds).')
  end
end

N.Data = withData            -- for the window (UI/Window.lua)
N.RouteFor = routeFor

--- /ei next
function N.Command()
  withData(false, function(rows, legacy, why, now, plan)
    local lines
    if EI.Plan.Mode() == 'mine' then
      lines = N.MineLines({ rows = rows, plan = plan, unlocked = N.Unlocked(rows), now = now, rates = EI.Plan.Rates(), ignore = EI.Plan.Ignore(),
        legacy = legacy, legacyWhy = why })
    else
      local res, ruleset = routeFor(rows, legacy, now)
      lines = N.AutoLines({ res = res, ruleset = ruleset, legacyWhy = why })
    end
    for _, l in ipairs(lines) do P.Print(l) end
  end)
end

local function say(s) P.Print('plan: ' .. s) end

local function settings(rows)
  local ign = {}
  local byGuid = {}
  for _, r in ipairs(rows) do if r.guid then byGuid[r.guid] = r end end
  for guid in pairs(EI.Plan.Ignore()) do ign[#ign + 1] = byGuid[guid] and tostring(byGuid[guid].name) or 'a character no longer known' end
  table.sort(ign)
  local nr = 0
  for _ in pairs(EI.Plan.Rates()) do nr = nr + 1 end
  local t = EI.Plan.Target()
  say(string.format('mode %s, target %s, my plan %s, ignored: %s, measured XP rates: %d.',
    EI.Plan.Mode() == 'auto' and 'auto (fastest route)' or 'mine (my plan)', tostring(t), plural(#EI.Plan.Mine(), 'step'),
    #ign > 0 and table.concat(ign, ', ') or 'none', nr))
  say('commands: /ei plan (the window), /ei plan help, /ei plan mode auto|mine, /ei plan target 16|reward|next, /ei plan copy, /ei plan remove <n>, /ei plan top <n>, /ei plan clear, /ei plan ignore <name>, /ei plan unignore <name>.')
  say('/ei plan opens the window; /ei minimap on|off. Saved by the game at /reload or logout.')
  if P.UI then say('window ' .. P.UI.FillText() .. '.') end
end

local function done(ok, why, text)
  if ok then say(text) else say(tostring(why)) end
end

--- /ei plan <args> (args lower case, trimmed)
function N.PlanCommand(args)
  local cmd, rest = string.match(args or '', '^(%S*)%s*(.-)$')
  if cmd == '' then
    if EI.Window then
      local ok, err = pcall(EI.Window.Toggle)
      if not ok then P.Print('UNEXPECTED: the window failed: ' .. tostring(err)) end
    else
      settings(EI.Views.Collect())
    end
    return
  end
  if cmd == 'help' then settings(EI.Views.Collect()); return end
  if cmd == 'mode' then
    local ok, why = EI.Plan.SetMode(rest)
    done(ok, why, 'mode ' .. rest .. '. /ei next shows it.')
  elseif cmd == 'target' then
    local ok, why = EI.Plan.SetTarget(rest)
    done(ok, why, 'target ' .. rest .. '.')
  elseif cmd == 'copy' then
    withData(true, function(rows, legacy, why, now)
      local res = routeFor(rows, legacy, now)
      local list, skipped = EI.Plan.FromRoute(res.steps)
      local ok, err = EI.Plan.SetMine(list)
      if not ok then say(err); return end
      local t = 'copied the fastest route into my plan: ' .. plural(#list, 'step') .. '.'
      if skipped > 0 then t = t .. ' ' .. plural(skipped, 'dungeon step') .. ' left out (challenge id needs a Legacy read).' end
      say(t .. ' /ei plan mode mine to follow it.')
    end)
  elseif cmd == 'remove' or cmd == 'top' then
    local n = tonumber(rest)
    local mine = EI.Plan.Mine()
    if not n or not mine[n] then say('no step ' .. tostring(rest) .. ' (my plan has ' .. plural(#mine, 'step') .. ').'); return end
    local byGuid = {}
    for _, r in ipairs(EI.Views.Collect()) do if r.guid then byGuid[r.guid] = r end end
    local list, carried
    if cmd == 'top' then list, carried = EI.Plan.MoveKeeping(mine, n, 1, byGuid) else list, carried = EI.Plan.RemoveKeeping(mine, n, byGuid) end
    if not list then say((cmd == 'top' and 'not moved: ' or '') .. tostring(carried)); return end
    local ok, why = EI.Plan.SetMine(list)
    done(ok, why, (cmd == 'top' and ('moved step ' .. n .. ' to the top.' .. EI.Plan.CarriedText(carried or {}, byGuid)) or 'removed step ' .. n .. '.'))
  elseif cmd == 'clear' then
    local ok, why = EI.Plan.SetMine({})
    done(ok, why, 'my plan is empty.')
  elseif cmd == 'ignore' or cmd == 'unignore' then
    local row, why = EI.Plan.MatchChar(EI.Views.Collect(), rest)
    if not row then say(why); return end
    local ok, err = EI.Plan.SetIgnored(row.guid, cmd == 'ignore')
    done(ok, err, EI.Plan.IgnoreText(row.name, row.guid, cmd == 'ignore'))
  else
    settings(EI.Views.Collect())
  end
end

--- /ei rules
function N.RulesCommand()
  local n, u = RR.Counts()
  P.Print(string.format('rules: %d planner rules, %d unverified (labelled where used). Status: confirmed, partly, user, unverified.', n, u))
  for _, r in ipairs(RR.LIST) do
    P.Print(string.format('%s [%s] %s. Source: %s', r.id, r.status, r.text, r.src))
  end
end
