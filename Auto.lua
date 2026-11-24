-- Auto Skinner (BETA): a plain DaylightUI look on the windows of addons this plugin has no pack
-- for, found on their own. Each such addon gets a switch of its own on All windows, off until the
-- player turns it on (an automatic look can't reach the standard of a pack: see the notes below).
--
-- How a window's addon is known: region:GetSourceLocation() names the file and line that made a
-- frame ("Interface/AddOns/<Folder>/file.lua:12", or the .xml line for an XML frame; a frame made
-- from a template names the line that made it). Measured on this client (2026-11-16): every one of
-- 28,415 frames answered, about a microsecond a call; the game's forbidden frames refuse the call.
-- Code inside an addon's Libs folder names that addon's folder too: those frames (AceGUI, LibDBIcon,
-- LibUIDropDownMenu) are left out, as libraries have looks of their own (the Ace3 pack, menus).
--
-- Which windows: the screen's top-level frames (UIParent's children), looked at once the world is
-- up and again whenever their count grows (a look every 2 seconds at a number; nothing every
-- frame). A window is a plain frame, not protected or forbidden, not built like a tooltip
-- (GameTooltip's NumLines and SetOwner both, or a tooltip-layout NineSlice), that wears a
-- window: the game's frame template parts (NineSlice, Bg, TitleBg, PortraitContainer,
-- TitleContainer) or a backdrop. On the tooltip layer only a dialog counts (it takes the mouse
-- and holds a button: VuhDo's yes / no box). Nothing under the world map is touched (frames under
-- it with scripts of ours taint the gamepad's interact key), and nothing is scripted: hooks only.
--
-- Which addons: not the game's (Blizzard_), not DaylightUI's or its plugins' (Daylight*, or
-- anything that needs DaylightUI: it is drawn in DaylightUI's look already), not one with a pack
-- here (or one of a pack's other folders: Altoholic's AddonFactory and DataStore) or in
-- DaylightUI's own Window Skins.
--
-- The dressing, on each show of a window big enough to be one (a frame not laid out yet is left
-- for its next show): a template window gets Kit.Window (its art off, DaylightUI's window, title
-- and close button); a backdrop window its backdrop hidden, DaylightUI's shell and its X (its
-- CloseButton key, or the button in its top right corner). Then the walk every pack uses
-- (ns.Dress), with the Auto Skinner's extras (DRESS below): the game's standard buttons and
-- input boxes; template scroll bars, bare ones (UIPanelScrollBarTemplate as a Slider of its own)
-- and the modern ones (MinimalScrollBar, WowTrimScrollBar); sliders (OptionsSliderTemplate and
-- its kin, through ns.Slider); old dropdowns (UIDropDownMenuTemplate and copies with Left /
-- Middle / Right art, through ns.OldDropdown); a close X in the game's art anywhere; the game's
-- size grabber in DaylightUI's grip look (ns.Grip); check buttons in the game's checkbox art as
-- switches. Radio buttons keep the game's dots (DaylightUI has no radio look), and check buttons
-- an addon drew itself (toggle tabs, its own boxes and dots: VuhDo's) keep their look. Flat
-- backdrop boxes are softened and the player's font goes on every string. Art the addon drew
-- itself (its own buttons, rows, icons, colors) stays as it is. In a fight, waits for its end.
local _, ns = ...
if not ns.ok then return end

local L = ns.L

-- Addons DaylightUI's own Window Skins dresses (its Packs/Addons), by folder or folder prefix.
local DUI_PACKS = { "Attune", "Baganator", "Bagnon", "BigWigs", "DBM", "ForeverDungeonJournal", "NeedRoll",
	"OPie", "PrettyTooltip", "Questie", "RXPGuides" }
-- Folders a pack here covers under another name.
local COVERED = { ForeverCore = true }

local MIN_W, MIN_H = 160, 100
local TEMPLATE_PARTS = { "NineSlice", "Bg", "TitleBg", "PortraitContainer", "TitleContainer" }

local found = {}        -- folder -> { label, windows = { frame = true } }
local frameFolder = setmetatable({}, { __mode = "k" })   -- frame -> folder
local hooked = setmetatable({}, { __mode = "k" })
local dressed = setmetatable({}, { __mode = "k" })
local waiting = setmetatable({}, { __mode = "k" })       -- shown during a fight
local eligible = {}     -- folder -> true / false

local function Secret(v) return issecretvalue and issecretvalue(v) or false end

local function Call(frame, method)
	if type(frame) ~= "table" then return nil end
	local fn = frame[method]
	if type(fn) ~= "function" then return nil end
	local ok, v = pcall(fn, frame)
	if not ok or Secret(v) then return nil end
	return v
end

-- The addon folder that made a frame, nil for the game's, a library's, or one that won't say.
local function FolderOf(frame)
	if Call(frame, "IsForbidden") then return nil end
	local loc = Call(frame, "GetSourceLocation")
	if type(loc) ~= "string" then return nil end
	local folder, rest = loc:match("[Aa][Dd][Dd][Oo][Nn][Ss][/\\]([^/\\]+)[/\\](.*)")
	if not folder then return nil end
	local lower = rest:lower()
	if lower:find("libs?[/\\]") or lower:find("externallibs[/\\]") then return nil end
	return folder
end

local function StartsWith(s, prefix) return s:sub(1, #prefix) == prefix end

local function NeedsDaylightUI(folder)
	local deps = C_AddOns and C_AddOns.GetAddOnDependencies and { pcall(C_AddOns.GetAddOnDependencies, folder) }
	if not deps or not deps[1] then return false end
	for i = 2, #deps do
		if deps[i] == "DaylightUI" then return true end
	end
	return false
end

-- Whether this plugin may dress `folder` on its own.
local function Eligible(folder)
	local e = eligible[folder]
	if e ~= nil then return e end
	e = true
	if StartsWith(folder, "Blizzard_") or StartsWith(folder, "Daylight") or COVERED[folder] or NeedsDaylightUI(folder) then
		e = false
	else
		for key in pairs(ns.targets) do
			if folder == key or StartsWith(folder, key .. "_") or StartsWith(folder, key .. "-") then
				e = false
				break
			end
		end
		-- (A pack's other folders, caps.folders: Altoholic's AddonFactory and DataStore, and their
		-- own _ / - parts.)
		if e then
			for _, list in pairs(ns.folders) do
				for _, f in ipairs(list) do
					if folder == f or StartsWith(folder, f .. "_") or StartsWith(folder, f .. "-") then
						e = false
						break
					end
				end
				if not e then break end
			end
		end
		if e then
			for _, prefix in ipairs(DUI_PACKS) do
				if StartsWith(folder, prefix) then
					e = false
					break
				end
			end
		end
	end
	eligible[folder] = e
	return e
end

-- The addon's name as its list shows it (its title, color codes off).
local function Label(folder)
	local title = C_AddOns and C_AddOns.GetAddOnMetadata and select(2, pcall(C_AddOns.GetAddOnMetadata, folder, "Title"))
	if type(title) ~= "string" or title == "" then return folder end
	title = title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
	title = title:match("^%s*(.-)%s*$")
	return title ~= "" and title or folder
end

-- The setting of one addon's switch (off until turned on).
local function Key(folder) return "auto." .. folder end
local function On(folder) return ns.Enabled() and ns.Setting(Key(folder)) == true end
ns.AutoKey = Key

-- The section's name, its "BETA" bright (the word stays English in every language).
local BETA = "|cffffb000BETA|r"
function ns.AutoTitle() return string.format(L["Auto Skinner (%s)"], BETA) end

-- Anything built like a tooltip: GameTooltip's own NumLines and SetOwner both (an addon's copy of
-- the template), or a NineSlice in a tooltip layout (TooltipBackdropTemplate). (Not one method
-- alone or "Tooltip" in its name: a log window with an AddLine, a XTooltipOptions window.)
local function Tooltipish(frame)
	if type(frame.NumLines) == "function" and type(frame.SetOwner) == "function" then return true end
	local nine = rawget(frame, "NineSlice")
	local layout = type(nine) == "table" and rawget(nine, "layoutType")
	return type(layout) == "string" and string.find(string.lower(layout), "tooltip", 1, true) ~= nil
end

-- A frame on the tooltip layer is a window only when it's a dialog: it takes the mouse and holds
-- a button of its own (VuhDo's yes / no and share dialogs). A tooltip-like box there doesn't.
local function Dialog(frame)
	if not Call(frame, "IsMouseEnabled") then return false end
	for _, child in ipairs({ frame:GetChildren() }) do
		if Call(child, "GetObjectType") == "Button" and not Call(child, "IsProtected") then return true end
	end
	return false
end

local function IsWindow(frame)
	if Call(frame, "GetObjectType") ~= "Frame" then return false end
	if Call(frame, "IsProtected") or Tooltipish(frame) then return false end
	if Call(frame, "GetFrameStrata") == "TOOLTIP" and not Dialog(frame) then return false end
	for _, part in ipairs(TEMPLATE_PARTS) do
		if rawget(frame, part) ~= nil then return true end
	end
	return Call(frame, "GetBackdrop") ~= nil
end

-- An addon's copy of the game's old dropdown list (UIDropDownListTemplate's parts by key: a dark
-- dialog Backdrop and a tooltip-bordered MenuBackdrop, rows with Check / UnCheck marks), as
-- BtWQuests' options menu is. Small, so no size rule; dressed as the Blizzard pack dresses the
-- game's own lists.
local function IsMenu(frame)
	local kind = Call(frame, "GetObjectType")
	if kind ~= "Frame" and kind ~= "Button" then return false end
	if Call(frame, "IsProtected") then return false end
	return type(rawget(frame, "Backdrop")) == "table" and type(rawget(frame, "MenuBackdrop")) == "table"
end

local function Templated(frame)
	for _, part in ipairs(TEMPLATE_PARTS) do
		if rawget(frame, part) ~= nil then return true end
	end
	return false
end

-- The walk's extra controls (ns.Dress in Core.lua): bare scroll bars and sliders, the modern
-- scroll bars, old dropdowns, a close X and size grabber in the game's art anywhere, and only
-- the game's own checkboxes made switches (an addon's own toggles keep their look).
local DRESS = { fonts = true, soften = true, sliders = true, modernBars = true, oldDropdowns = true, closes = true,
	grips = true, gameChecks = true }

-- The game's gold (GameFontNormal's 1, 0.82, 0), the color of most addons' headings: DaylightUI's
-- label ink in its place, as every pack here gives it. Any other color an addon set stays.
local function Gold(r, g, b)
	return type(r) == "number" and not Secret(r) and math.abs(r - 1) < 0.02 and math.abs(g - 0.82) < 0.02 and b < 0.03
end
local SKIP_KINDS = { GameTooltip = true, Model = true, PlayerModel = true, DressUpModel = true, ModelScene = true,
	Cooldown = true, SimpleHTML = true, MessageFrame = true, ScrollingMessageFrame = true }
local function InkAmong(label, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if Call(r, "GetObjectType") == "FontString" then
			local ok, cr, cg, cb = pcall(r.GetTextColor, r)
			if ok and Gold(cr, cg, cb) then r:SetTextColor(label[1], label[2], label[3]) end
		end
	end
end
local Ink
-- (The children as the game hands them back: no table made for each frame of the walk.)
local function InkChildren(label, depth, ...)
	for i = 1, select("#", ...) do
		local child = select(i, ...)
		if not Call(child, "IsProtected") then Ink(child, label, depth) end
	end
end
Ink = function(frame, label, depth)
	if depth > 10 or Call(frame, "IsForbidden") or SKIP_KINDS[Call(frame, "GetObjectType")] then return end
	if frame.GetRegions then InkAmong(label, frame:GetRegions()) end
	if frame.GetChildren then InkChildren(label, depth + 1, frame:GetChildren()) end
end

-- The window's title stays where the addon put it: Kit.Window moves it to the left of the title
-- row (DaylightUI's own windows have it there), and an addon may keep buttons there (BtWQuests'
-- back, forward and menu, where a portrait would be). Its anchors and justify are read before
-- and put back right after.
local function TitleOf(frame)
	local tc = rawget(frame, "TitleContainer")
	local t = (type(tc) == "table" and rawget(tc, "TitleText")) or rawget(frame, "TitleText")
	if Call(t, "GetObjectType") == "FontString" then return t end
end
local function Placement(title)
	local points = {}
	for i = 1, title:GetNumPoints() do points[i] = { title:GetPoint(i) } end
	return { points = points, justify = title:GetJustifyH() }
end
local function PutBack(title, was)
	if not (title and was and #was.points > 0) then return end
	title:ClearAllPoints()
	for _, p in ipairs(was.points) do title:SetPoint(unpack(p)) end
	if was.justify then title:SetJustifyH(was.justify) end
end

local MENU_SHELL = { quiet = true }
local UNCHECKED, HOVER_WASH = 0.55, 0.08
local washed = setmetatable({}, { __mode = "k" })

-- Its rows' marks, after the addon has set them up for this opening: ticked in the accent,
-- unticked gray.
local function MenuMarks(list)
	if not Call(list, "IsShown") then return end
	local r, g, b = ns.AccentOf()
	for _, row in ipairs({ list:GetChildren() }) do
		local check, uncheck = rawget(row, "Check"), rawget(row, "UnCheck")
		if Call(check, "GetObjectType") == "Texture" and Call(check, "IsShown") then
			check:SetDesaturated(true)
			check:SetVertexColor(r, g, b)
		end
		if Call(uncheck, "GetObjectType") == "Texture" and Call(uncheck, "IsShown") then
			uncheck:SetDesaturated(true)
			uncheck:SetVertexColor(UNCHECKED, UNCHECKED, UNCHECKED)
		end
	end
end

local function DressMenu(list, Kit)
	if not dressed[list] then
		dressed[list] = true
		for _, key in ipairs({ "Backdrop", "MenuBackdrop" }) do
			local part = rawget(list, key)
			if ns.Usable(part) then part:SetAlpha(0) end
		end
		ns.Guard(Kit.Shell, list, "window", MENU_SHELL)
	end
	-- (Opened again at another frame level: the shell back under its rows.)
	local shell = Kit.ShellOf and Kit.ShellOf(list)
	if shell and shell.SetFrameLevel then shell:SetFrameLevel(math.max(0, list:GetFrameLevel() - 1)) end
	for _, row in ipairs({ list:GetChildren() }) do
		local hl = rawget(row, "Highlight")
		if not washed[row] and Call(hl, "GetObjectType") == "Texture" then
			washed[row] = true
			hl:SetColorTexture(1, 1, 1, HOVER_WASH)
			hl:SetBlendMode("BLEND")
		end
	end
	ns.Dress(list, DRESS)
	C_Timer.After(0, function() ns.Guard(MenuMarks, list) end)
end

local function Dress(frame)
	local folder = frameFolder[frame]
	if not folder or not On(folder) or not ns.Usable(frame) then return end
	if InCombatLockdown() then
		waiting[frame] = true
		return
	end
	if Call(frame, "IsProtected") then return end
	if IsMenu(frame) then
		ns.WithKit(function(Kit)
			DressMenu(frame, Kit)
			local label = ns.Colors().LABEL
			if type(label) == "table" then ns.Guard(Ink, frame, label, 0) end
		end)
		return
	end
	local w, h = Call(frame, "GetWidth"), Call(frame, "GetHeight")
	if type(w) ~= "number" or type(h) ~= "number" or w < MIN_W or h < MIN_H then return end
	local screen = UIParent:GetWidth() or 0
	if screen > 0 and w >= screen * 0.95 then return end    -- (a full-screen holder, not a window)
	ns.WithKit(function(Kit)
		if not dressed[frame] then
			dressed[frame] = true
			if Templated(frame) then
				local title = TitleOf(frame)
				local was = title and Placement(title)
				ns.Guard(Kit.Window, frame)
				ns.Guard(PutBack, title, was)
			else
				ns.Guard(Kit.Backdrop, frame)
				ns.Shell(frame, { window = true })
				-- Its X, where Kit.Window would look for it or in the top right corner (one in the
				-- game's art anywhere else is found by the walk below). Not a "Close" text button.
				local close = rawget(frame, "CloseButton")
				if not (ns.Usable(close) and Call(close, "GetObjectType") == "Button") then close = ns.FindClose(frame) end
				if close and not (ns.TextButton and ns.TextButton(close)) and ns.Once(close) then ns.Guard(Kit.Close, close) end
			end
		end
		ns.Dress(frame, DRESS)
		local label = ns.Colors().LABEL
		if type(label) == "table" then ns.Guard(Ink, frame, label, 0) end
	end)
end

-- What a click inside a dressed window brings up (a page it draws without hiding first, new rows,
-- a list it fills): dressed again once its click has run, on the next frame. The game's
-- GLOBAL_MOUSE_UP, as DaylightUI's own NeedRoll skin listens for it: nothing runs between clicks.
local again = false
local caughtUp = false   -- (the first look over the whole interface done: below)
local Check              -- (a look at frames made since: below)
local function DressShown()
	again = false
	for frame in pairs(dressed) do
		if Call(frame, "IsVisible") then Dress(frame) end
	end
end
local clicks = CreateFrame("Frame")
clicks:RegisterEvent("GLOBAL_MOUSE_UP")
local newSoon = false
local function CheckSoon()
	newSoon = false
	Check()
end
clicks:SetScript("OnEvent", function()
	if caughtUp and not newSoon then
		newSoon = true
		C_Timer.After(0, CheckSoon)
	end
	if again or not next(dressed) then return end
	for frame in pairs(dressed) do
		if Call(frame, "IsVisible") and Call(frame, "IsMouseOver") then
			again = true
			C_Timer.After(0, DressShown)
			return
		end
	end
end)

-- The addons found, kept between sessions (DaylightAddonSkinsDB.autoKnown[folder] = label): an
-- addon makes many a window only when it's first opened, so without this its switch was gone
-- from the list after every login until that window had been opened again.
local function Known()
	local db = _G.DaylightAddonSkinsDB
	if type(db) ~= "table" then return nil end
	if type(db.autoKnown) ~= "table" then db.autoKnown = {} end
	return db.autoKnown
end

-- The list grew: the options page, when it's open, is laid out again so the new switch shows
-- at once (DaylightUI's own refresh, DaylightUI\Options\Panel.lua:13, :656, :1131; without it
-- the switch shows the next time the page is opened). Once for a burst of finds.
local telling = false
local function Grew()
	if telling then return end
	telling = true
	C_Timer.After(0.2, function()
		telling = false
		local D = _G.DaylightUI
		local P = type(D) == "table" and D.OptionsPanel
		if type(P) ~= "table" or type(P.IsShown) ~= "function" or type(P.Refresh) ~= "function" then return end
		if InCombatLockdown() then return end
		local ok, shown = pcall(P.IsShown)
		if ok and shown then pcall(P.Refresh) end
	end)
end

local function Take(frame, folder)
	frameFolder[frame] = folder
	local e = found[folder]
	if not e then
		e = { label = Label(folder), windows = {} }
		found[folder] = e
		local known = Known()
		local fresh = known and known[folder] == nil
		if known then known[folder] = e.label end
		if fresh then Grew() end
	end
	e.windows[frame] = true
	if not On(folder) or hooked[frame] then return end
	hooked[frame] = true
	frame:HookScript("OnShow", Dress)
	if Call(frame, "IsShown") then Dress(frame) end
end

-- A frame at the top (UIParent's child, or one made with no parent at all: BtWQuests' options
-- list) from an addon that may be dressed.
-- (Each frame is looked at once: the walk below never comes back to one it has passed.)
local function Consider(frame)
	if Call(frame, "IsForbidden") then return end
	local parent = Call(frame, "GetParent")
	if parent ~= nil and parent ~= UIParent then return end
	local folder = FolderOf(frame)
	if folder and Eligible(folder) and (IsMenu(frame) or IsWindow(frame)) then Take(frame, folder) end
end

-- Every frame the game has made, in the order it made them (EnumerateFrames), from where the last
-- look stopped: each look sees only frames made since. budget = at most this many now (the first
-- look, over the whole interface, is spread over a few frames); true once caught up.
local cursor
local function Step(budget)
	if not ns.Enabled() then return true end
	local frame
	if cursor then frame = EnumerateFrames(cursor) else frame = EnumerateFrames() end
	local n = 0
	while frame do
		-- (Moved past before it's looked at: one that errors is not looked at again.)
		cursor = frame
		Consider(frame)
		n = n + 1
		if budget and n >= budget then return false end
		frame = EnumerateFrames(frame)
	end
	return true
end

-- Once the world is up: the whole interface, 2,000 frames a frame (about 28,000 here). Then a
-- look at what's new every 2 seconds, and right after any click (a menu or window a click made:
-- found the next frame).
function Check()
	if caughtUp then ns.Guard(Step) end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		C_Timer.After(1, function()
			local first
			first = C_Timer.NewTicker(0, function()
				local ok, done = xpcall(Step, geterrorhandler(), 2000)
				if not ok or done then
					first:Cancel()
					caughtUp = true
					C_Timer.NewTicker(2, Check)
				end
			end)
		end)
	else
		for frame in pairs(waiting) do
			waiting[frame] = nil
			if Call(frame, "IsShown") then Dress(frame) end
		end
	end
end)

-- The addons found so far, for the All windows grid: { { folder, label, windows = n }, ... }.
function ns.AutoAddons()
	local list = {}
	for folder, e in pairs(found) do
		local n = 0
		for _ in pairs(e.windows) do n = n + 1 end
		list[#list + 1] = { folder = folder, label = e.label, windows = n }
	end
	-- Found in an earlier session and loaded now, its windows not made yet: listed all the same
	-- (windows = 0), so its switch is there and what it was set to shows. One that has a pack by
	-- now, or isn't loaded, is left out (and forgotten once it's no longer installed).
	local known = Known()
	if known then
		for folder, label in pairs(known) do
			if not found[folder] and type(folder) == "string" then
				if ns.AddonLoaded(folder) and Eligible(folder) then
					list[#list + 1] = { folder = folder, label = type(label) == "string" and label or Label(folder), windows = 0 }
				elseif C_AddOns and C_AddOns.DoesAddOnExist and not C_AddOns.DoesAddOnExist(folder) then
					known[folder] = nil
				end
			end
		end
	end
	table.sort(list, function(a, b) return a.label:lower() < b.label:lower() end)
	return list
end

-- /skinsauto: what was found, each window by name and how it would be dressed.
_G.SLASH_DAYLIGHTSKINSAUTO1 = "/skinsauto"
SlashCmdList.DAYLIGHTSKINSAUTO = function()
	Check()
	local list = ns.AutoAddons()
	print("|cffa335eeAddon Skins|r: " .. string.format(L["%d other addons with windows found."], #list))
	for _, a in ipairs(list) do
		local names = {}
		for frame in pairs(found[a.folder].windows) do
			local name = Call(frame, "GetName")
			local how = (IsMenu(frame) and " (menu)") or (Templated(frame) and "") or " (backdrop)"
			names[#names + 1] = (type(name) == "string" and name or "?") .. how
		end
		table.sort(names)
		print(string.format("  %s (%s): %s", a.label, On(a.folder) and L["On"] or L["Off"], table.concat(names, ", ")))
	end
end

