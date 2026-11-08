--[[
EmpireIntel / Tests / helpers / fakeui.lua

A fake UI layer for the P2-4b window, on top of fakeclient.lua. Only the methods the window uses exist, as the game
has them (EI-E-29..31); frames start SHOWN as in the game. It records what is created, shown, anchored, filled.

FU.install(W, opts)  opts (all optional):
  colorReadBack = false   SetColorTexture works but GetTexture then returns nothing (forces the white path)
  colorError = true       SetColorTexture raises
  whiteFail = true        GetVertexColor always returns 1, 1, 1, 1 (the white path does not read back)
  noResize = true         frames have no SetResizable
  square = true           GetMinimapShape returns 'SQUARE' (ElvUI)
  noCompartment = true    no AddonCompartmentFrame
  noPortrait = true       SetPortraitTexture draws nothing
  noArialn = true         SetFont refuses Fonts\ARIALN.TTF
]]

local FU = {}

local ATLASES = { ['raceicon-undead-male'] = true, ['raceicon-undead-female'] = true, ['raceicon-human-male'] = true,
  ['raceicon-orc-female'] = true, HordeEmblem = true, AllianceEmblem = true }
for _, c in ipairs({ 'warrior', 'paladin', 'hunter', 'rogue', 'priest', 'shaman', 'mage', 'warlock', 'druid' }) do ATLASES['classicon-' .. c] = true end
FU.ATLASES = ATLASES

local COLORS = { PALADIN = { 0.96, 0.55, 0.73 }, PRIEST = { 1, 1, 1 }, WARRIOR = { 0.78, 0.61, 0.43 }, MAGE = { 0.25, 0.78, 0.92 },
  SHAMAN = { 0, 0.44, 0.87 }, ROGUE = { 1, 0.96, 0.41 } }

function FU.install(W, opts)
  opts = opts or {}
  local env = W.env
  local ui = { made = {}, textures = {}, fonts = {}, shows = 0, templates = 0, moved = 0, sized = 0, registered = 0,
    cursor = { 400, 300 }, tooltip = {}, special = {} }
  W.ui = ui

  local function region(o)
    o.points = {}
    function o:SetPoint(p, rel, rp, x, y) table.insert(self.points, { p, rel, rp, x, y }) end
    function o:ClearAllPoints() self.points = {} end
    function o:SetAllPoints(rel) self.points = { { 'ALL', rel } } end
    function o:SetSize(w, h) self.w, self.h = w, h end
    function o:SetWidth(w) self.w = w end
    function o:SetHeight(h) self.h = h end
    -- like the game: a size not set comes from TOPLEFT and BOTTOMRIGHT anchors on a sized frame
    local function span(self, axis)
      local tl, br
      for _, p in ipairs(self.points or {}) do
        if p[1] == 'TOPLEFT' then tl = p elseif p[1] == 'BOTTOMRIGHT' then br = p end
      end
      if not tl or not br or tl[2] ~= br[2] or type(tl[2]) ~= 'table' then return nil end
      local rel = tl[2]
      if axis == 'w' then local rw = rel:GetWidth(); return rw and (rw - (tl[4] or 0) + (br[4] or 0)) end
      local rh = rel:GetHeight(); return rh and (rh + (tl[5] or 0) - (br[5] or 0))
    end
    function o:GetWidth() return self.w or span(self, 'w') end
    function o:GetHeight() return self.h or span(self, 'h') end
    function o:Show() if not self.shown then self.shown = true; if self.scripts and self.scripts.OnShow then self.scripts.OnShow(self) end end end
    function o:Hide() if self.shown then self.shown = false; if self.scripts and self.scripts.OnHide then self.scripts.OnHide(self) end end end
    function o:IsShown() return self.shown end
    function o:SetAlpha(a) self.alpha = a end
    return o
  end

  local function texture(owner, layer)
    local t = region({ kind = 'Texture', layer = layer, shown = true, owner = owner })
    function t:SetTexture(p) self.path = p; self.atlas = nil; return true end
    function t:GetTexture() return self.path end
    function t:SetColorTexture(r, g, b, a)
      if opts.colorError then error('SetColorTexture: not supported') end
      self.color = { r, g, b, a }
      if opts.colorReadBack == false then self.path = nil else self.path = 'FileData ID 0' end
    end
    function t:SetVertexColor(r, g, b, a) self.vc = { r, g, b, a } end
    function t:GetVertexColor()
      if opts.whiteFail or not self.vc then return 1, 1, 1, 1 end
      return self.vc[1], self.vc[2], self.vc[3], self.vc[4]
    end
    function t:SetTexCoord(...) self.coord = { ... } end
    function t:SetAtlas(name) if not ATLASES[name] then error('unknown atlas ' .. tostring(name)) end; self.atlas = name; self.path = 'atlas:' .. name end
    table.insert(ui.textures, t)
    return t
  end

  local function fontString(owner)
    local f = region({ kind = 'FontString', shown = true, owner = owner, text = '' })
    function f:SetFont(path, size)
      if opts.noArialn and path == 'Fonts\\ARIALN.TTF' then return false end
      self.font = { path, size }; return true
    end
    function f:SetText(s) self.text = s end
    function f:GetText() return self.text end
    function f:SetTextColor(r, g, b, a) self.textColor = { r, g, b, a } end
    function f:SetJustifyH(j) self.justify = j end
    function f:SetWordWrap(v) self.wrap = v end
    table.insert(ui.fonts, f)
    return f
  end

  local function frame(kind, parent)
    local f = region({ kind = kind, parent = parent, shown = true, scripts = {} })
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:GetScript(k) return self.scripts[k] end
    function f:GetObjectType() return kind end
    function f:EnableMouse(v) self.mouse = v end
    function f:EnableMouseWheel(v) self.wheel = v end
    function f:SetMovable(v) self.movable = v end
    if not opts.noResize then
      function f:SetResizable(v) self.resizable = v end
      function f:SetResizeBounds(a, b, c, d) self.bounds = { a, b, c, d } end
    end
    function f:StartMoving() ui.moved = ui.moved + 1; self.moving = true end
    function f:StartSizing(corner) ui.sized = ui.sized + 1; self.sizing = corner end
    function f:StopMovingOrSizing() self.moving, self.sizing = nil, nil end
    function f:RegisterForDrag(...) self.drag = { ... } end
    function f:RegisterForClicks(...) self.clicks = { ... } end
    function f:SetFrameStrata(s) self.strata = s end
    function f:SetToplevel(v) self.toplevel = v end
    function f:SetClampedToScreen(v) self.clamped = v end
    function f:GetPoint(i)
      local p = self.points[i or 1]
      if not p then return nil end
      return p[1], p[2], p[3], p[4], p[5]
    end
    function f:GetTop() return self.top or 400 end
    function f:GetLeft() return self.left or 100 end
    function f:GetCenter() return 800, 450 end
    function f:CreateTexture(_, layer) return texture(self, layer) end
    function f:CreateFontString() return fontString(self) end
    if kind == 'EditBox' then
      f.text = ''
      function f:SetAutoFocus(v) self.autoFocus = v end
      function f:SetFont(path, size) self.font = { path, size }; return true end
      function f:SetText(s) self.text = s end
      function f:GetText() return self.text end
      function f:SetTextColor() end
      function f:SetFocus() self.focus = true end
      function f:ClearFocus()
        local had = self.focus
        self.focus = false
        if had and self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
      end
    end
    table.insert(ui.made, f)
    return f
  end
  FU.frame = frame

  local base = env.CreateFrame
  env.CreateFrame = function(kind, name, parent, template)
    if template ~= nil then ui.templates = ui.templates + 1 end
    if parent == nil and kind ~= 'Frame' then return base(kind, name, parent) end
    if parent == nil then
      -- the add-ons' own event and scheduler frames (no parent): the base fake
      return base(kind, name, parent)
    end
    return frame(kind, parent)
  end
  env.UIParent = frame('Frame', nil)
  env.UIParent:SetSize(1600, 900)
  function env.UIParent:GetEffectiveScale() return 1 end
  env.Minimap = frame('Frame', env.UIParent)
  env.Minimap:SetSize(140, 140)
  if opts.square then env.GetMinimapShape = function() return 'SQUARE' end end
  env.GetCursorPosition = function() return ui.cursor[1], ui.cursor[2] end
  env.UISpecialFrames = ui.special
  if not opts.noCompartment then
    env.AddonCompartmentFrame = { RegisterAddon = function(_, info) ui.registered = ui.registered + 1; ui.compartment = info end }
  end
  env.GameTooltip = { SetOwner = function(_, owner) ui.tooltipOwner = owner; ui.tooltip = {} end,
    ClearLines = function() ui.tooltip = {} end, AddLine = function(_, s) table.insert(ui.tooltip, s) end,
    Show = function() ui.tooltipShown = true end, Hide = function() ui.tooltipShown = false end }
  env.SetPortraitTexture = function(tex, unit) if not opts.noPortrait and tex and unit == 'player' then tex.path = 'RTPortrait1' end end
  env.C_Texture = { GetAtlasInfo = function(name) if ATLASES[name] then return { width = 64, height = 64 } end end }
  env.C_ClassColor = { GetClassColor = function(c) local x = COLORS[c]; if x then return { r = x[1], g = x[2], b = x[3], GetRGB = function() end } end end }
  return ui
end

--- Every font string whose text contains `s` (plain find).
function FU.texts(W, s)
  local out = {}
  for _, f in ipairs(W.ui.fonts) do if f.shown and type(f.text) == 'string' and f.text:find(s, 1, true) then out[#out + 1] = f end end
  return out
end

return FU
