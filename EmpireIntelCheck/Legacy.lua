local ADDON, NS = ...
-- EmpireIntelCheck / Legacy.lua                                          (0.1.6-tp1, Q-T7 approved 2026-11-07)
-- Part C: read the Legacy values once the system is unlocked (evidence EI-E-16: the challenges are an
-- achievement category, the points are shown from currency info).
--
-- LIMITS (user, Q-T7)
--   (a) The values returned by the zero-argument LegacySystem calls are saved, with the non-function fields of the
--       LegacySystem table (read, never called). Those two calls go through D.Probe: denylist and crash guard.
--   (b) Calls WITH arguments only to the documented achievement and currency getters in L.ALLOWED, and only with
--       numbers the game itself returned in this read (L.ids): ids from earlier answers, and indexes 1..n where the
--       game returned n. Anything else is refused before the call.
--   * No Set, Spend, Learn, Reset, Buy, Purchase, Request, Claim, Open, Toggle, Show or Reincarnate name (U.denied).
--   * Crash guard: the function name is in saved data while the call runs (db.inFlight); a name found there at the
--     next login goes to db.neverCall and is never called again.
--   * Runs inside a scheduler job, one checkpoint per call (limit 3); skipped in combat.
--   * Character names returned by the game (earnedBy, criteria charName) are not saved.

local U = NS.U
local L = {}
NS.Legacy = L

L.MAX_CALLS = 2500
L.MAX_CATEGORIES = 400
L.MAX_CHALLENGES = 120
L.MAX_CRITERIA = 40
L.MAX_INDEX = 400
L.MAX_CURRENCY_LIST = 300

-- name -> allowed argument counts
L.ALLOWED = {
  ['C_CurrencyInfo.GetCurrencyInfo'] = { [1] = true },
  ['C_CurrencyInfo.GetCurrencyListSize'] = { [0] = true },
  ['C_CurrencyInfo.GetCurrencyListInfo'] = { [1] = true },
  GetCategoryList = { [0] = true },
  GetCategoryInfo = { [1] = true },
  GetCategoryNumAchievements = { [1] = true },
  GetAchievementInfo = { [1] = true, [2] = true },
  GetAchievementNumCriteria = { [1] = true },
  GetAchievementCriteriaInfo = { [2] = true },
}

local checkpoint = function() NS.Core.Checkpoint() end

-- scalar value safe to save: numbers and booleans as they are, strings as ASCII (capped), secrets marked
local function val(v)
  if U.isSecret(v) then return '<secret>' end
  local t = type(v)
  if t == 'number' or t == 'boolean' then return v end
  if t == 'string' then return U.ascii(string.sub(v, 1, 300)) end
  return nil
end

local function isId(v) return type(v) == 'number' and v >= 0 and v == math.floor(v) and not U.isSecret(v) end

local function newState()
  return { ids = {}, calls = 0, counts = {}, errors = {}, refused = {} }
end

local function count(st, code) st.counts[code] = (st.counts[code] or 0) + 1 end

-- a number the game returned may be used as an argument
local function reg(st, v) if isId(v) then st.ids[v] = true end end
-- indexes 1..n after the game returned n
local function regCount(st, n)
  if not isId(n) then return 0 end
  local top = math.min(n, L.MAX_INDEX)
  for i = 1, top do st.ids[i] = true end
  return top
end

--- One guarded call. Returns the packed results { n, ... } or nil.
function L.Call(st, full, ...)
  local arity = L.ALLOWED[full]
  local n = select('#', ...)
  if not arity or not arity[n] then count(st, 'refused'); st.refused[full] = 'not allowed'; return nil end
  for i = 1, n do
    local a = select(i, ...)
    if not isId(a) or not st.ids[a] then count(st, 'refused'); st.refused[full] = 'argument not returned by the game'; return nil end
  end
  if U.denied(full) then count(st, 'skipped_denylist'); return nil end
  if st.calls >= L.MAX_CALLS then count(st, 'skipped_cap'); return nil end
  if U.inCombat() then count(st, 'skipped_combat'); return nil end
  local db = NS.Core.DB()
  if db.neverCall[full] then count(st, 'skipped_crash_guard'); return nil end
  local fn = U.path(full)
  if type(fn) ~= 'function' then count(st, 'not_found'); st.errors[full] = st.errors[full] or 'not found'; return nil end
  st.calls = st.calls + 1
  db.inFlight = { name = full, at = U.wall() }
  local r = U.pack(pcall(fn, ...))
  db.inFlight = nil
  checkpoint()
  if not r[1] then
    count(st, 'error')
    st.errors[full] = st.errors[full] or U.ascii(tostring(r[2]))
    return nil
  end
  count(st, 'ok')
  local out = { n = r.n - 1 }
  for i = 2, r.n do out[i - 1] = r[i] end
  return out
end

-- numbers under id-like keys anywhere in a (dumped) table, depth-limited
local function collectIds(st, t, depth, into)
  if type(t) ~= 'table' or (depth or 0) > 4 then return end
  for k, v in pairs(t) do
    if type(v) == 'table' then
      collectIds(st, v, (depth or 0) + 1, into)
    elseif isId(v) and type(k) == 'string' and string.find(string.lower(k), 'id', 1, true) then
      reg(st, v)
      if into then table.insert(into, { key = k, id = v }) end
    elseif isId(v) and type(k) == 'number' then
      reg(st, v)                      -- arrays of ids (for example a list of challenge ids)
      if into then table.insert(into, { key = '[array]', id = v }) end
    end
  end
end

-- (a) LegacySystem table: non-function fields, and the values of its zero-argument Get calls
function L.ReadSystem(st, out)
  local ls = NS.G('LegacySystem')
  if type(ls) ~= 'table' then out.system = { present = false, note = 'LegacySystem not loaded: open the Legacy pane once, then /eicheck legacy' }; return end
  local sys = { present = true, fields = {}, functions = {}, ids = {} }
  pcall(function()
    for k, v in pairs(ls) do
      if type(k) == 'string' then
        if type(v) == 'function' then
          table.insert(sys.functions, k)
        else
          local d = U.dump(v)
          sys.fields[k] = d
          collectIds(st, { [k] = d }, 0, sys.ids)
        end
      end
    end
  end)
  table.sort(sys.functions)
  local budget = { calls = 0, bytes = 0 }
  for _, name in ipairs({ 'GetCurrencyInfo', 'GetFilteredChallenges' }) do
    local full = 'LegacySystem.' .. name
    local ok, res = pcall(NS.Discover.Probe, full, nil, nil, budget)
    if not ok then res = { code = 'error', detail = U.ascii(tostring(res)) } end
    sys[name] = res
    if res and res.values then collectIds(st, res.values, 0, sys.ids) end
    checkpoint()
  end
  out.system = sys
end

-- (b) achievement categories: every category with its title; Legacy ones are those titled Legacy and their children
function L.ReadCategories(st, out, extraIds)
  local r = L.Call(st, 'GetCategoryList')
  if not r then out.categoryNote = 'GetCategoryList gave nothing'; return {} end
  local list = r[1]
  if type(list) ~= 'table' then list = {}; for i = 1, r.n do list[i] = r[i] end end
  local ids = {}
  for _, id in ipairs(list) do if isId(id) and #ids < L.MAX_CATEGORIES then reg(st, id); table.insert(ids, id) end end
  out.categoryCount = #ids
  local byId, all = {}, {}
  for _, id in ipairs(ids) do
    local info = L.Call(st, 'GetCategoryInfo', id)
    local c = { id = id, title = info and val(info[1]), parent = info and isId(info[2]) and info[2] or nil }
    if c.parent then reg(st, c.parent) end
    byId[id] = c
    table.insert(all, c)
  end
  local function isLegacy(c, depth)
    if not c or depth > 6 then return false end
    if extraIds[c.id] then return true end
    if type(c.title) == 'string' and string.find(string.lower(c.title), 'legacy', 1, true) then return true end
    return c.parent ~= nil and c.parent ~= -1 and isLegacy(byId[c.parent], depth + 1)
  end
  local legacy = {}
  out.categories = {}
  for _, c in ipairs(all) do
    if isLegacy(c, 0) then c.legacy = true; table.insert(legacy, c) end
    table.insert(out.categories, c)
  end
  return legacy
end

local function readCriteria(st, achId)
  local r = L.Call(st, 'GetAchievementNumCriteria', achId)
  local n = r and regCount(st, r[1]) or 0
  local list = {}
  for i = 1, math.min(n, L.MAX_CRITERIA) do
    local c = L.Call(st, 'GetAchievementCriteriaInfo', achId, i)
    if c then
      -- criteriaString, criteriaType, completed, quantity, reqQuantity, charName (not saved), flags, assetID,
      -- quantityString, criteriaID, eligible
      table.insert(list, { text = val(c[1]), type = val(c[2]), completed = val(c[3]), quantity = val(c[4]),
        required = val(c[5]), assetID = val(c[8]), quantityString = val(c[9]), criteriaID = val(c[10]) })
    end
  end
  return list, r and val(r[1]) or nil
end

local function challengeFrom(st, a, category)
  -- id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild,
  -- wasEarnedByMe, earnedBy (not saved), isStatistic
  if not a or not isId(a[1]) then return nil end
  reg(st, a[1])
  local ch = { id = a[1], name = val(a[2]), points = val(a[3]), completed = val(a[4]), description = val(a[8]),
    reward = val(a[11]), earnedByMe = val(a[13]), category = category }
  if a[4] == true and isId(a[5]) then ch.date = string.format('%d-%02d-%02d', 2000 + (a[7] or 0), a[5], a[6] or 0) end
  ch.criteria, ch.criteriaCount = readCriteria(st, a[1])
  return ch
end

function L.ReadChallenges(st, out, legacyCats, extraAchIds)
  out.challenges = {}
  local seen = {}
  for _, c in ipairs(legacyCats) do
    local r = L.Call(st, 'GetCategoryNumAchievements', c.id)
    local n = r and regCount(st, r[1]) or 0
    c.numAchievements = r and val(r[1]) or nil
    c.numCompleted = r and val(r[2]) or nil
    for i = 1, n do
      if #out.challenges >= L.MAX_CHALLENGES then out.challengesTruncated = true; break end
      local ch = challengeFrom(st, L.Call(st, 'GetAchievementInfo', c.id, i), c.id)
      if ch and not seen[ch.id] then seen[ch.id] = true; table.insert(out.challenges, ch) end
    end
  end
  -- ids the LegacySystem table returned that no category covered
  for _, id in ipairs(extraAchIds) do
    if not seen[id] and #out.challenges < L.MAX_CHALLENGES then
      local ch = challengeFrom(st, L.Call(st, 'GetAchievementInfo', id), nil)
      if ch then seen[ch.id] = true; ch.source = 'LegacySystem'; table.insert(out.challenges, ch) end
    end
  end
end

local function currencyFrom(info)
  if type(info) ~= 'table' then return nil end
  local c = {}
  for _, k in ipairs({ 'name', 'quantity', 'maxQuantity', 'totalEarned', 'useTotalEarnedForMaxQty', 'quantityEarnedThisWeek',
    'maxWeeklyQuantity', 'isAccountWide', 'isAccountTransferable', 'discovered', 'currencyID', 'isHeader' }) do
    local ok, v = pcall(function() return info[k] end)
    if ok then c[k] = val(v) end
  end
  return c
end

-- (b) currency: ids the LegacySystem answers named; else the currency list, matched by name
function L.ReadCurrency(st, out, currencyIds)
  out.currency = {}
  for _, id in ipairs(currencyIds) do
    local r = L.Call(st, 'C_CurrencyInfo.GetCurrencyInfo', id)
    local c = r and currencyFrom(r[1])
    if c then c.id = id; c.source = 'GetCurrencyInfo'; table.insert(out.currency, c) end
  end
  if #out.currency > 0 then return end
  local r = L.Call(st, 'C_CurrencyInfo.GetCurrencyListSize')
  local n = r and regCount(st, r[1]) or 0
  out.currencyListSize = r and val(r[1]) or nil
  for i = 1, math.min(n, L.MAX_CURRENCY_LIST) do
    local e = L.Call(st, 'C_CurrencyInfo.GetCurrencyListInfo', i)
    local c = e and currencyFrom(e[1])
    if c and type(c.name) == 'string' and string.find(string.lower(c.name), 'legacy', 1, true) then
      c.listIndex = i; c.source = 'currency list'
      table.insert(out.currency, c)
    end
  end
end

-- which allowed names the in-client docs list (only when the docs addon is loaded: /eicheck docs)
function L.DocsStatus()
  local api = NS.G('APIDocumentation')
  if type(api) ~= 'table' or type(api.systems) ~= 'table' then return 'docs not loaded this session' end
  local found = {}
  for full in pairs(L.ALLOWED) do found[full] = false end
  for _, sys in ipairs(api.systems) do
    pcall(function()
      for _, f in ipairs(type(sys.Functions) == 'table' and sys.Functions or {}) do
        local name = (type(sys.Namespace) == 'string' and sys.Namespace ~= '') and (sys.Namespace .. '.' .. tostring(f.Name)) or tostring(f.Name)
        if found[name] ~= nil then found[name] = true end
      end
    end)
  end
  return found
end

--- Reads everything; must run inside a scheduler job. Returns the saved table.
function L.Read(reason, unlocked)
  local st = newState()
  local out = { at = U.wall(), reason = reason, unlocked = unlocked, version = NS.VERSION }
  -- no pcall around this block: it yields between calls, and Lua 5.1 cannot yield across pcall. Every game call is
  -- guarded on its own (L.Call, D.Probe); any other failure ends the job and is reported by the caller.
  do
    L.ReadSystem(st, out)
    local extraCats, extraAch, currencyIds = {}, {}, {}
    for _, e in ipairs(out.system and out.system.ids or {}) do
      local k = string.lower(e.key)
      if string.find(k, 'categor', 1, true) then extraCats[e.id] = true
      elseif string.find(k, 'currency', 1, true) then table.insert(currencyIds, e.id)
      elseif string.find(k, 'achiev', 1, true) or k == '[array]' then table.insert(extraAch, e.id) end
    end
    local legacyCats = L.ReadCategories(st, out, extraCats)
    out.legacyCategories = #legacyCats
    L.ReadChallenges(st, out, legacyCats, extraAch)
    L.ReadCurrency(st, out, currencyIds)
    out.docs = L.DocsStatus()
  end
  local done = 0
  for _, ch in ipairs(out.challenges or {}) do if ch.completed == true then done = done + 1 end end
  local pts = out.currency and out.currency[1]
  out.summary = { challenges = out.challenges and #out.challenges or 0, completed = done, categories = out.legacyCategories or 0,
    points = pts and pts.quantity, max = pts and pts.maxQuantity, currency = pts and pts.name }
  out.calls = { total = st.calls, counts = st.counts, errors = st.errors, refused = st.refused }
  local db = NS.Core.DB()
  local hist = db.legacy and db.legacy.history or {}
  table.insert(hist, { at = out.at, points = out.summary.points, completed = done, challenges = out.summary.challenges })
  while #hist > 30 do table.remove(hist, 1) end
  out.history = hist
  db.legacy = out
  return out
end

--- One chat line for the read.
function L.Line(out)
  local s = out.summary
  local text = 'Legacy read: ' .. s.challenges .. ' challenges (' .. s.completed .. ' completed) in ' .. s.categories .. ' categories; '
  if s.points ~= nil then
    text = text .. tostring(s.currency or 'currency') .. ' ' .. tostring(s.points) .. (s.max and s.max ~= 0 and ('/' .. tostring(s.max)) or '')
  else
    text = text .. 'points not found'
  end
  if out.system and not out.system.present then text = text .. '; LegacySystem not loaded (open the pane, then /eicheck legacy)' end
  if (out.calls.counts.refused or 0) > 0 then text = text .. '; UNEXPECTED refused ' .. out.calls.counts.refused end
  return text
end

-- /eicheck legacy: read again (for example after opening the pane)
function L.Command()
  if L.queued then return 'already running' end
  L.queued = true
  NS.Core.Enqueue(function()
    local mixin = NS.G('LegacyMicroButtonMixin')
    local unlocked = nil
    if type(mixin) == 'table' and type(mixin.IsLegacySystemUnlocked) == 'function' then
      local ok, v = pcall(mixin.IsLegacySystemUnlocked)
      if ok then unlocked = v end
    end
    local out = L.Read('command', unlocked)
    NS.Core.Trim()
    L.queued = false
    NS.Core.Say(L.Line(out) .. '. Type /reload to save.', true)
  end, 'legacy', function() L.queued = false end)
  return 'reading; result in a few seconds'
end
