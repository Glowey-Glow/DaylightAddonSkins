-- Auctionator: its auction house tabs, lists, dialogs and its crafting panel in the DaylightUI look.
-- Built against Auctionator 349 (the Forever client loads its Mainline / ModernAH code: Source,
-- Source_ModernAH, Source_Mainline, Libs_ModernAH\LibAHTab) and the client's own interface code
-- (wow-ui-source, branch "forever"), so every name and key below is Auctionator's or the game's.
-- DaylightUI's own Window Skins already dress the auction house ("system" pack: Kit.Window on
-- AuctionHouseFrame and a Kit.Auto walk over everything in it, Auctionator's frames included), and
-- this plugin's Kit is DaylightUI's: the same Kit call on the same piece twice is a no-op. So this
-- pack makes the same calls the walk would, sooner (in the frame a window is built or opened, no
-- polling), and adds only what that walk gets wrong or never reaches:
--   * Its four tab pages (Shopping, Selling, Cancelling, Auctionator) and the two buy pages: walked
--     the moment LibAHTab makes them (hidden parts too), again on every show; the player's font on
--     their words, the game's gold in DaylightUI's inks.
--   * Its result lists (AuctionatorResultsListingTemplate, eight of them): the row stripe off, the
--     hover a faint white wash, the picked row the accent wash, dressed in the frame each row is
--     filled (the list's own OnInitializedFrame callback); the item icons in a quality edge;
--     the column headers as DaylightUI buttons, their sort arrow kept.
--   * The shopping list and recent search lists (rows Auctionator builds in code): the same row
--     look; list names in its gold become the label ink (a temporary list's orange is kept).
--   * The selling bag (AuctionatorGroupsViewItemTemplate, pooled): items in DaylightUI's item edge,
--     kept in the item's quality as the pool hands buttons to other items (Auctionator colors its
--     border by hand, which the walk never follows); the empty-slot art off; the picked item's glow
--     in the accent; the group headers (the game's AuctionCategoryButtonTemplate) as plain lines.
--     The item being posted (SaleItemFrame.Icon) the same.
--   * Its dialogs inside the auction house: the shopping item editor (ButtonFrameTemplate), list
--     export / import, the copy-text box, price history (AuctionatorSimplePanelTemplate: rock
--     backdrop and border), and the buy / confirm dialogs (AuctionatorConfirmationDialogTemplate):
--     DaylightUI's window shell, its X, titles in the value ink.
--   * Its pop-ups on the screen (AuctionatorDialog1..n: new list, rename, confirm, money): window
--     shell, buttons and box, dressed in the frame they're first made; on a controller the D-pad
--     reaches them and B closes them (DaylightUI's controller kit, guarded, out of combat).
--   * Its small reset X buttons: the red pass glyph in the text ink inside DaylightUI's button.
--     Its self-sizing buttons (Search, Add to List, Accept...) sized again once they carry
--     DaylightUI's font (they only grow), so no word runs past a button's edge; check boxes' own
--     labels (strings inside the box, which the walk doesn't open) in the player's font.
--   * The buy pages' item header: the icon cropped, a quality edge instead of the round frame.
--   * Its tabs on the auction house's tab row (LibAHTab, AuctionHouseFrameDisplayModeTabTemplate):
--     DaylightUI's tabs, refitted to the player's font with Auctionator's own sizes (its "small
--     tabs" option kept) -- only while DaylightUI dresses the auction house itself and DaylightMogul
--     isn't loaded (then the tab row is theirs). Its mini tabs (lists / recents, the price tabs)
--     refitted the same way.
--   * The crafting panel on the profession window (AuctionatorCraftingInfoProfessionsFrame: costs,
--     Search, the "search for quantity" box) and the Search button on the objective tracker's
--     profession header: silent looks only (no script of ours: that window's OnShow casts a spell,
--     see Packs\BlizzardProfessions.lua). Its box's edit field is left to DaylightUI's own walk of
--     that window when that walk runs.
-- Kept as Auctionator draws them (they carry meaning): prices and their coins, red losses, item
-- names in their quality colors, your own auctions' green and bids' purple row marks, the sort
-- arrows, the loading spinner, the translators' flags, the list option icons.
-- Not here: its options (Settings canvas pages: the Game settings window pack walks addon pages),
-- its right-click and dropdown menus (DaylightUI's menus), its confirm popups (the game's
-- StaticPopups, DaylightUI's), tooltips (DaylightUI's). The auction house's own insets keep the
-- auction house's backgrounds, as DaylightUI leaves the game's own panels there.
-- Nothing of Auctionator's is handed over: it does nothing DaylightUI does (no junk selling or
-- repairs; its tooltip lines are its own price data).
-- DaylightMogul (the user's auction house addon) may own the auction house window: this pack then
-- leaves the tab row alone and dresses only Auctionator's own frames.
-- Daylight UI 2.0 has an Auction House window of its own, shown in place of the game's (which
-- stays open, unseen, under it): while that window is the one in use, nothing of Auctionator's at
-- the auction house is dressed (Covered, below); its pop-ups, crafting panel and tracker button
-- are dressed as ever.
-- Taint: hooks only (hooksecurefunc on Auctionator's functions and frames, HookScript, its lists'
-- callbacks); no SetScript on any frame of Auctionator's or the game's; looks only; nothing in a
-- fight (queued for its end).
local _, ns = ...
if not ns.ok then return end

local KEY = "Auctionator"
-- (Its words are the game's font objects: the player's font goes on all.)
local CAPS = { window = true, controls = true, text = true, shadow = true, font = "daylight" }
ns.Target(KEY, "Auctionator", CAPS)

local Usable, Guard = ns.Usable, ns.Guard
local ipairs, pairs, type, pcall = ipairs, pairs, type, pcall

local Kit
local done = setmetatable({}, { __mode = "k" })     -- frames and pieces dressed here
local accents = setmetatable({}, { __mode = "k" })  -- texture -> { alpha, fill }
local edges = setmetatable({}, { __mode = "k" })    -- buy page item header -> its edge
local listed = setmetatable({}, { __mode = "k" })   -- scroll box -> our callback owner
local rowish = setmetatable({}, { __mode = "k" })   -- list rows dressed by the lists' callbacks

local WASH = 0.08   -- a row's hover
local PICK = 0.16   -- a picked row

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end
local function Kind(x) return Usable(x) and x:GetObjectType() or nil end
local function IsTexture(x) return Kind(x) == "Texture" end

-- Work that changes Auctionator's frames: now, or once the fight is over.
local function Now(id, fn)
	if InCombatLockdown() then
		ns.Queue(id, fn, KEY)
		return
	end
	fn()
end

local function MogulLoaded()
	local api = _G.C_AddOns
	return type(api) == "table" and type(api.IsAddOnLoaded) == "function" and api.IsAddOnLoaded("DaylightMogul") == true
end

-- Daylight UI 2.0's own Auction House window stands in for the game's, whose frame (with every
-- page and tab of Auctionator's on it) is parked out of sight under it: nothing of Auctionator's
-- at the auction house is walked or dressed then, at an opening or as LibAHTab makes a page.
-- (ns.DaylightCoversAH, Core.lua: DaylightUI.ahCovers, 2.0 DaylightUI_AuctionHouse\Window.lua:
-- 403-407, the signal Daylight UI's own auction house skin stands down on, 2.0
-- DaylightUI_Skins\Packs\System.lua:656-661. Feature-detected: not there on 1.9.x, where this is
-- always false.) Nothing is marked as done while it stands down, so the first sweep after the
-- player picks the game's window dresses everything: at once when that pick is made with the
-- auction house open (SettingChanged, at the foot of this file), else as it next opens.
local function Covered() return ns.DaylightCoversAH() end

-- ---------------------------------------------------------------------------------------------
-- Small pieces
-- ---------------------------------------------------------------------------------------------

local function Font(fs)
	local k = Kind(fs)
	if k == "FontString" or k == "EditBox" then ns.FollowFont(fs, KEY) end
end

local function Ink(fs, name)
	if Kind(fs) ~= "FontString" then return end
	local c = ns.Colors()[name]
	if c then fs:SetTextColor(c[1], c[2], c[3]) end
end

-- A texture in the accent (fill: a plain shape; else a picture tinted), kept through style changes.
local function Accent(tex, alpha, fill)
	if not IsTexture(tex) then return end
	local a = accents[tex]
	if not a then
		a = { alpha, fill }
		accents[tex] = a
	end
	if a[2] then ns.FillAccent(tex, a[1], nil, KEY) else ns.PaintAccent(tex, a[1], nil, KEY) end
end

local function Wash(tex, alpha)
	if not IsTexture(tex) then return end
	tex:SetColorTexture(1, 1, 1, alpha)
	tex:SetBlendMode("BLEND")
end

-- The game's gold written into a string (NORMAL_FONT_COLOR:WrapTextInColorCode, |cffffd100) in
-- DaylightUI's label ink. Other colors (a temporary list's orange, gray "Empty") stay.
local function LabelCode()
	local c = ns.Colors().LABEL or { 1, 1, 1 }
	return string.format("|cff%02x%02x%02x", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end
local function GoldRuns(fs)
	if Kind(fs) ~= "FontString" then return end
	local text = fs:GetText()
	if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return end
	local new, n = string.gsub(text, "|c[fF][fF][fF][fF][dD]100", LabelCode())
	if n > 0 then fs:SetText(new) end
end

-- Its buttons that size themselves to their words (UIPanelDynamicResizeButtonTemplate: Search,
-- Add to List, Accept...) were sized in the game's font; once DaylightUI's walk has put its own on
-- them they're sized again (the game's DynamicResizeButton_Resize: they only ever grow), so no
-- word runs past a button's edge. Noted as the walk passes their parent, sized after it.
local growing = setmetatable({}, { __mode = "k" })

-- What the walk can't do for a frame's children (it doesn't open up a control it has dressed):
--   * a check button's own words (Auctionator's labels are strings inside it): the player's font;
--   * its reset buttons (AuctionatorResetButton: a 15 px UIPanelButtonTemplate with the red loot
--     "pass" X on it as `texture`; the button itself is the walk's): the X in the text ink;
--   * its self-sizing buttons, noted for Grow below.
local function Kids(frame)
	if not frame.GetChildren then return end
	local controls = Controls()
	for _, c in ipairs({ frame:GetChildren() }) do
		local k = Kind(c)
		if k == "CheckButton" then
			for _, r in ipairs({ c:GetRegions() }) do
				if Kind(r) == "FontString" then Font(r) end
			end
		elseif k == "Button" then
			local x = c.texture
			if controls and IsTexture(x) and not done[x] then
				local w = c:GetWidth()
				if type(w) == "number" and w > 0 and w <= 20 then
					done[x] = true
					x:SetDesaturated(true)
					x:SetVertexColor(Kit.TEXT[1], Kit.TEXT[2], Kit.TEXT[3], 1)
				end
			end
			if type(c.padding) == "number" and c.GetTextWidth then growing[c] = true end
		end
	end
end

local function Grow()
	local resize = _G.DynamicResizeButton_Resize
	if type(resize) ~= "function" then return end
	for b in pairs(growing) do
		if Kit.ButtonOf(b) then
			growing[b] = nil
			pcall(resize, b)
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- Lists
-- ---------------------------------------------------------------------------------------------

-- A scroll list's rows, dressed in the frame each is filled (the list's OnInitializedFrame
-- callback, raised after Auctionator's own initializer), and the rows it has now.
local function EachFrame(box, fn)
	if box.ForEachFrame then pcall(box.ForEachFrame, box, function(row) Guard(fn, row) end) end
end

local function Rows(box, fn)
	if not Usable(box) or listed[box] or type(box.RegisterCallback) ~= "function" then return end
	local mixin = _G.ScrollBoxListMixin
	local event = type(mixin) == "table" and type(mixin.Event) == "table" and mixin.Event.OnInitializedFrame
	if not event then return end
	local owner = {}
	listed[box] = owner
	box:RegisterCallback(event, function(_, row)
		if not On() then return end
		if InCombatLockdown() then
			ns.Queue(box, function() EachFrame(box, fn) end, KEY)
			return
		end
		Guard(fn, row)
	end, owner)
	EachFrame(box, fn)
end

-- A result row (AuctionatorResultsRowTemplate and the rows built on it): the stripe off, the hover
-- a white wash, the picked row the accent wash; own-auction and bid marks kept. Every fill: the
-- item icon's quality edge (DaylightUI's Kit.RowIcons, as its walk does) and the cells' font.
local function ResultRow(row)
	if not Usable(row) then return end
	if not done[row] then
		if not (IsTexture(row.NormalTexture) and IsTexture(row.HighlightTexture) and IsTexture(row.SelectedHighlight)) then return end
		done[row] = true
		rowish[row] = true
		Kit.Hide(row.NormalTexture)
		Wash(row.HighlightTexture, WASH)
		Accent(row.SelectedHighlight, PICK, true)
		row.SelectedHighlight:SetBlendMode("BLEND")
	end
	Kit.RowIcons(row)
	for _, cell in ipairs({ row:GetChildren() }) do
		Font(cell.text)
		Font(cell.Text)
	end
end

-- Column headers (AuctionatorStringColumnHeaderTemplate on ColumnDisplayButtonShortTemplate):
-- DaylightUI buttons, as its walk dresses the game's own auction house headers.
local function Headers(listing)
	local hc = listing.HeaderContainer
	if not Usable(hc) or not Controls() then return end
	for _, h in ipairs({ hc:GetChildren() }) do
		if Kind(h) == "Button" then Kit.Button(h) end
	end
end

local function Listing(l)
	if not Usable(l) or done[l] then return end
	local area = l.ScrollArea
	if not (Usable(area) and Usable(area.ScrollBox) and Usable(l.HeaderContainer)) then return end
	done[l] = true
	Rows(area.ScrollBox, ResultRow)
	Headers(l)
	-- (Its headers are made in InitializeTable, which some lists run on their first show.)
	if type(l.InitializeTable) == "function" then
		ns.HookOnce(l, "InitializeTable", function(self) Now(self, function() Headers(self) end) end, KEY)
	end
	Font(area.NoResultsText)
	Font(area.ResultsText)
	Kit.InkGameText(area)
end

-- A shopping list / recent search row (built by Auctionator.Shopping.Tab.SetupContainerRow: Bg,
-- Highlight and Selected on a plain button).
local function ListRow(b)
	if not Usable(b) or not (IsTexture(b.Bg) and IsTexture(b.Highlight) and IsTexture(b.Selected)) then return end
	if not done[b] then
		done[b] = true
		rowish[b] = true
		Kit.Hide(b.Bg)
		Wash(b.Highlight, WASH)
		Accent(b.Selected, PICK, true)
		b.Selected:SetBlendMode("BLEND")
	end
	Font(b.Text)
	GoldRuns(b.Text)
end

local function Lines(container)
	if Usable(container) then Rows(container.ScrollBox, ListRow) end
end

-- ---------------------------------------------------------------------------------------------
-- The selling bag
-- ---------------------------------------------------------------------------------------------

-- An item's edge in its quality now (Auctionator colors its IconBorder by hand), and the picked
-- item's glow in the accent (it sets its orange on every fill).
local function ItemState(btn)
	Kit.SlotQuality(btn)
	local glow = btn.IconSelectedHighlight
	if IsTexture(glow) then Accent(glow, 1, false) end
end

local function BagItem(btn)
	if Kind(btn) ~= "Button" or not (IsTexture(btn.Icon) and IsTexture(btn.IconBorder)) then return end
	if not done[btn] then
		done[btn] = true
		Kit.Item(btn)
		if IsTexture(btn.EmptySlot) then Kit.Hide(btn.EmptySlot) end
		if IsTexture(btn.IconSelectedHighlight) then btn.IconSelectedHighlight:SetDesaturated(true) end
		if type(btn.SetItemInfo) == "function" then
			ns.HookOnce(btn, "SetItemInfo", function(self) ItemState(self) end, KEY)
		end
	end
	ItemState(btn)
end

-- A group's header (the game's AuctionCategoryButtonTemplate): a plain line, the label ink.
local function GroupTitle(btn)
	if Kind(btn) ~= "Button" then return end
	if not done[btn] then
		done[btn] = true
		Kit.Row(btn, nil, nil, false)
	end
	local label = btn.Text or btn:GetFontString()
	Font(label)
	Ink(label, "LABEL")
end

local function BagItems(view)
	local pool = view.buttonPool
	if type(pool) == "table" and type(pool.EnumerateActive) == "function" then
		for btn in pool:EnumerateActive() do BagItem(btn) end
	end
	local groups = view.groupPool
	if type(groups) == "table" and type(groups.EnumerateActive) == "function" then
		for g in groups:EnumerateActive() do GroupTitle(g.GroupTitle) end
	end
end

local function BagView(view)
	if not Usable(view) or done[view] then return end
	if type(view.UpdateFromExisting) ~= "function" or type(view.buttonPool) ~= "table" then return end
	done[view] = true
	-- (It hands every button out again on each update: dressed right after.)
	ns.HookOnce(view, "UpdateFromExisting", function(self) Now(self, function() BagItems(self) end) end, KEY)
	BagItems(view)
end

-- ---------------------------------------------------------------------------------------------
-- Windows and dialogs
-- ---------------------------------------------------------------------------------------------

-- The buy pages' item header (AuctionatorBuyIconNameTemplate): the icon cropped, a quality edge
-- in place of the game's round icon frame (its color read from that frame, which Auctionator sets).
local function PaintEdge(f)
	local s = edges[f]
	if not s or not IsTexture(f.QualityBorder) then return end
	local r, g, b = f.QualityBorder:GetVertexColor()
	if type(r) == "number" then Kit.Paint(s, { r, g, b }) end
end

local function IconName(f)
	if not Usable(f) or done[f] or not (IsTexture(f.Icon) and IsTexture(f.QualityBorder)) then return end
	done[f] = true
	f.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	Kit.Hide(f.QualityBorder)
	edges[f] = Kit.Outline(f.Icon, 1, "outline")
	Font(f.Text)
	if type(f.SetItem) == "function" then ns.HookOnce(f, "SetItem", function(self) PaintEdge(self) end, KEY) end
	PaintEdge(f)
end

-- What our walks hand every frame they pass (after the shared walk's own fonts and controls).
local Each

-- A window of Auctionator's inside the auction house (the item editor, export / import, copy
-- text, price history, the buy and confirm dialogs): DaylightUI's window shell (the game's art,
-- its rock backdrop and the dialog background off), its X, its heading in the value ink.
local function Panel(f, titled)
	if not Usable(f) or done[f] then return end
	done[f] = true
	Kit.Window(f)
	if Usable(f.Border) then Kit.Hide(f.Border) end
	ns.Shell(f, { window = true }, KEY)
	if Controls() and Usable(f.CloseDialog) then Kit.Close(f.CloseDialog) end
	if titled then
		for _, r in ipairs({ f:GetRegions() }) do
			if Kind(r) == "FontString" then
				Font(r)
				Ink(r, "VALUE")
			end
		end
	end
	-- (Price history's dock button: its gold arrow in the text ink.)
	local dock = f.Dock
	if Usable(dock) and IsTexture(dock.Arrow) then
		dock.Arrow:SetDesaturated(true)
		dock.Arrow:SetVertexColor(Kit.TEXT[1], Kit.TEXT[2], Kit.TEXT[3], 1)
	end
	IconName(f.IconAndName)
end

-- A page (a tab's frame, a buy page) or a pop-up: the shared walk (Packs\Blizzard.lua), hidden
-- parts included the first time, again on every show.
local MINI_PAD, MINI_MIN = 20, 70     -- AuctionatorMiniTabButtonMixin's own sizes

local function FitMini(tab)
	if Kind(tab) ~= "Button" or not Kit.TabOf(tab) or not tab:IsShown() then return end
	if type(PanelTemplates_TabResize) == "function" then pcall(PanelTemplates_TabResize, tab, MINI_PAD, nil, MINI_MIN) end
end

local function After(f)
	Grow()
	local tabs = f.ContainerTabs
	if Usable(tabs) then
		FitMini(tabs.ListsTab)
		FitMini(tabs.RecentsTab)
	end
	local prices = f.PricesTabsContainer
	if Usable(prices) and type(prices.Tabs) == "table" then
		for _, tab in ipairs(prices.Tabs) do FitMini(tab) end
	end
end

local function Page(f)
	if not Usable(f) or done[f] or not ns.Walk then return end
	done[f] = true
	ns.Walk(Kit, f, nil, function(frame) Guard(After, frame) end, function(frame) Each(frame) end, KEY)
end

Each = function(frame)
	-- (List rows and their cells are the lists' own callbacks', above: refilled all the time.)
	if rowish[frame] or frame.rowData ~= nil then return end
	if Usable(frame.ScrollArea) and Usable(frame.HeaderContainer) then Listing(frame) end
	if type(frame.buttonPool) == "table" and type(frame.UpdateFromExisting) == "function" then BagView(frame) end
	if Usable(frame.ScrollBox) and type(frame.Populate) == "function" then Lines(frame) end
	if Usable(frame.IconAndName) then IconName(frame.IconAndName) end
	Kids(frame)
end

-- ---------------------------------------------------------------------------------------------
-- Its tabs on the auction house's tab row
-- ---------------------------------------------------------------------------------------------

-- The tab row is DaylightUI's (its auction house skin) or DaylightMogul's: Auctionator's tabs are
-- dressed only when DaylightUI dresses the row, so they match the game's tabs beside them.
local function TabRowOurs()
	return not MogulLoaded() and ns.DaylightDressesGame("system")
end

local function SmallTabs()
	local A = _G.Auctionator
	local ok, small = pcall(function() return A.Config.Get(A.Config.Options.SMALL_TABS) end)
	return ok and small == true
end

-- Sized again in the player's font, with LibAHTab's sizes or Auctionator's small ones.
local function FitTabs()
	local box = _G.AuctionatorAHTabsContainer
	if not Usable(box) or type(box.Tabs) ~= "table" or type(PanelTemplates_TabResize) ~= "function" then return end
	local small = SmallTabs()
	for _, tab in ipairs(box.Tabs) do
		if Kind(tab) == "Button" and Kit.TabOf(tab) then
			pcall(PanelTemplates_TabResize, tab, small and 0 or 20, nil, small and 36 or 70)
		end
	end
end

local function Tab(tab)
	if Kind(tab) ~= "Button" or done[tab] or not Controls() or not TabRowOurs() then return end
	done[tab] = true
	Kit.Tab(tab)
end

-- ---------------------------------------------------------------------------------------------
-- Everything that's there now (on the auction house's first opening, and again on each)
-- ---------------------------------------------------------------------------------------------

local PAGES = { "AuctionatorShoppingFrame", "AuctionatorSellingFrame", "AuctionatorCancellingFrame",
	"AuctionatorConfigFrame", "AuctionatorBuyItemFrame", "AuctionatorBuyCommodityFrame" }
local BUY_DIALOGS = { "BuyDialog", "WidePriceRangeWarningDialog", "FinalConfirmationDialog", "QuantityCheckConfirmationDialog" }
local LISTINGS = { "ResultsListing", "CurrentPricesListing", "HistoricalPriceListing", "PostingHistoryListing" }

local function Sweep()
	if not On() or Covered() then return end
	local shop = _G.AuctionatorShoppingFrame
	if Usable(shop) then
		-- (Its dialogs first: a window's shell before the walk passes its controls.)
		Panel(shop.itemDialog)
		Panel(shop.exportDialog, true)
		Panel(shop.importDialog, true)
		Panel(shop.exportCSVDialog, true)
		Panel(shop.itemHistoryDialog, true)
		if Usable(shop.exportDialog) then Panel(shop.exportDialog.copyTextDialog, true) end
		Lines(shop.ListsContainer)
		Lines(shop.RecentsContainer)
	end
	for _, name in ipairs({ "AuctionatorBuyItemFrame", "AuctionatorBuyCommodityFrame" }) do
		local f = _G[name]
		if Usable(f) then
			IconName(f.IconAndName)
			for _, k in ipairs(BUY_DIALOGS) do Panel(f[k]) end
		end
	end
	for _, name in ipairs(PAGES) do
		local f = _G[name]
		if Usable(f) then
			for _, k in ipairs(LISTINGS) do Listing(f[k]) end
			Page(f)
		end
	end
	local sell = _G.AuctionatorSellingFrame
	if Usable(sell) then
		if Usable(sell.BagListing) then BagView(sell.BagListing.View) end
		if Usable(sell.SaleItemFrame) then BagItem(sell.SaleItemFrame.Icon) end
	end
	local tabs = _G.AuctionatorAHTabsContainer
	if Usable(tabs) and type(tabs.Tabs) == "table" then
		for _, tab in ipairs(tabs.Tabs) do Tab(tab) end
		FitTabs()
	end
	-- (A long walk finishes over a few frames: its buttons sized once it has.)
	ns.Queue("Auctionator:grow", Grow, KEY)
	-- Every opening: anything new, and the tabs refitted once Auctionator's own sizing has run.
	local ah = _G.AuctionatorAHFrame
	if Usable(ah) then
		ns.ScriptOnce(ah, "OnShow", function()
			Now("Auctionator:sweep", Sweep)
			ns.Queue("Auctionator:fit", FitTabs, KEY)
		end, KEY)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Its pop-ups (Source\Components\Dialogs.lua: AuctionatorDialog1..n on UIParent, made on first
-- use, each kept and shown again)
-- ---------------------------------------------------------------------------------------------

-- DaylightUI's controller kit (DaylightUI.Pad: internal, so checked and wrapped; out of a fight):
-- the D-pad reaches the pop-up, B closes it.
local padded = setmetatable({}, { __mode = "k" })
local function PadFollow(frame, close)
	if padded[frame] then return end
	local D = _G.DaylightUI
	local P = type(D) == "table" and D.Pad or nil
	if type(P) ~= "table" or type(P.Follow) ~= "function" then return end
	padded[frame] = true
	ns.OutOfCombat(function() pcall(P.Follow, frame, close) end)
end

local function Dialog(d)
	if not Usable(d) or done[d] then return end
	done[d] = true
	Kit.Window(d)
	ns.Shell(d, { window = true }, KEY)
	if ns.Walk then ns.Walk(Kit, d, nil, function() Guard(Grow) end, function(frame) Each(frame) end, KEY) end
	Font(d.text)
	PadFollow(d, function() d:Hide() end)
end

local function Dialogs()
	for i = 1, 50 do
		local d = _G["AuctionatorDialog" .. i]
		if not d then break end
		Dialog(d)
	end
end

-- ---------------------------------------------------------------------------------------------
-- The crafting panel (on the profession window) and the objective tracker's Search button:
-- silent looks (Packs\Blizzard.lua's static button / edit box / window shell: no script of ours).
-- ---------------------------------------------------------------------------------------------

local function Crafting()
	local f = _G.AuctionatorCraftingInfoProfessionsFrame
	if not Usable(f) or done[f] then return end
	done[f] = true
	Font(f.Total)
	Kit.InkGameText(f)
	local B = ns.Blizz
	if not Controls() or type(B) ~= "table" then return end
	B.StaticButton(Kit, f.SearchButton)
	local box = f.CustomQuantity
	if not Usable(box) then return end
	-- (Its Inset is hidden by Auctionator for good.)
	B.ShellWindow(Kit, box, nil, true)
	Kit.Close(box.CloseButton)
	B.StaticButton(Kit, box.SearchButton)
	local q = box.Quantity
	local eb = Usable(q) and q.InputBox
	if Kind(eb) == "EditBox" then
		-- DaylightUI's own walk of the profession window takes the window's edit boxes while its
		-- System skins dress that window: left to it then (a second look would double the box).
		if not Kit.InputOf(eb) and not ns.DaylightDressesGame("system") then B.StaticEditBox(Kit, eb) end
		Font(eb.Label)
	end
end

local function Tracker()
	local f = _G.AuctionatorCraftingInfoObjectiveTrackerFrame
	if not Usable(f) or done[f] then return end
	done[f] = true
	local B = ns.Blizz
	if Controls() and type(B) == "table" then B.StaticButton(Kit, f.SearchButton) end
end

-- ---------------------------------------------------------------------------------------------
-- When: Auctionator's frames are made on the auction house's first opening (its
-- AuctionHouseShown, LibAHTab's CreateTab), its pop-ups on first use, the crafting panel on the
-- first profession opened. Each is post-hooked and dressed right there (no polling).
-- ---------------------------------------------------------------------------------------------

local DIALOG_CALLS = { "ShowEditBox", "ShowConfirm", "ShowConfirmAlt", "ShowMoney" }

ns.Pack(KEY, "Auctionator", function(K)
	Kit = K
	local A = _G.Auctionator
	if type(A) ~= "table" then return false end
	-- The auction house: its frame and tabs made (AuctionatorInitalizeMainlineFrame, sic).
	local init = _G.AuctionatorInitalizeMainlineFrame
	if Usable(init) and type(init.AuctionHouseShown) == "function" then
		ns.HookOnce(init, "AuctionHouseShown", function() Now("Auctionator:sweep", Sweep) end, KEY)
	end
	-- Each tab page the moment LibAHTab makes it (hidden: dressed before it's ever drawn).
	local lib = type(LibStub) == "table" and LibStub("LibAHTab-1-0", true) or nil
	if type(lib) == "table" and type(lib.CreateTab) == "function" then
		ns.HookOnce(lib, "CreateTab", function(self, id, frame)
			if type(id) ~= "string" or string.sub(id, 1, 16) ~= "AuctionatorTabs_" then return end
			Now("Auctionator:tab:" .. id, function()
				if Covered() then return end
				Page(frame)
				local ok, tab = pcall(self.GetButton, self, id)
				if ok then Tab(tab) end
			end)
		end, KEY)
	end
	-- Its pop-ups, in the frame they're shown.
	if type(A.Dialogs) == "table" then
		for _, name in ipairs(DIALOG_CALLS) do
			if type(A.Dialogs[name]) == "function" then
				ns.HookOnce(A.Dialogs, name, function() Now("Auctionator:dialogs", Dialogs) end, KEY)
			end
		end
	end
	-- The crafting panel and the tracker's button.
	local C = A.CraftingInfo
	if type(C) == "table" then
		if type(C.InitializeProfessionsFrame) == "function" then
			ns.HookOnce(C, "InitializeProfessionsFrame", function() Now("Auctionator:crafting", Crafting) end, KEY)
		end
		if type(C.InitializeObjectiveTrackerFrame) == "function" then
			ns.HookOnce(C, "InitializeObjectiveTrackerFrame", function() Now("Auctionator:tracker", Tracker) end, KEY)
		end
	end
	-- Whatever is there already (a reload with the auction house or a profession open).
	Now("Auctionator:sweep", Sweep)
	Now("Auctionator:dialogs", Dialogs)
	Now("Auctionator:crafting", Crafting)
	Now("Auctionator:tracker", Tracker)
end, CAPS)

local function Repaint()
	for tex in pairs(accents) do Accent(tex) end
end
ns.me.On("StyleChanged", function()
	if Kit and On() then Guard(Repaint) end
end)
ns.me.On("SettingChanged", function(scope)
	if scope == "DaylightAddonSkins" and Kit and On() then Guard(Repaint) end
	-- Daylight UI's Auction House settings (2.0; the pick between its window and the game's is its
	-- "enabled", written by the swap icon on its header: 2.0 Windows\Swap.lua:49-58, and its
	-- module trades the windows before this event reaches plugins, 2.0 Core.lua:868-878): the
	-- game's window may be the one in use now. Swept on the next frame, out of a fight; a sweep
	-- while Daylight UI's window still covers it does nothing.
	if scope == "AuctionHouse" and Kit and On() then
		ns.Queue("Auctionator:sweep", Sweep, KEY)
		ns.Queue("Auctionator:fit", FitTabs, KEY)
	end
end)
