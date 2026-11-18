-- High Fidelity World Map (HFWM): the controls it puts on the world map, its cave map window and its
-- settings pages, in the DaylightUI look. What's dressed and how:
--   * The HD / SD button in the map's top-right corner (HFWMForeverToggleButton, the game's red
--     UIPanelButtonTemplate): a DaylightUI button, its "HD" / "SD" in DaylightUI's font; the small
--     gold dot it shows while the map is a blend of the two, in the accent.
--   * The blend slider that drops below it on a right click (made on the first right click: dressed
--     in that click): DaylightUI's window shell instead of the tooltip border, the "Blend: 50%"
--     caption in the value ink, the slider (OptionsSliderTemplate) as DaylightUI's slider, the
--     pin / close mark in the text ink with a quiet wash under the mouse.
--   * The cave map window (an AceGUI "Frame" that HFWM dresses as the game menu: the Dialog
--     nine-slice border, the header plate and the tiled dialog ground): border and plate off, the
--     window shell instead (DaylightUI's Ace3 look already gave it one; this pack adds one if not),
--     the area name on the left of the title row in the value ink (HFWM sets its font and spot
--     again each time it shows a cave: put back each time), the X DaylightUI's, the window's ground
--     following HFWM's "Cave map opacity" (it was the dialog ground's). Its depth slider (a vertical
--     slider on the SliderBar backdrop with the scroll bar knob) as DaylightUI's slider; the height
--     window on it (the knob stretched, with two edge grips) as a bar in the scroll thumb's colors,
--     lighter under the mouse and while dragged, the grips' gold glow in the accent (along a
--     gradient accent's two ends); the floor dropdown
--     (UIDropDownMenuTemplate) as DaylightUI's box, its list the game's DropDownList (Blizzard.lua).
--     The status line under it is DaylightUI's Ace3 look's.
--   * The "Open cave map" button (HFWMForeverCaveReopenButton, made the first time a cave is closed):
--     its dialog border and ground off, a control box round its map icon (the icon stays).
--   * Its pages in the game's settings (AceConfig: Esc > Options > AddOns > High Fidelity World Map,
--     and its Area Labels, Cave Map, Instance Map and Profiles pages): every AceGUI widget is
--     DaylightUI's Ace3 look's (HFWM's own dropdown, checkbox and section reset widgets are built
--     from AceGUI's stock ones and registered under their names, so they're dressed as those);
--     here: the Reset to Defaults and Open / Close preview buttons beside the logo as DaylightUI's
--     buttons, and each section's gold reset arrows in the text ink (dim while it can't be used).
-- Left as they are: everything on the map itself (the satellite tiles, the fog of war, the
-- exploration art it adds, the caves' art, the player arrow, corpse and group dots, the area labels,
-- with their own fonts, colors and outlines set on its Area Labels page, and the map background it
-- picks behind the map, MapFrameBg), its logo on the settings pages, the "Use Global" and "All"
-- entries in Blizzard cyan (they mean "inherited") and the gray and red notes in the cave window's
-- status line. Its tooltips are the game's (GameTooltip) or its own GameTooltipTemplate one
-- (HFWMArtTooltip, made as it loads): DaylightUI's tooltip skin has both. Its popups (the Art link,
-- page reset and experimental confirmations) are the game's StaticPopup, which DaylightUI dresses.
-- /hfwm issue opens an AceGUI window: DaylightUI's Ace3 look. The game's coordinate readouts it
-- shows or hides are the game's own.
-- Text: a long area name in a narrow cave window and a long floor name in the dropdown's box are
-- shrunk a size or two to fit (DaylightUI's font runs wider), never cut off. AceGUI's drag strip
-- for the window (sized to its title, from above the window's top) is put on the title row, so it
-- doesn't take the map's clicks above the window.
-- How the pieces are found: HFWM keeps its code in its own namespace, so by name (the toggle, the
-- slider, the reopen button, the floor dropdown) and by AceGUI. The cave window from AceGUI: every
-- AceGUI "Frame" (made, or handed back to its pool, after this pack starts; those already in the
-- pool, and a cave window already up, are looked through as it starts) has its title's
-- SetFontObject followed, which HFWM calls only while it puts its game-menu dress on the cave
-- window (as it's made and each time it shows a cave), so the window is dressed right there,
-- before it's drawn; its parts made later (its X, the depth slider, the height window, the floor
-- dropdown) are dressed from HFWM's opacity call on the window's ground, which ends the making of
-- the window and every cave it shows, after those are made and before the window shows. The blend
-- slider from the toggle's own click. The "Open cave map" button from the click that makes it (the
-- cave window's X, HFWM's Alt-M key button). The settings pages' buttons by AceConfigDialog's list
-- of HFWM's pages; the reset arrows from AceGUI as each button is made. After any change of HFWM's
-- settings (AceConfigRegistry's change notice, which its pages and profiles send; /hfwm), what it
-- made is dressed at once. Watches by name are the fallback (the toggle and the reopen button as
-- HFWM makes them at login and from its cave poller, the pages if not there yet), each stopped as
-- soon as its frame can't come (the toggle or the cave map switched off, the pages 30 seconds after
-- login) and started again by the change notice. The AceGUI hooks go in only when this pack starts
-- (with HFWM loaded), again only for a newer AceGUI version.
-- Taint (HFWM's Taint.lua): nothing here runs inside the world map's or the settings window's own
-- show, hide or refresh. No hook on WorldMapFrame or any frame of the game's, no OnShow / OnHide
-- hook on anything inside the map or the settings window, no script set: only HFWM's own frames and
-- textures are dressed and post-hooked (mouse scripts, their own methods), the AceGUI library is
-- post-hooked as DaylightUI's Ace3 look does, and the map is never shown, hidden or written.
-- Conflicts with DaylightUI (the hand-over, on this pack's page): HFWM's Fog of War off on zone maps
-- (Hybrid background) draws the unexplored areas, as DaylightUI's map reveal (Window Skins) does:
-- given to DaylightUI by default (HFWM's Fog of War back on, an open map redrawn), the way back on
-- the page's DaylightUI tab. Its HD map, area labels, cave map,
-- coordinates switches, zoom memory and the rest have no DaylightUI copy.
local _, ns = ...
if not ns.ok then return end

local KEY = "HighFidelityWorldMap"
-- (Its words are the game's font objects: the player's font goes on all of them.)
local CAPS = { window = true, controls = true, text = true, shadow = true, font = "daylight",
	extraTab = "DaylightUI", extra = function() return { ns.HandoverGroup(KEY) } end }
ns.Target(KEY, "High Fidelity World Map", CAPS)

local L = ns.L
local Usable, Guard = ns.Usable, ns.Guard
local type, ipairs, pairs, select = type, ipairs, pairs, select

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end
local function Kind(x) return Usable(x) and x:GetObjectType() or nil end
local function IsTexture(x) return Kind(x) == "Texture" end

-- Each of HFWM's frames is looked over once (its own list: ns.Once is the dressing walk's).
local seen = setmetatable({}, { __mode = "k" })
local function First(x)
	if seen[x] then return false end
	seen[x] = true
	return true
end

local function Ink(name)
	local c = ns.Colors()[name]
	if type(c) ~= "table" then return 1, 1, 1 end
	return c[1], c[2], c[3]
end

-- The player's font on one of its strings, and one of DaylightUI's inks (unless the page says to
-- keep its colors).
local function Words(fs, ink)
	if Kind(fs) ~= "FontString" then return end
	ns.FollowFont(fs, KEY)
	if ink and ns.Look(KEY, "daylightColors") ~= false then fs:SetTextColor(Ink(ink)) end
end

-- Its art, by file (the game hands a texture's file back as a number).
local FILES
local function FileKind(tex)
	if not FILES then
		FILES = ns.FileIDs({
			["Interface\\DialogFrame\\UI-DialogBox-Background"] = "ground",
			["Interface\\Buttons\\UI-RefreshButton"] = "reset",
			["Interface\\Buttons\\ButtonHilight-Square"] = "glow",
			["Interface\\Buttons\\UI-ScrollBar-Knob"] = "knob",
		})
	end
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return nil end
	if type(file) == "string" then file = string.lower(file) end
	return FILES[file]
end

-- What follows the accent and DaylightUI's look: painted again when either changes.
local paints = {}
local function Paint(fn)
	paints[#paints + 1] = fn
	Guard(fn)
end
local paintQueued = false
local function PaintSoon()
	if paintQueued then return end
	paintQueued = true
	C_Timer.After(0, function()
		paintQueued = false
		if not On() then return end
		for i = 1, #paints do Guard(paints[i]) end
	end)
end
ns.me.On("StyleChanged", PaintSoon)
ns.me.On("SettingChanged", function(scope, path)
	if scope == "DaylightAddonSkins" and type(path) == "string" and string.find(path, "look." .. KEY .. ".", 1, true) == 1 then
		PaintSoon()
	end
end)

-- A glyph of its (a mark drawn in gold, red or gray) in the text ink, kept there as it's swapped.
local function Glyph(tex)
	if not IsTexture(tex) or not On() then return end
	tex:SetDesaturated(true)
	tex:SetVertexColor(Ink("TEXT"))
end

-- ---------------------------------------------------------------------------------------------
-- The HD / SD button and its blend slider
-- ---------------------------------------------------------------------------------------------

-- The slider's flyout (made on the first right click, inside the button's click): its tooltip
-- border off, the shell, the caption, the slider, the pin.
local function Popup(slider)
	if Kind(slider) ~= "Slider" then return end
	local popup = slider:GetParent()
	if not Usable(popup) or not First(popup) then return end
	local Kit = ns.Kit
	ns.NoBackdrop(popup)
	ns.Shell(popup, { window = true }, KEY)
	for i = 1, select("#", popup:GetRegions()) do
		local r = select(i, popup:GetRegions())
		if Kind(r) == "FontString" then Words(r, "VALUE") end
	end
	if Controls() and ns.Slider then ns.Slider(slider) end
	-- The pin (its gray dot, then the red X that closes it): a quiet wash under the mouse instead of
	-- the square glow, its mark in the text ink as it's swapped.
	for i = 1, select("#", popup:GetChildren()) do
		local b = select(i, popup:GetChildren())
		if Kind(b) == "Button" and b ~= slider then
			if Kit and Controls() then
				Kit.Hide(b:GetHighlightTexture())
				Kit.HoverWash(b)
			end
			for j = 1, select("#", b:GetRegions()) do
				local r = select(j, b:GetRegions())
				if IsTexture(r) and r:GetDrawLayer() == "ARTWORK" then
					Glyph(r)
					hooksecurefunc(r, "SetTexture", Glyph)
				end
			end
		end
	end
end

local function Toggle(btn)
	if Kind(btn) ~= "Button" or not First(btn) then return end
	local Kit = ns.Kit
	if Kit and Controls() then
		Guard(Kit.Button, btn)
	else
		Words(btn.GetFontString and btn:GetFontString())
	end
	-- The dot on its corner while the map is a blend of HD and SD (the game's yellow light).
	local dot = btn.blendLine
	if IsTexture(dot) then
		Paint(function()
			dot:SetDesaturated(true)
			ns.PaintAccent(dot, 1, nil, KEY)
		end)
	end
	-- (A right click makes the slider the first time, then shows it: dressed right after.)
	btn:HookScript("OnClick", function(_, mouse)
		if mouse == "RightButton" and On() then Guard(Popup, _G.HFWMForeverOpacitySlider) end
	end)
end

-- ---------------------------------------------------------------------------------------------
-- The cave map window
-- ---------------------------------------------------------------------------------------------

local caveShell = setmetatable({}, { __mode = "k" })   -- window -> its shell

-- The game-menu dress HFWM puts on it: DialogHeaderTemplate (its header plate) and
-- DialogBorderNoCenterTemplate (the Dialog nine-slice). Both there: the cave window.
local function CaveParts(f)
	local header, border
	for i = 1, select("#", f:GetChildren()) do
		local c = select(i, f:GetChildren())
		if Usable(c) then
			if type(c.headerTextPadding) == "number" then header = c
			elseif c.layoutType == "Dialog" then border = c end
		end
	end
	return header, border
end

-- The window's ground follows HFWM's "Cave map opacity" (its dialog ground's alpha).
local function Ground(f, alpha)
	local s = caveShell[f]
	if type(s) == "table" and IsTexture(s.bg) and type(alpha) == "number" then s.bg:SetAlpha(alpha) end
end

-- The height window on the depth slider (the scroll bar's knob stretched to the range shown, two
-- grips at its ends with a gold glow): a bar in the scroll thumb's colors, the glow in the accent.
local function Knobbed(body)
	for i = 1, select("#", body:GetRegions()) do
		local r = select(i, body:GetRegions())
		if IsTexture(r) and FileKind(r) == "knob" then return true end
	end
	return false
end

local function HeightWindow(body)
	if Kind(body) ~= "Button" or seen[body] or not Knobbed(body) then return end
	seen[body] = true
	local Kit = ns.Kit
	local S = Kit and Kit.SCROLL
	if type(S) ~= "table" then return end
	for i = 1, select("#", body:GetRegions()) do
		local r = select(i, body:GetRegions())
		if IsTexture(r) then Kit.Hide(r) end
	end
	local bar = body:CreateTexture(nil, "ARTWORK", nil, 3)
	bar:SetColorTexture(1, 1, 1, 1)
	bar:SetWidth(S.width or 6)
	bar:SetPoint("TOP", body, "TOP", 0, 0)
	bar:SetPoint("BOTTOM", body, "BOTTOM", 0, 0)
	local handles = { body }
	-- Lighter under the mouse and while it's being dragged (HFWM starts a drag on a press on the
	-- body or a grip and follows it until the button is let go, wherever the mouse is by then: the
	-- release comes back to the part that was pressed).
	local held = false
	local function shade()
		-- (A release that never came back, the window hidden mid-drag: over once the button's up.)
		if held and not _G.IsMouseButtonDown("LeftButton") then held = false end
		local over = held
		for _, h in ipairs(handles) do
			if h:IsMouseOver() then over = true end
		end
		local c = over and S.thumbHover or S.thumb
		if type(c) == "table" then bar:SetVertexColor(c[1], c[2], c[3], c[4] or 1) end
	end
	local function press(_, mouse)
		if mouse == "LeftButton" then held = true shade() end
	end
	local function release()
		held = false
		shade()
	end
	local glows = {}
	for i = 1, select("#", body:GetChildren()) do
		local h = select(i, body:GetChildren())
		if Kind(h) == "Button" then
			handles[#handles + 1] = h
			for j = 1, select("#", h:GetRegions()) do
				local r = select(j, h:GetRegions())
				if IsTexture(r) and r:GetDrawLayer() == "OVERLAY" and r:GetBlendMode() == "ADD" then glows[#glows + 1] = r end
			end
		end
	end
	for _, h in ipairs(handles) do
		h:HookScript("OnEnter", shade)
		h:HookScript("OnLeave", shade)
		h:HookScript("OnMouseDown", press)
		h:HookScript("OnMouseUp", release)
	end
	Paint(shade)
	-- Each glow is half a band that fades out away from its grip's line (the half above it bright
	-- at its bottom, the half below bright at its top; which one is told by its anchor). A texture
	-- takes one gradient, so the fade stays and the accent is the colors along it: a gradient
	-- accent's two ends (its light end on the line), else the one color. HFWM's own update fades
	-- the glow in while the mouse is on a grip or that grip is being dragged.
	Paint(function()
		local lo, hi = ns.AccentPairOf(KEY)
		local inner, outer
		if lo then
			inner, outer = CreateColor(hi[1], hi[2], hi[3], 0.85), CreateColor(lo[1], lo[2], lo[3], 0)
		else
			local r, g, b = ns.AccentOf(KEY)
			inner, outer = CreateColor(r, g, b, 0.85), CreateColor(r, g, b, 0)
		end
		for _, t in ipairs(glows) do
			local point = t:GetPoint(1)
			if type(point) == "string" and string.find(point, "^BOTTOM") then
				t:SetGradient("VERTICAL", inner, outer)
			else
				t:SetGradient("VERTICAL", outer, inner)
			end
		end
	end)
end

-- A string shrunk a size at a time (from `base`, at most four sizes) until it fits `width`, instead
-- of being cut off: DaylightUI's font runs wider than the game's.
local function Fit(fs, width, base)
	if Kind(fs) ~= "FontString" or type(width) ~= "number" or width <= 0 then return end
	local face, size, flags = fs:GetFont()
	if not face or type(size) ~= "number" then return end
	base = base or size
	local function wide()
		if fs.GetUnboundedStringWidth then return fs:GetUnboundedStringWidth() end
		return fs:GetStringWidth()
	end
	local s = base
	if s ~= size then fs:SetFont(face, s, flags or "") end
	while s > base - 4 and wide() > width do
		s = s - 1
		fs:SetFont(face, s, flags or "")
	end
end

local dropBase = setmetatable({}, { __mode = "k" })   -- the floor dropdown's text -> its size

local ReopenNow   -- (below: the "Open cave map" button, dressed as soon as it's made)

-- The parts HFWM makes as a cave needs them, each dressed once: its X (made after the dress that
-- finds the window), the depth slider's gutter (a frame holding the vertical slider and the
-- height window) and the floor dropdown. Looked at after every cave it shows; the floor's name in
-- the dropdown fitted to its box each time.
local function Sweep(f)
	if not On() or not ns.Kit then return end
	local Kit = ns.Kit
	local close = ns.FindClose(f)
	if close and not seen[close] then
		seen[close] = true
		if Controls() then Guard(Kit.Close, close) end
		-- Its click closes this cave and puts up the "Open cave map" button.
		close:HookScript("OnClick", function() Guard(ReopenNow) end)
	end
	for i = 1, select("#", f:GetChildren()) do
		local col = select(i, f:GetChildren())
		if Kind(col) == "Frame" then
			for j = 1, select("#", col:GetChildren()) do
				local c = select(j, col:GetChildren())
				local kind = Kind(c)
				if kind == "Slider" and c.GetOrientation and c:GetOrientation() == "VERTICAL" then
					if Controls() and ns.Slider then ns.Slider(c) end
				elseif kind == "Button" and c:GetNumChildren() == 2 then
					HeightWindow(c)
				end
			end
		end
	end
	local dd = _G.HFWMForeverCaveFloorDropdown
	if Usable(dd) then
		if Controls() and ns.OldDropdown then ns.OldDropdown(dd) end
		local text = dd.Text or _G.HFWMForeverCaveFloorDropdownText
		if Kind(text) == "FontString" then
			if not dropBase[text] then dropBase[text] = select(2, text:GetFont()) end
			Fit(text, text:GetWidth(), dropBase[text])
		end
	end
end

local titleBusy = false

-- Its dress, once; then its title (HFWM's font on it again) every time.
local function Cave(w)
	local f, title = w.frame, w.titletext
	if not Usable(f) or not On() then return end
	local Kit = ns.Kit
	if First(f) then
		local header, border = CaveParts(f)
		ns.Kill(header)
		ns.Kill(border)
		if not Kit.ShellOf(f) then ns.Shell(f, { window = true }, KEY) end
		caveShell[f] = Kit.ShellOf(f)
		-- AceGUI's drag strip is the frame over its header art (titlebg: 40 px tall, from 12 px
		-- above the window, as wide as the title + 10). With the title across the title row it
		-- grew into a strip above the window that took the map's clicks: the title row itself now
		-- (the X's corner left out).
		local strip = w.titlebg
		if IsTexture(strip) then
			strip:ClearAllPoints()
			strip:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -2)
			strip:SetPoint("TOPRIGHT", f, "TOPRIGHT", -32, -2)
			strip:SetHeight(24)
		end
		-- The title sat on the header plate (anchored to it on every cave shown): on the left of the
		-- title row instead, each time it's placed.
		if Kind(title) == "FontString" then
			hooksecurefunc(title, "SetPoint", function(fs)
				if titleBusy or not On() then return end
				titleBusy = true
				Guard(Kit.Title, f, fs)
				titleBusy = false
			end)
			titleBusy = true
			Guard(Kit.Title, f, title)
			titleBusy = false
		end
		-- The dialog ground: gone, its alpha (the cave map opacity) put on the shell's ground. HFWM
		-- sets that alpha at the end of every cave it shows, after making what the cave needs.
		for i = 1, select("#", f:GetRegions()) do
			local r = select(i, f:GetRegions())
			if IsTexture(r) and FileKind(r) == "ground" then
				local alpha = r:GetAlpha()
				Kit.Erase(r)
				Ground(f, alpha)
				hooksecurefunc(r, "SetAlpha", function(_, a)
					if not On() then return end
					Ground(f, a)
					Guard(Sweep, f)
				end)
				break
			end
		end
	end
	titleBusy = true
	Words(title, "VALUE")
	-- A long area name in a narrow cave window: a size or two smaller, never cut off.
	if Kind(title) == "FontString" then
		Fit(title, (f:GetWidth() or 0) - (Kit.TITLE_X or 16) - (Kit.TITLE_RIGHT or 40))
	end
	titleBusy = false
	Sweep(f)
end

-- An AceGUI Frame's title given a font object: only HFWM's cave dress does that.
local function TitleFont(w)
	if titleBusy or type(w) ~= "table" or not Usable(w.frame) then return end
	local header, border = CaveParts(w.frame)
	if not (header and border) or not On() then return end
	ns.WithKit(function() Cave(w) end)
end

-- ---------------------------------------------------------------------------------------------
-- The settings pages
-- ---------------------------------------------------------------------------------------------

-- AceConfigDialog keeps each page HFWM puts in the game's settings by its app name.
local PAGES = { "_Main", "_areaLabels", "_cave", "_instance", "_profiles" }
local function Page(suffix)
	local ACD = type(LibStub) == "table" and LibStub("AceConfigDialog-3.0", true)
	local list = type(ACD) == "table" and ACD.BlizOptions
	local app = KEY .. suffix
	local group = type(list) == "table" and type(list[app]) == "table" and list[app][app]
	local frame = type(group) == "table" and group.frame
	return Usable(frame) and frame or nil
end

-- The two buttons by the logo (Reset to Defaults, Open / Close preview): the page's own children.
local function Pages(Kit)
	if not Controls() then return end
	for _, suffix in ipairs(PAGES) do
		local frame = Page(suffix)
		if frame and First(frame) then
			for i = 1, select("#", frame:GetChildren()) do
				local b = select(i, frame:GetChildren())
				if Kind(b) == "Button" and IsTexture(b.Left) and IsTexture(b.Right) and not Kit.ButtonOf(b) then
					Guard(Kit.Button, b)
				end
			end
		end
	end
end

-- A section's reset arrows (HFWM's widget on AceGUI's Button: the real button moved onto a holder,
-- its words hidden, the game's gold arrows on it). HFWM sets their gray with SetDesaturated as the
-- section is turned on or off: kept in the text ink, dimmed while off.
local resetBusy = false
local function ResetGlyph(icon, off)
	if resetBusy then return end
	resetBusy = true
	icon:SetDesaturated(true)
	icon:SetVertexColor(Ink("TEXT"))
	icon:SetAlpha(off and 0.4 or 1)
	resetBusy = false
end

local function ResetArrows(w)
	if w.type ~= "HFWM-SectionReset" or not Usable(w.frame) or not On() then return end
	for i = 1, select("#", w.frame:GetChildren()) do
		local b = select(i, w.frame:GetChildren())
		if Kind(b) == "Button" then
			for j = 1, select("#", b:GetRegions()) do
				local r = select(j, b:GetRegions())
				if IsTexture(r) and FileKind(r) == "reset" and First(r) then
					ResetGlyph(r, w.disabled)
					hooksecurefunc(r, "SetDesaturated", function(self, off)
						if On() then ResetGlyph(self, off) end
					end)
				end
			end
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- AceGUI: the cave window and the reset arrows, as AceGUI makes its widgets
-- ---------------------------------------------------------------------------------------------

-- A Button widget turns into HFWM's reset arrows just after AceGUI has made it: looked at on the
-- next frame, all of the frame's new buttons in one go.
local newButtons = {}
local buttonsQueued = false
local function NewButtons()
	buttonsQueued = false
	for w in pairs(newButtons) do
		newButtons[w] = nil
		Guard(ResetArrows, w)
	end
end

-- An AceGUI Frame's title followed (once per widget: AceGUI's pool hands the same ones out again).
local titled = setmetatable({}, { __mode = "k" })
local function Titled(w)
	if type(w) ~= "table" or w.type ~= "Frame" or titled[w] or Kind(w.titletext) ~= "FontString" then return end
	titled[w] = true
	hooksecurefunc(w.titletext, "SetFontObject", function() TitleFont(w) end)
end

local function Made(_, w)
	if type(w) ~= "table" then return end
	if w.type == "Button" then
		newButtons[w] = true
		if not buttonsQueued then
			buttonsQueued = true
			C_Timer.After(0, NewButtons)
		end
	else
		Titled(w)
	end
end

-- What AceGUI made before this was hooked: the Frames in its pool (handed out again by its Create,
-- which makes nothing new), and a cave window already up (its dress found by its parts, among the
-- frames it can be parented to: the map, the gamepad UI's host, the screen with Keep Open).
local function AceEarlier(AG)
	local pool = type(AG.objPools) == "table" and AG.objPools.Frame
	if type(pool) == "table" then
		for w in pairs(pool) do Titled(w) end
	end
	for _, host in ipairs({ _G.WorldMapFrame, _G.HFWMForeverMapHost, UIParent }) do
		if Usable(host) then
			for i = 1, select("#", host:GetChildren()) do
				local c = select(i, host:GetChildren())
				local w = Usable(c) and c.obj
				if type(w) == "table" and w.type == "Frame" and w.frame == c then
					local header, border = CaveParts(c)
					if header and border then
						Titled(w)
						ns.WithKit(function() Cave(w) end)
					end
				end
			end
		end
	end
end

-- AceGUI is shared and a newer copy may replace it when another addon loads (its functions made
-- again in the same table, under a higher minor version): hooked again then, and only then.
-- (Told by the version, not by the function: DaylightUI's Ace3 look post-hooks the same functions,
-- and seen as "changed" each wrapper would be hooked again on every addon load.) Its Release
-- too: a Frame made before this, handed back to the pool, is followed from there.
local aceMinor
local function HookAce()
	local AG, minor = nil, nil
	if type(LibStub) == "table" then AG, minor = LibStub("AceGUI-3.0", true) end
	if type(AG) ~= "table" or minor == aceMinor then return end
	local first = aceMinor == nil
	aceMinor = minor
	for _, m in ipairs({ "RegisterAsWidget", "RegisterAsContainer" }) do
		if type(AG[m]) == "function" then hooksecurefunc(AG, m, Made) end
	end
	if type(AG.Release) == "function" then
		hooksecurefunc(AG, "Release", function(_, w) Titled(w) end)
	end
	if first then Guard(AceEarlier, AG) end
end

-- ---------------------------------------------------------------------------------------------
-- The "Open cave map" button
-- ---------------------------------------------------------------------------------------------

local function Reopen(btn, Kit)
	if Kind(btn) ~= "Button" or not First(btn) then return end
	for i = 1, select("#", btn:GetRegions()) do
		local r = select(i, btn:GetRegions())
		if IsTexture(r) then
			local kind = FileKind(r)
			if kind == "ground" or kind == "glow" then ns.Kill(r) end
		end
	end
	for i = 1, select("#", btn:GetChildren()) do
		local c = select(i, btn:GetChildren())
		if Usable(c) and c.layoutType == "Dialog" then ns.Kill(c) end
	end
	if Controls() then Guard(Kit.ArtButton, btn, 3) end
end

function ReopenNow()
	local btn, Kit = _G.HFWMForeverCaveReopenButton, ns.Kit
	if Kit and On() and Usable(btn) then Reopen(btn, Kit) end
end

-- ---------------------------------------------------------------------------------------------
-- When
-- ---------------------------------------------------------------------------------------------

-- HFWM's settings: an AceDB profile (HighFidelityWorldMapDB), read and set through AceDB's object
-- for it, so its defaults are read as HFWM reads them.
local function Profile()
	local sv = _G.HighFidelityWorldMapDB
	if type(sv) ~= "table" or type(LibStub) ~= "table" then return nil end
	local AceDB = LibStub("AceDB-3.0", true)
	local list = type(AceDB) == "table" and AceDB.db_registry
	if type(list) ~= "table" then return nil end
	for db in pairs(list) do
		if type(db) == "table" and rawget(db, "sv") == sv then
			local p = db.profile
			return type(p) == "table" and p or nil
		end
	end
	return nil
end

-- The watches by name are the fallback for what's made where nothing can be reached: each stops
-- once its frame is there, or once it can't come (handed STOP, which the dressing passes over).
-- One stopped that may come after all (its HFWM switch turned on again) is started again from the
-- fast paths below.
local STOP = {}
local watching = {}
local pageWait            -- when the look for the settings pages began
local WANTS = {
	-- The HD / SD button: made at login, or when its switch (or HFWM) is turned on again. None
	-- while either is off.
	toggle = {
		get = function()
			local b = _G.HFWMForeverToggleButton
			if b then return b end
			local p = Profile()
			if p and (p.enabled == false or p.toggleButtonEnabled == false) then return STOP end
		end,
		fn = function(b) Toggle(b) end,
	},
	-- The "Open cave map" button: made the first time a cave map is closed or left closed (its X,
	-- the Alt-M key and HFWM's cave poller). None while the cave map (or HFWM) is off.
	reopen = {
		get = function()
			local b = _G.HFWMForeverCaveReopenButton
			if b then return b end
			local p = Profile()
			if p and (p.enabled == false or p.caveEnabled == false) then return STOP end
		end,
		fn = function(b, Kit) Reopen(b, Kit) end,
	},
	-- The settings pages: made at login. Given up 30 seconds after login (HFWM failed to make them).
	pages = {
		get = function()
			local f = Page("_Main")
			if f then return f end
			if ns.loggedIn then
				pageWait = pageWait or GetTime()
				if GetTime() - pageWait > 30 then return STOP end
			end
		end,
		fn = function(f, Kit) if f ~= STOP then Pages(Kit) end end,
	},
}

local function Want(name)
	if watching[name] then return end
	local w = WANTS[name]
	local now = w.get()
	if now == STOP then return end
	if now and ns.Kit then
		Guard(w.fn, now, ns.Kit)
		return
	end
	watching[name] = true
	ns.Watch(KEY, w.get, function(frame, Kit)
		watching[name] = nil
		if frame ~= STOP then w.fn(frame, Kit) end
	end)
end

-- After a change of HFWM's settings (its pages, /hfwm, a profile switch): what it just made is
-- dressed, and a watch stopped by a switch that's on again is started again.
local function Changed()
	if not On() then return end
	for name in pairs(WANTS) do Want(name) end
end

local function FastPaths()
	-- Its settings pages and AceDBOptions call AceConfigRegistry:NotifyChange after every change,
	-- once HFWM has acted on it (the HD / SD button made or not).
	local reg = type(LibStub) == "table" and LibStub("AceConfigRegistry-3.0", true)
	if type(reg) == "table" and type(reg.RegisterCallback) == "function" then
		local owner = {}
		reg.RegisterCallback(owner, "ConfigTableChange", function(_, app)
			if type(app) == "string" and string.find(app, KEY, 1, true) == 1 then Guard(Changed) end
		end)
	end
	-- /hfwm (AceConsole's slash commands: on, off, cave, a profile reset...).
	local slash = _G.SlashCmdList
	if type(slash) == "table" then
		for _, name in ipairs({ "ACECONSOLE_HFWM", "ACECONSOLE_HFWMFOREVER" }) do
			if type(slash[name]) == "function" then
				ns.HookOnce(slash, name, function() C_Timer.After(0, Changed) end, KEY)
			end
		end
	end
	-- Alt-M (HFWM's key button) closes a cave map like its X: the "Open cave map" button comes up.
	local key = _G.HFWMForeverCaveKeybind
	if Kind(key) == "Button" then key:HookScript("OnClick", function() Guard(ReopenNow) end) end
end

ns.Pack(KEY, "High Fidelity World Map", function()
	-- AceGUI (the cave window, the settings pages' reset arrows): hooked now, and again when a newer
	-- copy loads with another addon.
	HookAce()
	local loads = CreateFrame("Frame")
	loads:RegisterEvent("ADDON_LOADED")
	loads:SetScript("OnEvent", function() HookAce() end)
	-- (HFWM makes its key button and slash commands at login, as it makes the toggle and pages.)
	local function start()
		FastPaths()
		Changed()
	end
	if ns.loggedIn then
		C_Timer.After(0, start)
	else
		ns.me.On("Login", function() C_Timer.After(0, start) end)
	end
end, CAPS)

-- ---------------------------------------------------------------------------------------------
-- Hand-over
-- ---------------------------------------------------------------------------------------------

-- (From an audit of HFWM 1.4.11 against every DaylightUI module and OpenMap. Its HD map, the
-- area labels, cave map, coordinates switches, zoom memory, keep centered and its map background
-- have no DaylightUI copy.
-- "fogOff" is its zone maps' Fog of War switched off while their background is Hybrid (the only
-- background its Fog of War works on: Options greys the switch out on the others): then it draws
-- every unexplored area of the game's own map, as DaylightUI's map reveal does. Given to
-- DaylightUI, its Fog of War is put back on. Not handed over: on its other backgrounds, and on
-- any background while the HD / SD blend is between the two, it shows the unexplored ground as
-- part of its HD map itself (the HD tiles cover the whole zone, and the game's map under a blend
-- has to match them): that's its map, not a reveal of the game's. Its World and Continent Fog of
-- War work on zones of those maps, where DaylightUI's reveal (zone maps' explored pieces) draws
-- nothing: no overlap.)
local function ZoneHybrid(p)
	local bg = p.zoneMapBackground
	if bg == nil or bg == "global" then bg = p.mapBackground end
	return bg == "hybrid"
end

-- An open map is drawn again at once, through HFWM's own "/hfwm fog on|off" (the only way into its
-- renderer from outside: it sets the switch, redraws the map and its pages, and says so in the
-- chat). A closed map reads the switch as it next opens. Out of combat.
local function Redraw(fogOn)
	local map = _G.WorldMapFrame
	if not (Usable(map) and map:IsShown()) then return end
	ns.OutOfCombat(function()
		local AA = type(LibStub) == "table" and LibStub("AceAddon-3.0", true)
		local ok, addon = false, nil
		if type(AA) == "table" and type(AA.GetAddon) == "function" then ok, addon = pcall(AA.GetAddon, AA, KEY, true) end
		if ok and type(addon) == "table" and type(addon.OnChatCommand) == "function" then
			addon.OnChatCommand(addon, fogOn and "fog on" or "fog off")
		end
	end)
end

ns.Handover(KEY, {
	ready = function() return Profile() ~= nil end,
	get = function(key)
		local p = Profile()
		if not p then return nil end
		if key == "fogOff" then return p.fogOfWarEnabled == false and ZoneHybrid(p) end
	end,
	set = function(key, value)
		local p = Profile()
		if p and key == "fogOff" then
			p.fogOfWarEnabled = not value
			Redraw(not value)
		end
	end,
	list = {
		{ key = "fogOff", label = L["Zone Maps Without Fog of War"], daylight = ns.In(L["map reveal"], "Window Skins"),
		  ours = function() return ns.DaylightHas("Skins", "mapReveal") end },
	},
})
