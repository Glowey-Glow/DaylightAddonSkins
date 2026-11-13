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
local function MenuFont(size)
	return _G["DaylightUIMenuFont" .. math.floor((size or 12) + 0.5)]
end

-- Setting a font object resets the colour: the game's (a class colour, a grey disabled entry)
-- goes back on.
local function FixText(fs, object)
	local r, g, b, a = fs:GetTextColor()
	fs:SetFontObject(object)
	fs:SetTextColor(r, g, b, a)
end

-- (This runs every frame while a menu is open: the regions and children are gone through as the
-- game hands them back, with no table made for them. A text still in the menu font is only read,
-- and the protected call is made only for one that lost it.)
local FixFrame

local function FixRegions(font, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if r.GetObjectType and r:GetObjectType() == "FontString" then
			-- (Read under a protected call too: a string the game won't let us read stops the
			-- fix for good, as one it won't let us change does, instead of erroring every frame.)
			local ok, file, size = pcall(r.GetFont, r)
			if not ok then
				blocked = true
				return
			end
			if file ~= font then
				local object = MenuFont(size)
				if object and not pcall(FixText, r, object) then
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
	FixRegions(font, frame:GetRegions())
	if not blocked and depth > 0 and frame.GetChildren then
		FixChildren(font, depth - 1, frame:GetChildren())
	end
end

watcher:SetScript("OnUpdate", function(self)
	local any = false
	local font = API.Font()
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
	watcher:Show()
end, owner)
registry:RegisterCallback("MenuProxy.OnClose", function(_, menu)
	if type(menu) == "table" then open[menu] = nil end
end, owner)
