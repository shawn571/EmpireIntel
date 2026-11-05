local ADDON, EI = ...
-- EmpireIntel / Store / Store.lua
--
-- PURPOSE
--   The persistence layer: opens EmpireIntelDB (through Platform.SavedVars), brings it to the current schema,
--   and gives the rest of the addon safe access to its sections.
--     Store.Open() -> status    Store.Get()    Store.Section(name)    Store.Status() / IsOpen() / IsWritable()
--
-- OPEN OUTCOMES (status.state)
--   created   nothing was saved: a fresh schema-1 database was built
--   ok        schema is current; sections validated (and repaired if needed)
--   migrated  an older database was upgraded (copy, then commit)
--   readonly  the database is NEWER than this addon understands: left untouched, a private copy is used
--   degraded  migration or validation failed: left untouched, an in-memory database is used
--
-- PORTED from GoldIntel GoldIntel/Store/Store.lua at commit a21e071 (read-only; GoldIntel unchanged).
-- Changes: no `compat` guarantee (no Probe in EmpireIntel); no per-character table (format 1 is account-wide).

EI = EI or {}
local P = EI.Platform
assert(P, 'Platform must be loaded before Store/Store.lua')

local Store = {}
EI.Store = Store

local status = nil      -- set by Open
local root = nil        -- working root (the live table, or a private copy)

local function fire(name, payload)
  if EI.Bus then EI.Bus.Fire(name, payload) end
end

---------------------------------------------------------------------------
-- Size estimation (cheap, bounded)
---------------------------------------------------------------------------

--- Approximate serialized size in bytes. Stops after nodeLimit nodes (default 200000) and
-- reports truncated = true. Cycle-safe.
function Store.EstimateBytes(value, nodeLimit)
  nodeLimit = nodeLimit or 200000
  local bytes, nodes = 0, 0
  local seen = {}
  local stack = { value }
  while #stack > 0 do
    local v = table.remove(stack)
    nodes = nodes + 1
    if nodes > nodeLimit then return bytes, true end
    local t = type(v)
    if t == 'string' then
      bytes = bytes + #v + 2
    elseif t == 'number' then
      bytes = bytes + 8
    elseif t == 'boolean' then
      bytes = bytes + 5
    elseif t == 'table' then
      if not seen[v] then
        seen[v] = true
        bytes = bytes + 4
        for k, x in pairs(v) do
          stack[#stack + 1] = k
          stack[#stack + 1] = x
        end
      end
    end
  end
  return bytes, false
end

---------------------------------------------------------------------------
-- Open
---------------------------------------------------------------------------

local function newStatus(target)
  return { state = 'ok', schema = 0, target = target, writable = true, repaired = {}, added = {},
           migrated = nil, reason = nil, svStatus = nil }
end

-- meta follows saved-data format 1 exactly: { created, opens, version, build } (build is set by Core/Snapshot).
local function updateMeta(db, st)
  local t = P.Now()
  local meta = db.meta
  if type(meta) ~= 'table' then meta = {}; db.meta = meta end
  if not meta.created then meta.created = t end
  meta.opens = (tonumber(meta.opens) or 0) + 1
  meta.version = P.VERSION
end

local function degrade(live, st, reason)
  st.state = 'degraded'
  st.writable = false
  st.reason = reason
  -- A private in-memory database; the live table is not touched.
  local working = EI.Migrations.Sections()
  working.schema = st.target
  root = working
  P.Diag('error', 'Store', 'database degraded: ' .. tostring(reason))
  P.Print('saved data could not be upgraded (' .. tostring(reason) .. '). EmpireIntel keeps your file untouched and runs without saving.')
  fire('STORE_DEGRADED', { reason = tostring(reason) })
end

local function migrate(live, from, target, st)
  local Util = P.Util
  local staged = Util.deepCopy(live)
  local report = EI.Migrations.Run(staged, from, target)
  if not report.ok then return false, 'migration failed' .. (report.failedAt and (' at schema ' .. report.failedAt) or '') .. ': ' .. tostring(report.err) end
  local shape = EI.Migrations.EnsureShape(staged)
  for _, name in ipairs(shape.added) do st.added[#st.added + 1] = name end
  for _, name in ipairs(shape.repaired) do st.repaired[#st.repaired + 1] = name end
  local problems = EI.Migrations.Check(staged)
  if #problems.missing > 0 or #problems.wrongType > 0 then return false, 'database invalid after migration' end
  -- Commit: replace the live table's contents with the staged copy.
  for key in pairs(live) do live[key] = nil end
  for key, value in pairs(staged) do live[key] = value end
  st.migrated = { from = from, to = target, applied = report.applied }
  return true
end

--- Opens the database. Idempotent: later calls return the same status.
function Store.Open()
  if status then return Store.Status() end
  local Mig = EI.Migrations
  local target = Mig.Latest()
  local st = newStatus(target)
  status = st

  local sv = P.SavedVars
  local live, svStatus
  if sv then live, svStatus = sv.Account() end
  st.svStatus = svStatus

  if type(live) ~= 'table' then
    degrade(nil, st, 'SavedVariables are not available')
  elseif svStatus ~= 'existing' or next(live) == nil then
    -- nothing was saved: build a fresh database in place
    local fresh = Mig.Sections()
    for key, value in pairs(fresh) do live[key] = value end
    live.schema = target
    st.state = 'created'
    st.schema = target
    root = live
  else
    local schema = live.schema
    local from = type(schema) == 'number' and schema or 0
    if type(schema) == 'number' and schema > target then
      st.state = 'readonly'
      st.writable = false
      st.schema = schema
      st.reason = 'saved data is schema ' .. schema .. ', newer than this addon (' .. target .. '); left untouched'
      root = P.Util.deepCopy(live)
      P.Diag('warn', 'Store', st.reason)
    elseif from < target then
      local ok, err = migrate(live, from, target, st)
      if ok then
        st.state = 'migrated'
        st.schema = target
        root = live
      else
        st.schema = from
        degrade(live, st, err)
      end
    else
      local shape = Mig.EnsureShape(live)
      for _, name in ipairs(shape.added) do st.added[#st.added + 1] = name end
      for _, name in ipairs(shape.repaired) do st.repaired[#st.repaired + 1] = name end
      if #shape.repaired > 0 then
        P.Diag('warn', 'Store', 'repaired wrong-typed sections: ' .. table.concat(shape.repaired, ', '))
      end
      st.schema = target
      root = live
    end
  end

  if st.writable and root then updateMeta(root, st) end
  fire('STORE_OPENED', { state = st.state, schema = st.schema, writable = st.writable })
  if st.migrated then fire('STORE_MIGRATED', { from = st.migrated.from, to = st.migrated.to }) end
  return Store.Status()
end

---------------------------------------------------------------------------
-- Access
---------------------------------------------------------------------------

function Store.IsOpen() return status ~= nil end

function Store.IsWritable()
  return status ~= nil and status.writable == true
end

--- Copy of the status table.
function Store.Status()
  if not status then return nil end
  local out = P.Util.shallowCopy(status)
  out.repaired = P.Util.shallowCopy(status.repaired)
  out.added = P.Util.shallowCopy(status.added)
  return out
end

function Store.Get()
  if not status then Store.Open() end
  return root
end

--- The named section; created when missing. Returns nil when the name is invalid.
function Store.Section(name)
  if type(name) ~= 'string' or name == '' or name == 'schema' then return nil end
  local db = Store.Get()
  if type(db[name]) ~= 'table' then db[name] = {} end
  return db[name]
end

--- Marks a checkpoint and returns the approximate size. Saving to disk still happens at
-- logout or /reload (addons cannot force it).
function Store.Checkpoint(opts)
  local db = Store.Get()
  local bytes, truncated = Store.EstimateBytes(db)
  return {
    bytes = bytes, truncated = truncated, writable = status.writable,
    note = 'The client writes saved data at logout or /reload.',
  }
end

--- Test helper: forget the open database (does not touch saved variables).
function Store.Reset()
  status, root = nil, nil
end

if EI.Core then EI.Core.Service('store', Store) end
