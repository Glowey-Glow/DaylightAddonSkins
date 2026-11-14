-- The game's own Options window and its dungeon-ready dialog, the two windows DaylightUI's Skins
-- module leaves as the game draws them on purpose. Each has its own switch ("Game settings window",
-- "Dungeon ready dialog" on the All windows page), so one can be turned off alone.
--   * The Options window (SettingsPanel; Esc > Options): DaylightUI's window shell in place of its
--     metal frame, the title on the left of the title row in the value ink with the accent line
--     above it, the close X, the Close / Apply / Defaults buttons, the search box, the Game / AddOns
--     tabs and the Graphics page's Base / Raid and Battleground tabs (words only, tan at rest, the
--     picked one in the accent with a line under it), both scroll bars, the category list (plain
--     lines, a faint wash under the mouse, the open category in a flat accent wash, its headings
--     in the accent, the +/- of a category with sub-categories as a plain "+" or "-" in the text
--     ink) and the settings list: labels in the text ink and your font (the game's size), section
--     and fold-out headings in the accent, checkboxes as a dark box filled with the accent when on,
--     sliders as a thin track with the accent fill and a round knob, dropdowns in DaylightUI's box
--     with the value in the value ink, every arrow (a slider's, a dropdown's) as a chevron in the
--     text ink (dim while it can't be used), buttons, the Graphics page's group box as a quiet well,
--     and the key binding rows (the label in the text ink, both binding buttons as DaylightUI's
--     flat buttons at the game's size, "Not Bound" in the dim ink, the one waiting for a key lit in
--     the accent).
--   * The pages addons draw themselves inside it (their canvas): the game's own controls on them,
--     once the addon (or another of this plugin's packs) has had its turn: the game's text buttons
--     (red ones too) as DaylightUI's buttons, its checkboxes, dropdowns and text boxes, the game's
--     gold words in DaylightUI's inks (big ones, the page titles, bright). Anything already dressed
--     by DaylightUI or another pack, AceGUI pages (DaylightUI's Ace3 look has those) and sliders
--     are left to them.
--   * The Ping System window (PingSystemTutorial, from the Ping System page): the window shell,
--     the title and the close X. Its pictures and words stay.
--   * The dungeon-ready dialog (LFGDungeonReadyDialog in LFGDungeonReadyPopup) and the "waiting
--     for players" box after it (LFGDungeonReadyStatus): DaylightUI's window shell, Enter Dungeon
--     and Leave Queue as DaylightUI's buttons, the hide button as a chevron, the words in
--     DaylightUI's inks. Dressed at login, so a dialog that pops up in a fight is dressed already.
-- Kept as they are: the dungeon's picture, the role icon, the reward icons, the players' ready
-- marks, the NEW badges, the language pictures in the language dropdowns, colored warnings,
-- grayed-out settings (in DaylightUI's dim ink). Left alone: the menus the dropdowns open and the
-- tooltips (DaylightUI's), and the confirmation popups (the game's StaticPopup, which DaylightUI
-- dresses).
--
-- The game reuses its rows (every page, every scroll) and sets their fonts, colors and art again
-- each time it fills one, so nothing here is done once per row: every pass looks at each shown row
-- and puts back whatever the game changed (cheap when nothing did: a look is made once per control,
-- and each color or font is only set when it isn't that already).
--
-- Never silent: the window is dressed whichever comes first (the window made, DaylightUI's Kit handed
-- over, the window opened), each part on its own so one failing part can't stop the others or the
-- passes, and a one-line chat notice says so (once) if the window opens undressed, its passes don't
-- run, or a part fails.
--
-- Taint. These windows run protected code: building the settings list calls protected functions
-- (IsUserOAuthed, in the Social page), the key binding page sets bindings, and Enter Dungeon
-- accepts the group. Any addon code that runs inside that work makes it fail with a blocked-action
-- error naming the addon. So, with DaylightUI's "quiet" rule for its confirm boxes as the model:
--   * Nothing here runs while the game shows, hides, enables, resizes or fills a piece inside these
--     windows. No OnShow / OnHide / OnEnable / OnDisable / OnSizeChanged hook on anything inside
--     them, no callback on their lists (Kit.EachRow's OnInitializedFrame / OnUpdate), no hook on
--     the game's functions. The only hooks inside are the mouse entering and leaving a control (and
--     the wheel over a list), which the game never sets off from its own code.
--   * The window's own OnShow and OnHide (the outermost frame the game shows, so these run last,
--     after all of the game's) only start and stop a light timer. Rows are dressed from that timer
--     (a fresh call of its own, out of combat, every 0.1 s while the window is open, and on the
--     next frame after a scroll with the wheel), long after the game has built them.
--   * Looks only: textures and words. The game's own tables are only read (which rows a list shows,
--     which category is open); nothing of the game's is replaced or written to, and what this pack
--     keeps is in its own tables.
--   * Controls with no quiet form in the Kit (checkboxes, sliders, tabs, key binding buttons) get a
--     look of this pack's own, drawn with textures that follow the game's state by themselves (a
--     checkbox's checked art, the hover layer) or are read by the timer.
local _, ns = ...
if not ns.ok then return end

local SETTINGS, READY = "BlizzardSettings", "BlizzardDungeonReady"
local API = ns.API

local Kit
local select, type, pairs, ipairs, pcall = select, type, pairs, ipairs, pcall
local abs, floor, max = math.abs, math.floor, math.max
local KNOB_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local TICK = 0.1           -- seconds between passes over the open Options window
local TITLE_SIZE = 18      -- a window title, as DaylightUI's are
local DEPTH = 10           -- how far into a settings row the pass looks (Graphics nests 5 deep)
local CANVAS_DEPTH = 40    -- how far into an addon's page (scroll frames nest them deep); only a
                           -- guard: a frame's children never lead back up to it
local HEADING_SIZE = 15    -- words this big or bigger, on a row or a page of its own, are headings

ns.Target(SETTINGS, "Game settings window", { controls = true })
-- (The game's dungeon finder is built in with the game's own windows: there at load or not at all.)
local hasReady = _G.LFGDungeonReadyPopup ~= nil or _G.LFGDungeonReadyDialog ~= nil
if hasReady then ns.Target(READY, "Dungeon ready dialog", { controls = true }) end

local function weak() return setmetatable({}, { __mode = "k" }) end

local panel                -- SettingsPanel, once dressed
local controls = true      -- whether the Options window's controls are dressed (its page's switch)

local Usable = ns.Usable

local function Is(obj, kind)
	return Usable(obj) and obj:GetObjectType() == kind
end

local function Hide(region)
	if Usable(region) and region.SetAlpha and region:GetAlpha() ~= 0 then region:SetAlpha(0) end
end

local function Secret(v)
	return issecretvalue and issecretvalue(v) or false
end

local function Num(v)
	return type(v) == "number" and not Secret(v)
end

-- Every texture of a frame's own hidden (not its children's), except those in keep.
local function StripRegions(keep, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if Is(r, "Texture") and not (keep and keep[r]) and r:GetAlpha() ~= 0 then r:SetAlpha(0) end
	end
end
local function Strip(frame, keep)
	if Usable(frame) and frame.GetRegions then StripRegions(keep, frame:GetRegions()) end
end

-- A button's own art (normal, pushed, hover, disabled).
local function ButtonArt(btn)
	if btn.GetNormalTexture then Hide(btn:GetNormalTexture()) end
	if btn.GetPushedTexture then Hide(btn:GetPushedTexture()) end
	if btn.GetHighlightTexture then Hide(btn:GetHighlightTexture()) end
	if btn.GetDisabledTexture then Hide(btn:GetDisabledTexture()) end
end

-- The game's text button (three pieces: Left, Middle or Center, Right).
local function TextButton(btn)
	if not Is(btn, "Button") then return false end
	return Is(btn.Left, "Texture") and Is(btn.Right, "Texture") and (Is(btn.Middle, "Texture") or Is(btn.Center, "Texture"))
end

-- The game's tab (MinimalTabTemplate: it carries the names of its atlases).
local function IsTab(btn)
	return Is(btn, "Button") and (btn.selectedMiddleTexture ~= nil or btn.upMiddleTexture ~= nil)
end

-- A close X: a small square button with no words.
local function CloseX(btn)
	if not Is(btn, "Button") or TextButton(btn) then return false end
	local text = btn.GetText and btn:GetText()
	if type(text) == "string" and text ~= "" then return false end
	local w, h = btn:GetSize()
	return Num(w) and w > 0 and w <= 40 and abs(w - h) < 4
end

-- A pass's errors: each different one is shown once (BugSack, at most a few), and the rest of the
-- pass goes on: one control that fails never leaves the others undressed.
-- A notice in chat, once per kind, when something goes wrong that would otherwise leave the Options
-- window undressed without a word.
local told = {}
local function Notice(kind, msg)
	if told[kind] then return end
	told[kind] = true
	pcall(print, "|cffa335eeAddon Skins|r: " .. msg)
end

local reported, nReported = {}, 0
local function Report(err)
	err = tostring(err)
	if reported[err] or nReported >= 5 then return end
	reported[err] = true
	nReported = nReported + 1
	Notice("error", "the game's Options window skin hit an error (details in your error display); the rest of the window is still dressed.")
	geterrorhandler()(err)
end
local function Try1(fn, a, b, c, d)
	local ok, err = pcall(fn, a, b, c, d)
	if not ok then Report(err) end
end

-- ---------------------------------------------------------------------------------------------
-- Inks and fonts
-- ---------------------------------------------------------------------------------------------

local GOLD, GRAY, WHITE_INK = { 1, 0.82, 0 }, { 0.5, 0.5, 0.5 }, { 1, 1, 1 }
local function Near(r, g, b, c)
	return abs(r - c[1]) <= 0.03 and abs(g - c[2]) <= 0.03 and abs(b - c[3]) <= 0.03
end

-- Sets a color only when it isn't that already (a pass runs ten times a second while open).
local function SetInk(fs, r, g, b)
	local cr, cg, cb = fs:GetTextColor()
	if not Num(cr) then return end
	if abs(cr - r) > 0.01 or abs(cg - g) > 0.01 or abs(cb - b) > 0.01 then fs:SetTextColor(r, g, b) end
end
local function SetInkOf(fs, c)
	if c then SetInk(fs, c[1], c[2], c[3]) end
end

-- (Read once per pass: a pass asks for it on every picked tab, heading and checkbox. Outside a
-- pass, read fresh.)
local passAccent, passR, passG, passB = false
local function Accent()
	if passAccent then return passR, passG, passB end
	return ns.AccentOf(SETTINGS)
end

-- The game's gold words in the label ink (big ones, headings, bright) and its gray in the dim ink;
-- every other color (white, red warnings, green) has a meaning and stays.
local function InkGame(fs, bigBright)
	local r, g, b = fs:GetTextColor()
	if not Num(r) then return end
	local c = ns.Colors()
	if Near(r, g, b, GOLD) then
		if bigBright then
			local _, size = fs:GetFont()
			if Num(size) and size >= HEADING_SIZE then SetInkOf(fs, c.VALUE) return end
		end
		SetInkOf(fs, c.LABEL)
	elseif Near(r, g, b, GRAY) then
		SetInkOf(fs, c.OFF)
	end
end

-- A label: the text ink (gold and white alike), grayed ones dim.
local function InkLabel(fs)
	local r, g, b = fs:GetTextColor()
	if not Num(r) then return end
	local c = ns.Colors()
	if Near(r, g, b, GRAY) then SetInkOf(fs, c.OFF)
	elseif Near(r, g, b, GOLD) or Near(r, g, b, WHITE_INK) then SetInkOf(fs, c.TEXT) end
end

-- The player's font on a string at the game's size, unless the words would no longer fit (the
-- game cuts a long label short with "..."): then the game's font stays for those words. The game
-- sets its font object again as it fills a row, picks a tab or hovers a category: whenever the
-- string's font or words are no longer what this pack left, it's done again from the game's new
-- font (its size included).
local basePath, baseSize, baseFlags = weak(), weak(), weak()   -- string -> the game's font
local leftPath = weak()    -- string -> the font this pack left on it
local leftText = weak()    -- string -> the words it was fitted for
local playerFont
local function PlayerFont()
	if playerFont == nil then
		local ok, face = pcall(API.Font)
		playerFont = ok and type(face) == "string" and face or false
	end
	return playerFont or nil
end

local function FitFont(fs)
	if not Is(fs, "FontString") then return end
	local text = fs:GetText() or ""
	if Secret(text) then return end
	local face = PlayerFont()
	if not face then return end
	local path, size, flags = fs:GetFont()
	if not path or not Num(size) or size <= 0 then return end
	if leftText[fs] == text and leftPath[fs] == path then return end
	if path ~= leftPath[fs] then
		-- The game's own font (first time, or the game set it again).
		basePath[fs], baseSize[fs], baseFlags[fs] = path, size, flags or ""
	end
	local size0, flags0 = baseSize[fs], baseFlags[fs]
	leftText[fs] = text
	fs:SetFont(face, size0, flags0)
	if fs.IsTruncated and fs:IsTruncated() then fs:SetFont(basePath[fs], size0, flags0) end
	leftPath[fs] = fs:GetFont()
end

-- ---------------------------------------------------------------------------------------------
-- The accent on this pack's own pieces (lines, fills, highlights)
-- ---------------------------------------------------------------------------------------------

local accentLines = weak()   -- texture -> alpha
local function PaintAccentLine(tex, alpha)
	local r, g, b = Accent()
	tex:SetColorTexture(r, g, b, alpha or 1)
end
local function AccentLine(tex, alpha)
	accentLines[tex] = alpha or 1
	PaintAccentLine(tex, alpha)
end

-- The thin accent line along a window's top, as DaylightUI's windows have.
local function TopLine(frame)
	local line = frame:CreateTexture(nil, "ARTWORK", nil, 7)
	line:SetHeight(2)
	line:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -2)
	line:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -2)
	AccentLine(line, 0.7)
end

-- A window's title: the player's font at a title's size, the value ink, on the left of the title
-- row as DaylightUI's windows have it.
local function Title(frame, fs)
	if not Is(fs, "FontString") then return end
	local _, size = fs:GetFont()
	if not Num(size) or size <= 0 then return end   -- (not set up by the game yet)
	Kit.Font(fs, TITLE_SIZE)
	SetInkOf(fs, ns.Colors().VALUE)
	Kit.Title(frame, fs)
end

-- ---------------------------------------------------------------------------------------------
-- Checkboxes: a dark box, filled with the accent while checked. The fill is the game's own checked
-- art recolored, so the game shows and hides it itself; the box's outline is dimmed while the
-- checkbox is grayed out (read by the pass).
-- ---------------------------------------------------------------------------------------------

local CHECK_BOX, CHECK_FILL_INSET = 18, 4
local checks = weak()      -- checkbox -> { shell, host, r, g, b }

local function FillCheck(cb, c)
	local r, g, b = Accent()
	local on, off = cb:GetCheckedTexture(), cb.GetDisabledCheckedTexture and cb:GetDisabledCheckedTexture()
	if Is(on, "Texture") then on:SetColorTexture(r, g, b, 1) end
	if Is(off, "Texture") then
		local d = ns.Colors().OFF or GRAY
		off:SetColorTexture(d[1], d[2], d[3], 0.6)
	end
	c.r, c.g, c.b = r, g, b
end

local function PlaceFill(cb, host)
	for i = 1, 2 do
		local t = i == 1 and cb:GetCheckedTexture() or (cb.GetDisabledCheckedTexture and cb:GetDisabledCheckedTexture())
		if Is(t, "Texture") then
			t:ClearAllPoints()
			t:SetPoint("TOPLEFT", host, "TOPLEFT", CHECK_FILL_INSET, -CHECK_FILL_INSET)
			t:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -CHECK_FILL_INSET, CHECK_FILL_INSET)
		end
	end
end

local function CheckLook(cb)
	if checks[cb] or not Is(cb, "CheckButton") then return checks[cb] end
	local w = cb:GetWidth()
	if not Num(w) or w <= 0 then w = CHECK_BOX end
	local inset = max(0, floor((w - CHECK_BOX) / 2 + 0.5))
	local shell = Kit.Outline(cb, -inset, "control")
	local host = shell and shell.host
	if not Usable(host) then return end
	local c = { shell = shell, host = host }
	checks[cb] = c
	PlaceFill(cb, host)
	FillCheck(cb, c)
	-- Under the mouse: a faint wash (the hover layer, shown by the game itself).
	local wash = cb:CreateTexture(nil, "HIGHLIGHT")
	wash:SetColorTexture(1, 1, 1, 0.08)
	wash:SetPoint("TOPLEFT", host, "TOPLEFT", 2, -2)
	wash:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -2, 2)
	return c
end

-- Each pass: the game's box and hover art off again, the outline dimmed while grayed, the fill
-- recolored if the accent changed or the game put its own tick back.
local function Check(cb)
	if not controls then return end
	local c = CheckLook(cb)
	if not c then return end
	if cb.GetNormalTexture then Hide(cb:GetNormalTexture()) end
	if cb.GetPushedTexture then Hide(cb:GetPushedTexture()) end
	if cb.GetHighlightTexture then Hide(cb:GetHighlightTexture()) end
	if cb.GetDisabledTexture then Hide(cb:GetDisabledTexture()) end
	Hide(cb.HoverBackground)
	Kit.Paint(c.shell, (cb.IsEnabled and not cb:IsEnabled()) and Kit.DISABLED_BORDER or nil)
	local r, g, b = Accent()
	local on = cb:GetCheckedTexture()
	if r ~= c.r or g ~= c.g or b ~= c.b or (Is(on, "Texture") and on:GetAtlas()) then
		PlaceFill(cb, c.host)
		FillCheck(cb, c)
	end
	-- A checkbox's own words (the game's UICheckButtonTemplate on an addon's page).
	local label = cb.Text or cb.text
	if Is(label, "FontString") then
		FitFont(label)
		InkLabel(label)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Sliders (MinimalSliderTemplate): a thin track, the accent fill up to a round knob. The fill hangs
-- off the game's thumb, so it follows the value by itself; grayed out is read by the pass.
-- ---------------------------------------------------------------------------------------------

local sliders = weak()     -- slider -> { fill, knob, r, g, b, off }

local function SliderLook(slider)
	if sliders[slider] then return sliders[slider] end
	local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
	if not Is(thumb, "Texture") then return end
	local track = slider:CreateTexture(nil, "ARTWORK")
	track:SetColorTexture(1, 1, 1, 0.14)
	track:SetPoint("LEFT", slider, "LEFT", 0, 0)
	track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
	track:SetHeight(4)
	local fill = slider:CreateTexture(nil, "ARTWORK", nil, 1)
	fill:SetPoint("LEFT", track, "LEFT", 0, 0)
	fill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)
	fill:SetHeight(4)
	local knob = slider:CreateTexture(nil, "OVERLAY")
	knob:SetColorTexture(1, 1, 1, 1)
	knob:SetSize(12, 12)
	knob:SetPoint("CENTER", thumb, "CENTER", 0, 0)
	local mask = slider:CreateMaskTexture()
	mask:SetTexture(KNOB_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(knob)
	knob:AddMaskTexture(mask)
	local s = { fill = fill, knob = knob, track = track, thumb = thumb }
	sliders[slider] = s
	return s
end

local function Slider(slider)
	if not controls then return end
	local s = SliderLook(slider)
	if not s then return end
	-- The game's track (Left, Middle, Right) and its diamond thumb out of sight, each pass.
	Hide(slider.Left)
	Hide(slider.Middle)
	Hide(slider.Right)
	Hide(s.thumb)
	local r, g, b = Accent()
	if r ~= s.r or g ~= s.g or b ~= s.b then
		s.r, s.g, s.b = r, g, b
		s.fill:SetColorTexture(r, g, b, 1)
	end
	local off = slider.IsEnabled and not slider:IsEnabled() or false
	if off ~= s.off then
		s.off = off
		s.knob:SetAlpha(off and 0.4 or 1)
		s.fill:SetAlpha(off and 0.4 or 1)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Arrows (a slider's Back / Forward, a dropdown's Decrement / Increment): DaylightUI's chevron in
-- the text ink, the value ink under the mouse, dim while it can't be used. The game sets its own
-- arrow art again as the arrow is grayed and lit: put out of sight again each pass.
-- ---------------------------------------------------------------------------------------------

local STEPPERS = { Back = "left", Forward = "right", DecrementButton = "left", IncrementButton = "right" }
local steppers = weak()    -- arrow -> { chevron, hover }

local function PaintStepper(btn)
	local s = steppers[btn]
	if not s or not s.chevron then return end
	local c = ns.Colors()
	local ink
	if btn.IsEnabled and not btn:IsEnabled() then ink = c.OFF
	elseif s.hover then ink = c.VALUE
	else ink = c.TEXT end
	if ink then s.chevron:SetVertexColor(ink[1], ink[2], ink[3], (btn.IsEnabled and not btn:IsEnabled()) and 0.5 or 1) end
end

local function Stepper(btn, dir)
	if not controls then return end
	local s = steppers[btn]
	if not s then
		s = {}
		steppers[btn] = s
		s.chevron = Kit.BareButton(btn, dir)
		-- (After the Kit's own: these run last and set the color this pack wants.)
		btn:HookScript("OnEnter", function(self) s.hover = true; PaintStepper(self) end)
		btn:HookScript("OnLeave", function(self) s.hover = false; PaintStepper(self) end)
	end
	-- (Its unnamed arrow art was put out of sight by the Kit once; the named pieces the game sets
	-- again as it's grayed and lit go each pass.)
	ButtonArt(btn)
	Hide(btn.Icon)
	Hide(btn.Background)
	PaintStepper(btn)
end

-- ---------------------------------------------------------------------------------------------
-- Dropdowns (WowStyle2DropdownTemplate and its kin): the Kit's dropdown look (DaylightUI's box and
-- chevron), the value in the value ink (dim while grayed). A language dropdown shows its value as a
-- picture of the language's name (its Language texture): that picture is kept.
-- ---------------------------------------------------------------------------------------------

local function Dropdown(dd)
	if not controls then return end
	local label = dd.Text or (dd.GetFontString and dd:GetFontString())
	if not Is(label, "FontString") then return end
	local w = dd:GetWidth()
	-- (An arrow-only one stays the game's: the Kit's arrow-only look hooks its showing and graying.)
	if Num(w) and w > 0 and w <= 36 then return end
	Kit.Dropdown(dd)
	Hide(dd.Background)
	Hide(dd.Arrow)
	if dd.GetNormalTexture then ButtonArt(dd) end
	local lang = dd.Language
	if Is(lang, "Texture") and lang:GetAlpha() ~= 1 then lang:SetAlpha(1) end
	FitFont(label)
	local c = ns.Colors()
	SetInkOf(label, (dd.IsEnabled and not dd:IsEnabled()) and c.OFF or c.VALUE)
end

-- ---------------------------------------------------------------------------------------------
-- Tabs (MinimalTabTemplate: Game / AddOns, Graphics' Base / Raid and Battleground): words only, tan
-- at rest, light under the mouse, the picked one in the accent with a line under it. Picked is the
-- game's own flag (SelectableButtonMixin's `selected`), read each pass.
-- ---------------------------------------------------------------------------------------------

local TAB_ART = { "Left", "Middle", "Right", "LeftActive", "MiddleActive", "RightActive",
	"LeftHighlight", "MiddleHighlight", "RightHighlight", "LeftDisabled", "MiddleDisabled", "RightDisabled" }
local tabs = weak()        -- tab -> { label, line, hover }

local PICKED_ART = { "LeftActive", "MiddleActive", "SelectedTexture", "selectedTexture" }
local function TabPicked(tab)
	if type(tab.selected) == "boolean" then return tab.selected end
	if type(tab.isSelected) == "boolean" then return tab.isSelected end
	for _, key in ipairs(PICKED_ART) do
		local art = tab[key]
		if Is(art, "Texture") then return art:IsShown() == true end
	end
	return false
end

local function PaintTab(tab)
	local t = tabs[tab]
	if not t then return end
	-- The game's tab art (set again on every hover and pick) out of sight.
	for _, key in ipairs(TAB_ART) do Hide(tab[key]) end
	ButtonArt(tab)
	FitFont(t.label)
	local c = ns.Colors()
	if TabPicked(tab) then
		local r, g, b = Accent()
		SetInk(t.label, r, g, b)
		t.line:SetColorTexture(r, g, b, 1)
		t.line:Show()
	else
		SetInkOf(t.label, t.hover and c.VALUE or c.LABEL)
		t.line:Hide()
	end
end

local function TabLook(tab)
	if tabs[tab] or not Usable(tab) then return end
	local label = tab.Text or (tab.GetFontString and tab:GetFontString())
	if not Is(label, "FontString") then return end
	local line = tab:CreateTexture(nil, "OVERLAY")
	line:SetHeight(2)
	line:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
	line:SetPoint("TOPRIGHT", label, "BOTTOMRIGHT", 0, -3)
	line:Hide()
	local t = { label = label, line = line }
	tabs[tab] = t
	tab:HookScript("OnEnter", function(self) t.hover = true; PaintTab(self) end)
	tab:HookScript("OnLeave", function(self) t.hover = false; PaintTab(self) end)
	PaintTab(tab)
end

-- ---------------------------------------------------------------------------------------------
-- The Options window
-- ---------------------------------------------------------------------------------------------


-- A small piece of art (an arrow or a +/-), as opposed to a row's long background.
local function SmallTexture(r)
	local w, h = r:GetSize()
	return Num(w) and w > 0 and w <= 24 and Num(h) and h <= 24
end

-- A plain "+" or "-" in the text ink, in place of the game's gold +/- art.
local glyphs = weak()      -- frame -> its glyph
local MINUS = "-"          -- (plain: the font has no true minus sign)
local function Glyph(frame, open)
	local g = glyphs[frame]
	if not g then
		g = frame:CreateFontString(nil, "OVERLAY")
		g:SetFontObject(GameFontHighlight)
		g:SetPoint("CENTER", frame, "CENTER", 0, 0)
		glyphs[frame] = g
	end
	local want = open and MINUS or "+"
	if g:GetText() ~= want then g:SetText(want) end
	SetInkOf(g, ns.Colors().TEXT)
	return g
end

-- A fold-out heading (SettingsExpandableSectionTemplate's Button: Left / Right / middle art, its
-- open state drawn into the Right piece's atlas): the art off, a faint wash under the mouse, a
-- "+" / "-" at its right end, its words in the accent.
local folds = weak()       -- heading -> the textures of ours on it (kept by the strip)
local function Fold(btn)
	if not folds[btn] then
		local wash = btn:CreateTexture(nil, "HIGHLIGHT")
		wash:SetColorTexture(1, 1, 1, 0.06)
		wash:SetAllPoints(btn)
		folds[btn] = { [wash] = true }
		glyphs[btn] = btn:CreateFontString(nil, "OVERLAY")
		glyphs[btn]:SetFontObject(GameFontHighlight)
		glyphs[btn]:SetPoint("RIGHT", btn, "RIGHT", -12, 0)
	end
	local right = btn.Right
	local open = false
	if Is(right, "Texture") then
		local atlas = right:GetAtlas()
		open = type(atlas) == "string" and not Secret(atlas) and string.find(atlas, "Expanded", 1, true) ~= nil
	end
	Strip(btn, folds[btn])
	ButtonArt(btn)
	local g = glyphs[btn]
	local want = open and MINUS or "+"
	if g:GetText() ~= want then g:SetText(want) end
	SetInkOf(g, ns.Colors().TEXT)
	local text = btn.Text or (btn.GetFontString and btn:GetFontString())
	if Is(text, "FontString") then
		FitFont(text)
		SetInk(text, Accent())
	end
end

-- A key binding button (KeyBindingFrameBindingButtonTemplate, the game's silver stretch button):
-- the game's art off, a flat dark box with a faint wash under the mouse, the words at the game's
-- size in your font, "Not Bound" in the dim ink, and its "waiting for a key" highlight in the
-- accent. (Not the Kit's button: that one sets a bigger font, and the rows beside it keep the
-- game's.)
local STRETCH = { "TopLeft", "TopRight", "BottomLeft", "BottomRight", "TopMiddle", "MiddleLeft",
	"MiddleRight", "BottomMiddle", "MiddleMiddle", "Left", "Right", "Middle" }
local binds = weak()       -- button -> its shell
local notBoundAs, notBoundOff    -- "Not Bound" in the dim ink, and the ink it was made with

local function NotBound()
	local off = ns.Colors().OFF
	if notBoundOff ~= off and off then
		notBoundOff = off
		notBoundAs = string.format("|cff%02x%02x%02x%s|r", floor(off[1] * 255 + 0.5), floor(off[2] * 255 + 0.5),
			floor(off[3] * 255 + 0.5), _G.NOT_BOUND or "Not Bound")
	end
	return notBoundAs
end

local function Bind(btn)
	if not controls then return end
	local glow = btn.SelectedHighlight
	if not binds[btn] then
		binds[btn] = Kit.Shell(btn, "control") or true
		local wash = btn:CreateTexture(nil, "HIGHLIGHT")
		wash:SetColorTexture(1, 1, 1, 0.06)
		wash:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
		wash:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
		if Is(glow, "Texture") then
			glow:ClearAllPoints()
			glow:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
			glow:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
			glow:SetBlendMode("BLEND")
			AccentLine(glow, 0.3)
		end
	end
	for _, key in ipairs(STRETCH) do Hide(btn[key]) end
	ButtonArt(btn)
	local text = btn.Text or (btn.GetFontString and btn:GetFontString())
	if Is(text, "FontString") then
		local words = text:GetText()
		local nb = _G.NOT_BOUND
		if type(words) == "string" and not Secret(words) and nb and words ~= nb and string.find(words, nb, 1, true) then
			local want = NotBound()
			if want and words ~= want then btn:SetText(want) end
		end
		FitFont(text)
	end
end

-- What one piece of a settings row (or of an addon's page) is, looked at on every pass.
-- canvas: the piece is on an addon's own page (only what nothing else has dressed is touched).
local Piece

-- (The regions and children are gone through as the game hands them back, asked for once per
-- frame: no table made, and not asked for again for each one.)
local function StringsOf(frame, canvas, labelKeysAsLabels, depth, value, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if Is(r, "FontString") and r:IsShown() then
			if not canvas and labelKeysAsLabels and (r == frame.Text or r == frame.Label) then
				FitFont(r)
				InkLabel(r)
			elseif not canvas and value then
				FitFont(r)
				SetInkOf(r, ns.Colors().VALUE)
			elseif not canvas and depth <= 1 and r == frame.Title then
				FitFont(r)
				SetInk(r, Accent())
			else
				if not canvas then FitFont(r) end
				InkGame(r, canvas or depth <= 1)
			end
		end
	end
end

local function Strings(frame, canvas, labelKeysAsLabels, depth)
	local value = Is(frame.Slider, "Slider")   -- a slider's value words
	StringsOf(frame, canvas, labelKeysAsLabels, depth, value, frame:GetRegions())
end

local function Kids(frame, nine, canvas, depth, ...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		if Usable(c) and c:IsShown() and c ~= nine then Piece(c, frame, canvas, depth + 1) end
	end
end

local function Container(frame, canvas, depth)
	-- A group box (the Graphics page's NineSlice): a quiet well.
	local nine = frame.NineSlice
	if not canvas and Usable(nine) then Kit.Inset(nine) end
	Kids(frame, nine, canvas, depth, frame:GetChildren())
	Strings(frame, canvas, true, depth)
end

function Piece(f, parent, canvas, depth)
	if depth > (canvas and CANVAS_DEPTH or DEPTH) then return end
	-- AceGUI's widgets (frame.obj) are DaylightUI's Ace3 look's; a page the Kit is still walking is
	-- left to it for now.
	if canvas and (type(f.obj) == "table" or Kit.Walking(f)) then return end
	local kind = f:GetObjectType()
	if kind == "CheckButton" then
		if not (canvas and Kit.SwitchOf(f)) then Try1(Check, f) end
	elseif kind == "Slider" then
		if not canvas then Try1(Slider, f) end
	elseif kind == "DropdownButton" then
		Try1(Dropdown, f)
	elseif kind == "EditBox" then
		if controls and not Kit.InputOf(f) and (not canvas or TextButton(f) or f.searchIcon) then Try1(Kit.EditBox, f, panel) end
	elseif kind == "Button" then
		local dir
		for key, d in pairs(STEPPERS) do
			if parent[key] == f then dir = d end
		end
		if dir then
			if not canvas then Try1(Stepper, f, dir) end
		elseif IsTab(f) then
			if controls and not canvas then Try1(TabLook, f) Try1(PaintTab, f) end
		elseif not canvas and (parent.Button1 == f or parent.Button2 == f or Is(f.SelectedHighlight, "Texture")) then
			Try1(Bind, f)
		elseif TextButton(f) then
			if controls and not Kit.ButtonOf(f) then Try1(Kit.Button, f, panel) end
		elseif not canvas and Is(f.Left, "Texture") and Is(f.Right, "Texture") and Is(f.Text, "FontString") then
			Try1(Fold, f)
		end
	elseif kind == "Frame" or kind == "EventFrame" or kind == "ScrollFrame" then
		Container(f, canvas, depth)
	end
end

-- A settings row, every pass.
local function Row(row)
	Container(row, false, 0)
end

-- The category list. The open category is the list's own (SettingsCategoryListMixin keeps it in
-- currentCategory); a row's category is in the list's data for it (GetElementData, the game's
-- accessor on its rows). Both only read.
local function RowCategory(row)
	local get = row.GetElementData
	if type(get) ~= "function" then return nil end
	local ok, data = pcall(get, row)
	if not ok or type(data) ~= "table" or type(data.data) ~= "table" then return nil end
	return data.data.category
end

local function IsOpen(category)
	if type(category) ~= "table" or type(category.IsExpanded) ~= "function" then return false end
	local ok, open = pcall(category.IsExpanded, category)
	return ok and open == true
end

local catLooks = weak()    -- category row -> { fill }

local function PaintCategory(row)
	local look = catLooks[row]
	if not look then return end
	local cats = panel and panel.CategoryList
	local category = RowCategory(row)
	local picked = category ~= nil and Usable(cats) and cats.currentCategory == category
	-- The game's selection and hover art (set again on every hover and pick) out of sight.
	Hide(row.Texture)
	ButtonArt(row)
	if picked then
		local r, g, b = Accent()
		if look.r ~= r or look.g ~= g or look.b ~= b then
			look.r, look.g, look.b = r, g, b
			look.fill:SetColorTexture(r, g, b, 0.18)
		end
		if not look.fill:IsShown() then look.fill:Show() end
	elseif look.fill:IsShown() then
		look.fill:Hide()
	end
	local label = row.Label
	if Is(label, "FontString") then
		FitFont(label)
		local c = ns.Colors()
		if row.IsEnabled and not row:IsEnabled() then SetInkOf(label, c.OFF)
		elseif picked then SetInkOf(label, c.VALUE)
		else SetInkOf(label, c.TEXT) end
	end
	-- The +/- of a category with sub-categories (its art, "common-button-dropdown-closed" / "-open",
	-- set again on every fill, on shown and hidden toggles alike): a plain "+" or "-".
	local toggle = row.Toggle
	if Usable(toggle) and controls then
		ButtonArt(toggle)
		Strip(toggle)
		if toggle:IsShown() then Glyph(toggle, IsOpen(category)) end
	end
end

local function CategoryRow(row)
	if row:GetObjectType() == "Button" then
		if not catLooks[row] then
			local fill = row:CreateTexture(nil, "BACKGROUND", nil, 1)
			fill:SetAllPoints(row)
			fill:Hide()
			local wash = row:CreateTexture(nil, "HIGHLIGHT")
			wash:SetColorTexture(1, 1, 1, 0.06)
			wash:SetAllPoints(row)
			catLooks[row] = { fill = fill }
			-- The game sets the words' font object again as the mouse comes and goes: put back at once.
			row:HookScript("OnEnter", PaintCategory)
			row:HookScript("OnLeave", PaintCategory)
		end
		PaintCategory(row)
	else
		-- A heading ("Gameplay", "Accessibility", "System"): its banner off, its words in the accent.
		Hide(row.Background)
		local label = row.Label
		if Is(label, "FontString") then
			FitFont(label)
			SetInk(label, Accent())
		end
	end
end

local function EachShownOf(fn, ...)
	for i = 1, select("#", ...) do
		local row = select(i, ...)
		if Usable(row) and row:IsShown() then Try1(fn, row) end
	end
end

-- The rows a list shows: its view's own list of them (read only), else its scroll target's children.
local function EachShown(list, fn)
	local box = Usable(list) and list.ScrollBox
	if not Usable(box) then return end
	local view = box.view
	local frames = type(view) == "table" and view.frames
	if type(frames) == "table" then
		for i = 1, #frames do
			local row = frames[i]
			if Usable(row) and row:IsShown() then Try1(fn, row) end
		end
		return
	end
	local target = box.ScrollTarget
	if not Usable(target) then return end
	EachShownOf(fn, target:GetChildren())
end

-- Addon pages (the canvas): dressed once a page has been open a moment, so the addon (and any
-- pack of this plugin's that dresses that page) has had its turn first; then looked at once a second
-- (a page's own rows come and go as it scrolls).
local CANVAS_WAIT = 3      -- passes a page is open before it's touched
local canvasSeen = weak()  -- page -> passes it has been open
local canvasTick = 0

local function CanvasPages(canvas, ...)
	for i = 1, select("#", ...) do
		local page = select(i, ...)
		if Usable(page) then
			if page:IsShown() then
				local n = (canvasSeen[page] or 0) + 1
				canvasSeen[page] = n
				if n >= CANVAS_WAIT and (n == CANVAS_WAIT or canvasTick % 10 == 0) then
					Try1(Piece, page, canvas, true, 1)
				end
			else
				canvasSeen[page] = nil
			end
		end
	end
end

local function CanvasPass()
	local container = panel.Container
	local canvas = Usable(container) and container.SettingsCanvas
	if not Usable(canvas) or not canvas:IsShown() then return end
	canvasTick = canvasTick + 1
	CanvasPages(canvas, canvas:GetChildren())
end

local headerTitle          -- the big name of the shown category, over the settings list
local panelTitle

local passes = 0           -- passes done (the watchdog below checks they run)

local function DefaultsKids(...)
	for i = 1, select("#", ...) do
		local b = select(i, ...)
		if TextButton(b) and not Kit.ButtonOf(b) then Try1(Kit.Button, b, panel) end
	end
end

local function Pass()
	if not panel or not panel:IsShown() or not ns.Enabled(SETTINGS) then return end
	if InCombatLockdown() then return end   -- (the timer comes back to it after the fight)
	passR, passG, passB = ns.AccentOf(SETTINGS)
	passAccent = true
	EachShown(panel.CategoryList, CategoryRow)
	local container = panel.Container
	local list = Usable(container) and container.SettingsList
	if Usable(list) and list:IsShown() then EachShown(list, Row) end
	for tab in pairs(tabs) do
		if tab:IsShown() then Try1(PaintTab, tab) end
	end
	if headerTitle then
		FitFont(headerTitle)
		SetInkOf(headerTitle, ns.Colors().VALUE)
	end
	if panelTitle then SetInkOf(panelTitle, ns.Colors().VALUE) end
	-- Buttons addons hang on the Defaults button (LootTriage's What's New): the game's template.
	local defaults = Usable(list) and Usable(list.Header) and list.Header.DefaultsButton
	if controls and Usable(defaults) then DefaultsKids(defaults:GetChildren()) end
	if controls then CanvasPass() end
	passes = passes + 1
	passAccent = false
end

local function SafePass()
	ns.Guard(Pass)
	passAccent = false   -- (also when the pass stopped on an error)
end

local passQueued = false
local function PassSoon()
	if passQueued then return end
	passQueued = true
	C_Timer.After(0, function()
		passQueued = false
		SafePass()
	end)
end

local ticker
local function Opened()
	if not ns.Enabled(SETTINGS) then return end
	PassSoon()
	if not ticker then ticker = C_Timer.NewTicker(TICK, SafePass) end
	-- Watchdog: a second after opening, the passes must have run (unless a fight holds them back).
	local before = passes
	C_Timer.After(1, function()
		if panel and panel:IsShown() and passes == before and not InCombatLockdown() and ns.Enabled(SETTINGS) then
			Notice("passes", "the game's Options window is open but its rows aren't being dressed (passes not running). Please report this.")
		end
	end)
end
local function Closed()
	if ticker then
		ticker:Cancel()
		ticker = nil
	end
end

-- Each part of the window is dressed on its own (Try1): one part that fails can't keep the rest,
-- or the passes over its rows, from happening. The hooks that start the passes go on first.
local function DressFrame(p)
	-- The frame: its metal pieces off (the pieces, not their frame: the title lives in it), its
	-- inner frame art too, DaylightUI's window shell, quiet (no script of its own on the window).
	Strip(p)
	local nine = p.NineSlice
	if Usable(nine) then Strip(nine) end
	Hide(p.Bg)
	if Usable(p.Bg) then Strip(p.Bg) end
	Kit.Shell(p, "window", { quiet = true })
	TopLine(p)
end

local function DressTitle(p)
	local nine = p.NineSlice
	panelTitle = Usable(nine) and Is(nine.Text, "FontString") and nine.Text or nil
	Title(p, panelTitle)
end

local function DressControls(p)
	if not controls then return end
	-- The X (ClosePanelButton) and the Close button (CloseButton): told apart by their shape.
	for _, key in ipairs({ "ClosePanelButton", "CloseButton" }) do
		local b = p[key]
		if TextButton(b) then Try1(Kit.Button, b, p) elseif CloseX(b) then Try1(Kit.Close, b) end
	end
	-- Any other text button along the bottom (Apply, and whatever this client adds).
	for i = 1, select("#", p:GetChildren()) do
		local c = select(i, p:GetChildren())
		if TextButton(c) and not IsTab(c) then Try1(Kit.Button, c, p) end
	end
	if Is(p.SearchBox, "EditBox") then Try1(Kit.EditBox, p.SearchBox, p) end
	for _, key in ipairs({ "GameTab", "AddOnsTab" }) do
		if IsTab(p[key]) then Try1(TabLook, p[key]) end
	end
end

local function DressLists(p)
	-- The category list and the page beside it: their backgrounds a shade darker than the window.
	local cats = p.CategoryList
	if Usable(cats) then
		Try1(Kit.Inset, cats)
		if controls then Try1(Kit.ScrollBar, cats.ScrollBar) end
	end
	local container = p.Container
	if not Usable(container) then return end
	Try1(Kit.Inset, container)
	local list = container.SettingsList
	if not Usable(list) then return end
	Strip(list)
	if controls then Try1(Kit.ScrollBar, list.ScrollBar) end
	local header = list.Header
	if not Usable(header) then return end
	if Is(header.Title, "FontString") then headerTitle = header.Title end
	-- Its gold divider (an unnamed texture): a faint hairline.
	for i = 1, header:GetNumRegions() do
		local r = select(i, header:GetRegions())
		if Is(r, "Texture") then
			r:SetColorTexture(1, 1, 1, 0.08)
			r:SetHeight(1)
		end
	end
	if controls and TextButton(header.DefaultsButton) then Try1(Kit.Button, header.DefaultsButton, p) end
end

local panelDressed = false
local function DressPanel(p)
	if panelDressed then return end
	panelDressed = true
	panel = p
	controls = ns.Controls(SETTINGS)

	-- When it opens and closes (its own OnShow and OnHide, which run after the game's), and right
	-- after the wheel scrolls a list (the rows it brings in are dressed on the next frame).
	p:HookScript("OnShow", Opened)
	p:HookScript("OnHide", Closed)
	local cats, container = p.CategoryList, p.Container
	local boxes = {}
	if Usable(cats) and Usable(cats.ScrollBox) then boxes[#boxes + 1] = cats.ScrollBox end
	if Usable(container) and Usable(container.SettingsList) and Usable(container.SettingsList.ScrollBox) then
		boxes[#boxes + 1] = container.SettingsList.ScrollBox
	end
	for _, box in ipairs(boxes) do
		-- (Only where the game already handles the wheel: a script of ours on a box without one would
		-- take the wheel from the frame under it.)
		if box:GetScript("OnMouseWheel") then box:HookScript("OnMouseWheel", PassSoon) end
	end

	Try1(DressFrame, p)
	Try1(DressTitle, p)
	Try1(DressControls, p)
	Try1(DressLists, p)
	if p:IsShown() then Opened() end
end

-- The Ping System window (from the Ping System page's "?"): the window shell, the title and the X.
-- Its pictures (its Tutorial art and the four panels) and words stay as they are.
local function DressPing(f)
	if not ns.Once(f) then return end
	local keep = Is(f.Tutorial, "Texture") and { [f.Tutorial] = true } or nil
	Strip(f, keep)
	for _, key in ipairs({ "NineSlice", "Bg", "TopTileStreaks", "TitleBg", "PortraitContainer" }) do
		local part = f[key]
		if Usable(part) and part:GetObjectType() == "Texture" then Hide(part) elseif Usable(part) then Strip(part) end
	end
	local inset = f.Inset
	if Usable(inset) and Usable(inset.NineSlice) then Strip(inset.NineSlice) end
	Kit.Shell(f, "window", { quiet = true })
	TopLine(f)
	local tc = f.TitleContainer
	Title(f, Usable(tc) and tc.TitleText or f.TitleText)
	if ns.Controls(SETTINGS) then
		local x = f.CloseButton or (Usable(tc) and tc.CloseButton)
		if CloseX(x) then Kit.Close(x) end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The dungeon-ready dialog
-- ---------------------------------------------------------------------------------------------

local readyBoxes = {}      -- the dialog and the status box, once dressed
local readyHost            -- the frame the game shows them in (its OnShow is the only one hooked)

-- The hide button in a box's corner (it only tucks the box away; the queue stays): a chevron.
local function HideButton(btn)
	if Is(btn, "Button") and not TextButton(btn) then Kit.BareButton(btn, "down") end
end

local function InkFrame(frame)
	for i = 1, frame:GetNumRegions() do
		local r = select(i, frame:GetRegions())
		if Is(r, "FontString") then InkGame(r, false) end
	end
end

local function InkReady(frame, depth)
	InkFrame(frame)
	if depth >= 2 then return end
	for i = 1, select("#", frame:GetChildren()) do
		local c = select(i, frame:GetChildren())
		if Is(c, "Frame") then InkReady(c, depth + 1) end
	end
end

local function FontReady(frame, depth)
	for i = 1, frame:GetNumRegions() do
		local r = select(i, frame:GetRegions())
		if Is(r, "FontString") then FitFont(r) end
	end
	if depth >= 2 then return end
	for i = 1, select("#", frame:GetChildren()) do
		local c = select(i, frame:GetChildren())
		if Is(c, "Frame") then FontReady(c, depth + 1) end
	end
end

local function ReadyPass()
	if InCombatLockdown() or not ns.Enabled(READY) then return end
	for _, box in ipairs(readyBoxes) do
		if box:IsShown() then
			FontReady(box, 0)
			InkReady(box, 0)
		end
	end
end

local function DressReadyBox(box, host)
	if not Usable(box) or not ns.Once(box) then return end
	readyBoxes[#readyBoxes + 1] = box
	-- The dungeon's picture stays; the gold frame and its flourishes go.
	local art = box.background or _G.LFGDungeonReadyDialogBackground
	local keep = Is(art, "Texture") and { [art] = true } or nil
	Strip(box, keep)
	for _, key in ipairs({ "Border", "NineSlice", "BorderFrame" }) do Hide(box[key]) end
	Kit.Shell(box, "window", { quiet = true })
	TopLine(box)
	-- A picture reaching the box's edges would cover the shell's border there: kept just inside it.
	if keep then
		local bw, aw = box:GetWidth(), art:GetWidth()
		if Num(bw) and Num(aw) and bw > 0 and aw >= bw - 4 then
			local h = art:GetHeight()
			art:ClearAllPoints()
			art:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
			art:SetPoint("TOPRIGHT", box, "TOPRIGHT", -3, -3)
			if Num(h) and h > 0 then art:SetHeight(h) end
		end
	end
	if ns.Controls(READY) then
		for i = 1, select("#", box:GetChildren()) do
			local c = select(i, box:GetChildren())
			if TextButton(c) then Kit.Button(c, host) end
		end
		HideButton(box.closeButton)
		HideButton(box.CloseButton)
	end
	FontReady(box, 0)
	InkReady(box, 0)
end

local function DressReady()
	local popup = _G.LFGDungeonReadyPopup
	local dialog = _G.LFGDungeonReadyDialog
	readyHost = Usable(popup) and popup or dialog
	if not Usable(readyHost) then return end
	DressReadyBox(dialog, readyHost)
	DressReadyBox(_G.LFGDungeonReadyStatus, readyHost)
	-- The game fills in the words as it shows the dialog: inked again on the next frame (out of a
	-- fight; in one they keep the game's colors until the next time).
	readyHost:HookScript("OnShow", function() C_Timer.After(0, function() ns.Guard(ReadyPass) end) end)
end

-- ---------------------------------------------------------------------------------------------
-- Finding them: at login (with the Kit), and as the game's own addons load
-- ---------------------------------------------------------------------------------------------

local settingsDone, pingDone, readyDone = false, false, not hasReady

local function Try()
	Kit = Kit or ns.Kit
	if not Kit then return end
	if not settingsDone and ns.Enabled(SETTINGS) and Usable(_G.SettingsPanel) then
		settingsDone = true
		local p = _G.SettingsPanel
		ns.OutOfCombat(function()
			local ok, err = pcall(DressPanel, p)
			if not ok then
				Notice("dress", "the game's Options window couldn't be dressed (details in your error display).")
				geterrorhandler()(err)
			end
		end)
	end
	if not pingDone and ns.Enabled(SETTINGS) and Usable(_G.PingSystemTutorial) then
		pingDone = true
		local f = _G.PingSystemTutorial
		ns.OutOfCombat(function() DressPing(f) end)
	end
	if not readyDone and ns.Enabled(READY) and (Usable(_G.LFGDungeonReadyPopup) or Usable(_G.LFGDungeonReadyDialog)) then
		readyDone = true
		ns.OutOfCombat(DressReady)
	end
end

local watching = false     -- the window's first opening is watched (below)
local WatchPanel

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self)
	WatchPanel()
	if settingsDone and pingDone and readyDone and watching then
		self:UnregisterEvent("ADDON_LOADED")
		return
	end
	ns.Guard(Try)
end)

-- Whatever happens first (the window made, the Kit handed over, the window opened), it's dressed
-- as soon as all three are there. Its first opening is watched from the start, with no Kit needed:
-- a window opened before the Kit came is dressed on that opening, and one still undressed a moment
-- after opening says why in chat.
local function Why()
	if not ns.Enabled(SETTINGS) then return nil end   -- (switched off: nothing to say)
	if not (Kit or ns.Kit) then return "DaylightUI's skin kit hasn't been handed over (is DaylightUI's Window Skins module on?)" end
	if InCombatLockdown() then return nil end         -- (dressed when the fight ends)
	return "it wasn't found or was skipped"
end

local function OnOpen()
	ns.Guard(Try)
	if panel then
		Opened()
		return
	end
	C_Timer.After(1, function()
		local p = _G.SettingsPanel
		if panel or not (Usable(p) and p:IsShown()) then return end
		local why = Why()
		if why then Notice("undressed", "the game's Options window isn't dressed: " .. why .. ".") end
	end)
end

function WatchPanel()
	local p = _G.SettingsPanel
	if watching or not Usable(p) then return end
	watching = true
	-- (Its own OnShow, run after the game's; only starts a timer.)
	p:HookScript("OnShow", function() C_Timer.After(0, OnOpen) end)
	if p:IsShown() then C_Timer.After(0, OnOpen) end
end
WatchPanel()

ns.me.On("Login", function()
	WatchPanel()
	ns.WithKit(function(K)
		Kit = K
		Try()
	end)
	-- In case neither of the above came through: once more a little later.
	C_Timer.After(3, function() WatchPanel() ns.Guard(Try) end)
end)

-- The accent and the font follow DaylightUI: this pack's own accent pieces repainted at once, the
-- rest on the next pass (every string is fitted again).
local function Restyle()
	playerFont = nil
	wipe(leftText)
	for tex, alpha in pairs(accentLines) do PaintAccentLine(tex, alpha) end
	if panel and panel:IsShown() then PassSoon() end
end
ns.me.On("StyleChanged", Restyle)
ns.me.On("SettingChanged", function(scope, path)
	if scope ~= "DaylightAddonSkins" or type(path) ~= "string" then return end
	if path == "followDaylight" or string.find(path, "^look%.BlizzardSettings%.") or string.find(path, "^look%.BlizzardDungeonReady%.") then Restyle() end
end)
