local ADDON, EI = ...
-- EmpireIntel / Core / Views.lua                                         (Phase 2, increment P2-3)
--
-- PURPOSE
--   /ei unlock, /ei rest, /ei milestones (Phase2_Plan.md section 6, approved Q-P2-3, Q-P2-3a, Q-P2-3b).
--
-- RULES
--   * The character list is the one /ei alts shows (Alts.Collect: own records plus DataStore, newer value wins).
--   * No new game call and no DataStore call: the only live read is the player's own progress (P.Unit.Progress),
--     already used by the snapshot. Nothing is written to saved data.
--   * Every worked-out number says "estimate"; the milestones header carries R.LABEL_RULES and the rest header R.LABEL_REST.

EI = EI or {}
local P = EI.Platform
local R = EI.Rules
assert(P and R and EI.Alts and EI.Commands, 'load order: Platform, Rules, Commands, Alts, Views')

local V = {}
EI.Views = V

local function ago(t) return EI.Commands.Ago(t) end
local function className(c) return R.CLASS_NAMES[c] or tostring(c or 'class?') end
local function who(row) return tostring(row.name or 'name unknown') end
local function levels(xp, bar) return string.format('%.2f levels', xp / bar) end

-- rows plus the player's live progress on the player's row
local function collect()
  local rows, ds, dup, playerGuid = EI.Alts.Collect()
  local live = nil
  for _, r in ipairs(rows) do
    if r.guid ~= nil and r.guid == playerGuid then
      local ok, prog = pcall(P.Unit.Progress)
      if ok and type(prog) == 'table' then
        live = r
        r.isPlayer = true
        if type(prog.level) == 'number' then r.level = prog.level end
        if type(prog.xpMax) == 'number' and prog.xpMax > 0 then r.xpMax = prog.xpMax; r.xp = prog.xp end
        r.rest, r.resting, r.liveRest = prog.rest, prog.resting, true
      end
    end
  end
  return rows, ds, live
end

V.Collect = collect

local function sayer(lines)
  return function(s) lines[#lines + 1] = s; P.Print(s) end
end

---------------------------------------------------------------------------
-- /ei unlock
---------------------------------------------------------------------------
function V.Unlock()
  local lines = {}
  local say = sayer(lines)
  local rows = collect()
  local best, reached = nil, {}
  for _, r in ipairs(rows) do
    if type(r.level) == 'number' then
      if r.level >= R.UNLOCK_LEVEL then reached[#reached + 1] = r end
      if not best or r.level > best.level
        or (r.level == best.level and (r.xp or 0) / (r.xpMax or 1) > (best.xp or 0) / (best.xpMax or 1)) then
        best = r
      end
    end
  end
  if #rows == 0 or not best then say('unlock: no characters known yet.'); return lines end
  if #reached > 0 then
    table.sort(reached, function(a, b) return a.level > b.level end)
    local first = reached[1]
    local parts = {}
    for _, r in ipairs(reached) do parts[#parts + 1] = who(r) .. ' ' .. className(r.class) .. ' ' .. r.level end
    say(string.format('unlock: Legacy is unlocked: %s reached %d (seen %s). Game rule: the first character to %d unlocks it.',
      table.concat(parts, ', '), R.UNLOCK_LEVEL, first.isPlayer and 'now' or ago(first.at), R.UNLOCK_LEVEL))
    return lines
  end
  local togo = R.UNLOCK_LEVEL - best.level
  local bar = ''
  if type(best.xp) == 'number' and type(best.xpMax) == 'number' then
    bar = string.format(', %d XP left in level %d', best.xpMax - best.xp, best.level)
  end
  say(string.format('unlock: not yet. Closest: %s %s %d, %d level%s to go%s (%s). Game rule: the first character to %d unlocks Legacy.',
    who(best), className(best.class), best.level, togo, togo == 1 and '' or 's', bar,
    best.isPlayer and 'this character' or ('seen ' .. ago(best.at)), R.UNLOCK_LEVEL))
  return lines
end

---------------------------------------------------------------------------
-- /ei rest
---------------------------------------------------------------------------
local function restingText(v)
  return (v == true and 'resting') or (v == false and 'not resting') or 'resting unknown'
end

function V.RestLine(r, now)
  local head = string.format('%s %s %s: ', who(r), className(r.class), tostring(r.level or '?'))
  if type(r.level) == 'number' and r.level >= R.MAX_LEVEL then return head .. 'max level, no rested XP [' .. r.src .. ']' end
  local bar = r.xpMax
  local function amount(x)
    if bar then return x .. ' XP (' .. levels(x, bar) .. ')' end
    return x .. ' XP'
  end
  if r.liveRest then
    local v = type(r.rest) == 'number' and amount(r.rest) or 'none reported'
    return head .. 'now ' .. v .. ', ' .. restingText(r.resting) .. ' [this character, live]'
  end
  local measured
  if type(r.rest) == 'number' then measured = amount(r.rest)
  elseif r.src == 'self' then measured = 'none reported'
  else measured = 'unknown' end
  local text = head .. 'measured ' .. measured .. ' ' .. ago(r.restAt) .. ', ' .. restingText(r.resting)
  local p, capped = R.ProjectRest(r.rest, bar, r.resting, r.restAt, now, r.src == 'self')
  if p then
    text = text .. ' -> now about ' .. amount(p) .. (capped and ' (at the 1.5-level cap)' or '') .. ' [estimate]'
    if r.resting == nil then text = text .. ' (resting unknown: outside rate used)' end
  elseif type(r.level) == 'number' and not bar then
    text = text .. ' -> no projection: XP bar not measured at level ' .. r.level
  else
    text = text .. ' -> no projection: no reading'
  end
  return text .. ' [' .. r.src .. ']'
end

function V.Rest()
  local lines = {}
  local say = sayer(lines)
  local rows = collect()
  if #rows == 0 then say('rest: no characters known yet.'); return lines end
  say('rest ' .. R.LABEL_REST .. ':')
  local now = (P.Now())
  for _, r in ipairs(rows) do say(V.RestLine(r, now)) end
  return lines
end

---------------------------------------------------------------------------
-- /ei milestones
---------------------------------------------------------------------------
local function plural(n, word) return n .. ' ' .. word .. (n == 1 and '' or 's') end

function V.Milestones()
  local lines = {}
  local say = sayer(lines)
  local rows = collect()
  say('milestones ' .. R.LABEL_RULES .. ':')
  -- classes: the best character of each class
  local bestByClass = {}
  for _, r in ipairs(rows) do
    if type(r.level) == 'number' and r.class then
      local b = bestByClass[r.class]
      if not b or r.level > b.level then bestByClass[r.class] = r end
    end
  end
  local classTotal, classReached = 0, 0
  for _, c in ipairs(R.CLASSES) do
    classTotal = classTotal + #R.CLASS_MILESTONES
    local b = bestByClass[c]
    if not b then
      say(className(c) .. ': no character yet -> next ' .. R.CLASS_MILESTONES[1])
    else
      local nextM, reached = R.Next(R.CLASS_MILESTONES, b.level)
      classReached = classReached + reached
      if nextM then
        say(string.format('%s: %s %d -> next %d (%s)', className(c), who(b), b.level, nextM, plural(nextM - b.level, 'level')))
      else
        say(string.format('%s: %s %d -> all %d done', className(c), who(b), b.level, #R.CLASS_MILESTONES))
      end
    end
  end
  -- crafting: the best skill of each crafting profession
  local bestCraft = {}
  for _, r in ipairs(rows) do
    for _, p in ipairs(type(r.professions) == 'table' and r.professions or {}) do
      local craft = R.Craft(p)
      if craft and type(p.skill) == 'number' then
        local b = bestCraft[craft]
        if not b or p.skill > b.skill then bestCraft[craft] = { row = r, skill = p.skill, max = p.max } end
      end
    end
  end
  local craftTotal, craftReached = 0, 0
  for _, c in ipairs(R.CRAFTS) do
    craftTotal = craftTotal + #R.CRAFT_MILESTONES
    local b = bestCraft[c.name]
    if not b then
      say(c.name .. ': nobody has it yet -> next ' .. R.CRAFT_MILESTONES[1])
    else
      local nextM, reached = R.Next(R.CRAFT_MILESTONES, b.skill)
      craftReached = craftReached + reached
      local skill = b.skill .. ((type(b.max) == 'number' and b.max > 0) and ('/' .. b.max) or '')
      if nextM then
        local s = string.format('%s: %s %s -> next %d (%d to go)', c.name, who(b.row), skill, nextM, nextM - b.skill)
        if type(b.max) == 'number' and b.max > 0 and b.max < nextM then s = s .. '; train to raise max ' .. b.max end
        say(s)
      else
        say(string.format('%s: %s %s -> all %d done', c.name, who(b.row), skill, #R.CRAFT_MILESTONES))
      end
    end
  end
  say(string.format('Classes %d of %d, crafting %d of %d. About %s from these two groups [estimate]. '
    .. 'PvP, dungeons, raids and adventure (20 points) are not tracked yet.',
    classReached, classTotal, craftReached, craftTotal, plural(classReached + craftReached, 'Legacy point')))
  return lines
end
