-- Game windows: the game's own windows and popups that DaylightUI's Window Skins (and this plugin's
-- BlizzardSettings pack) leave as the game draws them, in the same look through the Kit. Built
-- against the client's own interface code (wow-ui-source, branch "forever"; this client loads the
-- Mainline files plus its own Camelot overrides), so every name and key below is the game's.
--   Ready check (ReadyCheckListenerFrame), role check (RolePollPopup), the "Return to graveyard"
--     button (GhostFrame), quick keybind (QuickKeybindFrame): shown by the game itself, sometimes
--     in a fight, so dressed ahead of time and quietly (see Taint below).
--   Color picker (ColorPickerFrame; the wheel, value and alpha bars and the two swatches stay) and
--     the opacity panel (OpacityFrame: the zone map's and the chat windows' "Opacity").
--   Alert toasts other than DaylightUI's loot and money toasts: achievements, criteria, recipes,
--     honor, pets / mounts / toys, dungeon and scenario completion, guild and the rest the game
--     sends through AlertFrame_ShowNewAlert. Icons, an item's quality ring, the achievement
--     shield and points, a guild's tabard and a dig site's race stay.
--   Zone map (Shift-M): a DaylightUI border just above the map, its X and its tab. The map, its
--     pins and whatever other addons draw on it stay.
--   Chat settings (ChatConfigFrame: its chat-window tabs, category list, every panel's checkbox
--     rows as quiet wells, switches, the combat log's tabs, filter list, buttons, boxes,
--     dropdowns, sliders, scroll bars), the channels window (ChannelFrame: its channel list and
--     member list as rows, the picked channel in the accent) and its "new channel" popup.
--   Stopwatch, the old-style dropdown lists (DropDownList1..n; Questie's own copy is the Questie
--     pack's), queue status (QueueStatusFrame), ticket status, guild ranks (only once the game
--     has loaded it), the cooldown manager's settings and its alert editors.
--   Popups and dialogs: add friend, Battle.net invite, a friend's friends, the addon dialog,
--     community settings / invite links / avatar picker, death recap, guild invite, loot history,
--     guild rename, report player, report cheating, help, the LFG invite, the battleground
--     ready / role check / arena popups, master looter, money split (Shift-click your money),
--     the plain error dialog, the model preview, the quest details popup, party sync dialogs,
--     the abandon-instance popup, the bank's clean-up question, the quick-join role picker, the
--     icon pickers (macros, guild bank tabs, equipment sets), the battleground score and results,
--     the quest timer, the old tutorial box, the nameplate tutorial, help tips (HelpTip) and help
--     plates, the move pad, name autocomplete, the browser-settings and IME candidate boxes, the
--     LFG listing tooltip, the GM chat and survey status boxes.
-- Left alone on purpose: Edit Mode (the player's choice), the settings panel, the dungeon-ready
-- dialog and the ping tutorial (BlizzardSettings pack), everything DaylightUI dresses or replaces,
-- the cooldown manager's layout dialogs (Edit Mode's own templates), and windows whose content
-- this client never has (garrisons, covenants, Azerite, islands, Torghast, pet battles and the
-- like). Gamepad-only pieces (the input legend, the gamepad loot roll) only show with a
-- controller.
--
-- Taint: these are the game's frames. Looks only (textures, fonts, colors, the Kit's shells),
-- post-hooks only, no field of the game's written, nothing protected called. Windows the game
-- opens from its own event code (dialogs, popups, the ghost button) are dressed ahead of time
-- and quietly: nothing is hooked on the controls inside them that the game's own Show could set
-- off (Kit.Button / Kit.EditBox with a host, as DaylightUI dresses its confirm boxes), which is
-- why their checkboxes and role buttons keep the game's look. Everything else is dressed out of
-- combat. Nothing here loads a Blizzard addon.
local _, ns = ...
if not ns.ok then return end

local KEY = "Blizzard"
ns.Target(KEY, "Game windows", { controls = true })

local Usable, Guard = ns.Usable, ns.Guard
local ipairs, pairs, type, select = ipairs, pairs, type, select

local dressed = setmetatable({}, { __mode = "k" })   -- frames and controls of ours already done

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end

local function Kind(x)
	if not Usable(x) then return nil end
	return x:GetObjectType()
end

local function IsTexture(x) return Kind(x) == "Texture" end

-- Kit.Font on one string or edit box, unless the game hasn't given it a font size yet (a size of 0
-- makes "Invalid font height" errors, here and in DaylightUI's later repaint).
local function FontOf(Kit, fs)
	local k = Kind(fs)
	if k ~= "FontString" and k ~= "EditBox" then return end
	local ok, _, size = pcall(fs.GetFont, fs)
	if ok and type(size) == "number" and size > 0 then Kit.Font(fs) end
end

-- The player's font on every string a frame holds itself (not its children), sizes kept.
-- (Dressing time only, never on a refresh: the table made here is thrown away once.)
local function Fonts(Kit, frame, light)
	if not Usable(frame) or not frame.GetRegions then return end
	for _, r in ipairs({ frame:GetRegions() }) do
		-- (A string with no font size yet is left alone: the game hasn't set it up.)
		local _, size = r.GetFont and r:GetFont()
		if Kind(r) == "FontString" and type(size) == "number" and size > 0 then
			FontOf(Kit, r)
			if light then Kit.Light(r) end
		end
	end
end

-- Fonts and the game's gold / dark text in DaylightUI's inks, the frame and its children to depth.
local function Words(Kit, frame, depth)
	if not Usable(frame) or not frame.GetRegions then return end
	Fonts(Kit, frame)
	Kit.InkGameText(frame)
	if (depth or 0) > 0 and frame.GetChildren then
		for _, c in ipairs({ frame:GetChildren() }) do Words(Kit, c, depth - 1) end
	end
end

-- A dialog's own art the window look doesn't take off by itself: the dialog border frame
-- (DialogBorderTemplate and its kin, art only), a translucent dialog's BG frame, the header's gold
-- plate (its words stay), an old backdrop and a NineSlice.
local function DialogArt(Kit, f)
	if Kind(f.Border) == "Frame" then Kit.Hide(f.Border) end
	if Kind(f.BG) == "Frame" then Kit.Hide(f.BG) end
	if Usable(f.Header) then Kit.Strip(f.Header) end
	if Usable(f.NineSlice) then Kit.Hide(f.NineSlice) end
	Kit.Backdrop(f)
end

-- A game text button (UIPanelButtonTemplate and its kin: three pieces of art; or the dialog
-- button: one art texture under its words).
local function TextButton(b)
	if not Usable(b) or not b.GetObjectType or b:GetObjectType() ~= "Button" then return false end
	if IsTexture(b.Left) and IsTexture(b.Right) then return true end
	local name = b:GetName()
	if name and IsTexture(_G[name .. "Left"]) and IsTexture(_G[name .. "Right"]) then return true end
	local fs = b.GetFontString and b:GetFontString()
	local text = Kind(fs) == "FontString" and fs:GetText()
	if type(text) ~= "string" or text == "" or not b.GetNormalTexture or not b:GetNormalTexture() then return false end
	local w, h = b:GetWidth(), b:GetHeight()
	return type(w) == "number" and type(h) == "number" and h > 0 and w >= h * 2
end

-- ---------------------------------------------------------------------------------------------
-- Windows
-- ---------------------------------------------------------------------------------------------

local QUIET = { quiet = true }

local function TitleOf(f)
	local tc = f.TitleContainer
	return (Usable(tc) and tc.TitleText) or f.TitleText or f.Title
		or (Usable(f.Header) and (f.Header.Text or f.Header.Title))
		or (f.GetName and f:GetName() and _G[f:GetName() .. "Title"]) or nil
end

-- A window shell with nothing hooked on the window: its art stripped (keep = textures that stay),
-- DaylightUI's window shell, the title in the value ink on the left of the title row. For the
-- windows Kit.Window doesn't suit: a "Close" text button where Kit.Window looks for the X, a
-- minimize button, art that must stay, or a window the game shows from its own event code.
local function ShellWindow(Kit, f, keep, quiet)
	if not Usable(f) or dressed[f] then return end
	dressed[f] = true
	Kit.Strip(f, keep)
	DialogArt(Kit, f)
	-- (Always quiet: no script on the shell, which would run inside the game's own Show.)
	Kit.Shell(f, "window", QUIET)
	if Usable(f.Inset) then Kit.Inset(f.Inset) end
	local title = TitleOf(f)
	if Kind(title) == "FontString" then
		FontOf(Kit, title)
		Kit.Light(title, ns.Colors().VALUE)
		if title:GetParent() == f or title:GetParent() == f.TitleContainer then Kit.Title(f, title) end
	end
end

-- Whether a window's CloseButton is a text button ("Close") rather than the X Kit.Window expects.
local function TextClose(f)
	return TextButton(f.CloseButton)
end

-- The usual window: Kit.Window (strip, shell, title, X, fade), or the plain shell when its
-- CloseButton is a text button.
local function Window(Kit, f, opts)
	if TextClose(f) then
		ShellWindow(Kit, f, nil, opts and opts.quiet)
	else
		Kit.Window(f, opts)
	end
	DialogArt(Kit, f)
end

-- ---------------------------------------------------------------------------------------------
-- Controls the Kit's walk doesn't know
-- ---------------------------------------------------------------------------------------------

-- Old-style dropdowns (UIDropDownMenuTemplate: a frame with Left / Middle / Right art, Text and an
-- arrow Button; addons still make them): the art off, an input box of the Kit's round the part the
-- art drew (from the frame's left past the art's margin to the arrow's right edge, as tall as the
-- arrow), the arrow a bare chevron, the box lit on hover.
local THREE = { "Left", "Middle", "Right" }
-- Frames already found not to be one (a frame's template parts are there from its making): every
-- walk hands this every frame it passes, and a named one cost three new name strings each time.
local notDropdown = setmetatable({}, { __mode = "k" })

local function OldDropdown(Kit, dd)
	if dressed[dd] or notDropdown[dd] or Kind(dd) ~= "Frame" then return end
	local name = dd:GetName()
	local btn = dd.Button or (name and _G[name .. "Button"])
	local text = dd.Text or (name and _G[name .. "Text"])
	local left = dd.Left or (name and _G[name .. "Left"])
	if not (Usable(btn) and btn.GetNormalTexture) or Kind(text) ~= "FontString" or not IsTexture(left) then
		notDropdown[dd] = true
		return
	end
	dressed[dd] = true
	for _, k in ipairs(THREE) do
		Kit.Hide(dd[k])
		if name then Kit.Hide(_G[name .. k]) end
	end
	local box = CreateFrame("Frame", nil, dd)
	box:SetPoint("TOP", btn, "TOP", 0, 0)
	box:SetPoint("BOTTOM", btn, "BOTTOM", 0, 0)
	box:SetPoint("LEFT", dd, "LEFT", 16, 0)
	box:SetPoint("RIGHT", btn, "RIGHT", 0, 0)
	-- Under the dropdown's own text (a child below its parent's level).
	box:SetFrameLevel(math.max(0, dd:GetFrameLevel() - 1))
	box:EnableMouse(false)
	local s = Kit.Shell(box, "input")
	Kit.BareButton(btn, "down")
	btn:HookScript("OnEnter", function() Kit.Paint(s, Kit.ROW_HOVER) end)
	btn:HookScript("OnLeave", function() Kit.Paint(s, nil) end)
	FontOf(Kit, text)
	Kit.Light(text)
end

-- A slider in the scroll bars' look: the game's track art off (its pieces, backdrop or NineSlice),
-- a faint line along it, the thumb a pill (upright on a vertical slider, a short bar across a
-- horizontal one), brighter under the mouse; its words in the player's font. The stepper arrows
-- of MinimalSliderWithSteppersTemplate become bare chevrons.
local SLIDER_THUMB, SLIDER_KNOB_W, SLIDER_KNOB_H = 18, 6, 16
local function Slider(Kit, s)
	if not Usable(s) or dressed[s] then return end
	dressed[s] = true
	local S = Kit.SCROLL
	local thumb = s.GetThumbTexture and s:GetThumbTexture()
	Kit.Strip(s, IsTexture(thumb) and { [thumb] = true } or nil)
	Kit.Backdrop(s)
	Kit.Hide(s.NineSlice)
	local vertical = s.GetOrientation and s:GetOrientation() == "VERTICAL"
	local line = s:CreateTexture(nil, "BACKGROUND")
	line:SetColorTexture(1, 1, 1, 1)
	local c = S.track
	line:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
	if vertical then
		line:SetWidth(S.width)
		line:SetPoint("TOP", s, "TOP", 0, 0)
		line:SetPoint("BOTTOM", s, "BOTTOM", 0, 0)
	else
		line:SetHeight(S.width)
		line:SetPoint("LEFT", s, "LEFT", 0, 0)
		line:SetPoint("RIGHT", s, "RIGHT", 0, 0)
	end
	if IsTexture(thumb) then
		Kit.ScrollThumb(s, thumb)
		if vertical then
			thumb:SetHeight(SLIDER_THUMB)
		else
			thumb:SetSize(SLIDER_KNOB_W, SLIDER_KNOB_H)
		end
		s:HookScript("OnEnter", function()
			local h = S.thumbHover
			thumb:SetVertexColor(h[1], h[2], h[3], h[4] or 1)
		end)
		s:HookScript("OnLeave", function()
			local t = S.thumb
			thumb:SetVertexColor(t[1], t[2], t[3], t[4] or 1)
		end)
	end
	Fonts(Kit, s, true)
	local holder = s:GetParent()
	if Usable(holder) and holder.Slider == s then
		if Usable(holder.Back) then Kit.BareButton(holder.Back, "left") end
		if Usable(holder.Forward) then Kit.BareButton(holder.Forward, "right") end
		Words(Kit, holder, 0)
	end
end

-- What the walk hands every frame it passes (not the controls it dresses itself).
local function Each(Kit, frame)
	local k = Kind(frame)
	if k == "Slider" then
		if Controls() then Slider(Kit, frame) end
	elseif k == "Frame" then
		OldDropdown(Kit, frame)
	end
end

-- ---------------------------------------------------------------------------------------------
-- A window's walk: Kit.Auto over it once (hidden pages too), then over its shown parts again on
-- every show and whenever one of its pages is shown (next frame, once, out of combat; a walk still
-- going is waited for rather than dropped). after(f, Kit) runs after each walk; each(frame) on
-- every frame the walk passes, after this pack's own.
-- ---------------------------------------------------------------------------------------------

local function Walk(Kit, f, opts, after, each)
	opts = opts or {}
	local first, again = {}, {}
	for k, v in pairs(opts) do
		first[k] = v
		again[k] = v
	end
	again.shownOnly = true
	local function visit(frame)
		Each(Kit, frame)
		if each then each(frame) end
	end
	first.each, again.each = visit, visit
	local queued, waiting = false, false
	local queue
	local function run()
		queued = false
		if not Usable(f) or not f:IsShown() or not On() then return end
		if InCombatLockdown() then
			if not waiting then
				waiting = true
				ns.OutOfCombat(function() waiting = false queue() end)
			end
			return
		end
		if Kit.Walking(f) then
			queue()
			return
		end
		Kit.Auto(f, again)
		if after then Guard(after, f, Kit) end
	end
	queue = function()
		if queued then return end
		queued = true
		C_Timer.After(0, run)
	end
	first.onPage, again.onPage = queue, queue
	Kit.Auto(f, first)
	if after then Guard(after, f, Kit) end
	f:HookScript("OnShow", queue)
	return queue
end

-- The usual window and its walk.
local function Panel(Kit, f, walkOpts, after, each)
	Window(Kit, f)
	if Controls() then return Walk(Kit, f, walkOpts, after, each) end
end

-- Controls with nothing of ours hooked at all, for windows the game shows from its own (secure)
-- code. Any script of ours that runs inside the game's Show, Hide, Enable or Disable of a frame
-- taints what the game does next in that call: a help tip shown from an action button's update
-- did exactly that and got the action bars' SetShown blocked. So: the game's art faded, the Kit's
-- lite control / input look (no scripts on it), a hover wash on the HIGHLIGHT layer (shown by the
-- game itself), the player's font. No pressed or focused look, the price of being silent.
local THREE_ART = { "Left", "Middle", "Right", "Center", "Mid" }
local BUTTON_ART = { "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }

local function StaticButton(Kit, b)
	if not Usable(b) or dressed[b] then return end
	dressed[b] = true
	for _, get in ipairs(BUTTON_ART) do
		local t = b[get] and b[get](b)
		if IsTexture(t) then Kit.Hide(t) end
	end
	local name = b:GetName()
	for _, k in ipairs(THREE_ART) do
		if IsTexture(b[k]) then Kit.Hide(b[k]) end
		if name and IsTexture(_G[name .. k]) then Kit.Hide(_G[name .. k]) end
	end
	Kit.Shell(b, "control")
	Kit.HoverWash(b)
	local fs = b.GetFontString and b:GetFontString()
	if Kind(fs) == "FontString" then FontOf(Kit, fs) end
end

local function StaticEditBox(Kit, eb)
	if Kind(eb) ~= "EditBox" or dressed[eb] then return end
	dressed[eb] = true
	local name = eb:GetName()
	for _, k in ipairs(THREE_ART) do
		if IsTexture(eb[k]) then Kit.Hide(eb[k]) end
		if name and IsTexture(_G[name .. k]) then Kit.Hide(_G[name .. k]) end
	end
	if IsTexture(eb.Background) then Kit.Hide(eb.Background) end
	Kit.Shell(eb, "input")
	FontOf(Kit, eb)
	if Kind(eb.Instructions) == "FontString" then FontOf(Kit, eb.Instructions) end
	if IsTexture(eb.searchIcon) then
		local c = ns.Colors().OFF or { 0.5, 0.5, 0.5 }
		eb.searchIcon:SetVertexColor(c[1], c[2], c[3])
	end
	-- (Kit.Close hooks the mouse only: enter, leave, press, after a click.)
	if Usable(eb.clearButton) then Kit.Close(eb.clearButton) end
end

-- A dialog the game shows from its own event code (and so maybe in a fight): the shell with
-- nothing hooked on the dialog or its insides; its text buttons and edit boxes in the silent look
-- above; its words in DaylightUI's inks. Role buttons, checkboxes and other art buttons keep the
-- game's look. keep: textures of the dialog's own that stay (a background picture that means
-- something).
local QUIET_DEPTH = 4
local function QuietControls(Kit, host, frame, depth, skip)
	for _, c in ipairs({ frame:GetChildren() }) do
		if Usable(c) and not (skip and skip[c]) then
			local k = c:GetObjectType()
			if k == "Button" and TextButton(c) then
				StaticButton(Kit, c)
			elseif k == "EditBox" then
				local name = c:GetName()
				if IsTexture(c.Left) or (name and IsTexture(_G[name .. "Left"])) then StaticEditBox(Kit, c) end
			elseif depth > 0 and (k == "Frame" or k == "Button") then
				QuietControls(Kit, host, c, depth - 1, skip)
			end
		end
	end
end

-- A dialog's corner button: the X (Kit.Close), or a minimize / hide button (UIPanelHideButton, the
-- red "MiniCondense" art) as a bare down chevron.
local function CornerButton(Kit, btn)
	if not Usable(btn) or TextButton(btn) then return end
	local tex = btn.GetNormalTexture and btn:GetNormalTexture()
	local art = IsTexture(tex) and ((tex.GetAtlas and tex:GetAtlas()) or tex:GetTexture())
	art = type(art) == "string" and string.lower(art) or ""
	if string.find(art, "minicondense", 1, true) or string.find(art, "hidebutton", 1, true) then
		Kit.BareButton(btn, "down")
	else
		Kit.Close(btn)
	end
end

local function Quiet(Kit, f, keep, skip)
	if not Usable(f) then return end
	ShellWindow(Kit, f, keep, true)
	local name = f:GetName()
	CornerButton(Kit, f.CloseButton or (name and _G[name .. "CloseButton"]))
	CornerButton(Kit, f.minimizeButton)
	if Controls() then QuietControls(Kit, f, f, QUIET_DEPTH, skip) end
	Words(Kit, f, 3)
end

-- A tooltip-like panel: its tooltip border (NineSlice or backdrop) off, a window shell.
local function TipPanel(Kit, f)
	if not Usable(f) or dressed[f] then return end
	dressed[f] = true
	Kit.Hide(f.NineSlice)
	Kit.Backdrop(f)
	Kit.Strip(f)
	Kit.Shell(f, "window", QUIET)
end

-- ---------------------------------------------------------------------------------------------
-- The windows, each dressed once when it exists. Always-loaded ones at login; the rest when their
-- Blizzard addon loads.
-- ---------------------------------------------------------------------------------------------

local entries = {}
local left = 0

-- get = a global frame name, or a function returning the thing to dress (nil while it isn't there).
local function Entry(get, fn)
	entries[#entries + 1] = { get = get, fn = fn }
	left = left + 1
end

local function TryAll()
	local Kit = ns.Kit
	if left == 0 or not Kit or not On() then return end
	for i = 1, #entries do
		local e = entries[i]
		if not e.done then
			local target
			if type(e.get) == "string" then
				target = _G[e.get]
			else
				local ok, got = pcall(e.get)
				target = ok and got or nil
			end
			if target ~= nil and (type(target) ~= "table" or Usable(target)) then
				e.done = true
				left = left - 1
				Guard(e.fn, target, Kit)
			end
		end
	end
end

-- A dialog dressed quietly, by its global name.
local function QuietEntry(name, keepKeys)
	Entry(name, function(f, Kit)
		local keep
		if keepKeys then
			keep = {}
			for _, k in ipairs(keepKeys) do
				local t = f[k] or _G[name .. k]
				if IsTexture(t) then keep[t] = true end
			end
		end
		Quiet(Kit, f, keep)
	end)
end

-- A window and its walk, by its global name.
local function PanelEntry(name, walkOpts)
	Entry(name, function(f, Kit) Panel(Kit, f, walkOpts) end)
end

-- Ready check -----------------------------------------------------------------------------------
-- ReadyCheckFrame holds ReadyCheckListenerFrame (all its art: Bg, NineSlice, the initiator's
-- portrait, the title row; Text; YesButton / NoButton).

Entry("ReadyCheckFrame", function(frame, Kit)
	local f = _G.ReadyCheckListenerFrame
	if not Usable(f) then f = frame end
	-- (Silent: the game shows it from its event code, in a fight too.)
	ShellWindow(Kit, f)
	if Controls() then
		for _, b in ipairs({ f.YesButton or _G.ReadyCheckFrameYesButton, f.NoButton or _G.ReadyCheckFrameNoButton }) do
			StaticButton(Kit, b)
		end
	end
	Words(Kit, f, 1)
end)

-- Color picker and the opacity panel ------------------------------------------------------------

Entry("ColorPickerFrame", function(f, Kit)
	Kit.Window(f)
	DialogArt(Kit, f)
	if not Controls() then return end
	local content = Usable(f.Content) and f.Content or f
	local skip = {}
	-- The wheel with its value and alpha bars (a ColorSelect): the picker itself.
	if Usable(content.ColorPicker) then skip[content.ColorPicker] = true end
	local hex = content.HexBox
	if Kind(hex) == "EditBox" then
		Kit.EditBox(hex)
		skip[hex] = true
		if Kind(hex.Hash) == "FontString" then
			FontOf(Kit, hex.Hash)
			Kit.Light(hex.Hash)
		end
	end
	Walk(Kit, f, { skip = skip })
end)

-- OpacityFrame: a Border frame and OpacityFrameSlider, whose own strings are the title
-- (OpacityFrameSliderText, "Opacity") and the white + and -.
Entry("OpacityFrame", function(f, Kit)
	TipPanel(Kit, f)
	DialogArt(Kit, f)
	local slider = _G.OpacityFrameSlider
	if Controls() then Slider(Kit, slider) end
	local title = _G.OpacityFrameSliderText
	if Kind(title) == "FontString" then
		FontOf(Kit, title)
		Kit.Light(title, ns.Colors().VALUE)
	end
end)

-- Ghost: "Return to graveyard" ------------------------------------------------------------------
-- A UIPanelLargeSilverButton (GhostFrameLeft / Right / Middle and their highlight copies);
-- GhostFrameContentsFrame holds the icon and the gold words.

Entry("GhostFrame", function(f, Kit)
	Kit.Strip(f)
	-- Silent (nothing hooked): the game shows it from its event code.
	StaticButton(Kit, f)
	local contents = _G.GhostFrameContentsFrame
	FontOf(Kit, _G.GhostFrameContentsFrameText)
	Kit.Light(_G.GhostFrameContentsFrameText)
	Words(Kit, contents, 0)
end)

-- Alert toasts ----------------------------------------------------------------------------------

-- DaylightUI's: loot ("You received"), money; and the other item toasts, whose art is the item.
local TOAST_SKIP = { "LootAlertSystem", "MoneyWonAlertSystem", "LootUpgradeAlertSystem", "LegendaryItemAlertSystem" }
-- Kept: the picture that says what it is (icon, dungeon, tabard, dig site race, quest).
local TOAST_KEEP = { "Icon", "icon", "IconTexture", "IconOverlay", "dungeonTexture", "heroicIcon", "EmblemIcon",
	"GuildBanner", "GuildTabardBackground", "GuildTabardEmblem", "GuildTabardBorder", "DigsiteTypeTexture",
	"QuestTexture", "BonusStar", "Watermark" }
-- Erased for good (the game fades and re-shows these on every toast): banners, glows, gold rings.
local TOAST_ERASE = { "glow", "shine", "Background", "BGAtlas", "OldAchievement", "GuildBorder", "dungeonArt",
	"raidArt", "ToastBackground", "EmblemBackground", "EmblemBorder", "StandardBackground", "FancyBackground" }
local TOAST_INSET = 8   -- px the box sits inside the toast's frame (its art has a clear margin)
local ICON_PAD = 2

local function Toast(Kit, f)
	if dressed[f] then return end
	dressed[f] = true
	local keep = {}
	for _, k in ipairs(TOAST_KEEP) do
		if IsTexture(f[k]) then keep[f[k]] = true end
	end
	-- An item toast's ring is its quality (an atlas per quality): kept. Any other icon border is gold.
	local ring = f.IconBorder
	local atlas = IsTexture(ring) and ring.GetAtlas and ring:GetAtlas()
	local quality = type(atlas) == "string" and string.find(string.lower(atlas), "itemborder", 1, true) ~= nil
	if quality then keep[ring] = true end
	Kit.Strip(f, keep)
	for _, k in ipairs(TOAST_ERASE) do
		local t = f[k]
		if IsTexture(t) and not keep[t] then Kit.Erase(t) end
	end
	if IsTexture(ring) and not quality then Kit.Erase(ring) end
	if Usable(f.glowFrame) and IsTexture(f.glowFrame.glow) then Kit.Erase(f.glowFrame.glow) end
	-- An achievement's icon is a frame of its own: its gold ring and bling off, the picture outlined.
	local icon = f.Icon
	if Kind(icon) == "Frame" then
		if IsTexture(icon.Bling) then Kit.Erase(icon.Bling) end
		if IsTexture(icon.Overlay) then Kit.Erase(icon.Overlay) end
		if IsTexture(icon.Texture) then Kit.Outline(icon.Texture, ICON_PAD, "outline") end
	elseif IsTexture(icon) and not quality then
		Kit.Outline(icon, ICON_PAD, "outline")
	end
	-- (A child of the toast: it fades in and out with the game's own animation, no fade of ours.)
	Kit.Outline(f, -TOAST_INSET, "window", nil, QUIET)
	Words(Kit, f, 1)
end

Entry(function() return type(_G.AlertFrame_ShowNewAlert) == "function" or nil end, function(_, Kit)
	local skip = {}
	for _, name in ipairs(TOAST_SKIP) do
		local q = _G[name]
		if type(q) == "table" then skip[q] = true end
	end
	hooksecurefunc("AlertFrame_ShowNewAlert", function(f)
		if type(f) ~= "table" or not On() then return end
		-- (A loot toast without its queue is still a loot toast.)
		if (f.queue ~= nil and skip[f.queue]) or f.lootItem ~= nil then return end
		if not Usable(f) or not ns.Kit then return end
		Guard(Toast, ns.Kit, f)
	end)
end)

-- Zone map (Shift-M) ----------------------------------------------------------------------------
-- BattlefieldMapFrame: ScrollContainer (the map) and BorderFrame (strata HIGH, setAllPoints: the
-- gold border pieces and CloseButton). BattlefieldMapTab: Left / Middle / Right, Text, highlight.
-- The opacity setting fades BorderFrame (RefreshAlpha).

local function MapTab(Kit, tab)
	if not Usable(tab) or dressed[tab] then return end
	dressed[tab] = true
	Kit.Strip(tab)
	if tab.GetHighlightTexture then Kit.Hide(tab:GetHighlightTexture()) end
	Kit.Shell(tab, "tab")
	Kit.HoverWash(tab)
	FontOf(Kit, tab.Text)
	Kit.Light(tab.Text)
end

Entry("BattlefieldMapFrame", function(f, Kit)
	local border, canvas = f.BorderFrame, f.ScrollContainer
	local keep = {}
	if Usable(border) then keep[border] = true end
	if Usable(canvas) then keep[canvas] = true end
	Kit.Strip(f, keep)
	if Usable(border) then
		Kit.Strip(border)
		Kit.Close(border.CloseButton)
		-- DaylightUI's window edge (no ground) on a frame of ours inside BorderFrame: drawn above the
		-- map (that strata), faded with the game's opacity setting, never in the mouse's way.
		local edge = CreateFrame("Frame", nil, border)
		edge:SetAllPoints(f)
		edge:EnableMouse(false)
		Kit.Shell(edge, "window", { noBackground = true, quiet = true })
	end
	MapTab(Kit, _G.BattlefieldMapTab)
end)

-- Chat settings ---------------------------------------------------------------------------------
-- ChatConfigFrame (Border, Header): ChatConfigCategoryFrame (ConfigCategoryButtonTemplate rows),
-- ChatTabManager (a pool of ChatWindowTab: ChatTabArtTemplate tabs, picked by FCFTab_UpdateColors),
-- ChatConfigBackgroundFrame (the combat log's CombatConfigTab1..5: ChatConfigTabTemplate, the picked
-- one is the one whose panel is shown), panels of ChatConfigBoxTemplate / ChatConfigBorderBoxTemplate
-- boxes (TooltipBackdropTemplate: a NineSlice), checkbox rows (ChatConfigCheckButtonTemplate etc.),
-- color swatches, the combat filters' ScrollBox, the text-to-speech panel (sliders, dropdowns).

-- A category / filter row's highlight (blue, locked on the picked one): an accent wash.
local CATEGORY_WASH = 0.16
local function CategoryRow(btn)
	local hl = btn.Highlight
	if not IsTexture(hl) then return end
	local r, g, b = ns.AccentOf(KEY)
	hl:SetColorTexture(r, g, b, CATEGORY_WASH)
	hl:SetVertexColor(1, 1, 1)
	hl:SetBlendMode("BLEND")
end

-- The chat config's boxes (their NineSlice): quiet wells. A checkbox row gets a thin row edge;
-- a bigger box (a panel's group, the category list, the background) a darker inset.
local function ChatBox(Kit, frame)
	if dressed[frame] or not Usable(frame.NineSlice) then return end
	dressed[frame] = true
	Kit.Hide(frame.NineSlice)
	if Usable(frame.CheckButton) or Usable(frame.ColorSwatch) then
		Kit.Shell(frame, "row")
	else
		Kit.Inset(frame)
	end
end

local combatTabs = {}
local function CombatTabPicked(tab)
	local tabs = _G.COMBAT_CONFIG_TABS
	local spec = type(tabs) == "table" and tabs[tab:GetID()]
	local panel = type(spec) == "table" and _G[spec.frame]
	return Usable(panel) and panel:IsShown() == true
end

local function PaintTabs(Kit, list, picked)
	for i = 1, #list do
		local tab = list[i]
		local t = Kit.TabOf(tab)
		if t and t.Pick then t.Pick(picked(tab) == true, false) end
		-- (The game tints the words for its own art; the tab look colors them.)
		if Kind(tab.Text) == "FontString" then tab.Text:SetVertexColor(1, 1, 1) end
	end
end

local function TabArtOff(Kit, tab)
	for _, k in ipairs({ "ActiveLeft", "ActiveMiddle", "ActiveRight", "HighlightLeft", "HighlightMiddle", "HighlightRight", "glow" }) do
		if IsTexture(tab[k]) then Kit.Hide(tab[k]) end
	end
end

local function CombatTabs(Kit, skip)
	for i = 1, 8 do
		local tab = _G["CombatConfigTab" .. i]
		if not Usable(tab) then break end
		skip[tab] = true
		if not dressed[tab] then
			dressed[tab] = true
			TabArtOff(Kit, tab)
			Kit.Tab(tab, CombatTabPicked)
			combatTabs[#combatTabs + 1] = tab
		end
	end
end

local windowTabs, windowTabSet = {}, setmetatable({}, { __mode = "k" })
local function WindowTabPicked(tab)
	return IsTexture(tab.ActiveLeft) and tab.ActiveLeft:IsShown() == true
end

local function ChatWindowTabs(Kit, manager)
	if not Usable(manager) or not manager.GetChildren then return end
	for _, tab in ipairs({ manager:GetChildren() }) do
		if Usable(tab) and not windowTabSet[tab] and IsTexture(tab.ActiveLeft) then
			windowTabSet[tab] = true
			TabArtOff(Kit, tab)
			Kit.Tab(tab, WindowTabPicked)
			windowTabs[#windowTabs + 1] = tab
		end
	end
end

Entry("ChatConfigFrame", function(f, Kit)
	Kit.Window(f)
	DialogArt(Kit, f)
	local function categories()
		for i = 1, 16 do
			local btn = _G["ChatConfigCategoryFrameButton" .. i]
			if not Usable(btn) then break end
			CategoryRow(btn)
		end
	end
	categories()
	f:HookScript("OnShow", function() if On() then categories() end end)
	if not Controls() then return end
	local manager = f.ChatTabManager
	local skip = {}
	if Usable(manager) then skip[manager] = true end
	CombatTabs(Kit, skip)
	local queue = Walk(Kit, f, { skip = skip }, function()
		CombatTabs(Kit, skip)
		ChatWindowTabs(Kit, manager)
		PaintTabs(Kit, combatTabs, CombatTabPicked)
		PaintTabs(Kit, windowTabs, WindowTabPicked)
	end, function(frame)
		ChatBox(Kit, frame)
		if Kind(frame) == "Button" and IsTexture(frame.Highlight) and Kind(frame.NormalText) == "FontString" then
			CategoryRow(frame)
		end
	end)
	for _, fn in ipairs({ "ChatConfig_CreateCheckboxes", "ChatConfig_CreateColorSwatches", "ChatConfig_CreateTieredCheckboxes" }) do
		if type(_G[fn]) == "function" then hooksecurefunc(fn, function() if On() then queue() end end) end
	end
	-- The picked tab changed: the combat log's (its panel shown) and a chat window's.
	if type(_G.ChatConfig_UpdateCombatTabs) == "function" then
		hooksecurefunc("ChatConfig_UpdateCombatTabs", function()
			if On() then Guard(PaintTabs, Kit, combatTabs, CombatTabPicked) end
		end)
	end
	if type(_G.FCFTab_UpdateColors) == "function" then
		hooksecurefunc("FCFTab_UpdateColors", function(tab)
			-- (Called for every chat tab, often: the cheap test first.)
			if windowTabSet[tab] and On() then Guard(PaintTabs, Kit, windowTabs, WindowTabPicked) end
		end)
	end
end)

-- Channels --------------------------------------------------------------------------------------
-- ChannelFrame (ButtonFrameTemplate): NewButton, SettingsButton, ChannelList (a ScrollFrame whose
-- Child holds pooled ChannelButton* rows: row art in their normal and highlight textures, the
-- picked one locked lit, a header's "-" kept), LeftInset / RightInset, ChannelRoster (ScrollBox of
-- ChannelRosterButtonTemplate rows: their voice buttons kept).

local function ChannelPicked(btn)
	local frame = _G.ChannelFrame
	local list = Usable(frame) and frame.ChannelList
	return Usable(list) and list.GetSelectedChannelButton and list:GetSelectedChannelButton() == btn or false
end

local rowKeep = setmetatable({}, { __mode = "k" })   -- a list row -> the textures of its that stay

local function ChannelRow(Kit, row)
	if not Usable(row) then return end
	-- (Its keep set made once, not on every update of the list.)
	local keep = rowKeep[row]
	if not keep then
		keep = {}
		if IsTexture(row.Collapsed) then keep[row.Collapsed] = true end
		if IsTexture(row.Rank) then keep[row.Rank] = true end
		rowKeep[row] = keep
	end
	if not dressed[row] then
		dressed[row] = true
		if row.HookScript then row:HookScript("OnClick", Kit.RepaintSoon) end
	end
	Kit.Row(row, keep, ChannelPicked, false)
	FontOf(Kit, row.Text or row.Name)
end

local function ChannelRowsOf(Kit, ...)
	for i = 1, select("#", ...) do ChannelRow(Kit, (select(i, ...))) end
end

local function ChannelRows(Kit, frame)
	local list = frame.ChannelList
	local child = Usable(list) and list.Child
	if not Usable(child) then return end
	ChannelRowsOf(Kit, child:GetChildren())
end

Entry("ChannelFrame", function(f, Kit)
	Kit.Window(f)
	for _, k in ipairs({ "LeftInset", "RightInset" }) do
		if Usable(f[k]) then Kit.Inset(f[k]) end
	end
	if not Controls() then return end
	local skip = {}
	local list = f.ChannelList
	if Usable(list) and Usable(list.Child) then skip[list.Child] = true end
	Walk(Kit, f, { skip = skip }, function() ChannelRows(Kit, f) end)
	local roster = f.ChannelRoster
	if Usable(roster) and Usable(roster.ScrollBox) then
		Kit.EachRow(roster.ScrollBox, function(row)
			local keep = rowKeep[row]
			if not keep then
				keep = { [row.Rank or row] = true }
				rowKeep[row] = keep
			end
			Kit.Row(row, keep, nil, false)
		end, "dui-roster")
	end
	-- New rows as channels are joined while the window is open.
	if Usable(list) and type(list.Update) == "function" then
		-- (Hidden: its rows are looked over by the walk on its next show.)
		hooksecurefunc(list, "Update", function()
			if On() and f:IsShown() then Guard(ChannelRows, Kit, f) end
		end)
	end
end)

-- CreateChannelPopup (Header, BG, Name / Password edit boxes, UseVoiceChat, OK / Cancel, X).
QuietEntry("CreateChannelPopup")

-- Role check, quick keybind ---------------------------------------------------------------------
-- RolePollPopup: Border, CloseButton, three RolePollRoleButtonTemplate buttons (their radio
-- checkButtons stay), acceptButton. QuickKeybindFrame (protected): BG (DialogBorderTemplate),
-- Header, three description strings, UseCharacterBindingsButton (UICheckButtonTemplate: kept, its
-- Text inked), DefaultsButton / CancelButton / OkayButton.

Entry("RolePollPopup", function(f, Kit)
	ShellWindow(Kit, f)
	Kit.Close(f.CloseButton)
	if Controls() then StaticButton(Kit, f.acceptButton) end
	Words(Kit, f, 1)
end)

Entry("QuickKeybindFrame", function(f, Kit)
	-- Silent: the settings panel shows it from its own code, and its OnShow puts the action bars
	-- into key binding mode; nothing of ours may run inside that.
	ShellWindow(Kit, f)
	if Controls() then
		for _, k in ipairs({ "OkayButton", "DefaultsButton", "CancelButton" }) do StaticButton(Kit, f[k]) end
	end
	Words(Kit, f, 0)
	local cb = f.UseCharacterBindingsButton
	if Usable(cb) then
		FontOf(Kit, cb.Text)
		Kit.Light(cb.Text)
	end
end)

-- Stopwatch -------------------------------------------------------------------------------------
-- StopwatchFrame (StopwatchFrameBackgroundLeft and a second background texture), StopwatchTabFrame
-- (Left / Middle / Right, StopwatchTitle, StopwatchCloseButton), StopwatchTicker (Hour / Minute /
-- Second and the colons), StopwatchResetButton / StopwatchPlayPauseButton (pictures).

local function IconBox(Kit, btn)
	if not Usable(btn) or dressed[btn] then return end
	dressed[btn] = true
	if btn.GetHighlightTexture then Kit.Hide(btn:GetHighlightTexture()) end
	Kit.Shell(btn, "control")
	Kit.HoverWash(btn)
end

Entry("StopwatchFrame", function(f, Kit)
	Kit.Window(f)
	local tab = _G.StopwatchTabFrame
	if Usable(tab) then
		Kit.Strip(tab)
		Kit.Shell(tab, "tab")
		Fonts(Kit, tab, true)
	end
	Kit.Close(_G.StopwatchCloseButton)
	if Controls() then
		IconBox(Kit, _G.StopwatchPlayPauseButton)
		IconBox(Kit, _G.StopwatchResetButton)
	end
	Fonts(Kit, _G.StopwatchTicker)
end)

-- Old-style dropdown lists ----------------------------------------------------------------------
-- DropDownList1..n (UIDropDownListTemplate): $parentBackdrop (parentKey Border, a dark dialog
-- border) and $parentMenuBackdrop (a tooltip border), rows $parentButtonN with Highlight,
-- $parentCheck / $parentUnCheck (the radio-check sheet), $parentExpandArrow, $parentColorSwatch.
-- More levels and rows are made by UIDropDownMenu_CreateFrames.

local lists = setmetatable({}, { __mode = "k" })   -- list -> { { check, uncheck }, ... } of its rows
local UNCHECKED = 0.55
local HOVER_WASH = 0.08

local function MenuRow(Kit, list, btn)
	if dressed[btn] then return end
	dressed[btn] = true
	local name = btn:GetName()
	local hl = btn.Highlight or (name and _G[name .. "Highlight"])
	if IsTexture(hl) then
		hl:SetColorTexture(1, 1, 1, HOVER_WASH)
		hl:SetBlendMode("BLEND")
	end
	local arrow = name and _G[name .. "ExpandArrow"]
	local tex = Usable(arrow) and arrow.GetNormalTexture and arrow:GetNormalTexture()
	if IsTexture(tex) then
		tex:SetDesaturated(true)
		local c = ns.Colors().LABEL or { 0.7, 0.7, 0.7 }
		tex:SetVertexColor(c[1], c[2], c[3])
	end
	local row = lists[list]
	row[#row + 1] = { name and _G[name .. "Check"], name and _G[name .. "UnCheck"] }
end

local function MenuList(Kit, list)
	if not Usable(list) then return end
	local name = list:GetName()
	if not name then return end
	if not lists[list] then
		lists[list] = {}
		for _, part in ipairs({ _G[name .. "Backdrop"], _G[name .. "MenuBackdrop"] }) do
			if Usable(part) then part:SetAlpha(0) end
		end
		Kit.Shell(list, "window", QUIET)
	end
	if not Controls() then return end
	for j = 1, 512 do
		local btn = _G[name .. "Button" .. j]
		if not Usable(btn) then break end
		MenuRow(Kit, list, btn)
	end
end

-- The marks of a shown list: gray, the ticked ones in the accent. Read after the game set them up
-- (it sets their desaturation on every fill).
local function Marks(list)
	local rows = lists[list]
	if not rows or not list:IsShown() then return end
	local r, g, b = ns.AccentOf(KEY)
	for i = 1, #rows do
		local check, uncheck = rows[i][1], rows[i][2]
		if IsTexture(check) and check:IsShown() then
			check:SetDesaturated(true)
			check:SetVertexColor(r, g, b)
		end
		if IsTexture(uncheck) and uncheck:IsShown() then
			uncheck:SetDesaturated(true)
			uncheck:SetVertexColor(UNCHECKED, UNCHECKED, UNCHECKED)
		end
	end
end

-- A list reopened at another frame's level: the shell goes back under its rows.
local function Opened(list)
	local Kit = ns.Kit
	local s = Kit and Kit.ShellOf(list)
	if s and s.SetFrameLevel then s:SetFrameLevel(math.max(0, list:GetFrameLevel() - 1)) end
	if Controls() then Marks(list) end
end

local function EachList(fn, ...)
	for i = 1, 32 do
		local list = _G["DropDownList" .. i]
		if not list then break end
		if Usable(list) then fn(list, ...) end
	end
end

local function ShownMarks(list)
	if lists[list] and list:IsShown() then Marks(list) end
end

Entry("DropDownList1", function(_, Kit)
	EachList(function(list) MenuList(Kit, list) end)
	-- More levels and rows are made as a longer or deeper menu first needs them (the game asks on
	-- every row it adds: only a change in how many there are is looked over).
	if type(_G.UIDropDownMenu_CreateFrames) == "function" then
		local levels, buttons
		hooksecurefunc("UIDropDownMenu_CreateFrames", function()
			if not On() or not ns.Kit then return end
			local l, b = _G.UIDROPDOWNMENU_MAXLEVELS, _G.UIDROPDOWNMENU_MAXBUTTONS
			if l ~= nil and l == levels and b == buttons then return end
			levels, buttons = l, b
			EachList(function(list) Guard(MenuList, ns.Kit, list) end)
		end)
	end
	-- After the game has opened (and filled) a level: post-hooks, nothing runs inside the game's
	-- own menu code.
	if type(_G.ToggleDropDownMenu) == "function" then
		hooksecurefunc("ToggleDropDownMenu", function(level)
			if not On() then return end
			local list = _G["DropDownList" .. (tonumber(level) or 1)]
			if Usable(list) and lists[list] and list:IsShown() then Guard(Opened, list) end
		end)
	end
	-- A tick changed while the menu stays open.
	for _, fn in ipairs({ "UIDropDownMenu_Refresh", "UIDropDownMenu_RefreshAll" }) do
		if type(_G[fn]) == "function" then
			-- (Only the lists already dressed can have marks of ours: those, not a name lookup per level.)
			hooksecurefunc(fn, function()
				if On() and Controls() then
					for list in pairs(lists) do ShownMarks(list) end
				end
			end)
		end
	end
end)

-- Queue status and ticket status ----------------------------------------------------------------
-- QueueStatusFrame (TooltipBackdropTemplate) holds pooled QueueStatusEntryTemplate entries (gold
-- status words; AssignedSpec's gold tracking ring). TicketStatusFrame: TicketStatusTitleText,
-- TicketStatusTime, its icon, and TicketStatusFrameButton (a tooltip-backdrop box).

local queueFrame
local inkQueued = false
-- (One GetChildren for all of them, not a fresh one per entry.)
local function InkEntries(Kit, ...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		if Usable(c) then
			Kit.InkGameText(c)
			local spec = c.AssignedSpec
			if Usable(spec) and IsTexture(spec.Border) then Kit.Hide(spec.Border) end
		end
	end
end

local function InkQueue()
	inkQueued = false
	local Kit = ns.Kit
	if not Kit or not Usable(queueFrame) or not queueFrame:IsShown() then return end
	InkEntries(Kit, queueFrame:GetChildren())
end

Entry("QueueStatusFrame", function(f, Kit)
	queueFrame = f
	TipPanel(Kit, f)
	-- After the game fills it (a post-hook: nothing of ours runs inside its Show).
	if type(f.Update) == "function" then
		hooksecurefunc(f, "Update", function()
			if not On() or inkQueued then return end
			inkQueued = true
			C_Timer.After(0, InkQueue)
		end)
	end
end)

Entry("TicketStatusFrame", function(f, Kit)
	local box = _G.TicketStatusFrameButton
	if Usable(box) then TipPanel(Kit, box) else TipPanel(Kit, f) end
	FontOf(Kit, _G.TicketStatusTitleText)
	FontOf(Kit, _G.TicketStatusTime)
	Kit.InkGameText(f)
end)

-- Guild ranks -----------------------------------------------------------------------------------
-- GuildControlUI (TranslucentFrameTemplate): rank list, permission checkboxes, rank edit boxes,
-- bank tab rows, WowStyle1 dropdowns, square arrow buttons, scroll frame. Only once the game has
-- loaded Blizzard_GuildControlUI itself: loading it from addon code taints it.

PanelEntry("GuildControlUI")

-- Cooldown manager settings ---------------------------------------------------------------------
-- CooldownViewerSettings (ButtonFrameTemplate): SpellsTab / AurasTab / GroupBuffsTab
-- (LargeSideTabButtonTemplate: Icon, Mask, SelectedTexture), SearchBox, SettingsDropdown,
-- LayoutDropdown, UndoButton, the categories (ListHeaderThreeSliceTemplate headers, the cooldown
-- icons kept). Its alert editors (CooldownViewerEditAlertBaseTemplate: BG, CloseButton, AddButton,
-- three dropdowns).

-- Window chrome only, silent: the game opens it from Edit Mode's cooldown manager settings, and
-- Edit Mode owns the action bars' layout; nothing of ours may run inside its calls.
Entry("CooldownViewerSettings", function(f, Kit)
	ShellWindow(Kit, f)
	Kit.Close(f.CloseButton)
	if Controls() then
		StaticEditBox(Kit, f.SearchBox)
		StaticButton(Kit, f.UndoButton)
	end
end)
PanelEntry("CooldownViewerSettingsEditAlert")
PanelEntry("GroupBuffFilterEditVisualAlert")

-- Friends and communities popups ----------------------------------------------------------------

-- AddFriendFrame (Border, CloseButton; InfoFrame / EntryFrame with OkayButton, AcceptButton,
-- CancelButton, the name box: AutoCompleteEditBoxTemplate with its Left / Right / Middle atlas
-- pieces). BattleNetInviteFrame (Border, SendButton, CancelButton). FriendsFriendsFrame (Border,
-- Title, FriendsDropdown, SendRequestButton, CloseButton: a text button, ScrollFrameBorder,
-- ScrollBox, ScrollBar).
PanelEntry("AddFriendFrame")
PanelEntry("BattleNetInviteFrame")
Entry("FriendsFriendsFrame", function(f, Kit)
	Panel(Kit, f)
	if Usable(f.ScrollFrameBorder) then
		Kit.Hide(f.ScrollFrameBorder.NineSlice)
		Kit.Inset(f.ScrollFrameBorder)
	end
end)

-- CommunitiesSettingsDialog (BG, edit boxes, checkboxes, dropdowns, input scroll frames,
-- Delete / Accept / Cancel; the icon preview and its ring kept), CommunitiesTicketManagerDialog
-- (its own macro-popup art, dropdowns, buttons, invite list; the icon and ring kept),
-- CommunitiesAvatarPickerDialog (Selector with OK / Cancel, the avatar grid kept as it is).
local COMMUNITY_KEEP = { "IconPreview", "IconPreviewRing", "Icon", "IconRing" }
local function CommunityDialog(name, gridKey)
	Entry(name, function(f, Kit)
		local keep = {}
		for _, k in ipairs(COMMUNITY_KEEP) do
			if IsTexture(f[k]) then keep[f[k]] = true end
		end
		ShellWindow(Kit, f, keep)
		if Usable(f.Selector) then Kit.Strip(f.Selector) end
		if not Controls() then return end
		local skip = {}
		if gridKey and Usable(f[gridKey]) then skip[f[gridKey]] = true end
		Walk(Kit, f, { skip = skip })
	end)
end
CommunityDialog("CommunitiesSettingsDialog")
CommunityDialog("CommunitiesTicketManagerDialog")
CommunityDialog("CommunitiesAvatarPickerDialog", "ScrollBox")

-- Quick join: RoleSelectionTemplate (Border, CloseButton, three role buttons kept, Accept /
-- Cancel).
QuietEntry("QuickJoinRoleSelectionFrame")

-- Group, loot and PvP dialogs -------------------------------------------------------------------

-- Shown by the game's events (invites, queue pops), so quietly. LFGInvitePopup (Border, role
-- buttons, Accept / Decline). PVPReadyDialog (background picture kept: it's the battleground's;
-- Border, the hide button, enterButton / leaveButton, role icon). PVPRoleCheckPopup. PVPFramePopup
-- (its ring icon kept). PVPReadyPopup's ReadyStatus box. GuildInviteFrame (the guild's tabard and
-- its points shield kept). BasicMessageDialog (the plain error box). AddonDialog. Master looter
-- (DefaultPanelTemplate: the item's icon kept, the player buttons kept).
QuietEntry("LFGInvitePopup")
QuietEntry("PVPReadyDialog", { "background" })
QuietEntry("PVPRoleCheckPopup")
QuietEntry("PVPFramePopup", { "ringIcon", "Ring" })
Entry("PVPReadyPopup", function(f, Kit)
	if Usable(f.ReadyStatus) then Quiet(Kit, f.ReadyStatus) end
end)
QuietEntry("GuildInviteFrame", { "TabardBackground", "TabardEmblem", "TabardBorder" })
QuietEntry("BasicMessageDialog")
Entry("AddonDialog", function(f, Kit)
	local inner = _G.AddonDialogBackground
	Quiet(Kit, Usable(inner) and inner or f)
end)
Entry("MasterLooterFrame", function(f, Kit)
	Quiet(Kit, f)
	local item = f.Item
	if Usable(item) then
		for _, k in ipairs({ "NameBorderLeft", "NameBorderRight", "NameBorderMid", "IconBorder" }) do
			if IsTexture(item[k]) then Kit.Hide(item[k]) end
		end
		if IsTexture(item.Icon) then Kit.Outline(item.Icon, ICON_PAD, "outline") end
	end
end)

-- The abandon-instance popup (StaticPopupTemplate, like DaylightUI's StaticPopup1..4: its BG and
-- Border off, ButtonContainer buttons, ExtraButton, EditBox, all quiet).
Entry("InstanceAbandonPopup", function(f, Kit)
	ShellWindow(Kit, f, nil, true)
	if Usable(f.BG) then Kit.Hide(f.BG) end
	if Controls() then
		local c = f.ButtonContainer
		if Usable(c) then
			for i = 1, 4 do StaticButton(Kit, c["Button" .. i]) end
		end
		StaticButton(Kit, f.ExtraButton)
		StaticEditBox(Kit, f.EditBox)
	end
	Words(Kit, f, 1)
end)

-- The bank's clean-up question (Border, Text, its "don't show again" checkbox kept, Accept /
-- Cancel).
QuietEntry("BankCleanUpConfirmationPopup")

-- Party sync dialogs: QuestSessionManager's children (QuestSessionDialogTemplate: BG, Border,
-- Title, Divider, Body, ButtonContainer).
Entry("QuestSessionManager", function(m, Kit)
	for _, d in ipairs({ m:GetChildren() }) do
		if Usable(d) and Usable(d.ButtonContainer) then
			Quiet(Kit, d)
			if IsTexture(d.Divider) then Kit.Hide(d.Divider) end
		end
	end
end)

-- Money split (Shift-click your money): its frame art off, a window shell; Okay / Cancel as
-- buttons, the arrows as page buttons, the amount bright. The coin icons stay.
Entry("CoinPickupFrame", function(f, Kit)
	local keep = {}
	for _, n in ipairs({ "CoinPickupGoldIcon", "CoinPickupSilverIcon", "CoinPickupCopperIcon" }) do
		if IsTexture(_G[n]) then keep[_G[n]] = true end
	end
	ShellWindow(Kit, f, keep)
	if Controls() then
		Kit.PageButton(_G.CoinPickupLeftButton, "left")
		Kit.PageButton(_G.CoinPickupRightButton, "right")
		Kit.Button(_G.CoinPickupOkayButton)
		Kit.Button(_G.CoinPickupCancelButton)
	end
	FontOf(Kit, _G.CoinPickupText)
	Kit.Light(_G.CoinPickupText, ns.Colors().VALUE)
end)

-- Loot history (DefaultPanelFlatTemplate: ClosePanelButton, ScrollBox of loot rows, an encounter
-- dropdown, a timer bar and a resize grip kept, the 100-roll celebration kept).
Entry("GroupLootHistoryFrame", function(f, Kit)
	local skip = {}
	if Usable(f.PerfectAnimFrame) then skip[f.PerfectAnimFrame] = true end
	if Usable(f.Timer) then skip[f.Timer] = true end
	if Usable(f.ResizeButton) then skip[f.ResizeButton] = true end
	Panel(Kit, f, { skip = skip })
end)

-- Death recap (its raid-border pieces and background on the frame, Title, Divider, Unavailable,
-- CloseXButton, a "Close" text button, ScrollBox of the hits).
Entry("DeathRecapFrame", function(f, Kit)
	ShellWindow(Kit, f)
	Kit.Close(f.CloseXButton)
	if Controls() then Walk(Kit, f) end
end)

-- The battleground's score (PVPMatchScoreboard) and results (PVPMatchResults): Camelot frames
-- with a NineSlice, a header, stone backgrounds, tabs (PanelTabButtonTemplate), the score ScrollBox
-- and a leave button.
local function MatchBoard(Kit, f, content)
	ShellWindow(Kit, f)
	Kit.Close(f.CloseButton)
	Kit.Close(f.ClosePanelButton)
	if Usable(f.HeaderContainer) then
		FontOf(Kit, f.HeaderContainer.Text)
		Kit.Light(f.HeaderContainer.Text, ns.Colors().VALUE)
	end
	if Usable(content) then
		Kit.Strip(content)
		local cats = content.ScrollCategories or content.scrollCategories
		if Usable(cats) then Kit.Strip(cats) end
	end
	if Controls() then Walk(Kit, f) end
end
Entry("PVPMatchScoreboard", function(f, Kit) MatchBoard(Kit, f, f.Content) end)
Entry("PVPMatchResults", function(f, Kit) MatchBoard(Kit, f, f.content) end)

-- Guild rename (UIThemeContainerFrame on ButtonFrameTemplate: its two option rows, name box,
-- context button, money; the guild's emblem kept).
Entry("GuildRenameFrame", function(f, Kit) Panel(Kit, f) end)

-- Report player (SharedReportFrameTemplate: rock insets, dropdowns, Report button, screenshot
-- box, comment box, CloseButton with its own ring) and report cheating (Border, the comment box's
-- input border pieces, report / cancel).
Entry("ReportFrame", function(f, Kit)
	for _, k in ipairs({ "TopInset", "BottomInset", "TopInsetEdge", "BottomInsetEdge" }) do
		if IsTexture(f[k]) then Kit.Hide(f[k]) end
	end
	if Usable(f.CloseButton) and IsTexture(f.CloseButton.Border) then Kit.Hide(f.CloseButton.Border) end
	Panel(Kit, f)
end)
Entry("ReportCheatingDialog", function(f, Kit)
	Panel(Kit, f)
	local box = f.CommentFrame
	if Usable(box) then
		Kit.Strip(box)
		Kit.Shell(box, "input")
	end
end)

-- Help (DefaultPanelTemplate round a web page: the window only) and its browser-settings tooltip.
PanelEntry("HelpFrame")
Entry("BrowserSettingsTooltip", function(f, Kit)
	TipPanel(Kit, f)
	if Controls() and Usable(f.CookiesButton) then Kit.Button(f.CookiesButton) end
	Words(Kit, f, 0)
end)

-- The quest details popup from the tracker (ButtonFrameTemplate + QuestFramePanelTemplate: its
-- book icon off; Abandon / Track / Share, the map button), its quest text lit for the dark ground.
Entry("QuestLogPopupDetailFrame", function(f, Kit)
	Panel(Kit, f, nil, function()
		if Usable(f.ScrollFrame) then Kit.LightAll(f.ScrollFrame, nil, 8, true) end
	end)
end)

-- The model preview (ButtonFrameTemplate: a model with carousel arrows, a "Close" MagicButton).
Entry("ModelPreviewFrame", function(f, Kit)
	Panel(Kit, f)
	local scene = Usable(f.Display) and f.Display.ModelScene
	if Usable(scene) and Controls() then
		if Usable(scene.CarouselLeftButton) then Kit.PageButton(scene.CarouselLeftButton, "left") end
		if Usable(scene.CarouselRightButton) then Kit.PageButton(scene.CarouselRightButton, "right") end
	end
end)

-- The icon pickers (IconSelectorPopupFrameTemplate: BG, BorderBox (a NineSlice panel with OK /
-- Cancel, the name box with its named border pieces, a type dropdown), IconSelector grid and the
-- picked icon kept as they are).
local function IconPicker(name)
	Entry(name, function(f, Kit)
		Window(Kit, f)
		local box = f.BorderBox
		if Usable(box) then Kit.Strip(box) end
		if not Controls() then return end
		local skip = {}
		if Usable(f.IconSelector) then skip[f.IconSelector] = true end
		local area = Usable(box) and box.SelectedIconArea
		if Usable(area) then skip[area] = true end
		local eb = Usable(box) and box.IconSelectorEditBox
		if Kind(eb) == "EditBox" then
			Kit.Strip(eb)
			Kit.EditBox(eb)
			skip[eb] = true
		end
		Walk(Kit, f, { skip = skip })
	end)
end
IconPicker("MacroPopupFrame")
IconPicker("GuildBankPopupFrame")
IconPicker("GearManagerPopupFrame")

-- Quest timer (Border, Header, the timer lines; under the quest tracker).
Entry("QuestTimerFrame", function(f, Kit)
	ShellWindow(Kit, f, nil, true)
	Words(Kit, f, 2)
end)

-- The old tutorial box (TutorialFrame: its background, top and bottom art and the side pieces it
-- makes, all faded by the game, so erased for good; the mouse and arrow pictures kept; title,
-- Okay / Prev / Next, X).
Entry("TutorialFrame", function(f, Kit)
	for _, n in ipairs({ "TutorialFrameBackground", "TutorialFrameTop", "TutorialFrameBottom" }) do
		if IsTexture(_G[n]) then Kit.Erase(_G[n]) end
	end
	for i = 1, 40 do
		local l, r = _G["TutorialFrameLeft" .. i], _G["TutorialFrameRight" .. i]
		if not (l or r) then break end
		if IsTexture(l) then Kit.Erase(l) end
		if IsTexture(r) then Kit.Erase(r) end
	end
	dressed[f] = true
	Kit.Shell(f, "window", QUIET)
	local title = _G.TutorialFrameTitle
	FontOf(Kit, title)
	Kit.Light(title, ns.Colors().VALUE)
	Kit.Close(_G.TutorialFrameCloseButton)
	if Controls() then
		-- (Silent: the game shows the tutorial box from its event code.)
		StaticButton(Kit, _G.TutorialFrameOkayButton)
		if Usable(_G.TutorialFramePrevButton) then Kit.BareButton(_G.TutorialFramePrevButton, "left") end
		if Usable(_G.TutorialFrameNextButton) then Kit.BareButton(_G.TutorialFrameNextButton, "right") end
		local sf = _G.TutorialFrameTextScrollFrame
		if Usable(sf) then Kit.ScrollBar(sf.ScrollBar) end
	end
	FontOf(Kit, _G.TutorialFrameText)
end)

-- The nameplate tutorial (ButtonFrameTemplate: its picture cards and their frames kept).
Entry("NamePlatesTutorial", function(f, Kit)
	local keep = {}
	for _, r in ipairs({ f:GetRegions() }) do
		if IsTexture(r) then
			local atlas = r.GetAtlas and r:GetAtlas()
			if type(atlas) == "string" and string.find(atlas, "tutorial-card", 1, true) then keep[r] = true end
		end
	end
	ShellWindow(Kit, f, keep)
	Kit.Close(f.CloseButton)
	Words(Kit, f, 0)
end)

-- The move pad (TooltipBackdropTemplate: settings dropdown, the move checkboxes kept as pictures,
-- jump button).
Entry("MovePadFrame", function(f, Kit)
	TipPanel(Kit, f)
	if Controls() and f.SettingsDropdown then Kit.Dropdown(f.SettingsDropdown) end
end)

-- Name autocomplete, IME candidates, the LFG listing tooltip, the GM chat and survey status boxes:
-- tooltip-like panels.
for _, name in ipairs({ "AutoCompleteBox", "IMECandidatesFrame", "LFGBrowseSearchEntryTooltip", "GMChatStatusFrame", "WowSurveyStatusFrame" }) do
	Entry(name, function(f, Kit)
		TipPanel(Kit, f)
		Words(Kit, f, 1)
	end)
end

-- Help tips (HelpTip's pool of HelpTipTemplate: GlowBoxTemplate art, Text, OkayButton, Arrow with
-- its glow, CloseButton) and help plates (HelpPlateTooltip, its four arrows and their glows): the
-- glow box's art off, a window shell, the arrow in the accent. They can show in a fight; nothing
-- inside them is protected.
local GLOW = { "BG", "GlowTopLeft", "GlowTopRight", "GlowBottomLeft", "GlowBottomRight", "GlowTop", "GlowBottom",
	"GlowLeft", "GlowRight", "ShadowTopLeft", "ShadowTopRight", "ShadowBottomLeft", "ShadowBottomRight", "ShadowTop",
	"ShadowBottom", "ShadowLeft", "ShadowRight" }

local function Accent(tex)
	if not IsTexture(tex) then return end
	tex:SetDesaturated(true)
	tex:SetVertexColor(ns.AccentOf(KEY))
end

local function GlowBox(Kit, f)
	if not Usable(f) or dressed[f] then return end
	dressed[f] = true
	for _, k in ipairs(GLOW) do
		if IsTexture(f[k]) then Kit.Hide(f[k]) end
	end
	Kit.Shell(f, "window", QUIET)
	FontOf(Kit, f.Text)
	local arrow = f.Arrow
	if Usable(arrow) then
		Accent(arrow.Arrow)
		if IsTexture(arrow.Glow) then Kit.Hide(arrow.Glow) end
	end
	for _, d in ipairs({ "Up", "Down", "Left", "Right" }) do
		Accent(f["Arrow" .. d])
		if IsTexture(f["ArrowGlow" .. d]) then Kit.Hide(f["ArrowGlow" .. d]) end
	end
	if Controls() then
		StaticButton(Kit, f.OkayButton)
		if Usable(f.CloseButton) then Kit.Close(f.CloseButton) end
	end
end

-- (HelpTip's own pooled tips are left as the game draws them. The game shows them from inside
-- secure code: an action button's update shows the assisted-rotation tip, and with a shell of
-- DaylightUI's on a reused tip, its OnShow ran inside that update and the action bars' SetShown
-- was blocked, blamed on DaylightUI. Help plates are only shown by a click on the "?" button.)
Entry("HelpPlateTooltip", function(f, Kit) GlowBox(Kit, f) end)

-- Event toasts (EventToastManagerFrame: level up, new zone, flight point, scenario and the like).
-- The manager: BlackBG (a soft dark shadow, kept), GLine / GLine2 (the gold bars, tinted by the
-- game per toast with SetColorTint: kept when it tints them, in the accent when it doesn't),
-- HideButton. Each toast comes from a pool, gets its Title / SubTitle (gold and huge) set up, and
-- is shown from the game's event code; its icon and an item's rarity color stay. Dressed after
-- the game's DisplayToast (a post-hook: nothing of ours runs inside its Show), so silent.
local TOAST_TEXT = { "SubTitle", "InstructionalText" }

-- A gold bar of the manager's: in the accent (r given), or the game's own tint back (r nil).
local function ToastLine(line, r, g, b)
	if not IsTexture(line) then return end
	if r then
		line:SetDesaturated(true)
		line:SetVertexColor(r, g, b)
	else
		line:SetDesaturated(false)
	end
end

local function EventToast(Kit, m)
	local toast = m.currentDisplayingToast
	local info = Usable(toast) and toast.toastInfo
	if type(info) == "table" and not info.colorTint then
		local r, g, b = ns.AccentOf(KEY)
		ToastLine(m.GLine, r, g, b)
		ToastLine(m.GLine2, r, g, b)
	elseif type(info) == "table" then
		ToastLine(m.GLine)
		ToastLine(m.GLine2)
	end
	if not Usable(toast) then return end
	local value = ns.Colors().VALUE
	if Kind(toast.Title) == "FontString" then
		FontOf(Kit, toast.Title)
		Kit.Light(toast.Title, value)
	end
	for _, k in ipairs(TOAST_TEXT) do
		if Kind(toast[k]) == "FontString" then FontOf(Kit, toast[k]) end
	end
	-- Gold words in the label ink; an item's rarity color (RarityValue) is a color of its own, kept.
	Kit.InkGameText(toast)
end

Entry("EventToastManagerFrame", function(m, Kit)
	if type(m.DisplayToast) ~= "function" then return end
	hooksecurefunc(m, "DisplayToast", function(self)
		if On() and ns.Kit then Guard(EventToast, ns.Kit, self) end
	end)
	if m:IsShown() then EventToast(Kit, m) end
end)

-- The world map's metal border (WorldMapFrame.BorderFrame.NineSlice). DaylightUI's world map skin
-- fades it (Kit.Hide, alpha 0) once; nothing in the game's map code or in OpenMap sets that alpha
-- back (Maximize / Minimize only re-apply its layout with SetBorder, which keeps the alpha). Kept
-- at 0 after the map is shown, maximized or minimized, and only while DaylightUI's skin is on the
-- map (its accent line, Kit.TopLineOf, says so), so a map DaylightUI leaves alone stays the game's.
local function MapBorder()
	local map, Kit = _G.WorldMapFrame, ns.Kit
	if not (Usable(map) and Kit and Kit.TopLineOf and Kit.TopLineOf(map)) then return end
	local border = map.BorderFrame
	local nine = Usable(border) and border.NineSlice
	if Usable(nine) and nine:GetAlpha() > 0 then nine:SetAlpha(0) end
end

-- (Through the game's own EventRegistry events, which it runs apart from its own code: nothing
-- of ours runs inside the map's Show.)
local mapOwner = {}
Entry("WorldMapFrame", function()
	local reg = _G.EventRegistry
	if type(reg) ~= "table" or type(reg.RegisterCallback) ~= "function" then return end
	local function later()
		if On() then C_Timer.After(0, MapBorder) end
	end
	for _, event in ipairs({ "WorldMapOnShow", "WorldMapMaximized", "WorldMapMinimized" }) do
		reg:RegisterCallback(event, later, mapOwner)
	end
	MapBorder()
end)

-- The game's spellbook and talents (PlayerSpellsFrame, Blizzard_PlayerSpells; protected).
-- DaylightUI's Book shows instead and keeps this frame parked under its veil (Win.Follow:
-- reparented to a hidden or clipped frame); the game's frame is what shows with DaylightUI's
-- Book off, with the controller UI, or in a fight with its fight book off, and then it's opened by
-- secure code (keys, the micro menu, ShowUIPanel). So: dressed once out of combat, chrome only,
-- and silent: nothing hooked on any part of it that the game's Show, Hide, Enable or a tab change
-- could set off (only the mouse: Kit.Close, Kit.BareButton), no secure attribute read or written,
-- no spell button touched. The book's pages, the talent tree and every spell stay the game's.
--   The window: NineSlice, Bg, TopTileStreaks, PortraitContainer off, a quiet window shell, the
--     title (TitleContainer.TitleText) in the value ink on the left, the close X,
--     MaximizeMinimizeButton's red buttons as bare chevrons.
--   Tabs (TabSystem, the spellbook's CategoryTabSystem, the talents' TabSystem;
--     TabSystemButtonArtTemplate): the game's gold tab art off; the picked tab's own middle piece
--     (which the game shows only on the picked tab) becomes a soft accent wash, its hover piece a
--     faint white wash, so the pick follows the game with nothing of ours to run.
--   The spellbook: its settings dropdown (UIPanelArrowDropdownButtonTemplate) as a bare chevron,
--     the search box in the silent input look, the page arrows (PagingControls) as bare chevrons.
--   The talents: the search box, the search options arrow, Apply and Copy in the silent button
--     look.
local TAB_ART_OFF = { "Left", "Right", "Middle", "LeftActive", "RightActive", "LeftHighlight", "RightHighlight",
	"SquareBackground", "SquareBackgroundActive", "SquareBackgroundActiveGlow" }
local TAB_PICK, TAB_HOVER = 0.18, 0.08

local function SilentTabs(Kit, system)
	if not Usable(system) or not system.GetChildren then return end
	local r, g, b = ns.AccentOf(KEY)
	for _, tab in ipairs({ system:GetChildren() }) do
		if Usable(tab) and not dressed[tab] and IsTexture(tab.MiddleActive) then
			dressed[tab] = true
			for _, k in ipairs(TAB_ART_OFF) do
				if IsTexture(tab[k]) then Kit.Hide(tab[k]) end
			end
			tab.MiddleActive:SetColorTexture(r, g, b, TAB_PICK)
			if IsTexture(tab.MiddleHighlight) then
				tab.MiddleHighlight:SetColorTexture(1, 1, 1, TAB_HOVER)
				tab.MiddleHighlight:SetBlendMode("BLEND")
			end
			if Kind(tab.Text) == "FontString" then FontOf(Kit, tab.Text) end
		end
	end
end

local function PagingButtons(Kit, paging)
	if not Usable(paging) then return end
	if Usable(paging.PrevPageButton) then Kit.BareButton(paging.PrevPageButton, "left") end
	if Usable(paging.NextPageButton) then Kit.BareButton(paging.NextPageButton, "right") end
	if Kind(paging.PageText) == "FontString" then FontOf(Kit, paging.PageText) end
end

local spellsOwner = {}
Entry("PlayerSpellsFrame", function(f, Kit)
	if InCombatLockdown() then return end   -- (TryAll runs out of combat; a protected frame, so never in one)
	ShellWindow(Kit, f)
	Kit.Close(f.CloseButton)
	local mm = f.MaximizeMinimizeButton
	if Usable(mm) then
		if Usable(mm.MaximizeButton) then Kit.BareButton(mm.MaximizeButton, "up") end
		if Usable(mm.MinimizeButton) then Kit.BareButton(mm.MinimizeButton, "down") end
	end
	if not Controls() then return end
	SilentTabs(Kit, f.TabSystem)
	local book = f.SpellBookFrame
	if Usable(book) then
		SilentTabs(Kit, book.CategoryTabSystem)
		if Usable(book.SettingsDropdown) then Kit.BareButton(book.SettingsDropdown, "down") end
		StaticEditBox(Kit, book.SearchBox)
		local paged = book.PagedSpellsFrame
		if Usable(paged) then PagingButtons(Kit, paged.PagingControls) end
	end
	local talents = f.TalentsFrame
	-- Tabs the game adds later (the spellbook's categories): looked over again when the window
	-- opens or its tab changes (the game's EventRegistry events, out of combat only).
	local reg = _G.EventRegistry
	if type(reg) == "table" and type(reg.RegisterCallback) == "function" then
		local function again()
			if not On() or InCombatLockdown() or not ns.Kit then return end
			SilentTabs(ns.Kit, f.TabSystem)
			if Usable(book) then SilentTabs(ns.Kit, book.CategoryTabSystem) end
			if Usable(talents) then SilentTabs(ns.Kit, talents.TabSystem) end
		end
		for _, event in ipairs({ "PlayerSpellsFrame.OpenFrame", "PlayerSpellsFrame.TabSet" }) do
			reg:RegisterCallback(event, function() Guard(again) end, spellsOwner)
		end
	end
	if Usable(talents) then
		SilentTabs(Kit, talents.TabSystem)
		StaticEditBox(Kit, talents.SearchBox)
		if Usable(talents.SearchOptionsDropdown) then Kit.BareButton(talents.SearchOptionsDropdown, "down") end
		StaticButton(Kit, talents.ApplyButton)
		StaticButton(Kit, talents.InspectCopyButton)
	end
end)

-- ---------------------------------------------------------------------------------------------
-- When: at login (the always-loaded windows; out of combat), and when each Blizzard addon that
-- holds one of the others loads. Those are DaylightUI skins of this plugin's, so DaylightUI runs
-- them out of combat; a window whose addon isn't named below is still found when any Blizzard addon
-- loads. An addon that never loads costs nothing.
-- ---------------------------------------------------------------------------------------------

-- The Kit comes from DaylightUI only when its skins start, which can be before or after "Login":
-- the walk runs on whichever is later (ns.WithKit holds it until the Kit is there), and again the
-- moment the Kit arrives if that's later still. Every entry is done once, so a second run only
-- picks up what wasn't there yet.
local function Soon() ns.OutOfCombat(TryAll) end
ns.WithKit(function() if ns.loggedIn then Soon() end end)
ns.me.On("Login", function() ns.WithKit(Soon) end)

for _, addon in ipairs({ "Blizzard_PlayerSpells", "Blizzard_WorldMap", "Blizzard_BattlefieldMap", "Blizzard_TimeManager", "Blizzard_GuildControlUI",
	"Blizzard_DeathRecap", "Blizzard_MacroUI", "Blizzard_GuildBankUI", "Blizzard_HelpFrame",
	"Blizzard_ReportFrame", "Blizzard_Communities", "Blizzard_MovePad", "Blizzard_GMChatUI",
	"Blizzard_WowSurveyUI", "Blizzard_GroupFinder_VanillaStyle", "Blizzard_PVPMatch" }) do
	ns.Pack(addon, nil, function() TryAll() end)
end

local loads = CreateFrame("Frame")
loads:RegisterEvent("ADDON_LOADED")
loads:SetScript("OnEvent", function(self, _, name)
	if left == 0 then
		self:UnregisterEvent("ADDON_LOADED")
		return
	end
	if not ns.loggedIn or not ns.Kit or type(name) ~= "string" or string.sub(name, 1, 9) ~= "Blizzard_" then return end
	ns.OutOfCombat(TryAll)
end)
