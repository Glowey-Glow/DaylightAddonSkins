-- LayerSwap: a button for it in the minimap's corner, and its windows in the DaylightUI look.
--   * The minimap button: "Layer: B" in a square of the same make as DaylightUI's own corner
--     buttons (the calendar, the search, the drawer: a thin edge on a dark ground, the text in the
--     label ink, lit in the accent under the mouse), in the map's bottom-left corner. Shown all
--     the time, only while the mouse is over the map (as DaylightUI's corner buttons are), or not
--     at all: a choice on this addon's page. Only on DaylightUI's square map (with DaylightUI's
--     minimap off, the game's round map has no corner for it). It steps up above the game's queue
--     eye while that shows in the same corner. A click does what a click on LayerSwap's mini bar
--     does: left, its panel; right, its layer menu (here, under the button); shift + right, its
--     settings menu (here, beside the button). The layer is read once a second from LayerSwap's
--     own minimap launcher (its broker object, the only part of it open to other addons), so
--     nothing of LayerSwap's is changed; in a dungeon or raid it says so instead.
--   * Its panel (LayerSwapPanel): DaylightUI's window shell in place of its flat ground and blue
--     outline, DaylightUI's close button and buttons (Mini bar, Swap layer, Host), its headings in
--     the label ink, the layer bright, the rest in DaylightUI's text inks and your font. LayerSwap
--     puts the game's gold font back on its Swap button at every refresh (once a second): your
--     font and DaylightUI's ink go back on after it, the dim ink while it's grayed. A button's
--     words that outgrow it step down a size or three. While hosting is paused LayerSwap grays its
--     Host button ("Host: PAUSED", still clickable): it takes DaylightUI's grayed look then. Its own
--     ground and edges are DaylightUI's shell's, so its Panel background slider and Panel edges
--     box (LayerSwap's options) don't change it. Its "Ask your
--     guild" entry (LayerSwapPanelGuildButton, shown only in a guild): its title on font objects of
--     ours (the label ink, the accent under the mouse; LayerSwap sets them once, as it builds the
--     entry), its "Guild chat reaches every layer" line in your font and the text ink.
--   * Its layer menu and settings menu (LayerSwapMenu, LayerSwapSettingsMenu): DaylightUI's menu
--     shell, rows in your font and the text ink, ages in the dim ink. Grayed rows stay grayed.
--   * Its mini bar (LayerSwapMini): a thin DaylightUI edge round it, your font and the text ink.
--     Its background keeps LayerSwap's own darkness setting. It can fade out like DaylightUI's
--     minimap buttons (a choice on this addon's page): shown only while the mouse is over the
--     minimap or the bar, and while you drag it or one of its menus is open.
--   * Its settings menu gets one row of ours at the bottom, "Layer button: Always / On hover / Off"
--     (Shift + click, like its own switches): the minimap button's setting on this addon's page.
--   * Its options page (Options, AddOns, LayerSwap): DaylightUI's switches, buttons and text inks
--     (through Kit.Auto, its Open the panel and Reset to defaults buttons too), its sliders (two
--     share a row) as a thin track with the accent fill and a round knob. Its switches' names and
--     notes are one line each: one too long for your font steps down a size or three as it shows.
-- How the pieces are found: by name. The panel and the menus are made the first time they open, so
-- they're dressed the moment one of LayerSwap's own buttons, its slash command or this button
-- opens them (and watched for, for the panel it opens by itself after a swap); their rows are made
-- as they're first needed and dressed each time the menu shows.
-- Hooked (post-hooks only): each menu's OnShow and OnHide; the Swap / Host / Mini bar buttons'
-- SetDisabledFontObject, SetText, OnEnable and OnDisable; the options page's OnShow; the clicks
-- of the mini bar, its logo and LayerSwap's minimap button, and its /ls command (to dress what
-- they open at once).
-- Left as it is: its logo and the logo's light, the guild entry's emblem (the guild's own tabard)
-- and its faint 0.08 hover light, the green / gray ON and OFF words and the orange
-- world refresh line (they mean something), its rows' faint hover light (DaylightUI's own
-- strength), its LibDBIcon minimap button (DaylightUI's drawer has it), and what's the game's or
-- DaylightUI's: the tooltips over its rows (the game tooltip), its lines in chat and the chat box
-- it fills in for a request, the party invite popup, the Who list it reads quietly.
local ADDON, ns = ...
if not ns.ok then return end
local L = ns.L

local KEY = "LayerSwap"

ns.Target(KEY, "LayerSwap", { window = true, controls = true, text = true, shadow = true, colors = true,
	font = "daylight", defaults = { dock = "always", miniFade = "always" }, extraTab = L["Minimap"],
	extra = function(at)
		return {
			{ label = L["Minimap Button"], items = {
				{ type = "dropdown", key = at .. "dock", label = L["Layer Button on the Minimap"],
				  values = { always = L["Always"], hover = L["On Hover"], off = L["Off"] },
				  desc = L["A \"Layer: B\" button in the bottom-left corner of Daylight UI's minimap: always shown, only with the mouse over the map (On Hover), or off. Left-click opens LayerSwap's panel, right-click its layer menu, shift + right-click its settings. LayerSwap's own mini bar can be turned off in its options (Mini bar)."] },
				{ type = "dropdown", key = at .. "miniFade", label = L["LayerSwap's Mini Bar"],
				  values = { always = L["Always"], hover = L["On Hover"] },
				  desc = L["LayerSwap's own mini bar (its layer and hosting line): always shown, or only while the mouse is over the minimap or the bar (On Hover), fading in and out like Daylight UI's minimap buttons."] },
			} },
		}
	end })

if type(_G.LayerSwapDB) ~= "table" then return end

local API = ns.API

-- ---------------------------------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------------------------------

local function Ink(fs, role)
	if not ns.Usable(fs) or ns.Look(KEY, "daylightColors") == false then return end
	local c = ns.Colors()[role]
	if type(c) == "table" then fs:SetTextColor(c[1], c[2], c[3]) end
end

local function Font(fs)
	if ns.Usable(fs) and fs.GetFont then ns.Refont(fs, KEY) end
end

local function Pixel(tex, h)
	if PixelUtil and PixelUtil.SetHeight then PixelUtil.SetHeight(tex, h) else tex:SetHeight(h) end
end

-- A frame's own plain textures (its flat ground and the lines drawn round it): out of sight. Its
-- texts and its highlight light are left.
local function KillFlat(...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if r.GetObjectType and r:GetObjectType() == "Texture" and r:GetDrawLayer() ~= "HIGHLIGHT" then
			ns.Kill(r)
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The panel
-- ---------------------------------------------------------------------------------------------

local PANEL_TEXT = {      -- its texts and the ink each takes
	title = "VALUE", h1 = "LABEL", h2 = "LABEL", layer = "VALUE", detail = "TEXT",
	status = "TEXT", hostLine = "LABEL",
}
local PANEL_BUTTONS = { "lineButton", "swapButton", "hostButton" }

-- LayerSwap gives its Swap button the game's font objects again at every refresh (the disabled
-- one last), and DaylightUI's button look repaints its text as it's enabled or grayed: your font
-- and the ink for its state go on after either.
local buttonsDone = setmetatable({}, { __mode = "k" })
local labelSize = setmetatable({}, { __mode = "k" })   -- each label's size before it's fitted
local LABEL_ROOM, LABEL_STEPS = 14, 3                  -- (LayerSwap's own room round a label)

-- A label wider than its button steps down a size or three (LayerSwap only measures its own
-- font, and the Host button's words grow a lock clock, "Host: ON  4:59").
local function FitLabel(b, fs)
	local base = labelSize[fs]
	local path, size, flags = fs:GetFont()
	if not (base and path and type(size) == "number") then return end
	local room = (b:GetWidth() or 0) - LABEL_ROOM
	if room <= 0 then return end
	local s = base
	if size ~= s then fs:SetFont(path, s, flags or "") end
	while (fs:GetStringWidth() or 0) > room and s > base - LABEL_STEPS do
		s = s - 1
		fs:SetFont(path, s, flags or "")
	end
end

local function ButtonText(b)
	if not ns.Enabled(KEY) then return end
	local fs = b:GetFontString()
	if not ns.Usable(fs) then return end
	Font(fs)
	Ink(fs, b:IsEnabled() and "TEXT" or "OFF")
	labelSize[fs] = select(2, fs:GetFont())
	FitLabel(b, fs)
end

-- LayerSwap grays its Host button while hosting is paused (in a group, in combat, a break), and
-- it stays clickable: it reads "Host: PAUSED" then. DaylightUI's button takes its grayed look for
-- that time, put on as the words change.
local function HostPaused(b, text)
	local Kit = ns.Kit
	local s = Kit and type(Kit.ButtonOf) == "function" and Kit.ButtonOf(b) or nil
	if type(s) ~= "table" or type(s.Paint) ~= "function" then return end
	local paused = type(text) == "string" and string.find(text, "PAUSED", 1, true) ~= nil
	local off = (paused or not b:IsEnabled()) or nil
	if s.off == off then return end
	s.off = off
	s.Paint()
	if type(s.Light) == "function" then s.Light(not off and b:IsMouseOver() == true) end
end

-- New words on a button (its state words, the Swap button's next step): fitted again; the Host
-- button's grayed look follows them.
local function LabelSet(b, text)
	if not ns.Enabled(KEY) then return end
	local fs = b:GetFontString()
	if ns.Usable(fs) then FitLabel(b, fs) end
	if b:GetName() == "LayerSwapPanelHostButton" then HostPaused(b, text) end
end

local function PanelButton(b)
	if not ns.Usable(b) or buttonsDone[b] then return end
	buttonsDone[b] = true
	ns.HookOnce(b, "SetDisabledFontObject", ButtonText, KEY)
	ns.HookOnce(b, "SetText", LabelSet, KEY)
	ns.ScriptOnce(b, "OnEnable", ButtonText, KEY)
	ns.ScriptOnce(b, "OnDisable", ButtonText, KEY)
	ButtonText(b)
	LabelSet(b, b:GetText())
end

-- The guild entry's title takes its words' look from the button's font objects (gold, white under
-- the mouse): its own copies of them, made once and filled again when the style or look changes.
local guildFont, guildHover
local function FillGuildFonts()
	if not guildFont then return end
	local base = _G.GameFontNormal
	local path, size, flags = base:GetFont()
	local face
	face, size, flags = ns.FontFor(KEY, path, size, flags)
	guildFont:CopyFontObject(base)
	if face and size then guildFont:SetFont(face, size, flags or "") end
	guildHover:CopyFontObject(guildFont)
	if ns.Look(KEY, "daylightColors") == false then
		-- The addon's own colors: gold, white under the mouse.
		local h = _G.GameFontHighlight
		if h then guildHover:SetTextColor(h:GetTextColor()) end
		return
	end
	local c = ns.Colors().LABEL or { 1, 1, 1 }
	guildFont:SetTextColor(c[1], c[2], c[3])
	guildHover:SetTextColor(ns.AccentOf(KEY))
end

local function GuildEntry(ge)
	if not ns.Usable(ge) or not ge.SetNormalFontObject or not ns.Once(ge) then return end
	if not guildFont then
		guildFont = CreateFont("DaylightAddonSkinsLayerSwapGuild")
		guildHover = CreateFont("DaylightAddonSkinsLayerSwapGuildHover")
		FillGuildFonts()
	end
	ge:SetNormalFontObject(guildFont)
	ge:SetHighlightFontObject(guildHover)
	Font(ge.line)
	Ink(ge.line, "TEXT")
end

-- The panel's status line: two lines in a box LayerSwap sized for the game's font. In a larger
-- font (a text size above 100%, a taller face) the second line would be clipped, so the font steps
-- down a size at a time until two lines and their spacing fit the box again. The box itself keeps
-- its height: the rows under it are laid out from it.
local function FitStatus(fs, room)
	if not ns.Usable(fs) or type(room) ~= "number" or room <= 0 or not fs.GetLineHeight then return end
	local spacing = fs.GetSpacing and fs:GetSpacing() or 0
	for _ = 1, 6 do
		local face, size, flags = fs:GetFont()
		local line = fs:GetLineHeight()
		if not face or not size or not line or line * 2 + spacing <= room + 0.5 or size <= 8 then return end
		fs:SetFont(face, size - 1, flags or "")
	end
end

local function Panel(p, Kit)
	if not ns.Once(p) then return end
	KillFlat(p:GetRegions())
	ns.Shell(p, { window = true }, KEY)
	-- (The status line's box is two lines of the game's font tall, set once by LayerSwap; the rows
	-- below it are placed from that. Read before our font goes on.)
	local statusRoom = ns.Usable(p.status) and p.status.GetHeight and p.status:GetHeight() or nil
	for key, role in pairs(PANEL_TEXT) do
		Font(p[key])
		Ink(p[key], role)
	end
	FitStatus(p.status, statusRoom)
	Font(p.evict)
	for _, row in ipairs(type(p.rows) == "table" and p.rows or {}) do
		Font(row.left)
		Ink(row.left, "TEXT")
		Font(row.right)
		Ink(row.right, "OFF")
	end
	if ns.Controls(KEY) then
		if ns.Usable(p.closeButton) then ns.Guard(Kit.Close, p.closeButton) end
		for _, key in ipairs(PANEL_BUTTONS) do
			if ns.Usable(p[key]) then ns.Guard(Kit.Button, p[key]) end
		end
	end
	for _, key in ipairs(PANEL_BUTTONS) do PanelButton(p[key]) end
	GuildEntry(p.guildButton)
end

-- ---------------------------------------------------------------------------------------------
-- The two menus
-- ---------------------------------------------------------------------------------------------

local dock, dockText          -- the Layer button on the minimap and its words (made below)
local rowsDone = setmetatable({}, { __mode = "k" })
local dockMenu                -- the menu this button opened (kept up while it shows), or nil

local function MenuRows(menu)
	for _, b in ipairs(type(menu.items) == "table" and menu.items or {}) do
		if not rowsDone[b] then
			rowsDone[b] = true
			Font(b.label)
			Font(b.age)
			Ink(b.age, "OFF")
		end
		-- Its rows are white while they can be clicked and gray while not (set at each opening):
		-- the clickable ones take the text ink.
		if b:IsShown() and b:IsMouseEnabled() and ns.Usable(b.label) then
			local r = b.label:GetTextColor()
			if type(r) == "number" and r > 0.9 then Ink(b.label, "TEXT") end
		end
	end
end

-- A click anywhere else closes its menus (LayerSwap's own only close on Escape or a second
-- click on what opened them). Listened for only while one is open. A click on the menu, or on
-- what opens it (the Layer button, its mini bar and logo, its minimap icon), is left to them,
-- or that click would close the menu and open it again.
local MENU_NAMES = { "LayerSwapMenu", "LayerSwapSettingsMenu" }
local OPENERS = { "LayerSwapMini", "LayerSwapMiniLogo", "LibDBIcon10_LayerSwap" }
local outside = CreateFrame("Frame")

local function Over(f) return f ~= nil and ns.Usable(f) and f:IsShown() and f:IsMouseOver() == true end

local function AnyMenuOpen()
	for _, name in ipairs(MENU_NAMES) do
		local m = _G[name]
		if m and m:IsShown() then return true end
	end
	return false
end

local function OutsideClick()
	if Over(dock) then return end
	for _, name in ipairs(OPENERS) do
		if Over(_G[name]) then return end
	end
	for _, name in ipairs(MENU_NAMES) do
		local m = _G[name]
		if m and m:IsShown() and not Over(m) then m:Hide() end
	end
end

outside:SetScript("OnEvent", function() ns.Guard(OutsideClick) end)

local function OutsideWatch()
	if AnyMenuOpen() then
		outside:RegisterEvent("GLOBAL_MOUSE_DOWN")
	else
		outside:UnregisterEvent("GLOBAL_MOUSE_DOWN")
	end
end

local function MenuShown(menu)
	if ns.Enabled(KEY) then MenuRows(menu) end
	OutsideWatch()
end

local function MenuHidden(menu)
	if dockMenu == menu then dockMenu = nil end
	OutsideWatch()
end

local function Menu(menu)
	if not ns.Once(menu) then return end
	KillFlat(menu:GetRegions())
	ns.Shell(menu, { noBevel = true, borderPx = 2, bgAlpha = 0.95 }, KEY)
	ns.ScriptOnce(menu, "OnShow", MenuShown, KEY)
	ns.ScriptOnce(menu, "OnHide", MenuHidden, KEY)
	MenuRows(menu)
	OutsideWatch()   -- (dressed while already open: its first opening)
end

-- ---------------------------------------------------------------------------------------------
-- Dressing what's just been opened
-- ---------------------------------------------------------------------------------------------
-- LayerSwap makes its panel and menus inside the click that opens them: they're dressed right
-- after that click, before they're drawn. (Each is dressed once; later calls only look.)
local caughtAll = false
local function Catch()
	if caughtAll or not ns.Enabled(KEY) then return end
	local Kit = ns.Kit
	if not Kit then return end
	local p, menu, settings = _G.LayerSwapPanel, _G.LayerSwapMenu, _G.LayerSwapSettingsMenu
	if ns.Usable(p) then Panel(p, Kit) end
	if ns.Usable(menu) then Menu(menu) end
	if ns.Usable(settings) then
		Menu(settings)
		if ns.DockRowSetup then ns.Guard(ns.DockRowSetup, settings) end
	end
	caughtAll = p ~= nil and menu ~= nil and settings ~= nil
end

-- ---------------------------------------------------------------------------------------------
-- The mini bar
-- ---------------------------------------------------------------------------------------------

local function Mini(m)
	if not ns.Once(m) then return end
	-- Its ground is its own darkness setting: kept, with a thin edge round it.
	ns.Shell(m, { noBackground = true, noBevel = true, borderPx = 2 }, KEY)
	Font(m.text)
	Ink(m.text, "TEXT")
	Font(m.status)
	ns.ScriptOnce(m, "OnClick", Catch, KEY)
	ns.ScriptOnce(m.logo, "OnClick", Catch, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- The minimap button
-- ---------------------------------------------------------------------------------------------
-- Its make follows DaylightUI's corner buttons: 24 high, set in 4 from the map's edges, a dark
-- ground at 0.6 under a thin edge as thick as theirs, its text in the label ink and in the accent
-- while lit, at their level over the map, fading in and out over the map in their time.
local DOCK_H, DOCK_INSET, DOCK_PAD, DOCK_LEVEL = 24, 4, 8, 5
local DOCK_BG = 0.6
local DOCK_READ = 1
local function DockBorder(px) return math.max(3, math.floor(px * 0.5 + 0.5)) end

local dockGoal = 1
local dockLift = 0            -- how far it's raised over the queue eye

local function Launcher()
	local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
	local obj = LDB and LDB:GetDataObjectByName("LayerSwap")
	return type(obj) == "table" and obj or nil
end

-- What LayerSwap's launcher would put in its tooltip, caught line by line (its second line is the
-- layer, with " Host on" after it while hosting).
local caught = {}
local catcher = { AddLine = function(_, text) caught[#caught + 1] = text end,
	AddDoubleLine = function(_, text) caught[#caught + 1] = text end }

local function LayerLines()
	local obj = Launcher()
	if not obj or type(obj.OnTooltipShow) ~= "function" then return nil end
	wipe(caught)
	if not pcall(obj.OnTooltipShow, catcher) then return nil end
	return caught
end

local function LayerWord()
	-- (Read off its launcher's tooltip, in its words: LayerSwap keeps the layer it's on to itself,
	-- and is in English only. Should it ever be translated, the lines below read "Layer: ?".)
	-- Dungeons and raids have no layers (LayerSwap's own bar says so there too).
	if IsInInstance and IsInInstance() then return string.format(L["Layer: %s"], "-") end
	local lines = LayerLines()
	local line = lines and lines[2]
	if type(line) ~= "string" then return string.format(L["Layer: %s"], "?") end
	line = string.gsub(line, "%s%s%s.*$", "")          -- " Host on" after three spaces
	local rest = string.match(line, "^Layer%s+(.+)$")
	if rest then return string.format(L["Layer: %s"], rest) end
	-- (Not read yet; 1.14.34 says "In flight" there on a flight path with the layer unread.)
	if line == "Detecting..." or line == "In flight" then return string.format(L["Layer: %s"], "...") end
	return string.format(L["Layer: %s"], "?")
end

-- DaylightUI's square map, on which its corner buttons sit.
local function SquareMap()
	return API.IsModuleEnabled("InfoPanel") and API.GetSetting("InfoPanel", "map.enabled") ~= false
end

local function DockMode()
	if not (ns.Enabled(KEY) and SquareMap()) then return "off" end
	local v = ns.Setting("look." .. KEY .. ".dock")
	if v == "always" or v == "hover" or v == "off" then return v end
	return "always"
end

local function DockPaint()
	if not dock then return end
	if dock:IsMouseOver() == true then
		dockText:SetTextColor(ns.AccentOf(KEY))
	else
		local c = ns.Colors().LABEL
		dockText:SetTextColor(c[1], c[2], c[3])
	end
end

local function DockRead()
	if not dock then return end
	local word = LayerWord()
	if dockText:GetText() ~= word then dockText:SetText(word) end
	-- Measured every time (a font or size change resizes the text without changing it), set only
	-- when it changed.
	local w = math.ceil(dockText:GetStringWidth() or 0) + DOCK_PAD * 2
	if w ~= dock.width then
		dock.width = w
		dock:SetWidth(w)
	end
end

-- The game's queue eye, which DaylightUI pins in the same corner: the button sits above it while
-- it shows.
local function EyeLift()
	local eye = _G.QueueStatusButton
	if not (eye and eye.IsShown and eye:IsShown()) then return 0 end
	return math.ceil((eye:GetHeight() or 0) * (eye:GetScale() or 1)) + 2
end

local function DockPlace()
	local mm = _G.Minimap
	if not (dock and mm) then return end
	dockLift = EyeLift()
	dock:ClearAllPoints()
	dock:SetPoint("BOTTOMLEFT", mm, "BOTTOMLEFT", DOCK_INSET, DOCK_INSET + dockLift)
	dock:SetFrameLevel(mm:GetFrameLevel() + DOCK_LEVEL)
end

local function DockGoal()
	if DockMode() == "always" or dockMenu then return 1 end
	local mm = _G.Minimap
	return ((mm and mm:IsMouseOver() == true) or dock:IsMouseOver() == true) and 1 or 0
end

-- Nothing runs every frame. The goal (shown, or faded in hover mode) is looked at when the mouse
-- goes onto or off the map or this button; the layer's name, the queue eye and the goal once a
-- second while the button shows (a ticker, stopped while it's hidden).
local function DockCheck()
	if not (dock and dock:IsShown()) then return end
	local goal = DockGoal()
	if goal ~= dockGoal then
		dockGoal = goal
		API.Fade(dock, goal, "FAST")
	end
end
-- (A moment later: the mouse has landed on whatever is next.)
local function DockCheckSoon() C_Timer.After(0, DockCheck) end

local dockTicker
local function DockTick()
	DockRead()
	if EyeLift() ~= dockLift then DockPlace() end
	DockCheck()
end
local function DockTicking(on)
	if on and not dockTicker then
		dockTicker = C_Timer.NewTicker(DOCK_READ, DockTick)
	elseif not on and dockTicker then
		dockTicker:Cancel()
		dockTicker = nil
	end
end

-- LayerSwap places its menus by its own bar and button; the ones opened here are moved to this
-- button instead (LayerSwap places them again each time it opens them, so this holds for this
-- opening only).
local function MenuHere(menu, point, relPoint, x, y)
	if not (menu and menu:IsShown()) then return end
	dockMenu = menu
	menu:ClearAllPoints()
	menu:SetPoint(point, dock, relPoint, x, y)
end

local function Slash()
	local slash = SlashCmdList and SlashCmdList.LAYERSWAP
	if type(slash) == "function" then pcall(slash, "") end
end

local function DockClick(self, button)
	local obj = Launcher()
	if button == "RightButton" and not IsShiftKeyDown() then
		local logo = _G.LayerSwapMiniLogo
		local click = logo and logo:GetScript("OnClick")
		if click then
			pcall(click, logo, "RightButton")
			Catch()
			MenuHere(_G.LayerSwapMenu, "TOPLEFT", "BOTTOMLEFT", 0, -2)
		end
	elseif obj and type(obj.OnClick) == "function" then
		pcall(obj.OnClick, self, button)
		Catch()
		if button == "RightButton" then MenuHere(_G.LayerSwapSettingsMenu, "BOTTOMLEFT", "TOPLEFT", 0, 2) end
	elseif button ~= "RightButton" then
		-- No launcher (LayerSwap found no minimap library): its /ls opens the panel.
		Slash()
		Catch()
	end
end

local function DockEnter(self)
	DockPaint()
	DockCheckSoon()
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	local lines = LayerLines()
	GameTooltip:AddLine("LayerSwap")
	if lines and type(lines[2]) == "string" then GameTooltip:AddLine(lines[2], 1, 1, 1) end
	GameTooltip:AddLine(L["Left-click: the panel. Right-click: ask for a layer. Shift + right-click: settings."], 0.7, 0.7, 0.7, true)
	GameTooltip:Show()
end

local function DockLeave()
	DockPaint()
	DockCheckSoon()
	GameTooltip:Hide()
end

local function BuildDock()
	local mm = _G.Minimap
	if dock or not ns.Usable(mm) then return end
	dock = CreateFrame("Button", nil, mm)
	dock:SetHeight(DOCK_H)
	dock:SetWidth(70)
	dock:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	local shell = API.Skin(dock, { borderPx = DockBorder, noBevel = true })
	if shell and shell.bg then shell.bg:SetAlpha(DOCK_BG) end
	dockText = API.Text(dock, "small", "CENTER")
	dockText:SetPoint("CENTER", dock, "CENTER", 0, 0)
	dockText:SetWordWrap(false)
	dock:SetScript("OnClick", DockClick)
	dock:SetScript("OnEnter", DockEnter)
	dock:SetScript("OnLeave", DockLeave)
	dock:SetScript("OnShow", function() DockTicking(true) DockTick() end)
	dock:SetScript("OnHide", function() DockTicking(false) end)
	mm:HookScript("OnEnter", DockCheckSoon)
	mm:HookScript("OnLeave", DockCheckSoon)
	DockPlace()
	DockRead()
	DockPaint()
end

local function ApplyDock()
	if DockMode() == "off" then
		if dock then dock:Hide() end
		return
	end
	BuildDock()
	if not dock then return end
	DockPlace()
	dockGoal = DockGoal()
	dock:SetAlpha(dockGoal)
	dock:Show()
	DockTicking(true)   -- (Show on a shown frame doesn't run its OnShow)
end

-- ---------------------------------------------------------------------------------------------
-- The Layer button's row in LayerSwap's settings menu
-- ---------------------------------------------------------------------------------------------
-- LayerSwap draws its settings menu's rows itself and sets the menu's height for them on every
-- drawing (SetHeight in its render): one row of ours goes below its last one, and the height it
-- sets is raised by one row each time. Shift + click goes Always <-> On hover (Off -> Always),
-- the same setting as "Layer button on the minimap" on this addon's page.
local DOCK_PATH = "look." .. KEY .. ".dock"
local dockRow
local rowRaising = false

local function DockRowWanted() return ns.Enabled(KEY) and SquareMap() end

local function DockRowText()
	local v = ns.Setting(DOCK_PATH)
	local word = (v == "hover" and L["On Hover"]) or (v == "off" and L["Off"]) or L["Always"]
	local r, g, b = ns.AccentOf(KEY)
	return string.format(L["Layer Button: %s"],
		string.format("|cff%02x%02x%02x%s|r", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), word))
end

local function LastRow(menu)
	local last
	for _, b in ipairs(type(menu.items) == "table" and menu.items or {}) do
		if b:IsShown() then last = b end
	end
	return last
end

local function DockRowPlace(menu)
	if not dockRow then return end
	local last = LastRow(menu)
	if not (last and DockRowWanted()) then
		dockRow:Hide()
		return
	end
	dockRow:ClearAllPoints()
	dockRow:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, 0)
	dockRow:SetPoint("TOPRIGHT", last, "BOTTOMRIGHT", 0, 0)
	dockRow:SetHeight(last:GetHeight())
	dockRow.label:SetText(DockRowText())
	Font(dockRow.label)
	Ink(dockRow.label, "TEXT")
	dockRow:Show()
	-- Never cut off: the menu (170 wide, set once by LayerSwap) widens to fit our words.
	local need = math.ceil(dockRow.label:GetStringWidth() or 0) + 12 + 8
	if need > (menu:GetWidth() or 0) then menu:SetWidth(need) end
end

-- LayerSwap's own height (its rows and 8) plus ours, while ours shows.
local function DockRowRaise(menu, h)
	if rowRaising or not (dockRow and dockRow:IsShown()) or type(h) ~= "number" then return end
	rowRaising = true
	menu:SetHeight(h + dockRow:GetHeight())
	rowRaising = false
end

local function DockRowFit(menu)
	local shown = dockRow and dockRow:IsShown()
	DockRowPlace(menu)
	local n = 0
	for _, b in ipairs(type(menu.items) == "table" and menu.items or {}) do
		if b:IsShown() then n = n + 1 end
	end
	local last = LastRow(menu)
	if not last then return end
	local h = n * last:GetHeight() + 8
	if dockRow:IsShown() then h = h + dockRow:GetHeight() end
	if shown ~= dockRow:IsShown() or math.abs((menu:GetHeight() or 0) - h) > 0.5 then
		rowRaising = true
		menu:SetHeight(h)
		rowRaising = false
	end
end

local function DockRowClick(self)
	if not IsShiftKeyDown() then return end
	local v = ns.Setting(DOCK_PATH)
	local nextV = (v == "always" or v == nil) and "hover" or "always"
	ns.Guard(function() _G.DaylightUI:Set(ADDON, DOCK_PATH, nextV) end)
	self.label:SetText(DockRowText())
end

local function DockRowEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(L["Shift + click to switch"], 1, 1, 1)
	GameTooltip:AddLine(L["The Layer button on Daylight UI's minimap: always shown, or only with the mouse over the map. Off is on this addon's page in Addon Skins."], 0.7, 0.7, 0.7, true)
	GameTooltip:Show()
end

local function DockRowSetup(menu)
	if dockRow then return end
	dockRow = CreateFrame("Button", nil, menu)
	dockRow:Hide()
	local lit = dockRow:CreateTexture(nil, "HIGHLIGHT")
	lit:SetAllPoints(dockRow)
	lit:SetColorTexture(1, 1, 1, 0.1)
	dockRow.label = dockRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	dockRow.label:SetPoint("LEFT", dockRow, "LEFT", 6, 0)
	dockRow.label:SetPoint("RIGHT", dockRow, "RIGHT", -6, 0)
	dockRow.label:SetJustifyH("LEFT")
	dockRow.label:SetWordWrap(false)
	dockRow:SetScript("OnClick", DockRowClick)
	dockRow:SetScript("OnEnter", DockRowEnter)
	dockRow:SetScript("OnLeave", function() GameTooltip:Hide() end)
	ns.HookOnce(menu, "SetHeight", function(self, h) ns.Guard(DockRowRaise, self, h) end, KEY)
	-- (A plain HookScript: Menu above already has this menu's OnShow through ns.ScriptOnce.)
	menu:HookScript("OnShow", function(self) ns.Guard(DockRowFit, self) end)
	DockRowFit(menu)
end

ns.DockRowSetup = DockRowSetup

-- ---------------------------------------------------------------------------------------------
-- The mini bar's fade
-- ---------------------------------------------------------------------------------------------
-- On hover, LayerSwap's mini bar shows only while the mouse is over the minimap or the bar (or
-- you're dragging it, or one of its menus is open), fading in and out as DaylightUI's minimap
-- buttons do. Looked at when the mouse goes onto or off either one; nothing runs every frame.

local miniGoal = 1
local mapHooked = false

local function MiniMode()
	if not ns.Enabled(KEY) then return "always" end
	local v = ns.Setting("look." .. KEY .. ".miniFade")
	return v == "hover" and "hover" or "always"
end

local function MenuOpen()
	for _, name in ipairs({ "LayerSwapMenu", "LayerSwapSettingsMenu" }) do
		local m = _G[name]
		if m and m.IsShown and m:IsShown() then return true end
	end
	return false
end

local function MiniGoal(mini)
	if MiniMode() == "always" or mini.dragging or MenuOpen() then return 1 end
	local mm = _G.Minimap
	return ((mm and mm:IsMouseOver() == true) or mini:IsMouseOver() == true) and 1 or 0
end

local function MiniCheck()
	local mini = _G.LayerSwapMini
	if not (mini and ns.Usable(mini)) then return end
	local goal = MiniGoal(mini)
	if goal == miniGoal then return end
	miniGoal = goal
	if mini:IsShown() then API.Fade(mini, goal, "FAST") else mini:SetAlpha(goal) end
end
local function MiniCheckSoon() C_Timer.After(0, function() ns.Guard(MiniCheck) end) end

local function HookMini(mini)
	if not ns.Usable(mini) then return end
	ns.ScriptOnce(mini, "OnEnter", MiniCheckSoon, KEY)
	ns.ScriptOnce(mini, "OnLeave", MiniCheckSoon, KEY)
	ns.ScriptOnce(mini, "OnDragStart", function(self) self.dragging = true; MiniCheckSoon() end, KEY)
	ns.ScriptOnce(mini, "OnDragStop", function(self) self.dragging = nil; MiniCheckSoon() end, KEY)
	ns.ScriptOnce(mini, "OnShow", function(self)
		miniGoal = MiniGoal(self)
		self:SetAlpha(miniGoal)
	end, KEY)
	for _, name in ipairs({ "LayerSwapMiniLogo" }) do
		local child = _G[name]
		if child and ns.Usable(child) then
			ns.ScriptOnce(child, "OnEnter", MiniCheckSoon, KEY)
			ns.ScriptOnce(child, "OnLeave", MiniCheckSoon, KEY)
		end
	end
end

local function ApplyMiniFade()
	local mini = _G.LayerSwapMini
	if not mini then return end
	HookMini(mini)
	local mm = _G.Minimap
	if mm and not mapHooked and MiniMode() == "hover" then
		mapHooked = true
		mm:HookScript("OnEnter", MiniCheckSoon)
		mm:HookScript("OnLeave", MiniCheckSoon)
	end
	miniGoal = MiniGoal(mini)
	mini:SetAlpha(miniGoal)
end

-- ---------------------------------------------------------------------------------------------
-- The options page
-- ---------------------------------------------------------------------------------------------

-- Its sliders (no game template): a thin track with the accent fill up to the knob and a round
-- knob that grows under the mouse. Its own thumb stays (it moves it), out of sight; its gray
-- track gives way to ours.
local KNOB_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local sliders = setmetatable({}, { __mode = "k" })

local function SliderPaint(s)
	ns.FillAccent(s.fill, 1, nil, KEY)
end

local function SliderLook(slider)
	if not ns.Usable(slider) or sliders[slider] then return end
	local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
	if not ns.Usable(thumb) then return end
	local s = {}
	sliders[slider] = s
	-- Its gray track out of sight; the thumb only see-through (it's what the knob rides on).
	for i = 1, slider:GetNumRegions() do
		local r = select(i, slider:GetRegions())
		if r ~= thumb and r.GetObjectType and r:GetObjectType() == "Texture" then ns.Kill(r) end
	end
	thumb:SetAlpha(0)
	s.track = slider:CreateTexture(nil, "ARTWORK")
	s.track:SetColorTexture(1, 1, 1, 0.14)
	s.track:SetPoint("LEFT", slider, "LEFT", 0, 0)
	s.track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
	Pixel(s.track, 4)
	s.fill = slider:CreateTexture(nil, "ARTWORK", nil, 1)
	s.fill:SetPoint("LEFT", s.track, "LEFT", 0, 0)
	s.fill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)
	Pixel(s.fill, 4)
	s.knob = slider:CreateTexture(nil, "OVERLAY")
	s.knob:SetColorTexture(1, 1, 1, 1)
	s.knob:SetSize(12, 12)
	s.knob:SetPoint("CENTER", thumb, "CENTER", 0, 0)
	local mask = slider:CreateMaskTexture()
	mask:SetTexture(KNOB_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(s.knob)
	s.knob:AddMaskTexture(mask)
	SliderPaint(s)
	ns.ScriptOnce(slider, "OnEnter", function() if ns.Enabled(KEY) then s.knob:SetSize(14, 14) end end, KEY)
	ns.ScriptOnce(slider, "OnLeave", function() if ns.Enabled(KEY) then s.knob:SetSize(12, 12) end end, KEY)
	ns.ScriptOnce(slider, "OnShow", function() if ns.Enabled(KEY) then SliderPaint(s) end end, KEY)
end

local OPTION_GOLD = 0.03
local function GoldOf(fs)
	local r, g, b = fs:GetTextColor()
	return type(r) == "number" and math.abs(r - 1) <= OPTION_GOLD and math.abs(g - 0.82) <= OPTION_GOLD
		and b <= OPTION_GOLD
end

-- Its title and its switches' names are in the game's gold: bright, as DaylightUI's own settings
-- show them; the notes and values soft. (Every text on the page is one of its own strings.)
local function OptionTexts(...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if r.GetObjectType and r:GetObjectType() == "FontString" then
			Font(r)
			Ink(r, GoldOf(r) and "VALUE" or "TEXT")
		end
	end
end

-- Its switches' names and notes are one line each, cut short with "..." when too long (LayerSwap
-- sized them for its own font): one that runs over steps down a size or three. Done as the page
-- shows, when it has its width.
local lineSize = setmetatable({}, { __mode = "k" })
local function FitLines(...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if r.GetObjectType and r:GetObjectType() == "FontString" and r.IsTruncated
			and r.CanWordWrap and not r:CanWordWrap() then
			local path, size, flags = r:GetFont()
			if path and type(size) == "number" then
				local base = lineSize[r] or size
				lineSize[r] = base
				local s = base
				if size ~= s then r:SetFont(path, s, flags or "") end
				while r:IsTruncated() and s > base - LABEL_STEPS do
					s = s - 1
					r:SetFont(path, s, flags or "")
				end
			end
		end
	end
end

local function FitOptions(o)
	if not ns.Enabled(KEY) then return end
	FitLines(o:GetRegions())
	-- (Once more a moment later: the game's options window sizes the page as it shows it.)
	ns.Queue(o, function() if o:IsVisible() then FitLines(o:GetRegions()) end end, KEY)
end

local function Options(o, Kit)
	if not ns.Once(o) then return end
	OptionTexts(o:GetRegions())
	ns.ScriptOnce(o, "OnShow", FitOptions, KEY)
	if o:IsVisible() then FitOptions(o) end
	for _, s in ipairs(type(o.sliders) == "table" and o.sliders or {}) do SliderLook(s) end
	if ns.Controls(KEY) then
		ns.Guard(Kit.Auto, o, { rows = false })
	end
	-- Its "Open the panel" button is one more click that makes the panel.
	local open = _G.LayerSwapOptionsOpen
	if ns.Usable(open) and open:GetParent() == o then ns.ScriptOnce(open, "OnClick", Catch, KEY) end
end

-- ---------------------------------------------------------------------------------------------

ns.Pack(KEY, nil, function()
	if not ns.Enabled(KEY) then return end
	ApplyDock()
	-- Made at login (the mini bar hidden until then, the options page inside the game's options
	-- window): the watches find them before they can show.
	ns.Watch(KEY, "LayerSwapMini", Mini)
	ns.Watch(KEY, "LayerSwapOptions", Options)
	-- Made later, as they first open: dressed at once from the clicks that open them (and the
	-- watches stay for the panel LayerSwap opens by itself after a swap).
	ns.Watch(KEY, "LayerSwapPanel", Panel)
	ns.Watch(KEY, "LayerSwapMenu", function(menu) Menu(menu) end)
	ns.Watch(KEY, "LayerSwapSettingsMenu", function(menu)
		Menu(menu)
		ns.Guard(DockRowSetup, menu)
	end)
	if type(SlashCmdList) == "table" and type(SlashCmdList.LAYERSWAP) == "function" then
		ns.HookOnce(SlashCmdList, "LAYERSWAP", Catch, KEY)
	end
	ns.Watch(KEY, "LibDBIcon10_LayerSwap", function(b) ns.ScriptOnce(b, "OnClick", Catch, KEY) end)
	-- The mini bar is made as LayerSwap starts: its fade goes on when it's there.
	ns.Watch(KEY, "LayerSwapMini", function() ns.Guard(ApplyMiniFade) end)
	-- A menu of its closing: the bar may fade again. (A plain HookScript: Menu has the menu's
	-- OnHide through ns.ScriptOnce.)
	for _, name in ipairs({ "LayerSwapMenu", "LayerSwapSettingsMenu" }) do
		ns.Watch(KEY, name, function(m) m:HookScript("OnHide", MiniCheckSoon) end)
	end
	-- The button follows its setting as it's changed, and the accent and fonts as they change.
	ns.me.On("SettingChanged", function(scope, path)
		if scope == "DaylightAddonSkins" and type(path) == "string"
			and (path == "look." .. KEY .. ".dock" or path == KEY) then
			ns.Guard(ApplyDock)
			ns.Guard(ApplyMiniFade)
			local menu = _G.LayerSwapSettingsMenu
			if dockRow and menu and menu:IsShown() then ns.Guard(DockRowFit, menu) end
		elseif scope == "DaylightAddonSkins" and path == "look." .. KEY .. ".miniFade" then
			ns.Guard(ApplyMiniFade)
		elseif scope == "DaylightAddonSkins" and type(path) == "string"
			and (path == "followDaylight" or string.sub(path, 1, #KEY + 6) == "look." .. KEY .. ".") then
			-- Its font, colors or accent picked on its page: the guild entry's title follows.
			ns.Queue("LayerSwap:guildFonts", FillGuildFonts, KEY)
		elseif scope == "InfoPanel" then
			ns.Guard(ApplyDock)
		end
	end)
	ns.me.On("StyleChanged", function()
		if not ns.Enabled(KEY) then return end
		if dock then
			DockRead()
			DockPaint()
		end
		for _, s in pairs(sliders) do SliderPaint(s) end
		ns.Guard(FillGuildFonts)
	end)
	-- DaylightUI places its map (and may raise it) as the world loads: the button's level and
	-- place follow it.
	local entering = CreateFrame("Frame")
	entering:RegisterEvent("PLAYER_ENTERING_WORLD")
	entering:SetScript("OnEvent", function()
		ns.Queue("LayerSwap:dock", ApplyDock, KEY)
	end)
	if not dock then C_Timer.After(1, function() ns.Guard(ApplyDock) end) end
end)
