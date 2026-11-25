-- Curator: its named windows, panels and pop-ups (not the album and its pages, nor the booster
-- scene, the market or the merchant window: those are other Curator* files). Each is looked for by
-- name through the core's watches (Packs\Curator.lua: C.Track), dressed in the frame it's made,
-- and again on every show; Curator's own repaints of words are followed by the core's string hooks.
--
-- Dressed (how each is reached in the game):
--   * Windows on the game's portrait frame, as DaylightUI's window (shell, title on the left, the
--     X), their buttons, insets, dividers, bars, page arrows and words: CuratorInnCard (talk to an
--     innkeeper), CuratorTavernBet (innkeeper: "The innkeeper's bet"), CuratorGolden (/curator
--     golden), CuratorCardView (click a Curator card link in chat), CuratorMainWindow (/curator
--     main), CuratorChestWindow (/curator chest on a reroll), CuratorReseller (a general goods
--     vendor: the side tab, "Under the counter"), CuratorOptionsWindow (only on a client without
--     the game's Settings), CuratorWheel and CuratorAllIn (the Gambler's talents, album Talents
--     page), CuratorGift (/curator gift), CuratorMandatory and CuratorNews (/curator news),
--     CuratorPatternView (author tests), CuratorSite (/curator site), CuratorSuspended. The
--     textures Curator put on the window itself (the tavern's wall, lamp and table, the card view's
--     halo and gem, the coin of All In, the alert icons, the news bullets, the site's crosses) are
--     kept as they were: only the game template's own ground goes.
--   * Windows drawn with the old dialog backdrop, as DaylightUI's window: CuratorBankPanel (open
--     the bank), CuratorGossip (talk to an innkeeper with Dialogue UI or Immersion on; its rows'
--     hover in DaylightUI's wash), CuratorRubyShop (/curator counter), CuratorSearch (/curator
--     search; its rows' hover in the wash).
--   * Small panels in DaylightUI's panel look, Curator's dark ground and gold edge off:
--     CuratorLeads (/curator leads), CuratorGoldenTracker (a golden quest under way),
--     CuratorGoldenPrompt (target a faction leader with the golden quest), CuratorLive (a guild
--     member's opening: only its loot-toast ground; all else in it is the animation),
--     CuratorMailGift (open a letter with a gift code; the core makes it a panel),
--     CuratorAlertsMover (/curator alerts; its two preview boxes the same way).
--   * The section buttons of CuratorReseller and CuratorRubyShop (Curator's NavButton: dark card,
--     gold glow, gold side mark) as DaylightUI list rows, the open one in the accent; the
--     Reseller's "Under the counter" columns as quiet rows; the golden quest's reward choices with
--     the picked frame in the accent; the bet's rarity buttons with the picked one (the game's
--     locked highlight) in an accent wash.
--   * The Reseller's side tab on the game's merchant window (a general goods vendor the reseller
--     stands at): DaylightUI's clean icon tile, a quiet one (the game shows that window from its
--     own secure code), the picked one in the accent.
--   * The rumor parchments' words keep their brown ink: only the core's own pass goes over them,
--     never the Kit's walk (which lightens dark words).
--   * The tour (album: the (i) button, /curator tour): its bubble as DaylightUI's panel with its
--     Previous / Next buttons and X; the gold light round what it shows and the bubble's arrow kept.
--   * CuratorOptions, Curator's page in the game's Settings (Esc > Options > AddOns > Curator):
--     the Game settings window pack (Packs\BlizzardSettings.lua) dresses addon pages there (their
--     buttons, checkboxes, dropdowns and words) and leaves their sliders to the addon's pack, so
--     only the three sliders are done here; when that pack is off, this one dresses the whole page.
--   * Content windows, only their plain buttons: CuratorCertificate (Close the certificate),
--     CuratorScratchCard (its two buttons and X), CuratorViewer (Back / Turn it over / The whole
--     card), the rumor parchments CuratorRumor and CuratorRumorBuy (their X and page arrows).
-- Kept as Curator draws them: every card widget, model, scene and animation (the wheel, the coin,
-- the scratch ticket, the live panel's pack, card and light, the viewer's room, the bet's table,
-- keeper, bubble and dealt cards, the chest's art, the certificate document, the loyalty card,
-- slate, signed card and round banner of the inn), the parchment of the rumor notes, the gold
-- claim buttons (Hud.ClaimButton) and the count badges (Hud.Badge), rarity, finish, rank and
-- state colors (the wheel's and All In's results, the card view's name), every icon.
-- Left to DaylightUI: CuratorMinimapButton (its ring makes it one of DaylightUI's minimap drawer's
-- buttons, as other addons' are), the gossip rows Curator adds to the game's gossip window (that
-- window's skin; their OnClick is Curator's and never touched), GameTooltip, the chat links.
local _, ns = ...
if not ns.ok then return end
local C = ns.Curator
if not C then return end

local KEY = C.KEY
local Own, Kind, Widget, IsTexture, IsString = C.Own, C.Kind, C.Widget, C.IsTexture, C.IsString
local select, type, pairs, ipairs = select, type, pairs, ipairs

C.Area(function(Kit)
	local function Controls() return ns.Controls(KEY) end

	-- The first child among ... that passes test.
	local function FindIn(test, ...)
		for i = 1, select("#", ...) do
			local c = select(i, ...)
			if Widget(c) and test(c) then return c end
		end
	end

	local function EachIn(fn, ...)
		for i = 1, select("#", ...) do
			local c = select(i, ...)
			if Widget(c) then fn(c) end
		end
	end

	local function ContentKeys(f, ...)
		for i = 1, select("#", ...) do C.Content(Own(f, (select(i, ...)))) end
	end

	-- -----------------------------------------------------------------------------------------
	-- Content everywhere in Curator: its gold claim buttons and its count badges
	-- -----------------------------------------------------------------------------------------

	-- (Hud.ClaimButton is marked content by Packs\CuratorScenes.lua.)
	-- Hud.Badge: its art grows in a tween (Hud.lua:511).
	C.AddContentTest(function(f)
		return type(Own(f, "SetCount")) == "function" and IsTexture(Own(f, "tex"))
	end)
	-- The card view's case card (made later, on CuratorCardView.holder).
	C.AddContentTest(function(f)
		local cv = _G.CuratorCardView
		local holder = Widget(cv) and Own(cv, "holder")
		return holder ~= nil and f:GetParent() == holder
	end)
	-- The pattern viewer's cards and cases (each in a holder with its grade).
	C.AddContentTest(function(f)
		local pv = _G.CuratorPatternView
		if not Widget(pv) then return false end
		local p = f:GetParent()
		return p ~= nil and p ~= pv and IsString(Own(p, "grade")) and p:GetParent() == pv
	end)

	-- -----------------------------------------------------------------------------------------
	-- Shared pieces
	-- -----------------------------------------------------------------------------------------

	-- A portrait window as DaylightUI's window, the textures Curator put on the window itself kept
	-- (Kit.Window hides every texture a window owns; of these only the template's ground is the
	-- game's: Bg and TopTileStreaks).
	local function Window(f, opts)
		local saved = {}
		local bg, streaks = Own(f, "Bg"), Own(f, "TopTileStreaks")
		for i = 1, select("#", f:GetRegions()) do
			local r = select(i, f:GetRegions())
			if IsTexture(r) and r ~= bg and r ~= streaks then saved[r] = r:GetAlpha() end
		end
		C.Window(f, opts)
		for tex, alpha in pairs(saved) do tex:SetAlpha(alpha) end
	end

	-- Looks for a portrait window: setup(f) (its content marked first), then the window, then
	-- the core's passes (pass: C.Pass's opts, its `after` on every pass).
	local function TrackWindow(name, setup, pass, winOpts)
		C.Track(name, function(f)
			if setup then setup(f) end
			Window(f, winOpts)
		end, pass)
	end

	-- The game's highlight of a button of Curator's in DaylightUI's hover wash (once).
	local washed = setmetatable({}, { __mode = "k" })
	local function WashOf(b)
		if washed[b] or not b.GetHighlightTexture then return end
		local hl = b:GetHighlightTexture()
		if IsTexture(hl) then
			washed[b] = true
			C.Wash(hl)
		end
	end

	-- A small panel of Curator's own (a dark color texture, maybe a gold edge): those off,
	-- DaylightUI's panel shell on (the core's C.Panel). Curator sets them once, at build.
	local function Chrome(f, ...)
		for i = 1, select("#", ...) do Kit.Hide(Own(f, (select(i, ...)))) end
		C.Panel(f)
	end

	-- Curator's NavButton (Hud.lua:684): the sliced dark card and its gold glow (BORDER, ADD; its
	-- alpha set again on every Paint, so erased with a mask), a gold mark on its side shown when
	-- it's the open one. A DaylightUI row; the mark's showing is what the row reads as picked, and
	-- the row is painted again after each of the button's Paint.
	local navs = setmetatable({}, { __mode = "k" })
	local function IsNav(b)
		return Kind(b) == "Button" and IsTexture(Own(b, "accent")) and type(Own(b, "Paint")) == "function"
			and Widget(Own(b, "badge"))
	end
	local function NavTab(b)
		if navs[b] or not IsNav(b) or not Controls() then return end
		navs[b] = true
		local accent = Own(b, "accent")
		for i = 1, select("#", b:GetRegions()) do
			local r = select(i, b:GetRegions())
			if IsTexture(r) and r ~= accent and r:GetDrawLayer() == "BORDER" and r:GetBlendMode() == "ADD" then
				Kit.Erase(r)
			end
		end
		local keep = {}
		local icon = Own(b, "icon")
		if IsTexture(icon) then keep[icon] = true end
		Kit.Row(b, keep, accent)
		C.Hook(b, "Paint", function(self) Kit.RepaintRow(self) end, "windows:nav")
	end
	local function NavTabsOf(f)
		EachIn(NavTab, f:GetChildren())
	end

	-- Hud.Panel on a plain frame (the sliced dark card in BACKGROUND, its glow in BORDER, ADD):
	-- those off, a quiet DaylightUI row in their place.
	local panels = setmetatable({}, { __mode = "k" })
	local function HudPanel(c)
		if not Widget(c) or panels[c] then return end
		panels[c] = true
		for i = 1, select("#", c:GetRegions()) do
			local r = select(i, c:GetRegions())
			if IsTexture(r) then
				local layer = r:GetDrawLayer()
				if layer == "BACKGROUND" or (layer == "BORDER" and r:GetBlendMode() == "ADD") then Kit.Erase(r) end
			end
		end
		Kit.Shell(c, "row")
	end

	-- Buttons of a content window (the window itself is left to Curator).
	local function Buttons(f, ...)
		if not Controls() then return end
		for i = 1, select("#", ...) do
			local b = Own(f, (select(i, ...)))
			if Widget(b) then Kit.Button(b) end
		end
	end

	-- -----------------------------------------------------------------------------------------
	-- Portrait windows
	-- -----------------------------------------------------------------------------------------

	-- The inn's counter: its slate, loyalty card, signed card and round banner are content.
	TrackWindow("CuratorInnCard", function(f)
		ContentKeys(f, "slate", "card", "gift", "round")
	end)

	-- The innkeeper's bet: the keeper, his bubble and the room's art stay (the wall, lamp and
	-- table are the window's own textures, kept by Window). The rarity column marks the picked
	-- rarity with the game's locked highlight (UI:SetRarity, LockHighlight), set before this ever
	-- sees the window: that highlight stays, as an accent wash.
	local rarities = setmetatable({}, { __mode = "k" })
	local function RarityButton(b)
		if rarities[b] or Kind(b) ~= "Button" or Own(b, "noAlbum") == nil or Own(b, "n") == nil then return end
		rarities[b] = true
		Kit.Button(b)
		local hl = b:GetHighlightTexture()
		if IsTexture(hl) then
			hl:SetAlpha(1)
			C.Accent(hl, 0.22)
		end
	end
	TrackWindow("CuratorTavernBet", function(f)
		ContentKeys(f, "keeper", "bubble")
	end, { after = function(f)
		local ch = Own(f, "choose")
		if Widget(ch) and Controls() then EachIn(RarityButton, ch:GetChildren()) end
	end })

	-- The golden quest: its headings in DaylightUI's label ink (set once by Curator); the reward
	-- choices' picked frame (gold, set once) in the accent, their hover in the wash.
	local choices = setmetatable({}, { __mode = "k" })
	local function Choice(b)
		if choices[b] or Kind(b) ~= "Button" or not IsString(Own(b, "miss")) then return end
		local sel = Own(b, "sel")
		if not Widget(sel) then return end
		choices[b] = true
		local fill = Own(sel, "fill")
		for i = 1, select("#", sel:GetRegions()) do
			local r = select(i, sel:GetRegions())
			if IsTexture(r) then C.Accent(r, r == fill and 0.14 or 0.95) end
		end
		WashOf(b)
	end
	TrackWindow("CuratorGolden", function(f)
		for _, k in ipairs({ "head", "objTitle", "rewTitle" }) do C.Ink(Own(f, k), "LABEL") end
	end, { after = function(f) EachIn(Choice, f:GetChildren()) end })

	-- The card view: the card (and the case card) are content; Curator fades the window in
	-- itself (K:Open tweens its alpha); the card's name keeps Curator's gold or rank color.
	TrackWindow("CuratorCardView", function(f)
		C.KeepInk(Own(f, "name"))
	end, nil, { ownFade = true })

	TrackWindow("CuratorMainWindow")
	-- (Its chest art grows and glows in a tween.)
	TrackWindow("CuratorChestWindow", function(f) ContentKeys(f, "art") end)

	-- The reseller: its section buttons, the cluster of card backs on "He buys back", the
	-- columns "Under the counter" and the coin flip's rows.
	TrackWindow("CuratorReseller", function(f)
		local buy = Own(f, "buy")
		if Widget(buy) then C.Content(Own(buy, "art")) end
	end, { after = function(f)
		NavTabsOf(f)
		local co = Own(f, "counter")
		if not Widget(co) then return end
		HudPanel(Own(co, "mb"))
		local cf = Own(co, "cf")
		HudPanel(cf)
		if Widget(cf) then
			EachIn(function(r)
				if Kind(r) == "Button" and IsString(Own(r, "sub")) then
					local hl = Own(r, "hl")
					if IsTexture(hl) and not washed[r] then
						washed[r] = true
						C.Wash(hl)
					end
				end
			end, cf:GetChildren())
		end
	end })

	TrackWindow("CuratorOptionsWindow")

	-- The Gambler's wheel: the wheel is content; the won part's percent and the result keep
	-- Curator's gold (won) and gray (nothing).
	TrackWindow("CuratorWheel", function(f)
		ContentKeys(f, "wheel")
		C.KeepInk(Own(f, "result"))
		EachIn(function(r)
			if IsString(Own(r, "pct")) and IsTexture(Own(r, "swatch")) then C.KeepInk(Own(r, "pct")) end
		end, f:GetChildren())
	end)
	TrackWindow("CuratorAllIn", function(f) C.KeepInk(Own(f, "result")) end)

	TrackWindow("CuratorGift")
	TrackWindow("CuratorMandatory")
	TrackWindow("CuratorNews")
	TrackWindow("CuratorPatternView")
	TrackWindow("CuratorSite")
	TrackWindow("CuratorSuspended")

	-- -----------------------------------------------------------------------------------------
	-- Windows on the old dialog backdrop
	-- -----------------------------------------------------------------------------------------

	C.Track("CuratorBankPanel", function(f) C.Plain(f) end)
	C.Track("CuratorRubyShop", function(f) C.Plain(f) end, { after = NavTabsOf })

	-- Its rows are made as more lines come (never fewer): each pass looks again. (No parent of
	-- its own, on purpose: the shell is on the window itself, so it stays with it.)
	local function RowWashes(f, a, b)
		EachIn(function(r)
			if Kind(r) == "Button" and Own(r, a) ~= nil and Own(r, b) ~= nil then WashOf(r) end
		end, f:GetChildren())
	end
	C.Track("CuratorGossip", function(f) C.Plain(f) end, { after = function(f) RowWashes(f, "icon", "text") end })
	-- (Dark dialog ground with a tooltip edge: a window all the same.)
	C.Track("CuratorSearch", function(f) C.Plain(f) end, { after = function(f) RowWashes(f, "name", "album") end })

	-- -----------------------------------------------------------------------------------------
	-- Small panels
	-- -----------------------------------------------------------------------------------------

	C.Track("CuratorLeads", function(f) Chrome(f, "bg") end)
	C.Track("CuratorGoldenTracker", function(f) Chrome(f, "bg") end)
	C.Track("CuratorGoldenPrompt", function(f)
		Chrome(f, "edge", "bg")
		WashOf(f)
	end)
	-- (Its tooltip-edged backdrop is made a panel by the core's pass; its claim button is content.)
	C.Track("CuratorMailGift", nil, { noWindow = true })
	C.Track("CuratorAlertsMover", nil, { noWindow = true })
	-- The live panel is an animation: only its ground (the game's loot toast, set once) gives way.
	C.Track("CuratorLive", function(f)
		C.Content(f)
		Kit.Hide(Own(f, "bg"))
		C.Panel(f)
	end)

	-- -----------------------------------------------------------------------------------------
	-- Content windows: their plain buttons only
	-- -----------------------------------------------------------------------------------------

	C.Track("CuratorCertificate", function(f)
		C.Content(f)
		Buttons(f, "close")
	end)
	C.Track("CuratorScratchCard", function(f)
		C.Content(f)
		Buttons(f, "all", "collect")
		if Controls() and Widget(Own(f, "close")) then Kit.Close(Own(f, "close")) end
	end)
	C.Track("CuratorViewer", function(f)
		C.Content(f)
		local bar = Own(f, "bar")
		if Widget(bar) then Buttons(bar, "back", "flip", "whole") end
	end)
	-- The parchments stay; the core's own pass (not the Kit's walk, whose game-ink step turns any
	-- dark words light, the paper's brown ink among them) dresses their X and page arrows, and the
	-- brown ink isn't the game's gold, so the words keep it.
	local PAPER = { noWindow = true, noAuto = true }
	C.Track("CuratorRumor", nil, PAPER)
	C.Track("CuratorRumorBuy", nil, PAPER)

	-- -----------------------------------------------------------------------------------------
	-- The options page in the game's Settings
	-- -----------------------------------------------------------------------------------------

	-- (Made at login. The Game settings window pack dresses addon pages a moment after they open
	-- and leaves their sliders to the addon's pack; dressing the rest here too would do it twice.)
	local SLIDERS = { "scale", "barScale", "popupScale" }
	ns.Watch(KEY, "CuratorOptions", function(f)
		if not C.On() or not Widget(f) then return end
		if Controls() and ns.Slider then
			for _, k in ipairs(SLIDERS) do
				local s = Own(f, k)
				if Kind(s) == "Slider" then ns.Slider(s) end
			end
		end
		if not ns.Enabled("BlizzardSettings") then
			C.OnShow(f)
			if f:IsVisible() then C.Pass(f) end
		end
	end)

	-- -----------------------------------------------------------------------------------------
	-- The Reseller's side tab on the game's merchant window
	-- -----------------------------------------------------------------------------------------

	local BAG
	local function IsResellerTab(t)
		if type(t.SetCustomOnMouseUpHandler) ~= "function" then return false end
		local icon = Own(t, "Icon")
		if not IsTexture(icon) then return false end
		BAG = BAG or ns.FileIDs({ ["Interface\\Icons\\INV_Misc_Bag_10"] = true })
		local ok, file = pcall(icon.GetTexture, icon)
		if not ok then return false end
		if type(file) == "string" then file = string.lower(file) end
		return BAG[file] == true
	end
	-- (The game shows its merchant window from its own secure code, and the tab with it: the tile is
	-- a quiet one, nothing of ours on the tab's showing; its picked look follows Curator's SetChecked
	-- and the mouse.)
	local function ResellerPicked(t)
		local s = Own(t, "SelectedTexture")
		return IsTexture(s) and s:IsShown() == true
	end
	ns.Watch(KEY, function()
		local mf = _G.MerchantFrame
		if not (Widget(mf) and mf:IsShown()) then return nil end
		return FindIn(IsResellerTab, mf:GetChildren())
	end, function(tab)
		if not C.On() or not Controls() then return end
		Kit.Strip(tab)
		if ns.SideTile(tab, { picked = ResellerPicked, copy = true, quiet = true, key = KEY }) then
			C.Hook(tab, "SetChecked", ns.SideTilesPaintSoon, "windows:resellerTab")
		end
	end)

	-- -----------------------------------------------------------------------------------------
	-- The tour: an unnamed overlay on CuratorAlbum (made on the tour's first start), its bubble
	-- and its light
	-- -----------------------------------------------------------------------------------------

	local function IsBubble(b)
		return IsTexture(Own(b, "arrow")) and Widget(Own(b, "next")) and Widget(Own(b, "prev")) and Widget(Own(b, "close"))
	end
	-- The bubble: its shadow and glow rings, dark ground and warm light off (all set once), the
	-- arrow toward what's shown kept; DaylightUI's panel. Its buttons are the pass's.
	local function Bubble(b)
		local arrow, glow = Own(b, "arrow"), Own(b, "arrowGlow")
		for i = 1, select("#", b:GetRegions()) do
			local r = select(i, b:GetRegions())
			if IsTexture(r) and r ~= arrow and r ~= glow then Kit.Hide(r) end
		end
		C.Panel(b)
	end
	C.TrackBy(function()
		local album = _G.CuratorAlbum
		if not (Widget(album) and album:IsShown()) then return nil end
		-- (The overlay holds only the light and the bubble: a cheap test first.)
		return FindIn(function(o)
			return o.GetNumChildren and o:GetNumChildren() <= 3 and FindIn(IsBubble, o:GetChildren()) ~= nil
		end, album:GetChildren())
	end, function(o)
		-- (The light round what's shown breathes from the overlay's own OnUpdate: content.)
		EachIn(function(c)
			if IsBubble(c) then Bubble(c) else C.Content(c) end
		end, o:GetChildren())
	end)
end)
