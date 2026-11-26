-- Questie: what DaylightUI's own Questie support leaves as Questie draws it. DaylightUI already
-- dresses its AceGUI windows (My Journey, notes, the old options), puts its objective icons in
-- DaylightUI's art, keeps its tracker and NPC tooltip lines aside while DaylightUI's draw, skins its
-- tooltips and collects its minimap button: none of that is touched here, nor any Questie setting
-- DaylightUI's QuestieAside switches.
-- Dressed here: its current settings window (QuestieStandaloneSettings: shell, side tabs with
-- DaylightUI's hover wash and the accent outline following each click, the controls on each tab
-- including the play-sound buttons, the color swatches and the gold rules, each tab's scroll bar
-- even when its canvas is built over several frames, and from 12.13 its Search box, label and
-- "No matching options" line, each tab built again as you type), its own popups (QuestiePopup, not the game's StaticPopup: shell, buttons, edit
-- box), the objective type tutorial, its late tooltips (the minimap waypoint and gamepad map
-- tooltips, and from 12.15 the tracker's party-progress tooltip, QuestieTrackerQuestTooltip), its
-- developer profiler window (12.15, QuestieProfilerFrame: shell, buttons, check boxes, search box,
-- close buttons, size grip; its "profiler running" tag, QuestieProfilerIndicator, a small shell),
-- the gold ring on its world map corner button (the shared
-- ns.MapRings pass), and its own tracker while the player has picked Questie's over DaylightUI's
-- (the shell in place of its backdrop, following Questie's own backdrop switch, color opacity and
-- fader). Its pages in the game's Settings window (Esc > Options > AddOns > Questie and each page
-- under it) get the same treatment as that window's tabs: the same controls, inks, rules, title
-- and scroll bar, caught as each page is built over its first few frames.
-- Its right-click menus are the game's own since 12.12 (QuestieMenuBuilder, Blizzard_Menu), which
-- DaylightUI's window skins dress as they do every game menu; the old LibUIDropDownMenu lists and
-- the debug offer window (gone in 12.10) are no longer looked for (checked against Questie 12.15.0).
-- Left alone: its map and minimap icons, the tracker's lines and buttons (secure item buttons),
-- the profiler's rows, bars and its own drawn scroll bar (a developer's readout).
--
-- "Hand over to DaylightUI" (off until turned on on its page): Questie's quest icons on nameplates
-- step aside while DaylightUI's nameplates mark quest targets.
local _, ns = ...
if not ns.ok then return end
local L = ns.L

local KEY = "Questie"

-- Its settings, menus and popups are made from the game's serif font templates: the player's font
-- goes on their words (font = "daylight"). Its tracker's font is a Questie setting of its own and
-- nothing here touches the tracker's words.
ns.Target(KEY, "Questie", { window = true, controls = true, text = true, shadow = true, colors = true,
	font = "daylight",
	extraTab = "DaylightUI",
	extra = function()
		return { ns.HandoverGroup(KEY) }
	end })

local Loader = _G.QuestieLoader
if type(Loader) ~= "table" or type(Loader.ImportModule) ~= "function" then return end

local function Module(name)
	local ok, m = pcall(Loader.ImportModule, Loader, name)
	return ok and type(m) == "table" and m or nil
end

local function Profile()
	local q = _G.Questie
	local db = type(q) == "table" and q.db
	return type(db) == "table" and type(db.profile) == "table" and db.profile or nil
end

-- ---------------------------------------------------------------------------------------------
-- Settings window: made on first open; each tab's canvas is built, a few rows a frame, the first
-- time it is shown. Its rows are Questie's own controls, not the game's templates, so each one is
-- dressed as Questie makes it (QuestieOptionsControls.Create) rather than found afterwards.
-- ---------------------------------------------------------------------------------------------

local function Accent() return ns.AccentOf(KEY) end

local function Ink(fs, role)
	if not ns.Usable(fs) or not fs.SetTextColor then return end
	if ns.Look(KEY, "daylightColors") == false then return end
	local c = ns.Colors()[role]
	if type(c) == "table" then fs:SetTextColor(c[1], c[2], c[3]) end
end

-- Only the controls of its settings: its own window and its pages in the game's Settings window
-- (Esc > Options > AddOns > Questie, canvases named QuestieOptionsTab_Blizz_<tab>). The same
-- controls fill both; the game's Settings pack only looks a few frames deep into an addon's page,
-- not down to these rows, and leaves what the Kit has dressed alone.
local function InWindow(frame)
	for _ = 1, 16 do
		if not frame then return false end
		local name = frame.GetName and frame:GetName()
		if name and (string.find(name, "^QuestieOptionsTab_Popup_") or string.find(name, "^QuestieOptionsTab_Blizz_")
			or name == "QuestieStandaloneSettings") then return true end
		frame = frame.GetParent and frame:GetParent()
	end
	return false
end

-- The canvas (one tab's page, in either window) a control sits on: the engine's frame carrying
-- the tab and its controls.
local function CanvasOf(frame)
	for _ = 1, 16 do
		if not frame then return nil end
		if type(frame.controls) == "table" and type(frame.tab) == "table" then return frame end
		frame = frame.GetParent and frame:GetParent()
	end
	return nil
end

local function Tint(tex, r, g, b)
	if ns.Usable(tex) then
		tex:SetDesaturated(true)
		tex:SetVertexColor(r, g, b)
	end
end

-- Its gold divider art (Options_HorizontalDivider) as a quiet one-pixel hairline.
local DIVIDER = "Options_HorizontalDivider"
local function Hairlines(...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if ns.Usable(r) and r:GetObjectType() == "Texture" and r.GetAtlas and r:GetAtlas() == DIVIDER and ns.Once(r) then
			r:SetColorTexture(1, 1, 1, 0.08)
			r:SetHeight(1)
		end
	end
end

-- The row's height again, with its words in the player's font: Questie grew the row from its
-- labels' heights as it made them (QuestieOptionsControls _AddRowLabels: the title alone, or title
-- + description + 2 with the title moved to the row's top), in the game's font. Only rows whose
-- labels sit on a row frame of their own (checkboxes, radios, text lines); a dropdown's, a box's
-- and a container's title sits above its widget. Never shrunk.
local function FitRow(control)
	local title, desc = control.titleFrame, control.descriptionFrame
	if not ns.Usable(title) then return end
	local wrapper = title:GetParent()
	if not ns.Usable(wrapper) or wrapper == control then return end
	if not ns.Usable(desc) then
		local h = title:GetStringHeight()
		if type(h) == "number" and h > wrapper:GetHeight() then
			wrapper:SetHeight(h)
			control:SetHeight(h)
		end
		return
	end
	local h = title:GetStringHeight() + desc:GetStringHeight() + 2
	if h <= wrapper:GetHeight() or h <= control:GetHeight() then return end
	-- (Its indent: the x of the title's LEFT point on the row frame.)
	local indent = 0
	for i = 1, title:GetNumPoints() do
		local point, _, _, x = title:GetPoint(i)
		if point == "LEFT" and type(x) == "number" then indent = x end
	end
	control:SetHeight(h)
	title:SetPoint("TOPLEFT", control, "TOPLEFT", indent, 0)
end

-- Its text button sizes itself to its label on every SetText (its own SetText, which puts
-- GameFontHighlight back on first): the player's font after each, and wider when the label in
-- it no longer fits (up to the row's width; a label it already wraps keeps its wrap).
local BUTTON_PADDING = 24
local function FitButton(button)
	if not ns.Enabled(KEY) then return end
	local fs = button.GetFontString and button:GetFontString()
	if not ns.Usable(fs) then return end
	ns.FollowFont(fs, KEY)
	-- (This client's strings have no GetWordWrap: a label on more than one line is one it wraps.)
	if fs.GetWordWrap then
		if fs:GetWordWrap() then return end
	elseif fs.GetNumLines and (fs:GetNumLines() or 1) > 1 then
		return
	end
	local need = (fs:GetStringWidth() or 0) + BUTTON_PADDING
	local row = button:GetParent()
	local most = ns.Usable(row) and row:GetWidth() or need
	if need > button:GetWidth() then button:SetWidth(math.min(need, most)) end
end

local fitted = setmetatable({}, { __mode = "k" })
local function FollowButton(button)
	if fitted[button] or type(button.SetText) ~= "function" then return end
	fitted[button] = true
	local set = button.SetText
	button.SetText = function(self, ...)
		set(self, ...)
		FitButton(self)
	end
	FitButton(button)
end

-- The player's font on a row's words (names, sentences, a slider's name, ends and value) as it is
-- made, then its height again; a text button its label.
local function ControlFonts(control)
	if ns.PlainText(KEY) then return end
	local w = control.widget
	ns.FollowFont(control.titleFrame, KEY)
	ns.FollowFont(control.descriptionFrame, KEY)
	ns.FollowFont(control.valueDisplay, KEY)
	if type(w) == "table" then
		ns.FollowFont(w.Text, KEY)
		ns.FollowFont(w.Low, KEY)
		ns.FollowFont(w.High, KEY)
	end
	FitRow(control)
	local item = control.itemData
	if type(item) == "table" and item.type == "button" and ns.Usable(w) then FollowButton(w) end
	ns.FontsIn(control, KEY)
end

local function DressControl(Kit, control)
	local item, w = control.itemData, control.widget
	local kind = type(item) == "table" and item.type
	if kind == "checkbox" then
		ns.Guard(Kit.Check, w)
	elseif kind == "radioButton" then
		-- A radio stays a radio: its tick in the accent.
		local r, g, b = Accent()
		if ns.Usable(w) then
			Tint(w:GetCheckedTexture(), r, g, b)
			Tint(w:GetDisabledCheckedTexture(), 0.5, 0.5, 0.5)
		end
	elseif kind == "slider" and ns.Usable(w) then
		local r, g, b = Accent()
		Tint(w:GetThumbTexture(), r, g, b)
		for _, key in ipairs({ "TrackLeft", "TrackMiddle", "TrackRight" }) do Tint(w[key], 0.45, 0.45, 0.48) end
	elseif kind == "dropdown" or kind == "fontDropdown" then
		ns.Guard(Kit.Dropdown, w)
	elseif kind == "container" then
		-- Its gold glue-tooltip border becomes a quiet well (Questie draws it at 0.45 opacity).
		local box = control.containerFrame
		if ns.Usable(box) then
			for _, region in ipairs({ box:GetRegions() }) do
				if region:GetObjectType() == "Texture" then region:SetAlpha(0) end
			end
			if ns.Usable(box.NineSlice) then box.NineSlice:SetAlpha(0) end
			ns.Shell(box, { noBevel = true }, KEY)
		end
	elseif kind == "button" and ns.Usable(w) then
		-- Its red button art (three slices per state, shown and hidden as it is pressed) stays at
		-- nothing; the button is DaylightUI's.
		for _, region in ipairs({ w:GetRegions() }) do
			if region:GetObjectType() == "Texture" then region:SetAlpha(0) end
		end
		local hl = w:GetHighlightTexture()
		if ns.Usable(hl) then hl:SetAlpha(0) end
		ns.Shell(w, nil, KEY)
		ns.Guard(Kit.Button, w)
	elseif kind == "soundButton" and ns.Usable(w) then
		-- Its play button is the red button's arrow turned sideways: DaylightUI's page button.
		ns.Guard(Kit.PageButton, w, "right")
	elseif kind == "colorPicker" and ns.Usable(w) then
		-- Its gold ring off; the swatch square (its round mask off) with a thin edge.
		ns.Kill(w.border)
		local swatch = w.swatch
		if ns.Usable(swatch) and ns.Once(swatch) then
			local mask = swatch.GetMaskTexture and swatch:GetMaskTexture(1)
			if mask then swatch:RemoveMaskTexture(mask) end
			ns.Guard(Kit.Outline, swatch, 1, "outline", false, { borderPx = 1 })
		end
	elseif kind == "divider" then
		-- Its gold rules beside the heading (on a row frame beside the control): hairlines.
		local wrapper = ns.Usable(control.titleFrame) and control.titleFrame:GetParent()
		if ns.Usable(wrapper) then Hairlines(wrapper:GetRegions()) end
	end
	-- Template boxes and buttons among them (a text box and its OK button).
	ns.Dress(control, { checks = false, scrollBars = false }, 0, KEY)
end

-- One canvas's own pieces, in either window: its scroll bar (<canvas>_ScrollScrollBar), its
-- header's words (the big gold title in GameFontNormalHuge went in 12.13, which keeps only the
-- subtitle) and the gold rule under its header. All are made before its first control, so they
-- are there by the pass after it.
-- From 12.13 a tab is built on a hidden frame of its own (canvas.pendingContent) and swapped in
-- as canvas.content only once the build is done (QuestieOptionsEngine.lua:325-393), and its
-- window's search builds every shown tab again, scroll bar and all, on each letter typed
-- (SetSearchText, :547). So the frame being built is looked over too, and true is returned while
-- one is still being built: the caller looks again on the next frame, until the finished one is
-- in place (with its "No matching options" line, canvas.noResults, :366-370, made then).
local function CanvasChrome(Kit, canvas, controls)
	if not ns.Usable(canvas) then return end
	local name = canvas:GetName()
	-- (A rebuild makes the bar again under the same name: the global is always the newest.)
	local bar = name and _G[name .. "_ScrollScrollBar"]
	if controls and ns.Usable(bar) and ns.Once(bar) then ns.Guard(Kit.ScrollBar, bar) end
	for _, content in ipairs({ canvas.content or false, canvas.pendingContent or false }) do
		if ns.Usable(content) then
			Hairlines(content:GetRegions())
			for _, region in ipairs({ content:GetRegions() }) do
				if region:GetObjectType() == "FontString" then ns.FollowFont(region, KEY) end
			end
		end
	end
	local none = canvas.noResults
	if ns.Usable(none) and ns.Once(none) then
		Ink(none, "TEXT")
		ns.FollowFont(none, KEY)
	end
	return ns.Usable(canvas.pendingContent) and canvas:IsVisible() or false
end

-- Its pages in the game's Settings window: each is built, a few rows a frame, the first time it is
-- shown. Each page a control was just made on is looked over once on the next frame (only its own
-- frames: nothing of the Settings panel's is hooked).
local blizzPending = {}    -- canvas -> true, until the next frame's pass
local function BlizzPass()
	local Kit = ns.Kit
	if not Kit or not ns.Enabled(KEY) then wipe(blizzPending) return end
	local controls = ns.Controls(KEY)
	local again
	for canvas in pairs(blizzPending) do
		blizzPending[canvas] = nil
		-- (Still being built, 12.13: looked at again next frame, once it's in place.)
		local ok, building = ns.Guard(CanvasChrome, Kit, canvas, controls)
		if ok and building then
			again = again or {}
			again[#again + 1] = canvas
		end
	end
	if again then
		for _, canvas in ipairs(again) do blizzPending[canvas] = true end
		ns.Queue("Questie:blizzPages", BlizzPass, KEY)
	end
end
local function QueueBlizz(canvas)
	blizzPending[canvas] = true
	ns.Queue("Questie:blizzPages", BlizzPass, KEY)
end

-- The settings window's own pass (side tabs, each tab's scroll bar, title and rule), set once the
-- window is found; asked for again, once on the next frame, while a tab is still being built.
local QueueTabs

local Controls = Module("QuestieOptionsControls")
if Controls and type(Controls.Create) == "function" then
	local origCreate = Controls.Create
	Controls.Create = function(parent, ...)
		local control = origCreate(parent, ...)
		if type(control) == "table" and ns.Enabled(KEY) and InWindow(parent) then
			ns.Guard(ControlFonts, control)
		end
		if type(control) == "table" and ns.Enabled(KEY) and ns.Controls(KEY) and InWindow(parent) then
			ns.WithKit(function(Kit) DressControl(Kit, control) end)
			-- A tab's canvas is built over several frames, its scroll bar after the first pause.
			local canvas = CanvasOf(parent)
			local name = canvas and canvas:GetName()
			if name and string.find(name, "^QuestieOptionsTab_Blizz_") then
				QueueBlizz(canvas)
			elseif QueueTabs then
				QueueTabs()
			end
		end
		return control
	end
	-- Its colors: gold names, white descriptions, set again on every refresh. DaylightUI's:
	-- names white, sentences soft white, headings tan, off dimmed.
	if type(Controls.Refresh) == "function" then
		ns.HookOnce(Controls, "Refresh", function(control)
			if type(control) ~= "table" or not ns.Enabled(KEY) or not InWindow(control) then return end
			local item, w = control.itemData, control.widget
			local on = not (w and w.IsEnabled) or w:IsEnabled()
			local heading = type(item) == "table" and (item.type == "container" or item.type == "divider")
			Ink(control.titleFrame, not on and "OFF" or heading and "LABEL" or "VALUE")
			Ink(control.descriptionFrame, on and "TEXT" or "OFF")
			-- A slider's name sits on the slider itself, its value under it.
			if type(item) == "table" and item.type == "slider" and type(w) == "table" then
				Ink(w.Text, on and "VALUE" or "OFF")
				Ink(control.valueDisplay, on and "TEXT" or "OFF")
			end
		end, KEY)
	end
end

ns.Watch(KEY, "QuestieStandaloneSettings", function(frame, Kit)
	if not ns.Once(frame) then return end
	ns.Guard(Kit.Window, frame)
	local controls = ns.Controls(KEY)
	-- Side tabs, and each tab's scroll bar (QuestieOptionsTab_Popup_<tab>_ScrollScrollBar).
	local building = false
	local function tabs()
		building = false
		for _, child in ipairs({ frame:GetChildren() }) do
			if ns.Usable(child) and child.Background and child.Selected and child.Icon then
				if ns.Once(child) then
					ns.Kill(child.Background)
					if controls then
						-- A clean tile round its icon (ns.SideTile, as TrueshotLodge's and OpenMap's
						-- tabs): its gold selected glow and hover art off. Its picked state is still
						-- read from that glow being shown; the button inside the tab takes the mouse.
						ns.Kill(child.Highlight)
						if child.Selected.SetAlpha then child.Selected:SetAlpha(0) end
						-- (Its icon is drawn larger than the tab under a round mask: drawn again on the
						-- tile, cropped and evenly framed.)
						local made = ns.Guard(ns.SideTile, child, {
							picked = function(t) return t.Selected:IsShown() end,
							mouse = ns.Usable(child.button) and child.button or nil,
							copy = true,
							key = KEY,
						})
						if made and child.Selected.SetShown then
							ns.HookOnce(child.Selected, "SetShown", ns.SideTilesPaintSoon, KEY)
						end
					end
				end
				-- The tab's canvas: its scroll bar, big gold title and the gold rule under its header.
				local key = string.match(child:GetName() or "", "_Tab_(.+)$")
				local canvas = key and _G["QuestieOptionsTab_Popup_" .. key]
				if canvas and CanvasChrome(Kit, canvas, controls) then building = true end
			end
		end
		-- Its search (12.13, QuestieOptionsWindow.lua:28-52): a "Search" label in the game's gold
		-- (set once, as it's made) and an InputBoxTemplate box, both on the window itself. The box
		-- is dressed by the walk on every show (a template box); its words and the label's here.
		local label, box = frame.searchLabel, frame.searchBox
		if ns.Usable(label) and ns.Once(label) then Ink(label, "LABEL") end
		if ns.Usable(label) then ns.FollowFont(label, KEY) end
		if ns.Usable(box) then ns.FollowFont(box, KEY) end
		if building and QueueTabs then QueueTabs() end
	end
	-- (fonts: its title, tab names and page words, followed on every show.)
	ns.DressOnShow(frame, { fonts = true }, tabs)
	local function Run()
		if frame:IsShown() then ns.Guard(tabs) end
	end
	QueueTabs = function()
		ns.Queue("Questie:settingsTabs", Run, KEY)
	end
	-- A click on a tab: the picked tile moves (repainted on the click of the button inside it), and the tab's canvas, built on its first showing, is looked
	-- over as it arrives.
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and child.button and child.button.HookScript then
			ns.ScriptOnce(child.button, "OnClick", function()
				if not ns.Enabled(KEY) then return end
				if controls then ns.SideTilesPaintSoon() end
				QueueTabs()
			end, KEY)
		end
	end
end)

-- The window is made on its first opening (ShowFrame, through every way it opens: the minimap
-- button, the tracker, the slash command, the menu): looked for right after that call, once its
-- tabs are made and before it's drawn.
local OptionsEngine = Module("QuestieOptionsEngine")
if OptionsEngine and type(OptionsEngine.ShowFrame) == "function" then
	ns.HookOnce(OptionsEngine, "ShowFrame", function() ns.WatchNow() end, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- Questie's own popups: its dialog art kept at nothing under the shell, the edit box a quiet well.
-- ---------------------------------------------------------------------------------------------

local function Dialog(f)
	if not ns.Usable(f) or not ns.Enabled(KEY) then return end
	if not ns.Once(f) then return end
	for _, part in ipairs({ f.Background, f.Border }) do
		if ns.Usable(part) then part:SetAlpha(0) end
	end
	ns.NoBackdrop(f)
	ns.Shell(f, { window = true }, KEY)
	if ns.Usable(f.Text) then ns.Refont(f.Text, KEY) end
	-- Its two buttons (gold dialog-button art, gold words) and its edit box (a flat black fill).
	-- Each dialog key keeps its frame, so this is done once per frame.
	local Kit = ns.Kit
	if Kit and ns.Controls(KEY) then
		for _, b in ipairs({ f.Button1, f.Button2 }) do
			if ns.Usable(b) then ns.Guard(Kit.Button, b) end
		end
		local eb = f.EditBox
		if ns.Usable(eb) then
			ns.Guard(Kit.Strip, eb)
			ns.Guard(Kit.EditBox, eb)
		end
	end
end

local Popup = Module("QuestiePopup")
if Popup and type(Popup.Show) == "function" then
	local origShow = Popup.Show
	Popup.Show = function(...)
		local f, b, c = origShow(...)
		if type(f) == "table" then
			local ok, err = pcall(Dialog, f)
			if not ok then geterrorhandler()(err) end
		end
		return f, b, c
	end
end

-- The once-only tutorial (which objective icons to use): its dark dialog border is a child frame
-- of the game's DialogBorderDarkTemplate; its three pictures stay.
ns.Watch(KEY, "QuestieTutorialChooseObjectiveType", function(frame)
	if not ns.Once(frame) then return end
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Frame" then child:SetAlpha(0) end
	end
	ns.Shell(frame, { window = true })
	for _, region in ipairs({ frame:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "FontString" and region:GetFontObject() == GameFontNormalLarge then
			Ink(region, "VALUE")
		end
	end
	ns.DressOnShow(frame)
end)

-- Made a little after login, only until a choice is made (Tutorial.CreateChooseObjectiveTypeFrame,
-- shown as it's made): looked for right after that call.
local Tutorial = Module("Tutorial")
if Tutorial and type(Tutorial.CreateChooseObjectiveTypeFrame) == "function" then
	ns.HookOnce(Tutorial, "CreateChooseObjectiveTypeFrame", function() ns.WatchNow() end, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- Its tracker (made a few frames after login as Questie starts up, only while Questie's tracker is
-- the one in use: TrackerBaseFrame.Initialize, followed below). Its backdrop color
-- is set again on every update and by its fader; each color asked for is turned into the opacity
-- of a holder carrying the shell, and the backdrop itself kept clear.
-- ---------------------------------------------------------------------------------------------

ns.Watch(KEY, "Questie_BaseFrame", function(base)
	if not ns.Once(base) or not base.SetBackdropColor then return end
	local holder = CreateFrame("Frame", nil, base)
	holder:SetAllPoints()
	holder:SetFrameLevel(math.max(0, base:GetFrameLevel() - 1))
	holder:EnableMouse(false)
	ns.Shell(holder, { window = true }, KEY)
	holder:SetAlpha(0)

	local busy = false
	local function Follow(alpha)
		local p = Profile()
		local full = p and type(p.trackerBackdropColor) == "table" and p.trackerBackdropColor.a or 1
		if type(alpha) ~= "number" or alpha <= 0 then
			holder:SetAlpha(0)
		else
			holder:SetAlpha(math.min(1, alpha / math.max(full or 1, 0.01)))
		end
	end
	hooksecurefunc(base, "SetBackdropColor", function(self, _, _, _, a)
		if busy or not ns.Enabled(KEY) then return end
		busy = true
		Follow(a)
		pcall(self.SetBackdropColor, self, 0, 0, 0, 0)
		busy = false
	end)
	hooksecurefunc(base, "SetBackdropBorderColor", function(self)
		if busy or not ns.Enabled(KEY) then return end
		busy = true
		pcall(self.SetBackdropBorderColor, self, 0, 0, 0, 0)
		busy = false
	end)
	-- What it has now.
	local p = Profile()
	if p and p.trackerBackdropEnabled and not p.trackerBackdropFader and type(p.trackerBackdropColor) == "table" then
		Follow(p.trackerBackdropColor.a)
	end
	busy = true
	pcall(base.SetBackdropColor, base, 0, 0, 0, 0)
	pcall(base.SetBackdropBorderColor, base, 0, 0, 0, 0)
	busy = false
end)

-- Looked for right after the tracker's frame is made, before Questie first colors or shows it.
local TrackerBase = Module("TrackerBaseFrame")
if TrackerBase and type(TrackerBase.Initialize) == "function" then
	ns.HookOnce(TrackerBase, "Initialize", function() ns.WatchNow() end, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- Its own late tooltips: the minimap waypoint tooltip (made on the first hover of an NPC's path on
-- the minimap) and the gamepad map tooltip (its own, so the gamepad UI isn't tainted). Both are
-- only filled with lines, which DaylightUI's tooltip skin doesn't wait for: given DaylightUI's
-- tooltip look here unless that skin already has, the game's border kept out of sight on each
-- show and the shell kept just under the tooltip.
-- ---------------------------------------------------------------------------------------------

local API = ns.API

-- (ns.TipLook, Core.lua: from Daylight UI 2.0 the border is the tooltips' own size or General's,
-- 2.0 DaylightUI_Tooltip\Tooltip.lua:61-64 and :144; before 2.0 the fixed 3 px, 1.9.6
-- Tooltip.lua:28. Gate: ns.DaylightAtLeast(2, 0), in ns.TipLook.)
local function TipLook()
	return ns.TipLook()
end

local function Settle(tip)
	if not ns.Enabled(KEY) or not ns.Usable(tip) then return end
	if ns.Usable(tip.NineSlice) then tip.NineSlice:SetAlpha(0) end
	local Kit = ns.Kit
	local s = Kit and Kit.ShellOf and Kit.ShellOf(tip)
	if type(s) == "table" and s.SetFrameLevel then
		s:SetFrameLevel(math.max(0, tip:GetFrameLevel() - 1))
	end
end

local tipped = setmetatable({}, { __mode = "k" })
local ownTips = setmetatable({}, { __mode = "k" })   -- tooltips whose shell this pack made
local function Tip(tip)
	if not ns.Usable(tip) or tipped[tip] or tip:GetObjectType() ~= "GameTooltip" then return end
	if not ns.Enabled(KEY) or not ns.ModuleOn("Tooltip") then return end
	tipped[tip] = true
	local Kit = ns.Kit
	if not (Kit and Kit.ShellOf and Kit.ShellOf(tip)) then
		ownTips[tip] = true
		ns.Guard(API.Skin, tip, TipLook())
	end
	ns.ScriptOnce(tip, "OnShow", Settle, KEY)
	Settle(tip)
end

ns.Watch(KEY, "QuestieWaypointMinimapTooltip", Tip)
ns.Watch(KEY, "QuestieGamepadMapTooltip", Tip)

-- Both are shown through MapIconTooltip.ShowOnTooltip (as GameTooltip is, for every map icon
-- hovered): a tooltip of its own shown there is looked for right after, before it's drawn. (The
-- gamepad one is made hidden a little after login and found then; the minimap one is made on the
-- first hover of a path, in that very call.)
local IconTooltip = Module("MapIconTooltip")
if IconTooltip and type(IconTooltip.ShowOnTooltip) == "function" then
	ns.HookOnce(IconTooltip, "ShowOnTooltip", function(_, tip)
		if tip and tip ~= GameTooltip and not tipped[tip] then ns.WatchNow() end
	end, KEY)
end

-- The tracker's quest tooltip (12.15, Tracker/TrackerQuestTooltip.lua: a GameTooltipTemplate
-- tooltip of its own, QuestieTrackerQuestTooltip, made on the first hover of a tracked quest's
-- title in a group). Filled by the game's party-progress call (which DaylightUI's tooltip skin
-- answers) or, for a quest only to share, by SetText and AddLine alone (which it doesn't wait
-- for): given the same look as the two above right after TrackerQuestTooltip.Show, the only call
-- that makes it, so it's dressed before it's drawn. Only made there, so never watched for.
local QuestTip = Module("TrackerQuestTooltip")
if QuestTip and type(QuestTip.Show) == "function" then
	ns.HookOnce(QuestTip, "Show", function()
		local tip = _G.QuestieTrackerQuestTooltip
		if tip and not tipped[tip] then Tip(tip) end
	end, KEY)
end

-- DaylightUI's tooltip opacity (from 2.0 its tooltip border size too) changed: the shells made
-- here follow.
ns.me.On("SettingChanged", function(scope, path)
	if not ns.TipLookChanged(scope, path) or not ns.Enabled(KEY) or next(ownTips) == nil then return end
	local look = TipLook()
	for tip in pairs(ownTips) do
		if ns.Usable(tip) then ns.Guard(API.Skin, tip, look) end
	end
end)

-- ---------------------------------------------------------------------------------------------
-- QuestieTrace (comes with Questie, its own addon; the data sharing that took over from the debug
-- offer): its consent question, a copy of the game's dialog (diamond border, dark ground, two
-- dialog-art buttons, made at load and shown once until answered), and its export window (made on
-- first open: flat color textures, two input boxes, two panel buttons). Both on the DaylightUI
-- shell; the consent alert icon and the export window's stat icons stay.
-- ---------------------------------------------------------------------------------------------

-- The consent frame is made as QuestieTrace loads, so it's found at login; its export window is
-- then looked for right as QuestieTraceCore.ShowExportWindow makes and shows it.
ns.Watch(KEY, "QuestieTraceConsentFrame", function(frame)
	local core = _G.QuestieTraceCore
	if type(core) == "table" then
		ns.HookOnce(core, "ShowExportWindow", function() ns.WatchNow() end, KEY)
	end
	if not ns.Once(frame) then return end
	ns.NoBackdrop(frame)
	ns.Kill(frame.Background)
	ns.Kill(frame.Border)
	ns.Shell(frame, { window = true }, KEY)
	local Kit = ns.Kit
	if Kit and ns.Controls(KEY) then
		for _, b in ipairs({ frame.AcceptButton, frame.DeclineButton }) do
			if ns.Usable(b) then ns.Guard(Kit.Button, b) end
		end
	end
	ns.DressOnShow(frame, nil, nil, KEY)
end)

ns.Watch(KEY, "QuestieTraceExportFrame", function(frame)
	if ns.Usable(frame) and not frame.daylightTrace then
		frame.daylightTrace = true
		for _, region in ipairs({ frame:GetRegions() }) do
			if ns.Usable(region) then
				local kind = region:GetObjectType()
				if kind == "Texture" then
					ns.Kill(region)
				elseif kind == "FontString" and region:GetFontObject() == GameFontNormal then
					Ink(region, "VALUE")   -- its title
				end
			end
		end
	end
	ns.PlainWindow(frame, nil, KEY)
end)

-- ---------------------------------------------------------------------------------------------
-- Its profiler (12.15, Modules/Profiler/QuestieProfilerUI.lua; a developer's tool, /questie
-- profiler): the window (QuestieProfilerFrame: the game's tooltip-bordered backdrop, a header and a
-- footer band, panel buttons, check boxes, a search box with its clear button, close buttons and
-- a size grip) and its "profiler running" tag at the top of the screen (QuestieProfilerIndicator:
-- a half-black fill under its words). Both are made by ProfilerUI's own calls, Create, Show and
-- Hide (the tag by Show and Hide): dressed right after each, before either is drawn. The window
-- takes DaylightUI's shell, its bands go (square fills over the shell's rounded corners), its
-- template controls are dressed and its gold title and captions take DaylightUI's inks; the tag
-- takes a small shell, its words the player's font in its own orange. Its rows, column heads,
-- bars and its own drawn scroll bar stay as it draws them.
-- ---------------------------------------------------------------------------------------------

local profiled = setmetatable({}, { __mode = "k" })

local function Gold(fs)
	local r, g, b = fs:GetTextColor()
	return type(r) == "number" and math.abs(r - 1) < 0.02 and math.abs(g - 0.82) < 0.02 and b < 0.03
end

-- Its gold words on the window and on its title bar (the frames, not the buttons: a button's
-- words follow its font objects, set again on every hover): the title in GameFontNormal, the
-- captions and chips in the small gold.
local function ProfilerInks(...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if ns.Usable(r) and r:GetObjectType() == "FontString" and Gold(r) then
			Ink(r, r:GetFontObject() == _G.GameFontNormal and "VALUE" or "LABEL")
		end
	end
end

local function BandsOff(...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if ns.Usable(r) and r:GetObjectType() == "Texture" and r:GetDrawLayer() == "BACKGROUND" then ns.Kill(r) end
	end
end

local function Profiler()
	if not ns.Kit then return end
	local f = _G.QuestieProfilerFrame
	if ns.Usable(f) and not profiled[f] then
		profiled[f] = true
		-- (Before the shell: its two bands are the window's only textures on that layer.)
		BandsOff(f:GetRegions())
		ProfilerInks(f:GetRegions())
		for _, child in ipairs({ f:GetChildren() }) do
			if ns.Usable(child) and child:GetObjectType() == "Frame" then ProfilerInks(child:GetRegions()) end
		end
		ns.PlainWindow(f, { closes = true, grips = true, fonts = true }, KEY)
	end
	local tag = _G.QuestieProfilerIndicator
	if ns.Usable(tag) and not profiled[tag] then
		profiled[tag] = true
		BandsOff(tag:GetRegions())
		ns.Shell(tag, nil, KEY)
		local label = tag.label
		if ns.Usable(label) and not ns.PlainText(KEY) then
			ns.FollowFont(label, KEY)
			-- (It sized itself to its words in the game's font: again in the player's.)
			local w, h = label:GetStringWidth(), label:GetStringHeight()
			if type(w) == "number" and w > 0 then tag:SetSize(w + 12, math.max(16, (h or 0) + 6)) end
		end
	end
end

local ProfilerUI = Module("ProfilerUI")
if ProfilerUI then
	for _, method in ipairs({ "Create", "Show", "Hide" }) do
		if type(ProfilerUI[method]) == "function" then ns.HookOnce(ProfilerUI, method, Profiler, KEY) end
	end
end

-- Loaded: the world map's corner buttons it adds (its Krowi button) lose the gold ring, the same
-- shared pass the OpenMap and RareScanner packs ask for, now asked for by this pack too.
-- (And the profiler's frames when they were made before this file ran: a profiled start makes and
-- shows them as Questie starts.)
ns.Pack(KEY, nil, function()
	if ns.Enabled(KEY) then
		ns.FollowMapRings(KEY)
		ns.Guard(Profiler)
	end
end)

-- ---------------------------------------------------------------------------------------------
-- Hand-over: nameplate icons
-- ---------------------------------------------------------------------------------------------

-- A setting by dotted path ("autoAccept.enabled").
local function GetPath(p, key)
	local t = p
	for part in string.gmatch(key, "[^.]+") do
		if type(t) ~= "table" then return nil end
		t = t[part]
	end
	return t
end
local function SetPath(p, key, value)
	local t = p
	local parts = {}
	for part in string.gmatch(key, "[^.]+") do parts[#parts + 1] = part end
	for i = 1, #parts - 1 do
		if type(t[parts[i]]) ~= "table" then t[parts[i]] = {} end
		t = t[parts[i]]
	end
	local last = parts[#parts]
	t[last] = value
end

local function QuestsOn() return ns.ModuleOn("Quests") end

ns.Handover(KEY, {
	ready = function() return Profile() ~= nil end,
	get = function(key) local p = Profile() return p and GetPath(p, key) end,
	set = function(key, value)
		local p = Profile()
		if not p then return end
		SetPath(p, key, value)
		if key == "nameplateEnabled" and not value then
			local plates = Module("QuestieNameplate")
			if plates and type(plates.HideCurrentFrames) == "function" then pcall(plates.HideCurrentFrames, plates) end
		end
	end,
	list = {
		{ key = "nameplateEnabled", label = L["Quest Icons Over Nameplates"],
		  daylight = L["quest marks on its nameplates"],
		  ours = function() return ns.DaylightHas("Nameplates", "quest") end },
		{ key = "enableTooltips", label = L["Quest Lines in Unit and Item Tooltips"],
		  daylight = L["the quest lines its Quests module paints in tooltips"],
		  ours = QuestsOn },
		{ key = "soundOnQuestComplete", label = L["Sound When a Quest Is Ready"],
		  daylight = ns.In(L["the tracker's chime"], "Quests"),
		  ours = function() return ns.DaylightHas("Quests", "sound") end },
		{ key = "autoAccept.enabled", label = L["Accept Quests Automatically"],
		  daylight = ns.In(L["auto accept"], "Quality of Life"),
		  ours = function() return ns.DaylightHas("QoL", "questAccept") end },
		{ key = "autocomplete", label = L["Turn in Quests Automatically"],
		  daylight = ns.In(L["auto turn in"], "Quality of Life"),
		  ours = function() return ns.DaylightHas("QoL", "questTurnIn") end },
		{ key = "minimapCoordinatesEnabled", label = L["Coordinates on the Minimap"],
		  daylight = L["the info panel's coordinates"],
		  ours = function() return ns.DaylightHas("InfoPanel", "map.coords.enabled") end },
	},
})
