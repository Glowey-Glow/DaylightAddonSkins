-- Bag marks without the loot hitch.
-- Addons that mark bag slots (Polestar's upgrade arrows and quest marks, Keep or Toss) ask the
-- bag for a refresh after every bag change, through the Baganator-style API DaylightUI's bags
-- answer. DaylightUI's Plugins.Refresh then asks every mark again for every slot of every bag
-- and bank window, closed ones too, in one frame: right after each loot, with Polestar's gear
-- cache just emptied, that is a full upgrade check per slot.
-- Here a refresh repaints only the windows that are open. A closed one is marked to fill again
-- instead (Window.MarkDirty): DaylightUI's own background filler does that a couple of ms a frame
-- while it stays closed (the bag), or it fills on opening (Window.FillDirty, the bank), and its
-- slot fill asks the marks too. If DaylightUI's bags change shape, DaylightUI's own refresh runs.

local _, ns = ...
if not ns.ok then return end

local me = ns.me
local wrapped

local function Wrap()
	if wrapped or type(me.Wrap) ~= "function" then return end
	local DUI = _G.DaylightUI
	local mod = DUI and DUI.GetModule and DUI:GetModule("Bags")
	local B = type(mod) == "table" and mod.ns
	local Plugins, Window = B and B.Plugins, B and B.Window
	if type(Plugins) ~= "table" or type(Plugins.Refresh) ~= "function" or type(Plugins.Repaint) ~= "function"
		or type(Window) ~= "table" or type(Window.MarkDirty) ~= "function" then
		return
	end
	wrapped = true

	local queued = false
	local function Run()
		queued = false
		for _, f in ipairs(B.windows or {}) do
			if type(f) == "table" and not (f.spec and f.spec.still) and f.set then
				if f:IsShown() then
					for _, s in ipairs(f.set.Slots()) do Plugins.Repaint(s.button) end
					if f.match and Window.MatchAll then Window.MatchAll(f) end
				else
					Window.MarkDirty(f)
				end
			end
		end
	end

	me.Wrap(Plugins, "Refresh", function(original, ...)
		-- (Anything unexpected: DaylightUI's own refresh.)
		if type(B.windows) ~= "table" then return original(...) end
		if queued then return end
		queued = true
		C_Timer.After(0, function()
			local ok = pcall(Run)
			queued = false
			if not ok then original() end
		end)
	end)
end

me.On("Login", Wrap)
