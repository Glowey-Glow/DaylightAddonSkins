-- Polestar: it paints everything from one theme (Polestar.Theme) and repaints on Theme.Refresh(),
-- so the theme is fed rather than its frames touched: DaylightUI's shell as its window paint, the
-- player's font, accent and text colors in its palette. Only its house look ("polestar") is
-- changed; pick another look or skin in Polestar's own options (its added skins too, which are
-- built on the house look) and it is left as Polestar draws it.
-- Nothing is written to Polestar's saved settings but the hand-over at the end (its QoL switches
-- DaylightUI also has, asked once, given back from its page).
-- Through the palette: DaylightUI's window ground for Polestar's navy (bg, scrim, shade: the
-- header fades of its nav alerts, rare toasts, Guide End, Route Choice, Welcome and What's New,
-- the zone-art fades, the world map's info bar), picked rows in the accent (selected).
-- Through its paint: windows and the popups that stand alone (PolestarMenu, which holds every
-- dropdown's list and the minimap button's menu; PolestarLootNeeds; the gamepad hint bar) wear
-- DaylightUI's shell; panels inside a window keep Polestar's raised ground.
-- Hooked: the level-gain panel (LevelTip.Show) gets the shell; the "Polestar" game menu button
-- (after each GameMenu.Mirror) gets DaylightUI's button look; the minimap button's round back is
-- hidden while DaylightUI's drawer holds it. Left alone on purpose: where the world map's info
-- bar (PolestarMapInfo) sits and whether it shows, and Polestar's optional minimap coordinates.
-- (Checked against Polestar 0.4.3.1.) The guide window's edge tabs and its side strip are drawn
-- in DaylightUI's tab look, open on the side that meets the window, the picked one in the
-- accent, instead of a whole window shell each; a toast or tracker border set in Polestar's own
-- settings stays off under the shell (it was put back after every paint); and Polestar Arcade's
-- Tetris window (PolestarTetrisFrame) wears the shell, its buttons and words dressed, from its
-- first opening (PolestarTetrisAPI.Open). Its board and blocks keep their own colors.
local _, ns = ...
if not ns.ok then return end

local L = ns.L

ns.Target("Polestar", "Polestar", { window = true, text = true, colors = true, font = "daylight",
	note = L["The Daylight UI look goes on Polestar's own \"Polestar\" skin only. Its other looks (Vellum, Beacon and the rest) are yours to use and stay as Polestar draws them."],
	extraTab = "DaylightUI", extra = function() return { ns.HandoverGroup("Polestar") } end })

local P = _G.Polestar
local T = type(P) == "table" and P.Theme
if type(T) ~= "table" or type(T.Palette) ~= "function" or type(T.Refresh) ~= "function"
	or type(T.SkinKey) ~= "function" or type(T.SkinId) ~= "function" or type(T.SKIN_PAINT) ~= "table"
	or type(T.Paint) ~= "table" or type(T.Paint.house) ~= "table" or type(T.Paint.house.window) ~= "function" then
	return
end

local KEY = "Polestar"

-- Its house look itself, not a skin built on it (since 0.4.0 its added skins, Vellum, Beacon and
-- the rest, all extend the house look, so SkinKey says "polestar" for them too).
local function House()
	local ok, id = pcall(T.SkinId)
	return ok and id == "polestar"
end

local function On()
	return ns.Enabled(KEY) and House()
end

-- ---------------------------------------------------------------------------------------------
-- Palette: the resolved table is new after every refresh, and is written over once each time
-- ---------------------------------------------------------------------------------------------

local function Set(p, name, r, g, b, a)
	local old = p[name]
	p[name] = { r, g, b, a or (type(old) == "table" and old[4]) or 1 }
end

local function Overlay(p)
	local colors = ns.Colors()
	local ar, ag, ab = ns.AccentOf(KEY)
	local value, text, off = colors.VALUE, colors.TEXT, colors.OFF


	-- Text ladder and what follows it (Polestar's own text colors when the player said so).
	if ns.Look(KEY, "daylightColors") ~= false then
		for _, name in ipairs({ "text", "title", "buttonText", "rowLabel", "iconHover" }) do
			Set(p, name, value[1], value[2], value[3], 1)
		end
		for _, name in ipairs({ "textDim", "icon", "tabRest", "navRest" }) do
			Set(p, name, text[1], text[2], text[3], 1)
		end
		for _, name in ipairs({ "textMuted", "textOff" }) do
			Set(p, name, off[1], off[2], off[3], 1)
		end
	end

	-- Accent and what Polestar derives from it.
	if ar then
		Set(p, "accent", ar, ag, ab, 1)
		Set(p, "todo", ar, ag, ab, 1)
		Set(p, "accentLine", ar, ag, ab, 0.35)
		Set(p, "padSelect", ar, ag, ab, 0.12)
		Set(p, "chipAccent", ar, ag, ab, 0.16)
		-- A picked row (the rail, Lookup, the guide menu, the lists) in the accent, not white.
		Set(p, "selected", ar, ag, ab, 0.14)
		local light = 0.2126 * ar + 0.7152 * ag + 0.0722 * ab
		if light > 0.55 then Set(p, "onAccent", 0.05, 0.05, 0.06, 1) else Set(p, "onAccent", 1, 1, 1, 1) end
		-- The waypoint arrow follows the accent (and "good" up close), unless the player picked
		-- their own arrow colors in Polestar.
		local get = type(P.Get) == "function" and P.Get or nil
		local okFar, far = pcall(function() return get and get("nav.arrowColor") end)
		if not (okFar and type(far) == "table") then
			Set(p, "arrow", ar, ag, ab, 1)
			Set(p, "arrowText", ar, ag, ab, 1)
		end
		local good = colors.GOOD
		local okNear, near = pcall(function() return get and get("nav.arrowNearColor") end)
		if type(good) == "table" and not (okNear and type(near) == "table") then
			Set(p, "arrowNear", good[1], good[2], good[3], 1)
			Set(p, "arrowNearText", good[1], good[2], good[3], 1)
		end
	end

	-- The shell's columns and header band are square fills that would cover DaylightUI's rounded
	-- shell: clear, the way Polestar's own Halo look has them.
	for _, name in ipairs({ "sidebar", "footer", "sky" }) do
		local c = p[name]
		if type(c) == "table" then p[name] = { c[1], c[2], c[3], 0 } end
	end
	-- The window ground (DaylightUI's own, #141417) and the darker one under text on zone art,
	-- in place of Polestar's navy: the header fades of its alerts, toasts, Guide End, Route
	-- Choice, Welcome and What's New, the zone-art fades and the world map's info bar.
	Set(p, "bg", 0.078, 0.078, 0.090)
	Set(p, "scrim", 0.035, 0.035, 0.04)
	Set(p, "shade", 0, 0, 0)
	-- Raised panels, menus and controls: neutral darks that sit on any dark ground.
	Set(p, "panel", 0.075, 0.075, 0.085, 0.98)
	Set(p, "menuBg", 0.075, 0.075, 0.085, 0.98)
	Set(p, "panelAlt", 0.13, 0.13, 0.145, 1)
	Set(p, "control", 0.13, 0.13, 0.145, 1)
end

local origPalette, lastPalette = T.Palette, nil
T.Palette = function()
	local p = origPalette()
	if p ~= lastPalette then
		lastPalette = p
		if type(p) == "table" and p.skinId == "polestar" and ns.Enabled(KEY) then pcall(Overlay, p) end
	end
	return p
end

-- ---------------------------------------------------------------------------------------------
-- Font and header band
-- ---------------------------------------------------------------------------------------------

if type(T.FontSpec) == "function" then
	local origFontSpec = T.FontSpec
	-- (Its second argument, since 0.4.1: the text size of a window with its own, the guide
	-- window's ui.guideTextSize through Theme.TextScope. Passed on, or that size is lost.)
	T.FontSpec = function(role, ...)
		local path, size, flags = origFontSpec(role, ...)
		if not ns.PlainText(KEY) and On() then return ns.FontFor(KEY, path, size, flags) end
		return path, size, flags
	end
end

if type(T.ShowsBand) == "function" then
	local origShowsBand = T.ShowsBand
	T.ShowsBand = function(...)
		if On() then return false end
		return origShowsBand(...)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Window paint: DaylightUI's shell in place of Polestar's flat ground, border and shadow
-- ---------------------------------------------------------------------------------------------

local shelled = setmetatable({}, { __mode = "k" })   -- frame -> "on" | "bare"
local BARE = { noBorder = true, noBackground = true, noBevel = true }

local function HideHouse(f)
	local d = f.psSkin
	if type(d) == "table" and d.bg then d.bg:Hide() end
	-- (Since 0.4.0 the house look also draws a top light and contact lines round a window.)
	if type(d) == "table" and type(d.edge) == "table" then
		for i = 1, #d.edge do
			if ns.Usable(d.edge[i]) then d.edge[i]:Hide() end
		end
	end
	if type(T.Paint.hideBorder) == "function" then pcall(T.Paint.hideBorder, f) end
	if f.psShadow then f.psShadow:Hide() end
end

local house = T.Paint.house.window

-- A skin built on the house look (Theme.SkinKey "polestar", another skin id): Polestar's own
-- paint, and our shell off where it was on.
local function Unshell(f)
	if shelled[f] == "on" then
		shelled[f] = "bare"
		ns.Shell(f, BARE, KEY)
	end
end

-- The guide window's edge tabs and its side strip (UI/TabStyles/TabStyles.lua, 0.4.3: each painted
-- as a window of its own, f.psFootOf() naming the side that meets the window: 1 top, 2 bottom,
-- 3 left, 4 right). A whole window shell on each made a row of separate boxes; they wear
-- DaylightUI's tab look instead (Kit's lite "tab" shell: four edges and a ground, its edges in the
-- same order), that side left open so each runs into the window, the picked tab's edge in the
-- accent. The transparent guide window (psBare): none of it.
local tabShells = setmetatable({}, { __mode = "k" })   -- tab or strip -> its tab look

local function TabOff(f)
	local s = tabShells[f]
	if not s then return end
	for i = 1, 4 do s.edges[i]:Hide() end
	s.bg:Hide()
end

local function Tab(f)
	local Kit = ns.Kit
	if not Kit or type(Kit.Shell) ~= "function" or type(Kit.Paint) ~= "function" then return false end
	-- (Laid out again on every paint: the window's own opacity, which Polestar copies on, psBgAlpha.)
	local s = Kit.Shell(f, "tab", { bgAlpha = f.psBgAlpha })
	if type(s) ~= "table" or type(s.edges) ~= "table" or #s.edges < 4 or not ns.Usable(s.bg) then return false end
	tabShells[f] = s
	HideHouse(f)
	local okFoot, foot = pcall(f.psFootOf)
	if not okFoot then foot = nil end
	local bare = f.psBare and true or false
	for i = 1, 4 do s.edges[i]:SetShown(not bare and i ~= foot) end
	s.bg:SetShown(not bare)
	if f.psActive then
		ns.LightShell(s, { ns.AccentOf(KEY) }, KEY)
	else
		Kit.Paint(s, Kit.TAB_BORDER)
	end
	if shelled[f] == "on" then
		shelled[f] = "bare"
		ns.Shell(f, BARE, KEY)
	end
	return true
end

local function Window(f)
	if not ns.Enabled(KEY) then
		TabOff(f)
		return house(f)
	end
	if not House() then
		Unshell(f)
		TabOff(f)
		return house(f)
	end
	if type(f.psFootOf) == "function" and Tab(f) then return end
	-- The transparent guide window: no ground at all.
	if f.psBare then
		house(f)
		if shelled[f] == "on" then
			shelled[f] = "bare"
			ns.Shell(f, BARE, KEY)
		end
		return
	end
	HideHouse(f)
	if shelled[f] ~= "on" then
		shelled[f] = "on"
		ns.Shell(f, { window = true, bgAlpha = f.psBgAlpha }, KEY)
	end
end

T.SKIN_PAINT.polestar = T.SKIN_PAINT.polestar or {}
T.SKIN_PAINT.polestar.window = function(f)
	local ok, err = pcall(Window, f)
	if not ok then
		geterrorhandler()(err)
		house(f)
	end
end

-- Panel paint: the popups that stand on their own (every dropdown's list and the minimap
-- button's menu in PolestarMenu, the party loot list, the gamepad hint bar) wear DaylightUI's
-- shell; the panels inside a window keep Polestar's raised ground.
local housePanel = T.Paint.house.panel
local POPUPS = { PolestarMenu = true, PolestarLootNeeds = true }

local function Popup(f)
	-- (Its menus and dropdown lists, wherever they sit: the settings window's search results too.)
	if f.psMenu then return true end
	local name = f.GetName and f:GetName()
	if name and POPUPS[name] then return true end
	local parent = f.GetParent and f:GetParent()
	return parent ~= nil and (parent == UIParent or parent == P.UIParent)
end

local POPUP_SHELL = { window = true, bgAlpha = 0.98 }

local function Panel(f)
	if not ns.Enabled(KEY) then return housePanel(f) end
	if not House() then
		Unshell(f)
		return housePanel(f)
	end
	if not Popup(f) then return housePanel(f) end
	if f.psBare then
		housePanel(f)
		if shelled[f] == "on" then
			shelled[f] = "bare"
			ns.Shell(f, BARE, KEY)
		end
		return
	end
	HideHouse(f)
	if shelled[f] ~= "on" then
		shelled[f] = "on"
		ns.Shell(f, POPUP_SHELL, KEY)
	end
end

if type(housePanel) == "function" then
	T.SKIN_PAINT.polestar.panel = function(f)
		local ok, err = pcall(Panel, f)
		if not ok then
			geterrorhandler()(err)
			housePanel(f)
		end
	end
end

-- The level-gain panel (a route's "+1.3 levels" chip, hovered): Polestar's square edge and
-- ground off, DaylightUI's shell on. Made on the first hover.
local tip
local function TipLook(on)
	if not tip then return end
	if tip.Edge then tip.Edge:SetShown(not on) end
	if tip.Ground then tip.Ground:SetShown(not on) end
end

local LevelTip = type(P.UI) == "table" and P.UI.LevelTip
if type(LevelTip) == "table" and type(LevelTip.Show) == "function" and type(LevelTip.Frame) == "function" then
	ns.HookOnce(LevelTip, "Show", function()
		if not On() then return end
		local f = LevelTip.Frame()
		if not ns.Usable(f) then return end
		tip = f
		if shelled[f] ~= "on" then
			shelled[f] = "on"
			TipLook(true)
			ns.Shell(f, POPUP_SHELL, KEY)
		end
	end, KEY)
end

-- Another Polestar look picked: take the shell back off the windows it was on.
if type(T.OnChanged) == "function" then
	T.OnChanged(function()
		if House() then return end
		for f, state in pairs(shelled) do
			if state == "on" and ns.Usable(f) then
				shelled[f] = "bare"
				ns.Shell(f, BARE, KEY)
				if f == tip then TipLook(false) end
			end
		end
		for f in pairs(tabShells) do TabOff(f) end
	end)
end

-- A toast's or tracker's own border (Polestar's settings: a border color or thickness for its
-- rare, transport, while-here and heads-up cards and its trackers, UI/Toasts.lua PaintGround) is
-- drawn after every paint of the frame (its frame.psAfterPaint), over the shell. Its own step is
-- kept and the border taken off again right after it, while the shell is on the frame.
local Toasts = type(P.UI) == "table" and P.UI.Toasts or nil
if type(Toasts) == "table" and type(Toasts.PaintGround) == "function" and type(T.Paint.hideBorder) == "function" then
	local afterOf = setmetatable({}, { __mode = "k" })   -- frame -> { own = its step, fn = ours }
	local function BorderOff(f)
		if shelled[f] == "on" and On() then pcall(T.Paint.hideBorder, f) end
	end
	ns.HookOnce(Toasts, "PaintGround", function(f)
		if type(f) ~= "table" then return end
		local after = f.psAfterPaint
		if type(after) ~= "function" then return end
		local a = afterOf[f]
		if not a then
			a = {}
			a.fn = function(x)
				a.own(x)
				BorderOff(x)
			end
			afterOf[f] = a
		end
		-- (It sets its own step again on every call: ours wraps the newest.)
		if after ~= a.fn then
			a.own = after
			f.psAfterPaint = a.fn
		end
		BorderOff(f)
	end, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- The "Polestar" button in the game menu (Esc)
-- ---------------------------------------------------------------------------------------------

-- Polestar's button copies the look of the menu button above it each time the menu opens
-- (GameMenu.Mirror): with DaylightUI's menu that means a grey box of its own, white edge lines
-- and a white hover over it, and the alphas of its neighbour's pieces put on its own. It wears
-- DaylightUI's button look instead, like the menu's other buttons, put right after every copy.
local GameMenu = type(P.UI) == "table" and P.UI.GameMenu or nil
local MENU_ART = { "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }
local MENU_PARTS = { "Left", "Middle", "Right", "Center" }
local menuKit = setmetatable({}, { __mode = "k" })   -- button -> { texture = true } of Kit's look
local menuLit = setmetatable({}, { __mode = "k" })   -- button -> its lit line's color as Kit made it

local function KitPieces(s)
	local mine = {}
	for _, k in ipairs({ "outline", "band", "fill", "lit" }) do
		if type(s[k]) == "table" then mine[s[k]] = true end
	end
	local tr = s.trace
	if type(tr) == "table" then
		for _, k in ipairs({ "top", "right", "left", "bottom" }) do
			if type(tr[k]) == "table" then mine[tr[k]] = true end
		end
		if type(tr.gleams) == "table" then
			for i = 1, #tr.gleams do mine[tr.gleams[i]] = true end
		end
	end
	return mine
end

local function MenuRegions(mine, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if r and r.GetObjectType and r:GetObjectType() == "Texture" then
			if mine[r] then
				r:SetAlpha(1)
			elseif r:GetDrawLayer() == "HIGHLIGHT" then
				ns.Kill(r)   -- Polestar's white hover (and the template's)
			end
		end
	end
end

local function MenuChildren(...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		-- Polestar's own box behind the label: an unnamed frame of its own.
		if ns.Usable(c) and c:GetObjectType() == "Frame" and not c:GetName() then ns.Kill(c) end
	end
end

local function MenuButton()
	if not ns.Enabled(KEY) then return end
	local Kit = ns.Kit
	local b = GameMenu.Button()
	if not Kit or not ns.Usable(b) then return end
	if ns.Controls(KEY) and ns.Once(b) then ns.Guard(Kit.Button, b) end
	local s = type(Kit.ButtonOf) == "function" and Kit.ButtonOf(b) or nil
	if type(s) ~= "table" then return end
	local mine = menuKit[b]
	if not mine then
		mine = KitPieces(s)
		menuKit[b] = mine
		if s.lit and s.lit.GetVertexColor then menuLit[b] = { s.lit:GetVertexColor() } end
	end
	-- The template's art, as Kit.Button hides it (the copy may have put it back).
	for _, get in ipairs(MENU_ART) do
		if b[get] then Kit.Hide(b[get](b)) end
	end
	local name = b:GetName()
	for _, k in ipairs(MENU_PARTS) do
		Kit.Hide(b[k])
		if name then Kit.Hide(_G[name .. k]) end
	end
	MenuRegions(mine, b:GetRegions())
	MenuChildren(b:GetChildren())
	local lit = menuLit[b]
	if lit and s.lit then s.lit:SetVertexColor(lit[1], lit[2], lit[3], lit[4]) end
	if type(s.Paint) == "function" then s.Paint() end
end

if type(GameMenu) == "table" and type(GameMenu.Mirror) == "function" and type(GameMenu.Button) == "function" then
	-- (An error in it is put down against Polestar's pack by ns.HookOnce.)
	ns.HookOnce(GameMenu, "Mirror", function() MenuButton() end, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- The minimap button: its round dark back off while DaylightUI's drawer (or another collector)
-- holds it in a square cell of its own; back on when it is on the minimap's edge again.
-- ---------------------------------------------------------------------------------------------

local function BackOf(btn, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if r and r.GetObjectType and r:GetObjectType() == "Texture" and r ~= btn.Icon and r:GetDrawLayer() == "BACKGROUND" then
			return r
		end
	end
end

ns.Watch(KEY, "PolestarMinimapButton", function(btn)
	if not ns.Usable(btn) or not ns.Once(btn) then return end
	local back = BackOf(btn, btn:GetRegions())
	if not back then return end
	local function Fit()
		if not ns.Enabled(KEY) then return end
		back:SetShown(btn:GetParent() == _G.Minimap)
	end
	ns.HookOnce(btn, "SetParent", Fit, KEY)
	Fit()
end)

-- The button is made at login, or later when the player first turns it on in Polestar's settings
-- (Maps.RefreshMinimapButton): looked for right after that call, in the frame it is made.
local Maps = P.Maps
if type(Maps) == "table" and type(Maps.RefreshMinimapButton) == "function" then
	ns.HookOnce(Maps, "RefreshMinimapButton", function() ns.WatchNow() end, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- Polestar Arcade's Tetris (Polestar_Arcade, load-on-demand: loaded when Play is pressed). Its
-- window (PolestarTetrisFrame, games/tetris/Window.lua) is a tooltip-bordered backdrop of its own,
-- not drawn by Polestar's theme, made on its first opening (PolestarTetrisAPI.Open, which every
-- way in calls: the flight card, /polestar tetris, the guide menu): dressed right after that call,
-- before it's drawn. Its backdrop off and DaylightUI's shell on, its three buttons (Pause / Resume /
-- New Game, New Game, Close: the game's panel button template) in DaylightUI's button look, its
-- words in the player's font, the game's gold in DaylightUI's inks (its title in the title ink).
-- Its board, ghost and preview cells keep their own colors (the game itself).
-- ---------------------------------------------------------------------------------------------

local function TetrisInk(f)
	if ns.Look(KEY, "daylightColors") == false or type(ns.Ink) ~= "function" then return end
	for _, r in ipairs({ f:GetRegions() }) do
		if ns.Usable(r) and r:GetObjectType() == "FontString" then
			local cr, cg, cb = r:GetTextColor()
			if type(cr) == "number" and math.abs(cr - 1) < 0.02 and math.abs(cg - 0.82) < 0.02 and cb < 0.03 then
				-- (Its title is the one string in the top row; the rest are its labels and readouts.)
				local _, _, _, _, y = r:GetPoint(1)
				ns.Ink(r, (type(y) == "number" and y > -20) and "TITLE" or "TEXT")
			end
		end
	end
end

local function Tetris()
	local f = _G.PolestarTetrisFrame
	if not ns.Usable(f) or not ns.Kit or not ns.Once(f) then return end
	ns.NoBackdrop(f)
	ns.Shell(f, { window = true }, KEY)
	TetrisInk(f)
	-- (Its buttons are made with it; fonts: every label in the player's font, again on each show.)
	ns.DressOnShow(f, { fonts = true }, nil, KEY)
end

ns.OnLoad("Polestar_Arcade", function()
	local api = _G.PolestarTetrisAPI
	if type(api) ~= "table" or type(api.Open) ~= "function" then return end
	ns.HookOnce(api, "Open", Tetris, KEY)
	-- (Opened already before this pack's hook, after a reload with the Arcade loaded.)
	if ns.Enabled(KEY) then ns.Guard(Tetris) end
end)

-- Windows made before this file ran (the guide window) are repainted at login, and everything
-- follows when the DaylightUI look changes. One repaint a frame at most, however many asked.
local queued = false
local function Run()
	queued = false
	pcall(T.Refresh)
end
local function Refresh()
	if queued then return end
	queued = true
	C_Timer.After(0, Run)
end

ns.me.On("StyleChanged", Refresh)
ns.me.On("Login", Refresh)
-- A setting of this plugin's that Polestar is painted from: its switch, its own page, or the
-- switch for all windows. The others (another addon's page) are none of its business.
ns.me.On("SettingChanged", function(scope, path)
	if scope ~= "DaylightAddonSkins" or type(path) ~= "string" then return end
	if path == KEY or path == "followDaylight" or string.sub(path, 1, 14) == "look.Polestar." then Refresh() end
end)

-- ---------------------------------------------------------------------------------------------
-- Hand-over: its quality-of-life switches DaylightUI also has (Polestar 0.4.1, QoL/QoL.lua).
-- Its auto accept and turn in of the guide's quests too (DaylightUI's take every quest, the
-- guide's among them), and (0.4.1) its finished quests' XP on the game's XP bar, which DaylightUI's
-- own XP bar shows while it hides the game's. (0.4.1.1, DUI 1.9.4) Its zone level ranges on the world map too:
-- DaylightUI's Zone Levels show the hovered zone's range by its name, from other numbers; handing
-- them over also takes Polestar's labels on continent maps, which DaylightUI has no copy of. Its flight
-- timer too (checked against Polestar 0.4.1.1 and DUI 1.9.6: both showed on a flight). Left out: its other guide-only work (the step's
-- gossip, target list, route vendors, Restock), which DaylightUI has no copy of. Its settings
-- are per Polestar profile, so a handed-over value follows the profile in use.
-- ---------------------------------------------------------------------------------------------

if type(P.Get) == "function" and type(P.Set) == "function" then
	local has = ns.DaylightHas
	local PATH = {
		sellJunk = "qol.sellJunk", autoRepair = "qol.autoRepair", fastLoot = "qol.fastLoot",
		skipGossip = "qol.skipGossip", hideErrors = "qol.hideErrors", flightAutoOpen = "qol.flightAutoOpen",
		questXPOverlay = "qol.questXPOverlay",
		zoneLevels = "maps.zoneLevels",
		flightTimer = "maps.flightTimer",
		autoAccept = "behavior.autoAccept", autoTurnin = "behavior.autoTurnin",
	}
	ns.Handover(KEY, {
		ready = function() return type(_G.PolestarDB) == "table" end,
		get = function(key) return P.Get(PATH[key]) end,
		set = function(key, value) P.Set(PATH[key], value) end,
		list = {
			{ key = "sellJunk", label = L["Sell Junk at Vendors"], daylight = ns.In(L["sell junk"], "Bags"),
			  ours = function() return has("Bags", "sellJunk") end },
			{ key = "autoRepair", label = L["Repair at Vendors"], daylight = ns.In(L["auto repair"], "Bags"),
			  ours = function() return has("Bags", "autoRepair") end },
			{ key = "fastLoot", label = L["Faster Looting"], daylight = ns.In(L["fast loot"], "Quality of Life"),
			  ours = function() return has("QoL", "fastLoot") end },
			{ key = "skipGossip", label = L["Pick an NPC's Only Gossip Option"],
			  daylight = ns.In(L["skip gossip"], "Quality of Life"),
			  ours = function() return has("QoL", "skipGossip") end },
			{ key = "hideErrors", label = L["Hide Error Messages"],
			  daylight = ns.In(L["quiet errors and its own error text"], "Quality of Life"),
			  ours = function() return has("QoL", "quietErrors") or has("QoL", "errorText") end },
			{ key = "autoAccept", label = L["Accept the Guide's Quests Automatically"],
			  daylight = ns.In(L["auto accept"], "Quality of Life"),
			  ours = function() return has("QoL", "questAccept") end },
			{ key = "autoTurnin", label = L["Turn in the Guide's Quests Automatically"],
			  daylight = ns.In(L["auto turn in"], "Quality of Life"),
			  ours = function() return has("QoL", "questTurnIn") end },
			{ key = "flightAutoOpen", label = L["Open the Flight Map at Once"],
			  daylight = ns.In(L["its NPC window and skip-gossip"], "Quality of Life"),
			  ours = function() return has("NPC", "enabled") or has("QoL", "skipGossip") end },
			{ key = "questXPOverlay", label = L["Quest XP on the Game's Experience Bar"],
			  daylight = ns.In(L["its experience bar with banked quest XP"], "Info Panel"),
			  ours = function() return has("InfoPanel", "xp.enabled") end },
			{ key = "zoneLevels", label = L["Zone Level Ranges on the World Map"],
			  daylight = ns.In(L["zone levels"], "Window Skins"),
			  ours = function() return has("Skins", "mapLevels") end },
			-- (Daylight UI 1.9.6: its flight timer is a banner over the world with the route and a welcome
			-- on landing; Polestar's own (Maps/FlightTimer.lua, maps.flightTimer, read on every tick)
			-- showed with it on every flight.)
			{ key = "flightTimer", label = L["Flight Timer"], daylight = ns.In(L["the flight timer"], "Quality of Life"),
			  ours = function() return has("QoL", "flightTimer") end },
		},
	})
end
