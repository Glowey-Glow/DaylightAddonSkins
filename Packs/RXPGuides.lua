-- RestedXP Guides: its guide window docked to the quest tracker, a choice on its page (Guide):
--   * Off: the guide stays where you put it (the default).
--   * Under Tracker: the guide hangs under the quest list, as wide as it, and follows it as the
--     list grows, shrinks or is moved. When the list is too tall to leave room under it, the guide
--     goes back to its own spot until there is room again.
--   * Replace Tracker: the guide takes the tracker's place (its top edge and width) and the tracker
--     is put away, with its quest item column; set back to Off, the tracker comes back.
-- The tracker is Daylight UI's (DaylightUI.API GetFrame "questtracker"), else the game's
-- (ObjectiveTrackerFrame). The guide is RestedXP's new window (its "V2" interface, a beta setting:
-- addon.v2:GetGuideWindowAnchorFrame) when that's on, else its classic one (RXPFrame).
--
-- How: the guide is anchored to the tracker's frames by two points (its top corners), so it moves
-- and sizes with them by itself: nothing is watched over time. It is laid out again only when
-- something says it changed: this setting, the tracker's list or the guide changing size, showing
-- or hiding, RestedXP loading a position or its guide window, the UI scale, leaving combat. Where
-- the tracker is narrower than the guide's narrowest, the guide is scaled down to fit (never below
-- two thirds of its own scale: then it stays where it was).
-- RestedXP saves its windows' spots and sizes (addon.settings:SaveFramePositions, on logout and
-- after a drag). While the guide is docked, the spot, width and scale it had before are written
-- back over what that saved, so turning this off (or taking Addon Skins out) leaves it where you
-- had it. A drag of the docked guide puts it back on the tracker.
-- Only RestedXP's public objects are read (its AceAddon, its settings, its windows); none of its
-- code or art is copied. Daylight UI's tracker is read through its API's GetFrame and its two named
-- frames (DaylightUIQuestTracker, DaylightUIQuestItems); nothing of it is changed but whether it's
-- shown, out of combat (its item buttons are secure).
local _, ns = ...
if not ns.ok then return end
local L = ns.L

local KEY = "RXPGuides"
local PATH = "look." .. KEY .. ".dock"
local GAP = 6              -- between the tracker's list and the guide
local MIN_SCALE = 2 / 3    -- of the guide's own scale, the smallest it's shrunk to fit

ns.Target(KEY, "RestedXP Guides", { defaults = { dock = "off" } })

-- The dock's setting, on the All Windows page in a section of its own (Options.lua), shown while
-- RestedXP Guides is loaded: a setting of what the guide does, not of its look, so not buried in
-- Look and Feel.
function ns.RXPGroup()
	-- (Daylight UI hides a card whose rows are all hidden; a group's own hidden isn't read.)
	return { label = L["RestedXP Guides"],
		items = {
			{ type = "dropdown", key = PATH, label = L["Guide Window"],
			  hidden = function()
				local A = C_AddOns
				return not (A and A.IsAddOnLoaded and A.IsAddOnLoaded("RXPGuides"))
			  end,
			  values = { off = L["Off"], under = L["Under Tracker"], replace = L["Replace Tracker"] },
			  order = { "off", "under", "replace" },
			  desc = L["Docks RestedXP's guide to the quest tracker: under it at its width, or in its place with the tracker put away. Off, the guide stays where you put it. Needs RestedXP Guides switched on under Addons."] },
		} }
end

local API = ns.API

-- ---------------------------------------------------------------------------------------------
-- The guide and the tracker
-- ---------------------------------------------------------------------------------------------

local function RXP()
	local ace = _G.LibStub and _G.LibStub("AceAddon-3.0", true)
	local ok, rxp = pcall(function() return ace and ace:GetAddon("RXPGuides", true) end)
	return ok and type(rxp) == "table" and rxp or nil
end

local function Mode()
	if not ns.Enabled(KEY) then return "off" end
	local v = ns.Setting(PATH)
	if v == "under" or v == "replace" then return v end
	return "off"
end

-- The guide's frame and the name RestedXP saves it under, or nil (hidden in its settings, or not
-- made yet).
local function Guide(rxp)
	local v2 = rxp.v2
	if type(v2) == "table" and type(v2.IsEnabled) == "function" and v2:IsEnabled() then
		local f = type(v2.GetGuideWindowAnchorFrame) == "function" and v2:GetGuideWindowAnchorFrame()
		if ns.Usable(f) then return f, "RXPV2GuideWindow", _G.RXPV2GuideWindow end
		return nil
	end
	local f = rxp.RXPFrame or _G.RXPFrame
	if ns.Usable(f) then return f, "RXPFrame" end
end

-- The narrowest the guide is laid out at.
local function MinWidth(name, window)
	if name == "RXPV2GuideWindow" and type(window) == "table" and type(window.GetMinimumWidth) == "function" then
		local ok, w = pcall(window.GetMinimumWidth, window)
		if ok and type(w) == "number" and w > 0 then return w end
		return 265
	end
	return 220
end

-- RestedXP's current-step panel ("Step 1": the step you're on), pinned by RestedXP just above the
-- guide window (or just below it, with its Anchor set to the bottom), and which side, or nil while
-- it isn't showing. The dock leaves room for it so it doesn't sit over the minimap or the list.
local function Steps(rxp)
	local f
	local v2 = rxp.v2
	if type(v2) == "table" and type(v2.IsEnabled) == "function" and v2:IsEnabled() then
		local me = type(rxp.player) == "table" and rxp.player.name
		local mine = me and type(v2.state) == "table" and type(v2.state.player) == "table" and v2.state.player[me]
		local w = type(mine) == "table" and mine.activeStepFrame
		f = type(w) == "table" and w.frame
	else
		f = type(rxp.RXPFrame) == "table" and rxp.RXPFrame.CurrentStepFrame
	end
	if not (ns.Usable(f) and f:IsShown()) then return nil end
	local profile = type(rxp.settings) == "table" and rxp.settings.profile
	local below = type(profile) == "table" and profile.anchorOrientation == "bottom"
	return f, below
end

-- The tracker: { holder (the frame put away), items (its item column, or nil), list (the frame
-- whose bottom the guide hangs from), top (whose top edge it takes the place of) }, or nil.
local function Tracker()
	local ok, holder = pcall(API.GetFrame, "questtracker")
	if ok and ns.Usable(holder) then
		local list, view, up
		local kids = { holder:GetChildren() }
		for _, kid in ipairs(kids) do
			if kid:IsObjectType("ScrollFrame") then
				view, list = kid, kid
				-- (Growing up from the holder's bottom: the holder's bottom is the list's.)
				up = kid:GetPoint(1) == "BOTTOMRIGHT"
				-- Its box, when shown, sits round the list.
				for _, box in ipairs(kids) do
					if box ~= kid and box:IsShown() and select(2, box:GetPoint(1)) == kid then list = box end
				end
				break
			end
		end
		-- (The holder is a mover of a fixed size; the list is as wide as the tracker is set to, at
		-- the holder's right edge.)
		return { holder = holder, items = _G.DaylightUIQuestItems, list = (up or not list) and holder or list,
			top = (not up and view) or holder, own = true }
	end
	local f = _G.ObjectiveTrackerFrame or _G.QuestWatchFrame
	if ns.Usable(f) then return { holder = f, list = f, top = f } end
end

-- ---------------------------------------------------------------------------------------------
-- Docking
-- ---------------------------------------------------------------------------------------------

local state = {
	frame = nil,    -- the guide docked now
	name = nil,     -- its name in RestedXP's saved spots
	home = nil,     -- { points = { {...}, ... }, width, scale }: where it was before
	away = nil,     -- the tracker put away: { holder, items }
	pending = false,
}

local function Points(f)
	local out = {}
	for i = 1, f:GetNumPoints() do out[i] = { f:GetPoint(i) } end
	return out
end

-- The tracker back, out of combat (its item buttons are secure).
local function TrackerBack()
	local a = state.away
	if not a then return end
	if InCombatLockdown() then
		state.pending = true
		return
	end
	state.away = nil
	if ns.Usable(a.holder) then a.holder:Show() end
	if ns.Usable(a.items) then a.items:Show() end
end

local function TrackerAway(t)
	if InCombatLockdown() then
		state.pending = true
		return
	end
	state.away = { holder = t.holder, items = t.items }
	if t.holder:IsShown() then t.holder:Hide() end
	if ns.Usable(t.items) and t.items:IsShown() then t.items:Hide() end
end

local function Undock()
	local f, home = state.frame, state.home
	state.frame, state.name, state.home, state.across, state.scale = nil, nil, nil, nil, nil
	if not (ns.Usable(f) and home) then return end
	f:SetScale(home.scale)
	f:ClearAllPoints()
	for _, p in ipairs(home.points) do pcall(f.SetPoint, f, unpack(p, 1, 5)) end
	if #home.points == 0 then f:SetPoint("LEFT", UIParent, "LEFT", 0, 35) end
	f:SetWidth(home.width)
end

local Apply

-- Whether f is anchored exactly by these points already (so nothing is set again: re-anchoring a
-- frame that is where it should be is what kept it busy).
local function Anchored(f, want)
	if f:GetNumPoints() ~= #want then return false end
	for i, w in ipairs(want) do
		local p, rel, rp, x, y = f:GetPoint(i)
		if p ~= w[1] or rel ~= w[2] or rp ~= w[3] or math.abs((x or 0) - w[4]) > 0.01 or math.abs((y or 0) - w[5]) > 0.01 then
			return false
		end
	end
	return true
end

-- The guide on the tracker. Returns false when it doesn't fit, worked out before anything moves:
-- the guide is never put there to be measured and taken back (that swing resized it, which asked
-- for another try, every frame). Its height doesn't follow its width, so the answer holds.
local function Dock(f, name, window, t, mode, steps, stepsBelow)
	local anchor = mode == "replace" and t.top or t.list
	local left, right, top, bottom = anchor:GetLeft(), anchor:GetRight(), anchor:GetTop(), anchor:GetBottom()
	-- (Put away, the tracker's frames may not measure: a guide docked on them stays.)
	if not (left and right and top and bottom and right > left) then return state.frame == f and state.away ~= nil end
	local home = (state.frame == f and state.home) or { points = Points(f), width = f:GetWidth(), scale = f:GetScale() }
	-- Wide enough: the tracker's width in the guide's own units, at most its own scale. The scale is
	-- kept while the tracker's width is the same (the guide's narrowest width follows its title,
	-- which is laid out at the width it gets).
	local aScale = anchor:GetEffectiveScale()
	local across = (right - left) * aScale
	local parent = f:GetEffectiveScale() / f:GetScale()
	local scale
	if state.frame == f and state.across and math.abs(state.across - across) < 0.5 then
		scale = state.scale
	else
		scale = math.min(home.scale, across / (parent * MinWidth(name, window)))
	end
	if scale < home.scale * MIN_SCALE then return false end
	-- The current-step panel above the guide: the guide goes down by its height, so the panel takes
	-- the spot the guide's top would have had. Below the guide, it needs room under it too.
	local px = parent * scale
	local stepsPx = 0
	if steps then
		local h = steps:GetHeight()
		if type(h) == "number" and h > 0 then stepsPx = h * steps:GetEffectiveScale() + 5 * px end
	end
	local above = stepsBelow and 0 or stepsPx
	-- Room for the whole guide (and the panel) below where its top would go.
	local topAt = (mode == "replace" and top or bottom) * aScale - (mode == "replace" and 0 or GAP * px) - above
	local ground = (UIParent:GetBottom() or 0) * UIParent:GetEffectiveScale()
	if topAt - f:GetHeight() * px - (stepsBelow and stepsPx or 0) < ground then return false end
	local drop = above / px   -- in the guide's own units
	if state.frame and state.frame ~= f then Undock() end
	if not state.frame then
		state.frame, state.name, state.home = f, name, home
	end
	state.across, state.scale = across, scale
	if math.abs(f:GetScale() - scale) > 0.001 then f:SetScale(scale) end
	local want
	if mode == "replace" then
		want = { { "TOPLEFT", anchor, "TOPLEFT", 0, -drop }, { "TOPRIGHT", anchor, "TOPRIGHT", 0, -drop } }
	else
		want = { { "TOPLEFT", anchor, "BOTTOMLEFT", 0, -GAP - drop }, { "TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -GAP - drop } }
	end
	if not Anchored(f, want) then
		f:ClearAllPoints()
		for _, w in ipairs(want) do f:SetPoint(w[1], w[2], w[3], w[4], w[5]) end
	end
	return true
end

function Apply()
	state.pending = false
	local rxp = RXP()
	local mode = rxp and Mode() or "off"
	local f, name, window
	if rxp then f, name, window = Guide(rxp) end
	local t = mode ~= "off" and f and Tracker()
	if not (t and f:IsShown()) then
		Undock()
		TrackerBack()
		return
	end
	local steps, stepsBelow = Steps(rxp)
	if not Dock(f, name, window, t, mode, steps, stepsBelow) then
		Undock()
		TrackerBack()
		return
	end
	if mode == "replace" then TrackerAway(t) else TrackerBack() end
end

-- Once per burst: several of the hooks below fire for one change.
local queued = false
local function Soon()
	if queued then return end
	queued = true
	C_Timer.After(0, function()
		queued = false
		ns.Guard(Apply)
	end)
end
ns.RXPDockSoon = Soon

-- What RestedXP saves while the guide is docked: the spot, width and scale it had before.
local function KeepHome(rxp)
	local f, home, name = state.frame, state.home, state.name
	local profile = rxp.settings and rxp.settings.profile
	if not (f and home and name and type(profile) == "table") then return end
	if type(profile.framePositions) == "table" then
		local saved = {}
		for i, p in ipairs(home.points) do
			local rel = p[2]
			if type(rel) == "table" then rel = rel.GetName and rel:GetName() or nil end
			saved[i] = { p[1], rel, p[3], p[4], p[5] }
		end
		profile.framePositions[name] = saved
	end
	local sizes = profile.frameSizes
	if type(sizes) == "table" and type(sizes[name]) == "table" then
		sizes[name] = { home.width, sizes[name][2] or f:GetHeight() }
	end
end

-- ---------------------------------------------------------------------------------------------
-- Hooks: everything that can move the guide or the tracker
-- ---------------------------------------------------------------------------------------------

local hookedFrames = setmetatable({}, { __mode = "k" })
local function Watch(f)
	if not ns.Usable(f) or hookedFrames[f] then return end
	hookedFrames[f] = true
	f:HookScript("OnShow", Soon)
	f:HookScript("OnHide", Soon)
	f:HookScript("OnSizeChanged", Soon)
end

-- The tracker's frames: shown again by its own code while put away, it goes away again.
local function WatchTracker()
	local t = Tracker()
	if not t then return end
	for _, f in ipairs({ t.holder, t.list, t.items }) do
		if ns.Usable(f) and not hookedFrames[f] then
			hookedFrames[f] = true
			f:HookScript("OnSizeChanged", Soon)
			f:HookScript("OnShow", function()
				if state.away then Soon() end
			end)
		end
	end
	if t.own then
		-- (Its box showing or hiding moves the list's bottom.)
		for _, kid in ipairs({ t.holder:GetChildren() }) do Watch(kid) end
	end
end

local function WatchGuide(rxp)
	local f = Guide(rxp)
	Watch(f)
	-- (The step panel grows and shrinks with each step, and shows and hides with it.)
	local v2 = rxp.v2
	local me = type(rxp.player) == "table" and rxp.player.name
	local mine = me and type(v2) == "table" and type(v2.state) == "table" and type(v2.state.player) == "table" and v2.state.player[me]
	local w = type(mine) == "table" and mine.activeStepFrame
	Watch(type(w) == "table" and w.frame or nil)
	Watch(type(rxp.RXPFrame) == "table" and rxp.RXPFrame.CurrentStepFrame or nil)
	if ns.Usable(f) and not hookedFrames["drag:" .. tostring(f)] then
		hookedFrames["drag:" .. tostring(f)] = true
		-- A drag of the docked guide: back on the tracker.
		hooksecurefunc(f, "StopMovingOrSizing", function() if state.frame == f then Soon() end end)
	end
end

ns.Pack(KEY, nil, function()
	local rxp = RXP()
	if not rxp then return false end
	local settings = rxp.settings
	if type(settings) == "table" then
		if type(settings.SaveFramePositions) == "function" then
			hooksecurefunc(settings, "SaveFramePositions", function() ns.Guard(KeepHome, rxp) end)
		end
		-- RestedXP put a window where it saved it (a profile change, a reset): docked again.
		if type(settings.LoadFramePosition) == "function" then
			hooksecurefunc(settings, "LoadFramePosition", function()
				local f, home = state.frame, state.home
				if f and home then pcall(f.SetScale, f, home.scale) end
				state.frame, state.home, state.name, state.across, state.scale = nil, nil, nil, nil, nil
				Soon()
			end)
		end
	end
	local v2 = rxp.v2
	if type(v2) == "table" and type(v2.UpdateGuideWindow) == "function" then
		-- (Its window is made on its first draw, and its narrowest width follows the guide's title.)
		hooksecurefunc(v2, "UpdateGuideWindow", function()
			WatchGuide(rxp)
			Soon()
		end)
	end
	-- RestedXP placing its step panel again (made, a setting changed): watched, docked again.
	if type(v2) == "table" and type(v2.SetActiveStepsFrameAnchor) == "function" then
		hooksecurefunc(v2, "SetActiveStepsFrameAnchor", function()
			WatchGuide(rxp)
			Soon()
		end)
	end
	Watch(rxp.RXPFrame or _G.RXPFrame)
	WatchGuide(rxp)

	local events = CreateFrame("Frame")
	events:RegisterEvent("PLAYER_ENTERING_WORLD")
	events:RegisterEvent("PLAYER_REGEN_ENABLED")
	events:RegisterEvent("UI_SCALE_CHANGED")
	events:RegisterEvent("DISPLAY_SIZE_CHANGED")
	events:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_REGEN_ENABLED" and not state.pending then return end
		WatchTracker()
		WatchGuide(rxp)
		Soon()
	end)

	ns.me.On("SettingChanged", function(scope, path)
		if scope == "DaylightAddonSkins" and (path == PATH or path == KEY) then
			WatchTracker()
			Soon()
		elseif scope == "Quests" then
			-- (Daylight UI's tracker turned on or off, or grown the other way.)
			WatchTracker()
			Soon()
		end
	end)
	WatchTracker()
	Soon()
end)
