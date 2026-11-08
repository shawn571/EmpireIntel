-- EmpireIntel / Tests / test_ei_views.lua
-- Behavior of increment P2-3 (Phase2_Plan.md section 6): the rules table, /ei unlock, /ei rest, /ei milestones.
local T, F = ...

local WALL = 1800000000
local PROFS = { profIdx = { 1, 2 }, profs = { { name = 'Tailoring', skill = 75, line = 197 }, { name = 'Herbalism', skill = 60, line = 182 } } }
local function char() return { level = 4, xp = 86, xpMax = 2100, rest = 500, resting = true, profIdx = PROFS.profIdx, profs = PROFS.profs } end

local function session(opts)
  opts = opts or {}
  opts.char = opts.char or char()
  local W = F.new(opts)
  W.prints = {}
  W.env.print = function(...) local t = {}; for i = 1, select('#', ...) do t[i] = tostring((select(i, ...))) end; table.insert(W.prints, table.concat(t, ' ')) end
  local EI = F.loadAddon(W, 'EmpireIntel')
  W:fire('PLAYER_LOGIN')
  W:fire('PLAYER_ENTERING_WORLD', true, false)
  W:advance(3)
  return W, EI
end
local function cmd(W, msg)
  local from = #W.prints
  W.env.SlashCmdList.EMPIREINTEL(msg)
  local out = {}
  for i = from + 1, #W.prints do out[#out + 1] = W.prints[i] end
  return out
end
local function find(lines, text)
  for _, l in ipairs(lines) do if l:find(text, 1, true) then return l end end
  return nil
end
local function dump(lines) return table.concat(lines, '\n') end
local function roster(recs) return { schema = 1, meta = {}, roster = recs } end
local function rec(t)
  local r = { realm = 'Test Realm', src = 'self', lastSeen = WALL - 3600, restAt = WALL - 3600 }
  for k, v in pairs(t) do r[k] = v end
  return r
end

T.describe('P2-3: rules table', function()
  local _, EI = session({})
  local R = EI.Rules
  T.it('next milestone and count reached', function()
    T.eq({ R.Next(R.CLASS_MILESTONES, 24) }, { 25, 0 })
    T.eq({ R.Next(R.CLASS_MILESTONES, 25) }, { 45, 1 })
    T.eq({ R.Next(R.CLASS_MILESTONES, 59) }, { 60, 2 })
    local n, r = R.Next(R.CLASS_MILESTONES, 60)
    T.isnil(n); T.eq(r, 3)
    T.eq({ R.Next(R.CRAFT_MILESTONES, nil) }, { 150, 0 })
  end)
  T.it('the six crafting skills (Q-P2-3a), by skill line or name; gathering is not one', function()
    T.eq(#R.CRAFTS, 6)
    T.eq(R.Craft({ line = 197 }), 'Tailoring')
    T.eq(R.Craft({ name = 'leatherworking' }), 'Leatherworking')
    T.isnil(R.Craft({ name = 'Mining', line = 186 }))
    T.isnil(R.Craft({ name = 'Herbalism', line = 182 }))
    T.isnil(R.Craft({ name = 'Cooking', line = 185 }))
    T.eq(#R.CLASSES, 9)
  end)
  T.it('rest projection: classic rule (Q-P2-3b)', function()
    T.eq({ R.ProjectRest(0, 1000, true, 0, 8 * 3600) }, { 50, false }, '5% of a level per 8 h resting')
    T.eq({ R.ProjectRest(0, 1000, false, 0, 8 * 3600) }, { 12, false }, 'a quarter outside')
    T.eq({ R.ProjectRest(0, 1000, nil, 0, 8 * 3600) }, { 12, false }, 'resting unknown: outside rate')
    T.eq({ R.ProjectRest(1490, 1000, true, 0, 8 * 3600) }, { 1500, true }, 'cap 1.5 levels')
    T.eq({ R.ProjectRest(300, 1000, true, 100, 50) }, { 300, false }, 'a clock that went backwards removes nothing')
    T.eq({ R.ProjectRest(nil, 1000, true, 0, 8 * 3600, true) }, { 50, false }, 'none reported counts from 0')
    T.eq(select(2, R.ProjectRest(nil, 1000, true, 0, 1)), 'no reading')
    T.eq(select(2, R.ProjectRest(10, nil, true, 0, 1)), 'no bar')
  end)
end)

T.describe('P2-3: /ei unlock', function()
  T.it('before the unlock: the closest character, levels and XP to go', function()
    local W = session({})
    local l = cmd(W, 'unlock')[1]
    T.truthy(l:find('unlock: not yet. Closest: Testchar Tester Warrior 4, 21 levels to go, 2014 XP left in level 4 (this character)', 1, true), l)
    T.truthy(l:find('Game rule: the first character to 25 unlocks Legacy.', 1, true), l)
  end)
  T.it('after the unlock: who reached 25', function()
    local W = session({ eidb = roster({ ['Player-1-00000009'] = rec({ name = 'Pal Adin', class = 'PALADIN', level = 25, xp = 10, xpMax = 34000 }) }) })
    local l = cmd(W, 'unlock')[1]
    T.truthy(l:find('unlock: Legacy is unlocked: Pal Adin Paladin 25 reached 25 (seen 1 h ago).', 1, true), l)
  end)
  T.it('a character only DataStore knows counts too', function()
    local W = session({ datastore = 'good' })
    local l = cmd(W, 'unlock')[1]
    T.truthy(l:find('Alt Two Mage 45 reached 25', 1, true), l)
  end)
end)

T.describe('P2-3: /ei rest', function()
  local W = session({ datastore = 'good', eidb = roster({
    ['Player-1-00000007'] = rec({ name = 'Inn Priest', class = 'PRIEST', level = 6, xp = 1705, xpMax = 3600, rest = 650, resting = true,
      restAt = WALL - 8 * 3600, lastSeen = WALL - 8 * 3600 }),
    ['Player-1-00000008'] = rec({ name = 'Field Rogue', class = 'ROGUE', level = 10, xp = 5, xpMax = 1000, resting = false,
      restAt = WALL - 16 * 3600, lastSeen = WALL - 16 * 3600 }),
    ['Player-1-00000006'] = rec({ name = 'Old Hand', class = 'WARRIOR', level = 60, xp = 0, xpMax = 0, lastSeen = WALL - 7200 }),
  }) })
  local out = cmd(W, 'rest')
  T.it('the header carries the estimate label', function()
    T.truthy(out[1]:find('[estimate: classic rule, 5% of a level per 8 h resting, a quarter outside, cap 1.5 levels; unverified on Forever]', 1, true), out[1])
  end)
  T.it('this character: the live value, no projection', function()
    local l = find(out, 'Testchar Tester')
    T.truthy(l:find('now 500 XP (0.24 levels), resting [this character, live]', 1, true), l)
  end)
  T.it('an inn character: measured, then projected with the resting rate', function()
    local l = find(out, 'Inn Priest')
    T.truthy(l:find('measured 650 XP (0.18 levels) 8 h ago, resting -> now about 830 XP (0.23 levels) [estimate] [self]', 1, true), l)
  end)
  T.it('none reported outside an inn: projected from 0 at a quarter of the rate', function()
    local l = find(out, 'Field Rogue')
    T.truthy(l:find('measured none reported 16 h ago, not resting -> now about 25 XP (0.03 levels) [estimate] [self]', 1, true), l)
  end)
  T.it('a DataStore character without a measured XP bar gets no projection', function()
    local l = find(out, 'Alt Two')
    T.truthy(l:find('no projection: XP bar not measured at level 45 [datastore]', 1, true), l)
  end)
  T.it('level 60: no rested XP', function()
    T.truthy(find(out, 'Old Hand Warrior 60: max level, no rested XP [self]'), dump(out))
  end)
end)

T.describe('P2-3: /ei milestones', function()
  local W = session({ datastore = 'good', eidb = roster({
    ['Player-1-00000009'] = rec({ name = 'Pal Adin', class = 'PALADIN', level = 25, xp = 10, xpMax = 34000,
      professions = { { name = 'Mining', skill = 106, max = 150, line = 186 }, { name = 'Blacksmithing', skill = 56, max = 75, line = 164 } } }),
    ['Player-1-00000005'] = rec({ name = 'Max Ench', class = 'DRUID', level = 60, xp = 0, xpMax = 0,
      professions = { { name = 'Enchanting', skill = 300, max = 300, line = 333 } } }),
  }) })
  local out = cmd(W, 'milestones')
  T.it('the header carries the rules label', function()
    T.truthy(out[1]:find('[rules from your list; not yet confirmed by the game]', 1, true), out[1])
  end)
  T.it('one line per class: best character, next milestone, levels to go; all done; no character yet', function()
    T.truthy(find(out, 'Paladin: Pal Adin 25 -> next 45 (20 levels)'), dump(out))
    T.truthy(find(out, 'Warrior: Testchar Tester 4 -> next 25 (21 levels)'), dump(out))
    T.truthy(find(out, 'Mage: Alt Two 45 -> next 60 (15 levels)'), dump(out))
    T.truthy(find(out, 'Druid: Max Ench 60 -> all 3 done'), dump(out))
    T.truthy(find(out, 'Hunter: no character yet -> next 25'), dump(out))
    local n = 0
    for _, l in ipairs(out) do for _, c in ipairs({ 'Warrior', 'Paladin', 'Hunter', 'Rogue', 'Priest', 'Shaman', 'Mage', 'Warlock', 'Druid' }) do
      if l:find('^EmpireIntel: ' .. c .. ':') then n = n + 1 end end end
    T.eq(n, 9)
  end)
  T.it('one line per crafting skill: best skill, next milestone, gap, max skill in the way', function()
    T.truthy(find(out, 'Tailoring: Alt Two 230/300 -> next 300 (70 to go)'), dump(out))
    T.truthy(find(out, 'Blacksmithing: Pal Adin 56/75 -> next 150 (94 to go); train to raise max 75'), dump(out))
    T.truthy(find(out, 'Enchanting: Max Ench 300/300 -> all 3 done'), dump(out))
    T.truthy(find(out, 'Alchemy: nobody has it yet -> next 150'), dump(out))
    T.falsy(find(out, 'Mining:'), 'gathering is not a crafting milestone')
    T.falsy(find(out, 'Herbalism:'))
  end)
  T.it('the footer counts and labels the estimate', function()
    -- classes: Paladin 25 (1), Mage 45 (2), Druid 60 (3) = 6; crafting: Tailoring 230 (2), Enchanting 300 (3) = 5
    T.truthy(find(out, 'Classes 6 of 27, crafting 5 of 18. About 11 Legacy points from these two groups [estimate].'), dump(out))
    T.truthy(find(out, 'PvP, dungeons, raids and adventure (20 points) are not tracked yet.'), dump(out))
  end)
end)

T.describe('P2-3: read only, commands, faults', function()
  T.it('the three views change no saved data and write nothing into DataStore', function()
    local W, EI = session({ datastore = 'good' })
    local before = EI.Platform.Util.deepCopy(W.env.EmpireIntelDB)
    cmd(W, 'unlock'); cmd(W, 'rest'); cmd(W, 'milestones')
    T.truthy(EI.Platform.Util.deepEqual(before, W.env.EmpireIntelDB))
    T.eq(W.dsWrites, 0)
  end)
  T.it('/ei help lists the new commands; /ei and /ei alts are unchanged', function()
    local W = session({})
    T.truthy(cmd(W, 'help')[1]:find('/ei unlock, /ei rest, /ei milestones', 1, true))
    T.truthy(cmd(W, '')[1]:find('Testchar Tester (WARRIOR 4, Test Realm): XP 86/2100', 1, true))
    T.truthy(cmd(W, 'alts')[1]:find('alts: 1 characters', 1, true))
  end)
  T.it('a failing view is one UNEXPECTED line', function()
    local W, EI = session({})
    EI.Views.Rest = function() error('view broke') end
    local l = cmd(W, 'rest')[1]
    T.truthy(l:find('UNEXPECTED: /ei rest failed', 1, true) and l:find('view broke', 1, true), l)
  end)
  T.it('no characters: each view says so', function()
    local W, EI = session({})
    EI.Alts.Collect = function() return {}, { present = false, list = {}, missing = {} }, 0, nil end
    T.truthy(cmd(W, 'unlock')[1]:find('no characters known yet', 1, true))
    T.truthy(cmd(W, 'rest')[1]:find('no characters known yet', 1, true))
    T.truthy(find(cmd(W, 'milestones'), 'About 0 Legacy points'))
  end)
end)

T.describe('P2-3: projection edge cases', function()
  T.it('the projection starts when the rest was read, not when the character was last seen', function()
    -- a logout the guard rejected moves lastSeen only (P2-1); the rest reading is older
    local W = session({ eidb = roster({ ['Player-1-00000007'] = rec({ name = 'Inn Priest', class = 'PRIEST', level = 6, xp = 1, xpMax = 3600,
      rest = 650, resting = true, restAt = WALL - 16 * 3600, lastSeen = WALL - 60 }) }) })
    local l = find(cmd(W, 'rest'), 'Inn Priest')
    T.truthy(l:find('measured 650 XP (0.18 levels) 16 h ago, resting -> now about 1010 XP', 1, true), l)
  end)
  T.it('DataStore newer but without a rest value: no projection (unknown is not none)', function()
    local W = session({ datastore = 'faulty', eidb = roster({ ['Player-1-00000002'] = rec({ name = 'Alt Two', class = 'MAGE', level = 45,
      xp = 1, xpMax = 5000, rest = 900, resting = true, restAt = WALL - 5 * 86400, lastSeen = WALL - 5 * 86400 }) }) })
    local l = find(cmd(W, 'rest'), 'Alt Two')
    T.truthy(l:find('measured unknown', 1, true) and l:find('-> no projection: no reading [datastore]', 1, true), l)
  end)
  T.it('the best character of a class is the highest, whatever the list order', function()
    local W = session({ eidb = roster({ ['Player-1-00000004'] = rec({ name = 'Big Warrior', class = 'WARRIOR', level = 30, xp = 1, xpMax = 1000 }) }) })
    T.truthy(find(cmd(W, 'milestones'), 'Warrior: Big Warrior 30 -> next 45 (15 levels)'))
  end)
end)
