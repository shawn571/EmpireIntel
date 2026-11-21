local ADDON, EI = ...
-- EmpireIntel / Core / Alts.lua                                          (Phase 2, increment P2-2)
--
-- PURPOSE
--   /ei alts: every character, from EmpireIntel's own records merged with what the bridge reads live.
--
-- MERGE RULE (per GUID; Phase2_Plan.md section 5, approved Q-P2-2)
--   * The newer source is the base: EmpireIntel's lastSeen against the bridge's time. A tie goes to EmpireIntel.
--   * Name, realm, class, level and professions the base does not have come from the other source, and the line
--     says so with that source and its age. Rested XP and resting come from the base only (they change with time).
--   * A name "Unknown" never replaces a known one.
--   * A character only the bridge knows is shown, never stored. Nothing here writes to saved data.
--   * Bridge errors are shown as UNEXPECTED lines; the rest of the list still answers.

EI = EI or {}
local P = EI.Platform
assert(P and EI.Store and EI.Commands and EI.DataStoreBridge, 'load order: Platform, Store, Bridge, Commands, Alts')

local A = {}
EI.Alts = A

A.MAX_LINES = 40
local FIELDS = { 'name', 'realm', 'class', 'level', 'professions' }

local function knownName(v) return type(v) == 'string' and v ~= '' and v ~= 'Unknown' end

-- Of two bridge entries with one GUID, keep the one with a known name, then the newer.
local function better(a, b)
  if knownName(a.name) ~= knownName(b.name) then return knownName(a.name) and a or b end
  if (a.at or 0) >= (b.at or 0) then return a end
  return b
end

--- Merges own records (roster) with the bridge result. Pure: reads both, writes neither.
-- Returns rows, duplicates (bridge entries that shared a GUID).
function A.Merge(roster, ds)
  local byGuid, rows, dup = {}, {}, 0
  for guid, rec in pairs(type(roster) == 'table' and roster or {}) do
    if type(guid) == 'string' and type(rec) == 'table' then
      local row = { guid = guid, own = rec }
      byGuid[guid] = row
      rows[#rows + 1] = row
    end
  end
  for _, c in ipairs(ds and ds.list or {}) do
    if c.guid then
      local row = byGuid[c.guid]
      if not row then
        row = { guid = c.guid }
        byGuid[c.guid] = row
        rows[#rows + 1] = row
      end
      if row.ds then dup = dup + 1; row.ds = better(row.ds, c) else row.ds = c end
    else
      rows[#rows + 1] = { ds = c, noGuid = true }
    end
  end
  for _, row in ipairs(rows) do
    local own, d = row.own, row.ds
    local ownAt = own and type(own.lastSeen) == 'number' and own.lastSeen or nil
    local dsAt = d and d.at or nil
    local base, other, baseAt, otherAt
    if own and (not d or (ownAt or 0) >= (dsAt or 0)) then
      base, other, baseAt, otherAt, row.src = own, d, ownAt, dsAt, 'self'
    else
      base, other, baseAt, otherAt, row.src = d, own, dsAt, ownAt, 'datastore'
    end
    row.at = baseAt
    row.online = d and d.online or nil
    row.from = {}
    for _, f in ipairs(FIELDS) do
      local v = base[f]
      if f == 'name' and not knownName(v) and other and knownName(other.name) then v = nil end
      if v == nil and other and other[f] ~= nil then
        v = other[f]
        row.from[f] = { src = (row.src == 'self') and 'datastore' or 'self', at = otherAt }
      end
      row[f] = v
    end
    row.rest, row.resting = base.rest, base.resting
    -- format 2 (P2-4a): ruleset, faction, race and sex, from EmpireIntel's own record only
    if own then row.ruleset, row.faction, row.race, row.sex = own.ruleset, own.faction, own.race, own.sex end
    -- P2-4b: DataStore's faction until the character records its own (shown as "faction from DataStore")
    if not row.faction and d and d.faction then row.dsFaction = d.faction end
    -- when the rest was read: EmpireIntel's restAt, or DataStore's time (P2-3 projections start here)
    if row.src == 'self' then row.restAt = type(own.restAt) == 'number' and own.restAt or ownAt else row.restAt = dsAt end
    -- the XP bar only from EmpireIntel's own record, and only when it was measured at the level shown
    if own and type(own.xpMax) == 'number' and own.xpMax > 0 and own.level == row.level then
      row.xpMax = own.xpMax
      if type(own.xp) == 'number' then row.xp = own.xp end
    end
  end
  return rows, dup
end

local function profText(list)
  if type(list) ~= 'table' then return 'professions unknown' end
  if #list == 0 then return 'no professions' end
  local parts = {}
  for _, p in ipairs(list) do
    parts[#parts + 1] = tostring(p.name) .. (p.skill and (' ' .. p.skill .. (p.max and p.max > 0 and ('/' .. p.max) or '')) or '')
  end
  return table.concat(parts, ', ')
end

--- One chat line for a merged row.
function A.Line(row, isPlayer)
  local ago = EI.Commands.Ago
  local rest
  if type(row.rest) == 'number' then
    rest = 'rested ' .. row.rest .. ' XP'
    if row.xpMax and row.rest > 0 then rest = rest .. string.format(' (%.2f levels)', row.rest / row.xpMax) end
  else
    -- own record: nil means the game reported no rested XP (format 1); from DataStore it is simply unknown
    rest = (row.src == 'self') and 'rested none reported' or 'rested unknown'
  end
  local resting = (row.resting == true and 'resting') or (row.resting == false and 'not resting') or 'resting unknown'
  local when = (isPlayer and 'this character') or (row.online and row.src == 'datastore' and 'online now') or ago(row.at)
  local line = string.format('%s %s %s (%s): %s, %s; %s; %s [%s]',
    tostring(row.name or 'name unknown'), tostring(row.class or 'class?'), tostring(row.level or '?'),
    tostring(row.realm or 'realm unknown'), rest, resting, profText(row.professions), when, row.src)
  local notes = {}
  for _, f in ipairs(FIELDS) do
    local fr = row.from[f]
    if fr then notes[#notes + 1] = f .. ' from ' .. fr.src .. ', ' .. ago(fr.at) end
  end
  if row.noGuid then notes[#notes + 1] = 'no GUID in DataStore, not matched' end
  if #notes > 0 then line = line .. ' (' .. table.concat(notes, '; ') .. ')' end
  return line
end

local function sortRows(rows, playerGuid)
  table.sort(rows, function(a, b)
    local pa, pb = a.guid ~= nil and a.guid == playerGuid, b.guid ~= nil and b.guid == playerGuid
    if pa ~= pb then return pa end
    if (a.at or 0) ~= (b.at or 0) then return (a.at or 0) > (b.at or 0) end
    return tostring(a.name) < tostring(b.name)
  end)
end

--- The merged, sorted character list (shared by /ei alts and the P2-3 views). Reads only.
-- Returns rows, the bridge result, duplicates, the player's GUID.
function A.Collect()
  local roster = EI.Store.Section('roster')
  local okR, ds = pcall(EI.DataStoreBridge.Read)
  if not okR then ds = { present = true, list = {}, errors = 1, firstError = tostring(ds), missing = {} } end
  local rows, dup = A.Merge(roster, ds)
  local player = P.Player()
  local playerGuid = player and player.guid
  sortRows(rows, playerGuid)
  return rows, ds, dup, playerGuid
end

--- /ei alts. Returns the lines printed (for tests).
function A.Show()
  local lines = {}
  local function say(s) lines[#lines + 1] = s; P.Print(s) end
  local rows, ds, dup, playerGuid = A.Collect()

  local own, dsOnly = 0, 0
  for _, r in ipairs(rows) do if r.own then own = own + 1 else dsOnly = dsOnly + 1 end end
  local head = string.format('alts: %d characters (%d recorded by EmpireIntel, %d from DataStore only).', #rows, own, dsOnly)
  if not ds.present then
    head = head .. ' DataStore is not installed: EmpireIntel records only.'
  elseif ds.cannotList then
    head = head .. ' DataStore is installed but cannot list characters.'
  else
    head = head .. ' DataStore read live, not stored.'
  end
  say(head)
  if ds.cannotList then say('UNEXPECTED: DataStore has no IterateCharacters; only EmpireIntel records are shown.') end
  if (ds.errors or 0) > 0 then
    say(string.format('UNEXPECTED: DataStore gave %d error(s); the list may be incomplete. First: %s', ds.errors, tostring(ds.firstError)))
  end
  if dup > 0 then say('UNEXPECTED: ' .. dup .. ' DataStore character(s) share a GUID with another; the one with a known name, then the newer, is shown.') end
  if ds.present and not ds.cannotList and ds.missing.GetCharacterLevel then
    say('Note: DataStore_Characters is not loaded, so DataStore gives names only.')
  end
  if ds.present and not ds.cannotList and ds.missing.GetProfession1Name then
    say('Note: DataStore_Crafts is not loaded, so DataStore gives no professions.')
  end
  if ds.truncated then say('Note: DataStore lists more than ' .. EI.DataStoreBridge.MAX_CHARACTERS .. ' characters; the rest are not read.') end
  for i, r in ipairs(rows) do
    if i > A.MAX_LINES then say('... and ' .. (#rows - A.MAX_LINES) .. ' more.'); break end
    say(A.Line(r, r.guid ~= nil and r.guid == playerGuid))
  end
  if #rows == 0 then say('No characters known yet.') end
  return lines
end
