local ADDON, EI = ...
-- EmpireIntel / Store / Migrations.lua
--
-- PURPOSE
--   The schema migration framework and the database shape.
--
--   Migrations.Register(from, fn, name)   fn(db) upgrades a database from schema `from` to from+1
--   Migrations.Latest()                   the schema this addon writes (highest registered step + 1)
--   Migrations.Plan(from, to) / Run(db, from, to) / Sections() / Check(db) / EnsureShape(db)
--
-- PORTED from GoldIntel GoldIntel/Store/Migrations.lua at commit a21e071 (read-only; GoldIntel unchanged).
-- Changes: sections are those of saved-data format 1 (meta, roster); the GoldIntel schema steps (Phase 1 compat
-- adoption, ledger) are replaced by one step 0 -> 1; no `compat` section.
--
-- RULES
--   * A migration only mutates the table it is given. Store runs it on a COPY and commits only when the whole
--     chain succeeded and validation passed, so a failing migration can never damage saved data.
--   * Steps are contiguous: 0->1, 1->2, ... Unknown keys are preserved by every migration.
--   * Every change of the saved-data format needs the user's approval (D-019).

EI = EI or {}
local P = EI.Platform
assert(P, 'Platform must be loaded before Store/Migrations.lua')

local Mig = {}
EI.Migrations = Mig

local steps = {}      -- from -> { fn = function, name = string }

---------------------------------------------------------------------------
-- Database shape (Contracts F5)
---------------------------------------------------------------------------

-- Saved-data format 1 (approved by the user, Q-P2-1; Phase2_Plan.md section 2, with the realm field).
local FACTORIES = {
  meta = function() return {} end,
  roster = function() return {} end,
}
local NESTED = {}
Mig.SECTION_NAMES = {}
for name in pairs(FACTORIES) do Mig.SECTION_NAMES[#Mig.SECTION_NAMES + 1] = name end
table.sort(Mig.SECTION_NAMES)

--- Registers a section factory so later phases can add sections (Store validates it too).
function Mig.DefineSection(name, factory, nested)
  if type(name) ~= 'string' or name == '' or name == 'schema' then
    return nil, 'invalid section name'
  end
  if FACTORIES[name] then return nil, 'section already defined: ' .. name end
  if type(factory) ~= 'function' then return nil, 'factory must be a function' end
  FACTORIES[name] = factory
  NESTED[name] = nested
  Mig.SECTION_NAMES[#Mig.SECTION_NAMES + 1] = name
  table.sort(Mig.SECTION_NAMES)
  return true
end

--- Fresh default sections (every table is new).
function Mig.Sections()
  local out = {}
  for name, factory in pairs(FACTORIES) do out[name] = factory() end
  return out
end

--- Lists problems without changing anything: { missing = {...}, wrongType = {...} }.
function Mig.Check(db)
  local problems = { missing = {}, wrongType = {} }
  for _, name in ipairs(Mig.SECTION_NAMES) do
    local section = db[name]
    if section == nil then
      problems.missing[#problems.missing + 1] = name
    elseif type(section) ~= 'table' then
      problems.wrongType[#problems.wrongType + 1] = name
    else
      local nested = NESTED[name]
      if nested then
        for _, inner in ipairs(nested) do
          if section[inner] == nil then
            problems.missing[#problems.missing + 1] = name .. '.' .. inner
          elseif type(section[inner]) ~= 'table' then
            problems.wrongType[#problems.wrongType + 1] = name .. '.' .. inner
          end
        end
      end
    end
  end
  return problems
end

--- Adds missing sections and replaces wrong-typed ones. Returns { added = {...}, repaired = {...} }.
-- Existing valid content and unknown keys are never touched.
function Mig.EnsureShape(db)
  local report = { added = {}, repaired = {} }
  for _, name in ipairs(Mig.SECTION_NAMES) do
    local section = db[name]
    if section == nil then
      db[name] = FACTORIES[name]()
      report.added[#report.added + 1] = name
    elseif type(section) ~= 'table' then
      db[name] = FACTORIES[name]()
      report.repaired[#report.repaired + 1] = name
    else
      local nested = NESTED[name]
      if nested then
        for _, inner in ipairs(nested) do
          if section[inner] == nil then
            section[inner] = {}
            report.added[#report.added + 1] = name .. '.' .. inner
          elseif type(section[inner]) ~= 'table' then
            section[inner] = {}
            report.repaired[#report.repaired + 1] = name .. '.' .. inner
          end
        end
      end
    end
  end
  return report
end

---------------------------------------------------------------------------
-- Registry and runner
---------------------------------------------------------------------------

function Mig.Register(from, fn, name)
  if type(from) ~= 'number' or from < 0 or from ~= math.floor(from) then return nil, 'from must be a whole number >= 0' end
  if type(fn) ~= 'function' then return nil, 'migration must be a function' end
  if steps[from] then return nil, 'a migration from ' .. from .. ' is already registered' end
  steps[from] = { fn = fn, name = name or ('v' .. from .. '->v' .. (from + 1)) }
  return true
end

--- The schema this addon writes: the end of the contiguous chain that starts at 0.
function Mig.Latest()
  local v = 0
  while steps[v] do v = v + 1 end
  return v
end

function Mig.Plan(from, to)
  if type(from) ~= 'number' or type(to) ~= 'number' then return nil, 'from and to must be numbers' end
  if from > to then return nil, 'cannot migrate backwards from ' .. from .. ' to ' .. to end
  local plan = {}
  for v = from, to - 1 do
    if not steps[v] then return nil, 'no migration from schema ' .. v end
    plan[#plan + 1] = { from = v, name = steps[v].name }
  end
  return plan
end

--- Runs the chain on `db` (mutating it). Never throws.
function Mig.Run(db, from, to)
  local report = { ok = true, applied = {} }
  local plan, err = Mig.Plan(from, to)
  if not plan then
    report.ok = false
    report.err = err
    return report
  end
  for _, step in ipairs(plan) do
    local ok, stepErr = pcall(steps[step.from].fn, db)
    if not ok then
      report.ok = false
      report.failedAt = step.from
      report.err = tostring(stepErr)
      return report
    end
    db.schema = step.from + 1
    report.applied[#report.applied + 1] = step.name
  end
  return report
end

--- Test helper: remove every step (then Latest() is 0).
function Mig.Reset() steps = {} end

--- Test helper: remove one step (lets a framework test pin an older chain).
function Mig.Remove(from) steps[from] = nil end

---------------------------------------------------------------------------
-- Built-in migration: schema 0 (nothing saved yet) -> schema 1 (format 1: meta, roster)
---------------------------------------------------------------------------

Mig.Register(0, function(db)
  Mig.EnsureShape(db)
end, 'format 1: meta and roster')

if EI.Core then EI.Core.Service('migrations', Mig) end
