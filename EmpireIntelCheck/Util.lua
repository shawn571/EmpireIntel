local ADDON, NS = ...
-- EmpireIntelCheck / Util.lua
-- Test Package 1 (Architecture.md section 9). Shared helpers. Read-only throwaway addon.
--
-- RULES FOR EVERY FILE OF THIS ADDON
--  * Every WoW global is read through NS.env at call time (NS.G). Tests inject a fake client.
--    This file is the only one that names _G (enforced by Tests/test_static.lua).
--  * Lua 5.1, ASCII, line comments only, no long brackets.
--  * Never throw across a module boundary: wrap risky work in pcall and record the result.

NS = NS or {}
NS.env = NS.env or _G
NS.VERSION = '0.1.9-tp1'

local U = {}
NS.U = U

function NS.G(name)
  return NS.env[name]
end

-- Resolve a dotted path such as 'C_Container.GetContainerNumSlots'.
function U.path(dotted)
  local cur = NS.env
  for part in string.gmatch(dotted, '[^%.]+') do
    if type(cur) ~= 'table' then return nil end
    local ok, v = pcall(function() return cur[part] end)
    if not ok then return nil end
    cur = v
  end
  return cur
end

function U.now()
  local f = NS.G('GetTime')
  if type(f) == 'function' then
    local ok, t = pcall(f)
    if ok and type(t) == 'number' then return t end
  end
  return 0
end

function U.wall()
  local f = NS.G('time')
  if type(f) == 'function' then
    local ok, t = pcall(f)
    if ok and type(t) == 'number' then return t end
  end
  return 0
end

-- Milliseconds from a precise timer, or nil when the client has none.
function U.preciseMs()
  local f = NS.G('debugprofilestop')
  if type(f) == 'function' then
    local ok, t = pcall(f)
    if ok and type(t) == 'number' then return t end
  end
  return nil
end

function U.isSecret(v)
  local f = NS.G('issecretvalue')
  if type(f) ~= 'function' then return false end
  local ok, r = pcall(f, v)
  return ok and r and true or false
end

function U.inCombat()
  local f = NS.G('InCombatLockdown')
  if type(f) ~= 'function' then return false end
  local ok, r = pcall(f)
  return ok and r and true or false
end

---------------------------------------------------------------------------
-- Name rules (Architecture section 9, runtime limit 1)
---------------------------------------------------------------------------

U.TERMS = { 'legacy', 'perk', 'challenge', 'camelot', 'forever' }
-- The user's rule (Q-7): skip anything containing Set, Spend, Learn, Reset, Buy or Purchase.
-- Matched as written (capitalized words), so 'Preset', 'Offset' or 'Asset' do not match,
-- and also as a lower-case word at the start of a name segment ('setUp', 'buy_x').
-- Blocked words (Q-7, extended for Q-T3). Since 0.1.5 (user, Q-T5, 2026-11-05) they are matched as WHOLE
-- CamelCase words, case-insensitive, plus the stem 'Reincarnat' (Reincarnate, Reincarnating, Reincarnation ...).
U.DENY = { 'set', 'spend', 'learn', 'reset', 'buy', 'purchase', 'request', 'claim', 'open', 'toggle', 'show', 'reincarnate' }
U.DENY_STEMS = { 'reincarnat' }

-- Known retail-engine systems that match a term but are not the Forever Legacy system
-- (from GoldIntel evidence and the launch-build run, TP1_Report_Run1.md). Recorded, never called,
-- never counted toward the verdict.
U.UNRELATED_PREFIX = {
  'C_ChallengeMode', 'C_PerksProgram', 'C_PerksActivities', 'C_ProfSpecs', 'C_MythicPlus', 'ChallengeMode', 'Challenges',
  'PerksProgram', 'PerksActivities', 'PERKS_PROGRAM', 'CHALLENGE_MODE', 'WOW_PROJECT_',
  'UnitPopupLegacyRaid', 'UnitPopupResetChallenge', 'GuildChallenge', 'CommunitiesGuild', 'CommunitiesFrameGuild',
  'GetGuildChallenge', 'GetNumGuildChallenges', 'RequestGuildChallenge', 'GetGuildPerk', 'GetNumGuildPerks',
  'ProfessionsSpecPerk', 'ScenarioChallengeMode', 'ScenarioObjectiveTrackerChallengeMode', 'EventToastChallengeMode',
  'RecruitAFriendClaimLegacy', 'Class_PerksProgram', 'wlEvent_', 'AddPerksProgram', 'TextToSpeechFrame_LoadLegacy',
  'AuthChallenge', 'IsLegacyDifficulty', 'NormalizeLegacyDifficulty', 'GetLegacyRaidDifficulty', 'SetLegacyRaidDifficulty',
  'C_FriendList.IsLegacyFriend', 'C_Reputation.SetLegacyReputations', 'C_Reputation.AreLegacyReputations',
  'C_PartyInfo.IsChallengeMode', 'C_PartyInfo.ChallengeMode', 'HEALBOT_', 'LE_GAME_ERR_CHALLENGE', 'LE_GAME_ERR_LEGACY_RAID',
  'LE_FRAME_TUTORIAL_PERKS', 'CHALLENGE_MEDAL', 'GUILD_CHALLENGE', 'NUM_CHALLENGE', 'LE_SCENARIO_TYPE_CHALLENGE',
  'LE_GAME_ERR_NO_LOOT_IN_CHALLENGE', 'LE_GAME_ERR_START_RESTRICTED_CHALLENGE', 'LE_GAME_ERR_CLAIMED_CHALLENGE',
  'LE_GAME_ERR_CANT_DO_THAT_CHALLENGE', 'LE_GAME_ERR_NO_CHALLENGE', 'CamelotBank',
}
U.UNRELATED_EXACT = { ['C_Loot.IsLegacyLootModeEnabled'] = true }

-- 'legacy' sub-words that belong to retail features, not to the Forever Legacy system.
U.LEGACY_RETAIL = { 'legacyraid', 'legacydifficulty', 'legacyfriend', 'legacyreputation', 'legacyloot', 'claimlegacy',
  'legacysettings', 'legacyliquid', 'legacyspell', 'expansionlegacy', 'legacyletterbox', 'legacyunsupported',
  'legacybehavior', 'legacyexpansion', 'legacyrecruit', 'legacyrewardsbutton', 'legacy_raid', 'legacy_loot',
  'nameplates_style_legacy', 'voice', 'turnstrafe' }

function U.term(name)
  if type(name) ~= 'string' then return nil end
  local low = string.lower(name)
  for _, t in ipairs(U.TERMS) do
    if string.find(low, t, 1, true) then return t end
  end
  return nil
end

-- Split a name into words: on '.', '_' and other non-alphanumerics, then at CamelCase boundaries.
-- 'C_Seasons.GetActiveSeason' -> C, Seasons, Get, Active, Season; 'GetUIState' -> Get, UI, State;
-- 'setUpFunction' -> set, Up, Function; 'LEGACY_SET_X' -> LEGACY, SET, X.
function U.words(name)
  local out = {}
  for seg in string.gmatch(tostring(name), '%w+') do
    seg = string.gsub(seg, '(%l)(%u)', '%1 %2')
    seg = string.gsub(seg, '(%u)(%u%l)', '%1 %2')
    seg = string.gsub(seg, '(%a)(%d)', '%1 %2')
    seg = string.gsub(seg, '(%d)(%a)', '%1 %2')
    for w in string.gmatch(seg, '%S+') do table.insert(out, w) end
  end
  return out
end

function U.denied(name)
  for _, w in ipairs(U.words(name)) do
    local low = string.lower(w)
    for _, d in ipairs(U.DENY) do
      if low == d then return w end
    end
    for _, stem in ipairs(U.DENY_STEMS) do
      if string.sub(low, 1, #stem) == stem then return w end
    end
  end
  return nil
end

-- A name that points at the Forever Legacy system: contains 'legacy', is not a known retail feature.
function U.strong(name)
  if type(name) ~= 'string' then return false end
  local low = string.lower(name)
  if not string.find(low, 'legacy', 1, true) then return false end
  if U.unrelated(name) then return false end
  for _, r in ipairs(U.LEGACY_RETAIL) do
    if string.find(low, r, 1, true) then return false end
  end
  return true
end

-- 'Get', 'Is' or 'Has' followed by an upper-case letter, a digit, an underscore or the end.
function U.isReadName(fn)
  if type(fn) ~= 'string' then return false end
  for _, p in ipairs({ 'Get', 'Is', 'Has' }) do
    if string.sub(fn, 1, #p) == p then
      local nextc = string.sub(fn, #p + 1, #p + 1)
      if nextc == '' or string.find(nextc, '^[%u%d_]') then return true end
    end
  end
  return false
end

function U.unrelated(fullName)
  if U.UNRELATED_EXACT[fullName] then return true end
  for _, p in ipairs(U.UNRELATED_PREFIX) do
    if string.sub(fullName, 1, #p) == p then return true end
  end
  return false
end

---------------------------------------------------------------------------
-- Bounded, ASCII-only copy of any value (limit 4 of section 9)
---------------------------------------------------------------------------

U.MAX_DEPTH = 4
U.MAX_ENTRIES = 200
U.MAX_STRING = 120
U.MAX_VALUE_BYTES = 16384    -- per top-level value; the rest is marked truncated

function U.ascii(s)
  s = string.gsub(s, '[^\32-\126]', '?')
  if #s > U.MAX_STRING then s = string.sub(s, 1, U.MAX_STRING) .. '...' end
  return s
end

-- Returns copy, info where info = { secret = n, opaque = n, truncated = bool, cost = bytes }.
function U.dump(v, info, depth, seen)
  if type(info) ~= 'table' then info = { secret = 0, opaque = 0, truncated = false, cost = 0 } end
  depth = depth or 0
  if U.isSecret(v) then
    info.secret = info.secret + 1; info.cost = info.cost + 10
    return '<secret>', info
  end
  local tv = type(v)
  if tv == 'nil' then info.cost = info.cost + 4; return nil, info end
  if tv == 'number' or tv == 'boolean' then info.cost = info.cost + 12; return v, info end
  if tv == 'string' then
    local s = U.ascii(v)
    info.cost = info.cost + #s + 4
    return s, info
  end
  if tv == 'table' then
    seen = seen or {}
    if seen[v] then info.cost = info.cost + 8; return '<cycle>', info end
    if depth >= U.MAX_DEPTH then info.truncated = true; info.cost = info.cost + 8; return '<deeper>', info end
    seen[v] = true
    local out, n = {}, 0
    local ok = pcall(function()
      for k, val in pairs(v) do
        n = n + 1
        if n > U.MAX_ENTRIES or info.cost > (info.limit or U.MAX_VALUE_BYTES) then info.truncated = true; break end
        local key = k
        if type(k) == 'string' then key = U.ascii(k)
        elseif type(k) ~= 'number' then key = '<' .. type(k) .. '>' .. n end
        if U.isSecret(k) then key = '<secretkey>' .. n; info.secret = info.secret + 1 end
        out[key] = (U.dump(val, info, depth + 1, seen))
        info.cost = info.cost + 6
      end
    end)
    if not ok then info.truncated = true end
    seen[v] = nil
    info.cost = info.cost + 4
    return out, info
  end
  -- function, userdata, thread
  info.opaque = info.opaque + 1
  info.cost = info.cost + 12
  return '<' .. tv .. '>', info
end

-- Rough size of a stored value in bytes (used for the saved-data cap, limit 4).
function U.size(v, depth)
  depth = depth or 0
  local tv = type(v)
  if tv == 'string' then return #v + 4 end
  if tv ~= 'table' then return 12 end
  if depth > 12 then return 8 end
  local n = 4
  for k, val in pairs(v) do
    n = n + U.size(k, depth + 1) + U.size(val, depth + 1) + 2
  end
  return n
end

-- Pack varargs with their count (Lua 5.1 safe).
function U.pack(...)
  return { n = select('#', ...), ... }
end
