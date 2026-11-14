-- The game's pop-up menus keep DaylightUI's font after an option is ticked.
-- DaylightUI's popup menu skin puts its menu font on a menu's text when the menu opens. Ticking a
-- checkbox or radio refreshes the menu while it stays open (MenuResponse.Refresh ->
-- MenuMixin:ReinitializeAll), and the refresh hands every row a fresh text in the game's own font
-- (the compositor's font strings reset to GameFontHighlight). The menu never shows again, so that
-- skin isn't run again, and the rows stay in the game's wider font until the menu is reopened
-- (DaylightUI issue #1).
-- Here, while a game menu is open, a frame of ours looks over its texts each frame and gives any
-- that lost it DaylightUI's menu font object back (the one DaylightUI made for that size, so the
-- look is exactly its own). A refresh happens on a click, before that frame's OnUpdate, so the text
-- is back before it's drawn. Nothing is hooked or made on the menu itself; with no menu open the
-- frame is hidden and costs nothing. Only while DaylightUI's Skins module is on.
local _, ns = ...
if not ns.ok then return end

local API = ns.API
local registry = _G.EventRegistry
if type(registry) ~= "table" or type(registry.RegisterCallback) ~= "function" then return end

local open = {}            -- menu -> true while it shows
local blocked = false      -- the game refused a font change once: stop trying
local watcher = CreateFrame("Frame")
watcher:Hide()

-- DaylightUI's menu font object for a size, nil until DaylightUI has made it (it makes one per size
-- the first time a menu of that size is dressed).
local menuFonts = {}        -- size -> DaylightUI's font object for it, once there
local function MenuFont(size)
	local n = math.floor((size or 12) + 0.5)
	local object = menuFonts[n]
	if object == nil then
		object = _G["DaylightUIMenuFont" .. n]
		menuFonts[n] = object       -- (stays nil, and asked for again, until DaylightUI makes it)
	end
	return object
end

-- Setting a font object resets the color: the game's (a class color, a gray disabled entry)
-- goes back on.
local function FixText(fs, object)
	local r, g, b, a = fs:GetTextColor()
	fs:SetFontObject(object)
	fs:SetTextColor(r, g, b, a)
end

-- Their colors too. DaylightUI's menu skin leaves the game's gold in menus: section titles in
-- gold text ("Show:", an addon's heading in the world map's filter menu), yellow check and radio
-- marks, yellow submenu arrows. While a menu is open the same pass gives gold text DaylightUI's
-- label ink, a check or radio mark the accent, and an arrow the light text ink (by the art's
-- atlas or file name, so every menu built from the game's templates is covered, whichever addon
-- filled it). Each is set only when it isn't ours already. Colors the game gives on purpose (a
-- gray disabled entry, a class color) aren't gold and stay.
local GOLD_R, GOLD_G, GOLD_B = 1, 0.82, 0
local function NearGold(r, g, b)
	return r and math.abs(r - GOLD_R) < 0.06 and math.abs(g - GOLD_G) < 0.08 and b < 0.25
end
local inks                  -- { label = {r,g,b}, text = {r,g,b}, accent = {r,g,b} } for this pass
local kinds = setmetatable({}, { __mode = "k" })   -- texture -> "mark" | "arrow" | false, by its art
local artOf = setmetatable({}, { __mode = "k" })   -- texture -> the art that kind was read from

local function KindOf(t)
	local ok, atlas = pcall(t.GetAtlas, t)
	local art = ok and atlas or nil
	if not art or art == "" then
		local ok2, file = pcall(t.GetTexture, t)
		art = ok2 and file or nil
	end
	if artOf[t] == art and kinds[t] ~= nil then return kinds[t] end
	artOf[t] = art
	local kind = false
	if type(art) == "string" then
		local a = string.lower(art)
		if a:find("checkmark", 1, true) or a:find("check%-mark") or a:find("radio", 1, true) and a:find("dot", 1, true)
			or a:find("ui%-checkbox%-check") or a:find("dropdown%-icon%-check") or a:find("radio%-selected") then
			kind = "mark"
		elseif a:find("arrow", 1, true) or a:find("dropdown%-icon%-next") or a:find("expand", 1, true) then
			kind = "arrow"
		end
	end
	kinds[t] = kind
	return kind
end

local function Tint(t, c)
	local r, g, b = t:GetVertexColor()
	if r and math.abs(r - c[1]) < 0.01 and math.abs(g - c[2]) < 0.01 and math.abs(b - c[3]) < 0.01 then return end
	t:SetDesaturated(true)
	t:SetVertexColor(c[1], c[2], c[3])
end

local function InkText(fs)
	local r, g, b = fs:GetTextColor()
	if NearGold(r, g, b) then
		local c = inks.label
		fs:SetTextColor(c[1], c[2], c[3])
	end
end

-- One text: its font read, put back if it lost DaylightUI's, then inked. (One protected call for
-- all three: any of them the game refuses stops the fix for good.)
local function FixString(fs, font)
	local file, size = fs:GetFont()
	if file ~= font then
		local object = MenuFont(size)
		if object then FixText(fs, object) end
	end
	if inks then InkText(fs) end
end

-- (This runs every frame while a menu is open: the regions and children are gone through as the
-- game hands them back, with no table made for them. A text still in the menu font is only read,
-- under one protected call; the font and inks are read when a menu opens, not on every frame.)
local FixFrame

local function FixRegions(font, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		local kind = r.GetObjectType and r:GetObjectType()
		if kind == "FontString" then
			-- (Read under the protected call too: a string the game won't let us read stops the
			-- fix for good, as one it won't let us change does, instead of erroring every frame.)
			if not pcall(FixString, r, font) then
				blocked = true
				return
			end
		elseif inks and kind == "Texture" and r:IsShown() then
			local kind = KindOf(r)
			if kind and not pcall(Tint, r, kind == "mark" and inks.accent or inks.text) then
				blocked = true
				return
			end
		end
	end
end

local function FixChildren(font, depth, ...)
	for i = 1, select("#", ...) do
		if blocked then return end
		FixFrame(select(i, ...), font, depth)
	end
end

FixFrame = function(frame, font, depth)
	if blocked or type(frame) ~= "table" or not frame.GetRegions then return end
	if frame.IsForbidden and frame:IsForbidden() then return end
	FixRegions(font, frame:GetRegions())
	if not blocked and depth > 0 and frame.GetChildren then
		FixChildren(font, depth - 1, frame:GetChildren())
	end
end

-- The font and the inks, read again when a menu opens and when DaylightUI's style changes (not on
-- every frame: they can't change otherwise).
local font
local stale = true
local LABEL_INK, TEXT_INK = { 0.8, 0.75, 0.65 }, { 0.9, 0.9, 0.9 }
local function ReadInks()
	stale = false
	font = API.Font()
	local colors = ns.Colors()
	local ar, ag, ab = ns.AccentOf()
	inks = inks or { label = {}, text = {}, accent = {} }
	local l, t = colors.LABEL or LABEL_INK, colors.TEXT or TEXT_INK
	inks.label[1], inks.label[2], inks.label[3] = l[1], l[2], l[3]
	inks.text[1], inks.text[2], inks.text[3] = t[1], t[2], t[3]
	inks.accent[1], inks.accent[2], inks.accent[3] = ar, ag, ab
end

watcher:SetScript("OnUpdate", function(self)
	local any = false
	if stale then ReadInks() end
	for menu in pairs(open) do
		if type(menu) == "table" and menu.IsShown and menu:IsShown() then
			any = true
			FixFrame(menu, font, 5)
		else
			open[menu] = nil
		end
	end
	if not any or blocked then self:Hide() end
end)

local owner = {}
registry:RegisterCallback("MenuProxy.OnShow", function(_, menu)
	if blocked or type(menu) ~= "table" or not ns.ModuleOn("Skins") then return end
	open[menu] = true
	stale = true
	watcher:Show()
end, owner)
registry:RegisterCallback("MenuProxy.OnClose", function(_, menu)
	if type(menu) == "table" then open[menu] = nil end
end, owner)
if ns.me and ns.me.On then ns.me.On("StyleChanged", function() stale = true wipe(menuFonts) end) end
