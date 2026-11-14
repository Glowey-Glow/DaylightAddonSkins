-- Polestar: it paints everything from one theme (Polestar.Theme) and repaints on Theme.Refresh(),
-- so the theme is fed rather than its frames touched: DaylightUI's shell as its window paint, the
-- player's font, accent and text colors in its palette. Only its house look ("polestar") is
-- changed; pick another look in Polestar's own options and it is left as Polestar draws it.
-- Nothing is written to Polestar's saved settings.
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
local _, ns = ...
if not ns.ok then return end

ns.Target("Polestar", "Polestar", { window = true, text = true, colors = true, font = "daylight" })

local P = _G.Polestar
local T = type(P) == "table" and P.Theme
if type(T) ~= "table" or type(T.Palette) ~= "function" or type(T.Refresh) ~= "function"
	or type(T.SkinKey) ~= "function" or type(T.SKIN_PAINT) ~= "table"
	or type(T.Paint) ~= "table" or type(T.Paint.house) ~= "table" or type(T.Paint.house.window) ~= "function" then
	return
end

local API = ns.API
local KEY = "Polestar"

local function On()
	if not ns.Enabled(KEY) then return false end
	local ok, key = pcall(T.SkinKey)
	return ok and key == "polestar"
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
	local ar, ag, ab = API.Accent()
	local value, text, off = colors.VALUE, colors.TEXT, colors.OFF

	-- The player's own accent for Polestar, when they picked one on its page.
	if ns.Look(KEY, "daylightAccent") == false then
		local own = ns.Look(KEY, "accent")
		if type(own) == "table" and type(own[1]) == "number" and type(own[2]) == "number" and type(own[3]) == "number" then
			ar, ag, ab = own[1], own[2], own[3]
		end
	end

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
		if type(p) == "table" and p.skin == "polestar" and ns.Enabled(KEY) then pcall(Overlay, p) end
	end
	return p
end

-- ---------------------------------------------------------------------------------------------
-- Font and header band
-- ---------------------------------------------------------------------------------------------

if type(T.FontSpec) == "function" then
	local origFontSpec = T.FontSpec
	T.FontSpec = function(role)
		local path, size, flags = origFontSpec(role)
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
	if type(T.Paint.hideBorder) == "function" then pcall(T.Paint.hideBorder, f) end
	if f.psShadow then f.psShadow:Hide() end
end

local house = T.Paint.house.window

local function Window(f)
	if not ns.Enabled(KEY) then return house(f) end
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
	local name = f.GetName and f:GetName()
	if name and POPUPS[name] then return true end
	local parent = f.GetParent and f:GetParent()
	return parent ~= nil and (parent == UIParent or parent == P.UIParent)
end

local POPUP_SHELL = { window = true, bgAlpha = 0.98 }

local function Panel(f)
	if not ns.Enabled(KEY) or not Popup(f) then return housePanel(f) end
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
	hooksecurefunc(LevelTip, "Show", function()
		if not On() then return end
		local f = LevelTip.Frame()
		if not ns.Usable(f) then return end
		tip = f
		if shelled[f] ~= "on" then
			shelled[f] = "on"
			TipLook(true)
			ns.Shell(f, POPUP_SHELL, KEY)
		end
	end)
end

-- Another Polestar look picked: take the shell back off the windows it was on.
if type(T.OnChanged) == "function" then
	T.OnChanged(function()
		local ok, key = pcall(T.SkinKey)
		if ok and key == "polestar" then return end
		for f, state in pairs(shelled) do
			if state == "on" and ns.Usable(f) then
				shelled[f] = "bare"
				ns.Shell(f, BARE, KEY)
				if f == tip then TipLook(false) end
			end
		end
	end)
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
	hooksecurefunc(GameMenu, "Mirror", function()
		local ok, err = pcall(MenuButton)
		if not ok then geterrorhandler()(err) end
	end)
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
	hooksecurefunc(btn, "SetParent", Fit)
	Fit()
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
