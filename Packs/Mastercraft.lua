-- Mastercraft: every window it draws (the main window and its pages, the floating windows, its
-- pop-ups and the pieces it adds to the game's windows) in the DaylightUI look.
-- Mastercraft draws all of it with one toolkit of its own (Widgets.lua), in one of four styles. Its
-- Style is kept on Classic while this skin is on: Classic is the flat, square one (one-pixel boxes
-- on its own dark palette), the closest to DaylightUI; its Warcraft style is bronze art throughout.
-- The style it had is recorded and given back when the skin is off. Mastercraft reads its style
-- once, as it loads: the switch is made in that same moment (this plugin loads first), so it holds
-- from the first login. A style picked in its own Settings > Style or setup guide while skinned is
-- kept as the one to give back (and the chat says so at the next login); a Classic it had before
-- is never changed or given back. Whether the skin is on is kept per character (each character
-- picks its own DaylightUI profile, where the skin's switch lives).
-- Classic paints everything from a palette it keeps private (and repaints on every hover, pick and
-- refresh), so this pack follows the paint itself: each box, line, fill, icon and word of
-- Mastercraft's gets a hook on the call that colors it, and its colors are put into DaylightUI's as
-- they're set:
--   * Its blue-gray darks (window, sidebar, panels, hover, the edges of every box) as DaylightUI's
--     neutral darks; its white, muted and dim words in DaylightUI's value, text, label and off
--     inks; its faction accent (red or blue) as the DaylightUI accent (a gradient one runs along
--     fills, marks, lines and the primary buttons, their hover lift kept); its gold emphasis
--     (titles, "here", picks, the picked chip's rim, the watched eye, a tick) in the accent, as
--     DaylightUI pops what a glance needs, and a picked chip's dark gold ground as a faint accent
--     one. The warm plates it draws in every style (the Crafters chips, tabs and tick boxes, the
--     mailbox helper's band and rule) as the neutral darks, its faint warm hover as a white wash.
--     Quality, class, good / warn / bad, the status dots, the info blue and every inline color
--     code stay.
--   * Marks it colors once as they're made (the picked page's bar, a table row's and the fishing
--     window's page mark, the Crafters chips' rim and glow and the profession cells' bars, the
--     specialization cards' frames and step lines) and controls it set before this pack saw them
--     (switches, sliders, bars) are painted again through the same hooks.
-- Dressed here:
--   * The windows: the main window (MastercraftFrame), the compact view, the item tracker, the
--     farming HUD, the fishing bar and catch card, the mini guide, the never-bank list, the alt
--     view, the recipe details, the Trade board, Share my crafts, Map icons, What's New, the setup
--     guide, the error report, the question box (Mastercraft's own; it never uses the game's
--     popups), the Crafters request pop-up, its toasts, the mailbox helper and the bank pop-up: the
--     DaylightUI window shell in place of its box (its own opacity, border and bevel when it has a
--     look of its own), DaylightUI's X, the accent line along the top in the accent. The fishing bar
--     (and the question box while the reload button lies on it) hold the game's secure buttons:
--     their shell goes on out of combat, the secure buttons are never touched.
--   * The main window: the sidebar a shade darker with a faint edge, the picked page's bar and
--     wash in the accent, the reminder strip (its warn edge stays), the language pill and menu.
--   * Every control (all drawn by Mastercraft): text buttons (ghost: DaylightUI's darks and inks;
--     primary: the accent, lighter under the mouse; off: grayed as it does), icon buttons, the
--     sub-tabs (Segmented: the picked one in the accent), switches (on: the accent), sliders,
--     progress bars, search and text boxes (their focus edge the accent), table heads and list rows
--     (hover a neutral wash, the picked row's wash and its edge mark in the accent), scroll thumbs
--     (a light line, kept).
--   * The game's own templates it uses: the "Mastercraft" and "Share my crafts" buttons in the
--     profession window (SharedButtonSmallTemplate / UIPanelButtonTemplate), the auction house's
--     "Scan prices" tab (PanelTabButtonTemplate) and its in-window button: DaylightUI's button and
--     tab looks.
--   * Its recipe card in the profession window and the Nodes button on the world map: colors and
--     font as above (no shell: they sit inside the game's windows).
--   * Text: DaylightUI's font on every word of it (its sizes kept; its own Greek / Korean font
--     where its language needs one). Its sub-tabs are laid out again in that font, and a label
--     wider than its button (or cut short in its box) shrinks to fit.
-- Not here: its map and minimap node pins, the bobber mark and the profession art (its content);
-- 3D models and the character scene; the minimap button (DaylightUI's addon button drawer, or
-- LibDBIcon's); the tooltips (it uses the game's GameTooltip: DaylightUI's) and the lines it adds
-- to item tooltips; its secure fishing buttons (never touched); the hidden scanning tooltip.
-- Fast path: Mastercraft keeps everything in its own namespace. Reachable: the global functions its
-- key bindings call, /mc, its minimap button, its named frames and the methods it puts on them.
-- Those calls are post-hooked and look for its windows at once (dressed before they draw), as is
-- every click on one of its buttons; each window is dressed again on its OnShow, its Refresh and
-- size changes, the main window's pages on their own OnShow and after each refresh (its UpdateWho
-- starts every refresh), the Crafters page after each of its fills (FillList: it moves between
-- its own pages from tiles and events too), its scrolling lists after each Refresh (rows made as
-- they scroll), the question pop-up on each Show (brought up to date while it's up). The
-- dressing these queue runs in the same frame, before it's drawn.
-- Polling (Mastercraft being private, nothing else sees these as they're made): the windows it
-- opens from its own events (fishing bar and catch card, farming HUD, mini guide, compact view,
-- item tracker) are looked for by name each frame until each is made; its four unnamed pop-ups
-- (toast, Crafters request, mailbox helper, bank pop-up) by a look at the screen's child count each
-- frame (one call; a new child is looked at once), which stops once each is found or switched off
-- in its settings (and starts again when its main window closes, where those are switched).
-- Taint: Mastercraft's secure buttons (fishing cast, reload) and every explicitly protected frame
-- are left alone; a window holding secure buttons gets its shell only out of combat; nothing on the
-- game's frames is hooked but HookScript on their OnShow; the auction house and profession window
-- pieces are Mastercraft's own buttons inside them.
local ADDON, ns = ...
if not ns.ok then return end

local L = ns.L
local KEY = "Mastercraft"
-- (Its words are in the game's font, set by its own calls: the player's font goes on all of them.)
local CAPS = { window = true, controls = true, text = true, shadow = true, colors = true, font = "daylight",
	extraTab = "DaylightUI", extra = function() return { ns.HandoverGroup(KEY) } end }
ns.Target(KEY, "Mastercraft", CAPS)

local Usable, Guard = ns.Usable, ns.Guard
local abs, type, pairs, ipairs, pcall = math.abs, type, pairs, ipairs, pcall

local function On() return ns.Enabled(KEY) end
local function Kind(x) return Usable(x) and x:GetObjectType() or nil end

-- Explicitly protected (a secure template, never touched), implicitly (holding secure children:
-- dressed, but its size and shell left to out of combat).
local function Protected(f)
	if not f.IsProtected then return false, false end
	local p, explicit = f:IsProtected()
	if not p then return false, false end
	return explicit and true or false, not explicit
end

-- ---------------------------------------------------------------------------------------------
-- Its style: Classic while the skin is on
-- ---------------------------------------------------------------------------------------------

local function SV()
	local db = _G.DaylightAddonSkinsDB
	if type(db) ~= "table" then
		db = {}
		_G.DaylightAddonSkinsDB = db
	end
	return db
end

local function MSettings()
	local db = _G.MastercraftDB
	return type(db) == "table" and type(db.settings) == "table" and db.settings or nil
end

-- This character ("Name-Realm"), or nil while the game doesn't know the name yet.
local function CharKey()
	local name = _G.UnitName and _G.UnitName("player")
	if type(name) ~= "string" or name == "" or name == (_G.UNKNOWNOBJECT or "Unknown") then return nil end
	return name .. "-" .. tostring(_G.GetRealmName and _G.GetRealmName() or "")
end

-- Whether the skin was on for this character at its last login (nil: not known).
local function SkinWas()
	local t = SV().mastercraftSkin
	if type(t) ~= "table" then return nil end
	local key = CharKey()
	return key and t[key]
end

local function SkinIs(on)
	local db = SV()
	if type(db.mastercraftSkin) ~= "table" then db.mastercraftSkin = {} end
	local key = CharKey()
	if key then db.mastercraftSkin[key] = on end
end

-- Classic on, the style it had kept. A style it shows while the record is there was picked in its
-- settings since (the skin left it on Classic): that's the newest one to give back.
local function KeepClassic(s)
	local theme = s.theme
	if theme == "classic" then return end
	SV().mastercraftStyle = type(theme) == "string" and theme or "wow"
	s.theme = "classic"
end

local function GiveStyleBack(s)
	local db = SV()
	local was = db.mastercraftStyle
	if was == nil then return end
	db.mastercraftStyle = nil
	if s.theme == "classic" then s.theme = was end
end

local STYLE_NAMES = { wow = "WoW", modern = "Modern", midnight = "Midnight", classic = "Classic" }

-- Mastercraft reads its style once, as it loads (its ADDON_LOADED), and needs a reload for another:
-- the style is set in that same event, before Mastercraft reads it. This plugin loads before it
-- (keep Mastercraft out of the toc's OptionalDeps: that would load it first). Whether the skin is
-- on isn't known yet (DaylightUI's settings come at login): what it was at this character's last
-- login, or the last time its switch was flipped, is kept for this.
-- sessionTheme: the style Mastercraft runs this session, as it read it (nil until known). A first
-- install, or the one time Mastercraft switches everyone to its Warcraft style, gets Classic from
-- the next reload.
local sessionTheme
local picked                -- a style picked in Mastercraft while skinned (kept to give back)
local early = CreateFrame("Frame")
early:RegisterEvent("ADDON_LOADED")
early:SetScript("OnEvent", function(self, _, name)
	if name ~= KEY then return end
	self:UnregisterEvent("ADDON_LOADED")
	local s = MSettings()
	if not s then
		sessionTheme = "wow"
		return
	end
	if SkinWas() == false then
		GiveStyleBack(s)
	else
		if s.theme ~= "classic" and SV().mastercraftStyle ~= nil then picked = s.theme end
		KeepClassic(s)
	end
	-- (Its one-time switch to the Warcraft style runs after this, in its own handler.)
	sessionTheme = s.wowStyleV2 == true and s.theme or "wow"
end)

-- (Mastercraft loaded before this pack could see it: the style as it is now is the one it read.)
local function NoteTheme()
	if sessionTheme ~= nil then return end
	local s = MSettings()
	if s then sessionTheme = s.theme or "wow" end
end

local function ClassicNow()
	NoteTheme()
	return sessionTheme == "classic"
end

local function Say(text) print("|cffa335eeAddon Skins|r: " .. text) end

-- At login (the settings known): kept in step with the skin's switch. A change takes hold at the
-- next reload, as every skin's switch does.
ns.me.On("Login", function()
	NoteTheme()
	C_Timer.After(1, function()
		local s = MSettings()
		local on = On()
		SkinIs(on)
		if not s then return end
		if on then
			KeepClassic(s)
			if picked then
				Say(string.format(L["Mastercraft stays on its Classic style while Addon Skins dresses it. The style you picked (%s) comes back when its skin is off."],
					STYLE_NAMES[picked] or tostring(picked)))
			elseif sessionTheme ~= "classic" then
				Say(L["Mastercraft takes the Daylight UI look at your next reload."])
			end
		else
			GiveStyleBack(s)
		end
	end)
end)
ns.me.On("SettingChanged", function(scope, path)
	if scope ~= ADDON or path ~= KEY then return end
	local ok, value = pcall(ns.API.GetSetting, ADDON, KEY)
	if ok then SkinIs(value ~= false) end
end)

-- ---------------------------------------------------------------------------------------------
-- Its palette into DaylightUI's
-- ---------------------------------------------------------------------------------------------

-- Its accent: the faction's (red or blue; it sets it as its main window is built), and the blue it
-- starts with (windows made before that).
local START_ACCENT = { 0.30, 0.65, 1.00 }
local factionAccent
local function FactionAccent()
	if factionAccent then return factionAccent end
	local faction = _G.UnitFactionGroup and _G.UnitFactionGroup("player")
	if faction == "Horde" then
		factionAccent = { 0.92, 0.28, 0.22 }
	elseif faction == "Alliance" then
		factionAccent = { 0.30, 0.60, 1.00 }
	else
		return START_ACCENT
	end
	return factionAccent
end

-- How much lighter or darker than c this is (its primary button's hover is the accent x 1.12), or
-- nil when it isn't c.
local function Like(r, g, b, c)
	local k = (r + g + b) / (c[1] + c[2] + c[3])
	if k < 0.8 or k > 1.3 then return nil end
	if abs(r - c[1] * k) < 0.04 and abs(g - c[2] * k) < 0.04 and abs(b - c[3] * k) < 0.04 then return k end
	return nil
end

local function IsAccent(r, g, b)
	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return nil end
	return Like(r, g, b, FactionAccent()) or Like(r, g, b, START_ACCENT)
end

-- Its gold (C.gold: what it lifts out, "here", the pick, a title), and the lighter gold of a picked
-- crafter status's words and a picked color swatch's edge.
local function IsGold(r, g, b)
	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" or abs(r - 1) >= 0.04 then return false end
	return (abs(g - 0.82) < 0.04 and abs(b - 0.25) < 0.06) or (abs(g - 0.86) < 0.02 and b >= 0.40 and b <= 0.46)
end

-- A picked chip's ground (its gold x 0.3: the Crafters page's profession and filter chips).
local function IsGoldWash(r, g, b)
	return type(r) == "number" and abs(r - 0.30) < 0.02 and abs(g - 0.246) < 0.02 and abs(b - 0.075) < 0.02
end

-- Its faint warm hover and line (the compact view's rows, the farming HUD's and fishing bar's lines).
local function IsWarmWash(r, g, b)
	return type(r) == "number" and abs(r - 1) < 0.02 and abs(g - 0.85) < 0.02 and abs(b - 0.5) < 0.02
end

-- Its warm plates, drawn so in every style: the Crafters page's chips, tabs and tick boxes (ground and
-- edge), the mailbox helper's header band and its rule.
local WARM = { { 0.10, 0.09, 0.07 }, { 0.36, 0.31, 0.22 }, { 0.05, 0.035, 0.025 }, { 0.58, 0.39, 0.12 } }
local function Warm(r, g, b)
	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return false end
	for _, c in ipairs(WARM) do
		if abs(r - c[1]) < 0.006 and abs(g - c[2]) < 0.006 and abs(b - c[3]) < 0.006 then return true end
	end
	return false
end

local function IsWhite(r, g, b)
	return type(r) == "number" and r >= 0.995 and g >= 0.995 and b >= 0.995
end

-- Its neutrals: grays with a faint blue cast (window, panels, edges, hover, its white, muted and
-- dim words; the faintest is its window's, 0.02 bluer than red). A true gray (the poor quality's, a
-- white wash) isn't one of them, nor are DaylightUI's own darks (its background is 0.012 bluer)
-- and the grays this pack puts in their place.
local function Bluish(r, g, b)
	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return false end
	local d = b - r
	return d >= 0.015 and d <= 0.14 and g >= r - 0.005 and g <= b + 0.005
end

-- (DaylightUI's window color: from 1.8.4 the player's Background color pick. StyleChanged relights.)
local function Background()
	local c = ns.BackColor()
	return c[1], c[2], c[3]
end

-- A dark of its as DaylightUI's: its window dark as DaylightUI's background, the rest the same
-- lightness without the blue.
local function Gray(r, g, b)
	local l = (r + g + b) / 3
	if l < 0.07 then return Background() end
	return l, l, l + 0.01
end
local function IsBackDark(r, g, b) return (r + g + b) / 3 < 0.07 end

local function Inks() return ns.Look(KEY, "daylightColors") ~= false end

-- A word of its in DaylightUI's ink of the same weight.
local function InkFor(r, g, b)
	local l = (r + g + b) / 3
	local c = ns.Colors()
	local ink = (l >= 0.85 and c.TEXT) or (l >= 0.5 and c.LABEL) or c.OFF
	if ink then return ink[1], ink[2], ink[3] end
	return r, g, b
end

-- ---------------------------------------------------------------------------------------------
-- The hooks on its paint
-- ---------------------------------------------------------------------------------------------

local busy = false                                  -- this pack's own calls, not its
local ours = setmetatable({}, { __mode = "k" })     -- frames and regions DaylightUI or this pack made
local seen = setmetatable({}, { __mode = "k" })     -- objects hooked
local lit = setmetatable({}, { __mode = "k" })      -- texture or string -> { k = how, a = alpha, o = orientation }
local litBg = setmetatable({}, { __mode = "k" })    -- frame -> { a = its accent ground's alpha, up = lifted }
local litEdge = setmetatable({}, { __mode = "k" })  -- frame -> its accent edge's alpha
local grounds = setmetatable({}, { __mode = "k" })  -- frame -> { fill, lift } (textures of ours)
local darks = setmetatable({}, { __mode = "k" })    -- its pieces put in DaylightUI's window color -> { m = method, a = alpha }
local roots = setmetatable({}, { __mode = "k" })    -- its windows (their box under DaylightUI's shell)
local hosts = setmetatable({}, { __mode = "k" })    -- what a walk is queued for: windows and pieces

local function Call(obj, method, ...)
	busy = true
	pcall(obj[method], obj, ...)
	busy = false
end

-- One of its darks to DaylightUI's: its window dark becomes the window color (kept, to follow the
-- player's Background color when it changes), the others the same lightness without the blue.
local function Dark(obj, method, r, g, b, a)
	local x, y, z = Gray(r, g, b)
	darks[obj] = IsBackDark(r, g, b) and { m = method, a = a } or nil
	Call(obj, method, x, y, z, a)
end

local function Lit(tbl, obj, k, a, o)
	local e = tbl[obj]
	if not e then
		e = {}
		tbl[obj] = e
	end
	e.k, e.a, e.o = k, a, o
end

local function PaintLit(obj, e)
	busy = true
	if e.k == "fill" then
		pcall(ns.FillAccent, obj, e.a, e.o, KEY)
	elseif e.k == "paint" then
		pcall(ns.PaintAccent, obj, e.a, e.o, KEY)
	elseif e.k == "text" then
		local r, g, b = ns.AccentOf(KEY)
		pcall(obj.SetTextColor, obj, r, g, b, e.a)
	end
	busy = false
end

-- A texture of its in the accent from now (a mark it colors once, as it's made).
local function Accent(tex, a, o)
	if Kind(tex) ~= "Texture" or ours[tex] then return end
	Lit(lit, tex, "fill", a, o)
	PaintLit(tex, lit[tex])
end

-- A color texture (fills, lines, bars, washes).
local function OnFill(tex, r, g, b, a)
	if busy or ours[tex] or not On() then return end
	a = a or 1
	if IsAccent(r, g, b) or IsGold(r, g, b) then
		local e = lit[tex]
		Lit(lit, tex, "fill", a, e and e.o)
		PaintLit(tex, lit[tex])
		return
	end
	local was = lit[tex]
	lit[tex] = nil
	darks[tex] = nil
	if Bluish(r, g, b) or Warm(r, g, b) then
		Dark(tex, "SetColorTexture", r, g, b, a)
	elseif IsWarmWash(r, g, b) then
		Call(tex, "SetColorTexture", 1, 1, 1, a)
	end
	-- (A gradient put on before stays under a plain color until the vertex colors are reset.)
	if was then Call(tex, "SetVertexColor", 1, 1, 1, 1) end
end

-- A tinted picture (its icons, the logo, its round pieces).
local function OnTint(tex, r, g, b, a)
	if busy or ours[tex] or not On() then return end
	if IsAccent(r, g, b) or IsGold(r, g, b) then
		Lit(lit, tex, "paint", a or 1)
		PaintLit(tex, lit[tex])
		return
	end
	lit[tex] = nil
	darks[tex] = nil
	if not Bluish(r, g, b) then return end
	if (r + g + b) / 3 >= 0.45 and Inks() then
		local x, y, z = InkFor(r, g, b)
		Call(tex, "SetVertexColor", x, y, z, a)
	else
		Dark(tex, "SetVertexColor", r, g, b, a)
	end
end

-- A word (a string or a text box).
local function OnInk(fs, r, g, b, a)
	if busy or not On() then return end
	local inks = Inks()
	if IsAccent(r, g, b) or (inks and IsGold(r, g, b)) then
		Lit(lit, fs, "text", a or 1)
		PaintLit(fs, lit[fs])
		return
	end
	lit[fs] = nil
	if not inks then return end
	if Bluish(r, g, b) then
		local x, y, z = InkFor(r, g, b)
		Call(fs, "SetTextColor", x, y, z, a)
	elseif IsWhite(r, g, b) then
		-- (White under the mouse, a primary button's words: DaylightUI's value ink.)
		local v = ns.Colors().VALUE
		if v then Call(fs, "SetTextColor", v[1], v[2], v[3], a) end
	end
end

-- A box's ground in the accent: textures of ours inside its edge (the gradient can't go on a
-- backdrop), its own ground cleared; lifted with a soft white wash under the mouse (its primary
-- button's hover is the accent made lighter).
local function Ground(f, a, up)
	local g = grounds[f]
	if not g then
		local fill = f:CreateTexture(nil, "BACKGROUND", nil, -7)
		fill:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
		fill:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
		local lift = f:CreateTexture(nil, "BACKGROUND", nil, -6)
		lift:SetAllPoints(fill)
		lift:SetColorTexture(1, 1, 1, 0.12)
		ours[fill], ours[lift] = true, true
		g = { fill = fill, lift = lift }
		grounds[f] = g
	end
	busy = true
	pcall(ns.FillAccent, g.fill, a, nil, KEY)
	busy = false
	g.fill:Show()
	g.lift:SetShown(up == true)
end

local function NoGround(f)
	local g = grounds[f]
	if not g then return end
	g.fill:Hide()
	g.lift:Hide()
end

local function OnBack(f, r, g, b, a)
	if busy or not On() then return end
	if roots[f] then
		Call(f, "SetBackdropColor", 0, 0, 0, 0)
		return
	end
	a = a or 1
	local k = IsAccent(r, g, b)
	if k then
		local up = k > 1.06
		litBg[f] = { a = a, up = up }
		Ground(f, a, up)
		Call(f, "SetBackdropColor", 0, 0, 0, 0)
		return
	end
	if IsGoldWash(r, g, b) then
		-- (A picked chip: a faint accent ground on DaylightUI's dark.)
		litBg[f] = { a = a * 0.3, up = false }
		Ground(f, a * 0.3, false)
		local x, y, z = Background()
		darks[f] = { m = "SetBackdropColor", a = a }
		Call(f, "SetBackdropColor", x, y, z, a)
		return
	end
	litBg[f] = nil
	darks[f] = nil
	NoGround(f)
	if Bluish(r, g, b) or Warm(r, g, b) then
		Dark(f, "SetBackdropColor", r, g, b, a)
	end
end

local function OnEdge(f, r, g, b, a)
	if busy or not On() then return end
	if roots[f] then
		Call(f, "SetBackdropBorderColor", 0, 0, 0, 0)
		return
	end
	a = a or 1
	if IsAccent(r, g, b) or IsGold(r, g, b) then
		litEdge[f] = a
		local x, y, z = ns.AccentOf(KEY)
		Call(f, "SetBackdropBorderColor", x, y, z, a)
		return
	end
	litEdge[f] = nil
	if Bluish(r, g, b) or Warm(r, g, b) then
		local x, y, z = Gray(r, g, b)
		Call(f, "SetBackdropBorderColor", x, y, z, a)
	end
end

-- The accent again everywhere it was put, after DaylightUI's accent or this page's changed.
local function Relight()
	if not On() then return end
	for obj, e in pairs(lit) do
		if Usable(obj) then PaintLit(obj, e) end
	end
	for f, e in pairs(litBg) do
		if Usable(f) then Ground(f, e.a, e.up) end
	end
	for f, a in pairs(litEdge) do
		if Usable(f) then
			local x, y, z = ns.AccentOf(KEY)
			Call(f, "SetBackdropBorderColor", x, y, z, a)
		end
	end
	-- (DaylightUI's window color, after the player's Background color changed.)
	local x, y, z = Background()
	for obj, e in pairs(darks) do
		if Usable(obj) then Call(obj, e.m, x, y, z, e.a) end
	end
end
local function RelightSoon()
	ns.Queue("Mastercraft:relight", Relight, KEY)
end
ns.me.On("StyleChanged", RelightSoon)
ns.me.On("SettingChanged", function(scope) if scope == ADDON then RelightSoon() end end)

-- Hooked once; its color now put through the same.
local function HookText(fs)
	hooksecurefunc(fs, "SetTextColor", OnInk)
	local r, g, b, a = fs:GetTextColor()
	OnInk(fs, r, g, b, a)
end

local function HookTexture(tex)
	hooksecurefunc(tex, "SetColorTexture", OnFill)
	hooksecurefunc(tex, "SetVertexColor", OnTint)
	-- (One already in the accent keeps it: its gradient would read back as a color of its.)
	if lit[tex] then return end
	local r, g, b, a = tex:GetVertexColor()
	if r and not (r == 1 and g == 1 and b == 1) then OnTint(tex, r, g, b, a) end
	-- (A scroll thumb keeps its color in mcColor: set again, through the hook.)
	local c = tex.mcColor
	if type(c) == "table" and type(c[1]) == "number" then OnFill(tex, c[1], c[2], c[3], c[4]) end
end

-- A backdrop's own pieces are painted through its frame's two calls (below): left out of the
-- texture hooks.
local PIECES = { "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge",
	"BottomEdge", "LeftEdge", "RightEdge", "Center" }
local backed = setmetatable({}, { __mode = "k" })
local function HookBackdrop(f)
	if backed[f] then return end
	backed[f] = true
	for _, k in ipairs(PIECES) do
		local piece = f[k]
		if Kind(piece) == "Texture" then
			ours[piece] = true
			lit[piece] = nil
		end
	end
	hooksecurefunc(f, "SetBackdropColor", OnBack)
	hooksecurefunc(f, "SetBackdropBorderColor", OnEdge)
	local ok, r, g, b, a = pcall(f.GetBackdropColor, f)
	if ok and r then OnBack(f, r, g, b, a) end
	local ok2, r2, g2, b2, a2 = pcall(f.GetBackdropBorderColor, f)
	if ok2 and r2 then OnEdge(f, r2, g2, b2, a2) end
end

-- ---------------------------------------------------------------------------------------------
-- Words that fit
-- ---------------------------------------------------------------------------------------------

-- A label wider than its button (fs.mcFitTo: the button Mastercraft sizes it for, keeping 10 px),
-- or a line cut short in its box: a size smaller at a time until it fits (a button's label down to
-- 8, a line by 2 at most). DaylightUI's font is wider than the game's.
local function Shrink(fs)
	local box = type(fs.mcFitTo) == "table" and Usable(fs.mcFitTo) and fs.mcFitTo or nil
	local ok, path, size, flags = pcall(fs.GetFont, fs)
	if not ok or not path or type(size) ~= "number" then return end
	local room = box and box:GetWidth() - 10
	if box and (not room or room <= 2) then return end
	local function wide()
		if box then
			local w = fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth()
			return w > room
		end
		return fs.IsTruncated and fs:IsTruncated() == true
	end
	if not wide() then return end
	local least = box and 8 or math.max(8, math.floor(size + 0.5) - 2)
	local s = math.floor(size + 0.5)
	while s > least and wide() do
		s = s - 1
		fs:SetFont(path, s, flags)
	end
end

-- ---------------------------------------------------------------------------------------------
-- The walk
-- ---------------------------------------------------------------------------------------------

local Kit

-- The regions and children DaylightUI adds to f in fn(): this pack's walks leave them alone.
local function Before(f)
	local list = {}
	if f.GetRegions then for _, r in ipairs({ f:GetRegions() }) do list[r] = true end end
	if f.GetChildren then for _, c in ipairs({ f:GetChildren() }) do list[c] = true end end
	return list
end
local function Mark(f, fn)
	local before = Before(f)
	Guard(fn)
	if f.GetRegions then
		for _, r in ipairs({ f:GetRegions() }) do if not before[r] then ours[r] = true end end
	end
	if f.GetChildren then
		for _, c in ipairs({ f:GetChildren() }) do if not before[c] then ours[c] = true end end
	end
end

local CLOSE_IDS
local function IsClose(b)
	if Kind(b) ~= "Button" or Kind(b.icon) ~= "Texture" then return false end
	if not CLOSE_IDS then CLOSE_IDS = ns.FileIDs({ ["Interface\\AddOns\\Mastercraft\\media\\close"] = true }) end
	local ok, file = pcall(b.icon.GetTexture, b.icon)
	if not ok or file == nil then return false end
	if type(file) == "string" then file = string.lower(file) end
	return CLOSE_IDS[file] == true
end

-- A game template button of its (UIPanelButtonTemplate, SharedButtonSmallTemplate).
local function IsTemplateButton(b)
	return Kind(b.Left) == "Texture" and Kind(b.Right) == "Texture" and (Kind(b.Middle) == "Texture" or Kind(b.Center) == "Texture")
end

-- A click on any of its buttons may build or open something: its window is looked over again, and
-- its windows are looked for.
local Queue, Names
local function Clicked(self)
	Queue(self)
	if Names then Names() end
end

local pages = setmetatable({}, { __mode = "k" })   -- the main window's page containers

local SKIP = { Model = true, PlayerModel = true, DressUpModel = true, ModelScene = true, Cooldown = true,
	GameTooltip = true, SimpleHTML = true, MessageFrame = true, ScrollingMessageFrame = true, Minimap = true,
	ColorSelect = true }

local textOn = false
local fontMoved = false   -- a walk put a string in another face or size (a page sized to its words refits)

local function Regions(list)
	for _, r in ipairs(list) do
		if not ours[r] and Usable(r) then
			local kind = r:GetObjectType()
			if kind == "FontString" then
				if not seen[r] then
					seen[r] = true
					HookText(r)
				end
				if textOn then
					local _, path, size = pcall(r.GetFont, r)
					ns.FollowFont(r, KEY)
					local _, path2, size2 = pcall(r.GetFont, r)
					if path2 ~= path or size2 ~= size then fontMoved = true end
					Shrink(r)
				end
			elseif kind == "Texture" and not seen[r] then
				seen[r] = true
				HookTexture(r)
			end
		end
	end
end

local function HasBackdrop(f)
	return f.SetBackdropColor ~= nil and f.GetBackdrop ~= nil and f:GetBackdrop() ~= nil
end

-- The first look at a frame, before its parts: its controls of the game's templates, its close X.
local function First(f, kind)
	if kind == "EditBox" then HookText(f) end
	if kind == "Button" then
		if IsTemplateButton(f) then
			if ns.Controls(KEY) and Kit then
				Kit.Button(f)
				ours[f] = true
			end
			return
		end
		if IsClose(f) and roots[f:GetParent()] and ns.Controls(KEY) and Kit then
			Mark(f, function() Kit.Close(f) end)
			ours[f] = true
			return
		end
		f:HookScript("OnClick", Clicked)
	end
end

local function Regs(f) return f.GetRegions and { f:GetRegions() } or {} end

-- After its parts are hooked: what it colored before this pack saw it, through the hooks.
local function After(f)
	-- Its own paint (rows, tabs, buttons, nav).
	if type(f.Paint) == "function" then pcall(f.Paint, f) end
	-- A switch's track (ns.Switch: on in the accent), a slider's fill (ns.Slider).
	if type(f.SetOn) == "function" and f.trackFill ~= nil and f.on ~= nil then pcall(f.SetOn, f, f.on) end
	if type(f.SetValue) == "function" and Kind(f.knob) == "Texture" and Kind(f.fill) == "Texture"
		and type(f.value) == "number" then
		pcall(f.SetValue, f, f.value)
	end
	-- A progress bar (ns.Bar) already filled: its usual accent until its next SetProgress (its
	-- good and warn colors come with that, through the hook).
	if type(f.SetProgress) == "function" and Kind(f.fill) == "Texture" and Kind(f.extra) == "Texture"
		and f.fill:IsShown() and not lit[f.fill] then
		Accent(f.fill, 1)
	end
	-- Marks it colors once, as they're made.
	if type(f.Stripe) == "function" then Accent(f.mark, 0.95, "VERTICAL") end   -- a table row's pick
	if type(f.tab) == "table" then Accent(f.bar, 1, "VERTICAL") end             -- the main window's page bar
	if type(f.page) == "table" then Accent(f.mark, 1, "VERTICAL") end           -- the fishing window's page
	if Kind(f.bar) == "Texture" and Kind(f.track) == "Texture" then Accent(f.bar, 0.9) end   -- a profession cell
	local sel = f.sel
	if Usable(sel) and Kind(sel.glow) == "Texture" then
		-- A Crafters chip's pick: its gold glow and its four 1 px rim lines.
		Accent(sel.glow, 0.10)
		for _, r in ipairs(Regs(sel)) do
			if r ~= sel.glow then Accent(r, 0.9) end
		end
	end
	if f.spell ~= nil and backed[f] then
		-- A specialization card: the frame behind its icon (44 px) and the line joining its steps.
		for _, r in ipairs(Regs(f)) do
			if Kind(r) == "Texture" and not ours[r] then
				local layer = r:GetDrawLayer()
				local w, h = r:GetSize()
				if layer == "ARTWORK" and w and abs(w - 44) < 1 and abs(h - 44) < 1 then
					Accent(r, 0.6)
				elseif layer == "BORDER" and w and abs(w - 2) < 0.5 then
					Accent(r, 0.35, "VERTICAL")
				end
			end
		end
	end
	-- A scrolling list makes rows as it scrolls (ns.VarList, ns.ScrollList): looked over after each.
	if type(f.Refresh) == "function" and (type(f.kinds) == "table" or type(f.rows) == "table") then
		hooksecurefunc(f, "Refresh", function(self) Queue(self) end)
	end
	-- Its sub-tabs (ns.Segmented) laid out again in DaylightUI's font.
	if textOn and type(f.Layout) == "function" and type(f.buttons) == "table" and type(f.NeededWidth) == "function" then
		pcall(f.Layout, f)
	end
end

local Walk
local function Children(list, depth)
	for _, c in ipairs(list) do Walk(c, depth + 1) end
end

Walk = function(f, depth)
	if depth > 14 or ours[f] or not Usable(f) then return end
	-- (A secure button of its: never touched. A frame holding one is walked.)
	if (Protected(f)) then return end
	local kind = f:GetObjectType()
	if SKIP[kind] then return end
	-- (A page not shown is walked again by its own OnShow.)
	if pages[f] and seen[f] and not f:IsShown() then return end
	-- (Its box can come after the frame: ns.Style sets it on every paint.)
	if not backed[f] and HasBackdrop(f) then HookBackdrop(f) end
	local first = not seen[f]
	if first then
		seen[f] = true
		First(f, kind)
		if ours[f] then return end
	end
	if kind == "EditBox" and textOn then ns.FollowFont(f, KEY) end
	if f.GetRegions then Regions({ f:GetRegions() }) end
	if f.GetChildren then Children({ f:GetChildren() }, depth) end
	if first then After(f) end
end

local function Dress(f)
	if not Usable(f) or not On() then return end
	textOn = not ns.PlainText(KEY)
	Walk(f, 0)
end

-- Queued walks and calls: run in the same frame, before it's drawn (an OnUpdate runs after the
-- clicks and events of its frame), at most once a frame for each window.
local queued, soon = {}, {}
local runner = CreateFrame("Frame")
runner:Hide()
runner:SetScript("OnUpdate", function(self)
	self:Hide()
	local calls = soon
	soon = {}
	for _, fn in ipairs(calls) do Guard(fn) end
	local list = queued
	queued = {}
	for f in pairs(list) do
		if Usable(f) and f:IsVisible() then Guard(Dress, f) end
	end
end)

local function Soon(fn)
	soon[#soon + 1] = fn
	runner:Show()
end

Queue = function(obj)
	local f = obj
	for _ = 1, 20 do
		if not Usable(f) then return end
		if hosts[f] then break end
		f = f:GetParent()
	end
	if not hosts[f] then return end
	queued[f] = true
	runner:Show()
end

-- ---------------------------------------------------------------------------------------------
-- Windows and pieces
-- ---------------------------------------------------------------------------------------------

-- Its accent line along a window's top (ns.TopAccent: 2 px, OVERLAY) and the main window's.
local function TopLine(f)
	for _, r in ipairs(Regs(f)) do
		if Kind(r) == "Texture" and not ours[r] and r:GetDrawLayer() == "OVERLAY" and r:GetNumPoints() >= 2 then
			local h = r:GetHeight()
			local point, _, _, _, y = r:GetPoint(1)
			if h and h > 1 and h < 3 and point == "TOPLEFT" and y and abs(y + 1) < 0.5 then
				if not seen[r] then
					seen[r] = true
					HookTexture(r)
				end
				Accent(r, 1)
			end
		end
	end
end

-- The main window's sidebar ground and its edge (set once, as it's built).
local function Sidebar(f)
	for _, r in ipairs(Regs(f)) do
		if Kind(r) == "Texture" and not ours[r] then
			local layer, sub = r:GetDrawLayer()
			if layer == "BACKGROUND" and sub == 1 then
				busy = true
				r:SetColorTexture(0, 0, 0, 0.22)
				busy = false
			elseif layer == "BORDER" and (r:GetWidth() or 0) <= 1.5 then
				busy = true
				r:SetColorTexture(1, 1, 1, 0.06)
				busy = false
			end
		end
	end
end

local Poll   -- (below: starts the look at the screen's child count again)

local function Host(f)
	if hosts[f] then return false end
	hosts[f] = true
	f:HookScript("OnShow", function(self)
		if not On() then return end
		Guard(Dress, self)
		Queue(self)
	end)
	f:HookScript("OnSizeChanged", function(self) if self:IsVisible() then Queue(self) end end)
	return true
end

-- A page that lays itself out from its own calls (the Crafters page: its hub, its lists, a crafter's
-- page and Requests, opened from its tiles and lists as well as its buttons, with rows, chips and
-- tabs made as they're needed and sized to their words): dressed as each fill ends, and laid out
-- and filled once more when that put a word in DaylightUI's font (its sizes then fit the new words).
local paged = setmetatable({}, { __mode = "k" })
local refitting = false
local function PageHooks(c)
	if paged[c] or type(c.FillList) ~= "function" or type(c.Layout) ~= "function" then return end
	paged[c] = true
	hooksecurefunc(c, "FillList", function(self)
		if refitting or not On() or not self:IsVisible() then return end
		fontMoved = false
		Guard(Dress, self)
		if not fontMoved then return end
		refitting = true
		pcall(self.Layout, self)
		pcall(self.FillList, self)
		refitting = false
		Guard(Dress, self)
	end)
end

-- One of its windows: DaylightUI's shell for its box, the X, the accent line. A window drawn in
-- its Warcraft style (mcWindow: its bronze frame) is left as it is.
local waiting = setmetatable({}, { __mode = "k" })
local function Window(f)
	if roots[f] or not Usable(f) or not On() or f.mcWindow ~= nil then return end
	local explicit, implicit = Protected(f)
	if explicit or not ClassicNow() then return end
	if implicit and InCombatLockdown() then
		-- (It holds the game's secure buttons: its shell and size are set after the fight.)
		if not waiting[f] then
			waiting[f] = true
			ns.OutOfCombat(function() waiting[f] = nil Window(f) end)
		end
		return
	end
	roots[f] = true
	Mark(f, function() ns.Shell(f, { window = true }, KEY) end)
	if backed[f] then
		Call(f, "SetBackdropColor", 0, 0, 0, 0)
		Call(f, "SetBackdropBorderColor", 0, 0, 0, 0)
	else
		HookBackdrop(f)
	end
	TopLine(f)
	local main = f == _G.MastercraftFrame
	if main then
		Sidebar(f)
		-- (UpdateWho: the start of every refresh of its page.)
		if type(f.UpdateWho) == "function" then hooksecurefunc(f, "UpdateWho", function(self) Queue(self) end) end
		-- Each page is built the first time it's shown, in a container of its own (the one open now
		-- was built before this saw it).
		for _, c in ipairs({ f:GetChildren() }) do
			if Kind(c) == "Frame" and not ours[c] and not HasBackdrop(c) then
				pages[c] = true
				PageHooks(c)
				c:HookScript("OnShow", function(self)
					if not On() then return end
					PageHooks(self)
					Guard(Dress, self)
					Queue(self)
				end)
			end
		end
		-- (Its pop-ups are switched on and off in it: looked for again once it closes.)
		f:HookScript("OnHide", function() if Poll then Poll() end end)
	elseif type(f.Refresh) == "function" then
		hooksecurefunc(f, "Refresh", function(self) Queue(self) end)
	end
	Host(f)
	Dress(f)
	-- Its own refresh once, now through the hooks: what it filled before this pack saw it (its bars).
	if not main and type(f.Refresh) == "function" and f:IsShown() then pcall(f.Refresh, f) end
end

-- A piece of its inside a game window (no shell): the recipe card, the Nodes button, a button.
local function Piece(f)
	if not Usable(f) or not On() or hosts[f] or f.mcWindow ~= nil or (Protected(f)) then return end
	if not ClassicNow() then return end
	Host(f)
	Dress(f)
end

-- ---------------------------------------------------------------------------------------------
-- Finding them
-- ---------------------------------------------------------------------------------------------

-- Its named windows. Those it opens from its own events are also looked for by name each frame
-- until made (Setup); the rest open from a click on one of its buttons, /mc or its key bindings.
local NAMED = { "MastercraftFrame", "MastercraftCompact", "MastercraftGoals", "MastercraftFarmHUD",
	"MastercraftFishBar", "MastercraftFishRecap", "MastercraftMiniGuide", "MastercraftNeverBank",
	"MastercraftAltView", "MastercraftDetails", "MastercraftTradeBoard", "MastercraftConfirm",
	"MastercraftShareCrafts", "MastercraftNodeIcons", "MastercraftErrorReport" }
local BY_EVENT = { "MastercraftCompact", "MastercraftGoals", "MastercraftFarmHUD", "MastercraftFishBar",
	"MastercraftFishRecap", "MastercraftMiniGuide" }
-- (What's New and the setup guide are made once per language, named after it.)
local FAMILIES = { "MastercraftSetup", "MastercraftWhatsNew" }
local LANGS = { "", "_de", "_el", "_es", "_fr", "_ko", "_pl", "_pt", "_ru" }

Names = function()
	if not On() then return end
	for _, name in ipairs(NAMED) do
		local f = _G[name]
		if f and not roots[f] then Guard(Window, f) end
	end
	for _, base in ipairs(FAMILIES) do
		for _, lang in ipairs(LANGS) do
			local f = _G[base .. lang]
			if f and not roots[f] then Guard(Window, f) end
		end
	end
end

-- A frame of Mastercraft's: one of its strings in it (ns.Text marks each with mcSetText).
local function HasItsWords(f, depth)
	for _, r in ipairs(Regs(f)) do
		if Kind(r) == "FontString" and r.mcSetText ~= nil then return true end
	end
	if depth < 2 and f.GetChildren then
		for _, c in ipairs({ f:GetChildren() }) do
			if Usable(c) and HasItsWords(c, depth + 1) then return true end
		end
	end
	return false
end

-- Its four unnamed pop-ups, each made once: what each is known by, and the setting of its that
-- switches it off (then it's never made).
local singles = { toast = false, prompt = false, mail = false, bank = false }
local SINGLE_OFF = { toast = "toasts", prompt = "network", mail = "mailAlts", bank = "bankPopup" }
local function SingleOf(f)
	if type(f.Fit) == "function" and Kind(f.icon) == "Texture" and Kind(f.title) == "FontString" then return "toast" end
	-- (The prompt's copy box is made only for a pop-up with a link: its buttons and Close tell it.)
	if type(f.btns) == "table" and type(f.Close) == "function" and Kind(f.title) == "FontString" then return "prompt" end
	if type(f.buttons) == "table" and Kind(f.header) == "Texture" and Kind(f.rule) == "Texture" then return "mail" end
	if f.deposit ~= nil and f.depositKept ~= nil and f.filter ~= nil then return "bank" end
	return nil
end

local function AllFound()
	local s = MSettings()
	for k, found in pairs(singles) do
		if not found and not (s and s[SINGLE_OFF[k]] == false) then return false end
	end
	return true
end

-- An unnamed window of its: one of its boxes with its words in it.
local function Unnamed(f)
	if not Usable(f) or roots[f] or ours[f] or f:GetObjectType() ~= "Frame" then return false end
	local name = f:GetName()
	if type(name) == "string" and name:sub(1, 11) == "Mastercraft" then return false end
	if (Protected(f)) or not HasBackdrop(f) then return false end
	return HasItsWords(f, 0)
end

local looked = setmetatable({}, { __mode = "k" })
local function Among(list)
	for _, f in ipairs(list) do
		if not looked[f] then
			looked[f] = true
			if Unnamed(f) then
				local single = SingleOf(f)
				if single then singles[single] = true end
				Guard(Window, f)
				-- (A pop-up brought up to date while it's up, with new buttons and words, shows again:
				-- looked over each time.)
				if single == "prompt" then hooksecurefunc(f, "Show", function(self) Queue(self) end) end
			end
		end
	end
end

local watcher = CreateFrame("Frame")
watcher:Hide()
local lastCount = -1
local function LookNow()
	if not On() then return end
	local n = UIParent:GetNumChildren()
	if n ~= lastCount then
		lastCount = n
		Among({ UIParent:GetChildren() })
		Names()
	end
	if AllFound() then watcher:Hide() end
end
watcher:SetScript("OnUpdate", function() Guard(LookNow) end)

Poll = function()
	if On() and not AllFound() then watcher:Show() end
end

-- From a call that opens its windows: every one there is now, at once.
local function OpenNow()
	if not On() then return end
	lastCount = -1
	LookNow()
	Names()
	ns.WatchNow()
end

-- The auction house's Scan prices tab and its in-window button (isMastercraft on both).
local function Auction()
	if not On() or not Kit or not ns.Controls(KEY) or not ClassicNow() then return end
	local function dress(b)
		if not Usable(b) or not b.isMastercraft or ours[b] then return end
		ours[b] = true
		if b.isTab then
			Kit.Tab(b, function() return false end)
		else
			Kit.Button(b)
		end
	end
	local ah = _G.AuctionHouseFrame or _G.AuctionFrame
	if Usable(ah) then
		for _, c in ipairs({ ah:GetChildren() }) do dress(c) end
	end
	-- (With the Controller UI it sits in a holder of its own, over the auction house.)
	for _, c in ipairs({ UIParent:GetChildren() }) do
		if Kind(c) == "Frame" and c:GetNumChildren() == 1 then dress((c:GetChildren())) end
	end
end

-- The bank pop-up: in the game's bank window, Baganator's (when one is open) or on the screen.
local function Bank()
	local holders = { _G.BankFrame }
	local B = _G.Baganator
	local api = type(B) == "table" and type(B.API) == "table" and B.API.Skins
	if type(api) == "table" and type(api.GetCurrentSkin) == "function" then
		local ok, skin = pcall(api.GetCurrentSkin)
		if ok and type(skin) == "string" then
			for _, view in ipairs({ "Single", "Category" }) do
				holders[#holders + 1] = _G["Baganator_" .. view .. "ViewBankViewFrame" .. skin]
			end
		end
	end
	for _, h in ipairs(holders) do
		if Usable(h) then
			for _, c in ipairs({ h:GetChildren() }) do
				if not roots[c] and SingleOf(c) == "bank" and Usable(c) and HasBackdrop(c) then
					singles.bank = true
					Guard(Window, c)
				end
			end
		end
	end
	OpenNow()
end

-- The Nodes button on the world map (its own Button, made by its button maker); its right-click
-- opens Map icons.
local function MapButton()
	local map = _G.WorldMapFrame
	local sc = Usable(map) and (map.ScrollContainer or map)
	if not Usable(sc) then return end
	for _, c in ipairs({ sc:GetChildren() }) do
		if Kind(c) == "Button" and not hosts[c] and type(c.style) == "string" and Kind(c.label) == "FontString"
			and c.label.mcSetText ~= nil then
			Piece(c)
			ns.ScriptOnce(c, "OnMouseUp", function() Guard(Names) end, KEY)
		end
	end
end

local mapHooked = false
local function HookMap()
	local map = _G.WorldMapFrame
	if mapHooked or not Usable(map) then return end
	mapHooked = true
	map:HookScript("OnShow", function() if On() then Guard(MapButton) end end)
	if map:IsShown() then Guard(MapButton) end
end

local function Profession()
	local b = _G.MastercraftProfessionButton
	if Usable(b) and not ours[b] and Kit and ns.Controls(KEY) and ClassicNow() then
		ours[b] = true
		Kit.Button(b)
	end
	local card = _G.MastercraftRecipePanel
	if Usable(card) then Piece(card) end
end

-- Looking For Crafter (2.0.5), in the game's own Group Finder window: only seen when you use the
-- game's window over DaylightUI's (DaylightUI's Window Skins then dress that window). Its banner
-- under Custom is made from the game's category banner template, dressed as DaylightUI dresses the
-- game's own banners there (the cover off, the row outline, its art kept), "BY MASTERCRAFT" in the
-- label ink. Its panel over the page is made in the game's look (not Mastercraft's paint): its dark
-- dialog tile and page art off (DaylightUI erases the game's page art there too), its black ground
-- kept (it hides the game's list under it); the game's buttons and boxes in it DaylightUI's, the
-- open tab and your crafter status (lit by LockHighlight, whose art is gone) marked by an accent
-- line, its rows' gold quest-log highlight a soft wash, its gold headings in the label and value
-- inks. Both are made once, as the Group Finder loads.
local GAME_GOLD = { GameFontNormal = "LABEL", GameFontNormalLarge = "VALUE" }
local function GoldInk(fs)
	if Kind(fs) ~= "FontString" or not Inks() then return end
	local r, g, b = fs:GetTextColor()
	if type(r) ~= "number" then return end
	local role
	if abs(r - 1) < 0.03 and abs(g - 0.82) < 0.03 and b < 0.05 then
		role = "LABEL"
		local obj = fs:GetFontObject()
		local name = obj and obj.GetName and obj:GetName()
		if type(name) == "string" then
			for base, inkRole in pairs(GAME_GOLD) do
				if name == base or name:find("^MastercraftShopFont" .. base .. "%a*$") then role = inkRole end
			end
		end
	elseif abs(r - 0.78) < 0.02 and abs(g - 0.66) < 0.02 and abs(b - 0.42) < 0.02 then
		role = "LABEL"   -- (the banner's muted gold "BY MASTERCRAFT")
	end
	local c = role and ns.Colors()[role]
	if c then fs:SetTextColor(c[1], c[2], c[3]) end
end

local function GoldInks(f, depth)
	for _, r in ipairs({ f:GetRegions() }) do GoldInk(r) end
	if depth < 4 then
		-- (Not into its buttons and boxes: their words are DaylightUI's controls' own.)
		for _, c in ipairs({ f:GetChildren() }) do
			local kind = Kind(c)
			if kind == "Frame" then GoldInks(c, depth + 1) end
		end
	end
end

local function LitMark(b)
	if not Usable(b) or ours[b] then return end
	ours[b] = true
	local line = b:CreateTexture(nil, "OVERLAY")
	line:SetColorTexture(1, 1, 1, 1)
	line:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 3, 1)
	line:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 1)
	line:SetHeight(2)
	line:Hide()
	ns.HookOnce(b, "LockHighlight", function()
		if not On() then return end
		ns.PaintAccent(line, 1, nil, KEY)
		line:Show()
	end, KEY)
	ns.HookOnce(b, "UnlockHighlight", function() line:Hide() end, KEY)
end

local function SoftRows(list)
	if type(list) ~= "table" or type(list.rows) ~= "table" then return end
	for _, r in ipairs(list.rows) do
		if Usable(r) and not ours[r] then
			ours[r] = true
			local hl = r.GetHighlightTexture and r:GetHighlightTexture()
			if hl then Kit.Hide(hl) end
			if Kit.HoverWash then Kit.HoverWash(r, r) end
		end
	end
end

local function LFG()
	if not On() or not Kit or not ns.Controls(KEY) then return end
	local banner = _G.MastercraftLFGBanner
	if Usable(banner) and not ours[banner] then
		ours[banner] = true
		Kit.Hide(banner.Cover)
		local keep = {}
		if Kind(banner.Icon) == "Texture" then keep[banner.Icon] = true end
		Kit.Row(banner, keep)
		Kit.Font(banner.Label)
		GoldInks(banner, 0)
	end
	local p = _G.MastercraftLFGPanel
	if not Usable(p) or roots[p] or ours[p] then return end
	ours[p] = true
	ns.Kill(p.bg)
	ns.Kill(p.art)
	for _, b in ipairs(p.tabs or {}) do LitMark(b) end
	for _, b in ipairs(type(p.prof) == "table" and p.prof.st or {}) do LitMark(b) end
	SoftRows(type(p.shop) == "table" and p.shop.list)
	SoftRows(p.list)
	ns.DressOnShow(p, nil, function(f) GoldInks(f, 0) end, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- Wiring
-- ---------------------------------------------------------------------------------------------

local function HookGlobal(name)
	ns.HookOnce(nil, name, function() Guard(OpenNow) end, KEY)
end

local function Setup(K)
	Kit = K
	-- The calls that open its windows (its key bindings, /mc, the minimap button).
	for _, name in ipairs({ "Mastercraft_Toggle", "Mastercraft_ToggleTracker", "Mastercraft_ToggleCrafters" }) do
		HookGlobal(name)
	end
	if type(SlashCmdList) == "table" and type(SlashCmdList.MASTERCRAFT) == "function" then
		ns.HookOnce(SlashCmdList, "MASTERCRAFT", function() Guard(OpenNow) end, KEY)
	end
	-- (Made at login, maybe after this runs.)
	C_Timer.After(1, function()
		local mb = _G.MastercraftMinimapButton
		ns.ScriptOnce(mb, "OnClick", function() Guard(OpenNow) end, KEY)
	end)

	-- Windows made from its own events: by name until made, and its pop-ups by the screen's count.
	for _, name in ipairs(BY_EVENT) do ns.Watch(KEY, name, function(f) Window(f) end) end
	Poll()
	OpenNow()

	-- Its pieces in the game's windows, dressed in the frame they show (and once more as it moves
	-- or adds them).
	local events = CreateFrame("Frame")
	for _, e in ipairs({ "AUCTION_HOUSE_SHOW", "BANKFRAME_OPENED", "TRADE_SKILL_SHOW", "MAIL_SHOW", "ADDON_LOADED" }) do
		pcall(events.RegisterEvent, events, e)
	end
	events:SetScript("OnEvent", function(_, event, name)
		if event == "ADDON_LOADED" then
			if name == "Blizzard_WorldMap" then HookMap() end
			-- (Its Looking For Crafter banner and panel are made as the Group Finder loads, by its
			-- own handler of this event, which runs before this one.)
			if name == "Blizzard_GroupFinder_VanillaStyle" then Guard(LFG) end
			return
		end
		if not On() then return end
		if event == "AUCTION_HOUSE_SHOW" then
			-- (It places its tab as the window opens and again 0.5 and 2 seconds later.)
			Guard(Auction)
			Soon(Auction)
			for _, t in ipairs({ 0.6, 2.1 }) do C_Timer.After(t, function() Guard(Auction) end) end
		elseif event == "BANKFRAME_OPENED" then
			Soon(Bank)
			C_Timer.After(0.3, function() Guard(Bank) end)
		elseif event == "TRADE_SKILL_SHOW" then
			Soon(Profession)
			C_Timer.After(0.5, function() Guard(Profession) end)
		else
			Soon(OpenNow)
		end
	end)
	HookMap()
	-- (Both made on a recipe's first pick: looked for by name until then.)
	ns.Watch(KEY, "MastercraftRecipePanel", function(f) Piece(f) end)
	ns.Watch(KEY, "MastercraftProfessionButton", function() Profession() end)
	-- (The Group Finder loaded before this ran: made at its login.)
	ns.Watch(KEY, "MastercraftLFGPanel", function() LFG() end)
end

ns.Pack(KEY, "Mastercraft", function(K)
	NoteTheme()
	-- (Its windows are made once the player is in: from login on.)
	ns.Watch(KEY, function() return IsLoggedIn() and UIParent or nil end, function(_, Kit2) Setup(Kit2 or K) end)
end, CAPS)

-- ---------------------------------------------------------------------------------------------
-- What DaylightUI already does (the first-load choices; Choices.lua)
-- ---------------------------------------------------------------------------------------------

local has = ns.DaylightHas
local function Item(key, label, daylight, test)
	return { key = key, label = label, daylight = daylight, ours = test }
end

-- (From an audit of Mastercraft 2.0.0 against every DaylightUI module, checked again for 2.0.1: its
-- new Crafters pieces (Notify me, several recipes in one ask, the automatic Busy) have nothing in
-- DaylightUI or the Daylight plugins to overlap; checked for 2.0.5: Looking For Crafter sits in
-- the game's Group Finder, which DaylightUI's own Group Finder window covers by default (nothing
-- to hand over: it's simply out of sight there), and the next trainer at a profession's cap is
-- Daylight Recipes' ground. Left out: its fishing
-- helper's "after the fight" (Daylight Fishing hands that one over itself); its profession window
-- card, mini guide, shopping list and crafting costs (Daylight Recipes' ground, not DaylightUI's);
-- its minimap button (DaylightUI's drawer takes it as it is).)
ns.Handover(KEY, {
	ready = function() return MSettings() ~= nil end,
	get = function(key)
		local s = MSettings()
		return s and s[key]
	end,
	set = function(key, value)
		local s = MSettings()
		if s then s[key] = value end
	end,
	list = {
		Item("autoJunk", L["Sell Junk at Vendors"], ns.In(L["sell junk"], "Bags"),
			function() return has("Bags", "sellJunk") end),
		Item("autoRepair", L["Repair at Vendors"], ns.In(L["auto repair"], "Bags"),
			function() return has("Bags", "autoRepair") end),
		Item("ownedTooltip", L["How Many You Own, in Item Tooltips"],
			ns.In(L["each character's count in item tooltips"], "Bags"),
			function() return has("Bags", "viewer.enabled") end),
		Item("tipOwnersList", L["Who Owns It, in Item Tooltips"],
			ns.In(L["each character's count in item tooltips"], "Bags"),
			function() return has("Bags", "viewer.enabled") end),
		Item("fishEasyCast", L["Double Right-Click to Fish"], ns.In(L["right-click to fish"], "Quality of Life"),
			function() return has("QoL", "fishClick") end),
	},
})
