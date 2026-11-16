-- The skin switches as two grids on the options page (Options.lua): Addons and Blizzard, a
-- DaylightUI switch and a name per cell, in as many columns as the longest name lets fit (never
-- cut off). An addon that isn't installed shows "Get Addon" beside its name in the accent: a
-- click opens a box with its CurseForge link to copy (the game can't open a browser).
-- Built from DaylightUI's own widgets (API.Switch, API.Text, API.Button, API.Input, API.Skin).
local ADDON, ns = ...
if not ns.ok then return end

local API = ns.API
local L = ns.L
local DUI = _G.DaylightUI

local PAD, GAP, CELL_H, TOP_H = 16, 8, 28, 36
local MAX_COLS = 4

local function Get(key)
	local ok, v = pcall(API.GetSetting, ADDON, key)
	return ok and v ~= false
end

local function Set(key, on)
	ns.Guard(function() DUI:Set(ADDON, key, on and true or false) end)
end

local function Ink(fs, role, alpha)
	local c = ns.Colors()[role]
	if type(c) == "table" then fs:SetTextColor(c[1], c[2], c[3], alpha or 1) end
end

local function Width(fs, text)
	local w = fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth()
	if type(w) ~= "number" or w <= 0 then w = #(text or "") * 7 end
	return math.ceil(w)
end

-- ---------------------------------------------------------------------------------------------
-- Installed or not
-- ---------------------------------------------------------------------------------------------

-- Targets whose addon ships under another folder name too.
local FOLDERS = { ForeverDungeonJournal = { "ForeverDungeonJournal", "ForeverCore" } }

local function Exists(folder)
	local C = _G.C_AddOns
	if C and type(C.DoesAddOnExist) == "function" then
		local ok, yes = pcall(C.DoesAddOnExist, folder)
		if ok then return yes and true or false end
	end
	local info = C and C.GetAddOnInfo or _G.GetAddOnInfo
	if type(info) ~= "function" then return true end
	local ok, name, _, _, _, reason = pcall(info, folder)
	if not ok then return true end
	return name ~= nil and reason ~= "MISSING"
end

local function Installed(addon)
	for _, folder in ipairs(FOLDERS[addon] or { addon }) do
		if Exists(folder) then return true end
	end
	return false
end

-- ---------------------------------------------------------------------------------------------
-- The link box
-- ---------------------------------------------------------------------------------------------

local box
function ns.ShowLink(name, url)
	if not box then
		box = CreateFrame("Frame", "DaylightAddonSkinsLink", UIParent)
		box:SetSize(440, 140)
		box:SetPoint("CENTER", 0, 120)
		box:SetFrameStrata("FULLSCREEN_DIALOG")
		box:SetToplevel(true)
		box:SetClampedToScreen(true)
		box:EnableMouse(true)
		box:SetMovable(true)
		box:RegisterForDrag("LeftButton")
		box:SetScript("OnDragStart", box.StartMoving)
		box:SetScript("OnDragStop", box.StopMovingOrSizing)
		API.Skin(box, { window = true })
		table.insert(UISpecialFrames, "DaylightAddonSkinsLink")
		box.title = API.Text(box, "head", "LEFT")
		box.title:SetPoint("TOPLEFT", PAD, -PAD)
		box.title:SetPoint("RIGHT", box, "RIGHT", -40, 0)
		box.sub = API.Text(box, "body", "LEFT")
		box.sub:SetPoint("TOPLEFT", box.title, "BOTTOMLEFT", 0, -8)
		box.sub:SetPoint("RIGHT", box, "RIGHT", -PAD, 0)
		box.sub:SetText(L["Press Ctrl+C to copy the link, then paste it in your browser."])
		local close = API.Close(box, function() box:Hide() end)
		close:SetPoint("TOPRIGHT", -10, -10)
		box.input = API.Input(box, { height = 28 })
		box.input:SetPoint("BOTTOMLEFT", PAD, PAD)
		box.input:SetPoint("BOTTOMRIGHT", -PAD, PAD)
		box.input:HookScript("OnEscapePressed", function() box:Hide() end)
		box.input:HookScript("OnKeyDown", function(_, key)
			if key == "C" and IsControlKeyDown() then C_Timer.After(0.1, function() box:Hide() end) end
		end)
	end
	box.title:SetText(string.format(L["Get %s"], name))
	Ink(box.title, "VALUE")
	Ink(box.sub, "TEXT")
	local h = PAD + (box.title:GetStringHeight() or 18) + 8 + (box.sub:GetStringHeight() or 14) + 14 + 28 + PAD
	box:SetHeight(math.ceil(h))
	box.input.Lock(url)
	box:Show()
	box.input:SetFocus()
	box.input:HighlightText()
end

-- ---------------------------------------------------------------------------------------------
-- The lists
-- ---------------------------------------------------------------------------------------------

-- The targets that are the game's own windows (shown in the Blizzard grid, or not at all:
-- "Blizzard" is the old switch for every game window, see Windows.lua).
local function GameKeys()
	local keys = { Blizzard = true }
	for _, w in ipairs(ns.BLIZZ) do keys[w.key] = true end
	return keys
end

local function ByLabel(a, b) return a.label:lower() < b.label:lower() end

local function AddonList()
	local game, list = GameKeys(), {}
	for _, addon in ipairs(ns.order) do
		if not game[addon] then
			local have = Installed(addon)
			list[#list + 1] = { key = addon, label = ns.targets[addon], url = not have and ns.LINKS[addon] or nil,
				missing = not have, tip = string.format(L["Dress %s's windows."], ns.targets[addon]) }
		end
	end
	table.sort(list, ByLabel)
	return list
end

local function BlizzardList()
	local list = {}
	for _, w in ipairs(ns.BLIZZ) do
		-- (The two older switches only while their target is there: the dungeon-ready dialog isn't
		-- on every client.)
		if w.id or ns.targets[w.key] then
			list[#list + 1] = { key = w.key, label = w.label,
				tip = L["Dress this game window in the DaylightUI look."] }
		end
	end
	table.sort(list, ByLabel)
	return list
end

-- ---------------------------------------------------------------------------------------------
-- The grid: an options "custom" row
-- ---------------------------------------------------------------------------------------------

local function Tip(owner, title, text)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(title, 1, 1, 1)
	if text then GameTooltip:AddLine(text, nil, nil, nil, true) end
	GameTooltip:AddLine(L["Takes hold after a reload."], 0.6, 0.6, 0.6, true)
	GameTooltip:Show()
end

local function PaintCell(c)
	local on = Get(c.item.key)
	c.switch.SetOn(on)
	Ink(c.name, c.item.missing and "TEXT" or "VALUE", c.item.missing and 0.55 or 1)
	if c.link then
		local r, g, b = API.Accent()
		if c.link.hot then
			c.link.text:SetTextColor(1, 1, 1)
		else
			c.link.text:SetTextColor(r, g, b)
		end
		c.link.line:SetColorTexture(r, g, b, 0.8)
	end
end

local function MakeCell(row, item)
	local c = CreateFrame("Button", nil, row)
	c.item = item
	c:SetHeight(CELL_H)
	c.switch = API.Switch(c)
	c.switch:SetPoint("LEFT", 0, 0)
	local function flip()
		Set(item.key, not Get(item.key))
		PaintCell(c)
	end
	c.switch:SetScript("OnClick", flip)
	c:SetScript("OnClick", function() c.switch:Click() end)
	c.name = API.Text(c, "body", "LEFT")
	c.name:SetPoint("LEFT", c.switch, "RIGHT", GAP, 0)
	c.name:SetWordWrap(false)
	c.name:SetText(item.label)
	c:SetScript("OnEnter", function(self) Tip(self, item.label, item.tip) end)
	c:SetScript("OnLeave", function() GameTooltip:Hide() end)
	c.switch:HookScript("OnEnter", function() Tip(c, item.label, item.tip) end)
	c.switch:HookScript("OnLeave", function() GameTooltip:Hide() end)
	if item.url then
		local link = CreateFrame("Button", nil, c)
		link:SetHeight(CELL_H)
		link:SetPoint("LEFT", c.name, "RIGHT", GAP + 2, 0)
		link.text = API.Text(link, "body", "LEFT")
		link.text:SetPoint("LEFT", 0, 0)
		link.text:SetText(L["Get Addon"])
		link.line = link:CreateTexture(nil, "ARTWORK")
		link.line:SetHeight(1)
		link.line:SetPoint("TOPLEFT", link.text, "BOTTOMLEFT", 0, -2)
		link.line:SetPoint("TOPRIGHT", link.text, "BOTTOMRIGHT", 0, -2)
		link.line:Hide()
		link:SetScript("OnEnter", function(self)
			self.hot = true
			self.line:Show()
			PaintCell(c)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(item.label, 1, 1, 1)
			GameTooltip:AddLine(L["Not installed. Click to copy its CurseForge link."], nil, nil, nil, true)
			GameTooltip:Show()
		end)
		link:SetScript("OnLeave", function(self)
			self.hot = false
			self.line:Hide()
			PaintCell(c)
			GameTooltip:Hide()
		end)
		link:SetScript("OnClick", function() ns.ShowLink(item.label, item.url) end)
		c.link = link
	end
	return c
end

-- The width a cell needs to show everything in it.
local function Need(c)
	local w = c.switch:GetWidth() + GAP + Width(c.name, c.item.label)
	c.name:SetWidth(Width(c.name, c.item.label) + 2)
	if c.link then
		local lw = Width(c.link.text, L["Get Addon"])
		c.link:SetWidth(lw)
		w = w + GAP + 2 + lw
	end
	return w + 18
end

local function HeadButton(row, text, func)
	local b = API.Button(row, text, 24)
	local fs = b.text or (b.GetFontString and b:GetFontString())
	local w = fs and Width(fs, text) or #text * 7
	b:SetSize(math.max(96, w + 28), 24)
	b:SetScript("OnClick", func)
	return b
end

-- kind: "addons" or "blizzard". The options item: one row holding the whole grid.
function ns.SkinGrid(kind)
	local function build(row)
		local list = kind == "addons" and AddonList() or BlizzardList()
		local cells = {}
		row.skinCells = cells
		for i, item in ipairs(list) do cells[i] = MakeCell(row, item) end
		local function all(on)
			for _, c in ipairs(cells) do Set(c.item.key, on) end
			for _, c in ipairs(cells) do PaintCell(c) end
		end
		local on = HeadButton(row, L["Turn all on"], function() all(true) end)
		on:SetPoint("TOPLEFT", PAD, -6)
		local off = HeadButton(row, L["Turn all off"], function() all(false) end)
		off:SetPoint("LEFT", on, "RIGHT", GAP, 0)
		local reload = HeadButton(row, L["Reload interface"], function() ReloadUI() end)
		reload:SetPoint("TOPRIGHT", -PAD, -6)
		for _, c in ipairs(cells) do PaintCell(c) end
	end
	local function height(row)
		local cells = row.skinCells
		if not cells then return TOP_H end
		local avail = (row:GetWidth() or 0) - PAD * 2
		if avail <= 0 then avail = 640 end
		local need = 1
		for _, c in ipairs(cells) do need = math.max(need, Need(c)) end
		local cols = math.max(1, math.min(MAX_COLS, math.floor(avail / need)))
		local w = math.floor(avail / cols)
		for i, c in ipairs(cells) do
			local col, line = (i - 1) % cols, math.floor((i - 1) / cols)
			c:ClearAllPoints()
			c:SetPoint("TOPLEFT", row, "TOPLEFT", PAD + col * w, -(TOP_H + line * CELL_H))
			c:SetWidth(w)
		end
		return TOP_H + math.ceil(#cells / cols) * CELL_H + 6
	end
	local function update(row)
		local cells = row.skinCells
		if not cells then return end
		for _, c in ipairs(cells) do PaintCell(c) end
	end
	return { type = "custom", label = kind == "addons" and L["Addons"] or L["Blizzard"],
		build = build, height = height, update = update }
end

-- ---------------------------------------------------------------------------------------------
-- The Look and Feel page's pick: which addon's (or game window's) look its tabs show, a setting
-- ("lookPick"), so the page shows that one's cards. Picked from each tab's "Applies to" list.
-- ---------------------------------------------------------------------------------------------

ns.LOOK_PICK = "lookPick"

local function Picked(list)
	local ok, v = pcall(API.GetSetting, ADDON, ns.LOOK_PICK)
	if ok and type(v) == "string" and ns.targets[v] then return v end
	return list[1]
end

-- ---------------------------------------------------------------------------------------------
-- Under each Look and Feel tab: the addons its settings reach. Each cell: a Custom Settings switch
-- ("look.<addon>.own") and the addon's name; a click on the name picks it (its settings show in
-- the cards above), the picked one in the accent. Addons A to Z, then the game's windows.
-- ---------------------------------------------------------------------------------------------

function ns.LookList(addons)
	local game = GameKeys()
	local list, tail = {}, {}
	for _, addon in ipairs(addons) do
		local entry = { addon = addon, label = ns.targets[addon], key = "look." .. addon .. ".own" }
		if game[addon] then tail[#tail + 1] = entry else list[#list + 1] = entry end
	end
	table.sort(list, ByLabel)
	table.sort(tail, ByLabel)
	for _, e in ipairs(tail) do list[#list + 1] = e end

	local function Paint(c)
		local ok, v = pcall(API.GetSetting, ADDON, c.entry.key)
		c.switch.SetOn(ok and v == true)
		local picked = Picked({ ns.lookPickDefault })
		if c.entry.addon == picked then
			local r, g, b = API.Accent()
			c.name:SetTextColor(r, g, b)
		elseif c.hot then
			Ink(c.name, "VALUE")
		else
			Ink(c.name, "TEXT")
		end
	end

	local function build(row)
		local cells = {}
		row.listCells = cells
		for i, e in ipairs(list) do
			local c = CreateFrame("Frame", nil, row)
			c.entry = e
			c:SetHeight(CELL_H)
			c.switch = API.Switch(c)
			c.switch:SetPoint("LEFT", 0, 0)
			c.switch:SetScript("OnClick", function()
				local ok, v = pcall(API.GetSetting, ADDON, e.key)
				ns.Guard(function() DUI:Set(ADDON, e.key, not (ok and v == true)) end)
				Paint(c)
			end)
			c.switch:HookScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(string.format(L["Custom Settings for %s"], e.label), 1, 1, 1)
				GameTooltip:AddLine(L["On: this addon uses the settings on this page. Off: it follows DaylightUI."], nil, nil, nil, true)
				GameTooltip:Show()
			end)
			c.switch:HookScript("OnLeave", function() GameTooltip:Hide() end)
			local pick = CreateFrame("Button", nil, c)
			pick:SetHeight(CELL_H)
			pick:SetPoint("LEFT", c.switch, "RIGHT", GAP, 0)
			c.name = API.Text(pick, "body", "LEFT")
			c.name:SetPoint("LEFT", 0, 0)
			c.name:SetWordWrap(false)
			c.name:SetText(e.label)
			c.need = Width(c.name, e.label)
			c.name:SetWidth(c.need + 2)
			pick:SetWidth(c.need + 2)
			pick:SetScript("OnEnter", function() c.hot = true; Paint(c) end)
			pick:SetScript("OnLeave", function() c.hot = false; Paint(c) end)
			pick:SetScript("OnClick", function()
				if DUI.Sound then pcall(DUI.Sound.Play, "click") end
				ns.Guard(function() DUI:Set(ADDON, ns.LOOK_PICK, e.addon) end)
				for _, other in ipairs(cells) do Paint(other) end
			end)
			cells[i] = c
		end
		for _, c in ipairs(cells) do Paint(c) end
	end
	local function height(row)
		local cells = row.listCells
		if not cells then return CELL_H end
		local avail = (row:GetWidth() or 0) - PAD * 2
		if avail <= 0 then avail = 640 end
		local need = 1
		for _, c in ipairs(cells) do need = math.max(need, c.switch:GetWidth() + GAP + c.need + 18) end
		local cols = math.max(1, math.min(MAX_COLS, math.floor(avail / need)))
		local w = math.floor(avail / cols)
		for i, c in ipairs(cells) do
			local col, line = (i - 1) % cols, math.floor((i - 1) / cols)
			c:ClearAllPoints()
			c:SetPoint("TOPLEFT", row, "TOPLEFT", PAD + col * w, -(4 + line * CELL_H))
			c:SetWidth(w - GAP)
		end
		return 4 + math.ceil(#cells / cols) * CELL_H + 6
	end
	local function update(row)
		for _, c in ipairs(row.listCells or {}) do Paint(c) end
	end
	return { type = "custom", label = L["Applies to"], build = build, height = height, update = update }
end

-- ---------------------------------------------------------------------------------------------
-- DaylightUI's own look on the Look and Feel page's General tab: the rows of DaylightUI's General >
-- Appearance page that the skins follow, drawn by DaylightUI from its own row specs and reading and
-- writing DaylightUI's own settings ("general"), so a change here is the change there. A row
-- DaylightUI doesn't have (an older or newer DaylightUI) is left out.
-- ---------------------------------------------------------------------------------------------

local LOOK_ROWS = {
	{ "DaylightUI font", { "font", "textOutline", "textShadow" } },
	{ "DaylightUI accent", { "accent", "accentColor", "gradientBorder" } },
	{ "DaylightUI windows", { "windowAlpha", "windowTint", "windowTintColor", "borderPx", "borderAlpha" } },
}

local function GeneralGet(key) return DUI:Get("general", key) end

-- A copy of one of DaylightUI's rows, on DaylightUI's "general" settings instead of ours.
local function Borrow(item)
	local copy = {}
	for k, v in pairs(item) do copy[k] = v end
	local key = item.key
	copy.key, copy.since = nil, nil
	copy.noSearch = true   -- (found on DaylightUI's own page)
	copy.get = function() return DUI:Get("general", key) end
	copy.set = function(v) DUI:Set("general", key, v) end
	-- (No default: "Reset page" on our page must never reset DaylightUI's own look.)
	-- (Its own rules read DaylightUI's settings, not ours.)
	for _, name in ipairs({ "disabled", "hidden" }) do
		local rule = item[name]
		if type(rule) == "function" then copy[name] = function() return rule(GeneralGet) end end
	end
	return copy
end

function ns.DaylightLookGroups(tab)
	local groups = {}
	local O = DUI.Options
	local ok, page = pcall(function() return O and O.GetPage and O.GetPage("appearance") end)
	if not ok or type(page) ~= "table" or page.scope ~= "general" then return groups end
	local byKey = {}
	for _, g in ipairs(page.groups or {}) do
		for _, item in ipairs(g.items or {}) do
			if type(item.key) == "string" then byKey[item.key] = item end
		end
	end
	for _, spec in ipairs(LOOK_ROWS) do
		local items = {}
		for _, key in ipairs(spec[2]) do
			if byKey[key] then items[#items + 1] = Borrow(byKey[key]) end
		end
		if #items > 0 then
			groups[#groups + 1] = { label = L[spec[1]], tab = tab,
				desc = L["DaylightUI's own settings (General > Appearance): a change here changes them there too."],
				items = items }
		end
	end
	return groups
end
