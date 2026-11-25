-- Forever Leveling BiS: the shells of its windows (the main window, My gear, Stat weights and its
-- dialogs, Quest details, Settings, What's new, the selectors' lists, the gear panel beside the
-- Character frame) and its text in the player's font.
-- It keeps its theme private, so it is followed from outside: every string it draws takes one of
-- five font objects of its own (ForeverLevelingBiSFont*), which get the player's font here each
-- time it sets them; and its windows are found by the flat backdrop its W.Window gives them.
-- Only its Modern theme is dressed: pick Classic or a skin in its own settings and it is left as
-- it draws it. It fixes its theme for the session (a change takes a reload), so the theme is read
-- once, after login, and kept until the reload too.
-- The selectors' list beside the Character frame is moved there on the first click of a selector
-- in the gear panel: the panel's buttons' clicks look for it straight after, so it's dressed
-- before it's drawn.
-- Left alone: its buttons, tabs, rows and selectors (it recolors them on every hover and pick),
-- its scroll bars, bubbles, tooltip lines and its accent, and its question boxes (W.Confirm's and
-- W.Coach's, with a pointer notch and a pulsing halo of their own; their ground is a window's, so
-- they're told apart by the marks the addon gives them and skipped).
-- Nothing is written to its saved settings.
local _, ns = ...
if not ns.ok then return end

ns.Target("ForeverLevelingBiS", "Forever Leveling BiS", { window = true, text = true, font = "daylight" })

-- Not loaded: nothing to look for (its windows, and the gear panel on DaylightUI's character
-- window, never come), so no watches or hooks are left waiting for them.
if not ns.AddonLoaded("ForeverLevelingBiS") then return end

local KEY = "ForeverLevelingBiS"
local abs = math.abs

-- Its theme, as the player set it (read only): a skin or Classic is left alone. It keeps the one
-- set when its first widget is made (its saved settings are in by then) until a reload: kept here
-- from the first read after login (a change in its settings before the reload isn't drawn yet).
local sessionModern
local function Modern()
	if sessionModern ~= nil then return sessionModern end
	local db = _G.ForeverLevelingBiSDB
	-- (No settings yet, a first install: its own default, the modern theme. The pack only runs
	-- with the addon loaded: the check at the top.)
	local theme = type(db) == "table" and type(db.display) == "table" and db.display.theme
	local modern = theme == nil or theme == "modern"
	if type(db) == "table" and IsLoggedIn() then sessionModern = modern end
	return modern
end

local function On()
	return ns.Enabled(KEY) and Modern()
end

-- ---------------------------------------------------------------------------------------------
-- Fonts: its five font objects. What it set on each is kept, and the look is laid over that, so a
-- change of its own text size, or of ours, never adds up.
-- ---------------------------------------------------------------------------------------------

local FONTS = { "FontNormal", "FontNormalLarge", "FontNormalSmall", "FontHighlightSmall", "FontDisableSmall" }
local own = {}       -- font object -> { path, size, flags } as it set them
local busy = false

local function Restyle(font)
	local o = own[font]
	if not o or not o[1] or not o[2] then return end
	busy = true
	local ok, err = pcall(function()
		if On() and not ns.PlainText(KEY) then
			local path, size, flags = ns.FontFor(KEY, o[1], o[2], o[3])
			font:SetFont(path, size, flags or "")
		else
			font:SetFont(o[1], o[2], o[3] or "")
		end
	end)
	busy = false
	if not ok then geterrorhandler()(err) end
end

for _, name in ipairs(FONTS) do
	local font = _G["ForeverLevelingBiS" .. name]
	if type(font) == "table" and font.GetFont and font.SetFont then
		own[font] = { font:GetFont() }
		-- (Hooked directly, not through ns.HookOnce: it keeps the addon's own font even while this
		-- pack is off, for the switch to put back.)
		hooksecurefunc(font, "SetFont", function(self, path, size, flags)
			if busy then return end
			own[self] = { path, size, flags }
			Restyle(self)
		end)
	end
end

local function RestyleAll()
	for font in pairs(own) do Restyle(font) end
end

-- ---------------------------------------------------------------------------------------------
-- Windows: a Frame with W.Window's flat backdrop (a one-pixel WHITE8X8 border round its window
-- color, 0.06 / 0.06 / 0.08), or the selectors' lists' (0.05 gray).
-- ---------------------------------------------------------------------------------------------

local WHITE = "interface\\buttons\\white8x8"

local function Near(r, g, b, R, G, B)
	return r and abs(r - R) < 0.006 and abs(g - G) < 0.006 and abs(b - B) < 0.006
end

-- "window", "list" or nil.
local function Kind(f)
	if not ns.Usable(f) or f:GetObjectType() ~= "Frame" or not f.GetBackdrop then return nil end
	-- Its question boxes (left alone: see the top).
	if f.isConfirm or f.isCoach then return nil end
	local bd = f:GetBackdrop()
	if type(bd) ~= "table" or bd.edgeSize ~= 1 or type(bd.bgFile) ~= "string" or bd.bgFile:lower() ~= WHITE then
		return nil
	end
	local w, h = f:GetSize()
	if not w or w < 80 or not h or h < 40 then return nil end   -- tags and chips, not windows
	local r, g, b = f:GetBackdropColor()
	-- (Its window color since 1.3.2; the older one before.)
	if Near(r, g, b, 0.059, 0.067, 0.082) or Near(r, g, b, 0.06, 0.06, 0.08) then return "window" end
	if Near(r, g, b, 0.05, 0.05, 0.05) then return "list" end
	return nil
end

-- The title band W.TitleBand draws: a dark square strip a pixel inside the top, which would show
-- its corners on DaylightUI's rounded shell. The shell's own band takes its place.
-- Its titles: since 1.3.4 the band's title is painted its own soft gold (T.TITLE), once, as it is
-- made. They take DaylightUI's title ink instead, again when the look changes.
local titles = setmetatable({}, { __mode = "k" })
local function InkTitle(fs)
	local c = ns.Colors().VALUE
	if c and ns.Usable(fs) then fs:SetTextColor(c[1], c[2], c[3]) end
end
local function InkTitles()
	if not On() then return end
	for fs in pairs(titles) do InkTitle(fs) end
end

local function FadeBand(f)
	for _, region in ipairs({ f:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BORDER"
			and region:GetNumPoints() >= 1 then
			local point, rel, relPoint, x, y = region:GetPoint(1)
			local h = region:GetHeight()
			if point == "TOPLEFT" and rel == f and relPoint == "TOPLEFT" and x == 1 and y == -1
				and h and abs(h - 30) < 1 then
				region:SetAlpha(0)
				-- (Since 1.3.2 a faint rule runs under the band: it goes too. The title sits on the
				-- band, or on the icon W.TitleIcon puts at the band's start.)
				for _, r in ipairs({ f:GetRegions() }) do
					if ns.Usable(r) and r:GetNumPoints() >= 1 then
						local on = select(2, r:GetPoint(1))
						local kind = r:GetObjectType()
						if kind == "Texture" and on == region then
							r:SetAlpha(0)
						elseif kind == "FontString" and (on == region or (ns.Usable(on) and on.GetObjectType
							and on:GetObjectType() == "Texture" and on:GetNumPoints() >= 1
							and select(2, on:GetPoint(1)) == region)) then
							titles[r] = true
							InkTitle(r)
						end
					end
				end
			end
		end
	end
end

local dressed = setmetatable({}, { __mode = "k" })

-- A dialog laid over the whole of a window it sits in (Stat weights' editors): solid, or the
-- window under it shows through.
local function Overlay(f)
	local parent = f:GetParent()
	if not parent or not dressed[parent] then return false end
	local w, h = f:GetSize()
	local pw, ph = parent:GetSize()
	return w and pw and abs(w - pw) < 1 and abs(h - ph) < 1
end

local function Dress(f, kind)
	if dressed[f] then return end
	dressed[f] = kind
	ns.NoBackdrop(f)
	-- It may lay its backdrop on again: taken straight back off.
	local clearing = false
	ns.HookOnce(f, "SetBackdrop", function(self, info)
		if clearing or info == nil then return end
		clearing = true
		ns.NoBackdrop(self)
		clearing = false
	end, KEY)
	if kind == "list" then
		ns.Shell(f, { bgAlpha = 0.97 }, KEY)
	else
		FadeBand(f)
		if Overlay(f) then
			ns.Shell(f, { window = true, bgAlpha = 1 }, KEY)
		else
			ns.Shell(f, { window = true }, KEY)
		end
	end
end

-- Its windows among root and what is in it, `depth` levels down (parents first, so a dialog knows
-- its window is dressed).
local Scan
-- (The children as the game hands them back, with no table made: this runs after every click.)
local function ScanChildren(depth, ...)
	for i = 1, select("#", ...) do
		local child = select(i, ...)
		if ns.Usable(child) and child:GetObjectType() == "Frame" then Scan(child, depth) end
	end
end
function Scan(root, depth)
	if not ns.Usable(root) then return end
	local kind = not dressed[root] and Kind(root)
	if kind then Dress(root, kind) end
	if depth <= 0 or not root.GetChildren then return end
	ScanChildren(depth - 1, root:GetChildren())
end

local function Guarded(fn)
	return function(...) ns.Guard(fn, ...) end
end

-- The buttons in a window, `depth` levels down: a click on one looks again at once (after its own
-- click has run), for the panel, dialog or list it may just have made and opened, so that is
-- dressed before it's drawn.
local HookClicks
local function HookChildren(depth, look, ...)
	for i = 1, select("#", ...) do
		local child = select(i, ...)
		if ns.Usable(child) then
			if child:GetObjectType() == "Button" then
				ns.ScriptOnce(child, "OnClick", look, KEY)
			elseif depth > 0 then
				HookClicks(child, depth - 1, look)
			end
		end
	end
end
function HookClicks(f, depth, look)
	if ns.Usable(f) and f.GetChildren then HookChildren(depth, look, f:GetChildren()) end
end

-- Its side panels, dialogs and lists are made on their first open, while the window is up, by a
-- click on one of its buttons: each of them looks again straight after its click (and hooks the
-- buttons that click made). Also looked at once in the next update after any mouse button is let
-- go while it is shown (for one opened some other way, and to reach buttons made since); nothing
-- runs in between, and nothing at all while it is hidden. (Was a look twice a second while shown.)
local function Main(frame)
	if not On() then return end
	local Look
	local function Clicked()
		if On() then ns.Guard(Look) end
	end
	function Look()
		Scan(frame, 2)
		HookClicks(frame, 5, Clicked)
	end
	local soon = CreateFrame("Frame")
	soon:Hide()
	soon:SetScript("OnUpdate", function(self)
		self:Hide()
		if On() and frame:IsShown() then ns.Guard(Look) end
	end)
	local clicks = CreateFrame("Frame")
	clicks:SetScript("OnEvent", function() soon:Show() end)
	frame:HookScript("OnShow", Guarded(function()
		Look()
		clicks:RegisterEvent("GLOBAL_MOUSE_UP")
	end))
	frame:HookScript("OnHide", function() clicks:UnregisterEvent("GLOBAL_MOUSE_UP") end)
	Look()
	if frame:IsShown() then clicks:RegisterEvent("GLOBAL_MOUSE_UP") end
end

-- My gear beside the character window: on a holder of its own in the window in sight, the game's
-- Character frame or (since 1.3.2) DaylightUI's, which parks the game's frame where it never shows.
local function SheetOn(cf)
	if not ns.Usable(cf) or not cf.HookScript then return end
	local function Clicked()
		if On() then ns.Guard(Scan, cf, 2) end
	end
	local function Look()
		if not On() then return end
		Scan(cf, 2)
		-- The panel is the window on its holder (two down).
		for _, holder in ipairs({ cf:GetChildren() }) do
			if ns.Usable(holder) and holder:GetObjectType() == "Frame" and not holder:GetName() then
				for _, panel in ipairs({ holder:GetChildren() }) do
					if dressed[panel] == "window" then HookClicks(panel, 4, Clicked) end
				end
			end
		end
	end
	-- The panel is made and shown by its own hook on the window's showing, which runs before
	-- this one (it's put on when it loads): looked for right away, so it's dressed before it's
	-- drawn, and again a frame and half a second on, in case it comes up late.
	local function Shown()
		ns.Guard(Look)
		C_Timer.After(0, Guarded(Look))
		C_Timer.After(0.5, Guarded(Look))
	end
	cf:HookScript("OnShow", Shown)
	-- (Its holder moves over when DaylightUI's window is resized or its pages change.)
	cf:HookScript("OnSizeChanged", function() C_Timer.After(0, Guarded(Look)) end)
	if cf:IsShown() then C_Timer.After(0, Guarded(Look)) end
end

local function Sheet()
	SheetOn(_G.CharacterFrame)
end
-- (DaylightUI's character window is made as DaylightUI starts, at login.)
ns.Watch(KEY, "DaylightUICharacter", SheetOn)

-- Its main window and What's new are made on their first opening, by calls it keeps to itself.
-- What reaches them from outside is hooked: /bis (and its key binding, which runs /bis), the
-- addon compartment's entry and the minimap button, each looking at once after it has run, so
-- the window is dressed before it's drawn. What's new also opens a few seconds after login, by
-- a timer of its own, and the window from its other buttons and the wish list: those are found
-- by the watches, a frame late at most.
local function Opened() ns.WatchNow() end

ns.Watch(KEY, "ForeverLevelingBiSFrame", Main)
ns.Watch(KEY, "ForeverLevelingBiSWhatsNew", function(frame)
	if not On() then return end
	Scan(frame, 0)
	-- Its buttons (Open, and each change's "Try it now") may open the main window.
	HookClicks(frame, 3, Opened)
end)
-- The Wish list dock on the main window (1.3.2): by name, since folded it's too short for the scan.
-- From 1.4.3 the dock itself is a bare holder: the panel's look is on a face of its own (frame.face,
-- hidden while folded), and folded it is a small star tab with the wish count (frame.tab, a button
-- with the window's backdrop). Those two are dressed then, and the holder left bare (a shell on it
-- would double the face's, and sit behind the tab).
ns.Watch(KEY, "ForeverLevelingBiSWishDock", function(frame)
	if not On() then return end
	local face, tab = frame.face, frame.tab
	if ns.Usable(face) and face.GetBackdrop then
		Dress(face, "window")
		if ns.Usable(tab) and tab.GetBackdrop then Dress(tab, "window") end
	else
		Dress(frame, "window")
	end
end)
-- The wish list picker (1.5.0) opened from the on-screen tracker's title is put on the tracker
-- (WishLists.lua WS.ShowMenu, TopWindow), which no other watch reaches: looked for after that click.
ns.Watch(KEY, "ForeverLevelingBiSWishList", function(frame)
	if not On() or not ns.Usable(frame.pick) then return end
	ns.ScriptOnce(frame.pick, "OnClick", function() if On() then ns.Guard(Scan, frame, 1) end end, KEY)
end)
-- (The button is made at login.)
ns.Watch(KEY, "ForeverLevelingBiSMinimapButton", function(button)
	ns.ScriptOnce(button, "OnClick", Opened, KEY)
end)

local ok = false
ns.Pack(KEY, nil, function()
	if ok then return end
	ok = true
	Sheet()
	RestyleAll()
	local slash = _G.SlashCmdList
	if type(slash) == "table" and type(slash.FOREVERLEVELINGBIS) == "function" then
		ns.HookOnce(slash, "FOREVERLEVELINGBIS", Opened, KEY)
	end
	if type(_G.ForeverLevelingBiS_OnAddonCompartmentClick) == "function" then
		ns.HookOnce(nil, "ForeverLevelingBiS_OnAddonCompartmentClick", Opened, KEY)
	end
end)

-- Its text follows the DaylightUI font, and this plugin's page for it.
ns.me.On("Login", Guarded(RestyleAll))
ns.me.On("StyleChanged", Guarded(RestyleAll))
ns.me.On("StyleChanged", Guarded(InkTitles))
ns.me.On("SettingChanged", function(scope, path)
	if scope ~= "DaylightAddonSkins" or type(path) ~= "string" then return end
	if path == KEY or path == "followDaylight" or string.sub(path, 1, 24) == "look.ForeverLevelingBiS." then
		ns.Guard(RestyleAll)
	end
end)
