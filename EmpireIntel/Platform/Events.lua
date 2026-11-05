local ADDON, EI = ...
-- EmpireIntel / Platform / Events.lua                                     (Phase 1, task 1.4)
--
-- PURPOSE
--  1. A tiny pure-Lua dispatcher for NORMALIZED Platform events (P_MONEY, P_ZONE, ...).
--     Contract: Platform.On(eventName, handler(payload)), payload is always a table.
--  2. The only place a WoW event frame is created for event routing.
--     Other Platform modules call Events.Bind(wowEvent, fn) to receive raw WoW events.
--  3. Lifecycle: PLAYER_LOGIN -> ready, PLAYER_ENTERING/LEAVING_WORLD -> in-world flag,
--     PLAYER_REGEN_* -> P_COMBAT, PLAYER_LOGOUT -> P_LOGOUT.
--
-- DESIGN NOTES
--  * Handlers are isolated with pcall: one failing handler never blocks the others.
--  * Removing/adding handlers while an event is being dispatched is safe.
--  * This is the ONLY file allowed to call RegisterEvent (enforced by a test).
--  * Restricted events (P.RESTRICTED_EVENTS) are refused without calling RegisterEvent, and
--    names the client reports invalid (C_EventUtils.IsEventValid) are skipped the same way:
--    a blocked registration shows an ADDON_ACTION_FORBIDDEN popup that pcall cannot hide.
--  * The registration result is recorded as capability 'event.<NAME>'.
--  * After a fatal capability failure (P.Fatal) nothing is emitted except P_LOGOUT.
--
-- PORTED from EmpireIntel EmpireIntel/Platform/Events.lua at commit a21e071 (read-only; EmpireIntel unchanged).
-- Changes: normalized events reduced to P_LEVEL, P_PROFS, P_COMBAT, P_LOGOUT (no P_TICK, no money, loot, zone or
-- trade events: user, Q-P2-1); the allow-list is P.TRUSTED_EVENTS only; capability stages, delivery counters and
-- unit-filtered registration removed (they served EmpireIntel's collectors). Kept: restricted-event refusal, name
-- validity check, IsEventRegistered verification, pcall isolation, safe add/remove during dispatch.

EI = EI or {}
local P = EI.Platform
assert(P, 'Platform/Platform.lua must be loaded before Platform/Events.lua')

local Events = {}
P.Events = Events
P.Register('Events', Events)

---------------------------------------------------------------------------
-- Event specification (payload shapes). Suffix '?' = optional field.
---------------------------------------------------------------------------

local SPEC = {
  P_LEVEL         = { level = 'number' },
  P_PROFS         = { profs = 'table' },
  P_COMBAT        = { inCombat = 'boolean' },
  P_LOGOUT        = {},
}
Events.SPEC = SPEC

--- Sorted list of every normalized event name.
function Events.Names()
  return P.Util.sortedKeys(SPEC)
end

--- Validates a payload against SPEC. Returns true, or false plus a reason.
function Events.Validate(name, payload)
  local spec = SPEC[name]
  if not spec then return false, 'unknown event ' .. tostring(name) end
  if type(payload) ~= 'table' then return false, 'payload must be a table' end
  for field, want in pairs(spec) do
    local optional = want:sub(-1) == '?'
    local typeName = optional and want:sub(1, -2) or want
    local v = payload[field]
    if v == nil then
      if not optional then return false, 'missing field ' .. field end
    elseif type(v) ~= typeName then
      return false, 'field ' .. field .. ' must be ' .. typeName .. ', got ' .. type(v)
    end
  end
  return true
end

---------------------------------------------------------------------------
-- Normalized event dispatcher
---------------------------------------------------------------------------

local handlers = {}        -- name -> array of fn (false marks a slot removed mid-dispatch)
local depth = {}           -- name -> dispatch nesting level
local dirty = {}           -- name -> true when a compaction is pending

--- Subscribes handler(payload) to a normalized event. Idempotent per (name, fn).
-- Returns fn, or nil plus an error string.
function Events.On(name, fn)
  if type(name) ~= 'string' or not SPEC[name] then
    return nil, 'unknown event ' .. tostring(name)
  end
  if type(fn) ~= 'function' then return nil, 'handler must be a function' end
  local list = handlers[name]
  if not list then
    list = {}
    handlers[name] = list
  end
  for i = 1, #list do
    if list[i] == fn then return fn end
  end
  list[#list + 1] = fn
  return fn
end

--- Unsubscribes. Returns true if a handler was removed.
function Events.Off(name, fn)
  local list = handlers[name]
  if not list then return false end
  for i = 1, #list do
    if list[i] == fn then
      if (depth[name] or 0) > 0 then
        list[i] = false
        dirty[name] = true
      else
        table.remove(list, i)
      end
      return true
    end
  end
  return false
end

--- Number of live handlers for an event (tests/diagnostics).
function Events.HandlerCount(name)
  local list = handlers[name]
  if not list then return 0 end
  local n = 0
  for i = 1, #list do
    if list[i] then n = n + 1 end
  end
  return n
end

local function describe(value)
  if type(value) == 'table' then return '{...}' end
  return tostring(value)
end

local function debugEcho(name, payload)
  local parts = {}
  for _, k in ipairs(P.Util.sortedKeys(payload)) do
    parts[#parts + 1] = tostring(k) .. '=' .. describe(payload[k])
  end
  P.Print('[evt] ' .. name .. ' ' .. table.concat(parts, ' '))
end

--- Delivers a normalized event to subscribers. Returns the number of handlers invoked.
-- Platform modules call this; other layers must not.
function Events.Emit(name, payload)
  if not SPEC[name] then
    P.Diag('error', 'Events', 'emit of unknown event ' .. tostring(name))
    return 0
  end
  if not P.operational and name ~= 'P_LOGOUT' then return 0 end
  if payload == nil then payload = {} end
  if P.debug or P.validate then
    local ok, why = Events.Validate(name, payload)
    if not ok then
      P.Diag('error', 'Events', 'invalid payload for ' .. name .. ': ' .. tostring(why))
      if P.validate == 'strict' then return 0 end
    end
  end
  if P.debug then debugEcho(name, payload) end

  local list = handlers[name]
  if not list then return 0 end

  depth[name] = (depth[name] or 0) + 1
  local n = #list          -- handlers added during dispatch run on the next event
  local invoked = 0
  for i = 1, n do
    local fn = list[i]
    if fn then
      invoked = invoked + 1
      local ok, err = pcall(fn, payload)
      if not ok then
        P.Diag('error', 'Events', 'handler for ' .. name .. ' failed: ' .. tostring(err))
      end
    end
  end
  depth[name] = depth[name] - 1

  if depth[name] == 0 and dirty[name] then
    dirty[name] = nil
    for i = #list, 1, -1 do
      if not list[i] then table.remove(list, i) end
    end
  end
  return invoked
end

---------------------------------------------------------------------------
-- Raw WoW event routing
---------------------------------------------------------------------------

local frame = nil
local wowHandlers = {}   -- wowEvent -> array of fn(event, ...)

local registration = {}   -- wowEvent -> true (verified) | nil (could not verify); false entries are never kept

local function dispatchWow(event, ...)
  local list = wowHandlers[event]
  if not list then return end
  for i = 1, #list do
    local ok, err = pcall(list[i], event, ...)
    if not ok then P.Diag('error', 'Events', 'WoW handler for ' .. tostring(event) .. ' failed: ' .. tostring(err)) end
  end
end

--- Entry point used by the frame script (also callable from tests).
Events.DispatchWow = dispatchWow

--- Registration state of one raw event: true (verified), nil (unverified or not bound).
function Events.Registered(wowEvent) return registration[wowEvent] end

--- Names of every raw event EmpireIntel has bound (sorted).
function Events.BoundEvents()
  local out = {}
  for name in pairs(wowHandlers) do out[#out + 1] = name end
  table.sort(out)
  return out
end

local function ensureFrame()
  if frame then return frame end
  local create = P.fn('CreateFrame')
  if not create then
    P.SetCap('frame', false, 'CreateFrame unavailable')
    return nil
  end
  local ok, f = pcall(create, 'Frame')
  if not ok or not f then
    P.SetCap('frame', false, 'CreateFrame failed: ' .. tostring(f))
    return nil
  end
  frame = f
  f:SetScript('OnEvent', function(_, event, ...) dispatchWow(event, ...) end)
  P.SetCap('frame', true)
  return f
end

--- Subscribes fn(wowEvent, ...) to a raw WoW event.
-- Returns true, or false plus a reason (unknown event, no frame support).
function Events.Bind(wowEvent, fn)
  if type(wowEvent) ~= 'string' or type(fn) ~= 'function' then
    return false, 'Bind needs an event name and a function'
  end
  if P.RESTRICTED_EVENTS[wowEvent] then
    P.SetCap('event.' .. wowEvent, false, 'restricted event, never registered')
    return false, 'restricted event (never registered): ' .. wowEvent
  end
  -- Only events on the allow-list (P.TRUSTED_EVENTS, all proven in the live client) are ever registered.
  if not P.TRUSTED_EVENTS[wowEvent] then
    P.SetCap('event.' .. wowEvent, false, 'event is not on the allow-list')
    return false, 'event not on the allow-list: ' .. wowEvent
  end
  if P.EventNameValid(wowEvent) == false then
    P.SetCap('event.' .. wowEvent, false, 'event name not valid in this client')
    return false, 'event name not valid in this client: ' .. wowEvent
  end
  local f = ensureFrame()
  if not f then return false, 'no frame support' end

  local list = wowHandlers[wowEvent]
  if not list then
    -- Recorded BEFORE the call: if the client ever shows a blocked-action popup, /ei version
    -- names the event that caused it (the popup itself does not).
    Events.lastRegisterAttempt = wowEvent
    local ok, err = pcall(function() f:RegisterEvent(wowEvent) end)
    if not ok then
      P.SetCap('event.' .. wowEvent, false, tostring(err))
      return false, tostring(err)
    end
    -- A blocked registration returns normally. Verify that it actually took effect (E1).
    local verified = nil
    local okCheck, isRegistered = pcall(function() return f:IsEventRegistered(wowEvent) end)
    if okCheck and type(isRegistered) == 'boolean' then verified = isRegistered end
    if verified == false and P.TRUSTED_EVENTS[wowEvent] then
      -- proven in the live client: do not let an unproven check disable a working event
      P.Diag('warn', 'Events', wowEvent .. ': IsEventRegistered is false but this event is proven in the live client; treating it as registered (unverified)')
      verified = nil
    end
    if verified == false then
      local why = 'RegisterEvent returned normally but IsEventRegistered is false (blocked?)'
      P.SetCap('event.' .. wowEvent, false, why)
      P.Diag('error', 'Events', wowEvent .. ': ' .. why)
      return false, 'registration not in effect: ' .. wowEvent
    end
    P.SetCap('event.' .. wowEvent, true, verified and 'registered (verified)' or 'registered (could not verify)')
    registration[wowEvent] = verified      -- true, or nil when IsEventRegistered is unavailable
    list = {}
    wowHandlers[wowEvent] = list
  end
  for i = 1, #list do
    if list[i] == fn then return true end
  end
  list[#list + 1] = fn
  return true
end

--- Removes a raw subscription; unregisters the event when nobody listens any more.
function Events.Unbind(wowEvent, fn)
  local list = wowHandlers[wowEvent]
  if not list then return false end
  for i = 1, #list do
    if list[i] == fn then
      table.remove(list, i)
      if #list == 0 then
        wowHandlers[wowEvent] = nil
        registration[wowEvent] = nil
        if frame then pcall(function() frame:UnregisterEvent(wowEvent) end) end
      end
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------
-- Lifecycle state
---------------------------------------------------------------------------

local inWorld = false
Events.inCombat = false

--- True between PLAYER_ENTERING_WORLD and PLAYER_LEAVING_WORLD.
function P.InWorld() return inWorld end

Events.Bind('PLAYER_LOGIN', function()
  P.MarkReady()
end)

Events.Bind('PLAYER_ENTERING_WORLD', function()
  inWorld = true
end)

-- PLAYER_LEAVING_WORLD is optional: if the client lacks it, in-world simply stays true.
Events.Bind('PLAYER_LEAVING_WORLD', function()
  inWorld = false
end)

Events.Bind('PLAYER_REGEN_DISABLED', function()
  Events.inCombat = true
  Events.Emit('P_COMBAT', { inCombat = true })
end)

Events.Bind('PLAYER_REGEN_ENABLED', function()
  Events.inCombat = false
  Events.Emit('P_COMBAT', { inCombat = false })
end)

Events.Bind('PLAYER_LOGOUT', function()
  Events.Emit('P_LOGOUT', {})
end)

--- Addon loaded after login (load-on-demand, /reload quirks): PLAYER_LOGIN will not fire.
-- Core/Boot.lua calls this last, after every module has registered its OnReady listener.
function Events.CheckLateLoad()
  local isLoggedIn = P.fn('IsLoggedIn')
  if isLoggedIn and not P.IsReady() then
    local ok, logged = pcall(isLoggedIn)
    if ok and logged then
      inWorld = true
      P.MarkReady()
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------
-- Public Platform API (Contracts.md F2)
---------------------------------------------------------------------------

P.On = Events.On
P.Off = Events.Off
P.Emit = Events.Emit
