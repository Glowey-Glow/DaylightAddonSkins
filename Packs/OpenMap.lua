-- OpenMap, dressed throughout. What's dressed and how:
--   * Its dialogs and panels (search list, pins list and editor, the pin code window, What's new,
--     friends, the welcome choice, the dungeon card, the markup bars): OpenMap draws them through
--     four helpers on OpenMap.Look (Font, Panel, Window, Dropdown: "other addons may restyle these",
--     its Core.lua says), so each helper is followed and what it drew is swapped for DaylightUI's
--     shell; everything inside is then dressed as below.
--   * The settings menu (OpenMapMenu): its nine-slice, rock ground and header off, the shell on;
--     its tabs, tiles, switches, sliders and scroll bar dressed.
--   * The dungeon view (OpenMapDungeonView): its bar (back button, floor arrows, floor name, close),
--     the floor list, the side panel (title and levels, the Floors / Bosses / Quests / Loot tabs,
--     its rows, buttons, links, the floors' pictures' edges, its scroll bar), the hint: the quest
--     log's paper, frame, filigree and shade off, bronze rules as hairlines, grounds neutral.
--   * The tabs at the map's edge (OpenMap's own rail and the dungeon's two): clean tiles like
--     TrueshotLodge's and Questie's tabs, the lit or shown one edged in the accent; the rail's arrow gray.
--   * The coordinate labels (Azeroth / Player at the map's foot): a thin neutral edge, label ink.
--   * Its tiles and buttons framed as action buttons: the action-bar frame off, a thin edge on;
--     the checked glow in the accent.
--   * The corner row while "Buttons as edge tabs" is off (the OpenMap button, the favorites, the
--     arrow that folds them away): the map's own children, found by shape on each refresh of the
--     corner (so switching the setting with the map open is followed) and dressed as above, the
--     arrow gray.
--   * Its copy of the quest log toggle on the full-screen map: page buttons, as DaylightUI dresses
--     the game's own.
--   * The draw tray's tools: the picked one's gold wash and gold glyph in the accent, the others'
--     cream glyphs in DaylightUI's text ink.
--   * Its dropdown lists that grow while open (the search results): what they add is dressed on
--     the next frame.
--   * Its windows (Look:Window: What's new, Pins, the pin editor and code window, Report, Friends,
--     Welcome, the draw tray, notes export, Bench) on a solid ground (they sit over the map), and
--     dressed again on the next frame, once what they hold is made; a window that sets its own
--     OnShow afterwards (What's new) has the show hook put back. What's new: its count box and
--     version list as quiet wells, the picked version in the accent wash, its buttons and link box
--     DaylightUI's, its tan and gold text in DaylightUI's inks; its parchment page and the notes on
--     it stay (the page's scroll bar is DaylightUI's, refilled pages dressed as they're shown).
--     A scroll frame's content refilled while shown is dressed on the next frame; the draw
--     tray's Done glow is in the accent.
-- How the pieces are found: by what they are (template parts, keys, art by file and atlas), so a
-- frame from any of its files is dressed the same way. Colors it sets again on every refresh
-- (gold text, bronze edges, the picked floor in gold) are followed: the frame's own setter is
-- hooked and the color turned into DaylightUI's as it's set.
-- Its content stays: the map, the dungeon's picture, its pins, POIs and icons on the map, the
-- floors' pictures (their edge is dressed), the action and favorite icons, the favorite star.
-- Its minimap button is DaylightUI's button collector's.
local _, ns = ...
if not ns.ok then return end

ns.Target("OpenMap", "OpenMap", { window = true, controls = true, text = true, shadow = true, font = "daylight" })

local OM = _G.OpenMap
local Look = type(OM) == "table" and OM.Look
if type(Look) ~= "table" or type(Look.Window) ~= "function" or type(Look.Panel) ~= "function"
	or type(Look.Dropdown) ~= "function" then
	return
end

local KEY = "OpenMap"
local API = ns.API

local function Mod()
	local ok, m = pcall(OM.GetModule, OM, "worldmap")
	return ok and type(m) == "table" and m or nil
end

-- ---------------------------------------------------------------------------------------------
-- Colors: OpenMap's gold and bronze as DaylightUI's
-- ---------------------------------------------------------------------------------------------

local function Ink(name)
	local c = ns.Colors()[name]
	if type(c) ~= "table" then return 1, 1, 1 end
	return c[1], c[2], c[3]
end

local function Hex(r, g, b)
	return ("%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-- An ink as a color code's six digits, worked out once per ink: kept until DaylightUI's inks are
-- read again (ns.Colors hands back a new table then).
local hexes, hexesOf = {}, nil
local function InkHex(name)
	local c = ns.Colors()
	if c ~= hexesOf then
		wipe(hexes)
		hexesOf = c
	end
	local hex = hexes[name]
	if not hex then
		hex = Hex(Ink(name))
		hexes[name] = hex
	end
	return hex
end

local function BrightGold(r, g, b)
	return r > 0.88 and g > 0.68 and g < 0.9 and b < 0.5
end

-- Bronze, tan and brown: red over green over blue, and warm.
local function Warm(r, g, b)
	return r >= g and g >= b and r - b > 0.12
end

-- A text color of its: bright gold (names, headings) bright, tan small print as labels.
local function TextColorFor(r, g, b)
	if BrightGold(r, g, b) then return Ink("VALUE") end
	if Warm(r, g, b) and r > 0.55 and r < 0.97 then return Ink("LABEL") end
end

-- Its color codes inside text: gold bright, its tans as labels, its grays dim.
local CODES = {
	ffd100 = "VALUE", ffd200 = "VALUE", ffcc00 = "VALUE", ffe680 = "VALUE",
	e6c27a = "LABEL", e6b85c = "LABEL", c8a86a = "LABEL",
	["998866"] = "OFF", bbbbbb = "OFF",
}

local function Recode(a, hex)
	local name = CODES[string.lower(hex)]
	if not name then return nil end
	return "|c" .. a .. InkHex(name)
end

local function RecodeText(text)
	if type(text) ~= "string" or not string.find(text, "|c", 1, true) then return text end
	return (string.gsub(text, "|c(%x%x)(%x%x%x%x%x%x)", Recode))
end

-- A frame's edge: its lit gold in the accent, bronze a quiet neutral line.
local function EdgeFor(r, g, b, a)
	if BrightGold(r, g, b) then
		local ar, ag, ab = ns.AccentOf(KEY)
		return ar, ag, ab, 1
	end
	if Warm(r, g, b) then return 1, 1, 1, 0.12 end
end

-- A frame's ground: its browns a neutral dark, its alpha kept.
local function GroundFor(r, g, b, a)
	if Warm(r, g, b) and r < 0.35 then return 0.05, 0.05, 0.06, a end
end

local busy = false

-- The text color and text it sets from now on, turned as it's set (and what it has now). The
-- hooks are shared by every string: they're the same for each.
local function InkColor(self, r, g, b)
	if busy or type(r) ~= "number" or ns.Look(KEY, "daylightColors") == false then return end
	local nr, ng, nb = TextColorFor(r, g, b)
	if nr then
		busy = true
		self:SetTextColor(nr, ng, nb)
		busy = false
	end
end

local function InkCodes(self, t)
	-- (Text with no color code in it, nearly all of it, is let go before the setting is read.)
	if busy or type(t) ~= "string" or not string.find(t, "|c", 1, true) then return end
	if ns.Look(KEY, "daylightColors") == false then return end
	local new = RecodeText(t)
	if new ~= t then
		busy = true
		self:SetText(new)
		busy = false
	end
end

-- Strings set many times a second with text that never holds one of its color codes (the
-- coordinates): only their color is followed, so nothing runs as their text is set.
local colorOnly = setmetatable({}, { __mode = "k" })

local inked = setmetatable({}, { __mode = "k" })
local function InkText(fs)
	if inked[fs] or not ns.Usable(fs) or not fs.SetTextColor then return end
	inked[fs] = true
	hooksecurefunc(fs, "SetTextColor", InkColor)
	InkColor(fs, fs:GetTextColor())
	if colorOnly[fs] then return end
	hooksecurefunc(fs, "SetText", InkCodes)
	InkCodes(fs, fs:GetText())
end

-- A backdrop's edge and ground from now on, turned as they're set (and what they are now).
local backed = setmetatable({}, { __mode = "k" })
local function InkBackdrop(f)
	if backed[f] or not f.SetBackdropBorderColor or not f.GetBackdrop or not f:GetBackdrop() then return end
	backed[f] = true
	local function edge(self, r, g, b, a)
		if busy or type(r) ~= "number" then return end
		local nr, ng, nb, na = EdgeFor(r, g, b, a or 1)
		if nr then
			busy = true
			self:SetBackdropBorderColor(nr, ng, nb, na)
			busy = false
		end
	end
	local function ground(self, r, g, b, a)
		if busy or type(r) ~= "number" then return end
		local nr, ng, nb, na = GroundFor(r, g, b, a or 1)
		if nr then
			busy = true
			self:SetBackdropColor(nr, ng, nb, na)
			busy = false
		end
	end
	hooksecurefunc(f, "SetBackdropBorderColor", edge)
	hooksecurefunc(f, "SetBackdropColor", ground)
	edge(f, f:GetBackdropBorderColor())
	ground(f, f:GetBackdropColor())
end

-- ---------------------------------------------------------------------------------------------
-- Its art, by file and atlas
-- ---------------------------------------------------------------------------------------------

-- Gone wherever it is: the quest log's paper and frame round the dungeon panel, the action-bar
-- frame round its icons (and its hover), the classic slot, the dialog header, the rock ground.
-- (Lower case: the client hands an atlas back in its own spelling, not the one it was set with, so
-- "questlog-frame" comes back as "QuestLog-frame".)
local KILL_ATLAS = {
	["questlog-frame"] = true, ["questlog-frame-filigree"] = true,
	["questlog-frame-gradient-bottom"] = true, ["ui-hud-actionbar-iconframe"] = true,
	["ui-hud-actionbar-iconframe-mouseover"] = true,
}
local FILES = {
	["Interface\\Buttons\\UI-Quickslot2"] = "kill",
	["Interface\\DialogFrame\\UI-DialogBox-Header"] = "kill",
	["Interface\\FrameGeneral\\UI-Background-Rock"] = "kill",
	["Interface\\QuestFrame\\UI-QuestTitleHighlight"] = "wash",
	["Interface\\Buttons\\UI-Common-MouseHilight"] = "wash",
	["Interface\\Buttons\\ButtonHilight-Square"] = "wash",
	["Interface\\Buttons\\CheckButtonHilight"] = "accent",
	["Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"] = "next",
	["Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up"] = "prev",
	["Interface\\Buttons\\UI-Panel-MinimizeButton-Up"] = "close",
	["Interface\\Buttons\\UI-MinusButton-Up"] = "gray",
	["Interface\\Buttons\\UI-PlusButton-Up"] = "gray",
	["Interface\\COMMON\\Indicator-Yellow"] = "accent",
	["Interface\\AddOns\\OpenMap\\Media\\Textures\\MapPaper"] = "paper",
}
local FILE_IDS

local function FileKind(tex)
	if not FILE_IDS then FILE_IDS = ns.FileIDs(FILES) end
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return nil end
	if type(file) == "string" then file = string.lower(file) end
	return FILE_IDS[file]
end

local function AtlasOf(tex)
	if not tex.GetAtlas then return nil end
	local ok, atlas = pcall(tex.GetAtlas, tex)
	return ok and type(atlas) == "string" and atlas or nil
end

local function Grey(tex, ink)
	if tex.SetDesaturated then tex:SetDesaturated(true) end
	tex:SetVertexColor(Ink(ink or "TEXT"))
end

local function Pixel(tex, h)
	if PixelUtil and PixelUtil.SetHeight then PixelUtil.SetHeight(tex, h) else tex:SetHeight(h) end
end

local function Plain(tex)
	return AtlasOf(tex) == nil and (select(2, pcall(tex.GetTexture, tex))) == nil
end

local done = setmetatable({}, { __mode = "k" })   -- region or frame -> dressed

local function Region(r, view)
	if done[r] or not ns.Usable(r) then return end
	local kind = r:GetObjectType()
	if kind == "FontString" then
		done[r] = true
		InkText(r)
		return
	end
	if kind ~= "Texture" then return end
	local atlas = AtlasOf(r)
	if atlas then atlas = string.lower(atlas) end
	-- The quest log's paper is the dungeon panel's (and What's new's) only ground: a solid dark one
	-- in its place, or the world map's own quest log underneath shows through.
	if atlas == "questlog-main-background" then
		done[r] = true
		r:SetColorTexture(0.05, 0.05, 0.06, 0.97)
		r:SetAlpha(1)
		return
	end
	if atlas and KILL_ATLAS[atlas] then
		done[r] = true
		ns.Kill(r)
		return
	end
	local what = FileKind(r)
	if what == "kill" then
		done[r] = true
		ns.Kill(r)
	elseif what == "wash" then
		done[r] = true
		r:SetTexCoord(0, 1, 0, 1)
		r:SetColorTexture(1, 1, 1, 0.07)
		if r.SetBlendMode then r:SetBlendMode("BLEND") end
	elseif what == "accent" then
		done[r] = true
		if r.SetDesaturated then r:SetDesaturated(true) end
		r:SetVertexColor(ns.AccentOf(KEY))
	elseif what == "gray" or what == "next" or what == "prev" then
		done[r] = true
		Grey(r, "TEXT")
	elseif what == "paper" then
		-- The dungeon view's blank page is the map's own surface; anywhere else (What's new) its paper goes.
		done[r] = true
		if not (view and r:GetParent() == view.page) then ns.Kill(r) end
	elseif Plain(r) then
		local layer = r:GetDrawLayer()
		local w, h = r:GetWidth() or 0, r:GetHeight() or 0
		if layer == "ARTWORK" and (h > 0 and h <= 1.5 or w > 0 and w <= 1.5) then
			-- Its bronze rules: a hairline.
			done[r] = true
			r:SetColorTexture(1, 1, 1, 0.08)
		elseif layer == "HIGHLIGHT" then
			-- Its warm hover tints: a quiet wash.
			done[r] = true
			r:SetColorTexture(1, 1, 1, 0.07)
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- Its pieces
-- ---------------------------------------------------------------------------------------------

-- Sliders: DaylightUI's look from plain textures (its art isn't ours to use): a thin track, the
-- accent up to a round knob that grows under the mouse. The game's thumb stays, out of sight.
local KNOB_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local sliders = setmetatable({}, { __mode = "k" })
local function SliderLook(slider)
	if sliders[slider] or not ns.Usable(slider) or slider:GetObjectType() ~= "Slider" then return end
	local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
	if not ns.Usable(thumb) then return end
	sliders[slider] = true
	if slider.GetBackdrop and slider:GetBackdrop() then ns.NoBackdrop(slider) end
	for _, r in ipairs({ slider:GetRegions() }) do
		if r ~= thumb and r:GetObjectType() == "Texture" then r:SetAlpha(0) end
	end
	thumb:SetAlpha(0)
	local track = slider:CreateTexture(nil, "ARTWORK")
	track:SetColorTexture(1, 1, 1, 0.14)
	track:SetPoint("LEFT", slider, "LEFT", 0, 0)
	track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
	Pixel(track, 4)
	local fill = slider:CreateTexture(nil, "ARTWORK", nil, 1)
	fill:SetPoint("LEFT", track, "LEFT", 0, 0)
	fill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)
	Pixel(fill, 4)
	local knob = slider:CreateTexture(nil, "OVERLAY")
	knob:SetColorTexture(1, 1, 1, 1)
	knob:SetSize(12, 12)
	knob:SetPoint("CENTER", thumb, "CENTER", 0, 0)
	local mask = slider:CreateMaskTexture()
	mask:SetTexture(KNOB_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(knob)
	knob:AddMaskTexture(mask)
	local function paint()
		fill:SetColorTexture(ns.AccentOf(KEY))
		knob:SetVertexColor(1, 1, 1, (not slider.IsEnabled or slider:IsEnabled()) and 1 or 0.4)
	end
	paint()
	slider:HookScript("OnEnter", function() knob:SetSize(14, 14) end)
	slider:HookScript("OnLeave", function() knob:SetSize(12, 12) end)
	slider:HookScript("OnShow", paint)
	slider:HookScript("OnEnable", paint)
	slider:HookScript("OnDisable", paint)
end

-- Its own scroll bar (the menu's): a thin pill for a thumb on a quiet track.
local function ThinBar(bar)
	local thumb = bar:GetThumbTexture()
	if not ns.Usable(thumb) then return end
	thumb:SetTexture(nil)
	thumb:SetColorTexture(1, 1, 1, 0.3)
	thumb:SetWidth(4)
end

-- A tab of the game's MinimalTabTemplate: DaylightUI's tab. It says which is picked through
-- SetSelected, which the Kit doesn't hear: the tab is told here.
local picked = setmetatable({}, { __mode = "k" })
local function TextTab(Kit, b, initial)
	picked[b] = initial and true or false
	ns.Guard(Kit.Tab, b, function(self) return picked[self] == true end)
	if type(b.SetSelected) == "function" then
		hooksecurefunc(b, "SetSelected", function(self, on)
			picked[self] = on and true or false
			local look = Kit.TabOf and Kit.TabOf(self)
			if type(look) == "table" and look.Pick then pcall(look.Pick, picked[self]) end
		end)
	end
end

local edgeTabs = setmetatable({}, { __mode = "k" })
-- Its tabs on the map's edge (the tool rail, the dungeon's two): clean tiles (ns.SideTile, as
-- TrueshotLodge's and Questie's tabs), the icon cropped in an even margin, the lit one (its own
-- `selected` texture shown) edged in the accent, the others neutral and a little dimmed.
local function HideArt(icon, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if r:GetObjectType() == "Texture" and r ~= icon then r:SetAlpha(0) end
	end
end

local function Lit(b)
	return ns.Usable(b.selected) and b.selected:IsShown() == true
end

-- Its frame off and our tile made, once; nil = not a tab that can be dressed.
local function EdgeTabSetup(b)
	if not ns.Usable(b) or not ns.Usable(b.icon) then return nil end
	local e = edgeTabs[b]
	if not e then
		e = {}
		edgeTabs[b] = e
		if b.mask and b.icon.RemoveMaskTexture then pcall(b.icon.RemoveMaskTexture, b.icon, b.mask) end
		HideArt(b.icon, b:GetRegions())
		for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetCheckedTexture" }) do
			local t = b[get] and b[get](b)
			if ns.Usable(t) and t ~= b.icon then t:SetAlpha(0) end
		end
		-- (Drawn again on a tile centered on the button: OpenMap places its icon off-center, toward
		-- the map's edge, and sizes it on every refresh. A tool's symbol keeps its own size.)
		local w, h = b:GetSize()
		local side = math.floor(math.min(w or 44, h or 44) - 4 + 0.5)
		local picture = b.fill and b.icon.square ~= false
		ns.Guard(ns.SideTile, b, { icon = b.icon, picked = Lit, key = KEY, copy = true, point = "CENTER",
			size = side, iconSize = not picture and (b.iconSize or 24) or nil })
	end
	return e
end

-- The tab dressed, and lit or not as its own `selected` texture says now.
local function EdgeTab(b)
	local e = EdgeTabSetup(b)
	if not e then return end
	if b.selected then b.selected:SetAlpha(0) end
	ns.SideTilePaint(b)
end

-- A tile or button framed as an action button: a thin edge where the frame was (a boxed tile
-- already has its edge).
local function Tile(b)
	if done[b] then return end
	done[b] = true
	if b.boxed then return end
	local o = CreateFrame("Frame", nil, b)
	o:SetAllPoints(b.icon.slot or b)
	o:SetFrameLevel(b:GetFrameLevel() + 2)
	o:EnableMouse(false)
	ns.Shell(o, { noBackground = true, noBevel = true, borderPx = 2 }, KEY)
end

-- (art set by path reports its file's number on this client: matched through FILE_IDS)
local function IsClose(b)
	local n = b.GetNormalTexture and b:GetNormalTexture()
	if not ns.Usable(n) then return false end
	local atlas = AtlasOf(n)
	if atlas and string.find(string.lower(atlas), "exit", 1, true) then return true end
	return FileKind(n) == "close"
end

local function PageDir(b)
	local n = b.GetNormalTexture and b:GetNormalTexture()
	if not ns.Usable(n) then return nil end
	local kind = FileKind(n)
	if kind == "next" then return "right" end
	if kind == "prev" then return "left" end
end

local SKIP = { GameTooltip = true, Model = true, PlayerModel = true, ModelScene = true, Cooldown = true,
	SimpleHTML = true, MessageFrame = true, ColorSelect = true, Minimap = true }

-- The draw tray's tool buttons: the picked one's gold wash in the accent, and its glyph (lines
-- the tray colors again on every refresh: gold for the picked tool, cream for the rest) in the
-- accent and DaylightUI's text ink as the color is set.
local GLOW_ALPHA = 0.18
local toolButtons = setmetatable({}, { __mode = "k" })
local lineBusy = false

local function Near(a, b) return type(a) == "number" and math.abs(a - b) < 0.01 end

local function ToolLine(line, r, g, b)
	if lineBusy or not ns.Enabled(KEY) or ns.Look(KEY, "daylightColors") == false then return end
	local nr, ng, nb
	if Near(r, 1) and Near(g, 0.82) and Near(b, 0.3) then
		nr, ng, nb = ns.AccentOf(KEY)
	elseif Near(r, 0.93) and Near(g, 0.86) and Near(b, 0.7) then
		nr, ng, nb = Ink("TEXT")
	end
	if nr then
		lineBusy = true
		line:SetVertexColor(nr, ng, nb)
		lineBusy = false
	end
end

-- A fill of its own gold (a picked row's bar, a glow) in the accent instead, at the given alpha;
-- painted again when the accent changes.
local PICKED_ALPHA = 0.22
local accentFills = setmetatable({}, { __mode = "k" })   -- texture -> its alpha
local function PaintFill(tex, a)
	local r, g, b = ns.AccentOf(KEY)
	tex:SetColorTexture(r, g, b, a)
end
local function AccentFill(tex, a)
	accentFills[tex] = a
	PaintFill(tex, a)
end

local function ToolGlow(b)
	AccentFill(b.glow, GLOW_ALPHA)
end

local function ToolButton(b)
	if toolButtons[b] then return end
	toolButtons[b] = true
	ToolGlow(b)
	for _, line in ipairs(b.lines) do
		if ns.Usable(line) and line.SetVertexColor then
			hooksecurefunc(line, "SetVertexColor", ToolLine)
			local ok, r, g, bl = pcall(line.GetVertexColor, line)
			if ok then ToolLine(line, r, g, bl) end
		end
	end
end

ns.me.On("StyleChanged", function()
	if not ns.Enabled(KEY) then return end
	for tex, a in pairs(accentFills) do
		if ns.Usable(tex) then PaintFill(tex, a) end
	end
end)

local DressSoon   -- (below: dressed on the next frame)

local function Piece(Kit, f, view)
	if done[f] then return end
	-- (a tab on the map's edge is the rail's or the dungeon's: EdgeTab, from their hooks)
	if f.bg and f.selected and f.hover and f.icon then return end
	if f.GetBackdrop and f:GetBackdrop() then InkBackdrop(f) end
	if ns.Usable(f.icon) and f.icon.slot then
		Tile(f)
		return
	end
	local kind = f:GetObjectType()
	local controls = ns.Controls(KEY)
	if kind == "Button" and f.key and ns.Usable(f.glow) and type(f.lines) == "table" then
		done[f] = true
		ns.Guard(ToolButton, f)
		return
	end
	if kind == "Button" then
		if f.Text and type(f.SetSelected) == "function" and f.key then
			-- MinimalTabTemplate
			done[f] = true
			local m = Mod()
			local db = m and m.db or {}
			if controls then TextTab(Kit, f, f.key and (f.key == db.dungeonTab or f.key == db.menuTab)) end
		elseif f.Left and f.Middle and f.Right then
			done[f] = true
			if controls then ns.Guard(Kit.Button, f) end
			-- Its gold glow round a button that leads on (the draw tray's Done): the accent.
			if ns.Usable(f.glow) and f.glow:GetObjectType() == "Texture" then AccentFill(f.glow, 0.55) end
		elseif ns.Usable(f.lit) and f.lit:GetObjectType() == "Texture" and ns.Usable(f.label) then
			-- A list row whose picked state is a gold bar (What's new's versions): the accent wash.
			done[f] = true
			AccentFill(f.lit, PICKED_ALPHA)
		elseif IsClose(f) then
			done[f] = true
			if controls then ns.Guard(Kit.Close, f) end
		else
			local dir = PageDir(f)
			if dir then
				done[f] = true
				if controls then ns.Guard(Kit.PageButton, f, dir) end
			end
		end
	elseif kind == "CheckButton" then
		done[f] = true
		if controls then ns.Guard(Kit.Check, f) end
	elseif kind == "EditBox" then
		done[f] = true
		if controls and (f.Left or f.Middle or f.searchIcon) then ns.Guard(Kit.EditBox, f) end
		InkText(f)
	elseif kind == "ScrollFrame" then
		done[f] = true
		if controls and ns.Usable(f.ScrollBar) then ns.Guard(Kit.ScrollBar, f.ScrollBar) end
		-- What it scrolls is often filled again while shown (What's new's notes, page by page):
		-- what's added is dressed on the next frame.
		local child = f.GetScrollChild and f:GetScrollChild()
		if ns.Usable(child) and child.HookScript then child:HookScript("OnSizeChanged", DressSoon) end
	elseif kind == "Slider" then
		done[f] = true
		if f:GetOrientation() == "VERTICAL" then ThinBar(f) else SliderLook(f) end
	elseif ns.Usable(f.Slider) and ns.Usable(f.Back) and ns.Usable(f.Forward) then
		-- MinimalSliderWithSteppersTemplate: its arrows gray, its slider ours.
		done[f] = true
		for _, b in ipairs({ f.Back, f.Forward }) do
			done[b] = true
			for _, r in ipairs({ b:GetRegions() }) do
				if r:GetObjectType() == "Texture" then Grey(r, "TEXT") end
			end
		end
		SliderLook(f.Slider)
	end
end

local DEPTH = 12

-- A shell DaylightUI drew (a frame of its own holding its border pieces): not OpenMap's, left be.
local function IsShell(f)
	return type(f.opts) == "table" and type(f.border) == "table"
end

-- Its art first, then its template's dressing; what the Kit then adds is DaylightUI's, never
-- taken for OpenMap's art on a later pass. (It runs on every show and refill: the regions and
-- children are gone through as the game hands them back, with no table made of them, and what's
-- done already is passed over without a call.)
local Walk

local function MarkDone(...)
	for i = 1, select("#", ...) do done[(select(i, ...))] = true end
end

local function WalkChildren(Kit, depth, view, ...)
	for i = 1, select("#", ...) do Walk(Kit, (select(i, ...)), depth, view) end
end

local function WalkFrame(Kit, f, depth, view, count, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if not done[r] then ns.Guard(Region, r, view) end
	end
	if not done[f] then ns.Guard(Piece, Kit, f, view) end
	-- The regions as they were, unless the dressing added some (the Kit's and ours never take one
	-- away): then all of them again.
	if f:GetNumRegions() == count then MarkDone(...) else MarkDone(f:GetRegions()) end
	WalkChildren(Kit, depth + 1, view, f:GetChildren())
end

Walk = function(Kit, f, depth, view)
	if depth > DEPTH or not ns.Usable(f) or SKIP[f:GetObjectType()] or IsShell(f) then return end
	WalkFrame(Kit, f, depth, view, f:GetNumRegions(), f:GetRegions())
end

local function Dress(f)
	if not ns.Enabled(KEY) or not ns.Usable(f) then return end
	ns.WithKit(function(Kit) Walk(Kit, f, 0, _G.OpenMapDungeonView) end)
end
ns.OpenMapDress = Dress

-- Dressed on the next frame, once however many times it's asked for in this one; not if it's
-- hidden by then (its next show dresses it).
local soon = {}
local soonQueued = false
local function DressQueued()
	soonQueued = false
	for f in pairs(soon) do
		soon[f] = nil
		if ns.Usable(f) and f:IsShown() then Dress(f) end
	end
end
DressSoon = function(f)
	if not ns.Enabled(KEY) or soon[f] then return end
	soon[f] = true
	if not soonQueued then
		soonQueued = true
		C_Timer.After(0, DressQueued)
	end
end

-- Dressed now and on every show (in the same frame: OnShow runs before it's drawn).
local hooked = setmetatable({}, { __mode = "k" })
local showScript = setmetatable({}, { __mode = "k" })   -- frame -> its OnShow as it was once hooked
local function Follow(f)
	if not ns.Usable(f) then return end
	if not hooked[f] then
		hooked[f] = true
		f:HookScript("OnShow", Dress)
		showScript[f] = f:GetScript("OnShow") or false
	end
	Dress(f)
end

-- A window that sets its own OnShow after it's made (What's new does, at the end of its build)
-- drops the hook above: hooked again when its script is no longer the one it was.
local function Rehook(f)
	local was = showScript[f]
	if was == nil or not ns.Usable(f) then return end
	local now = f:GetScript("OnShow") or false
	if now ~= was then
		f:HookScript("OnShow", Dress)
		showScript[f] = f:GetScript("OnShow") or false
	end
end

-- ---------------------------------------------------------------------------------------------
-- The helpers it draws through
-- ---------------------------------------------------------------------------------------------

local helper = false   -- inside Window or Dropdown, which may call Panel themselves

local function Snapshot(frame)
	local seen = {}
	for _, child in ipairs({ frame:GetChildren() }) do seen[child] = true end
	for _, region in ipairs({ frame:GetRegions() }) do seen[region] = true end
	return seen
end

-- What a helper added to the frame, apart from the pieces to keep.
local function Added(frame, before, keep)
	local children, regions = {}, {}
	for _, child in ipairs({ frame:GetChildren() }) do
		if not before[child] and not keep[child] then children[#children + 1] = child end
	end
	for _, region in ipairs({ frame:GetRegions() }) do
		if not before[region] and not keep[region] then regions[#regions + 1] = region end
	end
	return children, regions
end

local function Call(fn, ...)
	local was = helper
	helper = true
	local a, b, c, d, e = pcall(fn, ...)
	helper = was
	if not a then error(b, 0) end
	return b, c, d, e
end

local origWindow, origPanel, origDropdown, origFont = Look.Window, Look.Panel, Look.Dropdown, Look.Font
local WINDOW_ALPHA = 0.97

-- A window OpenMap lays on the map itself (the quill's Draw on the map tray): made as wide as its
-- tools, centered on the map, it ran past both sides of DaylightUI's narrower map. Shrunk to the
-- map's width (never grown) each time it shows and whenever the map is resized.
local function FitOnMap(frame)
	local map = _G.WorldMapFrame
	local sc = map and map.ScrollContainer
	if not ns.Usable(sc) or not frame:IsShown() then return end
	local own = frame:GetScale() or 1
	local w = frame:GetWidth() or 0
	if w <= 0 then return end
	local room = (sc:GetWidth() or 0) * sc:GetEffectiveScale() - 16 * sc:GetEffectiveScale()
	local needed = w * frame:GetEffectiveScale() / own
	if room <= 0 or needed <= 0 then return end
	local s = math.min(1, room / needed)
	if math.abs(s - own) > 0.005 then frame:SetScale(s) end
end

local function FitLater(frame)
	C_Timer.After(0, function() ns.Guard(FitOnMap, frame) end)
end

local function OnMap(frame)
	local map = _G.WorldMapFrame
	if not map or frame:GetParent() ~= map or frame.dasFit then return end
	frame.dasFit = true
	frame:HookScript("OnShow", function(self) FitLater(self) end)
	frame:HookScript("OnSizeChanged", function(self) FitLater(self) end)
	if ns.Usable(map.ScrollContainer) then
		map.ScrollContainer:HookScript("OnSizeChanged", function() if frame:IsShown() then FitLater(frame) end end)
	end
	FitLater(frame)
end

Look.Window = function(self, frame, title, onClose)
	if type(frame) ~= "table" or not frame.GetChildren then return origWindow(self, frame, title, onClose) end
	if ns.Enabled(KEY) then pcall(OnMap, frame) end
	local before = Snapshot(frame)
	local top, text, close = Call(origWindow, self, frame, title, onClose)
	local keep = {}
	if text then keep[text] = true end
	if close then keep[close] = true end
	local children, regions = Added(frame, before, keep)
	ns.WithKit(function(Kit)
		if not ns.Enabled(KEY) or not ns.Once(frame) then return end
		for i = 1, #children do ns.Kill(children[i]) end
		for i = 1, #regions do ns.Kill(regions[i]) end
		-- A solid ground: these windows sit over the map, which showed through the window's
		-- usual see-through ground (the player's own opacity, when set on its page, still wins).
		ns.Shell(frame, { window = true, bgAlpha = WINDOW_ALPHA }, KEY)
		if close and ns.Controls(KEY) and ns.Once(close) then
			done[close] = true
			ns.Guard(Kit.Close, close)
		end
		if text then InkText(text) end
		Follow(frame)
		-- What the window holds is made after this call: dressed on the next frame, and its show
		-- hook put back if it set its own OnShow meanwhile.
		C_Timer.After(0, function()
			if not ns.Enabled(KEY) or not ns.Usable(frame) then return end
			Rehook(frame)
			if frame:IsShown() then Dress(frame) end
		end)
	end)
	return top, text, close
end

Look.Panel = function(self, frame, opts)
	local bd = origPanel(self, frame, opts)
	if helper or type(frame) ~= "table" then return bd end
	ns.WithKit(function()
		if not ns.Enabled(KEY) then return end
		local back = frame.omBackdrop
		if not ns.Usable(back) then return end
		done[back] = true
		ns.NoBackdrop(back)
		ns.Shell(back, nil, KEY)
		if ns.Once(frame) and frame.HookScript then Follow(frame) end
	end)
	return bd
end

Look.Dropdown = function(self, frame)
	if type(frame) ~= "table" or not frame.GetChildren then return origDropdown(self, frame) end
	local before = Snapshot(frame)
	local l, r, t, b = Call(origDropdown, self, frame)
	local children, regions = Added(frame, before, {})
	ns.WithKit(function()
		if not ns.Enabled(KEY) or not ns.Once(frame) then return end
		for i = 1, #children do ns.Kill(children[i]) end
		for i = 1, #regions do ns.Kill(regions[i]) end
		ns.Shell(frame, nil, KEY)
		Follow(frame)
		-- A list that grows while it's open (the search's results, made as they're typed for):
		-- what it added is dressed on the next frame.
		frame:HookScript("OnSizeChanged", DressSoon)
	end)
	return l, r, t, b
end

if type(origFont) == "function" then
	local function Restyle(fs, size, flags)
		ns.SetFont(KEY, fs, (fs:GetFont()), size or 12, flags or "")
	end
	Look.Font = function(self, fs, size, flags)
		local out = origFont(self, fs, size, flags)
		if type(fs) == "table" and fs.SetFont and fs.GetFont and ns.Enabled(KEY) and not ns.PlainText(KEY) then
			pcall(Restyle, fs, size, flags)
		end
		return out
	end
end

-- ---------------------------------------------------------------------------------------------
-- The settings menu
-- ---------------------------------------------------------------------------------------------

local function Menu(menu, Kit)
	if not ns.Once(menu) then return end
	-- Its own ground (the same recipe as the helpers', kept private): a nine-slice child and two
	-- BACKGROUND textures, or a dialog backdrop on clients without the nine-slice.
	for _, child in ipairs({ menu:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Frame" and child.TopLeftCorner and child.TopEdge then
			ns.Kill(child)
		end
	end
	for _, region in ipairs({ menu:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			ns.Kill(region)
		end
	end
	ns.NoBackdrop(menu)
	ns.Shell(menu, { window = true }, KEY)
	-- Its tabs refill the body: what they made is dressed in the same frame.
	if type(menu.tabs) == "table" then
		for _, tab in pairs(menu.tabs) do
			if ns.Usable(tab) and tab.HookScript then tab:HookScript("OnClick", function() Dress(menu) end) end
		end
	end
	Follow(menu)
end

-- ---------------------------------------------------------------------------------------------
-- The dungeon view
-- ---------------------------------------------------------------------------------------------

-- Its grounds (the view, its bar, the side panel, the hint) are color fills of its own browns,
-- set once: a neutral dark.
local function Grounds(view)
	local bar = ns.Usable(view.back) and view.back:GetParent()
	local box = view.side and view.side.scroll and view.side.scroll:GetParent()
	for _, f in ipairs({ view, bar, view.side, box, view.hint }) do
		if ns.Usable(f) then
			for _, r in ipairs({ f:GetRegions() }) do
				if r:GetObjectType() == "Texture" and r:GetDrawLayer() == "BACKGROUND" and Plain(r) then
					done[r] = true
					r:SetColorTexture(0.05, 0.05, 0.06, f == view.hint and 0.85 or 0.96)
				end
			end
		end
	end
end

-- Dungeon Journal's markers on the world map (a dungeon's entrance, a quest's start) sit at frame
-- level 10000, over everything on the map, OpenMap's dungeon view included. While that view is
-- open they're out of sight and let clicks through; when it closes they're as they were.
local tucked = setmetatable({}, { __mode = "k" })   -- marker -> its mouse state before

local function TuckAmong(...)
	for i = 1, select("#", ...) do
		local m = select(i, ...)
		if ns.Usable(m) and m._fdjKey ~= nil then
			if tucked[m] == nil then tucked[m] = m:IsMouseEnabled() end
			m:SetAlpha(0)
			m:EnableMouse(false)
		end
	end
end

local function DJMarkers(hide)
	local map = _G.WorldMapFrame
	local sc = map and map.ScrollContainer
	local canvas = sc and (sc.Child or sc)
	if not ns.Usable(canvas) then return end
	if hide then
		TuckAmong(canvas:GetChildren())
		return
	end
	-- Only those tucked away can come back: they're found in the list of them, not among every
	-- pin on the map (the map's corner buttons in it are MapCorner's).
	for m, mouse in pairs(tucked) do
		if ns.Usable(m) and m._fdjKey ~= nil and m:GetParent() == canvas then
			m:SetAlpha(1)
			m:EnableMouse(mouse)
			tucked[m] = nil
		end
	end
end

local openView   -- OpenMap's dungeon view, while it shows

-- The game's own controls in the map's corner (its overlayFrames: the map pin button, the floor
-- dropdown and the like) are raised over the dungeon view by OpenMap so its quest log toggle stays
-- usable. Those that fall over the view and mean nothing on the dungeon's picture are tucked away
-- with the markers: out of sight, clicks through. The quest log toggle stays.
local function Inside(f, view)
	local x, y = f:GetCenter()
	local l, b, w, h = view:GetRect()
	if not (x and y and l and w) then return false end
	local s = f:GetEffectiveScale() / view:GetEffectiveScale()
	x, y = x * s, y * s
	return x >= l and x <= l + w and y >= b and y <= b + h
end

local function MapCorner(hide)
	local map = _G.WorldMapFrame
	if not ns.Usable(map) or type(map.overlayFrames) ~= "table" then return end
	for _, o in ipairs(map.overlayFrames) do
		if ns.Usable(o) and o ~= map.SidePanelToggle then
			if hide then
				if openView and o:IsShown() and Inside(o, openView) then
					if tucked[o] == nil then tucked[o] = o:IsMouseEnabled() end
					o:SetAlpha(0)
					o:EnableMouse(false)
				end
			elseif tucked[o] ~= nil then
				o:SetAlpha(1)
				o:EnableMouse(tucked[o])
				tucked[o] = nil
			end
		end
	end
end
local function TuckMarkers()
	if openView and openView:IsShown() then
		DJMarkers(true)
		MapCorner(true)
	end
end

-- New markers Dungeon Journal puts up while the view is open are tucked away too.
local FDJ = _G.ForeverDungeonJournal_NS
if type(FDJ) == "table" and type(FDJ.MapMarkers) == "table" then
	for _, name in ipairs({ "ShowRecordedLocationOnMap", "ShowRouteOnMap", "ShowQuestStartOnMap" }) do
		if type(FDJ.MapMarkers[name]) == "function" then hooksecurefunc(FDJ.MapMarkers, name, TuckMarkers) end
	end
end

local function EdgeTabs(list)
	for _, b in ipairs(list) do EdgeTab(b) end
end

-- quiet: from a refresh that comes whether the view is up or not (every map open and change): a
-- view that's put away isn't walked then, since its own showing walks it before it's drawn.
local views = setmetatable({}, { __mode = "k" })
local function View(view, quiet)
	if not ns.Usable(view) then return end
	local first = not views[view]
	if first then
		views[view] = true
		Grounds(view)
		local side = view.side
		if ns.Usable(side) then
			-- The side panel: a well of its own beside the picture.
			ns.Shell(side, { noBevel = true, noBackground = true }, KEY)
			-- A solid ground under all of it, the title row too (its paper only lies under the
			-- list), so the world map's quest log never shows through.
			if not side.dasGround then
				side.dasGround = side:CreateTexture(nil, "BACKGROUND", nil, -8)
				side.dasGround:SetAllPoints(side)
				side.dasGround:SetColorTexture(0.05, 0.05, 0.06, 0.97)
			end
			-- Its tabs refill it, and its list grows as it's filled: dressed in the same frame.
			for _, b in ipairs(side.tabs or {}) do
				if ns.Usable(b) then b:HookScript("OnClick", function() Dress(side) end) end
			end
			if ns.Usable(side.child) then
				side.child:HookScript("OnSizeChanged", function() Dress(side.child) end)
			end
			-- The picked floor's picture: its edge lit again on each floor (the backdrop hook turns it).
			if type(side.LightThumbs) == "function" then
				hooksecurefunc(side, "LightThumbs", function() Dress(side.child) end)
			end
		end
		-- The floor list opened from the floor's name.
		if ns.Usable(view.floorButton) then
			view.floorButton:HookScript("OnClick", function() if view.list then Dress(view.list) end end)
		end
		hooked[view] = true
		view:HookScript("OnShow", Dress)
		view:HookScript("OnShow", function(self)
			openView = self
			if not ns.Enabled(KEY) then return end
			DJMarkers(true)
			MapCorner(true)
			C_Timer.After(0, TuckMarkers)
		end)
		view:HookScript("OnHide", function()
			DJMarkers(false)
			MapCorner(false)
		end)
		if view:IsShown() then
			openView = view
			if ns.Enabled(KEY) then
				DJMarkers(true)
				MapCorner(true)
			end
		end
	end
	if first or not quiet or view:IsShown() then Dress(view) end
	-- The dungeon's two tabs at the map's edge.
	local tabs = view.sideTabs
	if ns.Usable(tabs) and type(tabs.list) == "table" then ns.Guard(EdgeTabs, tabs.list) end
end

-- ---------------------------------------------------------------------------------------------
-- The coordinates at the map's foot
-- ---------------------------------------------------------------------------------------------

-- Its numbers are set about twenty times a second while the map is open (and the place's name
-- under the mouse with them): plain numbers, a gray "--" and place names, none of them one of its
-- color codes, so only their color is followed.
local function CoordsText(fs)
	if type(fs) == "table" then colorOnly[fs] = true end
end

local coordsBar
local function CoordsAmong(...)
	for i = 1, select("#", ...) do
		local child = select(i, ...)
		if ns.Usable(child) and child.player and child.cursor then return child end
	end
end

local function Coords()
	if coordsBar then return end
	local sc = _G.WorldMapFrame and _G.WorldMapFrame.ScrollContainer
	if not ns.Usable(sc) then return end
	local bar = CoordsAmong(sc:GetChildren())
	if not bar then return end
	coordsBar = bar
	if type(bar.player) == "table" then CoordsText(bar.player.at) end
	CoordsText(bar.cursor)
	CoordsText(bar.cursor.at)
	Follow(bar)
end

-- ---------------------------------------------------------------------------------------------
-- When it builds and refreshes
-- ---------------------------------------------------------------------------------------------

local railFrame
local function RailTabs(...)
	for i = 1, select("#", ...) do
		local b = select(i, ...)
		if ns.Usable(b) and b.bg and b.selected and b.icon then EdgeTab(b) end
	end
end

local function ArrowRegions(...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if not done[r] then ns.Guard(Region, r) end
	end
end

local function Rail()
	if not ns.Usable(railFrame) then return end
	RailTabs(railFrame:GetChildren())
	-- Its arrow: the page arrow, turned; gray.
	if ns.Usable(railFrame.arrow) and ns.Usable(railFrame.arrow.icon) then Grey(railFrame.arrow.icon, "TEXT") end
	if ns.Usable(railFrame.arrow) then ArrowRegions(railFrame.arrow:GetRegions()) end
end

-- The row in the map's bottom-left corner, while "Buttons as edge tabs" is off: the OpenMap button
-- and the favorites (action buttons in the action bar's frame, the checked glow while on), the
-- arrow that folds them away (the spellbook's page arrow), and the favorites' row. They're the
-- map's own children, so no walk of OpenMap's windows reaches them: found by what they are.
local function IsTray(b)
	local icon = b.icon
	if not (ns.Usable(icon) and icon.GetObjectType and icon:GetObjectType() == "Texture") then return false end
	local kind = FileKind(icon)
	return kind == "next" or kind == "prev"
end

local function CornerAmong(...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		if ns.Usable(c) and not (c.IsProtected and c:IsProtected()) then
			local kind = c:GetObjectType()
			if kind == "Button" then
				if not done[c] and (ns.Usable(c.icon) and c.icon.slot or IsTray(c)) then Dress(c) end
			elseif kind == "Frame" and type(c.buttons) == "table" then
				local first = c.buttons[1]
				if type(first) == "table" and ns.Usable(first.icon) and first.icon.slot then Dress(c) end
			end
		end
	end
end

local function Corner()
	local m = Mod()
	local db = m and m.db
	if type(db) ~= "table" or db.tabRail or db.mapButtons == false then return end
	local map = _G.WorldMapFrame
	if ns.Usable(map) and map:IsShown() then CornerAmong(map:GetChildren()) end
end

-- Asked for by every refresh of the corner (each map show, zoom and size change, a setting
-- changed while the map is open): looked over once, on the next frame, when it's been laid out.
local cornerQueued = false
local function CornerNow()
	cornerQueued = false
	if ns.Enabled(KEY) then ns.Guard(Corner) end
end
local function QueueCorner()
	if cornerQueued or not ns.Enabled(KEY) then return end
	cornerQueued = true
	C_Timer.After(0, CornerNow)
end

-- Its copy of the quest log toggle, in the corner of the full-screen map: dressed as DaylightUI
-- dresses the game's own (SidePanelToggle), its two arrows as page buttons.
local function LogToggle(Kit)
	local m = Mod()
	local t = m and m.maxLogToggle
	if not ns.Usable(t) or not ns.Controls(KEY) then return end
	if ns.Usable(t.CloseButton) then ns.Guard(Kit.PageButton, t.CloseButton, "left") end
	if ns.Usable(t.OpenButton) then ns.Guard(Kit.PageButton, t.OpenButton, "right") end
end

ns.Pack(KEY, nil, function(Kit)
	ns.Watch(KEY, "OpenMapMenu", Menu)
	local m = Mod()
	if not m then return end
	-- Its edge tabs are given their face here (the rail's, every refresh): dressed as they're faced.
	-- The rail lights its tabs after this and then ends its refresh in PlaceDungeonTabs, where Rail
	-- paints each one lit or not: here a tab is only set up (its frame off, our outline made), unless
	-- this OpenMap has no PlaceDungeonTabs to follow.
	local railPainted = type(m.PlaceDungeonTabs) == "function"
	if type(m.FaceSideTab) == "function" then
		hooksecurefunc(m, "FaceSideTab", function(b)
			if not ns.Enabled(KEY) or not ns.Usable(b) then return end
			local parent = b:GetParent()
			if parent and parent.main then railFrame = parent end
			if railPainted then EdgeTabSetup(b) else EdgeTab(b) end
		end)
	end
	-- The rail ends each refresh here, after lighting its tabs; the dungeon's tabs are placed here
	-- too as its view opens and docks.
	if railPainted then
		hooksecurefunc(m, "PlaceDungeonTabs", function()
			if not ns.Enabled(KEY) then return end
			Rail()
			local view = _G.OpenMapDungeonView
			if ns.Usable(view) then View(view, true) end
			Coords()
		end)
	end
	-- A dungeon's map opened from elsewhere (a link, the way back): the view as it opens.
	local function opened()
		local view = _G.OpenMapDungeonView
		if ns.Enabled(KEY) and ns.Usable(view) then View(view, true) end
	end
	for _, name in ipairs({ "OpenAwayMap", "ReturnView" }) do
		if type(m[name]) == "function" then hooksecurefunc(m, name, opened) end
	end
	-- Settings changed: the card and side panel are refilled.
	if type(m.RefreshDungeonCard) == "function" then
		hooksecurefunc(m, "RefreshDungeonCard", function()
			local view = _G.OpenMapDungeonView
			if ns.Enabled(KEY) and ns.Usable(view) and view:IsShown() then Dress(view) end
		end)
	end
	-- The map opening: the coordinates and the rail (made with the map's first opening). The game's
	-- round corner buttons: the shared pass (ns.MapRings), hooked once for this pack and RareScanner's.
	local map = _G.WorldMapFrame
	if map and map.HookScript then
		map:HookScript("OnShow", function()
			if not ns.Enabled(KEY) then return end
			Coords()
			Rail()
			LogToggle(Kit)
			QueueCorner()
			if openView and openView:IsShown() then MapCorner(true) end
		end)
		ns.FollowMapRings(KEY)
		if type(map.RefreshOverlayFrames) == "function" then
			hooksecurefunc(map, "RefreshOverlayFrames", function()
				if not ns.Enabled(KEY) then return end
				QueueCorner()
				if openView and openView:IsShown() then MapCorner(true) end
			end)
		end
	end
	-- Every refresh of its corner buttons ends in PlaceDungeonTabs (with the corner row as with the
	-- rail; the row's buttons are made just after it): the corner row looked over next frame. This
	-- is what follows "Buttons as edge tabs" being switched off while the map is open.
	if type(m.PlaceDungeonTabs) == "function" then
		hooksecurefunc(m, "PlaceDungeonTabs", QueueCorner)
	end
	-- The dungeon view is made the first time a dungeon's map opens.
	ns.Watch(KEY, "OpenMapDungeonView", function(view) View(view) end)
	ns.Watch(KEY, "OpenMapDungeonChooser", function(chooser) Follow(chooser) end)
end)
