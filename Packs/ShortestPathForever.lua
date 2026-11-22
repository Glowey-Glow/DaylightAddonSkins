-- Shortest Path Forever: its Nearby services panel in the world map's quest log (its paper ground
-- and border gone, DaylightUI's look on its search box, scroll bar, rows, section heads, map
-- switches and side tab, and the Quests tab ForeverCore puts atop that column), its Journey stops and Farming tour windows, the windows ForeverCore
-- opens for it (report, issue, thanks; before ForeverCore 1.15 also the Forever addons link and
-- your Forever profile), ForeverCore's right-click menu (the tracker's header and lines) and, before
-- Shortest Path 1.42 (which dropped it), its "Journey" button under the minimap.
-- (Checked against Shortest Path 1.43.10, which carries ForeverCore 1.15.6 inside itself.)
-- Left alone: everything it draws on the world map and minimap (route lines, pins, docks,
-- portals), the direction arrow and compass (on-screen guides with settings of their own), its
-- settings (the game's Settings window). Its tracker sections: docked under DaylightUI's quest
-- tracker, in its look (below).
--
-- DaylightUI's in-world marker (Quests > Navigation, "marker"): Shortest Path puts the game's
-- marker icon back on every waypoint change, and lays its own pin over it, which showed under
-- DaylightUI's marker. While DaylightUI's marker is on, both are kept at nothing again after it.
--
-- "Hand over to DaylightUI" (off until turned on on its page): its flight master, boat and
-- zeppelin pins on the world map step aside while DaylightUI's map pins show the same, and (before
-- ForeverCore 1.15, which removed it) ForeverCore's own quest list in the Forever column while
-- DaylightUI's quest tracker is on.
local _, ns = ...
if not ns.ok then return end
local L = ns.L

local KEY = "ShortestPathForever"

-- (font = "daylight": its settings panel's and menu's words, from the game's serif templates, in
-- the player's font; their walks pass fonts = true, since that look keeps the generic walk off
-- text. The tracker sections' fonts are set apart below and don't follow this.)
ns.Target(KEY, "Shortest Path Forever", { window = true, controls = true, text = true, shadow = true,
	font = "daylight",
	defaults = { dock = true }, extraTab = "DaylightUI",
	extra = function(at)
		return {
			{ label = L["Quest Tracker"], items = {
				{ type = "toggle", key = at .. "dock", label = L["Put the Forever Sections Under Daylight UI's Quest Tracker"],
				  desc = L["Shortest Path's lifts, boats and journey steps (and any other Forever addon's tracker sections) sit right under your quest list and look like it. Off: ForeverCore places them as it does without Daylight UI."] },
			} },
			ns.HandoverGroup(KEY),
		}
	end })

-- From 1.43.6 Shortest Path carries ForeverCore inside itself and runs its own files only once that
-- core starts, at login (its ForeverCoreRun.lua; after the fight, for a reload made in one). Before,
-- its files ran as it loaded and its global was there as this file loads. So this file goes by the
-- addon being loaded, and what reads Shortest Path's or ForeverCore's globals waits for them
-- (WhenCore below).
if type(_G.ShortestPathForever) ~= "table" and not ns.AddonLoaded(KEY) then return end

-- fn(core) once ForeverCore and Shortest Path are both up: now (a ForeverCore addon of its own
-- that ran as it loaded), or a frame at most after they start.
local coreWaiting
local function WhenCore(fn)
	local core = _G.ForeverCore
	if type(core) == "table" and type(_G.ShortestPathForever) == "table" then
		ns.Guard(fn, core)
		return
	end
	if coreWaiting then
		coreWaiting[#coreWaiting + 1] = fn
		return
	end
	coreWaiting = { fn }
	ns.Watch(KEY, function()
		return type(_G.ShortestPathForever) == "table" and type(_G.ForeverCore) == "table" and _G.ForeverCore or nil
	end, function(found)
		local list = coreWaiting
		coreWaiting = nil
		for _, f in ipairs(list) do ns.Guard(f, found) end
	end)
end

-- ---------------------------------------------------------------------------------------------
-- Nearby services panel (made when the world map loads)
-- ---------------------------------------------------------------------------------------------

-- A section head's fold button: its own plus or minus (an Icon texture) kept, in DaylightUI's text
-- ink. Not Kit's collapse button: that adds show and hide scripts, which under the world map run
-- inside the map's close (the #158 taint below). Its hover (the same picture again, put back with
-- each fold) hidden.
local function ServiceFold(btn, Kit)
	if not ns.Usable(btn) or not ns.Usable(btn.Icon) then return end
	btn.Icon:SetDesaturated(true)
	btn.Icon:SetVertexColor(Kit.TEXT[1], Kit.TEXT[2], Kit.TEXT[3])
	Kit.Hide(btn:GetHighlightTexture())
end

-- Its section heads (a band of the game's list art, a fold button, the name and count in gold):
-- line rows with DaylightUI's hover, the name in DaylightUI's value ink and the count in its label
-- ink. Its rows (the game's Who-list row art, its hover in the art too): DaylightUI's rows, their
-- icon and upgrade mark kept; gold names in DaylightUI's ink (a better trip's goods keep their
-- quality's color). Its dividers (the quest log's gold separator) gone. Its search box and scroll
-- bar: the walk below (its map switches are left as the game draws them).
local function ServiceHead(head, Kit, controls, value)
	if controls then
		if ns.Once(head) then ns.Guard(Kit.Row, head, nil, nil, false) end
		ServiceFold(head.CollapseButton, Kit)
	end
	if ns.Usable(head.Name) then Kit.Light(head.Name, value) end
	if ns.Usable(head.Count) then Kit.Light(head.Count, Kit.DIM) end
end

local function ServiceRow(row, Kit, controls)
	if controls and ns.Once(row) then
		local keep = { [row.Icon] = true }
		if ns.Usable(row.Badge) then keep[row.Badge] = true end
		ns.Guard(Kit.Row, row, keep)
	end
	Kit.InkGameText(row)
end

local DIVIDER = "questlog-frame-devider"
local function ServiceDivider(frame, Kit)
	if frame:GetObjectType() ~= "Frame" or frame:GetNumRegions() ~= 1 then return false end
	local tex = frame:GetRegions()
	if not ns.Usable(tex) or tex:GetObjectType() ~= "Texture" then return false end
	local ok, atlas = pcall(tex.GetAtlas, tex)
	if not ok or type(atlas) ~= "string" or string.lower(atlas) ~= DIVIDER then return false end
	Kit.Hide(tex)
	return true
end

-- panel: the whole panel; list: its scroll child (the head with the title and your zone, and the
-- list under it).
local function DressServices(panel, list, Kit)
	-- (Its map switches keep the game's checkbox: DaylightUI's switch adds a show/hide script, which
	-- under the world map runs inside the map's close: the #158 taint below.)
	ns.Dress(panel, { fonts = true, checks = false }, 0, KEY)
	if not ns.Usable(list) then return end
	local controls = ns.Controls(KEY)
	local value = ns.Colors().VALUE
	local big = _G.GameFontNormalLarge2
	for _, content in ipairs({ list:GetChildren() }) do
		for _, part in ipairs({ content:GetChildren() }) do
			if ns.Usable(part) then
				-- The title ("Nearby services") in the value ink; the rest of the game's gold in
				-- DaylightUI's label ink, its gray (nothing to show yet) in its dimmed ink.
				for _, region in ipairs({ part:GetRegions() }) do
					if region:GetObjectType() == "FontString" and big and region:GetFontObject() == big then
						Kit.Light(region, value)
					end
				end
				Kit.InkGameText(part)
				for _, child in ipairs({ part:GetChildren() }) do
					if ns.Usable(child) and child:IsShown() then
						if child.CollapseButton then
							ServiceHead(child, Kit, controls, value)
						elseif child.Icon and child.Label then
							ServiceRow(child, Kit, controls)
						else
							ServiceDivider(child, Kit)
						end
					end
				end
			end
		end
	end
end

ns.Watch(KEY, "ShortestPathForeverServicesPanel", function(panel, Kit)
	if not ns.Once(panel) then return end
	-- Its ground: the quest log's paper, a BACKGROUND texture of its own. DaylightUI's map window
	-- shows through, as it does behind the game's own quest log.
	for _, region in ipairs({ panel:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			ns.Kill(region)
		end
	end
	-- The quest log's gold border round its list: the first child of its body (the child holding
	-- the scroll list), with every piece of art of its own and of its children.
	local function strip(frame, depth)
		ns.Guard(Kit.Strip, frame)
		if depth > 3 then return end
		for _, child in ipairs({ frame:GetChildren() }) do
			if ns.Usable(child) and child:GetObjectType() == "Frame" then strip(child, depth + 1) end
		end
	end
	local list
	for _, body in ipairs({ panel:GetChildren() }) do
		if ns.Usable(body) and body:GetObjectType() == "Frame" and body:GetNumChildren() >= 2 then
			local first, second = body:GetChildren()
			if ns.Usable(first) and first:GetObjectType() == "Frame" and ns.Usable(second)
				and select("#", second:GetChildren()) > 0 then
				local inner = second:GetChildren()
				if ns.Usable(inner) and inner:GetObjectType() == "ScrollFrame" then
					strip(first, 0)
					list = inner:GetScrollChild()
				end
			end
		end
	end
	-- No show or hide script of ours on it: it lives under the world map, where a script runs
	-- inside the map's own close and taints the gamepad's interact action (Shortest Path's #158,
	-- which is why it sets none either). Its list is rebuilt on opening, on a zone change, on a
	-- search, on a fold and every 10 seconds while open, each time ending in its scroll child's
	-- SetSize: dressed a moment after that, outside its call.
	local function dress() ns.Guard(DressServices, panel, list, Kit) end
	dress()
	if ns.Usable(list) then
		local queued = false
		hooksecurefunc(list, "SetSize", function()
			if queued then return end
			queued = true
			C_Timer.After(0, function() queued = false dress() end)
		end)
	end
end)

local function Repaint()
	local Kit = ns.Kit
	if Kit and type(Kit.RepaintSoon) == "function" and ns.Enabled(KEY) then ns.Guard(Kit.RepaintSoon) end
end

-- ForeverCore 1.17: a click on a tab in its column goes through the tab's own mouse-up, which
-- picks the tab (the Quests tab with the ShowQuests it was handed as it was made, before the hook
-- below can be there) and, on a right-click once the column was dragged, opens ForeverCore's menu
-- ("Reset tab position") straight from inside it. After it: the tabs' look read again, and that
-- menu looked for at once (dressed before it's drawn, rather than by its watch a frame late).
local function TabClicked()
	C_Timer.After(0, Repaint)
	ns.WatchNow()
end

ns.Watch(KEY, "ShortestPathForeverServicesTab", function(tab, Kit)
	if ns.Controls(KEY) and ns.Once(tab) then ns.Guard(Kit.SideTab, tab) end
	ns.ScriptOnce(tab, "OnMouseUp", TabClicked, KEY)
end)

-- Where the game hides the quest log's own Quests tab, ForeverCore draws one of its own atop its
-- column (ForeverQuestLogQuestsTab: the same side tab template, the game's quest icons): DaylightUI's
-- side tab, cropped as DaylightUI crops the game's Quests tab. Made with the column, as the first
-- addon puts its tab in (QuestLogTabs.Register): looked for after each, and at once in case that
-- was before this ran. (No watch: a client that shows the game's own tab never gets this one.)
local function QuestsTab()
	local tab = _G.ForeverQuestLogQuestsTab
	if not ns.Usable(tab) or not ns.Enabled(KEY) then return end
	ns.ScriptOnce(tab, "OnMouseUp", TabClicked, KEY)
	if not ns.Controls(KEY) or not ns.Once(tab) then return end
	ns.WithKit(function(Kit) Kit.SideTab(tab, nil, Kit.SIDE_TAB_CROP) end)
end

-- Its side tab and the quest log's own are checked from code (ForeverCore's QuestLogTabs: picking
-- a tab, or the quest log asking for its quests back), so the tabs' look is read again after.
WhenCore(function(core)
	local LogTabs = core.QuestLogTabs
	if type(LogTabs) ~= "table" then return end
	if type(LogTabs.Register) == "function" then ns.HookOnce(LogTabs, "Register", QuestsTab, KEY) end
	QuestsTab()
	for _, method in ipairs({ "ShowQuests", "Select" }) do
		if type(LogTabs[method]) == "function" then
			ns.HookOnce(LogTabs, method, function() C_Timer.After(0, Repaint) end, KEY)
		end
	end
end)

-- ---------------------------------------------------------------------------------------------
-- ForeverCore's windows (the game's portrait window template) and its menu
-- ---------------------------------------------------------------------------------------------

-- Journey stops: its stops are buttons of the game's red-button template, the picked one (or the
-- one the journey is at) shown by locking its hover art. They are DaylightUI's rows here, the
-- picked one in the accent, their words in white rather than the template's gold (its hover and
-- disabled fonts follow the same, so a state change doesn't bring the gold back). Each refresh
-- ends by sizing the list under them, which repaints them right there.
local function Picked(row) return row.IsHighlightLocked and row:IsHighlightLocked() == true end

-- Shortest Path sets each row's OnEnter and OnLeave anew on every refresh, which drops Kit's hover
-- hooks: put back whenever its script changed (else a row clicked while hovered keeps its hover).
local wired = setmetatable({}, { __mode = "k" })
local function Rewire(row, Kit)
	local now = row:GetScript("OnEnter")
	if wired[row] == now or type(Kit.RowOf) ~= "function" then return end
	local r = Kit.RowOf(row)
	if not r then return end
	-- (Hooked directly: hooked again each time its script is set anew, which ns.ScriptOnce
	-- would refuse as already done.)
	row:HookScript("OnEnter", function() r.hover = true; Kit.RepaintRow(row) end)
	row:HookScript("OnLeave", function() r.hover = false; Kit.RepaintRow(row) end)
	wired[row] = row:GetScript("OnEnter")
end

local function StopRows(content, Kit)
	for _, row in ipairs({ content:GetChildren() }) do
		if ns.Usable(row) and row:GetObjectType() == "Button" then
			if ns.Once(row) then
				row:SetNormalFontObject("GameFontHighlight")
				row:SetHighlightFontObject("GameFontHighlight")
				row:SetDisabledFontObject("GameFontDisable")
				ns.Guard(Kit.Row, row, "art", Picked)
				local fs = row:GetFontString()
				if ns.Usable(fs) then ns.FollowFont(fs, KEY) end
			elseif type(Kit.RepaintRow) == "function" then
				Kit.RepaintRow(row)
			end
			Rewire(row, Kit)
		end
	end
end

-- The game's portrait window, from ForeverCore or Shortest Path: DaylightUI's window, the template
-- controls inside walked (and walked again a moment after it shows, and after its list grows or
-- shrinks: rows are made while it's open), the inset under its list in DaylightUI's darker shade.
local STOPS = "ShortestPathForeverJourneyStops"

local function Templated(frame, Kit)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	ns.Guard(Kit.Window, frame)
	if not ns.Controls(KEY) then return end
	local stops = frame:GetName() == STOPS
	-- Its insets (the template's, unnamed) and the scroll children inside them.
	local lists, skip = {}, {}
	local function look(parent, depth)
		for _, child in ipairs({ parent:GetChildren() }) do
			if ns.Usable(child) then
				if child.layoutType == "InsetFrameTemplate" then ns.Guard(Kit.Inset, child) end
				if child:GetObjectType() == "ScrollFrame" then
					local inner = child:GetScrollChild()
					if ns.Usable(inner) then lists[#lists + 1] = inner end
				elseif depth < 2 then
					look(child, depth + 1)
				end
			end
		end
	end
	look(frame, 0)
	-- (The stops' list is left to StopRows: the walk would make each stop a plain button.)
	if stops then for _, inner in ipairs(lists) do skip[inner] = true end end
	local function walk()
		if frame:IsShown() then ns.Guard(Kit.Auto, frame, { rows = false, shownOnly = true, skip = skip }) end
	end
	local queued = false
	local function soon()
		if queued then return end
		queued = true
		C_Timer.After(0.05, function() queued = false walk() end)
	end
	for _, inner in ipairs(lists) do
		if stops then
			local function rows() ns.Guard(StopRows, inner, Kit) end
			ns.HookOnce(inner, "SetHeight", rows, KEY)
			rows()
			-- (A second SetHeight hook on the same list: ns.HookOnce keeps one per method, so this
			-- one is hooked directly.)
			hooksecurefunc(inner, "SetHeight", soon)
		else
			ns.HookOnce(inner, "SetHeight", soon, KEY)
		end
		ns.HookOnce(inner, "SetSize", soon, KEY)
	end
	ns.ScriptOnce(frame, "OnShow", soon, KEY)
	walk()
end

for _, name in ipairs({ "ShortestPathForeverReport", "ShortestPathForeverIssue", "ForeverCreditsFrame",
	"ForeverFamilyLink", STOPS, "ShortestPathForeverFarming", "ForeverCoreProfile" }) do
	ns.Watch(KEY, name, Templated)
end

-- ForeverCore's menu: the game's dropdown look (its yellow ticks and radios, gold titles, the next
-- arrow) drawn in frames of its own. Drawn again for each submenu while it stays open, and that
-- ends in its SetSize: repainted there, ticks in the accent, the game's gold and gray in
-- DaylightUI's inks, new rows in the player's font.
-- ForeverCore 1.15.4 (UI/ContextMenu.lua) draws it after the game's own menus: a row's hover is the
-- quest log's blue highlight art, added on (kept lit while the row's submenu is open), here a wash
-- in the accent, fainter on a row that can't be clicked and none on a title or a divider, as it
-- has them; and a submenu is a menu frame of its own beside its row (below).
local function Opened() ns.WatchNow() end

local function MenuRows(menu, Kit)
	local rows = menu.rows
	if type(rows) ~= "table" then return end
	local ink = Kit.DIM
	for _, row in ipairs(rows) do
		if ns.Usable(row) and row:IsShown() then
			local hover = row.highlight
			if ns.Usable(hover) and hover.SetBlendMode then
				-- (It sets the art's alpha again on every draw: 1, 0.4 for a row that's off, 0 for a
				-- title or a divider. Told here by the row itself.)
				local passive = (ns.Usable(row.divider) and row.divider:IsShown())
					or (row.GetDisabledFontObject and row:GetDisabledFontObject() == _G.GameFontNormal)
				local alpha = 0.18
				if not row:IsEnabled() then alpha = passive and 0 or 0.08 end
				ns.FillAccent(hover, alpha, nil, KEY)
				hover:SetBlendMode("BLEND")
				-- A row lights its hover for good right after it has made and drawn its submenu, and
				-- before it shows it: that level is looked for there, so it's dressed before it's drawn.
				ns.HookOnce(row, "LockHighlight", Opened, KEY)
			end
			if ns.Usable(row.tick) then
				row.tick:SetDesaturated(true)
				ns.PaintAccent(row.tick, 1, nil, KEY)
			end
			if ns.Usable(row.arrow) then
				row.arrow:SetDesaturated(true)
				row.arrow:SetVertexColor(ink[1], ink[2], ink[3])
			end
			Kit.InkGameText(row)
		end
	end
	ns.Dress(menu, { scrollBars = false, fonts = true }, 0, KEY)
end

local DressMenu
DressMenu = function(menu, Kit)
	if not ns.Once(menu) then return end
	for _, region in ipairs({ menu:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			ns.Kill(region)
		end
	end
	ns.Shell(menu)
	local scroll = menu.scroll
	if ns.Controls(KEY) and type(scroll) == "table" and ns.Usable(scroll.ScrollBar) then ns.Guard(Kit.ScrollBar, scroll.ScrollBar) end
	ns.DressOnShow(menu, { scrollBars = false, fonts = true })
	ns.HookOnce(menu, "SetSize", function() ns.Guard(MenuRows, menu, Kit) end, KEY)
	-- (Its first opening made it and drew it in one call: drawn already.)
	ns.Guard(MenuRows, menu, Kit)
	-- ForeverCore 1.15.4: each submenu level is a frame of its own ("ForeverCoreContextMenu2",
	-- "...3"), made by a call it keeps to itself the first time a row opens one: the next level
	-- down is watched for from here (and looked for at once from the row's LockHighlight, above).
	if type(menu.depth) == "number" then
		ns.Watch(KEY, "ForeverCoreContextMenu" .. (menu.depth + 1), DressMenu)
	end
end
ns.Watch(KEY, "ForeverCoreContextMenu", DressMenu)

-- The menu is made on its first opening, and the windows on theirs: looked for right after the
-- calls that open them from outside (Shortest Path's map pins, flight pins and tracker lines open
-- the menu through ForeverCore.ContextMenu; /path stops, /path farm and /forever profile open the
-- windows), so they're dressed before they're drawn. The rest (ForeverCore's own tracker menu,
-- Shortest Path's map menu) are found by the watches, a frame late at most.
WhenCore(function(core)
	if type(core.ContextMenu) == "function" then ns.HookOnce(core, "ContextMenu", Opened, KEY) end
end)
-- (Its slash commands are set as its settings are made, after it starts: looked for until then.)
ns.Watch(KEY, function()
	local slash = _G.SlashCmdList
	return type(slash) == "table" and type(slash.SHORTESTPATHFOREVER) == "function" and slash or nil
end, function(slash)
	for _, name in ipairs({ "SHORTESTPATHFOREVER", "FOREVERCORE" }) do
		if type(slash[name]) == "function" then ns.HookOnce(slash, name, Opened, KEY) end
	end
end)

-- Its "Journey" button under the minimap (Settings: "Show options button on minimap", off by
-- default): a text button of the game's red-button template, DaylightUI's button look here. Where
-- it sits is Shortest Path's. It's made when its setting is on as the game starts, or later, when
-- the player turns it on: looked for then, never watched for all session.
local function OptionsButton(Kit)
	local btn = _G.ShortestPathForeverOptionsButton
	if not ns.Usable(btn) or not ns.Enabled(KEY) or not ns.Controls(KEY) or not ns.Once(btn) then return end
	ns.Guard(Kit.Button, btn)
end
ns.me.On("Login", function()
	ns.WithKit(OptionsButton)
	if type(Settings) == "table" and type(Settings.SetOnValueChangedCallback) == "function" then
		pcall(Settings.SetOnValueChangedCallback, "ShortestPathForever_minimapButton", function()
			-- (After Shortest Path's own answer to the change, which makes the button.)
			ns.Queue("ShortestPathForever:optionsButton", function() ns.WithKit(OptionsButton) end, KEY)
		end)
	end
end)

-- ForeverCore's "your ForeverCore is older" notice (1.15.6, Core/Loader.lua ShowNotice; before, the
-- game's StaticPopup, which DaylightUI dresses): a small dialog in the game's dialog art with one
-- OK button. It has no name, and the loader makes it by a call it keeps to itself, on the frame
-- after the world is entered, once per installed ForeverCore version. So only while the loader says
-- there is such a warning, it is looked for among the screen's own frames, each frame for two
-- seconds from the world's entry, by how it is made (strata, width) and by its words.
local function NoticeAmong(text, ...)
	for i = 1, select("#", ...) do
		local f = select(i, ...)
		if ns.Usable(f) and f:GetObjectType() == "Frame" and not f:GetName() and f:IsShown()
			and f:GetFrameStrata() == "DIALOG" and math.abs((f:GetWidth() or 0) - 320) < 1 then
			for _, r in ipairs({ f:GetRegions() }) do
				if ns.Usable(r) and r:GetObjectType() == "FontString" then
					local words = r:GetText()
					if type(words) == "string" and not (issecretvalue and issecretvalue(words)) and words == text then
						return f, r
					end
				end
			end
		end
	end
end

local function DressNotice(f, message, Kit)
	if not ns.Once(f) then return end
	for _, region in ipairs({ f:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			ns.Kill(region)
		end
	end
	ns.Shell(f, { window = true }, KEY)
	if ns.Controls(KEY) then
		for _, child in ipairs({ f:GetChildren() }) do
			if ns.Usable(child) and child:GetObjectType() == "Button" and ns.Once(child) then ns.Guard(Kit.Button, child) end
		end
	end
	-- (It sized itself to its words in the game's font: again in the player's.)
	ns.FollowFont(message, KEY)
	local h = message:GetStringHeight()
	if type(h) == "number" and h > 0 then f:SetHeight(h + 63) end
end

local noticeWatch = CreateFrame("Frame")
noticeWatch:RegisterEvent("PLAYER_ENTERING_WORLD")
noticeWatch:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	local loader = _G.ForeverCoreLoader
	if type(loader) ~= "table" or type(loader.Warning) ~= "function" or not ns.Enabled(KEY) then return end
	local left = 2
	self:SetScript("OnUpdate", function(me, elapsed)
		-- (The first frame after a loading screen can be seconds long: counted as a tenth at most.)
		left = left - math.min(elapsed or 0, 0.1)
		local ok, text = pcall(loader.Warning)
		if ok and type(text) == "string" then
			local f, message = NoticeAmong(text, UIParent:GetChildren())
			if f then
				left = 0
				ns.WithKit(function(Kit) ns.Guard(DressNotice, f, message, Kit) end)
			end
		end
		if left <= 0 then me:SetScript("OnUpdate", nil) end
	end)
end)

-- ---------------------------------------------------------------------------------------------
-- The Forever column (ForeverTrackerCompanion: Shortest Path's Lifts, boats and journey steps, and
-- every other Forever addon's tracker sections). ForeverCore hangs it under the game's quest
-- tracker, which DaylightUI hides, so it floated where that tracker would be.
-- Docked here under DaylightUI's quest tracker (look.ShortestPathForever.dock, on unless turned
-- off): its spot is handed to ForeverCore's own settings (ForeverTrackerHost.SetAttached(false),
-- SavePosition), the way its own grip does, and kept up as the tracker grows, shrinks or moves. The
-- tracker is only read, never moved or anchored to (the same way ForeverCore follows Questie's).
-- Its sections take the tracker's look: heads like its Quests header (caps, the header color and
-- size, a line under it), each entry's name like a quest title, each line like an objective, all
-- from DaylightUI's Quests settings, in the tracker's font. It fades with the tracker.
-- ---------------------------------------------------------------------------------------------

local API = ns.API
local upper = string.upper

-- DaylightUI's Quests settings, read once and kept until one of them (or the look) changes: the
-- column is restyled on every tracker layout and timer tick.
local qcache, NONE = {}, {}
local function Quests(path)
	local v = qcache[path]
	if v == nil then
		local ok, got = pcall(API.GetSetting, "Quests", path)
		if ok and got ~= nil then v = got else v = NONE end
		qcache[path] = v
	end
	if v == NONE then return nil end
	return v
end
local function ForgetQuests() wipe(qcache) end

local function QColor(name, fallback)
	local v = Quests("colors." .. name)
	if type(v) == "table" and type(v[1]) == "number" then return v[1], v[2], v[3] end
	local c = ns.Colors()[fallback]
	if type(c) == "table" then return c[1], c[2], c[3] end
	return 1, 1, 1
end

local function QSize(name, fallback)
	local v = Quests("sizes." .. name)
	return type(v) == "number" and v or fallback
end

local function HeaderColor()
	local mode = Quests("colors.headerMode")
	if mode == "accent" then return API.Accent() end
	if mode == "class" or mode == "gradient" then
		local _, token = UnitClass("player")
		local ok, r, g, b = pcall(API.ClassColor, token)
		if ok and r then return r, g, b end
	end
	return QColor("header", "VALUE")
end

-- The player's class, when DaylightUI has a gradient pair for it (its tracker's class gradient).
local function ClassGradient()
	local G = type(_G.DaylightUI) == "table" and _G.DaylightUI.Gradients
	local _, token = UnitClass("player")
	if type(G) ~= "table" or type(token) ~= "string" or type(G.Has) ~= "function" or not G.Has(token) then return nil end
	return G, token
end

-- A head's words in the tracker's header color, as DaylightUI's tracker draws them: letter by
-- letter along the class gradient, or along DaylightUI's accent when that's a gradient, otherwise
-- the one color.
local function PaintHead(fs, words)
	local mode = Quests("colors.headerMode")
	if mode == "gradient" then
		local G, token = ClassGradient()
		if G and type(G.Text) == "function" then
			local ok, colored = pcall(G.Text, token, words)
			if ok and type(colored) == "string" then
				fs:SetText(colored)
				fs:SetTextColor(1, 1, 1)
				return
			end
		end
	elseif mode == "accent" then
		local Style = type(_G.DaylightUI) == "table" and _G.DaylightUI.Style
		if type(Style) == "table" and type(Style.PaintAccentText) == "function" and pcall(Style.PaintAccentText, fs, words) then return end
	end
	fs:SetText(words)
	fs:SetTextColor(HeaderColor())
end

-- The line under a head, as DaylightUI's tracker draws it: along DaylightUI's gradient accent or
-- the class gradient, or the one color.
local function PaintLine(line, alpha)
	local mode = Quests("colors.headerLineMode")
	if mode == "custom" or mode == nil then
		local r, g, b = QColor("headerLine", "LABEL")
		line:SetColorTexture(r, g, b, alpha)
		return
	end
	local lo, hi
	if mode == "gradient" then
		local G, token = ClassGradient()
		if G and type(G.PaintRGB) == "function" then
			local ok, a, b = pcall(G.PaintRGB, token)
			if ok and type(a) == "table" and type(b) == "table" then lo, hi = a, b end
		end
	elseif mode == "accent" then
		local Style = type(_G.DaylightUI) == "table" and _G.DaylightUI.Style
		if type(Style) == "table" and type(Style.AccentPair) == "function" then
			local ok, a, b = pcall(Style.AccentPair)
			if ok and type(a) == "table" and type(b) == "table" then lo, hi = a, b end
		end
	end
	if lo and line.SetGradient and CreateColor then
		line:SetColorTexture(1, 1, 1, 1)
		line:SetVertexColor(1, 1, 1, alpha)
		line:SetGradient("HORIZONTAL", CreateColor(lo[1], lo[2], lo[3], alpha), CreateColor(hi[1], hi[2], hi[3], alpha))
		return
	end
	local r, g, b
	if mode == "class" or mode == "gradient" then
		local _, token = UnitClass("player")
		local ok, cr, cg, cb = pcall(API.ClassColor, token)
		if ok and cr then r, g, b = cr, cg, cb end
	end
	if not r then r, g, b = API.Accent() end
	line:SetColorTexture(r, g, b, alpha)
end

-- Blizzard's tracker colors (OBJECTIVE_TRACKER_COLOR): a text in one of these is the section's
-- plain text and takes the tracker's colors; any other (a warning, a countdown) is kept.
local function Plain(fs)
	local r, g, b = fs:GetTextColor()
	local set = _G.OBJECTIVE_TRACKER_COLOR
	if type(set) ~= "table" or not r then return true end
	for _, name in ipairs({ "Normal", "NormalHighlight", "Header", "HeaderHighlight" }) do
		local c = set[name]
		if type(c) == "table" and c.r and math.abs(c.r - r) + math.abs(c.g - g) + math.abs(c.b - b) < 0.03 then return true end
	end
	return false
end

local function Ink(fs, size, r, g, b)
	if not ns.Usable(fs) or not fs.SetFont then return end
	if size then
		local cur, curSize, flags = fs:GetFont()
		-- (Its own face kept where this client's letters aren't in the player's: ns.SafeFace.)
		local face = ns.PlayerFace() or cur
		if cur ~= face or not curSize or math.abs(curSize - size) > 0.05 then
			pcall(fs.SetFont, fs, face, size, flags or "")
		end
	end
	if r then fs:SetTextColor(r, g, b) end
end

-- How much larger a size must be on the column to look the size it is on DaylightUI's tracker
-- (the column is scaled to the tracker's width).
local zoom = 1

-- The font objects its entries and lines are drawn with (the game's tracker fonts, the native
-- tracker hidden under DaylightUI's): given the tracker's font and sizes while docked, so the
-- column measures its lines in them; what they were is kept and put back when it isn't.
local fontObjects = {}   -- font object -> { role, path, size, flags }

local function Dressed() return ns.Enabled(KEY) and ns.Setting("look." .. KEY .. ".dock") ~= false end

local function PaintFont(obj)
	local f = fontObjects[obj]
	if not f then return end
	if Dressed() and _G.DaylightUIQuestTracker then
		local size = f.role == "title" and QSize("title", 12) or QSize("objective", 11)
		pcall(obj.SetFont, obj, ns.PlayerFace() or f.path, math.floor(size * zoom + 0.5), f.flags or "")
	else
		pcall(obj.SetFont, obj, f.path, f.size, f.flags or "")
	end
end

local function NoteFont(fs, role)
	local obj = fs.GetFontObject and fs:GetFontObject()
	local name = type(obj) == "table" and obj.GetName and obj:GetName()
	-- Only the tracker's own font objects: a shared one (GameFontNormal...) would change text
	-- all over the screen. Text on any other gets its font on itself.
	if type(name) ~= "string" or string.sub(name, 1, 16) ~= "ObjectiveTracker" then
		local size = role == "title" and QSize("title", 12) or QSize("objective", 11)
		Ink(fs, math.floor(size * zoom + 0.5))
		return
	end
	if fontObjects[obj] or not obj.GetFont then return end
	local path, size, flags = obj:GetFont()
	fontObjects[obj] = { role = role, path = path, size = size, flags = flags }
	PaintFont(obj)
end

local function PaintFonts()
	for obj in pairs(fontObjects) do PaintFont(obj) end
end

local lines = setmetatable({}, { __mode = "k" })   -- section -> the line under its head

-- A section's entries and lines, wherever they hang (the tracker keeps them in a contents frame).
local function Entries(frame, depth, head, fn)
	if depth > 4 then return end
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and child ~= head then
			if child.HeaderText or child.Text or child.Dash then fn(child) end
			Entries(child, depth + 1, head, fn)
		end
	end
end

local function StyleSection(module, Kit)
	if not ns.Usable(module) or not Dressed() then return end
	local head = module.Header
	if ns.Usable(head) then
		if ns.Usable(head.Background) then head.Background:SetAlpha(0) end
		local text = head.Text
		if ns.Usable(text) then
			local words = text:GetText()
			-- (string.upper changes only a-z: words with other letters, "über", stay as they are
			-- rather than come out half in capitals.)
			-- (Without the colors put in last time, so they're neither capitalized nor colored twice.)
			if type(words) == "string" then
				words = string.gsub(string.gsub(words, "|c%x%x%x%x%x%x%x%x", ""), "|r", "")
				if not string.find(words, "[\128-\255]") then words = upper(words) end
			end
			Ink(text, math.floor(QSize("header", 12) * zoom + 0.5))
			if type(words) == "string" then PaintHead(text, words) else text:SetTextColor(HeaderColor()) end
		end
		local line = lines[module]
		if not line then
			line = head:CreateTexture(nil, "ARTWORK")
			line:SetHeight(1)
			line:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 0, 0)
			line:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", 0, 0)
			lines[module] = line
		end
		PaintLine(line, 0.6)
		if Kit and ns.Usable(head.MinimizeButton) and ns.Controls(KEY) and ns.Once(head.MinimizeButton) then
			ns.Guard(Kit.CollapseButton, head.MinimizeButton)
		end
	end
	-- A section taller than its room scrolls, with the game's minimal scroll bar (made the first
	-- time it's needed).
	local bar = module.scrollBar
	if Kit and ns.Usable(bar) and ns.Controls(KEY) and ns.Once(bar) then ns.Guard(Kit.ScrollBar, bar) end
	local tr, tg, tb = QColor("title", "VALUE")
	local orr, og, ob = QColor("objective", "TEXT")
	Entries(module, 0, head, function(item)
		local name = item.HeaderText
		if ns.Usable(name) then
			NoteFont(name, "title")
			if Plain(name) then name:SetTextColor(tr, tg, tb) end
		end
		for _, key in ipairs({ "Text", "Dash" }) do
			local fs = item[key]
			if ns.Usable(fs) and fs.GetTextColor then
				NoteFont(fs, "objective")
				if Plain(fs) then fs:SetTextColor(orr, og, ob) end
			end
		end
	end)
end

local styled = setmetatable({}, { __mode = "k" })

local function Styled(module) ns.Guard(StyleSection, module, ns.Kit) end

-- Every section on the column, as they come (a Forever addon adds its own when it loads). Each
-- gets one hook: after its layout ends (the last of the tracker's layout steps it has).
local knownKids = -1
local function Sections(host)
	local kids = host:GetNumChildren()
	if kids == knownKids then return end
	knownKids = kids
	for _, module in ipairs({ host:GetChildren() }) do
		if ns.Usable(module) and module.Header and not styled[module] then
			styled[module] = true
			for _, method in ipairs({ "EndLayout", "LayoutContents", "Update" }) do
				if type(module[method]) == "function" then
					-- (Hooked directly: a tracker section can hold a quest's secure item button,
					-- and ns.HookOnce refuses a protected frame.)
					hooksecurefunc(module, method, Styled)
					break
				end
			end
			Styled(module)
		end
	end
end
local function Restyle(host)
	PaintFonts()
	for module in pairs(styled) do
		if ns.Usable(module) and module:GetParent() == host then Styled(module) end
	end
	if host.MarkDirty then pcall(host.MarkDirty, host) end
end
-- Its text changes on a timer (departures counting down) through ForeverCore's own function.
WhenCore(function(core)
	local section = core.TrackerSection
	if type(section) == "table" and type(section.UpdateText) == "function" then
		ns.HookOnce(section, "UpdateText", Styled, KEY)
	end
end)

-- ---------------------------------------------------------------------------------------------
-- Docking
-- ---------------------------------------------------------------------------------------------

local GAP = 8            -- between the tracker's box and the column's
local PAD = { 8, 6 }     -- the box past the list (DaylightUI's tracker uses the same)
local GRIP = 24          -- ForeverCore's grip strip along the column's top (empty while locked)

-- ForeverCore's grip (before 1.15): a button along the column's top holding one label ("Forever
-- tracker", shown while unlocked or under the mouse). Kept at nothing while docked, put back after.
-- From 1.15 there is none (a section's header drags the column) and the first section starts at the
-- column's top.
local function HasGrip(host)
	for _, child in ipairs({ host:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" and not child.Header then return true end
	end
	return false
end
local function GripLabel(host, alpha)
	for _, child in ipairs({ host:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" and not child.Header then
			for _, region in ipairs({ child:GetRegions() }) do
				if region:GetObjectType() == "FontString" then region:SetAlpha(alpha) end
			end
		end
	end
end

local function TrackerList(holder)
	for _, child in ipairs({ holder:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "ScrollFrame" then return child end
	end
end

local function Column()
	local host, api = _G.ForeverTrackerCompanion, _G.ForeverTrackerHost
	if not ns.Usable(host) or type(api) ~= "table" or type(api.SavePosition) ~= "function"
		or type(api.SetAttached) ~= "function" then
		return
	end
	local db = _G.DaylightAddonSkinsDB
	if type(db) ~= "table" then db = {} _G.DaylightAddonSkinsDB = db end
	local uiScale = function() return UIParent:GetEffectiveScale() end
	-- (The grip is made with the column, before this runs: looked for once.)
	local gripH = HasGrip(host) and GRIP or 0
	-- ForeverCore 1.15 dropped attaching (SetAttached does nothing): the column sits at its saved
	-- spot, or pinned beside the game's tracker when it has none. The spot it had before docking
	-- (none = the pin) is kept and given back on undocking.
	local function Spot()
		if type(api.GetSettings) ~= "function" then return nil end
		local ok, s = pcall(api.GetSettings)
		return ok and type(s) == "table" and s or nil
	end
	-- ForeverCore 1.15.4 gave the column a place again (Under or Left of the game's tracker, the
	-- player's pick: GetPlacement / SetPlacement), and its SetAttached now picks one of the two and
	-- forgets the dragged spot. The player's place is left as it is there: the spot saved while
	-- docked takes the column off it, and letting go of that spot gives it back.
	local placed = type(api.GetPlacement) == "function" and type(api.SetPlacement) == "function"

	-- The box behind the sections, like the tracker's (Quests > box), on a frame of ours under them.
	local box = CreateFrame("Frame", nil, host)
	box:SetFrameLevel(math.max(0, host:GetFrameLevel()))
	box:EnableMouse(false)
	box:Hide()
	-- (Daylight UI 2.1.2 moved the box's border and opacity, Quests boxBorder / boxAlphaOwn /
	-- boxAlpha, into its look table, Quests frameStyle (DaylightUI_Quests\Defaults.lua:23), and its
	-- own box is now Style.Shell(box, { look = "Quests", panel = true }) (Tracker.lua:422): the same
	-- opts here, so this box has the tracker's border, shadow and background and follows them.)
	local function PaintBox()
		if Quests("box") ~= true then box:Hide() return end
		local opts
		if type(Quests("frameStyle")) == "table" then
			opts = { look = "Quests", panel = true }
		else
			opts = { noBorder = Quests("boxBorder") == false }
			if Quests("boxAlphaOwn") == true and type(Quests("boxAlpha")) == "number" then
				opts.bgAlpha = Quests("boxAlpha")
			else
				opts.window = true
			end
		end
		pcall(API.Skin, box, opts)
		box:Show()
	end

	local found, settled, boxX, boxY
	-- The last look's place, size, alpha and scales; empty = look again.
	local last = {}
	local function Moved(...)
		local moved = false
		for i = 1, select("#", ...) do
			local v = select(i, ...)
			if last[i] ~= v then
				last[i] = v
				moved = true
			end
		end
		return moved
	end

	local function Undock()
		wipe(last)
		settled, boxX, boxY = nil, nil, nil
		if db.foreverDocked then
			db.foreverDocked = nil
			if placed then
				-- (1.15.4: back to the spot it was dragged to, or to its place, Under or Left of the
				-- game's tracker: picking the place it has again lets go of the spot saved here.)
				if type(db.foreverX) == "number" and type(db.foreverY) == "number" then
					pcall(api.SavePosition, db.foreverX, db.foreverY)
				else
					local ok, place = pcall(api.GetPlacement)
					if ok then pcall(api.SetPlacement, place) end
				end
			else
				pcall(api.SetAttached, true)
				local s = Spot()
				if s then
					if type(db.foreverX) == "number" and type(db.foreverY) == "number" then
						pcall(api.SavePosition, db.foreverX, db.foreverY)
					else
						s.x, s.y = nil, nil
						if type(host.MarkDirty) == "function" then pcall(host.MarkDirty, host) end
					end
				end
			end
			db.foreverX, db.foreverY = nil, nil
			if type(api.SetScale) == "function" and type(db.foreverScale) == "number" then pcall(api.SetScale, db.foreverScale) end
			if type(api.SetLocked) == "function" and db.foreverLocked ~= nil then pcall(api.SetLocked, db.foreverLocked) end
			if type(api.SetBackdropOpacity) == "function" and type(db.foreverBackdrop) == "number" then
				pcall(api.SetBackdropOpacity, db.foreverBackdrop)
			end
			db.foreverScale, db.foreverLocked, db.foreverBackdrop = nil, nil, nil
			zoom = 1
			PaintFonts()
			GripLabel(host, 1)
		end
		box:Hide()
		if host:GetAlpha() ~= 1 then host:SetAlpha(1) end
	end

	local function Tick()
		Sections(host)
		local holder = _G.DaylightUIQuestTracker
		if not Dressed() or not ns.Usable(holder) or not holder:IsShown() then
			Undock()
			return
		end
		-- (The tracker's list: found once; the handle stands in until it is there.)
		found = found or TrackerList(holder)
		local list = found or holder
		-- Nothing moved, grew, faded or changed size since the last look: nothing to do.
		-- (Compared value by value: a string of them, made four times a second, was garbage.)
		if not Moved(list:GetRight() or 0, list:GetTop() or 0, list:GetBottom() or 0, host:GetWidth() or 0,
			host:GetHeight() or 0, holder:GetAlpha() or 1, host:GetLeft() or 0, host:GetTop() or 0,
			list:GetEffectiveScale(), host:GetEffectiveScale()) then
			return
		end
		local le = list:GetEffectiveScale() / uiScale()
		local he = host:GetEffectiveScale() / uiScale()
		local right, top, bottom = list:GetRight(), list:GetTop(), list:GetBottom()
		local hw, hh = host:GetWidth(), host:GetHeight()
		if not (right and top and bottom and hw and hw > 0) then return end
		right, top, bottom = right * le, top * le, bottom * le
		local listW = (list:GetWidth() or 0) * le

		if not db.foreverDocked then
			db.foreverDocked = true
			if type(api.GetScale) == "function" then db.foreverScale = api.GetScale() end
			local s = Spot()
			if s then db.foreverX, db.foreverY = s.x, s.y end
			if not placed then pcall(api.SetAttached, false) end
		end
		-- Locked while docked: nothing to drag, and its grip's "Forever tracker" label goes with it.
		-- (Once a session: a column docked before this was added was never locked.)
		if not settled then
			settled = true
			if type(api.IsLocked) == "function" and type(api.SetLocked) == "function" and not api.IsLocked() then
				if db.foreverLocked == nil then db.foreverLocked = false end
				pcall(api.SetLocked, true)
			end
			-- ForeverCore's own background behind the column (its menu's "Tracker background", the
			-- tooltip's color at an opacity of the player's) would show through DaylightUI's box:
			-- none while docked, the player's opacity kept and put back after.
			if type(api.GetBackdropOpacity) == "function" and type(api.SetBackdropOpacity) == "function" then
				local ok, opacity = pcall(api.GetBackdropOpacity)
				if ok and type(opacity) == "number" and opacity > 0 then
					if db.foreverBackdrop == nil then db.foreverBackdrop = opacity end
					pcall(api.SetBackdropOpacity, 0)
				end
			end
			GripLabel(host, 0)
		end

		-- As wide as the tracker's list, through ForeverCore's own scale; text sizes make up for it.
		if listW > 0 and type(api.SetScale) == "function" and type(api.GetScale) == "function" then
			local want = (api.GetScale() or 1) * listW / (hw * he)
			if math.abs(want - (api.GetScale() or 1)) > 0.01 then pcall(api.SetScale, want) end
		end
		local z = (list:GetEffectiveScale()) / host:GetEffectiveScale()
		if math.abs(z - zoom) > 0.01 then
			zoom = z
			Restyle(host)
		end

		-- Under the tracker's box (or over it, with a list that grows upward), box to box.
		local pad = PAD[2] * le
		local grip = gripH * he
		local contentH = math.max(0, hh * he - grip)
		local contentTop
		if Quests("growUp") == true then
			contentTop = top + pad + GAP + pad + contentH
		else
			contentTop = bottom - pad - GAP - pad
		end
		local x = right - hw * he
		local y = contentTop + grip - UIParent:GetTop()
		local hl, ht = host:GetLeft(), host:GetTop()
		local at = hl and ht and math.abs(hl * he - x) < 1 and math.abs(ht * he - UIParent:GetTop() - y) < 1
		if not at then pcall(api.SavePosition, x, y) end

		-- The box round the sections (below the grip strip): placed again only when the scales change.
		local px, py = PAD[1] * le / he, PAD[2] * le / he
		if px ~= boxX or py ~= boxY then
			boxX, boxY = px, py
			box:ClearAllPoints()
			box:SetPoint("TOPLEFT", host, "TOPLEFT", -px, -gripH + py)
			box:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", px, -py)
		end
		if not box:IsShown() and Quests("box") == true then PaintBox() end
		-- It fades with the tracker.
		local a = holder:GetAlpha() or 1
		if host:GetAlpha() ~= a then host:SetAlpha(a) end
	end

	C_Timer.NewTicker(0.25, function() ns.Guard(Tick) end)
	ns.Guard(Tick)
	ns.me.On("StyleChanged", function()
		ForgetQuests()
		wipe(last)
		ns.Guard(PaintBox)
		ns.Guard(Restyle, host)
	end)
	ns.me.On("SettingChanged", function(scope)
		if scope == "Quests" or scope == "general" or scope == "DaylightAddonSkins" then
			ForgetQuests()
			wipe(last)
			ns.Guard(PaintBox)
			ns.Guard(Restyle, host)
		end
	end)
end

-- A second after login, as ever. From Shortest Path 1.43.6 the column is made when its ForeverCore
-- starts (at login; after the fight, for a reload made in one): looked for once a second until it
-- is there, ten minutes at most. (Not a watch: this runs with the skin switched off too, to give
-- the column back.)
ns.me.On("Login", function()
	local tries = 0
	local function look()
		if ns.Usable(_G.ForeverTrackerCompanion) and type(_G.ForeverTrackerHost) == "table" then
			ns.Guard(Column)
			return
		end
		tries = tries + 1
		if tries < 600 then C_Timer.After(1, look) end
	end
	C_Timer.After(1, look)
end)


ns.Pack(KEY)

-- ---------------------------------------------------------------------------------------------
-- DaylightUI's in-world marker
-- ---------------------------------------------------------------------------------------------

local PIN = "interface\\addons\\shortestpathforever\\media\\pin"

local function IsTheirPin(child, icon)
	if not ns.Usable(child) or child:GetObjectType() ~= "Frame" or child:GetName() then return false end
	if child:GetNumRegions() ~= 1 then return false end
	local tex = child:GetRegions()
	if not ns.Usable(tex) or tex:GetObjectType() ~= "Texture" then return false end
	local file = tex:GetTexture()
	if type(file) == "string" then return string.lower(file) == PIN end
	-- (A file id: told by where it sits, on the marker's icon.)
	local _, rel = tex:GetPoint(1)
	return rel == icon
end

local hidden = setmetatable({}, { __mode = "k" })   -- its pins kept at nothing here

local function Marker()
	local f = _G.SuperTrackedFrame
	if type(f) ~= "table" or not ns.Usable(f.Icon) then return end
	if not ns.Enabled(KEY) or not ns.DaylightHas("Quests", "nav.marker") then
		-- DaylightUI puts the game's icon back itself when its marker goes off; its pin is ours to.
		for pin in pairs(hidden) do
			if ns.Usable(pin) then pin:SetAlpha(1) end
			hidden[pin] = nil
		end
		return
	end
	f.Icon:SetAlpha(0)
	if ns.Usable(f.IconBorder) then f.IconBorder:SetAlpha(0) end
	for _, child in ipairs({ f:GetChildren() }) do
		if IsTheirPin(child, f.Icon) then
			child:SetAlpha(0)
			hidden[child] = true
		end
	end
end

local function Soon()
	-- After Shortest Path's own handler, which runs in the same moment.
	C_Timer.After(0, function() ns.Guard(Marker) end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("SUPER_TRACKING_CHANGED")
events:RegisterEvent("USER_WAYPOINT_UPDATED")
events:SetScript("OnEvent", Soon)
ns.me.On("SettingChanged", function(scope, path)
	if (scope == "Quests" and path == "nav.marker") or (scope == "DaylightAddonSkins" and path == KEY) then Soon() end
end)

-- ---------------------------------------------------------------------------------------------
-- Hand-over: map pins
-- ---------------------------------------------------------------------------------------------

-- ForeverCore's own quest list ("Forever quest list", ForeverCoreDB.questList): its quests drawn
-- in the Forever column, the same quests DaylightUI's tracker lists right above it. Read and set
-- through ForeverCore's own calls, which redraw the column. ForeverCore 1.15 removed the list (and
-- TrackerQuests with it): there the entry is marked gone.
local QUEST_LIST = "questList"
local function ForeverQuests()
	local core = _G.ForeverCore
	local q = type(core) == "table" and core.TrackerQuests
	if type(q) == "table" and type(q.Enabled) == "function" and type(q.SetEnabled) == "function" then return q end
end

ns.Handover(KEY, {
	ready = function() return type(_G.ShortestPathForeverDB) == "table" end,
	get = function(key)
		if key == QUEST_LIST then
			local q = ForeverQuests()
			if not q then return nil end
			local ok, on = pcall(q.Enabled)
			if ok then return on end
			return nil
		end
		return _G.ShortestPathForeverDB[key]
	end,
	-- Through the game's Settings, where it registered each of them: its own refresh runs and the
	-- change shows at once. (Its saved table straight, when that isn't there.)
	set = function(key, value)
		if key == QUEST_LIST then
			local q = ForeverQuests()
			if q then pcall(q.SetEnabled, value) end
			return
		end
		local setting = type(Settings) == "table" and type(Settings.GetSetting) == "function"
			and Settings.GetSetting("ShortestPathForever_" .. key)
		if setting and type(setting.SetValue) == "function" and pcall(setting.SetValue, setting, value) then return end
		_G.ShortestPathForeverDB[key] = value
	end,
	list = {
		{ key = "mapFlightMasters", label = L["Flight Master Pins on the World Map"],
		  daylight = ns.In(L["map pins"], "Window Skins"),
		  ours = function() return ns.DaylightHas("Skins", "mapFlights") end },
		{ key = "pins", label = L["Boat and Zeppelin Pins on the World Map"],
		  daylight = ns.In(L["map pins"], "Window Skins"),
		  ours = function() return ns.DaylightHas("Skins", "mapTravel") end },
		{ key = "destinationPin", label = L["Pin Over the Destination"],
		  daylight = ns.In(L["the in-world quest marker"], "Quests", "Navigation"),
		  ours = function() return ns.DaylightHas("Quests", "nav.marker") end },
		{ key = "arrow", label = L["Direction Arrow (and the Route Marker It Sets)"],
		  daylight = string.format(L["the quest arrow (%s); with Shortest Path's off, routes no longer steer the marker"],
			string.format(L["%s, %s"], ns.Module("Quests"), ns.Module("Navigation"))),
		  ours = function() return ns.DaylightHas("Quests", "nav.arrow") end },
		-- (Gone from ForeverCore 1.15: never asked about there, only given back if it was handed over.)
		{ key = QUEST_LIST, label = L["Forever Quest List"],
		  daylight = ns.In(L["your quest list"], "Quests"), gone = ForeverQuests() == nil,
		  ours = function() return ForeverQuests() ~= nil and ns.ModuleOn("Quests") end },
	},
})
