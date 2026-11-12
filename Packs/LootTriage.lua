-- LootTriage: its one window is the unnamed "What's New" dialog, opened from its settings page.
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

-- Looked for only while the game's Settings window is open, twice a second.
local beat = 0
local function Find()
	local settings = _G.SettingsPanel
	if not settings or not settings:IsShown() then return end
	beat = beat + 1
	if beat % 5 ~= 0 then return end
	for _, child in ipairs({ UIParent:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Frame" and not child:GetName()
			and child:IsShown() and child:GetFrameStrata() == "DIALOG" and HasAtlas(child, BORDER) then
			return child
		end
	end
end

ns.Pack("LootTriage", "LootTriage", function()
	ns.Watch("LootTriage", Find, function(dialog, Kit)
		if not ns.Once(dialog) then return end
		for _, region in ipairs({ dialog:GetRegions() }) do
			if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then ns.Kill(region) end
		end
		ns.Shell(dialog, { window = true })
		for _, child in ipairs({ dialog:GetChildren() }) do
			if ns.Usable(child) and child:GetObjectType() == "Button" then
				local text = child:GetText()
				if text and text ~= "" and ns.Controls("LootTriage") and ns.Once(child) then ns.Guard(Kit.Button, child) end
			end
		end
	end)
end, { window = true, controls = true })
