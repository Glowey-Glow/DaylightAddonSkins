-- The choice window: on first load (and whenever a new conflict turns up), the features your other
-- addons do that DaylightUI already does, each with a switch: on = the addon keeps its own, off =
-- DaylightUI handles it (the default; the addon's own is switched off). Apply sets them (Core.lua, ns.Choose); Ask me later closes it
-- and it comes back at the next login. Every choice can be changed again on Look and Feel (the addon picked),
-- and "Show the choices again" on the All windows page opens it with all of them.
-- Built from DaylightUI's own widgets (API.Skin, API.Text, API.Switch, API.Button, API.Close).
local _, ns = ...
if not ns.ok then return end

local API = ns.API
local L = ns.L
local W, PAD, ROW, HEAD = 560, 18, 42, 30
local MAX_H = 520

local frame, content, scroll
local rows = {}       -- the rows on show: { addon, key, switch }
local pool = {}       -- made rows and headings, reused

-- ---------------------------------------------------------------------------------------------
-- One thing at a time
-- ---------------------------------------------------------------------------------------------
-- Daylight UI's own first-run and question windows. The choice window opened by itself (at login)
-- waits while one of them is up, so it never lands on top of one:
--   DaylightUIInstaller      the setup guide, the plugins' setup pages, and from 2.0 the "Welcome
--                            to Daylight UI 2.0" slides, which open 2 s after login in this same
--                            window (2.0 Welcome.lua:22, 526-544, 556-561; InstallerUI.lua:243;
--                            1.9.6 InstallerUI.lua:238)
--   DaylightUITour           the tour (2.0 and 1.9.6 Tour.lua:42)
--   DaylightUITourAsk        "Take the tour?" (2.0 and 1.9.6 Tour.lua:43)
--   DaylightUIAsk            every yes / no question of Daylight UI's: from 2.0 the portrait
--                            question 3 s after login (2.0 DaylightUI_UnitFrames\Socket.lua:
--                            399-451), a reload or profile question, the action bar effects
--                            question (2.0 Options\Widgets.lua:4384; 1.9.6 Options\Widgets.lua:4178)
--   DaylightUIQuestieChoice  "Which quest tracker?" with Questie, 3 s after login (2.0 and 1.9.6
--                            DaylightUI_Quests\Choice.lua:14-16)
-- Looked up by name each time (a window not made yet is nil) and counted only while shown and not
-- faded out, as the guides of Glowey's other plugins do (their Guide.lua, DaylightBusy). No gate:
-- the names are the same on 1.9.x.
local DAYLIGHT_DIALOGS = { "DaylightUIInstaller", "DaylightUITour", "DaylightUITourAsk", "DaylightUIAsk",
	"DaylightUIQuestieChoice" }
-- The flag the Daylight plugins' guides share (_G.DaylightGuides: name -> busy): another plugin's
-- welcome, tour or note is up while a key of theirs is set; ours is set while this window shows,
-- so theirs wait for it.
local GUIDE_KEY = "DaylightAddonSkins"

local function SetBusy(on)
	local busy = _G.DaylightGuides
	if type(busy) ~= "table" then
		if not on then return end
		busy = {}
		_G.DaylightGuides = busy
	end
	busy[GUIDE_KEY] = on and true or nil
end

local function DaylightBusy()
	for _, name in ipairs(DAYLIGHT_DIALOGS) do
		local f = _G[name]
		if type(f) == "table" and f.IsShown and f:IsShown() and (f:GetAlpha() or 0) > 0.05 then return true end
	end
	local busy = _G.DaylightGuides
	if type(busy) == "table" then
		for name, on in pairs(busy) do
			if on and name ~= GUIDE_KEY then return true end
		end
	end
	return false
end

-- (Core.lua: painted again whenever the look changes.)
local Ink = ns.Ink

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
	-- (Up: the other Daylight plugins' guides wait.)
	frame:HookScript("OnShow", function() SetBusy(true) end)
	frame:HookScript("OnHide", function() SetBusy(false) end)
	-- Escape, sounds, fade and the controller (Core.lua ns.Window; the name is Escape's fallback),
	-- at Daylight UI's global scale.
	ns.Window(frame, "DaylightAddonSkinsChoices", 6)
	ns.Scaled(frame, 1)

	local title = API.Text(frame, "title", "LEFT")
	title:SetPoint("TOPLEFT", PAD, -PAD)
	title:SetText("Addon Skins")
	Ink(title, "VALUE")
	frame.title = title

	local sub = API.Text(frame, "body", "LEFT")
	sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	sub:SetWidth(W - PAD * 2)
	sub:SetText(string.format(L["Some of your addons do things Daylight UI already does. Pick who handles each one: on = the addon keeps its own, off = Daylight UI handles it (the addon's own is switched off). You can change any of these later in Daylight UI options: %s > %s > %s, with the addon picked."],
		ns.Module("Plugins"), L["Addons"], L["Look and Feel"]))
	Ink(sub, "TEXT")
	frame.sub = sub

	local close = API.Close(frame, function() ns.CloseWindow(frame) end)
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

	-- Apply is the window's main action, as DaylightUI lays out its own (Accept, Send...): in the
	-- left corner with its main-button look (DaylightUI 1.8), Ask me later in the right corner.
	local apply = API.Button(frame, L["Apply"], 26)
	apply:SetSize(150, 26)
	apply:SetPoint("BOTTOMLEFT", PAD, PAD)
	if type(API.MainButton) == "function" then pcall(API.MainButton, apply, true) end
	apply:SetScript("OnClick", function()
		local reload = false
		for _, r in ipairs(rows) do
			-- (The switch shows the addon's own: on = the addon keeps it, off = Daylight UI's.)
			ns.Choose(r.addon, r.key, r.switch.on ~= true)
			if r.reload then reload = true end
		end
		ns.CloseWindow(frame)
		if reload then
			print("|cffa335eeAddon Skins|r: " .. L["some of these take a /reload to finish (the ones marked so). Type /reload when it suits you."])
		end
	end)

	local later = API.Button(frame, L["Ask Me Later"], 26)
	later:SetSize(150, 26)
	later:SetPoint("BOTTOMRIGHT", -PAD, PAD)
	later:SetScript("OnClick", function() ns.CloseWindow(frame) end)
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
		if all then print("|cffa335eeAddon Skins|r: " .. L["none of your addons does anything Daylight UI is doing now."]) end
		return
	end
	if not frame then Build() end
	for _, p in ipairs(pool) do
		p.used = false
		p:Hide()
	end
	wipe(rows)
	local y, last = 0, nil
	for _, c in ipairs(list) do
		if c.addon ~= last then
			last = c.addon
			local h = Piece("head")
			h:ClearAllPoints()
			h:SetPoint("TOPLEFT", 0, -y)
			h:SetPoint("RIGHT", content, "RIGHT", 0, 0)
			h.text:SetText(ns.targets[c.addon] or c.addon)
			Ink(h.text, "LABEL")
			ns.Tint(h.line, "pop", 0.5)
			h:Show()
			y = y + HEAD + 4
		end
		local row = Piece("row")
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, -y)
		row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
		row.name:SetText(c.item.label or c.item.key)
		Ink(row.name, "VALUE")
		local what = ""
		if c.item.daylight and c.item.reload then
			what = string.format(L["Daylight UI: %s  (takes a /reload)"], c.item.daylight)
		elseif c.item.daylight then
			what = string.format(L["Daylight UI: %s"], c.item.daylight)
		elseif c.item.reload then
			what = "  " .. L["(takes a /reload)"]
		end
		row.what:SetText(what)
		Ink(row.what, "TEXT")
		row.switch.SetOn(not c.daylight)
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
-- addons' settings are read by then), out of a fight, and never on top of a window of Daylight
-- UI's own or of another Daylight plugin's guide (DaylightBusy, above). Nothing to ask: nothing
-- waits. Otherwise it looks again every few seconds for as long as it takes (a handful of
-- lookups a time), so the window still comes in this session once the screen is free; a session
-- that ends first leaves the conflicts unanswered, and they are asked at the next login.
-- After any wait the screen must stay free for QUIET seconds first: Daylight UI's welcome looks
-- again every 5 s while its window is busy with something else (2.0 Welcome.lua:23, 546-554) and
-- its portrait question every 3 s behind the tour's question (2.0 Socket.lua:417-423), so the
-- next one of those gets to open before this does.
local FIRST, AGAIN, QUIET = 6, 3, 6
ns.me.On("Login", function()
	local waited, freeSince, any = false, nil, nil
	local function ask()
		-- (Opened by hand meanwhile: the player is at it.)
		if frame and ns.WindowShown(frame) then return end
		-- (Read once here; ns.ShowChoices reads them again as it opens.)
		if any == nil then any = #ns.Conflicts(false) > 0 end
		if not any then return end
		if InCombatLockdown() or DaylightBusy() then
			waited, freeSince = true, nil
			C_Timer.After(AGAIN, ask)
			return
		end
		if waited then
			local now = GetTime()
			freeSince = freeSince or now
			if now - freeSince < QUIET then
				C_Timer.After(AGAIN, ask)
				return
			end
		end
		ns.ShowChoices(false)
	end
	C_Timer.After(FIRST, ask)
end)
