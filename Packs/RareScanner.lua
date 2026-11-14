-- RareScanner, dressed throughout. What's dressed and how:
--   * The alert (RARESCANNER_BUTTON, a secure button): its parchment, dark tooltip edge and the
--     achievement header under the name give way to a flat DaylightUI panel, a quiet band under
--     the name, the name in the bright ink and "click to target" in the label ink. The edge lights
--     up under the mouse instead of its own white border (it recolors that border on every
--     enter and leave, so its pieces are kept out of sight each time). Its close button is
--     DaylightUI's X; the stop / go filter buttons keep their red and green icons (they say which
--     it is) with a soft wash for a hover; the yellow navigation arrows keep their shape, in gray.
--     The loot icons under it are cropped, in a thin edge. A secure button can't be laid out in a
--     fight, so everything that makes or places a frame on it waits for the fight to end: it's
--     done once at load, again as it shows (its ShowButton, which only runs out of combat), and
--     for the loot icons as they're filled, through ns.OutOfCombat. Colors and fonts go on any
--     time.
--   * Its tooltips: the map pins' and chat links' tooltips (LibQTip-1.0RS, plain frames the game's
--     tooltip skin never sees) take DaylightUI's tooltip look; the library lays its own border
--     again on every Acquire, so it's put out of sight after each Acquire and on every show (the
--     library refuses HookScript on these, so its Show is hooked instead). Its
--     gold separator lines become a faint hairline, the gold wash behind its achievement line a
--     quiet gray. The link tooltip's close button is DaylightUI's X. Its game tooltips made after
--     login (the stop / go hints, the explorer's, the explorer's comparison tooltips, the addon
--     compartment's) get the same look the moment they're made, unless DaylightUI's tooltip skin
--     got there first; those made while it loads are DaylightUI's tooltip skin's own. All of it
--     only while DaylightUI's Tooltip module is on, so its tooltips always match the game's; the
--     shells made here follow DaylightUI's tooltip opacity as it's changed.
--   * On the world map: its search box moves up into the map's top bar, left of the filter
--     button, slimmed to the bar and in DaylightUI's input look with a faint hint; the dark round
--     grounds behind the corner
--     buttons' icons are centered on their icons (ns.MapIconGround); the
--     round corner buttons all lose the game's gold ring, the icon alone: the game's own ones
--     through ns.MapRings (shared with the OpenMap pack, so the corner looks the same with either
--     addon loaded), RareScanner's here (a dropdown button, which that pass doesn't look at, so
--     nothing is done twice); the route progress bar is DaylightUI's bar, found as soon as a
--     route can start (the map opening, its map menu, a popup's button) as well as by name.
--   * Its popups (LibDialog-1.0RS, not the game's static popups): DaylightUI's window shell, put
--     back on every Spawn (the library lays its dialog border again on each), its buttons,
--     close button, boxes and switches DaylightUI's.
--   * The explorer (RSExplorerFrame): the window shell in place of its picture ground and stone
--     frame, DaylightUI's close button; the rare list, loot list, info and custom loot panels as
--     quiet wells with their stone frames off; the loot cards' parchment off (a well of their
--     own); the filters, continent and group dropdowns, check boxes, red buttons (the loot
--     toggle's arrow in gray), search and input boxes and scroll bars through DaylightUI's
--     Kit.Auto; the lists' rows as DaylightUI's plain lines with a hairline between them, the
--     picked rare and picked group in the accent; the loot icons cropped in a thin edge (both
--     icon pools and the loot list's); the group names and field labels in DaylightUI's inks
--     (the empty group's black text included), the rare's name and the scan page's heading
--     bright. The drop chance boxes in its loot filter menu get DaylightUI's input look on a
--     frame of ours behind them (a menu takes no new art while it's open).
--   * Its settings: the target marker picker (its own AceGUI widget, RS_Markers, which
--     DaylightUI's Ace3 skin doesn't know) gets DaylightUI's dropdown box and list; the About page
--     its title and field names in DaylightUI's inks and its copy box DaylightUI's; the custom
--     NPC import / export dialog DaylightUI's shell, button, scroll bar and a quiet well round the
--     text. The rest of its settings are AceConfig's, which DaylightUI's Ace3 skin dresses
--     (SharedMedia sound pickers included). What that skin leaves gold is inked here, for every
--     addon's AceConfig pages, not only RareScanner's (Packs/Ace3.lua): a settings tree's
--     lines (Map options' Icons, Timers...) in DaylightUI's label ink at rest and its value ink
--     hovered or picked, and text in GameFontNormal's gold code (Profiles' "Current Profile:"
--     value) in the value ink. Lines and text an addon colored on purpose keep their colors.
--   * The telemetry export window (/rs telemetry export): the shell, title, close button, inset,
--     link box, text area and scroll bar.
-- How the pieces are found: the alert, explorer, import dialog and About page by name; the
-- search box by its mixin, the map button through the map button library's list, tooltips and
-- popups through their libraries' lists, frames made late by a watch on their names.
-- Hooked (post-hooks only): the alert's ShowButton, OnEnter and OnLeave and its loot pool's
-- ShowIfReady; LibQTip's Acquire, Show, AddSeparator and SetLineColor (on the library's tooltip
-- prototype); LibDialog's Spawn and its buttons' clicks; the world map's OnShow and
-- RefreshOverlayFrames and the map button's OnMenuResponse; the explorer's OnShow, its two lists'
-- selection changes (made before the explorer first opens, so the lists' own callbacks run
-- through them) and its loot button's refresh; each list's rows as they're filled; AceGUI's
-- RegisterAsWidget, RegisterAsContainer and Release, the marker picker's SetDisabled (which paints
-- its label gold again), each AceGUI tree's RefreshTree and each AceGUI label's SetText; the
-- addon compartment's hover; DaylightUI's SettingChanged (tooltip opacity).
-- Left as it is: the 3D model over the alert, every item and loot icon's own picture and the loot
-- names' quality colors, the rare list's name colors (a level's difficulty color, gold for a
-- rare without a level: the two golds are too close to tell apart), its portraits with their
-- silver and gold dragon rings (rare or custom) and the mount, pet, toy, appearance and custom
-- badges on its rows, the filtered mark, the achievement shield, the explorer's map and the icons
-- on it, the loot cards' corner pictures, the world map and minimap pins and route lines, the
-- player arrow, its raid warning text, the action bar glow, chat links; its minimap button
-- (DaylightUI's button collector's), its world map menu and explorer menus (the game's menus,
-- which DaylightUI dresses), the hover light inside its map tooltips (a texture private to the
-- library, a soft wash already), and the alert's unused second description line (it never holds
-- text).
local _, ns = ...
if not ns.ok then return end

local KEY = "RareScanner"

ns.Target(KEY, "RareScanner", { window = true, controls = true, text = true, shadow = true,
	colors = true, font = "daylight" })

local BUTTON = _G.RARESCANNER_BUTTON
if type(BUTTON) ~= "table" or type(LibStub) ~= "table" then return end

local API = ns.API
local ROWS_KEY = "DaylightAddonSkins.RareScanner"

-- ---------------------------------------------------------------------------------------------
-- Text
-- ---------------------------------------------------------------------------------------------

local function Ink(fs, role)
	if not ns.Usable(fs) or not fs.SetTextColor then return end
	if ns.Look(KEY, "daylightColors") == false then return end
	local c = ns.Colors()[role]
	if type(c) == "table" then fs:SetTextColor(c[1], c[2], c[3]) end
end

-- The player's font on a string (or text box), from whatever font it has now. Remembered, so a
-- string already done isn't scaled again; one given a new font since is done again.
-- (The face and size it was left with, in two tables of their own: no table made per string.)
local fontedPath = setmetatable({}, { __mode = "k" })
local fontedSize = setmetatable({}, { __mode = "k" })
local function Font(fs)
	if not ns.Usable(fs) or not fs.GetFont or ns.PlainText(KEY) then return end
	local path, size, flags = fs:GetFont()
	if type(size) ~= "number" or size <= 0 then return end
	local lastSize = fontedSize[fs]
	if lastSize and fontedPath[fs] == path and math.abs(lastSize - size) < 0.01 then return end
	ns.SetFont(KEY, fs, path, size, flags)
	local p2, s2 = fs:GetFont()
	fontedPath[fs] = p2
	fontedSize[fs] = s2 or size
end

-- Its gold (GameFontNormal's, and the rare list's 1, 0.85, 0).
local function GoldRGB(r, g, b)
	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return false end
	return r > 0.85 and g > 0.6 and g < 0.9 and b < 0.4
end

local function Gold(fs)
	return GoldRGB(fs:GetTextColor())
end

-- Every string in a window, at any depth (rows and controls included; Font skips what's done).
local SKIP_KINDS = { GameTooltip = true, Model = true, PlayerModel = true, DressUpModel = true,
	ModelScene = true, Cooldown = true, SimpleHTML = true, MessageFrame = true, Minimap = true }

-- (Run over the whole explorer each time it or a panel in it shows: the regions and children are
-- gone through as the game hands them back, with no table made of them.)
local FontsIn

local function FontsAmong(...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if r:GetObjectType() == "FontString" then Font(r) end
	end
end

local function FontsBelow(depth, ...)
	for i = 1, select("#", ...) do FontsIn((select(i, ...)), depth) end
end

FontsIn = function(f, depth)
	if depth > 10 or not ns.Usable(f) then return end
	local kind = f:GetObjectType()
	if SKIP_KINDS[kind] then return end
	FontsAmong(f:GetRegions())
	if kind == "EditBox" then Font(f) end
	FontsBelow(depth + 1, f:GetChildren())
end

-- ---------------------------------------------------------------------------------------------
-- Pieces
-- ---------------------------------------------------------------------------------------------

local function Pixel(tex, h)
	if PixelUtil and PixelUtil.SetHeight then PixelUtil.SetHeight(tex, h) else tex:SetHeight(h) end
end

local function PixelWide(tex, w)
	if PixelUtil and PixelUtil.SetWidth then PixelUtil.SetWidth(tex, w) else tex:SetWidth(w) end
end

-- A picture kept, in gray: its own shape in one of DaylightUI's inks.
local function Grey(tex, ink)
	if not ns.Usable(tex) then return end
	if tex.SetDesaturated then tex:SetDesaturated(true) end
	local c = ns.Colors()[ink or "TEXT"]
	if type(c) == "table" then tex:SetVertexColor(c[1], c[2], c[3]) end
end

-- An item icon: cropped (it's drawn with a rim of its own), kept cropped as it's set again.
local function Crop(icon)
	local Kit = ns.Kit
	if Kit and Kit.KeepCrop and ns.Usable(icon) then ns.Guard(Kit.KeepCrop, icon, 0.08) end
end

-- A thin DaylightUI edge round an icon, on a frame of ours just above it (the icon fills its
-- button, so a shell under it wouldn't show).
local EDGE_LOOK = { noBackground = true, noBevel = true, borderPx = 2 }
local edged = setmetatable({}, { __mode = "k" })   -- icon -> its edge
local function Edge(icon, host)
	if edged[icon] or not ns.Usable(icon) or not ns.Usable(host) then return end
	local o = CreateFrame("Frame", nil, host)
	o:SetAllPoints(icon)
	o:SetFrameLevel(host:GetFrameLevel() + 2)
	o:EnableMouse(false)
	ns.Shell(o, EDGE_LOOK, KEY)
	edged[icon] = o
end

-- A panel inside a window: a quiet darker well with a faint hairline round it, drawn here (its
-- panels are plain frames, no backdrop to soften).
local wells = setmetatable({}, { __mode = "k" })
local function Well(f, alpha)
	if not ns.Usable(f) or wells[f] or not f.CreateTexture then return end
	wells[f] = true
	local ground = f:CreateTexture(nil, "BACKGROUND", nil, -8)
	ground:SetAllPoints(f)
	ground:SetColorTexture(0, 0, 0, alpha or 0.28)
	local function line(a1, a2, wide)
		local t = f:CreateTexture(nil, "BORDER", nil, 7)
		t:SetColorTexture(1, 1, 1, 0.07)
		t:SetPoint(a1, f, a1, 0, 0)
		t:SetPoint(a2, f, a2, 0, 0)
		if wide then Pixel(t, 1) else PixelWide(t, 1) end
	end
	line("TOPLEFT", "TOPRIGHT", true)
	line("BOTTOMLEFT", "BOTTOMRIGHT", true)
	line("TOPLEFT", "BOTTOMLEFT", false)
	line("TOPRIGHT", "BOTTOMRIGHT", false)
end

-- One hairline under a list row (its rows sit edge to edge: a box on each would double the line
-- between them).
local divided = setmetatable({}, { __mode = "k" })
local function Divider(row)
	if divided[row] then return end
	divided[row] = true
	local line = row:CreateTexture(nil, "ARTWORK")
	line:SetColorTexture(1, 1, 1, 0.07)
	line:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 6, 0)
	line:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 0)
	Pixel(line, 1)
end

-- ---------------------------------------------------------------------------------------------
-- Tooltips
-- ---------------------------------------------------------------------------------------------

-- DaylightUI's tooltip look (as its Tooltip module draws the game's), at the opacity set there.
local function TipLook()
	local look = { borderPx = 3, flat = true, noBevel = true }
	local ok, alpha = pcall(API.GetSetting, "Tooltip", "bgAlpha")
	if ok and type(alpha) == "number" then look.bgAlpha = alpha end
	return look
end

-- The game's border out of sight (it's laid again on every show and Acquire), the shell kept
-- just under the tooltip as its level changes.
local function Settle(tip)
	if not ns.Enabled(KEY) or not ns.Usable(tip) then return end
	if ns.Usable(tip.NineSlice) then tip.NineSlice:SetAlpha(0) end
	local Kit = ns.Kit
	local s = Kit and Kit.ShellOf and Kit.ShellOf(tip)
	if type(s) == "table" and s.SetFrameLevel then
		s:SetFrameLevel(math.max(0, tip:GetFrameLevel() - 1))
	end
end

-- A game tooltip it makes after login (or fills with text only, which DaylightUI's tooltip skin
-- doesn't wait for). Not shelled again if DaylightUI's skin already has: when that skin gets to
-- one of ours later, it takes this shell over as its own.
local tipped = setmetatable({}, { __mode = "k" })
local ours = setmetatable({}, { __mode = "k" })     -- tooltips whose shell this pack made
local Shopping
local function Tip(tip)
	if not ns.Usable(tip) or tipped[tip] or tip:GetObjectType() ~= "GameTooltip" then return end
	if not ns.Enabled(KEY) or not ns.ModuleOn("Tooltip") then return end
	tipped[tip] = true
	local Kit = ns.Kit
	if not (Kit and Kit.ShellOf and Kit.ShellOf(tip)) then
		ours[tip] = true
		ns.Guard(API.Skin, tip, TipLook())
	end
	tip:HookScript("OnShow", function(self)
		Settle(self)
		Shopping(self)
	end)
	Settle(tip)
	Shopping(tip)
end

-- Its comparison tooltips, made the first time an item is compared.
Shopping = function(tip)
	if type(tip.shoppingTooltips) ~= "table" then return end
	for _, t in ipairs(tip.shoppingTooltips) do Tip(t) end
end

-- LibQTip-1.0RS (RareScanner's own copy, used by no one else): the map pins' and chat links'
-- tooltips, plain frames from a pool. Its keys all start with "Rs". The library refuses HookScript
-- on its tooltips (it raises an error and hooks nothing), so nothing here hooks one of them: the
-- shell is DaylightUI's plain API.Skin (anchored to the tooltip, so it follows its size with no
-- resize hook), and each show is followed through the library's Show (hooked in the Pack below).
local QT = LibStub("LibQTip-1.0RS", true)
local qtShelled = setmetatable({}, { __mode = "k" })

local function OursQT(tip)
	return type(tip) == "table" and type(tip.key) == "string" and string.find(tip.key, "^Rs") ~= nil
end

local function QTipClose(tip)
	local close = tip.closeButton
	local Kit = ns.Kit
	if Kit and ns.Usable(close) and ns.Controls(KEY) then ns.Guard(Kit.Close, close) end
end

local function QTip(tip)
	if not ns.Usable(tip) or not OursQT(tip) then return end
	if not ns.Enabled(KEY) or not ns.ModuleOn("Tooltip") then return end
	if not qtShelled[tip] then
		qtShelled[tip] = true
		ours[tip] = true
		ns.Guard(API.Skin, tip, TipLook())
	end
	Settle(tip)
	QTipClose(tip)
end

-- Its tooltips' opacity follows DaylightUI's tooltip opacity as it's changed.
local function Reopacity()
	local look = TipLook()
	for tip in pairs(ours) do
		if ns.Usable(tip) then ns.Guard(API.Skin, tip, look) end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The alert
-- ---------------------------------------------------------------------------------------------

local RECENT_HEADER = "Interface\\AchievementFrame\\UI-Achievement-RecentHeader"
local HEADER_IDS
local function IsHeader(tex)
	if not HEADER_IDS then HEADER_IDS = ns.FileIDs({ [RECENT_HEADER] = true }) end
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return false end
	if type(file) == "string" then file = string.lower(file) end
	return HEADER_IDS[file] == true
end

local ALERT_LOOK = { noBevel = true, borderPx = 2, bgAlpha = 0.92 }
local alertDone = false

local function AlertText()
	Font(BUTTON.Title)
	Ink(BUTTON.Title, "VALUE")
	Font(BUTTON.Description_text)
	Ink(BUTTON.Description_text, "LABEL")
end

-- Its border recolored on enter and leave: its pieces kept out of sight, our edge lit instead.
local function AlertHover(over)
	local Kit = ns.Kit
	if not Kit then return end
	Kit.Backdrop(BUTTON)
	local s = Kit.ShellOf and Kit.ShellOf(BUTTON)
	if type(s) == "table" then ns.Guard(Kit.Paint, s, over and Kit.ROW_HOVER or nil) end
end

-- The stop / go buttons: their icons kept, the red glow of the close-button template they come
-- from a soft wash. Their hint tooltips are made on the first hover.
local function StopGo(Kit, b)
	if not ns.Usable(b) or not ns.Once(b) then return end
	local hl = b.GetHighlightTexture and b:GetHighlightTexture()
	if ns.Usable(hl) then Kit.Hide(hl) end
	ns.Guard(Kit.HoverWash, b)
	b:HookScript("OnEnter", function(self)
		if ns.Enabled(KEY) then Tip(self.tooltip) end
	end)
end

-- The loot icons under it, as they're filled (perhaps in a fight: their edge waits for it to end).
-- Filled in a fight: each icon's edge waits once for the fight to end (it's filled again with
-- every alert), all of them in one go.
local edgeLater = setmetatable({}, { __mode = "k" })   -- icon -> its loot button
local edgeQueued = false
local function EdgeAfterFight()
	edgeQueued = false
	for icon, host in pairs(edgeLater) do
		edgeLater[icon] = nil
		ns.Guard(Edge, icon, host)
	end
end

local function AlertLoot()
	local bar = BUTTON.LootBar
	local pool = bar and bar.itemFramesPool
	if type(pool) ~= "table" or type(pool.EnumerateActive) ~= "function" then return end
	for f in pool:EnumerateActive() do
		if ns.Usable(f) and ns.Usable(f.Icon) then
			Crop(f.Icon)
			if not edged[f.Icon] then
				if InCombatLockdown() then
					edgeLater[f.Icon] = f
					if not edgeQueued then
						edgeQueued = true
						ns.OutOfCombat(EdgeAfterFight)
					end
				else
					ns.Guard(Edge, f.Icon, f)
				end
			end
		end
	end
end

-- Once, out of combat.
local function Alert(Kit)
	if alertDone or InCombatLockdown() then return end
	alertDone = true
	Kit.Backdrop(BUTTON)
	local bg = BUTTON:GetNormalTexture()
	if ns.Usable(bg) then Kit.Hide(bg) end
	for _, r in ipairs({ BUTTON:GetRegions() }) do
		if r:GetObjectType() == "Texture" and IsHeader(r) then
			r:SetTexture(nil)
			r:SetColorTexture(0, 0, 0, 0.3)
		end
	end
	ns.Shell(BUTTON, ALERT_LOOK, KEY)
	AlertText()
	if ns.Controls(KEY) and ns.Usable(BUTTON.CloseButton) then
		ns.Guard(Kit.Close, BUTTON.CloseButton)
	end
	StopGo(Kit, BUTTON.FilterEntityButton)
	StopGo(Kit, BUTTON.UnFilterEntityButton)
	for _, nav in ipairs({ BUTTON.NextButton, BUTTON.PreviousButton }) do
		if ns.Usable(nav) then
			Grey(nav.Texture, "TEXT")
			Grey(nav.HighlightTexture, "VALUE")
		end
	end
	AlertLoot()
end

-- ---------------------------------------------------------------------------------------------
-- The world map
-- ---------------------------------------------------------------------------------------------

local searchDone = false
-- Its own box sat over the middle of the map's top edge, on the map itself. It moves up into the
-- map's top bar (the slim row DaylightUI makes of it, with the zone dropdowns), just left of the
-- map's filter button at the bar's right end, slimmed to the bar's height, in DaylightUI's input
-- look with a faint "Search rares" hint while it's empty. Its frame and box are RareScanner's
-- own (nothing of DaylightUI's or the game's is moved); its setting still shows or hides it, and
-- typing and Enter work as RareScanner's always did.
local SEARCH_W, SEARCH_H = 180, 22

local function SearchHint(eb)
	local hint = eb.daylightHint
	if not hint then
		hint = API.Text(eb, "small", "LEFT")
		hint:SetPoint("LEFT", eb, "LEFT", 8, 0)
		hint:SetPoint("RIGHT", eb, "RIGHT", -22, 0)
		hint:SetWordWrap(false)
		hint:SetText("Search rares")
		eb.daylightHint = hint
		local function update()
			local text = eb:GetText()
			hint:SetShown(not eb:HasFocus() and (type(text) ~= "string" or text == ""))
		end
		eb:HookScript("OnTextChanged", update)
		eb:HookScript("OnEditFocusGained", update)
		eb:HookScript("OnEditFocusLost", update)
		eb:HookScript("OnShow", update)
		update()
	end
	local ink = ns.Colors().OFF
	hint:SetTextColor(ink[1], ink[2], ink[3])
end

local function SearchPlace(c, eb)
	local map = _G.WorldMapFrame
	local filter = ns.Usable(map) and map.WorldMapTrackingOptionsButton
	if not ns.Usable(filter) then return end
	c:ClearAllPoints()
	c:SetPoint("RIGHT", filter, "LEFT", -8, 0)
	c:SetSize(SEARCH_W, SEARCH_H)
	eb:ClearAllPoints()
	eb:SetAllPoints(c)
	eb:SetTextInsets(8, 8, 0, 0)
end

-- -----------------------------------------------------------------------------------------
-- The search box's extras: a clear X, the text kept when it's clicked, and suggestions
-- -----------------------------------------------------------------------------------------
-- A little X at the box's right end (DaylightUI's close X, as on the quest journal's search),
-- shown while there's text: it clears the box and RareScanner's search with it. RareScanner's box
-- clears itself (and its search) whenever it's clicked; here a click only puts the cursor in it,
-- so a search stays until the X is clicked. (That click handler is the one script of
-- RareScanner's taken off, and only its box's.)
-- Suggestions: the rares on the map being looked at, by name, read from RareScanner's own pins
-- (a single rare's pin and each rare in a grouped one) every time it lays them out, and kept per
-- map, so a search that's on doesn't shrink the list. As the player types, those whose names hold
-- the text (any case; names starting with it first) show in a small list under the box, eight at
-- most; a click or Up / Down and Enter picks one and runs RareScanner's search on it. Matching a
-- few dozen names per key press costs next to nothing; the pins are only read when RareScanner
-- lays them out anyway.
local SUGGEST_MAX, SUGGEST_ROW = 8, 20
local rareNames = {}          -- mapID -> { [name] = the name in lower case }
local suggestList, suggestRows, suggestPick = nil, {}, 0
local suggested = {}          -- the names shown, in order (reused)
local startsWith = {}         -- name -> whether it starts with what's typed (reused)
local pickedName              -- the name Up / Down is on (kept past the box losing focus on Enter)

-- Names starting with what's typed first, then in order.
local function SuggestOrder(a, b)
	local sa, sb = startsWith[a], startsWith[b]
	if sa ~= sb then return sa end
	return a < b
end

local function NamesFor(mapID)
	local t = rareNames[mapID]
	if not t then
		t = {}
		rareNames[mapID] = t
	end
	return t
end

local function AddName(t, poi)
	local name = type(poi) == "table" and poi.name
	-- (Its lower case, kept: what's typed is matched against it on every key press.)
	if type(name) == "string" and name ~= "" and not t[name] then t[name] = string.lower(name) end
end

-- RareScanner has just laid its pins out on the world map: their names are read.
local function ReadPins(provider)
	local ok, map = pcall(provider.GetMap, provider)
	if not ok or type(map) ~= "table" or type(map.EnumeratePinsByTemplate) ~= "function" then return end
	local mapID = map.GetMapID and map:GetMapID()
	if not mapID then return end
	local t = NamesFor(mapID)
	for pin in map:EnumeratePinsByTemplate("RSEntityPinTemplate") do AddName(t, pin.POI) end
	for pin in map:EnumeratePinsByTemplate("RSGroupPinTemplate") do
		local pois = type(pin.POI) == "table" and pin.POI.POIs
		if type(pois) == "table" then
			for _, poi in ipairs(pois) do AddName(t, poi) end
		end
	end
end

local function SuggestHide()
	suggestPick = 0
	if suggestList then suggestList:Hide() end
end

local function SuggestPaint()
	local c = ns.Colors()
	for i, row in ipairs(suggestRows) do
		local on = i == suggestPick
		local ink = on and c.VALUE or c.TEXT
		row.text:SetTextColor(ink[1], ink[2], ink[3])
		row.wash:SetShown(on or row:IsMouseOver())
		if on then
			local r, g, b = ns.AccentOf(KEY)
			row.wash:SetColorTexture(r, g, b, 0.18)
		else
			row.wash:SetColorTexture(1, 1, 1, 0.06)
		end
	end
end

local function Run(eb, text)
	eb:SetText(text)
	eb:SetCursorPosition(#text)
	SuggestHide()
	if type(eb.RefreshAll) == "function" then pcall(eb.RefreshAll, eb) end
end

local function SuggestBuild(eb)
	if suggestList then return end
	local list = CreateFrame("Frame", nil, eb)
	suggestList = list
	list:SetFrameStrata("FULLSCREEN_DIALOG")
	list:SetPoint("TOPLEFT", eb, "BOTTOMLEFT", 0, -2)
	list:SetPoint("TOPRIGHT", eb, "BOTTOMRIGHT", 0, -2)
	list:Hide()
	ns.Guard(API.Skin, list, { noBevel = true, borderPx = 2, bgAlpha = 0.95 })
	for i = 1, SUGGEST_MAX do
		local row = CreateFrame("Button", nil, list)
		row:SetHeight(SUGGEST_ROW)
		row:SetPoint("TOPLEFT", list, "TOPLEFT", 3, -3 - (i - 1) * SUGGEST_ROW)
		row:SetPoint("TOPRIGHT", list, "TOPRIGHT", -3, -3 - (i - 1) * SUGGEST_ROW)
		row.wash = row:CreateTexture(nil, "BACKGROUND")
		row.wash:SetAllPoints(row)
		row.wash:Hide()
		row.text = API.Text(row, "small", "LEFT")
		row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
		row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
		row.text:SetWordWrap(false)
		row:SetScript("OnEnter", SuggestPaint)
		row:SetScript("OnLeave", function()
			SuggestPaint()
			-- Left behind by a click elsewhere while the mouse was on it: closed once it's left.
			if not eb:HasFocus() and not list:IsMouseOver() then SuggestHide() end
		end)
		row:EnableMouse(true)
		row:RegisterForClicks("LeftButtonUp")
		row:SetScript("OnClick", function(self)
			if self.name then
				Run(eb, self.name)
				eb:ClearFocus()
			end
		end)
		suggestRows[i] = row
	end
end

local function Suggest(eb)
	if not ns.Enabled(KEY) or not eb:HasFocus() then return SuggestHide() end
	local text = eb:GetText()
	text = type(text) == "string" and string.lower(text) or ""
	if text == "" then return SuggestHide() end
	local mapID = _G.WorldMapFrame and _G.WorldMapFrame.GetMapID and _G.WorldMapFrame:GetMapID()
	local names = mapID and rareNames[mapID]
	if not names then return SuggestHide() end
	wipe(suggested)
	wipe(startsWith)
	for name, lower in pairs(names) do
		-- The exact name typed already: nothing left to suggest for it.
		if lower ~= text then
			local at = string.find(lower, text, 1, true)
			if at then
				suggested[#suggested + 1] = name
				startsWith[name] = at == 1
			end
		end
	end
	if #suggested == 0 then return SuggestHide() end
	table.sort(suggested, SuggestOrder)
	SuggestBuild(eb)
	local n = math.min(#suggested, SUGGEST_MAX)
	for i, row in ipairs(suggestRows) do
		local name = i <= n and suggested[i] or nil
		row.name = name
		row.text:SetText(name or "")
		row:SetShown(name ~= nil)
	end
	if suggestPick > n then suggestPick = 0 end
	suggestList:SetHeight(n * SUGGEST_ROW + 6)
	suggestList:Show()
	SuggestPaint()
end

local function SearchExtras(eb)
	-- The clear X.
	local clear = API.Close(eb, function()
		Run(eb, "")
		eb:ClearFocus()
	end, 16, 10)
	clear:SetPoint("RIGHT", eb, "RIGHT", -3, 0)
	eb:SetTextInsets(8, 22, 0, 0)
	local function showClear()
		local text = eb:GetText()
		clear:SetShown(type(text) == "string" and text ~= "")
	end
	showClear()
	-- A click puts the cursor in it and leaves the search as it is.
	eb:SetScript("OnMouseDown", nil)
	eb:HookScript("OnTextChanged", function(self, user)
		showClear()
		if user then
			suggestPick = 0
			pickedName = nil
			Suggest(self)
		end
	end)
	eb:HookScript("OnEditFocusGained", function(self)
		pickedName = nil
		Suggest(self)
	end)
	-- Clicking a name takes the focus off the box before the click reaches the name: the list stays
	-- while the mouse is on it, so the click lands.
	eb:HookScript("OnEditFocusLost", function()
		if suggestList and suggestList:IsShown() and suggestList:IsMouseOver() then return end
		SuggestHide()
	end)
	eb:HookScript("OnHide", SuggestHide)
	-- Up and Down move through the list; Enter on a picked name searches for it (RareScanner's
	-- own Enter has already searched what was typed).
	eb:HookScript("OnArrowPressed", function(_, key)
		if not (suggestList and suggestList:IsShown()) then return end
		local n = 0
		for _, row in ipairs(suggestRows) do
			if row:IsShown() then n = n + 1 end
		end
		if n == 0 then return end
		if key == "DOWN" then
			suggestPick = suggestPick % n + 1
		elseif key == "UP" then
			suggestPick = (suggestPick - 2) % n + 1
		end
		local row = suggestRows[suggestPick]
		pickedName = row and row.name or nil
		SuggestPaint()
	end)
	-- (RareScanner's Enter has dropped the focus, and with it the list, by the time this runs.)
	eb:HookScript("OnEnterPressed", function(self)
		local name = pickedName
		pickedName = nil
		if name then Run(self, name) else SuggestHide() end
	end)
	eb:HookScript("OnEscapePressed", function()
		pickedName = nil
		SuggestHide()
	end)
	-- The pins' names, each time RareScanner lays them out.
	local provider = _G.RareScannerDataProviderMixin
	if type(provider) == "table" and type(provider.RefreshAllData) == "function" then
		hooksecurefunc(provider, "RefreshAllData", function(self)
			if ns.Enabled(KEY) then ns.Guard(ReadPins, self) end
		end)
		ns.Guard(ReadPins, provider)
	end
end

-- Its box among the map's children (looked for on each map opening until it's found).
local function SearchAmong(refresh, ...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		local eb = ns.Usable(c) and c.EditBox
		if ns.Usable(eb) and eb.RefreshAll == refresh then return c, eb end
	end
end

local function SearchBox(Kit)
	local map = _G.WorldMapFrame
	local mixin = _G.RSSearchBoxMixin
	if searchDone or not ns.Usable(map) or type(mixin) ~= "table" then return end
	local c, eb = SearchAmong(mixin.RefreshAll, map:GetChildren())
	if not c then return end
	searchDone = true
	SearchPlace(c, eb)
	if ns.Controls(KEY) then
		-- Its three chat-input pieces have no names: every texture on it goes.
		Kit.Strip(eb)
		ns.Guard(Kit.EditBox, eb)
	end
	Font(eb)
	SearchHint(eb)
	ns.Guard(SearchExtras, eb)
end

-- The route progress bar (made the first time a route is worked out): looked for by a watch on
-- its name, and straight away wherever a route can start (the map opening, its map menu, a
-- popup's button), so its old art doesn't show for the watch's moment.
local function RouteBar(bar, Kit)
	if not ns.Usable(bar) or not ns.Once(bar) then return end
	ns.NoBackdrop(bar)
	if ns.Usable(bar.statusBar) then ns.Guard(Kit.StatusBar, bar.statusBar) end
	Font(bar.text)
end

local function RouteNow()
	local bar = _G.RSRouteProgressBar
	if not ns.Usable(bar) or not ns.Enabled(KEY) then return end
	ns.WithKit(function(Kit) RouteBar(bar, Kit) end)
end

local function RouteSoon()
	RouteNow()
	C_Timer.After(0, RouteNow)
end

-- Its button in the map's corner (from the map button library, made when the map first loads or
-- when its option is turned on): the gold ring off, the icon alone.
-- (ns.MapRings, shared with OpenMap's pack, does the game's own corner buttons; it looks at plain
-- buttons only, and this one is a dropdown button.)
local ringed = setmetatable({}, { __mode = "k" })
local function MapButton()
	local lib = LibStub("Krowi_WorldMapButtons-1.4", true)
	local mixin = _G.RSWorldMapButtonMixin
	if type(lib) ~= "table" or type(lib.Buttons) ~= "table" or type(mixin) ~= "table" then return end
	for _, b in ipairs(lib.Buttons) do
		if ns.Usable(b) and not ringed[b] and b.Refresh == mixin.Refresh then
			ringed[b] = true
			if ns.Usable(b.Border) then b.Border:SetAlpha(0) end
			ns.MapIconGround(b)
			-- Its menu starts and resets routes.
			if type(b.OnMenuResponse) == "function" then
				hooksecurefunc(b, "OnMenuResponse", function() RouteSoon() end)
			end
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- Popups
-- ---------------------------------------------------------------------------------------------

local LD = LibStub("LibDialog-1.0RS", true)
local dialogs = setmetatable({}, { __mode = "k" })
local routeHooked = setmetatable({}, { __mode = "k" })

local function Dialog(Kit, d)
	if not ns.Usable(d) then return end
	ns.NoBackdrop(d)
	if not dialogs[d] then
		dialogs[d] = true
		ns.Shell(d, { window = true }, KEY)
	end
	Font(d.text)
	if not ns.Controls(KEY) then return end
	if ns.Usable(d.close_button) then ns.Guard(Kit.Close, d.close_button) end
	for _, b in ipairs(type(d.buttons) == "table" and d.buttons or {}) do
		if ns.Usable(b) then
			ns.Guard(Kit.Button, b)
			-- (The route reset popup's Yes starts a new route.)
			if not routeHooked[b] then
				routeHooked[b] = true
				b:HookScript("OnClick", function() RouteSoon() end)
			end
		end
	end
	for _, e in ipairs(type(d.editboxes) == "table" and d.editboxes or {}) do
		if ns.Usable(e) then
			ns.Guard(Kit.EditBox, e)
			Font(e)
		end
	end
	for _, c in ipairs(type(d.checkboxes) == "table" and d.checkboxes or {}) do
		if ns.Usable(c) then ns.Guard(Kit.Check, c) end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The explorer
-- ---------------------------------------------------------------------------------------------

-- Its loot icons (the info panel's and the custom group's, both pooled): dressed here, and left
-- out of Kit.Auto's walk, which would give them the game's item look.
local ownItems = setmetatable({}, { __mode = "k" })

local function LootIcon(b)
	if not ns.Usable(b) or not ns.Usable(b.Icon) then return end
	ownItems[b] = true
	if ns.Usable(b.IconBorder) then b.IconBorder:SetAlpha(0) end
	Crop(b.Icon)
	Edge(b.Icon, b)
end

local function Pool(pool)
	if type(pool) ~= "table" or type(pool.EnumerateActive) ~= "function" then return end
	for b in pool:EnumerateActive() do LootIcon(b) end
end

-- A name in its gold (GameFontNormal's): the label ink. (It never sets these again.)
local function GoldToLabel(fs)
	if ns.Usable(fs) and Gold(fs) then Ink(fs, "LABEL") end
end

-- The rare list's rows: plain lines, the picked one in the accent. Its collection badges and the
-- filtered mark stay; its portrait frame is a frame of its own and stays too. The names keep its
-- colors: a level's difficulty color, its gold for a rare without one (the two golds are too
-- close to tell apart, and the difficulty one means something).
local RARE_KEEP = { "MountTexture", "PetTexture", "ToyTexture", "AppearanceTexture", "DecorTexture",
	"CustomTexture", "StateIcon" }

-- Its own row art (the Garrison list button, its name band, picked and hover art): kept out of
-- sight every time a row is filled, since the list shows and hides its picked art itself.
local ROW_ART = { "BG", "NameBG", "Selected", "Highlight" }
local function RowArt(row)
	for _, key in ipairs(ROW_ART) do
		local t = row[key]
		if ns.Usable(t) and t.SetAlpha then t:SetAlpha(0) end
	end
	local hl = row.GetHighlightTexture and row:GetHighlightTexture()
	if ns.Usable(hl) then hl:SetAlpha(0) end
end

-- Which row is picked, asked of the list itself (its selection), not read off its picked art:
-- that art is shown and hidden by the list on its own schedule, and a reused row could still
-- carry it from the rare it showed before. Each list's owner is noted as its rows are dressed.
local rowList = setmetatable({}, { __mode = "k" })     -- row -> the list (owner of the selection)
local function Picked(row)
	local list = rowList[row]
	local sel = list and list.selectionBehavior
	if type(sel) ~= "table" or type(sel.IsSelected) ~= "function" then return false end
	local ok, on = pcall(sel.IsSelected, sel, row)
	return ok and on == true
end

-- The picked row's mark: a quiet wash in the accent (as DaylightUI's own lists mark a pick), a
-- texture of ours on each row. Shown purely from the list's selection each time the rows
-- are repainted (no on / off state kept on the row, which a reused row could carry over from the
-- rare it showed before). Repainted a frame after anything changes, once per change, so it's read
-- after the list has finished (on a zone change it fills its rows first and picks the first rare
-- after).
local marks = setmetatable({}, { __mode = "k" })     -- row -> its wash
local PICK_WASH = 0.16
local function PaintPick(row)
	local wash = marks[row]
	if not wash then
		wash = row:CreateTexture(nil, "BACKGROUND", nil, 6)
		wash:SetAllPoints(row)
		marks[row] = wash
	end
	local on = row:IsShown() and Picked(row)
	if on then
		local r, g, b = ns.AccentOf(KEY)
		wash:SetColorTexture(r, g, b, PICK_WASH)
	end
	wash:SetShown(on)
end

local pickBoxes = {}          -- scroll boxes waiting for a repaint (reused)
local pickQueued = false
local function PaintPicksNow()
	pickQueued = false
	for box in pairs(pickBoxes) do
		pickBoxes[box] = nil
		if ns.Usable(box) and box.ForEachFrame and ns.Enabled(KEY) then
			pcall(box.ForEachFrame, box, PaintPick)
		end
	end
end

local function PaintPicks(box)
	if not box then return end
	pickBoxes[box] = true
	if not pickQueued then
		pickQueued = true
		C_Timer.After(0, PaintPicksNow)
	end
end

local function RareRow(Kit, row)
	if not ns.Usable(row) then return end
	RowArt(row)
	if not Kit.RowOf(row) then
		local keep = {}
		for _, key in ipairs(RARE_KEEP) do
			if ns.Usable(row[key]) then keep[row[key]] = true end
		end
		ns.Guard(Kit.Row, row, keep, nil, false)
		Divider(row)
	end
	Font(row.Name)
	PaintPick(row)
	if rowList[row] then PaintPicks(rowList[row].scrollBox) end
end

-- The loot list's rows: plain lines; the icon cropped in a thin edge, its filter check
-- DaylightUI's switch, the name in its quality color.
local function LootRow(Kit, row)
	if not ns.Usable(row) then return end
	RowArt(row)
	if not Kit.RowOf(row) then
		local keep = {}
		for _, key in ipairs({ "Icon", "Upgrade" }) do
			if ns.Usable(row[key]) then keep[row[key]] = true end
		end
		ns.Guard(Kit.Row, row, keep, nil, false)
		Divider(row)
		Crop(row.Icon)
		Edge(row.Icon, row)
	end
	if ns.Controls(KEY) and ns.Usable(row.FilterCheck) then ns.Guard(Kit.Check, row.FilterCheck) end
	Font(row.Name)
	Font(row.Chance)
end

-- The custom loot's group list: plain lines, the picked group in the accent.
local function GroupRow(Kit, row)
	if not ns.Usable(row) then return end
	RowArt(row)
	if not Kit.RowOf(row) then
		ns.Guard(Kit.Row, row, nil, nil, false)
		Divider(row)
	end
	GoldToLabel(row.Name)
	Font(row.Name)
	PaintPick(row)
	local list = rowList[row]
	if list and list.GroupList then PaintPicks(list.GroupList.scrollBox) end
end

local listed = setmetatable({}, { __mode = "k" })
local rowOwner = {}
local function List(Kit, box, fn)
	if not ns.Usable(box) or listed[box] or not box.ForEachFrame then return end
	listed[box] = true
	ns.Guard(Kit.EachRow, box, function(row)
		if ns.Enabled(KEY) then fn(Kit, row) end
	end, ROWS_KEY)
	-- And each row as the list fills it (rows filled while the list was hidden included).
	if type(ScrollUtil) == "table" and type(ScrollUtil.AddInitializedFrameCallback) == "function" then
		-- (Registered rows come as owner, row; the ones already there as row, data.)
		ns.Guard(ScrollUtil.AddInitializedFrameCallback, box, function(a, b)
			local row = (type(a) == "table" and a.GetObjectType) and a or b
			if ns.Enabled(KEY) and ns.Usable(row) then ns.Guard(fn, Kit, row) end
		end, rowOwner, true)
	end
end

-- The window's own pieces, once (on its first show).
local QueueExplorer             -- below: the whole window walked on the next frame
local explored = setmetatable({}, { __mode = "k" })
local function Explorer(Kit, f)
	if explored[f] then return end
	explored[f] = true
	ns.Kill(f.Background)
	ns.Kill(f.Border)
	ns.Shell(f, { window = true }, KEY)
	if ns.Controls(KEY) and ns.Usable(f.CloseButton) then ns.Guard(Kit.Close, f.CloseButton) end
	-- The rare and loot lists.
	for _, panel in ipairs({ f.RareNPCList, f.RareLoot }) do
		if ns.Usable(panel) then
			ns.Kill(panel.background)
			Well(panel)
		end
	end
	-- The info panel: its tile ground, shade and stone frame off; the name band stays.
	local info = f.RareInfo
	if ns.Usable(info) then
		ns.Kill(info.BaseFrameBackground)
		ns.Kill(info.BoardDropShadow)
		ns.Kill(info.Border)
		Well(info)
		Font(info.Name)
		Ink(info.Name, "VALUE")
		-- ("Decor": a card of older RareScanner versions, gone from the current info panel; kept so
		-- those still get it, and passed over where it's missing.)
		for _, key in ipairs({ "Mounts", "Pets", "Toys", "Custom", "Appearances", "Decor" }) do
			local card = info[key]
			if ns.Usable(card) then
				ns.Kill(card.Background1)
				Well(card, 0.2)
			end
		end
	end
	-- The custom loot panel.
	local cl = f.CustomLoot
	if ns.Usable(cl) then
		ns.Kill(cl.background)
		ns.Kill(cl.background2)
		ns.Kill(cl.Border)
		Well(cl)
		local control = cl.ControlFrame
		if ns.Usable(control) then
			for _, key in ipairs({ "LootGroupLabel", "LootNewGroupLabel", "ItemListLabel" }) do
				Ink(control[key], "LABEL")
			end
		end
		local group = cl.GroupInfo
		if ns.Usable(group) then
			ns.Kill(group.BG)
			Well(group, 0.2)
			Ink(group.NoItems, "OFF")
		end
	end
	-- The scan page.
	local scan = f.ScanRequired
	if ns.Usable(scan) then Ink(scan.ScanRequiredText, "VALUE") end
	-- The loot panel toggle's arrow.
	local filters = f.Filters
	if ns.Usable(filters) and ns.Usable(filters.ToggleLootButton) then
		Grey(filters.ToggleLootButton.Arrow, "TEXT")
	end
	-- The filter dropdowns' "filters changed" badges.
	if ns.Controls(KEY) then
		for _, panel in ipairs({ filters, f.RareLoot }) do
			local dd = ns.Usable(panel) and panel.FilterDropDown
			if ns.Usable(dd) and ns.Usable(dd.ResetButton) then
				ns.Guard(Kit.ResetBadge, dd.ResetButton)
			end
		end
	end
	-- Its panels come and go on their own: they're hidden as it opens while it finds your zone
	-- (or while a scan is needed) and shown a moment later, after the walk over the window has
	-- passed them by. Each one showing walks the window again.
	local panels = { f.Filters, f.RareNPCList, f.RareLoot, f.RareInfo, f.Control, f.CustomLoot, f.ScanRequired }
	if ns.Usable(cl) then
		panels[#panels + 1] = cl.ControlFrame
		panels[#panels + 1] = cl.GroupInfo
		panels[#panels + 1] = cl.GroupList
	end
	for _, panel in ipairs(panels) do
		if ns.Usable(panel) and panel.HookScript then
			panel:HookScript("OnShow", function() if ns.Enabled(KEY) then QueueExplorer() end end)
		end
	end
	-- The lists' rows, as they're filled.
	if ns.Usable(f.RareNPCList) then List(Kit, f.RareNPCList.scrollBox, RareRow) end
	if ns.Usable(f.RareLoot) then List(Kit, f.RareLoot.scrollBox, LootRow) end
	if ns.Usable(cl) and ns.Usable(cl.GroupList) then List(Kit, cl.GroupList.scrollBox, GroupRow) end
end

-- Everything inside, on the next frame after each show (and when a panel inside shows).
local expQueued = false
local function RunExplorer()
	expQueued = false
	local Kit, f = ns.Kit, _G.RSExplorerFrame
	if not Kit or not ns.Enabled(KEY) or not ns.Usable(f) or not f:IsShown() then return end
	Explorer(Kit, f)
	Pool(f.lootItemsPool)
	local group = f.CustomLoot and f.CustomLoot.GroupInfo
	if ns.Usable(group) then Pool(group.lootItemsPool) end
	Tip(f.Tooltip)
	FontsIn(f, 0)
	if ns.Controls(KEY) then
		-- A walk still going over the window takes no second one: asked again shortly.
		if Kit.Walking and Kit.Walking(f) then
			C_Timer.After(0.2, QueueExplorer)
			return
		end
		ns.Guard(Kit.Auto, f, { skip = ownItems, rows = false, shownOnly = true, onPage = QueueExplorer })
	end
end

QueueExplorer = function()
	if expQueued then return end
	expQueued = true
	C_Timer.After(0, RunExplorer)
end

-- The drop chance boxes in its loot filter menu (RSExplorerLootChanceFilterTemplate rows): their
-- gold box art off, DaylightUI's input look on a frame of ours just behind the box.
local boxed = setmetatable({}, { __mode = "k" })
local function ChanceBox(Kit, row)
	local box = row.Value
	boxed[row] = true
	for _, key in ipairs({ "Left", "Middle", "Right" }) do
		if ns.Usable(box[key]) then Kit.Hide(box[key]) end
	end
	local back = CreateFrame("Frame", nil, row)
	back:SetPoint("TOPLEFT", box, "TOPLEFT", -6, 0)
	back:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 0, 0)
	back:SetFrameLevel(math.max(0, box:GetFrameLevel() - 1))
	back:EnableMouse(false)
	local s = Kit.Shell(back, "input")
	box:HookScript("OnEnter", function()
		if ns.Enabled(KEY) then Kit.Paint(s, Kit.ROW_HOVER) end
	end)
	box:HookScript("OnLeave", function()
		if ns.Enabled(KEY) then Kit.Paint(s, nil) end
	end)
end

local ChanceBoxesIn

local function ChanceBoxesAmong(Kit, depth, ...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		if ns.Usable(c) then
			local box = c.Value
			if not boxed[c] and ns.Usable(box) and box:GetObjectType() == "EditBox" and ns.Usable(c.Label)
				and c.Label.GetObjectType and c.Label:GetObjectType() == "FontString" then
				ns.Guard(ChanceBox, Kit, c)
			elseif depth > 0 then
				ChanceBoxesIn(Kit, c, depth - 1)
			end
		end
	end
end

ChanceBoxesIn = function(Kit, f, depth)
	ChanceBoxesAmong(Kit, depth, f:GetChildren())
end

-- Only while its loot filter menu is the one open.
local function ChanceMenu(menu)
	if not ns.Enabled(KEY) or not ns.Controls(KEY) or not ns.Usable(menu) then return end
	local f = _G.RSExplorerFrame
	local dd = ns.Usable(f) and f.RareLoot and f.RareLoot.FilterDropDown
	if not ns.Usable(dd) or type(dd.IsMenuOpen) ~= "function" or not dd:IsMenuOpen() then return end
	ns.WithKit(function(Kit) ChanceBoxesIn(Kit, menu, 6) end)
end

-- A menu that opened is looked at twice, on the next frame and a moment later. The menus waiting
-- for each look are kept in order, one list per look: the looks are timers of one length each, so
-- they come due in the order the menus opened, and each takes the oldest menu waiting for it.
local soonMenus, soonFirst, soonLast = {}, 1, 0
local lateMenus, lateFirst, lateLast = {}, 1, 0

local function ChanceSoon()
	local menu = soonMenus[soonFirst]
	soonMenus[soonFirst] = nil
	if soonFirst >= soonLast then soonFirst, soonLast = 1, 0 else soonFirst = soonFirst + 1 end
	ChanceMenu(menu)
end

local function ChanceLate()
	local menu = lateMenus[lateFirst]
	lateMenus[lateFirst] = nil
	if lateFirst >= lateLast then lateFirst, lateLast = 1, 0 else lateFirst = lateFirst + 1 end
	ChanceMenu(menu)
end

-- (Every menu anywhere in the game comes through here: one can only be the loot filter's while the
-- explorer is up, and only then is it looked at.)
local function MenuShown(_, menu)
	local f = _G.RSExplorerFrame
	if not (ns.Usable(f) and f:IsShown()) or not ns.Enabled(KEY) or not ns.Controls(KEY) then return end
	soonLast = soonLast + 1
	soonMenus[soonLast] = menu
	C_Timer.After(0, ChanceSoon)
	lateLast = lateLast + 1
	lateMenus[lateLast] = menu
	C_Timer.After(0.1, ChanceLate)
end

-- ---------------------------------------------------------------------------------------------
-- Its settings
-- ---------------------------------------------------------------------------------------------

-- The target marker picker (RS_Markers): a SharedMedia-style box with a list of its own lines.
local markers = setmetatable({}, { __mode = "k" })
local markerLists = setmetatable({}, { __mode = "k" })
local markerLines = setmetatable({}, { __mode = "k" })

local function MarkerList(Kit, w)
	local d = w.dropdown
	if not ns.Usable(d) then return end
	-- Its dialog border is laid again each time the list is handed back.
	Kit.Backdrop(d)
	if not markerLists[d] then
		markerLists[d] = true
		Kit.Shell(d, "window")
		if ns.Usable(d.slider) then
			Kit.Backdrop(d.slider)
			Kit.ScrollThumb(d.slider)
		end
	end
	for _, line in ipairs(type(d.contentRepo) == "table" and d.contentRepo or {}) do
		if ns.Usable(line) then
			if not markerLines[line] then
				markerLines[line] = true
				local hl = line.GetHighlightTexture and line:GetHighlightTexture()
				if ns.Usable(hl) then Kit.Hide(hl) end
				Kit.HoverWash(line)
				Font(line.text)
			end
			-- The picked marker's gold tick: the accent.
			if ns.Usable(line.check) then
				line.check:SetDesaturated(true)
				line.check:SetVertexColor(ns.AccentOf(KEY))
			end
		end
	end
end

local function Markers(Kit, w)
	local f = w.frame
	if markers[w] or not ns.Usable(f) or not ns.Usable(f.dropButton) then return end
	markers[w] = true
	Font(f.label)
	Ink(f.label, w.disabled and "OFF" or "LABEL")
	Font(f.text)
	-- Its SetDisabled paints the label gold again (or gray): ours goes back on each time.
	if type(w.SetDisabled) == "function" then
		hooksecurefunc(w, "SetDisabled", function(self, disabled)
			if not ns.Enabled(KEY) or type(self.frame) ~= "table" then return end
			Ink(self.frame.label, disabled and "OFF" or "LABEL")
		end)
	end
	if not ns.Controls(KEY) then return end
	for _, key in ipairs({ "DLeft", "DMiddle", "DRight" }) do
		if ns.Usable(f[key]) then Kit.Hide(f[key]) end
	end
	-- The box: from the widget's left edge to the end of its arrow, as tall as the arrow.
	local box = CreateFrame("Frame", nil, f)
	box:SetPoint("TOPRIGHT", f.dropButton, "TOPRIGHT", 0, 1)
	box:SetPoint("BOTTOMRIGHT", f.dropButton, "BOTTOMRIGHT", 0, -1)
	box:SetPoint("LEFT", f, "LEFT", 0, 0)
	box:SetFrameLevel(f:GetFrameLevel())
	box:EnableMouse(false)
	local s = Kit.Shell(box, "input")
	ns.Guard(Kit.BareButton, f.dropButton, "down")
	f.dropButton:HookScript("OnEnter", function()
		if ns.Enabled(KEY) then Kit.Paint(s, Kit.ROW_HOVER) end
	end)
	f.dropButton:HookScript("OnLeave", function()
		if ns.Enabled(KEY) then Kit.Paint(s, nil) end
	end)
	f.dropButton:HookScript("OnClick", function()
		if ns.Enabled(KEY) then ns.Guard(MarkerList, Kit, w) end
	end)
end

-- AceGUI is shared and a newer copy may replace it when another addon loads: hooked again then.
local aceHooked
local function HookAce()
	local AG = LibStub("AceGUI-3.0", true)
	if type(AG) ~= "table" or type(AG.RegisterAsWidget) ~= "function" then return end
	if AG.RegisterAsWidget == aceHooked then return end
	hooksecurefunc(AG, "RegisterAsWidget", function(_, w)
		if type(w) ~= "table" or w.type ~= "RS_Markers" or not ns.Enabled(KEY) then return end
		ns.WithKit(function(Kit) Markers(Kit, w) end)
	end)
	aceHooked = AG.RegisterAsWidget
end


-- The About page (LibAboutPanel's): its title bright, the field names as labels, its copy box.
local function About(panel, Kit)
	for _, r in ipairs({ panel:GetRegions() }) do
		if r:GetObjectType() == "FontString" then
			Font(r)
			if Gold(r) then
				local object = r.GetFontObject and r:GetFontObject()
				Ink(r, object == _G.GameFontNormalLarge and "VALUE" or "LABEL")
			end
		end
	end
	local lib = LibStub("LibAboutPanel-2.0RS", true)
	if type(lib) == "table" and ns.Usable(lib.editbox) and ns.Controls(KEY) then
		ns.Guard(Kit.EditBox, lib.editbox)
	end
end

-- The custom NPC import / export dialog, over the settings window.
local function Import(f, Kit)
	if ns.Usable(f.NineSlice) then ns.Kill(f.NineSlice) end
	if ns.Usable(f.Border) and f.Border:GetObjectType() == "Frame" then ns.Kill(f.Border) end
	ns.PlainWindow(f, nil, KEY)
	Well(_G.RSImportNpcsScrollFrame)
	Font(_G.RSImportNpcsEditBox)
end

-- ---------------------------------------------------------------------------------------------
-- The telemetry export window
-- ---------------------------------------------------------------------------------------------

local function Telemetry(f, Kit)
	if not ns.Usable(f) or not ns.Once(f) then return end
	Kit.Strip(f)
	ns.Shell(f, { window = true }, KEY)
	if ns.Usable(f.Inset) then ns.Guard(Kit.Inset, f.Inset) end
	Font(f.TitleText)
	Ink(f.TitleText, "VALUE")
	Font(f.Help)
	Font(f.PortalHelp)
	Font(f.Summary)
	Ink(f.Summary, "LABEL")
	local area = f.TextArea
	if ns.Usable(area) then
		Kit.Strip(area)
		Well(area)
		Font(area.EditBox)
	end
	if not ns.Controls(KEY) then return end
	if ns.Usable(f.CloseButton) then ns.Guard(Kit.Close, f.CloseButton) end
	if ns.Usable(f.PortalUrl) then ns.Guard(Kit.EditBox, f.PortalUrl) end
	if ns.Usable(area) and ns.Usable(area.ScrollBar) then ns.Guard(Kit.ScrollBar, area.ScrollBar) end
end

-- ---------------------------------------------------------------------------------------------
-- When it builds and refreshes
-- ---------------------------------------------------------------------------------------------

ns.Pack(KEY, nil, function(Kit)
	-- The alert: dressed now (or when the fight ends), and checked again as it shows.
	ns.OutOfCombat(function() if ns.Enabled(KEY) then Alert(Kit) end end)
	if type(BUTTON.ShowButton) == "function" then
		hooksecurefunc(BUTTON, "ShowButton", function()
			if not ns.Enabled(KEY) or InCombatLockdown() then return end
			Alert(Kit)
			AlertText()
			AlertHover(false)
		end)
	end
	BUTTON:HookScript("OnEnter", function() if ns.Enabled(KEY) then AlertHover(true) end end)
	BUTTON:HookScript("OnLeave", function() if ns.Enabled(KEY) then AlertHover(false) end end)
	local pool = BUTTON.LootBar and BUTTON.LootBar.itemFramesPool
	if type(pool) == "table" and type(pool.ShowIfReady) == "function" then
		hooksecurefunc(pool, "ShowIfReady", function()
			if ns.Enabled(KEY) then AlertLoot() end
		end)
	end

	-- Its map pins' and chat links' tooltips.
	if type(QT) == "table" then
		if type(QT.Acquire) == "function" then
			hooksecurefunc(QT, "Acquire", function(lib, key)
				local tips = lib.activeTooltips
				if type(tips) == "table" then QTip(tips[key]) end
			end)
		end
		local proto = QT.tipPrototype
		-- Each tooltip as it's shown (Show is the frame's own, reached through the prototype's
		-- metatable; the hook sits on the prototype, so only this library's tooltips go through it).
		if type(proto) == "table" and type(proto.Show) == "function" then
			hooksecurefunc(proto, "Show", function(self)
				if not OursQT(self) or not ns.Enabled(KEY) or not qtShelled[self] then return end
				Settle(self)
				QTipClose(self)
			end)
		end
		if type(proto) == "table" and type(proto.AddSeparator) == "function" then
			-- Its separators, gold unless given a color: a faint hairline.
			hooksecurefunc(proto, "AddSeparator", function(self, _, r)
				if r ~= nil or not OursQT(self) or not ns.Enabled(KEY) or not qtShelled[self] then return end
				local lines = self.lines
				local line = type(lines) == "table" and lines[#lines]
				if ns.Usable(line) and line.SetBackdropColor then line:SetBackdropColor(1, 1, 1, 0.12) end
			end)
		end
		if type(proto) == "table" and type(proto.SetLineColor) == "function" then
			-- The gold wash behind its achievement line: a quiet gray.
			hooksecurefunc(proto, "SetLineColor", function(self, lineNum, r, g, b)
				if not OursQT(self) or not ns.Enabled(KEY) or not qtShelled[self] then return end
				if not GoldRGB(r, g, b) then return end
				local line = type(self.lines) == "table" and self.lines[lineNum]
				if ns.Usable(line) and line.SetBackdropColor then line:SetBackdropColor(1, 1, 1, 0.06) end
			end)
		end
	end

	-- DaylightUI's tooltip opacity changed: the shells made here follow.
	ns.me.On("SettingChanged", function(scope, path)
		if scope == "Tooltip" and path == "bgAlpha" and ns.Enabled(KEY) then Reopacity() end
	end)

	-- The addon compartment's tooltip, made on its first hover.
	if type(_G.RareScanner_OnAddonCompartmentEnter) == "function" then
		hooksecurefunc("RareScanner_OnAddonCompartmentEnter", function()
			Tip(_G.RareScanner_AddonCompartimentTooltip)
		end)
	end
	ns.Watch(KEY, "RareScanner_AddonCompartimentTooltip", function(tip) Tip(tip) end)

	-- The world map: the search box and the corner button, as the map opens.
	local map = _G.WorldMapFrame
	if ns.Usable(map) then
		local function mapShown()
			if not ns.Enabled(KEY) then return end
			ns.Guard(SearchBox, Kit)
			ns.Guard(MapButton)
			RouteNow()
		end
		map:HookScript("OnShow", mapShown)
		-- The game's round corner buttons, as the map opens and on every zoom and map change: the
		-- shared pass (ns.MapRings), hooked once for this pack and OpenMap's.
		ns.FollowMapRings(KEY)
		if map:IsShown() then
			mapShown()
			if ns.Enabled(KEY) then ns.Guard(ns.MapRings) end
		end
	end
	ns.Watch(KEY, "RSRouteProgressBar", RouteBar)

	-- Its popups, on every Spawn.
	if type(LD) == "table" and type(LD.Spawn) == "function" then
		hooksecurefunc(LD, "Spawn", function(lib)
			if not ns.Enabled(KEY) or type(lib.active_dialogs) ~= "table" then return end
			for _, d in ipairs(lib.active_dialogs) do ns.Guard(Dialog, Kit, d) end
		end)
	end

	-- The explorer. The lists' selection callbacks are taken from the frames when the explorer
	-- first opens, so they're hooked now, before that.
	local ex = _G.RSExplorerFrame
	if ns.Usable(ex) then
		-- Every row, right after the list fills it (the list takes its fill function when the
		-- explorer first opens, so it's hooked now, before that).
		local function Filled(owner, fn)
			if not ns.Usable(owner) or type(owner.OnElementInitialize) ~= "function" then return end
			hooksecurefunc(owner, "OnElementInitialize", function(self, row)
				if not ns.Enabled(KEY) or not ns.Usable(row) then return end
				rowList[row] = self
				ns.Guard(fn, Kit, row)
			end)
		end
		Filled(ex.RareNPCList, RareRow)
		Filled(ex.RareLoot, LootRow)
		Filled(ex.CustomLoot, GroupRow)
		local list = ex.RareNPCList
		if ns.Usable(list) and type(list.OnElementSelectionChanged) == "function" then
			hooksecurefunc(list, "OnElementSelectionChanged", function(self)
				if not ns.Enabled(KEY) then return end
				PaintPicks(self.scrollBox)
				Pool(ex.lootItemsPool)
			end)
		end
		local cl = ex.CustomLoot
		if ns.Usable(cl) and type(cl.OnElementSelectionChanged) == "function" then
			hooksecurefunc(cl, "OnElementSelectionChanged", function(self)
				if not ns.Enabled(KEY) then return end
				if ns.Usable(self.GroupList) then PaintPicks(self.GroupList.scrollBox) end
				if ns.Usable(self.GroupInfo) then Pool(self.GroupInfo.lootItemsPool) end
			end)
		end
		if type(ex.UpdateLootButton) == "function" then
			hooksecurefunc(ex, "UpdateLootButton", function(self)
				if not ns.Enabled(KEY) then return end
				local b = self.Filters and self.Filters.ToggleLootButton
				if ns.Usable(b) then Grey(b.Arrow, "TEXT") end
			end)
		end
		ex:HookScript("OnShow", function(self)
			if not ns.Enabled(KEY) then return end
			Explorer(Kit, self)
			QueueExplorer()
		end)
		if ex:IsShown() then
			Explorer(Kit, ex)
			QueueExplorer()
		end
	end

	-- Its loot filter menu's drop chance boxes, as a menu opens (the menu code calls this from
	-- inside itself: only noted here, done a moment later).
	local registry = _G.EventRegistry
	if type(registry) == "table" and type(registry.RegisterCallback) == "function" then
		local menuOwner = {}
		registry:RegisterCallback("MenuProxy.OnShow", MenuShown, menuOwner)
	end

	-- Its settings (every AceGUI tree's lines are Packs/Ace3.lua's).
	HookAce()
	local loads = CreateFrame("Frame")
	loads:RegisterEvent("ADDON_LOADED")
	loads:SetScript("OnEvent", function() HookAce() end)
	ns.Watch(KEY, "RareScannerAboutPanel", About)
	ns.Watch(KEY, "RSImportNpcsFrame", Import)

	-- The telemetry export window, made the first time it's asked for.
	ns.Watch(KEY, "RareScannerTelemetryExportFrame", Telemetry)
end)
