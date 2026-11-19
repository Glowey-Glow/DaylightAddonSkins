-- Keep or Toss (2.0.0 and later): its journal is a look of its own now, drawn from its own art
-- with no game templates (Theme.lua): an open book (light, or dimmed at night), or Minimal, one
-- flat panel, light or dark. Its colors live inside the addon, out of reach, and its book is drawn
-- for dark ink on paper, so DaylightUI's window can't go behind that. What is dressed:
--   * Its words: its own font objects (KeepOrTossFont*: headings, names, body, tabs, small print)
--     in the player's font, their sizes kept, following font and text look changes. That reaches
--     every word it draws: the journal, its settings, what's new, the delete and sale notes.
--   * Its Minimal dark look: the flat panel's warm brown ground, rounded edge and soft shadow give
--     way to DaylightUI's window shell; the line between the list and the item a faint neutral one.
--     The same for the What's new page standing in the journal's place (KeepOrTossNews). Its light
--     ink, gold headings, tabs, buttons, search, marks and scroll bar stay its own.
--   * The look itself: with "Minimal dark look" on (this addon's page, on to start) Keep or Toss is
--     set to its Minimal look in dark mode, the one look of its that can stand on DaylightUI's
--     window; its look and dark mode as they were are kept and put back when that's turned off.
--     A look picked in Keep or Toss afterwards (its settings, its sun / moon switch) is left as
--     picked: the book and Minimal light stay exactly as it draws them.
--   * The sample item on its settings page (2.1.0 and later): a card of its own in the game's
--     tooltip frame (TooltipBackdropTemplate), not a tooltip, so DaylightUI's tooltip skin never
--     sees it. It gets DaylightUI's tooltip look here, as a real tooltip would (only while
--     DaylightUI's Tooltip module is on, in every journal look).
-- Left as it is: the book looks (paper, wax seal, tabs, fleurons), the addon's icon on the corner,
-- the item rims and names in their quality colors, its marks' and meanings' colors, its own
-- tooltip lines (DaylightUI's tooltip), the item page's sample tooltips (the game's tooltip,
-- DaylightUI's look), its minimap button (DaylightUI's addon drawer), What's new's version tabs
-- (2.2.0; its own inks, like its other tabs).
-- (Before 2.0.0 its windows were ButtonFrameTemplate frames: KeepOrTossDetailFrame,
-- KeepOrTossIntroFrame and a KeepOrTossDeleteNotice tooltip. Those are gone.)
local _, ns = ...
if not ns.ok then return end
local L = ns.L

local KEY = "KeepOrToss"

ns.Target(KEY, "Keep or Toss", { window = true, text = true, font = "daylight",
	defaults = { minimal = true }, extraTab = L["Journal Look"],
	extra = function(at)
		return {
			{ label = L["Journal Look"], items = {
				{ type = "toggle", key = at .. "minimal", label = L["Use Its Minimal Dark Look"],
				  desc = L["Keep or Toss's journal in its own Minimal look, in dark mode: the one look of its that Daylight UI's window can go behind. Off: its look and dark mode as they were before. A look you pick in Keep or Toss itself stays as you picked it."] },
			} },
		}
	end })

local function On() return ns.Enabled(KEY) end

-- The look it wears, as it reads it (its Theme.lua: CurrentLook): Minimal with dark mode on.
local function MinimalDark()
	local db = _G.KeepOrTossDB
	return type(db) == "table" and db.theme == "minimal" and db.darkMode and true or false
end

-- ---------------------------------------------------------------------------------------------
-- Its words
-- ---------------------------------------------------------------------------------------------
-- Every word it draws is in one of these font objects (its Theme.lua makes them as it loads, in
-- the game's own face): each takes this addon's text look, from the face, size and outline it was
-- made with.

local FONTS = { "Heading", "Group", "Name", "Body", "Small", "Tiny", "Large", "Tab", "TabFront" }
local made = {}   -- font object -> { path, size, flags } it was made with

local function Words()
	for _, name in ipairs(FONTS) do
		local font = _G["KeepOrTossFont" .. name]
		if type(font) == "table" and type(font.GetFont) == "function" then
			local was = made[font]
			if not was then
				local ok, path, size, flags = pcall(font.GetFont, font)
				if ok and type(path) == "string" and type(size) == "number" and size > 0 then
					was = { path, size, flags or "" }
					made[font] = was
				end
			end
			if was then
				local face, size, flags = ns.FontFor(KEY, was[1], was[2], was[3])
				if face and size then pcall(font.SetFont, font, face, size, flags or "") end
			end
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The Minimal dark look: DaylightUI's window under its panel
-- ---------------------------------------------------------------------------------------------
-- Its flat panel (a frame of the journal's with a Paint method, painted each time the look is
-- put on) draws its ground and edge as BACKGROUND and BORDER pictures, the line between the list
-- and the item on ARTWORK, and its soft shadow in a frame of its own. In the dark one those go out
-- of sight over a holder of ours with the window shell (one level under the panel, so the panel's
-- line and everything on it stay in front); in any other look they're put back and the holder hides.

local function Ground(frame, alpha)
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == "Texture" then
			local layer = region:GetDrawLayer()
			if layer == "BACKGROUND" or layer == "BORDER" then region:SetAlpha(alpha) end
		end
	end
end

local function Holder(frame, below)
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetAllPoints(frame)
	holder:SetFrameLevel(math.max(0, frame:GetFrameLevel() - (below and 1 or 0)))
	holder:Hide()
	ns.Shell(holder, { window = true }, KEY)
	return holder
end

local panels = setmetatable({}, { __mode = "k" })   -- its panel -> our holder

local function PaintPanel(panel, colours)
	local holder = panels[panel]
	if not holder then return end
	-- (Its dark Minimal panel is near black, its light one caramel.)
	local back = type(colours) == "table" and type(colours.panel) == "table" and colours.panel[1]
	local dress = On() and type(back) == "number" and back < 0.5
	holder:SetShown(dress)
	Ground(panel, dress and 0 or 1)
	for _, child in ipairs({ panel:GetChildren() }) do
		if child ~= holder then child:SetAlpha(dress and 0 or 1) end   -- its shadow
	end
	if dress then
		for _, region in ipairs({ panel:GetRegions() }) do
			if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "ARTWORK" then
				region:SetColorTexture(1, 1, 1, 0.08)
			end
		end
	end
end

local function Journal(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and type(child.Paint) == "function" and not panels[child] then
			-- (Made before the holder, its own shadow is the panel's only child frame.)
			panels[child] = Holder(child, true)
			ns.HookOnce(child, "Paint", PaintPanel, KEY)
			-- Painted once already as the journal was made, in the look it had then: the look it
			-- wears now is put on as the journal opens (its OnShow); until then the holder waits.
		end
	end
end

-- What's new, standing in the journal's place: a page of its own, painted (paper, or the Minimal
-- panel's ground and edge on the page itself) just before it shows. Its words and buttons are
-- frames a level up and its shadow one down, so the holder takes the page's own level.
local cover
local function Cover()
	local news = _G.KeepOrTossNews
	if not ns.Usable(news) then return end
	if not cover then cover = Holder(news) end
	local dress = On() and MinimalDark()
	cover:SetShown(dress)
	Ground(news, dress and 0 or 1)
end

-- ---------------------------------------------------------------------------------------------
-- The settings page's sample item: DaylightUI's tooltip look
-- ---------------------------------------------------------------------------------------------
-- The card (a TooltipBackdropTemplate frame, kept as .card on its part) is made, private to it,
-- the first time the settings page is built, inside the call that opens the page: nothing of it
-- can be hooked. It is looked for once, the frame after the journal or one of its pages opens or
-- after a click while the journal is open, until found; from then on it is settled each time it
-- is filled (SetHeight) or shown. The game's tooltip art stays out of sight under the shell.

local API = ns.API
local card, cardShell

local function TipLook()
	return { borderPx = 3, flat = true, noBevel = true, bgAlpha = ns.TipAlpha() }
end

local function Settle()
	if not ns.Usable(card) then return end
	local dress = On() and ns.ModuleOn("Tooltip")
	if dress and not cardShell then
		cardShell = CreateFrame("Frame", nil, card)
		cardShell:SetAllPoints(card)
		ns.Guard(API.Skin, cardShell, TipLook())
	end
	if cardShell then
		cardShell:SetShown(dress)
		-- (A level under the card's own, so its words stay in front: put back after every change
		-- of the card's level, which takes its children up with it.)
		cardShell:SetFrameLevel(math.max(0, card:GetFrameLevel() - 1))
	end
	if ns.Usable(card.NineSlice) then card.NineSlice:SetAlpha(dress and 0 or 1) end
end

local function FindCard(f, depth)
	if card or depth > 8 or not ns.Usable(f) then return end
	local c = rawget(f, "card")
	if type(c) == "table" and ns.Usable(c) and c.NineSlice and c.AddDoubleLine then
		card = c
		ns.HookOnce(card, "SetHeight", Settle, KEY)
		ns.ScriptOnce(card, "OnShow", Settle, KEY)
		Settle()
		return
	end
	for _, child in ipairs({ f:GetChildren() }) do
		FindCard(child, depth + 1)
		if card then return end
	end
end

local clicks
local function LookForCard()
	if card then
		if clicks then clicks:UnregisterAllEvents() end
		return
	end
	ns.Queue("KeepOrToss.card", function() FindCard(_G.KeepOrTossFrame, 0) end, KEY)
end

-- DaylightUI's tooltip opacity changed: the card follows; this skin or DaylightUI's Tooltip
-- module switched: it's dressed or given back.
ns.me.On("SettingChanged", function(scope, path)
	if not card then return end
	if cardShell and ns.TipAlphaChanged(scope, path) then ns.Guard(API.Skin, cardShell, TipLook()) end
	ns.Guard(Settle)
end)

-- ---------------------------------------------------------------------------------------------
-- The look: Minimal, dark (a plain option of this addon's page; what it was is kept)
-- ---------------------------------------------------------------------------------------------

ns.Handover(KEY, {
	ready = function() return type(_G.KeepOrTossDB) == "table" end,
	get = function(key)
		local db = _G.KeepOrTossDB
		if key == "theme" then return db.theme or "book" end
		-- (It reads an unset dark mode as light.)
		if key == "dark" then return db.darkMode and "dark" or "light" end
	end,
	set = function(key, value)
		local db = _G.KeepOrTossDB
		if key == "theme" then db.theme = value end
		if key == "dark" then db.darkMode = value == "dark" end
	end,
	list = {
		{ key = "theme", switch = "minimal", off = "minimal", ours = function() return true end },
		{ key = "dark", switch = "minimal", off = "dark", ours = function() return true end },
	},
})

-- ---------------------------------------------------------------------------------------------

ns.Pack(KEY, nil, function()
	if not On() then return end
	local frame = _G.KeepOrTossFrame
	if not ns.Usable(frame) or type(frame.GetChildren) ~= "function" then return false end
	Words()
	-- (Made as it loads, painted in its look again as it opens.)
	Journal(frame)
	-- What's new is made the first time it's shown, and painted just before.
	ns.Watch(KEY, "KeepOrTossNews", function(news)
		ns.ScriptOnce(news, "OnShow", function() ns.Guard(Cover) end, KEY)
		ns.Guard(Cover)
	end)
	-- The settings page's sample card, once it's made (see above).
	if API and type(API.Skin) == "function" then
		if not clicks then
			clicks = CreateFrame("Frame")
			clicks:SetScript("OnEvent", LookForCard)
		end
		ns.ScriptOnce(frame, "OnShow", function()
			if not card then clicks:RegisterEvent("GLOBAL_MOUSE_UP") end
			LookForCard()
		end, KEY)
		ns.ScriptOnce(frame, "OnHide", function() clicks:UnregisterAllEvents() end, KEY)
		-- (Shown with every page laid over the journal, just before the page is built.)
		local sheet = _G.KeepOrTossSheet
		if ns.Usable(sheet) then ns.ScriptOnce(sheet, "OnShow", LookForCard, KEY) end
		if frame:IsShown() and not card then
			clicks:RegisterEvent("GLOBAL_MOUSE_UP")
			LookForCard()
		end
	end
	-- Its words follow a new DaylightUI font, and this addon's text look.
	ns.me.On("StyleChanged", function() ns.Guard(Words) end)
	ns.me.On("SettingChanged", function(scope, path)
		if scope == "DaylightAddonSkins" and type(path) == "string"
			and (path == "followDaylight" or string.sub(path, 1, #KEY + 6) == "look." .. KEY .. ".") then
			ns.Guard(Words)
		end
	end)
end)
