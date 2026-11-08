--[[
EmpireIntel / Tests / helpers / fakeclient.lua

A fake WoW Forever client for EmpireIntelCheck. The base profile follows GoldIntel's beta evidence
[inherited]: modern API only, pre-modern globals absent, Interface 16001, project id 18.

Options (all optional):
  legacy    = 'none' | 'getters'      'getters' adds a FAKE Legacy namespace C_LegacyFixture, a frame
                                      LegacyFixtureFrame, an Enum and a string. These names are test
                                      fixtures only; they never appear in shipped code.
  datastore = nil | 'good' | 'faulty' | 'throws' | 'nolist' | 'charsonly'
  legacy25  = 'ids' | 'list'          unlocked level-25 profile with achievement and currency getters (use with launch)
  docs      = true                    a loadable Blizzard API documentation addon with one Legacy system
  precise   = number                  provide debugprofilestop; each call advances it by this many ms
  char      = table                   overrides for the character
  db        = table                   saved EmpireIntelCheckDB from an earlier session
  extraGlobals = number               add this many dummy globals (scheduler spreading tests)
  premodern = true                    put GetContainerNumSlots back (baseline change)
]]

local F = {}
F.NIL = {}        -- marker: set this character field to nil (a Lua table cannot hold nil)

local function newFrame(W, name)
  local f = { name = name, scripts = {}, hooks = {}, events = {}, shown = false }
  function f:SetScript(kind, fn) self.scripts[kind] = fn end
  function f:GetScript(kind) return self.scripts[kind] end
  function f:HookScript(kind, fn)
    self.hooks[kind] = self.hooks[kind] or {}
    table.insert(self.hooks[kind], fn)
    W.hookCount = W.hookCount + 1
  end
  function f:RegisterEvent(ev)
    self.events[ev] = true
    W.registered[ev] = true
  end
  function f:UnregisterEvent(ev) self.events[ev] = nil end
  function f:IsShown() return self.shown end
  function f:IsVisible() return self.shown and not self.parentHidden end
  function f:GetObjectType() return 'Frame' end
  function f:Show()
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
    for _, h in ipairs(self.hooks.OnShow or {}) do h(self) end
  end
  function f:Hide() self.shown = false end
  return f
end

function F.new(opts)
  opts = opts or {}
  local env = {}
  local W = { env = env, t = 1000, wall = 1800000000, frames = {}, chat = {}, calls = {}, registered = {},
    combat = false, hookCount = 0, ms = 0, SECRET = {} }
  local char = { guid = 'Player-1-00000001', first = 'Testchar', last = 'Tester', class = 'WARRIOR',
    classLoc = 'Warrior', classId = 1, level = 10, xp = 100, xpMax = 10000, rest = 0, resting = false,
    money = 1234, profIdx = {}, profs = {} }
  for k, v in pairs(opts.char or {}) do if v == F.NIL then char[k] = nil else char[k] = v end end
  W.char = char
  W.bags = { [0] = { { 6948, 1 }, { 2589, 5 }, { 2589, 3 } } }
  W.bankShown = false
  W.addons = { { name = 'GoldIntel', loaded = true } }

  local function rec(name) W.calls[name] = (W.calls[name] or 0) + 1 end

  env._VERSION = 'Lua 5.1'
  env.GetTime = function() return W.t end
  env.time = function() return W.wall end
  if opts.precise then
    env.debugprofilestop = function() W.ms = W.ms + opts.precise; return W.ms end
  end
  env.GetBuildInfo = function() return '1.60.1', '70450', 'Oct 17 2026', 16001 end
  env.WOW_PROJECT_ID = 18
  env.WOW_PROJECT_CAMELOT = 18
  env.loadstring = loadstring or load
  env.bit = {}
  env.UnitGUID = function(u) if u == 'player' then return char.guid end end
  env.UnitName = function() return char.first, char.last end
  env.UnitClass = function() return char.classLoc, char.class, char.classId end
  env.UnitLevel = function() return char.level end
  env.UnitXP = function() return char.xp end
  env.UnitXPMax = function() return char.xpMax end
  env.GetXPExhaustion = function() return char.rest end
  env.IsResting = function() return char.resting end
  env.GetRestState = function() return 1, 'Rested', 2 end
  env.GetMoney = function() return char.money end
  env.GetRealmName = function() return 'Test Realm' end
  env.GetNormalizedRealmName = function() return 'TestRealm' end
  env.InCombatLockdown = function() return W.combat end
  env.issecretvalue = function(v) return v == W.SECRET end
  env.GetProfessions = function() return char.profIdx[1], char.profIdx[2], nil, nil, nil end
  env.GetProfessionInfo = function(i)
    local p = char.profs[i]
    if p then return p.name, 136240, p.skill, 300, 0, 0, p.line, 0 end
  end
  env.GetItemInfo = function() end
  env.GetItemInfoInstant = function() end
  env.GetInboxHeaderInfo = function() end
  env.TakeInboxMoney = function() end
  env.Enum = { BagIndex = { Bank = -1 }, ItemQuality = { Poor = 0, Common = 1 } }
  env.C_EventUtils = { IsEventValid = function(n) return type(n) == 'string' and n ~= 'BOGUS_EVENT' end }
  env.C_Container = {
    GetContainerNumSlots = function(b) return W.bags[b] and #W.bags[b] or 0 end,
    GetContainerItemInfo = function(b, s)
      local it = W.bags[b] and W.bags[b][s]
      if it then return { itemID = it[1], stackCount = it[2] } end
    end,
    GetContainerNumFreeSlots = function() return 3, 0 end,
  }
  if opts.premodern then env.GetContainerNumSlots = function() return 16 end end
  env.C_AddOns = {
    GetNumAddOns = function() return #W.addons end,
    GetAddOnInfo = function(x)
      local a
      if type(x) == 'number' then a = W.addons[x] else
        for _, v in ipairs(W.addons) do if v.name == x then a = v end end
      end
      if not a then return x, nil, nil, false, 'MISSING' end
      return a.name, a.name, '', true, nil, 'INSECURE'
    end,
    IsAddOnLoaded = function(x)
      for i, v in ipairs(W.addons) do if v.name == x or i == x then return v.loaded end end
      return false
    end,
    IsAddOnLoadOnDemand = function() return false end,
    GetAddOnMetadata = function(x, f) if f == 'Version' then return '1.0' end end,
    LoadAddOn = function(name)
      rec('LoadAddOn:' .. tostring(name))
      if opts.docs and name == 'Blizzard_APIDocumentationGenerated' then env.APIDocumentation = W.docsTable; return true end
      return false, 'MISSING'
    end,
  }
  if opts.docs then
    table.insert(W.addons, { name = 'Blizzard_APIDocumentationGenerated', loaded = false })
    W.docsTable = { systems = {
      { Name = 'LegacyFixture', Namespace = 'C_LegacyFixture',
        Functions = {
          { Name = 'GetArgNeeded', Arguments = { { Name = 'id', Type = 'number', Nilable = false } } },
          { Name = 'GetPoints', Arguments = {}, Returns = { { Name = 'points', Type = 'number', Nilable = false } } },
          { Name = 'GetGone', Arguments = {} },
        },
        Events = { { Name = 'LegacyFixturePointsChanged', LiteralName = 'LEGACY_FIXTURE_POINTS_CHANGED', Payload = {} } } },
      { Name = 'Other', Namespace = 'C_Other', Functions = { { Name = 'GetX', Arguments = {} } } },
    } }
  end
  env.C_Item = { GetItemInfo = function() end }
  env.C_Mail = { HasInboxMoney = function() end }
  env.C_Spell = { GetSpellName = function() end }
  env.C_Map = { GetBestMapForUnit = function() end }
  env.C_AuctionHouse = { GetNumBids = function() end }
  env.C_TradeSkillUI = { GetTradeSkillLine = function() end }
  env.C_QuestLog = { GetInfo = function() end }
  env.C_Loot = { IsLegacyLootModeEnabled = function() rec('C_Loot.IsLegacyLootModeEnabled'); return false end }
  env.C_ChallengeMode = { GetMapTable = function() rec('C_ChallengeMode.GetMapTable'); return { 1, 2 } end }
  env.SlashCmdList = {}
  env.DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) table.insert(W.chat, m) end }
  env.print = function() end
  env.CreateFrame = function(_, name)
    local f = newFrame(W, name)
    table.insert(W.frames, f)
    return f
  end
  env.BankFrame = newFrame(W, 'BankFrame')
  env.BANK_CONTAINER = -1
  env.NUM_BAG_SLOTS = 4
  env.NUM_BANKBAGSLOTS = 2
  env.GoldIntelDB = { schema = 2, ledger = { entries = { 1, 2, 3 } } }
  env.GoldIntelCharDB = { lastMoney = 99 }

  if opts.legacy == 'getters' then
    local big = {}
    for i = 1, 300 do
      local inner = {}
      for j = 1, 200 do inner[j] = string.rep('x', 150) end
      big[i] = inner
    end
    env.C_LegacyFixture = {
      GetPoints = function() rec('GetPoints'); return 7 end,
      GetCap = function() rec('GetCap'); return 16 end,
      IsUnlocked = function() rec('IsUnlocked'); return false end,
      HasPerk = function() rec('HasPerk'); return true end,
      GetNothing = function() rec('GetNothing') end,
      GetNilOnly = function() rec('GetNilOnly'); return nil end,
      GetSecret = function() rec('GetSecret'); return W.SECRET end,
      GetThread = function() rec('GetThread'); return coroutine.create(function() end) end,
      GetBoom = function() rec('GetBoom'); error('boom') end,
      GetProtected = function()
        rec('GetProtected')
        W:fire('ADDON_ACTION_FORBIDDEN', 'EmpireIntelCheck', 'C_LegacyFixture.GetProtected()')
      end,
      GetGuarded = function() rec('GetGuarded'); error('Interface action failed: protected function') end,
      GetBig = function() rec('GetBig'); return big end,
      GetArgNeeded = function(id) rec('GetArgNeeded'); if id == nil then error('id required') end; return id end,
      SetPoints = function() rec('SetPoints') end,
      SpendPoint = function() rec('SpendPoint') end,
      GetResetCost = function() rec('GetResetCost'); return 5 end,
      GetBuyPrice = function() rec('GetBuyPrice'); return 5 end,
      LearnPerk = function() rec('LearnPerk') end,
      PurchaseRank = function() rec('PurchaseRank') end,
    }
    env.LegacyFixtureFrame = newFrame(W, 'LegacyFixtureFrame')
    env.Enum.LegacyFixtureTree = { Professions = 1, Adventure = 2, Resourcefulness = 3 }
    env.LEGACY_FIXTURE_TITLE = 'Legacy'
  end

  if opts.launch then
    -- retail look-alikes seen on the launch build (TP1_Report_Run1.md); none may count
    local mixin = {}
    for _, m in ipairs({ 'GetText', 'GetColor', 'IsEnabled', 'GetDifficultyID' }) do
      mixin[m] = function() rec('raid.' .. m); return m == 'GetText' and '10 Player' or 1 end
    end
    env.UnitPopupLegacyRaidDifficulty1ButtonMixin = mixin
    env.GetLegacyRaidDifficultyID = function() rec('GetLegacyRaidDifficultyID'); return 0 end
    env.C_FriendList = { IsLegacyFriendSystemEnabled = function() rec('legacyFriend'); return false end }
    env.C_GameRules = { GetForeverExperiencePreset = function() rec('GetForeverExperiencePreset'); return 1 end,
      SetForeverExperiencePresetPostLogin = function() rec('SetForeverExperiencePresetPostLogin') end }
    local guild = newFrame(W, 'CommunitiesFrameGuildDetailsFrameInfoChallenge1')
    guild.shown = true; guild.parentHidden = true          -- shown but not visible, as on the launch build
    env.CommunitiesFrameGuildDetailsFrameInfoChallenge1 = guild
    -- the Forever Legacy UI, locked
    W.unlocked = false
    env.LegacyMicroButtonMixin = { IsLegacySystemUnlocked = function() rec('IsLegacySystemUnlocked'); return W.unlocked end,
      OnClick = function() rec('legacy.OnClick') end }
    env.LegacyChallengeViewedUtil = { HasAnyUnviewedChallenges = function() return false end }
    env.ToggleLegacySystemUI = function() rec('ToggleLegacySystemUI') end
    env.LegacySystemFrame_LoadUI = function() rec('LegacySystemFrame_LoadUI') end
    local btn = newFrame(W, 'LegacyMicroButton'); btn.shown = true
    function btn:GetObjectType() return 'Button' end
    env.LegacyMicroButton = btn
    env.LEGACY_MICRO_BUTTON_LOCKED_TOOLTIP = 'This feature becomes available when your first character reaches level 25.'
    -- retail enums with a member literally named Legacy (launch-build run 2, defect 8)
    env.Enum.NamePlateStyle = { Modern = 1, Legacy = 5 }
    env.Enum.RespecType = { Talents = 1, Legacy = 4 }
    env.Enum.BnetAccountFlag = { IsLegacy = 131072 }
  end
  if opts.legacy25 then
    -- the level-25 profile as run 7 saw it (EI-E-20, EI-E-21): GetCategoryList returns only the Legacy categories, none
    -- titled "Legacy", plus two the pane hides; the points are a trait currency from LegacySystem.GetCurrencyInfo().
    -- 'ids': with the LegacySystem table (pane opened); 'list': without it (pane not opened yet).
    W.unlocked = true
    W.badArgs, W.argCalls = 0, 0
    local known = { [15568] = true, [15580] = true, [15593] = true, [15594] = true, [15626] = true, [15425] = true, [15430] = true, [50050] = true,
      [50001] = true, [50002] = true, [50010] = true, [50020] = true, [50030] = true, [50040] = true }
    local function arg(v, max)
      W.argCalls = W.argCalls + 1
      if type(v) ~= 'number' or not (known[v] or (max and v >= 1 and v <= max)) then W.badArgs = W.badArgs + 1 end
    end
    local cats = { [15568] = { 'Classes', -1 }, [15580] = { 'Paladin', 15568 }, [15593] = { 'Dungeons', -1 }, [15594] = { 'Raids', -1 },
      [15626] = { 'Tier 1 Gear', 15594 }, [15425] = { 'Do Not Display', -1 }, [15430] = { 'Odd Child', 15425 } }
    local ach = {
      [50001] = { 50001, 'Paladin: Level 25', 1, true, 11, 7, 26, 'Reach level 25 with a Paladin.', 0, 1, 'Legacy Point', false, true, 'Someone Name', false },
      [50002] = { 50002, 'Paladin: Level 45', 1, false, nil, nil, nil, 'Reach level 45 with a Paladin.', 0, 1, 'Legacy Point', false, false, nil, false },
      [50010] = { 50010, 'Novice Spelunker', 1, false, nil, nil, nil, 'Complete these dungeons.', 0, 1, 'Legacy Point', false, false, nil, false },
      [50020] = { 50020, 'Conqueror of the Lair', 1, false, nil, nil, nil, 'Defeat Onyxia.', 0, 1, 'Legacy Point', false, false, nil, false },
      [50030] = { 50030, 'Tier 1 Helm', 0, true, 11, 8, 26, 'hidden', 0, 1, '', false, true, nil, false },
      [50040] = { 50040, 'Internal', 5, true, 11, 8, 26, 'hidden', 0, 1, '', false, true, nil, false },
      [50050] = { 50050, 'Internal child', 2, false, nil, nil, nil, 'hidden', 0, 1, '', false, false, nil, false },
    }
    local inCat = { [15580] = { 50001, 50002 }, [15593] = { 50010 }, [15594] = { 50020 }, [15626] = { 50030 }, [15425] = { 50040 }, [15430] = { 50050 } }
    local function unpackT(t, i, n) if i > n then return end return t[i], unpackT(t, i + 1, n) end
    env.GetCategoryList = function() rec('GetCategoryList'); return { 15425, 15580, 15568, 15593, 15594, 15626, 15430 } end
    env.GetCategoryInfo = function(id)
      arg(id); rec('GetCategoryInfo')
      W.inFlightSeen = env.EmpireIntelCheckDB.inFlight and env.EmpireIntelCheckDB.inFlight.name
      local c = cats[id]; if c then return c[1], c[2], 0 end
    end
    env.GetCategoryNumAchievements = function(id)
      arg(id); rec('GetCategoryNumAchievements')
      local l = inCat[id] or {}
      local done = 0
      for _, a in ipairs(l) do if ach[a][4] then done = done + 1 end end
      return #l, done, #l - done
    end
    env.GetAchievementInfo = function(a, b)
      rec('GetAchievementInfo')
      local id
      if b ~= nil then arg(a); arg(b, 2); id = inCat[a] and inCat[a][b] else arg(a); id = a end
      local t = id and ach[id]
      if t then return unpackT(t, 1, 15) end
    end
    env.GetAchievementNumCriteria = function(id) arg(id); rec('GetAchievementNumCriteria'); return id == 50010 and 2 or 0 end
    env.GetAchievementCriteriaInfo = function(id, i)
      arg(id); arg(i, 2); rec('GetAchievementCriteriaInfo')
      if id == 50010 and i == 1 then return 'Ragefire Chasm', 8, true, 1, 1, 'Someone Name', 0, 389, '1/1', 777, true end
      if id == 50010 and i == 2 then return 'Wailing Caverns', 8, false, 0, 1, nil, 0, 43, '0/1', 778, true end
    end
    local legacyPoints = { name = 'Legacy Points', quantity = 1, maxQuantity = 16, totalEarned = 1, isAccountWide = true, iconFileID = 4567 }
    env.C_CurrencyInfo = {
      GetCurrencyInfo = function(id) arg(id); rec('C_CurrencyInfo.GetCurrencyInfo'); if id == 4225 then W.traitToCurrency = true end end,
      GetCurrencyListSize = function() rec('C_CurrencyInfo.GetCurrencyListSize'); return 2 end,
      GetCurrencyListInfo = function(i)
        arg(i, 2); rec('C_CurrencyInfo.GetCurrencyListInfo')
        if i == 1 then return { name = 'Honor', quantity = 50 } end
        if i == 2 then return legacyPoints end
      end,
      SetCurrencyBackpack = function() rec('SetCurrencyBackpack!') end,
    }
    if opts.legacy25 == 'ids' then
      env.LegacySystem = {
        GetCurrencyInfo = function() rec('LegacySystem.GetCurrencyInfo')
          return { quantity = 1, maxQuantity = 1, renownCurrency = 1, spent = 0, spentInTree = 0, traitCurrencyID = 4225 } end,
        GetFilteredChallenges = function() rec('LegacySystem.GetFilteredChallenges'); return {} end,
        GetChallengeIndices = function() error('Usage: GetCategoryNumAchievements(categoryID, includeSuperceded)') end,
      }
    end
  end
  if opts.undoc then
    -- undocumented namespaces (EI-E-12); fixture behaviour only
    env.C_Seasons = {
      GetActiveSeason = function() rec('C_Seasons.GetActiveSeason'); W.inFlightSeen = env.EmpireIntelCheckDB.inFlight and env.EmpireIntelCheckDB.inFlight.name; return 2 end,
      HasActiveSeason = function() rec('C_Seasons.HasActiveSeason'); return true end,
      IsSeasonOpen = function() rec('C_Seasons.IsSeasonOpen'); return true end,
      RequestSeasonInfo = function() rec('C_Seasons.RequestSeasonInfo') end,
      SetSeason = function() rec('C_Seasons.SetSeason') end,
    }
    env.C_Trophy = {
      GetTrophyListInfo = function() rec('C_Trophy.GetTrophyListInfo') end,
      GetTrophyByIndex = function(i) rec('C_Trophy.GetTrophyByIndex'); if i == nil then error('index required') end end,
      ShowTrophy = function() rec('C_Trophy.ShowTrophy') end,
      ClaimTrophy = function() rec('C_Trophy.ClaimTrophy') end,
    }
    env.C_Reincarnation = {
      GetReincarnationInfo = function() rec('C_Reincarnation.GetReincarnationInfo'); return 1 end,
      Reincarnate = function() rec('C_Reincarnation.Reincarnate') end,
    }
    env.C_AccountServices = { GetAccountThing = function() rec('C_AccountServices.GetAccountThing'); return 1 end }
    env.C_Debug = { GetDebugThing = function() rec('C_Debug.GetDebugThing'); return 1 end }
    env.C_NewSecretThing = { GetX = function() rec('C_NewSecretThing.GetX'); return 1 end }
  end
  if opts.bugs then
    env.BugGrabberDB = { errors = {
      { message = 'Interface/AddOns/EmpireIntelCheck/Run.lua:10: attempt to index a nil value', stack = '', counter = 2, session = 1 },
      { message = 'Interface/AddOns/ElvUI/Core.lua:5: something', stack = '', counter = 1, session = 1, locals = 'SENTINEL_LOCALS_42 Player-1-00000001' },
    } }
  end

  if opts.datastore then
    local faulty = opts.datastore == 'faulty'
    local key = 'Default.Test Realm.' .. char.first .. ' ' .. char.last
    local ds = {}
    W.dsKey = key
    function ds:GetCharacter() return key end
    function ds:GetCharacters() return { [char.first .. ' ' .. char.last] = key } end
    function ds:GetCharacterIDByGUID(g) if g == char.guid then return 1 end end
    function ds:GetCharacterKey(id) if id == 1 then return key end; if id == 2 then return 'Default.Test Realm.Alt Two' end end
    function ds:GetModuleLastUpdateByKey() return W.wall - 3600 end
    function ds:GetCharacterName() return char.first end
    function ds:GetCharacterLevel(k) if k == key then return char.level end; if k == 'Default.Test Realm.Alt Two' then return 45 end; return 12 end
    function ds:GetCharacterClass(k) if k == key then return char.classLoc, char.class, char.classId end; return 'Mage', 'MAGE', 8 end
    function ds:GetMoney() return faulty and (char.money + 5) or char.money end
    if not faulty then function ds:GetRestXP() return char.rest end end
    function ds:IsResting() return char.resting end
    function ds:GetLastLogout(k) if k == key then return 5000000000 end; return W.wall - 60 end   -- DataStore: logged in
    function ds:GetContainerItemCount(_, id)
      local n = 0
      for _, it in ipairs(W.bags[0]) do if it[1] == id then n = n + it[2] end end
      return n, 0, 0
    end
    function ds:GetProfession1Name(k) if k == 'Default.Test Realm.Alt Two' then return 'Tailoring' end; return '' end
    function ds:GetProfession1Rank(k) if k == 'Default.Test Realm.Alt Two' then return 230, 300 end; return 0, 0 end
    function ds:GetProfession2Name() return '' end
    function ds:GetProfession2Rank() return 0, 0 end
    function ds:IterateCharacters(cb)
      cb(key, 1)
      cb('Default.Test Realm.Alt Two', 2)
      if faulty then cb('Default.Test Realm.Unknown', 3) end
    end
    if opts.datastore == 'throws' then
      function ds:GetCharacterLevel(k) if k == key then return char.level end; error('boom in level') end
    elseif opts.datastore == 'nolist' then
      ds.IterateCharacters = nil
    elseif opts.datastore == 'charsonly' then
      for _, m in ipairs({ 'GetProfession1Name', 'GetProfession1Rank', 'GetProfession2Name', 'GetProfession2Rank' }) do ds[m] = nil end
    end
    W.dsWrites = 0
    env.DataStore = setmetatable(ds, { __newindex = function(t, k, v) W.dsWrites = W.dsWrites + 1; rawset(t, k, v) end })
    env.DataStore_CharacterGUIDs = setmetatable({ [1] = char.guid, [2] = 'Player-1-00000002', [3] = faulty and char.guid or nil },
      { __newindex = function(t, k, v) W.dsWrites = W.dsWrites + 1; rawset(t, k, v) end })
    env.AddonFactory = { isForever = true, isMainline = true, buildVersion = 16001 }
    for _, n in ipairs({ 'AddonFactory', 'DataStore', 'DataStore_Characters', 'DataStore_Containers', 'Altoholic' }) do
      table.insert(W.addons, { name = n, loaded = true })
    end
  end

  if opts.ctimer then
    -- a fake C_Timer that records every interval asked for (P2-1: no 0.5 s tick)
    W.tickers, W.timers = {}, {}
    local function sched(list, sec, fn, repeating)
      local t = { sec = sec, fn = fn, due = W.t + sec, repeating = repeating, active = true }
      table.insert(list, t)
      return { Cancel = function() t.active = false end }
    end
    env.C_Timer = {
      NewTicker = function(sec, fn) return sched(W.tickers, sec, fn, true) end,
      NewTimer = function(sec, fn) return sched(W.timers, sec, fn, false) end,
      After = function(sec, fn) sched(W.timers, sec, fn, false) end,
    }
    W.runTimers = function()
      for _, list in ipairs({ W.tickers, W.timers }) do
        for _, t in ipairs(list) do
          if t.active and W.t >= t.due then
            if t.repeating then t.due = t.due + t.sec else t.active = false end
            t.fn()
          end
        end
      end
    end
  end
  for i = 1, (opts.extraGlobals or 0) do env['Dummy' .. i] = i end
  if opts.db then env.EmpireIntelCheckDB = opts.db end
  if opts.eidb then env.EmpireIntelDB = opts.eidb end

  function W:fire(event, ...)
    for _, f in ipairs(self.frames) do
      if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, ...) end
    end
  end

  function W:advance(seconds, step)
    step = step or 0.1
    local n = math.floor(seconds / step + 0.5)
    for _ = 1, n do
      self.t = self.t + step
      self.wall = self.wall + step
      for _, f in ipairs(self.frames) do
        if f.scripts.OnUpdate then f.scripts.OnUpdate(f, step) end
      end
      if self.runTimers then self.runTimers() end
    end
  end

  function W:login()
    self:fire('ADDON_LOADED', 'EmpireIntelCheck')
    self:fire('PLAYER_LOGIN')
    self:fire('PLAYER_ENTERING_WORLD', true, false)
  end

  function W:slash(msg) env.SlashCmdList.EMPIREINTELCHECK(msg) end

  function W:db() return env.EmpireIntelCheckDB end
  function W:lastRun() local db = env.EmpireIntelCheckDB; return db and db.runs[#db.runs] end

  return W
end

-- Load the addon files listed in the TOC into a fresh namespace bound to the fake client.
function F.load(W, root)
  root = root or F.root
  local NS = { env = W.env }
  local toc = io.open(root .. '/EmpireIntelCheck/EmpireIntelCheck.toc', 'r')
  local files = {}
  for line in toc:lines() do
    line = line:gsub('\r', '')
    if line ~= '' and not line:find('^#') then table.insert(files, line) end
  end
  toc:close()
  for _, file in ipairs(files) do
    local chunk, err = loadfile(root .. '/EmpireIntelCheck/' .. file)
    if not chunk then error(err) end
    chunk('EmpireIntelCheck', NS)
  end
  W.NS = NS
  return NS, files
end

-- Load an addon folder (EmpireIntel) into a fresh namespace bound to the fake client.
function F.loadAddon(W, folder, root)
  root = root or F.root
  local EI = { Platform = { env = W.env } }
  local toc = io.open(root .. '/' .. folder .. '/' .. folder .. '.toc', 'r')
  local files = {}
  for line in toc:lines() do
    line = line:gsub('\r', '')
    if line ~= '' and not line:find('^#') then table.insert(files, line) end
  end
  toc:close()
  for _, file in ipairs(files) do
    local chunk, err = loadfile(root .. '/' .. folder .. '/' .. file)
    if not chunk then error(err) end
    chunk(folder, EI)
  end
  W.EI = EI
  return EI, files
end

-- Login, wait for the delay and let every queued job finish.
function F.session(opts)
  local W = F.new(opts)
  F.load(W)
  W:login()
  W:advance(12)
  W:advance(30)
  return W
end

return F
