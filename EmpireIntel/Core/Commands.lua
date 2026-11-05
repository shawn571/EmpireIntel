local ADDON, EI = ...
-- EmpireIntel / Core / Commands.lua                                      (Phase 2, increment P2-1)
--
-- /ei            this character: level, XP, rested XP, professions, last saved; characters known
-- /ei version    addon version, saved-data schema, store state
-- /ei off | on   stop or resume all snapshots (kept across logins)
-- /ei help

EI = EI or {}
local P = EI.Platform

local C = {}
EI.Commands = C

local function ago(t)
  if type(t) ~= 'number' then return 'never' end
  local d = (P.Now()) - t
  if d < 60 then return 'just now' end
  if d < 3600 then return math.floor(d / 60) .. ' min ago' end
  if d < 172800 then return math.floor(d / 3600) .. ' h ago' end
  return math.floor(d / 86400) .. ' days ago'
end

local function profText(list)
  if type(list) ~= 'table' then return 'not read yet' end
  if #list == 0 then return 'none' end
  local parts = {}
  for _, p in ipairs(list) do
    parts[#parts + 1] = tostring(p.name) .. ' ' .. tostring(p.skill) .. (p.max and ('/' .. p.max) or '')
  end
  return table.concat(parts, ', ')
end

function C.Status()
  local db = EI.Store.Get()
  local player = P.Player()
  local roster = EI.Store.Section('roster')
  local known = 0
  for _ in pairs(roster) do known = known + 1 end
  if EI.Snapshot.IsOff() then
    P.Print('is OFF: nothing is recorded. /ei on to resume. ' .. known .. ' characters known.')
    return
  end
  local rec = player and player.guid and roster[player.guid]
  if not rec then
    P.Print('this character is not recorded yet (it is saved about 2 seconds after login). ' .. known .. ' characters known.')
    return
  end
  local rest = rec.rest and (rec.rest .. ' XP') or 'none reported'
  P.Print(string.format('%s (%s %s, %s): XP %s/%s, rested %s, %s; professions: %s. Saved %s. %d characters known.',
    tostring(rec.name), tostring(rec.class), tostring(rec.level), tostring(rec.realm or 'realm unknown'),
    tostring(rec.xp), tostring(rec.xpMax), rest, rec.resting and 'resting' or 'not resting',
    profText(rec.professions), ago(rec.lastSeen), known))
end

function C.Handle(msg)
  msg = string.lower(tostring(msg or ''))
  msg = string.gsub(msg, '^%s+', '')
  msg = string.gsub(msg, '%s+$', '')
  local db = EI.Store.Get()
  if msg == '' or msg == 'status' then
    C.Status()
  elseif msg == 'version' then
    local st = EI.Store.Status() or {}
    P.Print('version ' .. P.VERSION .. ', saved data schema ' .. tostring(st.schema) .. ' (' .. tostring(st.state) .. ')')
  elseif msg == 'off' then
    db.off = true
    EI.Snapshot.Stop()
    P.Print('OFF. Nothing is recorded now or on later logins. /ei on to resume.')
  elseif msg == 'on' then
    db.off = nil
    EI.Snapshot.Start()
    P.Print('ON. This character is saved in about 2 seconds.')
  else
    P.Print('commands: /ei (this character), /ei version, /ei off, /ei on')
  end
end

function C.Install()
  return P.RegisterSlash('EMPIREINTEL', '/ei', C.Handle)
end
