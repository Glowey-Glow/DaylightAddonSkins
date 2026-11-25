-- Forever Fishing: the shells of its windows (Journal, Settings, Session Goals, the Session Tracker,
-- the trace / report windows, the bug report, the camera developer window, the Scan Diagnostics
-- card, the catch recap) and its text in the player's font. The session windows' title in the title
-- ink, their header mark and the Tracker's picked heading in the accent (the other heading in the
-- label ink), the Tracker's options button an icon button.
-- Left alone: the Journal's parchment page and everything on it (dark ink on paper, rebuilt on
-- every render), the inside of the Settings window (every control is its own drawing with its own
-- state colors), the Tracker's cards and its options menu (its own drawing), the report windows'
-- own buttons, the Scan Diagnostics step colors (done, active, waiting), the fishing bar, tool bar,
-- flyouts, cast bar and key capture (secure / HUD).
-- The Journal, Settings, Session Goals and Session Tracker roots are protected frames: they are
-- dressed out of combat only, and never moved, sized, shown or hidden from here.
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

local function SetInk(fs, name)
	local c = ns.Colors()[name]
	if c then fs:SetTextColor(c[1], c[2], c[3]) end
end

-- A session window's title (set gold once, when it's made) and the short bar beside it.
local function SessionTitle(panel)
	local title = panel.title
	if not ns.Usable(title) or title:GetObjectType() ~= "FontString" then return end
	SetInk(title, "VALUE")
	local header = title:GetParent()
	if not ns.Usable(header) then return end
	for _, region in ipairs({ header:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "ARTWORK"
			and region:GetWidth() <= 3 then
			ns.FillAccent(region, 1, nil, KEY)
		end
	end
end

-- The Tracker's two headings (Stats, Catches): the addon colors the picked one gold and the other
-- tan, lighter under the mouse, on every pick, hover and layout, and shows a bar by the picked one.
local painting = false
local function InkHeading(button)
	painting = true
	if button.accent:IsShown() then
		button.label:SetTextColor(ns.AccentOf(KEY))
	else
		SetInk(button.label, button:IsMouseOver() and "TEXT" or "LABEL")
	end
	painting = false
end

local function Heading(button)
	if not ns.Usable(button) or not ns.Usable(button.label) or not ns.Usable(button.accent) then return end
	if not ns.Once(button) then return end
	ns.FillAccent(button.accent, 1, nil, KEY)
	-- (Hooked directly: the Tracker's root is a protected frame, and ns.HookOnce refuses its parts.)
	hooksecurefunc(button.label, "SetTextColor", function()
		if not painting then InkHeading(button) end
	end)
	InkHeading(button)
end

-- The Tracker's options button: the game's red close plate with its own lines drawn on a strip of
-- that plate. The plate and strip off, the lines an icon in DaylightUI's control box.
local function OptionsButton(Kit, button)
	if not ns.Usable(button) or not ns.Usable(button.icon) or not ns.Once(button) then return end
	for _, region in ipairs({ button:GetRegions() }) do
		if ns.Usable(region) and region ~= button.icon and region:GetObjectType() == "Texture"
			and region:GetDrawLayer() == "ARTWORK" then
			region:SetAlpha(0)
		end
	end
	ns.Guard(Kit.IconButton, button, 4)
end

-- Session Goals and the Session Tracker (one maker for both).
local function Goals(panel, Kit)
	ns.OutOfCombat(function()
		if not ns.Once(panel) then return end
		KillGround(panel)
		Fade(panel.border)
		ns.Shell(panel, { window = true }, KEY)
		Close(Kit, panel.close)
		SessionTitle(panel)
		if ns.Controls(KEY) then
			Heading(panel.statsHeading)
			Heading(panel.catchesHeading)
			OptionsButton(Kit, panel.settings)
		end
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

-- The Scan Diagnostics card: a soft "bubble" drawn in nine pieces three times over (glow and fill
-- under, edge over). It takes no mouse itself (clicks pass through to the world) and changes height
-- when the run is done.
local function Diagnostics(panel)
	if not ns.Once(panel) then return end
	for _, region in ipairs({ panel:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" then
			local layer = region:GetDrawLayer()
			if layer == "BACKGROUND" or layer == "BORDER" then region:SetAlpha(0) end
		end
	end
	ns.Shell(panel, nil, KEY)
	ns.DressOnShow(panel, { checks = false }, nil, KEY)
end

local function Recap(panel)
	if not ns.Once(panel) then return end
	KillGround(panel)
	KillBackdropChildren(panel)
	ns.Shell(panel, nil, KEY)
end

ns.Watch(KEY, "ForeverFishingJournal", Journal)
ns.Watch(KEY, "ForeverFishingSessionGoals", Goals)
ns.Watch(KEY, "ForeverFishingSessionTracker", Goals)
ns.Watch(KEY, "ForeverFishingSettings", Settings)
ns.Watch(KEY, "ForeverFishingTracePanel", Report)
ns.Watch(KEY, "ForeverFishingBugReport", Report)
ns.Watch(KEY, "ForeverFishingScanDeveloper", Report)
ns.Watch(KEY, "ForeverFishingScanDiagnostics", Diagnostics)
ns.Watch(KEY, function() return ns.Usable(FF.catchRecapPanel) and FF.catchRecapPanel or nil end, Recap)

-- Its window stack (0.9.251, UI.lua SetFishingSurfaceLayer from BringFishingWindowForward): when
-- a window moves to a new level, every child below the window is lifted to one above it, and
-- DaylightUI's shells sit one below their frame (Style.lua Style.Skin). Lifted, a shell would
-- cover the window's own words and art: each one in the windows it restacked goes back under
-- its frame. (It restacks out of combat only.)
local function SinkShells(frame, GetShell, depth)
	local s = GetShell(frame)
	if s and s.GetParent and s:GetParent() == frame then
		local want = math.max(0, frame:GetFrameLevel() - 1)
		if s:GetFrameLevel() ~= want then s:SetFrameLevel(want) end
	end
	if depth >= 8 then return end
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) then SinkShells(child, GetShell, depth + 1) end
	end
end

if type(FF.BringFishingWindowForward) == "function" then
	ns.HookOnce(FF, "BringFishingWindowForward", function(self)
		if not ns.Enabled(KEY) or InCombatLockdown() then return end
		local Style = type(_G.DaylightUI) == "table" and _G.DaylightUI.Style
		local GetShell = type(Style) == "table" and Style.GetShell
		if type(GetShell) ~= "function" then return end
		for _, window in ipairs(type(self.floatingWindows) == "table" and self.floatingWindows or {}) do
			if ns.Usable(window) then ns.Guard(SinkShells, window, GetShell, 0) end
		end
	end, KEY)
end

-- The fast path: the calls that make (and open) these windows dress them before they're drawn.
for _, name in ipairs({ "ShowFishingBugReport", "ShowTraceWindow", "EnsureScanDiagnosticsUI", "ShowCameraDeveloper" }) do
	if type(FF[name]) == "function" then ns.HookOnce(FF, name, ns.WatchNow, KEY) end
end

ns.Pack("ForeverFishing")
