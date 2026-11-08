-- EmpireIntel / Tests / test_ei_legacy.lua
-- Behaviour of increment P3-1 (Phase3_Legacy_Plan.md section 3): /ei legacy, read on command, nothing saved.
-- The fixture is the level-25 profile the check was proven against (runs 7-15, fakeclient legacy25).
local T, F = ...

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
local function legacy(W, msg)
  local from = #W.prints
  W.env.SlashCmdList.EMPIREINTEL(msg or 'legacy')
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
local function paladin()
  return { schema = 1, meta = {}, roster = { ['Player-1-00000009'] = { name = 'Pal Adin', realm = 'Test Realm', class = 'PALADIN',
    level = 26, xp = 10, xpMax = 36000, lastSeen = WALL - 60, restAt = WALL - 60, src = 'self',
    professions = { { name = 'Tailoring', skill = 56, max = 75, line = 197 } } } } }
end

T.describe('P3-1: /ei legacy with the Legacy window loaded', function()
  local W, EI = session({ legacy25 = 'ids', eidb = paladin() })
  local out = legacy(W)
  T.it('says it is reading, then gives earned, available and spent', function()
    T.truthy(find(out, 'legacy: reading (about 2 seconds).'), dump(out))
    T.truthy(find(out, 'Legacy: 1 of 5 points earned; 1 available, 0 spent. [pane loaded]'), dump(out))
    T.falsy(find(out, 'UNEXPECTED'), dump(out))
  end)
  T.it('counts challenges per group; hidden categories stay out', function()
    T.truthy(find(out, 'Classes 1/2 | Dungeons 0/1 | Raids 0/1 | Adventure 0/1'), dump(out))
  end)
  T.it('lists the closest challenges with what is left', function()
    T.truthy(find(out, 'Closest: Novice Spelunker 1 of 2 (left: Wailing Caverns)'), dump(out))
    T.truthy(find(out, 'Explorer 1 of 6 on this character'), dump(out))
    T.truthy(find(out, "Experienced Paladin: Pal Adin is 26 of 45 [from EmpireIntel's records]"), dump(out))
  end)
  T.it('never shows spentInTree, maxQuantity or renownCurrency', function()
    for _, l in ipairs(out) do
      T.falsy(l:find('spentInTree', 1, true) or l:find('renown', 1, true) or l:find('maxQuantity', 1, true), l)
    end
  end)
  T.it('the zero-argument currency call only; no ordinary currency call; no Update or Register call', function()
    T.eq(W.calls['LegacySystem.GetCurrencyInfo'], 1)
    T.isnil(W.calls['C_CurrencyInfo.GetCurrencyInfo'])
    T.isnil(W.calls['C_CurrencyInfo.GetCurrencyListSize'])
    T.isnil(W.calls['SetCurrencyBackpack!'])
    T.eq(W.badArgs, 0, 'every argument was a number the game returned')
  end)
  T.it('the read is spread over frames', function()
    T.truthy((EI.Platform.Legacy.last.calls.total or 0) > EI.Platform.Legacy.PER_SLICE, 'more calls than one slice')
  end)
end)

T.describe('P3-1: /ei legacy all', function()
  local W = session({ legacy25 = 'ids' })
  local out = legacy(W, 'legacy all')
  T.it('one line per challenge: done, steps left, or not done', function()
    T.truthy(find(out, '[Paladin] Novice Paladin: done'), dump(out))
    T.truthy(find(out, '[Paladin] Experienced Paladin: not done'), dump(out))
    T.truthy(find(out, '[Dungeons] Novice Spelunker: 1 of 2 (left: Wailing Caverns)'), dump(out))
    T.truthy(find(out, '[Raids] Conqueror of the Lair: not done'), dump(out))
    T.truthy(find(out, '[Adventure] Explorer: 1 of 6 on this character'), dump(out))
    T.falsy(find(out, 'Internal'), 'hidden challenges are not listed')
    local n = 0
    for _, l in ipairs(out) do if l:find('^%[') then n = n + 1 end end
    T.eq(n, 5)
  end)
end)

T.describe('P3-1: without the Legacy window, in combat, and on faults', function()
  T.it('before the window is opened: challenges still show, points say how to get them', function()
    local W = session({ legacy25 = 'list' })
    local out = legacy(W)
    T.truthy(find(out, 'Legacy: 1 of 5 points earned; available and spent: open the Legacy window once this session.'), dump(out))
    T.truthy(find(out, 'Closest: Novice Spelunker'), dump(out))
  end)
  T.it('in combat nothing is read', function()
    local W = session({ legacy25 = 'ids' })
    W:fire('PLAYER_REGEN_DISABLED')
    local n = W.calls.GetCategoryList
    local out = legacy(W)
    T.truthy(find(out, 'legacy: not in combat; try again after combat.'), dump(out))
    T.eq(W.calls.GetCategoryList, n)
  end)
  T.it('combat starting during the read stops it', function()
    local W, EI = session({ legacy25 = 'ids' })
    EI.Platform.Legacy.PER_SLICE = 3
    W.env.SlashCmdList.EMPIREINTEL('legacy')
    W:fire('PLAYER_REGEN_DISABLED')
    W:advance(5)
    local out = {}
    for _, l in ipairs(W.prints) do out[#out + 1] = l end
    T.truthy(find(out, 'combat started during the read; try again after combat.'), dump(out))
    T.eq(EI.Platform.Legacy.busy, false)
  end)
  T.it('a second command while reading waits', function()
    local W, EI = session({ legacy25 = 'ids' })
    EI.Platform.Legacy.PER_SLICE = 3
    W.env.SlashCmdList.EMPIREINTEL('legacy')
    W.env.SlashCmdList.EMPIREINTEL('legacy')
    T.truthy(find(W.prints, 'legacy: already reading; the answer comes in a moment.'), dump(W.prints))
    W:advance(5)
    T.eq(EI.Platform.Legacy.busy, false)
  end)
  T.it('a failing game function is one UNEXPECTED line; the rest still answers', function()
    local W = session({ legacy25 = 'ids' })
    W.env.GetAchievementNumCriteria = function() error('boom criteria') end
    local out = legacy(W)
    T.truthy(find(out, 'Legacy: 1 of 5 points earned'), dump(out))
    local u = find(out, 'game call(s) failed')
    T.truthy(u and u:find('boom criteria', 1, true), dump(out))
  end)
  T.it('the pane counting a different earned total is UNEXPECTED', function()
    local W = session({ legacy25 = 'ids' })
    W.env.LegacySystem.GetCurrencyInfo = function() return { quantity = 0, maxQuantity = 3, renownCurrency = 3, spent = 3, spentInTree = 0 } end
    local out = legacy(W)
    T.truthy(find(out, 'UNEXPECTED: the pane counts 3 earned, the challenges 1.'), dump(out))
  end)
  T.it('without a recognizable Legacy reward text nothing is counted, and it says so', function()
    local W = session({ legacy25 = 'ids' })
    local real = W.env.GetAchievementInfo
    W.env.GetAchievementInfo = function(...)
      local t = { real(...) }
      if t[11] ~= nil then t[11] = 'Erhalte 1 Punkt.' end
      return (unpack or table.unpack)(t, 1, 15)
    end
    local out = legacy(W)
    T.truthy(find(out, 'UNEXPECTED: no Legacy reward text recognized'), dump(out))
    T.falsy(find(out, 'points earned'), dump(out))
  end)
  T.it('an error inside the reader is reported and the reader is free again', function()
    local W, EI = session({ legacy25 = 'ids' })
    EI.Platform.Legacy.Link = function() error('reader broke') end
    local out = legacy(W)
    T.truthy(find(out, 'UNEXPECTED: the Legacy read stopped:') and find(out, 'reader broke'), dump(out))
    T.eq(EI.Platform.Legacy.busy, false)
  end)
end)

T.describe('P3-1: limits and saved data', function()
  T.it('nothing is saved: EmpireIntelDB is unchanged by /ei legacy', function()
    local W, EI = session({ legacy25 = 'ids' })
    local before = EI.Platform.Util.deepCopy(W.env.EmpireIntelDB)
    legacy(W); legacy(W, 'legacy all')
    T.truthy(EI.Platform.Util.deepEqual(before, W.env.EmpireIntelDB))
  end)
  T.it('refuses a number the game did not return, a name outside the list, and the wrong argument count', function()
    local W, EI = session({ legacy25 = 'ids' })
    local L = EI.Platform.Legacy
    local st = { ids = {}, calls = 0, counts = {}, errors = {}, refused = {}, sinceYield = 0 }
    local n = W.calls.GetCategoryInfo or 0
    T.isnil(L.Call(st, 'GetCategoryInfo', 15568))
    T.eq(W.calls.GetCategoryInfo or 0, n, 'not called')
    T.isnil(L.Call(st, 'C_CurrencyInfo.GetCurrencyInfo', 4225))
    st.ids[1] = true
    T.isnil(L.Call(st, 'GetCategoryList', 1))
    T.eq(st.counts.refused, 3)
    st.ids[15568] = true
    T.truthy(L.Call(st, 'GetCategoryInfo', 15568))
  end)
  T.it('the denylist: whole CamelCase words and the Reincarnat stem', function()
    local _, EI = session({})
    local D = EI.Platform.Legacy.Denied
    T.eq(D('SetCurrencyBackpack'), 'set')
    T.eq(D('LegacySystem.UpdateCurrencyInfo'), nil, 'not a blocked word, but not in the list either')
    T.eq(D('ShowLegacyChallenge'), 'show')
    T.eq(D('StartReincarnation'), 'reincarnat')
    T.isnil(D('IsShown'))
    T.isnil(D('GetAchievementInfo'))
    for name in pairs(EI.Platform.Legacy.ALLOWED) do T.isnil(D(name), name) end
  end)
  T.it('a name the list allows but the denylist blocks is still refused', function()
    local W, EI = session({ legacy25 = 'ids' })
    local L = EI.Platform.Legacy
    local called = false
    W.env.SetFixtureThing = function() called = true end
    L.ALLOWED.SetFixtureThing = { [0] = true }
    local st = { ids = {}, calls = 0, counts = {}, errors = {}, refused = {}, sinceYield = 0 }
    T.isnil(L.Call(st, 'SetFixtureThing'))
    L.ALLOWED.SetFixtureThing = nil
    T.falsy(called)
    T.eq(st.counts.skipped_denylist, 1)
  end)
end)

T.describe('P3-1: Explorer zones on this character', function()
  T.it('counts zones with areas explored, not the roll-ups, and names the furthest', function()
    local W = session({ legacy25 = 'ids' })
    local real = W.env.GetAchievementCriteriaInfo
    W.env.GetAchievementCriteriaInfo = function(id, i)
      local t = { real(id, i) }
      if id == 627 and i == 1 then t[3] = true end            -- Kharanos explored: Dun Morogh started
      return (unpack or table.unpack)(t, 1, 11)
    end
    local out = legacy(W)
    T.truthy(find(out, 'Explorer 1 of 6 on this character (1 zones started; furthest: Dun Morogh 1/1 areas)'), dump(out))
  end)
end)

T.describe('P3-1: edge cases', function()
  T.it('a criterion whose area id equals an achievement id is not a step', function()
    local W = session({ legacy25 = 'ids' })
    local real = W.env.GetAchievementCriteriaInfo
    W.env.GetAchievementCriteriaInfo = function(id, i)
      local t = { real(id, i) }
      if id == 684 and i == 1 then t[8] = 728 end             -- Onyxia's encounter id happens to equal Explore Durotar's id
      return (unpack or table.unpack)(t, 1, 11)
    end
    local out = legacy(W, 'legacy all')
    T.truthy(find(out, '[Raids] Conqueror of the Lair: not done'), dump(out))
    T.truthy(find(out, '[Adventure] Explorer: 1 of 6 on this character'), dump(out))
  end)
  T.it('hidden categories are read only up to their cap', function()
    local W, EI = session({ legacy25 = 'ids' })
    legacy(W)
    local full = W.calls.GetAchievementInfo
    EI.Platform.Legacy.MAX_PER_EXCLUDED = 0
    legacy(W)
    T.eq(W.calls.GetAchievementInfo - full, full - 3, 'the three hidden achievements are not read')
  end)
  T.it('a challenge with a single step is not a "closest" entry', function()
    local W = session({ legacy25 = 'ids' })
    local out = legacy(W)
    T.falsy(find(out, 'Conqueror of the Lair 0 of 1'), dump(out))
  end)
  T.it('no level hint once the level is reached (the game has not marked the challenge yet)', function()
    local db = paladin()
    db.roster['Player-1-00000009'].level = 50
    local W = session({ legacy25 = 'ids', eidb = db })
    local out = legacy(W)
    T.falsy(find(out, 'Experienced Paladin: Pal Adin'), dump(out))
  end)
end)

T.describe('P3-1 (0.5.1): /ei legacy all is ordered group by group', function()
  T.it('every challenge of a group comes before the next group, sub-groups together', function()
    local W = session({ legacy25 = 'ids' })
    local out = legacy(W, 'legacy all')
    local order = {}
    for _, l in ipairs(out) do local w = l:match('^%[([^%]]+)%]'); if w then order[#order + 1] = w end end
    -- groups by id: Classes (Paladin) 15568, Dungeons 15593, Raids 15594, Adventure 15596
    T.eq(order, { 'Paladin', 'Paladin', 'Dungeons', 'Raids', 'Adventure' })
    T.falsy(find(out, 'Explorer: Explorer'), 'the name is not repeated')
  end)
  T.it('the game listing a later group first does not change the order', function()
    local W = session({ legacy25 = 'ids' })
    local real = W.env.GetCategoryList
    W.env.GetCategoryList = function()
      local t = real()
      local r = {}
      for i = #t, 1, -1 do r[#r + 1] = t[i] end           -- reversed: Adventure's sub-groups first
      return r
    end
    local out = legacy(W, 'legacy all')
    local order = {}
    for _, l in ipairs(out) do local w = l:match('^%[([^%]]+)%]'); if w then order[#order + 1] = w end end
    T.eq(order, { 'Paladin', 'Paladin', 'Dungeons', 'Raids', 'Adventure' })
  end)
end)
