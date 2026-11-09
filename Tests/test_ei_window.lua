-- EmpireIntel / Tests / test_ei_window.lua
-- Behaviour of increment P2-4b (Phase2_Plan.md section 9, D-060, D-061): the plan window, the fill path and its
-- fallback, size and position, the Up Next card, both modes and their actions, combat, the minimap button, the
-- compartment, the DataStore faction getter, and the static rules (only Platform/UI.lua touches the game's UI).
local T, F, root = ...
local FU = require('fakeui')

local WALL = 1800000000
local C1, C2 = 'Player-1-00000011', 'Player-1-00000012'

local function rec(t)
  local r = { realm = 'Test Realm', src = 'self', lastSeen = WALL - 3600, restAt = WALL - 3600 }
  for k, v in pairs(t) do r[k] = v end
  return r
end
local function c1() return rec({ name = 'Cee One', class = 'PALADIN', level = 27, xp = 0, xpMax = 38900, rest = 0, resting = true,
  race = 'Scourge', sex = 2, faction = 'Horde', ruleset = 'normal', preset = 1,
  professions = { { name = 'Mining', skill = 109, max = 150, line = 186 }, { name = 'Skinning', skill = 149, max = 225, line = 393 } } }) end
local function db(plan) return { schema = 2, meta = {}, roster = { [C1] = c1() }, plan = plan or {} } end

-- the played character: C2 Priest 6 with Tailoring 56/75 and Enchanting 28/75 (the user's account, names replaced)
local function session(opts)
  opts = opts or {}
  opts.char = opts.char or { guid = C2, first = 'Cee', last = 'Two', class = 'PRIEST', classLoc = 'Priest', classId = 5, level = 6,
    xp = 0, xpMax = 3600, rest = 1842, resting = true, profIdx = { 1, 2 },
    profs = { { name = 'Tailoring', skill = 56, max = 75, line = 197 }, { name = 'Enchanting', skill = 28, max = 75, line = 333 } } }
  if opts.eidb == nil then opts.eidb = db() end
  local W = F.new(opts)
  W.prints = {}
  W.env.print = function(...) local t = {}; for i = 1, select('#', ...) do t[i] = tostring((select(i, ...))) end; table.insert(W.prints, table.concat(t, ' ')) end
  W.env.GetProfessionInfo = function(i)
    local p = W.char.profs[i]
    if p then return p.name, 136240, p.skill, p.max or 75, 0, 0, p.line, 0 end
  end
  W.env.UnitRace = function() return 'Undead', 'Scourge', 5 end
  W.env.UnitSex = function() return 2 end
  W.env.UnitFactionGroup = function() return 'Horde', 'Horde' end
  W.env.C_GameRules = { IsHardcoreActive = function() return false end, GetForeverExperiencePreset = function() return 1 end }
  if opts.ui ~= false then FU.install(W, opts.ui) end
  if opts.before then opts.before(W) end
  local EI = F.loadAddon(W, 'EmpireIntel')
  W:fire('PLAYER_LOGIN')
  W:fire('PLAYER_ENTERING_WORLD', true, false)
  W:advance(3)
  return W, EI
end
local function slash(W, msg)
  local from = #W.prints
  W.env.SlashCmdList.EMPIREINTEL(msg)
  W:advance(5)
  local out = {}
  for i = from + 1, #W.prints do out[#out + 1] = (W.prints[i]:gsub('^EmpireIntel: ', '')) end
  return out
end
local function find(lines, text)
  for _, l in ipairs(lines) do if l:find(text, 1, true) then return l end end
  return nil
end
local function dump(lines) return table.concat(lines, '\n') end
local function shownText(W, s) return FU.texts(W, s)[1] end
local function openWin(W) return slash(W, 'plan') end
local function row(EI, i) return EI.Window.list.pool[i] end

---------------------------------------------------------------------------
T.describe('P2-4b: opening and closing', function()
  T.it('the window is not made before it is opened; /ei plan opens it, again closes it', function()
    local W, EI = session({})
    T.isnil(EI.Window.frame)
    openWin(W)
    T.truthy(EI.Window.IsShown())
    slash(W, 'plan')
    T.falsy(EI.Window.IsShown())
  end)
  T.it('Escape closes it (UISpecialFrames), no Blizzard template anywhere', function()
    local W, EI = session({})
    openWin(W)
    T.eq(W.ui.special, { 'EmpireIntelPlanWindow' })
    T.eq(W.env.EmpireIntelPlanWindow, EI.Window.frame)
    T.eq(W.ui.templates, 0)
  end)
  T.it('/ei plan help keeps the settings text and says which fill path ran', function()
    local W = session({})
    openWin(W)
    local out = slash(W, 'plan help')
    T.truthy(find(out, 'plan: mode auto (fastest route)'), dump(out))
    T.truthy(find(out, 'window fills: SetColorTexture'), dump(out))
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4b: the fill path (D-061)', function()
  T.it('SetColorTexture reads back: fills use it, and chat says so once', function()
    local W, EI = session({})
    local out = openWin(W)
    T.eq(W.EI.Platform.UI.fillPath, 'color')
    T.truthy(find(out, 'window: fills: SetColorTexture (read-back FileData ID 0)'), dump(out))
    T.truthy(EI.Window.bg.color, 'the background is a colour texture')
    T.eq(#FU.texts(W, 'fills:'), 0, 'not shown in the window')
    local again = slash(W, 'plan'); again = slash(W, 'plan')
    T.falsy(find(again, 'window: fills:'), 'once')
  end)
  T.it('no read-back: fills use our white texture plus SetVertexColor, and chat says so', function()
    local W, EI = session({ ui = { colorReadBack = false } })
    local out = openWin(W)
    T.eq(EI.Platform.UI.fillPath, 'white')
    T.truthy(find(out, 'window: fills: our white texture plus SetVertexColor'), dump(out))
    local bg = EI.Window.bg
    T.eq(bg.path, 'Interface\\AddOns\\EmpireIntel\\Media\\White8')
    T.near(bg.vc[1], EI.Theme.C.bg[1], 1e-9)
  end)
  T.it('SetColorTexture raises: the white path', function()
    local W, EI = session({ ui = { colorError = true } })
    openWin(W)
    T.eq(EI.Platform.UI.fillPath, 'white')
    T.eq(EI.Platform.UI.fillEvidence.color.ok, false)
  end)
  T.it('both fail: one UNEXPECTED line, text only, the window still opens and draws its text', function()
    local W, EI = session({ ui = { colorReadBack = false, whiteFail = true } })
    local out = openWin(W)
    T.eq(EI.Platform.UI.fillPath, 'none')
    T.truthy(find(out, 'UNEXPECTED: window: fill: neither SetColorTexture nor the white texture read back'), dump(out))
    T.truthy(EI.Window.IsShown())
    T.truthy(shownText(W, 'Reach level 10'), 'the card text is drawn')
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4b: size and position', function()
  T.it('default 560 x 420 in the centre (Q-P2-4b-4); bounds 440 x 300 to 900 x 800; clamped to the screen', function()
    local W, EI = session({})
    openWin(W)
    local f = EI.Window.frame
    T.eq({ f.w, f.h }, { 560, 420 })
    T.eq(f.points[1][1], 'CENTER')
    T.eq(f.bounds, { 440, 300, 900, 800 })
    T.truthy(f.clamped and f.movable and f.resizable)
  end)
  T.it('a saved size and position are restored; out-of-range sizes are brought within the limits', function()
    local W, EI = session({ eidb = db({ window = { point = 'TOPLEFT', x = 40, y = -60, w = 2000, h = 100 } }) })
    openWin(W)
    local f = EI.Window.frame
    T.eq({ f.w, f.h }, { 900, 300 })
    T.eq({ f.points[1][1], f.points[1][4], f.points[1][5] }, { 'TOPLEFT', 40, -60 })
  end)
  T.it('moving saves the position; resizing with the grip saves the size', function()
    local W, EI = session({})
    openWin(W)
    local f = EI.Window.frame
    f.scripts.OnDragStart(f)
    T.eq(W.ui.moved, 1)
    f:ClearAllPoints(); f:SetPoint('BOTTOMLEFT', nil, 'BOTTOMLEFT', 120.4, 400)     -- the game re-anchors a moved frame
    f.left, f.top = 120.4, 819.4
    f.scripts.OnDragStop(f)
    local s = W.env.EmpireIntelDB.plan.window
    T.eq({ s.point, s.x, s.y }, { 'TOPLEFT', 120, -81 })
    local grip = EI.Window.grip
    grip.scripts.OnMouseDown(grip)
    T.eq(f.sizing, 'BOTTOMRIGHT')
    f:SetSize(640, 500)
    grip.scripts.OnMouseUp(grip)
    s = W.env.EmpireIntelDB.plan.window
    T.eq({ s.w, s.h }, { 640, 500 })
  end)
  T.it('a client without SetResizable: fixed size, no grip, one UNEXPECTED line', function()
    local W, EI = session({ ui = { noResize = true } })
    local out = openWin(W)
    T.falsy(EI.Window.resizable)
    T.isnil(EI.Window.grip)
    T.truthy(find(out, 'UNEXPECTED: window: resize:'), dump(out))
    T.truthy(EI.Window.IsShown())
  end)
  T.it('read-only saved data: the window opens; a move says once that it is not saved', function()
    local W, EI = session({ eidb = { schema = 9, meta = {}, roster = { [C1] = c1() }, plan = {} } })
    openWin(W)
    local f = EI.Window.frame
    f.scripts.OnDragStop(f)
    local out = {}
    for _, l in ipairs(W.prints) do out[#out + 1] = l end
    T.truthy(find(out, 'plan: window not saved: the saved data is read-only'), dump(out))
    T.eq(W.env.EmpireIntelDB.plan, {})
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4b: the Up Next card and the rows (Fastest)', function()
  T.it('the card: C2 now, its live portrait, the step, the points, the time and the gate (the mockup)', function()
    local W, EI = session({})
    openWin(W)
    local card = EI.Window.card
    T.eq(card.art, 'portrait')
    T.eq(card.portrait.path, 'RTPortrait1')
    T.eq(card.label.text, 'UP NEXT')
    T.eq(card.name.text, 'Cee Two')
    T.eq(card.sub.text, 'Priest 6 - played now')
    T.eq(card.title.text, 'Reach level 10, then Tailoring 56 -> 150')
    T.eq(card.earns.text, '+1 Journeyman Tailor')
    T.truthy(card.time.text:find('[estimate]', 1, true))
    T.eq(card.gate.text, 'gate: Journeyman needs level 10 (L-4)')
    T.eq(card.badge.text, 'Realm type ?', 'the test realm name has no type')
    T.eq(card.emblem.path, 'Interface\\TargetingFrame\\UI-PVP-Horde')
    T.eq(card.ring.vc, { 1, 1, 1, 1 }, 'class colour: Priest white')
  end)
  T.it('the header shows earned / target; the footer the reward and the rules', function()
    local W, EI = session({})
    openWin(W)
    T.eq(EI.Window.targetText.text, 'Cap 1/16')
    T.truthy(EI.Window.footRight.text:find('Rules: 18, 11 unverified', 1, true))
    T.truthy(EI.Window.footLeft.text:find('Next reward at 15: Air Rifle', 1, true), EI.Window.footLeft.text)
  end)
  T.it('rows: step, now, points, time, the unverified dot; hover shows each rule with its source', function()
    local W, EI = session({})
    openWin(W)
    local r = row(EI, 1)
    T.eq(r.step.text, 'Enchanting 28 -> 150')
    T.eq(r.now.text, '28/75')
    T.eq(r.pts.text, '+1')
    T.eq(r.time.text, '~3.2 h')
    T.truthy(r.dot.shown)
    T.eq(r.status.coord, EI.Theme.ICON.open)
    r.button.scripts.OnEnter(r.button)
    T.truthy(W.ui.tooltipShown)
    local hit = false
    for _, l in ipairs(W.ui.tooltip) do if l:find('L-4  Training gates', 1, true) and l:find('wow-professions.com', 1, true) then hit = true end end
    T.truthy(hit, table.concat(W.ui.tooltip, '\n'))
  end)
  T.it('an alt on the card: race icon (Scourge -> undead) in a class-coloured ring, class icon, emblem', function()
    local W, EI = session({})
    slash(W, 'plan ignore cee two')
    openWin(W)
    local card = EI.Window.card
    T.eq(card.name.text, 'Cee One')
    T.eq(card.art, 'race')
    T.eq(card.portrait.atlas, 'raceicon-undead-male')
    T.eq(card.classIcon.atlas, 'classicon-paladin')
    T.truthy(card.classIcon.shown)
    T.eq(card.emblem.path, 'Interface\\TargetingFrame\\UI-PVP-Horde')
    T.near(card.ring.vc[1], 0.96, 1e-9)
    T.truthy(card.sub.text:find('seen 1 h ago', 1, true), card.sub.text)
  end)
  T.it('no race icon in the client: the class icon; no faction: no emblem; unknown ruleset badge', function()
    local W, EI = session({ eidb = { schema = 2, meta = {}, plan = { ignore = { [C2] = true } }, roster = {
      [C1] = rec({ name = 'Cee One', class = 'PALADIN', level = 27, xp = 0, race = 'Gnome', sex = 2, professions = {} }) } } })
    openWin(W)
    local card = EI.Window.card
    T.eq(card.art, 'class')
    T.eq(card.portrait.atlas, 'classicon-paladin')
    T.falsy(card.classIcon.shown, 'not twice')
    T.falsy(card.emblem.shown)
    T.eq(card.badge.text, 'Realm type ?')
  end)
  T.it('the target button cycles 16 -> next reward -> next point', function()
    local W, EI = session({})
    openWin(W)
    EI.Window.targetButton.scripts.OnClick(EI.Window.targetButton)
    T.eq(W.env.EmpireIntelDB.plan.target, 'reward')
    T.eq(EI.Window.targetText.text, 'Next reward 1/15')
    EI.Window.targetButton.scripts.OnClick(EI.Window.targetButton)
    T.eq(W.env.EmpireIntelDB.plan.target, 'next')
  end)
  T.it('the mouse wheel scrolls; a smaller window shows fewer rows', function()
    local W, EI = session({})
    openWin(W)
    local list = EI.Window.list
    list.frame:SetHeight(110)
    EI.Window.frame.scripts.OnSizeChanged(EI.Window.frame)
    T.eq(list.visible, 4)
    local first = row(EI, 1).step.text
    list.frame.scripts.OnMouseWheel(list.frame, -1)
    T.eq(list.offset, 1)
    T.neq(row(EI, 1).step.text, first)
    list.frame.scripts.OnMouseWheel(list.frame, 5)
    T.eq(list.offset, 0)
  end)
  T.it('Fastest right-click: Copy the route to my plan, Ignore; the copy is saved by GUID', function()
    local W, EI = session({})
    openWin(W)
    local r = row(EI, 1)
    r.button.scripts.OnClick(r.button, 'RightButton')
    local m = EI.Window.list.menu
    T.eq(m.items.count, 2)
    T.eq(m.items[1].label.text, 'Copy the route to my plan')
    T.eq(m.items[2].label.text, 'Ignore Cee Two')
    m.items[1].button.scripts.OnClick(m.items[1].button)
    local mine = W.env.EmpireIntelDB.plan.mine
    T.eq(mine[1], { kind = 'level', guid = C2, level = 10 })
    T.falsy(m.frame.shown, 'the menu closes')
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4b: My plan', function()
  local function minePlan()
    return { mode = 'mine', mine = { { kind = 'level', guid = C2, level = 10 }, { kind = 'skill', guid = C2, profession = 'Tailoring', skill = 150 },
      { kind = 'level', guid = C1, level = 45 } } }
  end
  T.it('the mode switch saves the mode; the card shows the first open step', function()
    local W, EI = session({ eidb = db({ mine = minePlan().mine }) })
    openWin(W)
    EI.Window.mine.button.scripts.OnClick(EI.Window.mine.button)
    T.eq(W.env.EmpireIntelDB.plan.mode, 'mine')
    T.eq(EI.Window.card.label.text, 'UP NEXT - MY PLAN STEP 1')
    T.eq(EI.Window.card.title.text, 'Level 10 - now 6')
    T.truthy(row(EI, 1).handle.shown, 'drag handles in My plan')
    EI.Window.fast.button.scripts.OnClick(EI.Window.fast.button)
    T.eq(W.env.EmpireIntelDB.plan.mode, 'auto')
    T.falsy(row(EI, 1).handle.shown)
  end)
  T.it('an empty plan says how to fill it', function()
    local W, EI = session({ eidb = db({ mode = 'mine' }) })
    openWin(W)
    T.truthy(EI.Window.card.empty.text:find('My plan is empty', 1, true), EI.Window.card.empty.text)
  end)
  T.it('drag to reorder writes the new order', function()
    local W, EI = session({ eidb = db(minePlan()) })
    openWin(W)
    local r = row(EI, 3)
    r.button.scripts.OnDragStart(r.button)
    T.truthy(EI.Window.list.dragLine.shown)
    W.ui.cursor = { 300, 400 - 22 * 1 - 11 }        -- over slot 1
    r.button.scripts.OnDragStop(r.button)
    local mine = W.env.EmpireIntelDB.plan.mine
    T.eq(mine[1], { kind = 'level', guid = C1, level = 45 })
    T.eq(mine[2], { kind = 'level', guid = C2, level = 10 })
  end)
  T.it('click a target to edit it in place; a valid value is saved, a bad one is refused', function()
    local W, EI = session({ eidb = db(minePlan()) })
    openWin(W)
    local r = row(EI, 1)
    r.button.scripts.OnClick(r.button, 'LeftButton')
    local e = EI.Window.list.edit
    T.truthy(e.shown and e.focus)
    T.eq(e.autoFocus, false)
    T.eq(e.text, '10')
    e.text = '25'
    e.scripts.OnEnterPressed(e)
    T.eq(W.env.EmpireIntelDB.plan.mine[1].level, 25)
    r = row(EI, 1)
    r.button.scripts.OnClick(r.button, 'LeftButton')
    e.text = '99'
    local from = #W.prints
    e.scripts.OnEnterPressed(e)
    T.truthy(W.prints[from + 1]:find('not saved: "level" must be 2 to 60', 1, true), W.prints[from + 1])
    T.eq(W.env.EmpireIntelDB.plan.mine[1].level, 25)
  end)
  T.it('right-click: Move to top, Add a level step after, Edit note, Ignore, Remove', function()
    local W, EI = session({ eidb = db(minePlan()) })
    openWin(W)
    local function menu(i)
      local r = row(EI, i)
      r.button.scripts.OnClick(r.button, 'RightButton')
      return EI.Window.list.menu
    end
    local function pick(m, text)
      for i = 1, m.items.count do if m.items[i].label.text == text then m.items[i].button.scripts.OnClick(m.items[i].button); return true end end
      error('no item ' .. text)
    end
    local m = menu(3)
    T.eq(m.items[1].label.text, 'Move to top')
    T.eq(m.items[m.items.count].label.text, 'Remove step')
    pick(m, 'Move to top')
    T.eq(W.env.EmpireIntelDB.plan.mine[1].guid, C1)
    pick(menu(1), 'Add a level step after')
    T.eq(W.env.EmpireIntelDB.plan.mine[2], { kind = 'level', guid = C1, level = 60 }, 'the next milestone after 45, not 45 again')
    pick(menu(2), 'Edit note')
    local e = EI.Window.list.edit
    e.text = 'with the guild'
    e.scripts.OnEnterPressed(e)
    T.eq(W.env.EmpireIntelDB.plan.mine[2].note, 'with the guild')
    pick(menu(2), 'Remove step')
    T.eq(#W.env.EmpireIntelDB.plan.mine, 3)
    pick(menu(1), 'Ignore Cee One in Fastest')
    T.eq(W.env.EmpireIntelDB.plan.ignore, { [C1] = true })
  end)
  T.it('read-only saved data: an edit says it is not saved and changes nothing', function()
    local plan = minePlan()
    local W, EI = session({ eidb = { schema = 9, meta = {}, roster = { [C1] = c1() }, plan = plan } })
    openWin(W)
    local r = row(EI, 1)
    r.button.scripts.OnClick(r.button, 'LeftButton')
    local e = EI.Window.list.edit
    e.text = '20'
    local from = #W.prints
    e.scripts.OnEnterPressed(e)
    local out = {}
    for i = from + 1, #W.prints do out[#out + 1] = W.prints[i] end
    T.truthy(find(out, 'the saved data is read-only'), dump(out))
    T.eq(W.env.EmpireIntelDB.plan.mine[1].level, 10)
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4b: Legacy and combat', function()
  T.it('opening reads Legacy after the unlock; in combat no read starts and the last read is labelled', function()
    local W, EI = session({ launch = true, legacy25 = 'ids' })
    openWin(W)
    T.truthy((W.calls.GetCategoryList or 0) >= 1)
    T.eq(EI.Window.targetText.text, 'Cap 1/16')
    slash(W, 'plan')
    W.combat = true
    local n = W.calls.GetCategoryList
    openWin(W)
    T.eq(W.calls.GetCategoryList, n, 'no read in combat')
    T.truthy(EI.Window.footLeft.text:find('Legacy values from before combat', 1, true), EI.Window.footLeft.text)
    T.truthy(EI.Window.IsShown())
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4b: the minimap button and the compartment', function()
  T.it('made at login under the minimap, on the round edge at the default angle', function()
    local W, EI = session({})
    local b = EI.MinimapButton.button
    T.truthy(b)
    T.eq(b.parent, W.env.Minimap)
    local p = b.points[1]
    T.near(math.sqrt(p[4] ^ 2 + p[5] ^ 2), 75, 1e-6)
  end)
  T.it('on a square minimap (ElvUI) it sits on the square edge', function()
    local W, EI = session({ ui = { square = true } })
    local p = EI.MinimapButton.button.points[1]
    T.near(math.max(math.abs(p[4]), math.abs(p[5])), 75, 1e-6)
  end)
  T.it('left-click opens and closes the window; right-click switches the mode', function()
    local W, EI = session({})
    local b = EI.MinimapButton.button
    b.scripts.OnClick(b, 'LeftButton')
    T.truthy(EI.Window.IsShown())
    b.scripts.OnClick(b, 'RightButton')
    T.eq(W.env.EmpireIntelDB.plan.mode, 'mine')
    b.scripts.OnClick(b, 'LeftButton')
    T.falsy(EI.Window.IsShown())
  end)
  T.it('dragging moves it along the edge and saves the angle', function()
    local W, EI = session({})
    local b = EI.MinimapButton.button
    b.scripts.OnDragStart(b)
    W.ui.cursor = { 900, 450 }                        -- right of the centre (800, 450): angle 0
    b.scripts.OnUpdate(b)
    b.scripts.OnDragStop(b)
    T.eq(W.env.EmpireIntelDB.plan.minimap.angle, 0)
    T.isnil(b.scripts.OnUpdate)
  end)
  T.it('/ei minimap off hides it and is kept; on shows it', function()
    local W, EI = session({})
    slash(W, 'minimap off')
    T.falsy(EI.MinimapButton.button.shown)
    T.eq(W.env.EmpireIntelDB.plan.minimap.hide, true)
    local W2, EI2 = session({ eidb = db({ minimap = { hide = true } }) })
    T.isnil(EI2.MinimapButton.button, 'not made while hidden')
    slash(W2, 'minimap on')
    T.truthy(EI2.MinimapButton.button.shown)
  end)
  T.it('the compartment entry is registered once, with our mark; its click opens the window', function()
    local W, EI = session({})
    T.eq(W.ui.registered, 1)
    T.eq(W.ui.compartment.text, 'EmpireIntel')
    T.eq(W.ui.compartment.icon, 'Interface\\AddOns\\EmpireIntel\\Media\\Mark')
    EI.MinimapButton.Init()
    T.eq(W.ui.registered, 1)
    W.ui.compartment.func(nil, nil, nil, nil, 'LeftButton')
    T.truthy(EI.Window.IsShown())
  end)
  T.it('no compartment in the client: nothing breaks', function()
    local W, EI = session({ ui = { noCompartment = true } })
    T.truthy(EI.MinimapButton.button)
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4b: the DataStore faction (Q-P2-4a-3, D-059)', function()
  local function withFaction(v)
    return function(W)
      rawset(W.env.DataStore, 'GetCharacterFaction', function(_, key) if key == 'Default.Test Realm.Alt Two' then return v end; return 'Horde' end)
    end
  end
  T.it('read for an alt and shown as from DataStore; never stored', function()
    local W, EI = session({ datastore = 'good', before = withFaction('Alliance') })
    local rows = EI.Views.Collect()
    local alt
    for _, r in ipairs(rows) do if r.guid == 'Player-1-00000002' then alt = r end end
    T.eq(alt.dsFaction, 'Alliance')
    T.isnil(alt.faction)
    local who = EI.PlanView.Who(alt, WALL)
    T.eq(who.faction, 'Alliance'); T.eq(who.factionSrc, 'datastore'); T.eq(who.emblem, 'AllianceEmblem')
    T.isnil(W.env.EmpireIntelDB.roster['Player-1-00000002'], 'nothing from DataStore is stored')
  end)
  T.it('the own record wins over DataStore', function()
    local W, EI = session({ datastore = 'good', before = withFaction('Alliance') })
    local own
    for _, r in ipairs(EI.Views.Collect()) do if r.guid == C2 then own = r end end
    T.eq(own.faction, 'Horde')
    T.isnil(own.dsFaction)
  end)
  T.it('only Alliance or Horde is accepted; anything else is counted as a DataStore error', function()
    local W, EI = session({ datastore = 'good', before = withFaction('Neutral') })
    local res = EI.DataStoreBridge.Read()
    T.eq(res.errors, 1)
    T.truthy(res.firstError:find('GetCharacterFaction returned Neutral', 1, true), res.firstError)
    for _, c in ipairs(res.list) do T.falsy(c.faction == 'Neutral') end
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4b: PlanView (pure)', function()
  local EI = F.loadAddon(F.new(), 'EmpireIntel')
  local V = EI.PlanView
  T.it('art: portrait for the played character, race atlas for an alt, class atlas without a race', function()
    T.eq(V.Who({ isPlayer = true, class = 'PRIEST' }).art, { kind = 'portrait' })
    T.eq(V.Who({ class = 'PRIEST', race = 'Scourge', sex = 3 }).art, { kind = 'race', atlas = 'raceicon-undead-female' })
    T.eq(V.Who({ class = 'MAGE', race = 'NightElf', sex = 2 }).art.atlas, 'raceicon-nightelf-male')
    T.eq(V.Who({ class = 'MAGE' }).art, { kind = 'class', atlas = 'classicon-mage' })
    T.eq(V.Who({ class = 'MAGE', ruleset = 'hardcore' }).ruleset.text, 'Hardcore')
  end)
  T.it('route steps: text, now and status (open, gate, progress, unknown)', function()
    local s = { parts = { { kind = 'level', from = 6, to = 10 }, { kind = 'skill', profession = 'Tailoring', from = 56, to = 150, max = 75 } }, earns = { 'Journeyman Tailor' }, train = 'Journeyman' }
    local text, now, status = V.StepFacts(s)
    T.eq({ text, now, status }, { 'Level 10, then Tailoring 150', '56/75', 'gate' })
    T.eq({ V.StepFacts({ parts = { { kind = 'runs', name = 'Experienced Spelunker', left = 9 } }, earns = {} }) }, { 'Experienced Spelunker', '1/10', 'progress' })
    T.eq({ V.StepFacts({ parts = { { kind = 'runs', name = 'Novice Spelunker', left = 6, unknown = true } }, earns = {} }) }, { 'Novice Spelunker', '?/6', 'unknown' })
    T.eq({ V.StepFacts({ parts = { { kind = 'level', from = 20, to = 25 } }, earns = { 'Novice Priest' } }) }, { 'Level 25 (Novice Priest)', '20', 'open' })
  end)
  T.it('all window text is ASCII', function()
    for _, f in ipairs({ 'Core/PlanView.lua', 'UI/Theme.lua', 'UI/UpNext.lua', 'UI/Rows.lua', 'UI/Window.lua', 'UI/Minimap.lua', 'Platform/UI.lua' }) do
      local h = assert(io.open(root .. '/EmpireIntel/' .. f, 'rb')); local s = h:read('*a'); h:close()
      T.falsy(s:find('[\128-\255]'), f)
    end
  end)
end)

---------------------------------------------------------------------------
T.describe('P2-4b static rules', function()
  local DIR = root .. '/EmpireIntel/'
  local function code(f)
    local h = assert(io.open(DIR .. f, 'rb')); local s = h:read('*a'); h:close()
    return (s:gsub('%-%-[^\n]*', ''):gsub("'[^'\n]*'", "''"))
  end
  local _, FILES = F.loadAddon(F.new(), 'EmpireIntel')
  T.it('only Platform/UI.lua names the game UI globals (Events and Scheduler keep their own CreateFrame)', function()
    local ui = { 'UIParent', 'Minimap%f[^%wB]', 'GetMinimapShape', 'GetCursorPosition', 'UISpecialFrames', 'AddonCompartmentFrame',
      'GameTooltip', 'SetPortraitTexture', 'C_Texture', 'C_ClassColor' }
    for _, f in ipairs(FILES) do
      local c = code(f)
      if f ~= 'Platform/UI.lua' then
        for _, n in ipairs(ui) do T.falsy(c:find('env%.' .. n) or c:find('P%.env%.' .. n), n .. ' in ' .. f) end
        if f ~= 'Platform/Events.lua' and f ~= 'Platform/Scheduler.lua' then T.falsy(c:find('CreateFrame', 1, true), 'CreateFrame in ' .. f) end
      end
    end
  end)
  T.it('no Blizzard template anywhere; CreateFrame only with kind, nil and a parent', function()
    for _, f in ipairs(FILES) do T.falsy(code(f):find('Template', 1, true), f) end
    local c = code('Platform/UI.lua')
    T.truthy(c:find('try%(\'\', create, kind, nil, parent or env%(%)%.UIParent%)') or c:find('create, kind, nil, parent or env().UIParent', 1, true))
  end)
  T.it('Core files draw nothing (no frame, texture or font calls)', function()
    for _, f in ipairs(FILES) do
      if f:sub(1, 5) == 'Core/' then
        local c = code(f)
        for _, n in ipairs({ ':SetPoint', ':CreateTexture', ':CreateFontString', ':SetScript', 'UI.Create(', 'UI.Texture(', 'UI.Fill(' }) do T.falsy(c:find(n, 1, true), n .. ' in ' .. f) end
      end
    end
  end)
  T.it('the TOC has no new header field (the compartment is registered at run time, Q-P2-4b-3)', function()
    local h = assert(io.open(DIR .. 'EmpireIntel.toc')); local toc = h:read('*a'); h:close()
    for line in toc:gmatch('[^\n]+') do
      if line:sub(1, 2) == '##' then T.truthy(({ Interface = 1, Title = 1, Notes = 1, Version = 1, SavedVariables = 1 })[line:match('^## (%a+):')], line) end
    end
  end)
  T.it('the textures: our own TGA files, 32-bit with alpha, power-of-two sizes', function()
    for name, size in pairs({ Icons = { 128, 64 }, White8 = { 8, 8 }, Mark = { 32, 32 } }) do
      local h = assert(io.open(DIR .. 'Media/' .. name .. '.tga', 'rb')); local s = h:read('*a'); h:close()
      T.eq(s:byte(3), 2, name)
      T.eq({ s:byte(13) + 256 * s:byte(14), s:byte(15) + 256 * s:byte(16) }, size, name)
      T.eq(s:byte(17), 32, name)
      T.eq(#s, 18 + size[1] * size[2] * 4, name)
    end
  end)
end)

T.describe('P2-4b: drawing at once and quiet reads', function()
  T.it('the window draws at once ("Reading Legacy challenges..."), then updates when the read finishes; no chat line', function()
    local W, EI = session({ launch = true, legacy25 = 'ids' })
    local from = #W.prints
    W.env.SlashCmdList.EMPIREINTEL('plan')
    T.truthy(EI.Window.footLeft.text:find('Reading Legacy challenges...', 1, true), EI.Window.footLeft.text)
    T.truthy(EI.Window.card.title.text ~= nil)
    W:advance(5)
    T.falsy(EI.Window.footLeft.text:find('Reading', 1, true), EI.Window.footLeft.text)
    for i = from + 1, #W.prints do T.falsy(W.prints[i]:find('reading Legacy challenges', 1, true), W.prints[i]) end
  end)
  T.it('the saved position is restored where it was saved (TOPLEFT against the screen)', function()
    local W, EI = session({ eidb = db({ window = { point = 'TOPLEFT', x = 120, y = -81, w = 560, h = 420 } }) })
    openWin(W)
    local p = EI.Window.frame.points[1]
    T.eq({ p[1], p[2], p[3], p[4], p[5] }, { 'TOPLEFT', W.env.UIParent, 'TOPLEFT', 120, -81 })
  end)
  T.it('a portrait after an atlas resets the texture coordinates', function()
    local W, EI = session({})
    local tex = FU.frame('Frame', W.env.UIParent):CreateTexture()
    tex:SetTexCoord(0.2, 0.3, 0.4, 0.5)
    T.truthy(EI.Platform.UI.Portrait(tex))
    T.eq(tex.coord, { 0, 1, 0, 1 })
  end)
end)

T.describe('P2-4b: Fastest is read only', function()
  T.it('rows cannot be dragged in Fastest; nothing is saved', function()
    local W, EI = session({})
    openWin(W)
    local r = EI.Window.list.pool[2]
    r.button.scripts.OnDragStart(r.button)
    T.isnil(EI.Window.list.dragFrom)
    T.falsy(EI.Window.list.dragLine.shown)
    W.ui.cursor = { 300, 400 - 22 * 1 - 11 }
    r.button.scripts.OnDragStop(r.button)
    T.eq(W.env.EmpireIntelDB.plan.mine or {}, {}, "nothing saved")
  end)
end)

---------------------------------------------------------------------------
-- P2-4b retest (EmpireIntel 0.7.1): the user's live-gate findings, items 1 to 9 (D-063)
---------------------------------------------------------------------------
local function minePlan2(extra)
  local m = { { kind = 'level', guid = C2, level = 10 }, { kind = 'skill', guid = C2, profession = 'Enchanting', skill = 150 },
    { kind = 'level', guid = C1, level = 45 } }
  for _, e in ipairs(extra or {}) do m[#m + 1] = e end
  return { mode = 'mine', mine = m }
end
local function since(W, from) local out = {}; for i = from + 1, #W.prints do out[#out + 1] = W.prints[i] end; return out end
local function menuOf(EI, i)
  local r = row(EI, i)
  r.button.scripts.OnClick(r.button, 'RightButton')
  return EI.Window.list.menu
end
local function pick(m, label)
  for i = 1, m.items.count do if m.items[i].label.text == label then m.items[i].button.scripts.OnClick(m.items[i].button); return true end end
  local have = {}
  for i = 1, m.items.count do have[#have + 1] = m.items[i].label.text end
  error('no item ' .. label .. ' (have: ' .. table.concat(have, ', ') .. ')')
end
local function kinds(list)
  local out = {}
  for _, e in ipairs(list) do out[#out + 1] = (e.kind == 'level' and ('L' .. e.level)) or (e.kind == 'skill' and (e.profession:sub(1, 3) .. e.skill)) or ('C' .. tostring(e.id)) end
  return table.concat(out, ' ')
end

T.describe('P2-4b retest, item 1: my plan keeps prerequisites (L-4)', function()
  local EI0 = F.loadAddon(F.new(), 'EmpireIntel')
  local P0 = EI0.Plan
  local byGuid = { [C2] = { guid = C2, name = 'Cee Two', level = 6, professions = { { name = 'Enchanting', skill = 28, max = 75 } } } }
  local function L(n) return { kind = 'level', guid = C2, level = n } end
  local function E(n) return { kind = 'skill', guid = C2, profession = 'Enchanting', skill = n } end
  T.it('the gate levels: 75 or less none, to 150 level 10, to 225 level 20, to 300 level 35', function()
    T.eq({ P0.GateLevel(75), P0.GateLevel(76), P0.GateLevel(150), P0.GateLevel(151), P0.GateLevel(225), P0.GateLevel(300) },
      { nil, 10, 10, 20, 20, 35 })
  end)
  T.it('no gate when the character is at the level, or already has the rank', function()
    T.isnil(P0.Needs(E(150), { [C2] = { level = 12 } }))
    T.isnil(P0.Needs(E(150), { [C2] = { level = 6, professions = { { name = 'Enchanting', skill = 80, max = 150 } } } }))
    T.eq(P0.Needs(E(150), byGuid), 10)
  end)
  T.it('Move to top: Enchanting 150 above Level 10 carries Level 10 with it', function()
    local list = { L(10), E(150) }
    local out, carried = P0.MoveKeeping(list, 2, 1, byGuid)
    T.eq(kinds(out), 'L10 Enc150')
    T.eq(#carried, 1)
    T.truthy(P0.CarriedText(carried, byGuid):find('Moved with it: Cee Two Level 10 (prerequisite of Cee Two Enchanting 150 (Journeyman needs level 10, L-4))', 1, true))
  end)
  T.it('moving Level 10 below Enchanting 150 takes Enchanting 150 down with it', function()
    local out = P0.MoveKeeping({ L(10), E(150), L(25) }, 1, 3, byGuid)
    T.eq(kinds(out), 'L25 L10 Enc150')
  end)
  T.it('a gate that was already open is left as it was (no surprise moves)', function()
    local out, carried = P0.MoveKeeping({ E(150), L(25), L(30) }, 3, 2, byGuid)
    T.eq(kinds(out), 'Enc150 L30 L25')
    T.eq(#carried, 0)
  end)
  T.it('removing or lowering the level step a later step needs is refused, with the reason', function()
    local out, why = P0.RemoveKeeping({ L(10), E(150) }, 1, byGuid)
    T.isnil(out)
    T.eq(why, 'not removed: Cee Two Enchanting 150 needs level 10 first (Journeyman needs level 10, L-4); remove that step first')
    out, why = P0.ReplaceKeeping({ L(10), E(150) }, 1, L(8), byGuid)
    T.isnil(out)
    T.truthy(why:find('Cee Two Enchanting 150 needs level 10 first', 1, true), why)
    T.truthy(P0.RemoveKeeping({ L(10), E(150) }, 2, byGuid), 'the dependent itself can go')
  end)
  T.it('editing a step whose gate was already open (a note, the same rank) adds nothing', function()
    local e2 = E(150); e2.note = 'later'
    local out, carried = P0.ReplaceKeeping({ E(150) }, 1, e2, byGuid)
    T.eq(kinds(out), 'Enc150')
    T.eq(#carried, 0)
    out = P0.ReplaceKeeping({ E(150) }, 1, E(140), byGuid)
    T.eq(kinds(out), 'Enc140')
  end)
  T.it('raising a skill target that now needs a higher level adds that level step before it', function()
    local out, carried = P0.ReplaceKeeping({ L(10), E(150) }, 2, E(225), byGuid)
    T.eq(kinds(out), 'L10 L20 Enc225')
    T.truthy(carried[1].added)
  end)
  T.it('in the window: dragging Enchanting 150 above Level 10 moves both and says so in chat', function()
    local W, EI = session({ eidb = db(minePlan2()) })
    openWin(W)
    local r = row(EI, 2)
    r.button.scripts.OnDragStart(r.button)
    W.ui.cursor = { 300, 400 - 22 * 1 - 11 }        -- over slot 1
    local from = #W.prints
    r.button.scripts.OnDragStop(r.button)
    T.eq(kinds(W.env.EmpireIntelDB.plan.mine), 'L10 Enc150 L45')
    local out = since(W, from)
    T.truthy(find(out, 'Moved with it: Cee Two Level 10'), dump(out))
  end)
  T.it('in the window: Move to top on Enchanting 150 keeps Level 10 first; Remove on Level 10 is refused', function()
    local W, EI = session({ eidb = db({ mode = 'mine', mine = { { kind = 'level', guid = C1, level = 45 }, { kind = 'level', guid = C2, level = 10 },
      { kind = 'skill', guid = C2, profession = 'Enchanting', skill = 150 } } }) })
    openWin(W)
    pick(menuOf(EI, 3), 'Move to top')
    T.eq(kinds(W.env.EmpireIntelDB.plan.mine), 'L10 Enc150 L45')
    local from = #W.prints
    pick(menuOf(EI, 1), 'Remove step')
    T.eq(kinds(W.env.EmpireIntelDB.plan.mine), 'L10 Enc150 L45')
    T.truthy(find(since(W, from), 'not removed: Cee Two Enchanting 150 needs level 10 first'), dump(since(W, from)))
  end)
  T.it('a skill step with no level step before it shows as a gate, with the reason in its tooltip', function()
    local W, EI = session({ eidb = db({ mode = 'mine', mine = { { kind = 'skill', guid = C2, profession = 'Enchanting', skill = 150 } } }) })
    openWin(W)
    local data = EI.Window.view.rows[1]
    T.eq(data.status, 'gate')
    local hit = false
    for _, l in ipairs(data.tooltip) do if l.text:find('Needs level 10 first (L-4)', 1, true) then hit = true end end
    T.truthy(hit)
  end)
end)

T.describe('P2-4b retest, item 2: Add a skill step after offers the next milestone, never a duplicate', function()
  T.it('after Enchanting 150: Enchanting 225 (with its Level 20); after 225: 300 (with Level 35); after 300: nothing', function()
    local W, EI = session({ eidb = db(minePlan2()) })
    openWin(W)
    local from = #W.prints
    pick(menuOf(EI, 2), 'Add a skill step after')
    T.eq(kinds(W.env.EmpireIntelDB.plan.mine), 'L10 Enc150 L20 Enc225 L45')
    T.truthy(find(since(W, from), 'added Cee Two Enchanting 225. Added before it: Cee Two Level 20'), dump(since(W, from)))
    pick(menuOf(EI, 4), 'Add a skill step after')
    T.eq(kinds(W.env.EmpireIntelDB.plan.mine), 'L10 Enc150 L20 Enc225 L35 Enc300 L45')
    from = #W.prints
    pick(menuOf(EI, 6), 'Add a skill step after')
    T.eq(kinds(W.env.EmpireIntelDB.plan.mine), 'L10 Enc150 L20 Enc225 L35 Enc300 L45')
    T.truthy(find(since(W, from), 'nothing added: Enchanting 300 is already planned.'), dump(since(W, from)))
  end)
  T.it('from a level step: the next milestone of the first craft after what is planned (no second Enchanting 150)', function()
    local W, EI = session({ eidb = db(minePlan2()) })
    openWin(W)
    pick(menuOf(EI, 1), 'Add a skill step after')
    local mine = W.env.EmpireIntelDB.plan.mine
    local n150 = 0
    for _, e in ipairs(mine) do if e.kind == 'skill' and e.skill == 150 and e.profession == 'Tailoring' then n150 = n150 + 1 end end
    T.eq(n150, 1, 'Tailoring 150 once (the first craft recorded is Tailoring)')
    T.eq(kinds(mine), 'L10 Tai150 Enc150 L45')
  end)
  T.it('Add a level step after: the next class milestone after the levels planned', function()
    local W, EI = session({ eidb = db(minePlan2()) })
    openWin(W)
    pick(menuOf(EI, 1), 'Add a level step after')
    T.eq(kinds(W.env.EmpireIntelDB.plan.mine), 'L10 L25 Enc150 L45')
  end)
end)

T.describe('P2-4b retest, item 3: notes have their own space', function()
  T.it('Edit note opens a bar below the rows, clear of the step text; Enter saves; the note shows in the tooltip and on the card', function()
    local W, EI = session({ eidb = db(minePlan2()) })
    openWin(W)
    pick(menuOf(EI, 1), 'Edit note')
    local list = EI.Window.list
    local bar = list.bar
    T.truthy(bar.frame.shown)
    T.eq(bar.label.text, 'Note for step 1 (Level 10):')
    local e = list.edit
    T.eq(e.parent, bar.frame, 'the edit box sits in the bar, not on a row')
    for _, p in ipairs(e.points) do T.neq(p[2], row(EI, 1).step, 'not anchored to the step text') end
    T.truthy(e.focus)
    e.text = 'with the guild'
    e.scripts.OnEnterPressed(e)
    T.eq(W.env.EmpireIntelDB.plan.mine[1].note, 'with the guild')
    T.falsy(bar.frame.shown)
    T.eq(row(EI, 1).step.text, 'Level 10 (note)')
    local hit = false
    for _, l in ipairs(EI.Window.view.rows[1].tooltip) do if l.text == 'Note: with the guild' then hit = true end end
    T.truthy(hit)
    T.eq(EI.Window.card.gate.text, 'Note: with the guild')
  end)
  T.it('clicking away saves the note too; Escape cancels', function()
    local W, EI = session({ eidb = db(minePlan2()) })
    openWin(W)
    pick(menuOf(EI, 2), 'Edit note')
    local e = EI.Window.list.edit
    e.text = 'buy vellum'
    e:ClearFocus()
    T.eq(W.env.EmpireIntelDB.plan.mine[2].note, 'buy vellum')
    pick(menuOf(EI, 2), 'Edit note')
    T.eq(e.text, 'buy vellum', 'the box starts with the saved note')
    e.text = 'changed'
    e.scripts.OnEscapePressed(e)
    T.eq(W.env.EmpireIntelDB.plan.mine[2].note, 'buy vellum')
    T.falsy(EI.Window.list.bar.frame.shown)
  end)
  T.it('the row list makes room for the bar while it is open', function()
    local W, EI = session({ eidb = db(minePlan2()) })
    openWin(W)
    local list = EI.Window.list
    local before = EI.Rows.Slots(list)
    pick(menuOf(EI, 1), 'Edit note')
    T.eq(EI.Rows.Slots(list), before - 1)
  end)
end)

T.describe('P2-4b retest, item 4: ignoring a character marks its steps in my plan', function()
  T.it('Ignore from my plan: its steps are kept, marked, not up next; chat says how many; Unignore undoes it', function()
    local W, EI = session({ eidb = db({ mode = 'mine', mine = { { kind = 'level', guid = C1, level = 45 }, { kind = 'level', guid = C2, level = 10 } } }) })
    openWin(W)
    local from = #W.prints
    pick(menuOf(EI, 1), 'Ignore Cee One in Fastest')
    local out = since(W, from)
    T.truthy(find(out, 'Cee One is left out of the fastest route. Its 1 step in my plan are kept, marked "ignored"'), dump(out))
    local v = EI.Window.view
    T.eq(v.rows[1].status, 'ignored')
    T.eq(row(EI, 1).step.text, 'Level 45 (ignored)')
    T.eq(EI.Window.card.label.text, 'UP NEXT - MY PLAN STEP 2', 'the ignored step is not up next')
    T.truthy(v.footer.total:find('1 ignored', 1, true), v.footer.total)
    pick(menuOf(EI, 1), 'Unignore Cee One')
    T.eq(W.env.EmpireIntelDB.plan.ignore, {})
    T.neq(EI.Window.view.rows[1].status, 'ignored')
  end)
  T.it('/ei plan ignore says the same; /ei next marks the steps', function()
    local W = session({ eidb = db({ mode = 'mine', mine = { { kind = 'level', guid = C1, level = 45 } } }) })
    local out = slash(W, 'plan ignore cee one')
    T.truthy(find(out, 'Its 1 step in my plan are kept'), dump(out))
    out = slash(W, 'next')
    T.truthy(find(out, '1. (ignored) Cee One'), dump(out))
  end)
  T.it('Fastest says how many are ignored in its footer', function()
    local W, EI = session({})
    slash(W, 'plan ignore cee one')
    openWin(W)
    T.truthy(EI.Window.footRight.text:find('1 ignored', 1, true), EI.Window.footRight.text)
  end)
end)

T.describe('P2-4b retest, item 5: the target button is labelled and has a tooltip', function()
  T.it('Cap 1/16 -> Next reward 1/15 -> Next point 1/2; hovering explains the three', function()
    local W, EI = session({})
    openWin(W)
    local b = EI.Window.targetButton
    T.eq(EI.Window.targetText.text, 'Cap 1/16')
    b.scripts.OnClick(b)
    T.eq(EI.Window.targetText.text, 'Next reward 1/15')
    b.scripts.OnClick(b)
    T.eq(EI.Window.targetText.text, 'Next point 1/2')
    b.scripts.OnEnter(b)
    T.truthy(W.ui.tooltipShown)
    local all = table.concat(W.ui.tooltip, '\n')
    T.truthy(all:find('Target: Next point 1/2', 1, true), all)
    T.truthy(all:find('Cap: 16 points, the spending cap per character (L-12, unverified)', 1, true), all)
    T.truthy(all:find('Next reward: the next reward on the track', 1, true), all)
    T.truthy(b.w >= 110, 'wide enough for the label')
  end)
end)

T.describe('P2-4b retest, item 6: the realm-type badge', function()
  local EI0 = F.loadAddon(F.new(), 'EmpireIntel')
  local V = EI0.PlanView
  T.it('read from the end of the realm name; Hardcore from the game; else unknown (never guessed)', function()
    local function t(realm, rs) return V.RealmType(realm, rs).text end
    T.eq(t('CAMWOW US2 Realm 3 PvE'), 'PvE')
    T.eq(t('Some Realm PvP'), 'PvP')
    T.eq(t('Some Realm RP-PvP'), 'RP-PvP')
    T.eq(t('Some Realm RP-PvE'), 'RP-PvE')
    T.eq(t('Some Realm RP'), 'RP-PvE')
    T.eq(t('SomeRealmPvE'), 'PvE')
    T.eq(t('Sharp'), 'Realm type ?')
    T.eq(t('Test Realm'), 'Realm type ?')
    T.eq(t(nil), 'Realm type ?')
    T.eq(t('Some Realm PvE', 'hardcore'), 'Hardcore')
    T.truthy(V.RealmType('X PvE').why:find('[inferred]', 1, true))
  end)
  T.it('on the card, with the reason in the card tooltip', function()
    local W, EI = session({ eidb = { schema = 2, meta = {}, plan = { ignore = { [C2] = true } }, roster = { [C1] = (function()
      local r = c1(); r.realm = 'CAMWOW US2 Realm 3 PvE'; return r end)() } } })
    openWin(W)
    T.eq(EI.Window.card.badge.text, 'PvE')
    local hit = false
    for _, l in ipairs(EI.Window.view.card.tooltip) do if l.text:find('Realm type PvE: from the realm name [inferred]', 1, true) then hit = true end end
    T.truthy(hit)
  end)
end)

T.describe('P2-4b retest, item 7: the faction emblem', function()
  T.it('the game\'s faction icon file, cropped to its icon; the atlas only when the file does not read back', function()
    local W, EI = session({})
    openWin(W)
    local em = EI.Window.card.emblem
    T.eq(em.path, 'Interface\\TargetingFrame\\UI-PVP-Horde')
    T.eq(em.coord, { 0, 0.625, 0, 0.625 })
    T.eq({ em.w, em.h }, { 26, 26 })
    local tex = FU.frame('Frame', W.env.UIParent):CreateTexture()
    tex.GetTexture = function(self) if self.atlas then return self.path end return nil end   -- the file does not load
    T.eq(EI.Platform.UI.Emblem(tex, 'Alliance'), 'atlas')
    T.eq(tex.atlas, 'AllianceEmblem')
    T.isnil(EI.Platform.UI.Emblem(tex, 'Neutral'))
  end)
end)

T.describe('P2-4b retest, item 8: the combat footer refreshes when combat ends', function()
  T.it('opened in combat: "Legacy not read (in combat)"; when combat ends the window reads Legacy and the line goes', function()
    local W, EI = session({ launch = true, legacy25 = 'ids' })
    W.combat = true
    W:fire('PLAYER_REGEN_DISABLED')
    openWin(W)
    T.truthy(EI.Window.footLeft.text:find('Legacy not read (in combat)', 1, true), EI.Window.footLeft.text)
    local n = W.calls.GetCategoryList or 0
    W.combat = false
    W:fire('PLAYER_REGEN_ENABLED')
    W:advance(5)
    T.truthy((W.calls.GetCategoryList or 0) > n, 'a read after combat')
    T.falsy(EI.Window.footLeft.text:find('combat', 1, true), EI.Window.footLeft.text)
  end)
  T.it('a closed window does not read when combat ends', function()
    local W, EI = session({ launch = true, legacy25 = 'ids' })
    W.combat = true
    openWin(W)
    slash(W, 'plan')
    local n = W.calls.GetCategoryList or 0
    W.combat = false
    W:fire('PLAYER_REGEN_ENABLED')
    W:advance(5)
    T.eq(W.calls.GetCategoryList or 0, n)
  end)
end)

T.describe('P2-4b retest, item 9: one meaning in both modes', function()
  local EI0 = F.loadAddon(F.new(), 'EmpireIntel')
  local V = EI0.PlanView
  local pal = { guid = C1, name = 'Cee One', class = 'PALADIN', level = 17, professions = {} }
  local pri = { guid = C2, name = 'Cee Two', class = 'PRIEST', level = 6, isPlayer = true,
    professions = { { name = 'Enchanting', skill = 28, max = 75 } } }
  local function res(steps) return { earned = 2, earnedSrc = 'game', target = 16, targetKind = 'points', states = { {} }, steps = steps,
    left = 0, reached = 16, excluded = { ignored = 0, ruleset = 0 }, unlocked = true } end
  local first = { row = pri, kind = 'class', parts = { { kind = 'level', from = 6, to = 25 } }, hours = 5, rules = {}, earns = { 'Novice Priest' }, points = 1, atLevel = 6 }
  local dungeon = { row = pal, kind = 'dungeon', parts = { { kind = 'level', from = 17, to = 20 }, { kind = 'runs', name = 'Experienced Spelunker', left = 9 } },
    hours = 8, rules = { 'L-7' }, earns = { 'Experienced Spelunker' }, points = 1, atLevel = 17 }
  local ench = { row = pri, kind = 'craft', parts = { { kind = 'level', from = 10, to = 20 }, { kind = 'skill', profession = 'Enchanting', from = 150, to = 225, max = 150 } },
    hours = 9, rules = { 'L-4' }, earns = { 'Expert Enchanter' }, points = 1, atLevel = 10, train = 'Expert' }
  T.it('a dungeon challenge is "Account" in Fastest as in My plan; the step names the character it runs on', function()
    local v = V.Build({ mode = 'auto', res = res({ first, dungeon }), now = WALL })
    local r = v.rows[1]
    T.eq(r.who.name, 'Account')
    T.eq(r.step, 'Level 20 on Cee, then Experienced Spelunker')
    T.eq(r.now, '1/10')
    T.isnil(r.guid, 'no Ignore offered for the account')
    T.truthy(r.tooltip[2].text:find('the route runs it on Cee One Paladin 17', 1, true), r.tooltip[2].text)
    local m = V.Build({ mode = 'mine', plan = { steps = { { kind = 'challenge', id = 99, n = 1 } }, problems = {}, total = 1 }, rows = {}, now = WALL, unlocked = true, res = res({}) })
    T.eq(m.rows[1].who.name, 'Account')
  end)
  T.it('NOW is today\'s value in Fastest too; the route\'s value is in the tooltip', function()
    local v = V.Build({ mode = 'auto', res = res({ first, ench }), now = WALL })
    local r = v.rows[1]
    T.eq(r.now, '28/75')
    T.eq(r.who.level, 6, 'today\'s level in the character column')
    local hit = false
    for _, l in ipairs(r.tooltip) do if l.text == 'NOW is today\'s value; at this point of the route: 150/150' then hit = true end end
    T.truthy(hit)
    local lv = V.Build({ mode = 'auto', res = res({ ench, first }), now = WALL }).rows[1]
    T.eq(lv.now, '6')
  end)
  T.it('copying the route keeps the runner\'s level step before a dungeon challenge', function()
    local d = { row = pal, kind = 'dungeon', id = 777, parts = dungeon.parts }
    local list = EI0.Plan.FromRoute({ d })
    T.eq(list, { { kind = 'level', guid = C1, level = 20 }, { kind = 'challenge', id = 777 } })
  end)
end)

T.describe('P2-4b retest 0.7.2, finding 10: my plan counts from the earlier steps (D-065)', function()
  local plan = { mode = 'mine', mine = {
    { kind = 'level', guid = C2, level = 10 },
    { kind = 'skill', guid = C2, profession = 'Enchanting', skill = 150 },
    { kind = 'level', guid = C2, level = 20 },
    { kind = 'skill', guid = C2, profession = 'Enchanting', skill = 225 },
    { kind = 'level', guid = C2, level = 15 },
  } }
  T.it('each row\'s time and points run from the end of the earlier steps; NOW stays today\'s', function()
    local W, EI = session({ eidb = db(plan) })
    openWin(W)
    local rows = EI.Window.view.rows
    local st = EI.Route.State(EI.Window.byGuid[C2], (W.EI.Platform.Now()), EI.Plan.Rates())
    local h10, h20 = EI.Route.LevelHours(st, 10), EI.Route.LevelHours(st, 20)
    T.near(rows[1].hours, h10, 1e-9)
    T.near(rows[3].hours, h20 - h10, 1e-9, 'Level 20 from 10, not from 6')
    T.near(rows[4].hours, EI.Route.SkillHours(150, 225), 1e-9, 'Enchanting 225 from 150, not from 28')
    T.eq(rows[4].pts, '+1')
    T.eq(rows[4].now, '28/75', 'NOW is today\'s value')
  end)
  T.it('a step an earlier step already reaches says "covered by step n", with no time or points, and is not up next', function()
    local W, EI = session({ eidb = db(plan) })
    openWin(W)
    local r = EI.Window.view.rows[5]
    T.eq(r.status, 'covered')
    T.eq(r.time, '')
    T.eq(r.pts, '')
    T.eq(row(EI, 5).step.text, 'Level 15 (covered by step 3)')
    T.truthy(EI.Window.view.footer.total:find('1 covered', 1, true), EI.Window.view.footer.total)
    local hit = false
    for _, l in ipairs(r.tooltip) do if l.text:find('Covered by step 3', 1, true) then hit = true end end
    T.truthy(hit)
  end)
  T.it('two milestones in one step count +2', function()
    local W, EI = session({ eidb = db({ mode = 'mine', mine = { { kind = 'level', guid = C1, level = 60 } } }) })
    openWin(W)
    T.eq(EI.Window.view.rows[1].pts, '+2', 'C1 27 -> 60 passes 45 and 60')
  end)
end)

T.describe('P2-4b retest 0.7.2: repeated saved steps are removed at load (D-065)', function()
  local function dupPlan()
    return { mode = 'mine', mine = {
      { kind = 'level', guid = C2, level = 10 },
      { kind = 'skill', guid = C2, profession = 'Enchanting', skill = 150 },
      { kind = 'level', guid = C2, level = 20 },
      { kind = 'skill', guid = C2, profession = 'Enchanting', skill = 150, note = 'vellum' },
      { kind = 'challenge', id = 62032 }, { kind = 'challenge', id = 62032 },
    } }
  end
  T.it('the first is kept (with a later copy\'s note), the others go, and chat says which', function()
    local W = session({ eidb = db(dupPlan()) })
    local mine = W.env.EmpireIntelDB.plan.mine
    T.eq(#mine, 4)
    T.eq(mine[2], { kind = 'skill', guid = C2, profession = 'Enchanting', skill = 150, note = 'vellum' })
    T.eq(mine[4], { kind = 'challenge', id = 62032 })
    T.truthy(find(W.prints, 'plan: removed 2 repeated steps from my plan (the first of each is kept): step 4 Cee Two Enchanting 150, step 6 challenge 62032.'), dump(W.prints))
  end)
  T.it('no repeats: nothing said; a bad step is never removed as a repeat; read-only: said, nothing changed', function()
    local W = session({ eidb = db({ mine = { { kind = 'level', guid = C2, level = 10 } } }) })
    for _, l in ipairs(W.prints) do T.falsy(l:find('repeated', 1, true), l) end
    local W2 = session({ eidb = db({ mine = { { kind = 'level', guid = C2, level = 10 }, { kind = 'level', guid = C2, level = 10, name = 'x' } } }) })
    T.eq(#W2.env.EmpireIntelDB.plan.mine, 2)
    local W3 = session({ eidb = { schema = 9, meta = {}, roster = { [C1] = c1() }, plan = dupPlan() } })
    T.eq(#W3.env.EmpireIntelDB.plan.mine, 6)
    T.truthy(find(W3.prints, 'my plan has repeated steps; not saved: the saved data is read-only'), dump(W3.prints))
  end)
end)
