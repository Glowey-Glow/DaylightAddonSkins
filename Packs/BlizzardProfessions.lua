-- Game windows: the game's profession window (ProfessionsFrame, Blizzard_Professions), the one
-- DaylightUI's own profession window (and Daylight Recipes' "The game's window" mode) leaves as the
-- game draws it. Built against this client's own interface code (wow-ui-source, branch "forever":
-- the Mainline Blizzard_Professions / Blizzard_ProfessionsTemplates / Blizzard_ProfessionsBook
-- files plus their Camelot overrides), so every name and key below is the game's. Follows the
-- "Game windows" switch of Packs\Blizzard.lua (same target key; that file registers no skin for
-- Blizzard_Professions, this one does, and no other pack may).
--   The window: DaylightUI's window shell, title on the left (clear of the X and of Daylight
--     Recipes' swap button beside it, which is never touched), the X; the profession tabs down
--     its right edge as clean icon tiles (the picked one in your accent).
--   The recipe page: the recipe list and the recipe form as quiet wells; the search box, the
--     filter dropdown with its reset badge, the list's scroll bar; the list's rows as plain
--     lines (soft hover, the picked recipe in your accent), category headers with a chevron and a
--     faint rule, the "Unlearned" divider; the skill bar as a DaylightUI bar in your accent; the
--     chat link button, the help button, the tool and gear slots; the form's output item, reagent
--     slots (quality edges kept), their checkboxes, the track / best-quality checkboxes; the
--     Create / Create All buttons (the game's red ones) and the count box.
--   Flyouts: the reagent picker (its items, Reset, undo, "hide unowned", scroll bar).
--   The professions book (on this client the same window with no trade skill open: K, the micro
--     menu): each profession card as a quiet panel, its skill bar, its spell buttons' edges.
--   A guild's crafters list ("View Crafters"), a recipe link's window (InspectRecipeFrame), and
--     the quality / output-log panels should the client ever show them.
-- Left alone on purpose (the game's own content): item and spell icons, quality and skill-up
-- difficulty colors (orange / yellow / green / gray), class colors, red "missing" and cooldown
-- text, the favorite star, the stars of a recipe's rank, the red "unlearn" X, the lock icons.
-- Hidden as DaylightUI hides it on Forever: the skill bar's expansion arrow (one expansion here).
-- Not on this client (its Camelot window has no tab bar): the Specializations and Crafting
-- Orders tabs, the maximize / minimize button (so the minimized view's search list never shows).
-- Tooltips, the right-click and filter menus and the unlearn popup are DaylightUI's own skins.
-- While DaylightUI's System skins are on (1.9.2 and later) they dress this window themselves, so
-- then only what they pass over is dressed here: the guild's crafters list, the output log, the
-- minimized search results and the quality picker, plus the reagent picker and the recipe link's
-- window as always.
--
-- Taint: ProfessionsFrame is a UI panel the game shows from secure code, and its OnShow casts a
-- profession spell (K / the micro menu: ProfessionsMixin:OnShow -> RecastSelectedProfession ->
-- C_SpellBook.CastSpellBookItem). The scripts of every frame inside it run inside that call, so the
-- whole window is silent, as Packs\Blizzard.lua does the spellbook: no OnShow, OnHide, OnEnable,
-- OnDisable or OnSizeChanged script of ours on the window or anything in it (no Kit.Window fade, no
-- walk, no Kit.Button / Kit.Check / Kit.EditBox / Kit.PageButton / Kit.ResetBadge, the side tiles
-- quiet). Only the mouse is hooked (enter, leave, press). Everything else follows the game from
-- post-hooks (hooksecurefunc) on its own methods, which run after the game's code and apart from
-- it, and from the lists' own callbacks (raised through securecallfunction). Nothing protected is
-- called, no size or place of the window set, no field of the game's written. The book's spell
-- buttons are secure: nothing is hooked or made on them (their edges are frames of ours on the
-- card).
-- Parked: DaylightUI (Win.Follow's veil) and Daylight Recipes (Take.lua's veil) hold this window
-- shown but see-through under a frame of theirs. Nothing is dressed or passed over while it's
-- held there (Really); it's dressed the first time it really shows, from the game's own refresh as
-- it opens or when it's handed to the screen (a post-hook on SetParent), out of combat. Its parent
-- is only ever read, never set.
local _, ns = ...
if not ns.ok then return end

local KEY = "Blizzard"   -- the "Game windows" target (Packs\Blizzard.lua)

local Usable, Guard = ns.Usable, ns.Guard
local ipairs, pairs, type, select, pcall = ipairs, pairs, type, select, pcall
local hooksecurefunc = hooksecurefunc

local Kit
local B                                             -- Packs\Blizzard.lua's shared builders (ns.Blizz)
local done = setmetatable({}, { __mode = "k" })     -- frames and pieces of ours already dressed
local rows = setmetatable({}, { __mode = "k" })     -- list row -> { pick, picked }
local accents = setmetatable({}, { __mode = "k" })  -- texture -> { alpha, fill }
local edges = setmetatable({}, { __mode = "k" })    -- book spell button -> its edge (ours)

local function On() return ns.Enabled(KEY) and ns.BlizzOn("professions") end
local function Controls() return ns.Controls(KEY) end

local function Once(x)
	if not Usable(x) or done[x] then return false end
	done[x] = true
	return true
end

local function Kind(x)
	if not Usable(x) then return nil end
	return x:GetObjectType()
end
local function IsTexture(x) return Kind(x) == "Texture" end

local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) end

-- Whether a window is really on screen: shown, and neither it nor what holds it see-through
-- (DaylightUI's and Daylight Recipes' veils are shown frames at alpha 0).
local function Really(f)
	if not Usable(f) or not f:IsVisible() then return false end
	local own = f:GetAlpha()
	if type(own) == "number" and not Secret(own) and own < 0.01 then return false end
	local p = f:GetParent()
	if Usable(p) and p ~= UIParent and p.GetEffectiveAlpha then
		local a = p:GetEffectiveAlpha()
		if type(a) == "number" and not Secret(a) and a < 0.01 then return false end
	end
	return true
end

-- The player's font on one string, its size kept (none yet: the game hasn't set it up).
local function FontOf(fs, size)
	if Kind(fs) ~= "FontString" then return end
	local ok, _, now = pcall(fs.GetFont, fs)
	if ok and type(now) == "number" and now > 0 then Kit.Font(fs, size) end
end

local function Ink(name)
	local c = ns.Colors()[name]
	if type(c) == "table" then return c[1], c[2], c[3] end
	return 1, 1, 1
end

local function Hide(t) if Usable(t) then Kit.Hide(t) end end

-- A texture in your accent (a fill: a plain shape; else a picture tinted), kept through
-- DaylightUI's style changes.
local function Accent(tex, alpha, fill)
	if not IsTexture(tex) then return end
	accents[tex] = { alpha or 1, fill }
	if fill then ns.FillAccent(tex, alpha, nil, KEY) else ns.PaintAccent(tex, alpha, nil, KEY) end
end

local BUTTON_ART = { "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }
local function ButtonArtOff(b)
	for _, get in ipairs(BUTTON_ART) do
		local t = b[get] and b[get](b)
		if IsTexture(t) then t:SetAlpha(0) end
	end
end

-- DaylightUI's own media folder (the Kit's erase mask lives there), for its X picture.
local function Media(file)
	local base = type(Kit.ERASE) == "string" and Kit.ERASE:gsub("mask%-none%.png$", "") or nil
	return base and (base .. file) or nil
end

-- ---------------------------------------------------------------------------------------------
-- Silent controls: the DaylightUI look drawn once, the game's own state art doing the rest, only
-- the mouse hooked.
-- ---------------------------------------------------------------------------------------------

local WASH = 0.08

-- A checkbox: the game's box art off, a small DaylightUI box (a frame of ours, no script) with the
-- game's own checked texture as an accent square inside it (the game shows and hides it itself).
local CHECK_BOX = 14
local function Check(cb)
	if Kind(cb) ~= "CheckButton" or not Once(cb) then return end
	local checked = cb.GetCheckedTexture and cb:GetCheckedTexture()
	ButtonArtOff(cb)
	local dis = cb.GetDisabledCheckedTexture and cb:GetDisabledCheckedTexture()
	if IsTexture(dis) then dis:SetAlpha(0) end
	local box = CreateFrame("Frame", nil, cb)
	box:SetSize(CHECK_BOX, CHECK_BOX)
	box:SetPoint("CENTER", cb, "CENTER", 0, 0)
	box:SetFrameLevel(math.max(0, cb:GetFrameLevel() - 1))
	box:EnableMouse(false)
	Kit.Shell(box, "control")
	if IsTexture(checked) then
		checked:SetAlpha(1)
		checked:ClearAllPoints()
		checked:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
		checked:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
		Accent(checked, 1, true)
	end
	local hl = cb.GetHighlightTexture and cb:GetHighlightTexture()
	if IsTexture(hl) then
		hl:SetColorTexture(1, 1, 1, WASH)
		hl:ClearAllPoints()
		hl:SetAllPoints(box)
		hl:SetAlpha(1)
	end
	local label = cb.Text or cb.text or cb.Label
	if Kind(label) == "FontString" then FontOf(label) end
end

-- A text button (the game's three-piece or three-slice art): Packs\Blizzard.lua's silent look.
-- Grayed buttons are dimmed from the game's own refresh (ButtonState below).
local function TextButton(b)
	if not Usable(b) or done[b] then return end
	done[b] = true
	B.StaticButton(Kit, b)
end

local function ButtonState(b)
	if not done[b] then return end
	local fs = b.GetFontString and b:GetFontString()
	-- (Grayed, the button takes its disabled font object: the player's font back on it.)
	if Kind(fs) == "FontString" then Kit.Refont(fs) end
	local s = Kit.ShellOf(b)
	if s then Kit.Paint(s, (b.IsEnabled and not b:IsEnabled()) and Kit.DISABLED_BORDER or nil) end
end

-- A small icon button (the chat link, the flyout's undo): the game's icon kept in DaylightUI's text
-- ink, its frame art off, a DaylightUI box round it (a frame of ours), a hover wash.
local function IconBox(b, icon, pad)
	if not Usable(b) or not IsTexture(icon) or not Once(b) then return end
	ButtonArtOff(b)
	Hide(b.Background)
	icon:SetAlpha(1)
	if icon.SetDesaturated then icon:SetDesaturated(true) end
	icon:SetVertexColor(Kit.TEXT[1], Kit.TEXT[2], Kit.TEXT[3])
	local box = CreateFrame("Frame", nil, b)
	box:SetPoint("TOPLEFT", b, "TOPLEFT", pad, -pad)
	box:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -pad, pad)
	box:SetFrameLevel(math.max(0, b:GetFrameLevel() - 1))
	box:EnableMouse(false)
	Kit.Shell(box, "control")
	if Kind(b) == "Button" then Kit.HoverWash(b, box) end
end

-- The filter's "reset" badge: its red art off, DaylightUI's X in the selected ink (lighter under the
-- mouse). The game shows and hides it.
local function ResetBadge(btn)
	if not Usable(btn) or not Once(btn) then return end
	ButtonArtOff(btn)
	for _, r in ipairs({ btn:GetRegions() }) do
		if IsTexture(r) then r:SetAlpha(0) end
	end
	local file = Media("ui-close.png")
	if not file then return end
	local x = btn:CreateTexture(nil, "OVERLAY")
	x:SetTexture(file)
	x:SetSize(Kit.BADGE_SIZE or 9, Kit.BADGE_SIZE or 9)
	x:SetPoint("CENTER", btn, "CENTER", 0, 0)
	local function paint(over)
		local s, t = Kit.SELECTED, over and 0.35 or 0
		x:SetVertexColor(s[1] + (1 - s[1]) * t, s[2] + (1 - s[2]) * t, s[3] + (1 - s[3]) * t, 1)
	end
	paint(false)
	ns.ScriptOnce(btn, "OnEnter", function() paint(true) end, KEY)
	ns.ScriptOnce(btn, "OnLeave", function() paint(false) end, KEY)
end

-- A panel inside the window (the quality picker, the output log): the silent window shell, its X,
-- its text buttons, its words.
local function Panel(f)
	if not Usable(f) or not Once(f) then return end
	B.ShellWindow(Kit, f)
	Hide(f.NineSlice)
	Kit.Close(f.ClosePanelButton or f.CloseButton)
	if Controls() then
		for _, k in ipairs({ "AcceptButton", "CancelButton" }) do TextButton(f[k]) end
		if Usable(f.ScrollBar) then Kit.ScrollBar(f.ScrollBar) end
	end
	ns.Words(f, 3)
end

-- ---------------------------------------------------------------------------------------------
-- List rows: the game's row art off, a soft hover wash (the HIGHLIGHT layer: no script of ours),
-- an accent wash while picked. picked(row) is read whenever the game changes the row.
-- ---------------------------------------------------------------------------------------------

local PICK = 0.18

local function PaintRow(row)
	local r = rows[row]
	if not r then return end
	local on = r.picked and r.picked(row) == true
	if on then
		ns.FillAccent(r.pick, PICK, nil, KEY)
		r.pick:Show()
	else
		r.pick:Hide()
	end
end

local function Row(row, picked)
	if rows[row] then return end
	for _, region in ipairs({ row:GetRegions() }) do
		if IsTexture(region) then region:SetAlpha(0) end
	end
	ButtonArtOff(row)
	local wash = row:CreateTexture(nil, "HIGHLIGHT")
	wash:SetColorTexture(1, 1, 1, WASH)
	wash:SetAllPoints(row)
	local pick = row:CreateTexture(nil, "BACKGROUND", nil, 7)
	pick:SetAllPoints(row)
	pick:Hide()
	rows[row] = { pick = pick, picked = picked }
	PaintRow(row)
end

-- A faint rule along a row's bottom (category headers).
local function Rule(row)
	local line = row:CreateTexture(nil, "ARTWORK")
	line:SetColorTexture(1, 1, 1, 0.07)
	line:SetHeight(1)
	line:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4, 1)
	line:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 1)
end

-- A scroll list's rows, dressed in the frame they're made and filled (the list's own callbacks:
-- the game raises them from securecallfunction, so nothing of ours runs inside its update).
local listed = setmetatable({}, { __mode = "k" })
local function List(box, acquired, initialized)
	if not Usable(box) or listed[box] or not box.RegisterCallback then return end
	listed[box] = true
	local SU = ScrollUtil
	if type(SU) ~= "table" then return end
	-- (The rows already there first, as made then filled. ScrollUtil's own "iterate existing" hands
	-- the frame where the callback takes its owner.)
	if box.ForEachFrame then
		pcall(box.ForEachFrame, box, function(frame)
			if acquired then Guard(acquired, frame) end
			if initialized then Guard(initialized, frame) end
		end)
	end
	if acquired and SU.AddAcquiredFrameCallback then
		SU.AddAcquiredFrameCallback(box, function(_, frame) Guard(acquired, frame) end, {})
	end
	if initialized and SU.AddInitializedFrameCallback then
		SU.AddInitializedFrameCallback(box, function(_, frame) Guard(initialized, frame) end, {})
	end
end

-- ---------------------------------------------------------------------------------------------
-- Item slots (ProfessionsButtonTemplate and the output icon): the Kit's item look, its edge in the
-- item's quality color. The game paints quality on the slot's own frame art (an atlas, white
-- vertex), which the Kit's item edge can't read, so the quality the game hands SetSlotQuality is
-- written onto the (hidden) frame art's color and the edge repainted from it.
-- ---------------------------------------------------------------------------------------------

local function QualityColor(q)
	if type(q) ~= "number" then return nil end
	local fn = _G.C_Item and _G.C_Item.GetItemQualityColor
	if type(fn) ~= "function" then return nil end
	local ok, r, g, b = pcall(fn, q)
	if ok and type(r) == "number" then return r, g, b end
	return nil
end

-- An item link's quality (nil while the game hasn't the item's data).
local function LinkQuality(link)
	local CI = _G.C_Item
	if not CI or type(link) ~= "string" then return nil end
	if type(CI.GetItemQualityByID) == "function" then
		local ok, q = pcall(CI.GetItemQualityByID, link)
		if ok and type(q) == "number" then return q end
	end
	if type(CI.GetItemInfo) == "function" then
		local ok, _, _, q = pcall(CI.GetItemInfo, link)
		if ok and type(q) == "number" then return q end
	end
	return nil
end

local function EdgeQuality(btn, q)
	local r, g, b = QualityColor(q)
	if r and IsTexture(btn.IconBorder) then btn.IconBorder:SetVertexColor(r, g, b) end
	Kit.SlotQuality(btn)
end

local function Slot(btn)
	if not Usable(btn) or not Once(btn) then return end
	Hide(btn.SlotBackground)
	Hide(btn.CropFrame)
	Hide(btn.NameFrame)
	if IsTexture(btn.Icon) and Usable(btn.CircleMask) then pcall(btn.Icon.RemoveMaskTexture, btn.Icon, btn.CircleMask) end
	Kit.Item(btn)
	if type(btn.SetSlotQuality) == "function" then
		ns.HookOnce(btn, "SetSlotQuality", function(self, q) Guard(EdgeQuality, self, q) end, KEY)
	end
	-- (The "pick this one" glow while a flyout is open: in your accent.)
	if IsTexture(btn.HighlightTexture) then Accent(btn.HighlightTexture, 0.6) end
end

-- ---------------------------------------------------------------------------------------------
-- The skill bar (ProfessionsRankBarTemplate: the crafting page's and each book card's): the game's
-- frame, background, animated fill and flare off; a DaylightUI bar of ours in their place, its
-- fill in your accent, set from the ratio the game's Update keeps; the rank words in your font.
-- ---------------------------------------------------------------------------------------------

local function BarValue(bar, sb)
	local ratio = bar.ratio
	sb:SetValue(type(ratio) == "number" and ratio or 0)
end

local function RankBar(bar)
	if not Usable(bar) or not Once(bar) then return end
	Hide(bar.Background)
	Hide(bar.Border)
	Hide(bar.Fill)
	-- (The flare fades in and out on its own: erased for good.)
	if IsTexture(bar.Flare) then Kit.Erase(bar.Flare) end
	local fill = bar.Fill
	local sb = CreateFrame("StatusBar", nil, bar)
	if IsTexture(fill) then
		sb:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, -2)
		sb:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT", 0, 2)
		local left = select(4, fill:GetPoint(1))
		sb:SetPoint("RIGHT", bar, "RIGHT", -(type(left) == "number" and left or 4), 0)
	else
		sb:SetAllPoints(bar)
	end
	sb:SetMinMaxValues(0, 1)
	sb:EnableMouse(false)
	sb:SetFrameLevel(bar:GetFrameLevel())
	-- (The rank words above our bar.)
	local rank = bar.Rank
	if Usable(rank) and rank:GetFrameLevel() <= sb:GetFrameLevel() then rank:SetFrameLevel(sb:GetFrameLevel() + 2) end
	Kit.StatusBar(sb)
	Accent(sb:GetStatusBarTexture(), 1)
	BarValue(bar, sb)
	if type(bar.Update) == "function" then
		ns.HookOnce(bar, "Update", function(self) BarValue(self, sb) end, KEY)
	end
	if Usable(rank) then FontOf(rank.Text) end
	-- The expansion arrow (one expansion on Forever): hidden and let through, as DaylightUI does.
	local arrow = bar.ExpansionDropdownButton
	if Usable(arrow) then
		Kit.Hide(arrow)
		arrow:EnableMouse(false)
	end
end

-- A small status bar (ProfessionsStatusBarArtTemplate: a category's rank in the recipe list, the
-- recipe level bar): the Kit's bar, its fill in your accent.
local function SmallBar(bar)
	if Kind(bar) ~= "StatusBar" or not Once(bar) then return end
	Kit.StatusBar(bar)
	-- (The game's blue bar color off, so the accent is the bar's own.)
	bar:SetStatusBarColor(1, 1, 1)
	Accent(bar:GetStatusBarTexture(), 1)
	FontOf(bar.Rank)
end

-- ---------------------------------------------------------------------------------------------
-- The recipe list's rows (ProfessionsRecipeListRecipeTemplate, ...CategoryTemplate,
-- ...DividerTemplate), dressed in the frame the list makes them (fonts first, so the game sizes
-- its labels in your font) and filled (colors and selection, every refill and scroll).
-- ---------------------------------------------------------------------------------------------

local function RecipePicked(row)
	local s = row.SelectedOverlay
	return IsTexture(s) and s:IsShown() == true
end

-- The game's label colors (learned / not learned; white under the mouse) in DaylightUI's inks.
local function RecipeInk(row, color)
	if color == _G.HIGHLIGHT_FONT_COLOR then return end
	local r, g, b = Ink(row.learned and "TEXT" or "OFF")
	if Kind(row.Label) == "FontString" then row.Label:SetVertexColor(r, g, b) end
	if Kind(row.Count) == "FontString" then row.Count:SetVertexColor(r, g, b) end
end

local chevrons = setmetatable({}, { __mode = "k" })   -- collapse button -> its chevron

local function PointChevron(btn)
	local c = chevrons[btn]
	if c then c:SetRotation(btn.collapsed and Kit.ROTATION.right or Kit.ROTATION.down) end
end

local fonted = setmetatable({}, { __mode = "k" })   -- rows whose words are in your font

local function RowFonts(row)
	if not Usable(row) or fonted[row] then return end
	fonted[row] = true
	if Kind(row.Label) == "FontString" then FontOf(row.Label) end
	if Kind(row.Count) == "FontString" then FontOf(row.Count) end
	if Usable(row.SkillUps) then FontOf(row.SkillUps.Text) end
	local title = row.ButtonText or row.Text
	if Kind(title) == "FontString" then FontOf(title) end
end

local function RecipeRow(row)
	if not Usable(row) then return end
	if Once(row) then
		RowFonts(row)
		if Usable(row.SkillUps) then
			-- A recipe row: its overlays off (their shown state still says which is picked).
			Row(row, RecipePicked)
			if type(row.SetSelected) == "function" then
				ns.HookOnce(row, "SetSelected", function(self) PaintRow(self) end, KEY)
			end
			if type(row.SetLabelFontColors) == "function" then
				ns.HookOnce(row, "SetLabelFontColors", function(self, color) Guard(RecipeInk, self, color) end, KEY)
			end
		elseif Usable(row.CollapseButton) then
			-- A category header: its bar art off, a rule under it, the +/- a chevron (mouse hooks only).
			Row(row, nil)
			Rule(row)
			if Controls() then
				chevrons[row.CollapseButton] = Kit.BareButton(row.CollapseButton, "down")
				if type(row.CollapseButton.UpdateCollapsedState) == "function" then
					ns.HookOnce(row.CollapseButton, "UpdateCollapsedState", PointChevron, KEY)
				end
			end
			SmallBar(row.RankBar)
			if type(row.CheckHighlightTitle) == "function" then
				-- (Under the mouse the game puts its highlight font object back on the title.)
				ns.HookOnce(row, "CheckHighlightTitle", function(self)
					Kit.Refont(self.ButtonText)
					Kit.InkGameText(self)
				end, KEY)
			end
		elseif Kind(row.Label) == "FontString" then
			-- The "Unlearned" divider: its gold rules faint.
			local r, g, b = Ink("LABEL")
			for _, region in ipairs({ row:GetRegions() }) do
				if IsTexture(region) then region:SetVertexColor(r, g, b, 0.35) end
			end
		end
	end
	-- Every fill: the colors the game just set, the pick, the chevron.
	if rows[row] then PaintRow(row) end
	if Usable(row.SkillUps) and type(row.GetLabelColor) == "function" then
		local ok, color = pcall(row.GetLabelColor, row)
		if ok then RecipeInk(row, color) end
	else
		Kit.InkGameText(row)
	end
	if Usable(row.CollapseButton) then PointChevron(row.CollapseButton) end
end

-- ---------------------------------------------------------------------------------------------
-- The recipe form (ProfessionsRecipeSchematicFormTemplate: the crafting page's and a recipe
-- link's window): its art off, a quiet well; the measured strings in your font before the game
-- sizes them; its checkboxes; the output item; on every Init, the reagent slots it shows and the
-- gold labels it sets.
-- ---------------------------------------------------------------------------------------------

local FORM_TEXT = { "OutputText", "RecraftingOutputText", "OutputSubText", "RequiredTools", "RecraftingRequiredTools",
	"Cooldown", "MinimizedCooldown", "Description", "RecraftingDescription" }
local FORM_PARTS = { "Reagents", "OptionalReagents", "FinishingReagents", "Concentrate", "FirstCraftBonus", "RecipeSourceButton" }

-- A checkbox the game placed by its label's width: placed again for the label in your font.
local function LabelRoom(cb)
	if not Usable(cb) or Kind(cb.Text) ~= "FontString" then return end
	local point, rel, relPoint, x, y = cb:GetPoint(1)
	if not point or type(x) ~= "number" or x >= 0 then return end
	local w = cb.Text:GetStringWidth()
	if type(w) ~= "number" or w <= 0 then return end
	cb:ClearAllPoints()
	cb:SetPoint(point, rel, relPoint, -(math.ceil(w) + 20), y)
end

local function ReagentSlot(slot)
	if not Usable(slot) then return end
	if Once(slot) then
		FontOf(slot.Name)
		Slot(slot.Button)
		if Controls() then Check(slot.Checkbox) end
		if Usable(slot.Checkmark) then Accent(slot.Checkmark.Check, 1) end
	end
end

local function Details(d)
	if not Usable(d) or not Once(d) then return end
	for _, k in ipairs({ "BackgroundTop", "BackgroundMiddle", "BackgroundBottom", "BackgroundMinimized" }) do Hide(d[k]) end
	Kit.Shell(d, "row")
	if IsTexture(d.Line) then
		local r, g, b = Ink("LABEL")
		d.Line:SetVertexColor(r, g, b, 0.35)
	end
	ns.Words(d, 3)
end

-- The window a form sits in, for Really (the form itself is parked with it).
local hostOf = setmetatable({}, { __mode = "k" })

-- Every Init: the slots it just made, the gold it just set. The slots are dressed even while the
-- window is held out of sight (they're made then); the inks only when it shows (Pass again).
local function FormInit(form)
	if not On() then return end
	local pool = form.reagentSlotPool
	if type(pool) == "table" and pool.EnumerateActive then
		for slot in pool:EnumerateActive() do ReagentSlot(slot) end
	end
	ReagentSlot(form.salvageSlot)
	ReagentSlot(form.enchantSlot)
	if not Really(hostOf[form]) then return end
	Kit.InkGameText(form)
	for _, k in ipairs(FORM_PARTS) do
		local part = form[k]
		if Usable(part) then
			if Kind(part.Label) == "FontString" then FontOf(part.Label) end
			if Kind(part.Text) == "FontString" then FontOf(part.Text) end
			Kit.InkGameText(part)
		end
	end
	if Usable(form.Details) and form.Details:IsShown() then Details(form.Details) end
end

local function Form(form, host)
	if not Usable(form) or not Once(form) then return end
	hostOf[form] = host
	Kit.Strip(form)
	Hide(form.NineSlice)
	Kit.Inset(form)
	for _, k in ipairs(FORM_TEXT) do FontOf(form[k]) end
	local out = form.OutputIcon
	if Usable(out) then
		if IsTexture(out.Icon) and Usable(out.CircleMask) then pcall(out.Icon.RemoveMaskTexture, out.Icon, out.CircleMask) end
		Kit.Item(out)
		done[out] = true
	end
	if Controls() then
		Check(form.TrackRecipeCheckbox)
		Check(form.AllocateBestQualityCheckbox)
		LabelRoom(form.TrackRecipeCheckbox)
		if Usable(form.RecipeLevelDropdown) then Kit.Dropdown(form.RecipeLevelDropdown) end
	end
	if Usable(form.recraftSlot) then
		Hide(form.recraftSlot.Background)
		Slot(form.recraftSlot.InputSlot)
		Slot(form.recraftSlot.OutputSlot)
	end
	SmallBar(form.RecipeLevelBar)
	Panel(form.QualityDialog)
	if type(form.Init) == "function" then
		ns.HookOnce(form, "Init", function(self) Guard(FormInit, self) end, KEY)
	end
	FormInit(form)
end

-- ---------------------------------------------------------------------------------------------
-- The reagent picker (ProfessionsFlyoutTemplate, one frame the game reuses, made by the game's
-- OpenProfessionsItemFlyout: dressed in the frame it opens. It is parented to the form it opens
-- from, so it is as silent as the window).
-- ---------------------------------------------------------------------------------------------

local function Flyout(fl)
	if not Usable(fl) then return end
	if Once(fl) then
		Kit.Backdrop(fl)
		Hide(fl.NineSlice)
		Kit.Shell(fl, "window", B.QUIET)
		FontOf(fl.Text)
		local undo = fl.UndoItem
		if Usable(undo) then
			Slot(undo)
			FontOf(undo.Text)
			if IsTexture(undo.Line) then
				local r, g, b = Ink("LABEL")
				undo.Line:SetVertexColor(r, g, b, 0.35)
			end
		end
		if Controls() then
			if Usable(fl.UndoButton) then IconBox(fl.UndoButton, fl.UndoButton.Icon, 0) end
			if Usable(fl.ScrollBar) then Kit.ScrollBar(fl.ScrollBar) end
			Check(fl.HideUnownedCheckbox)
		end
		List(fl.ScrollBox, Slot, nil)
	end
	ns.Words(fl, 2)
end

-- ---------------------------------------------------------------------------------------------
-- Guild crafters ("View Crafters": ProfessionsGuildListingTemplate on the crafting page)
-- ---------------------------------------------------------------------------------------------

local function GuildRow(row)
	if not Usable(row) then return end
	if Once(row) then
		Row(row, nil)
		-- (The button puts its own font object back on hover and when grayed.)
		ns.ScriptOnce(row, "OnEnter", function(self) Kit.Refont(self.Text) end, KEY)
		ns.ScriptOnce(row, "OnLeave", function(self) Kit.Refont(self.Text) end, KEY)
	end
	Kit.Refont(row.Text)
end

local function Guild(g)
	if not Usable(g) or not Once(g) then return end
	Kit.Strip(g)
	Hide(g.NineSlice)
	Kit.Backdrop(g)
	Kit.Shell(g, "window", B.QUIET)
	local box = g.Container
	if Usable(box) then
		Kit.Backdrop(box)
		Hide(box.NineSlice)
		Kit.Strip(box)
		if Controls() and Usable(box.ScrollBar) then Kit.ScrollBar(box.ScrollBar) end
		List(box.ScrollBox, nil, GuildRow)
	end
	FontOf(g.Title)
	Kit.InkGameText(g)
end

-- ---------------------------------------------------------------------------------------------
-- The craft results (ProfessionsCraftingOutputLogTemplate; this client never opens it on its own)
-- ---------------------------------------------------------------------------------------------

local function LogRow(row)
	if not Usable(row) then return end
	local box = row.ItemContainer
	if Once(row) and Usable(box) then
		for _, k in ipairs({ "NameFrame", "BorderFrame", "HighlightNameFrame", "PushedNameFrame" }) do Hide(box[k]) end
		Slot(box.Item)
		FontOf(box.Text)
		FontOf(box.CritText)
		if type(row.Rows) == "table" then
			for _, extra in ipairs(row.Rows) do
				Hide(extra.Bracket)
				Slot(extra.Item)
				FontOf(extra.Text)
			end
		end
	end
	local pool = row.itemButtonPool
	if type(pool) == "table" and pool.EnumerateActive then
		for b in pool:EnumerateActive() do Slot(b) end
	end
end

local function OutputLog(log)
	if not Usable(log) then return end
	Panel(log)
	List(log.ScrollBox, nil, LogRow)
end

-- ---------------------------------------------------------------------------------------------
-- The professions book page (ProfessionsBookFrameTemplate, Camelot: two primary cards, three
-- secondary ones). Each card a quiet panel (on a frame of ours inside it: the game's cards
-- overlap by their art's margin), its skill bar ours, its words in DaylightUI's inks. The spell
-- buttons are secure: their art is faded and recolored, nothing hooked or made on them; their
-- edges (frames of ours on the card) follow the buttons' shown state from the book's Update.
-- ---------------------------------------------------------------------------------------------

local CARDS = { "PrimaryProfession1", "PrimaryProfession2", "SecondaryProfession1", "SecondaryProfession2", "SecondaryProfession3" }

-- The game's highlight on a spell button (UpdateButton sets its picture again each update): a
-- faint wash over the icon.
local function SpellWash(btn)
	local hl = btn.highlightTexture
	if IsTexture(hl) then hl:SetColorTexture(1, 1, 1, WASH) end
end

local function SpellButton(card, btn)
	if not Usable(btn) or not Once(btn) then return end
	Hide(btn.IconBorder)
	Hide(btn.IconTextureOverlay)
	local icon = btn.IconTexture
	if IsTexture(icon) then
		local edge = CreateFrame("Frame", nil, card)
		edge:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
		edge:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
		edge:SetFrameLevel(btn:GetFrameLevel() + 1)
		edge:EnableMouse(false)
		Kit.Shell(edge, "outline")
		edge:SetShown(btn:IsShown())
		edges[btn] = edge
		local hl = btn.highlightTexture
		if IsTexture(hl) then
			hl:ClearAllPoints()
			hl:SetAllPoints(icon)
		end
		SpellWash(btn)
	end
	FontOf(btn.spellString)
	FontOf(btn.subSpellString)
end

-- A spell name too long for its two lines in your font: a size smaller, then one more.
local function FitSpellName(fs)
	if Kind(fs) ~= "FontString" or not fs.IsTruncated then return end
	for _ = 1, 2 do
		if not fs:IsTruncated() then return end
		local ok, _, size = pcall(fs.GetFont, fs)
		if not (ok and type(size) == "number" and size > 9) then return end
		Kit.Font(fs, size - 1)
	end
end

-- The gold the game puts on spell names back in our ink.
local function SpellInk(btn)
	local fs = btn.spellString
	if Kind(fs) ~= "FontString" then return end
	local r, g, b = fs:GetTextColor()
	local gold = _G.NORMAL_FONT_COLOR
	if type(r) == "number" and not Secret(r) and gold and math.abs(r - gold.r) < 0.03 and math.abs(g - gold.g) < 0.03
		and math.abs(b - gold.b) < 0.03 then
		fs:SetTextColor(Ink("TEXT"))
	end
	FitSpellName(fs)
end

-- After every book update: the edges follow the spell buttons the game showed or hid (always:
-- an empty edge would linger), the rest only while the window really shows.
local function BookUpdate(page, host)
	local content = page.ProfessionsContentFrame
	if not Usable(content) then return end
	local inks = Really(host) and not InCombatLockdown()
	for _, k in ipairs(CARDS) do
		local card = content[k]
		if Usable(card) and type(card.spellButtons) == "table" then
			for _, btn in ipairs(card.spellButtons) do
				local edge = edges[btn]
				if edge then edge:SetShown(btn:IsShown()) end
				if inks then
					SpellWash(btn)
					SpellInk(btn)
				end
			end
		end
		if inks and Usable(card) then
			Hide(card.Background)
			Kit.InkGameText(card)
			if Kind(card.ProfessionName) == "FontString" then card.ProfessionName:SetTextColor(Ink("VALUE")) end
		end
	end
end

local function Book(page, host)
	if not Usable(page) or not Once(page) then return end
	local content = page.ProfessionsContentFrame
	if not Usable(content) then return end
	for _, k in ipairs(CARDS) do
		local card = content[k]
		if Usable(card) then
			Hide(card.Background)
			local box = CreateFrame("Frame", nil, card)
			box:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -4)
			box:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -4, 4)
			box:SetFrameLevel(math.max(0, card:GetFrameLevel() - 1))
			box:EnableMouse(false)
			Kit.Shell(box, "row")
			for _, fk in ipairs({ "ProfessionName", "specialization", "missingHeader", "missingText" }) do FontOf(card[fk]) end
			RankBar(card.StatusBar)
			if type(card.spellButtons) == "table" then
				for _, btn in ipairs(card.spellButtons) do SpellButton(card, btn) end
			end
		end
	end
	if type(page.Update) == "function" then
		hooksecurefunc(page, "Update", function(self) if On() then Guard(BookUpdate, self, host) end end)
	end
	BookUpdate(page, host)
end

-- ---------------------------------------------------------------------------------------------
-- The crafting page (ProfessionsCraftingPageTemplate)
-- ---------------------------------------------------------------------------------------------

-- The help button sat on the portrait the window look takes off: a plain "i" where the portrait
-- was, left of the skill bar.
local function Help(btn, page)
	if not Usable(btn) or not Once(btn) then return end
	Hide(btn.Ring)
	for _, k in ipairs({ "I", "BigIPulse" }) do
		if IsTexture(btn[k]) then btn[k]:SetSize(22, 22) end
	end
	btn:ClearAllPoints()
	btn:SetPoint("CENTER", page, "TOPLEFT", 30, -50)
end

-- Text buttons the game sizes for its own font (Create, Create All, View Crafters): wide enough for
-- their words in yours (only ever wider), dimmed while grayed.
local FIT_ROOM = 24
local function Fit(b)
	if not Usable(b) then return end
	ButtonState(b)
	local fs = b.GetFontString and b:GetFontString()
	if Kind(fs) ~= "FontString" then return end
	local w = fs:GetStringWidth()
	if type(w) == "number" and w + FIT_ROOM > b:GetWidth() then b:SetWidth(math.ceil(w + FIT_ROOM)) end
end

local frame          -- ProfessionsFrame, once its addon has loaded

local function FitAll(page)
	-- (Not while the window is held out of sight: done again as it shows, from Pass.)
	if not Really(frame) then return end
	Fit(page.CreateButton)
	Fit(page.CreateAllButton)
	Fit(page.ViewGuildCraftersButton)
end

local function Crafting(page, host)
	if not Usable(page) or not Once(page) then return end
	Kit.Strip(page)
	local list = page.RecipeList
	if Usable(list) then
		Kit.Inset(list)
		Hide(list.BackgroundNineSlice)
		FontOf(list.NoResultsText)
		if Controls() then
			B.StaticEditBox(Kit, list.SearchBox)
			if Usable(list.FilterDropdown) then
				Kit.Dropdown(list.FilterDropdown)
				ResetBadge(list.FilterDropdown.ResetButton)
			end
			if Usable(list.ScrollBar) then Kit.ScrollBar(list.ScrollBar) end
		end
		List(list.ScrollBox, RowFonts, RecipeRow)
	end
	Form(page.SchematicForm, host)
	if Usable(page.GearSlotDivider) then
		local div = page.GearSlotDivider
		Kit.Strip(div)
		local line = div:CreateTexture(nil, "ARTWORK")
		line:SetColorTexture(1, 1, 1, 0.12)
		line:SetWidth(1)
		line:SetPoint("TOP", div, "TOP", 0, -4)
		line:SetPoint("BOTTOM", div, "BOTTOM", 0, 4)
	end
	for _, k in ipairs({ "Prof0ToolSlot", "Prof0Gear0Slot", "Prof0Gear1Slot", "Prof1ToolSlot", "Prof1Gear0Slot",
		"Prof1Gear1Slot", "CookingToolSlot", "CookingGear0Slot", "FishingToolSlot" }) do
		if Usable(page[k]) then Kit.Item(page[k]) end
	end
	RankBar(page.RankBar)
	if Usable(page.ConcentrationDisplay) then FontOf(page.ConcentrationDisplay.Amount) end
	if Controls() then
		Help(page.TutorialButton, page)
		-- The chat link button: the game's chain icon kept, in a DaylightUI box.
		if Usable(page.LinkButton) then IconBox(page.LinkButton, page.LinkButton.Icon, 2) end
		for _, k in ipairs({ "CreateButton", "CreateAllButton", "ViewGuildCraftersButton" }) do TextButton(page[k]) end
		-- The count box and its - and + (bare chevrons: the mouse only).
		local count = page.CreateMultipleInputBox
		if Usable(count) then
			B.StaticEditBox(Kit, count)
			-- (It's a NumericInputSpinnerTemplate over InputBoxTemplate: both draw their own left,
			-- middle and right border pieces, and the spinner's take the names, so the inherited set
			-- is only reachable among its regions. Every border texture of its own goes; the text
			-- and DaylightUI's shell, a child frame, stay.)
			for _, r in ipairs({ count:GetRegions() }) do
				if IsTexture(r) and r:GetDrawLayer() == "BACKGROUND" then Hide(r) end
			end
			-- (The game left-aligns the number for its old border; in DaylightUI's box it sits centered.)
			if count.SetJustifyH then count:SetJustifyH("CENTER") end
			if count.SetTextInsets then count:SetTextInsets(0, 0, 0, 0) end
			if Usable(count.DecrementButton) then Kit.BareButton(count.DecrementButton, "left") end
			if Usable(count.IncrementButton) then Kit.BareButton(count.IncrementButton, "right") end
		end
		B.StaticEditBox(Kit, page.MinimizedSearchBox)
		if type(page.ValidateControls) == "function" then
			ns.HookOnce(page, "ValidateControls", function(self) if On() then Guard(FitAll, self) end end, KEY)
		end
	end
	Guild(page.GuildFrame)
	OutputLog(page.CraftingOutputLog)
	Panel(page.MinimizedSearchResults)
end

-- ---------------------------------------------------------------------------------------------
-- The window
-- ---------------------------------------------------------------------------------------------

-- Beside the X other addons put their own controls in a row, each anchored to the one on its
-- right: DaylightUI 1.8.4's "Daylight UI window" link, Daylight Recipes' swap button (20 px, left of
-- the link when that shows). The title stops short of the leftmost one shown, measured each time
-- the window opens (and again once those addons have placed theirs). Nothing of theirs touched.
local SWAP_ROOM = 26   -- before the window has a size: room for Recipes' button
local TITLE_GAP = 6

local function BesideClose(f, right)
	for i = 1, select("#", f:GetChildren()) do
		local c = select(i, f:GetChildren())
		if c ~= right and Usable(c) and c:IsShown() and c.GetNumPoints and c:GetNumPoints() > 0 then
			local point, rel = c:GetPoint(1)
			if point == "RIGHT" and rel == right then return c end
		end
	end
	return nil
end

local function FitTitle(f)
	local title = f.TitleContainer and f.TitleContainer.TitleText
	if Kind(title) ~= "FontString" or not Usable(f.CloseButton) or InCombatLockdown() then return end
	local room = Kit.TITLE_RIGHT
	local fr = f:GetRight()
	if fr then
		-- (In screen pixels, each in its own scale: plain numbers, never secret.)
		local fs = f:GetEffectiveScale()
		local left, at = nil, f.CloseButton
		for _ = 1, 6 do
			at = BesideClose(f, at)
			if not at then break end
			local l = at:GetLeft()
			if l then left = l * at:GetEffectiveScale() end
		end
		if left and fs and fs > 0 then
			room = math.max(room, (fr * fs - left) / fs + TITLE_GAP)
		end
	else
		room = Kit.TITLE_RIGHT + SWAP_ROOM
	end
	title:SetPoint("TOPRIGHT", f, "TOPRIGHT", -room, -Kit.TITLE_TOP)
end

local function FitTitleSoon(f)
	FitTitle(f)
	-- (Daylight Recipes places its button a frame after the window opens, and again at 0.3 s.)
	C_Timer.After(0, function() Guard(FitTitle, f) end)
	C_Timer.After(0.35, function() Guard(FitTitle, f) end)
end

local function TabPicked(tab)
	local s = tab.SelectedTexture
	return IsTexture(s) and s:IsShown() == true
end

-- (The game crops and sizes the icon again on every SetChecked.)
local TILE_CROP = 0.08
local function TabChecked(tab)
	if IsTexture(tab.Icon) then tab.Icon:SetTexCoord(TILE_CROP, 1 - TILE_CROP, TILE_CROP, 1 - TILE_CROP) end
	ns.SideTilesPaintSoon()
end

local SIDE_ART = { "Background", "SelectedTexture", "HighlightTexture" }
local function SideTab(tab)
	if not Usable(tab) or not IsTexture(tab.Icon) or not Once(tab) then return end
	for _, k in ipairs(SIDE_ART) do Hide(tab[k]) end
	-- (Its glow is animated in and out: erased for good.)
	if IsTexture(tab.TabGlow) then Kit.Erase(tab.TabGlow) end
	-- (Quiet: no script on its showing; repainted from the game's SetChecked, which the window's
	-- own refresh calls on every tab as it opens.)
	if not ns.SideTile(tab, { picked = TabPicked, key = KEY, pad = 2, quiet = true }) then return end
	if type(tab.SetChecked) == "function" then
		ns.HookOnce(tab, "SetChecked", function(self) Guard(TabChecked, self) end, KEY)
	end
end

-- What follows the game each time the window really shows (also its first dressing's end).
local function Pass(f)
	if not Really(f) or InCombatLockdown() then return end
	local page = f.CraftingPage
	if Usable(page) and page:IsShown() then
		FitAll(page)
		if Usable(page.SchematicForm) then FormInit(page.SchematicForm) end
	end
	if Usable(f.BookPage) and f.BookPage:IsShown() then BookUpdate(f.BookPage, f) end
	for row in pairs(rows) do PaintRow(row) end
	ns.SideTilesPaintSoon()
	FitTitleSoon(f)
end

-- DaylightUI's System skins dress this window themselves whenever it shows as itself (their
-- "professions" skin, there in 1.9.2: the window look, its controls, the side tabs as icon tabs,
-- Create / Create All / View Crafters as buttons, the book's cards, the output item). Dressed here
-- too it drew a second outline on every side tab, a second box and hover on those buttons, and so
-- on. While those skins are on, only the panels they pass over are dressed here.
local function DaylightDresses()
	return ns.DaylightAtLeast(1, 9, 2) and ns.DaylightDressesGame("system")
end

local function DaylightExtras(f)
	local page = f.CraftingPage
	if not Usable(page) then return end
	Guild(page.GuildFrame)
	OutputLog(page.CraftingOutputLog)
	Panel(page.MinimizedSearchResults)
	local form = page.SchematicForm
	if Usable(form) then Panel(form.QualityDialog) end
end

local function Dress(f)
	if not Usable(f) then return end
	if done[f] then Pass(f) return end
	-- (Not while it's held out of sight, nor in a fight.)
	if not On() or InCombatLockdown() or not Really(f) then return end
	if DaylightDresses() then
		DaylightExtras(f)
		return
	end
	done[f] = true
	B.ShellWindow(Kit, f)
	Kit.Close(f.CloseButton)
	FitTitle(f)
	Crafting(f.CraftingPage, f)
	Book(f.BookPage, f)
	if Controls() then
		SideTab(f.ProfessionsOverviewTab)
		if type(f.rightProfessionTabs) == "table" then
			for _, tab in ipairs(f.rightProfessionTabs) do SideTab(tab) end
		end
	end
	ns.Words(f, 1)
	Pass(f)
end

-- A recipe link's window (InspectRecipeFrame, same addon; shown from a link click): the same
-- silent look.
local function Inspect(f)
	if not Usable(f) or done[f] then return end
	done[f] = true
	B.ShellWindow(Kit, f)
	Kit.Close(f.CloseButton)
	Form(f.SchematicForm, f)
end

-- ---------------------------------------------------------------------------------------------
-- When: Blizzard_Professions loads (on demand: the first profession or K). The window is dressed
-- the first time it really shows: from the game's own RefreshRightTabs (its OnShow calls it, and
-- a profession's opening or closing) and from SetParent (DaylightUI or Daylight Recipes handing
-- it to the screen), next frame and out of combat. The reagent picker in the frame it opens.
-- ---------------------------------------------------------------------------------------------

-- (Next frame, once however often it's asked; ns.Queue waits out a fight.)
local function DressQueued()
	if not frame or not On() or not ns.Kit then return end
	ns.OutOfCombat(function() Guard(Dress, frame) end)
end
local function Soon()
	ns.Queue("Blizzard:professions", DressQueued, KEY)
end

local hooked = false
local function Hooks(f)
	if hooked then return end
	hooked = true
	if Usable(f) then
		for _, m in ipairs({ "RefreshRightTabs", "SetParent" }) do
			if type(f[m]) == "function" then hooksecurefunc(f, m, Soon) end
		end
	end
	if type(_G.OpenProfessionsItemFlyout) == "function" then
		ns.HookOnce(nil, "OpenProfessionsItemFlyout", function(_, _, behavior)
			if not On() or type(behavior) ~= "table" or InCombatLockdown() then return end
			Guard(Flyout, behavior.flyout)
		end, KEY)
	end
	local P = _G.Professions
	if type(P) == "table" and type(P.SetupOutputIcon) == "function" then
		ns.HookOnce(P, "SetupOutputIcon", function(btn, _, info)
			if not On() or not done[btn] or type(info) ~= "table" or not info.hyperlink then return end
			Guard(EdgeQuality, btn, LinkQuality(info.hyperlink))
		end, KEY)
	end
end

local function Repaint()
	for row in pairs(rows) do PaintRow(row) end
	for tex, a in pairs(accents) do
		if a[2] then ns.FillAccent(tex, a[1], nil, KEY) else ns.PaintAccent(tex, a[1], nil, KEY) end
	end
end
ns.me.On("StyleChanged", function() if Kit then Guard(Repaint) end end)

ns.Pack("Blizzard_Professions", nil, function(K)
	Kit = K
	B = ns.Blizz
	if not On() or type(B) ~= "table" then return end
	local function Setup(f)
		if frame or not Usable(f) then return end
		frame = f
		ns.OutOfCombat(function()
			Guard(Hooks, frame)
			Guard(Inspect, _G.InspectRecipeFrame)
			Guard(Dress, frame)
		end)
	end
	-- DaylightUI can start this skin before the game has made ProfessionsFrame (seen in game: the
	-- addon counts as loaded, the window isn't there yet). Then it's looked for by name until it
	-- turns up, and set up the moment it does.
	if _G.ProfessionsFrame then
		Setup(_G.ProfessionsFrame)
	else
		ns.Watch(KEY, "ProfessionsFrame", function(f) Setup(f) end)
	end
end)
