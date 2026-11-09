-- EmpireIntel / Tests / test_ei_next.lua
-- Behaviour of increment P2-4a (Phase2_Plan.md section 8, D-055, D-056): saved-data format 2, the identity fields,
-- the rules table, the route engine (auto mode), my plan (mine mode), the /ei plan commands, the XP-rate
-- measurement (Q-F2), the Legacy lock rule (D-052) and the static rules (pure engine, no window code).
local T, F, root = ...

local WALL = 1800000000
local C1, C2, C3 = 'Player-1-00000011', 'Player-1-00000012', 'Player-1-00000013'

local function session(opts)
  opts = opts or {}
  opts.char = opts.char or { level = 4, xp = 86, xpMax = 2100, rest = 500, resting = true }
  local W = F.new(opts)
  W.prints = {}
  W.env.print = function(...) local t = {}; for i = 1, select('#', ...) do t[i] = tostring((select(i, ...))) end; table.insert(W.prints, table.concat(t, ' ')) end
  -- the real client reports the rank's cap (75 for Apprentice); the base fake says 300
  W.env.GetProfessionInfo = function(i)
    local p = W.char.profs[i]
    if p then return p.name, 136240, p.skill, p.max or 75, 0, 0, p.line, 0 end
  end
  if opts.before then opts.before(W) end
  local EI = F.loadAddon(W, 'EmpireIntel')
  W:fire('PLAYER_LOGIN')
  W:fire('PLAYER_ENTERING_WORLD', true, false)
  W:advance(3)
  return W, EI
end
local function run(W, msg)
  local from = #W.prints
  W.env.SlashCmdList.EMPIREINTEL(msg)
  W:advance(5)
  local out = {}
  for i = from + 1, #W.prints do out[#out + 1] = (W.prints[i]:gsub('^EmpireIntel: ', '')) end
  return out
end
local function find(lines, text)
  for _, l in ipairs(lines) do if l:find(text, 1, true) then return l end end
  return nil
end
local function dump(lines) return table.concat(lines, '\n') end

local function rec(t)
  local r = { realm = 'Test Realm', src = 'self', lastSeen = WALL - 3600, restAt = WALL - 3600 }
  for k, v in pairs(t) do r[k] = v end
  return r
end
local function db(recs, plan) return { schema = 1, meta = {}, roster = recs, plan = plan } end
-- today's account (Phase2_Plan.md 8.6, names replaced): C1 Paladin 27 (gathering only), C2 Priest 6 (two crafts)
local function c1() return rec({ name = 'Cee One', class = 'PALADIN', level = 27, xp = 0, xpMax = 38900, rest = 0, resting = true,
  professions = { { name = 'Mining', skill = 41, max = 75, line = 186 }, { name = 'Skinning', skill = 77, max = 150, line = 393 } } }) end
local function c2() return rec({ name = 'Cee Two', class = 'PRIEST', level = 6, xp = 0, xpMax = 3600, rest = 1842, resting = true,
  professions = { { name = 'Tailoring', skill = 56, max = 75, line = 197 }, { name = 'Enchanting', skill = 28, max = 75, line = 333 } } }) end
local function today() return db({ [C1] = c1(), [C2] = c2() }) end

-- pure engine helpers: rows as Views.Collect gives them
local function row(guid, t)
  local r = { guid = guid, src = 'self', at = WALL - 3600, restAt = WALL - 3600 }
  for k, v in pairs(t) do r[k] = v end
  return r
end
local function rowsToday()
  local a, b = c1(), c2()
  a.guid, b.guid = C1, C2
  return { a, b }
end
local function build(EI, input)
  input.now = input.now or WALL
  return EI.Route.Build(input)
end
local function pureEI()
  local W = F.new({})
  return F.loadAddon(W, 'EmpireIntel')
end

---------------------------------------------------------------------------
T.describe('P2-4a: saved-data format 2', function()
  T.it('a fresh database is schema 2 with an empty plan section', function()
    local W = session({})
    T.eq(W.env.EmpireIntelDB.schema, 2)
    T.eq(W.env.EmpireIntelDB.plan, {})
  end)
  T.it('format 1 is migrated: the plan section is added, nothing is converted, the roster is kept', function()
    local W, EI = session({ eidb = { schema = 1, meta = { created = 5 }, roster = { [C1] = c1() }, off = nil, keep = 'x' } })
    T.eq(EI.Store.Status().state, 'migrated')
    T.eq(EI.Store.Status().migrated.applied, { 'format 2: plan' })
    local d = W.env.EmpireIntelDB
    T.eq(d.schema, 2)
    T.eq(d.plan, {})
    T.eq(d.roster[C1].level, 27)
    T.eq(d.roster[C1].name, 'Cee One')
    T.eq(d.keep, 'x')
  end)
  T.it('a format-2 plan is opened as it is', function()
    local plan = { mode = 'mine', target = 'reward', mine = { { kind = 'level', guid = C1, level = 45 } }, ignore = { [C2] = true } }
    local W, EI = session({ eidb = { schema = 2, meta = {}, roster = { [C1] = c1(), [C2] = c2() }, plan = plan } })
    T.eq(EI.Store.Status().state, 'ok')
    T.eq(EI.Plan.Mode(), 'mine')
    T.eq(EI.Plan.Target(), 'reward')
    T.eq(W.env.EmpireIntelDB.plan.mine, { { kind = 'level', guid = C1, level = 45 } })
  end)
  T.it('a newer schema is read-only: plan commands say nothing is saved', function()
    local W, EI = session({ eidb = { schema = 3, meta = {}, roster = { [C1] = c1() }, plan = { mode = 'auto' } } })
    T.eq(EI.Store.Status().state, 'readonly')
    local out = run(W, 'plan mode mine')
    T.truthy(find(out, 'not saved: the saved data is read-only'), dump(out))
    T.eq(W.env.EmpireIntelDB.plan.mode, 'auto')
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4a: race, sex, faction and ruleset on the roster', function()
  local function withIdentity(hc, preset)
    return function(W)
      W.env.UnitRace = function() return 'Human', 'Human', 1 end
      W.env.UnitSex = function() return 3 end
      W.env.UnitFactionGroup = function() return 'Alliance', 'Alliance' end
      W.env.C_GameRules = { IsHardcoreActive = function() return hc end, GetForeverExperiencePreset = function() return preset end }
    end
  end
  T.it('are recorded for the played character when the client gives them', function()
    local W = session({ before = withIdentity(false, 1) })
    local r = W.env.EmpireIntelDB.roster['Player-1-00000001']
    T.eq(r.race, 'Human')
    T.eq(r.sex, 3)
    T.eq(r.faction, 'Alliance')
    T.eq(r.ruleset, 'normal')
    T.eq(r.preset, 1)
  end)
  T.it('IsHardcoreActive true is recorded as hardcore', function()
    local W = session({ before = withIdentity(true, 0) })
    T.eq(W.env.EmpireIntelDB.roster['Player-1-00000001'].ruleset, 'hardcore')
  end)
  T.it('unknown stays unknown: no call, a secret or an odd value records nothing', function()
    local W = session({})
    local r = W.env.EmpireIntelDB.roster['Player-1-00000001']
    T.isnil(r.race); T.isnil(r.sex); T.isnil(r.ruleset); T.isnil(r.preset)
    local W2 = session({ before = function(w)
      withIdentity(nil, nil)(w)
      w.env.C_GameRules.IsHardcoreActive = function() return w.SECRET end
      w.env.UnitSex = function() return 9 end
    end })
    local r2 = W2.env.EmpireIntelDB.roster['Player-1-00000001']
    T.isnil(r2.ruleset); T.isnil(r2.sex); T.isnil(r2.preset)
    T.eq(r2.faction, 'Alliance')
  end)
  T.it('a value the client stops giving keeps the one recorded before', function()
    local W, EI = session({ before = withIdentity(false, 1) })
    W.env.C_GameRules = nil
    EI.Snapshot.Write('command')
    T.eq(W.env.EmpireIntelDB.roster['Player-1-00000001'].ruleset, 'normal')
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4a: the rules table', function()
  local EI = pureEI()
  T.it('has L-1 to L-18, each with a status and a source', function()
    T.eq(#EI.RouteRules.LIST, 18)
    for i, r in ipairs(EI.RouteRules.LIST) do
      T.eq(r.id, 'L-' .. i)
      T.truthy(({ confirmed = 1, partly = 1, user = 1, unverified = 1 })[r.status], r.id)
      T.truthy(type(r.src) == 'string' and r.src ~= '' and type(r.text) == 'string', r.id)
    end
  end)
  T.it('Q-F3 (D-056): Explorer after 50 counting zones explored before; Spelunker at any level', function()
    local l11 = EI.RouteRules.BY_ID['L-11']
    T.eq(l11.status, 'user')
    T.truthy(l11.text:find('after a character reaches 50, counting zones explored before', 1, true))
    T.eq(EI.RouteRules.EXPLORER_LEVEL, 50)
  end)
  T.it('counts: 18 rules, 11 unverified (partly or unverified)', function()
    local n, u = EI.RouteRules.Counts()
    T.eq(n, 18); T.eq(u, 11)
  end)
  T.it('the XP table matches the bars measured on Forever (EI-E-14: level 6 3600, level 12 10100)', function()
    T.eq(EI.RouteRules.XP[6], 3600)
    T.eq(EI.RouteRules.XP[12], 10100)
    T.eq(#EI.RouteRules.XP, 59)
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4a: the route engine', function()
  local EI = pureEI()
  local R = EI.Route
  T.it('today\'s account: C2 to 10 then Tailoring 150 first, then Enchanting 150 (Phase2_Plan.md 8.6)', function()
    local res = build(EI, { rows = rowsToday(), target = 16 })
    local s1, s2 = res.steps[1], res.steps[2]
    T.eq(s1.row.guid, C2)
    T.eq(s1.parts[1], { kind = 'level', from = 6, to = 10 })
    T.eq(s1.parts[2].profession, 'Tailoring'); T.eq(s1.parts[2].to, 150)
    T.eq(s1.earns, { 'Journeyman Tailor' })
    T.eq(s1.train, 'Journeyman')
    T.eq(s2.earns, { 'Journeyman Enchanter' })
    T.eq(res.earnedSrc, 'inferred')
    T.eq(res.earned, 1, 'Novice Paladin from C1 at 27')
  end)
  T.it('each step names the rules it depends on; the unverified ones are listed in order', function()
    local res = build(EI, { rows = rowsToday(), target = 16 })
    T.eq(R.UnverifiedRules(res.steps[1]), { 'L-4', 'L-5', 'L-15', 'L-16', 'L-17' })
  end)
  T.it('a rested pool of R saves R of kill XP in full (L-17, D-055)', function()
    local base = row(C2, { name = 'Cee Two', class = 'PRIEST', level = 6, xp = 0, xpMax = 3600, rest = 0, liveRest = true })
    local rested = row(C2, { name = 'Cee Two', class = 'PRIEST', level = 6, xp = 0, xpMax = 3600, rest = 3000, liveRest = true })
    local h0, s0 = R.LevelHours(R.State(base, WALL), 10)
    local h1, s1, used = R.LevelHours(R.State(rested, WALL), 10)
    T.eq(used, 3000)
    T.near(s1, 3000 / 12000, 1e-9)
    T.near(h0 - h1, 3000 / 12000, 1e-9)
    T.eq(s0, 0)
  end)
  T.it('the saving never exceeds the XP to go', function()
    local r = row(C2, { name = 'X', class = 'MAGE', level = 6, xp = 3000, xpMax = 3600, rest = 5000, liveRest = true })
    local h, s, used = R.LevelHours(R.State(r, WALL), 7)
    T.eq(used, 600); T.eq(h, 0)
  end)
  T.it('a measured XP rate replaces the band default (Q-F2) and the step says so', function()
    local rows = { row(C2, { name = 'Cee Two', class = 'PRIEST', level = 20, xp = 0, xpMax = 23200, professions = {} }) }
    local a = build(EI, { rows = rows, target = 'next' })
    local b = build(EI, { rows = rows, target = 'next', rates = { [C2] = { xpPerHour = 48000 } } })
    T.eq(a.steps[1].earns, { 'Novice Priest' })
    T.truthy(b.steps[1].measured)
    T.near(a.steps[1].hours / b.steps[1].hours, 2, 1e-9)
  end)
  T.it('Legacy lock (D-052): before any character reaches 25 the first step is a character to 25', function()
    local rows = { row(C1, { name = 'Low', class = 'MAGE', level = 22, xp = 0, professions = { { name = 'Tailoring', skill = 74, max = 75 } } }),
      row(C2, { name = 'Lower', class = 'ROGUE', level = 8, xp = 0, professions = {} }) }
    local res = build(EI, { rows = rows, target = 16 })
    T.falsy(res.unlocked)
    T.eq(res.steps[1].row.guid, C1)
    T.eq(res.steps[1].earns, { 'Novice Mage' })
    T.eq(res.earned, 0)
    T.truthy(#res.steps > 1, 'after the unlock the route goes on')
  end)
  T.it('Legacy lock: while locked only a level-25 class step is planned, even if the game lists a class done', function()
    -- a deleted character earned Novice Mage; every known character is below 25, so the account counts as locked
    local legacy = { summary = { recognized = true, earned = 1 }, challenges = { { id = 1, name = 'Novice Mage', legacy = 1, completed = true } } }
    local rows = { row(C1, { name = 'M', class = 'MAGE', level = 24, xp = 0, xpMax = 31700, professions = {} }),
      row(C2, { name = 'R', class = 'ROGUE', level = 20, xp = 0, professions = {} }) }
    local res = build(EI, { rows = rows, target = 'next', legacy = legacy })
    T.eq(res.steps[1].earns, { 'Novice Rogue' })
    local only = build(EI, { rows = { rows[1] }, target = 16, legacy = legacy })
    T.eq(#only.steps, 0, 'no Experienced Mage step while locked')
  end)
  T.it('the target: next point, next reward, a number; met means no steps', function()
    T.eq(#build(EI, { rows = rowsToday(), target = 'next' }).steps, 1)
    local r = build(EI, { rows = rowsToday(), target = 'reward' })
    T.eq(r.target, 15); T.eq(r.reward.name, 'Air Rifle')
    local met = build(EI, { rows = rowsToday(), target = 1 })
    T.eq(#met.steps, 0); T.eq(met.left, 0)
  end)
  T.it('ignored characters are left out of the route and counted (Q-F4)', function()
    local res = build(EI, { rows = rowsToday(), target = 16, ignore = { [C2] = true } })
    T.eq(res.excluded.ignored, 1)
    for _, s in ipairs(res.steps) do T.eq(s.row.guid, C1) end
  end)
  T.it('rulesets are never mixed (L-18): a character on another recorded ruleset is left out; unknown stays in', function()
    local rows = rowsToday()
    rows[1].ruleset = 'hardcore'
    local res = build(EI, { rows = rows, target = 16, ruleset = 'normal' })
    T.eq(res.excluded.ruleset, 1)
    for _, s in ipairs(res.steps) do T.eq(s.row.guid, C2) end
    local any = build(EI, { rows = rowsToday(), target = 16, ruleset = 'normal' })
    T.eq(any.excluded.ruleset, 0)
  end)
  T.it('learning a craft is planned only with a free primary slot and known professions (L-6)', function()
    local free = build(EI, { rows = { row(C1, { name = 'A', class = 'MAGE', level = 30, xp = 0, professions = { { name = 'Mining', skill = 1, max = 75 } } }) }, target = 16 })
    local learned = 0
    for _, s in ipairs(free.steps) do
      for _, p in ipairs(s.parts) do if p.kind == 'skill' and p.learn then learned = learned + 1 end end
    end
    T.truthy(learned >= 1, 'one craft learned in the free slot')
    T.eq(learned, 1, 'only one slot is free')
    local unknown = build(EI, { rows = { row(C1, { name = 'B', class = 'MAGE', level = 30, xp = 0 }) }, target = 16 })
    for _, s in ipairs(unknown.steps) do T.falsy(s.kind == 'craft', 'no craft without known professions') end
  end)
  T.it('a second character of a class earns nothing for that class (L-2)', function()
    local rows = { row(C1, { name = 'A', class = 'PRIEST', level = 30, xp = 0, professions = {} }),
      row(C2, { name = 'B', class = 'PRIEST', level = 10, xp = 0, professions = {} }) }
    local res = build(EI, { rows = rows, target = 16 })
    for _, s in ipairs(res.steps) do
      if s.kind == 'class' then T.eq(s.row.guid, C1, 'class steps go to the higher Priest') end
    end
  end)
  T.it('PvP and level-60 content are never steps; what is left is reported', function()
    local res = build(EI, { rows = rowsToday(), target = 55 })
    for _, s in ipairs(res.steps) do T.truthy(({ class = 1, craft = 1, dungeon = 1, explorer = 1 })[s.kind], s.kind) end
    T.truthy(res.left > 0)
    T.eq(res.reached + res.left, 55)
  end)
  T.it('with a Legacy read the game\'s count is used (Q-F5) and dungeons left come from its steps', function()
    local legacy = { summary = { recognized = true, earned = 2 }, challenges = {
      { id = 61997, name = 'Novice Paladin', legacy = 1, completed = true },
      { id = 62031, name = 'Novice Spelunker', legacy = 1, completed = true },
      { id = 62032, name = 'Experienced Spelunker', legacy = 1, completed = false,
        criteria = { { completed = true }, { completed = false }, { completed = false } } },
      { id = 99, name = 'Journeyman Tailor', legacy = 1, completed = false },
    } }
    local res = build(EI, { rows = rowsToday(), target = 16, legacy = legacy })
    T.eq(res.earned, 2); T.eq(res.earnedSrc, 'game')
    local exp
    for _, s in ipairs(res.steps) do
      T.falsy(s.earns[1] == 'Novice Spelunker', 'done in the game')
      if s.earns[1] == 'Experienced Spelunker' then exp = s end
    end
    T.truthy(exp, 'Experienced Spelunker planned')
    T.eq(exp.parts[#exp.parts].left, 2)
    T.eq(exp.id, 62032)
    T.falsy(exp.unknownProgress)
  end)
  T.it('Explorer (D-056): a step for the played character at 50 or more, counting zones already explored', function()
    local legacy = { summary = { recognized = true, earned = 0 }, challenges = {
      { id = 62382, name = 'Explorer', legacy = 1, completed = false, steps = {
        { id = 62053, criteria = { { type = 8 } } },
        { id = 776, completed = true, criteria = { { type = 43 } } },
        { id = 627, completed = false, criteria = { { type = 43 } } },
        { id = 728, completed = false, criteria = { { type = 43 } } } } } } }
    local p = row(C1, { name = 'Old', class = 'WARRIOR', level = 50, xp = 0, isPlayer = true, professions = { { name = 'Mining', skill = 300 }, { name = 'Herbalism', skill = 300 } } })
    local res = build(EI, { rows = { p }, target = 'next', legacy = legacy })
    local ex
    for _, s in ipairs(res.steps) do if s.kind == 'explorer' then ex = s end end
    T.truthy(ex, 'Explorer is a step')
    T.eq(ex.parts[1], { kind = 'zones', left = 2, total = 3 })
    local below = build(EI, { rows = { row(C1, { name = 'Young', class = 'WARRIOR', level = 49, xp = 0, isPlayer = true, professions = {} }) },
      target = 'next', legacy = legacy })
    T.falsy(below.steps[1].kind == 'explorer', 'not before 50')
  end)
  T.it('the engine is greedy and stable: the same input gives the same route', function()
    local a = build(EI, { rows = rowsToday(), target = 16 })
    local b = build(EI, { rows = rowsToday(), target = 16 })
    T.eq(#a.steps, #b.steps)
    for i = 1, #a.steps do T.eq(a.steps[i].earns, b.steps[i].earns); T.eq(a.steps[i].hours, b.steps[i].hours) end
  end)
  T.it('ties go to the played character', function()
    local rows = { row(C1, { name = 'A', class = 'MAGE', level = 24, xp = 0, xpMax = 31700, professions = {} }),
      row(C2, { name = 'B', class = 'ROGUE', level = 24, xp = 0, xpMax = 31700, isPlayer = true, professions = {} }) }
    T.eq(build(EI, { rows = rows, target = 'next' }).steps[1].row.guid, C2)
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4a: /ei next, auto mode', function()
  T.it('prints the route with its target, the earned count and the rules count', function()
    local W = session({ eidb = today() })
    local out = run(W, 'next')
    T.truthy(find(out, 'next (fastest route to 16 Legacy points; 1 earned [inferred'), dump(out))
    T.truthy(find(out, '18 rules, 11 unverified: /ei rules'), dump(out))
    T.truthy(find(out, '1. Cee Two Priest 6: level 10, then Tailoring 56 -> 150 (train Journeyman): +1 (Journeyman Tailor), ~'), dump(out))
    T.truthy(find(out, '[estimate; unverified: L-4 L-5 L-15 L-16 L-17]'), dump(out))
    T.truthy(find(out, 'Next reward at 15: Air Rifle.'), dump(out))
  end)
  T.it('at most 10 steps, then "... and N more steps"', function()
    local W = session({ eidb = today() })
    local out = run(W, 'next')
    T.truthy(find(out, '10. '), dump(out))
    T.falsy(find(out, '11. '))
    T.truthy(find(out, 'more step'), dump(out))
  end)
  T.it('Legacy lock (D-052): before the unlock no Legacy function is called', function()
    local W = session({ launch = true, legacy25 = 'list', eidb = db({ [C2] = c2() }) })
    W.calls.GetCategoryList = nil
    local out = run(W, 'next')
    T.isnil(W.calls.GetCategoryList)
    T.truthy(find(out, 'Legacy not unlocked yet'), dump(out))
    T.truthy(find(out, '1. Cee Two Priest 6: level 25: +1 (Novice Priest)'), dump(out))
  end)
  T.it('after the unlock it reads the Legacy challenges and uses the game\'s count', function()
    local W = session({ launch = true, legacy25 = 'ids', char = { level = 27, xp = 0, xpMax = 38900, rest = 0, resting = true, class = 'PALADIN', classLoc = 'Paladin' } })
    local out = run(W, 'next')
    T.truthy((W.calls.GetCategoryList or 0) >= 1, 'read')
    T.truthy(find(out, '1 earned [game]'), dump(out))
    T.truthy(find(out, 'Novice Spelunker: 1 dungeon left'), dump(out))
  end)
  T.it('in combat it does not read and says so; the route still answers', function()
    local W = session({ launch = true, legacy25 = 'ids', eidb = today() })
    W.combat = true
    local out = run(W, 'next')
    T.truthy(find(out, 'Legacy not read (in combat)'), dump(out))
    T.truthy(find(out, '[inferred'), dump(out))
    T.truthy(find(out, '1. '), dump(out))
  end)
  T.it('an error inside the read callback is shown, not hidden', function()
    local W, EI = session({ launch = true, legacy25 = 'ids', eidb = today() })
    EI.Route.Build = function() error('boom') end
    local out = run(W, 'next')
    T.truthy(find(out, 'UNEXPECTED: /ei next failed:'), dump(out))
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4a: /ei plan and my plan', function()
  T.it('/ei plan help shows the settings and the commands', function()
    local W = session({ eidb = today() })
    local out = run(W, 'plan help')
    T.truthy(find(out, 'plan: mode auto (fastest route), target 16, my plan 0 steps, ignored: none'), dump(out))
    T.truthy(find(out, '/ei plan copy'), dump(out))
  end)
  T.it('mode and target are saved; bad values are refused and not saved', function()
    local W = session({ eidb = today() })
    run(W, 'plan mode mine')
    run(W, 'plan target reward')
    T.eq(W.env.EmpireIntelDB.plan.mode, 'mine')
    T.eq(W.env.EmpireIntelDB.plan.target, 'reward')
    run(W, 'plan target 25')
    T.eq(W.env.EmpireIntelDB.plan.target, 25)
    local out = run(W, 'plan target 99')
    T.truthy(find(out, 'target must be'), dump(out))
    out = run(W, 'plan mode fast')
    T.truthy(find(out, 'mode must be auto or mine'), dump(out))
    T.eq(W.env.EmpireIntelDB.plan.mode, 'mine')
  end)
  T.it('an empty plan in mine mode says how to fill it', function()
    local W = session({ eidb = today() })
    run(W, 'plan mode mine')
    T.truthy(find(run(W, 'next'), 'my plan: no steps'))
  end)
  T.it('copy saves the route by GUID; mine mode then shows the steps with estimates', function()
    local W = session({ eidb = today() })
    local out = run(W, 'plan copy')
    T.truthy(find(out, 'copied the fastest route into my plan'), dump(out))
    local mine = W.env.EmpireIntelDB.plan.mine
    T.eq(mine[1], { kind = 'level', guid = C2, level = 10 })
    T.eq(mine[2], { kind = 'skill', guid = C2, profession = 'Tailoring', skill = 150 })
    for _, e in ipairs(mine) do T.falsy(e.name, 'no names are saved') end
    T.truthy(find(out, 'dungeon step'), 'dungeon steps without an id are left out and counted: ' .. dump(out))
    run(W, 'plan mode mine')
    out = run(W, 'next')
    T.truthy(find(out, 'next (my plan: '), dump(out))
    T.truthy(find(out, '1. Cee Two Priest 6 -> level 10: 4 levels to go'), dump(out))
    T.truthy(find(out, '2. Cee Two Priest 6 -> Tailoring 150: now 56/75, 94 to go; train to raise max 75 -> earns Journeyman Tailor (1 Legacy point); ~'), dump(out))
  end)
  T.it('top, remove and clear change the order; a bad number is refused', function()
    local W = session({ eidb = today() })
    run(W, 'plan copy')
    local mine = W.env.EmpireIntelDB.plan.mine
    local first, second = mine[1], mine[2]
    -- D-063 item 1: Tailoring 150 needs level 10 (L-4), so the level step moves to the top with it
    local out = run(W, 'plan top 2')
    T.eq(W.env.EmpireIntelDB.plan.mine[1], first)
    T.eq(W.env.EmpireIntelDB.plan.mine[2], second)
    T.truthy(find(out, 'Moved with it: Cee Two Level 10 (prerequisite of Cee Two Tailoring 150 (Journeyman needs level 10, L-4))'), dump(out))
    local n = #W.env.EmpireIntelDB.plan.mine
    out = run(W, 'plan remove 1')
    T.truthy(find(out, 'not removed: Cee Two Tailoring 150 needs level 10 first'), dump(out))
    T.eq(#W.env.EmpireIntelDB.plan.mine, n)
    run(W, 'plan remove 2')
    T.eq(#W.env.EmpireIntelDB.plan.mine, n - 1)
    T.truthy(find(run(W, 'plan remove 99'), 'no step 99'))
    run(W, 'plan clear')
    T.eq(W.env.EmpireIntelDB.plan.mine, {})
  end)
  T.it('ignore and unignore save the GUID; the route says how many are ignored', function()
    local W = session({ eidb = today() })
    local out = run(W, 'plan ignore cee two')
    T.truthy(find(out, 'Cee Two is left out of the fastest route'), dump(out))
    T.eq(W.env.EmpireIntelDB.plan.ignore, { [C2] = true })
    T.truthy(find(run(W, 'next'), '(1 character ignored)'))
    run(W, 'plan unignore cee two')
    T.eq(W.env.EmpireIntelDB.plan.ignore, {})
    T.truthy(find(run(W, 'plan ignore nobody'), 'no character named "nobody"'))
  end)
  T.it('a met step is counted, not shown; a bad saved step is one UNEXPECTED line and skipped', function()
    local plan = { mode = 'mine', mine = {
      { kind = 'level', guid = C1, level = 20 },
      { kind = 'level', guid = C1, level = 45 },
      { kind = 'level', guid = 'Player-1-99999999', level = 30 },
      { kind = 'skill', guid = C2, profession = 'Jewelcrafting', skill = 50 },
      { kind = 'perk', guid = C1 },
      { kind = 'level', guid = C1, level = 45, name = 'Cee One' },
    } }
    local W = session({ eidb = db({ [C1] = c1(), [C2] = c2() }, plan) })
    local out = run(W, 'next')
    T.truthy(find(out, 'UNEXPECTED plan step 3: the character is no longer known (skipped)'), dump(out))
    T.truthy(find(out, 'UNEXPECTED plan step 4: unknown profession "Jewelcrafting" (skipped)'), dump(out))
    T.truthy(find(out, 'UNEXPECTED plan step 5: unknown kind "perk" (skipped)'), dump(out))
    T.truthy(find(out, 'UNEXPECTED plan step 6: unknown key "name" (skipped)'), dump(out))
    T.truthy(find(out, 'next (my plan: 6 steps; 1 met, 4 skipped):'), dump(out))
    T.truthy(find(out, '2. Cee One Paladin 27 -> level 45: 18 levels to go'), dump(out))
  end)
  T.it('a challenge step reads its progress from the game after the unlock', function()
    local plan = { mode = 'mine', mine = { { kind = 'challenge', id = 62031 } } }
    local W = session({ launch = true, legacy25 = 'ids', eidb = db({ [C1] = c1() }, plan) })
    local out = run(W, 'next')
    T.truthy(find(out, 'Account -> Novice Spelunker: 1 of 2 done'), dump(out))
  end)
  T.it('/ei rules lists every rule with its status and source', function()
    local W = session({})
    local out = run(W, 'rules')
    T.truthy(find(out, 'rules: 18 planner rules, 11 unverified'), dump(out))
    T.truthy(find(out, 'L-17 [unverified] While rested, kills give double XP'), dump(out))
    T.truthy(find(out, 'L-11 [user] Explorer'), dump(out))
    T.eq(#out, 19)
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4a: measured XP rate (Q-F2)', function()
  T.it('is saved after 30 minutes and a level gained, from the snapshot\'s own readings', function()
    local W = session({ ctimer = true, char = { level = 10, xp = 0, xpMax = 7600, rest = 0, resting = false } })
    local guid = 'Player-1-00000001'
    T.isnil(W.env.EmpireIntelDB.plan.rates)
    W.char.level, W.char.xp, W.char.xpMax = 11, 3800, 8800       -- 7600 + 3800 XP gained
    W:advance(1200)
    W.env.SlashCmdList.EMPIREINTEL('')
    T.isnil((W.env.EmpireIntelDB.plan.rates or {})[guid], 'not before 30 minutes')
    W:advance(900)
    local r = W.env.EmpireIntelDB.plan.rates[guid]
    T.truthy(r, 'saved')
    T.truthy(r.xpPerHour > 15000 and r.xpPerHour < 25000, tostring(r.xpPerHour))
    local keys = {}
    for k in pairs(r) do keys[#keys + 1] = k end
    table.sort(keys)
    T.eq(keys, { 'at', 'xpPerHour' }, 'exactly the format-2 fields')
  end)
  T.it('no level gained, no rate', function()
    local W = session({ ctimer = true, char = { level = 10, xp = 0, xpMax = 7600, rest = 0, resting = false } })
    W.char.xp = 7000
    W:advance(2000)
    T.isnil((W.env.EmpireIntelDB.plan.rates or {})['Player-1-00000001'])
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4a static rules', function()
  local DIR = root .. '/EmpireIntel/'
  local function code(f)
    local h = assert(io.open(DIR .. f, 'rb')); local s = h:read('*a'); h:close()
    return (s:gsub('%-%-[^\n]*', ''))
  end
  T.it('the rules table, the engine and the plan make no game call', function()
    for _, f in ipairs({ 'Core/RouteRules.lua', 'Core/Route.lua', 'Core/Plan.lua', 'Core/Next.lua' }) do
      local c = code(f)
      for _, bad in ipairs({ 'P.Call', 'P.CallIn', 'P.env', 'P.fn', 'EmpireIntelDB', 'DataStoreBridge' }) do
        T.falsy(c:find(bad, 1, true), bad .. ' in ' .. f)
      end
    end
  end)
  T.it('the rules table and the engine are pure: no Platform and no saved data', function()
    for _, f in ipairs({ 'Core/RouteRules.lua', 'Core/Route.lua' }) do
      local c = code(f)
      T.falsy(c:find('P%.'), f)
      T.falsy(c:find('Store', 1, true), f)
    end
  end)
  T.it('Next reads Legacy only through P3-1\'s read', function()
    local c = code('Core/Next.lua')
    T.truthy(c:find('P.Legacy.Read', 1, true))
    for _, n in ipairs({ 'GetCategoryList', 'GetAchievementInfo', 'LegacySystem' }) do T.falsy(c:find(n, 1, true), n) end
  end)
  T.it('P2-4a had no window code (D-056); from 0.7.0 the P2-4b static rules apply (test_ei_window.lua)', function()
    T.truthy(io.open(root .. '/Tests/test_ei_window.lua'), 'the P2-4b rules exist')
  end)
end)
