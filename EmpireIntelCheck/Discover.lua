local ADDON, NS = ...
-- EmpireIntelCheck / Discover.lua
-- Part B: discover the Legacy API in the live client WITHOUT assuming names (Architecture.md section 9).
--   L-1 namespaces and globals   L-2 Enum and constants   L-3 addons and frames
--   L-4 event names (validity only, never registered)   L-5 official API docs (only on /eicheck docs)
--   D-1 zero-argument calls of discovered read-style names under runtime limits 1 and 7.
-- All loops run inside a scheduler coroutine and call Checkpoint() between items (limit 3).

local U = NS.U
local D = {}
NS.Discover = D

D.MAX_CALLS = 300
D.MAX_LIST = 300
D.DOC_ADDONS = { 'Blizzard_APIDocumentation', 'Blizzard_APIDocumentationGenerated' }   -- candidates; presence is checked, never assumed

local checkpoint = function() NS.Core.Checkpoint() end

local function push(list, item, info)
  if #list >= D.MAX_LIST then
    if info then info.truncated = true end
    return false
  end
  table.insert(list, item)
  return true
end

local function frameInfo(v)
  local ok, isFrame = pcall(function() return type(v.GetObjectType) == 'function' end)
  if not ok or not isFrame then return nil end
  local okT, ot = pcall(v.GetObjectType, v)
  local okS, shown = pcall(v.IsShown, v)
  local okV, visible = pcall(v.IsVisible, v)
  return { objectType = okT and U.dump(ot) or 'error', shown = okS and U.dump(shown) or 'error',
    visible = okV and U.dump(visible) or 'error' }
end

---------------------------------------------------------------------------
-- L-1 and L-2: one resumable walk of the global table
---------------------------------------------------------------------------
-- Returns a discovery record:
--  namespaces = { all = {names}, count }, matchedNamespaces = { [ns] = { term, members = {[name]=type} } },
--  candidates = { 'C_X.Fn' or 'GlobalFn' -> { term, unrelated } }, globals = { functions, tables, frames, strings, constants },
--  enums = { [name] = { term, members } }
function D.Walk(rec)
  local env = NS.env
  rec.namespaces = { all = {}, count = 0 }
  rec.matchedNamespaces = {}
  rec.candidates = {}
  rec.globals = { functions = {}, tables = {}, frames = {}, strings = {}, constants = {} }
  rec.enums = {}
  rec.info = { truncated = false, restarts = 0, visited = 0 }
  local key = nil
  local restarts = 0
  while true do
    local ok, k, v = pcall(next, env, key)
    if not ok then
      -- the key vanished between frames; restart the walk (bounded)
      restarts = restarts + 1
      rec.info.restarts = restarts
      if restarts > 3 then rec.info.aborted = true; NS.Run.Unexpected('walk_aborted', 'global table changed too often'); break end
      key = nil
      k = nil
    else
      if k == nil then break end
      key = k
      rec.info.visited = rec.info.visited + 1
      if type(k) == 'string' then
        pcall(D.Visit, rec, k, v)
      end
    end
    checkpoint()
  end
  table.sort(rec.namespaces.all)
  D.WalkEnum(rec)
  return rec
end

function D.VisitEnum(rec, ek, ev)
  if type(ek) ~= 'string' or type(ev) ~= 'table' then return end
  local eTerm = U.term(ek)
  local members, hit = {}, false
  for mk, mv in pairs(ev) do
    if type(mk) == 'string' and (eTerm or U.term(mk)) then
      members[mk] = U.dump(mv); hit = true
    end
  end
  if hit then
    -- an enum counts only when its own name points at Legacy: retail enums such as NamePlateStyle or
    -- RespecType have a member literally called 'Legacy' (launch-build run 2, defect 8)
    local strong = U.strong(ek)
    rec.enums[ek] = { term = eTerm or 'member', members = members, unrelated = U.unrelated(ek), strong = strong or nil }
  end
end

function D.WalkEnum(rec)
  local enum = rec._enum
  rec._enum = nil
  if type(enum) ~= 'table' then return end
  local key = nil
  while true do
    local ok, k, v = pcall(next, enum, key)
    if not ok or k == nil then break end
    key = k
    pcall(D.VisitEnum, rec, k, v)
    checkpoint()
  end
end

function D.Visit(rec, k, v)
  local tv = type(v)
  if string.sub(k, 1, 2) == 'C_' and tv == 'table' then
    rec.namespaces.count = rec.namespaces.count + 1
    table.insert(rec.namespaces.all, k)
    local nsTerm = U.term(k)
    local members, nm, related = {}, 0, 0
    for mk, mv in pairs(v) do
      if type(mk) == 'string' then
        local mTerm = U.term(mk)
        if nsTerm or mTerm then
          nm = nm + 1
          if nm <= 200 then members[mk] = type(mv) end
          local full = k .. '.' .. mk
          local unrel = U.unrelated(full) or U.unrelated(k)
          if not unrel then related = related + 1 end
          if type(mv) == 'function' then
            rec.candidates[full] = { term = nsTerm or mTerm, unrelated = unrel, strong = U.strong(full) or nil, layer = 'data' }
          end
        end
      end
    end
    if nm > 0 then
      -- a namespace whose only matches are known unrelated names does not count toward the verdict
      local strongNs = false
      for mk in pairs(members) do if U.strong(k .. '.' .. mk) then strongNs = true end end
      rec.matchedNamespaces[k] = { term = nsTerm, members = members, unrelated = U.unrelated(k) or related == 0,
        strong = strongNs or nil }
    end
    return
  end
  if k == 'Enum' and tv == 'table' then
    rec._enum = v          -- walked separately, resumable (D.WalkEnum)
    return
  end
  local term = U.term(k)
  if not term then return end
  local unrelated = U.unrelated(k)
  local strong = U.strong(k) or nil
  if tv == 'function' then
    push(rec.globals.functions, { name = k, term = term, unrelated = unrelated, strong = strong }, rec.info)
    -- a global read-style function may be data; anything else (Toggle..., Show...) is UI
    rec.candidates[k] = { term = term, unrelated = unrelated, strong = strong,
      layer = U.isReadName(k) and 'data' or 'ui' }
  elseif tv == 'table' then
    local fi = frameInfo(v)
    if fi then
      fi.name = k; fi.term = term; fi.unrelated = unrelated; fi.strong = strong
      push(rec.globals.frames, fi, rec.info)
    else
      local keys, n = {}, 0
      for tk, tval in pairs(v) do
        if n >= 2000 then rec.info.truncated = true; break end
        if type(tk) == 'string' then
          n = n + 1
          if n <= 50 then keys[tk] = type(tval) end
          if type(tval) == 'function' then
            rec.candidates[k .. '.' .. tk] = { term = term, unrelated = unrelated, method = true, strong = strong, layer = 'ui' }
          end
        end
      end
      push(rec.globals.tables, { name = k, term = term, unrelated = unrelated, strong = strong, keys = keys, count = n }, rec.info)
    end
  elseif tv == 'string' then
    push(rec.globals.strings, { name = k, value = U.ascii(v) }, rec.info)
  elseif tv == 'number' or tv == 'boolean' then
    push(rec.globals.constants, { name = k, value = v, unrelated = unrelated }, rec.info)
  end
end

---------------------------------------------------------------------------
-- L-3 addons (user addons by index; Blizzard ones arrive via ADDON_LOADED, see Run.lua)
---------------------------------------------------------------------------
function D.Addons(rec)
  local ca = NS.G('C_AddOns')
  rec.addons = { list = {}, docs = {} }
  if type(ca) ~= 'table' then rec.addons.code = 'not_found'; return end
  local okN, n = pcall(ca.GetNumAddOns)
  rec.addons.count = okN and n or 'error'
  if okN and type(n) == 'number' then
    for i = 1, math.min(n, 150) do
      local r = U.pack(pcall(ca.GetAddOnInfo, i))
      if r[1] then
        local okL, loaded = pcall(ca.IsAddOnLoaded, i)
        local okD, lod = pcall(ca.IsAddOnLoadOnDemand, i)
        table.insert(rec.addons.list, { name = U.dump(r[2]), loadable = U.dump(r[5]), reason = U.dump(r[6]),
          loaded = okL and U.dump(loaded) or nil, lod = okD and U.dump(lod) or nil })
      end
      checkpoint()
    end
  end
  for _, name in ipairs(D.DOC_ADDONS) do
    local r = U.pack(pcall(ca.GetAddOnInfo, name))
    local exists = r[1] and r[2] ~= nil and r[6] ~= 'MISSING'
    rec.addons.docs[name] = exists and true or false
    if exists then rec.addons.docsAvailable = true end
  end
end

---------------------------------------------------------------------------
-- L-5 official API documentation (user command only; it loads a Blizzard addon)
---------------------------------------------------------------------------
-- A docs system matches when its name, namespace, a function, an argument or return name,
-- an event or payload name, or a table or field name carries a term (defect 7 of run 1).
local function listHit(list)
  for _, a in ipairs(type(list) == 'table' and list or {}) do
    if type(a) == 'table' and (U.term(a.Name) or U.term(a.InnerType)) then return true end
  end
  return false
end

local function docMatches(sys)
  if U.term(sys.Name) or U.term(sys.Namespace) then return true end
  for _, f in ipairs(type(sys.Functions) == 'table' and sys.Functions or {}) do
    if U.term(f.Name) or listHit(f.Arguments) or listHit(f.Returns) then return true end
  end
  for _, e in ipairs(type(sys.Events) == 'table' and sys.Events or {}) do
    if U.term(e.Name) or U.term(e.LiteralName) or listHit(e.Payload) then return true end
  end
  for _, t in ipairs(type(sys.Tables) == 'table' and sys.Tables or {}) do
    if U.term(t.Name) or listHit(t.Fields) then return true end
  end
  return false
end

local function docArgs(list, max)
  local out, required = {}, 0
  for _, a in ipairs(type(list) == 'table' and list or {}) do
    if #out < (max or 12) then
      table.insert(out, { name = U.dump(a.Name), type = U.dump(a.Type), nilable = U.dump(a.Nilable) })
    end
    if a.Nilable ~= true and a.Default == nil then required = required + 1 end
  end
  return out, required
end

-- Does any name in a docs system point at the Forever Legacy system (U.strong)?
-- Defect 10: retail enums document a member literally named 'Legacy' (TurnStrafeStyle, VoiceProviderID);
-- such member names do not make a system a Legacy system.
local ENUM_MEMBER = { Legacy = true, IsLegacy = true, LegacyFriend = true, LegacyLetterbox = true, LegacyUnsupported = true }
local function listStrong(list)
  for _, a in ipairs(type(list) == 'table' and list or {}) do
    if type(a) == 'table' and not ENUM_MEMBER[a.Name] and (U.strong(a.Name) or U.strong(a.InnerType)) then return true end
  end
  return false
end

local function docStrong(sys)
  if U.strong(sys.Name) or U.strong(sys.Namespace) then return true end
  for _, f in ipairs(type(sys.Functions) == 'table' and sys.Functions or {}) do
    if U.strong(f.Name) or listStrong(f.Arguments) or listStrong(f.Returns) then return true end
  end
  for _, e in ipairs(type(sys.Events) == 'table' and sys.Events or {}) do
    if U.strong(e.Name) or U.strong(e.LiteralName) or listStrong(e.Payload) then return true end
  end
  for _, t in ipairs(type(sys.Tables) == 'table' and sys.Tables or {}) do
    if U.strong(t.Name) or listStrong(t.Fields) then return true end
  end
  return false
end

-- Size limits for the saved docs (run 3 lost the docs to the size cap). Same fields as before:
-- Legacy systems keep signatures and fields within these caps; other matches keep names only.
D.DOCS_BUDGET = 120 * 1024
D.CAP = { functions = 40, args = 6, tables = 20, fields = 10, events = 20 }
D.CAP_REDUCED = { functions = 40, args = 3, tables = 10, fields = 5, events = 20 }
D.SYSTEM_DETAIL_MAX = 64 * 1024   -- a Legacy system bigger than this in full is kept with names only
D.ARGS_MAX = 600                  -- documented argument counts kept (Legacy systems first)

-- Runs inside a scheduler job (limit 3): one system per Checkpoint.
function D.LoadDocsJob()
  local ca = NS.G('C_AddOns')
  if type(ca) ~= 'table' or type(ca.LoadAddOn) ~= 'function' then return 'not_found (no C_AddOns.LoadAddOn)' end
  local tried = {}
  for _, name in ipairs(D.DOC_ADDONS) do
    local r = U.pack(pcall(ca.LoadAddOn, name))
    tried[name] = r[1] and U.dump(r[2]) or ('error ' .. U.ascii(tostring(r[2])))
  end
  local api = NS.G('APIDocumentation')
  local db = NS.Core.DB()
  if type(api) ~= 'table' or type(api.systems) ~= 'table' then
    db.docs = { at = U.wall(), tried = tried, result = 'not_found (no APIDocumentation table after loading)' }
    return 'not found'
  end
  local docs = { at = U.wall(), tried = tried, systems = {}, args = {}, events = {}, systemCount = #api.systems, index = {},
    skipped = {}, strongSystems = 0, argsCount = 0 }
  local strongList, weakList = {}, {}
  for _, sys in ipairs(api.systems) do
    -- index of every system, so a neutrally named Legacy system can still be spotted by eye
    if #docs.index < 450 then
      table.insert(docs.index, { name = U.dump(sys.Name), namespace = U.dump(sys.Namespace),
        functions = type(sys.Functions) == 'table' and #sys.Functions or 0,
        events = type(sys.Events) == 'table' and #sys.Events or 0,
        tables = type(sys.Tables) == 'table' and #sys.Tables or 0 })
    end
    local ok, hit = pcall(docMatches, sys)
    if ok and hit and not (type(sys.Namespace) == 'string' and U.unrelated(sys.Namespace)) then
      local okS, strong = pcall(docStrong, sys)
      if okS and strong then table.insert(strongList, sys) else table.insert(weakList, sys) end
    end
    checkpoint()
  end
  local C = D.CAP
  local function build(sys, full, caps)
    local C = caps or D.CAP
    local s = { name = U.dump(sys.Name), namespace = U.dump(sys.Namespace), functions = {}, events = {}, tables = {},
      legacy = full or nil }
    local fns = type(sys.Functions) == 'table' and sys.Functions or {}
    for _, f in ipairs(fns) do
      local args, required = docArgs(f.Arguments, C.args)
      local fullName = (type(sys.Namespace) == 'string' and sys.Namespace ~= '') and (sys.Namespace .. '.' .. tostring(f.Name)) or tostring(f.Name)
      if (full or required > 0) and docs.argsCount < D.ARGS_MAX then
        docs.args[fullName] = required
        docs.argsCount = docs.argsCount + 1
      end
      if #s.functions < C.functions then
        if full then
          table.insert(s.functions, { name = U.dump(f.Name), args = args, returns = (docArgs(f.Returns, C.args)) })
        else
          table.insert(s.functions, { name = U.dump(f.Name) })
        end
      end
    end
    if #fns > C.functions then s.functionsTotal = #fns end
    for _, e in ipairs(type(sys.Events) == 'table' and sys.Events or {}) do
      local lit = e.LiteralName
      if type(lit) == 'string' then docs.events[lit] = NS.Core.EventValid(lit) end
      if #s.events < C.events then
        table.insert(s.events, { name = U.dump(e.Name), literal = U.dump(lit),
          payload = full and (docArgs(e.Payload, C.args)) or {},
          valid = type(lit) == 'string' and U.dump(NS.Core.EventValid(lit)) or nil })
      end
    end
    for _, t in ipairs(type(sys.Tables) == 'table' and sys.Tables or {}) do
      if #s.tables < C.tables then
        table.insert(s.tables, { name = U.dump(t.Name), type = U.dump(t.Type), fields = full and (docArgs(t.Fields, C.fields)) or {} })
      end
    end
    return s
  end
  local used = 0
  local function add(sys, full)
    local s = build(sys, full)
    local cost = U.size(s)
    if full and (cost > D.SYSTEM_DETAIL_MAX or used + cost > D.DOCS_BUDGET) then
      -- too big in full: first fewer arguments and fields, then names only, rather than lose it
      s = build(sys, true, D.CAP_REDUCED)
      s.detailReduced = 'size'
      cost = U.size(s)
      if cost > D.SYSTEM_DETAIL_MAX or used + cost > D.DOCS_BUDGET then
        s = build(sys, false)
        s.legacy = true
        s.detailDropped = 'size'
        cost = U.size(s)
      end
    end
    if used + cost > D.DOCS_BUDGET then
      table.insert(docs.skipped, { name = U.dump(sys.Name), namespace = U.dump(sys.Namespace), reason = 'size budget',
        legacy = full or nil })
      return
    end
    used = used + cost
    table.insert(docs.systems, s)
    if full then docs.strongSystems = docs.strongSystems + 1 end
  end
  for _, sys in ipairs(strongList) do add(sys, true); checkpoint() end
  for _, sys in ipairs(weakList) do add(sys, false); checkpoint() end
  docs.bytes = used
  db.docs = docs
  NS.Core.Trim()
  NS.Run.Schedule('docs', 1, true)
  return 'saved ' .. #docs.systems .. ' matching systems of ' .. docs.systemCount .. ' (' .. docs.strongSystems
    .. ' with Legacy names' .. (#docs.skipped > 0 and (', ' .. #docs.skipped .. ' skipped for size') or '') .. '); rerun queued'
end

function D.LoadDocs()
  if D.docsQueued then return 'already loading' end
  D.docsQueued = true
  NS.Core.Enqueue(function()
    local result = D.LoadDocsJob()
    D.docsQueued = false
    NS.Core.Say('docs: ' .. tostring(result), true)
  end, 'docs', function() D.docsQueued = false end)
  return 'loading; results in a few seconds'
end

---------------------------------------------------------------------------
-- D-1 guarded calls (runtime limits 1 and 7)
---------------------------------------------------------------------------
D.blockedLog = {}          -- filled by Run.lua from ADDON_ACTION_FORBIDDEN / _BLOCKED for this addon
D.current = nil
D.erroredThisSession = {}

local function blockedText(err)
  local low = string.lower(tostring(err))
  return string.find(low, 'protected', 1, true) or string.find(low, 'forbidden', 1, true)
    or string.find(low, 'blocked', 1, true) or string.find(low, 'restricted', 1, true)
end

-- Classify one name. Returns a result table { code, values?, detail? }.
function D.Probe(full, cand, docsArgs, budget)
  local fnName = string.match(full, '([^%.]+)$')
  if cand and cand.unrelated then return { code = 'skipped_unrelated' } end
  if U.denied(full) then return { code = 'skipped_denylist', detail = U.denied(full) } end
  if not U.isReadName(fnName) then return nil end      -- not a read-style name: listed in discovery only
  if docsArgs and (docsArgs[full] or 0) > 0 then return { code = 'skipped_args', detail = docsArgs[full] } end
  if D.erroredThisSession[full] then return { code = 'skipped_errored_before' } end
  if budget.calls >= D.MAX_CALLS then return { code = 'skipped_cap' } end
  local fn = U.path(full)
  if fn == nil then return { code = 'not_found' } end
  if type(fn) ~= 'function' then return { code = 'not_function' } end
  local db = NS.Core.DB()
  if db.neverCall[full] then return { code = 'skipped_crash_guard', detail = db.neverCall[full] } end
  budget.calls = budget.calls + 1
  local before = #D.blockedLog
  D.current = full
  -- crash guard (user, Q-T3): the name is in saved data while the call runs and is cleared right after.
  -- Found at the next login (disconnect, /reload or error mid-call) -> never called again.
  db.inFlight = { name = full, at = U.wall() }
  local r = U.pack(pcall(fn))
  db.inFlight = nil
  D.current = nil
  if #D.blockedLog > before then return { code = 'blocked', detail = D.blockedLog[#D.blockedLog].fn } end
  if not r[1] then
    D.erroredThisSession[full] = true
    if blockedText(r[2]) then return { code = 'blocked', detail = U.ascii(tostring(r[2])) } end
    return { code = 'error', detail = U.ascii(tostring(r[2])) }
  end
  local any = false
  for i = 2, r.n do if r[i] ~= nil then any = true end end
  if r.n <= 1 or not any then return { code = 'returned_nothing' } end
  local values, info = {}, nil
  for i = 2, r.n do
    local v
    v, info = U.dump(r[i], info)
    values[i - 1] = v
  end
  budget.bytes = budget.bytes + (info and info.cost or 0)
  local res = { code = 'ok', values = values, n = r.n - 1, truncated = info and info.truncated or nil }
  if info and (info.secret > 0 or info.opaque > 0) then
    res.code = 'unreadable'
    res.detail = 'secret ' .. info.secret .. ', opaque ' .. info.opaque
  end
  return res
end

-- Meaningful data: something other than nil, false, 0, '' or an empty table.
function D.Meaningful(res)
  if not res or res.code ~= 'ok' or type(res.values) ~= 'table' then return false end
  for i = 1, res.n or 0 do
    local v = res.values[i]
    if type(v) == 'table' then
      if next(v) ~= nil then return true end
    elseif v ~= nil and v ~= false and v ~= 0 and v ~= '' then
      return true
    end
  end
  return false
end

function D.CallAll(rec, run)
  local db = NS.Core.DB()
  local docsArgs = db.docs and db.docs.args or nil
  -- names the official docs list (L-5) but the walk did not find: probed so they report not_found
  if db.docs and type(db.docs.args) == 'table' then
    for full in pairs(db.docs.args) do
      if not rec.candidates[full] and U.term(full) then
        rec.candidates[full] = { term = U.term(full), fromDocs = true, unrelated = U.unrelated(full), strong = U.strong(full) or nil, layer = 'data' }
      end
    end
  end
  local names = {}
  for full in pairs(rec.candidates) do table.insert(names, full) end
  table.sort(names)
  local results, counts = {}, {}
  local budget = { calls = 0, bytes = 0 }
  for _, full in ipairs(names) do
    if U.inCombat() then
      -- the scheduler pauses in combat; this guard covers a call that starts the same frame combat begins
      results[full] = { code = 'skipped_combat' }
    else
      local ok, res = pcall(D.Probe, full, rec.candidates[full], docsArgs, budget)
      if not ok then res = { code = 'error', detail = U.ascii(tostring(res)) } end
      if res then
        if budget.bytes > 96 * 1024 and res.values then res.values = nil; res.truncated = true; res.dropped = 'size cap' end
        results[full] = res
        counts[res.code] = (counts[res.code] or 0) + 1
      end
    end
    checkpoint()
  end
  run.calls = { results = results, counts = counts, calls = budget.calls, bytes = budget.bytes }
  return run.calls
end

---------------------------------------------------------------------------
-- Undocumented namespaces (Q-T3, approved with limits 2026-11-05; evidence EI-E-12)
--   * every undocumented namespace is LISTED (member names and types)
--   * C_Seasons and C_Trophy: zero-argument Get/Is/Has names (extended denylist) are PLANNED passively and
--     CALLED only when the user types /eicheck undoc (a hard crash erases any in-session marker, so a person
--     starts the calls), each under the crash guard in D.Probe
--   * C_Reincarnation: listed for the user's review, never called
--   * service, store, debug and all other namespaces: listed, never called
---------------------------------------------------------------------------
D.UNDOC_KNOWN = { 'C_AccountServices', 'C_ArrowCalloutManager', 'C_BlackMarket', 'C_CharacterServices',
  'C_CharacterServicesPublic', 'C_Debug', 'C_FunctionContainers', 'C_Heirloom', 'C_PrototypeDialog', 'C_Reincarnation',
  'C_Scenario', 'C_Seasons', 'C_SharedCharacterServices', 'C_SpectatingUI', 'C_ToyBox', 'C_Trophy', 'C_Widget',
  'C_WoWLabsMatchmaking', 'C_WowLabsDataManager', 'C_WowTokenPublic' }
D.UNDOC_CALL = { C_Seasons = true, C_Trophy = true }
D.UNDOC_REVIEW = { C_Reincarnation = true }

function D.ListUndocumented(rec)
  local db = NS.Core.DB()
  local set = {}
  for _, n in ipairs(D.UNDOC_KNOWN) do set[n] = 'known' end
  if db.docs and type(db.docs.index) == 'table' and type(rec.namespaces) == 'table' and type(rec.namespaces.all) == 'table' then
    local documented = {}
    for _, e in ipairs(db.docs.index) do if type(e.namespace) == 'string' then documented[e.namespace] = true end end
    for _, n in ipairs(rec.namespaces.all) do if not documented[n] and not set[n] then set[n] = 'new' end end
  end
  local out, plan = {}, {}
  for ns, origin in pairs(set) do
    local t = NS.G(ns)
    local policy = D.UNDOC_CALL[ns] and 'call-on-command' or (D.UNDOC_REVIEW[ns] and 'review' or 'list')
    local e = { present = type(t) == 'table', origin = origin, policy = policy, members = {}, count = 0 }
    if type(t) == 'table' then
      pcall(function()
        for k, v in pairs(t) do
          if type(k) == 'string' then
            e.count = e.count + 1
            if e.count <= 200 then e.members[k] = type(v) end
            if policy == 'call-on-command' and type(v) == 'function' then
              local full = ns .. '.' .. k
              if U.isReadName(k) and not U.denied(full) and not db.neverCall[full] then
                table.insert(plan, full)
              end
            end
          end
        end
      end)
    end
    out[ns] = e
    checkpoint()
  end
  table.sort(plan)
  db.undoc = { at = U.wall(), namespaces = out, plan = plan, results = db.undoc and db.undoc.results or nil,
    calledAt = db.undoc and db.undoc.calledAt or nil }
  return db.undoc
end

-- /eicheck undoc: call the planned names once, in a scheduler job (limit 3), each under the crash guard.
function D.CallUndocumented()
  local db = NS.Core.DB()
  if not db.undoc or type(db.undoc.plan) ~= 'table' then return "the first check of this session hasn't finished; try again in about 10 seconds" end
  if #db.undoc.plan == 0 then return 'nothing to call (no allowed names)' end
  if D.undocQueued then return 'already running' end
  D.undocQueued = true
  NS.Core.Enqueue(function()
    local results, counts = {}, {}
    local budget = { calls = 0, bytes = 0 }
    for _, full in ipairs(db.undoc.plan) do
      local res
      if U.inCombat() then
        res = { code = 'skipped_combat' }
      else
        local ok, r = pcall(D.Probe, full, nil, db.docs and db.docs.args or nil, budget)
        res = ok and r or { code = 'error', detail = U.ascii(tostring(r)) }
      end
      if res then
        results[full] = res
        counts[res.code] = (counts[res.code] or 0) + 1
      end
      checkpoint()
    end
    db.undoc.results = results
    db.undoc.calledAt = U.wall()
    D.undocQueued = false
    local parts = {}
    for code, n in pairs(counts) do table.insert(parts, code .. ' ' .. n) end
    table.sort(parts)
    NS.Core.Say('undoc: ' .. #db.undoc.plan .. ' names called: ' .. table.concat(parts, ', ') .. '. Type /reload to save.', true)
  end, 'undoc', function() D.undocQueued = false end)
  return 'calling ' .. #db.undoc.plan .. ' names in C_Seasons and C_Trophy; result in a few seconds'
end
