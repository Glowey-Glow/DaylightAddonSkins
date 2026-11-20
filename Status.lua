-- Status: where each addon this plugin can dress stands, and why one isn't dressed. Every target
-- (ns.Target), every addon with a CurseForge link (ns.LINKS) and every addon the Auto Skinner
-- found, as Active / Switched Off / Not Installed / Not Enabled on This Character / Load on
-- Demand, Not Loaded Yet / Error (Core.lua's ns.TargetState). Shown three ways:
--   /skins status          in chat (the ones not installed counted, not listed)
--   /skins report          a plain-text report in the copy box (Grid.lua's ns.ShowCopy): the
--                          game's build, this plugin's and Daylight UI's versions, each addon's
--                          version and state, and any error's first line
--   All Windows > Status   a card with the same list, Copy Report and Retry Broken Skins
-- And /skins retry [addon] (a pack off after an error, tried again after a reload), /skins test
-- <addon> (its pack fails once on purpose at the next reload: to see the error path work).
-- Read only when asked: nothing runs while idle.
local _, ns = ...
if not ns.ok then return end

local API, L = ns.API, ns.L

local PAD, GAP, LINE, TOP_H = 16, 12, 22, 36
local CHAT = "|cffa335eeAddon Skins|r: "

-- ---------------------------------------------------------------------------------------------
-- The list
-- ---------------------------------------------------------------------------------------------

local function ByLabel(a, b) return a.label:lower() < b.label:lower() end

-- { key, label, folder (Auto Skinner's), auto }: addons A to Z, then the game's windows.
local function Entries()
	local list, game, seen = {}, {}, {}
	for _, key in ipairs(ns.order) do
		if ns.targets[key] and not seen[key] then
			seen[key] = true
			local e = { key = key, label = ns.targets[key] }
			if ns.IsGameTarget(key) then game[#game + 1] = e else list[#list + 1] = e end
		end
	end
	for key in pairs(ns.LINKS or {}) do
		if not seen[key] then
			seen[key] = true
			list[#list + 1] = { key = key, label = key }
		end
	end
	for _, a in ipairs(ns.AutoAddons and ns.AutoAddons() or {}) do
		list[#list + 1] = { key = ns.AutoKey(a.folder), folder = a.folder, auto = true,
			label = string.format(L["%s (Auto Skinner)"], a.label) }
	end
	table.sort(list, ByLabel)
	table.sort(game, ByLabel)
	for _, e in ipairs(game) do list[#list + 1] = e end
	return list
end

local function State(e)
	if e.auto then
		return (ns.Enabled() and ns.Setting(e.key) == true) and "active" or "off"
	end
	return ns.TargetState(e.key)
end

local function Version(e)
	if e.auto then return ns.Meta(e.folder, "Version") or "?" end
	return ns.TargetVersion(e.key)
end

local function StateText(state, detail)
	if state == "active" then return L["Active"] end
	if state == "off" then return L["Switched Off"] end
	if state == "missing" then return L["Not Installed"] end
	if state == "disabled" then return L["Not Enabled on This Character"] end
	if state == "lod" then return L["Load on Demand, Not Loaded Yet"] end
	if state == "error" then return L["Error"] end
	if type(detail) == "string" then return string.format(L["Not Loaded: %s"], detail) end
	return L["Not Loaded"]
end

-- The ink each state's word is drawn in (ns.Colors' roles).
local INK = { active = "GOOD", error = "WARN", notloaded = "WARN", off = "TEXT", missing = "OFF",
	disabled = "LABEL", lod = "LABEL" }

local function Hex(role)
	local c = ns.Colors()[role]
	if type(c) ~= "table" then return "" end
	return string.format("|cff%02x%02x%02x", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

-- ---------------------------------------------------------------------------------------------
-- The report (plain text, to paste into a bug report)
-- ---------------------------------------------------------------------------------------------

-- What Daylight UI 2.0 brought that the packs follow or stand down for, as it is set now: the
-- tooltip look (API.TooltipStyle, API 1.12: 2.0 API.lua:820-825) and border (ns.TipBorder), which
-- window the Auction House opens in (DaylightUI.ahMogul, 2.0
-- DaylightUI_AuctionHouse\Module.lua:17-18; its "enabled", Options.lua:10) and its own loot roll
-- cards (Skins rolls.enabled, 2.0 DaylightUI_Skins\Defaults.lua:25). Nothing on 1.9.x.
local function Daylight2Lines(lines)
	if not ns.DaylightAtLeast(2, 0) then return end
	local style = type(API.TooltipStyle) == "function" and API.TooltipStyle() or nil
	lines[#lines + 1] = string.format(L["Tooltip Look: %s"],
		style == "rich" and L["Rich"] or style == "simple" and L["Simple"] or L["Off"])
	if style then
		local own = ns.TipBorder()
		local ok, general = pcall(API.GetSetting, "general", "borderPx")
		if own then
			lines[#lines + 1] = string.format(L["Tooltip Border: %s"], string.format(L["%d px (the Tooltips' Own)"], own))
		elseif ok and type(general) == "number" then
			lines[#lines + 1] = string.format(L["Tooltip Border: %s"], string.format(L["%d px (General's)"], general))
		end
	end
	local D = _G.DaylightUI
	local auction
	if type(D) == "table" and D.ahMogul == true then
		auction = L["DaylightMogul's Window"]
	elseif not ns.ModuleOn("AuctionHouse") then
		auction = L["Off"]
	elseif ns.DaylightHas("AuctionHouse", "enabled") then
		auction = L["Its Own Window"]
	else
		auction = L["The Game's Window"]
	end
	lines[#lines + 1] = string.format(L["Daylight UI's Auction House: %s"], auction)
	lines[#lines + 1] = string.format(L["Daylight UI's Loot Rolls: %s"],
		(ns.ModuleOn("Skins") and ns.DaylightHas("Skins", "rolls.enabled")) and L["On"] or L["Off"])
end

function ns.StatusReport()
	local locale = GetLocale and GetLocale() or "?"
	local lines = {
		L["Addon Skins Status Report"],
		string.format(L["Game: %s"], ns.GameVersion() .. ", " .. locale),
		string.format(L["Addon Skins: %s"], ns.OurVersion()),
		string.format(L["Daylight UI: %s"], ns.Meta("DaylightUI", "Version") or "?"),
		string.format(L["Window Skins: %s"], ns.ModuleOn("Skins") and L["On"] or L["Off"]),
	}
	ns.Guard(Daylight2Lines, lines)
	lines[#lines + 1] = ""
	for _, e in ipairs(Entries()) do
		local state, detail = State(e)
		lines[#lines + 1] = string.format(L["%s, version %s: %s"], e.label, Version(e), StateText(state, detail))
		local rec = not e.auto and ns.Failed(e.key)
		if rec then
			lines[#lines + 1] = "    " .. string.format(L["Error: %s"], rec.err)
			lines[#lines + 1] = "    " .. string.format(L["Recorded with Addon Skins %s and %s %s."], tostring(rec.ours),
				e.label, tostring(rec.target))
		end
	end
	return table.concat(lines, "\n")
end

function ns.ShowReport()
	ns.ShowCopy(L["Addon Skins Report"], L["Press Ctrl+C to copy the report, then paste it where you ask for help."],
		ns.StatusReport(), true)
end

-- ---------------------------------------------------------------------------------------------
-- /skins
-- ---------------------------------------------------------------------------------------------

local function Say(text) print(CHAT .. text) end

local function ChatStatus()
	Say(string.format(L["Addon Skins %s on Daylight UI %s."], ns.OurVersion(), ns.Meta("DaylightUI", "Version") or "?"))
	local missing = 0
	for _, e in ipairs(Entries()) do
		local state, detail = State(e)
		if state == "missing" then
			missing = missing + 1
		else
			print("  " .. string.format(L["%s, version %s: %s"], e.label, Version(e),
				Hex(INK[state] or "TEXT") .. StateText(state, detail) .. "|r"))
			local rec = state == "error" and ns.Failed(e.key)
			if rec then print("    " .. Hex("WARN") .. rec.err .. "|r " .. ns.RetryWhen(e.key)) end
		end
	end
	if missing > 0 then print("  " .. string.format(L["%d more not installed."], missing)) end
	print("  " .. L["/skins report opens the full report to copy."])
end

-- The target a word names: its key or its name, any case.
local function Find(word)
	if type(word) ~= "string" or word == "" then return nil end
	local want = word:lower()
	for key, label in pairs(ns.targets) do
		if key:lower() == want or label:lower() == want then return key end
	end
	return nil
end

local function Help()
	Say(L["/skins status: what's dressed, and why not."])
	print("  " .. L["/skins report: a report to copy when you ask for help."])
	print("  " .. L["/skins retry [addon]: try skins that hit an error again (after a reload)."])
	print("  " .. L["/skins test <addon>: make a skin fail once at the next reload, to test this."])
end

local repaint                                      -- (the status card's, once built)

local function RetryAll()
	if ns.RetryAll() then
		Say(L["Every skin that hit an error will be tried again after a reload."])
	else
		Say(L["No skin is off after an error."])
	end
	if repaint then repaint() end
end

_G.SLASH_DAYLIGHTSKINS1 = "/skins"
SlashCmdList.DAYLIGHTSKINS = function(msg)
	local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
	cmd = (cmd or ""):lower()
	if cmd == "" or cmd == "status" then
		ChatStatus()
	elseif cmd == "report" then
		ns.ShowReport()
	elseif cmd == "retry" then
		if rest == "" then
			RetryAll()
			return
		end
		local key = Find(rest)
		if not key then
			Say(string.format(L["No addon called %s here. /skins status lists them."], rest))
		elseif ns.Retry(key) then
			Say(string.format(L["%s will be dressed again after a reload."], ns.targets[key]))
		else
			Say(string.format(L["%s isn't off after an error."], ns.targets[key]))
		end
	elseif cmd == "test" then
		local key = Find(rest)
		if not key then
			if rest == "" then Help() else Say(string.format(L["No addon called %s here. /skins status lists them."], rest)) end
			return
		end
		ns.TestFail(key)
		Say(string.format(L["After a reload, %s's skin will fail once on purpose. /skins retry %s undoes it."], ns.targets[key], key))
	else
		Help()
	end
end

-- ---------------------------------------------------------------------------------------------
-- The card on All Windows: Copy Report, Retry Broken Skins, Reload Interface, then the list
-- (name, version, state; an error's line under it).
-- ---------------------------------------------------------------------------------------------

local function Ink(fs, role, alpha)
	local c = ns.Colors()[role]
	if type(c) == "table" then fs:SetTextColor(c[1], c[2], c[3], alpha or 1) end
end

local function Width(fs)
	local w = fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth()
	if type(w) ~= "number" or w <= 0 then w = #(fs:GetText() or "") * 7 end
	return math.ceil(w)
end

local function HeadButton(row, text, func, tip)
	local b = API.Button(row, text, 24)
	local fs = b.text or (b.GetFontString and b:GetFontString())
	local w = fs and Width(fs) or #text * 7
	b:SetSize(math.max(96, w + 28), 24)
	b:SetScript("OnClick", func)
	if tip then
		b:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(text, 1, 1, 1)
			GameTooltip:AddLine(tip, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		b:HookScript("OnLeave", function() GameTooltip:Hide() end)
	end
	return b
end

local function PaintLine(ln)
	local state, detail = State(ln.entry)
	ln.version:SetText(Version(ln.entry))
	ln.state:SetText(StateText(state, detail))
	Ink(ln.name, state == "missing" and "TEXT" or "VALUE", state == "missing" and 0.55 or 1)
	Ink(ln.version, "TEXT", 0.7)
	Ink(ln.state, INK[state] or "TEXT")
	local rec = state == "error" and ns.Failed(ln.entry.key)
	if rec then
		ln.err:SetText(rec.err .. " " .. ns.RetryWhen(ln.entry.key))
		Ink(ln.err, "WARN")
		ln.err:Show()
	else
		ln.err:SetText("")
		ln.err:Hide()
	end
end

local statusRows = setmetatable({}, { __mode = "k" })
repaint = function()
	for row in pairs(statusRows) do
		for _, ln in ipairs(row.statusLines or {}) do PaintLine(ln) end
	end
end
ns.OnStatusChange(repaint)

function ns.StatusList()
	local function build(row)
		statusRows[row] = true
		local copy = HeadButton(row, L["Copy Report"], function() ns.ShowReport() end,
			L["A plain-text report of every addon's version and state, to paste when you ask for help."])
		copy:SetPoint("TOPLEFT", PAD, -6)
		local retry = HeadButton(row, L["Retry Broken Skins"], RetryAll,
			L["Skins that hit an error are tried again after a reload."])
		retry:SetPoint("LEFT", copy, "RIGHT", GAP - 4, 0)
		local reload = HeadButton(row, L["Reload Interface"], function() ReloadUI() end)
		reload:SetPoint("TOPRIGHT", -PAD, -6)
		local lines = {}
		row.statusLines = lines
		for i, e in ipairs(Entries()) do
			local ln = { entry = e }
			ln.name = API.Text(row, "body", "LEFT")
			ln.name:SetWordWrap(false)
			ln.name:SetText(e.label)
			ln.version = API.Text(row, "body", "LEFT")
			ln.version:SetWordWrap(false)
			ln.state = API.Text(row, "body", "LEFT")
			ln.state:SetWordWrap(true)
			ln.err = API.Text(row, "small", "LEFT")
			ln.err:SetWordWrap(true)
			lines[i] = ln
		end
		for _, ln in ipairs(lines) do PaintLine(ln) end
	end
	local function height(row)
		local lines = row.statusLines
		if not lines then return TOP_H end
		for _, ln in ipairs(lines) do PaintLine(ln) end
		local avail = (row:GetWidth() or 0) - PAD * 2
		if avail <= 0 then avail = 640 end
		-- Three columns as wide as their longest text; the state wraps if the card is narrow.
		local nameW, verW = 1, 1
		for _, ln in ipairs(lines) do
			nameW = math.max(nameW, Width(ln.name))
			verW = math.max(verW, Width(ln.version))
		end
		local verX = nameW + GAP
		local stateX = verX + verW + GAP
		local stateW = math.max(120, avail - stateX)
		local y = TOP_H
		for _, ln in ipairs(lines) do
			ln.name:ClearAllPoints()
			ln.name:SetPoint("TOPLEFT", row, "TOPLEFT", PAD, -(y + 4))
			ln.name:SetWidth(nameW + 2)
			ln.version:ClearAllPoints()
			ln.version:SetPoint("TOPLEFT", row, "TOPLEFT", PAD + verX, -(y + 4))
			ln.version:SetWidth(verW + 2)
			ln.state:ClearAllPoints()
			ln.state:SetPoint("TOPLEFT", row, "TOPLEFT", PAD + stateX, -(y + 4))
			ln.state:SetWidth(stateW)
			local h = math.max(LINE, math.ceil(ln.state:GetStringHeight() or 14) + 8)
			if ln.err:IsShown() then
				ln.err:ClearAllPoints()
				ln.err:SetPoint("TOPLEFT", row, "TOPLEFT", PAD + 12, -(y + h))
				ln.err:SetWidth(avail - 12)
				h = h + math.ceil(ln.err:GetStringHeight() or 12) + 6
			end
			y = y + h
		end
		return y + 6
	end
	local function update(row)
		for _, ln in ipairs(row.statusLines or {}) do PaintLine(ln) end
	end
	return { type = "custom", label = L["Status"], build = build, height = height, update = update }
end

-- The card, for the first options page (Options.lua).
function ns.StatusGroup()
	return { label = L["Status"], wide = true,
		desc = L["Where each addon stands, and why one isn't dressed. Copy the report when you ask for help."],
		items = { ns.StatusList() } }
end
