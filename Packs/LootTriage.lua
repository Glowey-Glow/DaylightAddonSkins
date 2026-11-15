-- LootTriage: its one window is the unnamed "What's New" dialog, opened from its settings page.
-- DaylightUI's window shell, its Okay button, and its two page arrows at the top right (unnamed
-- buttons with the spellbook's page art: the right one turns to older notes, the one left of it to
-- newer) as DaylightUI's page buttons, grayed by the addon at either end as before.
-- Left as it is: the gold version and section headings and item names in the notes (color codes
-- in the text, readable on the dark shell, which DaylightUI's text lighting keeps as they are).
-- Bag marks, loot marks and tooltip lines are its display and are left alone.
local _, ns = ...
if not ns.ok then return end

local BORDER = "UI-DiamondDialogBox-Border"

local function HasAtlas(frame, atlas)
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == "Texture" then
			local ok, name = pcall(region.GetAtlas, region)
			if ok and name == atlas then return true end
		end
	end
	return false
end

-- The dialog is made the first time it opens, by its What's New button atop LootTriage's settings
-- pages (an unnamed button of the addon's, left of the game's Defaults button): a click on it
-- looks at once, so the dialog is dressed before it's drawn. Otherwise it's looked for only while
-- the game's Settings window is open, every fifth frame.
local beat = 0
local clicked = false
local function Find()
	local settings = _G.SettingsPanel
	if not settings or not settings:IsShown() then return end
	if clicked then
		clicked = false
	else
		beat = beat + 1
		if beat % 5 ~= 0 then return end
	end
	for _, child in ipairs({ UIParent:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Frame" and not child:GetName()
			and child:IsShown() and child:GetFrameStrata() == "DIALOG" and HasAtlas(child, BORDER) then
			return child
		end
	end
end

-- The addon's What's New button: an unnamed button of the addon's, on the game's Defaults button
-- (which is only read, and left as it is). Every such button there is hooked, in case another
-- addon puts one of its own in the same place.
local function NewsButtons()
	local list = _G.SettingsPanel and _G.SettingsPanel.Container and _G.SettingsPanel.Container.SettingsList
	local defaults = list and list.Header and list.Header.DefaultsButton
	local found = {}
	if not defaults then return found end
	for _, child in ipairs({ defaults:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" and not child:GetName()
			and child:GetText() == _G.GAMEMENU_NEW_BUTTON then
			local _, rel = child:GetPoint(1)
			if rel == defaults then found[#found + 1] = child end
		end
	end
	return found
end

local hooked = setmetatable({}, { __mode = "k" })
local function Clicked()
	clicked = true
	ns.WatchNow()
end

ns.Pack("LootTriage", "LootTriage", function()
	ns.Watch("LootTriage", function() return NewsButtons()[1] end, function()
		for _, button in ipairs(NewsButtons()) do
			if not hooked[button] then
				hooked[button] = true
				button:HookScript("OnClick", Clicked)
			end
		end
	end)
	ns.Watch("LootTriage", Find, function(dialog, Kit)
		if not ns.Once(dialog) then return end
		for _, region in ipairs({ dialog:GetRegions() }) do
			if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then ns.Kill(region) end
		end
		ns.Shell(dialog, { window = true })
		if not ns.Controls("LootTriage") then return end
		for _, child in ipairs({ dialog:GetChildren() }) do
			if ns.Usable(child) and child:GetObjectType() == "Button" then
				local text = child:GetText()
				if text and text ~= "" then
					if ns.Once(child) then ns.Guard(Kit.Button, child) end
				elseif ns.Once(child) then
					-- A page arrow: the one pinned to the dialog's top right shows older notes (a right
					-- arrow); the other sits left of it and shows newer ones.
					local point, rel = child:GetPoint(1)
					local older = point == "TOPRIGHT" and rel == dialog
					ns.Guard(Kit.PageButton, child, older and "right" or "left")
				end
			end
		end
	end)
end, { window = true, controls = true })
