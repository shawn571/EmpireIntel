-- EmpireIntel / Tests / test_static.lua
-- File rules C-1..C-6 (GoldIntel D-024/D-025) plus the TP-1 runtime limits that can be checked statically.
local T, F, root = ...

local DIR = root .. '/EmpireIntelCheck/'
local function read(path)
  local f = assert(io.open(path, 'rb'))
  local s = f:read('*a')
  f:close()
  return s
end
local _, FILES = F.load(F.new())

-- Lua builtins an addon file may name directly; every WoW global goes through NS.env (NS.G).
local ALLOWED = { type = true, pairs = true, ipairs = true, next = true, pcall = true, select = true, tostring = true,
  tonumber = true, string = true, table = true, math = true, coroutine = true, error = true }

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

T.describe('static rules', function()
  T.it('TOC is minimal: Interface 16001, Title, Notes, Version, SavedVariables, then files', function()
    local toc = read(DIR .. 'EmpireIntelCheck.toc')
    T.truthy(toc:find('^## Interface: 16001\n'), 'interface line first')
    for line in toc:gmatch('[^\n]+') do
      if line:sub(1, 2) == '##' then
        T.truthy(line:match('^## (%a+):') and ({ Interface = 1, Title = 1, Notes = 1, Version = 1, SavedVariables = 1 })[line:match('^## (%a+):')], line)
      else
        T.falsy(line:find('\\', 1, true), 'forward slashes only: ' .. line)
        T.truthy(io.open(DIR .. line), 'file exists: ' .. line)
      end
    end
    T.falsy(toc:find('Dependencies', 1, true), 'no dependency on DataStore or anything else (D-003)')
  end)

  for _, file in ipairs(FILES) do
    local src = read(DIR .. file)
    T.it(file .. ': ASCII, LF, final newline, no long brackets, header line', function()
      T.falsy(src:find('[\128-\255]'), 'ASCII only')
      T.falsy(src:find('\r', 1, true), 'LF only')
      T.eq(src:sub(-1), '\n', 'ends with a newline')
      T.falsy(src:find('%[%[') or src:find('%[=+%['), 'no long brackets')
      T.eq(src:match('^[^\n]*'), 'local ADDON, NS = ...', 'first line')
    end)
    T.it(file .. ': no WoW global outside NS.env; nothing assigned to globals', function()
      local get, set = luacGlobals(DIR .. file)
      if not get then print('      (skip: luac5.1 not available)'); return end
      for name in pairs(get) do
        if not ALLOWED[name] then
          T.truthy(name == '_G' and file == 'Util.lua', 'bare global ' .. name .. ' in ' .. file)
        end
      end
      T.eq(next(set), nil, 'no global assignment in ' .. file)
    end)
    T.it(file .. ': RegisterEvent only in Core.lua, HookScript only in Run.lua, no hooksecurefunc', function()
      if file ~= 'Core.lua' then T.falsy(src:find('RegisterEvent', 1, true), 'RegisterEvent in ' .. file) end
      if file ~= 'Run.lua' then T.falsy(src:find('HookScript', 1, true), 'HookScript in ' .. file) end
      T.falsy(src:find('hooksecurefunc', 1, true))
    end)
    T.it(file .. ': never names GoldIntel saved variables', function()
      T.falsy(src:find('GoldIntelDB', 1, true))
      T.falsy(src:find('GoldIntelCharDB', 1, true))
    end)
    T.it(file .. ': no fixture names in shipped code', function()
      T.falsy(src:find('Fixture', 1, true))
    end)
  end
end)

T.describe('0.1.6: Legacy.lua call list (Q-T7)', function()
  local src = read(DIR .. 'Legacy.lua'):gsub('%-%-[^\n]*', '')
  T.it('ALLOWED holds exactly the approved achievement and currency getters', function()
    local block = src:match('L%.ALLOWED = (%b{})')
    local names = {}
    for n in block:gmatch("%[?'?([%w_%.]+)'?%]? = {") do names[n] = true end
    local want = { 'C_CurrencyInfo.GetCurrencyInfo', 'C_CurrencyInfo.GetCurrencyListSize', 'C_CurrencyInfo.GetCurrencyListInfo',
      'GetCategoryList', 'GetCategoryInfo', 'GetCategoryNumAchievements', 'GetAchievementInfo', 'GetAchievementNumCriteria',
      'GetAchievementCriteriaInfo' }
    local n = 0
    for _ in pairs(names) do n = n + 1 end
    T.eq(n, #want)
    for _, w in ipairs(want) do T.truthy(names[w], w) end
  end)
  T.it('every L.Call names an allowed function; no denylisted word in any of them', function()
    for name in src:gmatch("L%.Call%(st, '([%w_%.]+)'") do
      T.truthy(src:find("'" .. name:gsub('%.', '%%.') .. "'", 1) , name)
      for _, bad in ipairs({ 'Set', 'Spend', 'Learn', 'Reset', 'Buy', 'Purchase', 'Request', 'Claim', 'Open', 'Toggle', 'Show', 'Reincarnat' }) do
        T.falsy(name:find(bad, 1, true), name)
      end
    end
  end)
  T.it('the only direct calls are pcall(fn, ...) inside L.Call and D.Probe for the two LegacySystem getters', function()
    local n = 0
    for _ in src:gmatch('pcall%(fn,') do n = n + 1 end
    T.eq(n, 1)
    T.truthy(src:find("{ 'GetCurrencyInfo', 'GetFilteredChallenges' }", 1, true))
  end)
end)
