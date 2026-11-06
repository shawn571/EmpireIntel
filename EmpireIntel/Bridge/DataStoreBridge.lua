local ADDON, EI = ...
-- EmpireIntel / Bridge / DataStoreBridge.lua                             (Phase 2, increment P2-2)
--
-- PURPOSE
--   Reads your characters from DataStore, live, when DataStore is installed. This is the ONLY file allowed to
--   touch DataStore (static test). DataStore is All Rights Reserved: it is used at run time only, never copied.
--
-- RULES (Phase2_Plan.md section 5, approved Q-P2-2)
--   * Read-only getters only, from the approved list below; dsCall refuses any other name. All were checked live
--     on the launch build by TP-1 T5/T6 (EI-E-07). Nothing that scans, sets or requests.
--   * The GUID comes from DataStore's own DataStore_CharacterGUIDs table, read only.
--   * Nothing read here is stored: the result is a fresh table each call (no change to saved-data format 1).
--   * Read only when the user types /ei alts; no timer, no event.
--   * Every DataStore error is caught and counted; the caller shows it as one UNEXPECTED line.
--
-- DATASTORE FACTS (DataStore_Characters and DataStore_Crafts source, read-only clone)
--   * Keys are "Account.Realm.Name"; IterateCharacters(callback(key, id)) walks every character.
--   * GetLastLogout is 5000000000 while the character is logged in (or if the game crashed), 0 when unknown.
--   * GetRestXP is the rested XP at the last update; DataStore turns "none" into 0.
--   * GetModuleLastUpdateByKey('DataStore_Characters', key) is when DataStore last saved that character.

EI = EI or {}
local P = EI.Platform
assert(P, 'Platform must be loaded before Bridge/DataStoreBridge.lua')

local B = {}
EI.DataStoreBridge = B

B.MAX_CHARACTERS = 200
B.ONLINE_LOGOUT = 5000000000

-- The approved getters (Phase2_Plan.md section 5). Nothing else is ever called.
B.ALLOWED = {
  IterateCharacters = true, GetCharacterLevel = true, GetCharacterClass = true, GetRestXP = true, IsResting = true,
  GetLastLogout = true, GetModuleLastUpdateByKey = true,
  GetProfession1Name = true, GetProfession1Rank = true, GetProfession2Name = true, GetProfession2Rank = true,
}

local function store() return P.env.DataStore end

--- True when DataStore is loaded (its table exists).
function B.Available()
  return type(store()) == 'table'
end

local function safeText(v)
  local ok, t = pcall(tostring, v)
  if ok and type(t) == 'string' then return t end
  return '(unprintable)'
end

-- Calls ds:name(...) under pcall. Returns ok, r1, r2, r3. ok is false on an error (counted in errs),
-- nil when the method is missing (not an error: a DataStore module may be off).
local function dsCall(ds, errs, name, ...)
  if not B.ALLOWED[name] then
    errs.n = errs.n + 1
    errs.first = errs.first or ('refused call ' .. safeText(name))
    return false
  end
  local okGet, f = pcall(function() return ds[name] end)
  if not okGet or type(f) ~= 'function' then
    errs.missing[name] = true
    return nil
  end
  local ok, r1, r2, r3 = pcall(f, ds, ...)
  if not ok then
    errs.n = errs.n + 1
    errs.first = errs.first or (name .. ': ' .. safeText(r1))
    return false
  end
  return true, r1, r2, r3
end

local function num(v) if type(v) == 'number' and v == v then return v end return nil end
local function str(v) if type(v) == 'string' and v ~= '' then return v end return nil end

local function readCharacter(ds, errs, key, id, guids, now)
  if type(key) ~= 'string' then error('character key is not a string') end
  local _, realm, name = string.match(key, '^([^%.]*)%.(.*)%.([^%.]*)$')
  local c = { key = key, name = str(name), realm = str(realm), src = 'datastore' }
  if type(guids) == 'table' and id ~= nil then
    local okG, g = pcall(function() return guids[id] end)
    if okG and type(g) == 'string' and g ~= '' then c.guid = g end
  end
  local ok, v = dsCall(ds, errs, 'GetCharacterLevel', key)
  if ok and num(v) and v >= 1 then c.level = v end
  local ok2, _, token = dsCall(ds, errs, 'GetCharacterClass', key)
  if ok2 then c.class = str(token) end
  ok, v = dsCall(ds, errs, 'GetRestXP', key)
  if ok and num(v) and v >= 0 then c.rest = v end
  ok, v = dsCall(ds, errs, 'IsResting', key)
  if ok and (v == true or v == false) then c.resting = v end
  ok, v = dsCall(ds, errs, 'GetLastLogout', key)
  if ok and num(v) then
    if v >= B.ONLINE_LOGOUT then c.online = true elseif v > 0 then c.lastLogout = v end
  end
  ok, v = dsCall(ds, errs, 'GetModuleLastUpdateByKey', 'DataStore_Characters', key)
  if ok and num(v) and v > 0 then c.updated = v end
  -- the time DataStore's values are from: its last save, else the last logout
  c.at = c.updated or c.lastLogout
  if c.at and now and c.at > now then c.at = now end
  local profs, okAll = {}, true
  for i = 1, 2 do
    local okN, pname = dsCall(ds, errs, 'GetProfession' .. i .. 'Name', key)
    local okR, rank, maxRank = dsCall(ds, errs, 'GetProfession' .. i .. 'Rank', key)
    if okN == nil and okR == nil then
      okAll = false                       -- DataStore_Crafts not loaded: professions unknown
    elseif okN and str(pname) then
      profs[#profs + 1] = { name = pname, skill = okR and num(rank) or nil, max = okR and num(maxRank) or nil }
    elseif okN == false or okR == false then
      okAll = false
    end
  end
  if okAll then c.professions = profs end
  return c
end

--- Reads every character DataStore knows.
-- Returns { present = bool, list = { character, ... }, errors = n, firstError = text, missing = { method = true },
--           truncated = bool }. Never raises.
function B.Read()
  local out = { present = false, list = {}, errors = 0, missing = {} }
  local ds = store()
  if type(ds) ~= 'table' then return out end
  out.present = true
  local errs = { n = 0, missing = out.missing }
  local guids = P.env.DataStore_CharacterGUIDs
  local now = (P.Now())
  local count = 0
  local ok = dsCall(ds, errs, 'IterateCharacters', function(key, id)
    count = count + 1
    if count > B.MAX_CHARACTERS then out.truncated = true; return end
    local okC, c = pcall(readCharacter, ds, errs, key, id, guids, now)
    if okC then
      out.list[#out.list + 1] = c
    else
      errs.n = errs.n + 1
      errs.first = errs.first or ('character ' .. safeText(key) .. ': ' .. safeText(c))
    end
  end)
  if ok == nil then out.cannotList = true end
  out.errors = errs.n
  out.firstError = errs.first
  return out
end
