-- EmpireIntel / Tests / test_check.lua
-- Behavior of EmpireIntelCheck against fake clients (Architecture.md section 9, runtime limits 1 to 8).
local T, F = ...

-- Storage format 2: full call results and discovery live once in db.latest (the newest run)
local function codes(W) local l = W:db().latest; return l and l.results or {} end
local function code(W, name) local r = codes(W)[name]; return r and r.code end
local function disc(W) return W:db().latest.discovery end
local function hasUnexpected(run, c)
  for _, u in ipairs(run.unexpected or {}) do if u.code == c then return true end end
  return false
end
local function keys(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end
local function copy(t)
  if type(t) ~= 'table' then return t end
  local o = {}
  for k, v in pairs(t) do o[k] = copy(v) end
  return o
end

T.describe('limit 2: login delay', function()
  T.it('nothing runs before 10 s after PLAYER_ENTERING_WORLD, one run after', function()
    local W = F.new()
    F.load(W)
    W:login()
    W:advance(9.5)
    T.eq(#W:db().runs, 0, 'no run yet')
    T.eq(W.calls['C_Loot.IsLegacyLootModeEnabled'], nil)
    W:advance(30)
    T.eq(#W:db().runs, 1)
    T.eq(W:lastRun().reason, 'login')
  end)
end)

T.describe('beta profile, nothing exposed', function()
  local W = F.session({ legacy = 'none' })
  local run = W:lastRun()
  T.it('verdict NOTHING EXPOSED, provisional for both reasons (pane not seen, no point expected)', function()
    T.eq(run.verdictInfo.verdict, 'NOTHING EXPOSED')
    T.truthy(run.verdictInfo.provisional)
    T.eq(#run.verdictInfo.provisionalReasons, 2)
    T.truthy(run.verdict:find('provisional', 1, true))
  end)
  T.it('prints at most two lines, the first with the verdict (limit 6)', function()
    T.truthy(#W.chat >= 1 and #W.chat <= 2, 'lines: ' .. #W.chat)
    T.truthy(W.chat[1]:find('LEGACY API: NOTHING EXPOSED', 1, true))
  end)
  T.it('pre-modern families match the GoldIntel baseline; no unexpected condition', function()
    for fam, row in pairs(run.partA.T2) do T.falsy(row.changed, fam) end
    T.eq(#run.unexpected, 0)
  end)
  T.it('known unrelated names are recorded but never called and do not count', function()
    T.eq(code(W, 'C_Loot.IsLegacyLootModeEnabled'), 'skipped_unrelated')
    T.eq(code(W, 'C_ChallengeMode.GetMapTable'), 'skipped_unrelated')
    T.eq(W.calls['C_Loot.IsLegacyLootModeEnabled'], nil)
    T.eq(W.calls['C_ChallengeMode.GetMapTable'], nil)
  end)
  T.it('records the namespace list once as the baseline for later diffs', function()
    T.truthy(W:db().nsBaseline and #W:db().nsBaseline.list > 5)
  end)
  T.it('identity, rest and professions recorded', function()
    T.eq(run.partA.T3.guid, 'Player-1-00000001')
    T.eq(run.partA.T3.name2, 'Tester')
    T.eq(run.char.rest.level, 10)
    T.eq(run.estimate.total, 0)
  end)
end)

T.describe('limit 8: provisional only while pane unseen or no point expected', function()
  T.it('level 30 warrior: provisional for the pane only; final after the user marks the pane open', function()
    local W = F.session({ char = { level = 30 } })
    local run = W:lastRun()
    T.eq(run.estimate.total, 1)
    T.eq(run.verdictInfo.provisionalReasons, { 'Legacy pane not seen opening yet' })
    W:slash('pane')
    W:advance(30)
    local run2 = W:lastRun()
    T.eq(run2.id, 2)
    T.eq(run2.verdictInfo.verdict, 'NOTHING EXPOSED')
    T.falsy(run2.verdictInfo.provisional, 'final verdict')
  end)
end)

T.describe('limits 1 and 7: guarded calls and separate result codes', function()
  local W = F.session({ legacy = 'getters' })
  local run = W:lastRun()
  local NSN = 'C_LegacyFixture.'
  T.it('verdict FOUND with the getters that returned data', function()
    T.eq(run.verdictInfo.verdict, 'FOUND')
    local found = table.concat(run.verdictInfo.found, ',')
    T.truthy(found:find('GetPoints', 1, true) and found:find('GetCap', 1, true) and found:find('HasPerk', 1, true))
    T.falsy(found:find('IsUnlocked', 1, true), 'false is not data')
  end)
  T.it('ok, returned_nothing, unreadable, error, blocked are separate', function()
    T.eq(code(W, NSN .. 'GetPoints'), 'ok')
    T.eq(code(W, NSN .. 'IsUnlocked'), 'ok')
    T.eq(code(W, NSN .. 'GetNothing'), 'returned_nothing')
    T.eq(code(W, NSN .. 'GetNilOnly'), 'returned_nothing')
    T.eq(code(W, NSN .. 'GetSecret'), 'unreadable')
    T.eq(code(W, NSN .. 'GetThread'), 'unreadable')
    T.eq(code(W, NSN .. 'GetBoom'), 'error')
    T.eq(code(W, NSN .. 'GetProtected'), 'blocked')
    T.eq(code(W, NSN .. 'GetGuarded'), 'blocked')
  end)
  T.it('denylisted names are never called (Set, Spend, Learn, Reset, Buy, Purchase)', function()
    for _, n in ipairs({ 'SetPoints', 'SpendPoint', 'GetResetCost', 'GetBuyPrice', 'LearnPerk', 'PurchaseRank' }) do
      T.eq(W.calls[n], nil, n .. ' called')
      T.eq(code(W, NSN .. n), 'skipped_denylist', n)
    end
  end)
  T.it('each read-style name is called once per run, with zero arguments', function()
    T.eq(W.calls.GetPoints, 1)
    T.eq(code(W, NSN .. 'GetArgNeeded'), 'error', 'without docs the zero-argument call errors and is recorded')
  end)
  T.it('an oversized return is truncated, and the blocked action is an unexpected condition', function()
    T.truthy(codes(W)[NSN .. 'GetBig'].truncated)
    T.truthy(hasUnexpected(run, 'blocked_action'))
  end)
  T.it('discovers the frame, enum and string by name', function()
    local d = disc(W)
    T.truthy(d.enums.LegacyFixtureTree)
    local frame, str = false, false
    for _, f in ipairs(d.globals.frames) do if f.name == 'LegacyFixtureFrame' then frame = true end end
    for _, s in ipairs(d.globals.strings) do if s.name == 'LEGACY_FIXTURE_TITLE' then str = true end end
    T.truthy(frame and str)
  end)
  T.it('an errored getter is not called again in the same session', function()
    W:slash('run')
    W:advance(30)
    T.eq(W.calls.GetBoom, 1)
    T.eq(code(W, NSN .. 'GetBoom'), 'skipped_errored_before')
  end)
end)

T.describe('limit 8: automatic reruns', function()
  T.it('pane frame shown, Blizzard Legacy addon loaded, level 25 reached: reruns, at most 4 automatic', function()
    local W = F.session({ legacy = 'getters' })
    T.eq(#W:db().runs, 1)
    W.env.LegacyFixtureFrame:Show()
    W:advance(30)
    T.eq(W:lastRun().reason, 'pane')
    T.eq(W:lastRun().paneSeen, 'frame:LegacyFixtureFrame')
    W:fire('ADDON_LOADED', 'Blizzard_LegacyUI')
    W:advance(30)
    T.truthy(W:lastRun().reason:find('addon-Blizzard_LegacyUI', 1, true))
    W.char.level = 25
    W:fire('PLAYER_LEVEL_UP', 25)
    W:advance(30)
    T.eq(W:lastRun().reason, 'level-25')
    T.eq(#W:db().runs, 4)
    W.char.level = 45
    W:fire('PLAYER_LEVEL_UP', 45)
    W:advance(30)
    T.eq(#W:db().runs, 4, 'fifth automatic run refused')
    T.eq(W:db().skippedAutoRuns, 1)
  end)
  T.it('a crafting skill crossing 150 reruns; a level that is not a milestone does not', function()
    local W = F.session({ char = { profIdx = { 1 }, profs = { { name = 'Tailoring', skill = 149, line = 197 } } } })
    W:fire('PLAYER_LEVEL_UP', 11)
    W:advance(10)
    T.eq(#W:db().runs, 1)
    W.char.profs[1].skill = 150
    W:fire('SKILL_LINES_CHANGED')
    W:advance(30)
    T.eq(#W:db().runs, 2)
    T.eq(W:lastRun().reason, 'skill')
  end)
end)

T.describe('limit 5: off switch', function()
  T.it('off stops queued work at once and on later logins; on re-enables', function()
    local W = F.new({ legacy = 'getters', extraGlobals = 5000 })
    F.load(W)
    W:login()
    W:advance(10.5)
    T.truthy(W.NS.Run.state.running, 'a run is in progress when off is typed')
    W:slash('off')
    W:advance(30)
    T.eq(#W:db().runs, 0, 'queued run dropped')
    -- next session with the same saved data
    local W2 = F.new({ legacy = 'getters', db = W:db() })
    F.load(W2)
    W2:login()
    W2:advance(40)
    T.eq(#W2:db().runs, 0)
    T.eq(W2.calls.GetPoints, nil)
    T.truthy(W2.chat[1]:find('is OFF', 1, true))
    W2:slash('on')
    W2:advance(5)
    T.eq(#W2:db().runs, 0, 'on waits for the login delay')
    W2:advance(40)
    T.eq(#W2:db().runs, 1)
    T.eq(W2:lastRun().reason, 'manual-on')
  end)
end)

T.describe('limit 3: spread across frames, paused in combat', function()
  T.it('without a precise timer, at most 40 steps per frame', function()
    local W = F.session({ extraGlobals = 5000 })
    local run = W:lastRun()
    T.truthy(run, 'run finished')
    T.truthy(run.scheduler.maxStepsPerFrame <= 41, 'max ' .. run.scheduler.maxStepsPerFrame)
    T.truthy(run.scheduler.ticks > 100, 'ticks ' .. run.scheduler.ticks)
  end)
  T.it('with a precise timer, it yields at the 2 ms budget', function()
    local W = F.session({ extraGlobals = 2000, precise = 0.25 })
    T.truthy(W:lastRun().scheduler.maxStepsPerFrame <= 9, 'max ' .. W:lastRun().scheduler.maxStepsPerFrame)
  end)
  T.it('no progress while in combat; completes after', function()
    local W = F.new({ legacy = 'getters' })
    F.load(W)
    W:login()
    W.combat = true
    W:advance(60)
    T.eq(#W:db().runs, 0)
    T.eq(W.calls.GetPoints, nil)
    W.combat = false
    W:advance(30)
    T.eq(#W:db().runs, 1)
  end)
end)

T.describe('limit 4: saved data cap', function()
  T.it('stays under 256 KB and keeps at most 20 runs', function()
    local W = F.session({ legacy = 'getters' })
    for _ = 1, 9 do W:slash('run'); W:advance(30) end
    local db = W:db()
    T.truthy(#db.runs <= 20, 'runs ' .. #db.runs)
    T.truthy(db.sizeEstimate <= 256 * 1024, 'size ' .. db.sizeEstimate)
    T.truthy(db.runs[#db.runs].id >= 10)
  end)
  T.it('drops the oldest runs when the runs alone exceed the cap', function()
    local W = F.new({ legacy = 'getters' })
    F.load(W)
    W.NS.Core.DB_LIMIT = 60 * 1024
    W:login()
    W:advance(40)
    for _ = 1, 5 do W:slash('run'); W:advance(30) end
    local db = W:db()
    T.truthy(db.sizeEstimate <= 60 * 1024, 'size ' .. db.sizeEstimate)
    T.truthy(#db.runs < 6, 'runs ' .. #db.runs)
    T.eq(db.runs[#db.runs].id, 6, 'the newest run is kept')
  end)
end)

T.describe('limit 6: no interference with GoldIntel', function()
  T.it('adds only its own globals, leaves GoldIntel data untouched, ignores GoldIntel blocks', function()
    local W = F.new({ legacy = 'getters', datastore = 'good' })
    local before = {}
    for k in pairs(W.env) do before[k] = true end
    local gi, gic = copy(W.env.GoldIntelDB), copy(W.env.GoldIntelCharDB)
    F.load(W)
    W:login()
    W:advance(40)
    W:fire('ADDON_ACTION_FORBIDDEN', 'GoldIntel', 'SomeFunction()')
    W:fire('PLAYER_LOGOUT')
    local added = {}
    for k in pairs(W.env) do if not before[k] then table.insert(added, k) end end
    table.sort(added)
    T.eq(added, { 'EmpireIntelCheckDB', 'SLASH_EMPIREINTELCHECK1' })
    T.eq(keys(W.env.SlashCmdList), 1)
    T.eq(W.env.GoldIntelDB, gi)
    T.eq(W.env.GoldIntelCharDB, gic)
    for _, u in ipairs(W:lastRun().unexpected) do T.falsy(u.detail:find('SomeFunction', 1, true)) end
    for _, u in ipairs(W:db().sessionUnexpected or {}) do T.falsy(u.detail:find('SomeFunction', 1, true), 'session log') end
    for _, b in ipairs(W.NS.Discover.blockedLog) do T.falsy(b.fn:find('SomeFunction', 1, true), 'blocked log') end
    T.eq(W.hookCount, 0, 'no script hooks at all (0.1.1 polls visibility instead)')
  end)
  T.it('registers only allow-listed events', function()
    local W = F.session({ legacy = 'getters', docs = true })
    W:slash('docs')
    W:advance(30)
    local allowed = {}
    for _, e in ipairs(W.NS.Core.EVENTS) do allowed[e] = true end
    for ev in pairs(W.registered) do T.truthy(allowed[ev], 'registered ' .. ev) end
    T.falsy(W.registered.LEGACY_FIXTURE_POINTS_CHANGED, 'discovered events are never registered')
  end)
end)

T.describe('L-5 docs (user command only)', function()
  local W = F.session({ legacy = 'getters', docs = true })
  T.it('not loaded without the command; docs availability is announced', function()
    T.eq(W.calls['LoadAddOn:Blizzard_APIDocumentationGenerated'], nil)
    T.truthy(W.chat[1]:find('/eicheck docs', 1, true))
  end)
  T.it('the command saves matching systems, validates event names, reruns with argument rules', function()
    W:slash('docs')
    W:advance(30)
    local docs = W:db().docs
    T.eq(#docs.systems, 1)
    T.eq(docs.events.LEGACY_FIXTURE_POINTS_CHANGED, true)
    local run = W:lastRun()
    T.eq(run.reason, 'docs')
    T.eq(code(W, 'C_LegacyFixture.GetArgNeeded'), 'skipped_args')
    T.eq(code(W, 'C_LegacyFixture.GetGone'), 'not_found')
    T.eq(W.calls.GetArgNeeded, 1, 'only the first, docs-less run called it')
  end)
end)

T.describe('Part A: DataStore cross-check (T4..T6)', function()
  T.it('good DataStore: money, level, class and item count equal; roster read; estimate uses the alt', function()
    local W = F.session({ datastore = 'good', char = { level = 30 } })
    local run = W:lastRun()
    local x = run.partA.T5.cross
    T.truthy(x.money.equal and x.level.equal and x.class.equal and x.itemCount.equal)
    T.eq(run.partA.T6.count, 2)
    T.eq(run.partA.T4.addons.DataStore.state, 'loaded')
    T.eq(run.partA.T4.addons.DataStore_Crafts.state, 'missing')
    T.eq(run.estimate.classes.MAGE.points, 2)
    T.eq(run.estimate.crafts.Tailoring.points, 2, 'alt profession from DataStore (0.1.1)')
    T.eq(run.estimate.total, 5)
    T.eq(#run.unexpected, 0)
  end)
  T.it('faulty DataStore: each fault is an unexpected condition, nothing is raised', function()
    local W = F.session({ datastore = 'faulty' })
    local run = W:lastRun()
    T.truthy(hasUnexpected(run, 'ds_money_mismatch'))
    T.truthy(hasUnexpected(run, 'ds_method_missing'))
    T.truthy(hasUnexpected(run, 'ds_unknown_name'))
    T.truthy(hasUnexpected(run, 'ds_duplicate_guid'))
    T.truthy(W.chat[2]:find('UNEXPECTED', 1, true))
  end)
end)

T.describe('R-1, P-1, E-1', function()
  T.it('logout writes the rest baseline; the next login compares the projection', function()
    local W = F.session({ char = { level = 30, rest = 1000, resting = true } })
    W:fire('PLAYER_LOGOUT')
    T.eq(W:db().logout['Player-1-00000001'].exhaustion, 1000)
    local W2 = F.new({ db = W:db(), char = { level = 30, rest = 1500, resting = true } })
    W2.wall = W.wall + 8 * 3600
    F.load(W2)
    W2:login()
    W2:advance(40)
    local p = W2:lastRun().char.restProjection
    T.eq(p.projected, 1500)
    T.eq(p.diff, 0)
  end)
  T.it('professions are read and crafting skill feeds the estimate', function()
    local W = F.session({ char = { level = 46, profIdx = { 1, 2 },
      profs = { { name = 'Tailoring', skill = 230, line = 197 }, { name = 'Herbalism', skill = 300, line = 182 } } } })
    local run = W:lastRun()
    T.eq(#run.char.professions.list, 2)
    T.eq(run.estimate.crafts.Tailoring.points, 2)
    T.eq(run.estimate.crafts.Herbalism, nil, 'gathering is not a crafting milestone')
    T.eq(run.estimate.total, 4)
    T.truthy(run.estimate.kind:find('lower bound', 1, true))
  end)
end)

T.describe('unexpected conditions are visible', function()
  T.it('a pre-modern API that came back is reported', function()
    local W = F.session({ premodern = true })
    T.truthy(hasUnexpected(W:lastRun(), 'baseline_changed'))
  end)
  T.it('a character name of Unknown is reported', function()
    local W = F.session({ char = { first = 'Unknown' } })
    T.truthy(hasUnexpected(W:lastRun(), 'name_unknown'))
  end)
  T.it('a run that fails part way is saved as ERROR and later runs still happen', function()
    local W = F.new()
    F.load(W)
    local walk = W.NS.Discover.Walk
    W.NS.Discover.Walk = function() error('simulated failure') end
    W:login()
    W:advance(40)
    T.truthy(W:lastRun().verdict:find('ERROR', 1, true))
    T.truthy(W.chat[#W.chat]:find('run_failed', 1, true))
    W.NS.Discover.Walk = walk
    W:slash('run')
    W:advance(30)
    T.eq(W:lastRun().verdictInfo.verdict, 'NOTHING EXPOSED')
  end)
end)

T.describe('0.1.1: launch-build profile (what run 1 saw)', function()
  local W = F.session({ launch = true, legacy = 'none' })
  local run = W:lastRun()
  T.it('verdict PANE ONLY, provisional because the system is locked; never FOUND on retail look-alikes', function()
    T.eq(run.verdictInfo.verdict, 'PANE ONLY')
    T.eq(run.legacyUnlocked, false)
    T.truthy(run.verdict:find('Legacy system locked', 1, true))
    T.eq(#run.verdictInfo.found, 0)
  end)
  T.it('retail legacy raid, legacy friends and guild challenge names are not called', function()
    T.eq(W.calls['raid.GetText'], nil)
    T.eq(W.calls.GetLegacyRaidDifficultyID, nil)
    T.eq(W.calls.legacyFriend, nil)
  end)
  T.it('a shown-but-invisible guild frame and an always-visible micro button do not count as the pane', function()
    W:advance(5)
    T.eq(W.NS.Run.state.paneSeen, nil)
    T.eq(#W:db().runs, 1)
  end)
  T.it('UI actions are never called; Preset is no longer caught by the Set rule', function()
    T.eq(W.calls.ToggleLegacySystemUI, nil)
    T.eq(W.calls.LegacySystemFrame_LoadUI, nil)
    T.eq(W.calls['legacy.OnClick'], nil)
    T.eq(code(W, 'C_GameRules.GetForeverExperiencePreset'), 'ok')
    T.eq(code(W, 'C_GameRules.SetForeverExperiencePresetPostLogin'), 'skipped_denylist')
    T.eq(W.calls.SetForeverExperiencePresetPostLogin, nil)
  end)
  T.it('the lock getter is the only Legacy UI call that records a value', function()
    T.eq(W.calls.IsLegacySystemUnlocked, 1)
    T.truthy(run.calls.legacy['LegacyMicroButtonMixin.IsLegacySystemUnlocked'])
  end)
end)

T.describe('0.1.1: unlock and pane', function()
  T.it('a Legacy UI addon loading and its frame becoming visible: pane seen, rerun, not locked', function()
    local W = F.session({ launch = true })
    W.unlocked = true
    local pane = { shown = false, scripts = {}, hooks = {}, events = {} }
    function pane:GetObjectType() return 'Frame' end
    function pane:IsShown() return self.shown end
    function pane:IsVisible() return self.shown end
    W.env.LegacySystemFrame = pane
    pane.shown = true
    W:fire('ADDON_LOADED', 'Blizzard_LegacySystem')
    W:advance(40)
    local run = W:lastRun()
    T.eq(W.NS.Run.state.paneSeen, 'addon:Blizzard_LegacySystem')
    T.truthy(run.reason:find('addon-Blizzard_LegacySystem', 1, true))
    T.eq(run.legacyUnlocked, true)
    T.falsy(run.verdict:find('locked', 1, true))
  end)
  T.it('a Legacy frame shown inside a hidden parent at login counts once its parent opens', function()
    local W = F.new({ legacy = 'getters' })
    W.env.LegacyFixtureFrame.shown = true
    W.env.LegacyFixtureFrame.parentHidden = true
    F.load(W)
    W:login(); W:advance(40)
    T.eq(W.NS.Run.state.paneSeen, nil, 'shown but not visible is not the pane')
    W.env.LegacyFixtureFrame.parentHidden = false
    W:advance(3)
    T.eq(W.NS.Run.state.paneSeen, 'frame:LegacyFixtureFrame')
  end)
  T.it('after a Blizzard addon loads, a new Legacy frame that is shown but not visible is not the pane', function()
    local W = F.session({ launch = true })
    local f = { shown = true }
    function f:GetObjectType() return 'Frame' end
    function f:IsShown() return true end
    function f:IsVisible() return false end
    W.env.LegacyTreeFrame = f
    W:fire('ADDON_LOADED', 'Blizzard_SomethingElse')
    W:advance(40)
    T.eq(W.NS.Run.state.paneSeen, nil)
  end)
  T.it('a Legacy frame going from hidden to visible counts as the pane', function()
    local W = F.session({ legacy = 'getters' })
    T.eq(W.NS.Run.state.paneSeen, nil)
    W.env.LegacyFixtureFrame:Show()
    W:advance(3)
    T.eq(W.NS.Run.state.paneSeen, 'frame:LegacyFixtureFrame')
  end)
end)

T.describe('0.1.1: logout baseline (EI-E-08)', function()
  T.it('bad values at logout fall back to the last in-world reading', function()
    local W = F.session({ char = { level = 2, xp = 86, xpMax = 900 } })
    W.char.level = 1; W.char.xpMax = 0
    W:fire('PLAYER_LOGOUT')
    local b = W:db().logout['Player-1-00000001']
    T.eq(b.source, 'last-in-world')
    T.eq(b.level, 2)
    T.eq(b.xpMax, 900)
  end)
  T.it('good values at logout are used as they are', function()
    local W = F.session({ char = { level = 12, xpMax = 5000 } })
    W:fire('PLAYER_LOGOUT')
    T.eq(W:db().logout['Player-1-00000001'].source, 'logout')
  end)
end)

T.describe('0.1.1: storage format 2', function()
  T.it('format 1 data is migrated: old runs compacted, nothing else lost', function()
    local old = { format = 1, nextRunId = 8, chars = { x = { level = 2 } }, logout = {}, bank = {},
      runs = { { id = 8, verdict = 'LEGACY API: FOUND', discovery = { big = string.rep('x', 1000) },
        calls = { counts = { ok = 30 }, calls = 91, results = { a = { code = 'ok' } } } } } }
    local W = F.session({ db = old })
    local db = W:db()
    T.eq(db.format, 2)
    T.eq(db.migratedFrom, 1)
    T.eq(db.runs[1].compacted, 'format 1 -> 2')
    T.isnil(db.runs[1].discovery)
    T.isnil(db.runs[1].calls.results)
    T.eq(db.runs[1].calls.counts.ok, 30)
    T.eq(db.runs[2].id, 9, 'new run numbering continues')
    T.truthy(db.chars.x, 'other data kept')
  end)
  T.it('runs keep no full discovery; db.latest holds one copy; changes are listed per run', function()
    local W = F.session({ legacy = 'getters' })
    local r1 = W:lastRun()
    T.isnil(r1.discovery)
    T.truthy(W:db().latest.discovery)
    T.truthy(r1.calls.legacy['C_LegacyFixture.GetPoints'])
    T.isnil(r1.calls.legacy['C_ChallengeMode.GetMapTable'], 'only Legacy names are kept per run')
    W.env.C_LegacyFixture.GetNewThing = function() return 1 end
    W:slash('run')
    W:advance(30)
    local added = table.concat(W:lastRun().discoveryChanges.added, ',')
    T.truthy(added:find('C_LegacyFixture.GetNewThing', 1, true), added)
    T.truthy(W:db().strongSeen['C_LegacyFixture.GetNewThing'])
  end)
end)

T.describe('0.1.1: docs index and field matching', function()
  T.it('saves an index of every system and finds a neutrally named system by a field name', function()
    local W = F.new({ docs = true })
    table.insert(W.docsTable.systems, { Name = 'AccountProgress', Namespace = 'C_AccountProgress',
      Functions = { { Name = 'GetProgressInfo', Arguments = {}, Returns = { { Name = 'info', Type = 'AccountProgressInfo' } } } },
      Tables = { { Name = 'AccountProgressInfo', Type = 'Structure', Fields = { { Name = 'legacyPoints', Type = 'number' } } } } })
    F.load(W)
    W:login(); W:advance(40)
    W:slash('docs'); W:advance(30)
    local docs = W:db().docs
    T.eq(#docs.index, 3)
    local names = {}
    for _, sys in ipairs(docs.systems) do names[#names + 1] = sys.name end
    T.truthy(table.concat(names, ','):find('AccountProgress', 1, true))
  end)
end)

T.describe('0.1.1: T8 errors seen by BugSack', function()
  T.it('counts errors per addon, flags our own, never stores locals', function()
    local W = F.session({ bugs = true })
    local t8 = W:lastRun().partA.T8
    T.eq(t8.byAddon.EmpireIntelCheck, 2)
    T.eq(t8.byAddon.ElvUI, 1)
    T.eq(#t8.ours, 1)
    T.truthy(hasUnexpected(W:lastRun(), 'own_lua_error'))
    T.falsy(T.serialize(W:db()):find('SENTINEL_LOCALS_42', 1, true), 'BugGrabber locals never copied')
  end)
  T.it('without BugGrabber, T8 just says it is absent', function()
    local W = F.session({})
    T.eq(W:lastRun().partA.T8.present, false)
  end)
end)

T.describe('0.1.1: docs processing is spread across frames (limit 3)', function()
  T.it('600 documented systems are processed over many frames, not in one', function()
    local W = F.new({ docs = true })
    for i = 1, 600 do table.insert(W.docsTable.systems, { Name = 'Sys' .. i, Namespace = 'C_Sys' .. i, Functions = { { Name = 'GetX' } } }) end
    F.load(W)
    W:login(); W:advance(40)
    local before = W.NS.Core.stats.ticks
    W:slash('docs')
    T.isnil(W:db().docs and W:db().docs.systems, 'nothing processed inside the slash command')
    W:advance(60)
    T.truthy(W:db().docs.systemCount >= 600)
    T.truthy(W.NS.Core.stats.ticks - before > 10, 'ticks ' .. (W.NS.Core.stats.ticks - before))
    T.truthy(W.NS.Core.stats.maxSteps <= 41, 'max steps ' .. W.NS.Core.stats.maxSteps)
    local saw = false
    for _, line in ipairs(W.chat) do if line:find('docs: saved', 1, true) then saw = true end end
    T.truthy(saw, 'result line printed')
  end)
end)

T.describe('0.1.3: docs survive the size cap (launch-build run 3)', function()
  local function bigSystem(name, ns, legacyField)
    local fns, tbls = {}, {}
    for i = 1, 150 do
      local args = {}
      for j = 1, 6 do args[j] = { Name = 'argument' .. j .. string.rep('x', 20), Type = 'number', Nilable = false } end
      fns[i] = { Name = 'GetPerkThing' .. i, Arguments = args, Returns = args }
    end
    for i = 1, 80 do
      local fields = {}
      for j = 1, 25 do fields[j] = { Name = 'field' .. j .. string.rep('y', 20), Type = 'string' } end
      if legacyField and i == 1 then fields[1] = { Name = 'legacyPointsEarned', Type = 'number' } end
      tbls[i] = { Name = 'PerkTable' .. i, Type = 'Structure', Fields = fields }
    end
    return { Name = name, Namespace = ns, Functions = fns, Tables = tbls, Events = {} }
  end
  local W = F.new({ legacy = 'getters', docs = true, extraGlobals = 3000 })
  for i = 1, 12 do table.insert(W.docsTable.systems, bigSystem('PerkSystem' .. i, 'C_PerkSystem' .. i)) end
  table.insert(W.docsTable.systems, bigSystem('AccountProgress', 'C_AccountProgress', true))
  F.load(W)
  W:login(); W:advance(40)
  W:slash('docs'); W:advance(80)
  for _ = 1, 3 do W:slash('run'); W:advance(40) end
  local docs = W:db().docs
  T.it('docs are kept, not dropped, and the total stays under the cap', function()
    T.truthy(docs and docs.systems, 'docs.systems present')
    T.isnil(docs.dropped)
    T.truthy(W:db().sizeEstimate <= 256 * 1024, 'size ' .. W:db().sizeEstimate)
  end)
  T.it('systems with Legacy names keep signatures and fields; others keep names only', function()
    local legacyFound, weakHasArgs = false, false
    for _, sys in ipairs(docs.systems) do
      if sys.name == 'AccountProgress' then
        legacyFound = sys.legacy and #sys.functions[1].args > 0 and #sys.tables[1].fields > 0
      elseif not sys.legacy and sys.functions[1] and sys.functions[1].args then
        weakHasArgs = true
      end
    end
    T.truthy(legacyFound, 'the Legacy system is stored with detail')
    T.falsy(weakHasArgs, 'non-Legacy systems keep names only')
    T.truthy(docs.strongSystems >= 2, 'LegacyFixture and AccountProgress')
  end)
  T.it('anything left out is listed by name', function()
    T.truthy(type(docs.skipped) == 'table')
    T.truthy(#docs.systems + #docs.skipped >= 14, 'kept ' .. #docs.systems .. ' skipped ' .. #docs.skipped)
  end)
end)

T.describe('0.1.3: under cap pressure the docs go last', function()
  local function sys(name, ns, n)
    local fns = {}
    for i = 1, n do fns[i] = { Name = 'GetPerkItem' .. i, Arguments = { { Name = 'id', Type = 'number', Nilable = false } } } end
    return { Name = name, Namespace = ns, Functions = fns, Events = {}, Tables = {} }
  end
  T.it('cheap data is shed first; the Legacy docs survive; budget and post-docs trim hold', function()
    local W = F.new({ legacy = 'getters', docs = true, extraGlobals = 2000 })
    for i = 1, 30 do table.insert(W.docsTable.systems, sys('PerkSys' .. i, 'C_PerkSys' .. i, 120)) end
    F.load(W)
    W.NS.Core.DB_LIMIT = 70 * 1024
    W:login(); W:advance(40)
    for _ = 1, 4 do W:slash('run'); W:advance(40) end
    W:slash('docs')
    W:advance(0.5)                               -- the docs job is done; the rerun (1 s later) has not run yet
    local db = W:db()
    T.truthy(db.docs and db.docs.systems, 'docs kept')
    local U = W.NS.U
    local systemsSize = U.size(db.docs.systems)
    T.truthy(systemsSize <= W.NS.Discover.DOCS_BUDGET + 4096, 'docs within budget (measured): ' .. systemsSize)
    local total = U.size(db)
    T.truthy(total <= 70 * 1024 + 64, 'trimmed right after docs (measured): ' .. total)
    local legacy = false
    for _, s in ipairs(db.docs.systems) do if s.name == 'LegacyFixture' then legacy = true end end
    T.truthy(legacy, 'the Legacy system is still there')
    T.truthy(db.latest.valuesDropped or db.latest.namesDropped or #db.runs < 5, 'cheaper data went first')
  end)
end)

T.describe('0.1.4: undocumented namespaces (Q-T3 limits)', function()
  local function count(W, prefix) local n = 0; for k, v in pairs(W.calls) do if k:sub(1, #prefix) == prefix then n = n + v end end; return n end
  T.it('passive run lists every undocumented namespace and calls none of them', function()
    local W = F.session({ undoc = true })
    local u = W:db().undoc
    T.truthy(u and u.namespaces.C_Seasons.present)
    T.eq(u.namespaces.C_Seasons.policy, 'call-on-command')
    T.eq(u.namespaces.C_Reincarnation.policy, 'review')
    T.eq(u.namespaces.C_AccountServices.policy, 'list')
    T.eq(u.namespaces.C_Debug.policy, 'list')
    T.eq(u.namespaces.C_Reincarnation.members.Reincarnate, 'function', 'Reincarnation function list for review')
    for _, p in ipairs({ 'C_Seasons.', 'C_Trophy.', 'C_Reincarnation.', 'C_AccountServices.', 'C_Debug.' }) do
      T.eq(count(W, p), 0, p .. ' called passively')
    end
  end)
  T.it('the plan holds only zero-argument read names that pass the extended denylist', function()
    local W = F.session({ undoc = true })
    local plan = table.concat(W:db().undoc.plan, ',')
    T.truthy(plan:find('C_Seasons.GetActiveSeason', 1, true))
    T.truthy(plan:find('C_Seasons.HasActiveSeason', 1, true))
    T.truthy(plan:find('C_Trophy.GetTrophyListInfo', 1, true))
    for _, bad in ipairs({ 'IsSeasonOpen', 'RequestSeasonInfo', 'SetSeason', 'ShowTrophy', 'ClaimTrophy', 'Reincarnat', 'AccountThing', 'DebugThing' }) do
      T.falsy(plan:find(bad, 1, true), bad .. ' planned')
    end
  end)
  T.it('/eicheck undoc calls the plan once, with the crash marker set during each call and cleared after', function()
    local W = F.session({ undoc = true })
    W:slash('undoc')
    W:advance(5)
    local u = W:db().undoc
    T.eq(W.calls['C_Seasons.GetActiveSeason'], 1)
    T.eq(W.inFlightSeen, 'C_Seasons.GetActiveSeason', 'name written before the call')
    T.isnil(W:db().inFlight, 'cleared after')
    T.eq(u.results['C_Seasons.GetActiveSeason'].code, 'ok')
    T.eq(u.results['C_Trophy.GetTrophyListInfo'].code, 'returned_nothing')
    T.eq(u.results['C_Trophy.GetTrophyByIndex'].code, 'error')
    for _, n in ipairs({ 'C_Seasons.IsSeasonOpen', 'C_Seasons.RequestSeasonInfo', 'C_Seasons.SetSeason', 'C_Trophy.ShowTrophy', 'C_Trophy.ClaimTrophy' }) do
      T.eq(W.calls[n], nil, n)
    end
    T.eq(count(W, 'C_Reincarnation.'), 0)
    T.eq(count(W, 'C_AccountServices.'), 0)
    T.eq(count(W, 'C_Debug.'), 0)
    local saw = false
    for _, line in ipairs(W.chat) do if line:find('undoc: ', 1, true) and line:find('/reload', 1, true) then saw = true end end
    T.truthy(saw, 'result line asks for /reload')
  end)
  T.it('a call that did not finish last session is never made again', function()
    local W = F.new({ undoc = true, db = { format = 2, runs = {}, chars = {}, logout = {}, bank = {},
      inFlight = { name = 'C_Seasons.GetActiveSeason', at = 1 } } })
    F.load(W)
    W:login(); W:advance(40)
    local db = W:db()
    T.truthy(db.neverCall['C_Seasons.GetActiveSeason'])
    T.isnil(db.inFlight)
    local flagged = false
    for _, u in ipairs(db.sessionUnexpected or {}) do if u.code == 'interrupted_call' then flagged = true end end
    T.truthy(flagged, 'reported as unexpected')
    T.falsy(table.concat(db.undoc.plan, ','):find('GetActiveSeason', 1, true), 'not planned')
    W:slash('undoc'); W:advance(5)
    T.eq(W.calls['C_Seasons.GetActiveSeason'], nil, 'not called')
  end)
  T.it('the crash guard also covers the regular Legacy getters', function()
    local W = F.new({ legacy = 'getters', db = { format = 2, runs = {}, chars = {}, logout = {}, bank = {},
      inFlight = { name = 'C_LegacyFixture.GetPoints', at = 1 } } })
    F.load(W)
    W:login(); W:advance(40)
    T.eq(W.calls.GetPoints, nil, 'interrupted getter not called again')
    T.eq(W:db().latest.results['C_LegacyFixture.GetPoints'].code, 'skipped_crash_guard')
  end)
  T.it('with the docs index, a live namespace missing from the docs is listed, not called', function()
    local W = F.session({ undoc = true, docs = true })
    W:slash('docs'); W:advance(40)
    W:slash('run'); W:advance(40)
    local e = W:db().undoc.namespaces.C_NewSecretThing
    T.truthy(e and e.origin == 'new' and e.policy == 'list')
    W:slash('undoc'); W:advance(5)
    T.eq(W.calls['C_NewSecretThing.GetX'], nil)
  end)
  T.it('the extended denylist applies to every call (Show, Open, Toggle, Claim, Request, Reincarnate)', function()
    local U = F.load(F.new()).U
    for _, n in ipairs({ 'LegacyX.Show', 'C_X.IsOpen', 'C_X.GetToggleState', 'C_X.GetClaim', 'C_X.GetRequestId', 'C_X.GetReincarnateCost' }) do
      T.truthy(U.denied(n), n)
    end
    T.falsy(U.denied('C_GameRules.GetForeverExperiencePreset'))
    T.falsy(U.denied('LegacyMicroButtonMixin.IsLegacySystemUnlocked'))
  end)
end)

T.describe('0.1.4: defect 10 (docs enum members named Legacy)', function()
  T.it('a system whose only Legacy match is an enum member is not a Legacy system', function()
    local W = F.new({ docs = true })
    table.insert(W.docsTable.systems, { Name = 'KeyBindings', Namespace = 'C_KeyBindings', Functions = { { Name = 'GetTurnStrafeStyle', Arguments = {} } },
      Tables = { { Name = 'TurnStrafeStyle', Type = 'Enumeration', Fields = { { Name = 'Modern' }, { Name = 'Legacy' } } } } })
    F.load(W)
    W:login(); W:advance(40)
    W:slash('docs'); W:advance(40)
    for _, s in ipairs(W:db().docs.systems) do
      if s.name == 'KeyBindings' then T.falsy(s.legacy, 'KeyBindings marked Legacy') end
    end
  end)
end)

T.describe('0.1.5: whole CamelCase words and the stem Reincarnat (user, Q-T5)', function()
  local U = F.load(F.new()).U
  T.it('blocked: a whole word equal to a blocked word, in any segment or case', function()
    for _, n in ipairs({ 'C_X.SetSeason', 'C_X.GetResetCost', 'C_X.GetBuyPrice', 'PurchaseRank', 'C_X.GetRequestId',
        'C_Seasons.IsSeasonOpen', 'C_X.GetToggleState', 'C_X.ShowFrame', 'C_X.GetClaim', 'C_X.SpendPoint', 'C_X.LearnPerk',
        'GuildChallengeAlertSystem.setUpFunction', 'LEGACY_SET_X' }) do
      T.truthy(U.denied(n), n)
    end
  end)
  T.it('blocked: anything starting with the stem Reincarnat', function()
    for _, n in ipairs({ 'C_Reincarnation.GetReincarnatingCharacter', 'C_Reincarnation.IsReincarnating',
        'C_X.GetReincarnationInfo', 'C_X.GetReincarnateCost' }) do
      T.truthy(U.denied(n), n)
    end
  end)
  T.it('allowed: words that only contain a blocked word', function()
    for _, n in ipairs({ 'C_GameRules.GetForeverExperiencePreset', 'LegacyX.IsShown', 'C_X.GetClaimable', 'IsPerkLearned',
        'C_X.GetBuyout', 'C_X.GetUnset', 'C_X.GetAssetInfo', 'C_X.GetSpellOffset', 'C_Seasons.GetActiveSeason',
        'LegacyMicroButtonMixin.IsLegacySystemUnlocked' }) do
      T.falsy(U.denied(n), n)
    end
  end)
  T.it('CamelCase split handles acronyms and digits', function()
    T.eq(U.words('C_X.GetUIState'), { 'C', 'X', 'Get', 'UI', 'State' })
    T.eq(U.words('GetItem2Count'), { 'Get', 'Item', '2', 'Count' })
  end)
end)

T.describe('0.1.5: defect 11 wording', function()
  T.it('undoc before the first check says to retry in about 10 seconds', function()
    local W = F.new({ undoc = true })
    F.load(W)
    W:login(); W:advance(2)
    W:slash('undoc')
    T.truthy(W.chat[#W.chat]:find('try again in about 10 seconds', 1, true), W.chat[#W.chat])
  end)
end)
