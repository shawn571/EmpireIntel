local ADDON, EI = ...
-- EmpireIntel / UI / Minimap.lua                                         (Phase 2, increment P2-4b)
--
-- PURPOSE
--   Our own minimap button (route mark): left-click opens or closes the window, right-click switches Fastest /
--   My plan, drag moves it along the edge of a round or square minimap (GetMinimapShape, EI-E-31). Angle and the
--   hidden flag are saved in plan.minimap (format 2). /ei minimap on | off. Also the AddOn compartment entry,
--   registered at run time (Q-P2-4b-3, EI-E-29).

EI = EI or {}
local P, T = EI.Platform, EI.Theme
assert(P and P.UI and T and EI.Plan and EI.Window, 'load order: Platform/UI, Theme, Plan, Window, Minimap')
local UI = P.UI

local M = {}
EI.MinimapButton = M
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
M.DEFAULT_ANGLE = 225
M.SIZE = 31

--- Offset of the button's centre from the minimap's centre for an angle in degrees, round or square.
function M.Offset(angle, shape, radius)
  local a = math.rad(angle)
  local x, y = math.cos(a), math.sin(a)
  if shape == 'square' then
    local m = math.max(math.abs(x), math.abs(y))
    x, y = x / m, y / m                       -- onto the square's edge
  end
  return x * radius, y * radius
end

function M.Place()
  local b, mm = M.button, UI.Minimap()
  if not b or not mm then return end
  local st = EI.Plan.MinimapState()
  local angle = tonumber(st.angle) or M.DEFAULT_ANGLE
  local w = mm:GetWidth() or 140
  local x, y = M.Offset(angle, UI.MinimapShape(), w / 2 + 5)
  b:ClearAllPoints()
  b:SetPoint('CENTER', mm, 'CENTER', x, y)
end

local function angleFromCursor()
  local mm = UI.Minimap()
  local cx, cy = mm:GetCenter()
  local x, y = UI.Cursor()
  if not cx or not x then return nil end
  local deg = math.deg(atan2(y - cy, x - cx))
  if deg < 0 then deg = deg + 360 end
  return math.floor(deg + 0.5)
end
M.AngleFromCursor = angleFromCursor

function M.Create()
  local mm = UI.Minimap()
  if M.button or not mm then return M.button end
  local C = T.C
  local b = UI.Create('Button', mm)
  if not b then return nil end
  M.button = b
  b:SetSize(M.SIZE, M.SIZE)
  b:SetFrameStrata('MEDIUM')
  b:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
  b:RegisterForDrag('LeftButton')
  local disc = UI.Texture(b, 'BACKGROUND')
  if disc then disc:SetAllPoints(b); UI.Icon(disc, T.ICON.disc, C.bg) end
  local ring = UI.Texture(b, 'BORDER')
  if ring then ring:SetAllPoints(b); UI.Icon(ring, T.ICON.thinRing, T.hex('4a4d60')) end
  local icon = UI.Texture(b, 'ARTWORK')
  if icon then icon:SetSize(16, 16); icon:SetPoint('CENTER', b, 'CENTER', 0, 0); UI.Icon(icon, T.ICON.route, C.accent) end
  b:SetScript('OnClick', function(_, button) M.Click(button) end)
  b:SetScript('OnDragStart', function(self)
    self:SetScript('OnUpdate', function()
      local a = angleFromCursor()
      if a then M.dragAngle = a; local x, y = M.Offset(a, UI.MinimapShape(), (mm:GetWidth() or 140) / 2 + 5); self:ClearAllPoints(); self:SetPoint('CENTER', mm, 'CENTER', x, y) end
    end)
  end)
  b:SetScript('OnDragStop', function(self)
    self:SetScript('OnUpdate', nil)
    if M.dragAngle then
      local st = EI.Plan.MinimapState()
      EI.Plan.SetMinimap({ hide = st.hide, angle = M.dragAngle })
      M.dragAngle = nil
    end
    M.Place()
  end)
  b:SetScript('OnEnter', function(self)
    UI.Tooltip(self, { { text = 'EmpireIntel' }, { text = 'Left-click: the plan window' }, { text = 'Right-click: Fastest / My plan' },
      { text = 'Drag: move along the edge' } })
  end)
  b:SetScript('OnLeave', function() UI.HideTooltip() end)
  M.Place()
  return b
end

--- left: open or close the window; right: switch the mode.
function M.Click(button)
  if button == 'RightButton' then
    local m = EI.Plan.Mode() == 'mine' and 'auto' or 'mine'
    if EI.Window.IsShown() then EI.Window.SetMode(m) else
      local ok, why = EI.Plan.SetMode(m)
      P.Print('plan: ' .. (ok and ('mode ' .. (m == 'mine' and 'My plan' or 'Fastest')) or tostring(why)))
    end
  else
    EI.Window.Toggle()
  end
end

--- Called once after login: the button (unless hidden) and the compartment entry.
function M.Init()
  if not EI.Plan.MinimapState().hide then M.Create() end
  UI.Compartment('EmpireIntel', UI.MEDIA .. 'Mark', function(button) M.Click(button) end)
end

function M.SetShown(on)
  local st = EI.Plan.MinimapState()
  local ok, why = EI.Plan.SetMinimap({ hide = not on, angle = st.angle })
  if on then
    if not M.button then M.Create() end
    if M.button then M.button:Show() end
  elseif M.button then
    M.button:Hide()
  end
  return ok, why
end

--- Test helper.
function M.Reset() M.button, M.dragAngle = nil, nil end
