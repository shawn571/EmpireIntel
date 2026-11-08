local ADDON, EI = ...
-- EmpireIntel / Platform / UI.lua                                        (Phase 2, increment P2-4b)
--
-- PURPOSE
--   The ONLY file that creates frames, textures and font strings for the window, or names a game UI global
--   (static test): CreateFrame, UIParent, Minimap, GetMinimapShape, GetCursorPosition, UISpecialFrames,
--   AddonCompartmentFrame, GameTooltip, SetPortraitTexture, C_Texture, C_ClassColor. Everything is under pcall;
--   a failure gives one UNEXPECTED line (once per kind) and a plain fallback. Evidence for each call: EI-E-29..31.
--
-- RULES
--   * No Blizzard template anywhere (Phase2_Plan.md 8.3.1): CreateFrame(kind, nil, parent) only.
--   * The fill path (D-061, 9.9): every colour fill goes through UI.Fill. UI.ProbeFill() runs once, at window
--     creation: SetColorTexture with a read-back; if that fails, SetTexture on our own white texture plus
--     SetVertexColor, read back with GetVertexColor; if both fail, fills are skipped (text only). UI.fillPath
--     says which ran: 'color' | 'white' | 'none'.
--   * Fonts: the game's built-in font files only (D-060); nothing shipped.

EI = EI or {}
local P = EI.Platform
assert(P, 'Platform must be loaded before Platform/UI.lua')

local UI = {}
P.UI = UI

UI.MEDIA = 'Interface\\AddOns\\EmpireIntel\\Media\\'
UI.WHITE = UI.MEDIA .. 'White8'
UI.ICONS = UI.MEDIA .. 'Icons'
UI.fillPath = nil                 -- set by UI.ProbeFill
UI.fillEvidence = nil
UI.unexpected = {}

local function env() return P.env end

--- One UNEXPECTED line per kind of failure (the window keeps working).
function UI.Unexpected(kind, detail)
  if UI.unexpected[kind] then return end
  UI.unexpected[kind] = tostring(detail)
  P.Print('UNEXPECTED: window: ' .. kind .. ': ' .. tostring(detail))
end

local function try(kind, fn, ...)
  local ok, a, b, c, d, e = pcall(fn, ...)
  if not ok then UI.Unexpected(kind, a); return nil end
  return a, b, c, d, e
end

---------------------------------------------------------------------------
-- frames, textures, text
---------------------------------------------------------------------------

--- A plain frame of `kind` (Frame, Button, EditBox, ScrollFrame), no template. parent nil = the screen (UIParent).
function UI.Create(kind, parent)
  local create = env().CreateFrame
  if type(create) ~= 'function' then UI.Unexpected('CreateFrame', 'missing'); return nil end
  return try('CreateFrame ' .. tostring(kind), create, kind, nil, parent or env().UIParent)
end

function UI.Screen() return env().UIParent end

function UI.ScreenSize()
  local up = env().UIParent
  if not up then return 1024, 768 end
  local w = try('screen size', function() return up:GetWidth() end)
  local h = try('screen size', function() return up:GetHeight() end)
  return tonumber(w) or 1024, tonumber(h) or 768
end

function UI.Texture(frame, layer)
  return try('CreateTexture', function() return frame:CreateTexture(nil, layer or 'ARTWORK') end)
end

--- A font string with one of the game's built-in fonts (Theme.FONTS). Falls back to the first font if refused.
function UI.Text(frame, font, size, layer)
  local fs = try('CreateFontString', function() return frame:CreateFontString(nil, layer or 'OVERLAY') end)
  if not fs then return nil end
  local T = EI.Theme
  local ok = try('SetFont', function() return fs:SetFont(font, size, '') end)
  if not ok and T and font ~= T.FONTS.title then
    try('SetFont', function() return fs:SetFont(T.FONTS.title, size, '') end)
  end
  return fs
end

--- An icon from our sheet (Theme.ICONS cell), tinted.
function UI.Icon(tex, cell, color)
  if not tex or not cell then return end
  try('icon', function()
    tex:SetTexture(UI.ICONS)
    tex:SetTexCoord(cell[1], cell[2], cell[3], cell[4])
    if color then tex:SetVertexColor(color[1], color[2], color[3], color[4] or 1) end
  end)
end

---------------------------------------------------------------------------
-- the fill path (D-061)
---------------------------------------------------------------------------

local function near(a, b) return type(a) == 'number' and math.abs(a - b) < 0.02 end

--- Tests the two fill paths on a hidden texture and keeps the first that reads back. Returns the path.
function UI.ProbeFill(frame)
  if UI.fillPath then return UI.fillPath end
  local tex = frame and UI.Texture(frame, 'BACKGROUND')
  local ev = {}
  if tex then
    pcall(function() tex:Hide() end)
    local ok, err = pcall(function() tex:SetColorTexture(0.2, 0.4, 0.6, 1) end)
    local okR, back = pcall(function() return tex:GetTexture() end)
    ev.color = { ok = ok, err = (not ok) and tostring(err) or nil, readBack = okR and back or nil }
    if ok and okR and back ~= nil then
      UI.fillPath = 'color'
    else
      local okW = pcall(function() tex:SetTexture(UI.WHITE); tex:SetVertexColor(0.2, 0.4, 0.6, 1) end)
      local okT, file = pcall(function() return tex:GetTexture() end)
      local okV, r, g, b = pcall(function() return tex:GetVertexColor() end)
      ev.white = { ok = okW, file = okT and file or nil, r = okV and r or nil, g = okV and g or nil, b = okV and b or nil }
      if okW and okT and file ~= nil and okV and near(r, 0.2) and near(g, 0.4) and near(b, 0.6) then
        UI.fillPath = 'white'
      end
    end
  end
  if not UI.fillPath then
    UI.fillPath = 'none'
    UI.Unexpected('fill', 'neither SetColorTexture nor the white texture read back; the window shows text only')
  end
  UI.fillEvidence = ev
  return UI.fillPath
end

--- Fills a texture with a colour { r, g, b, a } through the path the probe chose.
function UI.Fill(tex, c)
  if not tex or not c then return end
  local path = UI.fillPath
  if path == 'color' then
    try('fill', function() tex:SetColorTexture(c[1], c[2], c[3], c[4] or 1) end)
  elseif path == 'white' then
    try('fill', function() tex:SetTexture(UI.WHITE); tex:SetVertexColor(c[1], c[2], c[3], c[4] or 1) end)
  end
end

--- One line saying which fill path ran and what the read-back gave.
function UI.FillText()
  local ev = UI.fillEvidence or {}
  if UI.fillPath == 'color' then
    return 'fills: SetColorTexture (read-back ' .. tostring(ev.color and ev.color.readBack) .. ')'
  elseif UI.fillPath == 'white' then
    local w = ev.white or {}
    return string.format('fills: our white texture plus SetVertexColor (SetColorTexture read-back %s; vertex colour %s %s %s)',
      tostring(ev.color and ev.color.readBack), tostring(w.r), tostring(w.g), tostring(w.b))
  elseif UI.fillPath == 'none' then
    return 'fills: none (text only)'
  end
  return 'fills: not tested yet (open the window once)'
end

---------------------------------------------------------------------------
-- art (EI-E-30)
---------------------------------------------------------------------------

function UI.Portrait(tex)
  local f = env().SetPortraitTexture
  if type(f) ~= 'function' or not tex then return false end
  pcall(function() tex:SetTexCoord(0, 1, 0, 1) end)     -- an earlier atlas may have cropped this texture
  try('portrait', f, tex, 'player')
  local back = try('portrait', function() return tex:GetTexture() end)
  return back ~= nil
end

--- Sets an atlas when the client knows it. Returns true when set.
function UI.Atlas(tex, name)
  local ct = env().C_Texture
  if not tex or type(name) ~= 'string' or type(ct) ~= 'table' or type(ct.GetAtlasInfo) ~= 'function' then return false end
  local okI, info = pcall(ct.GetAtlasInfo, name)
  if not okI or info == nil then return false end
  local ok = pcall(function() tex:SetAtlas(name) end)
  return ok
end

--- The class colour { r, g, b }, or nil.
function UI.ClassColor(class)
  local cc = env().C_ClassColor
  if type(class) ~= 'string' or type(cc) ~= 'table' or type(cc.GetClassColor) ~= 'function' then return nil end
  local ok, c = pcall(cc.GetClassColor, class)
  if ok and type(c) == 'table' and type(c.r) == 'number' then return { c.r, c.g, c.b, 1 } end
  return nil
end

---------------------------------------------------------------------------
-- screen, minimap, Escape, compartment, tooltip, combat
---------------------------------------------------------------------------

--- Cursor position in the screen's units.
function UI.Cursor()
  local f = env().GetCursorPosition
  local up = env().UIParent
  if type(f) ~= 'function' then return nil end
  local ok, x, y = pcall(f)
  if not ok or type(x) ~= 'number' then return nil end
  local scale = 1
  if up then local okS, s = pcall(function() return up:GetEffectiveScale() end); if okS and tonumber(s) then scale = s end end
  return x / scale, y / scale
end

function UI.Minimap() return env().Minimap end

--- 'round' or 'square' (ElvUI defines GetMinimapShape, EI-E-31).
function UI.MinimapShape()
  local f = env().GetMinimapShape
  if type(f) ~= 'function' then return 'round' end
  local ok, s = pcall(f)
  if ok and s == 'SQUARE' then return 'square' end
  return 'round'
end

--- Lets Escape close the named frame (UISpecialFrames, EI-E-29). Frames get a global name only through this.
function UI.CloseOnEscape(frame, name)
  local list = env().UISpecialFrames
  if type(list) ~= 'table' then UI.Unexpected('Escape', 'UISpecialFrames missing'); return false end
  env()[name] = frame
  for _, n in ipairs(list) do if n == name then return true end end
  table.insert(list, name)
  return true
end

local compartmentDone = false
--- Registers the AddOn compartment entry once (run time, no TOC field, Q-P2-4b-3).
function UI.Compartment(text, icon, onClick)
  if compartmentDone then return true end
  local acf = env().AddonCompartmentFrame
  if type(acf) ~= 'table' or type(acf.RegisterAddon) ~= 'function' then return false end
  local ok = try('compartment', function()
    acf:RegisterAddon({ text = text, icon = icon, notCheckable = true, registerForAnyClick = true,
      func = function(_, _, _, _, button) onClick(button) end })
  end)
  compartmentDone = true
  return true
end

function UI.Tooltip(owner, lines)
  local tt = env().GameTooltip
  if type(tt) ~= 'table' or not owner then return end
  try('tooltip', function()
    tt:SetOwner(owner, 'ANCHOR_RIGHT')
    if tt.ClearLines then tt:ClearLines() end
    for i, l in ipairs(lines) do
      if i == 1 then tt:AddLine(l.text, 1, 1, 1) else tt:AddLine(l.text, l.r or 0.85, l.g or 0.85, l.b or 0.87, true) end
    end
    tt:Show()
  end)
end

function UI.HideTooltip()
  local tt = env().GameTooltip
  if type(tt) == 'table' and tt.Hide then pcall(function() tt:Hide() end) end
end

function UI.InCombat()
  local f = env().InCombatLockdown
  if type(f) ~= 'function' then return false end
  local ok, v = pcall(f)
  return ok and v == true
end

--- Test helper.
function UI.Reset()
  UI.fillPath, UI.fillEvidence, UI.unexpected, compartmentDone = nil, nil, {}, false
end
