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
    T.eq(card.badge.text, 'Normal')
    T.eq(card.emblem.atlas, 'HordeEmblem')
    T.eq(card.ring.vc, { 1, 1, 1, 1 }, 'class colour: Priest white')
  end)
  T.it('the header shows earned / target; the footer the reward and the rules', function()
    local W, EI = session({})
    openWin(W)
    T.eq(EI.Window.targetText.text, '1 / 16')
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
    T.eq(card.emblem.atlas, 'HordeEmblem')
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
    T.eq(card.badge.text, 'Ruleset unknown')
  end)
  T.it('the target button cycles 16 -> next reward -> next point', function()
    local W, EI = session({})
    openWin(W)
    EI.Window.targetButton.scripts.OnClick(EI.Window.targetButton)
    T.eq(W.env.EmpireIntelDB.plan.target, 'reward')
    T.eq(EI.Window.targetText.text, '1 / 15')
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
    T.eq(W.env.EmpireIntelDB.plan.mine[2], { kind = 'level', guid = C1, level = 45 })
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
    T.eq(EI.Window.targetText.text, '1 / 16')
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
