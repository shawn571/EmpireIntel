-- EmpireIntel / Tests / test_ei_next.lua
-- Behaviour of increment P2-4 (Phase2_Plan.md section 7, D-052): the plan file (format 1), /ei next with and
-- without a plan, the Legacy lock rule, and the EmpireIntel_Plan folder.
local T, F, root = ...

local WALL = 1800000000

local function session(opts)
  opts = opts or {}
  opts.char = opts.char or { level = 4, xp = 86, xpMax = 2100, rest = 500, resting = true }
  local W = F.new(opts)
  W.prints = {}
  W.env.print = function(...) local t = {}; for i = 1, select('#', ...) do t[i] = tostring((select(i, ...))) end; table.insert(W.prints, table.concat(t, ' ')) end
  local EI = F.loadAddon(W, 'EmpireIntel')
  W:fire('PLAYER_LOGIN')
  W:fire('PLAYER_ENTERING_WORLD', true, false)
  W:advance(3)
  return W, EI
end
local function next_(W)
  local from = #W.prints
  W.env.SlashCmdList.EMPIREINTEL('next')
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
local function count(lines, text)
  local n = 0
  for _, l in ipairs(lines) do if l:find(text, 1, true) then n = n + 1 end end
  return n
end

-- runs Lua source in the fake client's global table (as the game runs Plan.lua)
local function runIn(W, src, name)
  local chunk
  if setfenv then
    chunk = assert(loadstring(src, name))
    setfenv(chunk, W.env)
  else
    chunk = assert(load(src, name, 't', W.env))
  end
  return pcall(chunk)
end
local function readFile(path)
  local f = assert(io.open(path, 'rb')); local s = f:read('*a'); f:close(); return s
end
-- installs the plan folder: the marker, then the plan text (nil = no Plan.lua global, as after a Lua error)
local function install(W, planSrc)
  assert(runIn(W, readFile(root .. '/EmpireIntel_Plan/Marker.lua'), 'Marker.lua'))
  if planSrc then assert(runIn(W, planSrc, 'Plan.lua')) end
end
local function plan(goals) return 'EmpireIntelPlan = { version = 1, goals = { ' .. goals .. ' } }' end

local function rec(t)
  local r = { realm = 'Test Realm', src = 'self', lastSeen = WALL - 3600, restAt = WALL - 3600 }
  for k, v in pairs(t) do r[k] = v end
  return r
end
local function roster(recs) return { schema = 1, meta = {}, roster = recs } end
-- the account after the unlock: a Paladin 27 and a Priest 6 (the user's C1 and C2, renamed)
local function unlocked()
  return roster({
    ['Player-1-00000011'] = rec({ name = 'Cee One', class = 'PALADIN', level = 27, xp = 0, xpMax = 40000, rest = 0, resting = true,
      professions = { { name = 'Mining', skill = 41, max = 75, line = 186 }, { name = 'Skinning', skill = 77, max = 150, line = 393 } } }),
    ['Player-1-00000012'] = rec({ name = 'Cee Two', class = 'PRIEST', level = 6, xp = 0, xpMax = 3600, rest = 1842, resting = true,
      restAt = WALL - 3600, professions = { { name = 'Tailoring', skill = 56, max = 75, line = 197 }, { name = 'Enchanting', skill = 28, max = 75, line = 333 } } }),
  })
end
-- before the unlock: the same two, the Paladin at 22
local function locked()
  local r = unlocked()
  r.roster['Player-1-00000011'].level = 22
  return r
end

---------------------------------------------------------------------------
T.describe('P2-4: the plan folder', function()
  T.it('the TOC loads the marker, then Plan.lua; Interface 16001; no dependency on EmpireIntel', function()
    local toc = readFile(root .. '/EmpireIntel_Plan/EmpireIntel_Plan.toc')
    T.truthy(toc:find('## Interface: 16001', 1, true))
    T.truthy(toc:find('Marker.lua\nPlan.lua', 1, true))
    T.falsy(toc:find('Dependencies', 1, true) or toc:find('SavedVariables', 1, true))
  end)
  T.it('the shipped example loads and every goal is valid (names C1 and C2)', function()
    local W, EI = session({ eidb = roster({
      ['Player-1-00000011'] = rec({ name = 'C1', class = 'PALADIN', level = 27, xpMax = 40000 }),
      ['Player-1-00000012'] = rec({ name = 'C2', class = 'PRIEST', level = 6, xpMax = 3600, professions = {} }) }) })
    install(W, readFile(root .. '/EmpireIntel_Plan/Plan.lua'))
    local p = EI.Plan.Load(EI.Views.Collect())
    T.eq(p.state, 'ok')
    T.eq(p.total, 5)
    T.eq(#p.goals, 5, dump(p.problems))
    T.eq(#p.problems, 0)
  end)
  T.it('its only globals are EmpireIntelPlan and EmpireIntelPlanFolder', function()
    local W = session({})
    local before = {}
    for k in pairs(W.env) do before[k] = true end
    install(W, readFile(root .. '/EmpireIntel_Plan/Plan.lua'))
    local added = {}
    for k in pairs(W.env) do if not before[k] then added[#added + 1] = k end end
    table.sort(added)
    T.eq(added, { 'EmpireIntelPlan', 'EmpireIntelPlanFolder' })
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4: plan file format 1, validation', function()
  local function problems(goals, opts)
    local W, EI = session(opts or { eidb = unlocked() })
    install(W, plan(goals))
    local p = EI.Plan.Load(EI.Views.Collect())
    return p, p.problems
  end
  T.it('each bad goal is one UNEXPECTED line naming its number, and is skipped', function()
    local p, pr = problems([[
      { char = 'Cee One', level = 45 },
      { char = 'Cee Two', profession = 'Tailoring', skil = 150 },
      { char = 'Cee Two', level = 'high' },
      { char = 'Nobody', level = 30 },
      { char = 'Cee Two', level = 99 },
      { char = 'Cee Two' },
      { char = 'Cee Two', level = 25, rested = 1 },
      { char = 'Cee Two', profession = 'Jewelcrafting', skill = 50 },
      { char = 'Cee One', perk = 'Some Perk' },
      { account = true, challenges = 70 },
      { challenges = 5 },
      { char = 'Cee Two', rested = 2 },
      { level = 30 },
      { char = 'Cee Two', profession = 'tailoring', skill = 150 },
    ]])
    T.eq(p.total, 14)
    T.eq(p.skipped, 12)
    T.eq(#p.goals, 2)
    T.eq(pr[1], 'UNEXPECTED plan goal 2: unknown key "skil" (skipped)')
    T.eq(pr[2], 'UNEXPECTED plan goal 3: "level" must be a number (skipped)')
    T.eq(pr[3], 'UNEXPECTED plan goal 4: no character named "Nobody" (skipped)')
    T.eq(pr[4], 'UNEXPECTED plan goal 5: "level" must be 2 to 60 (skipped)')
    T.eq(pr[5], 'UNEXPECTED plan goal 6: no goal (level, profession and skill, rested, or account and challenges) (skipped)')
    T.eq(pr[6], 'UNEXPECTED plan goal 7: more than one goal in one entry (skipped)')
    T.eq(pr[7], 'UNEXPECTED plan goal 8: unknown profession "Jewelcrafting" (skipped)')
    T.eq(pr[8], 'UNEXPECTED plan goal 9: perk goals are not supported yet (needs Q-T4) (skipped)')
    T.eq(pr[9], 'UNEXPECTED plan goal 10: "challenges" must be 1 to 65 (skipped)')
    T.eq(pr[10], 'UNEXPECTED plan goal 11: a challenges goal needs account = true (skipped)')
    T.eq(pr[11], 'UNEXPECTED plan goal 12: "rested" must be 0.05 to 1.5 levels (skipped)')
    T.eq(pr[12], 'UNEXPECTED plan goal 13: no "char" (skipped)')
    T.eq(p.goals[2].profession, 'Tailoring', 'profession names are matched without case')
    T.eq(p.goals[2].n, 14)
  end)
  T.it('two characters with one name: UNEXPECTED unless written Name-Realm', function()
    local db = unlocked()
    db.roster['Player-1-00000013'] = rec({ name = 'Cee Two', realm = 'Other Realm', class = 'MAGE', level = 10, xpMax = 7000 })
    local p, pr = problems("{ char = 'Cee Two', level = 30 }, { char = 'cee two-other realm', level = 30 }", { eidb = db })
    T.eq(pr[1], 'UNEXPECTED plan goal 1: two characters are named "Cee Two"; write it as Name-Realm (skipped)')
    T.eq(#p.goals, 1)
    T.eq(p.goals[1].row.class, 'MAGE')
  end)
  T.it('a wrong version or no goals table: one UNEXPECTED line, then the defaults', function()
    local W = session({ eidb = unlocked() })
    install(W, 'EmpireIntelPlan = { version = 2, goals = {} }')
    local out = next_(W)
    T.eq(out[1], 'UNEXPECTED plan file: version 2, this EmpireIntel reads version 1. Showing default suggestions.')
    T.eq(out[2], 'next (default suggestions):')
    local W2 = session({ eidb = unlocked() })
    install(W2, 'EmpireIntelPlan = { version = 1 }')
    T.eq(next_(W2)[1], 'UNEXPECTED plan file: no goals table. Showing default suggestions.')
  end)
  T.it('the folder is installed but Plan.lua did not load: UNEXPECTED, then the defaults', function()
    local W = session({ eidb = unlocked() })
    install(W, nil)
    local out = next_(W)
    T.eq(out[1], 'UNEXPECTED plan file did not load (a Lua error in Plan.lua; BugSack shows the line). Showing default suggestions.')
    T.eq(out[2], 'next (default suggestions):')
    T.falsy(find(out, 'Add EmpireIntel_Plan'), dump(out))
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4: /ei next with a plan', function()
  local W = session({ eidb = unlocked(), legacy25 = 'ids' })
  install(W, plan([[
    { char = 'Cee One', level = 45, note = 'Experienced Paladin' },
    { char = 'Cee Two', level = 25 },
    { char = 'Cee Two', profession = 'Tailoring', skill = 150 },
    { char = 'Cee Two', rested = 1.0 },
    { account = true, challenges = 3 },
    { char = 'Cee One', level = 20 },
    { char = 'Cee One', profession = 'Cooking', skill = 50 },
  ]]))
  local out = next_(W)
  T.it('header: goals, met and skipped; the plan order is kept and numbered', function()
    T.truthy(find(out, 'next: reading Legacy challenges (about 2 seconds).'), dump(out))
    T.truthy(find(out, 'next (your plan: 7 goals; 1 met, 0 skipped):'), dump(out))
    T.eq(count(out, '. Cee '), 5, dump(out))
  end)
  T.it('a level goal: levels to go, rested now, what it earns, the note', function()
    T.truthy(find(out, '1. Cee One Paladin 27 -> level 45: 18 levels to go; about 0.01 levels rested [estimate] -> earns Experienced Paladin (1 Legacy point) (note: Experienced Paladin)'), dump(out))
    T.truthy(find(out, '2. Cee Two Priest 6 -> level 25: 19 levels to go; about 0.52 levels rested [estimate] -> earns Novice Priest (1 Legacy point)'), dump(out))
  end)
  T.it('a skill goal: now/max, to go, train to raise max, what it earns', function()
    T.truthy(find(out, '3. Cee Two Priest 6 -> Tailoring 150: now 56/75, 94 to go; train to raise max 75 -> earns Journeyman Tailor (1 Legacy point)'), dump(out))
  end)
  T.it('a rested goal: now and the hours in an inn, both estimates', function()
    T.truthy(find(out, '4. Cee Two Priest 6 -> rested 1.00 levels: about 0.52 now [estimate]; about 77 h more in an inn [estimate]'), dump(out))
  end)
  T.it('after the unlock, the challenges goal is read: done, to go, the closest (on a character below 25)', function()
    T.truthy(find(out, '5. Account -> 3 Legacy challenges: 1 done, 2 to go; closest: Novice Spelunker 1 of 2 (left: Wailing Caverns)'), dump(out))
    T.eq(W.calls.GetCategoryList, 1)
  end)
  T.it('a met goal is counted, not listed; a secondary skill not learned yet, no Legacy point', function()
    T.falsy(find(out, 'level 20'), dump(out))
    T.truthy(find(out, '6. Cee One Paladin 27 -> Cooking 50: not learned yet; 50 to go'), dump(out))
    T.falsy(find(out, 'Cooking 50: not learned yet; 50 to go ->'), 'Cooking earns no Legacy point')
    T.falsy(find(out, 'UNEXPECTED'), dump(out))
  end)
end)

T.describe('P2-4: plan goals, other cases', function()
  T.it('every goal met', function()
    local W = session({ eidb = unlocked() })
    install(W, plan("{ char = 'Cee One', level = 20 }, { char = 'Cee Two', profession = 'Tailoring', skill = 50 }"))
    local out = next_(W)
    T.truthy(find(out, 'next (your plan: 2 goals; 2 met, 0 skipped):'), dump(out))
    T.truthy(find(out, 'All 2 goals in your plan are met.'), dump(out))
  end)
  T.it('a challenges goal is met at exactly the count, and not one below', function()
    local W = session({ eidb = unlocked(), legacy25 = 'ids' })
    install(W, plan('{ account = true, challenges = 1 }, { account = true, challenges = 2 }'))
    local out = next_(W)
    T.truthy(find(out, 'next (your plan: 2 goals; 1 met, 0 skipped):'), dump(out))
    T.truthy(find(out, '1. Account -> 2 Legacy challenges: 1 done, 1 to go'), dump(out))
  end)
  T.it('a plan with no goals: says so, then the defaults', function()
    local W = session({ eidb = unlocked() })
    install(W, plan(''))
    local out = next_(W)
    T.eq(out[1], 'Your plan has no goals.')
    T.eq(out[2], 'next (default suggestions):')
  end)
  T.it('more than 10 unmet goals: the first 10, then how many more', function()
    local g = {}
    for i = 30, 41 do g[#g + 1] = "{ char = 'Cee One', level = " .. i .. " }" end
    local W = session({ eidb = unlocked() })
    install(W, plan(table.concat(g, ', ')))
    local out = next_(W)
    T.truthy(find(out, '10. Cee One Paladin 27 -> level 39'), dump(out))
    T.falsy(find(out, '11. '), dump(out))
    T.truthy(find(out, '... and 2 more'), dump(out))
  end)
  T.it('a DataStore character: its source and age; a profession DataStore does not keep is unknown, never met', function()
    local W = session({ eidb = unlocked(), datastore = 'good' })
    install(W, plan("{ char = 'Alt Two', level = 50 }, { char = 'Alt Two', profession = 'Cooking', skill = 1 }"))
    local out = next_(W)
    T.truthy(find(out, '1. Alt Two Mage 45 -> level 50: 5 levels to go'), dump(out))
    T.truthy(find(out, '[datastore, '), dump(out))
    T.truthy(find(out, '2. Alt Two Mage 45 -> Cooking 1: unknown (DataStore keeps primary professions only)'), dump(out))
    T.truthy(find(out, '0 met'), dump(out))
  end)
  T.it('the player: live rested XP, no estimate label', function()
    local W = session({ eidb = unlocked() })
    install(W, plan("{ char = 'Testchar Tester', level = 10 }"))
    local out = next_(W)
    T.truthy(find(out, '1. Testchar Tester Warrior 4 -> level 10: 6 levels to go; 0.24 levels rested now'), dump(out))
  end)
  T.it('a level-60 character: a rested goal is unknown (no rested XP), never met', function()
    local db = unlocked()
    db.roster['Player-1-00000014'] = rec({ name = 'Old Hand', class = 'WARRIOR', level = 60, xp = 0, xpMax = 0 })
    local W = session({ eidb = db })
    install(W, plan("{ char = 'Old Hand', rested = 0.5 }"))
    local out = next_(W)
    T.truthy(find(out, '1. Old Hand Warrior 60 -> rested 0.50 levels: unknown (max level, no rested XP)'), dump(out))
  end)
  T.it('in combat the challenges goal is not read and says so', function()
    local W = session({ eidb = unlocked(), legacy25 = 'ids' })
    install(W, plan('{ account = true, challenges = 3 }'))
    W:fire('PLAYER_REGEN_DISABLED')
    local out = next_(W)
    T.truthy(find(out, '1. Account -> 3 Legacy challenges: not read (in combat); try /ei next again after combat'), dump(out))
    T.isnil(W.calls.GetCategoryList)
  end)
  T.it('no challenges goal: no Legacy read', function()
    local W = session({ eidb = unlocked(), legacy25 = 'ids' })
    install(W, plan("{ char = 'Cee One', level = 45 }"))
    next_(W)
    T.isnil(W.calls.GetCategoryList)
    T.isnil(W.calls['LegacySystem.GetCurrencyInfo'])
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4: the Legacy lock rule (D-052)', function()
  T.it('before any character reaches 25: the challenges goal says "Legacy not unlocked yet", is never met, and nothing is read', function()
    local W = session({ eidb = locked(), legacy25 = 'ids' })
    install(W, plan('{ account = true, challenges = 1 }'))
    local out = next_(W)
    T.truthy(find(out, 'next (your plan: 1 goal; 0 met, 0 skipped; Legacy not unlocked yet):'), dump(out))
    T.truthy(find(out, '1. Account -> 1 Legacy challenge: Legacy not unlocked yet'), dump(out))
    T.isnil(W.calls.GetCategoryList)
    T.isnil(W.calls['LegacySystem.GetCurrencyInfo'])
    T.falsy(find(out, 'reading Legacy'), dump(out))
  end)
  T.it('before the unlock, the defaults lead with reach 25 (the closest character)', function()
    local W = session({ eidb = locked() })
    local out = next_(W)
    T.eq(out[1], 'next (no plan file: default suggestions; Legacy not unlocked yet):')
    T.eq(out[2], '1. Reach 25: Cee One Paladin 22 -> 25 (3 levels to go) unlocks Legacy for the account')
    T.falsy(find(out, 'Class milestone'), dump(out))
  end)
  T.it('once one character has reached 25 (even only in DataStore), Legacy is available on every character', function()
    local db = locked()
    local W = session({ eidb = db, datastore = 'good', legacy25 = 'ids' })   -- Alt Two, Mage 45, only in DataStore
    install(W, plan('{ account = true, challenges = 3 }'))
    local out = next_(W)
    T.truthy(find(out, '1. Account -> 3 Legacy challenges: 1 done, 2 to go'), dump(out))
    T.eq(W.calls.GetCategoryList, 1, 'read while logged in on a level-4 character')
  end)
  T.it('the unlock test is level 25 exactly', function()
    local db = locked()
    db.roster['Player-1-00000011'].level = 25
    local W, EI = session({ eidb = db })
    T.truthy(EI.Next.Unlocked(EI.Views.Collect()))
    db = locked()
    db.roster['Player-1-00000011'].level = 24
    W, EI = session({ eidb = db })
    T.falsy(EI.Next.Unlocked(EI.Views.Collect()))
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4: /ei next without a plan (FR-PRE-4 defaults)', function()
  local W = session({ eidb = unlocked() })
  local out = next_(W)
  T.it('header and footer', function()
    T.eq(out[1], 'next (no plan file: default suggestions):')
    T.eq(out[#out], 'Add EmpireIntel_Plan\\Plan.lua to set your own order (README).')
  end)
  T.it('after the unlock: class milestones not yet earned, closest first, at most 3', function()
    T.eq(out[2], '1. Class milestone: Cee One Paladin 27 -> 45 (18 levels) -> Experienced Paladin (1 Legacy point)')
    T.eq(out[3], '2. Class milestone: Cee Two Priest 6 -> 25 (19 levels) -> Novice Priest (1 Legacy point)')
    T.eq(out[4], '3. Class milestone: Testchar Tester Warrior 4 -> 25 (21 levels) -> Novice Warrior (1 Legacy point)')
  end)
  T.it('at most 3 class milestone lines (a fourth class, closer than none of them, is left out)', function()
    local o = next_((session({ eidb = unlocked(), datastore = 'good' })))   -- adds Alt Two, Mage 45 (15 levels to 60)
    T.eq(count(o, 'Class milestone:'), 3, dump(o))
    T.truthy(find(o, '1. Class milestone: Alt Two Mage 45 -> 60 (15 levels) -> Master Mage (1 Legacy point) [datastore, '), dump(o))
    T.falsy(find(o, 'Testchar Tester Warrior 4 -> 25'), dump(o))
  end)
  T.it('rested characters with at least 0.5 levels, most rested first', function()
    T.eq(out[5], '4. Rested: Cee Two Priest 6 has about 0.52 levels rested [estimate]: play it next')
    T.falsy(find(out, 'Rested: Cee One'), 'below 0.5 levels')
    T.falsy(find(out, 'Rested: Testchar'), 'below 0.5 levels (0.24)')
  end)
  T.it('crafting: none within 25 points, so the closest is named', function()
    T.eq(out[6], '5. Crafting: nothing within 25 points of a milestone (closest: Cee Two Tailoring 56/75 -> 150 (94 to go; train to raise max 75))')
  end)
  T.it('crafting within 25 points is listed with what it earns', function()
    local db = unlocked()
    db.roster['Player-1-00000012'].professions[1].skill = 140
    db.roster['Player-1-00000012'].professions[1].max = 150
    local o = next_((session({ eidb = db })))
    T.truthy(find(o, 'Crafting: Cee Two Tailoring 140/150 -> 150 (10 to go) -> Journeyman Tailor (1 Legacy point)'), dump(o))
  end)
end)
