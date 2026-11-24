-- AtlasLoot Continued (the Forever build, 12978): every window it draws in the DaylightUI look.
-- Atlas Nav (12987+, its default style, db.GUI.style "nav"): the window, Favourites, the changelog,
-- the theme chooser and the settings keep AtlasLoot's own Nav look; nothing here touches them. The
-- legacy style (/al style legacy) is dressed as before. Told apart at hook time, the way AtlasLoot
-- does: the main window by GUI.Nav.active (set by Nav:Apply at the end of GUI:Create, cleared by
-- Nav:Revert when Nav fails and the classic window comes back), Favourites by what its Nav layer did
-- to the window (title strip and X hidden: Favourites_Nav's FN.applied is a local of its own), the
-- changelog by which window is shown (Nav draws AtlasLootChangelogNavFrame instead of the classic
-- AtlasLootChangelogFrame). The theme chooser (AtlasLoot_ThemeChoice-Frame), the Nav settings
-- (AtlasLoot_Settings-Frame) and Nav's tooltip and dropdown are Nav's own and never looked at here.
-- Switching style: the main window is built once a session (GUI:Create at GUI.Init) and AtlasLoot
-- asks for a reload (ATLASLOOT_RELOAD_STYLE), so a classic window dressed here stays dressed until
-- that reload, then Nav is drawn and this pack stands down. Favourites takes the style it finds on its
-- first open, the changelog on every show: both are judged when they're built or shown. With Nav the
-- main window's pages and popups (model, sounds, set strip, faction tooltip, previews, copy box)
-- are left as AtlasLoot draws them too.
-- Legacy style: it draws everything itself from a handful of builders of its own (GUI:Create, its
-- DropDown and Select lists, its item buttons, the model and sound pages, Favourites' window), on the flat
-- tooltip backdrop; those builders are followed here and what they drew is dressed in the same
-- moment (fast path: post-hooks on GUI:Create, ModelFrame:Create, SoundFrame:Create, Favourites'
-- GUI:Create and the lazy popups' builders; a watch by name stays behind each as the safety net).
-- Dressed here:
--   * The main window (AtlasLoot_GUI-Frame): its backdrop gives way to DaylightUI's window shell
--     (its own opacity, border and bevel when it has a look of its own), DaylightUI's X, its title
--     strip without its band (the title in the value ink), the "i" help button in the label ink,
--     the game-version box's gold lines a neutral edge (the version logo stays).
--   * The two dropdowns (module, subcategory) and their lists: the input look with a hover edge and
--     a chevron; each list category a DaylightUI panel, its heading in the label ink, its lines
--     with a white hover wash and the picked line's radio in the accent (the others' faded). A
--     category's own name color and an entry's own color stay.
--   * The three side lists (difficulty, bosses, extras): an input-look well, the scroll bar
--     DaylightUI's, each line a quiet row in the text ink with a white hover wash and the picked
--     line in an accent wash (its gold / silver pick coin hidden: the accent shows the pick; the
--     achievement, reputation and expansion marks stay).
--   * The content area: a DaylightUI inset shade with two faint rules; the content-colored title
--     and bottom bands off; the plain item ground the inset shade (a background image, when its
--     option is on, stays); the boss / page title in the value ink.
--   * The bottom row: Items, Model and Sounds DaylightUI's buttons, the page arrows DaylightUI's
--     page buttons, the search box DaylightUI's, the map / class filter / content phase buttons
--     in control boxes (their pictures kept, the class filter still grayed while off).
--   * Item buttons (30 per page, refilled on every page): the gold / blue hover a white wash
--     (their second icon too); a gold name in the label ink. Quality colors, quality borders,
--     the favorite star, the tick and the phase marks stay.
--   * The class filter's class menu (made on its first right-click): a DaylightUI panel, its
--     lines' hover a wash (each class's own color stays as their ground).
--   * The model page: the model's zoom / turn buttons DaylightUI's icon buttons (the boss portrait
--     buttons are the dungeon journal's portraits and stay).
--   * The sound page: its rows a faint wash (the light gray grounds off), their +/- a plain
--     glyph, the play button a page button, the stop button in a control box, the scroll bar.
--   * The item set strip (ExtraItemFrame), the faction tooltip (its standing bar in DaylightUI's
--     bar, its standing color kept), the item / set preview boxes (when this client has them) and
--     the WoWHead copy box: DaylightUI panels and an input box.
--   * Favourites (AtlasLoot_GUI-FavouritesFrame): the window shell, its four wells as insets, the
--     list dropdown, the Global lists switch, its buttons, the Add ItemID box, the scroll bar, the
--     slot and list buttons' hover a wash, the model's buttons.
--   * What's New (AtlasLootChangelogFrame, new in 12978; /al changelog): the window shell in place
--     of its teal ground, header art and footer band, the title in the value ink, the list well an
--     inset, the scroll bar, the "Show this window after an update" checkbox and Close DaylightUI's,
--     its section bands a faint wash and its rules hairlines (item links keep their quality colors).
--   * Text: DaylightUI's font on every word (sizes kept; the item counts keep their narrow number
--     face), its gold words in DaylightUI's inks.
-- Not here: the options window (AceConfig: DaylightUI's Ace3 skin and this plugin's Ace3 pack),
-- its tooltips (AtlasLootTooltip and the game's tooltip: DaylightUI's tooltip skin finds them),
-- the note popup (the game's static popup: Game windows), the minimap button (DaylightUI's addon
-- drawer), the game-version menu (never opens on Forever) and the dungeon art and maps (content).
-- No conflict with DaylightUI's modules (loot tables and drop rates are its own): no hand-over.
local _, ns = ...
if not ns.ok then return end

local KEY = "AtlasLootContinued"
-- (Its words are the game's serif font objects and fonts it picks from LibSharedMedia: the
-- player's font goes on all of them.)
local CAPS = { window = true, controls = true, text = true, shadow = true, colors = true, font = "daylight" }
ns.Target(KEY, "AtlasLoot Continued", CAPS)

local Usable, Guard = ns.Usable, ns.Guard
local ipairs, pairs, select, type = ipairs, pairs, select, type

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end
local function Kind(x) return Usable(x) and x:GetObjectType() or nil end
local function IsTexture(x) return Kind(x) == "Texture" end

-- Pieces of AtlasLoot's already dressed (its own frames: nothing of the game's is marked).
local dressed = setmetatable({}, { __mode = "k" })
local function Once(x)
	if not x or dressed[x] then return false end
	dressed[x] = true
	return true
end

-- First dressing waits out a fight (AtlasLoot's frames aren't protected, but nothing is dressed
-- for the first time in combat).
local function Calm(fn, ...)
	local n, a = select("#", ...), { ... }
	if InCombatLockdown() then
		ns.OutOfCombat(function() Guard(fn, unpack(a, 1, n)) end)
	else
		Guard(fn, ...)
	end
end

local function Ink(fs, name)
	if Kind(fs) ~= "FontString" then return end
	local c = ns.Colors()[name]
	if c then fs:SetTextColor(c[1], c[2], c[3]) end
end

-- Its gold / blue hover art (UI-QuestTitleHighlight, the mouse glow) as a white wash.
local function Wash(btn, alpha)
	local hl = btn and btn.GetHighlightTexture and btn:GetHighlightTexture()
	if not IsTexture(hl) then return end
	hl:SetTexCoord(0, 1, 0, 1)
	hl:SetColorTexture(1, 1, 1, alpha or 0.06)
	hl:SetBlendMode("BLEND")
end

-- A flat tooltip backdrop off (its pieces faded: the addon recolors them on every refresh).
local function NoBack(frame)
	local Kit = ns.Kit
	if Kit and Usable(frame) then Kit.Backdrop(frame) end
end

-- ---------------------------------------------------------------------------------------------
-- Text: the player's font on every string (the item counts' narrow number face stays), gold words
-- in DaylightUI's inks.
-- ---------------------------------------------------------------------------------------------

local SKIP_KINDS = { Model = true, PlayerModel = true, DressUpModel = true, ModelScene = true, GameTooltip = true,
	Cooldown = true }

-- Whether a font file is the narrow number face (each path tested once: a handful come back on
-- every walk).
local narrow = {}
local function Narrow(path)
	local yes = narrow[path]
	if yes == nil then
		yes = string.find(string.upper(path), "ARIALN", 1, true) ~= nil
		narrow[path] = yes
	end
	return yes
end

local function FontsAmong(...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if Kind(r) == "FontString" then
			local ok, path = pcall(r.GetFont, r)
			if not (ok and type(path) == "string" and Narrow(path)) then
				ns.FollowFont(r, KEY)
			end
		end
	end
end

local Words
-- (The children as the game hands them back, taken once per frame: taking them again for each one
-- grew with the square of their number.)
local function WordsAmong(depth, ...)
	for i = 1, select("#", ...) do Words((select(i, ...)), depth) end
end

Words = function(f, depth)
	if depth > 8 or not Usable(f) or SKIP_KINDS[f:GetObjectType()] then return end
	local Kit = ns.Kit
	if f.GetRegions then
		if not ns.PlainText(KEY) then FontsAmong(f:GetRegions()) end
		if Kit then Kit.InkGameText(f) end
	end
	if f:GetObjectType() == "EditBox" and not ns.PlainText(KEY) then ns.FollowFont(f, KEY) end
	if f.GetChildren then WordsAmong(depth + 1, f:GetChildren()) end
end

local function WordsIn(f)
	if On() and Usable(f) then Guard(Words, f, 0) end
end

-- ---------------------------------------------------------------------------------------------
-- The accent pieces (picked side-list lines, picked dropdown radios), painted again when the look
-- changes.
-- ---------------------------------------------------------------------------------------------

local picks = setmetatable({}, { __mode = "k" })   -- texture -> alpha

local function PaintPick(tex, alpha)
	picks[tex] = alpha
	ns.FillAccent(tex, alpha, nil, KEY)
end

local radios = setmetatable({}, { __mode = "k" })  -- radio texture -> whether it's the picked one

local function PaintRadio(tex, on)
	radios[tex] = on and true or false
	tex:SetDesaturated(true)
	if on then
		tex:SetVertexColor(ns.AccentOf(KEY))
		tex:SetAlpha(1)
	else
		local c = ns.Colors().OFF or { 0.5, 0.5, 0.5 }
		tex:SetVertexColor(c[1], c[2], c[3])
		tex:SetAlpha(0.6)
	end
end

local function Repaint()
	if not On() then return end
	for tex, alpha in pairs(picks) do ns.FillAccent(tex, alpha, nil, KEY) end
	for tex, on in pairs(radios) do PaintRadio(tex, on) end
end
ns.me.On("StyleChanged", function() Guard(Repaint) end)
ns.me.On("SettingChanged", function(scope) if scope == "DaylightAddonSkins" then Guard(Repaint) end end)

-- ---------------------------------------------------------------------------------------------
-- Its controls
-- ---------------------------------------------------------------------------------------------

-- A UIPanelButtonTemplate button (GUI.CreateButton).
local function TextButton(btn)
	local Kit = ns.Kit
	if not Kit or not Controls() or Kind(btn) ~= "Button" or not Once(btn) then return end
	Guard(Kit.Button, btn)
end

-- A button whose picture is the point (class filter, content phase, map): the picture inset in a
-- control box with the hover trace. tex = its picture (re-placed inside the box).
local function PictureButton(btn, tex, pad)
	local Kit = ns.Kit
	if not Kit or not Controls() or Kind(btn) ~= "Button" or not Once(btn) then return end
	if IsTexture(tex) then
		pad = pad or 3
		tex:ClearAllPoints()
		tex:SetPoint("TOPLEFT", btn, "TOPLEFT", pad, -pad)
		tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -pad, pad)
	end
	Guard(Kit.ArtButton, btn, pad or 3)
end

-- The "i" help button (UIPanelInfoButton): its gold ring and letter in the label ink.
local function InfoButton(btn)
	if Kind(btn) ~= "Button" or not Once(btn) then return end
	local c = ns.Colors().LABEL
	for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture" }) do
		local t = btn[get] and btn[get](btn)
		if IsTexture(t) then
			t:SetDesaturated(true)
			if c then t:SetVertexColor(c[1], c[2], c[3]) end
		end
	end
	Wash(btn, 0.1)
end

-- Its title strip (GUI.CreateTextWithBg): the band off, the words in the value ink.
local function TitleStrip(strip)
	if not Usable(strip) then return end
	if Once(strip) then NoBack(strip) end
	if Kind(strip.text) == "FontString" then
		if not ns.PlainText(KEY) then ns.FollowFont(strip.text, KEY) end
		Ink(strip.text, "VALUE")
	end
end

-- An old-style scroll bar (UIPanelScrollBarTemplate slider): DaylightUI's slim bar.
local function ScrollBar(bar)
	local Kit = ns.Kit
	if not Kit or not Controls() or Kind(bar) ~= "Slider" or not Once(bar) then return end
	Guard(Kit.ScrollBar, bar)
end

-- A ModelWithControlsTemplate model's zoom / turn / reset buttons as DaylightUI's icon buttons.
local function ModelControls(model)
	local Kit = ns.Kit
	if not Kit or not Controls() or not Usable(model) then return end
	local controls = model.controlFrame or model.ControlFrame
	if not Usable(controls) or not Once(controls) then return end
	Kit.Strip(controls)
	for i = 1, select("#", controls:GetChildren()) do
		local b = select(i, controls:GetChildren())
		if Kind(b) == "Button" and IsTexture(b.icon or b.Icon) then Guard(Kit.IconButton, b, 1) end
	end
end

-- ---------------------------------------------------------------------------------------------
-- Dropdowns (GUI:CreateDropDown) and their lists
-- ---------------------------------------------------------------------------------------------

-- One line of an open list (pooled: moved between categories and lists, painted on every open).
local function ListLine(btn, dropdown)
	if not Usable(btn) then return end
	if Once(btn) then
		Wash(btn, 0.08)
		if not ns.PlainText(KEY) then ns.FollowFont(btn.label, KEY) end
	end
	-- (A line it gave no color is its white: left as it is. A gold one goes to the label ink.)
	local Kit = ns.Kit
	if Kit then Kit.InkGameText(btn) end
	if IsTexture(btn.check) and btn.check:IsShown() then
		PaintRadio(btn.check, btn.id ~= nil and btn.id == dropdown.selectedId)
	end
end

-- A list category (a panel of its own under the dropdown).
local function ListCategory(cat, dropdown)
	if not Usable(cat) then return end
	if Once(cat) then
		NoBack(cat)
		ns.Shell(cat, nil, KEY)
	end
	if Kind(cat.label) == "FontString" then
		if not ns.PlainText(KEY) then ns.FollowFont(cat.label, KEY) end
		local Kit = ns.Kit
		if Kit then Kit.InkGameText(cat) end
	end
	if type(cat.buttons) == "table" then
		for _, btn in ipairs(cat.buttons) do ListLine(btn, dropdown) end
	end
end

-- The open list: its categories are the dropdown's children with a button list.
local function OpenList(dropdown)
	if not On() or type(dropdown) ~= "table" or not Usable(dropdown.frame) then return end
	local f = dropdown.frame
	for i = 1, select("#", f:GetChildren()) do
		local c = select(i, f:GetChildren())
		if Kind(c) == "Frame" and type(c.buttons) == "table" and c:IsShown() then ListCategory(c, dropdown) end
	end
end

local function Dropdown(dropdown)
	local Kit = ns.Kit
	if not Kit or type(dropdown) ~= "table" or not Usable(dropdown.frame) or not Once(dropdown.frame) then return end
	local f = dropdown.frame
	if Controls() then
		NoBack(f)
		local s = Kit.Shell(f, "input")
		f:HookScript("OnEnter", function() if On() then Kit.Paint(s, Kit.ROW_HOVER) end end)
		f:HookScript("OnLeave", function() if On() then Kit.Paint(s, nil) end end)
		if Kind(f.button) == "Button" then
			Guard(Kit.BareButton, f.button, "down")
			f.button:HookScript("OnEnter", function() if On() then Kit.Paint(s, Kit.ROW_HOVER) end end)
			f.button:HookScript("OnLeave", function() if On() then Kit.Paint(s, nil) end end)
		end
	end
	if not ns.PlainText(KEY) then
		ns.FollowFont(f.label, KEY)
		ns.FollowFont(f.title, KEY)
	end
	Ink(f.title, "LABEL")
	-- Its list is made on the click (by the dropdown or its arrow): dressed right after.
	local function open() Guard(OpenList, dropdown) end
	f:HookScript("OnClick", open)
	if Kind(f.button) == "Button" then f.button:HookScript("OnClick", open) end
end

-- ---------------------------------------------------------------------------------------------
-- Side lists (GUI:CreateSelect): difficulty, bosses, extras
-- ---------------------------------------------------------------------------------------------

local COINS
local function IsPickCoin(tex)
	if not COINS then
		COINS = ns.FileIDs({ ["Interface\\MoneyFrame\\UI-GoldIcon"] = true, ["Interface\\MoneyFrame\\UI-SilverIcon"] = true })
	end
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return false end
	if type(file) == "string" then file = string.lower(file) end
	return COINS[file] == true
end

local function SelectLine(row)
	if Kind(row) ~= "CheckButton" then return end
	if Once(row) then
		Wash(row, 0.06)
		local checked = row.GetCheckedTexture and row:GetCheckedTexture()
		if IsTexture(checked) then
			checked:SetTexCoord(0, 1, 0, 1)
			PaintPick(checked, 0.18)
		end
		if Kind(row.label) == "FontString" then
			if not ns.PlainText(KEY) then ns.FollowFont(row.label, KEY) end
			Ink(row.label, "TEXT")
		end
	end
	-- Its plain gold / silver coin only marks the pick, which the accent wash shows now.
	local coin = row.coin
	if IsTexture(coin) then coin:SetAlpha(IsPickCoin(coin) and 0 or 1) end
end

local function SelectLines(obj)
	if not On() or type(obj) ~= "table" or type(obj.buttons) ~= "table" then return end
	for _, row in ipairs(obj.buttons) do SelectLine(row) end
end

local function Select(obj)
	local Kit = ns.Kit
	if not Kit or type(obj) ~= "table" or not Usable(obj.frame) or not Once(obj.frame) then return end
	if Controls() then
		NoBack(obj.frame)
		Kit.Shell(obj.frame, "input")
	end
	ScrollBar(obj.frame.scrollbar)
	-- Lines are made (from a pool shared by all three) on every fill, and their coins set on every
	-- pick and scroll.
	local function again() Guard(SelectLines, obj) end
	for _, m in ipairs({ "UpdateContent", "SetSelected" }) do
		if type(obj[m]) == "function" then hooksecurefunc(obj, m, again) end
	end
	if Usable(obj.frame.scrollbar) then obj.frame.scrollbar:HookScript("OnValueChanged", again) end
	again()
end

-- ---------------------------------------------------------------------------------------------
-- Item buttons (AtlasLoot.Button:Create / CreateSecOnly)
-- ---------------------------------------------------------------------------------------------

local function ItemButton(btn)
	if not Usable(btn) or not Once(btn) then return end
	if Kind(btn) == "Button" then Wash(btn, 0.06) end
	if Usable(btn.secButton) then Wash(btn.secButton, 0.12) end
end

local function ItemButtons(list)
	if type(list) ~= "table" then return end
	for _, btn in pairs(list) do
		ItemButton(btn)
		local Kit = ns.Kit
		if Kit and Usable(btn) then Kit.InkGameText(btn) end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The main window
-- ---------------------------------------------------------------------------------------------

local function AL() return _G.AtlasLoot end

-- Atlas Nav drawn over the main window right now (12987+; nil before it: the classic window).
local function NavMain()
	local A = AL()
	local N = A and type(A.GUI) == "table" and A.GUI.Nav
	return type(N) == "table" and N.active == true
end

-- Favourites' window in its Atlas Nav look: FN:Apply hides its title strip and its X (FN:Revert,
-- when Nav fails, shows them again).
local function NavFavourites(f)
	local A = AL()
	if not (A and type(A.GUI) == "table" and type(A.GUI.Nav) == "table") then return false end
	return Usable(f.titleFrame) and not f.titleFrame:IsShown() and Usable(f.CloseButton) and not f.CloseButton:IsShown()
end

-- The content area's inset: a shade and two faint rules of ours (its own colored bands off).
local function ContentArea(cf)
	if not Usable(cf) or not Once(cf) then return end
	local Kit = ns.Kit
	Kit.Hide(cf.topBG)
	Kit.Hide(cf.downBG)
	local shade = cf:CreateTexture(nil, "BACKGROUND", nil, -8)
	shade:SetColorTexture(0, 0, 0, Kit.INSET_SHADE or 0.3)
	shade:SetAllPoints(cf)
	for _, band in ipairs({ cf.topBG, cf.downBG }) do
		if IsTexture(band) then
			local line = cf:CreateTexture(nil, "BORDER")
			line:SetColorTexture(1, 1, 1, 0.08)
			line:SetHeight(1)
			line:SetPoint("LEFT", band, "LEFT", 0, 0)
			line:SetPoint("RIGHT", band, "RIGHT", 0, 0)
			line:SetPoint(band == cf.topBG and "BOTTOM" or "TOP", band, band == cf.topBG and "BOTTOM" or "TOP", 0, 0)
		end
	end
end

-- Its plain item ground (no background image) is AtlasLoot's near-black box: the inset's shade.
local function ItemGround()
	local A = AL()
	local G = A and A.GUI
	local f = G and G.frame
	local cf = f and f.contentFrame
	if not On() or not Usable(cf) or not IsTexture(cf.itemBG) then return end
	local db = A.db and A.db.GUI
	local image = db and db.content and db.content.showBgImage and G.curBgInfo and G.curBgInfo[2]
	if not image then
		cf.itemBG:SetColorTexture(0, 0, 0, 0)
		cf.itemBG:SetAlpha(1)
	end
end

-- Its two title strings, which it sets a LibSharedMedia font and color on (RefreshFonts).
local function Titles()
	local A = AL()
	local f = A and A.GUI and A.GUI.frame
	if not On() or not Usable(f) then return end
	TitleStrip(f.titleFrame)
	local cf = f.contentFrame
	if Usable(cf) and Kind(cf.title) == "FontString" then
		if not ns.PlainText(KEY) then ns.FollowFont(cf.title, KEY) end
		Ink(cf.title, "VALUE")
	end
end

-- The class filter's class menu, made on its first right-click.
local function ClassMenu(btn)
	local menu = btn and btn.selectionFrame
	if not On() or not Usable(menu) or not Once(menu) then return end
	NoBack(menu)
	ns.Shell(menu, nil, KEY)
	for _, b in ipairs(menu.buttons or {}) do
		if Usable(b) then
			Wash(b, 0.12)
			if Kind(b.text) == "FontString" then
				if not ns.PlainText(KEY) then ns.FollowFont(b.text, KEY) end
				Ink(b.text, "VALUE")
			end
		end
	end
end

local function MainWindow(f)
	local Kit = ns.Kit
	-- (Atlas Nav over it: its own look, nothing of ours.)
	if not Kit or not Usable(f) or not On() or NavMain() or not Once(f) then return end
	local A = AL()
	local G = A.GUI
	NoBack(f)
	ns.Shell(f, { window = true }, KEY)
	if Controls() and Usable(f.CloseButton) then Guard(Kit.Close, f.CloseButton) end
	TitleStrip(f.titleFrame)
	if Usable(f.titleFrame) then InfoButton(f.titleFrame.infoButton) end
	-- The game-version box: its four gold lines a neutral edge, its glow off.
	local gv = f.gameVersionButton
	if Usable(gv) then
		local n = Kit.TAB_BORDER or { 0.3, 0.3, 0.32 }
		for _, line in ipairs(gv.Box or {}) do
			if Usable(line) and line.SetColorTexture then line:SetColorTexture(n[1], n[2], n[3], 0.8) end
		end
		Kit.Hide(gv:GetHighlightTexture())
	end
	Dropdown(f.moduleSelect)
	Dropdown(f.subCatSelect)
	Select(f.difficulty)
	Select(f.boss)
	Select(f.extra)
	local cf = f.contentFrame
	if Usable(cf) then
		ContentArea(cf)
		TextButton(cf.itemsButton)
		TextButton(cf.modelButton)
		TextButton(cf.soundsButton)
		if Controls() then
			Guard(Kit.PageButton, cf.prevPageButton, "left")
			Guard(Kit.PageButton, cf.nextPageButton, "right")
			if Kind(cf.searchBox) == "EditBox" then Guard(Kit.EditBox, cf.searchBox) end
		end
		local map = cf.mapButton
		if Usable(map) then
			Kit.Hide(map.highlight)
			PictureButton(map, map.texture, 2)
		end
		PictureButton(cf.clasFilterButton, cf.clasFilterButton and cf.clasFilterButton.texture)
		PictureButton(cf.contentPhaseButton, cf.contentPhaseButton and cf.contentPhaseButton.texture)
		if Usable(cf.clasFilterButton) then
			cf.clasFilterButton:HookScript("OnClick", function(self) Guard(ClassMenu, self) end)
		end
	end
	-- Item buttons: made with the window; refilled (and re-colored) on every page.
	local items = G.ItemFrame and G.ItemFrame.frame
	if Usable(items) then ItemButtons(items.ItemButtons) end
	Titles()
	ItemGround()
	WordsIn(f)
	f:HookScript("OnShow", function() if On() then WordsIn(f) end end)
end

-- ---------------------------------------------------------------------------------------------
-- Pages made later: the model page, the sound page
-- ---------------------------------------------------------------------------------------------

local function ModelPage()
	local A = AL()
	local M = A and A.GUI and A.GUI.ModelFrame
	if not On() or NavMain() or not M or not Usable(M.frame) or not Once(M.frame) then return end
	ModelControls(M.frame)
end

local grounds = setmetatable({}, { __mode = "k" })  -- sound row -> its ground of ours
local glyphs = setmetatable({}, { __mode = "k" })   -- +/- button -> its glyph of ours

local function SoundRows()
	local A = AL()
	local S = A and A.GUI and A.GUI.SoundFrame
	local f = S and S.frame
	if not On() or not Usable(f) or type(f.buttons) ~= "table" then return end
	local Kit = ns.Kit
	for _, row in ipairs(f.buttons) do
		if Usable(row) then
			if Once(row) then
				Kit.Hide(row.bg)
				local ground = row:CreateTexture(nil, "BACKGROUND", nil, 1)
				ground:SetAllPoints(row)
				grounds[row] = ground
				local c = row.collapse
				if Kind(c) == "Button" then
					for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture" }) do
						local t = c[get] and c[get](c)
						if IsTexture(t) then Kit.Erase(t) end
					end
					local glyph = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
					glyph:SetPoint("CENTER", c, "CENTER", 0, 1)
					Ink(glyph, "TEXT")
					glyphs[c] = glyph
				end
				if Controls() then
					Guard(Kit.PageButton, row.play, "right")
					PictureButton(row.stop, row.stop and row.stop:GetNormalTexture(), 3)
				end
			end
			-- A sound's own row (+/- shown) a little lighter than its files' rows.
			local head = Usable(row.collapse) and row.collapse:IsShown()
			if grounds[row] then grounds[row]:SetColorTexture(1, 1, 1, head and 0.05 or 0.02) end
			local glyph = head and glyphs[row.collapse]
			if glyph then
				-- (Its "collapsed" flag is set while a sound's files are listed: open.)
				local info = row.collapse.info
				glyph:SetText((type(info) == "table" and info.collapsed) and "-" or "+")
			end
		end
	end
	WordsIn(f)
end

-- A scroll or a click runs both its Refresh and the scroll bar's or button's own script, each of
-- which repaints (a walk of the whole page's words): the first in a frame repaints at once, so the
-- rows are dressed before they're drawn; any more in that frame are folded into one pass after it.
local soundRowsAt
local function SoundRowsSoon()
	local now = GetTime()
	if soundRowsAt ~= now then
		soundRowsAt = now
		Guard(SoundRows)
	else
		ns.Queue("AtlasLootSoundRows", SoundRows, KEY)
	end
end

local function SoundPage()
	local A = AL()
	local S = A and A.GUI and A.GUI.SoundFrame
	local f = S and S.frame
	if not On() or NavMain() or not Usable(f) or not Once(f) then return end
	ScrollBar(f.scrollbar)
	local function again() SoundRowsSoon() end
	for _, row in ipairs(f.buttons or {}) do
		if Usable(row) and Usable(row.collapse) then row.collapse:HookScript("OnClick", again) end
	end
	if Usable(f.scrollbar) then f.scrollbar:HookScript("OnValueChanged", again) end
	again()
end

-- ---------------------------------------------------------------------------------------------
-- Its popups: the item set strip, the copy box, the faction tooltip, the preview boxes
-- ---------------------------------------------------------------------------------------------

-- The set strip (ExtraItemFrame): a child of the item page's window with an AddButton of its own.
local function ExtraStrip(button)
	local parent = Usable(button) and button:GetParent()
	parent = Usable(parent) and parent:GetParent()
	if NavMain() or not Usable(parent) then return end
	for i = 1, select("#", parent:GetChildren()) do
		local c = select(i, parent:GetChildren())
		if Usable(c) and type(c.AddButton) == "function" and type(c.Container) == "table" then
			if Once(c) then
				NoBack(c)
				ns.Shell(c, nil, KEY)
			end
			for b in pairs(c.Container) do ItemButton(b) end
			for _, b in ipairs(c.ShownContainer or {}) do ItemButton(b) end
		end
	end
end

-- The WoWHead copy box: an edit box made on its first use, under the item's button.
local function CopyBox(button)
	local Kit = ns.Kit
	if not Kit or NavMain() or not Usable(button) then return end
	for i = 1, select("#", button:GetChildren()) do
		local c = select(i, button:GetChildren())
		if Kind(c) == "EditBox" and type(c.SetCopyText) == "function" and Once(c) then
			Kit.Hide(c.bg)
			Kit.Shell(c, "input")
			if not ns.PlainText(KEY) then ns.FollowFont(c, KEY) end
		end
	end
end

local function FactionTip(T)
	local Kit = ns.Kit
	local f = T and T.tooltipFrame
	if not Kit or NavMain() or not Usable(f) or not Once(f) then return end
	NoBack(f)
	ns.Shell(f, nil, KEY)
	local st = f.standing
	if Usable(st) then
		NoBack(st)
		-- (Its standing color, set on every show, is kept: only the texture and the box change.)
		if Kind(st.bar) == "StatusBar" then Guard(Kit.StatusBar, st.bar) end
	end
	WordsIn(f)
end

local function PreviewBox(f)
	local Kit = ns.Kit
	if not Kit or NavMain() or not Usable(f) or not Once(f) then return end
	NoBack(f)
	ns.Shell(f, nil, KEY)
	if Usable(f.modelFrame) then NoBack(f.modelFrame) end
	if Usable(f.bonusDataFrame) then
		NoBack(f.bonusDataFrame)
		ns.Shell(f.bonusDataFrame, nil, KEY)
	end
	WordsIn(f)
end

-- ---------------------------------------------------------------------------------------------
-- Favourites
-- ---------------------------------------------------------------------------------------------

local function FavSlots(list)
	if type(list) ~= "table" then return end
	for _, b in pairs(list) do
		if Kind(b) == "Button" and Once(b) then
			Wash(b, 0.12)
			if IsTexture(b.icon) then b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
		end
	end
end

local function Favourites(f)
	local Kit = ns.Kit
	-- (Its Atlas Nav look, from Favourites_Nav's GUI:Create: its own, nothing of ours.)
	if not Kit or not Usable(f) or not On() or NavFavourites(f) or not Once(f) then return end
	NoBack(f)
	ns.Shell(f, { window = true }, KEY)
	if Controls() and Usable(f.CloseButton) then Guard(Kit.Close, f.CloseButton) end
	TitleStrip(f.titleFrame)
	InfoButton(f.infoButton)
	local c = f.content
	if Usable(c) then
		for _, k in ipairs({ "slotBg", "headerBg", "bottomBg", "itemListBg" }) do
			if Usable(c[k]) then Guard(Kit.Inset, c[k]) end
		end
		Dropdown(c.listSelect)
		if Controls() then
			local check = type(c.isGlobal) == "table" and c.isGlobal.frame
			if Kind(check) == "CheckButton" and Once(check) then Guard(Kit.Check, check) end
			if Kind(c.editBox) == "EditBox" then Guard(Kit.EditBox, c.editBox) end
		end
		TextButton(c.optionsButton)
		TextButton(c.chatLinkButton)
		TextButton(c.showAllItems)
		local sf = c.scrollFrame
		if Usable(sf) then
			Kit.Hide(sf.scrollbg)
			ScrollBar(sf.scrollbar)
			FavSlots(sf.itemButtons)
			-- Its item list's buttons are made as a list first fills it (SetItems) and scrolls.
			if type(sf.SetItems) == "function" then
				hooksecurefunc(sf, "SetItems", function() if On() then FavSlots(sf.itemButtons) end end)
			end
			if Usable(sf.scrollbar) then
				sf.scrollbar:HookScript("OnValueChanged", function() if On() then FavSlots(sf.itemButtons) end end)
			end
		end
		local slots = c.slotFrame
		if Usable(slots) then
			FavSlots(slots.slots)
			ModelControls(slots.modelFrame)
		end
	end
	WordsIn(f)
	f:HookScript("OnShow", function()
		if not On() then return end
		if Usable(c) and Usable(c.scrollFrame) then FavSlots(c.scrollFrame.itemButtons) end
		WordsIn(f)
	end)
end

local function FavGUI()
	local A = AL()
	local fav = A and A.Addons and type(A.Addons.GetAddon) == "function" and A.Addons:GetAddon("Favourites")
	return type(fav) == "table" and type(fav.GUI) == "table" and fav.GUI or nil
end

local function FavNow()
	local G = FavGUI()
	if G and Usable(G.frame) then Calm(Favourites, G.frame) end
end

local favHooked = false
local function FollowFavourites()
	local G = FavGUI()
	if favHooked or not G then return end
	favHooked = true
	if type(G.Create) == "function" then hooksecurefunc(G, "Create", FavNow) end
	-- (Its list fills its item buttons as a list or slot is picked.)
	if type(G.ItemListUpdate) == "function" then
		hooksecurefunc(G, "ItemListUpdate", function()
			local f = G.frame
			if On() and Usable(f) and dressed[f] and Usable(f.content) and Usable(f.content.scrollFrame) then
				FavSlots(f.content.scrollFrame.itemButtons)
			end
		end)
	end
	FavNow()
end

-- ---------------------------------------------------------------------------------------------
-- What's New (AtlasLootChangelogFrame, 12978): made on its first show, three seconds after the
-- first login following an update, or by /al changelog
-- ---------------------------------------------------------------------------------------------

-- Its lines (pooled, filled again on every show): the section band's gold-tabbed art a faint wash,
-- the rule under an entry's title a hairline. (Their words: WordsIn, after every fill.)
local function ChangelogRows(content)
	if not Usable(content) then return end
	for i = 1, select("#", content:GetChildren()) do
		local row = select(i, content:GetChildren())
		if Kind(row) == "Button" and Once(row) then
			if IsTexture(row.bg) then
				row.bg:SetTexCoord(0, 1, 0, 1)
				row.bg:SetColorTexture(1, 1, 1, 0.05)
			end
			if IsTexture(row.line) then
				row.line:SetTexCoord(0, 1, 0, 1)
				row.line:SetColorTexture(1, 1, 1, 0.08)
				row.line:SetHeight(1)
				row.line:ClearAllPoints()
				row.line:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
				row.line:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
			end
		end
	end
end

local function ChangelogWindow(f)
	local Kit = ns.Kit
	if not Kit or not Usable(f) or not On() then return end
	if Once(f) then
		NoBack(f)
		-- Its teal ground, header art (with its badge) and footer band give way to the window shell.
		for _, k in ipairs({ "ground", "titleBar", "footerBar", "footerLine" }) do
			if IsTexture(f[k]) then Kit.Hide(f[k]) end
		end
		ns.Shell(f, { window = true }, KEY)
		if Kind(f.title) == "FontString" then
			-- (It sat 46 px in, clear of the badge.)
			if IsTexture(f.titleBar) then
				f.title:ClearAllPoints()
				f.title:SetPoint("LEFT", f.titleBar, "LEFT", 12, 0)
			end
			Ink(f.title, "VALUE")
		end
		if Usable(f.panel) then
			NoBack(f.panel)
			Guard(Kit.Inset, f.panel)
		end
		TextButton(f.okButton)
		if Controls() and Kind(f.autoShow) == "CheckButton" and Once(f.autoShow) then Guard(Kit.Check, f.autoShow) end
		local scroll = f.scroll
		if Usable(scroll) then
			local name = scroll.GetName and scroll:GetName()
			ScrollBar(scroll.ScrollBar or (name and _G[name .. "ScrollBar"]))
		end
	end
	local content = Usable(f.scroll) and f.scroll.GetScrollChild and f.scroll:GetScrollChild()
	ChangelogRows(content)
	WordsIn(f)
end

local function ChangelogNow()
	-- (The classic window, shown in the legacy style or when Nav's AtlasLootChangelogNavFrame can't
	-- be drawn; with Nav it stays hidden and the Nav window keeps its own look.)
	local f = _G.AtlasLootChangelogFrame
	if Usable(f) and f:IsShown() then Calm(ChangelogWindow, f) end
end

-- ---------------------------------------------------------------------------------------------
-- Hooks: each builder and refresh of its own, followed where it's called (table fields, looked up
-- at call time)
-- ---------------------------------------------------------------------------------------------

local function MainNow()
	local A = AL()
	local f = A and A.GUI and A.GUI.frame
	if Usable(f) then Calm(MainWindow, f) end
end

local function Hook(t, name, fn)
	if type(t) == "table" and type(t[name]) == "function" then hooksecurefunc(t, name, fn) end
end

local function FollowAll()
	local A = AL()
	if type(A) ~= "table" or type(A.GUI) ~= "table" then return end
	local G = A.GUI
	Hook(G, "Create", MainNow)
	-- Its refreshes put its LibSharedMedia font, its colors and its grounds back.
	Hook(G, "RefreshFonts", function() if On() and dressed[G.frame] then Guard(Titles) end end)
	Hook(G, "RefreshContentBackGround", function() if dressed[G.frame] then Guard(ItemGround) end end)
	Hook(G, "ShowLoadingInfo", function()
		local cf = G.frame and G.frame.contentFrame
		if On() and not NavMain() and Usable(cf) and not ns.PlainText(KEY) then ns.FollowFont(cf.loadingDataText, KEY) end
	end)
	-- Every page fill ends in UpdateFilter: the item buttons' words re-inked.
	local IF = G.ItemFrame
	Hook(IF, "UpdateFilter", function()
		if On() and IF.frame and dressed[G.frame] then Guard(ItemButtons, IF.frame.ItemButtons) end
	end)
	local MF = G.ModelFrame
	Hook(MF, "Create", function() Calm(ModelPage) end)
	local SF = G.SoundFrame
	Hook(SF, "Create", function() Calm(SoundPage) end)
	Hook(SF, "Refresh", function() if SF.frame and dressed[SF.frame] then SoundRowsSoon() end end)
	-- Atlas Nav failing later (a refresh error) puts the classic window back: dressed then.
	Hook(G.Nav, "Revert", MainNow)
	local B = A.Button
	if type(B) == "table" then
		Hook(B, "ExtraItemFrame_GetFrame", function(_, button) if On() then Calm(ExtraStrip, button) end end)
		Hook(B, "CopyBox_Show", function(_, button) if On() then Calm(CopyBox, button) end end)
		local function typeOf(name)
			local ok, t = pcall(B.GetType, B, name)
			return ok and type(t) == "table" and t or nil
		end
		local faction = typeOf("Faction")
		Hook(faction, "ShowToolTipFrame", function() if On() then Calm(FactionTip, faction) end end)
		local item = typeOf("Item")
		Hook(item, "ShowQuickDressUp", function() if On() and item then Calm(PreviewBox, item.previewTooltipFrame) end end)
		local set = typeOf("Set")
		Hook(set, "ShowToolTipFrame", function() if On() and set then Calm(PreviewBox, set.tooltipFrame) end end)
	end
	-- What's New: its window is made in its Show (and its lines filled there, on every show).
	Hook(A.Changelog, "Show", ChangelogNow)
	-- Already made (this ran after its load): dressed now.
	MainNow()
	ChangelogNow()
	if MF and Usable(MF.frame) then Calm(ModelPage) end
	if SF and Usable(SF.frame) then Calm(SoundPage) end
end

ns.Pack(KEY, "AtlasLoot Continued", function()
	FollowAll()
	FollowFavourites()
	-- The safety net, by name.
	ns.Watch(KEY, "AtlasLoot_GUI-Frame", function(f) Calm(MainWindow, f) end)
end, CAPS)

-- Favourites loads after the core (its own folder): followed once it's there.
ns.Pack("AtlasLootContinued_Favourites", nil, function()
	if not On() then return end
	FollowFavourites()
	ns.Watch(KEY, "AtlasLoot_GUI-FavouritesFrame", function(f) Calm(Favourites, f) end)
end)
