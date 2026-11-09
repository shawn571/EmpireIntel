local ADDON, EI = ...
-- EmpireIntel / UI / UpNext.lua                                          (Phase 2, increment P2-4b)
--
-- PURPOSE
--   The Up Next card of the approved mockup (D-060): the character's portrait (played) or race icon (alt, else its
--   class icon) in a class-coloured ring, a small class icon, the game's faction emblem, the realm-type badge, the
--   step, the points, the time and a gate line. Draws only what Core/PlanView.lua returns.

EI = EI or {}
local P, T = EI.Platform, EI.Theme
assert(P and P.UI and T, 'load order: Platform/UI, Theme, UpNext')
local UI = P.UI

local U = {}
EI.UpNext = U

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

--- Builds the card under parent. Returns the card object.
function U.Create(parent)
  local C = T.C
  local f = UI.Create('Frame', parent)
  if not f then return nil end
  local card = { frame = f }
  f:SetHeight(T.CARD_H - 12)
  card.bg = fill(f, 'BACKGROUND', C.surface)
  if card.bg then card.bg:SetAllPoints(f) end
  card.edge = fill(f, 'BORDER', C.border)
  if card.edge then card.edge:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', 0, 0); card.edge:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 0); card.edge:SetHeight(1) end

  card.portrait = UI.Texture(f, 'ARTWORK')
  if card.portrait then card.portrait:SetSize(52, 52); card.portrait:SetPoint('TOPLEFT', f, 'TOPLEFT', 14, -14) end
  card.ring = UI.Texture(f, 'OVERLAY')
  if card.ring then card.ring:SetSize(60, 60); card.ring:SetPoint('CENTER', card.portrait, 'CENTER', 0, 0); UI.Icon(card.ring, T.ICON.ring, C.strong) end
  card.classIcon = UI.Texture(f, 'OVERLAY')
  if card.classIcon then card.classIcon:SetSize(18, 18); card.classIcon:SetPoint('BOTTOMRIGHT', card.portrait, 'BOTTOMRIGHT', 5, -5) end

  card.label = text(f, T.FONTS.title, T.SIZE.tiny, C.muted)
  card.label:SetPoint('TOPLEFT', f, 'TOPLEFT', 82, -12)
  card.emblem = UI.Texture(f, 'ARTWORK')
  if card.emblem then card.emblem:SetSize(T.EMBLEM_SIZE, T.EMBLEM_SIZE) end
  -- D-066: the badge is a fixed pill (T.BADGE_H high) and the emblem is drawn at a fixed size whose visible disc
  -- matches it (T.EMBLEM_SIZE), centred on the badge
  card.badgeBg = fill(f, 'ARTWORK', C.normalBg)
  if card.badgeBg then card.badgeBg:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -14, -10); card.badgeBg:SetSize(T.BADGE_W, T.BADGE_H) end
  card.badge = text(f, T.FONTS.rows, T.SIZE.small, C.normalText, 'CENTER')
  if card.badgeBg then card.badge:SetPoint('CENTER', card.badgeBg, 'CENTER', 0, 0) else card.badge:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -14, -14) end
  if card.emblem then card.emblem:SetPoint('RIGHT', card.badgeBg or card.badge, 'LEFT', -8, 0) end
  card.factionText = text(f, T.FONTS.rows, T.SIZE.tiny, C.muted)
  if card.emblem then card.factionText:SetPoint('RIGHT', card.emblem, 'LEFT', -4, 0) end

  card.name = text(f, T.FONTS.title, T.SIZE.cardName, C.strong)
  card.name:SetPoint('TOPLEFT', card.label, 'BOTTOMLEFT', 0, -5)
  card.sub = text(f, T.FONTS.rows, T.SIZE.text, C.muted)
  card.sub:SetPoint('LEFT', card.name, 'RIGHT', 6, 0)
  card.title = text(f, T.FONTS.title, T.SIZE.card, C.text)
  card.title:SetPoint('TOPLEFT', card.name, 'BOTTOMLEFT', 0, -5)
  card.title:SetPoint('RIGHT', f, 'RIGHT', -14, 0)
  card.earns = text(f, T.FONTS.rows, T.SIZE.text, C.green)
  card.earns:SetPoint('TOPLEFT', card.title, 'BOTTOMLEFT', 0, -5)
  card.time = text(f, T.FONTS.rows, T.SIZE.text, C.soft)
  card.time:SetPoint('LEFT', card.earns, 'RIGHT', 12, 0)
  card.gateDot = UI.Texture(f, 'ARTWORK')
  if card.gateDot then card.gateDot:SetSize(8, 8); card.gateDot:SetPoint('LEFT', card.time, 'RIGHT', 12, 0); UI.Icon(card.gateDot, T.ICON.dot, C.amber) end
  card.gate = text(f, T.FONTS.rows, T.SIZE.text, C.gateText)
  if card.gateDot then card.gate:SetPoint('LEFT', card.gateDot, 'RIGHT', 4, 0) end

  card.empty = text(f, T.FONTS.rows, T.SIZE.text, C.muted)
  card.empty:SetPoint('LEFT', f, 'LEFT', 14, 0)

  f:EnableMouse(true)
  f:SetScript('OnEnter', function(self) if card.tooltip then UI.Tooltip(self, card.tooltip) end end)
  f:SetScript('OnLeave', function() UI.HideTooltip() end)
  return card
end

local function show(x, on) if x then if on then x:Show() else x:Hide() end end end

local BADGE = { normal = { 'normalText', 'normalBg' }, pvp = { 'pvpText', 'pvpBg' }, hard = { 'hardText', 'hardBg' },
  unknown = { 'unknownText', 'unknownBg' } }

--- Draws a PlanView card (or the empty text when there is none). Returns what art was used (for tests and evidence).
function U.Render(card, c, mode, empty)
  if not card then return nil end
  local C = T.C
  local has = c ~= nil
  for _, k in ipairs({ 'portrait', 'ring', 'classIcon', 'label', 'emblem', 'badgeBg', 'badge', 'factionText', 'name', 'sub',
    'title', 'earns', 'time', 'gateDot', 'gate' }) do show(card[k], has) end
  show(card.empty, not has)
  card.tooltip = has and c.tooltip or nil
  if not has then card.empty:SetText(empty or ''); return nil end
  local who = c.who
  card.label:SetText(c.label or (mode == 'mine' and ('UP NEXT - MY PLAN STEP ' .. tostring(c.index)) or 'UP NEXT'))
  local col = UI.ClassColor(who.class) or C.strong
  card.name:SetText(who.name)
  card.name:SetTextColor(col[1], col[2], col[3], 1)
  if card.ring then card.ring:SetVertexColor(col[1], col[2], col[3], 1) end
  card.sub:SetText(who.account and 'account-wide' or (who.classText .. ' ' .. tostring(who.level or '?') .. ' - ' .. tostring(who.seen)))
  -- art: portrait, race icon, class icon (EI-E-30); a plain fill if none can be drawn
  local used = 'none'
  if who.art and who.art.kind == 'portrait' and UI.Portrait(card.portrait) then used = 'portrait'
  elseif who.art and who.art.kind == 'race' and UI.Atlas(card.portrait, who.art.atlas) then used = 'race'
  elseif UI.Atlas(card.portrait, who.classAtlas) then used = 'class'
  else UI.Fill(card.portrait, C.border) end
  if card.portrait and used ~= 'none' then card.portrait:SetVertexColor(1, 1, 1, 1) end
  local classIconOn = used ~= 'class' and UI.Atlas(card.classIcon, who.classAtlas)
  show(card.classIcon, classIconOn)
  -- faction: the game's emblem (D-060); DataStore's is marked
  local emblemOn = who.faction and UI.Emblem(card.emblem, who.faction)
  card.emblemPath = emblemOn
  show(card.emblem, emblemOn ~= nil and emblemOn ~= false)
  card.factionText:SetText(who.faction and (who.factionSrc == 'datastore' and (who.faction .. ' (DataStore)') or '') or '')
  -- the account (a dungeon challenge in My plan) has no realm badge
  show(card.badge, who.ruleset ~= nil); show(card.badgeBg, who.ruleset ~= nil)
  if who.ruleset then
    local b = BADGE[who.ruleset.kind] or BADGE.unknown
    card.badge:SetText(who.ruleset.text)
    card.badge:SetTextColor(C[b[1]][1], C[b[1]][2], C[b[1]][3], 1)
    UI.Fill(card.badgeBg, C[b[2]])
  end
  card.title:SetText(c.title)
  card.earns:SetText(c.earns or '')
  card.time:SetText((c.time ~= '' and (c.time .. ' [estimate]')) or '')
  card.gate:SetText(c.gate or '')
  show(card.gateDot, c.gate ~= nil)
  show(card.gate, c.gate ~= nil)
  card.art = used
  return used
end
