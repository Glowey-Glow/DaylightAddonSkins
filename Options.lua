-- This plugin's pages in DaylightUI's options, under the Plugins heading in the list on the left.
-- "All windows": the skin switches (Grid.lua), Addons and Blizzard. "Look and Feel": the switch that
-- keeps every window on DaylightUI's own settings, a picker, and the picked addon's settings (what
-- can be set for its windows alone, ns.Target's caps: its text, its window shell, its controls).
-- Each addon's settings open with its own switch, "Custom Settings": off, its rows are set
-- aside and the addon follows DaylightUI (or the switch for all windows); on, the rows are its look.
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
local fonts = { daylight = L["DaylightUI font"], addon = L["Addon's font"] }
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
local ACCENTS = { daylight = L["DaylightUI accent"], gradient = L["Daylight gradient"], class = L["Class color"],
	classGradient = L["Class gradient"], custom = L["Custom color"], customGradient = L["Custom gradient"] }
local ACCENT_ORDER = { "daylight", "gradient", "class", "classGradient", "custom", "customGradient" }
-- (DaylightUI's custom gradient, its colors set on General: only on a DaylightUI that has it.)
do
	local Style = type(_G.DaylightUI) == "table" and _G.DaylightUI.Style
	if not (type(Style) == "table" and type(Style.CustomAccentStops) == "function") then
		ACCENTS.customGradient = nil
		ACCENT_ORDER[#ACCENT_ORDER] = nil
	end
end

local OUTLINES = { keep = L["As the addon has it"], none = L["None"], thin = L["Thin"], thick = L["Thick"] }

-- The switch at the top of each tab of an addon's page: the addon's own settings, or DaylightUI's.
local function hintFor(addon)
	return function()
		return { type = "toggle", key = "look." .. addon .. ".own", label = string.format(L["Custom Settings for %s"], ns.targets[addon]),
			desc = string.format(L["On: the settings on this page are used for %s. Off: it goes by the \"%s\" switch on the %s page (your choices here are kept)."],
				ns.targets[addon], L["Use DaylightUI's settings for all windows"], L["Look and Feel"]) }
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
		items[#items + 1] = { type = "toggle", key = at .. "ownOpacity", label = L["Custom background opacity"],
			desc = L["Off: these windows follow DaylightUI's window background opacity."], disabled = following }
		items[#items + 1] = { type = "slider", key = at .. "opacity", label = L["Background opacity"], min = 0, max = 1, step = 0.05, unit = "%",
			desc = L["How solid the background of this addon's windows is."],
			disabled = function(get) return following(get) or get(at .. "ownOpacity") ~= true end }
		-- (A pack's own note on what it covers, Polestar's: its house skin only.)
		groups[#groups + 1] = { label = L["Window background"], tab = tab, items = items,
			desc = type(caps.note) == "string" and caps.note or nil }
		groups[#groups + 1] = { label = L["Window border"], tab = tab, items = {
			{ type = "toggle", key = at .. "border", label = L["Border"],
			  desc = L["The border round this addon's windows."], disabled = following },
			{ type = "toggle", key = at .. "ownBorder", label = L["Custom border size"],
			  desc = L["Off: the border is the size set in DaylightUI."],
			  disabled = function(get) return following(get) or get(at .. "border") == false end },
			{ type = "slider", key = at .. "borderPx", label = L["Border size"], min = 1, max = 16, step = 1, unit = "px",
			  desc = L["How thick the border is."],
			  disabled = function(get) return following(get) or get(at .. "border") == false or get(at .. "ownBorder") ~= true end },
			{ type = "toggle", key = at .. "gradientBorder", label = L["Gradient window borders"],
			  desc = L["When this addon's accent is a gradient (Daylight's, your class's or your own), its window borders run along it."],
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

local pages = {
	{ id = "addons", label = L["All windows"],
	  desc = L["Pick which windows get the DaylightUI look. Reload to apply changes."],
	  groups = {
		-- The switches: one grid per section (Grid.lua), each card the page's full width.
		{ label = L["Addons"], wide = true,
		  desc = L["Your addons this plugin can dress. One you don't have shows a link to get it."],
		  items = { ns.SkinGrid("addons") } },
		{ label = L["Blizzard"], wide = true,
		  desc = L["The game's own windows, each with a switch of its own."],
		  items = { ns.SkinGrid("blizzard") } },
		{ label = L["DaylightUI Override"],
		  desc = L["When your addons do something DaylightUI already does, DaylightUI handles it unless you picked the addon. On Look and Feel, each addon's settings have a switch per feature and a button to give everything back."],
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
-- Look and Feel: every addon's look on one page, in DaylightUI's page tabs (only the open tab's
-- cards are drawn, under the tab row). General: the switch for all windows and DaylightUI's own
-- look (its font, accent and window rows, on its own settings: Grid.lua, ns.DaylightLookGroups).
-- Text, Window, Controls and Extras: every addon's cards, each row hidden unless its addon is the
-- one picked ("lookPick"), so a tab shows only the picked one's cards (a card with no row to show
-- isn't drawn), then "Applies to": the addons the tab reaches, where one is picked.
local TAB_GENERAL, TAB_TEXT, TAB_WINDOW, TAB_CONTROLS, TAB_EXTRAS =
	L["General"], L["Text"], L["Window"], L["Controls"], L["Extras"]
local TAB_OF = { [L["Font"]] = TAB_TEXT, [L["Text colors"]] = TAB_TEXT, [L["Accent"]] = TAB_TEXT,
	[L["Window background"]] = TAB_WINDOW, [L["Window border"]] = TAB_WINDOW, [L["Controls"]] = TAB_CONTROLS }
local TAB_ORDER = { TAB_TEXT, TAB_WINDOW, TAB_CONTROLS, TAB_EXTRAS }

local byTab = { [TAB_TEXT] = {}, [TAB_WINDOW] = {}, [TAB_CONTROLS] = {}, [TAB_EXTRAS] = {} }
local picks = {}
for _, addon in ipairs(ns.order) do
	local page = addonPage(addon)
	if page then
		picks[#picks + 1] = addon
		for _, g in ipairs(page.groups) do
			local tab = TAB_OF[g.label] or TAB_EXTRAS
			g.tab = tab
			g.addon = addon
			for _, item in ipairs(g.items or {}) do
				local own = item.hidden
				item.hidden = function(get)
					if get(ns.LOOK_PICK) ~= addon then return true end
					return own ~= nil and own(get) or false
				end
			end
			local list = byTab[tab]
			list[#list + 1] = g
		end
	end
end
local looks = {
	{ label = L["DaylightUI's look"], tab = TAB_GENERAL, items = {
		{ type = "toggle", key = FOLLOW, label = L["Use DaylightUI's settings for all windows"],
		  desc = L["On: every addon's windows follow your DaylightUI font, colors, accent and window opacity, except an addon with \"Custom Settings\" on."] },
	} },
}
for _, g in ipairs(ns.DaylightLookGroups(TAB_GENERAL)) do looks[#looks + 1] = g end

-- The addon the other tabs show until one is clicked in a tab's "Applies to" list: the first
-- addon from A to Z.
table.sort(picks, function(a, b) return ns.targets[a]:lower() < ns.targets[b]:lower() end)
ns.lookPickDefault = picks[1]
-- Under each tab's cards, the addons that tab's settings reach: a Custom Settings switch each, and
-- a click on a name shows that addon's settings above (Grid.lua, ns.LookList).
for _, tab in ipairs(TAB_ORDER) do
	local reach, seen = {}, {}
	for _, g in ipairs(byTab[tab]) do
		looks[#looks + 1] = g
		if g.addon and not seen[g.addon] then
			seen[g.addon] = true
			reach[#reach + 1] = g.addon
		end
	end
	if #reach > 0 then
		looks[#looks + 1] = { label = L["Applies to"], tab = tab, wide = true,
			desc = L["Switch on Custom Settings per addon. Click a name to show its settings above."],
			items = { ns.LookList(reach) } }
	end
end
pages[#pages + 1] = { id = "look", label = L["Look and Feel"],
	desc = L["Fonts, text, accent and window looks for each addon you dress."],
	groups = looks }

-- The "Tell me when a newer version is out" switch (Update.lua), on the first page.
if ns.UpdateGroup and pages[1] then table.insert(pages[1].groups, ns.UpdateGroup()) end

ns.RegisterSettings(pages)
