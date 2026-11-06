-- EmpireIntel / Tests / test_ei_alts.lua
-- Behavior of increment P2-2 (Phase2_Plan.md section 5): /ei alts, the DataStore bridge and the merge rule,
-- with a good, faulty, erroring and absent DataStore. Nothing from DataStore may reach saved data.
local T, F = ...

local GUID, ALT = 'Player-1-00000001', 'Player-1-00000002'
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
local function alts(W)
  local from = #W.prints
  W.env.SlashCmdList.EMPIREINTEL('alts')
  local out = {}
  for i = from + 1, #W.prints do out[#out + 1] = W.prints[i] end
  return out
end
local function find(lines, text)
  for _, l in ipairs(lines) do if l:find(text, 1, true) then return l end end
  return nil
end
local function dump(lines) return table.concat(lines, '\n') end

T.describe('P2-2: /ei alts with DataStore', function()
  local W, EI = session({ datastore = 'good' })
  local before = EI.Platform.Util.deepCopy(W.env.EmpireIntelDB)
  local out = alts(W)
  T.it('counts characters and says DataStore is read live, not stored', function()
    T.truthy(find(out, 'alts: 2 characters (1 recorded by EmpireIntel, 1 from DataStore only). DataStore read live, not stored.'), dump(out))
    T.falsy(find(out, 'UNEXPECTED'), dump(out))
  end)
  T.it('shows this character first, from its own newer record, with rest in levels', function()
    local l = out[2]
    T.truthy(l:find('Testchar Tester WARRIOR 4 (Test Realm)', 1, true), l)
    T.truthy(l:find('rested 500 XP (0.24 levels), resting', 1, true), l)
    T.truthy(l:find('Tailoring 75/300, Herbalism 60/300', 1, true), l)
    T.truthy(l:find('this character [self]', 1, true), l)
  end)
  T.it('shows a DataStore-only alt with name, realm, class, level, profession and age', function()
    local l = out[3]
    T.truthy(l:find('Alt Two MAGE 45 (Test Realm)', 1, true), l)
    T.truthy(l:find('Tailoring 230/300', 1, true), l)
    T.truthy(l:find('min ago [datastore]', 1, true) or l:find('1 h ago [datastore]', 1, true), l)
  end)
  T.it('changes no saved data (format 1 unchanged) and writes nothing into DataStore', function()
    T.truthy(EI.Platform.Util.deepEqual(before, W.env.EmpireIntelDB), 'EmpireIntelDB unchanged by /ei alts')
    T.isnil(W.env.EmpireIntelDB.roster[ALT], 'a DataStore-only character is shown, not stored')
    T.eq(W.dsWrites, 0)
  end)
  T.it('a later snapshot still stores only the logged-in character', function()
    W:advance(301)
    local n = 0
    for _ in pairs(W.env.EmpireIntelDB.roster) do n = n + 1 end
    T.eq(n, 1)
  end)
end)

T.describe('P2-2: merge rule', function()
  T.it('an own record newer than DataStore wins; fields it lacks come from DataStore, with source and age', function()
    local W = session({ datastore = 'good', eidb = { schema = 1, meta = {}, roster = {
      [ALT] = { name = 'Alt Two', realm = 'Test Realm', class = 'MAGE', level = 46, rest = 900, resting = false, lastSeen = 1800000000 - 120, src = 'self' } } } })
    local l = find(alts(W), 'Alt Two')
    T.truthy(l:find('MAGE 46', 1, true) and l:find('rested 900 XP, not resting', 1, true), l)
    T.truthy(l:find('2 min ago [self]', 1, true) or l:find('[self]', 1, true), l)
    T.truthy(l:find('(professions from datastore, ', 1, true), l)
  end)
  T.it('DataStore newer than the own record wins, rest and resting included', function()
    local W = session({ datastore = 'good', eidb = { schema = 1, meta = {}, roster = {
      [ALT] = { name = 'Alt Two', class = 'MAGE', level = 40, xp = 1, xpMax = 5000, rest = 900, resting = false, lastSeen = 1800000000 - 3 * 86400, src = 'self' } } } })
    local l = find(alts(W), 'Alt Two')
    T.falsy(l:find('levels', 1, true), 'an XP bar from another level is never used: ' .. l)
    T.truthy(l:find('MAGE 45', 1, true) and l:find('[datastore]', 1, true), l)
    T.truthy(l:find('rested 500 XP, resting', 1, true), l)
    T.truthy(l:find('realm from datastore', 1, true) == nil, 'realm comes from the DataStore key: ' .. l)
  end)
  T.it('a DataStore name "Unknown" never replaces a known one', function()
    local _, EI = session({})
    local rows = EI.Alts.Merge({ g = { name = 'Known Name', level = 3, lastSeen = 10 } }, { list = { { guid = 'g', name = 'Unknown', level = 9, at = 50 } } })
    T.eq(rows[1].name, 'Known Name')
    T.eq(rows[1].level, 9)
    T.eq(rows[1].src, 'datastore')
    T.eq(rows[1].from.name.src, 'self')
  end)
  T.it('rested XP is never mixed: a newer source without it shows unknown', function()
    local _, EI = session({})
    local rows = EI.Alts.Merge({ g = { name = 'A', rest = 500, lastSeen = 10 } }, { list = { { guid = 'g', name = 'A', at = 50 } } })
    T.isnil(rows[1].rest)
    T.truthy(EI.Alts.Line(rows[1]):find('rested unknown', 1, true))
  end)
  T.it('an own record without rested XP says "none reported", as /ei does (live defect D2)', function()
    local _, EI = session({})
    local rows = EI.Alts.Merge({ g = { name = 'A', level = 16, lastSeen = 50 } }, { list = {} })
    T.truthy(EI.Alts.Line(rows[1]):find('rested none reported, ', 1, true), EI.Alts.Line(rows[1]))
  end)
  T.it('a tie goes to EmpireIntel', function()
    local _, EI = session({})
    local rows = EI.Alts.Merge({ g = { name = 'A', level = 5, lastSeen = 50 } }, { list = { { guid = 'g', name = 'A', level = 6, at = 50 } } })
    T.eq(rows[1].src, 'self')
    T.eq(rows[1].level, 5)
  end)
  T.it('Merge reads and never writes its inputs', function()
    local _, EI = session({})
    local roster = { g = { name = 'A', lastSeen = 10 } }
    local ds = { list = { { guid = 'g', name = 'B', at = 50 }, { name = 'NoGuid', at = 5 } } }
    local r0, d0 = EI.Platform.Util.deepCopy(roster), EI.Platform.Util.deepCopy(ds)
    local rows = EI.Alts.Merge(roster, ds)
    T.eq(#rows, 2)
    T.eq(roster, r0)
    T.eq(ds, d0)
  end)
end)

T.describe('P2-2: without DataStore and with DataStore faults', function()
  T.it('without DataStore, /ei alts lists own records and says DataStore is not installed', function()
    local W = session({})
    local out = alts(W)
    T.truthy(find(out, 'alts: 1 characters (1 recorded by EmpireIntel, 0 from DataStore only). DataStore is not installed'), dump(out))
    T.truthy(find(out, 'Testchar Tester WARRIOR 4'), dump(out))
    T.falsy(find(out, 'UNEXPECTED'), dump(out))
  end)
  T.it('a DataStore error is one UNEXPECTED line; the rest still answers', function()
    local W = session({ datastore = 'throws' })
    local out = alts(W)
    local u = find(out, 'UNEXPECTED: DataStore gave 1 error(s)')
    T.truthy(u and u:find('boom in level', 1, true), dump(out))
    T.truthy(find(out, 'Alt Two MAGE ?'), dump(out))
    T.truthy(find(out, 'Testchar Tester WARRIOR 4'), dump(out))
  end)
  T.it('a DataStore that cannot list characters is UNEXPECTED; own records still show', function()
    local W = session({ datastore = 'nolist' })
    local out = alts(W)
    T.truthy(find(out, 'UNEXPECTED: DataStore has no IterateCharacters'), dump(out))
    T.truthy(find(out, 'Testchar Tester WARRIOR 4'), dump(out))
  end)
  T.it('two DataStore entries with one GUID: UNEXPECTED, and the known name is kept', function()
    local W = session({ datastore = 'faulty' })
    local out = alts(W)
    T.truthy(find(out, 'UNEXPECTED: 1 DataStore character(s) share a GUID'), dump(out))
    T.falsy(find(out, 'Unknown '), dump(out))
    T.truthy(find(out, 'Testchar Tester WARRIOR 4'), dump(out))
  end)
  T.it('DataStore without its Crafts module: professions unknown, with a note', function()
    local W = session({ datastore = 'charsonly' })
    local out = alts(W)
    T.truthy(find(out, 'Note: DataStore_Crafts is not loaded'), dump(out))
    T.truthy(find(out, 'Alt Two MAGE 45 (Test Realm): rested 500 XP, resting; professions unknown'), dump(out))
  end)
  T.it('a crash inside the bridge is caught and shown', function()
    local W, EI = session({ datastore = 'good' })
    EI.DataStoreBridge.Read = function() error('bridge broke') end
    local out = alts(W)
    T.truthy(find(out, 'UNEXPECTED: DataStore gave 1 error(s)') and find(out, 'bridge broke'), dump(out))
    T.truthy(find(out, 'Testchar Tester'), dump(out))
  end)
  T.it('the bridge refuses any method outside the approved list', function()
    local W, EI = session({ datastore = 'good' })
    local called = false
    rawset(W.env.DataStore, 'GetCharacterLevel', function() called = true; return 1 end)
    EI.DataStoreBridge.ALLOWED.GetCharacterLevel = nil
    local r = EI.DataStoreBridge.Read()
    EI.DataStoreBridge.ALLOWED.GetCharacterLevel = true
    T.falsy(called, 'a name outside ALLOWED is never called')
    T.truthy(r.errors > 0 and tostring(r.firstError):find('refused call GetCharacterLevel', 1, true), tostring(r.firstError))
  end)
  T.it('the logged-in character reads as online (DataStore logout 5000000000), not as a logout time', function()
    local W, EI = session({ datastore = 'good' })
    local r = EI.DataStoreBridge.Read()
    local me
    for _, c in ipairs(r.list) do if c.guid == GUID then me = c end end
    T.eq(me.online, true)
    T.isnil(me.lastLogout)
    local rows = EI.Alts.Merge({}, { list = { me } })
    T.truthy(EI.Alts.Line(rows[1]):find('online now [datastore]', 1, true), EI.Alts.Line(rows[1]))
  end)
  T.it('one bad DataStore entry is counted and skipped; the others are read', function()
    local W, EI = session({ datastore = 'good' })
    local bad = setmetatable({}, { __tostring = function() error('bad key') end })
    rawset(W.env.DataStore, 'IterateCharacters', function(_, cb) cb(bad, 9); cb('Default.Test Realm.Alt Two', 2) end)
    local r = EI.DataStoreBridge.Read()
    T.eq(#r.list, 1)
    T.eq(r.list[1].name, 'Alt Two')
    T.eq(r.errors, 1)
  end)
end)

T.describe('P2-2: commands and events', function()
  T.it('/ei help lists /ei alts; /ei is unchanged', function()
    local W = session({ datastore = 'good' })
    W.env.SlashCmdList.EMPIREINTEL('help')
    T.truthy(W.prints[#W.prints]:find('/ei alts', 1, true))
    W.env.SlashCmdList.EMPIREINTEL('')
    T.truthy(W.prints[#W.prints]:find('Testchar Tester (WARRIOR 4, Test Realm): XP 86/2100', 1, true), W.prints[#W.prints])
  end)
  T.it('P2-2 adds no event and no timer', function()
    local W = session({ datastore = 'good', ctimer = true })
    local allowed = { PLAYER_LOGIN = 1, PLAYER_ENTERING_WORLD = 1, PLAYER_LEAVING_WORLD = 1, PLAYER_LOGOUT = 1,
      PLAYER_REGEN_DISABLED = 1, PLAYER_REGEN_ENABLED = 1, PLAYER_LEVEL_UP = 1, SKILL_LINES_CHANGED = 1 }
    for ev in pairs(W.registered) do T.truthy(allowed[ev], 'registered ' .. ev) end
    local n = #W.tickers
    alts(W)
    T.eq(#W.tickers, n)
  end)
end)
