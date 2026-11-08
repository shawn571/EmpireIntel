local ADDON, NS = ...
-- EmpireIntelCheck / Core.lua
-- Saved data, the event allow-list, the frame-spread scheduler, chat output and the off switch.
-- Architecture.md section 9, runtime limits 2 to 6. This is the ONLY file that calls RegisterEvent.

local U = NS.U
local C = {}
NS.Core = C

C.LOGIN_DELAY = 10          -- seconds after PLAYER_ENTERING_WORLD before any heavy work (limit 2)
C.FRAME_BUDGET_MS = 2       -- per-frame work budget with a precise timer (limit 3)
C.FRAME_STEPS = 40          -- per-frame step cap without one
C.DB_LIMIT = 256 * 1024     -- saved-data cap in bytes (limit 4)
C.MAX_RUNS_KEPT = 20       -- format 2 runs are small (the full discovery is kept once)

-- Events: GoldIntel-proven ones plus three every addon uses (section 9 safety rules).
C.EVENTS = {
  'ADDON_LOADED', 'PLAYER_LOGIN', 'PLAYER_ENTERING_WORLD', 'PLAYER_LOGOUT', 'PLAYER_LEVEL_UP',
  'SKILL_LINES_CHANGED', 'PLAYER_REGEN_DISABLED', 'PLAYER_REGEN_ENABLED',
  'ADDON_ACTION_FORBIDDEN', 'ADDON_ACTION_BLOCKED',
}

C.handlers = {}       -- event -> list of fn(...)
C.jobs = {}           -- queue of coroutines
C.timers = {}         -- { at = GetTime, fn = fn }
C.pollers = {}        -- fn() called about once per second
C.registered = {}
C.lines = 0           -- chat lines printed in the current run
C.stats = { ticks = 0, maxSteps = 0 }

---------------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------------

function C.DB()
  local env = NS.env
  local db = env.EmpireIntelCheckDB
  if type(db) ~= 'table' then
    db = {}
    env.EmpireIntelCheckDB = db
  end
  db.runs = type(db.runs) == 'table' and db.runs or {}
  -- Format 1 -> 2 (approved, Q-T1): old runs keep their verdict, results counts and Part A,
  -- but drop their full discovery and call results (they are in the user's report already).
  if db.format == 1 then
    for _, r in ipairs(db.runs) do
      if type(r) == 'table' then
        r.discovery = nil
        if type(r.calls) == 'table' then r.calls = { counts = r.calls.counts, calls = r.calls.calls } end
        r.compacted = 'format 1 -> 2'
      end
    end
    db.migratedFrom = 1
  end
  db.format = 2
  db.strongSeen = type(db.strongSeen) == 'table' and db.strongSeen or {}
  db.neverCall = type(db.neverCall) == 'table' and db.neverCall or {}
  db.chars = type(db.chars) == 'table' and db.chars or {}
  db.logout = type(db.logout) == 'table' and db.logout or {}
  db.bank = type(db.bank) == 'table' and db.bank or {}
  db.docs = type(db.docs) == 'table' and db.docs or nil
  return db
end

function C.IsOff()
  local db = NS.env.EmpireIntelCheckDB
  return type(db) == 'table' and db.off == true
end

-- Keep the saved data under the cap: drop the oldest runs first, then trim the largest sections.
-- Keep the saved data under the cap. Docs are the most valuable evidence and go LAST
-- (run 3 lost them because they were trimmed before cheaper data).
function C.Trim()
  local db = C.DB()
  while #db.runs > C.MAX_RUNS_KEPT do table.remove(db.runs, 1) end
  local size = U.size(db)
  local function over() return size > C.DB_LIMIT end
  local function again() size = U.size(db) end
  while over() and #db.runs > 3 do table.remove(db.runs, 1); again() end
  if over() and db.latest and db.latest.results then
    for _, res in pairs(db.latest.results) do res.values = nil end
    db.latest.valuesDropped = 'over size cap'; again()
  end
  if over() and db.latest and db.latest.names then
    db.latest.names = nil; db.latest.namesDropped = 'over size cap'; again()
  end
  if over() and db.latest and db.latest.discovery then
    db.latest.discovery = { dropped = 'over size cap' }; again()
  end
  if over() and db.nsBaseline and db.nsBaseline.list then
    db.nsBaseline = nil; db.nsBaselineDropped = 'over size cap'; again()
  end
  while over() and #db.runs > 1 do table.remove(db.runs, 1); again() end
  if over() and db.docs and db.docs.index then
    db.docs.index = nil; db.docs.indexDropped = 'over size cap'; again()
  end
  -- docs: drop systems without Legacy names first (from the end), recording what was dropped
  if over() and db.docs and db.docs.systems then
    local i = #db.docs.systems
    while over() and i >= 1 do
      local s = db.docs.systems[i]
      if not s.legacy then
        db.docs.skipped = db.docs.skipped or {}
        table.insert(db.docs.skipped, { name = s.name, namespace = s.namespace, reason = 'size cap' })
        table.remove(db.docs.systems, i); again()
      end
      i = i - 1
    end
  end
  if over() and db.runs[1] then
    local r = db.runs[1]
    r.calls = { dropped = 'over size cap' }
    r.partA = { dropped = 'over size cap' }
    r.truncated = true; again()
  end
  if over() and db.docs and db.docs.systems then
    while over() and #db.docs.systems > 0 do
      local s = table.remove(db.docs.systems)
      db.docs.skipped = db.docs.skipped or {}
      table.insert(db.docs.skipped, { name = s.name, namespace = s.namespace, reason = 'size cap (Legacy)' })
      again()
    end
  end
  -- Q-T9: the discovery leftovers go before any Legacy data (their findings are in TP1_Report_Run1.md sections 9-12)
  if over() and type(db.strongSeen) == 'table' then
    local n = 0
    for _ in pairs(db.strongSeen) do n = n + 1 end
    db.strongSeen = {}; db.strongSeenDropped = n .. ' names, over size cap'; again()
  end
  if over() and type(db.undoc) == 'table' and db.undoc.namespaces then
    db.undoc = { dropped = 'over size cap', at = db.undoc.at, calledAt = db.undoc.calledAt }; again()
  end
  if over() and type(db.docs) == 'table' and (db.docs.args or db.docs.events or db.docs.systems) then
    db.docs = { dropped = 'over size cap', systemCount = db.docs.systemCount, at = db.docs.at }; again()
  end
  -- last resort, in this order: the steps' own criteria (zone sub-areas), then every criteria list, then the category list.
  -- The challenges, their step lists (done / not done) and the points always stay.
  if over() and db.legacy then
    for _, ch in ipairs(db.legacy.challenges or {}) do if ch.stepOf or not ch.legacy then ch.criteria = nil end end
    db.legacy.trimmed = 'criteria of steps dropped: over size cap'; again()
  end
  if over() and db.legacy then
    for _, ch in ipairs(db.legacy.challenges or {}) do ch.criteria = nil end
    db.legacy.categories = nil
    db.legacy.trimmed = 'criteria and category list dropped: over size cap'; again()
  end
  db.sizeEstimate = size
  return size
end

---------------------------------------------------------------------------
-- Output (limit 6: at most two lines per run)
---------------------------------------------------------------------------

function C.Say(msg, force)
  if not force and C.lines >= 2 then return false end
  if not force then C.lines = C.lines + 1 end
  local text = 'EmpireIntelCheck ' .. NS.VERSION .. ': ' .. msg
  local chat = NS.G('DEFAULT_CHAT_FRAME')
  if type(chat) == 'table' and type(chat.AddMessage) == 'function' then
    pcall(chat.AddMessage, chat, text)
  else
    local p = NS.G('print')
    if type(p) == 'function' then pcall(p, text) end
  end
  return true
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

function C.On(event, fn)
  C.handlers[event] = C.handlers[event] or {}
  table.insert(C.handlers[event], fn)
end

local function dispatch(_, event, ...)
  local list = C.handlers[event]
  if not list then return end
  for i = 1, #list do
    local ok, err = pcall(list[i], ...)
    if not ok and NS.Run then NS.Run.Unexpected('handler_error', event .. ': ' .. tostring(err)) end
  end
end

local function eventValid(name)
  local eu = NS.G('C_EventUtils')
  if type(eu) == 'table' and type(eu.IsEventValid) == 'function' then
    local ok, v = pcall(eu.IsEventValid, name)
    if ok then return v end
  end
  return nil
end

function C.EventValid(name) return eventValid(name) end

---------------------------------------------------------------------------
-- Scheduler: coroutines resumed under a per-frame budget, paused in combat (limit 3)
---------------------------------------------------------------------------

local frameStart, frameSteps = 0, 0

-- Called by jobs between work items. Yields when the frame budget is used up.
-- Never call it from inside a pcall (Lua 5.1 cannot yield across pcall).
function C.Checkpoint()
  local co, isMain = coroutine.running()
  if not co or isMain then return end
  frameSteps = frameSteps + 1
  local t = U.preciseMs()
  if t then
    if t - frameStart >= C.FRAME_BUDGET_MS then coroutine.yield() end
  elseif frameSteps >= C.FRAME_STEPS then
    coroutine.yield()
  end
end

function C.Enqueue(fn, name, onError)
  local co = coroutine.create(fn)
  table.insert(C.jobs, { co = co, name = name or 'job', onError = onError })
end

function C.After(seconds, fn)
  table.insert(C.timers, { at = U.now() + seconds, fn = fn })
end

function C.Busy() return #C.jobs > 0 end

local pollAcc = 0

local function onUpdate(_, elapsed)
  if C.IsOff() then return end
  elapsed = type(elapsed) == 'number' and elapsed or 0
  -- timers
  if #C.timers > 0 then
    local now = U.now()
    local due = {}
    for i = #C.timers, 1, -1 do
      if C.timers[i].at <= now then
        table.insert(due, C.timers[i]); table.remove(C.timers, i)
      end
    end
    for i = #due, 1, -1 do
      local ok, err = pcall(due[i].fn)
      if not ok and NS.Run then NS.Run.Unexpected('timer_error', tostring(err)) end
    end
  end
  -- pollers, about once per second, cheap reads only
  pollAcc = pollAcc + elapsed
  if pollAcc >= 1 then
    pollAcc = 0
    for i = 1, #C.pollers do pcall(C.pollers[i]) end
  end
  -- jobs (limit 3: paused in combat)
  if #C.jobs == 0 or U.inCombat() then return end
  frameStart = U.preciseMs() or 0
  frameSteps = 0
  C.stats.ticks = C.stats.ticks + 1
  local job = C.jobs[1]
  local ok, err = coroutine.resume(job.co)
  if frameSteps > C.stats.maxSteps then C.stats.maxSteps = frameSteps end
  if not ok then
    table.remove(C.jobs, 1)
    if NS.Run then NS.Run.Unexpected('job_error', job.name .. ': ' .. tostring(err)) end
    if job.onError then pcall(job.onError, err) end
  elseif coroutine.status(job.co) == 'dead' then
    table.remove(C.jobs, 1)
  end
end

---------------------------------------------------------------------------
-- Boot: one unnamed frame, allow-listed events only
---------------------------------------------------------------------------

function C.Boot()
  local CreateFrame = NS.G('CreateFrame')
  if type(CreateFrame) ~= 'function' then return false end
  local f = CreateFrame('Frame')
  C.frame = f
  f:SetScript('OnEvent', dispatch)
  for _, ev in ipairs(C.EVENTS) do
    if eventValid(ev) ~= false then
      local ok = pcall(f.RegisterEvent, f, ev)
      C.registered[ev] = ok and true or false
    else
      C.registered[ev] = 'invalid'
    end
  end
  f:SetScript('OnUpdate', onUpdate)
  return true
end

---------------------------------------------------------------------------
-- Slash command /eicheck (limit 5: off switch)
---------------------------------------------------------------------------

function C.Slash(msg)
  msg = string.lower(tostring(msg or ''))
  msg = string.gsub(msg, '^%s+', '')
  msg = string.gsub(msg, '%s+$', '')
  local db = C.DB()
  if msg == 'off' then
    db.off = true
    C.jobs = {}
    C.timers = {}
    if NS.Run then NS.Run.Reset() end
    C.Say('OFF. Nothing runs now or on later logins. /eicheck on to re-enable.', true)
  elseif msg == 'on' then
    db.off = nil
    C.Say('ON. A check runs in ' .. C.LOGIN_DELAY .. ' s.', true)
    if NS.Run then NS.Run.Enable() end
  elseif C.IsOff() then
    C.Say('is OFF. /eicheck on to re-enable.', true)
  elseif msg == 'run' then
    if NS.Run then NS.Run.Schedule('manual', 0, true) end
    C.Say('run queued.', true)
  elseif msg == 'pane' then
    if NS.Run then NS.Run.PaneSeen('user') end
    C.Say('noted: Legacy pane open. Rerun queued.', true)
  elseif msg == 'undoc' then
    if NS.Discover then C.Say('undoc: ' .. tostring(NS.Discover.CallUndocumented()), true) end
  elseif msg == 'legacy' then
    if NS.Legacy then C.Say('legacy: ' .. tostring(NS.Legacy.Command()), true) end
  elseif msg == 'ui' then
    if NS.UI then
      local guid = NS.Run and NS.Run.state and NS.Run.state.guid
      C.Say(NS.UI.Command(guid), true)
    end
  elseif msg == 'docs' then
    if NS.Discover then
      local r = NS.Discover.LoadDocs()
      C.Say('docs: ' .. tostring(r), true)
    end
  else
    local last = db.runs[#db.runs]
    C.Say('status: ' .. (last and (tostring(last.verdict) .. ' (run ' .. tostring(last.id) .. ', ' .. tostring(last.reason) .. ')') or 'no run yet')
      .. '. Commands: off, on, run, pane, docs, undoc, legacy, ui', true)
  end
end

function C.InstallSlash()
  local env = NS.env
  local list = env.SlashCmdList
  if type(list) ~= 'table' then return false end
  env.SLASH_EMPIREINTELCHECK1 = '/eicheck'
  list.EMPIREINTELCHECK = function(msg)
    local ok, err = pcall(C.Slash, msg)
    if not ok then C.Say('command failed: ' .. tostring(err), true) end
  end
  return true
end
