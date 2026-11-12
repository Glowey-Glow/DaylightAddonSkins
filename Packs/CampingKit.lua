-- Camping Kit: the "This campfire" panel and the shared Kits menu. The kit itself (tent, slots,
-- flyouts, dials, dock) is a secure action HUD and is left exactly as it is.
local _, ns = ...
if not ns.ok then return end

-- The panel's ground is one of three things, by what the client has: a menu-style child frame one
-- level under the panel, a dropdown atlas texture, or a backdrop on the panel itself.
local function ClearGround(panel)
	local level = panel:GetFrameLevel()
	for _, child in ipairs({ panel:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Frame" and child:GetFrameLevel() < level
			and not child:IsMouseEnabled() and child:GetNumRegions() > 0 then
			ns.Kill(child)
		end
	end
	for _, region in ipairs({ panel:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			local ok, atlas = pcall(region.GetAtlas, region)
			if ok and atlas == "common-dropdown-bg" then ns.Kill(region) end
		end
	end
end

ns.Pack("CampingKit", "Camping Kit", function()
	ns.Watch("CampingKit", "CampingKitCampPanel", function(panel)
		ClearGround(panel)
		ns.PlainWindow(panel)
	end)
	ns.Watch("CampingKit", "KitDockMenu", function(menu)
		ns.PlainWindow(menu)
	end)
end, { window = true, controls = true, text = true, shadow = true })
