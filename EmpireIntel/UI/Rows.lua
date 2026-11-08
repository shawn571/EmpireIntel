local ADDON, EI = ...
-- EmpireIntel / UI / Rows.lua                                            (Phase 2, increment P2-4b)
--
-- PURPOSE
--   The rows of the approved mockup (D-060): status icon, character in class colour, step, now, points, time, the
--   unverified dot, a tooltip with each rule and its source; own scrolling (mouse wheel, no template); in My plan:
--   drag to reorder, click a target to edit it in place, right-click actions; in Fastest: right-click Copy to my
--   plan or Ignore. Every change goes through Core/Plan.lua (Plan.Check, Plan.SetMine, Plan.SetIgnored), which
--   refuses it when the saved data is read-only.

EI = EI or {}
local P, T = EI.Platform, EI.Theme
assert(P and P.UI and T and EI.Plan, 'load order: Platform/UI, Theme, Plan, Rows')
local UI = P.UI

local L = {}
EI.Rows = L

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

local function say(s) P.Print('plan: ' .. s) end

---------------------------------------------------------------------------
-- plan edits (all through Core/Plan.lua)
---------------------------------------------------------------------------

local function copyEntry(e) local o = {}; for k, v in pairs(e) do o[k] = v end; return o end

local function setMine(list)
  local ok, why = EI.Plan.SetMine(list)
  if not ok then say(why) end
  return ok
end

--- Moves saved step `from` to position `to` (1-based, in the saved list).
function L.Move(from, to)
  local mine = EI.Plan.Mine()
  if not mine[from] or from == to then return false end
  local list = {}
  for i, e in ipairs(mine) do if i ~= from then list[#list + 1] = e end end
  to = math.max(1, math.min(to, #list + 1))
  table.insert(list, to, mine[from])
  return setMine(list)
end

function L.Remove(n)
  local mine = EI.Plan.Mine()
  if not mine[n] then return false end
  local list = {}
  for i, e in ipairs(mine) do if i ~= n then list[#list + 1] = e end end
  return setMine(list)
end

--- Sets one field of saved step n after Plan.Check accepts the result. Returns ok, reason.
function L.Edit(n, field, value, byGuid)
  local mine = EI.Plan.Mine()
  local e = mine[n]
  if not e then return nil, 'no step ' .. tostring(n) end
  local e2 = copyEntry(e)
  if field == 'note' then
    e2.note = (value ~= nil and value ~= '') and tostring(value) or nil
  else
    local v = tonumber(value)
    if not v then return nil, 'not a number' end
    e2[field] = v
  end
  local ok, why = EI.Plan.Check(e2, byGuid)
  if not ok then return nil, why end
  local list = {}
  for i, x in ipairs(mine) do list[i] = (i == n) and e2 or x end
  if not setMine(list) then return nil, 'not saved' end
  return true
end

--- Inserts a new step after n: kind 'level' (next class milestone) or 'skill' (next craft milestone).
function L.AddAfter(n, kind, row)
  local mine = EI.Plan.Mine()
  local guid = row and row.guid
  if not guid then return false end
  local e
  local r = row.saved and row.saved.row
  if kind == 'level' then
    local lvl = (r and type(r.level) == 'number') and r.level or 1
    local nextM = EI.Rules.Next(EI.Rules.CLASS_MILESTONES, lvl) or EI.Rules.MAX_LEVEL
    e = { kind = 'level', guid = guid, level = nextM }
  else
    local prof = row.saved and row.saved.profession
    if not prof and r and type(r.professions) == 'table' then
      for _, p in ipairs(r.professions) do if EI.Rules.Craft(p) then prof = EI.Rules.Craft(p); break end end
    end
    if not prof then say('this character has no crafting skill recorded'); return false end
    local cur = 0
    for _, p in ipairs(r and r.professions or {}) do if p.name == prof and type(p.skill) == 'number' then cur = p.skill end end
    e = { kind = 'skill', guid = guid, profession = prof, skill = EI.Rules.Next(EI.Rules.CRAFT_MILESTONES, cur) or 300 }
  end
  local list = {}
  for i, x in ipairs(mine) do list[#list + 1] = x; if i == n then list[#list + 1] = e end end
  if #list == #mine then list[#list + 1] = e end
  return setMine(list)
end

---------------------------------------------------------------------------
-- the menu (our own, no dropdown template)
---------------------------------------------------------------------------

local function menuItems(list, row)
  if list.mode == 'mine' then
    local items = { { text = 'Move to top', act = 'top' } }
    if row.kind ~= 'challenge' then
      items[#items + 1] = { text = 'Add a level step after', act = 'addLevel' }
      items[#items + 1] = { text = 'Add a skill step after', act = 'addSkill' }
    end
    items[#items + 1] = { text = 'Edit note', act = 'note' }
    if row.guid then items[#items + 1] = { text = 'Ignore ' .. tostring(row.who.name) .. ' in Fastest', act = 'ignore' } end
    items[#items + 1] = { text = 'Remove step', act = 'remove', danger = true }
    return items
  end
  local items = { { text = 'Copy the route to my plan', act = 'copy' } }
  if row.guid then items[#items + 1] = { text = 'Ignore ' .. tostring(row.who.name), act = 'ignore' } end
  return items
end

function L.Act(list, act, row)
  local win = list.win
  if act == 'top' then L.Move(row.index, 1)
  elseif act == 'remove' then L.Remove(row.index)
  elseif act == 'addLevel' then L.AddAfter(row.index, 'level', row)
  elseif act == 'addSkill' then L.AddAfter(row.index, 'skill', row)
  elseif act == 'note' then L.StartEdit(list, row, 'note'); return
  elseif act == 'ignore' then
    local ok, why = EI.Plan.SetIgnored(row.guid, true)
    say(ok and (tostring(row.who.name) .. ' is left out of the fastest route.') or why)
  elseif act == 'copy' then
    local steps = win.res and win.res.steps or {}
    local entries, skipped = EI.Plan.FromRoute(steps)
    if setMine(entries) then
      say('copied the fastest route into my plan: ' .. #entries .. ' steps' .. (skipped > 0 and (', ' .. skipped .. ' left out (no challenge id)') or '') .. '.')
    end
  end
  if win.Refresh then win.Refresh() end
end

local function hideMenu(list) if list.menu then list.menu.frame:Hide() end end

local function showMenu(list, row)
  local C = T.C
  local m = list.menu
  if not m then
    local f = UI.Create('Frame', list.win.frame)
    if not f then return end
    m = { frame = f, items = {} }
    f:SetFrameStrata('DIALOG')
    f:SetWidth(200)
    m.bg = fill(f, 'BACKGROUND', C.menuBg)
    if m.bg then m.bg:SetAllPoints(f) end
    list.menu = m
  end
  local items = menuItems(list, row)
  for i, it in ipairs(items) do
    local b = m.items[i]
    if not b then
      b = { button = UI.Create('Button', m.frame) }
      b.button:SetHeight(22)
      b.button:SetPoint('TOPLEFT', m.frame, 'TOPLEFT', 4, -4 - (i - 1) * 22)
      b.button:SetPoint('RIGHT', m.frame, 'RIGHT', -4, 0)
      b.hover = fill(b.button, 'BACKGROUND', C.menuHover)
      if b.hover then b.hover:SetAllPoints(b.button); b.hover:Hide() end
      b.label = text(b.button, T.FONTS.rows, T.SIZE.text, C.text)
      b.label:SetPoint('LEFT', b.button, 'LEFT', 8, 0)
      b.button:SetScript('OnEnter', function() if b.hover then b.hover:Show() end end)
      b.button:SetScript('OnLeave', function() if b.hover then b.hover:Hide() end end)
      m.items[i] = b
    end
    b.label:SetText(it.text)
    local col = it.danger and C.danger or C.text
    b.label:SetTextColor(col[1], col[2], col[3], 1)
    b.button:SetScript('OnClick', function() hideMenu(list); L.Act(list, it.act, row) end)
    b.button:Show()
  end
  for i = #items + 1, #m.items do m.items[i].button:Hide() end
  m.frame:SetHeight(8 + #items * 22)
  m.frame:ClearAllPoints()
  local x, y = UI.Cursor()
  if x then m.frame:SetPoint('TOPLEFT', UI.Screen(), 'BOTTOMLEFT', x, y) else m.frame:SetPoint('CENTER', list.frame, 'CENTER', 0, 0) end
  m.frame:Show()
  m.items.count = #items
  list.menuRow = row
end
L.ShowMenu = showMenu

---------------------------------------------------------------------------
-- in-place edit
---------------------------------------------------------------------------

function L.StartEdit(list, row, field)
  if list.mode ~= 'mine' or not row or not row.editable then return false end
  field = field or row.field
  if not field then return false end
  local e = list.edit
  if not e then
    e = UI.Create('EditBox', list.frame)
    if not e then return false end
    e:SetAutoFocus(false)
    e:SetFont(T.FONTS.rows, T.SIZE.text, '')
    e:SetHeight(18)
    e:SetTextColor(1, 1, 1, 1)
    e:SetScript('OnEscapePressed', function(self) self:ClearFocus(); self:Hide() end)
    e:SetScript('OnEditFocusLost', function(self) self:Hide() end)
    list.edit = e
  end
  local ui = list.pool[row.slot]
  e:ClearAllPoints()
  if ui then e:SetPoint('LEFT', ui.step, 'LEFT', 0, 0); e:SetWidth(field == 'note' and 200 or 60) end
  local current = field == 'note' and (row.note or '') or tostring(row.target or '')
  e:SetText(current)
  e:SetScript('OnEnterPressed', function(self)
    local ok, why = L.Edit(row.index, field, self:GetText(), list.win.byGuid or {})
    if not ok then say('not saved: ' .. tostring(why)) end
    self:ClearFocus(); self:Hide()
    if list.win.Refresh then list.win.Refresh() end
  end)
  e:Show()
  e:SetFocus()
  list.editing = { row = row, field = field }
  return true
end

---------------------------------------------------------------------------
-- the list
---------------------------------------------------------------------------

local function newRow(list, i)
  local C, W = T.C, T.COLUMNS
  local b = UI.Create('Button', list.frame)
  local r = { button = b }
  b:SetHeight(T.ROW_H)
  b:SetPoint('TOPLEFT', list.frame, 'TOPLEFT', 0, -T.ROW_H * i)
  b:SetPoint('RIGHT', list.frame, 'RIGHT', 0, 0)
  b:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
  b:RegisterForDrag('LeftButton')
  r.hover = fill(b, 'BACKGROUND', C.rowHover)
  if r.hover then r.hover:SetAllPoints(b); r.hover:Hide() end
  r.line = fill(b, 'BORDER', C.rowLine)
  if r.line then r.line:SetPoint('TOPLEFT', b, 'TOPLEFT', 0, 0); r.line:SetPoint('TOPRIGHT', b, 'TOPRIGHT', 0, 0); r.line:SetHeight(1) end
  r.handle = UI.Texture(b, 'ARTWORK')
  if r.handle then r.handle:SetSize(12, 12); r.handle:SetPoint('LEFT', b, 'LEFT', 4, 0); UI.Icon(r.handle, T.ICON.handle, C.dim) end
  r.status = UI.Texture(b, 'ARTWORK')
  if r.status then r.status:SetSize(12, 12) end
  r.who = text(b, T.FONTS.rows, T.SIZE.text, C.text)
  r.who:SetWidth(W.char)
  r.step = text(b, T.FONTS.rows, T.SIZE.text, C.text)
  r.dot = UI.Texture(b, 'ARTWORK')
  if r.dot then r.dot:SetSize(6, 6); UI.Icon(r.dot, T.ICON.dot, C.amber) end
  r.time = text(b, T.FONTS.rows, T.SIZE.text, C.soft, 'RIGHT')
  r.time:SetWidth(W.time)
  r.time:SetPoint('RIGHT', b, 'RIGHT', -8, 0)
  r.pts = text(b, T.FONTS.rows, T.SIZE.text, C.green, 'RIGHT')
  r.pts:SetWidth(W.pts)
  r.pts:SetPoint('RIGHT', r.time, 'LEFT', 0, 0)
  r.now = text(b, T.FONTS.rows, T.SIZE.text, C.soft, 'RIGHT')
  r.now:SetWidth(W.now)
  r.now:SetPoint('RIGHT', r.pts, 'LEFT', 0, 0)
  r.step:SetPoint('RIGHT', r.now, 'LEFT', -16, 0)
  if r.dot then r.dot:SetPoint('RIGHT', r.now, 'LEFT', -6, 0) end
  b:SetScript('OnEnter', function(self)
    if r.hover then r.hover:Show() end
    if r.data then UI.Tooltip(self, r.data.tooltip) end
  end)
  b:SetScript('OnLeave', function() if r.hover then r.hover:Hide() end; UI.HideTooltip() end)
  b:SetScript('OnClick', function(_, button)
    if not r.data then return end
    if button == 'RightButton' then showMenu(list, r.data) else hideMenu(list); L.StartEdit(list, r.data) end
  end)
  b:SetScript('OnDragStart', function()
    if list.mode ~= 'mine' or not r.data then return end
    list.dragFrom = r.data.index
    if list.dragLine then list.dragLine:Show() end
  end)
  b:SetScript('OnDragStop', function()
    if not list.dragFrom then return end
    local from = list.dragFrom
    list.dragFrom = nil
    if list.dragLine then list.dragLine:Hide() end
    local to = L.DropIndex(list)
    if to then L.Move(from, to); if list.win.Refresh then list.win.Refresh() end end
  end)
  return r
end

--- The saved-list position under the cursor (for a drop), or nil.
function L.DropIndex(list)
  local x, y = UI.Cursor()
  local top = list.frame:GetTop()
  if not y or not top then return nil end
  local slot = math.floor((top - y) / T.ROW_H)            -- 0 = the header line
  local i = slot + list.offset
  local rows = list.view and list.view.rows or {}
  if i < 1 then i = 1 end
  if i > #rows then return #EI.Plan.Mine() end
  return rows[i].index
end

function L.Create(parent, win)
  local C = T.C
  local f = UI.Create('Frame', parent)
  if not f then return nil end
  local list = { frame = f, win = win, pool = {}, offset = 0, mode = 'auto' }
  f:EnableMouseWheel(true)
  f:SetScript('OnMouseWheel', function(_, delta) L.Scroll(list, -delta) end)
  list.head = {}
  local hy = -math.floor((T.ROW_H - T.SIZE.tiny) / 2)
  local function headText(t, justify) return text(f, T.FONTS.rows, T.SIZE.tiny, C.dim, justify) end
  list.head.char = headText('CHARACTER'); list.head.char:SetText('CHARACTER')
  list.head.step = headText('STEP'); list.head.step:SetText('STEP')
  list.head.time = headText('TIME', 'RIGHT'); list.head.time:SetText('TIME')
  list.head.time:SetWidth(T.COLUMNS.time); list.head.time:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -8, hy)
  list.head.pts = headText('PTS', 'RIGHT'); list.head.pts:SetText('PTS')
  list.head.pts:SetWidth(T.COLUMNS.pts); list.head.pts:SetPoint('RIGHT', list.head.time, 'LEFT', 0, 0)
  list.head.now = headText('NOW', 'RIGHT'); list.head.now:SetText('NOW')
  list.head.now:SetWidth(T.COLUMNS.now); list.head.now:SetPoint('RIGHT', list.head.pts, 'LEFT', 0, 0)
  list.dragLine = fill(f, 'OVERLAY', C.accentLine)
  if list.dragLine then list.dragLine:SetHeight(2); list.dragLine:Hide() end
  list.emptyText = text(f, T.FONTS.rows, T.SIZE.text, C.muted)
  list.emptyText:SetPoint('TOPLEFT', f, 'TOPLEFT', 12, -T.ROW_H - 8)
  f:SetScript('OnUpdate', function()
    if not list.dragFrom or not list.dragLine then return end
    local _, y = UI.Cursor()
    local top = f:GetTop()
    if not y or not top then return end
    local slot = math.max(1, math.floor((top - y) / T.ROW_H))
    list.dragLine:ClearAllPoints()
    list.dragLine:SetPoint('TOPLEFT', f, 'TOPLEFT', 8, -T.ROW_H * slot)
    list.dragLine:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -8, -T.ROW_H * slot)
  end)
  return list
end

--- Number of row slots that fit the list's height.
function L.Slots(list)
  local h = list.frame:GetHeight() or 0
  return math.max(1, math.floor(h / T.ROW_H) - 1)
end

function L.Scroll(list, by)
  local rows = list.view and list.view.rows or {}
  local maxOff = math.max(0, #rows - L.Slots(list))
  list.offset = math.max(0, math.min(maxOff, list.offset + by))
  L.Draw(list)
end

--- Draws the rows of a PlanView view.
function L.Render(list, view)
  if not list then return end
  list.view = view
  list.mode = view.mode
  local rows = view.rows or {}
  local maxOff = math.max(0, #rows - L.Slots(list))
  if list.offset > maxOff then list.offset = maxOff end
  L.Draw(list)
end

function L.Draw(list)
  local C, W = T.C, T.COLUMNS
  local view = list.view or { rows = {} }
  local rows = view.rows or {}
  local slots = L.Slots(list)
  local mine = list.mode == 'mine'
  local left = mine and (W.handle + 6) or 4
  list.head.char:ClearAllPoints()
  list.head.char:SetPoint('TOPLEFT', list.frame, 'TOPLEFT', left + W.status + 4, -math.floor((T.ROW_H - T.SIZE.tiny) / 2))
  list.head.step:ClearAllPoints()
  list.head.step:SetPoint('LEFT', list.head.char, 'LEFT', W.char, 0)
  list.emptyText:SetText(#rows == 0 and (view.empty or '') or '')
  for i = 1, math.max(slots, #list.pool) do
    local r = list.pool[i]
    local data = (i <= slots) and rows[i + list.offset] or nil
    if not r and data then r = newRow(list, i); list.pool[i] = r end
    if r then
      r.data = data
      if not data then r.button:Hide() else
        data.slot = i
        r.button:Show()
        if r.handle then if mine then r.handle:Show() else r.handle:Hide() end end
        if r.status then
          r.status:ClearAllPoints()
          r.status:SetPoint('LEFT', r.button, 'LEFT', left, 0)
          UI.Icon(r.status, T.ICON[data.status] or T.ICON.open, C[T.STATUS_COLOR[data.status] or 'muted'])
        end
        r.who:ClearAllPoints()
        r.who:SetPoint('LEFT', r.button, 'LEFT', left + W.status + 4, 0)
        r.step:ClearAllPoints()
        r.step:SetPoint('LEFT', r.who, 'RIGHT', 0, 0)
        r.step:SetPoint('RIGHT', r.now, 'LEFT', -16, 0)
        local col = UI.ClassColor(data.who.class) or C.text
        r.who:SetText(data.who.name .. ' ' .. (data.who.classText or '') .. (data.who.level and (' ' .. data.who.level) or ''))
        r.who:SetTextColor(col[1], col[2], col[3], 1)
        local step = data.step .. (data.target and (' ' .. data.target) or '') .. ((data.note and data.note ~= '') and (' - ' .. data.note) or '')
        r.step:SetText(step)
        local sc = data.status == 'done' and C.dim or C.text
        r.step:SetTextColor(sc[1], sc[2], sc[3], 1)
        r.now:SetText(data.now or '')
        r.pts:SetText(data.pts or '')
        r.time:SetText(data.time or '')
        if r.dot then if data.unverified then r.dot:Show() else r.dot:Hide() end end
      end
    end
  end
  list.visible = math.min(slots, math.max(0, #rows - list.offset))
end
