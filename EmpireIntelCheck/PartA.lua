local ADDON, NS = ...
-- EmpireIntelCheck / PartA.lua
-- Part A: platform checks T1..T7 (Architecture.md section 9), kept from v1.0.0.
-- These read KNOWN client and DataStore functions (some take 'player' or a DataStore key).
-- The zero-argument limit applies to DISCOVERED Legacy names (Discover.lua), not to these.

local U = NS.U
local A = {}
NS.PartA = A

-- Call a known function by dotted path; returns code, values (bounded copy).
function A.Call(path, ...)
  local fn = U.path(path)
  if fn == nil then return 'not_found' end
  if type(fn) ~= 'function' then return 'not_function' end
  local r = U.pack(pcall(fn, ...))
  if not r[1] then return 'error', { U.ascii(tostring(r[2])) } end
  if r.n <= 1 then return 'returned_nothing', {} end
  local out, info, any = {}, nil, false
  for i = 2, r.n do
    local v
    v, info = U.dump(r[i], info)
    out[i - 1] = v
    if r[i] ~= nil then any = true end
  end
  if not any then return 'returned_nothing', out end
  if info and (info.secret > 0 or info.opaque > 0) then return 'unreadable', out end
  return 'ok', out
end

local function first(path, ...)
  local code, v = A.Call(path, ...)
  return v and v[1], code, v
end

---------------------------------------------------------------------------
-- T1 client profile
---------------------------------------------------------------------------
function A.T1()
  local _, build = A.Call('GetBuildInfo')
  return {
    build = build,
    projectId = U.dump(NS.G('WOW_PROJECT_ID')),
    projectCamelot = U.dump(NS.G('WOW_PROJECT_CAMELOT')),
    lua = {
      load = type(NS.G('load')), loadstring = type(NS.G('loadstring')),
      tableUnpack = type(table.unpack), bit = type(NS.G('bit')), version = U.dump(NS.G('_VERSION')),
    },
  }
end

---------------------------------------------------------------------------
-- T2 pre-modern versus modern API presence; baseline = GoldIntel evidence [inherited]
---------------------------------------------------------------------------
A.FAMILIES = {
  { 'containers', { 'GetContainerNumSlots', 'GetContainerItemInfo', 'GetContainerItemLink' }, { 'C_Container' }, false },
  { 'skilllines', { 'GetNumSkillLines', 'GetSkillLineInfo', 'ExpandSkillHeader' }, { 'GetProfessions', 'GetProfessionInfo' }, false },
  { 'tradeskill', { 'GetTradeSkillInfo', 'GetNumTradeSkills', 'GetCraftInfo' }, { 'C_TradeSkillUI' }, false },
  { 'auction', { 'QueryAuctionItems', 'GetAuctionItemInfo', 'GetNumAuctionItems' }, { 'C_AuctionHouse' }, false },
  { 'addoninfo', { 'GetAddOnInfo' }, { 'C_AddOns' }, false },
  { 'addonmeta', { 'GetAddOnMetadata', 'IsAddOnLoaded' }, { 'C_AddOns.GetAddOnMetadata' }, nil },
  { 'spell', { 'GetSpellInfo' }, { 'C_Spell.GetSpellName', 'C_Spell.GetSpellInfo' }, nil },
  { 'item', { 'GetItemInfo', 'GetItemInfoInstant' }, { 'C_Item' }, true },
  { 'questlog', { 'GetQuestLogTitle', 'GetNumQuestLogEntries' }, { 'C_QuestLog' }, nil },
  { 'reputation', { 'GetFactionInfo', 'GetNumFactions' }, { 'C_Reputation' }, nil },
  { 'talents', { 'GetTalentInfo', 'GetNumTalentTabs' }, { 'C_ClassTalents', 'C_Traits' }, nil },
  { 'currency', { 'GetCurrencyInfo' }, { 'C_CurrencyInfo' }, nil },
  { 'mail', { 'GetInboxHeaderInfo', 'TakeInboxMoney' }, { 'C_Mail' }, true },
  { 'playedtime', { 'RequestTimePlayed' }, {}, nil },      -- presence only, never called
}

function A.T2(run)
  local out = {}
  for _, fam in ipairs(A.FAMILIES) do
    local row = { pre = {}, modern = {} }
    local allPre, anyPre = true, false
    for _, n in ipairs(fam[2]) do
      local present = U.path(n) ~= nil
      row.pre[n] = present
      if present then anyPre = true else allPre = false end
    end
    for _, n in ipairs(fam[3]) do row.modern[n] = U.path(n) ~= nil end
    if fam[4] ~= nil then
      row.baseline = fam[4]
      -- baseline absent: any pre-modern name that appears is a change; baseline present: any that vanished is
      local changed = (fam[4] == false and anyPre) or (fam[4] == true and not allPre)
      if changed then
        row.changed = true
        NS.Run.Unexpected('baseline_changed', fam[1] .. ': pre-modern ' .. (anyPre and 'present' or 'absent'), run)
      end
    end
    out[fam[1]] = row
  end
  return out
end

---------------------------------------------------------------------------
-- T3 identity
---------------------------------------------------------------------------
function A.T3(run)
  local guid = first('UnitGUID', 'player')
  local _, names = A.Call('UnitName', 'player')
  local realm = first('GetRealmName')
  local nrealm = first('GetNormalizedRealmName')
  local t = { guid = guid, name = names and names[1], name2 = names and names[2], realm = realm, normalizedRealm = nrealm }
  if t.name == 'Unknown' or t.name == nil then NS.Run.Unexpected('name_unknown', tostring(t.name), run) end
  if type(guid) ~= 'string' then NS.Run.Unexpected('guid_missing', tostring(guid), run) end
  return t
end

---------------------------------------------------------------------------
-- T4 DataStore presence
---------------------------------------------------------------------------
A.ADDONS = { 'AddonFactory', 'DataStore', 'DataStore_Characters', 'DataStore_Containers', 'DataStore_Crafts',
  'DataStore_Inventory', 'DataStore_Mails', 'Altoholic', 'GoldIntel' }

function A.T4()
  local out = { addons = {} }
  for _, name in ipairs(A.ADDONS) do
    local code, info = A.Call('C_AddOns.GetAddOnInfo', name)
    local loaded = first('C_AddOns.IsAddOnLoaded', name)
    local version = first('C_AddOns.GetAddOnMetadata', name, 'Version')
    local reason = info and info[5]
    local exists = code == 'ok' and info and info[1] ~= nil and reason ~= 'MISSING'
    out.addons[name] = {
      state = loaded and 'loaded' or (exists and 'installed' or 'missing'),
      reason = reason, version = version,
    }
  end
  local af = NS.G('AddonFactory')
  if type(af) == 'table' then
    out.addonFactory = { isForever = U.dump(af.isForever), isMainline = U.dump(af.isMainline), buildVersion = U.dump(af.buildVersion) }
  end
  return out
end

---------------------------------------------------------------------------
-- T5 DataStore method surface and cross-check (read-only getters of DataStore's public API)
---------------------------------------------------------------------------
A.DS_METHODS = { 'GetCharacter', 'GetCharacters', 'GetCharacterIDByGUID', 'GetCharacterKey', 'GetModuleLastUpdateByKey',
  'IterateCharacters', 'GetCharacterName', 'GetCharacterLevel', 'GetCharacterClass', 'GetMoney', 'GetRestXP',
  'IsResting', 'GetLastLogout', 'GetContainerItemCount', 'GetProfessions', 'GetProfessionInfo' }

local function dsCall(ds, m, ...)
  local f = ds[m]
  if type(f) ~= 'function' then return 'not_found' end
  local r = U.pack(pcall(f, ds, ...))
  if not r[1] then return 'error', U.ascii(tostring(r[2])) end
  return 'ok', r[2], r[3], r[4]
end
A.dsCall = dsCall

-- First carried item and its count over bags 0..5 (C_Container).
local function carriedSample()
  local cc = NS.G('C_Container')
  if type(cc) ~= 'table' then return nil end
  local id, total
  for bag = 0, 5 do
    local okn, slots = pcall(cc.GetContainerNumSlots, bag)
    if okn and type(slots) == 'number' then
      for slot = 1, slots do
        local oki, info = pcall(cc.GetContainerItemInfo, bag, slot)
        if oki and type(info) == 'table' and type(info.itemID) == 'number' and not U.isSecret(info.itemID) then
          if not id then id, total = info.itemID, 0 end
          if info.itemID == id then total = total + (tonumber(info.stackCount) or 1) end
        end
      end
    end
  end
  return id, total
end

function A.T5(run, ident)
  local ds = NS.G('DataStore')
  if type(ds) ~= 'table' then return { present = false } end
  local out = { present = true, methods = {}, cross = {} }
  for _, m in ipairs(A.DS_METHODS) do
    local ok, f = pcall(function() return ds[m] end)
    out.methods[m] = (ok and type(f) == 'function') and true or false
    if not out.methods[m] then NS.Run.Unexpected('ds_method_missing', m, run) end
  end
  local _, key = dsCall(ds, 'GetCharacter')
  out.key = U.dump(key)
  if ident and ident.guid then
    local _, id = dsCall(ds, 'GetCharacterIDByGUID', ident.guid)
    local _, keyById = dsCall(ds, 'GetCharacterKey', id)
    out.idByGuid = U.dump(id)
    out.keyByGuid = U.dump(keyById)
    if keyById ~= key then NS.Run.Unexpected('ds_guid_key_mismatch', tostring(keyById) .. ' vs ' .. tostring(key), run) end
  end
  if type(key) == 'string' then
    local function cross(label, dsValue, live)
      local equal = (dsValue == live)
      out.cross[label] = { datastore = U.dump(dsValue), live = U.dump(live), equal = equal }
      if not equal then NS.Run.Unexpected('ds_' .. label .. '_mismatch', tostring(dsValue) .. ' vs ' .. tostring(live), run) end
    end
    local _, dsMoney = dsCall(ds, 'GetMoney', key)
    cross('money', dsMoney, first('GetMoney'))
    local _, dsLevel = dsCall(ds, 'GetCharacterLevel', key)
    cross('level', dsLevel, first('UnitLevel', 'player'))
    local _, _, dsClass = dsCall(ds, 'GetCharacterClass', key)
    local _, liveClass = A.Call('UnitClass', 'player')
    cross('class', dsClass, liveClass and liveClass[2])
    local _, dsRest = dsCall(ds, 'GetRestXP', key)
    out.cross.restXP = { datastore = U.dump(dsRest), live = U.dump((first('GetXPExhaustion'))) }   -- informational: DataStore calls it unreliable
    local itemID, liveCount = carriedSample()
    if itemID then
      local _, bags, bank, reagent = dsCall(ds, 'GetContainerItemCount', key, itemID)
      local dsCount = (tonumber(bags) or 0) + (tonumber(reagent) or 0)
      cross('itemCount', dsCount, liveCount)
      out.cross.itemCount.itemID = itemID
      out.cross.itemCount.bank = U.dump(bank)
    end
  end
  return out
end

---------------------------------------------------------------------------
-- T6 DataStore roster health
---------------------------------------------------------------------------
function A.T6(run)
  local ds = NS.G('DataStore')
  if type(ds) ~= 'table' then return { present = false } end
  local out = { present = true, chars = {}, unknownNames = 0, duplicateGuids = 0 }
  local guids = NS.G('DataStore_CharacterGUIDs')       -- read only
  local seenGuid = {}
  local n = 0
  local ok = pcall(ds.IterateCharacters, ds, function(key, id)
    n = n + 1
    if n > 60 then return end
    local acct, realm, name = string.match(tostring(key), '^([^%.]*)%.([^%.]*)%.(.*)$')
    local _, level = dsCall(ds, 'GetCharacterLevel', key)
    local _, _, token = dsCall(ds, 'GetCharacterClass', key)
    local _, last = dsCall(ds, 'GetModuleLastUpdateByKey', 'DataStore_Characters', key)
    local guid = type(guids) == 'table' and guids[id] or nil
    local row = { key = U.ascii(tostring(key)), account = acct, realm = realm, name = name, level = U.dump(level),
      class = U.dump(token), lastUpdate = U.dump(last), guid = U.dump(guid) }
    if name == 'Unknown' then out.unknownNames = out.unknownNames + 1 end
    if guid and seenGuid[guid] then out.duplicateGuids = out.duplicateGuids + 1; row.duplicate = true end
    if guid then seenGuid[guid] = true end
    table.insert(out.chars, row)
  end)
  if not ok then NS.Run.Unexpected('ds_iterate_failed', 'IterateCharacters', run) end
  out.count = n
  if out.unknownNames > 0 then NS.Run.Unexpected('ds_unknown_name', tostring(out.unknownNames), run) end
  if out.duplicateGuids > 0 then NS.Run.Unexpected('ds_duplicate_guid', tostring(out.duplicateGuids), run) end
  return out
end

---------------------------------------------------------------------------
-- T7 bank read, polled once per second; records the first open per character per session
---------------------------------------------------------------------------
A.bankDone = false

function A.PollBank()
  if A.bankDone then return end
  local bf = NS.G('BankFrame')
  if type(bf) ~= 'table' or type(bf.IsShown) ~= 'function' then return end
  local ok, shown = pcall(bf.IsShown, bf)
  if not ok or not shown then return end
  A.bankDone = true
  local cc = NS.G('C_Container')
  local rec = { at = U.wall(), bags = {} }
  local ids = {}
  local bankId = NS.G('BANK_CONTAINER')
  local enum = U.path('Enum.BagIndex.Bank')
  table.insert(ids, type(bankId) == 'number' and bankId or (type(enum) == 'number' and enum or -1))
  local nb, nbank = NS.G('NUM_BAG_SLOTS'), NS.G('NUM_BANKBAGSLOTS')
  rec.NUM_BAG_SLOTS, rec.NUM_BANKBAGSLOTS = U.dump(nb), U.dump(nbank)
  if type(nb) == 'number' and type(nbank) == 'number' then
    for i = nb + 1, nb + nbank do table.insert(ids, i) end
  end
  for _, id in ipairs(ids) do
    local row = {}
    if type(cc) == 'table' then
      local oks, slots = pcall(cc.GetContainerNumSlots, id)
      row.slots = oks and U.dump(slots) or 'error'
      local okf, free = pcall(cc.GetContainerNumFreeSlots, id)
      row.free = okf and U.dump(free) or 'error'
      if oks and type(slots) == 'number' and slots > 0 then
        local oki, info = pcall(cc.GetContainerItemInfo, id, 1)
        row.slot1 = oki and U.dump(info) or 'error'
      end
    end
    rec.bags[tostring(id)] = row
  end
  local guid = first('UnitGUID', 'player')
  if guid then NS.Core.DB().bank[guid] = rec end
end
