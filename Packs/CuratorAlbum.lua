-- Curator: the album window (CuratorAlbum) and everything in it, through the core in
-- Packs\Curator.lua (ns.Curator). Reached from /curator, the addon compartment, the minimap button
-- (all three open it on the Inventory tab), the side tabs, toasts and Curator's other windows.
--
-- Dressed:
--   * The window: DaylightUI's shell, title and X (the portrait ring goes; the gold seal of a
--     complete album and the rule between the counters stay), the side tabs as icon tiles, the page
--     ground (the collections' inset), the pager and every page arrow (DaylightUI chevrons), the
--     head bar, the footer buttons, the farm dropdown, the gauge, the waiting note's panel.
--   * Every page Curator builds in it, the first time it shows and again after each repaint:
--     Inventory (cells' strings, filter chips, sort, album dropdown, sell footer), All albums (top
--     tabs, continent chips, tiles' panels), the album pages, Social (section tabs, toggles, lists,
--     trade editor, picker, chooser), Contracts (tiles, drawer, register, chips, buttons; the case
--     desk's pieces too), Achievements, Profile (section tabs, boxes, track, pulls), Quests (nav,
--     stock, board, cards and rows, the golden quest button), Talents (strip, footer), Inns (rest,
--     leads, counts tiles), Discovery and Winter Veil (buttons, bars, arrows, text), Statistics
--     (nav, key, rows, toggles), the chest, Boosters (featured column, tiles, picker, odds, the
--     golden slot, displays view, gift code), the case and souvenir albums and their detail, and
--     the card detail view with what other files add to it (copy chips, appraisal, void and mage
--     blocks, restoration block, quote viewer, certificate's close button).
--   * Curator's own pieces, by their parts: its dark cards (QuestCard art) become DaylightUI panels;
--     its section buttons and toggles (QuestCard + gold glow) become rows whose pick is the accent
--     outline (their accent stripe in the accent; so too the album chosen among the boosters'
--     "Choose the album" tiles); its chips lit in gold get the accent; its experience bars lose
--     their gold metal frame for DaylightUI's bar outline (the fill, its color, ticks, shine and
--     spark stay); its text buttons' "lit" glow takes the accent; the profile showcase's dark card
--     a DaylightUI panel (what stands on it kept); the golden slot's and the golden quest's gold
--     box and list highlight DaylightUI's.
--   * The Winter Veil letter (CuratorVeilLetter) and the full-screen gift opening (CuratorVeilOpening)
--     are scenes: only their buttons are dressed. The developer's 3D demo (CuratorVeil3D) gets a
--     DaylightUI window.
-- Kept as Curator draws them: card widgets and case cards, 3D boxes, pallets, displays, boosters,
-- models and scenes, particles and every FX, the photos and studio rooms, rarity / finish / rank /
-- grade / period / state colors, gems, emblems, medals, rings, seals, stamps, badges, the gold claim
-- buttons and the ruby pills, the contract deed and every parchment (the reconversion contract, the
-- passport, the letters, the certificates) with their ink, the loyalty card and slate, the talent
-- trees, the profile showcase, the detail's scenes (appraisal, rite, certification, restoration),
-- the Discovery and Winter Veil panels (their colors say ready / earned), the copy chips' finish
-- edges, the locked pills, the gift's step path (its current number dark on a gold disc) and the
-- letter written on its stationery, the tour button (i).
-- The window's title stands right of Curator's tour button (i), which sits on its top-left corner.
-- Re-dressed after every repaint: the window's SetTitle (once per refresh, the 20 s quest refresh
-- included), the pager's Set, a mouse button let go or the wheel over the window, and its show;
-- never per frame (one look at most every tenth of a second, the pages shown only, and a page passed
-- again only when what it shows changed: frames shown or hidden, made, given strings).
-- What each page keeps as content is marked before any pass reaches it (a pass from the core or
-- the Kit's walk marks through the content test below), so no walk ever inks a parchment's words.
local _, ns = ...
if not ns.ok then return end
local C = ns.Curator
if not C then return end

C.Area(function(Kit)
	local KEY = C.KEY
	local Own, Kind, Widget, Near = C.Own, C.Kind, C.Widget, C.Near
	local select, type, pcall, ipairs, pairs = select, type, pcall, ipairs, pairs
	local GetTime = _G.GetTime

	local function IsTexture(x) return Kind(x) == "Texture" end
	local function IsString(x) return Kind(x) == "FontString" end
	local function Controls() return ns.Controls(KEY) end

	-- Curator's own art, known by its file (a path or the number the client gives it).
	local MEDIA = "Interface\\AddOns\\Curator\\Media\\"
	local FILES = ns.FileIDs({
		[MEDIA .. "QuestCard"] = "card",
		[MEDIA .. "QuestGlow"] = "glow",
		[MEDIA .. "QuestAccent"] = "accent",
		[MEDIA .. "Glow"] = "light",
		[MEDIA .. "Shadow"] = "shadow",
		[MEDIA .. "VeilTag"] = "tag",
	})
	local function Art(tex)
		if not IsTexture(tex) then return nil end
		local ok, f = pcall(tex.GetTexture, tex)
		if not ok or f == nil then return nil end
		if type(f) == "string" then f = string.lower(f) end
		return FILES[f]
	end

	-- My hooks on Curator's widgets go through the core's (C.Hook / C.Script: once per object,
	-- method and tag, run only while the skin is on, guarded); each has a tag of its own.
	local function Hook(obj, method, fn, tag)
		if Widget(obj) then C.Hook(obj, method, fn, "album:" .. tag) end
	end
	local function Script(frame, script, fn, tag)
		if Widget(frame) then C.Script(frame, script, fn, "album:" .. tag) end
	end

	-- -----------------------------------------------------------------------------------------
	-- Content Curator draws itself: never dressed, never walked into
	-- -----------------------------------------------------------------------------------------

	-- The window and its page ground, once found; Prepare (below) marks what each page keeps.
	local album, body
	local Prepare
	-- Any pass that reaches the window's frames (the core's, on its show or a page the Kit saw
	-- shown; ours) marks the pages' content first: once a frame at most, from the first frame
	-- the pass tests under the window, the page ground or a page.
	local under = setmetatable({}, { __mode = "k" })     -- parent -> whether it's one of those
	local preparedAt
	local function PrepareFor(p)
		if not album or p == nil then return end
		local u = under[p]
		if u == nil then
			u = p == album or p == body or (body ~= nil and p.GetParent ~= nil and p:GetParent() == body)
			under[p] = u
		end
		if not u then return end
		local now = GetTime()
		if preparedAt == now then return end
		preparedAt = now
		Prepare()
	end

	C.AddContentTest(function(f)
		local p = f.GetParent and f:GetParent()
		PrepareFor(p)
		-- (Boosters, display boxes and crates are the scenes area's test; Hud.Badge the windows'.)
		-- (Rank emblems, sealed-rank and grade labels.)
		if type(Own(f, "SetRank")) == "function" or type(Own(f, "SetGrade")) == "function" then return true end
		-- (3D case boxes, pallets and displays.)
		if type(Own(f, "m")) == "table" and Own(f, "flat") ~= nil then return true end
		-- (Case cards, big and small.)
		if IsTexture(Own(f, "ground")) and IsTexture(Own(f, "pic")) and IsTexture(Own(f, "aura")) then return true end
		-- (A letter's paper, a gift's paper tag.)
		if Art(Own(f, "shadow")) == "shadow" and IsTexture(Own(f, "left")) and IsTexture(Own(f, "right")) then return true end
		if Art(Own(f, "paper")) == "tag" then return true end
		-- (A certificate.)
		if IsTexture(Own(f, "neb")) and IsTexture(Own(f, "sigil")) then return true end
		-- (A particle host of the Winter Veil: its parent holds it as .vfx.)
		local v = p and Own(p, "vfx")
		if type(v) == "table" and rawget(v, "frame") == f then return true end
		return false
	end)

	local function Content(f) if Widget(f) then C.Content(f) end end

	-- A text button inside a piece kept as content (the deed's, a scene's).
	local function Button(b)
		if Widget(b) and Controls() then ns.Guard(Kit.Button, b) end
	end

	-- -----------------------------------------------------------------------------------------
	-- The accent, on what carries it (painted again when the look changes)
	-- -----------------------------------------------------------------------------------------

	local accentColor
	local function Accent()
		if not accentColor then
			local r, g, b = ns.AccentOf(KEY)
			accentColor = { r, g, b }
		end
		return accentColor
	end

	local tinted = setmetatable({}, { __mode = "k" })   -- a stripe or glow in the accent
	local function Tint(tex)
		if not IsTexture(tex) then return end
		tinted[tex] = true
		ns.PaintAccent(tex, 1, nil, KEY)
	end

	-- -----------------------------------------------------------------------------------------
	-- Curator's dark cards (QuestCard): DaylightUI's panel; its section buttons and toggles: rows
	-- picked in the accent
	-- -----------------------------------------------------------------------------------------

	local WHITE = { 1, 1, 1 }
	local seen = setmetatable({}, { __mode = "k" })      -- frame -> looked at
	local shells = setmetatable({}, { __mode = "k" })    -- frame -> its lite shell
	local how = setmetatable({}, { __mode = "k" })       -- frame -> how its pick is read
	local picked = setmetatable({}, { __mode = "k" })    -- frame -> picked by its text's color

	-- (An album chosen among the tiles of "Choose the album": its name in this warm gold.)
	local CHOSEN = { 1, 0.86, 0.4 }
	local SOLID = { bgAlpha = 0.92 }

	local function Picked(f)
		local k = how[f]
		if k == "accent" then
			local a = Own(f, "accent")
			return IsTexture(a) and a:IsShown() == true
		elseif k == "on" then
			return Own(f, "on") and true or false
		elseif k == "text" then
			return picked[f] == true
		end
		return false
	end

	local function PaintPick(f)
		local s = shells[f]
		if s then Kit.Paint(s, Picked(f) and Accent() or nil) end
	end

	-- The texture pieces of a list Curator keeps on the frame (a 3-slice or a 9-slice).
	local function EachPiece(list, fn)
		if type(list) ~= "table" or Widget(list) then return end
		for i = 1, 9 do
			local t = rawget(list, i)
			if IsTexture(t) then fn(t) end
		end
	end

	local function CardPanel(f)
		local found = false
		for i = 1, select("#", f:GetRegions()) do
			local r = select(i, f:GetRegions())
			if Art(r) == "card" then
				found = true
				Kit.Hide(r)
			end
		end
		if not found then return false end
		-- (A button or a tile: a list row's light ground. A box or a panel, some laid over the page
		-- as Curator's opaque card was (the contract drawer, the odds, the trade picker): solid.)
		shells[f] = Kit.Shell(f, "row", Kind(f) ~= "Button" and SOLID or nil)
		-- (Its warm hover wash: DaylightUI's.)
		local hl = Own(f, "hl")
		if IsTexture(hl) and not Art(hl) then C.Wash(hl) end
		if Kind(f) ~= "Button" or not Controls() then return true end
		-- A section button (its accent stripe shown when picked), a toggle (SetSelected) or a sort
		-- button (white words when picked): its gold glow goes, the outline tells the pick.
		local text, accent = Own(f, "text"), Own(f, "accent")
		local name = Own(f, "name")
		if IsString(text) and Art(accent) == "accent" then
			how[f] = "accent"
			Tint(accent)
			Hook(accent, "SetShown", function() PaintPick(f) end, "pick")
		elseif type(Own(f, "SetSelected")) == "function" then
			how[f] = "on"
			Hook(f, "SetSelected", function() PaintPick(f) end, "pick")
		elseif IsString(text) and type(Own(f, "glow")) == "table" then
			how[f] = "text"
			local r, g, b = text:GetTextColor()
			picked[f] = Near(r, g, b, WHITE, 0.02)
			Hook(text, "SetTextColor", function(_, r2, g2, b2)
				picked[f] = Near(r2, g2, b2, WHITE, 0.02)
				PaintPick(f)
			end, "pick")
		elseif IsString(name) and IsTexture(Own(f, "photo")) and IsTexture(Own(f, "flash"))
			and type(Own(f, "glow")) == "table" and Own(f, "ring") == nil then
			-- An album to choose (Boosters.lua's pick tile): chosen, its name in warm gold.
			how[f] = "text"
			local r, g, b = name:GetTextColor()
			picked[f] = Near(r, g, b, CHOSEN, 0.02)
			Hook(name, "SetTextColor", function(_, r2, g2, b2)
				picked[f] = Near(r2, g2, b2, CHOSEN, 0.02)
				PaintPick(f)
			end, "pick")
		end
		if how[f] then
			EachPiece(Own(f, "glow"), Kit.Erase)
			PaintPick(f)
		end
		return true
	end

	-- -----------------------------------------------------------------------------------------
	-- Curator's experience bars (Hud.XPBar): its gold metal frame for DaylightUI's bar outline
	-- -----------------------------------------------------------------------------------------

	local function XPBar(f)
		if Kind(Own(f, "bar")) ~= "StatusBar" or not IsTexture(Own(f, "back")) or not Widget(Own(f, "over")) then return false end
		local l, m, r = Own(f, "left"), Own(f, "mid"), Own(f, "right")
		if not (IsTexture(l) and IsTexture(m) and IsTexture(r)) then return false end
		Kit.Hide(Own(f, "back"))
		Kit.Hide(l)
		Kit.Hide(m)
		Kit.Hide(r)
		Kit.Shell(f, "bar")
		return true
	end

	-- -----------------------------------------------------------------------------------------
	-- Chips (the copies', the filters', the continents'): the gold of a lit one in the accent;
	-- a copy chip's finish edge stays
	-- -----------------------------------------------------------------------------------------

	local LIT = { 1, 0.86, 0.45 }         -- a copy or filter chip lit (Copies.lua)
	local ON = { 1, 0.8, 0.32 }           -- a continent chip on (Album.lua)
	local OFF = { 0.55, 0.45, 0.25 }      -- a continent chip off: its brown edge
	local LIT_BG = { { 0.16, 0.12, 0.04 }, { 0.26, 0.18, 0.05 } }
	local litChips = setmetatable({}, { __mode = "k" })  -- chip -> lit
	local chipOf = setmetatable({}, { __mode = "k" })    -- edge / ground texture -> its chip
	local painting = false

	-- (The ground stays opaque over the edge it is laid on: the accent darkened.)
	local DARK = 0.28
	local function DarkGround(tex)
		local a = Accent()
		painting = true
		tex:SetColorTexture(a[1] * DARK, a[2] * DARK, a[3] * DARK, 0.95)
		painting = false
	end

	local function LightChip(b)
		litChips[b] = true
		painting = true
		ns.FillAccent(Own(b, "edge"), 0.95, nil, KEY)
		painting = false
		DarkGround(Own(b, "bg"))
	end

	local function Neutral(tex, a)
		local n = Kit.ROW_BORDER or Kit.CONTROL_BORDER
		painting = true
		tex:SetColorTexture(n[1], n[2], n[3], a or 0.8)
		painting = false
	end

	local function OnEdge(tex, r, g, b, a)
		if painting then return end
		local chip = chipOf[tex]
		if not chip then return end
		if type(a) == "number" and a >= 0.9 and (Near(r, g, b, LIT) or Near(r, g, b, ON)) then
			litChips[chip] = true
			painting = true
			ns.FillAccent(tex, 0.95, nil, KEY)
			painting = false
		else
			litChips[chip] = nil
			-- (A gradient left from its lit days would tint the finish color Curator gives it.)
			tex:SetVertexColor(1, 1, 1, 1)
			if Near(r, g, b, OFF) then Neutral(tex, a) end
		end
	end

	local function OnGround(tex, r, g, b)
		if painting then return end
		if Near(r, g, b, LIT_BG[1], 0.02) or Near(r, g, b, LIT_BG[2], 0.02) then DarkGround(tex) end
	end

	local function Chip(b)
		if Kind(b) ~= "Button" then return false end
		local edge, bg, text, hl = Own(b, "edge"), Own(b, "bg"), Own(b, "text"), Own(b, "hl")
		if not (IsTexture(edge) and IsTexture(bg) and IsString(text) and IsTexture(hl)) then return false end
		if not Controls() then return true end
		chipOf[edge], chipOf[bg] = b, b
		Hook(edge, "SetColorTexture", OnEdge, "chip")
		Hook(bg, "SetColorTexture", OnGround, "chip")
		if not Art(hl) then C.Wash(hl) end
		-- (Painted before it was found: its state now, from its words and its own flag.)
		local r, g, bl = text:GetTextColor()
		if Near(r, g, bl, WHITE, 0.02) then
			LightChip(b)
		elseif type(Own(b, "Paint")) == "function" and not Own(b, "on") then
			Neutral(edge, 0.55)
		end
		return true
	end

	-- -----------------------------------------------------------------------------------------
	-- Text buttons with a glow of Curator's when picked (the Winter Veil's tabs, the gift's
	-- wraps, the tree's modes, the shop's stalls): the glow in the accent
	-- -----------------------------------------------------------------------------------------

	local function LitButton(b)
		if Kind(b) ~= "Button" or not Controls() then return false end
		local lit = Own(b, "lit")
		if Art(lit) ~= "light" or not (IsTexture(Own(b, "Left")) or IsTexture(Own(b, "Middle"))) then return false end
		Tint(lit)
		return true
	end

	-- -----------------------------------------------------------------------------------------
	-- The walk over a page after the core's pass: Curator's own pieces, by their parts
	-- -----------------------------------------------------------------------------------------

	local function Look(f)
		if seen[f] then return end
		seen[f] = true
		local t = Kind(f)
		if t == "Frame" and XPBar(f) then return end
		if (t == "Frame" or t == "Button") and CardPanel(f) then return end
		if t == "Button" then
			if not Chip(f) then LitButton(f) end
		end
	end

	-- (Run as the pass's last step: the core's C.Mark has just marked the content under root, so
	-- the skip list is enough here.)
	local DEPTH = 14
	local skip = C.skip
	local function WalkEach(depth, ...)
		for i = 1, select("#", ...) do
			local c = select(i, ...)
			if not skip[c] and Widget(c) then
				Look(c)
				if depth < DEPTH and c.GetNumChildren and c:GetNumChildren() > 0 then WalkEach(depth + 1, c:GetChildren()) end
			end
		end
	end

	-- What a page shows, as a number: its frames shown (content left out), their regions and
	-- children. The same number after a repaint: nothing new to dress there.
	local function ShapeEach(depth, h, ...)
		for i = 1, select("#", ...) do
			local c = select(i, ...)
			if not skip[c] and c.IsShown and c:IsShown() then
				local nc = c:GetNumChildren()
				h = (h * 31 + c:GetNumRegions() * 7 + nc + 1) % 2147483647
				if depth < DEPTH and nc > 0 then h = ShapeEach(depth + 1, h, c:GetChildren()) end
			end
		end
		return h
	end
	local function Shape(root)
		return ShapeEach(1, (root:GetNumRegions() * 7 + root:GetNumChildren() + 1) % 2147483647, root:GetChildren())
	end
	local shapes = setmetatable({}, { __mode = "k" })     -- page -> its shape after its last pass

	local function Walk(root)
		if not Widget(root) or skip[root] then return end
		Look(root)
		if root.GetChildren then WalkEach(1, root:GetChildren()) end
		-- (Its shape with what the pass added: the next look passes it again only if it changed.)
		if root ~= album then shapes[root] = Shape(root) end
	end

	local PAGE = { after = Walk }

	-- -----------------------------------------------------------------------------------------
	-- The pages: what each keeps as content, found by its keys before every pass
	-- -----------------------------------------------------------------------------------------

	local done = setmetatable({}, { __mode = "k" })

	-- The card detail view: the body's Button with the detail's parts (Album.lua keeps it private).
	local detail
	local function FindDetail()
		if detail or not body then return detail end
		for i = 1, select("#", body:GetChildren()) do
			local c = select(i, body:GetChildren())
			if Kind(c) == "Button" and Own(c, "inspect") and Own(c, "pin") and Own(c, "panel") and Own(c, "ped") then
				detail = c
				break
			end
		end
		return detail
	end

	-- The detail's card, light and scenes (built by Album.lua and the files that add to it,
	-- some only on their first use).
	local SCENES = { "seat", "holder", "fx", "lab", "report", "catch", "rite", "pact", "riteCatch",
		"mageFx", "mageCatch", "restFx", "restRep", "restCatch", "quoteRep", "quoteMark" }
	local function PrepDetail(d)
		for _, k in ipairs(SCENES) do Content(Own(d, k)) end
		-- (The certificate is content; its Close button is a button.)
		local cv = Own(d, "certView")
		if Widget(cv) then
			Content(cv)
			if not done[cv] then
				done[cv] = true
				Button(Own(cv, "close"))
			end
		end
	end

	-- A golden slot or the golden quest button: their gold box for a DaylightUI panel; the golden
	-- pack art and its glow stay.
	local function Golden(b)
		if not Widget(b) or done[b] then return end
		done[b] = true
		Kit.Hide(Own(b, "edge"))
		Kit.Hide(Own(b, "bg"))
		Kit.Shell(b, "row")
		-- (Its gold list highlight: DaylightUI's wash.)
		local hl = b.GetHighlightTexture and b:GetHighlightTexture()
		if IsTexture(hl) then C.Wash(hl) end
	end

	local PREP = {}
	PREP.prof = function(p)
		-- (The showcase is the player's display: kept whole, its dark card a DaylightUI panel as on
		-- the rest of the page; its words follow the text look.)
		local st = Own(p, "stage")
		if Widget(st) then
			Content(st)
			if not seen[st] then
				seen[st] = true
				CardPanel(st)
			end
			for _, k in ipairs({ "title", "pins", "empty" }) do C.Text(Own(st, k)) end
		end
	end
	PREP.quests = function(p) Golden(Own(p, "golden")) end
	PREP.boost = function(p)
		local st = Own(p, "stock")
		if Widget(st) then Golden(Own(st, "gold")) end
	end
	PREP.ctb = function(p)
		-- (The deed is parchment with its ink; its three buttons are dressed by hand.)
		local deed = Own(p, "band")
		if Widget(deed) then
			Content(deed)
			if not done[deed] then
				done[deed] = true
				Button(Own(deed, "change"))
				Button(Own(deed, "clauseBtn"))
				local dd = Own(deed, "albums")
				if Widget(dd) and Controls() then ns.Guard(Kit.Dropdown, dd) end
			end
		end
	end
	PREP.inns = function(p)
		Content(Own(p, "card"))
		Content(Own(p, "dish"))
		Content(Own(p, "book"))
	end
	PREP.tal = function(p)
		local trees = Own(p, "trees")
		if type(trees) == "table" and not Widget(trees) then
			for i = 1, 3 do
				local tr = rawget(trees, i)
				if Widget(tr) then Content(Own(tr, "grid")) end
			end
		end
		local rs = Own(p, "respec")
		if Widget(rs) then
			Content(rs)
			if not done[rs] then
				done[rs] = true
				Button(Own(rs, "back"))
			end
		end
	end
	PREP.veil = function(p)
		local tv = Own(p, "treeView")
		if Widget(tv) then Content(Own(tv, "scene")) end
		local o = Own(p, "opening")
		if Widget(o) then
			Content(o)
			if not done[o] then
				done[o] = true
				for _, k in ipairs({ "open", "read", "close" }) do Button(Own(o, k)) end
			end
		end
		-- The gift being made (the shop, "My gift"): the letter written on the stationery, in its
		-- ink and letter font (its box sits beside the paper, not on it), and the step path, whose
		-- current step's number is dark on its gold disc.
		local shop = Own(p, "shop")
		local gift = Widget(shop) and Own(shop, "gift")
		if not Widget(gift) then return end
		local steps = Own(gift, "steps")
		if type(steps) == "table" and not Widget(steps) then
			for i = 1, 9 do Content(rawget(steps, i)) end
		end
		local parts = Own(gift, "body")
		local send = type(parts) == "table" and not Widget(parts) and rawget(parts, "send")
		if Widget(send) then Content(Own(send, "scroll")) end
	end
	PREP.inv = function(p) Content(Own(p, "lensHold")) end
	PREP.svd = function(p)
		Content(Own(p, "seat"))
		Content(Own(p, "holder"))
	end

	Prepare = function()
		if not album then return end
		-- The window's own: the gold of a complete album, the light of a page turned.
		Content(Own(album, "gold"))
		Content(Own(album, "goldBar"))
		local sweep = Own(album, "sweep")
		if IsTexture(sweep) then
			local lit = sweep:GetParent()
			Content(lit)
			Content(lit and lit:GetParent())
		end
		for key, fn in pairs(PREP) do
			local page = Own(album, key)
			if Widget(page) then ns.Guard(fn, page) end
		end
		-- (The case album's rule between its chips: a faint line.)
		local cases = Own(album, "casesA")
		local rule = Widget(cases) and Own(cases, "rule")
		if IsTexture(rule) and not done[rule] then
			done[rule] = true
			C.Hairline(rule, 0.12)
		end
		local d = FindDetail()
		if d then PrepDetail(d) end
	end

	-- -----------------------------------------------------------------------------------------
	-- Passes: the pages shown, after Curator painted them (one look at most every tenth of a second)
	-- -----------------------------------------------------------------------------------------

	-- Each shown child of parent (the window's own pieces, the pages on its ground) passed again
	-- when what it shows changed since its last pass.
	local function PassShown(skipChild, ...)
		for i = 1, select("#", ...) do
			local c = select(i, ...)
			if c ~= skipChild and not skip[c] and c:IsShown() and Widget(c) and not C.IsContent(c)
				and shapes[c] ~= Shape(c) then
				-- (Now, in the frame after Curator painted it; in a fight, once it's over.)
				if InCombatLockdown() then C.Queue(c, PAGE) else C.Pass(c, PAGE) end
			end
		end
	end

	local function DressShown()
		if not album or not C.On() or not album:IsVisible() then return end
		Prepare()
		C.Texts(album)
		PassShown(body, album:GetChildren())
		if body then PassShown(nil, body:GetChildren()) end
	end

	local GAP = 0.1
	local last, pending, waiting = 0, false, false
	local function Run()
		pending = false
		last = GetTime()
		ns.Guard(DressShown)
	end
	local function Soon()
		if pending or not album or not C.On() then return end
		pending = true
		local wait = GAP - (GetTime() - last)
		C_Timer.After(wait > 0 and wait or 0, Run)
	end
	-- (What a click or the wheel does may be painted a frame or two later.)
	local function Later()
		waiting = false
		Soon()
	end
	local function SoonAfter()
		if waiting or pending then return end
		waiting = true
		C_Timer.After(0.05, Later)
	end

	-- A mouse button let go over the window: most of what it does repaints a page (tabs, rows,
	-- arrows, buttons of every page). Listened to only while the window is shown.
	local mouse = CreateFrame("Frame")
	mouse:SetScript("OnEvent", function()
		if album and C.On() and album:IsVisible() and album:IsMouseOver() then SoonAfter() end
	end)

	-- -----------------------------------------------------------------------------------------
	-- The window
	-- -----------------------------------------------------------------------------------------

	-- (Curator's tour button (i), 64 x 64 at its top-left corner, 39 / +20, shows about 50 points
	-- of it from x 48: the window's title starts past it.)
	local TITLE_PAST_TOUR = 102

	local function Setup(f)
		album = f
		body = Own(f, "body")
		if not Widget(body) then body = nil end
		-- (The seal of a complete album and the rule between the counters are its own regions.)
		C.Window(f, { keep = { "goldSeal", "finRule" } })
		local tc = Own(f, "TitleContainer")
		local title = Widget(tc) and Own(tc, "TitleText")
		if IsString(title) and Widget(Own(f, "tourButton")) then
			title:SetPoint("TOPLEFT", f, "TOPLEFT", TITLE_PAST_TOUR, -(Kit.TITLE_TOP or 6))
		end
		local rule = Own(f, "finRule")
		if IsTexture(rule) then C.Hairline(rule, 0.12) end
		Prepare()
		-- Once per refresh: the window's title is set at the top of each (its page painted after,
		-- in the same call: the look waits).
		Hook(f, "SetTitle", Soon, "refresh")
		local pager = Own(f, "pager")
		if Widget(pager) then Hook(pager, "Set", Soon, "refresh") end
		Script(f, "OnShow", function()
			mouse:RegisterEvent("GLOBAL_MOUSE_UP")
			Prepare()
			Soon()
		end, "show")
		Script(f, "OnHide", function() mouse:UnregisterEvent("GLOBAL_MOUSE_UP") end, "hide")
		Script(f, "OnMouseWheel", SoonAfter, "wheel")
		if f:IsShown() then mouse:RegisterEvent("GLOBAL_MOUSE_UP") end
	end

	C.Track("CuratorAlbum", Setup, PAGE)

	-- -----------------------------------------------------------------------------------------
	-- The Winter Veil's own frames
	-- -----------------------------------------------------------------------------------------

	-- The letter reader: a page of stationery over the dimmed screen; its Close button only.
	ns.Watch(KEY, "CuratorVeilLetter", function(f)
		if not C.On() then return end
		Content(Own(f, "paper"))
		Button(Own(f, "close"))
	end)

	-- The full-screen opening of a gift (3D): a scene; its three buttons only.
	ns.Watch(KEY, "CuratorVeilOpening", function(f)
		if not C.On() then return end
		for _, k in ipairs({ "open", "read", "close" }) do Button(Own(f, k)) end
	end)

	-- The developer's 3D demo (/curator test 3d): a DaylightUI window round its model cells.
	C.Track("CuratorVeil3D", function(f)
		local bg = Own(f, "bg")
		if IsTexture(bg) then Kit.Hide(bg) end
		ns.Shell(f, { window = true }, KEY)
	end)

	-- -----------------------------------------------------------------------------------------
	-- A new look: the accent again on what carries it
	-- -----------------------------------------------------------------------------------------

	local function Repaint()
		accentColor = nil
		for tex in pairs(tinted) do
			if IsTexture(tex) then ns.PaintAccent(tex, 1, nil, KEY) end
		end
		for b in pairs(litChips) do
			if Widget(b) then LightChip(b) end
		end
		for f in pairs(shells) do
			if how[f] then PaintPick(f) end
		end
	end
	ns.me.On("StyleChanged", function() ns.Guard(Repaint) end)
	ns.me.On("SettingChanged", function(scope, path)
		if scope == "DaylightAddonSkins" and type(path) == "string"
			and string.find(path, "look." .. KEY .. ".", 1, true) == 1 then
			ns.Queue("CuratorAlbum:repaint", Repaint, KEY)
		end
	end)
end)
