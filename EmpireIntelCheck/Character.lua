local ADDON, NS = ...
-- EmpireIntelCheck / Character.lua
-- R-1 rested XP, P-1 professions, E-1 fallback estimate (Architecture.md sections 4, 6, 9).
-- The Legacy rules below come from web search summaries and are UNVERIFIED (Compatibility_Notes section 5).

local U = NS.U
local A = NS.PartA
local Ch = {}
NS.Character = Ch

Ch.RULES = {
  source = 'web search summaries 2026-11-03, unverified',
  totalChallenges = 65,
  classLevels = { 25, 45, 60 },
  classes = { 'WARRIOR', 'PALADIN', 'HUNTER', 'ROGUE', 'PRIEST', 'SHAMAN', 'MAGE', 'WARLOCK', 'DRUID' },
  craftSkills = { 150, 225, 300 },
  -- skill line id (classic ids, assumed) -> enUS name; matched by id or by name
  crafts = { [171] = 'Alchemy', [164] = 'Blacksmithing', [333] = 'Enchanting', [202] = 'Engineering',
    [165] = 'Leatherworking', [197] = 'Tailoring' },
  notEstimated = 'about 20 challenges of unknown kinds',
  -- Rested XP rule (assumed classic): 5% of a level per 8 h resting, a quarter of that elsewhere, cap 150%.
  restPer8h = 0.05, restOutsideFactor = 0.25, restCap = 1.5,
}

local function v1(path, ...)
  local code, v = A.Call(path, ...)
  return v and v[1], code
end

---------------------------------------------------------------------------
-- R-1 rested XP
---------------------------------------------------------------------------
function Ch.Rest()
  local r = {}
  r.level, r.codeLevel = v1('UnitLevel', 'player')
  r.xp = v1('UnitXP', 'player')
  r.xpMax = v1('UnitXPMax', 'player')
  r.exhaustion, r.codeExhaustion = v1('GetXPExhaustion')
  r.resting, r.codeResting = v1('IsResting')
  local code, state = A.Call('GetRestState')
  r.restState, r.codeRestState = state, code
  r.at = U.wall()
  return r
end

-- Projection from the last logout snapshot, assumed classic rule; nil when not comparable.
function Ch.Project(last, now)
  if type(last) ~= 'table' or type(now) ~= 'table' then return nil end
  if last.level ~= now.level or type(last.xpMax) ~= 'number' or last.xpMax <= 0 then return nil end
  if type(last.at) ~= 'number' or type(now.at) ~= 'number' or now.at < last.at then return nil end
  local R = Ch.RULES
  local hours = (now.at - last.at) / 3600
  local perHour = last.xpMax * R.restPer8h / 8
  if not last.resting then perHour = perHour * R.restOutsideFactor end
  local base = tonumber(last.exhaustion) or 0
  local projected = math.min(base + perHour * hours, last.xpMax * R.restCap)
  local measured = tonumber(now.exhaustion)
  return { hours = hours, projected = math.floor(projected + 0.5), measured = now.exhaustion,
    diff = measured and math.floor(measured - projected + 0.5) or nil, rule = 'assumed classic' }
end

---------------------------------------------------------------------------
-- P-1 professions
---------------------------------------------------------------------------
-- Return order of GetProfessionInfo in the retail engine (assumed; raw values are kept too).
Ch.PROF_FIELDS = { 'name', 'icon', 'skill', 'maxSkill', 'numAbilities', 'spellOffset', 'skillLine', 'skillModifier',
  'specializationIndex', 'specializationOffset', 'skillLineName' }

function Ch.Professions()
  local out = { slots = {}, list = {} }
  local code, idx = A.Call('GetProfessions')
  out.code = code
  if type(idx) ~= 'table' then return out end
  out.slots = idx
  for slot = 1, 6 do
    local i = idx[slot]
    if type(i) == 'number' then
      local c, vals = A.Call('GetProfessionInfo', i)
      local row = { slot = slot, index = i, code = c, raw = vals }
      if type(vals) == 'table' then
        for n, field in ipairs(Ch.PROF_FIELDS) do row[field] = vals[n] end
      end
      table.insert(out.list, row)
    end
  end
  return out
end

function Ch.CraftKey(row)
  local R = Ch.RULES
  if type(row.skillLine) == 'number' and R.crafts[row.skillLine] then return R.crafts[row.skillLine] end
  for _, name in pairs(R.crafts) do
    if row.name == name then return name end
  end
  return nil
end

---------------------------------------------------------------------------
-- Snapshot of the current character (kept per GUID so the estimate covers every character seen)
---------------------------------------------------------------------------
function Ch.Snapshot(guid)
  local rest = Ch.Rest()
  local profs = Ch.Professions()
  local _, cls = A.Call('UnitClass', 'player')
  local _, names = A.Call('UnitName', 'player')
  local snap = { at = U.wall(), level = rest.level, class = cls and cls[2], name = names and names[1],
    crafts = {} }
  for _, row in ipairs(profs.list) do
    local key = Ch.CraftKey(row)
    if key and type(row.skill) == 'number' then snap.crafts[key] = row.skill end
  end
  if guid then NS.Core.DB().chars[guid] = snap end
  return snap, rest, profs
end

---------------------------------------------------------------------------
-- E-1 estimate: a LOWER BOUND of Legacy points earned, from class levels and crafting skill only
---------------------------------------------------------------------------
function Ch.Estimate(extra)
  local R = Ch.RULES
  local maxLevel, maxSkill = {}, {}
  local sources = { self = 0, datastore = 0 }
  local function addChar(class, level, crafts, src)
    if type(class) == 'string' and type(level) == 'number' then
      if not maxLevel[class] or level > maxLevel[class] then maxLevel[class] = level end
    end
    if type(crafts) == 'table' then
      for name, skill in pairs(crafts) do
        if type(skill) == 'number' and (not maxSkill[name] or skill > maxSkill[name]) then maxSkill[name] = skill end
      end
    end
    sources[src] = sources[src] + 1
  end
  for _, c in pairs(NS.Core.DB().chars) do addChar(c.class, c.level, c.crafts, 'self') end
  if type(extra) == 'table' then
    for _, c in ipairs(extra) do addChar(c.class, c.level, c.crafts, 'datastore') end
  end
  local total, classPts, craftPts = 0, {}, {}
  for _, cls in ipairs(R.classes) do
    local n = 0
    for _, lv in ipairs(R.classLevels) do if (maxLevel[cls] or 0) >= lv then n = n + 1 end end
    if n > 0 then classPts[cls] = { maxLevel = maxLevel[cls], points = n } end
    total = total + n
  end
  for _, name in pairs(R.crafts) do
    local n = 0
    for _, sk in ipairs(R.craftSkills) do if (maxSkill[name] or 0) >= sk then n = n + 1 end end
    if n > 0 then craftPts[name] = { maxSkill = maxSkill[name], points = n } end
    total = total + n
  end
  return { total = total, ofChallenges = R.totalChallenges, maxEstimable = #R.classes * #R.classLevels + 6 * #R.craftSkills,
    classes = classPts, crafts = craftPts, sources = sources, kind = 'estimate, lower bound',
    note = 'class levels and crafting skill only; ' .. R.notEstimated .. ' not estimated; rules unverified' }
end

-- Milestone crossing check for automatic reruns (limit 8).
function Ch.CrossedLevel(level)
  for _, lv in ipairs(Ch.RULES.classLevels) do if level == lv then return true end end
  return false
end

function Ch.CrossedSkill(before, after)
  if type(before) ~= 'table' or type(after) ~= 'table' then return false end
  for name, skill in pairs(after) do
    local old = before[name] or 0
    for _, sk in ipairs(Ch.RULES.craftSkills) do
      if old < sk and skill >= sk then return true end
    end
  end
  return false
end
