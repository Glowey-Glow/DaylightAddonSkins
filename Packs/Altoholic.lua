-- Altoholic: its window, the seven tabs it loads on demand and AddonFactory's parts in the
-- DaylightUI look. Built against Altoholic 1.60.005 (Forever build) and AddonFactory 2026.10.14:
-- Altoholic/Main.xml, the Altoholic_* tab folders, AddonFactory/Templates.
-- How it's found: every Altoholic and AddonFactory frame is bound to its code through LibMVC's
-- BindViewToController, called from the frame's own OnLoad (the library's, and Altoholic's copy
-- of it). Both are post-hooked when this file loads (after AddonFactory and Altoholic, its
-- optional dependencies), so a frame made later (the tabs are load-on-demand, the dropdown lists
-- are made on their first use) is dressed in the frame it's made, before it's ever drawn. The
-- window itself is made before this file runs and is dressed at login. No polling.
-- Dressed here:
--   * The window (AltoholicFrame, PortraitFrameTemplate): the game's art off (portrait too),
--     DaylightUI's window shell, title and X (Kit.Window); its size grabber in DaylightUI's grip
--     look; the search box (SearchBoxTemplate).
--   * The tabs under it (AddonFactory_PanelTabButtonTemplate) as DaylightUI's tabs, the picked one
--     read from the window's selectedTab (AddonFactory's SetTab), refitted to the player's font.
--   * Every tab's page, by DaylightUI's walk (again on every tab switch, page shown and frame
--     Altoholic binds inside the window): buttons (UIPanelButtonTemplate), checkboxes
--     (InterfaceOptionsCheckButtonTemplate) as switches with their words in the player's font,
--     input boxes, scroll bars (AddonFactory's own UIPanelScrollBar copies), the option sliders
--     (AddonFactory_OptionsSliderTemplate: their backdrop child off, ns.Slider), the dropdowns
--     (AddonFactory_DropDownMenuTemplate: CharacterCreate-LabelFrame art off, ns.OldDropdown;
--     the hidden right-click "contextual" menus are left out, only their lists show).
--   * The page grounds (auctionhouse-background-index, -categories) as DaylightUI insets; the
--     scroll-border art beside every list (UI-Character-ScrollBar) off; flat backdrop boxes
--     (TooltipBorderBackdropTemplate: the sharing pages' lists) as insets.
--   * The category list on the left of every tab (AH-style nav buttons): DaylightUI line rows, the
--     picked category in the accent wash, hover a wash; top level in the label ink, sub levels in
--     the text ink, hovered in the value ink (font objects of ours, as Altoholic swaps them on every
--     refresh). Repainted from each list's own UpdateCategories.
--   * Column headers (AddonFactory_AuctionHouseSortButtonTemplate, WhoFrame-ColumnTabs art): art
--     off, a faint line under them, words in the label ink and the player's font (set as each is
--     made, before Altoholic measures it), its sort arrow kept (tinted to the label ink).
--   * Dropdown lists (AddonFactory_DropDownListTemplate, made without a parent, Backdrop +
--     MenuBackdrop keys): both backdrops off, DaylightUI's window shell, rows' hover a wash, the
--     tick in the accent and the empty mark gray, words in the player's font.
--   * Item and class icons (AltoItemIconTemplate, AltoClassIconTemplate, ...): DaylightUI's item
--     look, the outline following Altoholic's own border color (quality, or a class icon's
--     faction) whenever it sets it; class icons keep their place on the class sheet. Plain icon
--     buttons (AddonFactory_ButtonTemplate: the filter icons, spells, talents, guild bank tabs)
--     cropped in an edge, hover a wash; the spellbook slot art off.
--   * Grids: each cell's tooltip-bordered backdrop off, an edge round its picture; its quality glow
--     stays. Calendar: day cells as faint boxes (the days of other months still dimmed), weekday
--     strip art off, month arrows as DaylightUI's page buttons. Row hovers (HelpFrameButton,
--     QuestTitle highlights) a faint wash.
--   * The message box (AltoMessageBox): window shell, its buttons and box.
-- Kept as Altoholic draws them (they carry meaning): item quality, class and faction colors, the
-- grids' quality glow, its +/- collapse buttons, recipe stars, status colors in its text.
-- Not here: its minimap button (DaylightUI's minimap drawer holds it), its tooltip lines and
-- AddonFactory_Tooltip (a GameTooltip: DaylightUI's tooltips), garrison and covenant panels
-- (no such content on this client; they get the walk only).
-- Hand-over: its item counts and item ID in item tooltips, which DaylightUI's bags and tooltips
-- also add (asked once, given back from its page).
local _, ns = ...
if not ns.ok then return end

local L = ns.L

local KEY = "Altoholic"
local FOLDERS = { "Altoholic", "Altoholic_Summary", "Altoholic_Characters", "Altoholic_Search", "Altoholic_Guild",
	"Altoholic_Agenda", "Altoholic_Grids", "Altoholic_Options", "AddonFactory", "DataStore" }
local CAPS = { window = true, controls = true, text = true, shadow = true, font = "daylight", folders = FOLDERS,
	extraTab = "DaylightUI", extra = function() return { ns.HandoverGroup(KEY) } end }
ns.Target(KEY, "Altoholic", CAPS)

local Usable, Guard = ns.Usable, ns.Guard

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end
local function Kind(x) return Usable(x) and x:GetObjectType() or nil end
local function IsTexture(x) return Kind(x) == "Texture" end

local function Ink(fs, name)
	if Kind(fs) ~= "FontString" then return end
	local c = ns.Colors()[name]
	if c then fs:SetTextColor(c[1], c[2], c[3]) end
end

-- A gold / blue game highlight: a faint white wash, plain blending.
local function Wash(tex, alpha)
	if not IsTexture(tex) then return end
	tex:SetColorTexture(1, 1, 1, alpha)
	tex:SetBlendMode("BLEND")
end

local function HighlightOf(btn)
	return btn.GetHighlightTexture and btn:GetHighlightTexture() or nil
end

-- What a texture's file is (a number on this client).
local function FileOf(tex)
	if not IsTexture(tex) then return nil end
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return nil end
	if type(file) == "string" then file = string.lower(file) end
	return file
end

local function AtlasOf(tex)
	if not IsTexture(tex) then return nil end
	local ok, atlas = pcall(tex.GetAtlas, tex)
	return ok and type(atlas) == "string" and atlas or nil
end

local ART
local function ArtIs(tex, what)
	ART = ART or ns.FileIDs({
		["Interface\\HelpFrame\\HelpFrameButton-Highlight"] = "rowLit",
		["Interface\\QuestFrame\\UI-QuestTitleHighlight"] = "rowLit",
		["Interface\\Calendar\\Highlights"] = "rowLit",
		["Interface\\Calendar\\CalendarBackground"] = "calendar",
		["Interface\\Spellbook\\Spellbook-Parts"] = "spellbook",
	})
	local file = FileOf(tex)
	return file ~= nil and ART[file] == what
end

-- Frames the walk must leave to this pack (its own dressing would undo ours): the column headers,
-- radio buttons (DaylightUI has no radio look) and the hidden right-click menus.
local skip = setmetatable({}, { __mode = "k" })
local WALK = { skip = skip }

local done = setmetatable({}, { __mode = "k" })    -- frame -> true, once dressed by a step here
local function Once(f, what)
	local d = done[f]
	if not d then
		d = {}
		done[f] = d
	end
	if d[what] then return false end
	d[what] = true
	return true
end

-- ---------------------------------------------------------------------------------------------
-- Font objects: the category rows take theirs anew on every refresh, so they get copies of ours
-- (the player's font, an ink).
-- ---------------------------------------------------------------------------------------------

local INK = { GameFontNormalSmall = "LABEL", GameFontHighlightSmall = "TEXT", GameFontNormal = "LABEL",
	GameFontHighlight = "TEXT" }
local fonts, ours = {}, setmetatable({}, { __mode = "k" })
local function FontLike(base, ink)
	if type(base) ~= "table" or not base.GetName then return nil end
	local baseName = base:GetName() or "Anon"
	ink = ink or INK[baseName] or "TEXT"
	local name = "DaylightAddonSkinsAlto" .. ink .. baseName
	local f = fonts[name]
	if f then return f end
	f = CreateFont(name)
	f:CopyFontObject(base)
	local path, size, flags = base:GetFont()
	if path and size and not ns.PlainText(KEY) then f:SetFont(ns.FontFor(KEY, path, size, flags)) end
	local c = ns.Colors()[ink]
	if c then f:SetTextColor(c[1], c[2], c[3]) end
	fonts[name] = f
	ours[f] = true
	return f
end

-- ---------------------------------------------------------------------------------------------
-- Category lists (AddonFactory_AuctionHouseCategoriesListTemplate)
-- ---------------------------------------------------------------------------------------------

local function Picked(btn)
	local data = btn.data
	return type(data) == "table" and data.isSelected == true
end

local CATEGORY_ART = { "NormalTexture", "HighlightTexture", "SelectedTexture", "Lines" }

local function CategoryButton(btn)
	local Kit = ns.Kit
	if not Kit or Kind(btn) ~= "Button" or not Controls() or not Once(btn, "category") then return end
	-- (Altoholic puts their atlases and alpha back on every refresh: masked, not faded.)
	for _, k in ipairs(CATEGORY_ART) do
		if IsTexture(btn[k]) then Kit.Erase(btn[k]) end
	end
	Kit.Row(btn, nil, Picked, false)
end

local function CategoryFonts(btn)
	if not btn.GetNormalFontObject then return end
	local normal = btn:GetNormalFontObject()
	if normal and not ours[normal] then
		local mine = FontLike(normal)
		if mine then btn:SetNormalFontObject(mine) end
	end
	local lit = btn:GetHighlightFontObject()
	if lit and not ours[lit] then
		local mine = FontLike(lit, "VALUE")
		if mine then btn:SetHighlightFontObject(mine) end
	end
end

local function CategoryRows(list)
	local Kit = ns.Kit
	if not Kit or type(list.Buttons) ~= "table" then return end
	for _, btn in ipairs(list.Buttons) do
		CategoryButton(btn)
		if btn:IsShown() then
			CategoryFonts(btn)
			Kit.RepaintRow(btn)
		end
	end
end

local function CategoryList(list)
	local Kit = ns.Kit
	if not Kit or not Usable(list) or type(list.UpdateCategories) ~= "function" or not Once(list, "list") then return end
	if IsTexture(list.Background) then Kit.Inset(list) end
	-- (Run in the call itself: the rows are refilled there, and drawn right after.)
	ns.HookOnce(list, "UpdateCategories", function() CategoryRows(list) end, KEY)
	CategoryRows(list)
end

-- ---------------------------------------------------------------------------------------------
-- Column headers (AddonFactory_AuctionHouseSortButtonTemplate)
-- ---------------------------------------------------------------------------------------------

local function SortButton(btn)
	local Kit = ns.Kit
	if not Kit or Kind(btn) ~= "Button" then return end
	skip[btn] = true
	if not Once(btn, "sort") then return end
	for _, k in ipairs({ "Left", "Middle", "Right" }) do Kit.Hide(btn[k]) end
	Wash(HighlightOf(btn), 0.06)
	local line = btn:CreateTexture(nil, "BACKGROUND")
	line:SetColorTexture(1, 1, 1, 0.08)
	line:SetHeight(1)
	line:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2, 0)
	line:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 0)
	-- The words in the player's font before Altoholic measures them (PreserveWidth, on SetButton).
	if Kind(btn.Text) == "FontString" then
		ns.FollowFont(btn.Text, KEY)
		Ink(btn.Text, "LABEL")
	end
	-- Its sort arrow stays, in the label ink.
	local arrow = btn.Arrow
	if IsTexture(arrow) then
		local c = ns.Colors().LABEL
		arrow:SetDesaturated(true)
		if c then arrow:SetVertexColor(c[1], c[2], c[3]) end
	end
end

local function SortButtons(container)
	if type(container.SortButtons) ~= "table" then return end
	for _, btn in ipairs(container.SortButtons) do SortButton(btn) end
end

-- ---------------------------------------------------------------------------------------------
-- Dropdown lists (AddonFactory_DropDownListTemplate): made without a parent, on first use
-- ---------------------------------------------------------------------------------------------

local UNCHECKED = 0.55

local function ListRows(list)
	local r, g, b = ns.AccentOf(KEY)
	for _, row in ipairs({ list:GetChildren() }) do
		if Kind(row) == "Button" then
			if Once(row, "menuRow") then Wash(row.Highlight, 0.08) end
			if Kind(row.NormalText) == "FontString" then ns.FollowFont(row.NormalText, KEY) end
			local check, uncheck = row.Check, row.UnCheck
			if IsTexture(check) and r then
				check:SetDesaturated(true)
				check:SetVertexColor(r, g, b)
			end
			if IsTexture(uncheck) then
				uncheck:SetDesaturated(true)
				uncheck:SetVertexColor(UNCHECKED, UNCHECKED, UNCHECKED)
			end
		end
	end
end

local function DressList(list)
	if not Usable(list) then return end
	if Once(list, "menu") then
		for _, k in ipairs({ "Backdrop", "MenuBackdrop" }) do
			if Usable(list[k]) then list[k]:SetAlpha(0) end
		end
		ns.Shell(list, { window = true, bgAlpha = 0.98 }, KEY)
	end
	ListRows(list)
end

local function ListMade(list)
	if not Usable(list) then return end
	-- (Shown by Toggle once its rows are filled: dressed in that show, before it's drawn.)
	ns.ScriptOnce(list, "OnShow", function() DressList(list) end, KEY)
	if list:IsShown() then DressList(list) end
end

-- ---------------------------------------------------------------------------------------------
-- Icons
-- ---------------------------------------------------------------------------------------------

-- An item or class icon (an IconBorder over an Icon): DaylightUI's item look, its outline in the
-- color Altoholic gives its border (quality, a class icon's faction), whenever it gives one.
local function Item(btn)
	local Kit = ns.Kit
	if not Kit or Kind(btn) ~= "Button" or not IsTexture(btn.IconBorder) or not IsTexture(btn.Icon) then return end
	if not Controls() or not Once(btn, "item") then return end
	local icon = btn.Icon
	-- A class icon is a piece of the class sheet: its place there is kept, not cropped.
	local sheet = type(btn.SetClass) == "function"
	local coords = sheet and { icon:GetTexCoord() } or nil
	Kit.Item(btn)
	if coords and #coords == 8 then icon:SetTexCoord(unpack(coords)) end
	Wash(HighlightOf(btn), 0.12)
	if btn.GetPushedTexture then Kit.Hide(btn:GetPushedTexture()) end
	local border = btn.IconBorder
	local function repaint() Kit.SlotQuality(btn) end
	for _, m in ipairs({ "SetVertexColor", "Show", "Hide", "SetShown" }) do ns.HookOnce(border, m, repaint, KEY) end
	repaint()
end

local DEFAULT_COORDS = { 0, 0, 0, 1, 1, 0, 1, 1 }
local function Uncropped(tex)
	local c = { tex:GetTexCoord() }
	for i = 1, 8 do
		if type(c[i]) ~= "number" or math.abs(c[i] - DEFAULT_COORDS[i]) > 0.001 then return false end
	end
	return true
end

-- A plain icon button (AddonFactory_ButtonTemplate with no border: the filter icons, spells,
-- talents, guild bank tabs): the icon cropped in an edge, hover a wash.
local function IconTile(btn)
	local Kit = ns.Kit
	if not Kit or Kind(btn) ~= "Button" or not IsTexture(btn.Icon) or IsTexture(btn.IconBorder) then return end
	if type(btn.SetIcon) ~= "function" or not Controls() or not Once(btn, "tile") then return end
	if Uncropped(btn.Icon) then btn.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
	-- The spellbook's slot, its empty slot and the parchment behind a spell's name.
	for _, k in ipairs({ "Background", "TextBackground", "Slot" }) do
		if ArtIs(btn[k], "spellbook") then Kit.Hide(btn[k]) end
	end
	if btn.GetPushedTexture then Kit.Hide(btn:GetPushedTexture()) end
	Wash(HighlightOf(btn), 0.12)
	Kit.Outline(btn, 1, "icon")
end

-- A grid cell (AltoGridsButtonTemplate): its tooltip-bordered backdrop off, an edge round the
-- picture (its Background texture); the quality glow (IconBorder) stays Altoholic's.
local function GridCell(btn)
	local Kit = ns.Kit
	if not Kit or Kind(btn) ~= "Button" or not IsTexture(btn.Background) or not IsTexture(btn.IconBorder) then return end
	if not btn.GetBackdrop or not Controls() or not Once(btn, "grid") then return end
	Kit.Backdrop(btn)
	Kit.Outline(btn.Background, 1, "icon")
end

-- A calendar day (AltoCalendarDayButtonTemplate): its parchment a faint fill (Altoholic still
-- dims other months' days through its color), an edge, the gold hover a wash.
local function Day(btn)
	local Kit = ns.Kit
	if not Kit or Kind(btn) ~= "Button" or Kind(btn.Date) ~= "FontString" then return end
	local normal = btn.GetNormalTexture and btn:GetNormalTexture()
	if not ArtIs(normal, "calendar") or not Controls() or not Once(btn, "day") then return end
	normal:SetColorTexture(1, 1, 1, 0.05)
	Wash(HighlightOf(btn), 0.08)
	Kit.Shell(btn, "row")
end

-- ---------------------------------------------------------------------------------------------
-- The walk's extras: what this pack does on each frame DaylightUI's walk passes
-- ---------------------------------------------------------------------------------------------

local SCROLL_ART = { "scrollBorderTop", "scrollBorderMiddle", "scrollBorderBottom", "scrollFrameScrollBarBackground" }
local GROUND = { ["auctionhouse-background-index"] = true }

-- One frame on its own (not its children): from the walk, and from the hook as it's made.
local function DressOne(f)
	local Kit = ns.Kit
	if not Kit or not Usable(f) then return end
	local kind = f:GetObjectType()
	if kind == "Button" then
		if f.Day_OnClick then
			Day(f)
		elseif IsTexture(f.IconBorder) and IsTexture(f.Icon) then
			Item(f)
		elseif IsTexture(f.IconBorder) and IsTexture(f.Background) then
			GridCell(f)
		elseif IsTexture(f.Icon) then
			IconTile(f)
		elseif Once(f, "rowLit") then
			local lit = HighlightOf(f)
			if ArtIs(lit, "rowLit") then Wash(lit, 0.06) end
		end
	elseif kind == "ScrollFrame" then
		if Once(f, "scrollArt") then
			for _, k in ipairs(SCROLL_ART) do
				if IsTexture(f[k]) then Kit.Hide(f[k]) end
			end
		end
	elseif kind == "Slider" then
		-- (AddonFactory_OptionsSliderTemplate's track is a backdrop child: off; ns.Slider does the rest.)
		if Usable(f.Backdrop) and Once(f, "sliderBack") then Kit.Hide(f.Backdrop) end
	elseif kind == "Frame" then
		if type(f.UpdateCategories) == "function" and type(f.Buttons) == "table" then CategoryList(f) end
		if type(f.SortButtons) == "table" then SortButtons(f) end
		-- A tab's page ground.
		if IsTexture(f.bg) and GROUND[AtlasOf(f.bg) or ""] and Once(f, "ground") then Kit.Inset(f) end
		-- The calendar's weekday strip and month arrows.
		if Kind(f.PrevMonth) == "Button" and Once(f, "calendar") then
			for i = 1, 7 do
				local tex = f["Weekday" .. i .. "Background"]
				if IsTexture(tex) then Kit.Hide(tex) end
				Ink(f["Weekday" .. i .. "Name"], "LABEL")
			end
			if Controls() then
				Kit.PageButton(f.PrevMonth, "left")
				if Kind(f.NextMonth) == "Button" then Kit.PageButton(f.NextMonth, "right") end
			end
		end
		-- A flat backdrop box (TooltipBorderBackdropTemplate: the sharing pages' lists): an inset.
		local parent = f:GetParent()
		if f.GetBackdrop and f:GetBackdrop() and not (parent and parent.Backdrop == f) and Once(f, "well") then
			ns.NoBackdrop(f)
			Kit.Inset(f)
		end
	end
end

local function Each(f)
	DressOne(f)
	-- The right-click menus (AddonFactory_ContextualMenuTemplate) never show themselves: left out
	-- (their lists are dressed as lists).
	if Usable(f.ContextualMenu) then skip[f.ContextualMenu] = true end
	if not f.GetChildren then return end
	for _, c in ipairs({ f:GetChildren() }) do
		local kind = Kind(c)
		if kind == "CheckButton" then
			if ns.IsRadio(c) then
				skip[c] = true
			end
			-- (The walk doesn't open a checkbox up: its words in the player's font from here.)
			local name = c.GetName and c:GetName()
			local label = c.Text or c.text or (name and _G[name .. "Text"])
			if Kind(label) == "FontString" then ns.FollowFont(label, KEY) end
		elseif kind == "Button" and IsTexture(c.IconBorder) and IsTexture(c.Icon) then
			-- (Ahead of the walk's own item look, which would crop a class icon off its sheet.)
			Item(c)
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The window
-- ---------------------------------------------------------------------------------------------

local window, walkMain

-- Its tabs size themselves to their words as they show (in the game's font): measured again.
local function FitTabs(f)
	if type(f.Tabs) ~= "table" then return end
	for _, tab in ipairs(f.Tabs) do
		if Usable(tab) and type(tab.Resize) == "function" and tab:IsVisible() then
			pcall(tab.Resize, tab, f.tabPadding, nil, f.minTabWidth, f.maxTabWidth)
		end
	end
end

local function After(f)
	FitTabs(f)
end

local function Window(f, Kit)
	if not Once(f, "window") then return end
	Kit.Window(f)
	if Controls() then
		for _, c in ipairs({ f:GetChildren() }) do
			if ns.IsGrip(c) then ns.Grip(c) end
		end
	end
	if ns.Walk then walkMain = ns.Walk(Kit, f, WALK, After, Each, KEY) end
	-- A tab picked (its addon loaded on the first pick): walked again.
	if type(f.SwitchToTab) == "function" then
		ns.HookOnce(f, "SwitchToTab", function() if walkMain then walkMain() end end, KEY)
	end
end

local function MessageBox(f, Kit)
	if not Usable(f) or not Once(f, "box") then return end
	ns.NoBackdrop(f)
	ns.Shell(f, { window = true }, KEY)
	if ns.Walk then ns.Walk(Kit, f, WALK, nil, Each, KEY) end
end

local function Dress(Kit)
	local f = _G.AltoholicFrame
	if not Usable(f) then return end
	window = f
	Window(f, Kit)
	MessageBox(_G.AltoMessageBox, Kit)
end

ns.Pack(KEY, "Altoholic", function(Kit)
	if not Usable(_G.AltoholicFrame) then return false end
	if InCombatLockdown() then
		ns.OutOfCombat(function() if On() then Guard(Dress, Kit) end end)
	else
		Dress(Kit)
	end
end, CAPS)

-- ---------------------------------------------------------------------------------------------
-- The fast path: every Altoholic and AddonFactory frame as LibMVC binds it to its code
-- ---------------------------------------------------------------------------------------------

local function InWindow(frame)
	if not window then return false end
	local p = frame
	for _ = 1, 12 do
		p = p.GetParent and p:GetParent()
		if not p then return false end
		if p == window then return true end
	end
	return false
end

local BOUND = {
	["AddonFactory.AuctionHouseSortButton"] = SortButton,
	["AddonFactory.AuctionHouseCategoryButton"] = CategoryButton,
	["AddonFactory.DropDownList"] = ListMade,
}

local function Bound(_, frame, controller, inherits)
	if type(frame) ~= "table" or not ns.Kit or not Usable(frame) then return end
	local fn = type(controller) == "string" and BOUND[controller]
	if fn then fn(frame) end
	if controller == "AddonFactory.AuctionHouseCategoriesList"
		or (type(inherits) == "string" and string.find(inherits, "AuctionHouseCategoriesList", 1, true)) then
		CategoryList(frame)
	end
	if InWindow(frame) then
		DressOne(frame)
		-- (Coalesced: one walk next frame however many frames a tab's load binds.)
		if walkMain then walkMain() end
	end
end

-- (AddonFactory and Altoholic load before this plugin; Altoholic holds a copy of the library's
-- function, taken before this hook, so both are hooked: each call goes through one of them.)
local MVC = type(LibStub) == "table" and LibStub("LibMVC-1.0", true)
local A = _G.Altoholic
if type(A) == "table" and type(MVC) == "table" then
	ns.HookOnce(MVC, "BindViewToController", Bound, KEY)
	if A.BindViewToController ~= MVC.BindViewToController then
		ns.HookOnce(A, "BindViewToController", Bound, KEY)
	end
end

-- The look changed: the category rows' inks and accent again.
ns.me.On("StyleChanged", function()
	if On() then Guard(function() if ns.Kit then ns.Kit.RepaintRows() end end) end
end)

-- ---------------------------------------------------------------------------------------------
-- Hand-over: what Altoholic adds to item tooltips that DaylightUI also adds there (Altoholic
-- 1.60.005, Altoholic_Tooltip_Options, account-wide): each character's count (and the total), as
-- DaylightUI's bags do when their other-characters viewer is on; the item ID, as DaylightUI's
-- tooltip does with its ID lines on. Both would print twice. Left with Altoholic: where an item
-- comes from, known recipes, guild bank and account bank counts in its own lines (DaylightUI's
-- counts have no copy of those apart from the counts themselves), its mail autocomplete, vendor
-- and AH recipe colors, calendar and mail expiry warnings (DaylightUI has none of them).
-- ---------------------------------------------------------------------------------------------

local function Options() return _G.Altoholic_Tooltip_Options end
local has = ns.DaylightHas

ns.Handover(KEY, {
	ready = function() return type(Options()) == "table" end,
	get = function(key)
		local o = Options()
		if key == "itemCounts" then
			-- (Two of its switches as one: 1 = per character, 2 = the total, 3 = both.)
			local v = (o.ShowItemCount and 1 or 0) + (o.ShowTotalItemCount and 2 or 0)
			return v > 0 and v or false
		elseif key == "itemID" then
			return o.ShowItemID and true or false
		end
	end,
	set = function(key, value)
		local o = Options()
		if key == "itemCounts" then
			local v = tonumber(value) or 0
			o.ShowItemCount = v % 2 == 1
			o.ShowTotalItemCount = v >= 2
		elseif key == "itemID" then
			o.ShowItemID = value and true or false
		end
	end,
	list = {
		{ key = "itemCounts", label = L["Who Owns It, in Item Tooltips"],
		  daylight = ns.In(L["each character's count in item tooltips"], "Bags"),
		  ours = function() return has("Bags", "viewer.enabled") and has("Bags", "viewer.tipCounts") end },
		{ key = "itemID", label = L["Item ID in Item Tooltips"],
		  daylight = ns.In(L["item and spell IDs"], "Tooltip"),
		  ours = function() return has("Tooltip", "showIDs") end },
	},
})
