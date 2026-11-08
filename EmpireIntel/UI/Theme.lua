local ADDON, EI = ...
-- EmpireIntel / UI / Theme.lua                                           (Phase 2, increment P2-4b)
--
-- PURPOSE
--   The window's look as data (the approved mockup, D-060): colours, sizes, the game's built-in fonts (none
--   shipped, D-060), our icon sheet's cells, the race-to-atlas map (EI-E-30), the window's default and limits
--   (Q-P2-4b-4). Pure: no game call.

EI = EI or {}

local T = {}
EI.Theme = T

local function hex(h, a)
  return { tonumber(string.sub(h, 1, 2), 16) / 255, tonumber(string.sub(h, 3, 4), 16) / 255,
    tonumber(string.sub(h, 5, 6), 16) / 255, a or 1 }
end
T.hex = hex

T.C = {
  bg = hex('16171b'), surface = hex('1d1e24'), border = hex('2b2d34'), line = hex('24262c'), rowLine = hex('1f2026'),
  rowHover = hex('22232a'), rowDrag = hex('26283a'), switchBg = hex('1f2026'), switchOn = hex('34364a'),
  text = hex('e6e6e9'), strong = hex('ffffff'), muted = hex('9a9ca5'), dim = hex('8a8c95'), soft = hex('b8bac2'),
  accent = hex('a5a8ff'), accentLine = hex('7b7ff0'), green = hex('a5d6a7'), doneFill = hex('5b8f6a'),
  amber = hex('e0a83a'), gateText = hex('d9b36a'), menuBg = hex('202128'), menuBorder = hex('34363e'),
  menuHover = hex('2c2e3a'), danger = hex('f0a8a8'), editBg = hex('22232b'),
  hordeText = hex('f1b8b8'), hordeBg = hex('3a1f22'), allianceText = hex('b9cdf4'), allianceBg = hex('1f2840'),
  normalText = hex('c9d1c9'), normalBg = hex('23302a'), hardText = hex('ffd0c2'), hardBg = hex('45231a'),
  unknownText = hex('c4c6cd'), unknownBg = hex('26272d'),
}

-- the game's built-in fonts (EI-E-29: SetFont with FRIZQT__ returned true); ARIALN for the dense rows, with a
-- fallback to FRIZQT inside Platform/UI.lua if the client refuses it
T.FONTS = { title = 'Fonts\\FRIZQT__.TTF', rows = 'Fonts\\ARIALN.TTF' }
T.SIZE = { title = 13, text = 12, small = 11, tiny = 10, card = 13, cardName = 14 }

T.WINDOW = { w = 560, h = 420, minW = 440, minH = 300, maxW = 900, maxH = 800 }   -- Q-P2-4b-4
T.HEADER_H, T.FOOTER_H, T.ROW_H, T.CARD_H, T.PAD = 36, 30, 22, 92, 12
T.COLUMNS = { status = 22, char = 120, now = 46, pts = 28, time = 50, handle = 14 }

-- icon sheet cells (Media/Icons.tga, 128 x 64): left, right, top, bottom
local function cell(x, y, s) s = s or 16; return { x / 128, (x + s) / 128, y / 64, (y + s) / 64 } end
T.ICON = {
  route = cell(0, 0), open = cell(16, 0), progress = cell(32, 0), done = cell(48, 0), gate = cell(64, 0),
  unknown = cell(80, 0), dot = cell(96, 0), close = cell(112, 0),
  grip = cell(0, 16), handle = cell(16, 16), chevron = cell(32, 16), check = cell(48, 16),
  ring = cell(0, 32, 32), disc = cell(32, 32, 32), thinRing = cell(64, 32, 32),
}
T.STATUS_COLOR = { open = 'muted', progress = 'amber', done = 'doneFill', gate = 'muted', unknown = 'muted' }

-- race file (UnitRace's second value) -> the atlas token (EI-E-30: Scourge is "undead"); others lower case
T.RACE_ATLAS = { Scourge = 'undead', NightElf = 'nightelf' }

--- The race icon atlas for a race file and sex (2 male, 3 female), or nil.
function T.RaceAtlas(race, sex)
  if type(race) ~= 'string' or race == '' then return nil end
  local token = T.RACE_ATLAS[race] or string.lower(race)
  local g = (sex == 3) and 'female' or ((sex == 2) and 'male' or nil)
  if not g then return nil end
  return 'raceicon-' .. token .. '-' .. g
end

function T.ClassAtlas(class)
  if type(class) ~= 'string' or class == '' then return nil end
  return 'classicon-' .. string.lower(class)
end

T.EMBLEM = { Horde = 'HordeEmblem', Alliance = 'AllianceEmblem' }      -- EI-E-30 (D-060: the game's own)
