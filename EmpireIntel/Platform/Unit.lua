local ADDON, EI = ...
-- EmpireIntel / Platform / Unit.lua
--
-- PURPOSE
--  Player identity and character attributes.
--      Platform.Player() -> { guid, key, keyKind, name, realm, class, level, faction, profs }
--      Platform.Unit.Progress() -> { level, xp, xpMax, rest, resting }
--      Platform.Unit.ProfessionList() -> { { name, skill, max, line }, ... }
--  Emits normalized events P_LEVEL and P_PROFS.
--
-- PORTED from EmpireIntel EmpireIntel/Platform/Unit.lua at commit a21e071 (read-only; EmpireIntel unchanged).
-- Changes: the name is "First Last" (Forever two-part names, EI-E-44/T3); a realm field (launch has named realms,
-- EI-E-06; user, Q-P2-1); Progress() reads XP and rested XP (nil stays nil: never stored as 0); ProfessionList()
-- keeps skill, max and skill line; the cast tracking (UNIT_SPELLCAST_SUCCEEDED, gathering kinds) is removed.
--
-- IDENTITY (Decisions D-004)
--  The character key is the GUID. Name and realm are attributes. If the GUID is not
--  available yet, a degraded key 'name:<Name>:<Faction>' is used and keyKind says so.
--
-- CLASS
--  `class` is the non-localized class TOKEN (e.g. 'MAGE'), not the display name,
--  so aggregated data never splits by client language.
--
-- PROFESSIONS (one adapter, D-027)
--  GetProfessions()/GetProfessionInfo()  (modern API; the only one the Forever client has, E-05).
--  The classic skill-line adapter was removed under D-027 (approved 2026-10-18): GetNumSkillLines,
--  GetSkillLineInfo and ExpandSkillHeader do not exist in the target client.
--
--  SKILL_LINES_CHANGED fires very often (every weapon skill-up); it is debounced and
--  P_PROFS is emitted only when the profession set or a rank actually changed.

EI = EI or {}
local P = EI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Unit.lua')

local Unit = {}
P.Unit = Unit
P.Register('Unit', Unit)

local DEBOUNCE_SECONDS = 1.0
Unit.DEBOUNCE_SECONDS = DEBOUNCE_SECONDS

local cachedProfs = nil
local debouncePending = false

---------------------------------------------------------------------------
-- Professions
---------------------------------------------------------------------------

local function readList()
  local getProfs, getInfo = P.fn('GetProfessions'), P.fn('GetProfessionInfo')
  if not getProfs or not getInfo then return nil end
  local ok, a, b, c, d, e = pcall(getProfs)
  if not ok then return nil end
  local list = {}
  local indices = { a, b, c, d, e }
  for i = 1, 5 do
    local idx = indices[i]
    if idx then
      -- return order (retail engine, P-1 of the check): name, icon, skill, maxSkill, numAbilities, spellOffset, skillLine
      local okInfo, name, _, rank, maxRank, _, _, line = pcall(getInfo, idx)
      if okInfo and type(name) == 'string' and not P.IsSecret(name) and type(rank) == 'number' and not P.IsSecret(rank) then
        list[#list + 1] = { name = name, skill = rank,
          max = (type(maxRank) == 'number' and not P.IsSecret(maxRank)) and maxRank or nil,
          line = (type(line) == 'number' and not P.IsSecret(line)) and line or nil }
      end
    end
  end
  return list
end

local function readViaGetProfessions()
  local list = readList()
  if not list then return nil end
  local profs = {}
  for _, p in ipairs(list) do profs[p.name] = p.skill end
  return profs
end

--- Professions with skill, max and skill line, in the client's order ({} when the character has none),
-- or nil when the client cannot be read (so a caller never wipes stored professions on a bad read).
function Unit.ProfessionList()
  return readList()
end

--- Reads professions now. Returns a { [name] = rank } table (possibly empty).
function Unit.ReadProfessions()
  local profs = readViaGetProfessions()
  if profs then
    P.SetCap('prof.getprofessions', true)
    return profs
  end
  P.SetCap('prof.getprofessions', false)
  return {}
end

--- Cached professions (reads once). Returns a copy.
function Unit.Professions()
  if not cachedProfs then cachedProfs = Unit.ReadProfessions() end
  return P.Util.shallowCopy(cachedProfs)
end

---------------------------------------------------------------------------
-- Player snapshot
---------------------------------------------------------------------------

local function call(name, ...)
  local f = P.fn(name)
  if not f then return nil end
  local ok, a, b = pcall(f, ...)
  if not ok then return nil end
  if P.IsSecret(a) then a = nil end        -- 12.0 secret values cannot be compared or stored
  if P.IsSecret(b) then b = nil end
  return a, b
end

--- Platform.Player(). Returns the snapshot table, or nil plus a reason when the
-- character cannot be identified yet (too early in login).
function Unit.Player()
  local guid = call('UnitGUID', 'player')
  local name, surname = call('UnitName', 'player')
  if type(name) == 'string' and type(surname) == 'string' and surname ~= '' then name = name .. ' ' .. surname end
  local realm = call('GetRealmName')
  local _, classToken = call('UnitClass', 'player')
  local level = call('UnitLevel', 'player')
  local faction = call('UnitFactionGroup', 'player')

  if type(guid) ~= 'string' or guid == '' then guid = nil end
  if type(name) ~= 'string' or name == '' then name = nil end
  if not guid and not name then return nil, 'player identity unavailable' end

  local key, keyKind
  if guid then
    key, keyKind = guid, 'guid'
  else
    key, keyKind = 'name:' .. name .. ':' .. tostring(faction or '?'), 'name'
  end

  return {
    guid = guid,
    key = key,
    keyKind = keyKind,
    name = name,
    realm = type(realm) == 'string' and realm ~= '' and realm or nil,
    class = type(classToken) == 'string' and classToken or nil,
    level = type(level) == 'number' and level or nil,
    faction = type(faction) == 'string' and faction or nil,
    profs = Unit.Professions(),
  }
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local function refreshProfessions(emit)
  local fresh = Unit.ReadProfessions()
  local changed = not P.Util.shallowEqual(cachedProfs or {}, fresh)
  local first = cachedProfs == nil
  cachedProfs = fresh
  if changed and emit and not first then
    P.Events.Emit('P_PROFS', { profs = P.Util.shallowCopy(fresh) })
  end
  return changed
end

P.Events.Bind('PLAYER_LEVEL_UP', function(_, newLevel)
  local level = tonumber(newLevel)
  if not level then level = call('UnitLevel', 'player') end
  if type(level) == 'number' then
    P.Events.Emit('P_LEVEL', { level = level })
  end
end)

P.Events.Bind('SKILL_LINES_CHANGED', function()
  if not P.IsReady() or debouncePending then return end
  local cancel = P.After(DEBOUNCE_SECONDS, function()
    debouncePending = false
    refreshProfessions(true)
  end)
  if cancel then
    debouncePending = true
  else
    refreshProfessions(true)        -- no timer backend: refresh immediately
  end
end)

P.OnReady(function()
  refreshProfessions(false)         -- prime the cache silently
end)

--- Test helper.
function Unit.Reset()
  cachedProfs = nil
  debouncePending = false
end

P.Player = Unit.Player

---------------------------------------------------------------------------
-- XP and rested XP (FR-REST-1)
---------------------------------------------------------------------------

local function num(v) if type(v) == 'number' and v == v then return v end return nil end

--- Level, XP and rested XP of the player now. Fields are nil when the client gives nothing usable.
-- rest is nil (not 0) when GetXPExhaustion returns nothing: the approved format never stores unknown as 0.
function Unit.Progress()
  local resting = call('IsResting')
  return {
    level = num((call('UnitLevel', 'player'))),
    xp = num((call('UnitXP', 'player'))),
    xpMax = num((call('UnitXPMax', 'player'))),
    rest = num((call('GetXPExhaustion'))),
    resting = (resting == true or resting == false) and resting or nil,
  }
end
