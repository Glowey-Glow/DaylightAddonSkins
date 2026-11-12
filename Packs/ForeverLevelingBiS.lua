-- Forever Leveling BiS: the shells of its windows (the main window, My gear, Stat weights and its
-- dialogs, Quest details, Settings, What's new, the selectors' lists, the gear panel beside the
-- Character frame) and its text in the player's font.
-- It keeps its theme private, so it is followed from outside: every string it draws takes one of
-- five font objects of its own (ForeverLevelingBiSFont*), which get the player's font here each
-- time it sets them; and its windows are found by the flat backdrop its W.Window gives them.
-- Only its Modern theme is dressed: pick Classic or a skin in its own settings and it is left as
-- it draws it. Left alone: its buttons, tabs, rows and selectors (it recolours them on every
-- hover and pick), its scroll bars, bubbles, question boxes and tooltip lines, and its accent.
-- Nothing is written to its saved settings.
local _, ns = ...
if not ns.ok then return end

ns.Target("ForeverLevelingBiS", "Forever Leveling BiS", { window = true, text = true, font = "daylight" })

local KEY = "ForeverLevelingBiS"
local abs = math.abs

-- Its theme, as the player set it (read only): a skin or Classic is left alone.
local function Modern()
	local db = _G.ForeverLevelingBiSDB
	local theme = type(db) == "table" and type(db.display) == "table" and db.display.theme
	return theme == nil or theme == "modern"
end

local function On()
	return ns.Enabled(KEY) and Modern()
end

-- ---------------------------------------------------------------------------------------------
-- Fonts: its five font objects. What it set on each is kept, and the look is laid over that, so a
-- change of its own text size, or of ours, never adds up.
-- ---------------------------------------------------------------------------------------------

local FONTS = { "FontNormal", "FontNormalLarge", "FontNormalSmall", "FontHighlightSmall", "FontDisableSmall" }
local own = {}       -- font object -> { path, size, flags } as it set them
local busy = false

local function Restyle(font)
	local o = own[font]
	if not o or not o[1] or not o[2] then return end
	busy = true
	local ok, err = pcall(function()
		if On() and not ns.PlainText(KEY) then
			local path, size, flags = ns.FontFor(KEY, o[1], o[2], o[3])
			font:SetFont(path, size, flags or "")
		else
			font:SetFont(o[1], o[2], o[3] or "")
		end
	end)
	busy = false
	if not ok then geterrorhandler()(err) end
end

for _, name in ipairs(FONTS) do
	local font = _G["ForeverLevelingBiS" .. name]
	if type(font) == "table" and font.GetFont and font.SetFont then
		own[font] = { font:GetFont() }
		hooksecurefunc(font, "SetFont", function(self, path, size, flags)
			if busy then return end
			own[self] = { path, size, flags }
			Restyle(self)
		end)
	end
end

local function RestyleAll()
	for font in pairs(own) do Restyle(font) end
end

-- ---------------------------------------------------------------------------------------------
-- Windows: a Frame with W.Window's flat backdrop (a one-pixel WHITE8X8 border round its window
-- colour, 0.06 / 0.06 / 0.08), or the selectors' lists' (0.05 grey).
-- ---------------------------------------------------------------------------------------------

local WHITE = "interface\\buttons\\white8x8"

local function Near(r, g, b, R, G, B)
	return r and abs(r - R) < 0.006 and abs(g - G) < 0.006 and abs(b - B) < 0.006
end

-- "window", "list" or nil.
local function Kind(f)
	if not ns.Usable(f) or f:GetObjectType() ~= "Frame" or not f.GetBackdrop then return nil end
	local bd = f:GetBackdrop()
	if type(bd) ~= "table" or bd.edgeSize ~= 1 or type(bd.bgFile) ~= "string" or bd.bgFile:lower() ~= WHITE then
		return nil
	end
	local w, h = f:GetSize()
	if not w or w < 80 or not h or h < 40 then return nil end   -- tags and chips, not windows
	local r, g, b = f:GetBackdropColor()
	if Near(r, g, b, 0.06, 0.06, 0.08) then return "window" end
	if Near(r, g, b, 0.05, 0.05, 0.05) then return "list" end
	return nil
end

-- The title band W.TitleBand draws: a dark square strip a pixel inside the top, which would show
-- its corners on DaylightUI's rounded shell. The shell's own band takes its place.
local function FadeBand(f)
	for _, region in ipairs({ f:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BORDER"
			and region:GetNumPoints() >= 1 then
			local point, rel, relPoint, x, y = region:GetPoint(1)
			local h = region:GetHeight()
			if point == "TOPLEFT" and rel == f and relPoint == "TOPLEFT" and x == 1 and y == -1
				and h and abs(h - 30) < 1 then
				region:SetAlpha(0)
			end
		end
	end
end

local dressed = setmetatable({}, { __mode = "k" })

-- A dialog laid over the whole of a window it sits in (Stat weights' editors): solid, or the
-- window under it shows through.
local function Overlay(f)
	local parent = f:GetParent()
	if not parent or not dressed[parent] then return false end
	local w, h = f:GetSize()
	local pw, ph = parent:GetSize()
	return w and pw and abs(w - pw) < 1 and abs(h - ph) < 1
end

local function Dress(f, kind)
	if dressed[f] then return end
	dressed[f] = true
	ns.NoBackdrop(f)
	-- It may lay its backdrop on again: taken straight back off.
	local clearing = false
	hooksecurefunc(f, "SetBackdrop", function(self, info)
		if clearing or info == nil then return end
		clearing = true
		ns.NoBackdrop(self)
		clearing = false
	end)
	if kind == "list" then
		ns.Shell(f, { bgAlpha = 0.97 }, KEY)
	else
		FadeBand(f)
		if Overlay(f) then
			ns.Shell(f, { window = true, bgAlpha = 1 }, KEY)
		else
			ns.Shell(f, { window = true }, KEY)
		end
	end
end

-- Its windows among root and what is in it, `depth` levels down (parents first, so a dialog knows
-- its window is dressed).
local function Scan(root, depth)
	if not ns.Usable(root) then return end
	local kind = not dressed[root] and Kind(root)
	if kind then Dress(root, kind) end
	if depth <= 0 or not root.GetChildren then return end
	for _, child in ipairs({ root:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Frame" then Scan(child, depth - 1) end
	end
end

local function Guarded(fn)
	return function(...) ns.Guard(fn, ...) end
end

-- Its side panels, dialogs and lists are made on their first open, while the window is up: looked
-- for twice a second while it is shown, and not at all while it is hidden.
local function Main(frame)
	if not On() then return end
	local ticker
	local function Look() Scan(frame, 2) end
	frame:HookScript("OnShow", Guarded(function()
		Look()
		if not ticker then ticker = C_Timer.NewTicker(0.5, Guarded(Look)) end
	end))
	frame:HookScript("OnHide", function()
		if ticker then
			ticker:Cancel()
			ticker = nil
		end
	end)
	Look()
	if frame:IsShown() and not ticker then ticker = C_Timer.NewTicker(0.5, Guarded(Look)) end
end

-- My gear beside the Character frame: on a holder of its own in the Character frame.
local function Sheet()
	local cf = _G.CharacterFrame
	if not ns.Usable(cf) or not cf.HookScript then return end
	local function Look()
		if On() then Scan(cf, 2) end
	end
	cf:HookScript("OnShow", function()
		C_Timer.After(0, Guarded(Look))
		C_Timer.After(0.5, Guarded(Look))
	end)
	if cf:IsShown() then C_Timer.After(0, Guarded(Look)) end
end

ns.Watch(KEY, "ForeverLevelingBiSFrame", Main)
ns.Watch(KEY, "ForeverLevelingBiSWhatsNew", function(frame)
	if On() then Scan(frame, 0) end
end)

local ok = false
ns.Pack(KEY, nil, function()
	if ok then return end
	ok = true
	Sheet()
	RestyleAll()
end)

-- Its text follows the DaylightUI font, and this plugin's page for it.
ns.me.On("Login", Guarded(RestyleAll))
ns.me.On("StyleChanged", Guarded(RestyleAll))
ns.me.On("SettingChanged", function(scope, path)
	if scope ~= "DaylightAddonSkins" or type(path) ~= "string" then return end
	if path == KEY or path == "followDaylight" or string.sub(path, 1, 24) == "look.ForeverLevelingBiS." then
		ns.Guard(RestyleAll)
	end
end)
