-- DoesItDie: the options window and the learned-ticks viewer, both flat one-pixel backdrops: their
-- shells, template buttons, check boxes, text boxes and sliders, its tabs (the picked one's words
-- and underline in the accent), its dropdown list (the current entry in the accent) and the game's
-- gold and gray words in DaylightUI's inks (green, red, spell and school colors kept).
-- Its marker, skull and nameplate pieces are the addon's display and are never touched: the options
-- window hosts live copies of them on its mock frames, so those are skipped whole.
local _, ns = ...
if not ns.ok then return end

local KEY = "DoesItDie"
local abs = math.abs
-- (Its own record, not ns.Once: the dressing walk marks the backdrop buttons it softens there.)
local hooked = setmetatable({}, { __mode = "k" })
local function First(obj)
	if hooked[obj] then return false end
	hooked[obj] = true
	return true
end

local function Near(r, g, b, r2, g2, b2)
	return abs(r - r2) <= 0.03 and abs(g - g2) <= 0.03 and abs(b - b2) <= 0.03
end

local function SetInk(fs, name)
	local c = ns.Colors()[name]
	if c then fs:SetTextColor(c[1], c[2], c[3]) end
end

-- The game's gold and gray words in DaylightUI's inks, the frame and its children (skip: frames
-- left as they are). The window titles (its large gold font) in the title ink.
local function Ink(Kit, frame, skip, depth)
	if not ns.Usable(frame) or (skip and skip[frame]) or depth > 8 then return end
	if frame.GetRegions then
		for _, r in ipairs({ frame:GetRegions() }) do
			if ns.Usable(r) and r:GetObjectType() == "FontString" and r:GetFontObject() == GameFontNormalLarge then
				SetInk(r, "VALUE")
			end
		end
		Kit.InkGameText(frame)
	end
	if frame.GetChildren then
		for _, c in ipairs({ frame:GetChildren() }) do Ink(Kit, c, skip, depth + 1) end
	end
end

-- Every slider below a frame: its own plain Slider with the game's thumb.
local function Sliders(frame, skip, depth)
	if not ns.Usable(frame) or (skip and skip[frame]) or depth > 8 then return end
	if frame:GetObjectType() == "Slider" then
		ns.Slider(frame)
		return
	end
	for _, c in ipairs({ frame:GetChildren() }) do Sliders(c, skip, depth + 1) end
end

-- Tabs: the addon sets the picked one's words gold and the others gray on every pick, its
-- underline gold once. The picked one's words in the accent, the others in the label ink.
local painting = false
local function PaintTab(fs, words, picked)
	painting = true
	if picked then
		ns.AccentText(fs, words, KEY)
	else
		fs:SetText(words)
		SetInk(fs, "LABEL")
	end
	painting = false
end

local function Tab(button)
	local fs, line = button.text, button.underline
	if not ns.Usable(fs) or not First(button) then return end
	local words = fs:GetText()
	if type(words) ~= "string" then return end
	if ns.Usable(line) then ns.FillAccent(line, 1, nil, KEY) end
	local function Follow(_, r, g, b)
		if painting or type(r) ~= "number" then return end
		if Near(r, g, b, 1, 0.82, 0) then
			PaintTab(fs, words, true)
		elseif Near(r, g, b, 0.6, 0.6, 0.6) then
			PaintTab(fs, words, false)
		end
	end
	hooksecurefunc(fs, "SetTextColor", Follow)
	Follow(fs, fs:GetTextColor())
end

-- Its dropdown list: one frame of its own under UIParent, made on the first open, its rows filled
-- again on every open with the current entry written in the game's gold.
local menu
local function FindMenu(owner)
	for _, f in ipairs({ UIParent:GetChildren() }) do
		if ns.Usable(f) and f.owner == owner and type(f.buttons) == "table" then return f end
	end
end

local function DressMenu(owner)
	menu = menu or FindMenu(owner)
	if not menu or not menu:IsShown() then return end
	if First(menu) then
		ns.NoBackdrop(menu)
		ns.Shell(menu, nil, KEY)
	end
	for _, b in ipairs(menu.buttons) do
		local fs = ns.Usable(b) and b:IsShown() and b.text
		local words = fs and fs:GetText()
		if type(words) == "string" then
			local current = words:match("^|cffffd100(.-)|r$")
			if current then
				ns.AccentText(fs, current, KEY)
			else
				SetInk(fs, "TEXT")
			end
		end
	end
end

-- Its choice buttons: the only buttons with a backdrop of their own.
local function Choices(frame, depth)
	if depth > 8 then return end
	for _, c in ipairs({ frame:GetChildren() }) do
		if ns.Usable(c) then
			if c:GetObjectType() == "Button" and c.GetBackdrop and c:GetBackdrop() then
				if First(c) then c:HookScript("OnClick", DressMenu) end
			else
				Choices(c, depth + 1)
			end
		end
	end
end

ns.Pack(KEY, "DoesItDie", function()
	ns.Watch(KEY, "DoesItDieOptions", function(frame, Kit)
		local skip = {}
		for _, key in ipairs({ "mock", "mockPlate", "mockFocus", "host", "plateHost", "focusHost",
			"healthBar", "plateHealthBar", "focusHealthBar" }) do
			if type(frame[key]) == "table" then skip[frame[key]] = true end
		end
		ns.PlainWindow(frame, { skip = skip, soften = true })
		local area = frame.settingsArea
		local tabs = {}
		if ns.Usable(area) then
			for _, c in ipairs({ area:GetChildren() }) do
				if ns.Usable(c) and c:GetObjectType() == "Button" and ns.Usable(c.underline) and ns.Usable(c.text) then
					tabs[c] = true
				end
			end
		end
		local inkSkip = {}
		for f in pairs(skip) do inkSkip[f] = true end
		for f in pairs(tabs) do inkSkip[f] = true end
		Ink(Kit, frame, inkSkip, 0)
		if ns.Controls(KEY) then
			for b in pairs(tabs) do Tab(b) end
			if ns.Slider then Sliders(frame, skip, 0) end
			if ns.Usable(area) then Choices(area, 0) end
		end
	end)
	ns.Watch(KEY, "DoesItDieLearnedTicks", function(frame, Kit)
		ns.PlainWindow(frame, { soften = true })
		Ink(Kit, frame, nil, 0)
	end)
end, { window = true, controls = true, text = true, shadow = true })
