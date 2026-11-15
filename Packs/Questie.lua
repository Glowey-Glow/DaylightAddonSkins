-- Questie: what DaylightUI's own Questie support leaves as Questie draws it. DaylightUI already
-- dresses its AceGUI windows (My Journey, notes, the old options), puts its objective icons in
-- DaylightUI's art, keeps its tracker and NPC tooltip lines aside while DaylightUI's draw, skins its
-- tooltips and collects its minimap button: none of that is touched here, nor any Questie setting
-- DaylightUI's QuestieAside switches.
-- Dressed here: its current settings window (QuestieStandaloneSettings: shell, side tabs with
-- DaylightUI's hover wash and the accent outline following each click, the controls on each tab
-- including the play-sound buttons, the color swatches and the gold rules, each tab's scroll bar
-- even when its canvas is built over several frames), its right-click menus (LibUIDropDownMenu's
-- lists: the tracker menu, Townsfolk; their rows' hover, radio and check marks, expand arrows and
-- color swatches), its own popups (QuestiePopup, not the game's StaticPopup: shell, buttons, edit
-- box), the objective type tutorial, its late tooltips (the minimap waypoint and gamepad map
-- tooltips), the debug offer window, the gold ring on its world map corner button (the shared
-- ns.MapRings pass), and its own tracker while the player has picked Questie's over DaylightUI's
-- (the shell in place of its backdrop, following Questie's own backdrop switch, color opacity and
-- fader). Its pages in the game's Settings window (Esc > Options > AddOns > Questie and each page
-- under it) get the same treatment as that window's tabs: the same controls, inks, rules, title
-- and scroll bar, caught as each page is built over its first few frames.
-- Left alone: its map and minimap icons, the tracker's lines and buttons (secure item buttons),
-- the menu trace entry's own red and green mark colors, the debug offer's inline gold title.
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
	if fs:GetWordWrap() then return end
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

-- One canvas's own pieces, in either window: its scroll bar (<canvas>_ScrollScrollBar), the big
-- gold title ("Questie • Icon Options") and the gold rule under its header. All are made before
-- its first control, so they are there by the pass after it.
local function CanvasChrome(Kit, canvas, controls)
	if not ns.Usable(canvas) then return end
	local name = canvas:GetName()
	local bar = name and _G[name .. "_ScrollScrollBar"]
	if controls and ns.Usable(bar) and ns.Once(bar) then ns.Guard(Kit.ScrollBar, bar) end
	local content = canvas.content
	if not ns.Usable(content) then return end
	Hairlines(content:GetRegions())
	for _, region in ipairs({ content:GetRegions() }) do
		if region:GetObjectType() == "FontString" then
			if region:GetFontObject() == _G.GameFontNormalHuge then Ink(region, "VALUE") end
			ns.FollowFont(region, KEY)
		end
	end
end

-- Its pages in the game's Settings window: each is built, a few rows a frame, the first time it is
-- shown. Each page a control was just made on is looked over once on the next frame (only its own
-- frames: nothing of the Settings panel's is hooked).
local blizzPending = {}    -- canvas -> true, until the next frame's pass
local blizzQueued = false
local function BlizzPass()
	blizzQueued = false
	local Kit = ns.Kit
	if not Kit or not ns.Enabled(KEY) then wipe(blizzPending) return end
	local controls = ns.Controls(KEY)
	for canvas in pairs(blizzPending) do
		blizzPending[canvas] = nil
		ns.Guard(CanvasChrome, Kit, canvas, controls)
	end
end
local function QueueBlizz(canvas)
	blizzPending[canvas] = true
	if blizzQueued then return end
	blizzQueued = true
	C_Timer.After(0, BlizzPass)
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
		hooksecurefunc(Controls, "Refresh", function(control)
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
		end)
	end
end

ns.Watch(KEY, "QuestieStandaloneSettings", function(frame, Kit)
	if not ns.Once(frame) then return end
	ns.Guard(Kit.Window, frame)
	local controls = ns.Controls(KEY)
	-- Side tabs, and each tab's scroll bar (QuestieOptionsTab_Popup_<tab>_ScrollScrollBar).
	local function tabs()
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
							hooksecurefunc(child.Selected, "SetShown", ns.SideTilesPaintSoon)
						end
					end
				end
				-- The tab's canvas: its scroll bar, big gold title and the gold rule under its header.
				local key = string.match(child:GetName() or "", "_Tab_(.+)$")
				local canvas = key and _G["QuestieOptionsTab_Popup_" .. key]
				if canvas then CanvasChrome(Kit, canvas, controls) end
			end
		end
	end
	-- (fonts: its title, tab names and page words, followed on every show.)
	ns.DressOnShow(frame, { fonts = true }, tabs)
	local queued = false
	local function Run()
		queued = false
		if frame:IsShown() then ns.Guard(tabs) end
	end
	QueueTabs = function()
		if queued then return end
		queued = true
		C_Timer.After(0, Run)
	end
	-- A click on a tab: the picked tile moves (repainted on the click of the button inside it), and the tab's canvas, built on its first showing, is looked
	-- over as it arrives.
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and child.button and child.button.HookScript then
			child.button:HookScript("OnClick", function()
				if not ns.Enabled(KEY) then return end
				if controls then ns.SideTilesPaintSoon() end
				QueueTabs()
			end)
		end
	end
end)

-- The window is made on its first opening (ShowFrame, through every way it opens: the minimap
-- button, the tracker, the slash command, the menu): looked for right after that call, once its
-- tabs are made and before it's drawn.
local OptionsEngine = Module("QuestieOptionsEngine")
if OptionsEngine and type(OptionsEngine.ShowFrame) == "function" then
	hooksecurefunc(OptionsEngine, "ShowFrame", function() ns.WatchNow() end)
end

-- ---------------------------------------------------------------------------------------------
-- Right-click menus: L_DropDownListQuestie1..n. The library shows one of its two backdrops on every
-- open; both are kept at nothing and the shell is the menu's ground. The first three are made as
-- the library loads, so they are there at login; the rest follow the library's CreateFrames.
-- ---------------------------------------------------------------------------------------------

-- Its rows: the quest-title hover bar becomes a faint white wash (the library only shows and hides
-- it); the gold radio and check marks are made gray (desaturated) and tinted, the ticked one in the
-- accent and the empty one gray. On every fill the library sets the marks' texture, desaturation
-- and color (white) again, so those two setters are followed on each mark: a white the library
-- asks for is turned into ours, any other color (the trace entry's red and green) is kept.
-- The expand arrow gray, the color swatch's gold hover ring white.
local marks = setmetatable({}, { __mode = "k" })   -- mark texture -> true for the tick, false for the empty one
local painting = false

local function MarkColor(tex)
	if marks[tex] then return Accent() end
	return 0.55, 0.55, 0.55
end

local function PaintMark(tex)
	painting = true
	tex:SetDesaturated(true)
	tex:SetVertexColor(MarkColor(tex))
	painting = false
end

local function OnMarkDesaturated(tex, on)
	if painting or on or not ns.Enabled(KEY) then return end
	painting = true
	tex:SetDesaturated(true)
	painting = false
end

local function OnMarkColor(tex, r, g, b)
	if painting or not ns.Enabled(KEY) then return end
	if r == 1 and g == 1 and b == 1 then
		painting = true
		tex:SetVertexColor(MarkColor(tex))
		painting = false
	end
end

local function Mark(tex, ticked)
	if not ns.Usable(tex) or marks[tex] ~= nil then return end
	marks[tex] = ticked
	PaintMark(tex)
	hooksecurefunc(tex, "SetDesaturated", OnMarkDesaturated)
	hooksecurefunc(tex, "SetVertexColor", OnMarkColor)
end

local function SwatchEnter(self)
	if not ns.Enabled(KEY) then return end
	local bg = self.SwatchBg or _G[(self:GetName() or "") .. "SwatchBg"]
	if ns.Usable(bg) then bg:SetVertexColor(1, 1, 1) end
end

local function MenuButton(btn)
	if not ns.Usable(btn) or not ns.Once(btn) then return end
	local hl = btn.Highlight
	if ns.Usable(hl) then
		hl:SetTexture(nil)
		hl:SetColorTexture(1, 1, 1, 0.08)
		hl:SetBlendMode("BLEND")
	end
	Mark(btn.Check, true)
	Mark(btn.UnCheck, false)
	local arrow = btn.ExpandArrow
	local tex = ns.Usable(arrow) and arrow.GetNormalTexture and arrow:GetNormalTexture()
	if ns.Usable(tex) then
		tex:SetDesaturated(true)
		local c = ns.Colors().LABEL
		if type(c) == "table" then tex:SetVertexColor(c[1], c[2], c[3]) else tex:SetVertexColor(0.7, 0.7, 0.7) end
	end
	local swatch = btn.ColorSwatch
	if ns.Usable(swatch) and swatch.HookScript then swatch:HookScript("OnEnter", SwatchEnter) end
end

-- The accent changed: the ticks follow.
local function Repaint()
	for tex in pairs(marks) do
		if ns.Usable(tex) then PaintMark(tex) end
	end
end
local repaintQueued = false
local function QueueRepaint()
	if repaintQueued or next(marks) == nil then return end
	repaintQueued = true
	C_Timer.After(0, function()
		repaintQueued = false
		if ns.Enabled(KEY) then ns.Guard(Repaint) end
	end)
end
ns.me.On("StyleChanged", QueueRepaint)
ns.me.On("SettingChanged", function(scope, path)
	if scope ~= "DaylightAddonSkins" or type(path) ~= "string" then return end
	if path == "followDaylight" or string.sub(path, 1, 12) == "look.Questie" then QueueRepaint() end
end)

-- Its rows, as many as the list has made (more are made as a longer menu needs them).
local function MenuRows(list)
	local name = list:GetName()
	if not name then return end
	for j = 1, 64 do
		local btn = _G[name .. "Button" .. j]
		if not btn then break end
		MenuButton(btn)
	end
end

-- Its rows' words (GameFontHighlightSmallLeft, set again on every fill) in the player's font once
-- the list is shown (the library fills it first and sizes it in its own OnShow, which runs before
-- this one); the list wider when a row no longer fits, as the library works out a row's width.
local function MenuFonts(list)
	if not ns.Enabled(KEY) or ns.PlainText(KEY) then return end
	local name = list:GetName()
	local count = list.numButtons
	if not name or type(count) ~= "number" then return end
	local lib = type(LibStub) == "table" and LibStub("LibUIDropDownMenuQuestie-4.0", true)
	local widest = 0
	for j = 1, count do
		local btn = _G[name .. "Button" .. j]
		if not btn then break end
		ns.FollowFont(_G[name .. "Button" .. j .. "NormalText"], KEY)
		if lib and type(lib.UIDropDownMenu_GetButtonWidth) == "function" then
			local ok, w = pcall(lib.UIDropDownMenu_GetButtonWidth, lib, btn)
			if ok and type(w) == "number" and w > widest then widest = w end
		end
	end
	if list.noResize or type(list.maxWidth) ~= "number" or widest <= list.maxWidth then return end
	for j = 1, count do
		local btn = _G[name .. "Button" .. j]
		if btn then btn:SetWidth(widest) end
	end
	list:SetWidth(widest + 25)
end

local function Menu(list)
	if not ns.Usable(list) then return end
	if ns.Once(list) then
		for _, part in ipairs({ list.Backdrop, list.MenuBackdrop }) do
			if ns.Usable(part) then part:SetAlpha(0) end
		end
		ns.Shell(list, nil, KEY)
		list:HookScript("OnShow", MenuFonts)
		if list:IsShown() then MenuFonts(list) end
	end
	if ns.Controls(KEY) then MenuRows(list) end
end

ns.Watch(KEY, "L_DropDownListQuestie1", function()
	for i = 1, 8 do
		local list = _G["L_DropDownListQuestie" .. i]
		if not list then break end
		Menu(list)
	end
	-- Deeper levels and more rows are made when a menu first needs them. (The library asks for
	-- them on every row it adds: only a change in how many it has is looked over.)
	local lib = type(LibStub) == "table" and LibStub("LibUIDropDownMenuQuestie-4.0", true)
	if lib and type(lib.UIDropDownMenu_CreateFrames) == "function" then
		local levels, buttons
		hooksecurefunc(lib, "UIDropDownMenu_CreateFrames", function()
			if not ns.Enabled(KEY) then return end
			local l, b = _G.L_UIDROPDOWNMENUQUESTIE_MAXLEVELS, _G.L_UIDROPDOWNMENUQUESTIE_MAXBUTTONS
			if l ~= nil and l == levels and b == buttons then return end
			levels, buttons = l, b
			for i = 1, 16 do
				local list = _G["L_DropDownListQuestie" .. i]
				if not list then break end
				ns.Guard(Menu, list)
			end
		end)
	end
end)

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
	hooksecurefunc(Tutorial, "CreateChooseObjectiveTypeFrame", function() ns.WatchNow() end)
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
	hooksecurefunc(TrackerBase, "Initialize", function() ns.WatchNow() end)
end

-- ---------------------------------------------------------------------------------------------
-- Its own late tooltips: the minimap waypoint tooltip (made on the first hover of an NPC's path on
-- the minimap) and the gamepad map tooltip (its own, so the gamepad UI isn't tainted). Both are
-- only filled with lines, which DaylightUI's tooltip skin doesn't wait for: given DaylightUI's
-- tooltip look here unless that skin already has, the game's border kept out of sight on each
-- show and the shell kept just under the tooltip.
-- ---------------------------------------------------------------------------------------------

local API = ns.API

local function TipLook()
	local look = { borderPx = 3, flat = true, noBevel = true }
	local ok, alpha = pcall(API.GetSetting, "Tooltip", "bgAlpha")
	if ok and type(alpha) == "number" then look.bgAlpha = alpha end
	return look
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
	tip:HookScript("OnShow", Settle)
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
	hooksecurefunc(IconTooltip, "ShowOnTooltip", function(_, tip)
		if tip and tip ~= GameTooltip and not tipped[tip] then ns.WatchNow() end
	end)
end

-- DaylightUI's tooltip opacity changed: the shells made here follow.
ns.me.On("SettingChanged", function(scope, path)
	if scope ~= "Tooltip" or path ~= "bgAlpha" or not ns.Enabled(KEY) or next(ownTips) == nil then return end
	local look = TipLook()
	for tip in pairs(ownTips) do
		if ns.Usable(tip) then ns.Guard(API.Skin, tip, look) end
	end
end)

-- ---------------------------------------------------------------------------------------------
-- The debug offer (only with its advanced debug option on): a chat link opens a small window with
-- the game's dialog backdrop, a panel button and an input box. Each offer makes a new frame under
-- the same name, so each one is dressed as its link opens it.
-- ---------------------------------------------------------------------------------------------

local DebugOffer = Module("QuestieDebugOffer")
if DebugOffer and type(DebugOffer.ShowOffer) == "function" then
	hooksecurefunc(DebugOffer, "ShowOffer", function()
		if not ns.Enabled(KEY) then return end
		local frame = _G.QuestieDebugOfferFrame
		if ns.Usable(frame) and ns.Kit then ns.Guard(ns.PlainWindow, frame, nil, KEY) end
	end)
end

-- Loaded: the world map's corner buttons it adds (its Krowi button) lose the gold ring, the same
-- shared pass the OpenMap and RareScanner packs ask for, now asked for by this pack too.
ns.Pack(KEY, nil, function()
	if ns.Enabled(KEY) then ns.FollowMapRings(KEY) end
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
		{ key = "nameplateEnabled", label = L["Quest icons over nameplates"],
		  daylight = L["quest marks on its nameplates"],
		  ours = function() return ns.DaylightHas("Nameplates", "quest") end },
		{ key = "enableTooltips", label = L["Quest lines in unit and item tooltips"],
		  daylight = L["the quest lines its Quests module paints in tooltips"],
		  ours = QuestsOn },
		{ key = "soundOnQuestComplete", label = L["Sound when a quest is ready"],
		  daylight = ns.In(L["the tracker's chime"], "Quests"),
		  ours = function() return ns.DaylightHas("Quests", "sound") end },
		{ key = "autoAccept.enabled", label = L["Accept quests automatically"],
		  daylight = ns.In(L["auto accept"], "Quality of Life"),
		  ours = function() return ns.DaylightHas("QoL", "questAccept") end },
		{ key = "autocomplete", label = L["Turn in quests automatically"],
		  daylight = ns.In(L["auto turn in"], "Quality of Life"),
		  ours = function() return ns.DaylightHas("QoL", "questTurnIn") end },
		{ key = "minimapCoordinatesEnabled", label = L["Coordinates on the minimap"],
		  daylight = L["the info panel's coordinates"],
		  ours = function() return ns.DaylightHas("InfoPanel", "map.coords.enabled") end },
	},
})
