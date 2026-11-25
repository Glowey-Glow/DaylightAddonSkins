-- Curator: its scenes and the small windows around them, through the core in Packs\Curator.lua.
-- Curator's scenes are spectacle (booster art, cards, models, particles, rays, its own celebration
-- type): each scene's root is kept as content, so no walk ever goes through its hundreds of
-- textures. Only the ordinary controls laid on a scene are dressed, one by one, by their keys.
-- Dressed here:
--   * The booster scene (CuratorBoosterScene, made on the first booster opened: the minimap
--     button, /curator, the album's Open, the boosters page, a toast click): its buttons (Reveal
--     all, Open all, Stop, Omen, Open it, Shake it, Redraw a card, Open another, Album, Close) as
--     DaylightUI buttons, the pick arrows beside Open all / Open another / Open the next as
--     DaylightUI page buttons (made later, when a label is set: dressed after each SetLabel); the
--     red corner buttons (Condense / Expand, and Exit in the small window) as a chevron and an X;
--     the small window's gold dialog border off for DaylightUI's outline (Curator sets it again on
--     every open, drag, wheel and size change: put off again after each SetBackdrop); the album
--     bar under the summary in the bar look (its fill keeps the album's color); the counter, the
--     hint and the summary in the player's text look (the hint keeps Curator's colors).
--     Open all (made on the first batch, found by the watch after the click that starts it): Open
--     the next, Reveal all, Reveal commons and uncommons, Sort by rarity as buttons, its two check
--     boxes as switches, and the showcase's "See all the cards" button.
--     A revealed card clicked (CuratorBoosterScene.inspect): Back, Inspect, Show in the chat and
--     Replay its entrance as buttons, its words in DaylightUI's inks (the rarity keeps its color),
--     its rule a faint line.
--   * The booster bar (CuratorBoosterBar, over the experience bar): only its gold frame gives way
--     to DaylightUI's bar outline. Curator places and scales it: it is never moved here.
--   * The toasts (CuratorToast): the loot toast and the achievement banner on a DaylightUI panel
--     instead of the game's parchment and banner, the item's gold border a DaylightUI outline,
--     "Achievement earned" (black on the banner) in the label ink, the words in the player's look.
--   * The Continue / Open the album / Later buttons of the level-up, album-complete and reward
--     screens (CuratorLevelUp, CuratorAlbumComplete, CuratorOffers), and the reward screen's hint
--     and note in the player's text look.
--   * The copy chooser (CuratorCopyPicker: a contract slot, a trade, a duel stake), the enchanter's
--     restoration panel (CuratorRestorePanel, beside the gossip or trainer window at an
--     enchanter) and the protective cases panel (CuratorCasePanel, under the bank panel when the
--     bank opens): the old dialog backdrop off for DaylightUI's window shell, their buttons, X,
--     list rows, pagers and divider through the core's pass. The chooser's drawn check boxes as a
--     DaylightUI box with a light tick.
--   * The display scene's Back and its words in the player's text look (CuratorDisplayScene), the
--     pick-up scene's inspector Back (CuratorRestoreReturn.ins). (A case card's "See the
--     certificate", CuratorCrate.inspect.certBtn, is the market area's; the reseller's display
--     sale view, CuratorReseller.disp, comes with the windows area's pass over the reseller.)
-- Kept as Curator draws them:
--   * Hud.ClaimButton everywhere (Claim, Take, Confirm, Pick it up, Close, Open the display...):
--     it is Curator's call to action, gold with dark brown words and a pulse that says a reward is
--     waiting; its own SetEnabled and SetLabel repaint it all the time. A content test here keeps
--     it out of every walk (DaylightUI's walk would also turn its dark words light on the gold).
--   * Every 3D box, crate and booster (Box3D / CrateBox faces here; anything with SetSeries is
--     the album area's test).
--   * The scenes themselves: stage, packs, cards, grid, showcase cards and chips, zoom, contract
--     ceremony (CuratorBoosterScene.ct), lair, experience bar and emblem, the scene's title and
--     subtitle, every flash and particle; the trophy toast; CuratorCinematic entirely; the level-up,
--     album-complete, reward, display and pick-up scenes apart from the buttons above; the booster
--     bar's icon, glow, spark, fill colors, floats and talent buttons; rarity and finish colors; the
--     chooser's copy chips (their edge is the finish).
local _, ns = ...
if not ns.ok then return end
local C = ns.Curator
if not C then return end

local Own, Widget, Kind = C.Own, C.Widget, C.Kind
local type, select = type, select

-- ---------------------------------------------------------------------------------------------
-- Content known by its shape (read with rawget only: these frames hold album tables)
-- ---------------------------------------------------------------------------------------------

-- Hud.ClaimButton: gold art (bg, hot, glow), its own words, its own SetPulse.
C.AddContentTest(function(f)
	return Kind(f) == "Button" and type(Own(f, "SetPulse")) == "function"
		and C.IsTexture(Own(f, "bg")) and C.IsTexture(Own(f, "hot")) and C.IsString(Own(f, "text"))
end)

-- A display box or a crate: Box3D.New and CrateBox.New (faces drawn in groups of frames). (A
-- booster or a box with SetSeries is the album area's test, Packs\CuratorAlbum.lua.)
C.AddContentTest(function(f)
	return type(Own(f, "groups")) == "table" and type(Own(f, "faces")) == "table"
end)

C.Area(function(Kit)
	local KEY = C.KEY
	local NOAUTO = { noAuto = true }

	-- Each child of a frame, as the game hands them back (no table made).
	local function EachChild(fn, ...)
		for i = 1, select("#", ...) do fn((select(i, ...))) end
	end

	-- -----------------------------------------------------------------------------------------
	-- Single controls
	-- -----------------------------------------------------------------------------------------

	-- A text button of Curator's (S.Button, UIPanelButtonTemplate). Its pick arrows (S.Arrow,
	-- made later on it) are dressed by the core's pass over it, again after each SetLabel.
	local buttons = setmetatable({}, { __mode = "k" })
	local function Button(b)
		if Kind(b) ~= "Button" or C.IsContent(b) then return end
		-- (The player's "Controls" switch for this addon off: their words only, through the pass.)
		if not buttons[b] and ns.Controls(KEY) then
			buttons[b] = true
			Kit.Button(b)
			if type(Own(b, "SetLabel")) == "function" then C.After(b, "SetLabel", b, NOAUTO) end
		end
		C.Pass(b, NOAUTO)
	end

	-- A check box of Curator's (S.Check, CheckboxWithLabelTemplate) as a switch.
	local function Check(cb)
		if Kind(cb) ~= "CheckButton" then return end
		if ns.Controls(KEY) then Kit.Check(cb) end
		C.Text(Own(cb, "Text"))
	end

	-- One of Curator's own pieces the core knows (red corner buttons, the thin bar).
	local function Piece(f)
		if Widget(f) then C.Pass(f, NOAUTO) end
	end

	-- A DaylightUI panel behind a face Curator draws on art of the game's (a toast), inset to
	-- where that art showed; under the face's own words and icons.
	local function Plate(face, left, top, right, bottom)
		local p = CreateFrame("Frame", nil, face)
		p:SetPoint("TOPLEFT", face, "TOPLEFT", left, -top)
		p:SetPoint("BOTTOMRIGHT", face, "BOTTOMRIGHT", -right, bottom)
		p:SetFrameLevel(math.max(0, face:GetFrameLevel() - 1))
		p:EnableMouse(false)
		ns.Shell(p, nil, KEY)
		return p
	end

	-- A window Curator drew with the old dialog backdrop: DaylightUI's window shell instead. (Its
	-- controls come with the core's pass, which leaves content alone.)
	local function Dialog(f)
		ns.NoBackdrop(f)
		ns.Shell(f, { window = true }, KEY)
	end

	-- -----------------------------------------------------------------------------------------
	-- The booster scene
	-- -----------------------------------------------------------------------------------------

	local SCENE_BUTTONS = { "revealAll", "all", "stop", "omen", "omenOpen", "omenShake", "redraw",
		"again", "album", "close", "batchNext", "batchFlip", "batchPlain", "batchSort" }

	-- The small window's gold border: its backdrop pieces hidden (again after each SetBackdrop),
	-- DaylightUI's outline over its edge, shown and hidden with it.
	local edged = setmetatable({}, { __mode = "k" })
	local function Border(border)
		if not Widget(border) then return end
		Kit.Backdrop(border)
		if edged[border] then return end
		edged[border] = true
		Kit.Outline(border, 0, "outline", true)
		C.Hook(border, "SetBackdrop", function(self) Kit.Backdrop(self) end, "scenes:border")
	end

	local function DressScene(s)
		if not C.On() or not Widget(s) then return end
		for i = 1, #SCENE_BUTTONS do Button(Own(s, SCENE_BUTTONS[i])) end
		Check(Own(s, "batchAuto"))
		Check(Own(s, "batchNew"))
		local sh = Own(s, "showcase")
		if Widget(sh) then Button(Own(sh, "back")) end
		Piece(Own(s, "size"))
		Piece(Own(s, "shut"))
		Piece(Own(s, "bar"))
		Border(Own(s, "border"))
		-- (The hint's colors are Curator's: a gamble's note, an omen's rarity.)
		C.KeepInk(Own(s, "hint"))
		C.Text(Own(s, "hint"))
		C.Text(Own(s, "counter"))
		C.Text(Own(s, "summary"))
		-- (The contract ceremony is content too, should anything pass over it.)
		C.Content(Own(s, "ct"))
	end

	local function SceneSoon(s)
		ns.Queue("Curator:scene", function() DressScene(s) end, KEY)
	end

	C.Track("CuratorBoosterScene", function(s)
		-- The scene is content: only the pieces above are dressed, never a walk through it.
		C.Content(s)
		DressScene(s)
		C.Script(s, "OnShow", function() SceneSoon(s) end, "scenes:scene")
	end)

	-- Open all's pieces (made on the first batch, B:BatchBuild, which a click starts: the watch's
	-- burst after that click finds them before Curator first lays them out by their words' width).
	C.TrackBy(function()
		local s = _G.CuratorBoosterScene
		return s and Own(s, "batchNext")
	end, function() DressScene(_G.CuratorBoosterScene) end, NOAUTO)

	-- A revealed card looked at: its own panel of words and buttons (the core's whole pass; the
	-- card in it is content).
	C.TrackBy(function()
		local s = _G.CuratorBoosterScene
		return s and Own(s, "inspect")
	end, function(o)
		local info = Own(o, "info")
		if Widget(info) then C.KeepInk(Own(info, "rar")) end
	end)

	-- -----------------------------------------------------------------------------------------
	-- The booster bar: only its gold frame
	-- -----------------------------------------------------------------------------------------

	C.Track("CuratorBoosterBar", function(b)
		C.Content(b)
		local bar = Own(b, "bar")
		if not Widget(bar) then return end
		-- (Curator tints the frame for a dungeon; the fill, ring and medallion still say it.)
		Kit.Erase(Own(bar, "left"))
		Kit.Erase(Own(bar, "mid"))
		Kit.Erase(Own(bar, "right"))
		Kit.Outline(bar, 2, "bar")
	end)

	-- -----------------------------------------------------------------------------------------
	-- The toasts
	-- -----------------------------------------------------------------------------------------

	-- "Achievement earned": Curator writes it in black for the game's banner on every alert.
	local unlocking = false
	local function Unlock(fs)
		if unlocking or not C.On() then return end
		local r, g, b = fs:GetTextColor()
		if type(r) ~= "number" or r + g + b > 0.9 then return end
		local c = ns.Colors().LABEL
		if not c then return end
		unlocking = true
		fs:SetTextColor(c[1], c[2], c[3])
		unlocking = false
	end

	C.Track("CuratorToast", function(f)
		-- (Its alpha, scale and place are Curator's every frame; nothing here sets them.)
		C.Content(f)
		C.Content(Own(f, "trophy"))
		local l, a = Own(f, "loot"), Own(f, "ach")
		local icon, edge
		if Widget(l) then
			Kit.Erase(Own(l, "bg"))
			Kit.Erase(Own(l, "border"))
			Plate(l, 12, 12, 12, 12)
			icon = Own(l, "icon")
			if C.IsTexture(icon) then
				-- The item's edge, over its outer pixels, shown only while the icon is (a card
				-- found shows the card instead).
				edge = CreateFrame("Frame", nil, l)
				edge:SetAllPoints(icon)
				edge:SetFrameLevel(l:GetFrameLevel() + 2)
				edge:EnableMouse(false)
				Kit.Shell(edge, "outline")
				edge:SetShown(icon:IsShown())
			end
			C.Text(Own(l, "label"))
			-- (The name is in its quality's color.)
			C.KeepInk(Own(l, "name"))
			C.Text(Own(l, "name"))
			C.Text(Own(l, "line"))
		end
		if Widget(a) then
			Kit.Erase(Own(a, "bg"))
			Plate(a, 6, 16, 6, 14)
			local un = Own(a, "unlocked")
			if C.IsString(un) then
				C.KeepInk(un)
				C.Text(un)
				Unlock(un)
				C.Hook(un, "SetTextColor", Unlock, "scenes:unlock")
			end
			C.Text(Own(a, "name"))
		end
		-- Each alert is filled before the toast is shown (and it is hidden between two).
		if edge then
			C.Script(f, "OnShow", function() edge:SetShown(icon:IsShown()) end, "scenes:toast")
		end
	end)

	-- -----------------------------------------------------------------------------------------
	-- The full-screen celebrations: their buttons only
	-- -----------------------------------------------------------------------------------------

	C.Track("CuratorCinematic", function(f) C.Content(f) end)

	C.Track("CuratorLevelUp", function(f)
		C.Content(f)
		Button(Own(f, "go"))
	end)

	C.Track("CuratorAlbumComplete", function(f)
		C.Content(f)
		Button(Own(f, "open"))
		Button(Own(f, "go"))
	end)

	C.Track("CuratorOffers", function(f)
		C.Content(f)
		Button(Own(f, "later"))
		C.Text(Own(f, "hint"))
		C.Text(Own(f, "note"))
	end)

	-- (Its words in the player's text look, as the pallet scene's: Packs\CuratorMarket.lua.)
	C.Track("CuratorDisplayScene", function(f)
		C.Content(f)
		for _, k in ipairs({ "title", "sub", "have", "destLabel", "hint" }) do C.Text(Own(f, k)) end
		local ctl = Own(f, "ctl")
		if Widget(ctl) then Button(Own(ctl, "back")) end
	end)

	C.Track("CuratorRestoreReturn", function(f) C.Content(f) end)

	-- Its inspector (made on the first card clicked once the scene is ready): Back.
	C.TrackBy(function()
		local f = _G.CuratorRestoreReturn
		local ins = f and Own(f, "ins")
		return ins and Own(ins, "back")
	end, Button, NOAUTO)

	-- -----------------------------------------------------------------------------------------
	-- The small windows
	-- -----------------------------------------------------------------------------------------

	C.Track("CuratorRestorePanel", Dialog)
	C.Track("CuratorCasePanel", Dialog)

	-- The copy chooser's rows: the chip (its edge is the finish) kept, the game's check box art
	-- drawn as plain textures becomes a DaylightUI box with a light tick (Curator shows the tick).
	local rowsDone = setmetatable({}, { __mode = "k" })
	local function PickerRow(r)
		if rowsDone[r] then return end
		local check, tick, chip = Own(r, "check"), Own(r, "tick"), Own(r, "chip")
		if not (C.IsTexture(check) and C.IsTexture(tick) and Widget(chip)) then return end
		rowsDone[r] = true
		-- (Curator sizes the chip to its words: kept whole, even with the controls switch off.)
		C.Content(chip)
		if not ns.Controls(KEY) then return end
		check:SetAlpha(0)
		Kit.Outline(check, 0, "control", true, { noBackground = true })
		C.Tint(tick, "TEXT")
	end

	C.Track("CuratorCopyPicker", function(f)
		Dialog(f)
		EachChild(PickerRow, f:GetChildren())
	end)

	-- (Pieces Curator hangs on windows of the other areas are dressed with those windows: a case
	-- card's "See the certificate" (CuratorCrate.inspect.certBtn) by Packs\CuratorMarket.lua's
	-- watch on it, the reseller's Displays sale view (CuratorReseller.disp, built with the window
	-- inside its ground) by the windows area's pass over CuratorReseller, whose walk watches its
	-- pages being shown.)
end)
