local ADDON, NS = ...
-- EmpireIntelCheck / Run.lua  (last file in the TOC)
-- Orchestration: login delay, runs, verdict, provisional rule, automatic reruns, logout snapshot.
-- Architecture.md section 9, runtime limits 2, 5, 6, 7, 8.

local U = NS.U
local C = NS.Core
local A = NS.PartA
local Ch = NS.Character
local D = NS.Discover
local R = {}
NS.Run = R

R.MAX_AUTO_RUNS = 4
R.RESCAN_MIN_GAP = 30

local S = {                 -- session state (not saved)
  ready = false,            -- login delay passed
  loggedIn = false,
  autoRuns = 0,
  pending = nil,            -- reasons waiting for the login delay or for the running job
  running = false,
  paneSeen = nil,           -- nil | 'frame:<name>' | 'user' | 'addon:<name>'
  hooked = {},              -- frame name -> true
  watchFrames = {},         -- names polled for IsShown
  lastRelevant = nil,       -- relevant name count of the last full run
  lastRescan = -1000,
  unexpected = {},
  current = nil,
  guid = nil,
}
R.state = S

---------------------------------------------------------------------------
-- Unexpected conditions: saved with the run, summarized in chat line 2 (NFR-3)
---------------------------------------------------------------------------
function R.Unexpected(code, detail, run)
  run = run or S.current
  local item = { code = code, detail = U.ascii(tostring(detail or '')), at = U.now() }
  if run then
    run.unexpected = run.unexpected or {}
    if #run.unexpected < 50 then table.insert(run.unexpected, item) end
  else
    if #S.unexpected < 50 then table.insert(S.unexpected, item) end
    local db = NS.env.EmpireIntelCheckDB
    if type(db) == 'table' then
      db.sessionUnexpected = db.sessionUnexpected or {}
      if #db.sessionUnexpected < 50 then table.insert(db.sessionUnexpected, item) end
    end
  end
end

---------------------------------------------------------------------------
-- Scheduling (limit 8: at most 4 automatic runs per session, manual ones are extra)
---------------------------------------------------------------------------
function R.Schedule(reason, delay, manual)
  if C.IsOff() then return false end
  if not manual then
    if S.autoRuns >= R.MAX_AUTO_RUNS then
      local db = C.DB()
      db.skippedAutoRuns = (db.skippedAutoRuns or 0) + 1
      return false
    end
  end
  if not S.ready or S.running or S.pending then
    S.pending = S.pending or { reasons = {}, manual = false }
    table.insert(S.pending.reasons, reason)
    if manual then S.pending.manual = true end
    if S.ready and not S.running and not S.pending.timer then
      S.pending.timer = true
      C.After(delay or 0, R.FlushPending)
    end
    return true
  end
  S.pending = { reasons = { reason }, manual = manual and true or false, timer = true }
  C.After(delay or 0, R.FlushPending)
  return true
end

function R.FlushPending()
  if C.IsOff() or not S.ready or S.running or not S.pending then return end
  local p = S.pending
  S.pending = nil
  if not p.manual then S.autoRuns = S.autoRuns + 1 end
  R.Start(table.concat(p.reasons, '+'), p.manual)
end

---------------------------------------------------------------------------
-- One run, as a scheduler job
---------------------------------------------------------------------------
local function safe(run, label, fn, ...)
  local ok, res = pcall(fn, ...)
  if not ok then R.Unexpected('probe_error', label .. ': ' .. tostring(res), run); return { error = U.ascii(tostring(res)) } end
  return res
end

local function relevantCount(rec)
  local n = { candidates = 0, namespaces = 0, enums = 0, tables = 0, frames = 0, functions = 0 }
  for _, c in pairs(rec.candidates or {}) do if not c.unrelated then n.candidates = n.candidates + 1 end end
  for _, m in pairs(rec.matchedNamespaces or {}) do if not m.unrelated then n.namespaces = n.namespaces + 1 end end
  for _, e in pairs(rec.enums or {}) do if not e.unrelated then n.enums = n.enums + 1 end end
  local g = rec.globals or {}
  for _, t in ipairs(g.tables or {}) do if not t.unrelated then n.tables = n.tables + 1 end end
  for _, f in ipairs(g.frames or {}) do if not f.unrelated then n.frames = n.frames + 1 end end
  n.total = n.candidates + n.namespaces + n.enums + n.tables + n.frames
  return n
end
R.RelevantCount = relevantCount

function R.Verdict(rec, calls, estimate)
  local n = relevantCount(rec)
  local found = {}
  for full, res in pairs(calls and calls.results or {}) do
    local c = rec.candidates[full]
    if c and not c.unrelated and D.Meaningful(res) then table.insert(found, full) end
  end
  table.sort(found)
  local v = { counts = n, found = found }
  if #found > 0 then
    v.verdict = 'FOUND'
  elseif n.candidates + n.namespaces + n.enums + n.tables > 0 then
    v.verdict = 'NAMES ONLY'
  elseif n.frames > 0 then
    v.verdict = 'PANE ONLY'
  else
    v.verdict = 'NOTHING EXPOSED'
    local reasons = {}
    if not S.paneSeen then table.insert(reasons, 'Legacy pane not seen opening yet') end
    if not estimate or (estimate.total or 0) == 0 then table.insert(reasons, 'no Legacy point expected yet') end
    if #reasons > 0 then
      v.provisional = true
      v.provisionalReasons = reasons
    end
  end
  v.text = 'LEGACY API: ' .. v.verdict
  if v.provisional then v.text = v.text .. ' (provisional: ' .. table.concat(v.provisionalReasons, '; ') .. ')' end
  return v
end

local function nsDiff(db, rec, build)
  if type(db.nsBaseline) ~= 'table' then
    db.nsBaseline = { build = build, list = rec.namespaces.all, at = U.wall() }
    return { baseline = 'set now', count = rec.namespaces.count }
  end
  local base, now = {}, {}
  for _, n in ipairs(db.nsBaseline.list or {}) do base[n] = true end
  for _, n in ipairs(rec.namespaces.all) do now[n] = true end
  local added, removed = {}, {}
  for n in pairs(now) do if not base[n] then table.insert(added, n) end end
  for n in pairs(base) do if not now[n] then table.insert(removed, n) end end
  table.sort(added); table.sort(removed)
  return { baselineBuild = db.nsBaseline.build, count = rec.namespaces.count, added = added, removed = removed }
end

local function hookFrames(rec)
  for _, f in ipairs(rec.globals and rec.globals.frames or {}) do
    if not f.unrelated and not S.hooked[f.name] then
      local obj = NS.G(f.name)
      if type(obj) == 'table' and type(obj.HookScript) == 'function' then
        local name = f.name
        local ok = pcall(obj.HookScript, obj, 'OnShow', function() R.PaneSeen('frame:' .. name) end)
        S.hooked[name] = ok and true or 'failed'
      end
      table.insert(S.watchFrames, f.name)
    end
  end
end

function R.Start(reason, manual)
  S.running = true
  C.Enqueue(function()
    local db = C.DB()
    db.nextRunId = (db.nextRunId or 0) + 1
    local run = { id = db.nextRunId, reason = reason, manual = manual or nil, at = U.wall(), version = NS.VERSION,
      unexpected = {} }
    S.current = run
    C.lines = 0
    local ident = safe(run, 'T3', A.T3, run)
    S.guid = ident and ident.guid or S.guid
    run.guid, run.name = ident.guid, ident.name
    C.Checkpoint()
    run.partA = { T3 = ident }
    run.partA.T1 = safe(run, 'T1', A.T1)
    run.build = run.partA.T1 and run.partA.T1.build
    run.partA.T2 = safe(run, 'T2', A.T2, run); C.Checkpoint()
    run.partA.T4 = safe(run, 'T4', A.T4); C.Checkpoint()
    run.partA.T5 = safe(run, 'T5', A.T5, run, ident); C.Checkpoint()
    run.partA.T6 = safe(run, 'T6', A.T6, run); C.Checkpoint()
    -- R-1, P-1 and the snapshot used by E-1
    local okS, snap, rest, profs = pcall(Ch.Snapshot, run.guid)
    if okS then
      run.char = { snapshot = snap, rest = rest, professions = profs }
      local last = run.guid and db.logout[run.guid]
      if last then run.char.restProjection = Ch.Project(last, rest) end
    else
      R.Unexpected('probe_error', 'character: ' .. tostring(snap), run)
    end
    C.Checkpoint()
    -- Part B discovery (these loops checkpoint internally and pcall each item)
    local rec = {}
    D.Walk(rec)
    D.Addons(rec)
    rec.namespaces.diff = nsDiff(db, rec, run.build)
    D.CallAll(rec, run)
    -- E-1
    local dsChars = {}
    for _, c in ipairs(run.partA.T6 and run.partA.T6.chars or {}) do
      if type(c.level) == 'number' then table.insert(dsChars, { class = c.class, level = c.level }) end
    end
    run.estimate = safe(run, 'E-1', Ch.Estimate, dsChars)
    -- verdict
    local v = R.Verdict(rec, run.calls, run.estimate)
    run.verdict = v.text
    run.verdictInfo = v
    run.paneSeen = S.paneSeen
    run.addonLoads = S.addonLoads
    rec.namespaces.all = nil        -- kept once in db.nsBaseline
    run.discovery = rec
    run.discovery.candidateCount = 0
    for _ in pairs(rec.candidates) do run.discovery.candidateCount = run.discovery.candidateCount + 1 end
    run.discovery.candidates = nil  -- the call results carry every candidate name
    run.scheduler = { ticks = C.stats.ticks, maxStepsPerFrame = C.stats.maxSteps }
    S.lastRelevant = v.counts.total
    hookFrames(rec)
    table.insert(db.runs, run)
    local size = C.Trim()
    run.dbSize = size
    -- chat: at most two lines (limit 6)
    local docsHint = rec.addons and rec.addons.docsAvailable and '; docs available: /eicheck docs' or ''
    C.Say(v.text .. '. Run ' .. run.id .. ' (' .. tostring(reason) .. ')' .. docsHint .. '. Data in EmpireIntelCheckDB.')
    if #run.unexpected > 0 then
      local codes, seen = {}, {}
      for _, u in ipairs(run.unexpected) do
        if not seen[u.code] then seen[u.code] = true; table.insert(codes, u.code) end
      end
      C.Say('UNEXPECTED ' .. #run.unexpected .. ': ' .. table.concat(codes, ', ') .. ' (details saved)')
    end
    R.Finish()
  end, 'run', function(err)
    -- a run failed part way: keep what it has, mark it, and let later runs happen
    local run = S.current
    if run then
      run.verdict = 'ERROR (run failed; see unexpected)'
      table.insert(run.unexpected, { code = 'run_failed', detail = U.ascii(tostring(err)) })
      run.calls = nil
      pcall(function() table.insert(C.DB().runs, run); C.Trim() end)
      C.Say('UNEXPECTED run_failed: ' .. U.ascii(tostring(err)), true)
    end
    R.Finish()
  end)
end

function R.Finish()
  S.current = nil
  S.running = false
  if S.pending and not S.pending.timer then
    S.pending.timer = true
    C.After(1, R.FlushPending)
  end
end

-- Off switch support (limit 5): drop session work; re-enable with the login delay.
function R.Reset()
  S.running = false
  S.current = nil
  S.pending = nil
  S.ready = false
end

function R.Enable()
  if not S.loggedIn then return end
  C.After(C.LOGIN_DELAY, function()
    S.ready = true
    R.Schedule('manual-on', 0, true)
  end)
end

---------------------------------------------------------------------------
-- Triggers (limit 8)
---------------------------------------------------------------------------
function R.PaneSeen(src)
  if C.IsOff() then return end
  local first = not S.paneSeen
  S.paneSeen = S.paneSeen or src
  if src == 'user' then
    R.Schedule('pane-user', 0, true)
  elseif first then
    R.Schedule('pane', 2)
  end
end

-- Light rescan after a Blizzard UI addon loads: names only, no calls; a full run follows if new names appear.
function R.LightRescan(addonName)
  if C.IsOff() or not S.ready then return end
  if U.now() - S.lastRescan < R.RESCAN_MIN_GAP then return end
  S.lastRescan = U.now()
  C.Enqueue(function()
    local rec = {}
    D.Walk(rec)
    local n = relevantCount(rec)
    if S.lastRelevant and n.total > S.lastRelevant then
      R.Schedule('new-names-after-' .. addonName, 1)
    end
  end, 'rescan')
end

local function pollFrames()
  if C.IsOff() then return end
  for _, name in ipairs(S.watchFrames) do
    local f = NS.G(name)
    if type(f) == 'table' and type(f.IsShown) == 'function' then
      local ok, shown = pcall(f.IsShown, f)
      if ok and shown then R.PaneSeen('frame:' .. name); return end
    end
  end
end

---------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------
C.On('ADDON_LOADED', function(name)
  if name == ADDON then
    local db = C.DB()
    db.addonVersion = NS.VERSION
    C.InstallSlash()
    if C.IsOff() then C.Say('is OFF. Nothing runs. /eicheck on to re-enable.', true) end
    return
  end
  if C.IsOff() or not S.loggedIn or type(name) ~= 'string' then return end
  S.addonLoads = S.addonLoads or {}
  if #S.addonLoads < 40 then table.insert(S.addonLoads, { name = name, at = U.now() }) end
  if string.sub(name, 1, 9) == 'Blizzard_' then
    if U.term(name) then
      S.paneSeen = S.paneSeen or ('addon:' .. name)
      R.Schedule('addon-' .. name, 3)
    else
      C.After(3, function() R.LightRescan(name) end)
    end
  end
end)

C.On('PLAYER_ENTERING_WORLD', function()
  if S.loggedIn then return end
  S.loggedIn = true
  if C.IsOff() then return end
  C.After(C.LOGIN_DELAY, function()
    S.ready = true
    R.Schedule('login', 0)
  end)
end)

C.On('PLAYER_LEVEL_UP', function(level)
  if C.IsOff() or not S.ready then return end
  if type(level) == 'number' and Ch.CrossedLevel(level) then R.Schedule('level-' .. level, 3) end
end)

local skillPending = false
C.On('SKILL_LINES_CHANGED', function()
  if C.IsOff() or not S.ready or skillPending then return end
  skillPending = true
  C.After(2, function()
    skillPending = false
    local db = C.DB()
    local guid = S.guid
    local before = guid and db.chars[guid] and db.chars[guid].crafts or nil
    local copy = {}
    for k, v in pairs(before or {}) do copy[k] = v end
    local ok, snap = pcall(Ch.Snapshot, guid)
    if ok and snap and Ch.CrossedSkill(copy, snap.crafts) then R.Schedule('skill', 1) end
  end)
end)

C.On('PLAYER_LOGOUT', function()
  -- tiny write only: the rested-XP baseline for the next login's projection check
  if C.IsOff() then return end
  local ok, rest = pcall(Ch.Rest)
  local g = S.guid
  if not g then
    local _, v = A.Call('UnitGUID', 'player')
    g = v and v[1]
  end
  if ok and type(g) == 'string' then C.DB().logout[g] = rest end
end)

local function onBlocked(addon, fn)
  if addon ~= ADDON then return end      -- other addons' blocks (GoldIntel or anything else) are not ours
  if #D.blockedLog < 50 then
    table.insert(D.blockedLog, { fn = U.ascii(tostring(fn)), during = D.current, at = U.now() })
  end
  R.Unexpected('blocked_action', tostring(fn) .. ' during ' .. tostring(D.current))
end
C.On('ADDON_ACTION_FORBIDDEN', onBlocked)
C.On('ADDON_ACTION_BLOCKED', onBlocked)

table.insert(C.pollers, pollFrames)
table.insert(C.pollers, function() if not C.IsOff() and S.ready then A.PollBank() end end)

C.Boot()
