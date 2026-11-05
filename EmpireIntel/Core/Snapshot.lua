local ADDON, EI = ...
-- EmpireIntel / Core / Snapshot.lua                                      (Phase 2, increment P2-1)
--
-- PURPOSE
--   Passive snapshot of the logged-in character into EmpireIntelDB.roster[GUID] (saved-data format 1).
--
-- WHEN (no 0.5 s tick: events plus one 5-minute timer, user Q-P2-1)
--   * 2 s after login              * on level-up (P_LEVEL)        * on a profession change (P_PROFS)
--   * every 5 minutes              * at logout, guarded: unit data at logout can be wrong (EI-E-08), so the record
--                                    is updated only when the reading is valid and not lower than the last one
--
-- RULES
--   * GUID is the only key (D-004); a character without a GUID is not recorded.
--   * A name equal to "Unknown" never overwrites a known name (Altoholic report, R-04).
--   * rest = nil when the client returns nothing: unknown is never stored as 0.
--   * A value the client could not read keeps the previous one; professions are only replaced by a good read.
--   * /ei off stops all snapshots now and on later logins.

EI = EI or {}
local P = EI.Platform
assert(P and EI.Store, 'Platform and Store must be loaded before Core/Snapshot.lua')

local Snap = {}
EI.Snapshot = Snap

Snap.INTERVAL = 300
Snap.FIRST_DELAY = 2

local cancelTimer = nil
local started = false
local lastLevel = nil
Snap.count = 0

local function db() return EI.Store.Get() end

function Snap.IsOff()
  local d = db()
  return type(d) == 'table' and d.off == true
end

local function buildString()
  local r = P.Call('GetBuildInfo')
  if r and type(r[1]) == 'string' and type(r[2]) == 'string' then return r[1] .. '/' .. r[2] end
  return nil
end

--- Writes the snapshot. reason: 'login' | 'level' | 'profs' | 'timer' | 'logout' | 'command'.
-- Returns 'written', 'kept' (logout values rejected), or nil plus a reason.
function Snap.Write(reason)
  if Snap.IsOff() then return nil, 'off' end
  if not EI.Store.IsWritable() then return nil, 'store not writable' end
  local player = P.Player()
  if not player or not player.guid then return nil, 'no GUID yet' end
  local prog = P.Unit.Progress()
  local roster = EI.Store.Section('roster')
  local rec = roster[player.guid]
  local t = P.Now()

  if reason == 'logout' then
    local valid = type(prog.level) == 'number' and prog.level >= 1 and type(prog.xpMax) == 'number' and prog.xpMax > 0
      and (lastLevel == nil or prog.level >= lastLevel)
    if not valid then
      if rec then rec.lastSeen = t end
      return 'kept'
    end
  end

  rec = rec or {}
  if type(player.name) == 'string' then
    if player.name ~= 'Unknown' or rec.name == nil then rec.name = player.name end
  end
  if player.realm then rec.realm = player.realm end
  if player.class then rec.class = player.class end
  if prog.level ~= nil then rec.level = prog.level end
  if prog.xp ~= nil then rec.xp = prog.xp end
  if prog.xpMax ~= nil then rec.xpMax = prog.xpMax end
  rec.rest = prog.rest                       -- nil = the client reported none (never stored as 0)
  if prog.resting ~= nil then rec.resting = prog.resting end
  rec.restAt = t
  local profs = P.Unit.ProfessionList()
  if profs then rec.professions = profs end
  rec.lastSeen = t
  rec.src = 'self'
  roster[player.guid] = rec
  if type(rec.level) == 'number' then lastLevel = rec.level end
  local meta = EI.Store.Section('meta')
  local build = buildString()
  if build then meta.build = build end
  Snap.count = Snap.count + 1
  Snap.lastReason = reason
  return 'written'
end

local function safeWrite(reason)
  local ok, res, why = pcall(Snap.Write, reason)
  if not ok then P.Diag('error', 'Snapshot', tostring(res)) end
  return res, why
end

function Snap.Start()
  if started or Snap.IsOff() then return false end
  started = true
  P.After(Snap.FIRST_DELAY, function() safeWrite('login') end)
  cancelTimer = P.Every(Snap.INTERVAL, function() safeWrite('timer') end)
  return true
end

function Snap.Stop()
  if cancelTimer then cancelTimer() end
  cancelTimer = nil
  started = false
end

P.On('P_LEVEL', function() if started then safeWrite('level') end end)
P.On('P_PROFS', function() if started then safeWrite('profs') end end)
P.On('P_LOGOUT', function() if started then safeWrite('logout') end end)

--- Test helper.
function Snap.Reset()
  Snap.Stop()
  lastLevel = nil
  Snap.count = 0
end
