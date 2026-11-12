-- Questie: what DaylightUI's own Questie support leaves as Questie draws it. DaylightUI already
-- dresses its AceGUI windows (My Journey, notes, the old options), puts its objective icons in
-- DaylightUI's art, keeps its tracker and NPC tooltip lines aside while DaylightUI's draw, skins its
-- tooltips and collects its minimap button: none of that is touched here, nor any Questie setting
-- DaylightUI's QuestieAside switches.
-- Dressed here: its current settings window (QuestieStandaloneSettings: shell, side tabs, the
-- controls on each tab), its right-click menus (LibUIDropDownMenu's lists: the tracker menu,
-- Townsfolk), its own popups (QuestiePopup, not the game's StaticPopup), the objective type
-- tutorial, and its own tracker while the player has picked Questie's over DaylightUI's (the shell
-- in place of its backdrop, following Questie's own backdrop switch, colour opacity and fader).
-- Left alone: its map and minimap icons, the tracker's lines and buttons (secure item buttons),
-- the world map button.
--
-- "Hand over to DaylightUI" (off until turned on on its page): Questie's quest icons on nameplates
-- step aside while DaylightUI's nameplates mark quest targets.
local _, ns = ...
if not ns.ok then return end

local KEY = "Questie"

ns.Target(KEY, "Questie", { window = true, controls = true, text = true, shadow = true, colors = true,
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

local API = ns.API

local function Accent() return ns.AccentOf(KEY) end

local function Ink(fs, role)
	if not ns.Usable(fs) or not fs.SetTextColor then return end
	if ns.Look(KEY, "daylightColors") == false then return end
	local c = API.Colors()[role]
	if type(c) == "table" then fs:SetTextColor(c[1], c[2], c[3]) end
end

-- Only the controls of its own settings window (the same controls also fill its pages in the
-- game's Settings window, which is the game's to dress).
local function InWindow(frame)
	for _ = 1, 16 do
		if not frame then return false end
		local name = frame.GetName and frame:GetName()
		if name and (string.find(name, "^QuestieOptionsTab_Popup_") or name == "QuestieStandaloneSettings") then return true end
		frame = frame.GetParent and frame:GetParent()
	end
	return false
end

local function Tint(tex, r, g, b)
	if ns.Usable(tex) then
		tex:SetDesaturated(true)
		tex:SetVertexColor(r, g, b)
	end
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
	end
	-- Template boxes and buttons among them (a text box and its OK button).
	ns.Dress(control, { checks = false, scrollBars = false }, 0, KEY)
end

local Controls = Module("QuestieOptionsControls")
if Controls and type(Controls.Create) == "function" then
	local origCreate = Controls.Create
	Controls.Create = function(parent, ...)
		local control = origCreate(parent, ...)
		if type(control) == "table" and ns.Enabled(KEY) and ns.Controls(KEY) and InWindow(parent) then
			ns.WithKit(function(Kit) DressControl(Kit, control) end)
		end
		return control
	end
	-- Its colours: gold names, white descriptions, set again on every refresh. DaylightUI's:
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
					if controls then ns.Guard(Kit.SideTab, child, child.Selected) end
				end
				local key = string.match(child:GetName() or "", "_Tab_(.+)$")
				local bar = key and _G["QuestieOptionsTab_Popup_" .. key .. "_ScrollScrollBar"]
				if controls and ns.Usable(bar) and ns.Once(bar) then ns.Guard(Kit.ScrollBar, bar) end
				-- The page's big gold title ("Questie • General Options").
				local canvas = key and _G["QuestieOptionsTab_Popup_" .. key]
				if ns.Usable(canvas) then
					for _, part in ipairs({ canvas:GetChildren() }) do
						for _, region in ipairs({ part:GetRegions() }) do
							if region:GetObjectType() == "FontString" and region:GetFontObject() == _G.GameFontNormalHuge then
								Ink(region, "VALUE")
							end
						end
					end
				end
			end
		end
	end
	ns.DressOnShow(frame, nil, tabs)
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and child.button and child.button.HookScript then
			child.button:HookScript("OnClick", function() C_Timer.After(0.05, function() ns.Guard(tabs) end) end)
		end
	end
end)

-- ---------------------------------------------------------------------------------------------
-- Right-click menus: L_DropDownListQuestie1..n. The library shows one of its two backdrops on every
-- open; both are kept at nothing and the shell is the menu's ground.
-- ---------------------------------------------------------------------------------------------

local function Menu(list)
	if not ns.Usable(list) or not ns.Once(list) then return end
	for _, part in ipairs({ list.Backdrop, list.MenuBackdrop }) do
		if ns.Usable(part) then part:SetAlpha(0) end
	end
	ns.Shell(list, nil, KEY)
end

ns.Watch(KEY, "L_DropDownListQuestie1", function()
	for i = 1, 8 do
		local list = _G["L_DropDownListQuestie" .. i]
		if not list then break end
		Menu(list)
	end
	-- Deeper levels are made when a menu first needs them.
	local lib = type(LibStub) == "table" and LibStub("LibUIDropDownMenuQuestie-4.0", true)
	if lib and type(lib.UIDropDownMenu_CreateFrames) == "function" then
		hooksecurefunc(lib, "UIDropDownMenu_CreateFrames", function()
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

-- ---------------------------------------------------------------------------------------------
-- Its tracker (made at login, only while Questie's tracker is the one in use). Its backdrop colour
-- is set again on every update and by its fader; each colour asked for is turned into the opacity
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
	hooksecurefunc(base, "SetBackdropColor", function(self, r, g, b, a)
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

ns.Pack(KEY)

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
	local t, last = p, nil
	local parts = {}
	for part in string.gmatch(key, "[^.]+") do parts[#parts + 1] = part end
	for i = 1, #parts - 1 do
		if type(t[parts[i]]) ~= "table" then t[parts[i]] = {} end
		t = t[parts[i]]
	end
	last = parts[#parts]
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
		{ key = "nameplateEnabled", label = "Quest icons over nameplates",
		  daylight = "quest marks on its nameplates",
		  ours = function() return ns.DaylightHas("Nameplates", "quest") end },
		{ key = "enableTooltips", label = "Quest lines in unit and item tooltips",
		  daylight = "the quest lines its Quests module paints in tooltips",
		  ours = QuestsOn },
		{ key = "soundOnQuestComplete", label = "Sound when a quest is ready",
		  daylight = "the tracker's chime (Quests)",
		  ours = function() return ns.DaylightHas("Quests", "sound") end },
		{ key = "autoAccept.enabled", label = "Accept quests automatically",
		  daylight = "auto accept (Quality of Life)",
		  ours = function() return ns.DaylightHas("QoL", "questAccept") end },
		{ key = "autocomplete", label = "Turn in quests automatically",
		  daylight = "auto turn in (Quality of Life)",
		  ours = function() return ns.DaylightHas("QoL", "questTurnIn") end },
		{ key = "minimapCoordinatesEnabled", label = "Coordinates on the minimap",
		  daylight = "the info panel's coordinates",
		  ours = function() return ns.DaylightHas("InfoPanel", "map.coords.enabled") end },
	},
})
