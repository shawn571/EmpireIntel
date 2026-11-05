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
  tonumber = true, string = true, table = true, math = true, error = true, assert = true }

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
  T.it('TOC: Interface 16001, version 0.2.0, one saved variable, forward slashes, files exist', function()
    local toc = read(DIR .. 'EmpireIntel.toc')
    T.truthy(toc:find('^## Interface: 16001\n'))
    T.truthy(toc:find('## Version: 0.2.0', 1, true))
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
      T.falsy(src:find('DataStore', 1, true), 'DataStore is P2-2 (Bridge/), not P2-1')
    end)
    T.it(file .. ': no 0.5 s tick (user, Q-P2-1)', function()
      local code = src:gsub('%-%-[^\n]*', '')          -- comments may mention it; code may not
      T.falsy(code:find('P_TICK', 1, true))
    end)
  end
end)
