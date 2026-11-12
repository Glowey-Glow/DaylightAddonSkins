-- Keep or Toss: three ButtonFrameTemplate windows (the item page, its detail pane, the intro).
local _, ns = ...
if not ns.ok then return end

local function Again(frame, Kit)
	-- Lists inside the detail pane (an inset and a scroll frame) are made as items are shown.
	local queued
	local function run()
		queued = nil
		if frame:IsShown() and ns.Controls("KeepOrToss") then ns.Guard(Kit.Auto, frame, { rows = false }) end
	end
	local function later()
		if queued then return end
		queued = true
		C_Timer.After(0, run)
	end
	frame:HookScript("OnShow", later)
	if type(frame.SetTitle) == "function" then hooksecurefunc(frame, "SetTitle", later) end
end

local function Window(frame, Kit)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	ns.Guard(Kit.Window, frame)
	if ns.Controls("KeepOrToss") then ns.Guard(Kit.Auto, frame, { rows = false }) end
	Again(frame, Kit)
end

ns.Pack("KeepOrToss", "Keep or Toss", function(Kit)
	if not _G.KeepOrTossFrame then return false end
	Window(_G.KeepOrTossFrame, Kit)
	Window(_G.KeepOrTossDetailFrame, Kit)
	ns.Watch("KeepOrToss", "KeepOrTossIntroFrame", Window)
end, { controls = true })
