local ADDON, EI = ...
-- EmpireIntel / Platform / Legacy.lua                                    (Phase 3, increment P3-1)
--
-- PURPOSE
--   Reads the Legacy values on the user's command (/ei legacy). The ONLY file that calls the Legacy and achievement
--   functions (static test). Ported from EmpireIntelCheck/Legacy.lua (0.1.8-tp1), our own code, which proved every
--   call on the live client (TP-1 runs 6-15, Phase3_Legacy_Plan.md section 1).
--
-- LIMITS (Q-P3-1, carried over from Q-T7, Q-T8, Q-T9; D-037)
--   * Only the names in L.ALLOWED. Arguments only numbers the game itself returned in this read (L.Call refuses
--     anything else before the call). The denylist (Set, Spend, Learn, Reset, Buy, Purchase, Request, Claim, Open,
--     Toggle, Show, Reincarnat...) applies to every name.
--   * LegacySystem.GetCurrencyInfo() with no argument only. No trait-system call (Q-T4 unapproved); never
--     UpdateCurrencyInfo or RegisterCurrencyInfoCallback.
--   * No call in combat. The work is spread over frames (L.PER_SLICE calls per frame).
--   * Nothing is saved (Q-P3-1a): the result lives in memory until the next read. No saved crash guard.
--   * Character names the game returns with achievements (earnedBy, criteria charName) are never kept.

EI = EI or {}
local P = EI.Platform
assert(P and P.After, 'Platform and Scheduler must be loaded before Platform/Legacy.lua')

local L = {}
P.Legacy = L

L.PER_SLICE = 60
L.MAX_CALLS = 2500
L.MAX_CATEGORIES = 400
L.MAX_CHALLENGES = 250
L.MAX_CRITERIA = 40
L.MAX_INDEX = 400
L.MAX_STEPS = 200
L.MAX_PER_EXCLUDED = 30
L.EXCLUDED_TITLES = { ['do not display'] = true, ['tier 1 gear'] = true }    -- not shown in the pane (Q-T8)

-- name -> allowed argument counts. Narrowed from the check: the C_CurrencyInfo getters are dropped (D-037).
L.ALLOWED = {
  ['LegacySystem.GetCurrencyInfo'] = { [0] = true },
  GetCategoryList = { [0] = true },
  GetCategoryInfo = { [1] = true },
  GetCategoryNumAchievements = { [1] = true },
  GetAchievementInfo = { [1] = true, [2] = true },
  GetAchievementNumCriteria = { [1] = true },
  GetAchievementCriteriaInfo = { [2] = true },
}

L.DENY = { 'set', 'spend', 'learn', 'reset', 'buy', 'purchase', 'request', 'claim', 'open', 'toggle', 'show', 'reincarnate' }

-- CamelCase words of a name, lower case ("GetCurrencyInfo" -> get, currency, info)
local function words(name)
  local out = {}
  for part in string.gmatch(tostring(name), '[^%._]+') do
    local s = string.gsub(part, '(%l)(%u)', '%1 %2')
    s = string.gsub(s, '(%u)(%u%l)', '%1 %2')
    for w in string.gmatch(s, '%S+') do out[#out + 1] = string.lower(w) end
  end
  return out
end

--- The blocked word in a name, or nil (whole CamelCase words, plus the stem "reincarnat").
function L.Denied(name)
  if string.find(string.lower(tostring(name)), 'reincarnat', 1, true) then return 'reincarnat' end
  local set = {}
  for _, w in ipairs(words(name)) do set[w] = true end
  for _, d in ipairs(L.DENY) do if set[d] then return d end end
  return nil
end

local function isId(v) return type(v) == 'number' and v >= 0 and v == math.floor(v) and not P.IsSecret(v) end

local function val(v)
  if P.IsSecret(v) then return '<secret>' end
  local t = type(v)
  if t == 'number' or t == 'boolean' then return v end
  if t == 'string' then return string.sub(v, 1, 300) end
  return nil
end

local function safeText(v)
  local ok, t = pcall(tostring, v)
  if ok and type(t) == 'string' then return t end
  return '(unprintable)'
end

local function path(full)
  local cur = P.env
  for part in string.gmatch(full, '[^%.]+') do
    if type(cur) ~= 'table' then return nil end
    local ok, nxt = pcall(function() return cur[part] end)
    if not ok then return nil end
    cur = nxt
  end
  return cur
end

local function pack(...) return { n = select('#', ...), ... } end
local function count(st, code) st.counts[code] = (st.counts[code] or 0) + 1 end
local function reg(st, v) if isId(v) then st.ids[v] = true end end
local function regCount(st, n)
  if not isId(n) then return 0 end
  local top = math.min(n, L.MAX_INDEX)
  for i = 1, top do st.ids[i] = true end
  return top
end

local function inCombat()
  if P.Events and P.Events.inCombat then return true end
  local r = P.Call('InCombatLockdown')
  return r ~= nil and r[1] == true
end

--- One guarded call. Returns { n, ... } or nil. Yields to the next frame every L.PER_SLICE calls when run inside
-- the read coroutine (never inside a pcall: Lua 5.1 cannot yield across it).
function L.Call(st, full, ...)
  local arity = L.ALLOWED[full]
  local n = select('#', ...)
  if not arity or not arity[n] then count(st, 'refused'); st.refused[full] = 'not allowed'; return nil end
  for i = 1, n do
    local a = select(i, ...)
    if not isId(a) or not st.ids[a] then count(st, 'refused'); st.refused[full] = 'argument not returned by the game'; return nil end
  end
  if L.Denied(full) then count(st, 'skipped_denylist'); return nil end
  if st.calls >= L.MAX_CALLS then count(st, 'skipped_cap'); return nil end
  if inCombat() then st.combat = true; count(st, 'skipped_combat'); return nil end
  local fn = path(full)
  if type(fn) ~= 'function' then count(st, 'not_found'); st.errors[full] = st.errors[full] or 'not found'; return nil end
  st.calls = st.calls + 1
  local r = pack(pcall(fn, ...))
  st.sinceYield = st.sinceYield + 1
  if st.inCoroutine and st.sinceYield >= L.PER_SLICE then
    st.sinceYield = 0
    coroutine.yield()
  end
  if not r[1] then
    count(st, 'error')
    st.errors[full] = st.errors[full] or safeText(r[2])
    return nil
  end
  count(st, 'ok')
  local out = { n = r.n - 1 }
  for i = 2, r.n do out[i - 1] = r[i] end
  return out
end

---------------------------------------------------------------------------
-- Points: LegacySystem.GetCurrencyInfo() (EI-E-21, EI-E-24..27). Available once the pane has loaded this session.
---------------------------------------------------------------------------
function L.ReadPoints(st, out)
  local ls = P.env.LegacySystem
  if type(ls) ~= 'table' then out.paneLoaded = false; return end
  out.paneLoaded = true
  local r = L.Call(st, 'LegacySystem.GetCurrencyInfo')
  local t = r and r[1]
  if type(t) ~= 'table' then return end
  local p = {}
  local ok = pcall(function()
    for k, v in pairs(t) do
      if type(k) == 'string' and type(v) ~= 'table' then p[k] = val(v) end
    end
  end)
  if ok and next(p) ~= nil then out.points = p end
end

---------------------------------------------------------------------------
-- Challenges: every category the game lists (EI-E-20); a challenge is an achievement whose reward names a Legacy point
-- (EI-E-22); steps are linked through the game's own achievement chain (Explorer, EI-E-23).
---------------------------------------------------------------------------
function L.ReadCategories(st, out)
  local r = L.Call(st, 'GetCategoryList')
  if not r then return {} end
  local list = r[1]
  if type(list) ~= 'table' then list = {}; for i = 1, r.n do list[i] = r[i] end end
  local ids = {}
  for _, id in ipairs(list) do if isId(id) and #ids < L.MAX_CATEGORIES then reg(st, id); ids[#ids + 1] = id end end
  local byId, all = {}, {}
  for _, id in ipairs(ids) do
    local info = L.Call(st, 'GetCategoryInfo', id)
    local c = { id = id, title = info and val(info[1]), parent = info and isId(info[2]) and info[2] or nil }
    if c.parent then reg(st, c.parent) end
    byId[id] = c
    all[#all + 1] = c
  end
  local function excluded(c, depth)
    if not c or depth > 6 then return false end
    if type(c.title) == 'string' and L.EXCLUDED_TITLES[string.lower(c.title)] then return true end
    return c.parent ~= nil and excluded(byId[c.parent], depth + 1)
  end
  local function top(c, depth)
    if not c or depth > 6 or not c.parent or not byId[c.parent] then return c end
    return top(byId[c.parent], depth + 1)
  end
  for _, c in ipairs(all) do
    if excluded(c, 0) then c.excluded = true end
    c.group = top(c, 0).id
  end
  out.categories, out.categoryById = all, byId
  return all
end

local function readCriteria(st, achId)
  local r = L.Call(st, 'GetAchievementNumCriteria', achId)
  local n = r and regCount(st, r[1]) or 0
  local list = {}
  for i = 1, math.min(n, L.MAX_CRITERIA) do
    local c = L.Call(st, 'GetAchievementCriteriaInfo', achId, i)
    if c then
      -- criteriaString, type, completed, quantity, reqQuantity, charName (never kept), flags, assetID
      list[#list + 1] = { text = val(c[1]), type = val(c[2]), completed = val(c[3]), quantity = val(c[4]),
        required = val(c[5]), assetID = val(c[8]) }
    end
  end
  return list
end

local function challengeFrom(st, a, category)
  -- id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe,
  -- earnedBy (never kept), isStatistic
  if not a or not isId(a[1]) then return nil end
  reg(st, a[1])
  local reward = val(a[11])
  local value = type(reward) == 'string' and tonumber(string.match(reward, '(%d+) Legacy Point')) or nil
  local ch = { id = a[1], name = val(a[2]), completed = val(a[4]), description = val(a[8]), legacy = value, category = category }
  ch.criteria = readCriteria(st, a[1])
  return ch
end

function L.ReadChallenges(st, out, cats)
  out.challenges = {}
  local seen = {}
  for _, c in ipairs(cats) do
    local r = L.Call(st, 'GetCategoryNumAchievements', c.id)
    local n = r and regCount(st, r[1]) or 0
    local top = c.excluded and math.min(n, L.MAX_PER_EXCLUDED) or n
    for i = 1, top do
      if #out.challenges >= L.MAX_CHALLENGES then break end
      local ch = challengeFrom(st, L.Call(st, 'GetAchievementInfo', c.id, i), c.id)
      if ch and not seen[ch.id] then
        seen[ch.id] = true
        if c.excluded then ch.excluded = true end
        out.challenges[#out.challenges + 1] = ch
      end
    end
  end
end

-- A criterion links to an achievement when its assetID is that achievement's id and it is of the "complete
-- achievement" type (8) or carries that achievement's name; an area id that merely equals an achievement id is not.
function L.Link(out)
  local byId = {}
  for _, ch in ipairs(out.challenges or {}) do byId[ch.id] = ch end
  out.challengeById = byId
  local function children(ch)
    local list = {}
    for _, c in ipairs(ch.criteria or {}) do
      local t = isId(c.assetID) and byId[c.assetID] or nil
      if t and t ~= ch and (c.type == 8 or c.text == t.name) then list[#list + 1] = t end
    end
    return list
  end
  for _, ch in ipairs(out.challenges or {}) do
    if ch.legacy and not ch.excluded then
      local steps, seen, queue, i = {}, { [ch.id] = true }, children(ch), 1
      while i <= #queue and #steps < L.MAX_STEPS do
        local s = queue[i]; i = i + 1
        if not seen[s.id] and not s.legacy and not s.excluded then
          seen[s.id] = true
          s.stepOf = ch.id
          steps[#steps + 1] = s
          for _, c in ipairs(children(s)) do queue[#queue + 1] = c end
        end
      end
      if #steps > 0 then ch.steps = steps end
    end
  end
end

function L.Summarize(out)
  local recognized = false
  for _, ch in ipairs(out.challenges or {}) do if ch.legacy and not ch.excluded then recognized = true end end
  local s = { challenges = 0, completed = 0, offered = 0, earned = 0, recognized = recognized, groups = {} }
  for _, ch in ipairs(out.challenges or {}) do
    if ch.legacy and not ch.excluded then
      s.challenges = s.challenges + 1
      s.offered = s.offered + ch.legacy
      local cat = out.categoryById and out.categoryById[ch.category]
      local gid = cat and cat.group or 0
      local g = s.groups[gid]
      if not g then
        local gc = out.categoryById and out.categoryById[gid]
        g = { id = gid, title = gc and gc.title or '?', done = 0, total = 0 }
        s.groups[gid] = g
      end
      g.total = g.total + 1
      if ch.completed == true then s.completed = s.completed + 1; s.earned = s.earned + ch.legacy; g.done = g.done + 1 end
    end
  end
  out.summary = s
  return s
end

---------------------------------------------------------------------------
-- The read: a coroutine resumed by the scheduler, L.PER_SLICE calls per frame. Nothing is saved.
---------------------------------------------------------------------------
L.busy = false
L.last = nil

local function body(st, out)
  L.ReadPoints(st, out)
  local cats = L.ReadCategories(st, out)
  L.ReadChallenges(st, out, cats)
  L.Link(out)
  L.Summarize(out)
end

--- Starts a read. done(out) is called when it finishes (or stops for combat or an error).
-- Returns false plus a reason when no read was started.
function L.Read(done)
  if L.busy then return false, 'busy' end
  if inCombat() then return false, 'combat' end
  L.busy = true
  local st = { ids = {}, calls = 0, counts = {}, errors = {}, refused = {}, sinceYield = 0, inCoroutine = true }
  local out = { at = (P.Now()) }
  local co = coroutine.create(function() body(st, out) end)
  local function finish(err)
    L.busy = false
    out.calls = { total = st.calls, counts = st.counts, errors = st.errors, refused = st.refused }
    out.combat = st.combat
    if err then out.error = safeText(err) end
    L.last = out
    if done then pcall(done, out) end
  end
  local function step()
    local ok, err = coroutine.resume(co)
    if not ok then finish(err); return end
    if coroutine.status(co) == 'dead' then finish(nil); return end
    if st.combat then finish(nil); return end
    P.After(0.01, step)
  end
  step()
  return true
end
