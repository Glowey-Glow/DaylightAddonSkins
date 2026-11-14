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
--     font and DaylightUI's ink go back on after it, the dim ink while it's grayed. Its "Ask your
--     guild" entry (LayerSwapPanelGuildButton, shown only in a guild): its title on font objects of
--     ours (the label ink, the accent under the mouse; LayerSwap sets them once, as it builds the
--     entry), its "Guild chat reaches every layer" line in your font and the text ink.
--   * Its layer menu and settings menu (LayerSwapMenu, LayerSwapSettingsMenu): DaylightUI's menu
--     shell, rows in your font and the text ink, ages in the dim ink. Grayed rows stay grayed.
--   * Its mini bar (LayerSwapMini): a thin DaylightUI edge round it, your font and the text ink.
--     Its background keeps LayerSwap's own darkness setting.
--   * Its options page (Options, AddOns, LayerSwap): DaylightUI's switches, buttons and text inks
--     (through Kit.Auto), its sliders as a thin track with the accent fill and a round knob.
-- How the pieces are found: by name. The panel and the menus are made the first time they open, so
-- they're dressed the moment one of LayerSwap's own buttons, its slash command or this button
-- opens them (and watched for, for the panel it opens by itself after a swap); their rows are made
-- as they're first needed and dressed each time the menu shows.
-- Hooked (post-hooks only): each menu's OnShow and OnHide; the Swap / Host / Mini bar buttons'
-- SetDisabledFontObject, OnEnable and OnDisable; the clicks of the mini bar, its logo and
-- LayerSwap's minimap button, and its /ls command (to dress what they open at once).
-- Left as it is: its logo and the logo's light, the guild entry's emblem (the guild's own tabard)
-- and its faint 0.08 hover light, the green / gray ON and OFF words and the orange
-- world refresh line (they mean something), its rows' faint hover light (DaylightUI's own
-- strength), its LibDBIcon minimap button (DaylightUI's drawer has it), and what's the game's or
-- DaylightUI's: the tooltips over its rows (the game tooltip), its lines in chat and the chat box
-- it fills in for a request, the party invite popup, the Who list it reads quietly.
local _, ns = ...
if not ns.ok then return end

local KEY = "LayerSwap"

ns.Target(KEY, "LayerSwap", { window = true, controls = true, text = true, shadow = true, colors = true,
	font = "daylight", defaults = { dock = "always" }, extraTab = "Minimap",
	extra = function(at)
		return {
			{ label = "Minimap button", items = {
				{ type = "dropdown", key = at .. "dock", label = "Layer button on the minimap",
				  values = { always = "Always", hover = "On hover", off = "Off" },
				  desc = "A \"Layer: B\" button in the bottom-left corner of DaylightUI's minimap: always shown, only with the mouse over the map (On hover), or off. Left-click opens LayerSwap's panel, right-click its layer menu, shift + right-click its settings. LayerSwap's own mini bar can be turned off in its options (Mini bar)." },
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
local function ButtonText(b)
	if not ns.Enabled(KEY) then return end
	local fs = b:GetFontString()
	Font(fs)
	Ink(fs, b:IsEnabled() and "TEXT" or "OFF")
end

local function PanelButton(b)
	if not ns.Usable(b) or buttonsDone[b] then return end
	buttonsDone[b] = true
	hooksecurefunc(b, "SetDisabledFontObject", ButtonText)
	b:HookScript("OnEnable", ButtonText)
	b:HookScript("OnDisable", ButtonText)
	ButtonText(b)
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

local function Panel(p, Kit)
	if not ns.Once(p) then return end
	KillFlat(p:GetRegions())
	ns.Shell(p, { window = true }, KEY)
	for key, role in pairs(PANEL_TEXT) do
		Font(p[key])
		Ink(p[key], role)
	end
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

local function MenuShown(menu)
	if ns.Enabled(KEY) then MenuRows(menu) end
end

local function MenuHidden(menu)
	if dockMenu == menu then dockMenu = nil end
end

local function Menu(menu)
	if not ns.Once(menu) then return end
	KillFlat(menu:GetRegions())
	ns.Shell(menu, { noBevel = true, borderPx = 2, bgAlpha = 0.95 }, KEY)
	menu:HookScript("OnShow", MenuShown)
	menu:HookScript("OnHide", MenuHidden)
	MenuRows(menu)
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
	if ns.Usable(settings) then Menu(settings) end
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
	m:HookScript("OnClick", Catch)
	if ns.Usable(m.logo) then m.logo:HookScript("OnClick", Catch) end
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

local dock, dockText
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
	-- Dungeons and raids have no layers (LayerSwap's own bar says so there too).
	if IsInInstance and IsInInstance() then return "Layer: -" end
	local lines = LayerLines()
	local line = lines and lines[2]
	if type(line) ~= "string" then return "Layer: ?" end
	line = string.gsub(line, "%s%s%s.*$", "")          -- " Host on" after three spaces
	local rest = string.match(line, "^Layer%s+(.+)$")
	if rest then return "Layer: " .. rest end
	if line == "Detecting..." then return "Layer: ..." end
	return "Layer: ?"
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
	GameTooltip:AddLine("Left-click: the panel. Right-click: ask for a layer. Shift + right-click: settings.", 0.7, 0.7, 0.7, true)
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
-- The options page
-- ---------------------------------------------------------------------------------------------

-- Its sliders (no game template): a thin track with the accent fill up to the knob and a round
-- knob that grows under the mouse. Its own thumb stays (it moves it), out of sight; its gray
-- track gives way to ours.
local KNOB_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local sliders = setmetatable({}, { __mode = "k" })

local function SliderPaint(s)
	s.fill:SetColorTexture(ns.AccentOf(KEY))
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
	slider:HookScript("OnEnter", function() if ns.Enabled(KEY) then s.knob:SetSize(14, 14) end end)
	slider:HookScript("OnLeave", function() if ns.Enabled(KEY) then s.knob:SetSize(12, 12) end end)
	slider:HookScript("OnShow", function() if ns.Enabled(KEY) then SliderPaint(s) end end)
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

local function Options(o, Kit)
	if not ns.Once(o) then return end
	OptionTexts(o:GetRegions())
	for _, s in ipairs(type(o.sliders) == "table" and o.sliders or {}) do SliderLook(s) end
	if ns.Controls(KEY) then
		ns.Guard(Kit.Auto, o, { rows = false })
	end
end

-- ---------------------------------------------------------------------------------------------

ns.Pack(KEY, nil, function(Kit)
	if not ns.Enabled(KEY) then return end
	ApplyDock()
	ns.Watch(KEY, "LayerSwapMini", Mini)
	ns.Watch(KEY, "LayerSwapOptions", Options)
	-- Made later, as they first open: dressed at once from the clicks that open them (and the
	-- watches stay for the panel LayerSwap opens by itself after a swap).
	ns.Watch(KEY, "LayerSwapPanel", Panel)
	ns.Watch(KEY, "LayerSwapMenu", function(menu) Menu(menu) end)
	ns.Watch(KEY, "LayerSwapSettingsMenu", function(menu) Menu(menu) end)
	if type(SlashCmdList) == "table" and type(SlashCmdList.LAYERSWAP) == "function" then
		hooksecurefunc(SlashCmdList, "LAYERSWAP", Catch)
	end
	ns.Watch(KEY, "LibDBIcon10_LayerSwap", function(b) b:HookScript("OnClick", Catch) end)
	-- The button follows its setting as it's changed, and the accent and fonts as they change.
	ns.me.On("SettingChanged", function(scope, path)
		if scope == "DaylightAddonSkins" and type(path) == "string"
			and (path == "look." .. KEY .. ".dock" or path == KEY) then
			ns.Guard(ApplyDock)
		elseif scope == "DaylightAddonSkins" and type(path) == "string"
			and (path == "followDaylight" or string.sub(path, 1, #KEY + 6) == "look." .. KEY .. ".") then
			-- Its font, colors or accent picked on its page: the guild entry's title follows.
			C_Timer.After(0, function() ns.Guard(FillGuildFonts) end)
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
		C_Timer.After(0, function() ns.Guard(ApplyDock) end)
	end)
	if not dock then C_Timer.After(1, function() ns.Guard(ApplyDock) end) end
end)
