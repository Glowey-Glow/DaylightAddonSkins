-- Spoken: the welcome window, the contribute dialogs, Azeroth's Compendium, the two narrator
-- windows (Large and Small, the Small one's menu rows lit in the accent), the Places panel beside
-- the world map and its side tab, and its text buttons on the game's quest, gossip and book
-- windows (Listen / Stop, Contribute, Play). Left alone: subtitles (no window to dress), the
-- DialogueUI-style narrator (drawn in DialogueUI's art on purpose), the minimap button, the
-- Compendium's and the Places panel's parchment pages and list rows (dark ink on paper, redrawn on
-- every render), and the settings pages, which sit inside the game's own Settings window.
local _, ns = ...
if not ns.ok then return end

local KEY = "Spoken"

local function Env(name)
	local env = _G.SpokenEnv
	if type(env) ~= "table" then return nil end
	local value = rawget(env, name)
	return type(value) == "table" and value or nil
end

local function Templated(frame, Kit)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	ns.Guard(Kit.Window, frame)
	if ns.Controls(KEY) then ns.Guard(Kit.Auto, frame, { rows = false }) end
end

-- Large Window: its box art is drawn again on every refresh, but only the texture, never the alpha.
local function Large()
	local player = Env("PlayerFrame")
	local frame = player and player.frame
	if not ns.Usable(frame) or not ns.Enabled(KEY) then return end
	if ns.Usable(frame.background) then frame.background:SetAlpha(0) end
	if ns.Once(frame) then ns.Shell(frame, { window = true }, KEY) end
end

-- Small Window: dressed on its dark background only. On parchment its words are dark ink, so the
-- paper stays and only the border is DaylightUI's.
local function Small()
	local mini = Env("MinimalPlayer")
	local panel = mini and mini.panel
	if not ns.Usable(panel) or not ns.Enabled(KEY) then return end
	local addon = Env("Addon")
	local frameSettings = addon and addon.db and addon.db.profile and addon.db.profile.Frame
	local dark = type(frameSettings) == "table" and frameSettings.MinimalBackground == "dark"
	if ns.Once(panel) then
		ns.NoBackdrop(panel)
		ns.Shell(panel, { window = true }, KEY)
	end
	if ns.Usable(mini.paper) then mini.paper:SetAlpha(dark and 0 or 1) end
	local menu = mini.menu
	if ns.Usable(menu) and ns.Once(menu) then
		ns.NoBackdrop(menu)
		ns.Shell(menu, nil, KEY)
	end
end

-- The Small Window's menu: its rows (made as the menu opens) gold, lit in yellow; DaylightUI's text
-- color, lit in the accent. Painted on every open, so a change of the accent shows the next time.
local function MenuRows(mini)
	local menu = mini and mini.menu
	if not ns.Usable(menu) or not ns.Enabled(KEY) then return end
	local c = ns.Colors().VALUE
	for _, row in ipairs({ menu:GetChildren() }) do
		if ns.Usable(row.text) and row.GetHighlightTexture then
			local hl = row:GetHighlightTexture()
			if ns.Usable(hl) then
				hl:SetAlpha(1)
				ns.FillAccent(hl, 0.2, nil, KEY)
			end
			if type(c) == "table" then row.text:SetTextColor(c[1], c[2], c[3]) end
		end
	end
end

-- The Places panel beside the world map: the game's flat panel (or, on a client without it, a
-- dialog box) on DaylightUI's shell, its quest-log rim round the page hidden; the page is
-- parchment and stays. It shows and hides with the map, so no fade and no closing ghost.
local function PlacesPanel(frame, Kit)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	if frame.templated then
		if type(Kit.GHOST) == "table" then Kit.GHOST[frame:GetName() or ""] = true end
		ns.Guard(Kit.Window, frame, { ownFade = true })
	else
		ns.NoBackdrop(frame)
		ns.Shell(frame, { window = true }, KEY)
	end
	if ns.Usable(frame.rim) then frame.rim:SetAlpha(0) end
	if ns.Controls(KEY) and ns.Usable(frame.close) and ns.Once(frame.close) then ns.Guard(Kit.Close, frame.close) end
end

-- Its side tab on the map's edge (the game's large side tab): a tile; it only ever opens, so it is
-- never shown picked. (The round button of a client without that template is left as it is.)
local function NeverPicked() return false end
local function PlacesToggle(tab, Kit)
	if not ns.Usable(tab) or not ns.Controls(KEY) or not ns.Usable(tab.Icon) or not ns.Once(tab) then return end
	for _, k in ipairs({ "Background", "Border", "SelectedTexture" }) do
		if ns.Usable(tab[k]) then Kit.Hide(tab[k]) end
	end
	for _, k in ipairs({ "HighlightTexture", "TabGlow" }) do
		if ns.Usable(tab[k]) then Kit.Erase(tab[k]) end
	end
	if tab.GetHighlightTexture and ns.Usable(tab:GetHighlightTexture()) then Kit.Hide(tab:GetHighlightTexture()) end
	if not ns.SideTile(tab, { picked = NeverPicked, key = KEY, pad = 2 }) then return end
	-- (The game fits its icon again on SetChecked: the tile's crop back after it.)
	if type(tab.SetChecked) == "function" then
		hooksecurefunc(tab, "SetChecked", function(self)
			if ns.Usable(self.Icon) then self.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
			ns.SideTilePaint(self)
		end)
	end
end

-- Its red text buttons: Listen / Stop and Contribute (Spoken_Quests, on the game's quest and gossip
-- windows, made once as it starts) and Play on the book window (Spoken_Readables).
local function TextButton(button, Kit)
	if ns.Usable(button) and ns.Controls(KEY) then ns.Guard(Kit.Button, button) end
end

local function QuestsButton(name)
	return function()
		local vo = _G.VoiceOver
		local part = type(vo) == "table" and rawget(vo, name)
		return type(part) == "table" and part.button or nil
	end
end

local function BookButton()
	local readables = _G.SpokenReadables
	return type(readables) == "table" and readables.playButton or nil
end

ns.Pack("Spoken", "Spoken", function(Kit)
	local player, mini = Env("PlayerFrame"), Env("MinimalPlayer")
	if not player then return false end

	if type(player.RefreshConfig) == "function" then
		hooksecurefunc(player, "RefreshConfig", function() ns.Guard(Large) end)
	end
	if mini and type(mini.RefreshConfig) == "function" then
		hooksecurefunc(mini, "RefreshConfig", function() ns.Guard(Small) end)
	end
	if mini and type(mini.ToggleMenu) == "function" then
		hooksecurefunc(mini, "ToggleMenu", function(self) ns.Guard(MenuRows, self) end)
	end
	ns.Watch(KEY, "SpokenPlayerFrame", function() Large() end)
	ns.Watch(KEY, "SpokenMinimalPlayerFrame", function() Small() end)

	ns.Watch(KEY, "SpokenWelcomeFrame", Templated)
	ns.Watch(KEY, "SpokenContributeBox", function(frame) ns.PlainWindow(frame) end)
	ns.Watch(KEY, "SpokenGatheredLines", function(frame) ns.PlainWindow(frame) end)
	ns.Watch(KEY, "SpokenMinimapMenu", function(frame) ns.PlainWindow(frame) end)

	ns.Watch(KEY, "SpokenPlacesPanel", PlacesPanel)
	ns.Watch(KEY, "SpokenPlacesPanelToggle", PlacesToggle)
	ns.Watch(KEY, QuestsButton("DialogPlayButton"), TextButton)
	ns.Watch(KEY, QuestsButton("ContributeButton"), TextButton)
	ns.Watch(KEY, BookButton, TextButton)

	ns.Watch(KEY, "SpokenCompendiumWindow", function(frame)
		if not ns.Usable(frame) or not ns.Once(frame) then return end
		if frame.templated then
			ns.Guard(Kit.Window, frame)
		else
			ns.NoBackdrop(frame)
			ns.Shell(frame, { window = true }, KEY)
			if ns.Usable(frame.CloseButton) and ns.Controls(KEY) and ns.Once(frame.CloseButton) then ns.Guard(Kit.Close, frame.CloseButton) end
		end
		-- Tabs and each part's list (search box, inset, filter) are made as parts are opened.
		local function parts()
			for i = 1, 12 do
				local tab = _G["SpokenCompendiumWindowTab" .. i]
				if not tab then break end
				if ns.Controls(KEY) and ns.Once(tab) then ns.Guard(Kit.Tab, tab) end
			end
			if ns.Controls(KEY) then ns.Guard(Kit.Auto, frame, { rows = false, shownOnly = true }) end
		end
		local queued
		local function later()
			if queued then return end
			queued = true
			C_Timer.After(0.05, function() queued = nil if frame:IsShown() then parts() end end)
		end
		frame:HookScript("OnShow", later)
		local compendium = _G.SpokenCompendium
		if type(compendium) == "table" and type(compendium.Select) == "function" then
			hooksecurefunc(compendium, "Select", later)
		end
		parts()
		later()
	end)
end, { window = true, controls = true, text = true, shadow = true })
