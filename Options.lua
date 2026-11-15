-- This plugin's pages in DaylightUI's options, under the Plugins heading in the list on the left.
-- "All windows": the switch that keeps every window on DaylightUI's own settings, and one switch
-- per addon. Then a page per addon with what can be set for its windows alone (ns.Target's caps):
-- its text, its window shell, its controls. Each addon page opens with its own switch, "Use my own
-- settings": off, the page's rows are set aside and the addon follows DaylightUI (or the switch for
-- all windows); on, the rows are the addon's look.
local _, ns = ...
if not ns.ok then return end

local L = ns.L
local FOLLOW = "followDaylight"

-- Whether an addon's page is set aside: its own switch is off and the all-windows switch is on.
local function followingFor(addon)
	local own = "look." .. addon .. ".own"
	return function(get)
		if get(own) == true then return false end
		return get(FOLLOW) ~= false
	end
end

-- Fonts: DaylightUI's, the addon's own, and every font shared through LibSharedMedia. Fonts that
-- other addons share after this file has run are added at login, into the same table.
local fonts = { daylight = L["DaylightUI font"], addon = L["The addon's own font"] }
local function gatherFonts()
	local LSM = ns.LSM
	if not LSM then return end
	local ok, list = pcall(LSM.List, LSM, "font")
	if not ok or type(list) ~= "table" then return end
	for _, name in ipairs(list) do
		if type(name) == "string" and fonts[name] == nil then fonts[name] = name end
	end
end
gatherFonts()
local late = CreateFrame("Frame")
late:RegisterEvent("PLAYER_LOGIN")
late:SetScript("OnEvent", gatherFonts)

-- The accents an addon's page can pick: DaylightUI's own Accent choices, its gradients included.
local ACCENTS = { daylight = L["DaylightUI's accent"], gradient = L["Daylight gradient"], class = L["Class color"],
	classGradient = L["Class gradient"], custom = L["Custom color"] }
local ACCENT_ORDER = { "daylight", "gradient", "class", "classGradient", "custom" }

local OUTLINES = { keep = L["As the addon has it"], none = L["None"], thin = L["Thin"], thick = L["Thick"] }

-- The switch at the top of each tab of an addon's page: the addon's own settings, or DaylightUI's.
local function hintFor(addon)
	return function()
		return { type = "toggle", key = "look." .. addon .. ".own", label = string.format(L["Use my own settings for %s"], ns.targets[addon]),
			desc = string.format(L["On: the settings on this page are used for %s. Off: it goes by the \"%s\" switch on the %s page (your choices here are kept)."],
				ns.targets[addon], L["Use DaylightUI's settings for all windows"], L["All windows"]) }
	end
end

local function textGroups(addon, caps, tab)
	local at = "look." .. addon .. "."
	local following, hint = followingFor(addon), hintFor(addon)
	local items = {
		hint(),
		{ type = "dropdown", key = at .. "font", label = L["Font"], values = fonts,
		  desc = L["The font of this addon's text."], disabled = following },
		{ type = "dropdown", key = at .. "outline", label = L["Text outline"], values = OUTLINES,
		  desc = L["The outline round this addon's text."], disabled = following },
	}
	if caps.shadow then
		items[#items + 1] = { type = "toggle", key = at .. "shadow", label = L["Text shadow"],
			desc = L["A soft shadow under this addon's text."], disabled = following }
	end
	items[#items + 1] = { type = "slider", key = at .. "size", label = L["Text size"], min = 0.8, max = 1.4, step = 0.05, unit = "%",
		desc = L["How big this addon's text is, next to the size the addon gave it."], disabled = following }
	local groups = { { label = L["Font"], tab = tab, items = items } }
	if caps.colors then
		groups[#groups + 1] = { label = L["Text colors"], tab = tab, items = {
			{ type = "toggle", key = at .. "daylightColors", label = L["Use DaylightUI's text colors"],
			  desc = L["Off: the addon keeps its own text colors."], disabled = following },
		} }
		groups[#groups + 1] = { label = L["Accent"], tab = tab, items = {
			{ type = "dropdown", key = at .. "accentMode", label = L["Accent"], values = ACCENTS, order = ACCENT_ORDER,
			  desc = L["This addon's accent: DaylightUI's own (a gradient one included), or one for this addon alone."],
			  disabled = following },
			{ type = "color", key = at .. "accent", label = L["Accent color"],
			  desc = L["This addon's accent: its highlights, marks and arrow."],
			  disabled = function(get) return following(get) or get(at .. "accentMode") ~= "custom" end },
		} }
	end
	return groups
end

local function lookGroups(addon, caps, tab, lead)
	local at = "look." .. addon .. "."
	local following, hint = followingFor(addon), hintFor(addon)
	local groups = {}
	if caps.window then
		local items = {}
		if lead then items[#items + 1] = hint() end
		lead = false
		items[#items + 1] = { type = "toggle", key = at .. "ownOpacity", label = L["Use my own background opacity"],
			desc = L["Off: these windows follow DaylightUI's window background opacity."], disabled = following }
		items[#items + 1] = { type = "slider", key = at .. "opacity", label = L["Background opacity"], min = 0, max = 1, step = 0.05, unit = "%",
			desc = L["How solid the background of this addon's windows is."],
			disabled = function(get) return following(get) or get(at .. "ownOpacity") ~= true end }
		groups[#groups + 1] = { label = L["Window background"], tab = tab, items = items }
		groups[#groups + 1] = { label = L["Window border"], tab = tab, items = {
			{ type = "toggle", key = at .. "border", label = L["Border"],
			  desc = L["The border round this addon's windows."], disabled = following },
			{ type = "toggle", key = at .. "ownBorder", label = L["Use my own border size"],
			  desc = L["Off: the border is the size set in DaylightUI."],
			  disabled = function(get) return following(get) or get(at .. "border") == false end },
			{ type = "slider", key = at .. "borderPx", label = L["Border size"], min = 1, max = 16, step = 1, unit = "px",
			  desc = L["How thick the border is."],
			  disabled = function(get) return following(get) or get(at .. "border") == false or get(at .. "ownBorder") ~= true end },
			{ type = "toggle", key = at .. "gradientBorder", label = L["Gradient window borders"],
			  desc = L["When this addon's accent is a gradient (Daylight's or your class's), its window borders run along it."],
			  disabled = function(get) return following(get) or get(at .. "border") == false end },
			{ type = "toggle", key = at .. "bevel", label = L["Bevel"],
			  desc = L["The soft light along the top of this addon's windows."], disabled = following },
		} }
	end
	if caps.controls then
		local items = {}
		if lead then items[#items + 1] = hint() end
		items[#items + 1] = { type = "toggle", key = at .. "controls", label = L["Dress buttons, boxes and scroll bars"],
			desc = L["Off: only the windows are dressed and their controls stay as the addon drew them. Takes hold after a reload."],
			disabled = following }
		groups[#groups + 1] = { label = L["Controls"], tab = tab, items = items }
	end
	return groups
end

local function addonPage(addon)
	local caps = ns.caps[addon] or {}
	local label = ns.targets[addon]
	local hasText, hasLook = caps.text, caps.window or caps.controls
	if not hasText and not hasLook then return nil end
	local tabs = hasText and hasLook
	local groups = {}
	if hasText then
		for _, g in ipairs(textGroups(addon, caps, tabs and L["Text styling"] or nil)) do groups[#groups + 1] = g end
	end
	if hasLook then
		for _, g in ipairs(lookGroups(addon, caps, tabs and L["Appearance"] or nil, tabs or not hasText)) do groups[#groups + 1] = g end
	end
	-- The pack's own settings, on a tab of their own.
	if type(caps.extra) == "function" then
		local ok, extra = pcall(caps.extra, "look." .. addon .. ".", followingFor(addon), hintFor(addon))
		if ok and type(extra) == "table" then
			local tab = tabs and (caps.extraTab or label) or nil
			for _, g in ipairs(extra) do
				g.tab = tab
				groups[#groups + 1] = g
			end
		end
	end
	return { id = addon, label = label,
		desc = string.format(L["How %s's windows look in DaylightUI. Windows follow at once; text and controls after a reload."], label),
		groups = groups }
end

local switches = {}
for _, addon in ipairs(ns.order) do
	switches[#switches + 1] = {
		type = "toggle", key = addon, label = ns.targets[addon], default = true,
		desc = string.format(L["Dress %s's windows."], ns.targets[addon]),
	}
end
switches[#switches + 1] = { type = "button", label = L["Reload interface"], func = function() ReloadUI() end }

local pages = {
	{ id = "addons", label = L["All windows"],
	  desc = L["Dress your other addons' windows in the DaylightUI look. Reload the interface after turning an addon on or off."],
	  groups = {
		{ label = L["DaylightUI's look"], items = {
			{ type = "toggle", key = FOLLOW, label = L["Use DaylightUI's settings for all windows"],
			  desc = L["On: every addon's windows follow your DaylightUI font, colors, accent and window opacity, except an addon whose own page has \"Use my own settings\" on."] },
		} },
		{ label = L["Addon windows"], items = switches },
		{ label = L["DaylightUI Override"],
		  desc = L["When your addons do something DaylightUI already does, DaylightUI handles it unless you picked the addon. Each addon's own DaylightUI tab has a switch per feature and a button to give everything back."],
		  items = {
			-- The button alone, centered under the text: no name of its own (it would only say the
			-- button's words again); the button's words are its text.
			{ type = "button", label = "", text = L["Show the choices again"],
			  desc = L["Opens the window from your first login, with every feature and your current picks."],
			  func = function() if ns.ShowChoices then ns.ShowChoices(true) end end,
			  built = function(b, row)
				local function centre()
					b:ClearAllPoints()
					b:SetPoint("CENTER", row, "CENTER", 0, 0)
				end
				-- (After the row has put its control on the right.)
				C_Timer.After(0, centre)
				row:HookScript("OnShow", function() C_Timer.After(0, centre) end)
			  end },
		} },
	  } },
}
for _, addon in ipairs(ns.order) do
	local page = addonPage(addon)
	if page then pages[#pages + 1] = page end
end

ns.RegisterSettings(pages)
