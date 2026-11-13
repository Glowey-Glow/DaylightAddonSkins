-- The choice window: on first load (and whenever a new conflict turns up), the features your other
-- addons do that DaylightUI already does, each with a switch: on = DaylightUI handles it (the
-- default), off = the addon keeps it. Apply sets them (Core.lua, ns.Choose); Ask me later closes it
-- and it comes back at the next login. Every choice can be changed again on the addon's own page,
-- and "Show the choices again" on the All windows page opens it with all of them.
-- Built from DaylightUI's own widgets (API.Skin, API.Text, API.Switch, API.Button, API.Close).
local ADDON, ns = ...
if not ns.ok then return end

local API = ns.API
local W, PAD, ROW, HEAD = 560, 18, 42, 30
local MAX_H = 520

local frame, content, scroll
local rows = {}       -- the rows on show: { addon, key, switch }
local pool = {}       -- made rows and headings, reused

local function Ink(fs, role)
	local c = ns.Colors()[role]
	if type(c) == "table" then fs:SetTextColor(c[1], c[2], c[3]) end
end

local function Build()
	frame = CreateFrame("Frame", "DaylightAddonSkinsChoices", UIParent)
	frame:SetSize(W, 300)
	frame:SetPoint("CENTER", 0, 60)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()
	API.Skin(frame, { window = true })
	table.insert(UISpecialFrames, "DaylightAddonSkinsChoices")

	local title = API.Text(frame, "title", "LEFT")
	title:SetPoint("TOPLEFT", PAD, -PAD)
	title:SetText("Addon Skins")
	Ink(title, "VALUE")
	frame.title = title

	local sub = API.Text(frame, "body", "LEFT")
	sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	sub:SetWidth(W - PAD * 2)
	sub:SetText("Some of your addons do things DaylightUI already does. Pick who handles each one: "
		.. "on = DaylightUI (the addon's own is switched off), off = the addon keeps it. "
		.. "You can change any of these later: DaylightUI options, Plugins, Addons, each addon's DaylightUI tab.")
	Ink(sub, "TEXT")
	frame.sub = sub

	local close = API.Close(frame, function() frame:Hide() end)
	close:SetPoint("TOPRIGHT", -10, -10)

	scroll = CreateFrame("ScrollFrame", nil, frame)
	scroll:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -14)
	scroll:SetPoint("RIGHT", frame, "RIGHT", -PAD, 0)
	scroll:SetPoint("BOTTOM", frame, "BOTTOM", 0, 58)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local max = math.max(0, (content:GetHeight() or 0) - (self:GetHeight() or 0))
		self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - delta * ROW)))
	end)
	content = CreateFrame("Frame", nil, scroll)
	content:SetSize(W - PAD * 2, 10)
	scroll:SetScrollChild(content)

	local apply = API.Button(frame, "Apply", 26)
	apply:SetSize(150, 26)
	apply:SetPoint("BOTTOMRIGHT", -PAD, PAD)
	apply:SetScript("OnClick", function()
		local reload = false
		for _, r in ipairs(rows) do
			local pick = r.switch.on == true
			ns.Choose(r.addon, r.key, pick)
			if r.reload then reload = true end
		end
		frame:Hide()
		if reload then
			print("|cffa335eeAddon Skins|r: some of these take a /reload to finish (the ones marked so). Type /reload when it suits you.")
		end
	end)

	local later = API.Button(frame, "Ask me later", 26)
	later:SetSize(150, 26)
	later:SetPoint("RIGHT", apply, "LEFT", -10, 0)
	later:SetScript("OnClick", function() frame:Hide() end)
end

local function Piece(kind)
	for _, p in ipairs(pool) do
		if not p.used and p.kind == kind then
			p.used = true
			return p
		end
	end
	local p = CreateFrame("Frame", nil, content)
	p.kind, p.used = kind, true
	if kind == "head" then
		p:SetHeight(HEAD)
		p.text = API.Text(p, "head", "LEFT")
		p.text:SetPoint("BOTTOMLEFT", 0, 6)
		p.line = p:CreateTexture(nil, "ARTWORK")
		p.line:SetHeight(1)
		p.line:SetPoint("BOTTOMLEFT", 0, 0)
		p.line:SetPoint("BOTTOMRIGHT", 0, 0)
	else
		p:SetHeight(ROW)
		p:EnableMouse(true)
		p.name = API.Text(p, "body", "LEFT")
		p.name:SetPoint("TOPLEFT", 4, -6)
		p.what = API.Text(p, "small", "LEFT")
		p.what:SetPoint("TOPLEFT", p.name, "BOTTOMLEFT", 0, -3)
		p.switch = API.Switch(p)
		p.switch:SetPoint("RIGHT", -4, 0)
		p.switch:SetScript("OnClick", function(self) self.SetOn(not self.on) end)
		-- The whole row flips it.
		p:SetScript("OnMouseUp", function(self, button) if button == "LeftButton" then self.switch:Click() end end)
	end
	pool[#pool + 1] = p
	return p
end

-- `all`: every conflict (as picked now); otherwise the new ones. Nothing to ask: nothing shown
-- (with `all`, a line in chat says so).
function ns.ShowChoices(all)
	if InCombatLockdown() then return end
	local list = ns.Conflicts(all)
	if #list == 0 then
		if all then print("|cffa335eeAddon Skins|r: none of your addons does anything DaylightUI is doing now.") end
		return
	end
	if not frame then Build() end
	for _, p in ipairs(pool) do
		p.used = false
		p:Hide()
	end
	wipe(rows)
	local y, last = 0, nil
	local r, g, b = API.Accent()
	for _, c in ipairs(list) do
		if c.addon ~= last then
			last = c.addon
			local h = Piece("head")
			h:ClearAllPoints()
			h:SetPoint("TOPLEFT", 0, -y)
			h:SetPoint("RIGHT", content, "RIGHT", 0, 0)
			h.text:SetText(ns.targets[c.addon] or c.addon)
			Ink(h.text, "LABEL")
			h.line:SetColorTexture(r, g, b, 0.5)
			h:Show()
			y = y + HEAD + 4
		end
		local row = Piece("row")
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, -y)
		row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
		row.name:SetText(c.item.label or c.item.key)
		Ink(row.name, "VALUE")
		row.what:SetText((c.item.daylight and ("DaylightUI: " .. c.item.daylight) or "")
			.. (c.item.reload and "  (takes a /reload)" or ""))
		Ink(row.what, "TEXT")
		row.switch.SetOn(c.daylight)
		row:Show()
		rows[#rows + 1] = { addon = c.addon, key = c.item.key, switch = row.switch, was = c.daylight, reload = c.item.reload }
		y = y + ROW
	end
	content:SetHeight(math.max(10, y))
	scroll:SetVerticalScroll(0)
	local top = PAD + (frame.title:GetStringHeight() or 20) + 8 + (frame.sub:GetStringHeight() or 30) + 14
	frame:SetHeight(math.min(MAX_H, top + y + 58 + 4))
	frame:Show()
end

-- First load, and any login with a conflict not answered yet: a moment after the world shows (the
-- addons' settings are read by then), out of a fight.
ns.me.On("Login", function()
	local tries = 0
	local function ask()
		tries = tries + 1
		if InCombatLockdown() then
			if tries < 30 then C_Timer.After(5, ask) end
			return
		end
		ns.ShowChoices(false)
	end
	C_Timer.After(6, ask)
end)
