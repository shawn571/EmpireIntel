-- EmpireIntel / Tests / test_ei.lua
-- Behavior of EmpireIntel increment P2-1 against the fake client (Phase2_Plan.md, saved-data format 1).
local T, F = ...

local GUID = 'Player-1-00000001'

local function session(opts)
  opts = opts or {}
  local W = F.new(opts)
  local EI = F.loadAddon(W, 'EmpireIntel')
  W:fire('PLAYER_LOGIN')
  W:fire('PLAYER_ENTERING_WORLD', true, false)
  W:advance(3)
  return W, EI
end
local function rec(W, guid) return W.env.EmpireIntelDB.roster[guid or GUID] end
local function ei(W, msg) W.env.SlashCmdList.EMPIREINTEL(msg) end
local function lastLine(W) return W.chat[#W.chat] or '' end
local function lastPrint(W) return W.prints[#W.prints] or '' end

local PROFS = { profIdx = { 1, 2 }, profs = { { name = 'Tailoring', skill = 75, line = 197 }, { name = 'Herbalism', skill = 60, line = 182 } } }
local function char(extra)
  local c = { level = 4, xp = 86, xpMax = 2100, rest = 500, resting = true, profIdx = PROFS.profIdx, profs = PROFS.profs }
  for k, v in pairs(extra or {}) do c[k] = v end      -- F.NIL passes through to the fake client
  return c
end

-- capture P.Print output (it goes through env.print)
local realNew = F.new
F.new = function(opts)
  local W = realNew(opts)
  W.prints = {}
  W.env.print = function(...) local t = {}; for i = 1, select('#', ...) do t[i] = tostring((select(i, ...))) end; table.insert(W.prints, table.concat(t, ' ')) end
  return W
end

T.describe('P2-1: snapshot of the logged-in character (format 1)', function()
  local W = session({ char = char() })
  local r = rec(W)
  T.it('is written about 2 seconds after login, keyed by GUID', function()
    T.truthy(r, 'record exists')
    T.eq(r.src, 'self')
  end)
  T.it('holds name (two-part), realm, class, level, XP, rest, resting and the read time', function()
    T.eq(r.name, 'Testchar Tester')
    T.eq(r.realm, 'Test Realm', 'realm field (user change to format 1)')
    T.eq(r.class, 'WARRIOR')
    T.eq(r.level, 4)
    T.eq(r.xp, 86)
    T.eq(r.xpMax, 2100)
    T.eq(r.rest, 500)
    T.eq(r.resting, true)
    T.truthy(type(r.restAt) == 'number' and type(r.lastSeen) == 'number')
  end)
  T.it('holds professions with skill, max and skill line', function()
    T.eq(r.professions, { { name = 'Tailoring', skill = 75, max = 300, line = 197 }, { name = 'Herbalism', skill = 60, max = 300, line = 182 } })
  end)
  T.it('uses exactly the approved fields (format 1 plus realm; format 2 identity fields), nothing else', function()
    local allowed = { name = 1, realm = 1, class = 1, level = 1, xp = 1, xpMax = 1, rest = 1, resting = 1, restAt = 1,
      professions = 1, lastSeen = 1, src = 1, race = 1, sex = 1, faction = 1, ruleset = 1, preset = 1 }
    for k in pairs(r) do T.truthy(allowed[k], 'unexpected roster field ' .. k) end
    local db = W.env.EmpireIntelDB
    for k in pairs(db) do T.truthy(({ schema = 1, meta = 1, roster = 1, off = 1, plan = 1 })[k], 'unexpected top-level key ' .. k) end
    T.eq(db.plan, {}, 'format 2: the plan section starts empty')
    for k in pairs(db.meta) do T.truthy(({ created = 1, opens = 1, version = 1, build = 1 })[k], 'unexpected meta key ' .. k) end
    T.eq(db.schema, 2)
    T.eq(db.meta.version, '0.7.3')
    T.eq(db.meta.build, '1.60.1/70450')
  end)
end)

T.describe('P2-1: unknown stays unknown', function()
  T.it('no rested XP from the client is stored as nil, never 0', function()
    local W = session({ char = char({ rest = F.NIL }) })
    T.isnil(rec(W).rest)
    T.truthy(rec(W).restAt, 'the reading time is still kept')
  end)
  T.it('a secret level keeps the previous value', function()
    local W = session({ char = char() })
    W.env.UnitLevel = function() return W.SECRET end
    ei(W, '')                       -- status only reads
    W:fire('PLAYER_LEVEL_UP', nil)
    W:advance(1)
    T.eq(rec(W).level, 4)
  end)
  T.it('professions are not wiped when the client cannot be read', function()
    local W = session({ char = char() })
    W.env.GetProfessions = nil
    W:advance(301)
    T.eq(#rec(W).professions, 2)
  end)
  T.it('not resting is stored as false, not lost (live defect D1)', function()
    local W = session({ char = char({ resting = false }) })
    T.eq(rec(W).resting, false)
    ei(W, '')
    T.truthy(lastPrint(W):find(', not resting;', 1, true), lastPrint(W))
  end)
  T.it('an unreadable resting state stays unknown and /ei says so', function()
    local W = session({ char = char() })
    W.env.IsResting = function() return nil end
    local W2 = session({ char = char(), eidb = { schema = 1, meta = {}, roster = {} } })
    W2.env.IsResting = nil
    W2:advance(301)
    T.eq(rec(W2).resting, true, 'a failed read keeps the previous value')
    local W3 = session({ char = char() })
    W3.env.EmpireIntelDB.roster[GUID].resting = nil
    W3.env.IsResting = function() return nil end
    W3:advance(301)
    T.isnil(rec(W3).resting)
    ei(W3, '')
    T.truthy(lastPrint(W3):find('resting unknown', 1, true), lastPrint(W3))
  end)
  T.it('a character with no professions is stored with an empty list', function()
    local W = session({ char = char({ profIdx = {}, profs = {} }) })
    T.eq(rec(W).professions, {})
  end)
end)

T.describe('P2-1: when it records (events plus the 5-minute timer, no 0.5 s tick)', function()
  T.it('level-up updates the record at once', function()
    local W = session({ char = char() })
    W.char.level = 5
    W:fire('PLAYER_LEVEL_UP', 5)
    W:advance(0.2)
    T.eq(rec(W).level, 5)
  end)
  T.it('a profession skill change updates the record after the 1 s debounce', function()
    local W = session({ char = char() })
    W.char.profs[1].skill = 76
    W:fire('SKILL_LINES_CHANGED')
    W:advance(1.5)
    T.eq(rec(W).professions[1].skill, 76)
    W.char.profs[1].skill = 75
  end)
  T.it('the timer writes every 5 minutes, not more often', function()
    local W, EI = session({ char = char() })
    local n = EI.Snapshot.count
    W:advance(290)
    T.eq(EI.Snapshot.count, n, 'nothing between timer ticks')
    W:advance(20)
    T.eq(EI.Snapshot.count, n + 1)
  end)
  T.it('with C_Timer, the only repeating timer is 300 s', function()
    local W = session({ char = char(), ctimer = true })
    T.eq(#W.tickers, 1)
    T.eq(W.tickers[1].sec, 300)
  end)
  T.it('no P_TICK event exists', function()
    local W, EI = session({ char = char() })
    T.isnil(EI.Platform.Events.SPEC.P_TICK)
    T.isnil((EI.Platform.On('P_TICK', function() end)))
  end)
end)

T.describe('P2-1: logout guard (EI-E-08)', function()
  T.it('wrong values at logout keep the last in-world record; only lastSeen moves', function()
    local W = session({ char = char() })
    local before = rec(W).lastSeen
    W:advance(10)
    W.char.level = 1; W.char.xpMax = 0
    W:fire('PLAYER_LOGOUT')
    T.eq(rec(W).level, 4)
    T.eq(rec(W).xpMax, 2100)
    T.truthy(rec(W).lastSeen > before)
  end)
  T.it('valid values at logout are written', function()
    local W = session({ char = char() })
    W.char.xp = 120
    W:fire('PLAYER_LOGOUT')
    T.eq(rec(W).xp, 120)
  end)
end)

T.describe('P2-1: identity rules', function()
  T.it('a name reported as Unknown never overwrites a known name', function()
    local W = session({ char = char() })
    local W2 = session({ char = char({ first = 'Unknown', last = '' }), eidb = W.env.EmpireIntelDB })
    T.eq(rec(W2).name, 'Testchar Tester')
  end)
  T.it('two characters get two records; the first is untouched by the second', function()
    local W = session({ char = char() })
    local first = rec(W).level
    local W2 = session({ char = char({ guid = 'Player-1-00000002', first = 'Second', last = 'Alt', level = 12 }), eidb = W.env.EmpireIntelDB })
    T.eq(rec(W2).level, first)
    T.eq(rec(W2, 'Player-1-00000002').level, 12)
  end)
  T.it('no GUID: nothing is recorded (never keyed by name) and nothing fails', function()
    local W, EI = session({ char = char({ guid = F.NIL }) })
    T.eq(next(W.env.EmpireIntelDB.roster), nil)
    for _, d in ipairs(EI.Platform.GetDiag()) do T.falsy(d.level == 'error', 'error: ' .. tostring(d.msg)) end
    T.eq(select(2, EI.Snapshot.Write('command')), 'no GUID yet')
  end)
end)

T.describe('P2-1: off switch', function()
  T.it('/ei off stops recording now and on later logins; /ei on resumes', function()
    local W, EI = session({ char = char() })
    ei(W, 'off')
    local n = EI.Snapshot.count
    W.char.level = 6
    W:fire('PLAYER_LEVEL_UP', 6)
    W:advance(600)
    T.eq(EI.Snapshot.count, n)
    T.eq(rec(W).level, 4)
    local W2, EI2 = session({ char = char({ level = 7 }), eidb = W.env.EmpireIntelDB })
    T.eq(EI2.Snapshot.count, 0)
    T.eq(rec(W2).level, 4)
    ei(W2, 'on')
    W2:advance(3)
    T.eq(rec(W2).level, 7)
    T.isnil(W2.env.EmpireIntelDB.off)
  end)
  T.it('a direct write while off records nothing', function()
    local W, EI = session({ char = char() })
    ei(W, 'off')
    W.char.level = 9
    T.eq(select(2, EI.Snapshot.Write('command')), 'off')
    T.eq(rec(W).level, 4)
  end)
end)

T.describe('P2-1: saved data (Store, ported)', function()
  T.it('a newer schema is left untouched and nothing is saved', function()
    local newer = { schema = 3, roster = { [GUID] = { level = 50 } }, meta = {}, future = 'x' }
    local W = session({ char = char(), eidb = newer })
    T.eq(W.env.EmpireIntelDB.roster[GUID].level, 50)
    T.eq(W.env.EmpireIntelDB.future, 'x')
    local saw = false
    for _, l in ipairs(W.prints) do if l:find('newer than this version', 1, true) then saw = true end end
    T.truthy(saw, 'the user is told')
  end)
  T.it('saved data without a schema is migrated to schema 2; its keys survive', function()
    local W, EI = session({ char = char(), eidb = { leftover = { a = 1 } } })
    T.eq(EI.Store.Status().state, 'migrated')
    T.eq(W.env.EmpireIntelDB.schema, 2)
    T.eq(W.env.EmpireIntelDB.leftover, { a = 1 })
    T.truthy(rec(W))
  end)
  T.it('a damaged roster section is repaired; unknown keys survive', function()
    local W = session({ char = char(), eidb = { schema = 1, meta = {}, roster = 'broken', extra = 1 } })
    T.truthy(type(W.env.EmpireIntelDB.roster) == 'table' and rec(W))
    T.eq(W.env.EmpireIntelDB.extra, 1)
  end)
  T.it('opens are counted and created is kept', function()
    local W = session({ char = char() })
    local created = W.env.EmpireIntelDB.meta.created
    local W2 = F.new({ char = char(), eidb = W.env.EmpireIntelDB })
    W2.wall = W2.wall + 86400
    F.loadAddon(W2, 'EmpireIntel')
    W2:fire('PLAYER_LOGIN'); W2:fire('PLAYER_ENTERING_WORLD', true, false); W2:advance(3)
    T.eq(W2.env.EmpireIntelDB.meta.opens, 2)
    T.eq(W2.env.EmpireIntelDB.meta.created, created)
  end)
end)

T.describe('P2-1: commands', function()
  T.it('/ei shows this character', function()
    local W = session({ char = char() })
    ei(W, '')
    local line = lastPrint(W)
    T.truthy(line:find('Testchar Tester', 1, true) and line:find('WARRIOR 4', 1, true) and line:find('Test Realm', 1, true), line)
    T.truthy(line:find('XP 86/2100', 1, true) and line:find('rested 500 XP', 1, true) and line:find('Tailoring 75/300', 1, true), line)
    T.truthy(line:find('1 characters known', 1, true), line)
  end)
  T.it('/ei says "none reported" when there is no rested XP', function()
    local W = session({ char = char({ rest = F.NIL }) })
    ei(W, '')
    T.truthy(lastPrint(W):find('rested none reported', 1, true), lastPrint(W))
  end)
  T.it('/ei version shows version and schema', function()
    local W = session({ char = char() })
    ei(W, 'version')
    T.truthy(lastPrint(W):find('version 0.7.3, saved data schema 2', 1, true), lastPrint(W))
  end)
end)

T.describe('P2-1: events and coexistence', function()
  T.it('registers only allow-listed events', function()
    local W = session({ char = char() })
    local allowed = { PLAYER_LOGIN = 1, PLAYER_ENTERING_WORLD = 1, PLAYER_LEAVING_WORLD = 1, PLAYER_LOGOUT = 1,
      PLAYER_REGEN_DISABLED = 1, PLAYER_REGEN_ENABLED = 1, PLAYER_LEVEL_UP = 1, SKILL_LINES_CHANGED = 1 }
    for ev in pairs(W.registered) do T.truthy(allowed[ev], 'registered ' .. ev) end
  end)
  T.it('refuses restricted and non-allow-listed events', function()
    local W, EI = session({ char = char() })
    T.falsy((EI.Platform.Events.Bind('COMBAT_LOG_EVENT_UNFILTERED', function() end)))
    T.falsy((EI.Platform.Events.Bind('PLAYER_MONEY', function() end)))
    T.isnil(W.registered.COMBAT_LOG_EVENT_UNFILTERED)
  end)
  T.it('runs beside EmpireIntelCheck and GoldIntel without touching them', function()
    local W = F.new({ char = char() })
    local before = {}
    for k in pairs(W.env) do before[k] = true end
    local gi = { schema = W.env.GoldIntelDB.schema, n = #W.env.GoldIntelDB.ledger.entries }
    F.load(W)                                 -- EmpireIntelCheck
    F.loadAddon(W, 'EmpireIntel')
    W:login()
    W:advance(40)
    local added = {}
    for k in pairs(W.env) do if not before[k] then table.insert(added, k) end end
    table.sort(added)
    T.eq(added, { 'EmpireIntelCheckDB', 'EmpireIntelDB', 'SLASH_EMPIREINTEL1', 'SLASH_EMPIREINTELCHECK1' })
    T.eq(W.env.GoldIntelDB.schema, gi.schema)
    T.eq(#W.env.GoldIntelDB.ledger.entries, gi.n)
    T.truthy(rec(W), 'EmpireIntel recorded')
    T.truthy(#W.env.EmpireIntelCheckDB.runs >= 1, 'the check still ran')
  end)
end)
