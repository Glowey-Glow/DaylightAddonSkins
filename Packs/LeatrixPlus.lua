-- Leatrix Plus: its options window, its 31 configuration panels and its own windows in the
-- DaylightUI look, and its switches DaylightUI also has handed over. Built against Leatrix Plus
-- 1.60.35 (Forever build: Leatrix_Plus.toc, Leatrix_Plus.lua, Leatrix_Plus.xml).
-- How its windows are found: Leatrix Plus keeps everything in file locals (LeaPlusLC, LeaPlusCB),
-- so nothing of it can be hooked, and its windows are frames on UIParent with a new random name
-- every session. It puts every window of its own in UISpecialFrames (so Escape closes it), and
-- that list is read here: each new entry whose frame Leatrix Plus made (region:GetSourceLocation
-- names its folder) is dressed on its first show, from a script hook that runs before it's drawn.
-- The list is looked at when this pack runs, a frame after login (its panels are made at
-- PLAYER_LOGIN), whenever one of its windows shows, and after a click when the list has changed
-- (GLOBAL_MOUSE_UP, its length and last name compared: the flight report, the recent chat window,
-- the help panel and the info card are made the first time they're wanted). Entries are known by
-- name, so one another addon takes out doesn't hide a later one. Nothing polls.
-- Dressed here:
--   * The options window and every configuration panel (CreatePanel): its dark ground, the
--     parchment bars (CreateBar) and the panel opacity it sets on each show give way to the window
--     shell; faint lines where the menu column and the button row met the parchment; titles in
--     the value ink; the old close X (UI-Panel-MinimizeButton) as DaylightUI's X.
--   * The page menu (MakeMN rows): the olive hover a faint white wash, the picked page's bar the
--     accent wash; the search results' olive hover a faint wash.
--   * Every control of the game's templates, by DaylightUI's walk (again on each show and each
--     page shown): buttons (UIPanelButtonTemplate, its own art on them too), checkboxes
--     (ChatConfigCheckButtonTemplate) as switches with their words in the text ink, sliders
--     (LeaPlusConfigurationPanelSliderTemplate) in the scroll bars' look, dropdowns
--     (WowStyle1DropdownTemplate) and their labels, edit boxes (InputBoxTemplate, its tooltip
--     border box off), scroll bars (MinimalScrollBar), its gold cogwheels in the label ink.
--   * Its dropdowns' lists (its own pop-up lists, not the game's menu): the shell, the gold tick in
--     the accent, the picked choice's words in the accent and the rest in the text ink, a faint
--     hover; the tabs on the minimap panels as DaylightUI's tabs; the blue list boxes (scrolling
--     panels, junk and mute lists) as insets, a gold-edged bar frame as a plain outline.
--   * Its own windows: the recent chat window, the flight time report and the help panel (their
--     ground, hairlines and gold accent line off, the shell on), the info card (its backdrop off,
--     the shell on; its inner layout kept). Their boxes' own fill and outline off: the recent
--     chat's search box and the one-line copy boxes as DaylightUI's input box, the flight
--     report's several-line report box as an inset well.
-- Kept as Leatrix Plus draws them: quality and class colors, item icons, the info card's inside,
-- the panel scale. Left alone on purpose: its minimap button bag (DaylightUI's drawer and the
-- minimap are the player's own setup), its developer map-pin tool on the world map, the game's
-- windows it changes (DaylightUI's and this plugin's game-window skins own those).
-- Taint: Leatrix Plus's frames are an addon's own; hooks only (script hooks on its frames), looks
-- only. Its panels' words in the player's font can be wider than it measured them.
-- Hand-over: its switches DaylightUI also has (asked once, DaylightUI by default, given back from
-- its page). Leatrix Plus reads its settings once, as it loads (ADDON_LOADED), and writes its live
-- copy back at logout (a PLAYER_LOGOUT handler it registers at PLAYER_LOGIN), so a change is kept
-- here (DaylightAddonSkinsDB.leatrixNext) and written into LeaPlusDB twice: at logout, by a
-- handler registered a moment after login so it runs after Leatrix Plus's write-back, and in
-- Leatrix Plus's ADDON_LOADED in case that logout was missed (this plugin loads first: keep
-- Leatrix_Plus out of the toc's OptionalDeps). The kept change is let go once a later load finds
-- LeaPlusDB already holding it. Every one takes a /reload. At logout a switch whose live value in
-- Leatrix Plus is neither the kept one nor what it ran with that session (changed or reset in
-- Leatrix Plus after the hand-over) is left as Leatrix Plus has it; one flipped back on in
-- Leatrix Plus in a later session stays on. When another addon loaded Leatrix Plus before this
-- plugin, it has read its settings already: nothing is handed over that session, and its page
-- says so.
local _, ns = ...
if not ns.ok then return end

local L = ns.L
local KEY = "Leatrix_Plus"
local FOLDER = "Leatrix_Plus"
-- Loaded before this file (another addon that needs it pulled it in first): too late to hand over.
local late = ns.AddonLoaded(FOLDER)
-- The hand-over switches; while it's too late, greyed out with the reason.
local function HandoverGroups()
	local group = ns.HandoverGroup(KEY)
	if late then
		local why = L["Another addon loaded Leatrix Plus before this plugin, so it had already read its settings: nothing can be handed over to Daylight UI this session. Leatrix Plus keeps its own."]
		for _, item in ipairs(group.items) do
			item.desc = why
			item.disabled = function() return true end
		end
	end
	return { group }
end
-- (Its words are the game's font objects: the player's font goes on all.)
local CAPS = { window = true, controls = true, text = true, shadow = true, font = "daylight",
	extraTab = "DaylightUI", extra = HandoverGroups }
ns.Target(KEY, "Leatrix Plus", CAPS)

local Usable = ns.Usable
local ipairs, type, select, pairs = ipairs, type, select, pairs

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end
local function Kind(x) return Usable(x) and x:GetObjectType() or nil end
local function IsTexture(x) return Kind(x) == "Texture" end

local function Ink(fs, name)
	if Kind(fs) ~= "FontString" then return end
	local c = ns.Colors()[name]
	if c then fs:SetTextColor(c[1], c[2], c[3]) end
end

-- A faint white wash in place of an olive or blue hover.
local function Wash(tex, alpha)
	if not IsTexture(tex) then return end
	tex:SetColorTexture(1, 1, 1, alpha)
	tex:SetBlendMode("BLEND")
end

-- fn(x) for each of ... (a frame's children or regions, as the game hands them back: no table).
local function Each_(fn, ...)
	for i = 1, select("#", ...) do fn((select(i, ...))) end
end

local dressed = setmetatable({}, { __mode = "k" })   -- windows dressed
local looked = setmetatable({}, { __mode = "k" })    -- pieces done (rows, boxes, cogs, lists)

-- ---------------------------------------------------------------------------------------------
-- Pieces
-- ---------------------------------------------------------------------------------------------

local GEAR
local function IsGear(tex)
	if not IsTexture(tex) then return false end
	GEAR = GEAR or ns.FileIDs({ ["Interface\\WorldMap\\Gear_64.png"] = true, ["Interface\\WorldMap\\Gear_64"] = true })
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return false end
	if type(file) == "string" then file = string.lower(file) end
	return GEAR[file] == true
end

-- A cogwheel (CfgBtn, CreateHelpButton): its gold in the label ink.
local function Cog(btn)
	if looked[btn] or Kind(btn) ~= "Button" or not IsGear(btn.t) then return end
	looked[btn] = true
	local c = ns.Colors().LABEL
	if c then btn.t:SetVertexColor(c[1], c[2], c[3], 1) end
end

-- The page menu's rows (MakeMN): hover a wash, the picked page's bar in the accent.
local picks = {}
local function PaintPicks()
	for _, tex in ipairs(picks) do
		ns.FillAccent(tex, 0.16, nil, KEY)
		tex:SetBlendMode("BLEND")
	end
end

local function MenuRow(row)
	if looked[row] then return end
	looked[row] = true
	Wash(row.t, 0.06)
	row.t:SetAlpha(1)
	picks[#picks + 1] = row.s
	ns.FillAccent(row.s, 0.16, nil, KEY)
	row.s:SetBlendMode("BLEND")
end

-- A search result row: its olive hover a wash.
local function ResultRow(row)
	if looked[row] then return end
	looked[row] = true
	Wash(row.hl, 0.06)
end

-- Its own fill and outline off a box of its (masked: it recolors the search box's outline on
-- every focus and hover).
local function OwnLook(eb)
	local Kit = ns.Kit
	Kit.Erase(eb.bg)
	if type(eb.edges) == "table" then
		for _, e in pairs(eb.edges) do Kit.Erase(e) end
	end
end

-- The recent chat window's search box (its magnifier .icon and "Search" .hint): DaylightUI's
-- input box.
local function SearchBox(eb)
	if looked[eb] then return end
	looked[eb] = true
	OwnLook(eb)
	if Controls() then ns.Kit.EditBox(eb) end
end

-- Its read-only copy boxes (the flight report's link and report, the recent chat's copy bar):
-- a one-line box as DaylightUI's input box, the several-line report as an inset well.
local function CopyBox(eb)
	if looked[eb] then return end
	looked[eb] = true
	OwnLook(eb)
	if not Controls() then return end
	if eb:IsMultiLine() then ns.Kit.Inset(eb) else ns.Kit.EditBox(eb) end
end

-- An input box's tooltip-border box (CreateEditBox's eb.f): off, the walk's input box in its place.
local function BoxFrame(eb)
	if looked[eb] then return end
	looked[eb] = true
	if Kind(eb.f) == "Frame" then ns.Kit.Hide(eb.f) end
end

-- A checkbox's words (its own .f string, which the walk doesn't open up) and the cog inside it.
local function CheckParts(cb)
	if Kind(cb.f) == "FontString" then
		ns.FollowFont(cb.f, KEY)
		if not looked[cb.f] then
			looked[cb.f] = true
			ns.Kit.Light(cb.f)
		end
	end
	Each_(Cog, cb:GetChildren())
end

-- A dropdown's label above it (GameFontNormal, gold): the label ink and the player's font.
local function DropLabel(dd)
	if looked[dd] then return end
	looked[dd] = true
	Each_(function(r)
		if Kind(r) == "FontString" and r ~= dd.Text then ns.FollowFont(r, KEY) end
	end, dd:GetRegions())
	ns.Kit.InkGameText(dd)
end

-- Its dropdowns' pop-up lists: the shell, the rows' tick and picked words in the accent.
local InkRows
local function InkRow(list, row, c, ar, ag, ab)
	if Kind(row) == "Button" and IsTexture(row.Check) and Kind(row.Text) == "FontString" then
		if not looked[row] then
			looked[row] = true
			ns.FollowFont(row.Text, KEY)
			local hl = row.GetHighlightTexture and row:GetHighlightTexture()
			Wash(hl, 0.08)
			ns.ScriptOnce(row, "OnClick", function() InkRows(list) end, KEY)
		end
		if ar then row.Check:SetVertexColor(ar, ag, ab, 1) end
		if row.Check:IsShown() and ar then
			row.Text:SetTextColor(ar, ag, ab)
		elseif c then
			row.Text:SetTextColor(c[1], c[2], c[3])
		end
	end
end

local function InkAmong(list, c, ar, ag, ab, ...)
	for i = 1, select("#", ...) do InkRow(list, (select(i, ...)), c, ar, ag, ab) end
end

InkRows = function(list)
	local ar, ag, ab = ns.AccentOf(KEY)
	InkAmong(list, ns.Colors().TEXT, ar, ag, ab, list:GetChildren())
end

local function PopupList(list)
	if looked[list] then return end
	looked[list] = true
	ns.NoBackdrop(list)
	ns.Shell(list, { window = true, bgAlpha = 0.98 }, KEY)
	-- (Its rows are made and colored in the same call that shows it, and recolored by a click or
	-- the wheel.)
	ns.ScriptOnce(list, "OnShow", function() InkRows(list) end, KEY)
	ns.ScriptOnce(list, "OnMouseWheel", function() InkRows(list) end, KEY)
end

-- The tabs on the minimap panels (MakeMiniTab: a backdrop button with its own .text). Which one
-- is picked never changes on a panel: each tab of a pair opens the other panel.
local function MiniTab(tab)
	if looked[tab] then return end
	looked[tab] = true
	local Kit = ns.Kit
	Kit.Backdrop(tab)
	-- (Kit.Tab reads a tab's words from .Text.)
	if tab.Text == nil then tab.Text = tab.text end
	Kit.Tab(tab, function(t) return t.selected == true end)
end

-- A backdrop box inside a window: a blue list box as an inset, a gold-edged frame as an outline.
local function Box(frame)
	if looked[frame] then return end
	looked[frame] = true
	local bd = frame:GetBackdrop()
	ns.NoBackdrop(frame)
	if type(bd) == "table" and bd.bgFile then
		ns.Kit.Inset(frame)
	else
		ns.Kit.Shell(frame, "outline")
	end
end

-- A button the walk passed over: a menu row, a result row, a minimap panel tab, a cogwheel.
local function Button(frame)
	if IsTexture(frame.t) and IsTexture(frame.s) and Kind(frame.f) == "FontString" then
		MenuRow(frame)
	elseif IsTexture(frame.hl) and Kind(frame.f) == "FontString" and Kind(frame.e) == "FontString" then
		ResultRow(frame)
	elseif Controls() and frame.GetBackdrop and frame:GetBackdrop() and Kind(frame.text) == "FontString" then
		MiniTab(frame)
	else
		Cog(frame)
	end
end

-- A frame inside a window: a page's title, a backdrop box, a dropdown's list.
local function Inner(frame, root)
	-- A page of the options window: its title in the value ink.
	if frame:GetParent() == root and Kind(frame.s) == "FontString" and not looked[frame.s] then
		looked[frame.s] = true
		Ink(frame.s, "VALUE")
	end
	if frame.GetBackdrop and frame:GetBackdrop() and not looked[frame] then
		if frame:IsMouseWheelEnabled() and frame:GetFrameStrata() == "FULLSCREEN_DIALOG" then
			PopupList(frame)
		else
			Box(frame)
		end
	end
end

-- A text button (CreateButton): sized by Leatrix Plus to its words in the game's font, so widened
-- to fit them in the player's (never narrowed); the words beside it (the Reload button's "Your UI
-- needs to be reloaded.", its own .f) in the player's font and DaylightUI's inks.
local function TextButton(b)
	local fs = b.GetFontString and b:GetFontString()
	if Kind(fs) == "FontString" then
		local w = fs:GetStringWidth()
		if type(w) == "number" and w > 0 and b:GetWidth() < w + 20 then b:SetWidth(w + 20) end
	end
	if Kind(b.f) == "FontString" and b.f ~= fs then
		ns.FollowFont(b.f, KEY)
		if not looked[b.f] then
			looked[b.f] = true
			ns.Kit.InkGameText(b)
		end
	end
end

-- A frame's children the walk takes as whole controls: their own parts.
local function Part(c)
	local ck = Kind(c)
	if ck == "CheckButton" then
		CheckParts(c)
	elseif ck == "EditBox" then
		if IsTexture(c.bg) and type(c.edges) == "table" then
			if not c:IsMultiLine() and IsTexture(c.icon) and Kind(c.hint) == "FontString" then
				SearchBox(c)
			else
				CopyBox(c)
			end
		elseif Kind(c.f) == "Frame" then
			BoxFrame(c)
		end
	elseif ck == "Button" and IsTexture(c.Arrow) and Kind(c.Text) == "FontString" then
		DropLabel(c)
	elseif ck == "Button" and IsTexture(c.Left) and IsTexture(c.Right) then
		TextButton(c)
	end
end

-- What the walk hands every frame it passes (not the controls it dressed itself), the window too.
local function Each(frame, root)
	local k = Kind(frame)
	if k == "Button" then return Button(frame) end
	if k ~= "Frame" then return end
	if frame ~= root then Inner(frame, root) end
	Each_(Part, frame:GetChildren())
end

-- ---------------------------------------------------------------------------------------------
-- Windows
-- ---------------------------------------------------------------------------------------------

-- A faint 1 px line of ours on a window.
local function Line(f, vertical, a1, x1, y1, a2, x2, y2)
	local t = f:CreateTexture(nil, "ARTWORK")
	t:SetColorTexture(1, 1, 1, 0.07)
	t:SetPoint(a1, f, a1, x1, y1)
	t:SetPoint(a2, f, a2, x2, y2)
	if vertical then t:SetWidth(1) else t:SetHeight(1) end
end

-- Its ground, hairlines and accent line (the window's own BACKGROUND and BORDER textures: the
-- dark fill, the parchment bars, the hairline edges) off for good, masked: it sets the panel
-- opacity on the ground on every show.
local function Ground(f)
	local Kit = ns.Kit
	Each_(function(r)
		if IsTexture(r) then
			local layer = r:GetDrawLayer()
			if layer == "BACKGROUND" or layer == "BORDER" then Kit.Erase(r) end
		end
	end, f:GetRegions())
	if IsTexture(f.accent) then Kit.Erase(f.accent) end
end

local function Title(fs)
	if Kind(fs) ~= "FontString" then return end
	ns.FollowFont(fs, KEY)
	Ink(fs, "VALUE")
end

-- Its old close X (UI-Panel-MinimizeButton), wherever it sits on the window.
local function Closes(f, Kit)
	if not Controls() then return end
	Each_(function(c)
		if Usable(c) and ns.IsGameClose(c) and ns.Once(c) then Kit.Close(c) end
	end, f:GetChildren())
end

local function Dress(f)
	local Kit = ns.Kit
	if dressed[f] or not Kit or not On() then return end
	dressed[f] = true
	if f.GetBackdrop and f:GetBackdrop() then
		-- The info card: a flat card of its own; its backdrop gives way to the shell, its inside
		-- (icon, portrait, quality glow, its buttons) stays as laid out.
		ns.NoBackdrop(f)
		ns.Shell(f, { window = true }, KEY)
		return
	end
	Ground(f)
	ns.Shell(f, { window = true }, KEY)
	-- The options window (.mt) and its configuration panels (.c close, .r / .h / .b buttons).
	local main = Kind(f.mt) == "FontString"
	local panel = Usable(f.c) and Usable(f.r) and Usable(f.b)
	if main then
		Title(f.mt)
		-- Where the menu column and the button row met the parchment.
		Line(f, true, "TOPLEFT", 130, -10, "BOTTOMLEFT", 130, 48)
		Line(f, false, "BOTTOMLEFT", 10, 48, "BOTTOMRIGHT", -10, 48)
	elseif panel then
		Title(f.f)
		Line(f, false, "BOTTOMLEFT", 10, 48, "BOTTOMRIGHT", -10, 48)
	else
		Title(f.title)
	end
	Closes(f, Kit)
	if ns.Walk then
		ns.Walk(Kit, f, nil, nil, function(frame) Each(frame, f) end, KEY)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Finding its windows in UISpecialFrames
-- ---------------------------------------------------------------------------------------------

local function Made(f)
	if not Usable(f) or f.GetSourceLocation == nil then
		-- (No source to ask: its random names, "F" and 16 letters or digits, or its own globals.)
		local name = Usable(f) and f:GetName()
		return type(name) == "string" and (name:match("^F%w+$") ~= nil and #name == 17 or name:sub(1, 7) == "LeaPlus")
	end
	local ok, loc = pcall(f.GetSourceLocation, f)
	if not ok or type(loc) ~= "string" then return false end
	return string.find(string.lower(loc), "addons[/\\]leatrix_plus[/\\]") ~= nil
end

-- The names in the list already looked at (by name, not place: another addon may take an entry
-- out), and its length and last name then, to tell cheaply whether it changed.
local seen = {}
local count, last = 0, nil
local Scan

local function Changed(list)
	local n = #list
	return n ~= count or list[n] ~= last
end

local function Found(f)
	if dressed[f] then return end
	-- Dressed on its first show, before it's drawn (and at once if it's showing now).
	ns.ScriptOnce(f, "OnShow", function() Dress(f) Scan() end, KEY)
	if f:IsShown() then Dress(f) end
end

Scan = function()
	local list = _G.UISpecialFrames
	if type(list) ~= "table" or not On() or not ns.AddonLoaded(FOLDER) then return end
	if not Changed(list) then return end
	local n = #list
	for i = 1, n do
		local name = list[i]
		if type(name) == "string" and not seen[name] then
			-- (A name not made yet is looked at again next time.)
			local f = _G[name]
			if f ~= nil then
				seen[name] = true
				if Made(f) then Found(f) end
			end
		end
	end
	count, last = n, list[n]
end

local function ScanSoon() ns.Queue("LeatrixPlus:scan", Scan, KEY) end

-- After a click that may have made a window (its keybinds' windows wait for the next click).
local clicks = CreateFrame("Frame")
clicks:SetScript("OnEvent", function()
	local list = _G.UISpecialFrames
	if type(list) == "table" and Changed(list) then ScanSoon() end
end)

ns.Pack(KEY, "Leatrix Plus", function()
	Scan()
	clicks:RegisterEvent("GLOBAL_MOUSE_UP")
	-- Its panels are made at PLAYER_LOGIN, after this.
	ScanSoon()
end, CAPS)

ns.me.On("Login", function() if On() then ScanSoon() end end)
ns.me.On("StyleChanged", function() if On() then PaintPicks() end end)
ns.me.On("SettingChanged", function(scope)
	if scope == "DaylightAddonSkins" and On() then PaintPicks() end
end)

-- ---------------------------------------------------------------------------------------------
-- Hand-over: its switches DaylightUI also has (Leatrix Plus 1.60.33, LeaPlusDB "On" / "Off").
-- Left out: its automate gossip (only with Alt held as the window opens: nothing happens on its
-- own), faster movie skip (skips without asking; DaylightUI's skip cinematics, when on, ends them
-- first), hide zone text (DaylightUI's zone title replaces the game's text rather than hiding it,
-- the player's pick either way), its own minimap button (DaylightUI's drawer takes it as it is),
-- and the rest, which DaylightUI has no copy of (social blocks, summons and resurrections, mute
-- sounds, the dressing room, weather, keybindings, its recent chat window, chat filters...). Its
-- portrait numbers, player chain and borders on the game's unit frames are left too: harmless
-- work on frames DaylightUI's unit frames hide.
-- ---------------------------------------------------------------------------------------------

local function SV()
	local db = _G.DaylightAddonSkinsDB
	if type(db) ~= "table" then
		db = {}
		_G.DaylightAddonSkinsDB = db
	end
	return db
end

-- The values to write into LeaPlusDB as Leatrix Plus next loads (kept per account until a load
-- finds them there).
local function Next()
	local db = SV()
	if type(db.leatrixNext) ~= "table" then db.leatrixNext = {} end
	return db.leatrixNext
end

local function Tidy()
	local db = SV()
	if type(db.leatrixNext) == "table" and next(db.leatrixNext) == nil then db.leatrixNext = nil end
end

-- What Leatrix Plus runs with this session, per setting: LeaPlusDB as it read it (only its logout
-- writes there, and the hand-over no longer does), noted before the logout write-back.
local base = {}
local function Base(key)
	local db = _G.LeaPlusDB
	if base[key] == nil and type(db) == "table" then base[key] = db[key] end
	return base[key]
end

-- In its own ADDON_LOADED, before its handler reads LeaPlusDB (this plugin loads first, so this
-- frame's handler runs first): a kept value LeaPlusDB already holds (written back at the last
-- logout) is let go; one it doesn't is written in and kept until a later load finds it there.
if not late then
	local early = CreateFrame("Frame")
	early:RegisterEvent("ADDON_LOADED")
	early:SetScript("OnEvent", function(self, _, name)
		if name ~= FOLDER then return end
		self:UnregisterEvent("ADDON_LOADED")
		local db = _G.LeaPlusDB
		local want = SV().leatrixNext
		if type(db) ~= "table" or type(want) ~= "table" then return end
		for k, v in pairs(want) do
			if db[k] == v then want[k] = nil else db[k] = v end
		end
		Tidy()
	end)
end

-- At logout, after Leatrix Plus has written its live copy back: each kept value over it, unless
-- the live one is neither the kept one nor what it ran with this session (changed in Leatrix Plus
-- itself after the hand-over, or reset there): that one stands and the kept one is let go.
-- Registered a moment after login, so after Leatrix Plus registered its own at PLAYER_LOGIN (the
-- game calls them in the order they registered).
local logout = CreateFrame("Frame")
logout:SetScript("OnEvent", function()
	local db = _G.LeaPlusDB
	local want = SV().leatrixNext
	if type(db) ~= "table" or type(want) ~= "table" then return end
	for k, v in pairs(want) do
		local live = db[k]
		if live == v or live == base[k] then db[k] = v else want[k] = nil end
	end
	Tidy()
end)
ns.me.On("Login", function()
	if late or not ns.AddonLoaded(FOLDER) then return end
	C_Timer.After(0, function()
		local want = SV().leatrixNext
		if type(want) == "table" then
			for k in pairs(want) do Base(k) end
		end
		logout:RegisterEvent("PLAYER_LOGOUT")
	end)
end)

local has = ns.DaylightHas
local function notOne(v) return type(v) == "number" and v ~= 1 end
local function moduleOn(name) return function() return ns.ModuleOn(name) end end
local function C(key, label, daylight, ours)
	return { key = key, label = label, daylight = daylight, ours = ours, off = "Off", reload = true }
end

ns.Handover(KEY, {
	ready = function() return not late and type(_G.LeaPlusDB) == "table" end,
	get = function(key)
		local want = SV().leatrixNext
		if type(want) == "table" and want[key] ~= nil then return want[key] end
		local db = _G.LeaPlusDB
		local v = type(db) == "table" and db[key] or nil
		return v == "On" and "On" or "Off"
	end,
	-- Kept for its next load (LeaPlusDB is left as Leatrix Plus has it: it writes its live copy back
	-- at logout over anything written now), with what it runs with noted first.
	set = function(key, value)
		Base(key)
		Next()[key] = value
	end,
	list = {
		-- Automation
		C("AutomateQuests", L["Accept and Turn in Quests Automatically"],
			ns.In(L["auto accept and auto turn in"], "Quality of Life"),
			function() return has("QoL", "questAccept") or has("QoL", "questTurnIn") end),
		C("AutoSellJunk", L["Sell Junk at Vendors"], ns.In(L["sell junk"], "Bags"),
			function() return has("Bags", "sellJunk") end),
		C("AutoRepairGear", L["Repair at Vendors"], ns.In(L["auto repair"], "Bags"),
			function() return has("Bags", "autoRepair") end),
		-- System and frames
		C("FasterLooting", L["Faster Looting"], ns.In(L["fast loot"], "Quality of Life"),
			function() return has("QoL", "fastLoot") end),
		C("HideErrorMessages", L["Hide Error Messages"], ns.In(L["quiet errors and its own error text"], "Quality of Life"),
			function() return has("QoL", "quietErrors") or has("QoL", "errorText") end),
		C("MaxCameraZoom", L["Farther Camera Zoom"], ns.In(L["camera distance"], "Quality of Life"),
			function() return has("QoL", "cameraZoom", notOne) end),
		C("ShowTrainAllButton", L["Train All Button at Trainers"], ns.In(L["the Train All button"], "Quality of Life"),
			function() return has("QoL", "trainAll") end),
		C("EasyItemDestroy", L["Destroy Good Items Without Typing DELETE"],
			ns.In(L["DELETE filled in for you"], "Quality of Life"),
			function() return has("QoL", "autoDelete") end),
		C("ShowFlightTimes", L["Flight Timer"], ns.In(L["the flight timer"], "Quality of Life"),
			function() return has("QoL", "flightTimer") end),
		-- Interface: DaylightUI's own minimap, tooltip and unit frames.
		C("MinimapModder", L["Enhanced Minimap"], ns.In(L["its own square minimap"], "Info Panel"),
			function() return has("InfoPanel", "map.enabled") end),
		C("TipModEnable", L["Enhanced Tooltip"], ns.In(L["its tooltip, with item level and quality"], "Tooltip"),
			moduleOn("Tooltip")),
		C("ClassColFrames", L["Class Colors on the Game's Unit Frames"], ns.In(L["its own unit frames"], "Unit Frames"),
			moduleOn("UnitFrames")),
		-- Chat: DaylightUI_Chat draws its own panel over the game's chat windows.
		C("NoChatButtons", L["Hide the Chat Buttons"], ns.In(L["its hidden chat buttons"], "Chat"),
			function() return has("Chat", "hideButtons") end),
		C("NoChatFade", L["No Chat Fade"], ns.In(L["the chat's own fading"], "Chat"), moduleOn("Chat")),
		C("MoveChatEditBoxToTop", L["Chat Box at the Top"], ns.In(L["where its chat box sits"], "Chat"),
			moduleOn("Chat")),
		C("UseArrowKeysInChat", L["Arrow Keys Move the Chat Cursor"], ns.In(L["Up and Down for sent lines"], "Chat"),
			function() return has("Chat", "arrowHistory") end),
		C("RestoreChatMessages", L["Restore Chat After a Reload"], ns.In(L["the chat history"], "Chat"),
			function() return has("Chat", "history") end),
		-- Action buttons: DaylightUI's bars set their keybind, macro name and range looks per bar.
		C("HideKeybindText", L["Hide Keybind Text on Action Buttons"],
			ns.In(L["its action buttons' text and range colors"], "Action Bars"), moduleOn("ActionBars")),
		C("HideMacroText", L["Hide Macro Text on Action Buttons"],
			ns.In(L["its action buttons' text and range colors"], "Action Bars"), moduleOn("ActionBars")),
		C("ShowRangeColoring", L["Range Colors on Action Buttons"],
			ns.In(L["its action buttons' text and range colors"], "Action Bars"), moduleOn("ActionBars")),
	},
})
