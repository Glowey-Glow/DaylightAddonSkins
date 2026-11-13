-- Total RP 3: every window and panel of its own in the DaylightUI look.
-- It draws everything from a handful of its own templates (UI/Widgets.xml, UI/Backdrop.xml,
-- UI/IconTemplates.xml, Resources/UI/Templates.xml), so the pack works from those rather than from
-- frame names: one walk over a window finds each template by its pieces and dresses it.
--   * Windows and popups: its main window (wooden border, neutral and parchment grounds, sidebar)
--     and every free-standing frame with a backdrop or NineSlice of its own (the toolbar, target
--     frame, glance bar, "Currently" and NPC speech frames, the icon, color, image, music, pet,
--     companion and background browsers, the profile and import dialogs, the link copy dialog)
--     get DaylightUI's window shell. Boxes inside a window (page panels, group boxes, the about and
--     characteristics panels, list frames) become quiet flat wells. Its dimming overlay behind
--     popups stays a dim.
--   * Its page art (parchment, settings and profiles backgrounds, wooden borders, slice frames and
--     glows) is hidden by file, wherever it turns up.
--   * The sidebar's category buttons become plain rows, the picked one in the accent. Its red text
--     buttons are DaylightUI buttons, its red art buttons (close, resize, condense, edit) a close X
--     or a neutral gray, its framed icon buttons keep their icon inside a thin outline.
--   * List rows drawn with its slice art (profiles, modules, relations, music, backgrounds) are
--     DaylightUI's plain list lines (no box on each, a hairline between them), the picked one
--     in the accent.
--   * The game's own templates inside (buttons, tabs, check boxes, edit boxes, dropdowns, scroll
--     bars, insets) are dressed by DaylightUI's Kit.Auto, and its text takes the player's font and
--     DaylightUI's colors.
-- Hooked: each window on show, each page as Total RP 3 opens it (PAGE_OPENED), each panel inside a
-- window on show, each scroll child as it grows (lines added in edit mode), each ScrollBox list's
-- rows as they are filled, and its category buttons as the sidebar is rebuilt.
-- Left as it is: what the player put in it (portraits, icons, the About page's pictures and text,
-- color swatches), map markers, its tooltips (DaylightUI's Tooltip module dresses every game
-- tooltip, these included), its right-click and dropdown menus (the game's menus, which
-- DaylightUI's skins dress), the game's static popups, and its sliders' tracks.
--
-- "Hand over to DaylightUI": its unit tooltip hiding the game's (DaylightUI's tooltip stays, its
-- RP card shows beside it) and its own name colors in chat (DaylightUI's class colors).
local _, ns = ...
if not ns.ok then return end

local KEY = "totalRP3"

ns.Target(KEY, "Total RP 3", { window = true, controls = true, text = true, shadow = true, colors = true,
	font = "daylight",
	extraTab = "DaylightUI",
	extra = function()
		return { ns.HandoverGroup(KEY) }
	end })

if type(_G.TRP3_API) ~= "table" then return end

local API = ns.API
local UI_ART = "Interface\\AddOns\\totalRP3\\Resources\\UI\\"

-- ---------------------------------------------------------------------------------------------
-- Its art, known by file
-- ---------------------------------------------------------------------------------------------

-- Grounds, borders, slice frames and glows: hidden wherever they are.
local CHROME_FILES = { "ui-frame-neutral-background", "!ui-frame-wooden-border", "_ui-frame-wooden-border",
	"ui-frame-parchment-background", "ui-frame-settings-background", "ui-frame-profiles-background",
	"ui-frame-slice-md-edge", "ui-frame-slice-md-fill", "ui-frame-slice-md-glow",
	"ui-frame-slice-sm-edge", "ui-frame-slice-sm-fill", "ui-frame-slice-sm-glow", "ui-frame-slice-sm-pushed",
	"ui-frame-backdrop-fill", "ui-frame-backdrop-edge", "ui-category-button" }
-- Its red square buttons (close, resize, condense, expand, menu, edit).
local RED_FILES = { "ui-red-buttons", "blz-redbutton2x" }
-- The achievement frame around TRP3_IconButton's icon.
local ICON_FRAME = "Interface\\AchievementFrame\\UI-Achievement-IconFrame"

-- The game's achievement title bar it uses as a list header (the directory's Character / Relation
-- / Flags band): a quiet dark strip instead.
local BAND = "Interface\\AchievementFrame\\UI-Achievement-Title"

local CHROME, RED, FRAMED, BANDS

local function Learn()
	if CHROME then return end
	local paths = {}
	for _, name in ipairs(CHROME_FILES) do paths[UI_ART .. name] = true end
	CHROME = ns.FileIDs(paths)
	paths = {}
	for _, name in ipairs(RED_FILES) do paths[UI_ART .. name] = true end
	RED = ns.FileIDs(paths)
	FRAMED = ns.FileIDs({ [ICON_FRAME] = true })
	BANDS = ns.FileIDs({ [BAND] = true })
end

local function FileOf(tex)
	if not ns.Usable(tex) or not tex.GetTexture then return nil end
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return nil end
	if type(file) == "string" then return string.lower(file) end
	return file
end

local function IsChrome(tex) local f = FileOf(tex) return f ~= nil and CHROME[f] == true end
local function IsRed(tex) local f = FileOf(tex) return f ~= nil and RED[f] == true end
local function IsFramed(tex) local f = FileOf(tex) return f ~= nil and FRAMED[f] == true end
local function IsBand(tex) local f = FileOf(tex) return f ~= nil and BANDS[f] == true end

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
-- string already done isn't scaled again; one it gave a new font object since is done again.
local fonted = setmetatable({}, { __mode = "k" })
local function Font(fs)
	if ns.PlainText(KEY) or not fs.GetFont then return end
	local path, size, flags = fs:GetFont()
	if type(size) ~= "number" or size <= 0 then return end
	local last = fonted[fs]
	if last and last[1] == path and math.abs(last[2] - size) < 0.01 then return end
	ns.SetFont(KEY, fs, path, size, flags)
	local p2, s2 = fs:GetFont()
	fonted[fs] = { p2, s2 or size }
end

-- Its gold (headings, field titles: GameFontNormal's and its own 0.95, 0.75, 0.1) becomes the
-- label tan. Other colors are its meaning (status, relations, quality) and stay.
local function Gold(fs)
	local r, g, b = fs:GetTextColor()
	return type(r) == "number" and r > 0.85 and g > 0.6 and g < 0.88 and b < 0.4
end

local function Text(fs)
	Font(fs)
	if fs.GetObjectType and fs:GetObjectType() == "FontString" and Gold(fs) then Ink(fs, "LABEL") end
end

-- ---------------------------------------------------------------------------------------------
-- Pieces
-- ---------------------------------------------------------------------------------------------

local WHITE = "Interface\\Buttons\\WHITE8X8"
local FLAT = { bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }
-- The grounds its backdrops come with. Any other ground is one the player picked (the About and
-- characteristics pages' backgrounds) and is kept.
local CHROME_BG = {
	["interface\\addons\\totalrp3\\resources\\ui\\ui-frame-backdrop-fill"] = true,
	["interface\\dialogframe\\ui-dialogbox-background"] = true,
	["interface\\dialogframe\\ui-dialogbox-gold-background"] = true,
	["interface\\collections\\collectionsbackgroundtile"] = true,
	["interface\\achievementframe\\ui-achievement-statsbackground"] = true,
	["interface\\tooltips\\ui-tooltip-background"] = true,
	["interface\\buttons\\white8x8"] = true,
}
local BACKDROP_PIECES = { "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
	"TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center" }

local dressed = setmetatable({}, { __mode = "k" })  -- frame -> its pieces are done
local killed = setmetatable({}, { __mode = "k" })   -- texture -> hidden by us
local skip = setmetatable({}, { __mode = "k" })     -- frames Kit.Auto leaves to us
local overlays = setmetatable({}, { __mode = "k" }) -- its dims behind popups

local function Kill(tex)
	if not ns.Usable(tex) or killed[tex] then return end
	killed[tex] = true
	ns.Kill(tex)
end

local function HasBackdrop(f)
	return f.GetBackdrop ~= nil and f:GetBackdrop() ~= nil
end

-- A thin outline over a button's icon: on a child above it, since the icon fills the button.
local function Outline(btn)
	local o = CreateFrame("Frame", nil, btn)
	o:SetAllPoints(btn)
	o:SetFrameLevel(btn:GetFrameLevel() + 2)
	o:EnableMouse(false)
	ns.Shell(o, { noBackground = true, noBevel = true, borderPx = 2 }, KEY)
end

-- A backdrop kept (it reads it back to lay a picked background over it, and errors without one)
-- but out of sight: its pieces are reused by every later SetBackdrop, so they stay hidden.
local function HidePieces(f)
	if not f.SetBackdrop then return end
	f:SetBackdrop(FLAT)
	for _, key in ipairs(BACKDROP_PIECES) do
		if ns.Usable(f[key]) then f[key]:SetAlpha(0) end
	end
end

-- The window shell in place of its backdrop (and the ground it draws under a popup).
local function ShellOf(f)
	HidePieces(f)
	if ns.Usable(f.NineSlice) then ns.Kill(f.NineSlice) end
	if ns.Usable(f.Background) and f.Background:GetObjectType() == "Texture" then Kill(f.Background) end
	ns.Shell(f, { window = true }, KEY)
end

-- A box inside a window: a flat one-pixel well. A ground the player picked stays, inside the
-- same thin edge.
local function Well(f)
	local info = f:GetBackdrop()
	local bg = type(info) == "table" and info.bgFile or nil
	if type(bg) == "string" and not CHROME_BG[string.lower((string.gsub(bg, "/", "\\")))] then
		f:SetBackdrop({ bgFile = bg, tile = info.tile, tileSize = info.tileSize, edgeFile = WHITE, edgeSize = 1 })
		f:SetBackdropBorderColor(1, 1, 1, 0.07)
		return
	end
	f:SetBackdrop(FLAT)
	ns.Soften(f, 0.3)
end

-- Its dim behind popups: a plain dim.
local function Overlay(f)
	overlays[f] = true
	HidePieces(f)
	local dim = f:CreateTexture(nil, "BACKGROUND", nil, -8)
	dim:SetAllPoints(f)
	dim:SetColorTexture(0, 0, 0, 0.55)
end

-- A frame that stands on its own (on the screen, over a window, or in front of it): its own
-- shell, and what's inside starts afresh.
local HOSTS = {}
local function Host(f)
	if HOSTS[f] then return true end
	local p = f:GetParent()
	if not p then return false end
	if p == UIParent or p == _G.TRP3_PopupsFrame then return true end
	if overlays[p] then return true end
	return f:GetFrameStrata() ~= p:GetFrameStrata()
end

-- Sidebar category buttons: plain rows, the picked one (disabled while picked) in the accent.
local CATEGORY_ART = { "EdgeLeft", "EdgeRight", "Center", "BorderEdgeLeft", "BorderEdgeRight", "BorderCenter",
	"HighlightEdgeLeft", "HighlightEdgeRight", "HighlightCenter",
	"HighlightBorderEdgeLeft", "HighlightBorderEdgeRight", "HighlightBorderCenter" }
local function Picked(b) return b.IsEnabled and not b:IsEnabled() end

local function CategoryInk(b)
	if not ns.Usable(b.Text) then return end
	Font(b.Text)
	Ink(b.Text, Picked(b) and "VALUE" or "TEXT")
end

-- A pooled row hidden under the mouse (its list is rebuilt on a click) never hears the mouse
-- leave, and would keep its hover wash wherever it's shown next: it's told on hide.
local function ClearHoverOnHide(b)
	b:HookScript("OnHide", function(self)
		if ExecuteFrameScript then pcall(ExecuteFrameScript, self, "OnLeave") end
	end)
end

local function Category(Kit, b)
	for _, key in ipairs(CATEGORY_ART) do Kill(b[key]) end
	local keep = {}
	if ns.Usable(b.Icon) then keep[b.Icon] = true end
	ns.Guard(Kit.Row, b, keep, Picked, false)
	if ns.Controls(KEY) and ns.Usable(b.CloseButton) then ns.Guard(Kit.Close, b.CloseButton) end
	CategoryInk(b)
	ClearHoverOnHide(b)
	-- Each rebuild gives it its font object again after picking it, then shows it.
	b:HookScript("OnShow", CategoryInk)
	-- Buttons made before the mixin was hooked (below) are hooked one by one.
	local mixin = _G.TRP3_CategoryButtonMixin
	if type(b.SetSelected) == "function" and not (mixin and b.SetSelected == mixin.SetSelected) then
		hooksecurefunc(b, "SetSelected", function(self)
			if ns.Kit then ns.Guard(ns.Kit.RepaintRow, self) end
			CategoryInk(self)
		end)
	end
end

-- A red text button: its three pieces off, DaylightUI's button.
local function RedTextButton(Kit, b)
	Kill(b.EdgeLeft)
	Kill(b.EdgeRight)
	Kill(b.Center)
	if ns.Controls(KEY) then ns.Guard(Kit.Button, b) end
end

-- A red art button: an X is DaylightUI's close button; the rest keep their picture, in gray.
local function CloseLike(b)
	local key = b.GetParentKey and b:GetParentKey()
	local name = b:GetName() or ""
	return key == "CloseButton" or key == "Close" or string.find(name, "Close$") ~= nil
end

local function RedArtButton(Kit, b)
	if CloseLike(b) then
		if ns.Controls(KEY) then ns.Guard(Kit.Close, b) end
		return
	end
	for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
		local t = b[get] and b[get](b)
		if ns.Usable(t) then
			t:SetDesaturated(true)
			if get == "GetHighlightTexture" then t:SetAlpha(0.35) else t:SetVertexColor(0.8, 0.8, 0.8) end
		end
	end
end

-- TRP3_IconButton: the achievement frame round its icon goes, a thin outline instead.
local function FramedIcon(b)
	local n = b:GetNormalTexture()
	if ns.Usable(n) then n:SetAlpha(0) end
	local d = b.GetDisabledTexture and b:GetDisabledTexture()
	if ns.Usable(d) then d:SetAlpha(0) end
	Outline(b)
end

-- TRP3_BorderedIconTemplate (toolbar, target frame, glance and icon buttons): square, no frame,
-- a thin outline, a quiet hover.
local function BorderedIcon(b)
	Kill(b.Border)
	local mask = b.IconMask
	if ns.Usable(mask) then
		for _, t in ipairs({ b.Icon, b.Background }) do
			if ns.Usable(t) and t.RemoveMaskTexture then pcall(t.RemoveMaskTexture, t, mask) end
		end
	end
	if ns.Usable(b.HighlightBorder) then b.HighlightBorder:SetColorTexture(1, 1, 1, 0.12) end
	if ns.Usable(b.PushedTexture) then b.PushedTexture:SetColorTexture(0, 0, 0, 0.35) end
	Outline(b)
end

-- A list row drawn with its slice art: DaylightUI's row; its own textures (icons) are kept.
local function SliceRow(Kit, f)
	local keep = {}
	for _, r in ipairs({ f:GetRegions() }) do
		if r:GetObjectType() == "Texture" and not IsChrome(r) and r ~= f.Background and r ~= f.Border
			and r ~= f.Highlight and r ~= f.SelectedTexture and r ~= f.HighlightBorder then
			keep[r] = true
		end
	end
	local selected = ns.Usable(f.SelectedTexture) and f.SelectedTexture or nil
	-- A plain line, not a box: its rows sit edge to edge, and a box on each one doubles the
	-- border between them. A hover wash, an accent wash when picked, and one hairline under it.
	ns.Guard(Kit.Row, f, keep, selected, false)
	ClearHoverOnHide(f)
	if not f.dasDivider then
		local line = f:CreateTexture(nil, "ARTWORK")
		line:SetColorTexture(1, 1, 1, 0.07)
		line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6, 0)
		line:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 0)
		if PixelUtil and PixelUtil.SetHeight then PixelUtil.SetHeight(line, 1) else line:SetHeight(1) end
		f.dasDivider = line
	end
end

local function IsMinimalCheck(f)
	local t = f.GetCheckedTexture and f:GetCheckedTexture()
	if not ns.Usable(t) or not t.GetAtlas then return false end
	local ok, atlas = pcall(t.GetAtlas, t)
	return ok and atlas == "checkmark-minimal"
end

-- ---------------------------------------------------------------------------------------------
-- The game's art it borrows, by file or atlas: each made DaylightUI's wherever it shows
-- ---------------------------------------------------------------------------------------------

local GAME = {
	progress = "Interface\\AchievementFrame\\UI-Achievement-ProgressBar-Border",  -- bar borders
	blueBar = "Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar-Blue",        -- list row hover
	ring = "Interface\\Minimap\\MiniMap-TrackingBorder",                           -- glance slots
	info = "Interface\\FriendsFrame\\InformationIcon",                             -- help "i"
	infoHi = "Interface\\FriendsFrame\\InformationIcon-Highlight",
	tile = "Interface\\Collections\\CollectionsBackgroundTile",                    -- help popups' ground
	knob = "Interface\\Buttons\\UI-SliderBar-Button-Horizontal",                   -- old slider thumb
	reorder = UI_ART .. "ui-button-reorder",
	reorderDown = UI_ART .. "ui-button-reorder-down",
	collapse = "Interface\\Buttons\\UI-Panel-CollapseButton-Up",
	collapseDown = "Interface\\Buttons\\UI-Panel-CollapseButton-Down",
	expand = "Interface\\Buttons\\UI-Panel-ExpandButton-Up",
	expandDown = "Interface\\Buttons\\UI-Panel-ExpandButton-Down",
	home = "Interface\\Buttons\\UI-HomeButton",
}
local GAME_IDS   -- file id (or lower-case path) -> its key in GAME

local function GameArt(tex)
	if not GAME_IDS then
		local paths = {}
		for key, path in pairs(GAME) do paths[path] = key end
		GAME_IDS = ns.FileIDs(paths)
	end
	local f = FileOf(tex)
	return f ~= nil and GAME_IDS[f] or nil
end

local function AtlasOf(tex)
	if not tex.GetAtlas then return nil end
	local ok, atlas = pcall(tex.GetAtlas, tex)
	return ok and type(atlas) == "string" and atlas or nil
end

local function Pixel(tex, h)
	if PixelUtil and PixelUtil.SetHeight then PixelUtil.SetHeight(tex, h) else tex:SetHeight(h) end
end

-- A picture kept, in gray: its own shape in the text color (lighter under the mouse).
local function Grey(tex, ink)
	if not ns.Usable(tex) then return end
	if tex.SetDesaturated then tex:SetDesaturated(true) end
	local c = ns.Colors()[ink or "TEXT"]
	if type(c) == "table" then tex:SetVertexColor(c[1], c[2], c[3]) end
end

-- Sliders: DaylightUI's look drawn from plain textures (its own art isn't ours to use): a thin
-- track, the accent fill up to the knob, a round knob that grows under the mouse. The game's
-- track and thumb stay (it moves the thumb) but out of sight; ours hangs on the thumb.
local KNOB_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local sliders = setmetatable({}, { __mode = "k" })

local function SliderLook(slider, withTrack)
	if not ns.Usable(slider) or slider:GetObjectType() ~= "Slider" or sliders[slider] then return end
	local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
	if not ns.Usable(thumb) then return end
	local s = {}
	sliders[slider] = s
	thumb:SetAlpha(0)
	if withTrack then
		s.track = slider:CreateTexture(nil, "ARTWORK")
		s.track:SetColorTexture(1, 1, 1, 0.14)
		s.track:SetPoint("LEFT", slider, "LEFT", 0, 0)
		s.track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
		Pixel(s.track, 4)
		s.fill = slider:CreateTexture(nil, "ARTWORK", nil, 1)
		s.fill:SetPoint("LEFT", s.track, "LEFT", 0, 0)
		s.fill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)
		Pixel(s.fill, 4)
	end
	s.knob = slider:CreateTexture(nil, "OVERLAY")
	s.knob:SetColorTexture(1, 1, 1, 1)
	s.knob:SetSize(12, 12)
	s.knob:SetPoint("CENTER", thumb, "CENTER", 0, 0)
	local mask = slider:CreateMaskTexture()
	mask:SetTexture(KNOB_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(s.knob)
	s.knob:AddMaskTexture(mask)
	local function paint()
		if s.fill then s.fill:SetColorTexture(ns.AccentOf(KEY)) end
		local on = not slider.IsEnabled or slider:IsEnabled()
		s.knob:SetVertexColor(1, 1, 1, on and 1 or 0.4)
	end
	s.paint = paint
	paint()
	slider:HookScript("OnEnter", function() s.knob:SetSize(14, 14) end)
	slider:HookScript("OnLeave", function() s.knob:SetSize(12, 12) end)
	slider:HookScript("OnShow", paint)
	slider:HookScript("OnEnable", paint)
	slider:HookScript("OnDisable", paint)
end

-- The stepper arrows beside a slider: kept, gray.
local function Stepper(b)
	if not ns.Usable(b) or not ns.Once(b) then return end
	for _, r in ipairs({ b:GetRegions() }) do
		if r:GetObjectType() == "Texture" then Grey(r, "TEXT") end
	end
end

local fixedArt = setmetatable({}, { __mode = "k" })
local barsDone = setmetatable({}, { __mode = "k" })

-- One texture of the game's art it borrows.
local function FixArt(Kit, r)
	if fixedArt[r] then return end
	local key = GameArt(r)
	local atlas = not key and AtlasOf(r) or nil
	if not key and not atlas then return end
	local parent = r:GetParent()
	if key == "progress" then
		fixedArt[r] = true
		Kill(r)
		-- The bar gets a thin edge; a plain progress bar also takes DaylightUI's bar look (the
		-- personality bars keep the colors the player picked).
		if ns.Usable(parent) and parent:GetObjectType() == "StatusBar" and not barsDone[parent] then
			barsDone[parent] = true
			if not parent.OppositeFill and Kit.StatusBar then ns.Guard(Kit.StatusBar, parent) end
			ns.Shell(parent, { noBackground = true, noBevel = true, borderPx = 2 }, KEY)
		end
	elseif key == "blueBar" then
		fixedArt[r] = true
		r:SetTexCoord(0, 1, 0, 1)
		r:SetColorTexture(1, 1, 1, 0.06)
		if r.SetBlendMode then r:SetBlendMode("BLEND") end
	elseif key == "ring" then
		fixedArt[r] = true
		Grey(r, "OFF")
	elseif key == "info" or key == "infoHi" then
		fixedArt[r] = true
		Grey(r, key == "info" and "LABEL" or "VALUE")
	elseif key == "tile" then
		fixedArt[r] = true
		Kill(r)
	elseif key == "knob" then
		fixedArt[r] = true
		SliderLook(parent, false)
	elseif key then
		-- Small buttons drawn with the game's arrows and icons: their shape, in gray.
		fixedArt[r] = true
		Grey(r, (key == "reorderDown" or key == "collapseDown" or key == "expandDown") and "VALUE" or "TEXT")
	elseif atlas == "Minimal_SliderBar_Left" or atlas == "_Minimal_SliderBar_Middle" or atlas == "Minimal_SliderBar_Right" then
		fixedArt[r] = true
		r:SetAlpha(0)
		SliderLook(parent, true)
	elseif atlas == "Minimal_SliderBar_Button_Left" or atlas == "Minimal_SliderBar_Button_Right" then
		fixedArt[r] = true
		Grey(r, "TEXT")
	elseif atlas == "Options_HorizontalDivider" then
		-- Its gold divider under page titles: a hairline.
		fixedArt[r] = true
		r:SetColorTexture(1, 1, 1, 0.08)
		Pixel(r, 1)
	elseif atlas == "collections-background-corner" or atlas == "Headhunter_BG" then
		fixedArt[r] = true
		Kill(r)
	elseif atlas == "storyheader-bg" then
		fixedArt[r] = true
		r:SetColorTexture(0, 0, 0, 0.3)
	elseif atlas == "Forge-ColorSwatchSelection" or atlas == "WoWShare-Selection" then
		-- The icon and pet browsers' picked mark: in the accent.
		fixedArt[r] = true
		if r.SetDesaturated then r:SetDesaturated(true) end
		r:SetVertexColor(ns.AccentOf(KEY))
	elseif atlas == "help-i" then
		fixedArt[r] = true
		Grey(r, "LABEL")
	end
end

-- Its color picker button (TRP3_ColorPickerButton): the color in a thin edge, not in the
-- achievement icon frame; a soft light under the mouse instead of its big glow.
local function ColorPicker(f)
	Kill(f.Border)
	local hl = f.SwatchBgHighlight
	if ns.Usable(hl) then
		hl:ClearAllPoints()
		hl:SetAllPoints(f)
		hl:SetTexCoord(0, 1, 0, 1)
		hl:SetColorTexture(1, 1, 1, 0.18)
		if hl.SetBlendMode then hl:SetBlendMode("ADD") end
	end
	ns.Shell(f, { noBackground = true, noBevel = true, borderPx = 2 }, KEY)
end

-- The game's stretch menu button (its click-binding buttons): nine pieces off, DaylightUI's button.
local STRETCH = { "TopLeft", "TopRight", "BottomLeft", "BottomRight", "TopMiddle", "MiddleLeft",
	"MiddleRight", "BottomMiddle", "MiddleMiddle" }

local function StretchButton(Kit, b)
	for _, key in ipairs(STRETCH) do Kill(b[key]) end
	if ns.Controls(KEY) then ns.Guard(Kit.Button, b) end
end

-- Its tabs (TRP3_TabButtonTemplate): DaylightUI's tabs. It never disables the picked one (it only
-- stops it taking the mouse), so the Kit can't see which is picked: SetTabState says, and the
-- picked one gets the accent line and the bright ink.
local tabPicked = setmetatable({}, { __mode = "k" })   -- tab -> "SELECTED" | "NORMAL" | "DISABLED"

local function PaintTab(Kit, tab)
	local state = tabPicked[tab]
	local look = Kit.TabOf and Kit.TabOf(tab)
	if type(look) == "table" and ns.Usable(look.line) then
		if state == "SELECTED" then
			look.line:SetColorTexture(ns.AccentOf(KEY))
			look.line:Show()
		else
			look.line:Hide()
		end
	end
	-- It swaps the label's font object with each state: the player's font goes back on.
	if ns.Usable(tab.Text) then Font(tab.Text) end
	Ink(tab.Text, state == "SELECTED" and "VALUE" or state == "DISABLED" and "OFF" or "LABEL")
end

local function Tab(Kit, tab)
	local disabled = tab.IsEnabled and not tab:IsEnabled()
	tabPicked[tab] = tab.LeftActive:IsShown() and "SELECTED" or disabled and "DISABLED" or "NORMAL"
	if ns.Controls(KEY) then
		ns.Guard(Kit.Tab, tab, function(self) return tabPicked[self] == "SELECTED" end)
	end
	hooksecurefunc(tab, "SetTabState", function(self, state)
		tabPicked[self] = state
		if ns.Enabled(KEY) then PaintTab(Kit, self) end
	end)
	PaintTab(Kit, tab)
end

-- Its template pieces, once per frame.
local function Pieces(Kit, f)
	local t = f:GetObjectType()
	if t == "Button" and ns.Usable(f.LeftActive) and ns.Usable(f.MiddleActive) and type(f.SetTabState) == "function" then
		Tab(Kit, f)
		return
	end
	if t == "Button" and ns.Usable(f.SwatchBg) and ns.Usable(f.Border) then
		skip[f] = true
		ColorPicker(f)
		return
	end
	if t == "Button" and ns.Usable(f.TopLeft) and ns.Usable(f.MiddleMiddle) then
		StretchButton(Kit, f)
		return
	end
	-- The slider's arrows (MinimalSliderWithSteppersTemplate): kept, gray. Its track and thumb are
	-- found by their art, below.
	if ns.Usable(f.Slider) and ns.Usable(f.Back) and ns.Usable(f.Forward) then
		Stepper(f.Back)
		Stepper(f.Forward)
		skip[f.Back], skip[f.Forward] = true, true
	end
	if f.BorderEdgeLeft and f.HighlightCenter then
		skip[f] = true
		Category(Kit, f)
		return
	end
	if (t == "Button" or t == "CheckButton") then
		local normal = f.GetNormalTexture and f:GetNormalTexture()
		if ns.Usable(f.EdgeLeft) and ns.Usable(f.EdgeRight) and ns.Usable(f.Center) and f.GetFontString then
			RedTextButton(Kit, f)
			return
		end
		if normal and IsRed(normal) then
			skip[f] = true
			RedArtButton(Kit, f)
			return
		end
		if normal and IsFramed(normal) then
			skip[f] = true
			FramedIcon(f)
			return
		end
		if t == "CheckButton" and IsMinimalCheck(f) then
			if ns.Controls(KEY) then ns.Guard(Kit.Check, f) end
			return
		end
	end
	if ns.Usable(f.IconMask) and ns.Usable(f.Icon) and ns.Usable(f.Border) then
		skip[f] = true
		BorderedIcon(f)
		return
	end
	if IsChrome(f.Background) and IsChrome(f.Border) and not HasBackdrop(f) then
		SliceRow(Kit, f)
		return
	end
	-- TRP3_InnerFrame: the game's inset art round a dialog ground.
	if ns.Usable(f.InsetBorderBottomLeft) then
		ns.Guard(Kit.Inset, f)
	end
end

-- ---------------------------------------------------------------------------------------------
-- The walk
-- ---------------------------------------------------------------------------------------------

local SKIP_KINDS = { GameTooltip = true, SimpleHTML = true, Model = true, PlayerModel = true,
	DressUpModel = true, CinematicModel = true, ModelScene = true, Cooldown = true, ColorSelect = true,
	MessageFrame = true, ScrollingMessageFrame = true, Minimap = true }
local DEPTH = 16

local Queue
local shownHooked = setmetatable({}, { __mode = "k" })
local sizeHooked = setmetatable({}, { __mode = "k" })
local rowsHooked = setmetatable({}, { __mode = "k" })

-- One frame: its pieces (once), its backdrop, its art by file, its text. Answers whether what's
-- inside it is inside a shell.
local function Dress(Kit, f, depth, inShell, rows)
	if not dressed[f] then
		dressed[f] = true
		Pieces(Kit, f)
		local host = Host(f)
		if f.backdropInfo ~= nil and f.backdropInfo == _G.TRP3_BACKDROP_OVERLAY then
			Overlay(f)
		elseif HasBackdrop(f) then
			if not inShell or host then
				ShellOf(f)
				dressed[f] = "shell"
			else
				Well(f)
			end
		elseif host and ns.Usable(f.NineSlice) and f.NineSlice:GetObjectType() == "Frame" then
			ShellOf(f)
			dressed[f] = "shell"
		elseif host and ns.Usable(f.Backdrop) and f.Backdrop.layoutType and not HasBackdrop(f.Backdrop) then
			-- A NineSlice panel under the key Backdrop (the icon browser's hover card).
			ns.Kill(f.Backdrop)
			ns.Shell(f, { window = true }, KEY)
			dressed[f] = "shell"
		elseif host then
			dressed[f] = "host"
		end
	end
	for _, r in ipairs({ f:GetRegions() }) do
		local kind = r:GetObjectType()
		if kind == "Texture" then
			if not killed[r] and not fixedArt[r] then FixArt(Kit, r) end
			if not killed[r] then
				if IsChrome(r) then
					Kill(r)
				elseif IsBand(r) then
					killed[r] = true
					r:SetTexCoord(0, 1, 0, 1)
					r:SetColorTexture(0, 0, 0, 0.3)
				end
			end
		elseif kind == "FontString" then
			Text(r)
		end
	end
	if f:GetObjectType() == "EditBox" then Font(f) end
	-- Edit mode adds lines to a scroll child: dressed as it grows.
	if f.GetScrollChild and not rows then
		local child = f:GetScrollChild()
		if ns.Usable(child) and not sizeHooked[child] then
			sizeHooked[child] = true
			local shelled = inShell or dressed[f] == "shell"
			child:HookScript("OnSizeChanged", function(self) Queue(self, shelled) end)
		end
	end
	-- A ScrollBox list: each row as it is filled.
	if f.ForEachFrame and f.ScrollTarget and Kit.EachRow and not rowsHooked[f] then
		rowsHooked[f] = true
		ns.Guard(Kit.EachRow, f, function(row)
			if ns.Enabled(KEY) and ns.Usable(row) then Queue(row, true, true) end
		end, "DaylightAddonSkins.totalRP3")
	end
	-- Panels inside a window: dressed again when they show (tabs, edit and view modes).
	local kind = f:GetObjectType()
	if not rows and depth > 0 and depth <= 6 and kind ~= "Button" and kind ~= "CheckButton"
		and not shownHooked[f] and f.HookScript and f:GetNumChildren() > 0 then
		shownHooked[f] = true
		local shelled = inShell or dressed[f] == "shell"
		f:HookScript("OnShow", function(self) Queue(self, shelled) end)
	end
	if dressed[f] == "shell" then return true end
	if dressed[f] == "host" then return false end
	return inShell
end

local function Walk(Kit, f, depth, inShell, rows)
	if depth > DEPTH or not ns.Usable(f) or SKIP_KINDS[f:GetObjectType()] then return end
	local ok, inside = xpcall(Dress, geterrorhandler(), Kit, f, depth, inShell, rows)
	if not ok then inside = inShell end
	for _, child in ipairs({ f:GetChildren() }) do
		Walk(Kit, child, depth + 1, inside, rows)
	end
end

-- What to do on the next frame: { frame = inShell }; rows are walked without new hooks.
local pending, pendingRows, queued = {}, {}, false

local function Run()
	queued = false
	local Kit = ns.Kit
	if not Kit or not ns.Enabled(KEY) then
		wipe(pending)
		wipe(pendingRows)
		return
	end
	Learn()
	local list, rowList = pending, pendingRows
	pending, pendingRows = {}, {}
	for row, inShell in pairs(rowList) do
		if ns.Usable(row) then Walk(Kit, row, 1, inShell, true) end
	end
	for f, inShell in pairs(list) do
		if ns.Usable(f) and f:IsVisible() then
			Walk(Kit, f, 0, inShell, false)
			if ns.Controls(KEY) then
				ns.Guard(Kit.Auto, f, { skip = skip, shownOnly = true, depth = DEPTH })
			end
		end
	end
end

Queue = function(f, inShell, rows)
	if not ns.Usable(f) then return end
	if rows then pendingRows[f] = inShell and true or false else pending[f] = inShell and true or false end
	if not queued then
		queued = true
		C_Timer.After(0, Run)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Windows
-- ---------------------------------------------------------------------------------------------

-- The main window: its wooden frame and grounds off, the shell on, a faint line where the sidebar's
-- wooden divider was.
local function MainFrame(f, Kit)
	if not ns.Once(f) then return end
	Learn()
	if ns.Usable(f.Backdrop) then
		HidePieces(f.Backdrop)
		dressed[f.Backdrop] = true
		for _, key in ipairs({ "LeftWoodBorder", "RightWoodBorder", "TopWoodBorder", "BottomWoodBorder" }) do
			Kill(f.Backdrop[key])
		end
	end
	Kill(f.Background)
	ns.Shell(f, { window = true }, KEY)
	dressed[f] = "shell"
	local menu = _G.TRP3_MainFrameMenuScroll
	if ns.Usable(menu) then
		dressed[menu] = true
		Kill(menu.Background)
		Kill(menu.SidebarWoodBorder)
		local line = menu:CreateTexture(nil, "BORDER")
		line:SetColorTexture(1, 1, 1, 0.08)
		line:SetWidth(1)
		line:SetPoint("TOP", menu, "TOP", 0, 12)
		line:SetPoint("BOTTOM", menu, "BOTTOM", 0, -12)
		line:SetPoint("LEFT", menu, "LEFT", 190, 0)
	end
	if ns.Usable(f.ResizeButton) then
		skip[f.ResizeButton] = true
		RedArtButton(Kit, f.ResizeButton)
		dressed[f.ResizeButton] = true
	end
	f:HookScript("OnShow", function(self) Queue(self, true) end)
	if f:IsShown() then Queue(f, true) end
end

-- A frame of its own on the screen (or made late inside the main window).
local function Root(f)
	if not ns.Usable(f) or not ns.Once(f) then return end
	HOSTS[f] = true
	f:HookScript("OnShow", function(self) Queue(self, false) end)
	if f:IsShown() then Queue(f, false) end
end

local ROOTS = { "TRP3_ToolbarFrame", "TRP3_TargetFrame", "TRP3_GlanceBar", "TRP3_CurrentlyFrame",
	"TRP3_NPCTalkFrame", "TRP3_StaticPopUpCopyDropdown",
	"TRP3_ScanLoaderFrame", "TRP3_ResizeShadowFrame", "TRP3_IconBrowserButtonTooltip", "TRP3_PetBrowserFrame",
	"TRP3_MatureDictionaryEditor", "TRP3_WorldMapButton" }

-- Frames drawn with the game's glow box or dialog border rather than a backdrop: that art off,
-- the shell on.
local GLOWS = { "TRP3_AtFirstGlanceEditor", "TRP3_TutorialTooltip", "TRP3_LinkCopyDialog" }

local function Glow(f, Kit)
	if not ns.Usable(f) or not ns.Once(f) then return end
	ns.Guard(Kit.Strip, f)
	if ns.Usable(f.Border) and f.Border:GetObjectType() == "Frame" then ns.Kill(f.Border) end
	ns.Shell(f, { window = true }, KEY)
	dressed[f] = "shell"
	HOSTS[f] = true
	f:HookScript("OnShow", function(self) Queue(self, true) end)
	if f:IsShown() then Queue(f, true) end
end

-- Its own tooltips (character and companion cards, its main tooltip, chat links, toasts).
-- DaylightUI's Tooltip module dresses the game's named tooltips only, so these get its flat
-- tooltip look here: the game's border (restyled by the game on every show) hidden each show, the
-- shell kept just under the tooltip as its level changes. What's in them is Total RP 3's and
-- stays as it draws it.
local TIPS = { "TRP3_MainTooltip", "TRP3_CharacterTooltip", "TRP3_CompanionTooltip", "TRP3_RefTooltip", "TRP3_Toast" }
local TIP_LOOK = { noBevel = true, borderPx = 2, bgAlpha = 0.92 }

local function Tooltip(tip, Kit)
	if not ns.Usable(tip) or not ns.Once(tip) then return end
	local shell = API.Skin(tip, TIP_LOOK)
	ns.Shell(tip, TIP_LOOK, KEY)
	local function settle(self)
		if not ns.Enabled(KEY) then return end
		if ns.Usable(self.NineSlice) then self.NineSlice:SetAlpha(0) end
		if type(shell) == "table" and shell.SetFrameLevel then
			shell:SetFrameLevel(math.max(0, self:GetFrameLevel() - 1))
		end
	end
	settle(tip)
	tip:HookScript("OnShow", settle)
	if ns.Controls(KEY) and ns.Usable(tip.CloseButton) then ns.Guard(Kit.Close, tip.CloseButton) end
end

-- Sidebar buttons made from now on are hooked through the mixin they copy.
local mixin = _G.TRP3_CategoryButtonMixin
if type(mixin) == "table" and type(mixin.SetSelected) == "function" then
	hooksecurefunc(mixin, "SetSelected", function(self)
		if not ns.Enabled(KEY) then return end
		if dressed[self] then
			if ns.Kit then ns.Guard(ns.Kit.RepaintRow, self) end
			CategoryInk(self)
		else
			Queue(self, true)
		end
	end)
end

ns.Pack(KEY, nil, function(Kit)
	Learn()
	ns.Watch(KEY, "TRP3_MainFrame", MainFrame)
	for _, name in ipairs(GLOWS) do ns.Watch(KEY, name, Glow) end
	for _, name in ipairs(ROOTS) do ns.Watch(KEY, name, Root) end
	for _, name in ipairs(TIPS) do ns.Watch(KEY, name, Tooltip) end
	-- Each page as it opens (pages are made the first time they're opened).
	if type(_G.TRP3_Addon) == "table" and type(TRP3_API.RegisterCallback) == "function"
		and type(TRP3_Addon.Events) == "table" and TRP3_Addon.Events.PAGE_OPENED then
		TRP3_API.RegisterCallback(TRP3_Addon, TRP3_Addon.Events.PAGE_OPENED, function()
			if ns.Enabled(KEY) and ns.Usable(_G.TRP3_MainFramePageContainer) then
				Queue(_G.TRP3_MainFramePageContainer, true)
			end
		end)
	end
end)

-- ---------------------------------------------------------------------------------------------
-- DaylightUI Override
-- ---------------------------------------------------------------------------------------------

local function Config() return type(TRP3_API.configuration) == "table" and TRP3_API.configuration or nil end

ns.Handover(KEY, {
	ready = function()
		local c = Config()
		if not c or type(c.getDefaultValue) ~= "function" or type(_G.TRP3_Configuration) ~= "table" then return false end
		return (pcall(c.getDefaultValue, "tooltip_char_HideOriginal"))
	end,
	get = function(key)
		local c = Config()
		if not c then return nil end
		local ok, value = pcall(c.getValue, key)
		if ok then return value end
		return nil
	end,
	set = function(key, value)
		local c = Config()
		if c then pcall(c.setValue, key, value) end
	end,
	list = {
		{ key = "tooltip_char_HideOriginal", label = "Unit tooltip (its RP card replacing the game's)",
		  daylight = "its unit tooltip; Total RP 3's RP card then shows beside it",
		  ours = function() return ns.DaylightHas("Tooltip", "anchor", function() return true end) end },
		{ key = "chat_color", label = "Name colors in chat",
		  daylight = "class-colored names in chat",
		  ours = function() return ns.DaylightHas("Chat", "classColors") end },
	},
})
