-- EmpireIntel / Tests / run.lua
-- Runs the offline suite on plain Lua 5.1 or 5.3 (D-009). From the repository root:
--     lua5.1 Tests/run.lua        lua5.3 Tests/run.lua        lua5.1 Tests/run.lua static
-- Exit status 0 when every test passed.
local script = arg and arg[0] or 'Tests/run.lua'
local root = script:match('^(.*)[/\\]Tests[/\\]run%.lua$') or '.'
if script == 'run.lua' then root = '..' end
package.path = root .. '/Tests/helpers/?.lua;' .. package.path
local T = require('testlib')
local F = require('fakeclient')
F.root = root
_G.TEST_ROOT = root

local FILES = { 'test_static', 'test_check', 'test_ei_static', 'test_ei' }
local filter = arg and arg[1]
for _, name in ipairs(FILES) do
  if not filter or name:find(filter, 1, true) then
    local chunk, err = loadfile(root .. '/Tests/' .. name .. '.lua')
    if not chunk then
      T.failed = T.failed + 1
      table.insert(T.failures, { name = name, err = 'cannot load: ' .. tostring(err) })
    else
      local ok, e = pcall(chunk, T, F, root)
      if not ok then
        T.failed = T.failed + 1
        table.insert(T.failures, { name = name, err = tostring(e) })
      end
    end
  end
end
print(_VERSION)
local ok = T.summary()
os.exit(ok and 0 or 1)
