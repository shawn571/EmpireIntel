local ADDON, EI = ...
-- EmpireIntel / Platform / SavedVars.lua                                  (Phase 2)
--
-- PURPOSE
--   The only access path to the SavedVariables globals (EmpireIntelDB, EmpireIntelCharDB).
--   Store and every other module above Platform/ must use this adapter, because WoW
--   globals may not be touched outside Platform/ (Requirements FR-PLT-1).
--
--   Platform.SavedVars.Account()   -> table, status
--   Platform.SavedVars.Character() -> table, status
--     status: 'existing' (the client restored a table), 'created' (nothing was there),
--             'replaced' (something that was not a table was there and was replaced).
--
-- TIMING
--   The client restores SavedVariables after an addon's files run and before ADDON_LOADED,
--   so these functions are safe from PLAYER_LOGIN onward (never at file-load time).
--
-- The table returned is the live global table. The client writes it to disk at logout or
-- reload; addons cannot force a write.

-- PORTED from GoldIntel GoldIntel/Platform/SavedVars.lua at commit a21e071 (read-only; GoldIntel unchanged).
-- Changes: one account-wide table (EmpireIntelDB, saved-data format 1, Phase2_Plan.md);
-- the per-character table is removed (not in format 1).
EI = EI or {}
local P = EI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/SavedVars.lua')

local SV = {}
P.SavedVars = SV
P.Register('SavedVars', SV)

SV.NAMES = { account = 'EmpireIntelDB' }

local function ensure(kind)
  local name = SV.NAMES[kind]
  local value = P.env[name]
  if type(value) == 'table' then return value, 'existing' end
  local status = 'created'
  if value ~= nil then
    status = 'replaced'
    P.Diag('warn', 'SavedVars', name .. ' is not a table (was ' .. type(value) .. '); replaced by an empty table')
  end
  value = {}
  P.env[name] = value
  return value, status
end

--- The account-wide SavedVariables table (EmpireIntelDB).
function SV.Account() return ensure('account') end
