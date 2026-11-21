-- EmpireIntel / Tests / test_check_ui.lua
-- EmpireIntelCheck 0.1.9-tp1: the UI checks of Phase2_Plan.md 8.3.4 (Q-G1, D-055, D-056). Each check records what
-- the game returned (present / nothing / absent / failed); test widgets are hidden at once and never shown.
local T, F, root = ...

-- a fake UI layer on top of the base fake client: widgets with methods, textures, atlases, colours, compartment
local function withUI(W, opts)
  opts = opts or {}
  local env = W.env
  W.ui = { made = {}, shows = 0, autoFocus = {}, moved = 0, anchored = 0, setTex = {} }
  local base = env.CreateFrame
  local function texture()
    local t = { path = nil }
    function t:SetColorTexture() return nil end
    function t:SetTexture(p) table.insert(W.ui.setTex, p); if p and p:find('NoSuchFile', 1, true) then return false end; self.path = p; return true end
    function t:GetTexture() return self.path end
    function t:SetTexCoord(a, b, c, d) self.coord = { a, b, c, d } end
    function t:GetTexCoord() local x = self.coord or { 0, 1, 0, 1 }; return x[1], x[3], x[1], x[4], x[2], x[3], x[2], x[4] end
    function t:SetAtlas() end
    return t
  end
  env.CreateFrame = function(kind, name, parent)
    local f = base(kind, name, parent)
    f.kind, f.parent = kind, parent
    f.shown = true                       -- the real client creates frames shown; the check must hide its own
    table.insert(W.ui.made, f)
    local hide = f.Hide
    function f:Show() W.ui.shows = W.ui.shows + 1; self.shown = true end
    function f:Hide() hide(self) end
    function f:GetObjectType() return kind end
    function f:CreateTexture() return texture() end
    function f:CreateFontString() return { SetFont = function(s, p, size) s.font = { p, size }; return true end,
      GetFont = function(s) return s.font and s.font[1], s.font and s.font[2], '' end } end
    for _, m in ipairs({ 'SetMovable', 'RegisterForDrag', 'StopMovingOrSizing', 'EnableMouse', 'EnableMouseWheel', 'SetClampedToScreen',
      'RegisterForClicks', 'SetScrollChild', 'SetVerticalScroll', 'ClearFocus' }) do f[m] = function() end end
    function f:StartMoving() W.ui.moved = W.ui.moved + 1 end
    function f:SetPoint() W.ui.anchored = W.ui.anchored + 1 end
    function f:SetAutoFocus(v) table.insert(W.ui.autoFocus, v) end
    return f
  end
  env.UnitRace = function() return 'Human', 'Human', 1 end
  env.UnitSex = function() return 3 end
  env.UnitFactionGroup = function() return 'Alliance', 'Alliance' end
  env.C_GameRules = { IsHardcoreActive = function() return opts.hardcore or false end,
    GetForeverExperiencePreset = function() return 1 end, IsSelfFoundAllowed = function() return false end,
    SetForeverExperiencePresetPostLogin = function() W.ui.setPreset = true end }
  env.SetPortraitTexture = function(tex, unit) if tex and unit == 'player' then tex.path = 136240 end end
  env.C_Texture = { GetAtlasInfo = function(name)
    if name == 'raceicon-human-male' or name == 'classicon-warrior' then return { width = 64, height = 64, file = 1234 } end
  end }
  env.CLASS_ICON_TCOORDS = { WARRIOR = { 0, 0.25, 0, 0.25 } }
  env.RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
  env.C_ClassColor = { GetClassColor = function(c) if c == 'WARRIOR' then return { r = 0.78, g = 0.61, b = 0.43, GetRGB = function() end } end end }
  env.UISpecialFrames = { 'A', 'B' }
  env.AddonCompartmentFrame = { RegisterAddon = function() W.ui.registered = true end }
  env.Minimap = { shape = 'round' }
  env.GetCursorPosition = function() return 512, 384 end
  if opts.shape then env.GetMinimapShape = function() return opts.shape end end
  env.GameTooltip = { SetOwner = function() end, AddLine = function() end, Show = function() W.ui.tooltipShown = true end }
  table.insert(W.addons, { name = 'SomeCompartmentAddon', loaded = true, compartment = 'SomeCompartmentAddon_OnClick' })
  local meta = env.C_AddOns.GetAddOnMetadata
  env.C_AddOns.GetAddOnMetadata = function(x, field)
    local a = type(x) == 'number' and W.addons[x] or nil
    if field == 'AddonCompartmentFunc' then return a and a.compartment or nil end
    return meta(x, field)
  end
  if opts.elvui then env.ElvUI = { {} }; table.insert(W.addons, { name = 'ElvUI', loaded = true }) end
end

local function session(opts)
  opts = opts or {}
  local W = F.new(opts)
  if opts.ui ~= false then withUI(W, opts) end
  F.load(W)
  W:login()
  W:advance(12)
  W:advance(30)
  return W
end
local function latest(W) return W:db().uiLatest end
local function check(W, name) return latest(W).checks[name] end

T.describe('0.1.9: UI checks (Q-G1), evidence from the client', function()
  local W = session({})
  local run = W:lastRun()
  T.it('run on every check run; full results in uiLatest, counts on the run', function()
    T.truthy(latest(W), 'uiLatest saved')
    T.truthy(run.ui and run.ui.counts, 'counts on the run')
    T.isnil(run.ui.checks, 'not the full results on every run (size cap)')
    T.eq(#run.unexpected, 0)
  end)
  T.it('widgets with no template: Frame, Button, EditBox, ScrollFrame; texture and font calls', function()
    for _, k in ipairs({ 'Frame', 'Button', 'EditBox', 'ScrollFrame' }) do
      T.eq(check(W, 'CreateFrame ' .. k), { r = 'present', v = { k } })
    end
    T.eq(check(W, 'Texture:SetTexture (file in this folder)').v, { true })
    T.eq(check(W, 'Texture:GetTexture after it').v, { 'Interface\\AddOns\\EmpireIntelCheck\\Media\\Test' })
    T.eq(check(W, 'Texture:SetTexture (missing file)').v, { false })
    T.eq(check(W, 'Texture:GetTexture after missing').r, 'nothing')
    T.eq(check(W, 'FontString:SetFont').v, { true })
    T.eq(check(W, 'Frame:StartMoving'), { r = 'present', v = 'function' })
  end)
  T.it('the portrait of the live character: what GetTexture returned after SetPortraitTexture', function()
    T.eq(check(W, 'portrait GetTexture after it').v, { 136240 })
    T.eq(latest(W).identity.portrait, 136240)
  end)
  T.it('race, sex, faction and ruleset: the values the game returned', function()
    T.eq(check(W, 'UnitRace player').v, { 'Human', 'Human', 1 })
    T.eq(check(W, 'UnitSex player').v, { 3 })
    T.eq(check(W, 'C_GameRules.IsHardcoreActive').v, { false })
    T.eq(check(W, 'C_GameRules.GetForeverExperiencePreset').v, { 1 })
    T.eq(check(W, 'C_GameRules members').v, { 'GetForeverExperiencePreset', 'IsHardcoreActive', 'IsSelfFoundAllowed', 'SetForeverExperiencePresetPostLogin' })
    T.isnil(W.ui.setPreset, 'listed, never called')
    local id = latest(W).identity
    T.eq(id.race, 'Human'); T.eq(id.sex, 3); T.eq(id.faction, 'Alliance'); T.eq(id.hardcore, false); T.eq(id.preset, 1)
  end)
  T.it('atlases: a known name is present with its info, an unknown one "returned nothing" (not assumed absent)', function()
    T.eq(check(W, 'atlas raceicon-human-male'), { r = 'present', v = { { width = 64, height = 64, file = 1234 } } })
    T.eq(check(W, 'atlas raceicon-orc-female'), { r = 'nothing' })
    T.eq(check(W, 'atlas classicon-warrior').r, 'present')
  end)
  T.it('class icons and colours, faction emblems', function()
    T.eq(check(W, 'CLASS_ICON_TCOORDS WARRIOR').v, { { 0, 0.25, 0, 0.25 } })
    T.eq(check(W, 'RAID_CLASS_COLORS WARRIOR').v, { { r = 0.78, g = 0.61, b = 0.43 } })
    T.eq(check(W, 'C_ClassColor WARRIOR').v, { r = 0.78, g = 0.61, b = 0.43 })
    T.eq(check(W, 'C_ClassColor MAGE').r, 'nothing')
    T.eq(check(W, 'GetTexture UI-PVP-Alliance').v, { 'Interface\\TargetingFrame\\UI-PVP-Alliance' })
  end)
  T.it('Escape, compartment, minimap, tooltip, ElvUI, DataStore getters', function()
    T.eq(check(W, 'UISpecialFrames').v, { type = 'table', count = 2 })
    T.eq(check(W, 'AddonCompartmentFrame:RegisterAddon').r, 'present')
    T.isnil(W.ui.registered, 'never registered')
    T.eq(check(W, 'TOC AddonCompartmentFunc declared by').v.declaring, { 'SomeCompartmentAddon' })
    T.eq(check(W, 'GetMinimapShape').r, 'absent', 'no addon defines it here')
    T.eq(check(W, 'GetCursorPosition').v, { 512, 384 })
    T.eq(check(W, 'GameTooltip:SetOwner').r, 'present')
    T.isnil(W.ui.tooltipShown)
    T.eq(check(W, 'ElvUI global').r, 'absent')
    T.eq(check(W, 'ElvUI loaded').v, { false })
    T.eq(check(W, 'DataStore:GetCharacterFaction').r, 'absent')
  end)
  T.it('hidden and never shown: the parent is hidden, nothing is shown, anchored or moved; the EditBox has no focus', function()
    local parent, kids = nil, 0
    for _, f in ipairs(W.ui.made) do if f.kind == 'Button' then parent = f.parent end end
    T.truthy(parent, 'the Button has a parent')
    T.falsy(parent.shown, 'parent hidden')
    T.isnil(parent.parent, 'the parent is not under UIParent')
    for _, f in ipairs(W.ui.made) do
      if f.kind ~= 'Frame' then kids = kids + 1; T.eq(f.parent, parent, 'every test widget under the hidden parent') end
    end
    T.eq(kids, 3)
    T.eq(W.ui.shows, 0)
    T.eq(W.ui.anchored, 0)
    T.eq(W.ui.moved, 0)
    T.eq(W.ui.autoFocus, { false })
  end)
  T.it('the widgets are made once per session; later runs reuse them and still report them', function()
    local n = #W.ui.made
    W:slash('run')
    W:advance(30)
    T.eq(#W.ui.made, n)
    T.eq(check(W, 'CreateFrame EditBox').r, 'present')
  end)
  T.it('the identity is saved per character GUID, never a name', function()
    local e = W:db().uiChars['Player-1-00000001']
    T.eq(e.race, 'Human')
    for k, v in pairs(e) do T.falsy(type(v) == 'string' and v:find('Testchar', 1, true), k) end
  end)
  T.it('/eicheck ui runs the checks now and prints one line', function()
    local before = #W.chat
    W:slash('ui')
    T.eq(#W.chat, before + 1)
    T.truthy(W.chat[#W.chat]:find('UI checks: %d+ present, %d+ returned nothing, %d+ absent, %d+ failed; portrait drawn; ruleset hardcore=false preset=1; ElvUI not loaded'), W.chat[#W.chat])
  end)
end)

T.describe('0.1.9: UI checks, other client states', function()
  T.it('hardcore, ElvUI and a minimap shape are recorded as returned', function()
    local W = session({ hardcore = true, elvui = true, shape = 'SQUARE' })
    T.eq(W:db().uiLatest.checks['C_GameRules.IsHardcoreActive'].v, { true })
    T.eq(W:db().uiLatest.checks['ElvUI global'].r, 'present')
    T.eq(W:db().uiLatest.checks['ElvUI loaded'].v, { true })
    T.eq(W:db().uiLatest.checks['GetMinimapShape'].v, { 'SQUARE' })
  end)
  T.it('in combat the checks are skipped and say so', function()
    local W = session({})
    W.combat = true
    W:slash('ui')
    T.truthy(W.chat[#W.chat]:find('UI checks skipped (combat)', 1, true), W.chat[#W.chat])
  end)
  T.it('a client without the UI layer: every missing piece is absent or failed, the run still finishes', function()
    local W = session({ ui = false })
    local u = W:db().uiLatest
    T.truthy(u, 'saved')
    T.eq(u.checks['CreateFrame Frame'].r, 'present')
    T.eq(u.checks['Frame:CreateTexture'].r, 'failed')
    T.eq(u.checks['UnitRace player'].r, 'absent')
    T.eq(u.checks['C_Texture.GetAtlasInfo'].r, 'absent')
    T.eq(#W:lastRun().unexpected, 0)
  end)
end)

T.describe('0.1.9 static rules', function()
  local function read(p) local f = assert(io.open(p, 'rb')); local s = f:read('*a'); f:close(); return s end
  local DIR = root .. '/EmpireIntelCheck/'
  local code = read(DIR .. 'UI.lua'):gsub('%-%-[^\n]*', '')
  T.it('UI.lua never shows, anchors, sizes or moves anything, registers nothing, calls no addon', function()
    for _, bad in ipairs({ ':Show(', 'SetPoint', 'SetSize', 'SetWidth', 'SetHeight', ':StartMoving(', 'RegisterAddon(',
      'SetParent', 'UIParent', 'ds:', 'ElvUI[', 'ElvUI.', 'EmpireIntelDB' }) do
      T.falsy(code:find(bad, 1, true), bad)
    end
  end)
  T.it('the TOC names UI.lua before Run.lua; version 0.1.10-tp1; the texture is an 8x8 TGA', function()
    local toc = read(DIR .. 'EmpireIntelCheck.toc')
    T.truthy(toc:find('## Version: 0.1.10-tp1', 1, true))
    T.truthy(toc:find('UI.lua\nRun.lua', 1, true))
    local tga = read(DIR .. 'Media/Test.tga')
    T.eq(#tga, 18 + 8 * 8 * 4)
    T.eq(tga:byte(3), 2, 'uncompressed true-colour')
    T.eq(tga:byte(13) + 256 * tga:byte(14), 8)
    T.eq(tga:byte(15) + 256 * tga:byte(16), 8)
    T.eq(tga:byte(17), 32)
  end)
end)

---------------------------------------------------------------------------
-- 0.1.10-tp1 (Phase2_Plan.md 12.3, Q-R-4, D-077): the realm and Skyborne probes; the file compacted at logout
---------------------------------------------------------------------------
T.describe('0.1.10: realm probes after build 71037 (EI-E-34..37)', function()
  local function realmSession(o)
    local W = F.new({})
    withUI(W, {})
    W.env.GetRealmName = function() return o.realm end
    W.env.GetNormalizedRealmName = function() return o.realm end
    if o.realmID then W.env.GetRealmID = function() return o.realmID end end
    W.env.C_AddOns.IsAddOnLoaded = function(x) return x == '!RealmFix' and o.fix == true end
    W.env.UnitGUID = function(u) if u == 'player' then return 'Player-9999-00000099' end end
    F.load(W); W:login(); W:advance(12); W:advance(30)
    return W
  end
  T.it('an empty realm name is recorded as the game gave it, with the GUID server number and no realm add-on', function()
    local W = realmSession({ realm = '', realmID = 1234 })
    T.eq(check(W, 'GetRealmName').v, { '' })
    T.eq(check(W, 'UnitGUID server'), { r = 'present', v = { '9999' } })
    T.eq(check(W, 'GetRealmID').v, { 1234 })
    T.eq(check(W, 'realm add-on !RealmFix loaded').v, { false })
    local id = latest(W).identity
    T.eq({ id.realm, id.server, id.realmAddon }, { '', '9999', false })
    T.eq(W:db().uiChars['Player-9999-00000099'].server, '9999', 'per character')
  end)
  T.it('with the realm add-on loaded, the name is recorded and the add-on is named; GetRealmID absent is "not found"', function()
    local W = realmSession({ realm = 'Some Realm PvP', fix = true })
    T.eq(check(W, 'GetRealmName').v, { 'Some Realm PvP' })
    T.eq(check(W, 'realm add-on !RealmFix loaded').v, { true })
    T.eq(latest(W).identity.realmAddon, true)
    T.truthy(check(W, 'GetRealmID').r ~= 'present')
  end)
end)

T.describe('0.1.10: the Skyborne atlases (EI-E-38)', function()
  T.it('raceicon-skyborne, -windshaper and -highorder are probed for both sexes; present ones say so', function()
    local W = F.new({})
    withUI(W, {})
    local get = W.env.C_Texture.GetAtlasInfo
    W.env.C_Texture.GetAtlasInfo = function(n) if n == 'raceicon-windshaper-male' then return { width = 64, height = 64, file = 9 } end; return get(n) end
    F.load(W); W:login(); W:advance(12); W:advance(30)
    for _, r in ipairs({ 'skyborne', 'windshaper', 'highorder' }) do
      for _, g in ipairs({ 'male', 'female' }) do T.truthy(check(W, 'atlas raceicon-' .. r .. '-' .. g), r .. g) end
    end
    T.eq(check(W, 'atlas raceicon-windshaper-male').r, 'present')
    T.eq(check(W, 'atlas raceicon-highorder-female').r, 'nothing')
  end)
end)

T.describe('0.1.10: the saved file is compacted at logout', function()
  local function filled(W)
    local db = W:db()
    db.latest = db.latest or {}
    db.latest.results = {}
    for i = 1, 400 do db.latest.results['C_X.Get' .. i] = { code = 'ok', values = { string.rep('v', 60) } } end
    db.latest.names = { a = true }
    db.docs = { at = 1, systemCount = 410, result = 'ok', args = { ['C_X.GetA'] = 1 }, argsCount = 1,
      systems = { { name = 'Sys', namespace = 'C_Sys', legacy = false, functions = { string.rep('f', 2000) } }, { name = 'LegacyThing', legacy = true } },
      events = { E = true }, index = { string.rep('i', 5000) } }
    db.undoc = { at = 2, calledAt = 3, namespaces = { C_A = { string.rep('n', 3000) } }, plan = { 'C_A.GetB' }, results = { ['C_A.GetB'] = { code = 'ok' } } }
    db.strongSeen = { LegacyA = { first = 1 }, LegacyB = { first = 2 } }
    db.nsBaseline = { list = { string.rep('b', 3000) } }
    db.uiLatest = { checks = { ['atlas x'] = { r = 'present', v = { { width = 64, file = 1, rawSize = { x = 64, y = 64, Add = '<function>' } } } } } }
    db.legacy = { challenges = {
      { id = 1, name = 'Novice Druid', legacy = 1, completed = false, description = 'Reach level 25', reward = 'Earn 1 Legacy Point.', earnedByMe = false,
        criteria = { { text = 'Dungeon A', completed = true, achievement = 760 } } },
      { id = 2, name = 'Explore Eastern Kingdoms', stepOf = 3, completed = false, description = 'Complete the maps', reward = '',
        criteria = { { text = 'Alterac Mountains', completed = false, achievement = 761 } } } } }
    return db
  end
  T.it('in the session nothing is dropped; at logout the leftovers go and what later phases use stays', function()
    local W = session({})
    local db = filled(W)
    T.truthy(db.latest.results and db.docs.systems and db.undoc.plan, 'usable during the session')
    W:fire('PLAYER_LOGOUT')
    db = W:db()
    T.eq(db.compacted, '0.1.10')
    T.isnil(db.latest.results); T.isnil(db.latest.names); T.truthy(db.latest.runId ~= nil or db.latest.compacted)
    T.isnil(db.docs.systems); T.isnil(db.docs.events); T.isnil(db.docs.index)
    T.eq(db.docs.args, { ['C_X.GetA'] = 1 }, 'the argument guard stays')
    T.eq(db.docs.legacySystems, { 'LegacyThing' })
    T.eq(db.docs.systemCount, 410)
    T.isnil(db.undoc.namespaces); T.isnil(db.undoc.plan)
    T.eq(db.undoc.results, { ['C_A.GetB'] = { code = 'ok' } })
    T.eq(db.strongSeen, {}); T.truthy(db.strongSeenDropped:find('2 names', 1, true))
    T.isnil(db.nsBaseline)
    T.eq(db.uiLatest.checks['atlas x'].v[1], { width = 64, file = 1 })
    local c1, c2 = db.legacy.challenges[1], db.legacy.challenges[2]
    T.isnil(c1.description); T.isnil(c1.reward); T.isnil(c1.earnedByMe)
    T.eq(c1.criteria, { { text = 'Dungeon A', completed = true } }, 'done and progress stay')
    T.eq({ c1.id, c1.name, c1.completed }, { 1, 'Novice Druid', false })
    T.isnil(c2.criteria, 'a step\'s own sub-areas go')
    T.eq({ c2.stepOf, c2.completed }, { 3, false })
  end)
  T.it('a file of the user\'s size shape ends far under the cap (half of it)', function()
    local W = session({})
    local db = filled(W)
    for i = 1, 111 do
      db.legacy.challenges[#db.legacy.challenges + 1] = { id = 100 + i, name = 'Ch' .. i, legacy = (i <= 65) and 1 or nil, stepOf = (i > 65) and 7 or nil,
        completed = false, description = string.rep('d', 85), reward = 'Earn 1 Legacy Point.', earnedByMe = false,
        criteria = (function() local t = {} for j = 1, 10 do t[j] = { text = 'Zone ' .. j, completed = false, achievement = j } end return t end)() }
    end
    W:fire('PLAYER_LOGOUT')
    local size = W.env.EmpireIntelCheckDB and #T.serialize(W.env.EmpireIntelCheckDB) or 0
    T.truthy(size < 128 * 1024, 'size ' .. size)
  end)
end)
