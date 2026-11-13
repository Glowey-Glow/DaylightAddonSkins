-- Dungeon Journal (ForeverDungeonJournal): what DaylightUI's own Dungeon Journal skin leaves as it
-- is. DaylightUI dresses the journal, its favorites and settings windows; none of that is touched
-- here.
-- Dressed here:
--   * Character Logs (ForeverDungeonJournalRunLog): a ButtonFrameTemplate window of its own that
--     DaylightUI's skin never sees. The window shell, its run list (picked run in the accent), its
--     stat tiles, loot cards and delete buttons as quiet flat boxes (loot cards keep their quality
--     edge), its gold headings and lines in DaylightUI's colors, its buttons and scroll bars, and
--     the party list that drops from the Party button. Each dungeon's faint picture behind a run
--     stays.
--   * Loot Filter (ForeverDungeonJournalLootFilter): a popup inside the journal. DaylightUI's skin
--     walks it like a panel of the journal, so its background goes and the home page shows through.
--     It gets the window shell instead, and so do its Armor / Weapon / Resistances / school menus
--     and its stat tip. Its controls are DaylightUI's skin's and are left alone.
local _, ns = ...
if not ns.ok then return end

local KEY = "ForeverDungeonJournal"

ns.Target(KEY, "Dungeon Journal", { window = true, controls = true, text = true, shadow = true })

local FLAT = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }

local function Ink(fs, name)
	if not ns.Usable(fs) then return end
	local c = ns.Colors()[name]
	if c then fs:SetTextColor(c[1], c[2], c[3]) end
end

-- A gold separator line of its own, made a faint neutral one.
local function Quiet(tex)
	if not ns.Usable(tex) or tex:GetObjectType() ~= "Texture" then return end
	tex:SetColorTexture(1, 1, 1, 0.08)
end

-- Its tooltip-border boxes (tiles, loot cards, the delete X): a flat one-pixel box, a dark well.
-- A loot card's edge is recolored by quality on every refresh, which the flat edge keeps.
local function Flat(frame, alpha)
	if not ns.Usable(frame) or not frame.SetBackdrop or not ns.Once(frame) then return end
	frame:SetBackdrop(FLAT)
	ns.Soften(frame, alpha)
end

-- The textures a frame draws behind itself: its backdrop pieces and any border or ground
-- DaylightUI's journal skin put on it. Its own icons, ticks and lines are ARTWORK and above.
-- (Run four times on each show: the regions are gone through as the game hands them back, with no
-- table made of them.)
local function ClearAmong(...)
	for i = 1, select("#", ...) do
		local region = select(i, ...)
		if region:GetObjectType() == "Texture" then
			local layer = region:GetDrawLayer()
			if layer == "BACKGROUND" or layer == "BORDER" then region:SetAlpha(0) end
		end
	end
end

local function ClearGround(frame)
	ClearAmong(frame:GetRegions())
end

-- Runs fn now and over the next few frames: DaylightUI's journal skin dresses what it walks a
-- frame or two after a click, and what it draws there is cleared again after it.
local function Settle(fn)
	fn()
	C_Timer.After(0, function()
		fn()
		C_Timer.After(0, fn)
	end)
	C_Timer.After(0.25, fn)
end

-- ---------------------------------------------------------------------------------------------
-- Popups: a window shell in place of their backdrop
-- ---------------------------------------------------------------------------------------------

local popups = setmetatable({}, { __mode = "k" })

local function Popup(frame)
	if not ns.Usable(frame) then return end
	local function fix()
		if not ns.Enabled(KEY) then return end
		ClearGround(frame)
		ns.Shell(frame, { window = true }, KEY)
	end
	if not popups[frame] then
		popups[frame] = true
		frame:HookScript("OnShow", function() Settle(fix) end)
	end
	if frame:IsShown() then Settle(fix) end
end

-- ---------------------------------------------------------------------------------------------
-- Character Logs
-- ---------------------------------------------------------------------------------------------

local rowsDone = setmetatable({}, { __mode = "k" })

local function Row(r)
	if rowsDone[r] then return end
	rowsDone[r] = true
	local ar, ag, ab = ns.AccentOf(KEY)
	if ns.Usable(r.sel) and ar then r.sel:SetColorTexture(ar, ag, ab, 0.16) end
	local hl = r.GetHighlightTexture and r:GetHighlightTexture()
	if ns.Usable(hl) then hl:SetColorTexture(1, 1, 1, 0.06) end
	Quiet(r.line)
	Ink(r.name, "VALUE")
	-- The delete X keeps its red cross; its brown box goes.
	for _, child in ipairs({ r:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" and child.GetBackdrop and child:GetBackdrop() then
			Flat(child, 0.35)
		end
	end
end

local function Detail(win)
	for kind, pool in pairs(type(win.pools) == "table" and win.pools or {}) do
		for _, w in ipairs(type(pool.items) == "table" and pool.items or {}) do
			if ns.Usable(w) then
				if kind == "tile" then
					Flat(w, 0.35)
				elseif kind == "item" then
					local hl = w.GetHighlightTexture and w:GetHighlightTexture()
					if ns.Usable(hl) and ns.Once(hl) then hl:SetColorTexture(1, 1, 1, 0.06) end
					Flat(w, 0.35)
				elseif kind == "divider" and ns.Once(w) then
					Quiet(w.left)
					Quiet(w.right)
					Ink(w.title, "LABEL")
				end
			end
		end
	end
	if ns.Usable(win.partyButton) and ns.Usable(win.partyButton.list) then
		local list = win.partyButton.list
		if ns.Once(list) then ns.NoBackdrop(list) end
		Popup(list)
	end
end

local function RunLog(win, Kit)
	if not ns.Usable(win) or not ns.Once(win) then return end
	ns.Guard(Kit.Window, win)
	-- Its line between the list and the run is a texture on the window, which the stripped window
	-- hid: back, faint and neutral.
	for _, region in ipairs({ win:GetRegions() }) do
		if region:GetObjectType() == "Texture" and region:GetNumPoints() == 2 and math.abs((region:GetWidth() or 0) - 1) < 0.01 then
			Quiet(region)
			region:SetAlpha(1)
		end
	end
	Ink(win.title, "VALUE")
	local function dress()
		if not win:IsShown() or not ns.Enabled(KEY) then return end
		for _, r in ipairs(type(win.rows) == "table" and win.rows or {}) do
			if ns.Usable(r) then ns.Guard(Row, r) end
		end
		ns.Guard(Detail, win)
	end
	local later = ns.DressOnShow(win, nil, dress, KEY)
	local FDJ = _G.ForeverDungeonJournal_NS
	-- Every redraw (picking a run, a kill or loot while it's open) goes through RefreshRunLog.
	if type(FDJ) == "table" and later and type(FDJ.RefreshRunLog) == "function" then
		hooksecurefunc(FDJ, "RefreshRunLog", later)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Loot Filter
-- ---------------------------------------------------------------------------------------------

local MENUS = { "armor", "weapon", "schoolArrow", "resist" }

local function LootFilter(win)
	if not ns.Usable(win) or not ns.Once(win) then return end
	local function menus()
		if not ns.Enabled(KEY) then return end
		for _, key in ipairs(MENUS) do
			local b = win[key]
			if type(b) == "table" and ns.Usable(b.menu) then Popup(b.menu) end
		end
		if ns.Usable(win.fdjTip) then Popup(win.fdjTip) end
	end
	Popup(win)
	win:HookScript("OnShow", menus)
	menus()
	-- Its stat tip is made the first time a stat is hovered.
	if type(win.statChecks) == "table" then
		for _, check in pairs(win.statChecks) do
			if ns.Usable(check) and check.HookScript then check:HookScript("OnEnter", menus) end
		end
	end
end

-- Both windows are made the first time they open, through its exported toggles. Dressing them right
-- after the toggle runs puts the look on in the same frame they first show; the look-out for them
-- by name (which checks only every 2 seconds once the first minute after login has passed, so the
-- window showed undressed that long) stays as the fallback. Each is dressed once either way.
ns.Pack(KEY, nil, function(Kit)
	ns.Watch(KEY, "ForeverDungeonJournalRunLog", RunLog)
	ns.Watch(KEY, "ForeverDungeonJournalLootFilter", LootFilter)
	local FDJ = _G.ForeverDungeonJournal_NS
	if type(FDJ) ~= "table" then return end
	if type(FDJ.ToggleRunLog) == "function" then
		hooksecurefunc(FDJ, "ToggleRunLog", function()
			local win = _G.ForeverDungeonJournalRunLog
			if ns.Enabled(KEY) and ns.Usable(win) then ns.Guard(RunLog, win, Kit) end
		end)
	end
	-- The boss icon size control on its dungeon maps (the journal's, and the world map's in a
	-- dungeon): a flat box, DaylightUI's - and + buttons, its label in the label ink.
	if type(FDJ.UpdateMapBossSizer) == "function" then
		hooksecurefunc(FDJ, "UpdateMapBossSizer", function(panel)
			local c = type(panel) == "table" and panel.fdjBossSizer
			if not ns.Enabled(KEY) or not ns.Usable(c) or c.dasSized then return end
			c.dasSized = true
			Flat(c, 0.6)
			Ink(c.label, "LABEL")
			Ink(c.value, "VALUE")
			if ns.Controls(KEY) then
				for _, b in ipairs({ c.minus, c.plus }) do
					if ns.Usable(b) then ns.Guard(Kit.Button, b) end
				end
			end
		end)
	end
	if type(FDJ.ToggleLootFilterWindow) == "function" then
		hooksecurefunc(FDJ, "ToggleLootFilterWindow", function(frame)
			local win = type(frame) == "table" and frame.lootFilterWindow or _G.ForeverDungeonJournalLootFilter
			if ns.Enabled(KEY) and ns.Usable(win) then ns.Guard(LootFilter, win) end
		end)
	end
	-- Inside a dungeon, both Dungeon Journal and OpenMap lay a dungeon map over the world map, one on
	-- top of the other (its floor buttons, its "World Map" toggle and its boss icon size poking
	-- through OpenMap's). The player picked OpenMap's (2026-11-12): while OpenMap is loaded, each
	-- time the journal puts its overlay up it's taken back down at once (through its own
	-- DetachWorldMapOverlay, so its map panel goes home to the journal), and its toggle and Scarlet
	-- Monastery wing buttons are hidden. Its own setting is left as it is: without OpenMap its
	-- overlay works as before.
	if type(FDJ.RefreshWorldMapOverlay) == "function" and type(FDJ.DetachWorldMapOverlay) == "function" then
		-- (Whether OpenMap is loaded is asked until it is, then kept: an addon loaded stays loaded.)
		local openMap = false
		local function hideWings(...)
			for i = 1, select("#", ...) do
				local child = select(i, ...)
				if ns.Usable(child) and child.fdjWing then child:Hide() end
			end
		end
		hooksecurefunc(FDJ, "RefreshWorldMapOverlay", function()
			if not ns.Enabled() then return end
			if not openMap then
				openMap = (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("OpenMap")) and true or false
				if not openMap then return end
			end
			pcall(FDJ.DetachWorldMapOverlay)
			local toggle = _G.ForeverDungeonJournalWorldMapToggle
			if ns.Usable(toggle) then toggle:Hide() end
			local map = _G.WorldMapFrame
			if ns.Usable(map) then hideWings(map:GetChildren()) end
		end)
	end
end)
