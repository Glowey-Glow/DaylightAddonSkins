-- Game windows, part two: the game's character window and the spellbook and talents, whenever
-- the game shows them itself rather than DaylightUI's own. Built against the client's own
-- interface code (wow-ui-source, branch "forever": the Camelot files of Blizzard_UIPanels_Game,
-- Blizzard_TokenUI, Blizzard_Statistics and Blizzard_PlayerSpells), so every name and key below
-- is the game's. Follows the "Game windows" switch and look (key "Blizzard", Packs/Blizzard.lua).
--   The character window (CharacterFrame, its pages PaperDollFrame, ReputationFrame, SkillsFrame,
--     PVPRankFrame, TokenFrame and StatisticsFrame): shows when DaylightUI's character window is
--     off, and on its Currency page when DaylightUI's "Transfer to another character" hands the
--     game's window back (DaylightUI keeps it parked under a hidden frame the rest of the time).
--     Dressed only while it is on screen (parent UIParent, visible), so nothing here touches it
--     while it sits parked under DaylightUI's window: from the game's own "CharacterFrame.Show"
--     event and after each ToggleCharacter (a page picked), next frame, out of combat.
--     The window shell, title and X; the page tabs on its right edge as clean tiles, the picked
--     one in the accent; the panel art (the gray backdrops, stone header, gold dividers, gear
--     slot frames, stat stripes, list header bars, race background) off; items in DaylightUI's
--     item look; every list (currency, reputation, skills, statistics, stats, titles, equipment
--     sets, the transfer log) as rows: headers as boxes with their +/-, entries as lines with the
--     accent wash on the picked one, sub-headers' arrows as chevrons, bars in the bar look; the
--     side panes' rows in DaylightUI's inks; checkboxes as switches, the dropdowns, buttons
--     (the red three-slice ones too), scroll bars and boxes in DaylightUI's controls.
--   The currency transfer window (CurrencyTransferMenu): shell, title, X, its source dropdown,
--     amount box, Max / Confirm / Cancel, the balance lines. The long arrow beside the dropdown
--     stays (it says "from this character").
--   The spellbook and talents (PlayerSpellsFrame): Packs/Blizzard.lua dresses its chrome; this
--     adds the loadout dropdown, the reset and undo buttons, the dual spec "Activate" button, the
--     search preview lists of both pages, the spellbook's spell names and gold page headers, and
--     the loadout dialogs (ClassTalentLoadoutCreateDialog / EditDialog / ImportDialog).
-- Left alone on purpose: the character model, item icons, faction and rank art, reputation and
-- skill bar colors, the talent tree and every spell button (the game's), the side panes' title
-- colors (the game's per-page color), the equipment set icon picker (Packs/Blizzard.lua), and the
-- loadout dialog's "shared action bars" checkbox (quiet, see Taint).
--
-- Taint: these are the game's frames. Looks only, nothing protected called. The character window
-- and the transfer window are plain windows (not protected): dressed as Packs/Blizzard.lua dresses
-- its plain windows, out of combat. The spellbook and talents window is protected and opened by
-- secure code, so everything for it follows Packs/Blizzard.lua's quiet rules: dressed out of
-- combat; nothing hooked that the game's Show, Hide, Enable or a tab change could set off (only
-- the mouse: Kit.Dropdown's hover, Kit.ScrollBar's thumb); its pages are looked over again from
-- the game's EventRegistry events (run apart from its own code) and post-hooks
-- (hooksecurefunc), next frame; no field of the game's written, no secure attribute touched.
-- Nothing here loads a Blizzard addon.
local _, ns = ...
if not ns.ok then return end

local KEY = "Blizzard"   -- "Game windows" (Packs/Blizzard.lua registers it)
local Usable, Guard = ns.Usable, ns.Guard
local ipairs, pairs, type = ipairs, pairs, type

local dressed = setmetatable({}, { __mode = "k" })   -- frames and controls of ours already done

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end

local function Kind(x)
	if not Usable(x) then return nil end
	return x:GetObjectType()
end

local function IsTexture(x) return Kind(x) == "Texture" end
local function Value() return ns.Colors().VALUE end

-- Kit.Font on a string or box, unless the game hasn't given it a size yet ("Invalid font height").
local function FontOf(Kit, fs)
	local k = Kind(fs)
	if k ~= "FontString" and k ~= "EditBox" then return end
	local ok, _, size = pcall(fs.GetFont, fs)
	if ok and type(size) == "number" and size > 0 then Kit.Font(fs) end
end

local function Light(Kit, fs, color)
	if Kind(fs) ~= "FontString" then return end
	FontOf(Kit, fs)
	Kit.Light(fs, color)
end

-- The player's font on the strings a frame holds itself, sizes kept (Kit.Refont leaves one already
-- in DaylightUI's font alone). The game's narrow number font (counts on icons) stays.
local function Refont(Kit, frame)
	if not (Usable(frame) and frame.GetRegions) or frame:GetNumRegions() == 0 then return end
	for _, r in ipairs({ frame:GetRegions() }) do
		if Kind(r) == "FontString" then
			local ok, path, size = pcall(r.GetFont, r)
			local number = type(path) == "string" and string.find(string.upper(path), "ARIALN", 1, true) ~= nil
			if ok and type(size) == "number" and size > 0 and not number then Kit.Refont(r) end
		end
	end
end

-- The character window's panel art, by atlas: backdrops, the stone header, dividers, gear slot
-- frames, stat stripes and title plates, list header bars. Its icons stay (the "+" of a new set,
-- a set's tick, resistance icons), and so does the honor rank art.
local ART = { "ui-character-info-", "common-insideframe", "common-framedivider",
	"common-button-list-collapseexpand", "activities-divider" }
local ART_KEEP = { "-icon-", "resistance", "honor" }
local artSeen = setmetatable({}, { __mode = "k" })   -- texture -> looked at (it had an atlas)

local function IsArt(atlas)
	atlas = string.lower(atlas)
	for _, k in ipairs(ART_KEEP) do
		if string.find(atlas, k, 1, true) then return false end
	end
	for _, p in ipairs(ART) do
		if string.sub(atlas, 1, #p) == p then return true end
	end
	return false
end

local function ArtOff(Kit, frame)
	if not (Usable(frame) and frame.GetRegions) or frame:GetNumRegions() == 0 then return end
	for _, r in ipairs({ frame:GetRegions() }) do
		if not artSeen[r] and IsTexture(r) then
			local ok, atlas = pcall(r.GetAtlas, r)
			if ok and type(atlas) == "string" and atlas ~= "" then
				artSeen[r] = true
				if IsArt(atlas) then Kit.Hide(r) end
			end
		end
	end
end

-- With the controls left to the game: the art off and DaylightUI's fonts and inks, to depth.
local function Plain(Kit, frame, depth)
	if not Usable(frame) then return end
	ArtOff(Kit, frame)
	Refont(Kit, frame)
	Kit.InkGameText(frame)
	if depth > 0 and frame.GetChildren then
		for _, c in ipairs({ frame:GetChildren() }) do Plain(Kit, c, depth - 1) end
	end
end

-- What the walk hands every frame it passes (the controls it dresses itself aside): the art off,
-- the fonts, and the controls the Kit's walk doesn't know (the game's intrinsic dropdowns, sliders,
-- old-style dropdowns), as Packs/Blizzard.lua's walk does.
local function Each(Kit, frame)
	ArtOff(Kit, frame)
	Refont(Kit, frame)
	local k = Kind(frame)
	if k == "Button" and frame.intrinsic == "DropdownButton" then
		Kit.Dropdown(frame)
	elseif k == "Slider" then
		ns.Slider(frame)
	elseif k == "Frame" then
		ns.OldDropdown(frame)
	end
end

-- A text button made wide enough for its words in DaylightUI's (wider) font. Plain windows only.
local function Refit(b, pad)
	if Kind(b) ~= "Button" or not b.GetFontString then return end
	local fs = b:GetFontString()
	if Kind(fs) ~= "FontString" then return end
	local w = fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth()
	local have = b:GetWidth()
	if type(w) == "number" and type(have) == "number" and have > 0 and w + (pad or 24) > have then
		b:SetWidth(math.ceil(w + (pad or 24)))
	end
end

-- A gold tick (a watched currency, the title in use, the equipped set) in the accent.
local accented = setmetatable({}, { __mode = "k" })   -- texture -> "paint" / "fill" (repainted on a style change)
local function Tick(tex)
	if not IsTexture(tex) then return end
	if not dressed[tex] then
		dressed[tex] = true
		tex:SetDesaturated(true)
		accented[tex] = "paint"
	end
	ns.PaintAccent(tex, 1, nil, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- Quiet controls (the spellbook's and its dialogs'): nothing of ours hooked but the mouse, the
-- same rules and looks as Packs/Blizzard.lua's (its StaticButton / StaticEditBox).
-- ---------------------------------------------------------------------------------------------

local QUIET = { quiet = true }
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
	if b.GetFontString then FontOf(Kit, b:GetFontString()) end
end

local function StaticEditBox(Kit, eb)
	if Kind(eb) ~= "EditBox" or dressed[eb] then return end
	dressed[eb] = true
	local name = eb:GetName()
	for _, k in ipairs(THREE_ART) do
		if IsTexture(eb[k]) then Kit.Hide(eb[k]) end
		if name and IsTexture(_G[name .. k]) then Kit.Hide(_G[name .. k]) end
	end
	Kit.Shell(eb, "input")
	FontOf(Kit, eb)
	if Kind(eb.Instructions) == "FontString" then FontOf(Kit, eb.Instructions) end
end

-- An icon button (IconButtonTemplate: the talents' reset and undo): its picture kept (the game
-- grays it while disabled), the hover copy of it off, a control box with a hover wash round it.
local function StaticIconButton(Kit, b)
	if not Usable(b) or dressed[b] then return end
	dressed[b] = true
	for _, get in ipairs(BUTTON_ART) do
		local t = b[get] and b[get](b)
		if IsTexture(t) and t ~= b.Icon then Kit.Hide(t) end
	end
	Kit.Shell(b, "control")
	Kit.HoverWash(b)
end

-- A dialog's text buttons and edit boxes, quietly (as Packs/Blizzard.lua's QuietControls).
local function QuietControls(Kit, frame, depth)
	for _, c in ipairs({ frame:GetChildren() }) do
		if Usable(c) then
			local k = c:GetObjectType()
			if k == "Button" and ns.TextButton(c) then
				StaticButton(Kit, c)
			elseif k == "EditBox" then
				local name = c:GetName()
				if IsTexture(c.Left) or (name and IsTexture(_G[name .. "Left"])) then StaticEditBox(Kit, c) end
			elseif depth > 0 and (k == "Frame" or k == "Button") then
				QuietControls(Kit, c, depth - 1)
			end
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- List rows (every ScrollBox list of the character window and the transfer log)
-- ---------------------------------------------------------------------------------------------

local ROW_KEY = "AddonSkins.BlizzardCharacter"
local rowKeep = setmetatable({}, { __mode = "k" })   -- row -> the textures Kit.Row keeps
local ourRows = setmetatable({}, { __mode = "k" })   -- rows this file made with Kit.Row (repainted on a style change)

local function RowSelected(row)
	return type(row.IsSelected) == "function" and row:IsSelected() == true
end

-- What of a gear set row (GearSetButtonTemplate) or a title row (PlayerTitleButtonTemplate) stays:
-- the set's icon, tick and spec badge; the title's tick.
local function KeepOf(row)
	local keep = rowKeep[row]
	if keep then return keep end
	keep = {}
	for _, k in ipairs({ "icon", "Check", "SpecRing", "SpecIcon" }) do
		if IsTexture(row[k]) then keep[row[k]] = true end
	end
	rowKeep[row] = keep
	return keep
end

-- Header rows (TokenHeaderTemplate, ReputationHeaderTemplate, SkillsHeaderTemplate,
-- StatisticsHeaderTemplate: a gold bar, a +/- and the gold name), entry rows (a Content frame with
-- the game's BackgroundHighlight wash, which it fades in for hover and the picked one), sub-headers
-- (ToggleCollapseButton), the stats pane's rows (a stripe or title plate), gear sets and titles.
local function ListRow(Kit, row)
	if not Usable(row) then return end
	local content = Usable(row.Content) and row.Content or nil
	ArtOff(Kit, row)
	Refont(Kit, row)
	if content then
		ArtOff(Kit, content)
		Refont(Kit, content)
	end
	local hl = (content and content.BackgroundHighlight) or row.BackgroundHighlight
	if Usable(hl) and not dressed[hl] then
		dressed[hl] = true
		local list = type(hl.TextureRegions) == "table" and hl.TextureRegions or { hl:GetRegions() }
		for _, t in ipairs(list) do Kit.Erase(t) end
	end
	local header = IsTexture(row.StateIcon) and not content
	if Controls() then
		if header then
			local keep = rowKeep[row]
			if not keep then
				keep = { [row.StateIcon] = true }
				rowKeep[row] = keep
			end
			Kit.Row(row, keep)
		elseif Usable(hl) then
			Kit.Row(row, nil, RowSelected, false)
		elseif IsTexture(row.SelectedBar) then
			Kit.Row(row, KeepOf(row), row.SelectedBar, false)
		end
		if Kit.RowOf(row) then ourRows[row] = true end
		if Usable(row.ToggleCollapseButton) then Kit.CollapseButton(row.ToggleCollapseButton) end
		local bar = content and (content.ReputationBar or content.SkillsBar)
		if Usable(bar) then Kit.ProgressBar(bar) end
	end
	if header then
		if not dressed[row.StateIcon] then
			dressed[row.StateIcon] = true
			row.StateIcon:SetDesaturated(true)
		end
		local t = Kit.TEXT
		row.StateIcon:SetVertexColor(t[1], t[2], t[3])
		Light(Kit, row.Name, Value())
	elseif Kind(row.Title) == "FontString" and IsTexture(row.Background) then
		-- A stats pane category (its title plate is off): the title in the value ink.
		Light(Kit, row.Title, Value())
	end
	Tick(content and content.WatchedCurrencyCheck)
	Tick(row.Check)
	Kit.InkGameText(row)
	if content then Kit.InkGameText(content) end
end

-- Each list once: its rows now, after every list update and as each row is filled (Kit.EachRow,
-- driven by the list's own callbacks). Lists not there yet (a page's addon loading later) are
-- looked for again on the next pass.
local listsDone = setmetatable({}, { __mode = "k" })
local function Lists(Kit, ...)
	for i = 1, select("#", ...) do
		local box = select(i, ...)
		if Usable(box) and box.ForEachFrame and not listsDone[box] then
			listsDone[box] = true
			Kit.EachRow(box, function(row) ListRow(Kit, row) end, ROW_KEY)
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The character window
-- ---------------------------------------------------------------------------------------------

local char = { done = false, queued = false, waiting = false, skip = {} }
local CHAR_DEPTH = 8

local function CharEach(frame) Each(ns.Kit, frame) end
local CHAR_FIRST = { rows = false, each = CharEach, skip = char.skip }
local CHAR_AGAIN = { rows = false, each = CharEach, skip = char.skip, shownOnly = true }

-- On screen: parented to UIParent (not parked under DaylightUI's window) and visible.
local function CharacterOnScreen()
	local f = _G.CharacterFrame
	return Usable(f) and f:GetParent() == UIParent and f:IsVisible() == true
end

-- The page tabs down the window's right edge (CharacterFrameModeSideTabTemplate: Background,
-- Icon, SelectedTexture shown on the picked one, HighlightTexture, TabGlow): clean tiles.
local TILE_CROP = 0.08   -- ns.SideTile's crop
local function ModeTabPicked(tab)
	return IsTexture(tab.SelectedTexture) and tab.SelectedTexture:IsShown() == true
end

local function Crop(tab)
	if On() and IsTexture(tab.Icon) then tab.Icon:SetTexCoord(TILE_CROP, 1 - TILE_CROP, TILE_CROP, 1 - TILE_CROP) end
end

local function ModeTabs(Kit, f)
	local holder = f.ModeTabs
	local tabs = Usable(holder) and holder.Tabs
	if type(tabs) ~= "table" then return end
	char.skip[holder] = true
	if not Controls() then return end
	for _, tab in ipairs(tabs) do
		if Usable(tab) and IsTexture(tab.Icon) and not dressed[tab] then
			dressed[tab] = true
			Kit.Hide(tab.Background)
			Kit.Hide(tab.SelectedTexture)
			Kit.Hide(tab.HighlightTexture)
			Kit.Erase(tab.TabGlow)
			ns.SideTile(tab, { picked = ModeTabPicked, key = KEY, pad = 2 })
			-- The game puts the icon's own crop back on every pick (SetChecked -> UpdateIconInterior)
			-- and on the portrait's refresh: the tile's crop again after both (post-hooks).
			if type(tab.SetChecked) == "function" then
				hooksecurefunc(tab, "SetChecked", function(self) Guard(Crop, self) end)
			end
			Crop(tab)
		end
	end
	if type(f.UpdateCharacterModeTabPortrait) == "function" then
		hooksecurefunc(f, "UpdateCharacterModeTabPortrait", function(self)
			local t = Usable(self.ModeTabs) and self.ModeTabs.CharacterTab
			if Usable(t) then Guard(Crop, t) end
		end)
	end
end

-- The paper doll's side tabs (PaperDollSidebarTab1-4: stats, equipment sets, titles, pet; their
-- frame art and checked art are off with the rest): a tab outline, the picked one in the accent.
local sidebar = {}            -- tab -> its shell
local function PaintSidebar()
	local Kit = ns.Kit
	if not Kit or not On() then return end
	-- (A new table each time: the shell keeps the one it was painted with and compares to it.)
	local accent = { ns.AccentOf(KEY) }
	for tab, s in pairs(sidebar) do
		if tab:GetChecked() then ns.LightShell(s, accent, KEY) else Kit.Paint(s, Kit.TAB_BORDER) end
	end
end
local sideQueued = false
local function PaintSidebarSoon()
	if sideQueued then return end
	sideQueued = true
	C_Timer.After(0, function() sideQueued = false Guard(PaintSidebar) end)
end

local function SidebarTab(Kit, tab)
	if Kind(tab) ~= "CheckButton" or dressed[tab] then return end
	dressed[tab] = true
	ArtOff(Kit, tab)
	Kit.Hide(tab:GetCheckedTexture())
	sidebar[tab] = Kit.Shell(tab, "tab")
end

local function PaperDollChrome(Kit, f)
	local pd = _G.PaperDollFrame
	if not Usable(pd) then return end
	if Usable(pd.TopBackgroundStripHost) then Kit.Strip(pd.TopBackgroundStripHost) end
	local scene = pd.CharacterModelScene
	if Usable(scene) then
		for _, k in ipairs({ "BackgroundTopLeft", "BackgroundTopRight", "BackgroundBotLeft", "BackgroundBotRight", "BackgroundOverlay" }) do
			Kit.Hide(scene[k])
		end
	end
	if Usable(_G.GearManagerPopupFrame) then char.skip[_G.GearManagerPopupFrame] = true end
	if not Controls() then return end
	for i = 1, 4 do SidebarTab(Kit, _G["PaperDollSidebarTab" .. i]) end
	if type(_G.PaperDollFrame_SetSidebar) == "function" then
		hooksecurefunc("PaperDollFrame_SetSidebar", function() if On() then PaintSidebarSoon() end end)
	end
	-- The "new set" button (PaperDollTertiaryButtonTemplate: one state texture the game swaps).
	local pane = pd.EquipmentManagerPane
	local new = Usable(pane) and pane.NewSet
	if Usable(new) and not dressed[new] then
		dressed[new] = true
		Kit.Hide(new.StateTexture)
		Kit.Shell(new, "control")
		Kit.HoverWash(new)
	end
	-- The side pane's show / hide arrow (the game swaps its page-arrow art): a bare chevron
	-- pointing the way it goes.
	local btn = f.RightPaneToggleButton
	if Usable(btn) and not dressed[btn] then
		dressed[btn] = true
		local c = Kit.BareButton(btn, "left")
		if c then
			local function point()
				local ok, collapsed = pcall(f.IsRightPaneCollapsed, f)
				c:SetRotation((ok and collapsed) and Kit.ROTATION.right or Kit.ROTATION.left)
			end
			point()
			if type(f.UpdateRightPaneToggleButton) == "function" then
				hooksecurefunc(f, "UpdateRightPaneToggleButton", function() Guard(point) end)
			end
		end
	end
end

-- The side panes (CharacterFrameSidePaneTemplate: the currency, reputation, skill, honor and
-- statistics details), whose rows come from pools on every refresh: their art off, fonts and
-- inks after each LayoutRows. A wrapped row the game sized for its own font is sized again.
local function PaneRows(Kit, pane)
	FontOf(Kit, pane.Title)
	FontOf(Kit, pane.Subtitle)
	FontOf(Kit, pane.EmptyText)
	Kit.InkGameText(pane)
	local content = pane.Content
	if not Usable(content) then return end
	local resized = false
	for _, row in ipairs({ content:GetChildren() }) do
		if Usable(row) and row:IsShown() then
			ArtOff(Kit, row)
			local label = row.Label
			local before = Kind(label) == "FontString" and label:GetStringHeight()
			Refont(Kit, row)
			Kit.InkGameText(row)
			if Kind(label) == "FontString" and IsTexture(row.Background) then
				-- A category row (its plate is off): the value ink.
				Kit.Light(label, Value())
			elseif before and Kind(row.Value) ~= "FontString" and not IsTexture(row.Icon) and label:GetText() ~= "" then
				local after = label:GetStringHeight()
				if type(after) == "number" and after ~= before and after > 0 then
					row:SetHeight(math.max(1, after))
					resized = true
				end
			end
		end
	end
	if resized and content.Layout then content:Layout() end
end

local function SidePanes(Kit, f)
	if type(f.SidePanes) ~= "table" then return end
	for _, pane in ipairs(f.SidePanes) do
		if Usable(pane) and not dressed[pane] then
			dressed[pane] = true
			if type(pane.LayoutRows) == "function" then
				hooksecurefunc(pane, "LayoutRows", function(self)
					if char.done and On() and ns.Kit then Guard(PaneRows, ns.Kit, self) end
				end)
			end
			PaneRows(Kit, pane)
		end
	end
end

local function CharacterLists(Kit)
	if not Controls() then return end
	local pd, rep, skills, stats, tokens = _G.PaperDollFrame, _G.ReputationFrame, _G.SkillsFrame, _G.StatisticsFrame, _G.TokenFrame
	local box = function(frame) return Usable(frame) and frame.ScrollBox or nil end
	Lists(Kit, box(tokens), box(rep), box(skills), box(stats), box(_G.CharacterStatsPaneScrollBox),
		box(_G.CharacterStatsPanePetScrollBox), box(_G.CurrencyTransferLog),
		Usable(pd) and box(pd.EquipmentManagerPane) or nil, Usable(pd) and box(pd.TitleManagerPane) or nil)
end

-- Once, the first time the window is on screen.
local function CharacterChrome(Kit, f)
	Kit.Window(f)
	ModeTabs(Kit, f)
	PaperDollChrome(Kit, f)
	SidePanes(Kit, f)
	-- (The transfer log is its own window, dressed with the transfer window.)
	if Usable(_G.CurrencyTransferLog) then char.skip[_G.CurrencyTransferLog] = true end
end

-- After every pass: what the game sets again on a page change, and what loaded late.
local CHAR_REFIT = 10   -- passes at most waiting for the walk to reach the buttons
local function CharacterAfter(Kit, f)
	local tc = f.TitleContainer
	local title = Usable(tc) and tc.TitleText
	if Kind(title) == "FontString" then Kit.Light(title, Value()) end
	CharacterLists(Kit)
	SidePanes(Kit, f)
	ns.SideTilesPaintSoon()
	PaintSidebarSoon()
	if Controls() then Kit.RepaintSoon() end
	-- Buttons made wide enough for DaylightUI's font, once the walk has put it on them.
	local tries = 0
	local function refit()
		tries = tries + 1
		if Kit.Walking(f) and tries < CHAR_REFIT then
			C_Timer.After(0.1, refit)
			return
		end
		local detail = Usable(_G.TokenFrame) and _G.TokenFrame.DetailFrame
		if Usable(detail) then Refit(detail.CurrencyTransferToggleButton) end
		local rep = _G.ReputationFrame
		local repDetail = Usable(rep) and rep.ReputationDetailFrame
		if Usable(repDetail) then Refit(repDetail.ViewRenownButton) end
		local pd = _G.PaperDollFrame
		local pane = Usable(pd) and pd.EquipmentManagerPane
		if Usable(pane) then
			Refit(pane.EquipSet)
			Refit(pane.SaveSet)
		end
	end
	if Controls() then C_Timer.After(0, refit) end
end

local CharacterSoon
local function CharacterRun()
	char.queued = false
	local Kit, f = ns.Kit, _G.CharacterFrame
	if not Kit or not On() or not CharacterOnScreen() then return end
	if InCombatLockdown() then
		if not char.waiting then
			char.waiting = true
			ns.OutOfCombat(function() char.waiting = false CharacterSoon() end)
		end
		return
	end
	if Kit.Walking(f) then
		C_Timer.After(0.1, CharacterSoon)
		return
	end
	if not char.done then
		char.done = true
		Guard(CharacterChrome, Kit, f)
		if Controls() then Kit.Auto(f, CHAR_FIRST) else Plain(Kit, f, CHAR_DEPTH) end
	elseif Controls() then
		Kit.Auto(f, CHAR_AGAIN)
	else
		Plain(Kit, f, CHAR_DEPTH)
	end
	Guard(CharacterAfter, Kit, f)
end

CharacterSoon = function()
	if char.queued then return end
	char.queued = true
	C_Timer.After(0, CharacterRun)
end

local charOwner = {}
local function CharacterStart()
	if not Usable(_G.CharacterFrame) then return false end
	-- The game's own event (run apart from its code) when the window comes on screen, and after
	-- each ToggleCharacter (a page picked, the window opened or closed).
	local reg = _G.EventRegistry
	if type(reg) == "table" and type(reg.RegisterCallback) == "function" then
		reg:RegisterCallback("CharacterFrame.Show", function() if On() then CharacterSoon() end end, charOwner)
	end
	if type(_G.ToggleCharacter) == "function" then
		hooksecurefunc("ToggleCharacter", function() if On() then CharacterSoon() end end)
	end
	if CharacterOnScreen() then CharacterSoon() end
	return true
end

-- ---------------------------------------------------------------------------------------------
-- The currency transfer window and its log (Blizzard_TokenUI)
-- ---------------------------------------------------------------------------------------------

local function TransferEach(frame) if ns.Kit then ArtOff(ns.Kit, frame) end end

local function TransferAfter(f, Kit)
	local content = f.Content
	if not Usable(content) then return end
	-- The long arrow beside the source dropdown is one of the dropdown's own textures, which
	-- the dropdown's look clears: back, in the dim ink.
	local sel = content.SourceSelector
	local arrow = Usable(sel) and Usable(sel.Dropdown) and sel.Dropdown.LongArrow
	if IsTexture(arrow) then
		arrow:SetDesaturated(true)
		local d = Kit.DIM
		arrow:SetVertexColor(d[1], d[2], d[3])
		arrow:SetAlpha(1)
	end
	local amount = content.AmountSelector
	if Usable(amount) then Refit(amount.MaxQuantityButton) end
	Refit(content.ConfirmButton)
	Refit(content.CancelButton)
end

local function TransferStart(Kit)
	local menu, log = _G.CurrencyTransferMenu, _G.CurrencyTransferLog
	if not Usable(menu) then return false end
	if not dressed[menu] then
		dressed[menu] = true
		Kit.Window(menu)
		Kit.Erase(menu.CelebrationBackgroundFlash)
		if Controls() then
			ns.Walk(Kit, menu, nil, TransferAfter, TransferEach)
		else
			Plain(Kit, menu, 6)
		end
	end
	if Usable(log) and not dressed[log] then
		dressed[log] = true
		Kit.Window(log)
		if Controls() then
			ns.Walk(Kit, log, { rows = false }, nil, TransferEach)
			Lists(Kit, log.ScrollBox)
		else
			Plain(Kit, log, 4)
		end
	end
	return true
end

-- ---------------------------------------------------------------------------------------------
-- The spellbook and talents (Blizzard_PlayerSpells; protected: quiet, see Taint)
-- ---------------------------------------------------------------------------------------------

-- The search preview list (SpellSearchPreviewContainerTemplate) of the spellbook and the talents:
-- its border art off and a quiet window shell; each result (SpellSearchPreviewResultTemplate and
-- the suggested-result buttons) without its row art and icon frame, its highlight (shown by the
-- game on the mouse or keyboard pick) a soft accent wash. Looked over after the game's
-- UpdateResultsDisplay (a post-hook), next frame, out of combat.
local function PreviewRow(Kit, row)
	if not Usable(row) then return end
	if not dressed[row] then
		dressed[row] = true
		for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture" }) do
			local t = row[get] and row[get](row)
			if IsTexture(t) then Kit.Hide(t) end
		end
		Kit.Hide(row.IconFrame)
		FontOf(Kit, row.Name)
		FontOf(Kit, row.Text)
		if IsTexture(row.HighlightTexture) then
			row.HighlightTexture:SetBlendMode("BLEND")
			accented[row.HighlightTexture] = "fill"
		end
	end
	if IsTexture(row.HighlightTexture) then ns.FillAccent(row.HighlightTexture, 0.22, nil, KEY) end
end

local function PreviewRows(Kit, c)
	if not On() or InCombatLockdown() then return end
	local box = c.ScrollBox
	if Usable(box) and box.ForEachFrame then
		pcall(box.ForEachFrame, box, function(row) Guard(PreviewRow, Kit, row) end)
	end
	for _, b in ipairs({ c:GetChildren() }) do
		if Kind(b) == "Button" then Guard(PreviewRow, Kit, b) end
	end
	local over = c.OverflowCount
	if Usable(over) then FontOf(Kit, over.Text) end
end

local function SearchPreview(Kit, c)
	if not Usable(c) or dressed[c] then return end
	dressed[c] = true
	Kit.Strip(c)
	Kit.Shell(c, "window", QUIET)
	if type(c.UpdateResultsDisplay) == "function" then
		hooksecurefunc(c, "UpdateResultsDisplay", function(self)
			if On() then C_Timer.After(0, function() if ns.Kit then Guard(PreviewRows, ns.Kit, self) end end) end
		end)
	end
	PreviewRows(Kit, c)
end

-- The spellbook's page contents (PagedSpellsFrame's frames: SpellBookHeaderTemplate, a gold
-- header with a gold divider; SpellBookItemTemplate, a spell's name, subtext and level line, in
-- the game's parchment ink): headers in the value ink with the divider in the accent, names in
-- DaylightUI's text ink, the rest in its dim ink. The game dims an unlearned spell's words with
-- their alpha, which stays. Fonts and colors only: the spell buttons stay the game's.
local function SpellElement(Kit, el)
	if not Usable(el) then return end
	if Usable(el.Button) and Kind(el.Name) == "FontString" then
		Light(Kit, el.Name)
		Light(Kit, el.SubName, Kit.DIM)
		Light(Kit, el.RequiredLevel, Kit.DIM)
	elseif Kind(el.Text) == "FontString" and IsTexture(el.Border) then
		Light(Kit, el.Text, Value())
		if not dressed[el.Border] then
			dressed[el.Border] = true
			el.Border:SetDesaturated(true)
		end
		ns.PaintAccent(el.Border, 1, nil, KEY)
	end
end

local spells = { queued = false, waiting = false }

-- Really on screen: parented to UIParent (not parked under DaylightUI's Book veil, which is shown
-- at alpha 0, or its hidden holder), visible, and not faded out.
local function Really(f)
	if not (Usable(f) and f:GetParent() == UIParent and f:IsVisible()) then return false end
	local a = f.GetEffectiveAlpha and f:GetEffectiveAlpha()
	return type(a) ~= "number" or a > 0.01
end
local SpellsSoon
local function SpellPages()
	spells.queued = false
	local Kit, f = ns.Kit, _G.PlayerSpellsFrame
	if not Kit or not On() or not Really(f) then return end
	if InCombatLockdown() then
		if not spells.waiting then
			spells.waiting = true
			ns.OutOfCombat(function() spells.waiting = false SpellsSoon() end)
		end
		return
	end
	local book = f.SpellBookFrame
	local paged = Usable(book) and book.PagedSpellsFrame
	local frames = Usable(paged) and paged.frames
	if type(frames) ~= "table" then return end
	for _, el in ipairs(frames) do Guard(SpellElement, Kit, el) end
end

SpellsSoon = function()
	if spells.queued then return end
	spells.queued = true
	C_Timer.After(0, SpellPages)
end

-- The loadout dialogs (ClassTalentLoadoutDialogTemplate: a Title, a DialogBorderDarkTemplate
-- Border, text buttons, an InputBoxTemplate name box; the import dialog's InputScrollFrameTemplate
-- box): shown with StaticPopupSpecial_Show, so dressed ahead of time and quietly.
local function ImportBox(Kit, f)
	local control = f.ImportControl
	local box = Usable(control) and control.InputContainer
	if not Usable(box) or dressed[box] then return end
	dressed[box] = true
	Kit.Strip(box)
	Kit.Shell(box, "input")
	local eb = box.EditBox
	FontOf(Kit, eb)
	if Usable(eb) and Kind(eb.Instructions) == "FontString" then FontOf(Kit, eb.Instructions) end
	FontOf(Kit, box.CharCount)
	if Usable(box.ScrollBar) then Kit.ScrollBar(box.ScrollBar) end
end

local DIALOGS = { "ClassTalentLoadoutCreateDialog", "ClassTalentLoadoutEditDialog", "ClassTalentLoadoutImportDialog" }

local function Dialog(Kit, f)
	if not Usable(f) or dressed[f] then return end
	dressed[f] = true
	Kit.Strip(f)
	Kit.Hide(f.Border)
	Kit.Shell(f, "window", QUIET)
	Light(Kit, f.Title, Value())
	if Controls() then
		QuietControls(Kit, f, 4)
		ImportBox(Kit, f)
	end
	ns.Words(f, 4)
end

local spellsOwner = {}
local SPELL_EVENTS = { "PlayerSpellsFrame.OpenFrame", "PlayerSpellsFrame.TabSet", "PlayerSpellsFrame.SpellBookFrame.Show",
	"PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged" }

local function SpellsStart(Kit)
	local f = _G.PlayerSpellsFrame
	if not Usable(f) then return false end
	if InCombatLockdown() then return false end
	for _, name in ipairs(DIALOGS) do Guard(Dialog, Kit, _G[name]) end
	local talents = f.TalentsFrame
	if Usable(talents) and Controls() then
		local load = talents.LoadSystem
		if Usable(load) and Usable(load.Dropdown) then Kit.Dropdown(load.Dropdown) end
		StaticIconButton(Kit, talents.ResetButton)
		StaticIconButton(Kit, talents.UndoButton)
		local active = talents.ActiveSpec
		if Usable(active) then
			StaticButton(Kit, active.ActivateButton)
			FontOf(Kit, active.ActiveLabel)
		end
		SearchPreview(Kit, talents.SearchPreviewContainer)
	end
	local book = f.SpellBookFrame
	if Usable(book) and Controls() then SearchPreview(Kit, book.SearchPreviewContainer) end
	local reg = _G.EventRegistry
	if type(reg) == "table" and type(reg.RegisterCallback) == "function" then
		for _, event in ipairs(SPELL_EVENTS) do
			reg:RegisterCallback(event, function() if On() then SpellsSoon() end end, spellsOwner)
		end
	end
	if Really(f) then SpellsSoon() end
	return true
end

-- ---------------------------------------------------------------------------------------------
-- When: once the player is in the world and the Kit is there, each part as soon as its Blizzard
-- addon has loaded (out of combat). Packs/Blizzard.lua already registers Blizzard_PlayerSpells
-- with DaylightUI (a second registration would be dropped), so the loads are watched here.
-- ---------------------------------------------------------------------------------------------

local PARTS = {
	{ addon = nil, fn = CharacterStart },   -- (the character window is always there)
	{ addon = "Blizzard_TokenUI", fn = TransferStart },
	{ addon = "Blizzard_PlayerSpells", fn = SpellsStart },
}

local function Loaded(addon)
	local A = C_AddOns
	if type(A) ~= "table" or type(A.IsAddOnLoaded) ~= "function" then return false end
	local ok, loaded = pcall(A.IsAddOnLoaded, addon)
	return ok and loaded and true or false
end

local function TryParts()
	local Kit = ns.Kit
	if not Kit or not ns.loggedIn or not On() then return end
	for _, p in ipairs(PARTS) do
		if not p.done and (p.addon == nil or Loaded(p.addon)) then
			local ok, out = xpcall(p.fn, geterrorhandler(), Kit)
			p.done = ok and out ~= false
		end
	end
end

-- A style change (the accent): this file's own accent marks and rows again, and the spellbook's
-- headers (SpellsSoon). Only what this file painted; the rest is DaylightUI's and the Kit's.
local function Restyle()
	if not On() or not ns.Kit then return end
	PaintSidebarSoon()
	for tex, how in pairs(accented) do
		if Usable(tex) then
			if how == "fill" then ns.FillAccent(tex, 0.22, nil, KEY) else ns.PaintAccent(tex, 1, nil, KEY) end
		end
	end
	for row in pairs(ourRows) do
		if Usable(row) then ns.Kit.RepaintRow(row) end
	end
	SpellsSoon()
end
ns.me.On("StyleChanged", function() Guard(Restyle) end)

local function Soon() ns.OutOfCombat(TryParts) end
ns.WithKit(function() if ns.loggedIn then Soon() end end)
ns.me.On("Login", function() ns.WithKit(Soon) end)

local loads = CreateFrame("Frame")
loads:RegisterEvent("ADDON_LOADED")
loads:SetScript("OnEvent", function(self, _, name)
	local left = false
	for _, p in ipairs(PARTS) do
		if not p.done then left = true end
	end
	if not left then
		self:UnregisterEvent("ADDON_LOADED")
		return
	end
	for _, p in ipairs(PARTS) do
		if not p.done and p.addon == name then
			if ns.loggedIn and ns.Kit then Soon() end
			return
		end
	end
end)
