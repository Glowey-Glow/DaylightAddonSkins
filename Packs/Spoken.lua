-- Spoken: the welcome window, the contribute dialogs, Azeroth's Compendium, and the two narrator
-- windows (Large and Small). Left alone: subtitles (no window to dress), the DialogueUI-style
-- narrator (drawn in DialogueUI's art on purpose), the minimap button, the Compendium's parchment
-- pages and list rows (dark ink on paper, redrawn on every render), and the settings pages, which
-- sit inside the game's own Settings window.
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

ns.Pack("Spoken", "Spoken", function(Kit)
	local player, mini = Env("PlayerFrame"), Env("MinimalPlayer")
	if not player then return false end

	if type(player.RefreshConfig) == "function" then
		hooksecurefunc(player, "RefreshConfig", function() ns.Guard(Large) end)
	end
	if mini and type(mini.RefreshConfig) == "function" then
		hooksecurefunc(mini, "RefreshConfig", function() ns.Guard(Small) end)
	end
	ns.Watch(KEY, "SpokenPlayerFrame", function() Large() end)
	ns.Watch(KEY, "SpokenMinimalPlayerFrame", function() Small() end)

	ns.Watch(KEY, "SpokenWelcomeFrame", Templated)
	ns.Watch(KEY, "SpokenContributeBox", function(frame) ns.PlainWindow(frame) end)
	ns.Watch(KEY, "SpokenGatheredLines", function(frame) ns.PlainWindow(frame) end)
	ns.Watch(KEY, "SpokenMinimapMenu", function(frame) ns.PlainWindow(frame) end)

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
