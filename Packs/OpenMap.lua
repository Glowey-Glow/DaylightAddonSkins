-- OpenMap: the dialogs and panels around the map. OpenMap draws them through four helpers on
-- OpenMap.Look (Font, Panel, Window, Dropdown: "other addons may restyle these", its Core.lua says),
-- so each helper is followed here and what it drew is swapped for DaylightUI's shell.
-- The map itself (Blizzard's WorldMapFrame, already DaylightUI's to dress), the canvas, pins, the
-- tab rail and the dungeon picture are left alone.
local _, ns = ...
if not ns.ok then return end

ns.Target("OpenMap", "OpenMap", { window = true, controls = true, text = true, shadow = true, font = "daylight" })

local OM = _G.OpenMap
local Look = type(OM) == "table" and OM.Look
if type(Look) ~= "table" or type(Look.Window) ~= "function" or type(Look.Panel) ~= "function"
	or type(Look.Dropdown) ~= "function" then
	return
end

local KEY = "OpenMap"
local busy = false   -- inside Window or Dropdown, which may call Panel themselves

local function Snapshot(frame)
	local seen = {}
	for _, child in ipairs({ frame:GetChildren() }) do seen[child] = true end
	for _, region in ipairs({ frame:GetRegions() }) do seen[region] = true end
	return seen
end

-- What a helper added to the frame, apart from the pieces to keep.
local function Added(frame, before, keep)
	local children, regions = {}, {}
	for _, child in ipairs({ frame:GetChildren() }) do
		if not before[child] and not keep[child] then children[#children + 1] = child end
	end
	for _, region in ipairs({ frame:GetRegions() }) do
		if not before[region] and not keep[region] then regions[#regions + 1] = region end
	end
	return children, regions
end

local function Call(fn, ...)
	local was = busy
	busy = true
	local a, b, c, d, e = pcall(fn, ...)
	busy = was
	if not a then error(b, 0) end
	return b, c, d, e
end

local origWindow, origPanel, origDropdown, origFont = Look.Window, Look.Panel, Look.Dropdown, Look.Font

Look.Window = function(self, frame, title, onClose)
	if type(frame) ~= "table" or not frame.GetChildren then return origWindow(self, frame, title, onClose) end
	local before = Snapshot(frame)
	local top, text, close = Call(origWindow, self, frame, title, onClose)
	local keep = {}
	if text then keep[text] = true end
	if close then keep[close] = true end
	local children, regions = Added(frame, before, keep)
	ns.WithKit(function(Kit)
		if not ns.Enabled(KEY) or not ns.Once(frame) then return end
		for i = 1, #children do ns.Kill(children[i]) end
		for i = 1, #regions do ns.Kill(regions[i]) end
		ns.Shell(frame, { window = true }, KEY)
		if close and ns.Controls(KEY) and ns.Once(close) then ns.Guard(Kit.Close, close) end
		ns.DressOnShow(frame, nil, nil, KEY)
	end)
	return top, text, close
end

Look.Panel = function(self, frame, opts)
	local bd = origPanel(self, frame, opts)
	if busy or type(frame) ~= "table" then return bd end
	ns.WithKit(function()
		if not ns.Enabled(KEY) then return end
		local back = frame.omBackdrop
		if not ns.Usable(back) then return end
		ns.NoBackdrop(back)
		ns.Shell(back, nil, KEY)
		if ns.Once(frame) and frame.HookScript then ns.DressOnShow(frame, nil, nil, KEY) end
	end)
	return bd
end

Look.Dropdown = function(self, frame)
	if type(frame) ~= "table" or not frame.GetChildren then return origDropdown(self, frame) end
	local before = Snapshot(frame)
	local l, r, t, b = Call(origDropdown, self, frame)
	local children, regions = Added(frame, before, {})
	ns.WithKit(function()
		if not ns.Enabled(KEY) or not ns.Once(frame) then return end
		for i = 1, #children do ns.Kill(children[i]) end
		for i = 1, #regions do ns.Kill(regions[i]) end
		ns.Shell(frame, nil, KEY)
	end)
	return l, r, t, b
end

if type(origFont) == "function" then
	local function Restyle(fs, size, flags)
		ns.SetFont(KEY, fs, (fs:GetFont()), size or 12, flags or "")
	end
	Look.Font = function(self, fs, size, flags)
		local out = origFont(self, fs, size, flags)
		if type(fs) == "table" and fs.SetFont and fs.GetFont and ns.Enabled(KEY) and not ns.PlainText(KEY) then
			pcall(Restyle, fs, size, flags)
		end
		return out
	end
end

-- The settings menu draws its own ground (the same recipe, kept private): a nine-slice child and
-- two BACKGROUND textures, or a dialog backdrop on clients without the nine-slice.
ns.Watch(KEY, "OpenMapMenu", function(menu, Kit)
	if not ns.Once(menu) then return end
	for _, child in ipairs({ menu:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Frame" and child.TopLeftCorner and child.TopEdge then
			ns.Kill(child)
		end
	end
	for _, region in ipairs({ menu:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			ns.Kill(region)
		end
	end
	ns.NoBackdrop(menu)
	ns.Shell(menu, { window = true })
	local close = ns.FindClose(menu)
	if close and ns.Controls(KEY) and ns.Once(close) then ns.Guard(Kit.Close, close) end
	-- Its checkboxes are pooled and already flat; its rows and tiles are its own drawing.
	local later = ns.DressOnShow(menu, { checks = false })
	if type(menu.tabs) == "table" then
		for _, tab in pairs(menu.tabs) do
			if ns.Usable(tab) and tab.HookScript then tab:HookScript("OnClick", later) end
		end
	end
end)

ns.Pack("OpenMap")
