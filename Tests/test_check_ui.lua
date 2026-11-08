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
  T.it('the TOC names UI.lua before Run.lua; version 0.1.9-tp1; the texture is an 8x8 TGA', function()
    local toc = read(DIR .. 'EmpireIntelCheck.toc')
    T.truthy(toc:find('## Version: 0.1.9-tp1', 1, true))
    T.truthy(toc:find('UI.lua\nRun.lua', 1, true))
    local tga = read(DIR .. 'Media/Test.tga')
    T.eq(#tga, 18 + 8 * 8 * 4)
    T.eq(tga:byte(3), 2, 'uncompressed true-colour')
    T.eq(tga:byte(13) + 256 * tga:byte(14), 8)
    T.eq(tga:byte(15) + 256 * tga:byte(16), 8)
    T.eq(tga:byte(17), 32)
  end)
end)
