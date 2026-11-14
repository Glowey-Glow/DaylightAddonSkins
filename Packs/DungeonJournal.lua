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
--   * Three more popups inside the journal that DaylightUI's skin walks the same way (and so leaves
--     see-through): the bug report window, the search results list and the language list. The
--     window shell; the results' and languages' gold hover a faint white wash.
--   * The RPG Mode note over the home page (ForeverDungeonJournalRPGIntro): DaylightUI's skin takes
--     its gold frame away and lights its dark ink, which left light words on the parchment. Its
--     parchment goes and it gets the window shell, so the light words read.
--   * The Dungeon Tracker (ForeverDungeonJournalRunTracker): the window shell, its X, its reset
--     button as an icon button, its title in the value ink, its labels in the label ink, its gold
--     line faint and neutral, its size grip without the gold; a boss's loot line (the popup a
--     right-click on a portrait opens) gets the shell too, its items keeping their quality edges.
--     The boss portraits, the rare glow and the glow behind the open boss stay.
--   * The quest trackers (ForeverDungeonJournalQuestTracker, ...2, ...): the copy of the game's
--     Options window frame (or its drawn stand-in) and its plum ground give way to the window
--     shell; its X, title ink, size grip and the rows' gold hover are DaylightUI's. Quest colors
--     (by level) and the plus / minus fold button stay.
--   * The mode chooser shown to new characters and its RPG Mode "are you sure?" box: the window
--     shell; the two option cards quiet flat boxes whose hover is a faint wash, not a gold edge.
--   * Its small right-click menus (journal icon, tracker, Onyxia, Sleeping Bag, Group Finder eye,
--     an item's favorite menu): the window shell, a faint white hover.
--   * Its notes: the "tracker closed" notice, the tracker's two first-time hints, the Group Browser
--     and full-view hints, the Onyxia popup, the plain page-unlocked toast (its parchment sketch
--     kept). Their red and yellow arrows stay. The other toast, a copy of the game's own
--     achievement alert, is left as it is on purpose.
--   * The export, progress export / import and debug copy windows: the window shell, the text well
--     a quiet flat box, their buttons and scroll bars DaylightUI's.
--   * The "Hide quests" box above the boss icon size control on its dungeon maps: a flat box, its
--     check DaylightUI's.
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

-- ---------------------------------------------------------------------------------------------
-- Its windows, notes and menus out on the screen: DaylightUI's journal skin never walks them.
-- Each is dressed once, the first time it's seen.
-- ---------------------------------------------------------------------------------------------

local EDGE = { edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }

local dressed = setmetatable({}, { __mode = "k" })
local function First(obj)
	if dressed[obj] then return false end
	dressed[obj] = true
	return true
end

-- The golds it writes second lines and headings in (1, 0.82, 0.27 and near it), which the game's
-- own gold match doesn't catch: the label ink. Quality and quest colors are never this near.
local function GoldText(frame)
	for _, r in ipairs({ frame:GetRegions() }) do
		if r:GetObjectType() == "FontString" then
			local cr, cg, cb = r:GetTextColor()
			if type(cr) == "number" and cr > 0.95 and cg > 0.74 and cg < 0.86 and cb < 0.4 then Ink(r, "LABEL") end
		end
	end
end

-- Its list and menu buttons light up in the game's gold quest-title glow: a faint white wash.
local function WhiteHovers(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" then
			local hl = child.GetHighlightTexture and child:GetHighlightTexture()
			if ns.Usable(hl) and First(hl) then hl:SetColorTexture(1, 1, 1, 0.06) end
		end
	end
end

-- The gold hover glow it draws itself on a button (a HIGHLIGHT texture): a faint white wash.
local function WhiteGlow(btn)
	if not ns.Usable(btn) or not First(btn) then return end
	for _, r in ipairs({ btn:GetRegions() }) do
		if r:GetObjectType() == "Texture" and r:GetDrawLayer() == "HIGHLIGHT" then r:SetColorTexture(1, 1, 1, 0.06) end
	end
end

-- The chat window's size grabber, without its gold.
local GRIP_ART = { "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture" }
local function Grip(grip)
	if not ns.Usable(grip) or not First(grip) then return end
	for _, get in ipairs(GRIP_ART) do
		local tex = grip[get] and grip[get](grip)
		if ns.Usable(tex) then tex:SetDesaturated(true) end
	end
end

-- A frame of its own with a tooltip-border backdrop: the backdrop off, the window shell on, its X
-- and template buttons dressed, its gold words in DaylightUI's inks on every show.
local function Window(frame, Kit, extra)
	if not ns.Usable(frame) or not First(frame) then return false end
	ns.NoBackdrop(frame)
	ns.Shell(frame, { window = true }, KEY)
	if ns.Controls(KEY) then
		local close = ns.FindClose(frame)
		if close and ns.Once(close) then ns.Guard(Kit.Close, close) end
	end
	ns.DressOnShow(frame, nil, function(f)
		if not ns.Enabled(KEY) then return end
		Kit.InkGameText(f)
		GoldText(f)
		if extra then extra(f) end
	end, KEY)
	return true
end

local function Menu(menu, Kit)
	Window(menu, Kit, WhiteHovers)
end

-- The Dungeon Tracker.
local function Tracker(t, Kit)
	if not Window(t, Kit) then return end
	Ink(t.title, "VALUE")
	for _, key in ipairs({ "timeLabel", "xpLabel", "goldLabel", "raresLabel" }) do Ink(t[key], "LABEL") end
	Quiet(t.line)
	Grip(t.grip)
	if ns.Controls(KEY) and ns.Usable(t.reset) then ns.Guard(Kit.IconButton, t.reset) end
end

-- A quest tracker window. Its frame art is drawn in a frame of its own (artClip), shown and cut to
-- size on every layout, so that frame is faded rather than its pieces hidden. Without the game's
-- art it draws lines and 3 px corner glints on the window itself.
local function QuestRows(f)
	for _, row in ipairs(type(f.rows) == "table" and f.rows or {}) do
		if ns.Usable(row) then
			WhiteGlow(row)
			WhiteGlow(row.step)
			for _, line in ipairs(type(row.chainLines) == "table" and row.chainLines or {}) do WhiteGlow(line) end
		end
	end
end

local function QuestTracker(f, Kit)
	if not ns.Usable(f) or not First(f) then return end
	ns.NoBackdrop(f)
	if ns.Usable(f.artClip) then f.artClip:SetAlpha(0) end
	if not f.art then
		for _, r in ipairs({ f:GetRegions() }) do
			if r:GetObjectType() == "Texture" then
				local layer = r:GetDrawLayer()
				local w, h = r:GetSize()
				if layer == "BACKGROUND" or layer == "BORDER" or (layer == "ARTWORK" and w <= 3.5 and h <= 3.5) then r:SetAlpha(0) end
			end
		end
	end
	ns.Shell(f, { window = true }, KEY)
	if ns.Controls(KEY) and ns.Usable(f.close) and ns.Once(f.close) then ns.Guard(Kit.Close, f.close) end
	Grip(f.grip)
	local header = f.header
	if type(header) == "table" then Ink(header.title, "VALUE") end
	-- Rows are made as quests come in; a new one changes the window's height.
	local later = ns.DressOnShow(f, nil, function()
		if not ns.Enabled(KEY) then return end
		QuestRows(f)
		if ns.Usable(header) then Kit.InkGameText(header) end
	end, KEY)
	if later then f:HookScript("OnSizeChanged", later) end
end

local function QuestTrackers(Kit)
	for i = 1, 20 do
		local f = _G["ForeverDungeonJournalQuestTracker" .. (i > 1 and i or "")]
		if not f then return end
		ns.Guard(QuestTracker, f, Kit)
	end
end

-- The mode chooser's two cards: quiet flat boxes, a faint wash on hover in place of the gold edge
-- its own hover puts on (the hooks run after it).
local function Card(c, Kit)
	if not ns.Usable(c) or not First(c) then return end
	Flat(c, 0.35)
	Ink(c.title, "VALUE")
	c:HookScript("OnEnter", function(self) if ns.Enabled(KEY) then self:SetBackdropBorderColor(1, 1, 1, 0.2) end end)
	c:HookScript("OnLeave", function(self) if ns.Enabled(KEY) then self:SetBackdropBorderColor(1, 1, 1, 0.07) end end)
	if c:GetObjectType() == "Button" then ns.Guard(Kit.HoverWash, c) end
end

local function Chooser(f, Kit)
	if not Window(f, Kit) then return end
	Ink(f.title, "VALUE")
	Ink(f.sub, "LABEL")
	Card(f.gamer, Kit)
	Card(f.rpg, Kit)
end

-- The page-unlocked toast. The plain one (a backdrop window): its gold wash goes, the parchment
-- sketch stays, the gold edge round the sketch a faint line. The other one copies the game's own
-- achievement alert and is left as it is.
local function Toast(t, Kit)
	if not ns.Usable(t) or not (t.GetBackdrop and t:GetBackdrop()) or dressed[t] then return end
	ClearGround(t)
	if not Window(t, Kit) then return end
	for _, child in ipairs({ t:GetChildren() }) do
		if ns.Usable(child) and child.GetBackdrop and child:GetBackdrop() and First(child) then
			child:SetBackdrop(EDGE)
			child:SetBackdropBorderColor(1, 1, 1, 0.12)
		end
	end
end

-- The Onyxia popup: its hover turned its edge gold, which the shell has no edge for: a wash.
local function Onyxia(p, Kit)
	if not Window(p, Kit) then return end
	if p:GetObjectType() == "Button" then ns.Guard(Kit.HoverWash, p) end
end

-- The export and import windows: the text well behind the box a quiet flat box (f.bg, or the export
-- frame's unnamed backdrop child).
local function Export(f, Kit)
	if not Window(f, Kit) then return end
	if ns.Usable(f.bg) then
		Flat(f.bg, 0.35)
		return
	end
	for _, child in ipairs({ f:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Frame" and child.GetBackdrop and child:GetBackdrop() then Flat(child, 0.35) end
	end
end

-- Popups inside the journal that DaylightUI's skin walks like its panels (see Popup). The search
-- results list fills its rows while it's open, each search changing its height.
local function JournalPopups(frame)
	if not ns.Enabled(KEY) or not ns.Usable(frame) then return end
	local results = frame.searchResultsFrame
	if ns.Usable(results) and First(results) then
		Popup(results)
		local queued
		local function rows()
			queued = nil
			if results:IsShown() then WhiteHovers(results) end
		end
		local function later()
			if queued then return end
			queued = true
			C_Timer.After(0, rows)
		end
		results:HookScript("OnShow", later)
		results:HookScript("OnSizeChanged", later)
		later()
	end
	local languages = frame.languageMenu
	if ns.Usable(languages) and First(languages) then
		Popup(languages)
		WhiteHovers(languages)
	end
	local intro = _G.ForeverDungeonJournalRPGIntro
	if ns.Usable(intro) and ns.Usable(intro.note) and First(intro.note) then Popup(intro.note) end
end

-- The "Hide quests" box on its dungeon maps, as the boss icon size control under it.
local function QuestToggle(q, Kit)
	if not First(q) then return end
	Flat(q, 0.6)
	Ink(q.label, "LABEL")
	if ns.Controls(KEY) and ns.Usable(q.check) then ns.Guard(Kit.Check, q.check) end
end

local MENU_NAMES = { "ForeverDungeonJournalRunLogMenu", "ForeverDungeonJournalTrackerMenu",
	"ForeverDungeonJournalOnyxiaMenu", "ForeverDungeonJournalSleepingBagMenu", "ForeverDungeonJournalLFGMenu",
	"ForeverDungeonJournalFavouriteContextMenu" }

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

	-- What its exported functions make or show: dressed right after they run, in the frame it first
	-- shows. (Each frame is dressed once; a later call only looks it up.)
	local function After(name, get, fn)
		if type(FDJ[name]) ~= "function" then return end
		hooksecurefunc(FDJ, name, function(...)
			if not ns.Enabled(KEY) then return end
			local f = get(...)
			if ns.Usable(f) then ns.Guard(fn, f, Kit) end
		end)
	end
	local function Global(name) return function() return _G[name] end end
	local function Field(name) return function() return FDJ[name] end end
	local function TrackerLoot()
		local t = _G.ForeverDungeonJournalRunTracker
		return type(t) == "table" and t.lootRow or nil
	end
	After("TrackerLootToggle", TrackerLoot, Window)
	After("ShowTrackerMenu", Global("ForeverDungeonJournalTrackerMenu"), Menu)
	After("ShowLFGMenu", Field("lfgMenu"), Menu)
	After("ShowItemFavouriteMenu", Field("favouriteContextMenu"), Menu)
	After("ShowBrowseHint", Field("browseHint"), Window)
	After("ShowOnyxiaPopup", Global("ForeverDungeonJournalOnyxiaPopup"), Onyxia)
	After("ShowModeChooser", Global("ForeverDungeonJournalModeChooser"), Chooser)
	After("ShowRPGConfirm", Global("ForeverDungeonJournalRPGConfirm"), Window)
	After("ShowExportDialog", Global("FDJExportFrame"), Export)
	After("ShowProgressExport", Global("FDJProgressExportFrame"), Export)
	After("ShowProgressImport", Global("FDJProgressImportFrame"), Export)
	After("ShowCopyBox", Field("copyBox"), Window)
	After("ToggleBugReportWindow", function(frame) return type(frame) == "table" and frame.bugReportWindow or nil end, Popup)
	After("UpdateMapQuestToggle", function(panel) return type(panel) == "table" and panel.fdjQuestToggle or nil end, QuestToggle)
	-- The home page header is laid out again after every home refresh; the RPG Mode note is made
	-- the first time it's due.
	After("UpdateRPGHeader", function(frame) return frame end, JournalPopups)

	-- The tracker is made the first time a run is tracked, its two hints the first time they're
	-- due; all three in UpdateRunTracker, which runs every second while it's up (here: three
	-- lookups until all three are found, then nothing).
	if type(FDJ.UpdateRunTracker) == "function" then
		local tracker, trackerHint, bossHint, all
		hooksecurefunc(FDJ, "UpdateRunTracker", function()
			if all or not ns.Enabled(KEY) then return end
			if not tracker then
				tracker = _G.ForeverDungeonJournalRunTracker
				if tracker then ns.Guard(Tracker, tracker, Kit) end
			end
			if not trackerHint then
				trackerHint = FDJ.trackerHint
				if trackerHint then ns.Guard(Window, trackerHint, Kit) end
			end
			if not bossHint then
				bossHint = FDJ.bossHint
				if bossHint then ns.Guard(Window, bossHint, Kit) end
			end
			all = (tracker and trackerHint and bossHint) and true or false
		end)
	end

	-- The quest trackers: redrawn through RefreshQuestTracker (and a moment after the Track button,
	-- which redraws on the next frame from a local of its own).
	if type(FDJ.RefreshQuestTracker) == "function" then
		hooksecurefunc(FDJ, "RefreshQuestTracker", function()
			if ns.Enabled(KEY) then QuestTrackers(Kit) end
		end)
	end
	if type(FDJ.ToggleQuestTracking) == "function" then
		hooksecurefunc(FDJ, "ToggleQuestTracking", function()
			C_Timer.After(0.1, function()
				if ns.Enabled(KEY) then QuestTrackers(Kit) end
			end)
		end)
	end

	-- Made by functions of its own that can't be hooked: looked out for by name (or field).
	ns.Watch(KEY, "ForeverDungeonJournalQuestTracker", function(_, K) QuestTrackers(K) end)
	for _, name in ipairs(MENU_NAMES) do ns.Watch(KEY, name, Menu) end
	ns.Watch(KEY, "ForeverDungeonJournalTrackerClosedNotice", Window)
	ns.Watch(KEY, "ForeverDungeonJournalUnlockToast", Toast)
	ns.Watch(KEY, function() return FDJ.foreverHint end, Window)
	ns.Watch(KEY, "ForeverDungeonJournalRPGIntro", function()
		JournalPopups(_G.ForeverDungeonJournalFrame)
	end)
	ns.Watch(KEY, "ForeverDungeonJournalFrame", function(frame)
		JournalPopups(frame)
		frame:HookScript("OnShow", JournalPopups)
	end)
end)
