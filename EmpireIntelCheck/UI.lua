local ADDON, NS = ...
-- EmpireIntelCheck / UI.lua                                              (0.1.9-tp1, Q-G1, D-055, D-056)
--
-- PURPOSE
--   The UI checks of Phase2_Plan.md 8.3.4, run before any window code exists (P2-4b). Each check records what the
--   game returned: present (with the value or type), nothing (the function exists but returned nothing, for example
--   an atlas name the client does not know), absent (the name does not exist), or failed (the call raised, with the
--   error text). Nothing is assumed; a check that did not run says why.
--
-- LIMITS
--   * Existence checks; read-only getters with no argument or with 'player' or a fixed name; hidden test widgets.
--   * Test widgets are made once per session under one parent frame that is hidden at once and never shown; no
--     widget is anchored, sized or shown, and nothing is moved (StartMoving is checked for presence only). The
--     EditBox is made under the hidden parent, so it can never take the keyboard.
--   * Not in combat (the run says "skipped: combat").
--   * No addon's code is called: ElvUI and DataStore are checked for presence only. Other addons' TOC fields are read
--     with C_AddOns.GetAddOnMetadata (a read).
--   * Saved: the full results of the latest check (db.uiLatest), the counts on each run (run.ui), and per character
--     GUID the identity values (db.uiChars). No names are saved.

local U, C, A = NS.U, NS.Core, NS.PartA
local UI = {}
NS.UI = UI

UI.TEXTURE = 'Interface\\AddOns\\EmpireIntelCheck\\Media\\Test'       -- an 8x8 flat-colour TGA shipped in this folder
UI.MISSING = 'Interface\\AddOns\\EmpireIntelCheck\\Media\\NoSuchFile'   -- for comparison: a file that does not exist
UI.RACES = { 'human', 'orc', 'dwarf', 'nightelf', 'scourge', 'undead', 'tauren', 'gnome', 'troll' }
UI.CLASSES = { 'WARRIOR', 'PALADIN', 'HUNTER', 'ROGUE', 'PRIEST', 'SHAMAN', 'MAGE', 'WARLOCK', 'DRUID' }
UI.FACTION_ATLASES = { 'AllianceEmblem', 'HordeEmblem' }
UI.MAX_ADDONS = 200

local widgets = nil        -- made once per session

-- one result from a code of A.Call (or the same shape)
local function result(code, v)
  if code == 'not_found' then return { r = 'absent' } end
  if code == 'not_function' then return { r = 'present', v = '(not a function)' } end
  if code == 'error' then return { r = 'failed', err = v and v[1] } end
  if code == 'returned_nothing' then return { r = 'nothing' } end
  return { r = 'present', v = v, unreadable = (code == 'unreadable') or nil }
end

-- a global's type (existence check, no call)
local function exists(path)
  local v = U.path(path)
  if v == nil then return { r = 'absent' } end
  return { r = 'present', v = type(v) }
end

-- obj:method(...) under pcall; absent when the object or the method is missing
local function mcall(obj, method, ...)
  if type(obj) ~= 'table' and type(obj) ~= 'userdata' then return { r = 'absent', why = 'no object' } end
  local okF, fn = pcall(function() return obj[method] end)
  if not okF or type(fn) ~= 'function' then return { r = 'absent' } end
  local r = U.pack(pcall(fn, obj, ...))
  if not r[1] then return { r = 'failed', err = U.ascii(tostring(r[2])) } end
  local out = {}
  for i = 2, r.n do out[i - 1] = (U.dump(r[i])) end
  if r.n <= 1 or (r.n == 2 and r[2] == nil) then return { r = 'nothing' } end
  return { r = 'present', v = out }
end

-- method presence only (no call)
local function has(obj, method)
  if type(obj) ~= 'table' and type(obj) ~= 'userdata' then return { r = 'absent', why = 'no object' } end
  local ok, fn = pcall(function() return obj[method] end)
  if ok and type(fn) == 'function' then return { r = 'present', v = 'function' } end
  return { r = 'absent' }
end

local function makeWidgets()
  local out = {}
  local create = U.path('CreateFrame')
  if type(create) ~= 'function' then return nil, { ['CreateFrame Frame'] = exists('CreateFrame') } end
  local w = { created = out }
  local okP, parent = pcall(create, 'Frame')
  out['CreateFrame Frame'] = okP and parent and { r = 'present', v = mcall(parent, 'GetObjectType').v } or { r = 'failed', err = U.ascii(tostring(parent)) }
  if not okP or not parent then return nil, out end
  pcall(function() parent:Hide() end)                    -- hidden at once; never shown
  w.parent = parent
  for _, kind in ipairs({ 'Button', 'EditBox', 'ScrollFrame' }) do
    local ok, f = pcall(create, kind, nil, parent)
    if ok and f then
      w[kind] = f
      out['CreateFrame ' .. kind] = { r = 'present', v = mcall(f, 'GetObjectType').v }
    else
      out['CreateFrame ' .. kind] = { r = 'failed', err = U.ascii(tostring(f)) }
    end
  end
  if w.EditBox then
    pcall(function() w.EditBox:SetAutoFocus(false) end)
    pcall(function() w.EditBox:ClearFocus() end)
  end
  local okT, tex = pcall(function() return parent:CreateTexture() end)
  out['Frame:CreateTexture'] = (okT and tex) and { r = 'present' } or { r = 'failed', err = U.ascii(tostring(tex)) }
  if okT and tex then w.tex = tex end
  local okT2, tex2 = pcall(function() return parent:CreateTexture() end)
  if okT2 and tex2 then w.tex2 = tex2 end
  local okP2, portrait = pcall(function() return parent:CreateTexture() end)
  if okP2 and portrait then w.portrait = portrait end
  local okS, fs = pcall(function() return parent:CreateFontString() end)
  out['Frame:CreateFontString'] = (okS and fs) and { r = 'present' } or { r = 'failed', err = U.ascii(tostring(fs)) }
  if okS and fs then w.fs = fs end
  return w, out
end

local function atlas(name) return result(A.Call('C_Texture.GetAtlasInfo', name)) end

--- Runs every check. Returns the results table (saved as run.ui).
function UI.Run()
  local res = { at = U.wall(), version = NS.VERSION, checks = {}, counts = { present = 0, nothing = 0, absent = 0, failed = 0 } }
  if U.inCombat() then res.skipped = 'combat'; return res end
  local c = res.checks

  -- widgets with no template (8.3.1)
  if widgets == nil then
    local made, created = makeWidgets()
    widgets = made or { created = created }
  end
  local w = widgets
  for k, v in pairs(w.created or {}) do c[k] = v end
  local f = w.parent
  for _, m in ipairs({ 'SetMovable', 'RegisterForDrag', 'StartMoving', 'StopMovingOrSizing', 'EnableMouse', 'EnableMouseWheel', 'SetClampedToScreen' }) do
    c['Frame:' .. m] = has(f, m)
  end
  c['Button:RegisterForClicks'] = has(w.Button, 'RegisterForClicks')
  c['EditBox:SetAutoFocus'] = has(w.EditBox, 'SetAutoFocus')
  c['ScrollFrame:SetScrollChild'] = has(w.ScrollFrame, 'SetScrollChild')
  c['ScrollFrame:SetVerticalScroll'] = has(w.ScrollFrame, 'SetVerticalScroll')
  c['Texture:SetColorTexture'] = mcall(w.tex, 'SetColorTexture', 0.1, 0.1, 0.12, 1)
  c['Texture:SetTexture (file in this folder)'] = mcall(w.tex, 'SetTexture', UI.TEXTURE)
  c['Texture:GetTexture after it'] = mcall(w.tex, 'GetTexture')
  c['Texture:SetTexture (missing file)'] = mcall(w.tex2, 'SetTexture', UI.MISSING)
  c['Texture:GetTexture after missing'] = mcall(w.tex2, 'GetTexture')
  c['Texture:SetTexCoord'] = mcall(w.tex, 'SetTexCoord', 0, 0.5, 0, 0.5)
  c['Texture:GetTexCoord'] = mcall(w.tex, 'GetTexCoord')
  c['Texture:SetAtlas'] = has(w.tex, 'SetAtlas')
  c['CreateFont'] = exists('CreateFont')
  c['FontString:SetFont'] = mcall(w.fs, 'SetFont', 'Fonts\\FRIZQT__.TTF', 12, '')
  c['FontString:GetFont'] = mcall(w.fs, 'GetFont')

  -- the live character's portrait
  c['SetPortraitTexture player'] = result(A.Call('SetPortraitTexture', w.portrait, 'player'))
  c['portrait GetTexture after it'] = mcall(w.portrait, 'GetTexture')

  -- race, sex, faction, ruleset of the live character
  local _, race = A.Call('UnitRace', 'player')
  c['UnitRace player'] = result(A.Call('UnitRace', 'player'))
  c['UnitSex player'] = result(A.Call('UnitSex', 'player'))
  c['UnitFactionGroup player'] = result(A.Call('UnitFactionGroup', 'player'))
  c['UnitClass player'] = result(A.Call('UnitClass', 'player'))
  c['C_GameRules.IsHardcoreActive'] = result(A.Call('C_GameRules.IsHardcoreActive'))
  c['C_GameRules.GetForeverExperiencePreset'] = result(A.Call('C_GameRules.GetForeverExperiencePreset'))
  c['C_GameRules.IsSelfFoundAllowed'] = result(A.Call('C_GameRules.IsSelfFoundAllowed'))
  c['GetRealmName'] = result(A.Call('GetRealmName'))
  c['GetNormalizedRealmName'] = result(A.Call('GetNormalizedRealmName'))
  -- the names C_GameRules has (listed, not called), for a realm-type or ruleset getter not known yet
  local gr = U.path('C_GameRules')
  if type(gr) == 'table' then
    local names = {}
    pcall(function() for k, v in pairs(gr) do if type(k) == 'string' and type(v) == 'function' then names[#names + 1] = k end end end)
    table.sort(names)
    c['C_GameRules members'] = { r = 'present', v = names }
  else
    c['C_GameRules members'] = { r = 'absent' }
  end

  -- race icons (for logged-out alts), class icons and colours, faction emblems
  c['C_Texture.GetAtlasInfo'] = exists('C_Texture.GetAtlasInfo')
  for _, r in ipairs(UI.RACES) do
    for _, g in ipairs({ 'male', 'female' }) do
      c['atlas raceicon-' .. r .. '-' .. g] = atlas('raceicon-' .. r .. '-' .. g)
    end
  end
  c['RACE_ICON_TCOORDS'] = exists('RACE_ICON_TCOORDS')
  local live = race and race[2]
  if type(live) == 'string' then
    local t = U.path('RACE_ICON_TCOORDS')
    local key = string.upper(live) .. '_MALE'
    c['RACE_ICON_TCOORDS ' .. key] = type(t) == 'table' and result('ok', { (U.dump(t[key])) }) or { r = 'absent' }
  end
  c['CLASS_ICON_TCOORDS'] = exists('CLASS_ICON_TCOORDS')
  local ct = U.path('CLASS_ICON_TCOORDS')
  local rc = U.path('RAID_CLASS_COLORS')
  c['RAID_CLASS_COLORS'] = exists('RAID_CLASS_COLORS')
  c['C_ClassColor.GetClassColor'] = exists('C_ClassColor.GetClassColor')
  for _, cl in ipairs(UI.CLASSES) do
    c['atlas classicon-' .. string.lower(cl)] = atlas('classicon-' .. string.lower(cl))
    if type(ct) == 'table' then c['CLASS_ICON_TCOORDS ' .. cl] = result('ok', { (U.dump(ct[cl])) }) end
    if type(rc) == 'table' then
      local col = rc[cl]
      c['RAID_CLASS_COLORS ' .. cl] = type(col) == 'table' and result('ok', { { r = col.r, g = col.g, b = col.b } }) or { r = 'absent' }
    end
    local code, v = A.Call('C_ClassColor.GetClassColor', cl)
    local col = v and v[1]
    if (code == 'ok' or code == 'unreadable') and type(col) == 'table' then     -- a colour object carries methods
      c['C_ClassColor ' .. cl] = { r = 'present', v = { r = col.r, g = col.g, b = col.b } }
    else
      c['C_ClassColor ' .. cl] = result(code, v)
    end
  end
  for _, a in ipairs(UI.FACTION_ATLASES) do c['atlas ' .. a] = atlas(a) end
  for _, fac in ipairs({ 'Alliance', 'Horde' }) do
    local t = w['tex' .. fac]
    if not t and w.parent then
      local ok, tx = pcall(function() return w.parent:CreateTexture() end)
      if ok then t = tx; w['tex' .. fac] = tx end
    end
    c['SetTexture UI-PVP-' .. fac] = mcall(t, 'SetTexture', 'Interface\\TargetingFrame\\UI-PVP-' .. fac)
    c['GetTexture UI-PVP-' .. fac] = mcall(t, 'GetTexture')
  end

  -- Escape, compartment, minimap, tooltip, ElvUI
  local sf = U.path('UISpecialFrames')
  c['UISpecialFrames'] = type(sf) == 'table' and { r = 'present', v = { type = 'table', count = #sf } } or exists('UISpecialFrames')
  c['AddonCompartmentFrame'] = exists('AddonCompartmentFrame')
  c['AddonCompartmentFrame:RegisterAddon'] = has(U.path('AddonCompartmentFrame'), 'RegisterAddon')
  local declaring, errors, firstError = {}, 0, nil
  local codeN, vN = A.Call('C_AddOns.GetNumAddOns')
  local n = codeN == 'ok' and tonumber(vN[1]) or 0
  for i = 1, math.min(n, UI.MAX_ADDONS) do
    local code, v = A.Call('C_AddOns.GetAddOnMetadata', i, 'AddonCompartmentFunc')
    if code == 'ok' and type(v[1]) == 'string' and v[1] ~= '' then
      local _, info = A.Call('C_AddOns.GetAddOnInfo', i)
      declaring[#declaring + 1] = info and info[1] or i
    elseif code == 'error' then
      errors = errors + 1
      firstError = firstError or (v and v[1])
    end
  end
  c['TOC AddonCompartmentFunc declared by'] = { r = (codeN == 'ok') and (errors > 0 and 'failed' or 'present') or 'absent',
    v = { addons = n, declaring = declaring, errors = errors }, err = firstError }
  c['Minimap'] = exists('Minimap')
  c['GetMinimapShape'] = result(A.Call('GetMinimapShape'))
  c['GetCursorPosition'] = result(A.Call('GetCursorPosition'))
  c['GameTooltip'] = exists('GameTooltip')
  c['GameTooltip:SetOwner'] = has(U.path('GameTooltip'), 'SetOwner')
  c['GameTooltip:AddLine'] = has(U.path('GameTooltip'), 'AddLine')
  c['ElvUI loaded'] = result(A.Call('C_AddOns.IsAddOnLoaded', 'ElvUI'))
  c['ElvUI global'] = exists('ElvUI')
  -- what DataStore offers for alts (presence of the getters only; DataStore is never called here)
  local ds = U.path('DataStore')
  for _, m in ipairs({ 'GetCharacterFaction', 'GetCharacterRace', 'GetCharacterGender' }) do c['DataStore:' .. m] = has(ds, m) end

  for _, v in pairs(c) do res.counts[v.r] = (res.counts[v.r] or 0) + 1 end
  -- the identity values in short, for the per-character record
  local function first(name) local x = c[name]; return x and x.r == 'present' and type(x.v) == 'table' and x.v or nil end
  local rv, sv, fv = first('UnitRace player'), first('UnitSex player'), first('UnitFactionGroup player')
  local hv, pv, sfv = first('C_GameRules.IsHardcoreActive'), first('C_GameRules.GetForeverExperiencePreset'), first('C_GameRules.IsSelfFoundAllowed')
  res.identity = { race = rv and rv[2], raceId = rv and rv[3], sex = sv and sv[1], faction = fv and fv[1],
    hardcore = hv and hv[1], preset = pv and pv[1], selfFound = sfv and sfv[1],
    portrait = (first('portrait GetTexture after it') or {})[1] }
  return res
end

--- One chat line for a result.
function UI.Line(res)
  if res.skipped then return 'UI checks skipped (' .. res.skipped .. '); /eicheck ui after combat' end
  local id = res.identity or {}
  return string.format('UI checks: %d present, %d returned nothing, %d absent, %d failed; portrait %s; ruleset hardcore=%s preset=%s; ElvUI %s',
    res.counts.present or 0, res.counts.nothing or 0, res.counts.absent or 0, res.counts.failed or 0,
    id.portrait ~= nil and 'drawn' or 'not drawn', tostring(id.hardcore), tostring(id.preset),
    (res.checks['ElvUI loaded'] and res.checks['ElvUI loaded'].v and res.checks['ElvUI loaded'].v[1] == true) and 'loaded' or 'not loaded')
end

--- Saves a result: the latest in full, and the identity per character GUID. Returns the counts for the run.
function UI.Store(res, guid)
  local db = C.DB()
  db.uiLatest = res
  if type(guid) == 'string' and res.identity then
    db.uiChars = type(db.uiChars) == 'table' and db.uiChars or {}
    local e = {}
    for k, v in pairs(res.identity) do e[k] = v end
    e.at = res.at
    db.uiChars[guid] = e
  end
  return { counts = res.counts, skipped = res.skipped }
end

--- /eicheck ui: run the checks now and print one line.
function UI.Command(guid)
  local res = UI.Run()
  UI.Store(res, guid)
  return UI.Line(res)
end

--- Test helper: forget the session's widgets.
function UI.Reset() widgets = nil end
