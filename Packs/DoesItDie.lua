-- DoesItDie: the options window and the learned-ticks viewer, both flat one-pixel backdrops.
-- Its marker, skull and nameplate pieces are the addon's display and are never touched: the options
-- window hosts live copies of them on its mock frames, so those are skipped whole.
local _, ns = ...
if not ns.ok then return end

ns.Pack("DoesItDie", "DoesItDie", function()
	ns.Watch("DoesItDie", "DoesItDieOptions", function(frame)
		local skip = {}
		for _, key in ipairs({ "mock", "mockPlate", "mockFocus", "host", "plateHost", "focusHost",
			"healthBar", "plateHealthBar", "focusHealthBar" }) do
			if type(frame[key]) == "table" then skip[frame[key]] = true end
		end
		ns.PlainWindow(frame, { skip = skip, soften = true })
	end)
	ns.Watch("DoesItDie", "DoesItDieLearnedTicks", function(frame)
		ns.PlainWindow(frame, { soften = true })
	end)
end, { window = true, controls = true, text = true, shadow = true })
