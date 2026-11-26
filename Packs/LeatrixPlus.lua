-- Leatrix Plus: its options window, its 31 configuration panels and its own windows in the
-- DaylightUI look, and its switches DaylightUI also has handed over. Built against Leatrix Plus
-- 1.60.35 (Forever build: Leatrix_Plus.toc, Leatrix_Plus.lua, Leatrix_Plus.xml); checked against
-- 1.60.38, whose redesigned Sell Junk exceptions and Mute Game Sounds custom panels are dressed too
-- (see "1.60.38" below).
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
--     hover, an information-only entry (the bag and bank counts) in the off ink, its gold
--     dividers a faint line; the panel tabs (MakePanelTab) as DaylightUI's tabs, their gold
--     sheen off and the tab look put back after Leatrix Plus recolors them (on show, enter and
--     leave); the blue list boxes (scrolling panels, junk and mute lists) as insets, a gold-edged
--     bar frame as a plain outline.
--   * 1.60.38's Sell Junk exceptions and Mute Game Sounds custom panels: the search, item ID,
--     sound ID and description boxes (plain boxes with a faint fill) as DaylightUI's input box,
--     their hints in the off ink, their round clear crosses as DaylightUI's X; the sort column
--     headings in the label ink (light on hover, the sorted column and its arrow in the accent);
--     list rows in the player's font, a picked row's gold fill and the gold flash on a new row in
--     the accent, the playing note in the accent; the gold plus, play and stop marks on the Add,
--     Play and Stop buttons in the text ink; the gold drag-target outlines (MakeDropGlow) kept as
--     the drop cue, in the accent (never an inset); the help plates (CreateHelpPlate): the help
--     button in the label ink, its ring and the plate's boxes (hover too) in the accent. Its item
--     tooltip (LeaPlusSellJunkListTooltip, GameTooltipTemplate) is filled by SetItemByID, so
--     DaylightUI's tooltip skin (its TooltipDataProcessor post-call) dresses it as GameTooltip.
--     The rows are made as the list fills: they're left out of the walk and dressed here, again
--     when the list grows (its scroll child's size change), never by polling.
--   * Its own windows: the recent chat window, the flight time report and the help panel (their
--     ground, hairlines and gold accent line off, the shell on), the info card (its backdrop off,
--     the shell on; its inner layout kept). Their boxes' own fill and outline off: the recent
--     chat's search box and the one-line copy boxes as DaylightUI's input box, the flight
--     report's several-line report box as an inset well.
-- Kept as Leatrix Plus draws them: quality and class colors, the junk list's action colors (keep,
-- sell, can't be sold), red sound IDs that won't play, its orange footer messages, the help
-- plates' info icons and dimmed plate, item icons, the info card's inside,
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
			-- (Its gold divider above an entry: a faint line, as DaylightUI's menus.)
			if IsTexture(row.Divider) then row.Divider:SetColorTexture(1, 1, 1, 0.08) end
			ns.ScriptOnce(row, "OnClick", function() InkRows(list) end, KEY)
		end
		if ar then row.Check:SetVertexColor(ar, ag, ab, 1) end
		local off = ns.Colors().OFF
		if row.IsEnabled and not row:IsEnabled() and off then
			-- An information-only entry (the bag and bank counts): it can't be clicked.
			row.Text:SetTextColor(off[1], off[2], off[3])
		elseif row.Check:IsShown() and ar then
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

-- A panel's tabs (MakePanelTab, 1.60.38; MakeMiniTab before it: a backdrop button with its own
-- .text). Which one is picked never changes on a panel: each tab opens another panel. Leatrix Plus
-- recolors its words and shows its gold or white sheen (.sheen) on every show, enter and leave
-- (SetPanelTabStyle, from its scripts): the sheen is masked off for good, and the tab look is put
-- back after its show (the Kit's own hooks repaint on enter and leave, after its scripts).
local function PaintTab(tab)
	local t = ns.Kit and ns.Kit.TabOf(tab)
	if t and t.Paint then t.Paint(tab:IsMouseOver() == true) end
end

local function MiniTab(tab)
	if looked[tab] then return end
	looked[tab] = true
	local Kit = ns.Kit
	Kit.Backdrop(tab)
	if IsTexture(tab.sheen) then Kit.Erase(tab.sheen) end
	-- (Kit.Tab reads a tab's words from .Text.)
	if tab.Text == nil then tab.Text = tab.text end
	Kit.Tab(tab, function(t) return t.selected == true end)
	ns.ScriptOnce(tab, "OnShow", function() PaintTab(tab) end, KEY)
	PaintTab(tab)
end

-- ---------------------------------------------------------------------------------------------
-- 1.60.38: the Sell Junk exceptions and Mute Game Sounds custom panels
-- ---------------------------------------------------------------------------------------------

-- Its gold marks (a sort arrow, a picked row's fill, the plus on a button): repainted when
-- DaylightUI's style or the accent changes. ink: one of DaylightUI's inks, nil for the accent;
-- fill: a plain color texture (SetColorTexture), else a picture tinted.
local marks = setmetatable({}, { __mode = "k" })
local function PaintMark(tex, m)
	if m.ink then
		local c = ns.Colors()[m.ink]
		if not c then return end
		if m.fill then tex:SetColorTexture(c[1], c[2], c[3], m.alpha) else tex:SetVertexColor(c[1], c[2], c[3], m.alpha) end
	elseif m.fill then
		ns.FillAccent(tex, m.alpha, nil, KEY)
	else
		ns.PaintAccent(tex, m.alpha, nil, KEY)
	end
end

local function Mark(tex, fill, ink, alpha)
	if not IsTexture(tex) or marks[tex] then return end
	local m = { fill = fill and true or false, ink = ink, alpha = alpha or 1 }
	marks[tex] = m
	PaintMark(tex, m)
end

-- A drag-target outline (MakeDropGlow: a 1 px edged backdrop with a pulse, shown while an item is
-- held over the list or the search box): kept as the drop cue, its gold in the accent, its own
-- faint fill kept.
local glows = setmetatable({}, { __mode = "k" })   -- outline -> its fill's alpha
local function PaintGlow(glow, a)
	local r, g, b = ns.AccentOf(KEY)
	glow:SetBackdropColor(r, g, b, a)
	glow:SetBackdropBorderColor(r, g, b, 1)
end

local function IsDropGlow(f)
	return Kind(f) == "Frame" and Kind(f.pulse) == "AnimationGroup" and not IsTexture(f.icon)
		and f.SetBackdropColor ~= nil
end

local function DropGlow(f)
	if glows[f] then return end
	looked[f] = true
	local _, _, _, a = f:GetBackdropColor()
	glows[f] = type(a) == "number" and a or 0.1
	PaintGlow(f, glows[f])
end

-- A help plate's box (CreateHelpPlate: edged backdrop with an info icon and its glow): its gold in
-- the accent, brighter on hover (Leatrix Plus recolors it in its own enter and leave scripts; the
-- hooks run after them).
local helpBoxes = setmetatable({}, { __mode = "k" })
local function PaintHelpBox(box, over)
	if over == nil then over = box:IsMouseOver() == true end
	local r, g, b = ns.AccentOf(KEY)
	box:SetBackdropColor(r, g, b, over and 0.15 or 0.05)
	box:SetBackdropBorderColor(r, g, b, over and 1 or 0.7)
end

local function IsHelpBox(f)
	return Kind(f) == "Frame" and IsTexture(f.icon) and IsTexture(f.glow) and f.SetBackdropColor ~= nil
end

local function HelpBox(box)
	if helpBoxes[box] then return end
	helpBoxes[box] = true
	looked[box] = true
	ns.ScriptOnce(box, "OnEnter", function() PaintHelpBox(box, true) end, KEY)
	ns.ScriptOnce(box, "OnLeave", function() PaintHelpBox(box, false) end, KEY)
	PaintHelpBox(box)
end

local function HelpBoxes(plate)
	Each_(function(c) if IsHelpBox(c) then HelpBox(c) end end, plate:GetChildren())
end

-- The help button by a panel's title (its gold-tinted info icon in the label ink, its ring while
-- the help shows in the accent) and its plate, a sibling with a .dim shade: the plate's boxes are
-- made the first time it shows, so they're dressed from its show (after its own script).
local function HelpButton(btn)
	if looked[btn] then return end
	looked[btn] = true
	Mark(btn:GetNormalTexture(), false, "LABEL", 1)
	if btn.ring.SetDesaturated then btn.ring:SetDesaturated(true) end
	Mark(btn.ring, false, nil, 1)
	local parent = btn:GetParent()
	if not Usable(parent) then return end
	Each_(function(p)
		if Kind(p) == "Frame" and IsTexture(p.dim) and type(p.fade) == "table" and not looked[p] then
			looked[p] = true
			ns.ScriptOnce(p, "OnShow", function() HelpBoxes(p) end, KEY)
			HelpBoxes(p)
		end
	end, parent:GetChildren())
end

-- A sort column heading (MakeSortHeading: a button with .text and .arrow): the label ink, light on
-- hover, the sorted one (its arrow shown) in the accent, as DaylightUI's column headers. Leatrix
-- Plus sets white on enter and gold on leave; the hooks run after.
local heads = setmetatable({}, { __mode = "k" })
local function PaintHeading(h, over)
	if over == nil then over = h:IsMouseOver() == true end
	if over then
		Ink(h.text, "VALUE")
	elseif h.arrow:IsShown() then
		local r, g, b = ns.AccentOf(KEY)
		h.text:SetTextColor(r, g, b)
	else
		Ink(h.text, "LABEL")
	end
end

local function PaintHeadings(parent)
	for h in pairs(heads) do
		if h:GetParent() == parent then PaintHeading(h) end
	end
end

local function IsHeading(f)
	return Kind(f) == "Button" and Kind(f.text) == "FontString" and IsTexture(f.arrow)
end

local function Heading(h)
	if heads[h] then return PaintHeading(h) end
	heads[h] = true
	looked[h] = true
	ns.FollowFont(h.text, KEY)
	-- (A drawn triangle is a color texture; without SetVertexOffset it's the game's arrow picture.)
	Mark(h.arrow, h.arrow.SetVertexOffset ~= nil, nil, 1)
	ns.ScriptOnce(h, "OnEnter", function() PaintHeading(h, true) end, KEY)
	ns.ScriptOnce(h, "OnLeave", function() PaintHeading(h, false) end, KEY)
	-- (A click moves the sort: every heading of the list again.)
	ns.ScriptOnce(h, "OnClick", function() PaintHeadings(h:GetParent()) end, KEY)
	PaintHeading(h)
end

-- The gold marks on its text buttons (the Add button's plus, two bars anchored to an empty .icon;
-- the Play button's .play and .stop; the heading Stop button's .icon square): the text ink. A
-- button's .icon picture (the sound finder's atlas icons) stays.
local function ButtonIcons(b)
	if looked[b] then return end
	looked[b] = true
	local holder = b.icon
	if IsTexture(holder) then
		local bars = false
		Each_(function(r)
			if IsTexture(r) and r ~= holder and select(2, r:GetPoint(1)) == holder then
				bars = true
				Mark(r, true, "TEXT", 1)
			end
		end, b:GetRegions())
		if not bars then
			local atlas = holder.GetAtlas and holder:GetAtlas()
			local ok, file = pcall(holder.GetTextureFileID, holder)
			local picture = (type(atlas) == "string" and atlas ~= "") or (ok and type(file) == "number" and file > 0)
			if not picture then Mark(holder, true, "TEXT", 1) end
		end
	end
	if IsTexture(b.play) then Mark(b.play, b.play.SetVertexOffset ~= nil, "TEXT", 1) end
	if IsTexture(b.stop) then Mark(b.stop, true, "TEXT", 1) end
end

-- Its plain boxes (the search box, the item ID box, the sound ID and description boxes, the inline
-- description editor: an EditBox with only a faint .bg fill): DaylightUI's input box, the hint
-- words in the off ink and the player's font, the magnifier in the off ink, the round clear cross
-- as DaylightUI's X (its picture masked: Leatrix Plus fades it on enter and leave), the drop
-- outline on the search box in the accent.
local function PlainBox(eb)
	if looked[eb] then return end
	looked[eb] = true
	local Kit = ns.Kit
	local controls = Controls()
	local off = ns.Colors().OFF
	-- (Its own regions first: the input look adds its own.)
	Each_(function(r)
		if Kind(r) == "FontString" then
			ns.FollowFont(r, KEY)
		elseif controls and off and r ~= eb.bg and IsTexture(r) and r:GetDrawLayer() == "OVERLAY" then
			r:SetVertexColor(off[1], off[2], off[3])
		end
	end, eb:GetRegions())
	Kit.InkGameText(eb)
	Each_(function(c)
		if IsDropGlow(c) then
			DropGlow(c)
		elseif controls and Kind(c) == "Button" and IsTexture(c.icon) then
			Kit.Erase(c.icon)
			Kit.Close(c)
		end
	end, eb:GetChildren())
	if controls then
		Kit.Erase(eb.bg)
		Kit.EditBox(eb)
	end
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

-- A button the walk passed over: a menu row, a result row, a sort heading, a help button, a panel
-- tab, a cogwheel.
local function Button(frame)
	if IsTexture(frame.t) and IsTexture(frame.s) and Kind(frame.f) == "FontString" then
		MenuRow(frame)
	elseif IsTexture(frame.hl) and Kind(frame.f) == "FontString" and Kind(frame.e) == "FontString" then
		ResultRow(frame)
	elseif IsHeading(frame) then
		Heading(frame)
	elseif IsTexture(frame.ring) and IsTexture(frame:GetNormalTexture()) then
		HelpButton(frame)
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
		-- (A drag-target outline and a help plate's box are backdrops too: never an inset.)
		if IsDropGlow(frame) then
			DropGlow(frame)
		elseif IsHelpBox(frame) then
			HelpBox(frame)
		elseif frame:IsMouseWheelEnabled() and frame:GetFrameStrata() == "FULLSCREEN_DIALOG" then
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
	ButtonIcons(b)
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
		elseif IsTexture(c.bg) then
			PlainBox(c)
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

-- A list's rows (1.60.38's junk and mute lists: buttons with .sel and .idText, made as the list
-- fills): the player's font, the picked row's gold fill in the accent wash. With them in the
-- scroll child: the gold flash on a new row (.t) and the playing note (.head / .stem / .flag) in
-- the accent, the inline description editor as an input box. Each piece once.
local function ListParts(child)
	Each_(function(c)
		local k = Kind(c)
		if k == "Button" and IsTexture(c.sel) and Kind(c.idText) == "FontString" then
			if not looked[c] then
				looked[c] = true
				Mark(c.sel, true, nil, (ns.Kit and ns.Kit.ROW_PICK) or 0.16)
				Each_(function(r) if Kind(r) == "FontString" then ns.FollowFont(r, KEY) end end, c:GetRegions())
			end
		elseif k == "EditBox" then
			Part(c)
		elseif k == "Frame" and not looked[c] then
			if IsTexture(c.head) and IsTexture(c.stem) and IsTexture(c.flag) then
				looked[c] = true
				Mark(c.head, false, nil, 1)
				Mark(c.stem, true, nil, 1)
				Mark(c.flag, true, nil, 1)
			elseif IsTexture(c.t) then
				looked[c] = true
				Mark(c.t, true, nil, 0.35)
			end
		end
	end, child:GetChildren())
end

-- A list box of 1.60.38's panels (the panel's .tabAnchor): its scroll child is left out of the
-- window's walk (skip) and dressed here, again whenever the list grows (a new row makes the scroll
-- child taller); its sort headings and drop outline at once.
local function ListBox(eb, skip)
	Each_(function(c)
		local k = Kind(c)
		if k == "ScrollFrame" and c.GetScrollChild then
			local child = c:GetScrollChild()
			if Usable(child) then
				skip[child] = true
				ListParts(child)
				ns.ScriptOnce(child, "OnSizeChanged", function() ListParts(child) end, KEY)
			end
		elseif IsHeading(c) then
			Heading(c)
		elseif IsDropGlow(c) then
			DropGlow(c)
		end
	end, eb:GetChildren())
end

-- Everything of the pieces above that follows the accent or DaylightUI's inks, painted again.
local function Repaint()
	PaintPicks()
	for tex, m in pairs(marks) do PaintMark(tex, m) end
	for glow, a in pairs(glows) do PaintGlow(glow, a) end
	for box in pairs(helpBoxes) do PaintHelpBox(box) end
	for h in pairs(heads) do PaintHeading(h) end
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
	-- (1.60.38's list panels: their rows are dressed by the pack, not the walk.)
	local opts
	if Usable(f.tabAnchor) and f.tabAnchor:GetParent() == f then
		opts = { skip = {} }
		ListBox(f.tabAnchor, opts.skip)
	end
	if ns.Walk then
		ns.Walk(Kit, f, opts, nil, function(frame) Each(frame, f) end, KEY)
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
ns.me.On("StyleChanged", function() if On() then Repaint() end end)
ns.me.On("SettingChanged", function(scope)
	if scope == "DaylightAddonSkins" and On() then Repaint() end
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
