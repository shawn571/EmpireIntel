-- EmpireIntel / Tests / test_ei_static.lua
-- File rules for the EmpireIntel addon (C-1..C-6 as in GoldIntel D-024/D-025) and the P2-1 rules:
-- WoW API only through P.env (Platform), RegisterEvent only in Platform/Events.lua, no 0.5 s tick.
local T, F, root = ...

local DIR = root .. '/EmpireIntel/'
local function read(path)
  local f = assert(io.open(path, 'rb'))
  local s = f:read('*a')
  f:close()
  return s
end
local _, FILES = F.loadAddon(F.new(), 'EmpireIntel')

local ALLOWED = { type = true, pairs = true, ipairs = true, next = true, pcall = true, select = true, tostring = true,
  tonumber = true, string = true, table = true, math = true, error = true, assert = true, coroutine = true }

local function luacGlobals(path)
  local p = io.popen('luac5.1 -p -l "' .. path .. '" 2>/dev/null')
  if not p then return nil end
  local out = p:read('*a')
  p:close()
  if out == '' then return nil end
  local get, set = {}, {}
  for op, name in out:gmatch('([GS]ETGLOBAL)%s+[%-%d]+%s+[%-%d]+%s+; ([%w_]+)') do
    if op == 'GETGLOBAL' then get[name] = true else set[name] = true end
  end
  return get, set
end

T.describe('EmpireIntel static rules', function()
  T.it('TOC: Interface 16001, version 0.7.5, one saved variable, forward slashes, files exist', function()
    local toc = read(DIR .. 'EmpireIntel.toc')
    T.truthy(toc:find('^## Interface: 16001\n'))
    T.truthy(toc:find('## Version: 0.7.5', 1, true))
    T.truthy(toc:find('## SavedVariables: EmpireIntelDB\n', 1, true))
    T.falsy(toc:find('SavedVariablesPerCharacter', 1, true), 'format 1 is account-wide only')
    T.falsy(toc:find('Dependencies', 1, true))
    for line in toc:gmatch('[^\n]+') do
      if line:sub(1, 2) ~= '##' then
        T.falsy(line:find('\\', 1, true))
        T.truthy(io.open(DIR .. line), 'exists: ' .. line)
      end
    end
  end)
  for _, file in ipairs(FILES) do
    local src = read(DIR .. file)
    T.it(file .. ': ASCII, LF, final newline, no long brackets, header line', function()
      T.falsy(src:find('[\128-\255]'))
      T.falsy(src:find('\r', 1, true))
      T.eq(src:sub(-1), '\n')
      T.falsy(src:find('%[%[') or src:find('%[=+%['))
      T.eq(src:match('^[^\n]*'), 'local ADDON, EI = ...')
    end)
    T.it(file .. ': no bare WoW global, no global assignment', function()
      local get, set = luacGlobals(DIR .. file)
      if not get then print('      (skip: luac5.1 not available)'); return end
      for name in pairs(get) do
        if not ALLOWED[name] then T.truthy(name == '_G' and file == 'Platform/Platform.lua', 'bare global ' .. name .. ' in ' .. file) end
      end
      T.eq(next(set), nil)
    end)
    T.it(file .. ': RegisterEvent only in Platform/Events.lua; no hooks; no GoldIntel data; no third-party addon', function()
      if file ~= 'Platform/Events.lua' then T.falsy(src:find('RegisterEvent', 1, true)) end
      T.falsy(src:find('hooksecurefunc', 1, true))
      T.falsy(src:find('HookScript', 1, true))
      T.falsy(src:find('GoldIntelDB', 1, true))
      if file ~= 'Bridge/DataStoreBridge.lua' then          -- user-facing text may name DataStore; code may not
        local code = src:gsub('%-%-[^\n]*', ''):gsub("'[^'\n]*'", "''"):gsub('"[^"\n]*"', '""')
        T.falsy(code:find('DataStore', 1, true) and not code:find('EI%.DataStoreBridge'), 'only Bridge/ touches DataStore: ' .. file)
        T.falsy(code:find('env%.DataStore'), 'no DataStore access outside Bridge/: ' .. file)
      end
    end)
    T.it(file .. ': no 0.5 s tick (user, Q-P2-1)', function()
      local code = src:gsub('%-%-[^\n]*', '')          -- comments may mention it; code may not
      T.falsy(code:find('P_TICK', 1, true))
    end)
  end

  T.it('Bridge/DataStoreBridge.lua: only the approved read-only getters, no writes into DataStore', function()
    local src = read(DIR .. 'Bridge/DataStoreBridge.lua')
    local code = src:gsub('%-%-[^\n]*', '')
    local approved = { 'IterateCharacters', 'GetCharacterLevel', 'GetCharacterClass', 'GetRestXP', 'IsResting', 'GetLastLogout',
      'GetModuleLastUpdateByKey', 'GetProfession1Name', 'GetProfession1Rank', 'GetProfession2Name', 'GetProfession2Rank',
      'GetCharacterFaction' }   -- the P2-2 list plus GetCharacterFaction (P2-4b, D-059)
    local ok = {}
    for _, m in ipairs(approved) do ok[m] = true end
    -- the ALLOWED table lists exactly the approved names
    local block = code:match('B%.ALLOWED = (%b{})')
    T.truthy(block, 'ALLOWED table found')
    local listed = {}
    for name in block:gmatch('([%w_]+) = true') do listed[name] = true; T.truthy(ok[name], 'not approved: ' .. name) end
    for _, m in ipairs(approved) do T.truthy(listed[m], 'missing from ALLOWED: ' .. m) end
    -- every name passed to dsCall is approved (the Profession names are built from 1..2)
    for name in code:gmatch("dsCall%(ds, errs, '([%w_]+)'[,%)]") do T.truthy(ok[name], 'dsCall of ' .. name) end
    for name in code:gmatch("'GetProfession' %.%. i %.%. '([%w_]+)'") do T.truthy(ok['GetProfession1' .. name], name) end
    -- nothing that scans, sets, requests or deletes; no assignment into the DataStore tables
    for _, bad in ipairs({ 'Set', 'Scan', 'Request', 'Delete', 'Clear', 'Import', 'Broadcast', 'RegisterEvent', 'SendMessage' }) do
      T.falsy(code:find("'" .. bad, 1, true) or code:find(':' .. bad, 1, true), bad)
    end
    T.falsy(code:find('ds%s*%.[%w_]+%s*=[^=]') or code:find('ds%s*%b[]%s*=[^=]') or code:find('guids%s*%b[]%s*=[^=]'))
    T.falsy(code:find('EmpireIntelDB', 1, true) or code:find('Store%.'), 'the bridge never touches saved data')
  end)
end)

T.describe('P2-3 static rules', function()
  T.it('Core/Views.lua and Core/Rules.lua make no game call and never touch saved data', function()
    for _, f in ipairs({ 'Core/Views.lua', 'Core/Rules.lua' }) do
      local code = read(DIR .. f):gsub('%-%-[^\n]*', '')
      for _, bad in ipairs({ 'P.Call', 'P.CallIn', 'P.env', 'P.fn', 'Store.', 'EmpireIntelDB', 'DataStoreBridge' }) do
        T.falsy(code:find(bad, 1, true), bad .. ' in ' .. f)
      end
    end
    local rules = read(DIR .. 'Core/Rules.lua'):gsub('%-%-[^\n]*', '')
    T.falsy(rules:find('P%.'), 'Rules.lua is pure')
  end)
end)

T.describe('P3-1 static rules', function()
  local function code(f) return (read(DIR .. f):gsub('%-%-[^\n]*', '')) end
  T.it('only Platform/Legacy.lua names the Legacy and achievement functions', function()
    for _, file in ipairs(FILES) do
      if file ~= 'Platform/Legacy.lua' then
        local c = code(file)
        for _, n in ipairs({ 'GetCategoryList', 'GetCategoryInfo', 'GetCategoryNumAchievements', 'GetAchievementInfo',
          'GetAchievementNumCriteria', 'GetAchievementCriteriaInfo', 'LegacySystem' }) do
          T.falsy(c:find(n, 1, true), n .. ' in ' .. file)
        end
      end
    end
  end)
  T.it('Platform/Legacy.lua: the allowed list is exactly the approved one; no Update, Register, trait or currency call', function()
    local c = code('Platform/Legacy.lua')
    local block = c:match('L%.ALLOWED = (%b{})')
    local names = {}
    for n in block:gmatch("%[?'?([%w_%.]+)'?%]? = {") do names[n] = true end
    local want = { 'LegacySystem.GetCurrencyInfo', 'GetCategoryList', 'GetCategoryInfo', 'GetCategoryNumAchievements',
      'GetAchievementInfo', 'GetAchievementNumCriteria', 'GetAchievementCriteriaInfo' }
    local n = 0
    for _ in pairs(names) do n = n + 1 end
    T.eq(n, #want)
    for _, w in ipairs(want) do T.truthy(names[w], w) end
    for _, bad in ipairs({ 'UpdateCurrencyInfo', 'RegisterCurrencyInfoCallback', 'C_Traits', 'C_ClassTalents', 'C_CurrencyInfo' }) do
      T.falsy(c:find(bad, 1, true), bad)
    end
    for name in c:gmatch("L%.Call%(st, '([%w_%.]+)'") do T.truthy(names[name], 'L.Call of ' .. name) end
  end)
  T.it('P3-1 files never touch saved data', function()
    for _, f in ipairs({ 'Platform/Legacy.lua', 'Core/LegacyView.lua' }) do
      local c = code(f)
      T.falsy(c:find('Store.', 1, true) or c:find('EmpireIntelDB', 1, true) or c:find('SavedVars', 1, true), f)
    end
  end)
  T.it('Core/LegacyView.lua makes no game call', function()
    local c = code('Core/LegacyView.lua')
    T.falsy(c:find('P.Call', 1, true) or c:find('P.env', 1, true) or c:find('P.CallIn', 1, true))
  end)
end)
