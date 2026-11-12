-- This plugin's pages in DaylightUI's options, under the Plugins heading in the list on the left.
-- "All windows": the switch that keeps every window on DaylightUI's own settings, and one switch
-- per addon. Then a page per addon with what can be set for its windows alone (ns.Target's caps):
-- its text, its window shell, its controls. Each addon page opens with its own switch, "Use my own
-- settings": off, the page's rows are set aside and the addon follows DaylightUI (or the switch for
-- all windows); on, the rows are the addon's look.
local _, ns = ...
if not ns.ok then return end

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
local fonts = { daylight = "DaylightUI font", addon = "The addon's own font" }
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

local OUTLINES = { keep = "As the addon has it", none = "None", thin = "Thin", thick = "Thick" }

-- The switch at the top of each tab of an addon's page: the addon's own settings, or DaylightUI's.
local function hintFor(addon)
	return function()
		return { type = "toggle", key = "look." .. addon .. ".own", label = "Use my own settings for " .. ns.targets[addon],
			desc = "On: the settings on this page are used for " .. ns.targets[addon] .. ". Off: it goes by the \"Use DaylightUI's settings for all windows\" switch on the All windows page (your choices here are kept)." }
	end
end

local function textGroups(addon, caps, tab)
	local at = "look." .. addon .. "."
	local following, hint = followingFor(addon), hintFor(addon)
	local items = {
		hint(),
		{ type = "dropdown", key = at .. "font", label = "Font", values = fonts,
		  desc = "The font of this addon's text.", disabled = following },
		{ type = "dropdown", key = at .. "outline", label = "Text outline", values = OUTLINES,
		  desc = "The outline round this addon's text.", disabled = following },
	}
	if caps.shadow then
		items[#items + 1] = { type = "toggle", key = at .. "shadow", label = "Text shadow",
			desc = "A soft shadow under this addon's text.", disabled = following }
	end
	items[#items + 1] = { type = "slider", key = at .. "size", label = "Text size", min = 0.8, max = 1.4, step = 0.05, unit = "%",
		desc = "How big this addon's text is, next to the size the addon gave it.", disabled = following }
	local groups = { { label = "Font", tab = tab, items = items } }
	if caps.colors then
		groups[#groups + 1] = { label = "Text colors", tab = tab, items = {
			{ type = "toggle", key = at .. "daylightColors", label = "Use DaylightUI's text colors",
			  desc = "Off: the addon keeps its own text colors.", disabled = following },
		} }
		groups[#groups + 1] = { label = "Accent", tab = tab, items = {
			{ type = "toggle", key = at .. "daylightAccent", label = "Use DaylightUI's accent",
			  desc = "Off: pick an accent for this addon alone.", disabled = following },
			{ type = "color", key = at .. "accent", label = "Accent color",
			  desc = "This addon's accent: its highlights, marks and arrow.",
			  disabled = function(get) return following(get) or get(at .. "daylightAccent") ~= false end },
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
		items[#items + 1] = { type = "toggle", key = at .. "ownOpacity", label = "Use my own background opacity",
			desc = "Off: these windows follow DaylightUI's window background opacity.", disabled = following }
		items[#items + 1] = { type = "slider", key = at .. "opacity", label = "Background opacity", min = 0, max = 1, step = 0.05, unit = "%",
			desc = "How solid the background of this addon's windows is.",
			disabled = function(get) return following(get) or get(at .. "ownOpacity") ~= true end }
		groups[#groups + 1] = { label = "Window background", tab = tab, items = items }
		groups[#groups + 1] = { label = "Window border", tab = tab, items = {
			{ type = "toggle", key = at .. "border", label = "Border",
			  desc = "The border round this addon's windows.", disabled = following },
			{ type = "toggle", key = at .. "ownBorder", label = "Use my own border size",
			  desc = "Off: the border is the size set in DaylightUI.",
			  disabled = function(get) return following(get) or get(at .. "border") == false end },
			{ type = "slider", key = at .. "borderPx", label = "Border size", min = 1, max = 16, step = 1, unit = "px",
			  desc = "How thick the border is.",
			  disabled = function(get) return following(get) or get(at .. "border") == false or get(at .. "ownBorder") ~= true end },
			{ type = "toggle", key = at .. "bevel", label = "Bevel",
			  desc = "The soft light along the top of this addon's windows.", disabled = following },
		} }
	end
	if caps.controls then
		local items = {}
		if lead then items[#items + 1] = hint() end
		items[#items + 1] = { type = "toggle", key = at .. "controls", label = "Dress buttons, boxes and scroll bars",
			desc = "Off: only the windows are dressed and their controls stay as the addon drew them. Takes hold after a reload.",
			disabled = following }
		groups[#groups + 1] = { label = "Controls", tab = tab, items = items }
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
		for _, g in ipairs(textGroups(addon, caps, tabs and "Text styling" or nil)) do groups[#groups + 1] = g end
	end
	if hasLook then
		for _, g in ipairs(lookGroups(addon, caps, tabs and "Appearance" or nil, tabs or not hasText)) do groups[#groups + 1] = g end
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
		desc = "How " .. label .. "'s windows look in DaylightUI. Windows follow at once; text and controls after a reload.",
		groups = groups }
end

local switches = {}
for _, addon in ipairs(ns.order) do
	switches[#switches + 1] = {
		type = "toggle", key = addon, label = ns.targets[addon], default = true,
		desc = "Dress " .. ns.targets[addon] .. "'s windows.",
	}
end
switches[#switches + 1] = { type = "button", label = "Reload interface", func = function() ReloadUI() end }

local pages = {
	{ id = "addons", label = "All windows",
	  desc = "Dress your other addons' windows in the DaylightUI look. Reload the interface after turning an addon on or off.",
	  groups = {
		{ label = "DaylightUI's look", items = {
			{ type = "toggle", key = FOLLOW, label = "Use DaylightUI's settings for all windows",
			  desc = "On: every addon's windows follow your DaylightUI font, colors, accent and window opacity, except an addon whose own page has \"Use my own settings\" on." },
		} },
		{ label = "Addon windows", items = switches },
	  } },
}
for _, addon in ipairs(ns.order) do
	local page = addonPage(addon)
	if page then pages[#pages + 1] = page end
end

ns.RegisterSettings(pages)
