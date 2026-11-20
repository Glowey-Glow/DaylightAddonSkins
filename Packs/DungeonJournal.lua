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
--   * The RPG Mode "I already did this dungeon" box (2.0.8, from a locked page or the button under
--     a hidden boss): the window shell in place of its gold dialog edge, its two buttons
--     DaylightUI's (the box made wider when DaylightUI's button font needs it), its title in the
--     value ink, the dungeon's gold name in the value ink.
--   * An item set's row of pieces (2.0.8, a click on a set piece): the window shell in place of its
--     tooltip edge; the piece you clicked framed in the accent, not gold (the others keep their
--     quality edge); a faint white hover.
--   * The Loot Filter's "no items match" panel (a popup inside the journal, see Loot Filter): the
--     window shell, its title in the value ink.
--   * The one-time update notice it shows after login: the window shell, its button DaylightUI's.
--   * 2.0.10: the Loot Filter's Armor slot box (beside the armor list) gets the shell like the other
--     lists, and all of the filter's lists light with a faint white wash, not the gold glow. The
--     "Searching the loot... 42%" box: the shell, its words in the value ink, its bar DaylightUI's
--     in the accent. The resize notes (Options > General > Resize): the shell, the text ink, their
--     glow in the accent, OK DaylightUI's (their yellow arrows stay). The Tier Sets page: its Show
--     Classes list the shell with a white wash, its Compact view button's glow a wash; the Tier Sets
--     icon's Hide menu and a piece's "who drops it" box the window shell. The rest of the page
--     (rows, pieces, quality colors, ticks) is DaylightUI's journal skin's.
--   * 2.1.0, on a quest's page (DaylightUI's journal skin writes every line there in its text ink):
--     the red lines keep a warning color (the "must be summoned" line, the warning at the top, the
--     chain notice, and 2.1.0's line under the objective), "Requires Neutral with ..." is green or
--     red by whether you have the standing, the reputation bar under it is DaylightUI's (its standing
--     color kept), and the mark round a required item from this dungeon is the accent, not a plain
--     edge. None of it is touched while DaylightUI's journal skin is off.
--   * The two buttons under its arrow ("Not found? Next spot", and 2.1.0's "Skip for now"):
--     DaylightUI's, made wider when its font needs it. The arrow, its words and its item button are
--     its own.
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
		ns.ScriptOnce(frame, "OnShow", function() Settle(fix) end, KEY)
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
	if ns.Usable(r.sel) then ns.FillAccent(r.sel, 0.16, nil, KEY) end
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
		ns.HookOnce(FDJ, "RefreshRunLog", later, KEY)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Loot Filter
-- ---------------------------------------------------------------------------------------------

local MENUS = { "armor", "weapon", "schoolArrow", "resist" }

-- Its list and menu buttons light up in the game's gold quest-title glow: a faint white wash.
local washed = setmetatable({}, { __mode = "k" })
local function WhiteHovers(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" then
			local hl = child.GetHighlightTexture and child:GetHighlightTexture()
			if ns.Usable(hl) and not washed[hl] then
				washed[hl] = true
				hl:SetColorTexture(1, 1, 1, 0.06)
			end
		end
	end
end

-- One of its tick lists (a backdrop box under a button): the shell, its rows' gold glow a wash.
local function TickMenu(menu)
	if not ns.Usable(menu) then return end
	Popup(menu)
	WhiteHovers(menu)
end

local function LootFilter(win)
	if not ns.Usable(win) or not ns.Once(win) then return end
	local function menus()
		if not ns.Enabled(KEY) then return end
		for _, key in ipairs(MENUS) do
			local b = win[key]
			if type(b) == "table" then
				TickMenu(b.menu)
				-- The Armor list's slot box beside it (2.0.10: Head, Shoulder ... Feet).
				TickMenu(b.slotMenu)
			end
		end
		if ns.Usable(win.fdjTip) then Popup(win.fdjTip) end
	end
	Popup(win)
	-- (Plain HookScript: Popup has hooked its OnShow through ns.ScriptOnce.)
	win:HookScript("OnShow", menus)
	menus()
	-- Its stat tip is made the first time a stat is hovered.
	if type(win.statChecks) == "table" then
		for _, check in pairs(win.statChecks) do
			if ns.Usable(check) and check.HookScript then ns.ScriptOnce(check, "OnEnter", menus, KEY) end
		end
	end
end

-- Its "no items match" panel over the journal (made the first time a filter finds nothing): the
-- shell like the filter's own popup, its gold title in the value ink after DaylightUI's walk.
local function NoMatch(panel)
	Popup(panel)
	Settle(function()
		if ns.Enabled(KEY) then Ink(panel.title, "VALUE") end
	end)
end

-- The "Searching the loot... 42%" box over the journal (2.0.10, made the first time a filter with
-- stats or resistances ticked is shown): the shell like the filter's popup, its gold words in the
-- value ink, its gold bar DaylightUI's in the accent.
local function Loading(box, Kit)
	Popup(box)
	local bar = box.bar
	if ns.Controls(KEY) and ns.Usable(bar) and bar:GetObjectType() == "StatusBar" then
		if ns.Once(bar) then ns.Guard(Kit.StatusBar, bar) end
		bar:SetStatusBarColor(ns.AccentOf(KEY))
	end
	Settle(function()
		if ns.Enabled(KEY) then Ink(box.text, "VALUE") end
	end)
end

-- The "Drag the corners to resize" notes (2.0.10, Options > General > Resize), one by each corner
-- of the journal and inside it, so DaylightUI's skin walks them and leaves them see-through: the
-- shell, their white words in the text ink, their OK DaylightUI's. Their flashing gold glow in the
-- accent; their yellow arrows stay. (Told apart from the journal's other children by the corner and
-- handle it keeps on each.)
local function ResizeNotes(frame, Kit)
	if not ns.Usable(frame) then return end
	for _, n in ipairs({ frame:GetChildren() }) do
		if ns.Usable(n) and type(n.corner) == "table" and n.handle and ns.Usable(n.ok) then
			Popup(n)
			Ink(n.text, "TEXT")
			-- (Its OnUpdate sets the glow's alpha every frame, never its color.)
			if ns.Usable(n.glow) then ns.PaintAccent(n.glow, 1, nil, KEY) end
			if ns.Controls(KEY) and ns.Once(n.ok) then ns.Guard(Kit.Button, n.ok) end
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
	if later then ns.ScriptOnce(f, "OnSizeChanged", later, KEY) end
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
	ns.ScriptOnce(c, "OnEnter", function(self) if ns.Enabled(KEY) then self:SetBackdropBorderColor(1, 1, 1, 0.2) end end, KEY)
	ns.ScriptOnce(c, "OnLeave", function(self) if ns.Enabled(KEY) then self:SetBackdropBorderColor(1, 1, 1, 0.07) end end, KEY)
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
		local function rows()
			if results:IsShown() then WhiteHovers(results) end
		end
		local function later()
			ns.Queue("ForeverDungeonJournal:results", rows, KEY)
		end
		-- (Plain HookScript: Popup has hooked its OnShow through ns.ScriptOnce.)
		results:HookScript("OnShow", later)
		ns.ScriptOnce(results, "OnSizeChanged", later, KEY)
		later()
	end
	local languages = frame.languageMenu
	if ns.Usable(languages) and First(languages) then
		Popup(languages)
		WhiteHovers(languages)
	end
	local intro = _G.ForeverDungeonJournalRPGIntro
	if ns.Usable(intro) and ns.Usable(intro.note) and First(intro.note) then Popup(intro.note) end
	-- "Show all dungeons anyway" under an empty level range (2.0.9): its gold hover a white wash.
	WhiteGlow(frame.homeShowAllButton)
end

-- The "Hide quests" box on its dungeon maps, as the boss icon size control under it.
local function QuestToggle(q, Kit)
	if not First(q) then return end
	Flat(q, 0.6)
	Ink(q.label, "LABEL")
	if ns.Controls(KEY) and ns.Usable(q.check) then ns.Guard(Kit.Check, q.check) end
end

-- One of DaylightUI's inks as an inline color code.
local function Hex(ink)
	local c = ns.Colors()[ink]
	if not c then return nil end
	return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end

-- The RPG Mode "I already did this dungeon" box. It writes the dungeon's name in gold inline each
-- time it fills its words (a click on its own buttons fills them again, through no call of its own
-- that can be hooked): the gold is swapped as the words are set.
local GOLD_NAME = "|cffffd100"
local function ValueName(fs)
	if not ns.Usable(fs) or fs.dasRecoding or not ns.Enabled(KEY) then return end
	local text, hex = fs:GetText(), Hex("VALUE")
	if type(text) ~= "string" or not hex then return end
	local out = string.gsub(text, GOLD_NAME, hex)
	if out == text then return end
	fs.dasRecoding = true
	fs:SetText(out)
	fs.dasRecoding = nil
end

-- It sizes its two buttons, and the box round them, to their words before the box is first dressed;
-- DaylightUI's button font can be wider. A button its words outgrow is widened and the box laid out
-- again the way it does it (the row centered, 34 px each side, its heights from top to bottom).
local DONE_GAP, DONE_SIDE = 12, 34
local function RefitDone(box)
	local ok, back = box.ok, box.back
	if not (ns.Usable(ok) and ns.Usable(back)) then return end
	local grew = false
	for _, b in ipairs({ ok, back }) do
		local fs = b:IsShown() and b.GetFontString and b:GetFontString()
		local need = fs and math.ceil((fs:GetStringWidth() or 0) + 36) or 0
		if need > (b:GetWidth() or 0) then
			b:SetWidth(need)
			grew = true
		end
	end
	if not grew then return end
	local single = not ok:IsShown()
	local row = single and back:GetWidth() or (ok:GetWidth() + DONE_GAP + back:GetWidth())
	local width = math.max(box:GetWidth() or 400, math.ceil(row + 2 * DONE_SIDE))
	box:SetWidth(width)
	if not single then
		ok:ClearAllPoints()
		ok:SetPoint("BOTTOMLEFT", box, "BOTTOM", -row / 2, 18)
	end
	local title, text = box.title, box.text
	if not (ns.Usable(title) and ns.Usable(text)) then return end
	title:SetWidth(width - 2 * DONE_SIDE)
	text:SetWidth(width - 2 * DONE_SIDE)
	text:SetHeight(0)
	local textHeight = math.max(text:GetStringHeight() or 0, 12)
	text:SetHeight(textHeight)
	local titleHeight = math.max(title:GetStringHeight() or 0, 16)
	box:SetHeight(math.ceil(22 + titleHeight + 8 + textHeight + 16 + 24 + 18))
end

local function RPGDone(box, Kit)
	if Window(box, Kit) then
		Ink(box.title, "VALUE")
		if ns.Usable(box.text) then ns.HookOnce(box.text, "SetText", ValueName, KEY) end
	end
	ValueName(box.text)
	RefitDone(box)
end

-- An item set's row of pieces (made the first time a set piece is clicked, filled again on every
-- show): the shell once; on each fill the piece you clicked framed in the accent and the hovers
-- white.
local function SetStrip(strip, owner)
	if ns.Once(strip) then
		ns.NoBackdrop(strip)
		ns.Shell(strip, { window = true }, KEY)
	end
	local item = type(owner) == "table" and owner.item
	local current = type(item) == "table" and tonumber(item[1]) or nil
	for _, c in ipairs(type(strip.cells) == "table" and strip.cells or {}) do
		if ns.Usable(c) and c:IsShown() then
			if current and c.id == current and ns.Usable(c.edge) then ns.FillAccent(c.edge, 1, nil, KEY) end
			local hl = c.GetHighlightTexture and c:GetHighlightTexture()
			if ns.Usable(hl) and First(hl) then hl:SetColorTexture(1, 1, 1, 0.1) end
		end
	end
end

-- The Tier Sets page (2.0.10, on the journal's home page): its Show Classes tick list drops over the
-- page and DaylightUI's skin walks it like a panel (see-through): the shell, its rows' gold glow a
-- wash; its Compact view button's blue glow a wash too.
local function TierPage(panel)
	if not ns.Enabled(KEY) or not ns.Usable(panel) then return end
	local classes = panel.classes
	if type(classes) == "table" then TickMenu(classes.menu) end
	WhiteGlow(panel.compact)
end

-- ---------------------------------------------------------------------------------------------
-- A quest's page. DaylightUI's journal skin writes every line of it in its text ink on each of its
-- passes (a click anywhere in the journal, item data coming in, the page drawn again), which takes
-- the meaning out of the lines the journal colors: its dark red warnings, and (2.1.0) the green or
-- red "Requires <standing> with <faction>". Those are held in DaylightUI's warning and done inks:
-- each time one is colored, by the journal (its own dark red or green, which says which it is) or
-- by DaylightUI's skin (anything else), it's put back. While DaylightUI's journal skin is off only
-- the journal colors them, and they stay as it draws them.
-- ---------------------------------------------------------------------------------------------

local kept = setmetatable({}, { __mode = "k" })   -- font string -> the ink it's held in
local keeping = false

local function Rekeep(fs, r, g, b)
	if keeping or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return end
	-- The journal's own: 0.05, 0.42, 0.05 (you have the standing) and 0.62, 0.10, 0.05 (a warning).
	if r < 0.2 and g > 0.3 and b < 0.2 then
		kept[fs] = "GOOD"
		return
	elseif r > 0.5 and g < 0.2 and b < 0.2 then
		kept[fs] = "BAD"
		return
	end
	local c = ns.Colors()[kept[fs] or "BAD"]
	if not c or (r == c[1] and g == c[2] and b == c[3]) then return end
	keeping = true
	fs:SetTextColor(c[1], c[2], c[3])
	keeping = false
end

local function KeepInk(fs)
	if not ns.Usable(fs) or fs:GetObjectType() ~= "FontString" then return end
	if kept[fs] == nil then
		kept[fs] = "BAD"
		ns.HookOnce(fs, "SetTextColor", Rekeep, KEY)
	end
	Rekeep(fs, fs:GetTextColor())
end

-- The page's red lines, by the keys the journal keeps them under.
local WARNINGS = { "questSummonNote", "questWarningText", "questChainNotice", "questObjectiveNoteText" }

-- (2.1.0) A required item that comes from the dungeon whose page this is has a gold edge round its
-- card. DaylightUI's journal skin swaps that for one of its plain outlines, like any box: lit in
-- the accent, so the mark still reads. (The outline is DaylightUI's skin's; without it the gold
-- stays.)
local function HereMarks(Kit)
	local f = _G.ForeverDungeonJournalFrame
	if not ns.Usable(f) or type(Kit.ShellOf) ~= "function" then return end
	local accent
	for _, b in ipairs(type(f.questStepItemButtons) == "table" and f.questStepItemButtons or {}) do
		local glow = type(b) == "table" and b.fdjHereGlow
		if ns.Usable(glow) and glow:IsShown() then
			local s = Kit.ShellOf(glow)
			if s then
				-- (A new table each time: the shell keeps the one it was painted with.)
				accent = accent or { ns.AccentOf(KEY) }
				ns.LightShell(s, accent, KEY)
			end
		end
	end
end

-- (2.1.0) A quest that needs a reputation: its "Requires ..." line held like the warnings, its
-- bar (a plain status bar in the game's bar art with a dark edge) DaylightUI's. The journal colors
-- the bar by standing on every draw, which stays.
local function RepNeeds(Kit)
	local f = _G.ForeverDungeonJournalFrame
	if not ns.Usable(f) or type(f.fdjRepRows) ~= "table" then return end
	for _, row in ipairs(f.fdjRepRows) do
		if type(row) == "table" then
			KeepInk(row.text)
			local bar = row.bar
			if ns.Controls(KEY) and ns.Usable(bar) and bar:GetObjectType() == "StatusBar" and First(bar) then
				ns.Guard(Kit.StatusBar, bar)
			end
		end
	end
end

-- The buttons under its arrow (ForeverDungeonJournalArrow, out on the screen): "Not found? Next
-- spot (2/3)" and (2.1.0) "Skip for now", the game's red buttons: DaylightUI's. It sizes them for
-- the game's font; one DaylightUI's font outgrows is widened (they hang centered under the arrow).
local function FitButton(b)
	local fs = b.GetFontString and b:GetFontString()
	local need = fs and math.ceil((fs:GetStringWidth() or 0) + 24) or 0
	if need > (b:GetWidth() or 0) then b:SetWidth(need) end
end

local function Arrow(f, Kit)
	if not ns.Usable(f) or not ns.Controls(KEY) then return end
	for _, key in ipairs({ "nextSpawn", "skipNow" }) do
		local b = f[key]
		if ns.Usable(b) and b:GetObjectType() == "Button" and First(b) then
			ns.Guard(Kit.Button, b)
			ns.ScriptOnce(b, "OnShow", FitButton, KEY)
			ns.HookOnce(b, "SetText", FitButton, KEY)
			FitButton(b)
		end
	end
end

local MENU_NAMES = { "ForeverDungeonJournalRunLogMenu", "ForeverDungeonJournalTrackerMenu",
	"ForeverDungeonJournalOnyxiaMenu", "ForeverDungeonJournalSleepingBagMenu", "ForeverDungeonJournalLFGMenu",
	"ForeverDungeonJournalFavouriteContextMenu", "ForeverDungeonJournalTierMenu" }

-- ---------------------------------------------------------------------------------------------
-- Its own fonts: since 2.0.8 the journal draws its words with copies of the game's font objects
-- (ForeverDJ_<name>, Core/Fonts.lua) carrying the game's Friz Quadrata and Morpheus files by
-- name, so neither DaylightUI's font nor its journal skin reaches them. Those copies take the
-- player's font (their size and outline kept), where it has this client's letters (ns.SafeFace);
-- each one's own Korean / Chinese / Russian member is never touched. The ones
-- changed are remembered (with the size and outline they had), so a new DaylightUI font follows.
-- They stay changed until the next login if the skin is turned off.
-- ---------------------------------------------------------------------------------------------

local ownChanged = {}   -- font object -> { size, flags } it had before

local function GameSerif(path)
	if type(path) ~= "string" then return false end
	path = string.lower(path)
	return string.find(path, "frizqt__", 1, true) ~= nil or string.find(path, "morpheus", 1, true) ~= nil
end

local function OwnFontsInDaylight()
	if not ns.Enabled(KEY) then return end
	local face = ns.PlayerFace()
	if not face then return end
	local FDJ = _G.ForeverDungeonJournal_NS
	local own = type(FDJ) == "table" and FDJ.OwnFontObjects
	if type(own) ~= "table" then return end
	local prefix = type(FDJ.OWN_FONT_PREFIX) == "string" and FDJ.OWN_FONT_PREFIX or "ForeverDJ_"
	for name in pairs(own) do
		local font = _G[prefix .. name]
		-- (A font family: its Latin member is the one these locales draw with.)
		if type(font) == "table" and type(font.GetFontObjectForAlphabet) == "function" then
			local okM, member = pcall(font.GetFontObjectForAlphabet, font, "roman")
			if okM and type(member) == "table" then font = member end
		end
		if type(font) == "table" and type(font.GetFont) == "function" and type(font.SetFont) == "function" then
			local was = ownChanged[font]
			if not was then
				local ok, path, size, flags = pcall(font.GetFont, font)
				if ok and GameSerif(path) and type(size) == "number" and size > 0 then
					was = { size, flags or "" }
					ownChanged[font] = was
				end
			end
			if was then pcall(font.SetFont, font, face, was[1], was[2]) end
		end
	end
end

-- A new DaylightUI font (or text style): the copies follow.
ns.me.On("StyleChanged", function() ns.Guard(OwnFontsInDaylight) end)

-- Every window here is made the first time it opens, so each is dressed right after the call or
-- click that makes or opens it, in the same frame it first shows; the look-out by name stays as the
-- fallback. Each is dressed once either way.
ns.Pack(KEY, nil, function(Kit)
	OwnFontsInDaylight()
	ns.Watch(KEY, "ForeverDungeonJournalRunLog", RunLog)
	ns.Watch(KEY, "ForeverDungeonJournalLootFilter", LootFilter)
	local FDJ = _G.ForeverDungeonJournal_NS
	if type(FDJ) ~= "table" then return end
	if type(FDJ.ToggleRunLog) == "function" then
		ns.HookOnce(FDJ, "ToggleRunLog", function()
			local win = _G.ForeverDungeonJournalRunLog
			if ns.Enabled(KEY) and ns.Usable(win) then ns.Guard(RunLog, win, Kit) end
		end, KEY)
	end
	-- A quest's page ends in ApplyQuestDetailScroll, with every line of it placed: its red lines
	-- (2.0.9's "must be summoned", 2.1.0's line under the objective, the older warnings) are held in
	-- the warning ink from there on (see KeepInk), and the mark round this dungeon's items is lit a
	-- frame later, once DaylightUI's skin has put its outline there.
	if type(FDJ.ApplyQuestDetailScroll) == "function" then
		local function marks() HereMarks(Kit) end
		ns.HookOnce(FDJ, "ApplyQuestDetailScroll", function()
			local f = _G.ForeverDungeonJournalFrame
			if not ns.Usable(f) then return end
			for _, key in ipairs(WARNINGS) do KeepInk(f[key]) end
			ns.Queue("ForeverDungeonJournal:here", marks, KEY)
		end, KEY)
	end
	-- (2.1.0) A quest's reputation needs are placed (and colored) inside this call.
	if type(FDJ.PlaceRepNeeds) == "function" then
		ns.HookOnce(FDJ, "PlaceRepNeeds", function() RepNeeds(Kit) end, KEY)
	end
	-- The boss icon size control on its dungeon maps (the journal's, and the world map's in a
	-- dungeon): a flat box, DaylightUI's - and + buttons, its label in the label ink.
	if type(FDJ.UpdateMapBossSizer) == "function" then
		ns.HookOnce(FDJ, "UpdateMapBossSizer", function(panel)
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
		end, KEY)
	end
	if type(FDJ.ToggleLootFilterWindow) == "function" then
		ns.HookOnce(FDJ, "ToggleLootFilterWindow", function(frame)
			local win = type(frame) == "table" and frame.lootFilterWindow or _G.ForeverDungeonJournalLootFilter
			if ns.Enabled(KEY) and ns.Usable(win) then ns.Guard(LootFilter, win) end
		end, KEY)
	end
	-- Its loot search box shows with the first step of a search, inside this call.
	if type(FDJ.ShowLootFilterResults) == "function" then
		ns.HookOnce(FDJ, "ShowLootFilterResults", function(frame)
			local box = type(frame) == "table" and frame.lootFilterLoading
			if ns.Enabled(KEY) and ns.Usable(box) then ns.Guard(Loading, box, Kit) end
		end, KEY)
	end
	-- The resize notes are made and shown inside this call.
	if type(FDJ.StartResizeMode) == "function" then
		ns.HookOnce(FDJ, "StartResizeMode", function()
			if ns.Enabled(KEY) then ns.Guard(ResizeNotes, _G.ForeverDungeonJournalFrame, Kit) end
		end, KEY)
	end
	-- The Tier Sets page is made the first time it opens (its icon, a piece's Back to Tiers).
	if type(FDJ.OpenTierPage) == "function" then
		ns.HookOnce(FDJ, "OpenTierPage", function()
			ns.Guard(TierPage, _G.ForeverDungeonJournalTierPanel)
		end, KEY)
	end
	if type(FDJ.ShowLootFilterList) == "function" then
		ns.HookOnce(FDJ, "ShowLootFilterList", function(frame)
			local panel = type(frame) == "table" and frame.lootFilterResults
			if ns.Enabled(KEY) and ns.Usable(panel) then ns.Guard(NoMatch, panel) end
		end, KEY)
	end
	-- An item set's row: filled (and shown) on every hover of a set piece once it was clicked.
	if type(FDJ.UpdateSetStrip) == "function" then
		ns.HookOnce(FDJ, "UpdateSetStrip", function(owner)
			local strip = FDJ.setStrip
			if ns.Enabled(KEY) and ns.Usable(strip) and strip:IsShown() then ns.Guard(SetStrip, strip, owner) end
		end, KEY)
	end
	-- Inside a dungeon, both Dungeon Journal and OpenMap lay a dungeon map over the world map, one on
	-- top of the other (its floor buttons, its "World Map" toggle and its boss icon size poking
	-- through OpenMap's). The player picked OpenMap's (2026-11-12): while OpenMap is loaded, each
	-- time the journal puts its overlay up it's taken back down at once (through its own
	-- DetachWorldMapOverlay, so its map panel goes home to the journal), and its toggle and Scarlet
	-- Monastery wing buttons are hidden. Its own setting is left as it is: without OpenMap its
	-- overlay works as before.
	-- Since OpenMap 0.8.10 OpenMap steps aside inside a dungeon Dungeon Journal knows (its #302), so
	-- in a dungeon the journal's overlay stays (else there'd be no dungeon map at all); OpenMap's
	-- map of a dungeon opened there (its view up) still wins.
	if type(FDJ.RefreshWorldMapOverlay) == "function" and type(FDJ.DetachWorldMapOverlay) == "function" then
		-- (Whether OpenMap is loaded is asked until it is, then kept: an addon loaded stays loaded.)
		local openMap = false
		local function hideWings(...)
			for i = 1, select("#", ...) do
				local child = select(i, ...)
				if ns.Usable(child) and child.fdjWing then child:Hide() end
			end
		end
		-- (Plain hooksecurefunc: not looks but the overlay handed to OpenMap, so it follows the
		-- Skins module alone, not this pack's switch or its errors.)
		hooksecurefunc(FDJ, "RefreshWorldMapOverlay", function()
			if not ns.Enabled() then return end
			if not openMap then
				openMap = (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("OpenMap")) and true or false
				if not openMap then return end
			end
			local inDungeon = IsInInstance and select(2, IsInInstance())
			if (inDungeon == "party" or inDungeon == "raid") then
				local view = _G.OpenMapDungeonView
				if not (ns.Usable(view) and view:IsShown()) then return end
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
		ns.HookOnce(FDJ, name, function(...)
			if not ns.Enabled(KEY) then return end
			local f = get(...)
			if ns.Usable(f) then ns.Guard(fn, f, Kit) end
		end, KEY)
	end
	local function Global(name) return function() return _G[name] end end
	local function Field(name) return function() return FDJ[name] end end
	-- What its own click scripts open (a small menu, a note), from functions it keeps to itself: the
	-- button that opens it is hooked once, when it's found, and what it opened is dressed right after
	-- the click, in the same frame.
	local clicked = setmetatable({}, { __mode = "k" })
	local function AfterClick(btn, script, get, fn)
		if not ns.Usable(btn) or not btn.HookScript or clicked[btn] then return end
		clicked[btn] = true
		ns.ScriptOnce(btn, script, function()
			if not ns.Enabled(KEY) then return end
			local f = get()
			if ns.Usable(f) then ns.Guard(fn, f, Kit) end
		end, KEY)
	end
	-- The home page's icons, made with its header: the Character Logs, Sleeping Bag and Onyxia
	-- icons' right-click menus, and the Forever emblem's "back to full view" note.
	local function HomeIcons(frame)
		if type(frame) ~= "table" then return end
		AfterClick(frame.runLogButton, "OnClick", Global("ForeverDungeonJournalRunLogMenu"), Menu)
		AfterClick(frame.sleepingBagButton, "OnClick", Global("ForeverDungeonJournalSleepingBagMenu"), Menu)
		AfterClick(frame.onyxiaButton, "OnClick", Global("ForeverDungeonJournalOnyxiaMenu"), Menu)
		AfterClick(frame.foreverFilterButton, "OnClick", Field("foreverHint"), Window)
		-- (2.0.10: a right-click on the Tier Sets icon opens its Hide menu.)
		AfterClick(frame.tierButton, "OnClick", Global("ForeverDungeonJournalTierMenu"), Menu)
	end
	-- The tracker's own openers: a right-click on it or its top opens its menu, its X the "tracker
	-- closed" notice. (A right-click on a rare's portrait opens the menu too; those are left to the
	-- look-out below.)
	local function TrackerOpeners(t)
		local menu = Global("ForeverDungeonJournalTrackerMenu")
		AfterClick(t, "OnMouseUp", menu, Menu)
		AfterClick(t.handle, "OnMouseUp", menu, Menu)
		AfterClick(ns.FindClose(t), "OnClick", Global("ForeverDungeonJournalTrackerClosedNotice"), Window)
	end
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
	After("ShowRPGDoneBox", Global("ForeverDungeonJournalRPGDone"), RPGDone)
	After("ShowExportDialog", Global("FDJExportFrame"), Export)
	After("ShowProgressExport", Global("FDJProgressExportFrame"), Export)
	After("ShowProgressImport", Global("FDJProgressImportFrame"), Export)
	After("ShowCopyBox", Field("copyBox"), Window)
	-- A Tier Sets piece's "who drops it" box (2.0.10): the shell, its gold boss names in the label ink.
	After("ShowTierSourceTip", Global("ForeverDungeonJournalTierSourceTip"), Window)
	-- Its arrow is made the first time it has somewhere to point (a click on a quest's Show on Map,
	-- a Route step), its buttons with it.
	After("FollowWaypoint", Global("ForeverDungeonJournalArrow"), Arrow)
	After("SetWaypointArrow", Global("ForeverDungeonJournalArrow"), Arrow)
	After("ToggleBugReportWindow", function(frame) return type(frame) == "table" and frame.bugReportWindow or nil end, Popup)
	After("UpdateMapQuestToggle", function(panel) return type(panel) == "table" and panel.fdjQuestToggle or nil end, QuestToggle)
	-- The home page header is laid out again after every home refresh; the RPG Mode note is made
	-- the first time it's due, and the header's icons the first time it's laid out.
	After("UpdateRPGHeader", function(frame) return frame end, function(frame)
		JournalPopups(frame)
		HomeIcons(frame)
	end)
	-- The page-unlocked toast: shown just before the home cards are refreshed (a page opening), or
	-- through its map toast call.
	local function UnlockToast() return _G.ForeverDungeonJournalUnlockToast end
	After("RefreshHomeCards", UnlockToast, Toast)
	After("RPGToast", UnlockToast, Toast)

	-- The tracker is made the first time a run is tracked, its two hints the first time they're
	-- due; all three in UpdateRunTracker, which runs every second while it's up (here: three
	-- lookups until all three are found, then nothing).
	if type(FDJ.UpdateRunTracker) == "function" then
		local tracker, trackerHint, bossHint, all
		ns.HookOnce(FDJ, "UpdateRunTracker", function()
			if all or not ns.Enabled(KEY) then return end
			if not tracker then
				tracker = _G.ForeverDungeonJournalRunTracker
				if tracker then
					ns.Guard(Tracker, tracker, Kit)
					TrackerOpeners(tracker)
				end
			end
			if not trackerHint then
				trackerHint = FDJ.trackerHint
				if trackerHint then
					ns.Guard(Window, trackerHint, Kit)
					-- (A right-click on it opens the tracker's menu.)
					AfterClick(trackerHint, "OnClick", Global("ForeverDungeonJournalTrackerMenu"), Menu)
				end
			end
			if not bossHint then
				bossHint = FDJ.bossHint
				if bossHint then ns.Guard(Window, bossHint, Kit) end
			end
			all = (tracker and trackerHint and bossHint) and true or false
		end, KEY)
	end

	-- The quest trackers: redrawn through RefreshQuestTracker and ToggleQuestTracking (the Track
	-- buttons), both dressed right after they run; a moment after the Track button too, for a redraw
	-- it leaves for the next frame.
	if type(FDJ.RefreshQuestTracker) == "function" then
		ns.HookOnce(FDJ, "RefreshQuestTracker", function()
			if ns.Enabled(KEY) then QuestTrackers(Kit) end
		end, KEY)
	end
	if type(FDJ.ToggleQuestTracking) == "function" then
		ns.HookOnce(FDJ, "ToggleQuestTracking", function()
			if ns.Enabled(KEY) then QuestTrackers(Kit) end
			C_Timer.After(0.1, function()
				if ns.Enabled(KEY) then QuestTrackers(Kit) end
			end)
		end, KEY)
	end

	-- The look-out by name (or field), as the safety net for all of the above. It's the only way
	-- for two of them: the quest trackers its next-frame redraw makes after quest log events (from a
	-- frame of its own with no name), and the quest page toast (from a quest accepted or turned in).
	-- Either is found in the frame it's made, or at worst the next.
	ns.Watch(KEY, "ForeverDungeonJournalQuestTracker", function(_, K) QuestTrackers(K) end)
	for _, name in ipairs(MENU_NAMES) do ns.Watch(KEY, name, Menu) end
	ns.Watch(KEY, "ForeverDungeonJournalTrackerClosedNotice", Window)
	ns.Watch(KEY, "ForeverDungeonJournalUnlockToast", Toast)
	-- (The update notice is shown from a timer of its own three seconds after login, through no call
	-- that can be hooked: found by name in the frame it's made.)
	ns.Watch(KEY, "ForeverDungeonJournalNotice", Window)
	ns.Watch(KEY, function() return FDJ.foreverHint end, Window)
	ns.Watch(KEY, "ForeverDungeonJournalTierPanel", TierPage)
	ns.Watch(KEY, "ForeverDungeonJournalArrow", Arrow)
	ns.Watch(KEY, "ForeverDungeonJournalRPGIntro", function()
		JournalPopups(_G.ForeverDungeonJournalFrame)
	end)
	-- (The journal itself is made at login.)
	ns.Watch(KEY, "ForeverDungeonJournalFrame", function(frame)
		JournalPopups(frame)
		HomeIcons(frame)
		ns.ScriptOnce(frame, "OnShow", JournalPopups, KEY)
	end)
end)
