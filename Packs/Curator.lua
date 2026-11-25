-- Curator: the core of its skin. Curator builds every window with the game's own templates
-- (PortraitFrameTemplate windows, UIPanelButtonTemplate buttons, the collections' side tabs,
-- insets and list buttons, CheckboxWithLabelTemplate, WowStyle1 dropdowns, the spellbook's page
-- arrows, achievement-style bars), so most of it takes DaylightUI's look from the Kit's own walk;
-- what is Curator's own (its list buttons, page arrows, red corner buttons, bars, dividers, side
-- tabs, dialog backdrops, gold text it paints again on every refresh) is recognized here. The
-- windows themselves, one area at a time, are in Packs\Curator*.lua, through ns.Curator below.
--
-- RULES (read from Curator 1.15.6, which is All Rights Reserved: its files are only read):
--   * Guard.lua checks its card and album tables (ns.Cards, ns.Series, and every card or album a
--     widget holds: frame.card, .series, .shown, .x, ...) with rawget / getmetatable, a step every
--     0.25 s and before every gain. A field written into one of them, a metatable, an extra key:
--     Curator gives nothing more (cards, boosters, experience, rubies) until /reload. So this skin
--     never writes into a table it reaches through a frame, never sets a metatable on one, never
--     walks frame keys with pairs(): only GetChildren / GetRegions (real UI objects). Its own state
--     is kept in weak tables keyed by frame.
--   * CuratorDB / CuratorExport / HoardDB are sealed at logout: never touched.
--   * CuratorSaveKey is a secure /reload button laid over Curator's save buttons: never touched,
--     nor the buttons under it moved or resized.
--   * Curator reads its own scripts back (GetScript) and some frames start an OnUpdate only when
--     they have none (Wire.lua's message pump, a card's model scene): no SetScript on any Curator
--     frame, and no OnUpdate hook on one. HookScript (OnShow / OnHide / OnEnter / OnLeave /
--     OnMouseUp) and hooksecurefunc on its frames' methods only.
--   * Content stays as Curator draws it: card widgets (their faces draw their words as glyph
--     textures and read the font every frame), 3D models and scenes, boosters and boxes, particle
--     hosts, the full-screen celebrations, rarity colors and rank art.
--   * Curator sizes much of its text to fit (S.Fit / ns.SetFont shrink loops, widths summed from
--     GetStringWidth): sizes are never changed here, only the face (when the player's text look
--     asks for it) and the inks.
--   * Its windows can only be found by name (its ns is private): each is looked for on the fast
--     path (a burst of looks every frame after any click, which is how all of them open, and its
--     slash command, the addon compartment and the minimap button asking at once), then dressed
--     again on each show.
local _, ns = ...
if not ns.ok then return end

local KEY = "Curator"

local C = {}
ns.Curator = C
C.KEY = KEY

local Kit
local abs, type, pairs, ipairs, pcall, select = math.abs, type, pairs, ipairs, pcall, select

local function On() return ns.Enabled(KEY) end
C.On = On

-- A real UI object (a frame, a texture, a font string): never one of Curator's data tables.
local function Widget(x)
	if type(x) ~= "table" then return false end
	local f = x.GetObjectType
	if type(f) ~= "function" then return false end
	local ok, t = pcall(f, x)
	return ok and type(t) == "string"
end
C.Widget = Widget

local function Kind(x)
	if not Widget(x) then return nil end
	return x:GetObjectType()
end
C.Kind = Kind

local function IsTexture(x) return Kind(x) == "Texture" end
local function IsString(x) return Kind(x) == "FontString" end
C.IsTexture, C.IsString = IsTexture, IsString

-- A frame's own field, read without its metatable (never a method, never a lookup that runs code).
local function Own(f, key)
	if type(f) ~= "table" then return nil end
	return rawget(f, key)
end
C.Own = Own

local function Near(r, g, b, c, tol)
	tol = tol or 0.03
	return type(r) == "number" and abs(r - c[1]) <= tol and abs(g - c[2]) <= tol and abs(b - c[3]) <= tol
end
C.Near = Near

-- ---------------------------------------------------------------------------------------------
-- Hooks. ns.HookOnce / ns.ScriptOnce keep ONE hook per object and method for a whole pack, and
-- this pack is five files that often hook the same frame (the core's OnShow pass, an area's own
-- OnShow): every hook here goes through C.Hook / C.Script with a tag of its own, once per
-- (object, method, tag). Post-hooks only (hooksecurefunc, HookScript), never on protected frames,
-- each run only while the skin is on and guarded against errors.
-- ---------------------------------------------------------------------------------------------

local hooks = setmetatable({}, { __mode = "k" })     -- object -> { [method .. "|" .. tag] = true }

local function Hooked(obj, id)
	local set = hooks[obj]
	if not set then
		set = {}
		hooks[obj] = set
	end
	if set[id] then return true end
	set[id] = true
	return false
end

local function Run(fn)
	return function(...)
		if On() then ns.Guard(fn, ...) end
	end
end

-- After obj:method(...) runs, fn(obj, ...). tag: what this hook is for (unique per caller).
function C.Hook(obj, method, fn, tag)
	if type(obj) ~= "table" or type(method) ~= "string" or type(fn) ~= "function" then return false end
	if type(obj[method]) ~= "function" then return false end
	if obj.GetObjectType and not ns.Unprotected(obj) then return false end
	if Hooked(obj, method .. "|" .. tostring(tag)) then return true end
	hooksecurefunc(obj, method, Run(fn))
	return true
end

-- After frame's script runs (never OnUpdate: some Curator frames start their own only when they
-- have none), fn(frame, ...). tag: as above.
function C.Script(frame, script, fn, tag)
	if type(script) ~= "string" or script == "OnUpdate" or type(fn) ~= "function" then return false end
	if not ns.Unprotected(frame) or not (frame.HasScript and frame:HasScript(script)) then return false end
	if Hooked(frame, "script:" .. script .. "|" .. tostring(tag)) then return true end
	frame:HookScript(script, Run(fn))
	return true
end

-- ---------------------------------------------------------------------------------------------
-- Content: never dressed, never walked into
-- ---------------------------------------------------------------------------------------------

-- frame -> true: left as Curator draws it. Asked by every walk (the Kit's included) as it reaches
-- a frame, so content made while a long walk is under way (a page built between two of its
-- frames) is still known: a frame not marked yet is tested then (IsContent, below), and the
-- answer kept.
local plain = setmetatable({}, { __mode = "k" })     -- frames tested: not content
local IsContent
local skip = setmetatable({}, { __mode = "k", __index = function(t, f)
	if type(f) ~= "table" or plain[f] then return nil end
	if IsContent(f) then
		rawset(t, f, true)
		return true
	end
	plain[f] = true
	return nil
end })
C.skip = skip
local contentTests = {}
-- (ns.Dress's options everywhere: content skipped, Curator's checkboxes and scroll bars left to
-- the Kit's walk and ours.)
local DRESS = { skip = skip, checks = false, scrollBars = false }
C.DRESS = DRESS

-- A frame (and all under it) left exactly as Curator draws it.
function C.Content(f)
	if Widget(f) then
		plain[f] = nil
		rawset(skip, f, true)
	end
end

-- A test for content an area knows by its shape: fn(frame) -> true.
function C.AddContentTest(fn)
	contentTests[#contentTests + 1] = fn
end

local MODELS = { PlayerModel = true, DressUpModel = true, CinematicModel = true, ModelScene = true,
	Model = true, TabardModel = true }

function IsContent(f)
	if rawget(skip, f) then return true end
	local t = Kind(f)
	if not t then return true end
	if MODELS[t] then return true end
	-- (The secure /reload key, and anything protected: never touched.)
	if f == _G.CuratorSaveKey then return true end
	if f.IsProtected and f:IsProtected() then return true end
	-- A card widget (UI/Card.lua ns.NewCard): a Button with its face's layers and SetCard.
	if type(Own(f, "SetCard")) == "function" and (Own(f, "front") ~= nil or Own(f, "back") ~= nil) then return true end
	for i = 1, #contentTests do
		local ok, yes = pcall(contentTests[i], f)
		if ok and yes then return true end
	end
	return false
end
C.IsContent = IsContent

-- Marks the content under root, so every walk after it (the Kit's and ours) leaves it.
local MARK_DEPTH = 14
local function MarkEach(depth, ...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		if Widget(c) and not rawget(skip, c) then
			if IsContent(c) then
				rawset(skip, c, true)
			elseif depth < MARK_DEPTH and c.GetChildren then
				MarkEach(depth + 1, c:GetChildren())
			end
		end
	end
end
function C.Mark(root)
	if not Widget(root) or not root.GetChildren then return end
	MarkEach(1, root:GetChildren())
end

-- ---------------------------------------------------------------------------------------------
-- Inks: the game's gold and gray in DaylightUI's inks, again every time Curator paints them back
-- ---------------------------------------------------------------------------------------------

local INKS = {
	{ 1, 0.82, 0, "LABEL" },            -- the game's gold (GameFontNormal, S.GOLD)
	{ 1, 0.82, 0.2, "LABEL" },          -- (its gold as some fonts carry it)
	{ 0.91, 0.76, 0.42, "LABEL" },      -- Curator's own gold (its chat color, e8c26a)
	{ 0.5, 0.5, 0.5, "OFF" },           -- the game's gray (GameFontDisable, S.GREY)
}

local strings = setmetatable({}, { __mode = "k" })    -- font string -> hooked
local keepInk = setmetatable({}, { __mode = "k" })    -- strings whose color means something
local inked = setmetatable({}, { __mode = "k" })      -- font string -> the ink it was given
local inking = false

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
	if inking or keepInk[fs] or not On() then return end
	local r, g, b = fs:GetTextColor()
	if type(r) ~= "number" then return end
	local name = InkFor(r, g, b)
	if name then
		SetInk(fs, name)
	elseif inked[fs] then
		-- Curator's own color on it now (white, a rarity): its own from here on.
		local c = ns.Colors()[inked[fs]]
		if not (c and Near(r, g, b, c, 0.01)) then inked[fs] = nil end
	end
end

-- The player's face for Curator's words, at Curator's own size and outline: it sizes and fits
-- much of its text to the room it has (S.Fit, ns.SetFont, widths summed for tabs and labels), so
-- the text look's size and outline are not put on it, only its face.
local fonts = true
local refonting = false
local function FontFollow(fs)
	if not fonts or refonting then return end
	local ok, path, size, flags = pcall(fs.GetFont, fs)
	if not ok or type(path) ~= "string" or type(size) ~= "number" or size <= 0 then return end
	-- (The game's narrow number font stays: it's made to read on an icon.)
	if string.find(string.upper(path), "ARIALN", 1, true) then return end
	local face = ns.SafeFace((ns.FontFor(KEY, path, size, flags)))
	if type(face) ~= "string" or face == path then return end
	refonting = true
	pcall(fs.SetFont, fs, face, size, flags or "")
	refonting = false
end

local function OnColor(fs)
	if not inking and On() then InkString(fs) end
end

local function OnFont(fs)
	if not On() then return end
	FontFollow(fs)
	InkString(fs)
end

-- A string in the inks, followed through Curator's repaints.
function C.Text(fs)
	if not IsString(fs) then return end
	if not strings[fs] then
		strings[fs] = true
		C.Hook(fs, "SetTextColor", OnColor, "core:ink")
		C.Hook(fs, "SetFontObject", OnFont, "core:ink")
		C.Hook(fs, "SetFont", OnFont, "core:ink")
	end
	FontFollow(fs)
	InkString(fs)
end

-- A string whose color means something (a rarity, a state Curator colors in gold on purpose).
function C.KeepInk(fs)
	if IsString(fs) then keepInk[fs] = true end
end

-- A string in a given ink, kept in it (and repainted when the look changes).
local fixedInk = setmetatable({}, { __mode = "k" })
function C.Ink(fs, name)
	if not IsString(fs) then return end
	keepInk[fs] = true
	fixedInk[fs] = name
	local c = ns.Colors()[name]
	if c then fs:SetTextColor(c[1], c[2], c[3]) end
end

-- The strings of one frame (its regions only).
function C.Texts(f)
	if not Widget(f) or not f.GetRegions then return end
	for i = 1, select("#", f:GetRegions()) do
		local r = select(i, f:GetRegions())
		if IsString(r) then C.Text(r) end
	end
end

-- ---------------------------------------------------------------------------------------------
-- Textures: faint lines, the hover wash, the accent, tints
-- ---------------------------------------------------------------------------------------------

local accents = setmetatable({}, { __mode = "k" })    -- texture -> its alpha in the accent
local tinted = setmetatable({}, { __mode = "k" })     -- texture -> its ink

function C.Hairline(tex, alpha)
	if IsTexture(tex) then tex:SetColorTexture(1, 1, 1, alpha or 0.08) end
end

function C.Wash(tex, alpha)
	if not IsTexture(tex) then return end
	tex:SetColorTexture(1, 1, 1, alpha or (Kit and Kit.HOVER_WASH) or 0.08)
	tex:SetBlendMode("BLEND")
end

function C.Accent(tex, alpha)
	if not IsTexture(tex) then return end
	accents[tex] = alpha or 1
	ns.FillAccent(tex, alpha or 1, nil, KEY)
	tex:SetBlendMode("BLEND")
end

function C.Tint(tex, ink)
	if not IsTexture(tex) then return end
	ink = ink or "TEXT"
	tinted[tex] = ink
	tex:SetDesaturated(true)
	local c = ns.Colors()[ink]
	if c then tex:SetVertexColor(c[1], c[2], c[3]) end
end

-- The accent and tints again after the look changed.
function C.Repaint()
	for tex, alpha in pairs(accents) do
		if IsTexture(tex) then ns.FillAccent(tex, alpha, nil, KEY) end
	end
	local colors = ns.Colors()
	for tex, ink in pairs(tinted) do
		local c = colors[ink]
		if c and IsTexture(tex) then tex:SetVertexColor(c[1], c[2], c[3]) end
	end
	for fs, ink in pairs(inked) do
		if IsString(fs) and not keepInk[fs] then SetInk(fs, ink) end
	end
	for fs, ink in pairs(fixedInk) do
		local c = colors[ink]
		if c and IsString(fs) then fs:SetTextColor(c[1], c[2], c[3]) end
	end
	ns.SideTilesPaintSoon()
end

-- ---------------------------------------------------------------------------------------------
-- Curator's own controls (UI/Skin.lua), recognized by their parts
-- ---------------------------------------------------------------------------------------------

local done = setmetatable({}, { __mode = "k" })       -- frame -> what it was dressed as

local function Atlas(tex)
	if not IsTexture(tex) then return nil end
	local ok, a = pcall(tex.GetAtlas, tex)
	if ok and type(a) == "string" then return a end
end

local function File(tex)
	if not IsTexture(tex) then return nil end
	local ok, f = pcall(tex.GetTexture, tex)
	if ok then
		if type(f) == "string" then return string.lower(f) end
		return f
	end
end

local ARROWS                                          -- file -> "left" / "right"
local function Arrows()
	if not ARROWS then
		ARROWS = ns.FileIDs({
			["Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up"] = "left",
			["Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"] = "right",
		})
	end
	return ARROWS
end

-- S.ListButton: dark ground, gold when chosen (b.sel), lit under the mouse (b.hl).
local function ListButton(b)
	local bg, sel, hl = Own(b, "bg"), Own(b, "sel"), Own(b, "hl")
	if not (IsTexture(bg) and IsTexture(sel) and IsTexture(hl)) then return false end
	if type(Own(b, "SetSelected")) ~= "function" then return false end
	bg:SetColorTexture(1, 1, 1, 0.03)
	C.Accent(sel, 0.22)
	C.Wash(hl)
	return true
end

-- S.Arrow: the spellbook's round page arrows.
local function PageArrow(b)
	if Kind(b) ~= "Button" or not b.GetNormalTexture then return false end
	local dir = Arrows()[File(b:GetNormalTexture())]
	if not dir then return false end
	Kit.PageButton(b, dir)
	return true
end

-- S.RedButton: the small red corner buttons (Condense / Expand / Exit), b.icon repainted on every
-- press: its art stays hidden, a chevron (or the X) of DaylightUI's drawn instead.
local REDDIR = { Condense = "down", Expand = "up" }
local chevrons = setmetatable({}, { __mode = "k" })
local function RedKind(b)
	local k = Own(b, "kind")
	return type(k) == "string" and k or "Exit"
end
local function RedButton(b)
	if not (IsTexture(Own(b, "icon")) and IsTexture(Own(b, "hl")) and type(Own(b, "SetKind")) == "function") then return false end
	local kind = RedKind(b)
	if kind == "Exit" then
		Kit.Close(b)
		return true
	end
	local c = Kit.PageButton(b, REDDIR[kind] or "up")
	chevrons[b] = c
	C.Hook(b, "SetKind", function(self)
		local chev = chevrons[self]
		local d = REDDIR[RedKind(self)]
		if chev and chev.SetRotation and d and Kit.ROTATION then chev:SetRotation(Kit.ROTATION[d] or 0) end
	end, "core:red")
	return true
end

-- S.ThinBar / S.Bar's older bar: a status bar in its gold metal frame, or the skills bar's.
local function Bar(b)
	if Kind(b) ~= "StatusBar" then return false end
	local metal = IsTexture(Own(b, "left")) and IsTexture(Own(b, "right")) and IsTexture(Own(b, "mid"))
	local skills = IsTexture(Own(b, "border")) and IsTexture(Own(b, "bg"))
	if not (metal or skills) then return false end
	-- (Its fill keeps Curator's color: green, blue, a rarity. Kit.StatusBar hides every texture on
	-- the bar: all but the frame art come back as Curator left them, a tip or spark it tweens.)
	local art = {}
	for _, key in ipairs({ "left", "right", "mid", "border", "bg" }) do
		local t = Own(b, key)
		if IsTexture(t) then art[t] = true end
	end
	local was = {}
	for i = 1, select("#", b:GetRegions()) do
		local reg = select(i, b:GetRegions())
		if IsTexture(reg) and not art[reg] then was[reg] = reg:GetAlpha() end
	end
	local r, g, bl = b:GetStatusBarColor()
	Kit.StatusBar(b)
	if type(r) == "number" then b:SetStatusBarColor(r, g, bl) end
	local fill = b:GetStatusBarTexture()
	for reg, alpha in pairs(was) do
		if reg ~= fill and type(alpha) == "number" then reg:SetAlpha(alpha) end
	end
	return true
end

-- S.SideTab: the collections' side tabs, as clean icon tiles.
local function TabPicked(tab)
	if tab.GetChecked then
		local ok, on = pcall(tab.GetChecked, tab)
		if ok and on ~= nil then return on == true or on == 1 end
	end
	local s = Own(tab, "SelectedTexture")
	return IsTexture(s) and s:IsShown() == true
end
local function SideTab(tab)
	if not (IsTexture(Own(tab, "Icon")) and type(tab.SetCustomOnMouseUpHandler) == "function") then return false end
	Kit.Strip(tab)
	-- (A tab Curator hangs on a game window the game shows from its own code: no script of ours
	-- on its showing.)
	local parent = tab:GetParent()
	local name = parent and parent.GetName and parent:GetName()
	local quiet = not (type(name) == "string" and string.sub(name, 1, 7) == "Curator")
	if ns.SideTile(tab, { picked = TabPicked, copy = true, key = KEY, quiet = quiet }) then
		C.Hook(tab, "SetChecked", ns.SideTilesPaintSoon, "core:tile")
	end
	return true
end

-- A panel drawn with the old dialog or tooltip backdrop (Curator's fallbacks and its own panels).
local DIALOG = { ["interface\\dialogframe\\ui-dialogbox-border"] = "window", ["interface\\tooltips\\ui-tooltip-border"] = "panel" }
local function BackdropKind(f)
	if type(f.GetBackdrop) ~= "function" then return nil end
	local ok, b = pcall(f.GetBackdrop, f)
	if ok and type(b) == "table" and type(b.edgeFile) == "string" then
		return DIALOG[string.lower(b.edgeFile)]
	end
end
C.BackdropKind = BackdropKind

function C.Panel(f)
	if not Widget(f) or done[f] then return end
	done[f] = "panel"
	ns.NoBackdrop(f)
	ns.Shell(f, nil, KEY)
end

-- A whole window drawn with the dialog backdrop: its backdrop off, DaylightUI's window shell on,
-- its X dressed (ns.PlainWindow without its ns.Dress pass, which would put the text look's size on
-- words Curator measures: the pass here does the rest, face only).
local function PlainShell(f)
	ns.NoBackdrop(f)
	ns.Shell(f, { window = true }, KEY)
	if ns.Controls(KEY) then
		local close = ns.FindClose(f)
		if close and not done[close] then
			done[close] = "close"
			Kit.Close(close)
		end
	end
end

function C.Plain(f)
	if not Widget(f) or done[f] then return end
	done[f] = "window"
	PlainShell(f)
end

-- An inset (InsetFrameTemplate, the collections' background): DaylightUI's dark inset.
local function Inset(f)
	if not (Own(f, "NineSlice") ~= nil and IsTexture(Own(f, "Bg"))) then return false end
	-- (A whole window has those too: never darkened over.)
	if Own(f, "TitleContainer") ~= nil or Own(f, "PortraitContainer") ~= nil or done[f] then return false end
	Kit.Inset(f)
	return true
end

-- One frame, by what it is (once each).
local function Control(f)
	if done[f] then return end
	local t = Kind(f)
	if t == "Button" or t == "CheckButton" then
		if ns.IsGameClose(f) then
			done[f] = "close"
			Kit.Close(f)
		elseif t == "Button" and (Own(f, "intrinsic") or f.intrinsic) == "DropdownButton" then
			-- (S.Dropdown: WowStyle1DropdownTemplate, which this client calls a Button; the Kit's
			-- walk only knows it by a "Dropdown" key.)
			done[f] = "dropdown"
			Kit.Dropdown(f)
		elseif SideTab(f) then
			done[f] = "tab"
		elseif ListButton(f) then
			done[f] = "list"
		elseif PageArrow(f) then
			done[f] = "arrow"
		elseif RedButton(f) then
			done[f] = "red"
		end
	elseif t == "StatusBar" then
		if Bar(f) then done[f] = "bar" end
	elseif t == "Frame" then
		local k = BackdropKind(f)
		if SideTab(f) then
			-- (S.SideTab: LargeSideTabButtonTemplate, a Frame on this client.)
			done[f] = "tab"
		elseif k == "panel" then
			C.Panel(f)
		elseif Inset(f) then
			done[f] = "inset"
		end
	end
end

-- The atlases Curator draws its dividers with: a faint line.
local DIVIDERS = { Options_HorizontalDivider = true }
local function Regions(f)
	for i = 1, select("#", f:GetRegions()) do
		local r = select(i, f:GetRegions())
		local t = Kind(r)
		if t == "FontString" then
			C.Text(r)
		elseif t == "Texture" and not done[r] then
			local a = Atlas(r)
			if a and DIVIDERS[a] then
				done[r] = "line"
				C.Hairline(r, 0.1)
			end
		end
	end
end

-- Our own walk: Curator's controls and every string, content left alone.
local WALK_DEPTH = 14
local function WalkEach(depth, controls, ...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		if Widget(c) and not skip[c] then
			if controls then Control(c) end
			Regions(c)
			if depth < WALK_DEPTH and c.GetChildren then WalkEach(depth + 1, controls, c:GetChildren()) end
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The pass over a window: content marked, the Kit's walk, the fonts, ours
-- ---------------------------------------------------------------------------------------------

local function Auto(root, opts)
	if not ns.Controls(KEY) then return end
	if Kit.Walking(root) then
		-- (A walk still under way drops a second one: asked again a moment later.)
		C_Timer.After(0.1, function() C.Queue(root, opts) end)
		return
	end
	ns.Guard(Kit.Auto, root, { skip = skip, rows = false, depth = opts and opts.depth or 14,
		onPage = function(shown) C.Queue(Widget(shown) and shown or root, opts) end })
end

-- A pass over root (a window, a page): run again whenever something may have been built or
-- painted again under it. opts.noAuto: Curator's own controls and the strings only.
function C.Pass(root, opts)
	if not Kit or not On() or not Widget(root) then return end
	if skip[root] then return end
	-- (The Kit still walking this window: the whole pass a moment later, once.)
	if Kit.Walking(root) then
		C_Timer.After(0.1, function() C.Queue(root, opts) end)
		return
	end
	-- (opts.before: an area marks content Curator built late under root before anything walks it.)
	local before = opts and opts.before
	if before then ns.Guard(before, root) end
	C.Mark(root)
	local controls = ns.Controls(KEY)
	fonts = not ns.PlainText(KEY)
	if not (opts and opts.noAuto) then Auto(root, opts) end
	if controls then Control(root) end
	Regions(root)
	if root.GetChildren then WalkEach(1, controls, root:GetChildren()) end
	local after = opts and opts.after
	if after then ns.Guard(after, root) end
end

local passOpts = setmetatable({}, { __mode = "k" })
local passIds = setmetatable({}, { __mode = "k" })    -- root -> its own queue id (never the frame)
-- The pass on the next frame, once however often it's asked.
function C.Queue(root, opts)
	if not Widget(root) then return end
	if opts then passOpts[root] = opts end
	local id = passIds[root]
	if not id then
		id = {}
		passIds[root] = id
	end
	ns.Queue(id, function()
		if root:IsVisible() then C.Pass(root, passOpts[root]) end
	end, KEY)
end

-- After obj:method() runs (a Curator frame's own method: SetTitle, a pager's Set, a tab's SetChecked),
-- root is dressed again.
function C.After(obj, method, root, opts)
	if not Widget(obj) or type(obj[method]) ~= "function" then return end
	C.Hook(obj, method, function() C.Queue(root or obj, opts) end, "core:after:" .. tostring(root or obj))
end

-- On every show of f, root (f by default) is dressed again.
function C.OnShow(f, root, opts)
	if not Widget(f) then return end
	C.Script(f, "OnShow", function() C.Queue(root or f, opts) end, "core:show:" .. tostring(root or f))
end

-- ---------------------------------------------------------------------------------------------
-- Windows
-- ---------------------------------------------------------------------------------------------

-- A window of the game's (S.Window: PortraitFrameTemplate): DaylightUI's shell, title and X.
-- opts: Kit.Window's (keep = { keys }, ownFade = true for a window whose alpha Curator reads).
function C.Window(f, opts)
	if not Widget(f) or done[f] then return end
	done[f] = "window"
	if BackdropKind(f) == "window" then
		PlainShell(f)
		return
	end
	-- (Kit.Window hides every texture on the window itself, Curator's divider lines among them:
	-- those come back as faint lines.)
	local lines = {}
	for i = 1, select("#", f:GetRegions()) do
		local r = select(i, f:GetRegions())
		local a = Atlas(r)
		if a and DIVIDERS[a] then lines[#lines + 1] = { r, r:GetAlpha() } end
	end
	Kit.Window(f, opts)
	for _, line in ipairs(lines) do
		local r = line[1]
		done[r] = "line"
		C.Hairline(r, 0.1)
		r:SetAlpha(line[2] or 1)
	end
end

-- Looks for the window named `name`; on finding it, setup(frame) (C.Window by default) and a
-- pass, again on every show. opts: passed on to C.Pass / C.Window.
function C.Track(name, setup, opts)
	ns.Watch(KEY, name, function(frame)
		if not On() or not Widget(frame) then return end
		if setup then
			ns.Guard(setup, frame, opts)
		elseif not (opts and opts.noWindow) then
			C.Window(frame, opts and opts.window)
		end
		C.OnShow(frame, frame, opts)
		if frame:IsVisible() then C.Pass(frame, opts) end
	end)
end

-- Looks for a frame found by a function (a page hung off a named window): get() -> frame or nil.
function C.TrackBy(get, setup, opts)
	ns.Watch(KEY, function()
		local ok, f = pcall(get)
		if ok and Widget(f) then return f end
	end, function(frame)
		if not On() then return end
		if setup then ns.Guard(setup, frame, opts) end
		C.OnShow(frame, frame, opts)
		if frame:IsVisible() then C.Pass(frame, opts) end
	end)
end

-- ---------------------------------------------------------------------------------------------
-- The areas (Packs\Curator*.lua): each adds fn(Kit), run as the pack starts
-- ---------------------------------------------------------------------------------------------

local areas = {}
function C.Area(fn)
	areas[#areas + 1] = fn
end

local function Entry()
	-- What opens its windows from outside: each looks at once after it ran.
	if type(_G.Curator_OnAddonCompartmentClick) == "function" then
		C.Hook(_G, "Curator_OnAddonCompartmentClick", ns.WatchNow, "core:entry")
	end
	local slash = _G.SlashCmdList
	if type(slash) == "table" and type(slash.CURATOR) == "function" then
		C.Hook(slash, "CURATOR", ns.WatchNow, "core:entry")
	end
	ns.Watch(KEY, "CuratorMinimapButton", function(button)
		C.Script(button, "OnClick", ns.WatchNow, "core:entry")
		C.Script(button, "OnMouseUp", ns.WatchNow, "core:entry")
	end)
end

ns.Pack(KEY, "Curator", function(K)
	Kit = K
	C.Kit = K
	Entry()
	for _, fn in ipairs(areas) do ns.Guard(fn, K) end
	ns.me.On("StyleChanged", function() ns.Guard(C.Repaint) end)
	ns.me.On("SettingChanged", function(scope, path)
		if scope == "DaylightAddonSkins" and type(path) == "string"
			and string.find(path, "look." .. KEY .. ".", 1, true) == 1 then
			ns.Queue("Curator:repaint", C.Repaint, KEY)
		end
	end)
end, { window = true, controls = true, text = true, shadow = true, font = "addon" })
