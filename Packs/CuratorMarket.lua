-- Curator: its Steamwheedle Exchange (the "Bourse", Curator's own auction house), its merchant,
-- the tabs it hangs on the game's windows, and the plain chrome of its case and pallet scenes.
-- Through the core (Packs\Curator.lua, ns.Curator); Curator's files are only read.
--
-- Dressed:
--   * CuratorMarketWindow: DaylightUI's window shell, title and X, as soon as Curator makes it (hidden,
--     at the Auction House's first opening); the panel it holds, CuratorMarket, is built the first
--     time the Exchange opens.
--   * CuratorMarket, all four pages (Buy, Sell, My Sales, My Purchases): the top tabs
--     CuratorMarketSellTab1-2 / MineTab1-2 / BoughtTab1-2 (DaylightUI's text tabs, the picked one
--     read from the game's own tab art); the bottom tabs CuratorMarketTab1-3, which Curator draws
--     itself on this client (the Kit's tab box, a line in the accent under the picked one); the auction
--     house grounds (marble, parchment, the categories' crest) off, the insets dark; the category
--     buttons (their bar art off, hover wash, the picked one in the accent, again after every
--     repaint); the column heads (their tab art off, a faint line under them, the sort arrow and
--     words in DaylightUI's inks); the table lines (faint stripes, hover wash, the picked line in
--     the accent); Curator's own hand-drawn scroll bars (DaylightUI's pill and track); the price
--     and count boxes and Curator's own text boxes (DaylightUI's input look); the summary lines
--     of My Sales / My Purchases; the Favorites and Refresh square buttons (the star in the
--     accent while the favorites filter is on); the Filter dropdown and its "every filter off"
--     badge; the small dropdowns' arrows; the picker's little tabs (an accent line under the picked
--     one); the purse's gold edge off; the "Create Auction" tab art
--     off; the item slot of the sell form; the confirm dialog; the "Opening soon" cover; the price
--     popup, the copy-address box and the "Ask for..." picker (each when it is first made).
--     Buttons, checks, dropdowns, search boxes and page arrows come through the Kit's walk and the
--     core's (Packs\Curator.lua).
--   * CuratorMarketSheet: window shell; its buttons and texts.
--   * CuratorMerchantFrame: window shell, CuratorMerchantFrameTab1-3, the goods (slot and label art
--     off, an outline round each good, hover wash), the foot art and the purse's gold edge off, the
--     page arrows (core). CuratorMerchantConfirm: window shell, its slot art off, an outline round
--     the icon. The card and pallet previews it puts beside the tooltip: DaylightUI's panel.
--   * The side tab Curator adds to the Auction House (AuctionHouseFrame) and to ClassTrainerFrame
--     (an alchemy master's): DaylightUI's icon tiles, in the accent while their window is open.
--     The "Curator" AuctionFrameTab<n> on the game's older AuctionFrame (Classic clients only; never
--     made on this client): a DaylightUI text tab. Neither Auction House piece while Daylight UI's
--     own Auction House window stands in for the game's (ns.DaylightCoversAH, as Packs\Auctionator
--     and Packs\Mastercraft do); dressed once the player picks the game's window.
--   * CuratorCrate (the case opening, also in souvenir-package mode) and CuratorPalletScene: only
--     their plain chrome. The buttons (Open, Key, Close, Open another case, Inspect, Second
--     Chance, Back, See the certificate, the lot's two buttons, the pallet's Back), the count
--     arrows, the Quick opening check, the item panel's hand-drawn scroll bar, and the face of
--     their plain texts (subtitle, hints, the panel's heading, the reason line, the notes).
-- Kept as Curator draws them: cards, cases, pallets, models and every scene's art and effects,
-- item and card icons (and the creatures drawn over them), rarity / rank / finish / state colors,
-- the ruby icons in prices, the favorite stars, the closed cover's crest, the curve of the sheet,
-- the case scene's title (its outlined 28 px words in Curator's own font), the slot words of a
-- several-case opening (Curator fits them to their width) and the pallet's gold Unpack button
-- (Hud.ClaimButton).
-- How each is reached: the Exchange from the Auction House (the side tab on its right edge) or
-- /curator test bourse; the sheet from "Its sheet" or a right click on a line; the merchant from
-- an alchemy or rogue master's gossip (or the trainer's side tab), the reseller from the
-- merchant's tab; cases with /curator cases (souvenirs: /curator package); a pallet from the
-- inventory or a Ctrl-click on a pallet at the reseller.
local _, ns = ...
if not ns.ok then return end
local C = ns.Curator
if not C then return end

local KEY = C.KEY
local Own, Kind, Widget = C.Own, C.Kind, C.Widget
local type, select, ipairs, pcall, string = type, select, ipairs, pcall, string

C.Area(function(Kit)
	-- What this file has dressed (frames and textures), so each is done once.
	local mine = setmetatable({}, { __mode = "k" })
	local function Once(x)
		if mine[x] then return false end
		mine[x] = true
		return true
	end

	local function Controls() return ns.Controls(KEY) end
	local function IsTex(x) return Kind(x) == "Texture" end
	local function IsButton(x)
		local k = Kind(x)
		return k == "Button" or k == "CheckButton"
	end

	local function Atlas(tex)
		if not IsTex(tex) then return nil end
		local ok, a = pcall(tex.GetAtlas, tex)
		if ok and type(a) == "string" then return a end
	end

	local function File(tex)
		if not IsTex(tex) then return nil end
		local ok, f = pcall(tex.GetTexture, tex)
		if not ok then return nil end
		if type(f) == "string" then return string.lower(f) end
		return f
	end

	local function Shade(tex, c)
		if IsTex(tex) and type(c) == "table" then tex:SetVertexColor(c[1], c[2], c[3], c[4] or 1) end
	end

	-- The first of the frames given (a frame's children) that passes test.
	local function FindAmong(test, ...)
		for i = 1, select("#", ...) do
			local c = select(i, ...)
			if Widget(c) and test(c) then return c end
		end
	end

	-- A button's own art (normal, pushed, disabled, highlight) faded for good.
	local function ArtOff(b)
		for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
			if type(b[get]) == "function" then Kit.Hide(b[get](b)) end
		end
	end

	-- A tab of the game's (PanelTabButtonTemplate and its kin) is picked while its active art is
	-- shown (PanelTemplates_SelectTab; the Kit fades that art, the game still shows and hides it).
	-- Curator picks its My Sales / My Purchases tabs once, as it builds them, so the tab's own art
	-- is the one sure sign.
	local function Picked(tab)
		local a = Own(tab, "LeftActive")
		return Widget(a) and a:IsShown() == true
	end

	-- Curator draws a tab itself where the client has no CharacterFrameTabButtonTemplate (this
	-- client has none: the Exchange's bottom tabs CuratorMarketTab1-3): its words in t.text, the
	-- game's old tab art in two sets it shows and hides (t:SetSelected), its words' font set again
	-- each time. Its art off, the Kit's tab box (as for a tab without the game's words), the line
	-- along its bottom in the accent while picked, read from the active set's art being shown.
	local ACTIVE
	local function DrawnPicked(tab)
		ACTIVE = ACTIVE or ns.FileIDs({ ["Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"] = true })
		for i = 1, select("#", tab:GetRegions()) do
			local r = select(i, tab:GetRegions())
			if IsTex(r) and r:IsShown() and ACTIVE[File(r)] then return true end
		end
		return false
	end
	local drawnLines = setmetatable({}, { __mode = "k" })
	local function DrawnPaint(tab)
		local line = drawnLines[tab]
		if not line then return end
		if DrawnPicked(tab) then
			C.Accent(line, 1)
			line:Show()
		else
			line:Hide()
		end
	end
	local function DrawnTab(tab)
		if type(Own(tab, "SetSelected")) ~= "function" or not C.IsString(Own(tab, "text")) then return end
		if not Once(tab) then return end
		Kit.Strip(tab)
		Kit.Shell(tab, "tab")
		Kit.HoverWash(tab)
		local line = tab:CreateTexture(nil, "OVERLAY")
		line:SetHeight(2)
		line:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 3, 3)
		line:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -3, 3)
		drawnLines[tab] = line
		C.Hook(tab, "SetSelected", DrawnPaint, "market:drawnTab")
		DrawnPaint(tab)
	end

	local function Tabs(fmt, n)
		for i = 1, n do
			local t = _G[string.format(fmt, i)]
			if Kind(t) == "Button" then
				if Own(t, "LeftActive") ~= nil then Kit.Tab(t, Picked) else DrawnTab(t) end
			end
		end
	end

	-- -----------------------------------------------------------------------------------------
	-- The Exchange's own pieces (UI/Market.lua), known by their parts
	-- -----------------------------------------------------------------------------------------

	-- An inset of the auction house (Curator's AHInset, the tables too): its ground of the game's
	-- auction house (marble, parchment, the categories' crest) off; its edge is the core's dark
	-- inset.
	local function Ground(f)
		local g, e = Own(f, "ground"), Own(f, "edge")
		if not (IsTex(g) and Widget(e)) then return false end
		if Once(g) then Kit.Hide(g) end
		return true
	end

	-- A category button: its bar art off for good (Curator sets its alpha again on every paint),
	-- a hover wash, the picked one in the accent (Curator sets the atlas of its pick again on every
	-- paint: b:SetUp, followed), the tree lines quiet.
	local function CategoryPick(b)
		local sel = Own(b, "sel")
		if IsTex(sel) then C.Accent(sel, 0.22) end
	end
	local function Category(b)
		if type(Own(b, "SetUp")) ~= "function" then return false end
		local normal, sel, hl, lines = Own(b, "normal"), Own(b, "sel"), Own(b, "hl"), Own(b, "lines")
		if not (IsTex(normal) and IsTex(sel) and IsTex(hl)) then return false end
		if Once(b) then
			Kit.Erase(normal)
			C.Wash(hl)
			if IsTex(lines) then C.Tint(lines, "OFF") end
			C.Hook(b, "SetUp", CategoryPick, "market:category")
			CategoryPick(b)
		end
		return true
	end

	-- A column head: its tab art off, a faint line under it, its words in the label ink, the sort
	-- arrow in the text ink, a hover wash.
	local function Head(h)
		if type(Own(h, "SetArrow")) ~= "function" then return false end
		local l, m, r = Own(h, "left"), Own(h, "middle"), Own(h, "right")
		if not (IsTex(l) and IsTex(m) and IsTex(r)) then return false end
		if Once(h) then
			Kit.Hide(l)
			Kit.Hide(m)
			Kit.Hide(r)
			local hl = h:GetHighlightTexture()
			if IsTex(hl) then C.Wash(hl) end
			local arrow = Own(h, "arrow")
			if IsTex(arrow) then C.Tint(arrow, "TEXT") end
			local text = Own(h, "text")
			if C.IsString(text) then C.Ink(text, "LABEL") end
			local line = h:CreateTexture(nil, "BORDER")
			line:SetHeight(1)
			line:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 2, 0)
			line:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -2, 0)
			C.Hairline(line, 0.12)
		end
		return true
	end

	-- A line of a table: the odd lines a faint stripe (the game's stripes off), a hover wash, the
	-- picked line in the accent. (Its cells, icons and star are Curator's.)
	local function Line(ln)
		local stripe, sel, hl = Own(ln, "stripe"), Own(ln, "selTex"), Own(ln, "hlTex")
		if not (IsTex(stripe) and IsTex(sel) and IsTex(hl)) then return false end
		if Once(ln) then
			local odd = Atlas(stripe) == "auctionhouse-rowstripe-1"
			stripe:SetColorTexture(1, 1, 1, odd and 0.03 or 0)
			C.Accent(sel, 0.22)
			C.Wash(hl)
		end
		return true
	end

	-- A summary line of My Sales / My Purchases (Deposits, History, On its way...): a hover wash,
	-- the picked one in the accent.
	local function Summary(b)
		if type(Own(b, "Paint")) ~= "function" or Own(b, "bg") ~= nil then return false end
		local sel, hl = Own(b, "sel"), Own(b, "hl")
		if not (IsTex(sel) and IsTex(hl) and C.IsString(Own(b, "text"))) then return false end
		if Once(b) then
			C.Accent(sel, 0.22)
			C.Wash(hl)
		end
		return true
	end

	-- Curator's own scroll bar (a Slider with the old scroll bar's knob and arrows): DaylightUI's
	-- pill on a faint track, the arrows' art off (they still take clicks, as the Kit's bars do).
	local function Scroller(sc)
		if Kind(sc) ~= "Slider" or type(Own(sc, "Wheel")) ~= "function" then return false end
		local up, down = Own(sc, "up"), Own(sc, "down")
		if not (IsButton(up) and IsButton(down)) then return false end
		if Once(sc) then
			local S = Kit.SCROLL
			local thumb = sc:GetThumbTexture()
			if IsTex(thumb) then Kit.ScrollThumb(sc, thumb) end
			local track = sc:CreateTexture(nil, "BACKGROUND")
			track:SetColorTexture(1, 1, 1, 1)
			track:SetWidth((S and S.width) or 4)
			track:SetPoint("TOP", sc, "TOP", 0, 0)
			track:SetPoint("BOTTOM", sc, "BOTTOM", 0, 0)
			Shade(track, S and S.track)
			ArtOff(up)
			ArtOff(down)
		end
		return true
	end

	-- A price box or a count box (the auction house's input field art): that art off, DaylightUI's
	-- input look. The ruby beside a price stays.
	local function FieldArt(eb, hide)
		local found = false
		for i = 1, select("#", eb:GetRegions()) do
			local r = select(i, eb:GetRegions())
			local a = Atlas(r)
			if a and string.find(a, "auctionhouse-ui-inputfield", 1, true) then
				found = true
				if hide then Kit.Hide(r) end
			end
		end
		return found
	end
	local function Field(eb)
		if Kind(eb) ~= "EditBox" or not FieldArt(eb, false) then return false end
		if Once(eb) then
			FieldArt(eb, true)
			Kit.EditBox(eb)
		end
		return true
	end

	-- Curator's own text box (a box in a dark inset, its grey hint inside: the picker's search, the
	-- copy-address box): the inset's art off, DaylightUI's input look on the box it holds. Walked
	-- no further by anyone (its inset would be shaded again).
	local function TypeBox(box)
		local eb, hint = Own(box, "eb"), Own(box, "hint")
		if Kind(eb) ~= "EditBox" or eb == box or not C.IsString(hint) or type(Own(box, "Get")) ~= "function" then return false end
		if Own(box, "NineSlice") == nil then return false end
		if Once(box) then
			Kit.Strip(box)
			Kit.EditBox(eb)
			C.Text(hint)
			C.Content(box)
		end
		return true
	end

	-- The Filter dropdown's red X (shown while a filter is on): DaylightUI's reset badge.
	local function ClearBadge(b)
		local tex, hl = Own(b, "tex"), Own(b, "hl")
		if not (IsTex(tex) and IsTex(hl)) then return false end
		local parent = b:GetParent()
		if not (Widget(parent) and Own(parent, "clear") == b) then return false end
		if Once(b) then
			Kit.Hide(tex)
			Kit.Hide(hl)
			Kit.ResetBadge(b)
		end
		return true
	end

	-- The confirm dialog of the Exchange (a dark dialog over the window, the rest shaded): its
	-- dialog border off, DaylightUI's panel. The shade stays.
	local function Dialog(over)
		local d = Own(over, "d")
		if not (Widget(d) and IsTex(Own(over, "shade")) and type(Own(over, "Ask")) == "function") then return false end
		if Once(over) then
			local border = FindAmong(function(c) return Kind(c) == "Frame" and IsTex(Own(c, "Bg")) end, d:GetChildren())
			if border then Kit.Strip(border) end
			C.Panel(d)
		end
		return true
	end

	-- A small dropdown or the Filter button's arrow (a button with its own arrow picture): the arrow
	-- in the text ink. The button itself is a game button (the Kit's walk).
	local function Arrow(b)
		local arrow = Own(b, "arrow")
		if not (IsTex(arrow) and C.IsString(Own(b, "label"))) then return false end
		if Once(arrow) then C.Tint(arrow, "TEXT") end
		return false
	end

	-- A little tab of the "Ask for..." picker (a game button with its own words, b.words, painted by
	-- b:Paint(on, text), the picked one held lit with LockHighlight and its words white): the
	-- button itself is the Kit's walk, which fades that highlight, so the picked one gets the
	-- accent line under it. Its state before the first paint we see: its words still in Curator's
	-- white (this runs before any pass inks them).
	local subLines = setmetatable({}, { __mode = "k" })
	local function SubPaint(b, on)
		local line = subLines[b]
		if not line then return end
		if on then
			C.Accent(line, 1)
			line:Show()
		else
			line:Hide()
		end
	end
	local function SubTab(b)
		local words = Own(b, "words")
		if type(Own(b, "Paint")) ~= "function" or type(Own(b, "Words")) ~= "function" or not C.IsString(words) then return false end
		if Once(b) then
			local line = b:CreateTexture(nil, "OVERLAY")
			line:SetHeight(2)
			line:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 3, 2)
			line:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 2)
			line:Hide()
			subLines[b] = line
			C.Hook(b, "Paint", SubPaint, "market:subTab")
			local r, g, bl = words:GetTextColor()
			SubPaint(b, type(r) == "number" and r > 0.95 and g > 0.95 and bl > 0.95)
		end
		return false
	end

	-- The walk over the Exchange (and its lazy pieces): Curator's own controls, by their parts.
	-- Content (marked by the core) and what is done is left; nothing but real frames is visited.
	local WALK = 12
	local function Walk(depth, ...)
		for i = 1, select("#", ...) do
			local c = select(i, ...)
			if Widget(c) and not C.skip[c] then
				local t = Kind(c)
				local stop = false
				if t == "Button" then
					Arrow(c)
					SubTab(c)
					stop = Category(c) or Head(c) or Line(c) or Summary(c) or ClearBadge(c) or Dialog(c)
				elseif t == "Frame" then
					Ground(c)
					stop = TypeBox(c)
				elseif t == "EditBox" then
					Field(c)
					stop = true
				elseif t == "Slider" then
					stop = Scroller(c)
				end
				if not stop and depth < WALK and c.GetChildren then Walk(depth + 1, c:GetChildren()) end
			end
		end
	end

	local function Dress(root)
		if not C.On() or not Widget(root) or not Controls() then return end
		C.Mark(root)
		Ground(root)
		Walk(1, root:GetChildren())
	end

	-- The Buy page (CuratorMarket.pages.buy), read without touching Curator's tables.
	local function Page(market, key)
		local pages = Own(market, "pages")
		if type(pages) ~= "table" then return nil end
		local p = rawget(pages, key)
		if Widget(p) then return p end
	end

	-- The Favorites button holds itself pushed while the favorites filter is on: its star then in
	-- the accent, else in the text ink (Curator sets its state on every paint).
	local function FavoriteState(b)
		local icon = Own(b, "Icon")
		if not IsTex(icon) or not ns.Enabled(KEY) then return end
		if b:GetButtonState() == "PUSHED" then
			local r, g, bl = ns.AccentOf(KEY)
			icon:SetVertexColor(r, g, bl)
		else
			Shade(icon, Kit.TEXT)
		end
	end

	-- The Exchange's window: Curator makes it (hidden) as the Auction House first opens, and only
	-- builds the panel in it on the Exchange's first opening, a frame after the window shows: its
	-- shell is put on as soon as it exists, so it opens dressed. (The side tab on the Auction House
	-- is in the accent while the window is open.)
	local function MarketWindow(w)
		if not C.On() or not Widget(w) then return end
		C.Window(w)
		C.Script(w, "OnHide", ns.SideTilesPaintSoon, "market:tiles")
	end
	ns.Watch(KEY, "CuratorMarketWindow", MarketWindow)

	-- What is only the Exchange's, by key: done as it is first found (all four pages are built then).
	local function Market(m)
		if not C.On() then return end
		MarketWindow(_G.CuratorMarketWindow)
		local closed = Own(m, "closed")
		local cover = Widget(closed) and Own(closed, "bg")
		if IsTex(cover) and Once(cover) then ns.PaintBack(cover, 0.94) end
		if not Controls() then return end
		-- (Before the Kit's walk reaches them: the picked tab is read from the tab's own art.)
		Tabs("CuratorMarketTab%d", 3)
		Tabs("CuratorMarketSellTab%d", 2)
		Tabs("CuratorMarketMineTab%d", 2)
		Tabs("CuratorMarketBoughtTab%d", 2)
		local edge = Own(m, "moneyEdge")
		if Widget(edge) and Once(edge) then Kit.Strip(edge) end
		local buy = Page(m, "buy")
		local favs = buy and Own(buy, "favs")
		if IsButton(favs) and Once(favs) then
			Kit.IconButton(favs)
			C.Hook(favs, "SetButtonState", FavoriteState, "market:favs")
			FavoriteState(favs)
		end
		local sell = Page(m, "sell")
		if sell then
			for _, k in ipairs({ "tabL", "tabM", "tabR" }) do
				local tex = Own(sell, k)
				if IsTex(tex) and Once(tex) then Kit.Hide(tex) end
			end
			local form = Own(sell, "form")
			local slot = Widget(form) and Own(form, "slot")
			if Widget(slot) and Once(slot) then
				Kit.Hide(Own(slot, "art"))
				Kit.Hide(Own(form, "empty"))
				Kit.Shell(slot, "row")
				local icon = Own(form, "icon")
				if IsTex(icon) then Kit.Outline(icon, 2, "outline", true) end
			end
		end
		Dress(m)
	end

	C.Track("CuratorMarket", Market, { after = function(m)
		Dress(m)
		ns.SideTilesPaintSoon()
	end })

	-- The lazy pieces of the Exchange, each dressed as it is first made (then on each show).
	local function Child(test)
		return function()
			local m = _G.CuratorMarket
			if Widget(m) then return FindAmong(test, m:GetChildren()) end
		end
	end
	local AFTER = { after = Dress }
	-- The "Ask for..." picker: its ground in DaylightUI's window color.
	C.TrackBy(Child(function(c) return Own(c, "pager") ~= nil and Own(c, "casedBox") ~= nil end), function(pk)
		local bg = Own(pk, "bg")
		if IsTex(bg) and Once(bg) then ns.PaintBack(bg, 0.97) end
		Dress(pk)
	end, AFTER)
	-- The copy-address box.
	C.TrackBy(Child(function(c) return Own(c, "box") ~= nil and Own(c, "close") ~= nil and Own(c, "hint") ~= nil end), Dress, AFTER)
	-- The price popup under the Filter button (its tooltip backdrop is the core's panel).
	C.TrackBy(function()
		local m = _G.CuratorMarket
		local buy = Widget(m) and Page(m, "buy")
		local box = buy and Own(buy, "min")
		if Widget(box) then return box:GetParent() end
	end, Dress, AFTER)

	-- The sheet of a thing: its window; what it shows of the thing (card, case, pallet, icon) kept.
	C.Track("CuratorMarketSheet", function(w)
		local holder = Own(w, "holder")
		if Widget(holder) then C.Content(holder) end
		C.Window(w)
		-- (Its divider is a texture of the window itself, faded with the window's art by the shell:
		-- back at the alpha Curator gave it, a faint line from the core's pass.)
		-- (Only the atlas line: where the client lacks that atlas, Curator draws a gold line, which
		-- stays faded.)
		local line = Own(w, "line")
		if IsTex(line) and Atlas(line) == "Options_HorizontalDivider" and Once(line) then line:SetAlpha(0.6) end
	end)

	-- -----------------------------------------------------------------------------------------
	-- The merchant (UI/Merchant.lua)
	-- -----------------------------------------------------------------------------------------

	-- A good: the game's slot and label art off for good (Curator tints them again on every paint),
	-- an outline round its button, a hover wash. Its icon (and the booster drawn in it), its
	-- name's rarity color and its price stay.
	local function Good(g)
		local slot, frame, b = Own(g, "slot"), Own(g, "frame"), Own(g, "button")
		if not (IsTex(slot) and IsTex(frame) and Kind(b) == "Button" and IsTex(Own(b, "icon"))) then return end
		if not Once(g) then return end
		Kit.Erase(slot)
		Kit.Erase(frame)
		Kit.Erase(b:GetNormalTexture())
		Kit.Erase(b:GetPushedTexture())
		local hl = b:GetHighlightTexture()
		if IsTex(hl) then C.Wash(hl) end
		Kit.Outline(b, 2, "outline")
	end

	-- The card and pallet previews beside the tooltip (made on the first hover of such a good):
	-- DaylightUI's panel round them; the card and the pallet are Curator's.
	local previews = 0
	local function Preview(v)
		if not Once(v) then return end
		previews = previews + 1
		C.Panel(v)
		C.Text(Own(v, "word"))
	end
	-- (Each a BackdropTemplate frame on UIParent with the tooltip's border, its card or pallet and
	-- its word: UI/Merchant.lua M:CardPreview, UI/Pallet.lua PU:Preview.)
	local function IsPreview(c)
		return not mine[c] and C.IsString(Own(c, "word")) and (Widget(Own(c, "pallet")) or Widget(Own(c, "card")))
			and C.BackdropKind(c) == "panel"
	end
	local function FindPreviews()
		if previews >= 2 or not C.On() then return end
		local ui = _G.UIParent
		local v = FindAmong(IsPreview, ui:GetChildren())
		while v do
			Preview(v)
			v = FindAmong(IsPreview, ui:GetChildren())
		end
	end
	-- (Looked for once per hover of a good, and no more once both are found.)
	local function PreviewsSoon()
		if previews < 2 then ns.Queue("Curator:previews", FindPreviews, KEY) end
	end

	local function Merchant(f)
		C.Window(f)
		C.Script(f, "OnHide", ns.SideTilesPaintSoon, "market:tiles")
		if not Controls() then return end
		Tabs("CuratorMerchantFrameTab%d", 3)
		for i = 1, select("#", f:GetChildren()) do
			local g = select(i, f:GetChildren())
			if Widget(g) then
				Good(g)
				local b = Own(g, "button")
				if Kind(b) == "Button" then
					C.Script(b, "OnEnter", PreviewsSoon, "market:previews")
				end
			end
		end
		local foot = Own(f, "foot")
		if Widget(foot) and Once(foot) then
			for i = 1, select("#", foot:GetRegions()) do
				local r = select(i, foot:GetRegions())
				if IsTex(r) then Kit.Hide(r) end
			end
		end
		local money = Own(f, "money")
		local edge = C.IsString(money) and money:GetParent()
		if Widget(edge) and edge ~= f and Once(edge) then
			ns.NoBackdrop(edge)
			Kit.Strip(edge)
		end
	end
	C.Track("CuratorMerchantFrame", Merchant, { after = function() ns.SideTilesPaintSoon() end })

	-- The buy dialog: its dialog backdrop is DaylightUI's window; the game's empty slot off, an
	-- outline round the icon (Curator's).
	C.Track("CuratorMerchantConfirm", function(d)
		C.Window(d)
		if not Controls() then return end
		local slot, icon = Own(d, "slot"), Own(d, "icon")
		if IsTex(slot) and Once(slot) then Kit.Erase(slot) end
		if IsTex(icon) and Once(icon) then Kit.Outline(icon, 2, "outline", true) end
	end)

	-- -----------------------------------------------------------------------------------------
	-- The tabs Curator puts on the game's windows
	-- -----------------------------------------------------------------------------------------

	local ICONS
	local function Icons()
		if not ICONS then
			ICONS = ns.FileIDs({
				["Interface\\Icons\\INV_Misc_Coin_17"] = "bourse",
				["Interface\\Icons\\INV_Potion_43"] = "shop",
			})
		end
		return ICONS
	end

	-- A side tab of Curator's (LargeSideTabButtonTemplate, which is a Frame on this client): its
	-- icon, known by its picture.
	local function SideTabOf(which)
		return function(c)
			if type(c.SetCustomOnMouseUpHandler) ~= "function" then return false end
			local icon = Own(c, "Icon")
			return IsTex(icon) and Icons()[File(icon)] == which
		end
	end

	local function Shown(name)
		return function()
			local f = _G[name]
			return Widget(f) and f:IsShown() == true
		end
	end

	-- DaylightUI's icon tile, as the core gives Curator's side tabs; the picked look follows the
	-- window it opens.
	local tiled = setmetatable({}, { __mode = "k" })
	local function SideTab(tab, picked)
		if tiled[tab] or not C.On() or not Controls() then return end
		tiled[tab] = true
		Kit.Strip(tab)
		if ns.SideTile(tab, { picked = picked, copy = true, key = KEY }) and type(tab.SetChecked) == "function" then
			C.Hook(tab, "SetChecked", ns.SideTilesPaintSoon, "market:tile")
		end
	end

	-- The Exchange's tab on the Auction House: not while Daylight UI's own Auction House window
	-- stands in for the game's (the game's window is parked out of sight under it then).
	local bourseTab
	local function BourseTab()
		if bourseTab and not ns.DaylightCoversAH() then SideTab(bourseTab, Shown("CuratorMarketWindow")) end
	end
	ns.Watch(KEY, function()
		local ah = _G.AuctionHouseFrame
		if Widget(ah) and ah:IsShown() then return FindAmong(SideTabOf("bourse"), ah:GetChildren()) end
	end, function(tab)
		bourseTab = tab
		local ah = _G.AuctionHouseFrame
		if Widget(ah) then C.Script(ah, "OnShow", BourseTab, "market:ahTab") end
		BourseTab()
	end)

	-- The "Curator" tab on the game's older AuctionFrame (Classic clients only).
	local classicTab
	local function ClassicTab()
		if classicTab and Controls() and not ns.DaylightCoversAH() and not tiled[classicTab] then
			tiled[classicTab] = true
			Kit.Tab(classicTab, function() return false end)
		end
	end
	ns.Watch(KEY, function()
		local af = _G.AuctionFrame
		local n = Widget(af) and Own(af, "numTabs")
		local tab = type(n) == "number" and _G["AuctionFrameTab" .. n]
		if Widget(tab) and tab.GetText and tab:GetText() == "Curator" then return tab end
	end, function(tab)
		classicTab = tab
		ClassicTab()
	end)

	-- Daylight UI's Auction House settings changed (the pick between its window and the game's):
	-- the game's window may be the one in use now.
	ns.me.On("SettingChanged", function(scope)
		if scope == "AuctionHouse" and C.On() then
			ns.Queue("Curator:ahTabs", function()
				BourseTab()
				ClassicTab()
			end, KEY)
		end
	end)

	-- The alchemy master's tab on the trainer's window (it opens the merchant).
	ns.Watch(KEY, function()
		local t = _G.ClassTrainerFrame
		if Widget(t) and t:IsShown() then return FindAmong(SideTabOf("shop"), t:GetChildren()) end
	end, function(tab)
		SideTab(tab, Shown("CuratorMerchantFrame"))
	end)

	-- -----------------------------------------------------------------------------------------
	-- The case scene and the pallet scene: full-screen stages, only their plain chrome
	-- -----------------------------------------------------------------------------------------

	local function Button(b)
		if Kind(b) == "Button" then Kit.Button(b) end
	end

	-- A hand-drawn scroll bar's colors (its size and place are Curator's, set on every refill).
	local function ScrollColors(track, thumb)
		local S = Kit.SCROLL
		if not S then return end
		if IsTex(track) and Once(track) then
			local c = S.track
			track:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
		end
		if IsTex(thumb) and Once(thumb) then
			local c = S.thumb
			thumb:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
		end
	end

	-- Everything plain the case scene has made so far (its lot view and certificate button come
	-- later). Alphas, places and sizes stay Curator's: its fades drive them.
	local function Crate(f)
		if not C.On() or not Widget(f) then return end
		-- (Its title, 28 px with an outline over the scene, stays in Curator's own font.)
		for _, k in ipairs({ "sub", "hint", "why" }) do C.Text(Own(f, k)) end
		local panel = Own(f, "panel")
		if Widget(panel) then
			C.Text(Own(panel, "head"))
			C.Text(Own(panel, "inspect"))
		end
		local rv, ins, lot = Own(f, "reveal"), Own(f, "inspect"), Own(f, "lot")
		if Widget(rv) then C.Text(Own(rv, "note")) end
		if Widget(ins) then
			C.Text(Own(ins, "from"))
			C.Text(Own(ins, "hint"))
		end
		if Widget(lot) then C.Text(Own(lot, "hint")) end
		if not Controls() then return end
		if Widget(panel) then ScrollColors(Own(panel, "track"), Own(panel, "thumb")) end
		Button(Own(f, "open"))
		Button(Own(f, "key"))
		Button(Own(f, "quit"))
		local less, more = Own(f, "less"), Own(f, "more")
		if Kind(less) == "Button" then Kit.PageButton(less, "left") end
		if Kind(more) == "Button" then Kit.PageButton(more, "right") end
		local fast = Own(f, "fast")
		if Kind(fast) == "CheckButton" then Kit.Check(fast) end
		if Widget(rv) then
			for _, k in ipairs({ "again", "inspect", "close", "second" }) do Button(Own(rv, k)) end
		end
		if Widget(ins) then
			Button(Own(ins, "back"))
			Button(Own(ins, "certBtn"))
		end
		if Widget(lot) then
			Button(Own(lot, "again"))
			Button(Own(lot, "close"))
		end
	end

	-- (Again a frame after a show, once however many layers show together.)
	local function CrateSoon()
		ns.Queue("Curator:crate", function() Crate(_G.CuratorCrate) end, KEY)
	end
	ns.Watch(KEY, "CuratorCrate", function(f)
		C.Script(f, "OnShow", CrateSoon, "market:crate")
		for _, k in ipairs({ "reveal", "inspect" }) do
			local layer = Own(f, k)
			if Widget(layer) then C.Script(layer, "OnShow", CrateSoon, "market:crate") end
		end
		Crate(f)
	end)
	-- (The lot view of several cases, made on the first such opening; the certificate button, on
	-- the first certificate shown.)
	ns.Watch(KEY, function()
		local f = _G.CuratorCrate
		local lot = Widget(f) and Own(f, "lot")
		if Widget(lot) then return lot end
	end, function(lot)
		C.Script(lot, "OnShow", CrateSoon, "market:crate")
		Crate(_G.CuratorCrate)
	end)
	ns.Watch(KEY, function()
		local f = _G.CuratorCrate
		local ins = Widget(f) and Own(f, "inspect")
		local b = Widget(ins) and Own(ins, "certBtn")
		if Widget(b) then return b end
	end, function() Crate(_G.CuratorCrate) end)

	-- The pallet scene: its texts' face, its Back button (the gold Unpack button is Curator's).
	local function Pallet(f)
		if not C.On() then return end
		for _, k in ipairs({ "title", "sub", "have", "destLabel", "hint" }) do C.Text(Own(f, k)) end
		local ctl = Own(f, "ctl")
		if Widget(ctl) and Controls() then Button(Own(ctl, "back")) end
	end
	ns.Watch(KEY, "CuratorPalletScene", function(f)
		C.Script(f, "OnShow", Pallet, "market:pallet")
		Pallet(f)
	end)
end)
