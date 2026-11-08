local ADDON, EI = ...
-- EmpireIntel / Core / LegacyView.lua                                    (Phase 3, increment P3-1)
--
-- PURPOSE
--   /ei legacy       points earned / available / spent, challenges per group, and the closest challenges
--   /ei legacy all   one line per challenge: done, or what is left
--   (Phase3_Legacy_Plan.md section 3, approved Q-P3-1; D-037)
--
-- RULES
--   * Reads only on the user's command, through Platform/Legacy.lua. Nothing is saved (Q-P3-1a).
--   * Earned = the completed challenges' reward points (confirmed). Available = quantity, spent = spent (confirmed,
--     EI-E-25, EI-E-26); they need the Legacy window opened once this session. spentInTree is never shown (closed,
--     EI-E-27). maxQuantity is only a cross-check: a difference from "earned" is one UNEXPECTED line.
--   * Explorer progress is the logged-in character's (EI-E-27); every other challenge's progress is the account's.
--   * Level and skill hints come from EmpireIntel's own records (and DataStore) and say so.

EI = EI or {}
local P = EI.Platform
assert(P and P.Legacy and EI.Alts and EI.Commands, 'load order: Platform/Legacy, Commands, Alts, LegacyView')

local V = {}
EI.LegacyView = V

V.LEFT_NAMES = 3
V.CLOSEST = 2

local function stepsOf(ch)
  -- the steps of a challenge: its linked achievements (Explorer) or its own criteria (dungeons, bosses, ...)
  if ch.steps then
    local d = 0
    for _, s in ipairs(ch.steps) do if s.completed == true then d = d + 1 end end
    return d, #ch.steps, ch.steps
  end
  local d, n = 0, 0
  for _, c in ipairs(ch.criteria or {}) do
    n = n + 1
    if c.completed == true then d = d + 1 end
  end
  return d, n, nil
end

local function leftNames(ch, max)
  local names = {}
  local more = 0
  local list = ch.steps or ch.criteria or {}
  for _, s in ipairs(list) do
    if s.completed ~= true then
      if #names < max then names[#names + 1] = tostring(s.name or s.text) else more = more + 1 end
    end
  end
  local t = table.concat(names, ', ')
  if more > 0 then t = t .. ', +' .. more end
  return t
end

local function sortedGroups(s)
  local list = {}
  for _, g in pairs(s.groups) do list[#list + 1] = g end
  table.sort(list, function(a, b) return a.id < b.id end)
  return list
end

-- Explorer (or any challenge with linked steps): the logged-in character's zone progress
local function explorerLine(out, ch, noName)
  local d, n = stepsOf(ch)
  local started, furthest = 0, {}
  for _, s in ipairs(ch.steps) do
    local sd, sn, rollup = 0, 0, false
    for _, c in ipairs(s.criteria or {}) do
      sn = sn + 1
      if c.completed == true then sd = sd + 1 end
      if c.type == 8 then rollup = true end          -- a roll-up (Explore Azeroth, ... Kalimdor), not a zone
    end
    if s.completed ~= true and sd > 0 and not rollup then
      started = started + 1
      furthest[#furthest + 1] = { name = tostring(s.name), d = sd, n = sn }
    end
  end
  table.sort(furthest, function(a, b) return a.d / a.n > b.d / b.n end)
  local f = {}
  for i = 1, math.min(2, #furthest) do
    f[#f + 1] = string.gsub(furthest[i].name, '^Explore ', '') .. ' ' .. furthest[i].d .. '/' .. furthest[i].n .. ' areas'
  end
  local text = string.format('%d of %d on this character', d, n)
  if not noName then text = tostring(ch.name) .. ' ' .. text end
  if started > 0 then text = text .. ' (' .. started .. ' zones started; furthest: ' .. table.concat(f, ', ') .. ')' end
  return text
end

-- class level and crafting skill hints from EmpireIntel's records (English challenge text, EI-E-22)
local CLASS_BY_NAME = { warrior = 'WARRIOR', paladin = 'PALADIN', hunter = 'HUNTER', rogue = 'ROGUE', priest = 'PRIEST',
  shaman = 'SHAMAN', mage = 'MAGE', warlock = 'WARLOCK', druid = 'DRUID' }

local function recordHints(out)
  local okC, rows = pcall(EI.Alts.Collect)
  if not okC or type(rows) ~= 'table' then return {} end
  local bestLevel, bestSkill = {}, {}
  for _, r in ipairs(rows) do
    if r.class and type(r.level) == 'number' and (not bestLevel[r.class] or r.level > bestLevel[r.class].level) then
      bestLevel[r.class] = { level = r.level, name = r.name }
    end
    for _, p in ipairs(type(r.professions) == 'table' and r.professions or {}) do
      local k = type(p.name) == 'string' and string.lower(p.name) or nil
      if k and type(p.skill) == 'number' and (not bestSkill[k] or p.skill > bestSkill[k].skill) then
        bestSkill[k] = { skill = p.skill, name = r.name }
      end
    end
  end
  local classHint, craftHint = nil, nil
  for _, ch in ipairs(out.challenges or {}) do
    if ch.legacy and not ch.excluded and ch.completed ~= true and type(ch.description) == 'string' then
      local lvl, cls = string.match(ch.description, 'Reach level (%d+) for the first time on an? (%a+)')
      if lvl then
        local b = bestLevel[CLASS_BY_NAME[string.lower(cls)] or '']
        local gap = b and (tonumber(lvl) - b.level) or nil
        if gap and gap > 0 and (not classHint or gap < classHint.gap) then
          classHint = { gap = gap, text = string.format('%s: %s is %d of %s', tostring(ch.name), tostring(b.name), b.level, lvl) }
        end
      end
      local sk, prof = string.match(ch.description, 'Reach (%d+) skill in (%a+)')
      if sk then
        local b = bestSkill[string.lower(prof)]
        local gap = b and (tonumber(sk) - b.skill) or nil
        if gap and gap > 0 and (not craftHint or gap < craftHint.gap) then
          craftHint = { gap = gap, text = string.format('%s: %s is %d of %s', tostring(ch.name), tostring(b.name), b.skill, sk) }
        end
      end
    end
  end
  local hints = {}
  if classHint then hints[#hints + 1] = classHint.text .. " [from EmpireIntel's records]" end
  if craftHint then hints[#hints + 1] = craftHint.text .. " [from EmpireIntel's records]" end
  return hints
end

--- The closest challenges with several steps, most done first: up to max lines, plus the Explorer challenge
-- (shown on its own by the caller). Pure. Also used by /ei next (P2-4).
function V.Closest(out, max)
  local cand = {}
  local explorer = nil
  for _, ch in ipairs(out.challenges or {}) do
    if ch.legacy and not ch.excluded and ch.completed ~= true then
      if ch.steps then
        explorer = explorer or ch
      else
        local d, n = stepsOf(ch)
        if n > 1 and d > 0 then cand[#cand + 1] = { ch = ch, d = d, n = n } end
      end
    end
  end
  table.sort(cand, function(a, b)
    if a.d / a.n ~= b.d / b.n then return a.d / a.n > b.d / b.n end
    return (a.n - a.d) < (b.n - b.d)
  end)
  local closest = {}
  for i = 1, math.min(max, #cand) do
    local c = cand[i]
    closest[#closest + 1] = string.format('%s %d of %d (left: %s)', tostring(c.ch.name), c.d, c.n, leftNames(c.ch, V.LEFT_NAMES))
  end
  return closest, explorer
end

--- The lines for one finished read (pure: no game call, no print). mode: nil or 'all'.
function V.Lines(out, mode)
  local lines = {}
  local function add(s) lines[#lines + 1] = s end
  if out.error then
    add('UNEXPECTED: the Legacy read stopped: ' .. tostring(out.error))
  end
  if out.combat then
    add('legacy: combat started during the read; try again after combat.')
    return lines
  end
  local s = out.summary
  if not s then add('legacy: no Legacy data read.'); return lines end
  if not s.recognized then
    add('UNEXPECTED: no Legacy reward text recognized (non-English client?); challenges are not counted.')
    return lines
  end
  local pts = out.points
  local head = string.format('Legacy: %d of %d points earned; ', s.earned, s.offered)
  if pts and type(pts.quantity) == 'number' and type(pts.spent) == 'number' then
    head = head .. string.format('%d available, %d spent. [pane loaded]', pts.quantity, pts.spent)
  else
    head = head .. 'available and spent: open the Legacy window once this session.'
  end
  add(head)
  if pts and type(pts.maxQuantity) == 'number' and pts.maxQuantity ~= s.earned then
    add(string.format('UNEXPECTED: the pane counts %d earned, the challenges %d.', pts.maxQuantity, s.earned))
  end
  local g = {}
  for _, x in ipairs(sortedGroups(s)) do g[#g + 1] = tostring(x.title) .. ' ' .. x.done .. '/' .. x.total end
  add(table.concat(g, ' | '))

  if mode == 'all' then
    -- group by group (the order of the line above), then by sub-group, then in the game's order (P3-1 live: 0.5.0
    -- printed the game's internal order, which mixes the groups)
    local list = {}
    for i, ch in ipairs(out.challenges) do
      if ch.legacy and not ch.excluded then
        local cat = out.categoryById and out.categoryById[ch.category]
        list[#list + 1] = { ch = ch, group = cat and cat.group or 0, cat = ch.category or 0, i = i }
      end
    end
    table.sort(list, function(a, b)
      if a.group ~= b.group then return a.group < b.group end
      if a.cat ~= b.cat then return a.cat < b.cat end
      return a.i < b.i
    end)
    for _, e in ipairs(list) do
      local ch = e.ch
      do
        local cat = out.categoryById and out.categoryById[ch.category]
        local where = cat and cat.title or '?'
        local text
        if ch.completed == true then
          text = 'done'
        elseif ch.steps then
          text = explorerLine(out, ch, true)
        else
          local d, n = stepsOf(ch)
          if n > 1 then text = d .. ' of ' .. n .. ' (left: ' .. leftNames(ch, V.LEFT_NAMES) .. ')' else text = 'not done' end
        end
        add(string.format('[%s] %s: %s', where, tostring(ch.name), text))
      end
    end
  else
    local closest, explorer = V.Closest(out, V.CLOSEST)
    if explorer then closest[#closest + 1] = explorerLine(out, explorer) end
    for _, h in ipairs(recordHints(out)) do closest[#closest + 1] = h end
    for i, c in ipairs(closest) do add((i == 1 and 'Closest: ' or '         ') .. c) end
    add('/ei legacy all: every challenge, done or what is left.')
  end
  local nerr = out.calls and out.calls.counts and out.calls.counts.error or 0
  if nerr > 0 then
    local first
    for name, e in pairs(out.calls.errors) do first = first or (name .. ': ' .. tostring(e)) end
    add('UNEXPECTED: ' .. nerr .. ' game call(s) failed; the list may be incomplete. First: ' .. tostring(first))
  end
  local nref = out.calls and out.calls.counts and out.calls.counts.refused or 0
  if nref > 0 then add('UNEXPECTED: ' .. nref .. ' call(s) refused by the limits.') end
  return lines
end

--- /ei legacy [all]
function V.Command(mode)
  local ok, why = P.Legacy.Read(function(out)
    for _, l in ipairs(V.Lines(out, mode)) do P.Print(l) end
  end)
  if ok then
    if P.Legacy.busy then P.Print('legacy: reading (about 2 seconds).') end
  elseif why == 'busy' then
    P.Print('legacy: already reading; the answer comes in a moment.')
  elseif why == 'combat' then
    P.Print('legacy: not in combat; try again after combat.')
  end
end
