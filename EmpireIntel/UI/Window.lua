local ADDON, EI = ...
-- EmpireIntel / UI / Window.lua                                          (Phase 2, increment P2-4b)
--
-- PURPOSE
--   The plan window of the approved mockup (D-060): header (route mark, Fastest / My plan, target, close), the
--   Up Next card (UI/UpNext.lua), the rows (UI/Rows.lua), the footer; movable, resizable with our own grip, size
--   and position saved in plan.window (format 2), kept within 440 x 300 .. 900 x 800 (default 560 x 420,
--   Q-P2-4b-4) and on screen; Escape closes it. Made on first open, never before.
--
-- RULES
--   * Not a secure frame: it works in combat. In combat no Legacy read starts; the last read is used and labelled
--     "from before combat" (Phase2_Plan.md 9.1).
--   * The fill path is chosen once, at creation (UI.ProbeFill, D-061), and said once in chat.
--   * Resizing refused by the client: a fixed-size window and one UNEXPECTED line.

EI = EI or {}
local P, T = EI.Platform, EI.Theme
assert(P and P.UI and T and EI.UpNext and EI.Rows and EI.PlanView and EI.Next and EI.Plan,
  'load order: Platform/UI, Theme, Next, PlanView, UpNext, Rows, Window')
local UI = P.UI

local W = {}
EI.Window = W
W.NAME = 'EmpireIntelPlanWindow'

local function fill(parent, layer, color)
  local t = UI.Texture(parent, layer)
  if t then UI.Fill(t, color) end
  return t
end

local function text(parent, font, size, color, justify)
  local fs = UI.Text(parent, font, size)
  if fs then
    fs:SetJustifyH(justify or 'LEFT')
    if fs.SetWordWrap then fs:SetWordWrap(false) end
    fs:SetTextColor(color[1], color[2], color[3], color[4] or 1)
  end
  return fs
end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

--- The saved (or default) size and position, kept within the limits.
function W.Geometry()
  local s = EI.Plan.Window() or {}
  local D = T.WINDOW
  local w = clamp(tonumber(s.w) or D.w, D.minW, D.maxW)
  local h = clamp(tonumber(s.h) or D.h, D.minH, D.maxH)
  local sw, sh = UI.ScreenSize()
  w, h = math.min(w, math.max(D.minW, sw)), math.min(h, math.max(D.minH, sh))
  local point = type(s.point) == 'string' and s.point or 'CENTER'
  return { point = point, x = tonumber(s.x) or 0, y = tonumber(s.y) or 0, w = w, h = h }
end

local function save()
  local f = W.frame
  if not f then return end
  -- the game may re-anchor a moved frame to another corner, and format 2 keeps no relative point: save the
  -- top-left corner against the screen's top-left (point TOPLEFT), which restores exactly
  local left, top = f:GetLeft(), f:GetTop()
  local _, sh = UI.ScreenSize()
  local g = { point = 'TOPLEFT', x = math.floor((left or 0) + 0.5), y = math.floor(((top or sh) - sh) + 0.5),
    w = math.floor((f:GetWidth() or T.WINDOW.w) + 0.5), h = math.floor((f:GetHeight() or T.WINDOW.h) + 0.5) }
  local D = T.WINDOW
  g.w, g.h = clamp(g.w, D.minW, D.maxW), clamp(g.h, D.minH, D.maxH)
  local ok, why = EI.Plan.SetWindow(g)
  if not ok and not W.saidReadOnly then W.saidReadOnly = true; P.Print('plan: window ' .. tostring(why)) end
end
W.Save = save

local function modeButton(parent, label)
  local C = T.C
  local b = UI.Create('Button', parent)
  b:SetSize(64, 20)
  local bg = fill(b, 'BACKGROUND', C.switchOn)
  if bg then bg:SetAllPoints(b) end
  local fs = text(b, T.FONTS.title, T.SIZE.small, C.text, 'CENTER')
  fs:SetPoint('CENTER', b, 'CENTER', 0, 0)
  fs:SetText(label)
  return { button = b, bg = bg, label = fs }
end

local function build()
  local C, D = T.C, T.WINDOW
  local f = UI.Create('Frame')
  if not f then return nil end
  W.frame = f
  f:Hide()
  UI.ProbeFill(f)
  local g = W.Geometry()
  f:SetSize(g.w, g.h)
  f:ClearAllPoints()
  f:SetPoint(g.point, UI.Screen(), g.point, g.x, g.y)
  f:SetFrameStrata('MEDIUM')
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag('LeftButton')
  f:SetScript('OnDragStart', function(self) self:StartMoving() end)
  f:SetScript('OnDragStop', function(self) self:StopMovingOrSizing(); save() end)
  -- resizable (bounds through the call the client has; else a fixed size)
  local okR = pcall(function()
    f:SetResizable(true)
    if f.SetResizeBounds then f:SetResizeBounds(D.minW, D.minH, D.maxW, D.maxH)
    else f:SetMinResize(D.minW, D.minH); f:SetMaxResize(D.maxW, D.maxH) end
  end)
  W.resizable = okR
  if not okR then UI.Unexpected('resize', 'the client refused SetResizable; the window keeps a fixed size') end

  W.edge = fill(f, 'BACKGROUND', C.border)
  if W.edge then W.edge:SetAllPoints(f) end
  W.bg = fill(f, 'BORDER', C.bg)
  if W.bg then W.bg:SetPoint('TOPLEFT', f, 'TOPLEFT', 1, -1); W.bg:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -1, 1) end

  -- header
  local mark = UI.Texture(f, 'ARTWORK')
  if mark then mark:SetSize(16, 16); mark:SetPoint('TOPLEFT', f, 'TOPLEFT', 12, -10); UI.Icon(mark, T.ICON.route, C.accent) end
  local title = text(f, T.FONTS.title, T.SIZE.title, C.strong)
  title:SetPoint('LEFT', mark or f, mark and 'RIGHT' or 'LEFT', 8, 0)
  title:SetText('EmpireIntel')
  W.fast = modeButton(f, 'Fastest')
  W.fast.button:SetPoint('LEFT', title, 'RIGHT', 14, 0)
  W.mine = modeButton(f, 'My plan')
  W.mine.button:SetPoint('LEFT', W.fast.button, 'RIGHT', 2, 0)
  W.fast.button:SetScript('OnClick', function() W.SetMode('auto') end)
  W.mine.button:SetScript('OnClick', function() W.SetMode('mine') end)
  local close = UI.Create('Button', f)
  close:SetSize(20, 20)
  close:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -8, -8)
  local cx = UI.Texture(close, 'ARTWORK')
  if cx then cx:SetSize(12, 12); cx:SetPoint('CENTER', close, 'CENTER', 0, 0); UI.Icon(cx, T.ICON.close, C.muted) end
  close:SetScript('OnClick', function() W.Close() end)
  W.targetButton = UI.Create('Button', f)
  W.targetButton:SetSize(T.TARGET_W, 20)
  W.targetButton:SetPoint('RIGHT', close, 'LEFT', -8, 0)
  local tbg = fill(W.targetButton, 'BACKGROUND', C.switchBg)
  if tbg then tbg:SetAllPoints(W.targetButton) end
  W.targetText = text(W.targetButton, T.FONTS.title, T.SIZE.small, C.text, 'CENTER')
  W.targetText:SetPoint('CENTER', W.targetButton, 'CENTER', 0, 0)
  W.targetButton:SetScript('OnClick', function(self) W.CycleTarget(); if W.view then UI.Tooltip(self, W.view.targetTip) end end)
  -- D-063 item 5: the label says what the target is ("Cap 2/16"); the tooltip explains the three choices
  W.targetButton:SetScript('OnEnter', function(self) if W.view then UI.Tooltip(self, W.view.targetTip) end end)
  W.targetButton:SetScript('OnLeave', function() UI.HideTooltip() end)
  local hl = fill(f, 'ARTWORK', C.line)
  if hl then hl:SetHeight(1); hl:SetPoint('TOPLEFT', f, 'TOPLEFT', 1, -T.HEADER_H); hl:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -1, -T.HEADER_H) end

  -- card and rows
  W.card = EI.UpNext.Create(f)
  if W.card then
    -- D-066: clicking a selected card goes back to Up next
    W.card.frame:SetScript('OnMouseUp', function() if W.selected then W.Select(nil) end end)
    W.card.frame:SetPoint('TOPLEFT', f, 'TOPLEFT', T.PAD, -(T.HEADER_H + 10))
    W.card.frame:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -T.PAD, -(T.HEADER_H + 10))
  end
  W.list = EI.Rows.Create(f, W)
  if W.list then
    W.list.frame:SetPoint('TOPLEFT', f, 'TOPLEFT', 4, -(T.HEADER_H + T.CARD_H + 4))
    W.list.frame:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -4, T.FOOTER_H + 2)
  end

  -- footer
  local fl = fill(f, 'ARTWORK', C.line)
  if fl then fl:SetHeight(1); fl:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', 1, T.FOOTER_H); fl:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -1, T.FOOTER_H) end
  W.footLeft = text(f, T.FONTS.rows, T.SIZE.small, C.muted)
  W.footLeft:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', 12, 10)
  W.footRight = text(f, T.FONTS.rows, T.SIZE.small, C.muted, 'RIGHT')
  W.footRight:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -26, 10)

  -- resize grip (our own)
  if W.resizable then
    local grip = UI.Create('Button', f)
    grip:SetSize(16, 16)
    grip:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -2, 2)
    local gt = UI.Texture(grip, 'OVERLAY')
    if gt then gt:SetAllPoints(grip); UI.Icon(gt, T.ICON.grip, C.dim) end
    grip:SetScript('OnMouseDown', function() f:StartSizing('BOTTOMRIGHT') end)
    grip:SetScript('OnMouseUp', function() f:StopMovingOrSizing(); save(); W.Redraw() end)
    W.grip = grip
  end
  f:SetScript('OnSizeChanged', function() W.Redraw() end)
  f:SetScript('OnHide', function()
    UI.HideTooltip()
    if W.list and W.list.menu then W.list.menu.frame:Hide() end
    if W.list and W.list.bar then W.list.editing = nil; W.list.bar.frame:Hide() end
  end)
  UI.CloseOnEscape(f, W.NAME)
  -- D-063 item 8: when combat ends, a window that could not read Legacy in combat reads it again
  if P.Events and P.Events.On then
    P.Events.On('P_COMBAT', function(payload)
      if payload and payload.inCombat == false and W.IsShown() and W.cache and W.cache.why == 'combat' then W.Refresh(true) end
    end)
  end
  return f
end

---------------------------------------------------------------------------
-- data and drawing
---------------------------------------------------------------------------

local function compute(rows, legacy, why, now, plan)
  local res = EI.Next.RouteFor(rows, legacy, now)
  W.res = res
  W.byGuid = {}
  for _, r in ipairs(rows) do if r.guid then W.byGuid[r.guid] = r end end
  W.view = EI.PlanView.Build({ mode = W.mode, res = res, plan = plan, rows = rows, now = now, rates = EI.Plan.Rates(), ignore = EI.Plan.Ignore(),
    selected = W.selected,
    unlocked = EI.Next.Unlocked(rows), legacy = legacy, legacyWhy = why })
  W.Redraw()
end

--- Reloads the data. reread = start a Legacy read (never in combat); else the last data is reused.
function W.Refresh(reread)
  if not W.frame then return end
  if reread or not W.cache then
    -- draw at once from what is known, then again when the read finishes (about 2 seconds)
    local rows = EI.Views.Collect()
    compute(rows, W.cache and W.cache.legacy, (W.cache and W.cache.why) or 'reading', (P.Now()), EI.Plan.Load(rows))
    EI.Next.Data(true, function(rows2, legacy, why, now, plan)
      rows = rows2
      if why == 'combat' and P.Legacy.last and not P.Legacy.last.error and P.Legacy.last.summary then
        legacy = P.Legacy.last                    -- labelled "from before combat" by PlanView
      end
      W.cache = { legacy = legacy, why = why }
      compute(rows, legacy, why, now, plan)
    end, true)
  else
    local rows = EI.Views.Collect()
    compute(rows, W.cache.legacy, W.cache.why, (P.Now()), EI.Plan.Load(rows))
  end
end

function W.Redraw()
  local view = W.view
  if not W.frame or not view then return end
  local C = T.C
  local on, off = W.mode == 'mine' and W.mine or W.fast, W.mode == 'mine' and W.fast or W.mine
  UI.Fill(on.bg, C.switchOn); on.label:SetTextColor(1, 1, 1, 1)
  UI.Fill(off.bg, C.switchBg); off.label:SetTextColor(C.muted[1], C.muted[2], C.muted[3], 1)
  W.targetText:SetText(view.target or '?')
  EI.UpNext.Render(W.card, view.card, view.mode, view.empty)
  EI.Rows.Render(W.list, view)
  W.footLeft:SetText((view.note and (view.note .. '   ') or '') .. (view.footer.reward or '')
    .. (view.footer.notPlanned and ('   ' .. view.footer.notPlanned) or ''))
  W.footRight:SetText(view.footer.rules .. ((view.footer.total and view.footer.total ~= '') and ('   ' .. view.footer.total) or ''))
end

--- D-066: the card follows the selected row; nil goes back to Up next.
function W.Select(mode, key)
  if mode and key then W.selected = { mode = mode, key = key } else W.selected = nil end
  W.Refresh(false)
end

function W.SetMode(m)
  W.mode = m
  W.selected = nil
  local ok, why = EI.Plan.SetMode(m)
  if not ok and not W.saidReadOnly then W.saidReadOnly = true; P.Print('plan: mode ' .. tostring(why)) end
  W.Refresh(false)
end

W.TARGETS = { EI.RouteRules.CAP, 'reward', 'next' }          -- the cap from the rules table (L-12, R-6)
function W.CycleTarget()
  local cur = EI.Plan.Target()
  local idx = 1
  for i, t in ipairs(W.TARGETS) do if t == cur then idx = i end end
  local nextT = W.TARGETS[idx % #W.TARGETS + 1]
  local ok, why = EI.Plan.SetTarget(nextT)
  if not ok then P.Print('plan: ' .. tostring(why)) end
  W.Refresh(false)
end

---------------------------------------------------------------------------
-- open and close
---------------------------------------------------------------------------

function W.Open()
  if not W.frame then
    local ok, f = pcall(build)
    if not ok or not f then
      UI.Unexpected('window', ok and 'could not be made' or f)
      W.frame = nil
      return false
    end
    P.Print('window: ' .. UI.FillText())
  end
  W.mode = EI.Plan.Mode()
  W.frame:Show()
  W.Refresh(true)
  return true
end

function W.Close() if W.frame then W.frame:Hide() end end

function W.IsShown() return W.frame ~= nil and W.frame:IsShown() == true end

function W.Toggle()
  if W.IsShown() then W.Close() else W.Open() end
  return W.IsShown()
end

--- Test helper.
function W.Reset() W.frame, W.view, W.cache, W.res, W.saidReadOnly, W.selected = nil, nil, nil, nil, nil, nil end
