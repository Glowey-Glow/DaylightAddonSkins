-- Polestar: it paints everything from one theme (Polestar.Theme) and repaints on Theme.Refresh(),
-- so the theme is fed rather than its frames touched: DaylightUI's shell as its window paint, the
-- player's font, accent and text colors in its palette. Only its house look ("polestar") is
-- changed; pick another look in Polestar's own options and it is left as Polestar draws it.
-- Nothing is written to Polestar's saved settings.
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

-- Another Polestar look picked: take the shell back off the windows it was on.
if type(T.OnChanged) == "function" then
	T.OnChanged(function()
		local ok, key = pcall(T.SkinKey)
		if ok and key == "polestar" then return end
		for f, state in pairs(shelled) do
			if state == "on" and ns.Usable(f) then
				shelled[f] = "bare"
				ns.Shell(f, BARE, KEY)
			end
		end
	end)
end

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
