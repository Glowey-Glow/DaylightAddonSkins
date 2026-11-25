-- The game's pop-up menus keep DaylightUI's font after an option is ticked.
-- DaylightUI's popup menu skin puts its menu font on a menu's text when the menu opens. Ticking a
-- checkbox or radio refreshes the menu while it stays open (MenuResponse.Refresh ->
-- MenuMixin:ReinitializeAll), and the refresh hands every row a fresh text in the game's own font
-- (the compositor's font strings reset to GameFontHighlight). The menu never shows again, so that
-- skin isn't run again, and the rows stay in the game's wider font until the menu is reopened
-- (DaylightUI issue #1).
-- Here, while a game menu is open, a frame of ours looks over its texts and gives any that lost it
-- DaylightUI's menu font object back (the one DaylightUI made for that size, so the look is exactly
-- its own). It looks every frame for a moment after the menu opens, after a click and when the
-- mouse moves onto another row or scrolls the list under it (a refresh happens on a click, before
-- that frame's OnUpdate, so the text is back before it's drawn), and not at all otherwise: an open
-- menu the mouse rests on, or has left, costs one mouse-focus compare a frame. Nothing is hooked
-- or made on the menu itself; with no menu open the frame is hidden and costs nothing. Only while
-- DaylightUI's Skins module is on.
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
local GOLD_R, GOLD_G = 1, 0.82
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

-- Language names drawn as pictures. The game shows the choices of its language menus (Settings >
-- Languages, Text and Audio; the Communities finder's language) as pictures, one "Lang-Regions-..."
-- atlas per language (each name in its own alphabet), with the row's text hidden. DaylightUI's
-- menu skin takes any wide picture on a menu row for the row's hover, and paints it over with its
-- hover bar: the menu showed blank bars instead of the languages. Here each such picture is
-- noted while it still shows its atlas; once it has been painted over (its blend turned to ADD)
-- it is made clear, and a picture of ours (on a small frame over the row, where DaylightUI's skin
-- doesn't look) shows the same atlas in the same place. DaylightUI's own picture stays painted,
-- so its skin finds nothing to dress again.
local langOf = setmetatable({}, { __mode = "k" })  -- the game's texture -> its language atlas
local cover = setmetatable({}, { __mode = "k" })   -- the game's texture -> our texture over it
local rowOf = setmetatable({}, { __mode = "k" })   -- the game's texture -> the row it was on
local mine = setmetatable({}, { __mode = "k" })    -- our textures (left alone)
local langOn = true                                -- false once the game refused this once
local isLang = {}                                  -- atlas name -> whether it's a language's

local function Lang(t, row)
	if mine[t] then return end
	local atlas = t:GetAtlas()
	local lang = false
	if type(atlas) == "string" then
		-- (Each atlas name tested once: the same few dozen come back on every pass.)
		lang = isLang[atlas]
		if lang == nil then
			lang = atlas:lower():find("^lang%-regions%-") ~= nil
			isLang[atlas] = lang
		end
	end
	if lang then
		langOf[t], rowOf[t] = atlas, row
		local c = cover[t]
		if c then c:Hide() end
		return
	end
	local want = langOf[t]
	if not want or rowOf[t] ~= row or t:GetBlendMode() ~= "ADD" then return end
	local c = cover[t]
	if c and c:IsShown() and c.daylightAtlas == want and t:GetAlpha() == 0 then return end
	if not c then
		local holder = CreateFrame("Frame", nil, row)
		c = holder:CreateTexture(nil, "ARTWORK")
		mine[c] = true
		cover[t] = c
	end
	local holder = c:GetParent()
	if holder:GetParent() ~= row then holder:SetParent(row) end
	holder:SetAllPoints(row)
	holder:SetFrameLevel(row:GetFrameLevel() + 1)
	holder:Show()
	t:SetAlpha(0)
	c:ClearAllPoints()
	for i = 1, t:GetNumPoints() do c:SetPoint(t:GetPoint(i)) end
	c:SetAtlas(want, true)
	c.daylightAtlas = want
	c:Show()
end

-- Ours shows only while the game's picture it stands for does, on the same row.
local function SweepCovers()
	for t, c in pairs(cover) do
		if c:IsShown() and (not t:IsShown() or t:GetParent() ~= rowOf[t] or t:GetBlendMode() ~= "ADD") then
			c:Hide()
		end
	end
end

-- The pictures noted the moment a menu shows (its rows are filled by then), before DaylightUI's
-- skin, which dresses a menu a frame later, paints them over.
local function NoteLangs(menu)
	for _, row in ipairs({ menu:GetChildren() }) do
		if row.GetRegions and not (row.IsForbidden and row:IsForbidden()) then
			for _, r in ipairs({ row:GetRegions() }) do
				if r.GetObjectType and r:GetObjectType() == "Texture" then Lang(r, row) end
			end
		end
	end
end

local function DropCovers()
	for _, c in pairs(cover) do c:Hide() end
	wipe(langOf)
	wipe(rowOf)
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

-- (This runs often while a menu is open: the regions and children are gone through as the
-- game hands them back, with no table made for them. A text still in the menu font is only read,
-- under one protected call; the font and inks are read when a menu opens, not on every frame.)
local FixFrame

local function FixRegions(font, frame, ...)
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
		elseif kind == "Texture" then
			if langOn and not pcall(Lang, r, frame) then langOn = false end
			if inks and r:IsShown() then
				local part = KindOf(r)
				if part and not pcall(Tint, r, part == "mark" and inks.accent or inks.text) then
					blocked = true
					return
				end
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
	FixRegions(font, frame, frame:GetRegions())
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

-- When to look: every frame for a moment after a menu opens (DaylightUI's skin dresses it a frame
-- later, and paints the language pictures over then), after a click (a tick refreshes the menu)
-- and when the mouse moves onto something else (a row's hover, a wheel scroll moving the rows
-- under it); never in between.
local BURST = 0.25         -- seconds of a look every frame after one of those
local burstLeft = 0
local lastFocus
local Foci = _G.GetMouseFoci
local Focus = _G.GetMouseFocus

local function MouseOn()
	if Foci then
		local ok, f = pcall(Foci)
		return ok and type(f) == "table" and f[1] or nil
	end
	if Focus then
		local ok, f = pcall(Focus)
		return ok and f or nil
	end
end

local function Burst() burstLeft = BURST end

watcher:SetScript("OnUpdate", function(self, elapsed)
	local on = MouseOn()
	if on ~= lastFocus then
		lastFocus = on
		burstLeft = BURST
	end
	-- (Between bursts: only the focus compare above. A menu closed meanwhile is let go by
	-- MenuProxy.OnClose, below, which hides this frame with none left.)
	if burstLeft <= 0 then return end
	burstLeft = burstLeft - elapsed
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
	if langOn and next(cover) and not pcall(SweepCovers) then langOn = false end
	if not any or blocked then
		pcall(DropCovers)
		self:Hide()
	end
end)

local owner = {}
registry:RegisterCallback("MenuProxy.OnShow", function(_, menu)
	if blocked or type(menu) ~= "table" or not ns.ModuleOn("Skins") then return end
	open[menu] = true
	stale = true
	if langOn and menu.GetChildren and not pcall(NoteLangs, menu) then langOn = false end
	Burst()
	watcher:Show()
end, owner)
-- A click (on a menu's row, or anywhere: the menu may close or refresh): looked at the same frame.
local clicks = CreateFrame("Frame")
clicks:RegisterEvent("GLOBAL_MOUSE_DOWN")
clicks:RegisterEvent("GLOBAL_MOUSE_UP")
clicks:SetScript("OnEvent", function() if watcher:IsShown() then Burst() end end)
registry:RegisterCallback("MenuProxy.OnClose", function(_, menu)
	if type(menu) == "table" then open[menu] = nil end
	if not next(open) then
		pcall(DropCovers)
		watcher:Hide()
	end
end, owner)
if ns.me and ns.me.On then ns.me.On("StyleChanged", function() stale = true wipe(menuFonts) end) end
