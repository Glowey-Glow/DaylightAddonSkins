-- Guildy: its guild window and everything it opens, in the DaylightUI look. Guildy draws its window
-- (GuildyFrame) over the game's guild window (CommunitiesFrame, which it keeps at alpha 0 beneath
-- it) and builds every tab the first time it's picked; nearly all of it comes from one toolkit of
-- its own (dark boxes with a gold edge, the game's red panel buttons, a pooled scroll list, its own
-- menu, segmented buttons, slider, resize grip), which is what this pack follows.
-- Dressed here:
--   * The window (ButtonFrameTemplate): its frame, portrait ring and stone ground give way to the
--     window shell (its own opacity, border and bevel when it has a look of its own); its X; the
--     title moved past the guild emblem (the tabard in the corner stays), the version note beside
--     it in the dim ink (an "update available" note keeps its orange); the size grip without gold.
--   * The cog by the X: a DaylightUI button, its gold cog in the text ink.
--   * The bottom tabs (Chat, Members, Overview, ... PanelTabButtonTemplate) as DaylightUI's tabs,
--     the picked one in the accent, each measured again in DaylightUI's font with room between
--     them (they overlap by Guildy's 14 px). The two side tabs (guild, communities; the game's
--     large side tab) as DaylightUI icon tiles, the picked one edged in the accent; the guild
--     emblem on the first and the "something new" dot on the second stay. The same tile for the
--     tab Guildy puts on the game's own guild window ("Back to Guildy", Info / member menu mode).
--   * Every page's boxes (its dark boxes with a gold edge) as DaylightUI row panels: their edge
--     neutral, the accent where Guildy edges the picked one (the options' list-style cards), a
--     lighter edge where it lights one under the mouse (the chat's "jump to newest").
--   * Buttons (UIPanelButtonTemplate: text, small, menu buttons with their arrow, "x" and "+"),
--     re-fitted to their words in DaylightUI's font; the segmented choices (Bank's kinds and the
--     like) with the picked one lit in the accent instead of grayed out; buttons that hand their
--     click to the game's secure button (invite, notes, MOTD, removal, rank arrows) lit while that
--     button lies over them. Search and text boxes (InputBoxTemplate), checkboxes
--     (UICheckButtonTemplate) as switches, scroll bars (UIPanelScrollFrameTemplate and its slim
--     gold restyle), the chat's timeline rail (track and thumb in the scroll bar look), the
--     professions' close X and progress bar, the options' size slider, the guild info editor box.
--   * Lists (its pooled scroll lists): the gold hover and picked bands a white wash and the accent;
--     the player's own row in the Hall of Fame in a faint accent; section hairlines and the gold
--     rules under headings and between groups faint neutral lines; column headings' hover.
--     Each list's rows are dressed as it fills or scrolls them.
--   * Customizing a tab (Customize / Done): the box strips' gold edges in the accent and their
--     ground dark, the free places' gold field faint accent with neutral edges, the "add below"
--     bar, the drag marker and landing field in the accent, the heading handles' gold tint and
--     width grip in the accent, the size grips without gold.
--   * Text: DaylightUI's font on every word (its Morpheus headings too); the game's gold, Guildy's
--     own gold, parchment and muted tones in DaylightUI's inks, set again whenever Guildy
--     re-colors or re-fonts a string. Class colors, online green, rank and quality colors, red
--     (removal), orange (fading score), the score buckets and every inline color stay.
--   * Its menu (W.OpenMenu: Presets, Options, columns, member right-click) on the DaylightUI shell,
--     the hover a wash, the ticks in the accent, the title in the label ink.
--   * Its floating panels: the member card (the tooltip of any member), the activity score panel,
--     the item tooltips' ground (GuildyItemTooltip, GuildyWornTooltip): the shell instead of the
--     gold edge and shadow rings, their gold rules faint lines. The score scale's colors, marker,
--     bars and notes' tints stay (they are the score).
--   * Its dialogs: the remove confirmation (GuildyConfirm; its red "Remove" stays red), the copy
--     box (GuildyCopyBox), the invite suggestions beside the game's invite popup, the Hall of Fame's
--     tile list, the tab customizer's picker: shell, buttons, box. The boxes Guildy lays under the
--     game's note dialog and its text box (the dialog's own art made see-through by Guildy): the
--     window look and the text box look.
--   * The options window (GuildyOptions): shell, X, its top tabs (re-measured), switches, the size
--     slider, buttons and the member-style cards (the picked one edged in the accent).
--   * The level-60 banner (GuildyDing): its gold hairlines and seal in the accent, the level and
--     line in DaylightUI's inks and font. The dark band and the class-colored name stay.
-- Not here: the game's own frames Guildy shows with it or borrows (the guild window under it, the
-- member panel beside the character page, the MOTD / info text box it lends into its Info tab,
-- the rank editor, the invite popup, the communities dialogs: DaylightUI's Window Skins dress
-- those, and touching them would taint Guildy's protected guild actions), its secure buttons
-- (GuildySecureOverlay, GuildyNotePick: invisible, never touched), the chat lines and their font
-- (a ScrollingMessageFrame: the chat's own content), 3D models, portraits and their colored rims,
-- the guild tabard, icons, charts and graphs (bank plot and day bars, level and ilvl bars, timeline
-- day marks, skill bars), the game's tooltip (GameTooltip, DaylightUI's), its test frames (/guildy
-- probe: GuildyModelTest) and screenshot backdrop (/guildy shots, a developer tool).
-- The guild window under Guildy's stays hidden: Guildy keeps it at alpha 0 with its chat stretched
-- across the screen, and DaylightUI's fade-in on that window could carry it back up; it's held at
-- 0 while Guildy's window is in it (its alpha only, as Guildy sets it; see HoldHost).
-- Fast path: Guildy keeps its functions in its own namespace (nothing reachable from _G but
-- GuildyConfirm, GuildyCopyBox and the frames it names). The window is built and shown inside the
-- game's guild window's OnShow: caught from the game's own open calls (ToggleGuildFrame,
-- ToggleCommunitiesFrame, post-hooked), with a watch by name for the banker's opening (an event);
-- dressed again from its own OnShow; /guildy is hooked. Each tab is built the first time its panel
-- is shown: each panel's OnShow dresses it that same frame, after Guildy has filled it; the
-- character page (a new panel, made on its first open) is found in the hide of the tab it replaces.
-- Lists are dressed from their own SetItems, scroll, size and range changes. Pages shown later
-- inside a tab, menus, the customizer and dialogs are dressed from the click that opens them
-- (every Guildy button's click, the menu's rows, the customizer's handles and free places), which
-- also looks at the screen for Guildy's own frames there. Those shown from a hover or a chat name's
-- right-click are found by a fallback look at the screen's child count each frame, only while
-- Guildy's window is open and only until all of them have been found; each is recognized by
-- Guildy's own parts on it (another addon's frame made meanwhile is never taken for one). The
-- options window is dressed from the cog's click. The level-60 banner can show without the window:
-- a watch by name.
-- Taint: Guildy's guild actions go through the game's secure buttons laid over its own; those and
-- every game frame it borrows are left alone (walks skip them), nothing is hooked on the game's
-- frames (only global functions are post-hooked) and only the guild window's alpha is set (as
-- Guildy does), and Guildy's own frames are only dressed and post-hooked (HookScript, hooksecurefunc
-- on its own tables; no SetScript).
local _, ns = ...
if not ns.ok then return end

local KEY = "Guildy"
-- (Its words are the game's font objects and a serif heading font: the player's font goes on all.)
local CAPS = { window = true, controls = true, text = true, shadow = true, font = "daylight" }
ns.Target(KEY, "Guildy", CAPS)

local Usable, Guard = ns.Usable, ns.Guard
local abs, select, type, ipairs, pairs = math.abs, select, type, ipairs, pairs

local Kit

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end
local function Kind(x) return Usable(x) and x:GetObjectType() or nil end
local function IsTexture(x) return Kind(x) == "Texture" end

local function Near(r, g, b, c, tol)
	tol = tol or 0.03
	return type(r) == "number" and abs(r - c[1]) <= tol and abs(g - c[2]) <= tol and abs(b - c[3]) <= tol
end

local GOLD = { 1, 0.82, 0 }           -- the game's gold (text, Guildy's hover edges and marks)
local W_GOLD = { 0.79, 0.64, 0.29 }   -- Guildy's own gold (box edges, rules, labels)

-- Frames this pack's walks leave alone (and everything in them): the game's frames Guildy borrows,
-- secure buttons, chat lines, models, tooltips, and the frames this pack dresses itself.
local skip = setmetatable({}, { __mode = "k" })

-- ---------------------------------------------------------------------------------------------
-- Files Guildy uses, by the number the game gives each for the session
-- ---------------------------------------------------------------------------------------------

local GRABBER, ARROW, COG
local function Files()
	if GRABBER then return end
	GRABBER = ns.FileIDs({
		["Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"] = true,
		["Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight"] = true,
		["Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down"] = true,
	})
	ARROW = ns.FileIDs({ ["Interface\\Buttons\\Arrow-Down-Up"] = true })
	COG = ns.FileIDs({ ["Interface\\Scenarios\\ScenarioIcon-Interact"] = true, ["Interface\\Buttons\\UI-OptionsButton"] = true })
end

local function FileIs(tex, ids)
	if not IsTexture(tex) or not ids then return false end
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return false end
	if type(file) == "string" then file = string.lower(file) end
	return ids[file] == true
end

-- ---------------------------------------------------------------------------------------------
-- Colors on textures: the accent (repainted when it changes), faint lines, the hover wash
-- ---------------------------------------------------------------------------------------------

local accents = setmetatable({}, { __mode = "k" })   -- texture -> its alpha in the accent

local function Accent(tex, alpha)
	if not IsTexture(tex) then return end
	accents[tex] = alpha
	ns.FillAccent(tex, alpha, nil, KEY)
	tex:SetBlendMode("BLEND")
end

local function Hairline(tex, alpha)
	if IsTexture(tex) then tex:SetColorTexture(1, 1, 1, alpha or 0.08) end
end

local function Wash(tex, alpha)
	if not IsTexture(tex) then return end
	tex:SetColorTexture(1, 1, 1, alpha or (Kit and Kit.HOVER_WASH) or 0.08)
	tex:SetBlendMode("BLEND")
end

local tinted = setmetatable({}, { __mode = "k" })   -- texture -> the ink it was tinted in

local function Tint(tex, ink)
	if not IsTexture(tex) then return end
	ink = ink or "TEXT"
	tinted[tex] = ink
	tex:SetDesaturated(true)
	local c = ns.Colors()[ink]
	if c then tex:SetVertexColor(c[1], c[2], c[3]) end
end

-- DaylightUI's own text style (its window font at its sizes), as its Kit dresses buttons and tabs.
local function DUIStyle()
	local dui = _G.DaylightUI
	local Style = type(dui) == "table" and dui.Style
	if type(Style) == "table" and type(Style.DressText) == "function" and type(Style.SIZE) == "table" then return Style end
end

-- ---------------------------------------------------------------------------------------------
-- Text: DaylightUI's font on every string and Guildy's own tones in DaylightUI's inks, again each
-- time Guildy re-colors or re-fonts one (its lists and boxes do on every refresh).
-- ---------------------------------------------------------------------------------------------

local INKS = {
	{ 1, 0.82, 0, "LABEL" },           -- the game's gold (its Normal fonts, menu titles)
	{ 0.79, 0.64, 0.29, "LABEL" },     -- Guildy's gold (facts' labels, note headings)
	{ 0.79, 0.64, 0.15, "LABEL" },     -- the Hall of Fame's band labels
	{ 0.95, 0.89, 0.71, "VALUE" },     -- parchment headings
	{ 1, 0.86, 0.45, "VALUE" },        -- the banner's level
	{ 0.93, 0.88, 0.76, "TEXT" },      -- the banner's line
	{ 0.60, 0.56, 0.47, "LABEL" },     -- the member card's muted labels
	{ 0.47, 0.44, 0.37, "OFF" },       -- the member card's dim lines
	{ 0.5, 0.5, 0.5, "OFF" },          -- the game's gray (its Disable fonts)
}

local strings = setmetatable({}, { __mode = "k" })   -- font string -> hooked
local keepInk = setmetatable({}, { __mode = "k" })   -- strings whose gold means something
local inked = setmetatable({}, { __mode = "k" })     -- font string -> the ink it was given
local inking = false
local hookedCount = 0                                 -- strings hooked so far (the member card's check)

local function InkFor(r, g, b)
	for i = 1, #INKS do
		local c = INKS[i]
		if Near(r, g, b, c) then return c[4] end
	end
end

local function SetInk(fs, name)
	local c = ns.Colors()[name]
	if not c then return end
	inked[fs] = name
	inking = true
	fs:SetTextColor(c[1], c[2], c[3])
	inking = false
end

local function InkString(fs)
	if inking or keepInk[fs] then return end
	local r, g, b = fs:GetTextColor()
	if type(r) ~= "number" then return end
	local name = InkFor(r, g, b)
	if name then
		SetInk(fs, name)
	elseif inked[fs] then
		-- Guildy's own color on it now (a class color, white): its own from here on.
		local c = ns.Colors()[inked[fs]]
		if not (c and Near(r, g, b, c, 0.01)) then inked[fs] = nil end
	end
end

local function FontFollow(fs)
	local ok, path, size = pcall(fs.GetFont, fs)
	if not ok or type(size) ~= "number" or size <= 0 then return end
	-- (The game's narrow number font stays: it's made to read on an icon.)
	if type(path) == "string" and string.find(string.upper(path), "ARIALN", 1, true) then return end
	ns.FollowFont(fs, KEY)
end

local function OnColor(fs)
	if not inking and On() then InkString(fs) end
end

local function OnFontObject(fs)
	if not On() then return end
	FontFollow(fs)
	InkString(fs)
end

local function Text(fs)
	if Kind(fs) ~= "FontString" then return end
	if not strings[fs] then
		strings[fs] = true
		hookedCount = hookedCount + 1
		ns.HookOnce(fs, "SetTextColor", OnColor, KEY)
		ns.HookOnce(fs, "SetFontObject", OnFontObject, KEY)
	end
	FontFollow(fs)
	InkString(fs)
end

local Queue, Floating
local seenFrame = setmetatable({}, { __mode = "k" })
local seenTex = setmetatable({}, { __mode = "k" })

-- Runs fn(...), a dressing of frame f by DaylightUI (a shell, the window look), and marks what it
-- added to f as not Guildy's: its textures are never taken for Guildy's rules or hover bands, and
-- the frames it adds are never walked.
local function Own(f, fn, ...)
	local regions, kids = {}, {}
	for _, r in ipairs({ f:GetRegions() }) do regions[r] = true end
	for _, c in ipairs({ f:GetChildren() }) do kids[c] = true end
	fn(...)
	for _, r in ipairs({ f:GetRegions() }) do
		if not regions[r] then seenTex[r] = true end
	end
	for _, c in ipairs({ f:GetChildren() }) do
		if not kids[c] then skip[c] = true end
	end
end

-- ---------------------------------------------------------------------------------------------
-- Boxes (Guildy's dark boxes with a gold edge, BackdropTemplate with the tooltip border)
-- ---------------------------------------------------------------------------------------------

local TOOLTIP_EDGE = "interface\\tooltips\\ui-tooltip-border"

local function BackdropOf(f)
	if type(f.GetBackdrop) ~= "function" then return nil end
	local ok, b = pcall(f.GetBackdrop, f)
	if ok and type(b) == "table" and type(b.edgeFile) == "string" and string.lower(b.edgeFile) == TOOLTIP_EDGE then
		return b
	end
end

local boxShell = setmetatable({}, { __mode = "k" })   -- box -> its shell
local picked = setmetatable({}, { __mode = "k" })     -- boxes Guildy edges as picked

-- Guildy recolors a box's edge to mark it: bright gold under the mouse, its full gold when picked.
local function BoxBorder(box, r, g, b)
	local s = boxShell[box]
	if not s or not Kit or not On() then return end
	local border
	picked[box] = nil
	if Near(r, g, b, GOLD) then
		border = Kit.ROW_HOVER
	elseif Near(r, g, b, W_GOLD) then
		picked[box] = true
		local ar, ag, ab = ns.AccentOf(KEY)
		border = { ar, ag, ab }
	end
	Kit.Paint(s, border)
end

local function Box(f, backdrop)
	if boxShell[f] then return end
	Kit.Backdrop(f)
	if backdrop.bgFile == nil then
		-- (An edge without a ground, round a 3D model: a neutral edge alone, never "picked".)
		Own(f, Kit.Shell, f, "row", { noBackground = true })
		return
	end
	Own(f, function() boxShell[f] = Kit.Shell(f, "row") end)
	if type(f.SetBackdropBorderColor) == "function" then ns.HookOnce(f, "SetBackdropBorderColor", BoxBorder, KEY) end
	if f.GetBackdropBorderColor then
		local ok, r, g, b = pcall(f.GetBackdropBorderColor, f)
		if ok then BoxBorder(f, r, g, b) end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The walk: what each frame of Guildy's is, looked at once; its words every time
-- ---------------------------------------------------------------------------------------------

local function InChart(r)
	local p = r:GetParent()
	for _ = 1, 2 do
		if not Usable(p) then return false end
		if type(rawget(p, "Bars")) == "table" or type(rawget(p, "Lines")) == "table" then return true end
		p = p:GetParent()
	end
	return false
end

local function TextureOf(r, button)
	-- W.Icon's gold edge under an icon: the neutral tab edge.
	if IsTexture(r.Border) and r.Border ~= r then
		local n = Kit.TAB_BORDER
		r.Border:SetColorTexture(n[1], n[2], n[3], 1)
	end
	local layer = r:GetDrawLayer()
	if layer == "HIGHLIGHT" then
		-- Every hover band (the quest-title glow, the gold washes): a white wash. The size grip's
		-- own highlight stays (it's grayed with the grip).
		if not FileIs(r, GRABBER) then Wash(r) end
	elseif layer == "ARTWORK" and not button then
		-- Gold (or bronze) rules one pixel high, under headings and between groups. (Not the bank
		-- chart's day bars, one pixel high on a quiet day: its plot holds them in .Bars.)
		local h, w = r:GetHeight(), r:GetWidth()
		if type(h) == "number" and h > 0 and h <= 1.5 and type(w) == "number" and w >= 24 and not InChart(r) then
			Hairline(r)
		end
	end
end

local function Regions(button, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if Usable(r) then
			local k = r:GetObjectType()
			if k == "FontString" then
				Text(r)
				-- W.Heading's ornament under it.
				if not seenTex[r] then
					seenTex[r] = true
					if IsTexture(r.Divider) then
						Hairline(r.Divider, 0.1)
						r.Divider:SetHeight(1)
					end
				end
			elseif k == "Texture" and not seenTex[r] then
				seenTex[r] = true
				TextureOf(r, button)
			end
		end
	end
end

-- The lines of a marker or a strip (BORDER-layer color textures on it).
local function BorderLines(fn, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if IsTexture(r) and r:GetDrawLayer() == "BORDER" then fn(r) end
	end
end

local function AccentLine(alpha) return function(r) Accent(r, alpha) end end
local function NeutralLine(alpha) return function(r) Hairline(r, alpha) end end

-- Guildy's menu button arrow, its cog.
local function ArtOf(btn, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if IsTexture(r) and r:GetDrawLayer() == "OVERLAY" and FileIs(r, ARROW) then Tint(r, "LABEL") end
	end
	if IsTexture(btn.Icon) and FileIs(btn.Icon, COG) then Tint(btn.Icon, "TEXT") end
end

-- A UIPanelButtonTemplate button of Guildy's (W.Button, W.IconButton, W.DropButton).
local seenButton = setmetatable({}, { __mode = "k" })
local QueueMain   -- (below: every click on a control of Guildy's)
local HoverHook   -- (below: a hover that may make Guildy's member card or score panel)

-- Guildy sizes its buttons to their words as they're set (W.Button's SetText hook), some only up to a
-- cap past which it cuts the words off with "..." (the bank's tab buttons at 120 px, "Only" at 200,
-- a box's Options at 160, the language and phase menus at 240). Set again here, measured in
-- DaylightUI's (larger) font; words still past the cap get the font a size or more smaller until
-- they fit whole. Again whenever Guildy sets new words or the Kit puts its size back (enable,
-- disable), and after a style change.
local MIN_SIZE = 8
local fitting = setmetatable({}, { __mode = "k" })
local shrunk = setmetatable({}, { __mode = "k" })

local function Refit(btn, measure)
	if fitting[btn] or not On() or not Controls() then return end
	local Style = DUIStyle()
	local fs = btn.GetFontString and btn:GetFontString()
	local words = btn.GetText and btn:GetText()
	if not Style or Kind(fs) ~= "FontString" or type(words) ~= "string" or words == "" then return end
	fitting[btn] = true
	local size = Style.SIZE.body or 13
	if shrunk[btn] or measure then
		shrunk[btn] = nil
		Style.DressText(fs, size)
		btn:SetText(words)
	end
	if fs.IsTruncated and fs:IsTruncated() then
		while fs:IsTruncated() and size > MIN_SIZE do
			size = size - 1
			Style.DressText(fs, size)
		end
		shrunk[btn] = true
	end
	fitting[btn] = nil
end

local function OnSetText(btn) Guard(Refit, btn, false) end
local function OnState(btn) Guard(Refit, btn, false) end

local function PanelButton(btn)
	if seenButton[btn] then return end
	seenButton[btn] = true
	ArtOf(btn, btn:GetRegions())
	if Controls() then
		Kit.Button(btn)
		Refit(btn, true)
		ns.HookOnce(btn, "SetText", OnSetText, KEY)
		-- (After the Kit's own: it puts the body size back on these.)
		ns.ScriptOnce(btn, "OnEnable", OnState, KEY)
		ns.ScriptOnce(btn, "OnDisable", OnState, KEY)
		-- A button whose click is the game's secure button laid over it: that button takes the mouse,
		-- and Guildy lights the one below with LockHighlight.
		local s = Kit.ButtonOf(btn)
		if type(btn.relayOverlay) == "function" and type(s) == "table" and type(s.Hover) == "function" then
			ns.HookOnce(btn, "LockHighlight", function() if On() then s.Hover(true) end end, KEY)
			ns.HookOnce(btn, "UnlockHighlight", function() if On() then s.Hover(false) end end, KEY)
		end
	end
	-- What its click opens or rebuilds (a page, the customizer, a menu), dressed in the same frame.
	ns.ScriptOnce(btn, "OnClick", QueueMain, KEY)
end

-- (Not the bottom tabs, whose template has the same three pieces and its "active" ones.)
local function IsPanelButton(b)
	return IsTexture(b.Left) and IsTexture(b.Right) and IsTexture(b.Middle) and not b.LeftActive
end

-- Kinds of frames the walks don't go into.
local SKIP_KIND = { ScrollingMessageFrame = true, MessageFrame = true, ModelScene = true, PlayerModel = true,
	DressUpModel = true, Model = true, CinematicModel = true, GameTooltip = true, Cooldown = true }

local childCount = setmetatable({}, { __mode = "k" })
local function ChildList(...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		if Usable(c) then
			local k = c:GetObjectType()
			if SKIP_KIND[k] or (c.IsProtected and c:IsProtected()) then
				skip[c] = true
			elseif k == "Button" and IsPanelButton(c) then
				Guard(PanelButton, c)
			end
		end
	end
end

local function Children(f)
	local n = f:GetNumChildren()
	if childCount[f] == n then return end
	childCount[f] = n
	ChildList(f:GetChildren())
end

-- Segmented choices (W.Segmented): Guildy disables the picked one and turns the others' words gold.
-- Here they read as tabs: only the picked one is lit (the accent trace, the brighter band, bright
-- words) and not grayed; the others are plain, their words brighten under the mouse. (A DaylightUI
-- button lights its trace on hover too, which made a hovered choice look picked beside the real
-- one: on these the trace follows the pick alone.)
local groups = setmetatable({}, { __mode = "k" })
local function SegPaint(g)
	if not Kit or not On() then return end
	for _, b in ipairs(g.buttons) do
		local s = Kit.ButtonOf(b)
		local on = b.IsEnabled and not b:IsEnabled() or false
		if type(s) == "table" and type(s.Paint) == "function" then
			s.active = on or nil
			s.main = on or nil
			if on then s.off = nil end
			s.Paint()
			if type(s.Light) == "function" then s.Light(false) end
		end
		-- Its words: the picked one's bright, the others' the buttons' own ink (not Guildy's gold),
		-- bright too while the mouse is over one.
		local fs = b.GetFontString and b:GetFontString()
		if Kind(fs) == "FontString" then SetInk(fs, (on or b:IsMouseOver() == true) and "VALUE" or "TEXT") end
	end
end

-- Guildy placed them side by side once, at the widths they had in the game's font (only their
-- group's own anchors move it: the toolbar chains to the group, never to a button in it): placed
-- again at their widths in DaylightUI's, so none runs into the next. Again after a style change.
local function SegLayout(g)
	local x = 0
	for _, b in ipairs(g.buttons) do
		if Kind(b) == "Button" then
			b:ClearAllPoints()
			b:SetPoint("LEFT", g, "LEFT", x, 0)
			x = x + (b:GetWidth() or 70) + 2
		end
	end
	if x > 0 then g:SetWidth(x) end
end

local function Segmented(g)
	if groups[g] or not Controls() then return end
	groups[g] = true
	for _, b in ipairs(g.buttons) do
		if Kind(b) == "Button" then
			Guard(PanelButton, b)
			Text(b:GetFontString())
			-- The trace shows the pick only, never the mouse (Kit's state changes and hover call
			-- s.Light; this one reads the pick).
			local s = Kit.ButtonOf(b)
			if type(s) == "table" and type(s.trace) == "table" and type(s.trace.To) == "function" then
				s.Light = function() s.trace.To((s.active and not s.off) and true or false) end
			end
			ns.ScriptOnce(b, "OnEnter", function() Guard(SegPaint, g) end, KEY)
			ns.ScriptOnce(b, "OnLeave", function() Guard(SegPaint, g) end, KEY)
		end
	end
	SegLayout(g)
	ns.HookOnce(g, "SetValue", function() Guard(SegPaint, g) end, KEY)
	SegPaint(g)
end

-- The chat's timeline rail (a track with a thumb, Guildy's own scroll bar): the scroll bar look.
local function Rail(rail, thumb)
	local S = Kit.SCROLL
	if type(S) ~= "table" then return end
	for i = 1, rail:GetNumRegions() do
		local r = select(i, rail:GetRegions())
		if IsTexture(r) and r:GetDrawLayer() == "BACKGROUND" then
			local c = S.track
			r:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
		end
	end
	for i = 1, thumb:GetNumRegions() do
		local r = select(i, thumb:GetRegions())
		if IsTexture(r) then
			local layer = r:GetDrawLayer()
			if layer == "BACKGROUND" then
				r:SetAlpha(0)
			elseif layer == "ARTWORK" then
				local c = S.thumb
				r:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
			end
		end
	end
end

local function RailThumb(...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		if Kind(c) == "Button" and abs((c:GetWidth() or 0) - 8) < 0.5 then
			for j = 1, c:GetNumRegions() do
				local r = select(j, c:GetRegions())
				if IsTexture(r) and r:GetDrawLayer() == "HIGHLIGHT" then return c end
			end
		end
	end
end

-- One of Guildy's lists (W.ScrollList): its rows as it fills or scrolls them.
local function List(sf)
	local child = sf.GetScrollChild and sf:GetScrollChild()
	if not Usable(child) then return end
	local function again() if On() then Queue(child, "sub") end end
	ns.HookOnce(sf, "SetItems", again, KEY)
	ns.ScriptOnce(sf, "OnVerticalScroll", again, KEY)
	-- (A larger window shows more rows: made in its size and range changes, not in SetItems.)
	ns.ScriptOnce(sf, "OnSizeChanged", again, KEY)
	ns.ScriptOnce(sf, "OnScrollRangeChanged", again, KEY)
end

local function Grip(btn)
	for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture" }) do
		local tex = btn[get] and btn[get](btn)
		if IsTexture(tex) then tex:SetDesaturated(true) end
	end
end

local function CloseArt(btn)
	local tex = btn.GetNormalTexture and btn:GetNormalTexture()
	if not IsTexture(tex) then return false end
	local ok, atlas = pcall(tex.GetAtlas, tex)
	return ok and type(atlas) == "string" and string.lower(atlas) == "redbutton-exit"
end

-- Picked rows and the player's own row (Hall of Fame): the accent, faint (0: the Kit's pick wash).
local PICK_KEYS = { Selected = 0, Picked = 0, Mine = 0.1 }

-- A box Guildy puts in the dialog layer above its window (the customizer's picker) is a dialog of
-- its own. (Not a box lifted to HIGH while it's dragged or previewed: a box of the page.)
local Dialog
local function Lifted(f)
	local parent = f:GetParent()
	return Usable(parent) and f:GetFrameStrata() == "DIALOG" and parent:GetFrameStrata() ~= "DIALOG"
end

-- Customizing: a heading's or tile's handle, a free place and "add below" open the picker, the
-- Hall of Fame's tile list or a menu with their click (none of them a button of Guildy's toolkit).
local function OpensSomething(btn)
	ns.ScriptOnce(btn, "OnClick", QueueMain, KEY)
end

-- What one frame of Guildy's is, the first time it's seen.
local function Piece(f)
	local k = f:GetObjectType()
	for key, alpha in pairs(PICK_KEYS) do
		local tex = rawget(f, key)
		if IsTexture(tex) then Accent(tex, alpha > 0 and alpha or Kit.ROW_PICK or 0.16) end
	end
	if k == "Button" then
		local normal = f.GetNormalTexture and f:GetNormalTexture()
		if FileIs(normal, GRABBER) then
			Grip(f)
		elseif CloseArt(f) then
			if Controls() then Kit.Close(f) end
		elseif IsTexture(f.Fill) and f.Remove ~= nil then
			-- A heading's handle while customizing: its gold tint and width grip in the accent.
			Accent(f.Fill, 0.14)
			if Usable(f.Grip) and IsTexture(f.Grip.Line) then Accent(f.Grip.Line, 0.8) end
			-- (A part's handle on a box marks the part with a gold bar.)
			if IsTexture(f.Mark) then Accent(f.Mark, 0.9) end
			OpensSomething(f)
		elseif IsTexture(f.Fill) and Kind(f.Plus) == "FontString" then
			-- A free place while customizing.
			Accent(f.Fill, 0.07)
			BorderLines(NeutralLine(0.18), f:GetRegions())
			OpensSomething(f)
		elseif IsTexture(f.Fill) and IsTexture(f.Edge) and Kind(f.Label) == "FontString" then
			-- "Add below": its ground dark, its top edge in the accent.
			f.Fill:SetColorTexture(0.08, 0.08, 0.08, 0.95)
			Accent(f.Edge, 0.6)
			OpensSomething(f)
		elseif IsTexture(f.Fill) and Usable(f:GetParent()) and f:GetParent().Strip == f then
			-- A box's strip while customizing (its name, Options, + and x).
			f.Fill:SetColorTexture(0.08, 0.08, 0.08, 1)
			BorderLines(AccentLine(0.6), f:GetRegions())
		elseif IsTexture(f.Track) and IsTexture(f.Fill) and type(f.SetData) == "function" then
			-- W.BarRow: its brown track neutral (the fill is the data's color).
			f.Track:SetColorTexture(1, 1, 1, 0.08)
		elseif abs((f:GetWidth() or 0) - 40) < 0.5 then
			local thumb = RailThumb(f:GetChildren())
			if thumb then Rail(f, thumb) end
		end
	elseif k == "Frame" then
		local backdrop = BackdropOf(f)
		if backdrop then
			if type(f.Shadow) == "table" then
				Floating(f)
			elseif Lifted(f) then
				Dialog(f)
			else
				Box(f, backdrop)
			end
		elseif type(f.buttons) == "table" and type(f.SetValue) == "function" then
			Segmented(f)
		elseif IsTexture(f.Fill) and f:GetNumChildren() == 0 then
			-- A drop marker (a heading being dragged, a box's landing field): the accent.
			Accent(f.Fill, 0.22)
			BorderLines(AccentLine(0.9), f:GetRegions())
		end
	elseif k == "ScrollFrame" then
		if type(f.SetItems) == "function" and type(f.rows) == "table" then List(f) end
		-- W.InputArea: a multi-line box with no art of its own.
		if Kind(f.EditBox) == "EditBox" then
			FontFollow(f.EditBox)
			if Controls() then Own(f, Kit.Shell, f, "input") end
		end
	elseif k == "Slider" then
		if type(f.Set) == "function" and not f.ScrollUpButton and Controls() and ns.Slider then Own(f, ns.Slider, f) end
	elseif k == "StatusBar" then
		if Controls() then
			local r, g, b = ns.AccentOf(KEY)
			Own(f, Kit.StatusBar, f, { r, g, b })
		end
	elseif k == "EditBox" then
		FontFollow(f)
	end
end

local function Each(f)
	if not Usable(f) or not On() then return end
	if not seenFrame[f] then
		seenFrame[f] = true
		Guard(Piece, f)
		Guard(HoverHook, f)
	end
	if f.GetNumChildren then Children(f) end
	if f.GetRegions then Regions(f:GetObjectType() == "Button", f:GetRegions()) end
end

-- The walk with the controls left as Guildy draws them ("Controls" off on its page): words and
-- Guildy's own pieces only.
local Walk
local function WalkKids(depth, shownOnly, ...)
	for i = 1, select("#", ...) do Walk((select(i, ...)), depth, shownOnly) end
end
function Walk(f, depth, shownOnly)
	if depth > 16 or not Usable(f) or skip[f] then return end
	if shownOnly and depth > 0 and not f:IsShown() then return end
	Each(f)
	if skip[f] then return end
	if f.GetChildren then WalkKids(depth + 1, shownOnly, f:GetChildren()) end
end

-- ---------------------------------------------------------------------------------------------
-- Passes: queued, and run once each in the next update of this same frame (before it's drawn)
-- ---------------------------------------------------------------------------------------------

local FIRST = { skip = skip, rows = false, depth = 16, each = Each }
local AGAIN = { skip = skip, rows = false, depth = 16, each = Each, shownOnly = true }
local SUB = { skip = skip, rows = false, depth = 16, each = Each, shownOnly = true }
local OPTS = { first = FIRST, again = AGAIN, sub = SUB }
local RANK = { sub = 1, again = 2, first = 3 }

-- The game's text box Guildy lends into its Info tab while the MOTD or guild info is edited: the
-- game's own, left alone.
local function BorrowedSkip()
	local editor = _G.CommunitiesGuildTextEditFrame
	if Usable(editor) and Usable(editor.Container) then skip[editor.Container] = true end
end

local pending, running = {}, {}
local runner = CreateFrame("Frame")
runner:Hide()
local waitingCombat = false

local function Pass(root, mode)
	if not Usable(root) or not On() then return end
	if mode ~= "first" and not root:IsVisible() then return end
	BorrowedSkip()
	if not Controls() then
		Walk(root, 0, mode ~= "first")
		return
	end
	if Kit.Walking(root) then
		-- A walk still under way (a fight pauses it) drops a second one: asked again once it's done.
		if InCombatLockdown() then
			if not waitingCombat then
				waitingCombat = true
				ns.OutOfCombat(function() waitingCombat = false Queue(root, mode) end)
			end
		else
			C_Timer.After(0.1, function() Queue(root, mode) end)
		end
		return
	end
	Kit.Auto(root, OPTS[mode] or AGAIN)
end

runner:SetScript("OnUpdate", function(self)
	self:Hide()
	if not Kit then wipe(pending) return end
	pending, running = running, pending
	for root, mode in pairs(running) do Guard(Pass, root, mode) end
	wipe(running)
end)

function Queue(root, mode)
	if not Usable(root) then return end
	mode = mode or "again"
	local was = pending[root]
	if not was or RANK[mode] > RANK[was] then pending[root] = mode end
	runner:Show()
end

-- ---------------------------------------------------------------------------------------------
-- Frames Guildy makes on the screen itself: menu, floating panels, dialogs
-- ---------------------------------------------------------------------------------------------

local shelled = setmetatable({}, { __mode = "k" })

-- A floating panel's words and rules as they are now (the member card refills its pools).
local function FloatWalk(f, depth)
	if depth > 6 or not Usable(f) or (depth > 0 and skip[f]) then return end
	Each(f)
	for i = 1, (f.GetNumChildren and f:GetNumChildren() or 0) do
		FloatWalk((select(i, f:GetChildren())), depth + 1)
	end
end

-- The member card measures its words and sizes itself as it's filled (Popups.lua Card:Layout). A
-- string it uses for the first time is in the game's font then (its font hook isn't on it yet), so
-- the card was measured too small for DaylightUI's: it's filled again once, right after, by the
-- hover that showed it (its owner's own OnEnter), now that every string follows the font as it's set.
local relayout = CreateFrame("Frame")
relayout:Hide()
local relaying = false
relayout:SetScript("OnUpdate", function(self)
	self:Hide()
	local f = self.card
	self.card = nil
	if not (Usable(f) and f:IsShown() and On()) then return end
	local owner = rawget(f, "owner")
	if not Usable(owner) or (owner.IsProtected and owner:IsProtected()) or not owner:IsVisible()
		or not (owner.IsMouseOver and owner:IsMouseOver()) then return end
	local enter = owner.GetScript and owner:GetScript("OnEnter")
	if type(enter) ~= "function" then return end
	relaying = true
	pcall(enter, owner)
	relaying = false
end)

local function FloatDress(f)
	if not On() then return end
	local before = hookedCount
	if type(f.rules) == "table" then
		for _, rule in ipairs(f.rules) do Hairline(rule, 0.1) end
	end
	FloatWalk(f, 0)
	if hookedCount > before and type(f.texts) == "table" and not relaying then
		relayout.card = f
		relayout:Show()
	end
end

-- W.FloatingPanel: the member card, the score panel, the item tooltips' ground.
function Floating(f)
	if shelled[f] then return end
	shelled[f] = true
	skip[f] = true
	if type(f.Shadow) == "table" then
		for _, t in ipairs(f.Shadow) do ns.Kill(t) end
	end
	local ground = Usable(f.Ground) and f.Ground or f
	Kit.Backdrop(ground)
	Own(ground, ns.Shell, ground, { window = true }, KEY)
	if Kind(f) == "GameTooltip" then return end
	-- The score panel's notes keep their gold and orange (they say how the score was scaled).
	if type(f.Notes) == "table" then
		for _, note in pairs(f.Notes) do
			if Usable(note) and Kind(note.Text) == "FontString" then keepInk[note.Text] = true end
		end
	end
	ns.ScriptOnce(f, "OnShow", function() Guard(FloatDress, f) end, KEY)
	-- The member card is laid out anew (and sized) while it stays shown, row to row.
	if type(f.rules) == "table" then ns.HookOnce(f, "SetSize", function() Guard(FloatDress, f) end, KEY) end
	FloatDress(f)
end

-- Guildy's menu (W.OpenMenu): one shared frame, its rows reused and refilled on every open.
local function MenuRows(m)
	if not On() then return end
	local r, g, b = ns.AccentOf(KEY)
	for _, row in ipairs(m.buttons) do
		if Usable(row) then
			if not seenFrame[row] then
				seenFrame[row] = true
				local hl = row.GetHighlightTexture and row:GetHighlightTexture()
				if IsTexture(hl) then Wash(hl) end
			end
			-- Guildy sets each shown row's OnClick anew on every open (SetScript, which drops a hook),
			-- right before it sizes the menu: hooked again each time, the shown rows only.
			if row:IsShown() then row:HookScript("OnClick", QueueMain) end
			if IsTexture(row.Check) then
				row.Check:SetDesaturated(true)
				row.Check:SetVertexColor(r, g, b)
			end
			Text(row.Label)
		end
	end
end

local function Menu(m)
	if shelled[m] then return end
	shelled[m] = true
	Kit.Backdrop(m)
	Own(m, ns.Shell, m, { window = true }, KEY)
	-- (Sized on every open, right before it's shown.)
	ns.HookOnce(m, "SetSize", function() Guard(MenuRows, m) end, KEY)
	MenuRows(m)
end

-- A dialog of Guildy's on the screen: the remove confirmation, the copy box, the invite suggestions,
-- the Hall of Fame's tile list, the customizer's picker.
function Dialog(f)
	if shelled[f] then return end
	shelled[f] = true
	Kit.Backdrop(f)
	Own(f, ns.Shell, f, { window = true }, KEY)
	-- The confirmation's OK: red for a removal (kept), gold otherwise.
	if Kind(f.Ok) == "Button" then Text(f.Ok:GetFontString()) end
	ns.ScriptOnce(f, "OnShow", function() if On() then Queue(f, "again") end end, KEY)
	Queue(f, "first")
end

-- Guildy's boxes behind the game's note dialog and its text box (Notes.lua: it makes the dialog's
-- own art see-through and lays a box of its own under each): the window look under the dialog, the
-- text box look under its box. Only the box of Guildy's is dressed; the dialog is the game's.
local function NoteBacking(f, kind)
	if shelled[f] then return end
	shelled[f] = true
	Kit.Backdrop(f)
	if kind == "input" then
		Own(f, Kit.Shell, f, "input")
	else
		Own(f, ns.Shell, f, { window = true }, KEY)
	end
end

-- ---------------------------------------------------------------------------------------------
-- The options window (GuildyOptions, built on the cog's first click)
-- ---------------------------------------------------------------------------------------------

local function FitTab(tab, pad, min)
	if type(PanelTemplates_TabResize) == "function" then pcall(PanelTemplates_TabResize, tab, pad, nil, min) end
end

-- The tabs' words in DaylightUI's font in every state. The button swaps its font objects (the game's
-- small serif ones) as the mouse comes and goes and as Guildy locks its highlight under the game's
-- secure button: all three are one font object in DaylightUI's window font, and the words are dressed
-- again (size, outline, ink) on each of those changes. (The picked tab's disabled font object is set
-- by the game on every pick; the Kit dresses that one.)
local tabFont
local function TabFont()
	local Style = DUIStyle()
	if not Style or type(Style.FontFile) ~= "function" then return nil end
	local file = Style.FontFile(Style.WINDOW_SLOT)
	if type(file) ~= "string" then return nil end
	if not tabFont then
		tabFont = CreateFont("DaylightAddonSkinsGuildyTab")
		local base = _G.GameFontNormalSmall
		if base then tabFont:CopyFontObject(base) end
	end
	tabFont:SetFont(file, Style.SIZE.body or 13, "")
	local c = ns.Colors().LABEL
	if c then tabFont:SetTextColor(c[1], c[2], c[3]) end
	return tabFont
end

local textTabs = setmetatable({}, { __mode = "k" })   -- tab -> { pad, min }

local function TabWords(tab, over)
	if not On() then return end
	local Style = DUIStyle()
	local fs = tab.Text or (tab.GetFontString and tab:GetFontString())
	if Style and Kind(fs) == "FontString" then Style.DressText(fs, Style.SIZE.body or 13) end
	local t = Kit.TabOf and Kit.TabOf(tab)
	if type(t) == "table" and type(t.Paint) == "function" then
		if over == nil then over = tab:IsMouseOver() == true end
		t.Paint(over)
	end
end

local function TabFonts(tab)
	local f = TabFont()
	if not f then return end
	tab:SetNormalFontObject(f)
	tab:SetHighlightFontObject(f)
	if tab:IsEnabled() then tab:SetDisabledFontObject(f) end
end

-- Text tabs sized again in DaylightUI's font, now and each time the template sizes them (on show
-- and on a display change), with pad px more room.
local function TextTab(tab, pad, min)
	if not Usable(tab) or textTabs[tab] then return end
	textTabs[tab] = { pad, min }
	seenFrame[tab] = true
	if not Controls() then return end
	Kit.Tab(tab)
	-- (The game drops a picked tab's words 5 px lower than the others' (PanelTemplates_SelectTab:
	-- selectedTextY -3, deselectedTextY 2). DaylightUI's tab marks the pick with its accent line, so
	-- the words stay level: the picked offset is the same as the others'.)
	tab.selectedTextY = tab.deselectedTextY or 2
	if tab.Text and tab.Text.SetPoint then
		tab.Text:ClearAllPoints()
		tab.Text:SetPoint("CENTER", tab, "CENTER", tab.deselectedTextX or 0, tab.selectedTextY)
	end
	TabFonts(tab)
	TabWords(tab)
	FitTab(tab, pad, min)
	local function again() if On() then FitTab(tab, pad, min) end end
	ns.ScriptOnce(tab, "OnShow", again, KEY)
	ns.ScriptOnce(tab, "OnEvent", again, KEY)
	ns.ScriptOnce(tab, "OnEnter", function() TabWords(tab, true) end, KEY)
	ns.ScriptOnce(tab, "OnLeave", function() TabWords(tab, false) end, KEY)
	-- (Lit by Guildy while the game's secure button lies over it.)
	ns.HookOnce(tab, "LockHighlight", function() TabWords(tab, true) end, KEY)
	ns.HookOnce(tab, "UnlockHighlight", function() TabWords(tab, false) end, KEY)
end

local function Options(o)
	if not Kit or not Usable(o) or shelled[o] then return end
	shelled[o] = true
	Own(o, function()
		Kit.Window(o)
		ns.Shell(o, { window = true }, KEY)
	end)
	local i = 1
	while Usable(_G["GuildyOptionsTab" .. i]) do
		TextTab(_G["GuildyOptionsTab" .. i], 15, 70)
		i = i + 1
	end
	ns.ScriptOnce(o, "OnShow", function() if On() then Queue(o, "again") end end, KEY)
	Queue(o, "first")
end

local function OptionsNow()
	if On() and Kit then Guard(Options, _G.GuildyOptions) end
end

-- ---------------------------------------------------------------------------------------------
-- The game's guild window under Guildy's
-- ---------------------------------------------------------------------------------------------

-- Guildy keeps the game's guild window (CommunitiesFrame, its host) at alpha 0 under its own
-- (Main.lua Embed) and parks the game's member list off the screen, which stretches the game's chat
-- in that window across the whole screen (Notes.lua Release). DaylightUI's skin of that window fades
-- it in each time it shows (Kit.Window's Motion.FadeIn, from the alpha it has then); run before
-- Guildy's own OnShow hook, that fade carries the window back up to full under Guildy's, and the
-- stretched chat (lines, its input bar) shows below and over Guildy's window. While Guildy's window
-- is embedded the host is held at 0 for the length of a fade, and it's left at 0 when it closes, so
-- the next fade starts from 0. Only its alpha, as Guildy itself sets it: nothing of the game's
-- window is hooked, walked or dressed here.
local function Embedded()
	local host, main = _G.CommunitiesFrame, _G.GuildyFrame
	if not (Usable(host) and Usable(main)) then return nil end
	-- (Not at the guild banker, where Guildy's window stands alone, nor while Guildy shows the
	-- game's window instead: its own window is hidden then.)
	if main:GetParent() ~= host or not main:IsShown() then return nil end
	return host
end

local function Clear(host)
	local a = host:GetAlpha()
	if type(a) == "number" and a > 0.001 then pcall(host.SetAlpha, host, 0) end
end

local HOLD = 1   -- seconds: longer than any fade of DaylightUI's
local holdLeft = 0
local holder = CreateFrame("Frame")
holder:Hide()
holder:SetScript("OnUpdate", function(self, elapsed)
	holdLeft = holdLeft - elapsed
	local host = Embedded()
	if host then Clear(host) end
	if not host or holdLeft <= 0 then self:Hide() end
end)

local function HoldHost()
	if not On() then return end
	local host = Embedded()
	if not host then return end
	Clear(host)
	holdLeft = HOLD
	holder:Show()
end

-- Closed: left at 0 for the next open (Guildy's window is its child, so it hides with it).
local function HostClosed()
	local host, main = _G.CommunitiesFrame, _G.GuildyFrame
	if not On() or not (Usable(host) and Usable(main)) then return end
	if main:GetParent() == host and not host:IsShown() then Clear(host) end
end

-- ---------------------------------------------------------------------------------------------
-- The window
-- ---------------------------------------------------------------------------------------------

-- Side tabs (the game's large side tab): DaylightUI's tile round the icon. Their template art goes;
-- the picked one is the template's SelectedTexture still shown or hidden by SetChecked.
local function SidePicked(tab)
	local s = tab.SelectedTexture
	return IsTexture(s) and s:IsShown() == true
end

local SIDE_ART = { "Background", "SelectedTexture", "TabGlow", "HighlightTexture" }
local function SideTab(tab)
	if not Usable(tab) or not IsTexture(tab.Icon) or seenFrame[tab] then return end
	seenFrame[tab] = true
	skip[tab] = true
	if not Controls() then return end
	for _, k in ipairs(SIDE_ART) do
		if IsTexture(tab[k]) then tab[k]:SetAlpha(0) end
	end
	-- The guild emblem drawn in the icon's place: square, as the tile is.
	local emblem = tab.Emblem
	if type(emblem) == "table" and Usable(tab.Mask) then
		for _, k in ipairs({ "Background", "Emblem", "Border" }) do
			local t = emblem[k]
			if IsTexture(t) and t.RemoveMaskTexture then pcall(t.RemoveMaskTexture, t, tab.Mask) end
		end
	end
	if not ns.SideTile(tab, { picked = SidePicked, key = KEY, pad = 2 }) then return end
	if type(tab.SetChecked) == "function" then ns.HookOnce(tab, "SetChecked", ns.SideTilesPaintSoon, KEY) end
	-- (Lit by Guildy while the game's secure button lies over it.)
	if type(tab.SetHover) == "function" then ns.HookOnce(tab, "SetHover", function() ns.SideTilePaint(tab) end, KEY) end
end

-- The tab Guildy puts on the game's guild window while that one shows instead (Info, member
-- menu): found among the game window's children by Guildy's marks, read only. (Guildy's own frame;
-- nothing else of the game's window is touched.)
local function ReturnTab()
	local host = _G.CommunitiesFrame
	if not Usable(host) or not host:IsShown() then return end
	local main = _G.GuildyFrame
	for i = 1, host:GetNumChildren() do
		local c = select(i, host:GetChildren())
		if c ~= main and Usable(c) and rawget(c, "sideTab") == true and type(rawget(c, "Emblem")) == "table" then
			SideTab(c)
		end
	end
end

-- The title past the guild emblem in the corner, the version note beside it.
local TITLE_X = 64
local function Title(f)
	local tc = f.TitleContainer
	local title = Usable(tc) and tc.TitleText
	if Kind(title) ~= "FontString" then return end
	title:ClearAllPoints()
	title:SetPoint("TOPLEFT", f, "TOPLEFT", TITLE_X, -(Kit.TITLE_TOP or 6))
	title:SetJustifyH("LEFT")
	if title.SetWordWrap then title:SetWordWrap(false) end
	local v = f.Version
	if Usable(v) then
		v:ClearAllPoints()
		v:SetPoint("LEFT", title, "RIGHT", 10, 0)
	end
end

-- The X: lit while the game's secure button lies over it (its click is the game window's close).
local function CloseLit(btn)
	if not Usable(btn) then return end
	local x
	for i = 1, btn:GetNumRegions() do
		local r = select(i, btn:GetRegions())
		if IsTexture(r) and r:GetDrawLayer() == "OVERLAY" and r:GetAlpha() > 0 then x = r end
	end
	if not x then return end
	ns.HookOnce(btn, "LockHighlight", function()
		if On() then x:SetVertexColor(ns.AccentOf(KEY)) end
	end, KEY)
	ns.HookOnce(btn, "UnlockHighlight", function()
		if not On() then return end
		local c = ns.Colors().LABEL
		if c then x:SetVertexColor(c[1], c[2], c[3]) end
	end, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- What Guildy makes on the screen itself (menu, floating panels, dialogs). Guildy keeps all its
-- functions in its own namespace (nothing of it is reachable from _G but GuildyConfirm and
-- GuildyCopyBox, named once they exist, and the frames it names), so these are recognized by what
-- they are, never by being new alone: each by Guildy's own parts on it.
-- ---------------------------------------------------------------------------------------------

local found = {}           -- kind -> true, once dressed
local KINDS = 11           -- menu, card, score, item, worn, confirm, copy, invite, fame, note, noteEdit
local foundCount = 0
local function Found(kind)
	if found[kind] then return end
	found[kind] = true
	foundCount = foundCount + 1
end

-- Whether frame f's first anchor lies in one of Guildy's windows.
local function AnchoredIn(f)
	local _, rel = f:GetPoint(1)
	local main, options = _G.GuildyFrame, _G.GuildyOptions
	for _ = 1, 40 do
		if not Usable(rel) then return false end
		if rel == main or rel == options then return true end
		rel = rel:GetParent()
	end
	return false
end

local function MouseOnGuildy()
	local main, options = _G.GuildyFrame, _G.GuildyOptions
	return (Usable(main) and main:IsVisible() and main:IsMouseOver())
		or (Usable(options) and options:IsVisible() and options:IsMouseOver()) or false
end

local function Spot(f)
	if not Usable(f) or (f.IsProtected and f:IsProtected()) then return end
	local name = f:GetName()
	if name == "GuildyOptions" then Options(f) return end
	if name == "GuildyItemTooltip" or name == "GuildyWornTooltip" then
		if type(f.Shadow) == "table" then
			Floating(f)
			Found(name)
		end
		return
	end
	if name or Kind(f) ~= "Frame" or shelled[f] or not BackdropOf(f) then return end
	if type(f.Shadow) == "table" then
		-- W.FloatingPanel: the member card (its pools of words, icons and rules) or the score panel.
		if type(f.texts) == "table" and type(f.rules) == "table" then
			Floating(f)
			Found("card")
		elseif Usable(f.Marker) and type(f.Notes) == "table" then
			Floating(f)
			Found("score")
		end
	elseif type(f.buttons) == "table" and f:GetFrameStrata() == "FULLSCREEN_DIALOG" then
		-- W.OpenMenu's shared menu, opened from Guildy's window (from a control in it, or at the
		-- mouse over it: a name's right-click).
		if f:IsShown() and (AnchoredIn(f) or MouseOnGuildy()) then
			Menu(f)
			Found("menu")
		end
	elseif f == rawget(_G, "GuildyConfirm") then
		Dialog(f)
		Found("confirm")
	elseif f == rawget(_G, "GuildyCopyBox") then
		Dialog(f)
		Found("copy")
	elseif type(f.Buttons) == "table" and Kind(f.Title) == "FontString" and f:GetFrameStrata() == "DIALOG" then
		-- The invite suggestions beside the game's invite popup.
		Dialog(f)
		Found("invite")
	elseif Kind(f.Search) == "EditBox" and Usable(f.ListBox) and Usable(f.List) then
		-- The Hall of Fame's tile and title list.
		Dialog(f)
		Found("fame")
	elseif not f:IsMouseEnabled() and f:GetNumChildren() == 0 and f.IsIgnoringParentAlpha and f:IsIgnoringParentAlpha() then
		-- Guildy's box under the game's note dialog, or under that dialog's text box.
		local _, rel = f:GetPoint(1)
		local relName = Usable(rel) and rel:GetName()
		if Kind(rel) == "EditBox" then
			NoteBacking(f, "input")
			Found("noteEdit")
		elseif type(relName) == "string" and string.find(relName, "^StaticPopup%d+$") then
			NoteBacking(f, "window")
			Found("note")
		end
	end
end

local lastScreen
local function SpotFrom(from, ...)
	for i = from, select("#", ...) do Guard(Spot, (select(i, ...))) end
end

-- The screen's children made since the last look (a few before it too: one taken off the screen
-- meanwhile shifts the rest).
local function LookNew()
	if foundCount >= KINDS then return end
	local n = UIParent:GetNumChildren()
	if not lastScreen then lastScreen = n end
	if n > lastScreen then SpotFrom(math.max(1, lastScreen - 2), UIParent:GetChildren()) end
	lastScreen = n
end

-- The shared menu, made earlier (while Guildy's window wasn't open) and opened from it now. The
-- screen's children are taken once per look and walked as they come (taking them again for each
-- one grew with the square of their number, on every click until the menu was found).
local function MenuAmong(...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		if Usable(c) and type(rawget(c, "buttons")) == "table" and c:IsShown() then Guard(Spot, c) end
	end
end

local function LookMenu()
	if found.menu then return end
	MenuAmong(UIParent:GetChildren())
end

-- Each tab's (and page's) panel, dressed the moment it's shown: Guildy builds it then. A page
-- (the character page) is made the first time it's opened, as a new child of the content area, and
-- shown right after the tab's panel is hidden: looked for in that hide.
local hookedPanel = setmetatable({}, { __mode = "k" })
local panelDone = setmetatable({}, { __mode = "k" })
local Panels

local function PanelShown(p)
	if not On() then return end
	Queue(p, panelDone[p] and "again" or "first")
	panelDone[p] = true
	-- (The character page makes the item tooltips with itself.)
	for _, name in ipairs({ "GuildyItemTooltip", "GuildyWornTooltip" }) do
		local tip = _G[name]
		if Usable(tip) and not found[name] then Guard(Spot, tip) end
	end
end

local function PanelHidden()
	local main = _G.GuildyFrame
	if On() and Usable(main) then Panels(main) end
end

function Panels(f)
	local content = f.Content
	if not Usable(content) then return end
	for i = 1, content:GetNumChildren() do
		local p = select(i, content:GetChildren())
		if Usable(p) and not hookedPanel[p] then
			hookedPanel[p] = true
			ns.ScriptOnce(p, "OnShow", PanelShown, KEY)
			ns.ScriptOnce(p, "OnHide", PanelHidden, KEY)
			if p:IsShown() then PanelShown(p) end
		end
	end
end

-- Every click on a control of Guildy's: what it opens or rebuilds is dressed in the same frame (a
-- walk of the shown window; Guildy's own frames on the screen looked at right away).
function QueueMain()
	if not On() then return end
	Queue(_G.GuildyFrame, "again")
	local o = _G.GuildyOptions
	if Usable(o) and o:IsShown() then Queue(o, "again") end
	if Usable(o) and not shelled[o] and Kit then Guard(Options, o) end
	Guard(LookNew)
	Guard(LookMenu)
end

-- The fallback, while Guildy's window or options are open and some of its frames haven't been
-- seen yet: one look at the screen's new children in the next update (still before it's drawn)
-- after each thing that makes them: a mouse button let go anywhere (a name's right-click in the
-- chat, a menu's row, a dialog's button) and a hover on one of Guildy's own frames (the member
-- card and the score panel are made by their owner's OnEnter). Nothing runs in between; the mouse
-- event is listened to only while a window is open, and never again once all are found.
local function Spotted()
	local main, options = _G.GuildyFrame, _G.GuildyOptions
	local open = (Usable(main) and main:IsVisible()) or (Usable(options) and options:IsVisible())
	return open and Kit and On() and foundCount < KINDS
end

local spotter = CreateFrame("Frame")
spotter:Hide()
spotter:SetScript("OnUpdate", function(self)
	self:Hide()
	if Spotted() then Guard(LookNew) end
end)

local clicks = CreateFrame("Frame")
local listening = false
local function Listen(on)
	if on == listening then return end
	listening = on
	if on then clicks:RegisterEvent("GLOBAL_MOUSE_UP") else clicks:UnregisterEvent("GLOBAL_MOUSE_UP") end
end
clicks:SetScript("OnEvent", function()
	if Spotted() then spotter:Show() else Listen(false) end
end)

local function Spotting()
	if foundCount >= KINDS then
		Listen(false)
		return
	end
	Listen(true)
	spotter:Show()
end

-- A hover on one of Guildy's frames with an OnEnter of its own: looked at right after, while the
-- member card or the score panel is still to be found (hooked as frames are first seen). Run after
-- the owner's own OnEnter, so what it made is there already.
local hoverHooked = setmetatable({}, { __mode = "k" })
local function HoverLook()
	if not (found.card and found.score) and Spotted() then Guard(LookNew) end
end
function HoverHook(f)
	if hoverHooked[f] or (found.card and found.score) then return end
	if (f.IsProtected and f:IsProtected()) or not (f.HasScript and f:HasScript("OnEnter")) then return end
	if type(f:GetScript("OnEnter")) ~= "function" then return end
	hoverHooked[f] = true
	-- (Plain HookScript: ns.ScriptOnce keeps one OnEnter hook per pack, and tabs and segmented
	-- buttons already have theirs.)
	f:HookScript("OnEnter", HoverLook)
end

-- (Guildy hides itself when it shows the game's window in its place, and makes or places that
-- window's tab right after: looked for in the next update, still before it's drawn.)
local returnLook = CreateFrame("Frame")
returnLook:Hide()
returnLook:SetScript("OnUpdate", function(self)
	self:Hide()
	Guard(ReturnTab)
end)
local function MainHidden()
	if not On() then return end
	HostClosed()
	returnLook:Show()
	if not Spotted() then Listen(false) end
end

-- The bottom tabs hang below the window: a panel behind them (the window's look) from its left
-- edge to just past the last tab, tucked under its bottom edge, gone with the tabs (no guild).
local function TabShelf(f, first, last)
	if not (Usable(first) and Usable(last)) then return end
	local shelf = CreateFrame("Frame", nil, f)
	shelf:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, 2)
	shelf:SetPoint("BOTTOMRIGHT", last, "BOTTOMRIGHT", 8, -2)
	shelf:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
	shelf:EnableMouse(false)
	skip[shelf] = true
	ns.Shell(shelf, nil, KEY)
	shelf:SetShown(first:IsShown())
	-- (Plain HookScript: TextTab already hooks this tab's OnShow through ns.ScriptOnce.)
	first:HookScript("OnShow", function() shelf:Show() end)
	first:HookScript("OnHide", function() shelf:Hide() end)
end

local function Window(f)
	if not Kit or not Usable(f) or shelled[f] then return end
	shelled[f] = true
	Files()
	HoldHost()
	Own(f, function()
		Kit.Window(f)
		ns.Shell(f, { window = true }, KEY)
	end)
	Title(f)
	if Controls() then CloseLit(f.CloseButton) end
	SideTab(f.GuildTab)
	SideTab(f.CommunitiesTab)
	local i = 1
	while Usable(_G["GuildyFrameTab" .. i]) do
		TextTab(_G["GuildyFrameTab" .. i], 16)
		i = i + 1
	end
	if Controls() and i > 1 then TabShelf(f, _G.GuildyFrameTab1, _G["GuildyFrameTab" .. (i - 1)]) end
	local cog = f.OptionsButton
	if Usable(cog) then
		Guard(PanelButton, cog)
		-- (Plain HookScript: PanelButton already hooks its OnClick through ns.ScriptOnce.)
		cog:HookScript("OnClick", OptionsNow)
	end
	Panels(f)
	ns.ScriptOnce(f, "OnShow", function()
		if not On() then return end
		HoldHost()
		Panels(f)
		Queue(f, "again")
		Spotting()
	end, KEY)
	ns.ScriptOnce(f, "OnHide", MainHidden, KEY)
	Queue(f, "first")
	Spotting()
end

-- ---------------------------------------------------------------------------------------------
-- The level-60 banner (GuildyDing): built on the first one, shown with or without the window
-- ---------------------------------------------------------------------------------------------

-- Its four hairlines fade out from the seal (Guildy's alphas, by their order).
local DING_FADES = { { 0, 1 }, { 1, 0 }, { 0, 0.6 }, { 0.6, 0 } }

local function DingPaint(b)
	if not On() then return end
	local r, g, bl = ns.AccentOf(KEY)
	local make = _G.CreateColor
	if type(b.Lines) == "table" and type(make) == "function" then
		for i, line in ipairs(b.Lines) do
			local f = DING_FADES[i]
			if IsTexture(line) and f then
				line:SetColorTexture(1, 1, 1, 1)
				pcall(line.SetGradient, line, "HORIZONTAL", make(r, g, bl, f[1]), make(r, g, bl, f[2]))
			end
		end
	end
	-- The seal: its gold square (the lower one of its two) in the accent, the dark inside kept.
	local seal = b.Seal
	if Usable(seal) then
		for i = 1, seal:GetNumRegions() do
			local t = select(i, seal:GetRegions())
			if IsTexture(t) then
				local _, sub = t:GetDrawLayer()
				if sub == 0 then t:SetColorTexture(r, g, bl, 1) end
			end
		end
	end
	for _, fs in ipairs({ b.Level, b.Text, b.Name }) do Text(fs) end
end

local dinged
local function Ding(b)
	if dinged then return end
	dinged = b
	ns.ScriptOnce(b, "OnShow", function() Guard(DingPaint, b) end, KEY)
	DingPaint(b)
end

-- ---------------------------------------------------------------------------------------------

-- A style change: the accent on this pack's pieces, the inks on Guildy's words and art, the tabs'
-- font, and every button measured again in the new font (and the segmented rows placed again).
local function Repaint()
	if not Kit or not On() then return end
	local r, g, b = ns.AccentOf(KEY)
	for tex, alpha in pairs(accents) do ns.FillAccent(tex, alpha, nil, KEY) end
	for box in pairs(picked) do ns.LightShell(boxShell[box], { r, g, b }, KEY) end
	local colors = ns.Colors()
	for fs, name in pairs(inked) do
		local c = colors[name]
		if c then
			inking = true
			fs:SetTextColor(c[1], c[2], c[3])
			inking = false
		end
	end
	for tex, name in pairs(tinted) do
		local c = colors[name]
		if c then tex:SetVertexColor(c[1], c[2], c[3]) end
	end
	if dinged then DingPaint(dinged) end
	TabFont()
	for tab, t in pairs(textTabs) do
		TabWords(tab)
		FitTab(tab, t[1], t[2])
	end
	for btn in pairs(seenButton) do Refit(btn, true) end
	for group in pairs(groups) do
		SegLayout(group)
		Guard(SegPaint, group)
	end
end

local function RepaintSoon()
	-- (After DaylightUI has put its own new look on, which this follows.)
	ns.Queue("Guildy:repaint", Repaint, KEY)
end

local function Now()
	local f, K = _G.GuildyFrame, ns.Kit
	if K and Usable(f) and On() then
		Kit = K
		Guard(Window, f)
		HoldHost()
	end
end

-- The game's guild window, opened by its key or button: Guildy builds and shows its own inside it.
local function GuildOpened()
	ns.WatchNow()
	Now()
end

ns.Pack(KEY, "Guildy", function(K)
	Kit = K
	-- /guildy (with the window open it brings Guildy back over the game's).
	if type(_G.SlashCmdList) == "table" and type(_G.SlashCmdList.GUILDY) == "function" then
		ns.HookOnce(_G.SlashCmdList, "GUILDY", Now, KEY)
	end
	-- Built and shown inside the game's guild window's OnShow: from the game's own open calls (J,
	-- the guild button; post-hooks on its global functions), and a watch by name for the rest (the
	-- guild banker, where Guildy opens alone on an event).
	for _, name in ipairs({ "ToggleGuildFrame", "ToggleCommunitiesFrame" }) do
		if type(_G[name]) == "function" then ns.HookOnce(nil, name, GuildOpened, KEY) end
	end
	ns.Watch(KEY, "GuildyFrame", function(f, K2)
		Kit = K2
		Window(f)
	end)
	ns.Watch(KEY, "GuildyDing", function(b, K2)
		Kit = K2
		Ding(b)
	end)
	-- The game's guild window loads on demand: at 0 from the start, before its first open.
	local function HostLoaded()
		local host = _G.CommunitiesFrame
		if On() and Usable(host) and not host:IsShown() then Clear(host) end
	end
	local loaded = CreateFrame("Frame")
	loaded:RegisterEvent("ADDON_LOADED")
	loaded:SetScript("OnEvent", function(self, _, name)
		if name ~= "Blizzard_Communities" then return end
		self:UnregisterEvent("ADDON_LOADED")
		Guard(HostLoaded)
	end)
	Guard(HostLoaded)
	ns.me.On("StyleChanged", RepaintSoon)
	ns.me.On("SettingChanged", function(scope, path)
		if scope == "DaylightAddonSkins" and type(path) == "string"
			and string.find(path, "look." .. KEY .. ".", 1, true) == 1 then
			RepaintSoon()
		end
	end)
end, CAPS)
