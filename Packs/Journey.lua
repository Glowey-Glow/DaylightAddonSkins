-- Journey (the guide addon): every part of it in the DaylightUI look, each part with its own setting
-- on this plugin's Journey page.
-- Journey keeps its code in an environment of its own; JGADDON (which it puts in _G) leads to it,
-- so its frames are not hunted for: its CreateFrame is followed, and each frame it makes is dressed
-- the frame after it was made, once Journey has set it up. What is dressed:
--   the guide header, the step boxes and the "something should be here" box: DaylightUI's shell in
--     place of the glue-tooltip backdrop; a box the guide marks with a colour gets a bar in it
--   the progress bar (the accent, its own colour, or Journey's blue), the logo (shown or not)
--   the step buttons: flat in the step's own colour, DaylightUI's buttons, or Journey's art
--   the item / target buttons beside the guide: square icons with a thin border
--   the guide menu and its submenu, Advanced Options, the link popup: shells, buttons, text box;
--     menu rows lit and checked in the accent
--   the guide tooltip: DaylightUI's shell
--   the HUD arrow's labels: the player's font, its distance in the accent
--   every string: the player's font, size, outline and shadow, and DaylightUI's text colours
--   the colours of quests, NPCs, items, places, flights and levels in the step text (optional)
-- Journey's sliders and its header arrows and gear are left as it draws them.
-- Nothing is written to Journey's saved settings, and none of its files are touched.
local _, ns = ...
if not ns.ok then return end

local KEY = "Journey"

-- ---------------------------------------------------------------------------------------------
-- Its page: the settings of its own, under the "Journey" tab
-- ---------------------------------------------------------------------------------------------

-- Journey's own colours, the defaults of the link colours.
local function Hex(s)
	return { tonumber(s:sub(1, 2), 16) / 255, tonumber(s:sub(3, 4), 16) / 255, tonumber(s:sub(5, 6), 16) / 255 }
end

-- setting = { label, Journey's colour names it stands for, its default }
local LINKS = {
	{ "linkQuest", "Quests to do", { "QUEST", "QUEST_DO" }, Hex("0084EB") },
	{ "linkAccept", "Quests to accept", { "QUEST_ACCEPT" }, Hex("FFFF00") },
	{ "linkTurnin", "Quests to turn in", { "QUEST_TURNIN" }, Hex("FFA500") },
	{ "linkFriendly", "Friendly NPCs", { "NPC_FRIENDLY" }, Hex("9DFF9D") },
	{ "linkHostile", "Hostile NPCs", { "NPC_HOSTILE" }, Hex("FF6363") },
	{ "linkNeutral", "Neutral NPCs", { "NPC_NEUTRAL" }, Hex("FFD100") },
	{ "linkObject", "Items, objects, spells and other NPCs", { "ITEM", "GAME_OBJECT", "SPELL", "SKILL", "NPC", "SEARCH_TERM" }, Hex("E36EE4") },
	{ "linkPlace", "Places and zones", { "AREA", "ZONE", "WMOAREA" }, Hex("FFD100") },
	{ "linkTravel", "Flights and inns", { "TAXI", "INN" }, Hex("FFA500") },
	{ "linkLevel", "Levels and experience", { "LEVEL", "XP" }, Hex("FFFF00") },
	{ "linkWarn", "Warnings and tips", { "TIP", "RED_TEXT", "GET_OUT", "QUEST_SKIPPED", "SKIPPED_HEADING" }, Hex("FF0000") },
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
		{ type = "toggle", key = at .. "ownLinks", label = "Use my own link colors",
		  desc = "Off: the quests, NPCs, items and places in the steps keep Journey's colors.", disabled = off },
	}
	for _, l in ipairs(LINKS) do
		linkItems[#linkItems + 1] = { type = "color", key = at .. l[1], label = l[2],
			desc = "Their color in the step text.",
			disabled = function(get) return following(get) or get(at .. "ownLinks") ~= true end }
	end
	return {
		{ label = "Guide window", items = {
			hint(),
			{ type = "toggle", key = at .. "showLogo", label = "Journey logo",
			  desc = "The logo at the left of the guide's header.", disabled = off },
			{ type = "toggle", key = at .. "groupMarks", label = "Marked steps",
			  desc = "A colored bar in the step boxes the guide marks with a color (it drew their border in it).", disabled = off },
			{ type = "dropdown", key = at .. "progress", label = "Progress bar",
			  values = { accent = "The accent", own = "My own color", journey = "Journey's blue" },
			  desc = "The color of the guide's progress bar under the title.", disabled = off },
			{ type = "color", key = at .. "progressColor", label = "Progress bar color",
			  desc = "Its color when \"My own color\" is picked.",
			  disabled = function(get) return following(get) or get(at .. "progress") ~= "own" end },
		} },
		{ label = "Step buttons", items = {
			{ type = "dropdown", key = at .. "stepButtons", label = "Style",
			  values = { flat = "Flat, in the step's color", daylight = "DaylightUI buttons", journey = "As Journey draws them" },
			  desc = "The buttons in the steps (Go to, Skip and the guide's own). Takes hold after a reload.", disabled = off },
			{ type = "slider", key = at .. "buttonTint", label = "Color strength", min = 0.1, max = 0.8, step = 0.05, unit = "%",
			  desc = "How strongly a flat button shows its step's color.",
			  disabled = function(get) return following(get) or get(at .. "stepButtons") ~= "flat" end },
			{ type = "toggle", key = at .. "accentHighlight", label = "Highlighted buttons in the accent",
			  desc = "Off: the button the guide highlights keeps Journey's blue.", disabled = off },
			{ type = "toggle", key = at .. "squareItems", label = "Square item buttons",
			  desc = "The item and target buttons beside the guide: square icons with a thin border. Takes hold after a reload.",
			  disabled = off },
			{ type = "button", label = "Reload interface", func = function() ReloadUI() end },
		} },
		{ label = "Menus, tooltip and arrow", items = {
			{ type = "toggle", key = at .. "menuAccent", label = "Menus in the accent",
			  desc = "The guide menu's rows light up, and its check marks show, in the accent.", disabled = off },
			{ type = "toggle", key = at .. "tooltip", label = "Dress the guide tooltip",
			  desc = "The tooltip of the guide's links in DaylightUI's shell. Takes hold after a reload.", disabled = off },
			{ type = "toggle", key = at .. "arrowAccent", label = "Arrow distance in the accent",
			  desc = "Off: the HUD arrow's distance stays gold.", disabled = off },
		} },
		{ label = "Link colors", items = linkItems },
	}
end

ns.Target(KEY, "Journey Guides", { window = true, controls = true, text = true, shadow = true, colors = true,
	font = "daylight", defaults = DEFAULTS, extra = Extra, extraTab = "Guide" })

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

local API = ns.API
local JUI = rawget(env, "UI")
local Color = rawget(env, "Color")
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
	if Look("daylightAccent") == false then return RGB(Look("accent")) end
	local ok, r, g, b = pcall(API.Accent)
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

-- Which DaylightUI text colour a font takes: gold headings TITLE, white VALUE, grey OFF.
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
local header, tooltip, arrow, logo

local GLUE = "glue%-tooltip%-background"

local function IsGlue(f)
	local info = f.backdropInfo
	return type(info) == "table" and type(info.bgFile) == "string" and info.bgFile:lower():find(GLUE) ~= nil
end

local function GuideFrame()
	local c = JUI.GetComponent("GuideContainer")
	return c and c.frame
end

-- A box the guide marks: Journey drew its border in a colour of the guide's.
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
		if mode == "journey" then
			tex:SetColorTexture(j[1], j[2], j[3])
			tex:SetAlpha(0.5)
		else
			local r, g, b
			if mode == "own" then r, g, b = RGB(Look("progressColor")) else r, g, b = Accent() end
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

-- Journey hands the button's colour to its art as hex / 128.
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
	tooltip = tip
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

-- The link colours, and the highlighted step buttons' colour. Journey's Color table is looked up
-- each time (it could make a new one), and its own colours are taken from it at login, before any
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
