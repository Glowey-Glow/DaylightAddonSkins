-- Forever Fishing: the shells of its windows (Journal, Settings, Session Goals, the report
-- window, the catch recap) and its text in the player's font.
-- Left alone: the Journal's parchment page and everything on it (dark ink on paper, rebuilt on
-- every render), the inside of the Settings window (every control is its own drawing with its own
-- state colors), the fishing bar, tool bar, flyouts, cast bar and key capture (secure / HUD).
-- The Journal, Settings and Session Goals roots are protected frames: they are dressed out of
-- combat only, and never moved, sized, shown or hidden from here.
local _, ns = ...
if not ns.ok then return end

ns.Target("ForeverFishing", "Forever Fishing", { window = true, controls = true, text = true, shadow = true, font = "daylight" })

local FF = _G.ForeverFishing
if type(FF) ~= "table" then return end

local KEY = "ForeverFishing"

-- Its one font choke point: every Journal and Settings string is set through it, again and again.
if type(FF.SetDisplayFont) == "function" then
	local orig = FF.SetDisplayFont
	-- font -> the face and size the addon gave it, and the size put on it here. A string still at
	-- that size was left alone by the addon this time, and is sized from what the addon gave it.
	local seen = setmetatable({}, { __mode = "k" })
	local function Restyle(font)
		local own, now, flags = font:GetFont()
		if not now or now <= 0 then return end
		local s = seen[font]
		if not s then
			s = {}
			seen[font] = s
		end
		if s.ours ~= now then s.own, s.base = own, now end
		ns.SetFont(KEY, font, s.own, s.base, flags)
		local _, after = font:GetFont()
		s.ours = after
	end
	FF.SetDisplayFont = function(self, font, path, size, flags)
		local out = orig(self, font, path, size, flags)
		if type(font) == "table" and font.SetFont and font.GetFont and ns.Enabled(KEY) and not ns.PlainText(KEY) then
			pcall(Restyle, font)
		end
		return out
	end
end

-- Faded, not hidden: the Journal shows its art again each time it switches between its two sizes.
local function Fade(region)
	if ns.Usable(region) and region.SetAlpha then region:SetAlpha(0) end
end

local function KillGround(frame)
	for _, region in ipairs({ frame:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			region:SetAlpha(0)
		end
	end
end

-- The unnamed gold border: a backdrop child with no mouse.
local function KillBackdropChildren(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Frame" and child.GetBackdrop and child:GetBackdrop()
			and not child:IsMouseEnabled() then
			child:SetAlpha(0)
		end
	end
end

local function Close(Kit, button)
	if ns.Usable(button) and ns.Controls(KEY) and ns.Once(button) then ns.Guard(Kit.Close, button) end
end

local function Journal(panel, Kit)
	ns.OutOfCombat(function()
		if not ns.Once(panel) then return end
		Fade(panel.windowFill)
		Fade(panel.outerBorder)
		Fade(panel.fullHeaderFill)
		Fade(panel.navFill)
		Fade(panel.headerDivider)
		Fade(panel.navDivider)
		ns.Shell(panel, { window = true }, KEY)
		Close(Kit, panel.fullCloseButton)
		Close(Kit, panel.compactCloseButton)
		local skip = {}
		if type(panel.page) == "table" then skip[panel.page] = true end
		if type(panel.nav) == "table" then skip[panel.nav] = true end
		if type(panel.backButton) == "table" then skip[panel.backButton] = true end
		ns.DressOnShow(panel, { skip = skip, checks = false }, nil, KEY)
	end)
end

local function Goals(panel, Kit)
	ns.OutOfCombat(function()
		if not ns.Once(panel) then return end
		KillGround(panel)
		Fade(panel.border)
		ns.Shell(panel, { window = true }, KEY)
		Close(Kit, panel.close)
		ns.DressOnShow(panel, { checks = false }, nil, KEY)
	end)
end

local function Settings(panel)
	ns.OutOfCombat(function()
		if not ns.Once(panel) then return end
		-- The outer frame only: the full-size ground and the three border rings round it.
		local w, h = panel:GetSize()
		for _, region in ipairs({ panel:GetRegions() }) do
			if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
				local rw, rh = region:GetSize()
				if rw >= w - 2 and rh >= h - 2 then region:SetAlpha(0) end
			end
		end
		if type(panel.settingsBorderEdges) == "table" then
			for _, edges in pairs(panel.settingsBorderEdges) do
				if type(edges) == "table" then
					for _, edge in pairs(edges) do Fade(edge) end
				end
			end
		end
		ns.Shell(panel, { window = true }, KEY)
	end)
end

local function Report(panel, Kit)
	if not ns.Once(panel) then return end
	Fade(panel.background)
	Fade(panel.topEdge)
	KillBackdropChildren(panel)
	ns.Shell(panel, { window = true }, KEY)
	Close(Kit, panel.closeButton)
	ns.DressOnShow(panel, { checks = false }, function() Fade(panel.topEdge) end, KEY)
end

local function Recap(panel)
	if not ns.Once(panel) then return end
	KillGround(panel)
	KillBackdropChildren(panel)
	ns.Shell(panel, nil, KEY)
end

ns.Watch(KEY, "ForeverFishingJournal", Journal)
ns.Watch(KEY, "ForeverFishingSessionGoals", Goals)
ns.Watch(KEY, "ForeverFishingSettings", Settings)
ns.Watch(KEY, "ForeverFishingTracePanel", Report)
ns.Watch(KEY, function() return ns.Usable(FF.catchRecapPanel) and FF.catchRecapPanel or nil end, Recap)

ns.Pack("ForeverFishing")
