-- Journey (the guide addon): every part of it in the DaylightUI look, each part with its own setting
-- on this plugin's Journey page.
-- Journey keeps its code in an environment of its own; JGADDON (which it puts in _G) leads to it,
-- so its frames are not hunted for: its CreateFrame is followed, and each frame it makes is dressed
-- the frame after it was made, once Journey has set it up. What is dressed:
--   the guide header, the step boxes and the "something should be here" box: DaylightUI's shell in
--     place of the glue-tooltip backdrop; a box the guide marks with a color gets a bar in it
--   the progress bar (the accent, its own color, or Journey's blue), the logo (shown or not)
--   the step buttons: flat in the step's own color, DaylightUI's buttons, or Journey's art
--   the item / target buttons beside the guide: square icons with a thin border
--   the guide menu and its submenu, Advanced Options, the link popup: shells, buttons, text box;
--     menu rows lit and checked in the accent
--   the guide tooltip: DaylightUI's shell
--   the HUD arrow's labels: the player's font, its distance in the accent
--   every string: the player's font, size, outline and shadow, and DaylightUI's text colors
--   the colors of quests, NPCs, items, places, flights and levels in the step text (optional)
-- Journey's sliders and its header arrows and gear are left as it draws them.
-- The hardcore progress bar keeps Journey's red. The link colors also reach what Journey copied
-- out as it loaded ("do" and "start" steps, and the items, places, flights and red words of the
-- text steps).
-- Nothing is written to Journey's saved settings but the one conflict below (accepting and turning
-- in the guide's quests), and none of its files are touched.
local _, ns = ...
if not ns.ok then return end
local L = ns.L

local KEY = "Journey"

-- ---------------------------------------------------------------------------------------------
-- Its page: the settings of its own, under the "Journey" tab
-- ---------------------------------------------------------------------------------------------

-- Journey's own colors, the defaults of the link colors.
local function Hex(s)
	return { tonumber(s:sub(1, 2), 16) / 255, tonumber(s:sub(3, 4), 16) / 255, tonumber(s:sub(5, 6), 16) / 255 }
end

-- setting = { label, Journey's color names it stands for, its default }
local LINKS = {
	{ "linkQuest", L["Quests to Do"], { "QUEST", "QUEST_DO", "QUEST_STARTWORK" }, Hex("0084EB") },
	{ "linkAccept", L["Quests to Accept"], { "QUEST_ACCEPT" }, Hex("FFFF00") },
	{ "linkTurnin", L["Quests to Turn In"], { "QUEST_TURNIN" }, Hex("FFA500") },
	{ "linkFriendly", L["Friendly NPCs"], { "NPC_FRIENDLY" }, Hex("9DFF9D") },
	{ "linkHostile", L["Hostile NPCs"], { "NPC_HOSTILE" }, Hex("FF6363") },
	{ "linkNeutral", L["Neutral NPCs"], { "NPC_NEUTRAL" }, Hex("FFD100") },
	{ "linkObject", L["Items, Objects, Spells and Other NPCs"], { "ITEM", "GAME_OBJECT", "SPELL", "SKILL", "NPC", "SEARCH_TERM" }, Hex("E36EE4") },
	{ "linkPlace", L["Places and Zones"], { "AREA", "ZONE", "WMOAREA" }, Hex("FFD100") },
	{ "linkTravel", L["Flights and Inns"], { "TAXI", "INN" }, Hex("FFA500") },
	{ "linkLevel", L["Levels and Experience"], { "LEVEL", "XP" }, Hex("FFFF00") },
	{ "linkWarn", L["Warnings and Tips"], { "TIP", "RED_TEXT", "GET_OUT", "QUEST_SKIPPED", "SKIPPED_HEADING" }, Hex("FF0000") },
}

local DEFAULTS = {
	showLogo = true,
	groupMarks = true,
	progress = "accent",
	progressColor = { 0.25, 0.6, 1 },
	stepButtons = "flat",
	buttonTint = 0.35,
	accentHighlight = true,
	squareItems = true,
	menuAccent = true,
	tooltip = true,
	arrowAccent = true,
	ownLinks = false,
}
for _, l in ipairs(LINKS) do DEFAULTS[l[1]] = l[4] end

local function Extra(at, following, hint)
	local function off(get) return following(get) end
	local linkItems = {
		{ type = "toggle", key = at .. "ownLinks", label = L["Custom Link Colors"],
		  desc = L["Off: the quests, NPCs, items and places in the steps keep Journey's colors."], disabled = off },
	}
	for _, l in ipairs(LINKS) do
		linkItems[#linkItems + 1] = { type = "color", key = at .. l[1], label = l[2],
			desc = L["Their color in the step text."],
			disabled = function(get) return following(get) or get(at .. "ownLinks") ~= true end }
	end
	return {
		{ label = L["Guide Window"], items = {
			hint(),
			{ type = "toggle", key = at .. "showLogo", label = L["Journey Logo"],
			  desc = L["The logo at the left of the guide's header."], disabled = off },
			{ type = "toggle", key = at .. "groupMarks", label = L["Marked Steps"],
			  desc = L["A colored bar in the step boxes the guide marks with a color (it drew their border in it)."], disabled = off },
			{ type = "dropdown", key = at .. "progress", label = L["Progress Bar"],
			  values = { accent = L["The Accent"], own = L["My Own Color"], journey = L["Journey's Blue"] },
			  desc = L["The color of the guide's progress bar under the title."], disabled = off },
			{ type = "color", key = at .. "progressColor", label = L["Progress Bar Color"],
			  desc = L["Its color when \"My Own Color\" is picked."],
			  disabled = function(get) return following(get) or get(at .. "progress") ~= "own" end },
		} },
		{ label = L["Step Buttons"], items = {
			{ type = "dropdown", key = at .. "stepButtons", label = L["Style"],
			  values = { flat = L["Flat, in the Step's Color"], daylight = L["Daylight UI Buttons"], journey = L["As Journey Draws Them"] },
			  desc = L["The buttons in the steps (Go to, Skip and the guide's own). Takes hold after a reload."], disabled = off },
			{ type = "slider", key = at .. "buttonTint", label = L["Color Strength"], min = 0.1, max = 0.8, step = 0.05, unit = "%",
			  desc = L["How strongly a flat button shows its step's color."],
			  disabled = function(get) return following(get) or get(at .. "stepButtons") ~= "flat" end },
			{ type = "toggle", key = at .. "accentHighlight", label = L["Highlighted Buttons in the Accent"],
			  desc = L["Off: the button the guide highlights keeps Journey's blue."], disabled = off },
			{ type = "toggle", key = at .. "squareItems", label = L["Square Item Buttons"],
			  desc = L["The item and target buttons beside the guide: square icons with a thin border. Takes hold after a reload."],
			  disabled = off },
			{ type = "button", label = L["Reload Interface"], func = function() ReloadUI() end },
		} },
		{ label = L["Menus, Tooltip and Arrow"], items = {
			{ type = "toggle", key = at .. "menuAccent", label = L["Menus in the Accent"],
			  desc = L["The guide menu's rows light up, and its check marks show, in the accent."], disabled = off },
			{ type = "toggle", key = at .. "tooltip", label = L["Dress the Guide Tooltip"],
			  desc = L["The tooltip of the guide's links in Daylight UI's shell. Takes hold after a reload."], disabled = off },
			{ type = "toggle", key = at .. "arrowAccent", label = L["Arrow Distance in the Accent"],
			  desc = L["Off: the HUD arrow's distance stays gold."], disabled = off },
		} },
		{ label = L["Link Colors"], items = linkItems },
		ns.HandoverGroup(KEY),
	}
end

ns.Target(KEY, "Journey Guides", { window = true, controls = true, text = true, shadow = true, colors = true,
	font = "daylight", defaults = DEFAULTS, extra = Extra, extraTab = L["Guide"] })

-- ---------------------------------------------------------------------------------------------
-- Conflicts (Core.lua): what it does that DaylightUI already does. Its account-wide settings
-- (Journey_Account), read each time they're used. One switch accepts and turns in the guide's own
-- quests: handed over only while DaylightUI does both. Its screen arrow (the way to the step) has
-- a different purpose from DaylightUI's and isn't offered.
-- ---------------------------------------------------------------------------------------------

ns.Handover(KEY, {
	ready = function() return type(_G.Journey_Account) == "table" end,
	-- (It reads a setting it never saved as on.)
	get = function(key)
		local v = _G.Journey_Account[key]
		if v == nil then return true end
		return v
	end,
	set = function(key, value) _G.Journey_Account[key] = value end,
	list = {
		{ key = "autoquests", label = L["Accept and Turn in the Guide's Quests"],
		  daylight = ns.In(string.format(L["%s, %s"], L["auto accept"], L["auto turn in"]), "Quality of Life"),
		  ours = function() return ns.DaylightHas("QoL", "questAccept") and ns.DaylightHas("QoL", "questTurnIn") end },
	},
})

-- ---------------------------------------------------------------------------------------------
-- Journey's environment
-- ---------------------------------------------------------------------------------------------

local A = _G.JGADDON
local env = type(A) == "table" and type(A.GetWorldPosFromMapPos) == "function" and type(getfenv) == "function"
	and getfenv(A.GetWorldPosFromMapPos)
if type(env) ~= "table" or type(rawget(env, "UI")) ~= "table" or type(rawget(env, "UI").GetComponent) ~= "function"
	or type(rawget(env, "CreateFrame")) ~= "function" then
	return
end

local JUI = rawget(env, "UI")
local abs, floor, min = math.abs, math.floor, math.min

local function Look(name) return ns.Look(KEY, name) end
local function On() return ns.Enabled(KEY) end

local function RGB(c, fallback)
	if type(c) == "table" then
		local r, g, b = c[1] or c.r, c[2] or c.g, c[3] or c.b
		if type(r) == "number" and type(g) == "number" and type(b) == "number" then return r, g, b end
	end
	if fallback then return RGB(fallback) end
	return 1, 1, 1
end

local function Accent()
	local ok, r, g, b = pcall(ns.AccentOf, KEY)
	if ok and r then return r, g, b end
	return 1, 0.82, 0
end

local function TextColor(name)
	local ok, colors = pcall(ns.Colors)
	local c = ok and type(colors) == "table" and (colors[name] or colors.VALUE)
	return RGB(c, { 1, 1, 1 })
end

local function HexOf(r, g, b)
	return string.format("FF%02X%02X%02X", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

-- ---------------------------------------------------------------------------------------------
-- Text: copies of the game fonts Journey uses (its strings are pointed at them), and its own fonts
-- restyled where they are. Every string follows its font object, so a change shows at once.
-- ---------------------------------------------------------------------------------------------

local GAME_FONTS = {
	"GameFontNormal", "GameFontNormalLarge", "GameFontNormalSmall", "GameFontNormalSmallLeft",
	"GameFontHighlight", "GameFontHighlightLarge", "GameFontHighlightSmall", "GameFontHighlightSmallLeft",
	"GameFontWhiteSmall", "GameFontDisable", "GameFontDisableSmall", "GameFontDisableSmallLeft",
	"GameFontDisableTiny2",
}

-- Which DaylightUI text color a font takes: gold headings TITLE, white VALUE, gray OFF.
local function Role(name)
	if name:find("Disable") then return "OFF" end
	if name:find("Normal") then return "TITLE" end
	return "VALUE"
end

local copies = {}      -- game font object -> { copy, name }
local copyOf = {}      -- game font object -> copy
for i, name in ipairs(GAME_FONTS) do
	local src = _G[name]
	if type(src) == "table" and src.GetFont then
		local copy = CreateFont("DaylightAddonSkinsJourney" .. i)
		copy:CopyFontObject(src)
		copies[src] = { copy = copy, name = name }
		copyOf[src] = copy
	end
end

local function Styled()
	return On() and not ns.PlainText(KEY)
end

local function RestyleCopy(src, c)
	local copy = c.copy
	copy:CopyFontObject(src)
	if not On() then return end
	local path, size, flags = src:GetFont()
	if Styled() and path and size then
		path, size, flags = ns.FontFor(KEY, path, size, flags)
		copy:SetFont(path, size, flags or "")
	end
	if Look("shadow") == true then
		copy:SetShadowColor(0, 0, 0, 0.9)
		copy:SetShadowOffset(1, -1)
	end
	if Look("daylightColors") ~= false then copy:SetTextColor(TextColor(Role(c.name))) end
end

-- Its own fonts: what it set on each is kept, the look laid over it.
local own = {}          -- font object -> { path, size, flags, r, g, b, role }
local busyFont = false

local function RestyleOwn(font)
	local o = own[font]
	if not o or not o[1] or not o[2] then return end
	busyFont = true
	local ok, err = pcall(function()
		if Styled() then
			local path, size, flags = ns.FontFor(KEY, o[1], o[2], o[3])
			font:SetFont(path, size, flags or "")
		else
			font:SetFont(o[1], o[2], o[3] or "")
		end
		if On() and Look("daylightColors") ~= false and o.role then
			font:SetTextColor(TextColor(o.role))
		elseif o[4] then
			font:SetTextColor(o[4], o[5], o[6])
		end
	end)
	busyFont = false
	if not ok then geterrorhandler()(err) end
end

local function AdoptFont(font, role)
	if type(font) ~= "table" or not font.GetFont or own[font] then return end
	local path, size, flags = font:GetFont()
	local r, g, b = font:GetTextColor()
	own[font] = { path, size, flags, r, g, b, role = role }
	hooksecurefunc(font, "SetFont", function(self, p, s, f)
		if busyFont then return end
		local o = own[self]
		o[1], o[2], o[3] = p, s, f
		RestyleOwn(self)
	end)
	RestyleOwn(font)
end

local function RestyleFonts()
	for src, c in pairs(copies) do pcall(RestyleCopy, src, c) end
	for font in pairs(own) do RestyleOwn(font) end
end

-- A string, or a button's three font objects, onto the copies.
local function Remap(fs)
	if not ns.Usable(fs) or not fs.GetFontObject then return end
	local copy = copyOf[fs:GetFontObject()]
	if copy then fs:SetFontObject(copy) end
end

local busyButton = false
local STATES = { "Normal", "Highlight", "Disabled" }

local function RemapButton(b, white)
	for _, state in ipairs(STATES) do
		local get, set = b["Get" .. state .. "FontObject"], "Set" .. state .. "FontObject"
		if get and b[set] then
			local obj = get(b)
			local copy = copyOf[obj]
			if white and state ~= "Disabled" then copy = copyOf[_G.GameFontHighlight] or copy end
			if copy and copy ~= obj then
				busyButton = true
				pcall(b[set], b, copy)
				busyButton = false
			end
			-- Journey sets them again on the menu's rows each time it fills them.
			hooksecurefunc(b, set, function(self, font)
				if busyButton then return end
				local obj2 = type(font) == "string" and _G[font] or font
				local c = copyOf[obj2]
				if c and white and state ~= "Disabled" then c = copyOf[_G.GameFontHighlight] or c end
				if c then
					busyButton = true
					pcall(self[set], self, c)
					busyButton = false
				end
			end)
		end
	end
end

local function RemapRegions(f)
	for _, region in ipairs({ f:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "FontString" then Remap(region) end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The parts, each painted again whenever a setting or the DaylightUI look changes
-- ---------------------------------------------------------------------------------------------

local done = setmetatable({}, { __mode = "k" })
local groups = setmetatable({}, { __mode = "k" })     -- step box -> its bar
local flats = setmetatable({}, { __mode = "k" })      -- flat step button -> { fill, r, g, b }
local menuRows = setmetatable({}, { __mode = "k" })
local bars = {}                                       -- progress bar textures -> { r, g, b, alpha } Journey's
local header, arrow, logo

local GLUE = "glue%-tooltip%-background"

local function IsGlue(f)
	local info = f.backdropInfo
	return type(info) == "table" and type(info.bgFile) == "string" and info.bgFile:lower():find(GLUE) ~= nil
end

local function GuideFrame()
	local c = JUI.GetComponent("GuideContainer")
	return c and c.frame
end

-- A box the guide marks: Journey drew its border in a color of the guide's.
local function PaintGroup(f)
	local bar = groups[f]
	if not bar then return end
	local c = f.backdropBorderColor
	local plain = rawget(env, "GLUE_BACKDROP_BORDER_COLOR")
	if On() and Look("groupMarks") ~= false and type(c) == "table" and c ~= plain and c.GetRGB then
		bar:SetColorTexture(c:GetRGB())
		bar:Show()
	else
		bar:Hide()
	end
end

-- The glue-tooltip boxes: their backdrop off for good, DaylightUI's shell on.
local function Box(f)
	-- (In this order: the backdrop's own clearing only works while backdropInfo is still set.)
	ns.NoBackdrop(f)
	f.backdropInfo = nil
	hooksecurefunc(f, "OnBackdropLoaded", function(self)
		if self.backdropInfo then
			ns.NoBackdrop(self)
			self.backdropInfo = nil
		end
		PaintGroup(self)
	end)
	ns.Shell(f, { window = true }, KEY)
	if f:GetParent() == GuideFrame() and f ~= header then
		local bar = f:CreateTexture(nil, "OVERLAY")
		bar:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -6)
		bar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 3, 6)
		bar:SetWidth(2)
		bar:Hide()
		groups[f] = bar
		PaintGroup(f)
	end
end

local busyBar = false
local function PaintProgress()
	for tex, j in pairs(bars) do
		busyBar = true
		local mode = On() and Look("progress") or "journey"
		-- (Red in hardcore mode, a warning: kept whatever the color picked.)
		local hardcore = j[1] == 1 and j[2] == 0 and j[3] == 0
		if mode == "journey" then
			tex:SetColorTexture(j[1], j[2], j[3])
			tex:SetAlpha(0.5)
		else
			local r, g, b
			if hardcore then
				r, g, b = 1, 0, 0
			elseif mode == "own" then
				r, g, b = RGB(Look("progressColor"))
			else
				r, g, b = Accent()
			end
			tex:SetColorTexture(r, g, b)
			tex:SetAlpha(j.complete and 0.9 or 0.25)
		end
		busyBar = false
	end
end

local function PaintLogo()
	if logo then logo:SetAlpha((On() and Look("showLogo") == false) and 0 or 1) end
end

local function Header(f)
	header = f
	Box(f)
	logo = f.Icon
	-- The progress bar: its two thin strips, the done part over the rest.
	for _, region in ipairs({ f:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" then
			local layer, sub = region:GetDrawLayer()
			local h = region:GetHeight()
			if layer == "BACKGROUND" and h and abs(h - 4.25) < 0.6 then
				bars[region] = { 0.04, 0.4, 0.68, complete = (sub or 0) > 0 }
				hooksecurefunc(region, "SetColorTexture", function(self, r, g, b)
					if busyBar then return end
					local j = bars[self]
					j[1], j[2], j[3] = r, g, b
					PaintProgress()
				end)
			end
		end
	end
	PaintProgress()
	PaintLogo()
end

local function PaintFlat(b)
	local s = flats[b]
	if not s then return end
	local alpha = Look("buttonTint")
	if type(alpha) ~= "number" then alpha = DEFAULTS.buttonTint end
	s.fill:SetColorTexture(s.r, s.g, s.b, alpha)
end

-- Journey hands the button's color to its art as hex / 128.
local function FromArt(v) return min(1, (v or 0) * 128 / 255) end

local function HideArt(b)
	for _, region in ipairs({ b:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region ~= b.Highlight then
			region:SetAlpha(0)
		end
	end
	if b.Highlight then b.Highlight:SetAlpha(0) end
end

local function StepButton(b, Kit)
	local style = Look("stepButtons")
	if style == "journey" then
		RemapButton(b)
		return
	end
	if style == "daylight" then
		-- Controls off: nothing to put on, so Journey's art stays.
		if ns.Controls(KEY) then
			HideArt(b)
			ns.Guard(Kit.Button, b)
		end
		RemapButton(b)
		return
	end
	HideArt(b)
	local fill = b:CreateTexture(nil, "BACKGROUND", nil, -8)
	fill:SetPoint("TOPLEFT", 1, -1)
	fill:SetPoint("BOTTOMRIGHT", -1, 1)
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints(fill)
	hl:SetColorTexture(1, 1, 1, 0.1)
	local r, g, bl = 1, 1, 1
	if b.Middle and b.Middle.GetVertexColor then r, g, bl = b.Middle:GetVertexColor() end
	flats[b] = { fill = fill, r = FromArt(r), g = FromArt(g), b = FromArt(bl) }
	if b.Middle then
		hooksecurefunc(b.Middle, "SetVertexColor", function(_, r2, g2, b2)
			local s = flats[b]
			s.r, s.g, s.b = FromArt(r2), FromArt(g2), FromArt(b2)
			PaintFlat(b)
		end)
	end
	PaintFlat(b)
	ns.Shell(b, { noBackground = true, noBevel = true }, KEY)
	RemapButton(b, true)
end

-- The item and target buttons: secure, so only out of combat.
local function ItemButton(b)
	if Look("squareItems") == false then return end
	ns.OutOfCombat(function()
		for _, region in ipairs({ b:GetRegions() }) do
			if ns.Usable(region) and region:GetObjectType() == "Texture" then
				local w = region:GetWidth()
				if w and w > 40 then region:SetAlpha(0) end   -- the round quick-slot ring
			end
		end
		if b.icon then b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
		ns.Shell(b, { noBackground = true, noBevel = true }, KEY)
	end)
end

local function PaintMenuRow(b)
	local accent = On() and Look("menuAccent") ~= false
	local r, g, bl = Accent()
	if b.highlight then
		if accent then
			b.highlight:SetTexture(nil)
			b.highlight:SetColorTexture(r, g, bl, 0.18)
			b.highlight:SetBlendMode("BLEND")
		else
			b.highlight:SetTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
			b.highlight:SetBlendMode("ADD")
			b.highlight:SetVertexColor(1, 1, 1)
		end
	end
	if b.checkbox then
		local left = b.checkbox:GetTexCoord()
		if accent and left == 0 then b.checkbox:SetVertexColor(r, g, bl) else b.checkbox:SetVertexColor(1, 1, 1) end
	end
end

local function MenuRow(b)
	menuRows[b] = true
	RemapButton(b)
	if type(b.SetChecked) == "function" then hooksecurefunc(b, "SetChecked", PaintMenuRow) end
	PaintMenuRow(b)
end

local function Tooltip(tip)
	if Look("tooltip") == false then return end
	local function Hide()
		if tip.NineSlice then tip.NineSlice:SetAlpha(0) end
	end
	Hide()
	tip:HookScript("OnShow", Hide)
	ns.Shell(tip, { noBevel = true }, KEY)
end

local function PaintArrow()
	if not arrow or not arrow.distLabel then return end
	if On() and Look("arrowAccent") ~= false then
		arrow.distLabel:SetTextColor(Accent())
	else
		arrow.distLabel:SetTextColor(1, 0.82, 0, 1)
	end
end

local function Arrow(f)
	arrow = f
	AdoptFont(_G.JourneyArrowLabelFont)
	PaintArrow()
end

-- The link colors, and the highlighted step buttons' color. Journey's Color table is looked up
-- each time (it could make a new one), and its own colors are taken from it at login, before any
-- of ours go in.
local original, originalOf = {}, nil

local function TakeOriginals()
	local Color = rawget(env, "Color")
	if type(Color) ~= "table" or originalOf == Color then return end
	originalOf = Color
	original = {}
	for _, l in ipairs(LINKS) do
		for _, name in ipairs(l[3]) do original[name] = Color[name] end
	end
	original.MODE_HIGHLIGHT = Color.MODE_HIGHLIGHT
end

-- A kind of step, found the way Journey finds it (by the step's key), or nil.
local function TaskType(kind)
	local get = rawget(env, "GetTaskType")
	if type(get) ~= "function" then return nil end
	local ok, t = pcall(get, { [kind] = true })
	if ok and type(t) == "table" and t.type == kind then return t end
end

-- Some colors were copied out of Color as Journey loaded, so a change there never reaches them:
-- "do" and "start" steps keep theirs on the step type (set again here), and the text steps'
-- items, objects, spells, places, flights and red words are written in the loaded hexes (each
-- mapped to the player's pick after they render, an NPC's link left to its own color).
local TASK_COLORS = { complete = "QUEST_DO", startwork = "QUEST_STARTWORK" }
local baked = {}   -- Journey's loaded hex (upper case) -> the setting it stands for

local function Baked()
	baked = {}
	local function add(name, setting)
		local hex = original[name]
		if type(hex) == "string" then baked[hex:upper()] = setting end
	end
	add("ITEM", "linkObject")
	add("AREA", "linkPlace")
	add("TAXI", "linkTravel")
	add("RED_TEXT", "linkWarn")
end

local function LinkDefault(setting)
	for _, l in ipairs(LINKS) do
		if l[1] == setting then return l[4] end
	end
end

local function Remark(fs)
	if not ns.Usable(fs) or not fs.GetText then return end
	local text = fs:GetText()
	if type(text) ~= "string" or not text:find("|[cC]") then return end
	local changed = false
	local out = text:gsub("|[cC](%x%x%x%x%x%x%x%x)()", function(hex, at)
		local setting = baked[hex:upper()]
		if not setting or text:sub(at, at + 5) == "|Hnpc:" then return nil end
		changed = true
		return "|c" .. HexOf(RGB(Look(setting), LinkDefault(setting)))
	end)
	if changed then fs:SetText(out) end
end

local textHooked = false
local function HookText()
	if textHooked then return end
	local t = TaskType("text")
	if not t or type(t.RenderFunc) ~= "function" then return end
	textHooked = true
	ns.HookOnce(t, "RenderFunc", function(_, _, container)
		if not (On() and Look("ownLinks") == true) or type(container) ~= "table" then return end
		ns.Guard(function()
			Remark(container.text)
			if type(container.taskDetailContainers) == "table" then
				for _, detail in ipairs(container.taskDetailContainers) do
					if type(detail) == "table" then Remark(detail.text) end
				end
			end
		end)
	end, KEY)
end

local function ApplyColors()
	local Color = rawget(env, "Color")
	if type(Color) ~= "table" then return end
	TakeOriginals()
	local mine = On() and Look("ownLinks") == true
	for _, l in ipairs(LINKS) do
		local hex = mine and HexOf(RGB(Look(l[1]), l[4])) or nil
		for _, name in ipairs(l[3]) do
			if original[name] then Color[name] = hex or original[name] end
		end
	end
	if original.MODE_HIGHLIGHT then
		Color.MODE_HIGHLIGHT = (On() and Look("accentHighlight") ~= false) and HexOf(Accent()) or original.MODE_HIGHLIGHT
	end
	for kind, name in pairs(TASK_COLORS) do
		local t = TaskType(kind)
		if t and Color[name] then t.taskColor = Color[name] end
	end
	Baked()
	HookText()
	local npc = rawget(env, "NPCColor")
	if type(npc) == "table" then
		npc[1], npc[2], npc[3], npc[4] = Color.NPC, Color.NPC_HOSTILE, Color.NPC_FRIENDLY, Color.NPC_NEUTRAL
	end
	local mark = rawget(env, "MarkAllDirty")
	if type(mark) == "function" then pcall(mark) end
end

local function PaintAll()
	RestyleFonts()
	ApplyColors()
	PaintProgress()
	PaintLogo()
	PaintArrow()
	for f in pairs(groups) do PaintGroup(f) end
	for b in pairs(flats) do PaintFlat(b) end
	for b in pairs(menuRows) do PaintMenuRow(b) end
end

-- ---------------------------------------------------------------------------------------------
-- What a frame of Journey's is, and its dressing
-- ---------------------------------------------------------------------------------------------

local function Dress(f, Kit)
	if done[f] or not ns.Usable(f) then return end
	done[f] = true
	local kind = f:GetObjectType()
	if kind == "GameTooltip" then
		Tooltip(f)
		return
	end
	if kind == "Button" then
		-- A secure button: only the item buttons are dressed, and only out of combat.
		if f.IsProtected and f:IsProtected() then
			if f.icon and f.cover then ItemButton(f) end
			return
		end
		if f.checkbox and f.arrow and f.text2 then
			MenuRow(f)
		elseif f.Left and f.Middle and f.Right then
			if f.Highlight then
				StepButton(f, Kit)
			else
				if ns.Controls(KEY) then ns.Guard(Kit.Button, f) end
				RemapButton(f)
			end
		elseif f.icon and f.cover then
			ItemButton(f)
		else
			RemapButton(f)
		end
		RemapRegions(f)
		return
	end
	if kind == "EditBox" then
		if f.Left and f.Middle and f.Right and ns.Controls(KEY) then ns.Guard(Kit.EditBox, f) end
		Remap(f)
		return
	end
	if kind == "Slider" then
		RemapRegions(f)
		return
	end
	if kind == "Frame" then
		local h = JUI.GetComponent("Header")
		if h and f == h.frame then
			Header(f)
		elseif IsGlue(f) then
			Box(f)
		end
		if f.Button and f.Left and f.Middle and f.Right and f.Text and ns.Controls(KEY) then
			ns.Guard(Kit.Dropdown, f)
		end
		RemapRegions(f)
	end
end

-- A frame and what is in it.
local function DressTree(f, Kit, depth)
	if not ns.Usable(f) then return end
	ns.Guard(Dress, f, Kit)
	if depth <= 0 or not f.GetChildren then return end
	for _, child in ipairs({ f:GetChildren() }) do DressTree(child, Kit, depth - 1) end
end

-- Every frame Journey makes from now on, dressed the frame after (it is set up by then).
local queue = {}
local queued = false
local started = false

local function Drain()
	queued = false
	if not started then return end
	local list = queue
	queue = {}
	if not On() then return end
	ns.WithKit(function(Kit)
		for i = 1, #list do
			local f = list[i]
			ns.Guard(Dress, f, Kit)
			-- (its fonts and rows made with it)
			if ns.Usable(f) and f.GetChildren then
				for _, child in ipairs({ f:GetChildren() }) do
					if not done[child] then ns.Guard(Dress, child, Kit) end
				end
			end
		end
	end)
end

local function Kick()
	if queued or not started then return end
	queued = true
	C_Timer.After(0, Drain)
end

local origCreateFrame = rawget(env, "CreateFrame")
rawset(env, "CreateFrame", function(...)
	local f = origCreateFrame(...)
	if f and not (started and not On()) then
		queue[#queue + 1] = f
		Kick()
	end
	return f
end)

-- Advanced Options was made before this plugin loaded, and Journey keeps no way to it: found
-- among UIParent's children the first time it opens.
local configFound = false
if type(JUI.OpenConfigurationWindow) == "function" then
	local origOpen = JUI.OpenConfigurationWindow
	JUI.OpenConfigurationWindow = function(...)
		local out = origOpen(...)
		if not configFound and started and On() then
			ns.WithKit(function(Kit)
				for _, child in ipairs({ UIParent:GetChildren() }) do
					if ns.Usable(child) and child:GetObjectType() == "Frame" and child:IsShown()
						and not done[child] and IsGlue(child) and child:GetFrameLevel() >= 3000 then
						configFound = true
						DressTree(child, Kit, 3)
						break
					end
				end
			end)
		end
		return out
	end
end

-- At login: what Journey made when it loaded (the guide, its header, the tooltip, the fonts).
ns.me.On("Login", function()
	started = true
	if not On() then
		queue = {}
		return
	end
	ns.Guard(function()
		TakeOriginals()
		AdoptFont(_G.JGGameFontWhiteSmall, "VALUE")
		AdoptFont(_G.JGGameFontWhiteTiny, "TEXT")
		ns.WithKit(function(Kit)
			local guide = GuideFrame()
			if guide then DressTree(guide, Kit, 4) end
			local tip = rawget(env, "GuideTooltip")
			if tip then ns.Guard(Dress, tip, Kit) end
		end)
		PaintAll()
	end)
	Kick()
end)

ns.me.On("StyleChanged", function() if started then ns.Guard(PaintAll) end end)
local paintQueued = false
ns.me.On("SettingChanged", function(scope, path)
	if not started or scope ~= "DaylightAddonSkins" or type(path) ~= "string" then return end
	if path == KEY or path == "followDaylight" or string.sub(path, 1, 13) == "look.Journey." then
		if paintQueued then return end
		paintQueued = true
		C_Timer.After(0, function()
			paintQueued = false
			ns.Guard(PaintAll)
		end)
	end
end)

-- The HUD arrow is made by a part of Journey that keeps its own CreateFrame: looked for by name.
ns.Watch(KEY, "JourneyScreenArrow", function(f)
	if On() then Arrow(f) end
end)

ns.Pack(KEY)
