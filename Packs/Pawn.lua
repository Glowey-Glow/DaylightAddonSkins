-- Pawn: its window, its string dialogs, its buttons on other windows and its loot callouts in the
-- DaylightUI look. Built against Pawn 2.14.4 (Forever build: Pawn.toc, PawnUI.xml, PawnUI.lua).
-- Pawn makes its window and dialogs from XML at load, so they're dressed at once (out of combat),
-- before they're ever drawn; the parts it builds later are dressed from post-hooks on the Pawn
-- functions that build them (no polling).
-- Dressed here:
--   * The window (PawnUIFrame): its painted backdrop gives way to the window shell (its own
--     opacity, border and bevel when it has a look of its own) with the accent line; the small X;
--     the header (scale names keep their own color) in the value ink. Its logo stays.
--   * The seven tabs under it (PanelTabButtonTemplate) as DaylightUI's tabs, the picked one marked
--     (the game's PanelTemplates_SetTab, which Pawn calls, moves the mark); refitted to the
--     player's font.
--   * Every control of the game's templates in it, by DaylightUI's walk (again on every page
--     shown): buttons (UIPanelButtonTemplate, the grey Reset button too), checkboxes and radio
--     buttons (UICheckButtonTemplate, UIRadioButtonTemplate) as switches with their words (Pawn's
--     own "_Label" strings) in the text ink, the value and gem level boxes (InputBoxTemplate),
--     the scroll bars (UIPanelScrollFrameTemplate, the stat list's FauxScrollFrameTemplate).
--   * Its gold words in DaylightUI's inks, its blue headings (stat list and gem headers, the
--     compare tab's section heads) in the label ink, its silver "not in this scale" words in the
--     off ink: through font objects of ours on its list rows (it swaps their font object on every
--     refresh, so they're put back from the same refresh), the walk's inks elsewhere.
--   * Lists: the scale list (rebuilt on every refresh), the stat list (20 rows it refills as it
--     scrolls), the compare lines and the gem lines (made anew on every compare / gem pass): the
--     blue hover bar a faint white wash, the picked scale's and stat's blue bar the accent wash.
--   * The Automatic / Manual buttons (a PvP queue's art): DaylightUI's control box, the picked one
--     edged in the accent, hover lighter. The scale color swatch: its gold round frame off, an
--     outline round the color, lighter on hover.
--   * The compare tab: item slots and shortcut slots as icons in an edge (item art cropped, the
--     empty-slot art a dark well), the clear button DaylightUI's reset glyph, its gold bars and
--     banner quiet washes, its dividers faint 1 px lines; the winning side's glow in the good ink.
--   * The two string dialogs (rename, import, export...): window shell, buttons, boxes, the
--     multi-line box's frame an inset.
--   * Its "Pawn" buttons on the character, inspect and socketing windows and its settings page:
--     DaylightUI buttons reading "Pawn" (its picture button art can't sit inside one).
--   * The loot roll callouts (PawnUI_LootUpgradeAdvisor1-4): window shell instead of the glow
--     box, the pointer arrow off.
-- Kept as Pawn draws them (they carry meaning): scale colors, item quality colors, the red and
-- green differences, upgrade arrows (bags, quests, loot history, the compare tab), spec and gem
-- icons, its logo and Mr. Robot's.
-- Not here: Pawn's lines in item tooltips and its tooltip icons (DaylightUI's tooltips), the color
-- picker (the game's, Game windows), its glow hint tooltips on the socketing window (the game's
-- help-tip look, made inside the game's socketing refresh), the settings page's other words (the
-- Game settings window pack walks addon pages). Bag upgrade arrows: DaylightUI's bags already
-- show Pawn's arrows through Pawn's own third-party bag API, so nothing is handed over.
local _, ns = ...
if not ns.ok then return end

local KEY = "Pawn"
-- (Its words are the game's font objects and its own copies of them: the player's font goes on all.)
local CAPS = { window = true, controls = true, text = true, shadow = true, font = "daylight" }
ns.Target(KEY, "Pawn", CAPS)

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

-- A blue (or gold) game bar: a faint white wash, plain blending.
local function Wash(tex, alpha)
	if not IsTexture(tex) then return end
	tex:SetColorTexture(1, 1, 1, alpha)
	tex:SetBlendMode("BLEND")
end

-- Work that changes Pawn's frames waits for the end of a fight (once per job).
local waiting = {}
local function Later(job, fn)
	if not InCombatLockdown() then
		Guard(fn)
		return
	end
	if waiting[job] then return end
	waiting[job] = true
	ns.OutOfCombat(function()
		waiting[job] = nil
		if On() then fn() end
	end)
end

-- ---------------------------------------------------------------------------------------------
-- Font objects. Its list rows (scales, stats) take their font object anew on every refresh, so
-- each row's font objects become copies of ours: the player's font (its text look) and an ink.
-- ---------------------------------------------------------------------------------------------

-- The ink each of its font objects becomes (by name); one not listed keeps its color.
local INK = {
	GameFontNormal = "LABEL", GameFontNormalSmall = "LABEL", GameFontNormalLarge = "LABEL",
	GameFontHighlight = "TEXT", GameFontHighlightSmall = "TEXT", GameFontHighlightLarge = "VALUE",
	PawnFontBlue = "LABEL", PawnFontBlueSmall = "LABEL",
	PawnFontSilver = "OFF", PawnFontSilverTiny = "OFF", PawnFontSilverLarge = "LABEL",
}

local fonts, ours = {}, setmetatable({}, { __mode = "k" })
local function FontLike(base, ink)
	if type(base) ~= "table" or not base.GetName then return nil end
	local baseName = base:GetName() or "Anon"
	ink = ink or INK[baseName]
	local name = "DaylightAddonSkinsPawn" .. (ink or "Own") .. baseName
	local f = fonts[name]
	if f then return f end
	f = CreateFont(name)
	f:CopyFontObject(base)
	local path, size, flags = base:GetFont()
	if path and size and not ns.PlainText(KEY) then f:SetFont(ns.FontFor(KEY, path, size, flags)) end
	local c = ink and ns.Colors()[ink]
	if c then f:SetTextColor(c[1], c[2], c[3]) end
	fonts[name] = f
	ours[f] = true
	return f
end

local STATES = {
	{ "GetNormalFontObject", "SetNormalFontObject" },
	{ "GetHighlightFontObject", "SetHighlightFontObject", "VALUE" },
	{ "GetDisabledFontObject", "SetDisabledFontObject" },
}

-- One list row (PawnUIFrame_Generic_ItemTemplate): its font objects ours, its blue hover a wash.
local function ListRow(btn)
	if Kind(btn) ~= "Button" then return end
	for _, s in ipairs(STATES) do
		local get, set = btn[s[1]], btn[s[2]]
		local obj = get and get(btn)
		if obj and not ours[obj] then
			local mine = FontLike(obj, s[3])
			if mine then set(btn, mine) end
		end
	end
	if ns.Once(btn) and btn.GetHighlightTexture then Wash(btn:GetHighlightTexture(), 0.06) end
end

-- ---------------------------------------------------------------------------------------------
-- Pieces
-- ---------------------------------------------------------------------------------------------

local TEX = "Interface\\AddOns\\Pawn\\Textures\\"
local artOf      -- file id -> what it is (rule, bar, banner, glow)

local function ArtIn(frame)
	if not Usable(frame) or not frame.GetRegions then return end
	artOf = artOf or ns.FileIDs({ [TEX .. "HorizontalBar"] = "rule", [TEX .. "CompareBar"] = "bar",
		[TEX .. "CompareBanner"] = "banner", [TEX .. "CompareBarLeft"] = "glow", [TEX .. "CompareBarRight"] = "glow" })
	for _, r in ipairs({ frame:GetRegions() }) do
		if IsTexture(r) then
			local ok, id = pcall(r.GetTexture, r)
			local what = ok and id ~= nil and (artOf[id] or (type(id) == "string" and artOf[string.lower(id)]))
			if what == "rule" then
				r:SetColorTexture(1, 1, 1, 0.08)
			elseif what == "bar" then
				r:SetColorTexture(1, 1, 1, 0.04)
			elseif what == "banner" then
				r:SetAlpha(0)
			elseif what == "glow" then
				-- The winning side: its glow in the good ink.
				r:SetDesaturated(true)
				local c = ns.Colors().GOOD
				if c then r:SetVertexColor(c[1], c[2], c[3], 0.6) end
			end
		end
	end
end

-- A checkbox's or radio button's words: Pawn's own "<name>_Label" string inside it (the walk
-- doesn't go into a control it dressed).
local labeled = setmetatable({}, { __mode = "k" })
local function CheckLabel(cb, Kit)
	local name = cb.GetName and cb:GetName()
	local label = type(name) == "string" and _G[name .. "_Label"]
	if Kind(label) ~= "FontString" then return end
	ns.FollowFont(label, KEY)
	if not labeled[label] then
		labeled[label] = true
		Kit.Light(label)
	end
end

-- A frame with a painted backdrop inside the window (the stat list's box, the multi-line box's
-- frame): an inset.
local function Well(frame, Kit)
	if not Usable(frame) or not frame.GetBackdrop or not frame:GetBackdrop() or not ns.Once(frame) then return end
	ns.NoBackdrop(frame)
	Kit.Inset(frame)
end

-- What the walk hands every frame it passes.
local function Each(frame, Kit, root)
	ArtIn(frame)
	if frame ~= root then Well(frame, Kit) end
	if frame.GetChildren then
		for _, c in ipairs({ frame:GetChildren() }) do
			if Kind(c) == "CheckButton" then CheckLabel(c, Kit) end
		end
	end
end

-- Its picked-row bars (scale list, stat list): the accent wash.
local picks = {}
local function PaintPicks()
	for _, tex in ipairs(picks) do
		ns.FillAccent(tex, 0.16, nil, KEY)
		tex:SetBlendMode("BLEND")
	end
end
local function Pick(tex)
	if not IsTexture(tex) or not ns.Once(tex) then return end
	picks[#picks + 1] = tex
	PaintPicks()
end

local function PickFrame(frame)
	if not Usable(frame) then return end
	for _, r in ipairs({ frame:GetRegions() }) do
		if IsTexture(r) and r:GetTexture() ~= nil then Pick(r) end
	end
end

-- The Automatic / Manual buttons: a control box, the picked one (its SelectedTexture shown)
-- edged in the accent.
local choices = {}
local accent = { 1, 1, 1 }
local function PaintChoice(btn)
	local c = choices[btn]
	local Kit = ns.Kit
	if not c or not Kit or not On() then return end
	local sel = btn.SelectedTexture
	if IsTexture(sel) and sel:IsShown() then
		accent[1], accent[2], accent[3] = ns.AccentOf(KEY)
		ns.LightShell(c.shell, accent, KEY)
	else
		Kit.Paint(c.shell, c.hover and Kit.ROW_HOVER or nil)
	end
end
local function PaintChoices() for btn in pairs(choices) do Guard(PaintChoice, btn) end end

local function Choice(btn, Kit)
	if Kind(btn) ~= "Button" or choices[btn] or not Controls() then return end
	for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture" }) do
		local t = btn[get] and btn[get](btn)
		if IsTexture(t) then Kit.Erase(t) end
	end
	if IsTexture(btn.SelectedTexture) then Kit.Erase(btn.SelectedTexture) end
	Wash(btn.GetHighlightTexture and btn:GetHighlightTexture(), 0.05)
	local c = { shell = Kit.Shell(btn, "control") }
	choices[btn] = c
	btn:HookScript("OnEnter", function() c.hover = true PaintChoice(btn) end)
	btn:HookScript("OnLeave", function() c.hover = false PaintChoice(btn) end)
	PaintChoice(btn)
end

-- The scale color swatch: its gold round frame off, an outline round the color.
local function Swatch(btn, Kit)
	local color = _G.PawnUIFrame_ScaleColorSwatch_Color
	if Kind(btn) ~= "Button" or not IsTexture(color) or not ns.Once(btn) or not Controls() then return end
	for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture" }) do
		local t = btn[get] and btn[get](btn)
		if IsTexture(t) then Kit.Hide(t) end
	end
	local s = Kit.Outline(color, 2, "control")
	btn:HookScript("OnEnter", function() Kit.Paint(s, Kit.ROW_HOVER) end)
	btn:HookScript("OnLeave", function() Kit.Paint(s, nil) end)
end

-- An item slot (compare items, shortcuts): the item's art cropped, the empty-slot art a dark
-- well, an edge round it, its hover a wash.
local function Slot(btn, Kit)
	if Kind(btn) ~= "Button" or not ns.Once(btn) then return end
	local normal = btn.GetNormalTexture and btn:GetNormalTexture()
	if IsTexture(normal) then normal:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
	Wash(btn.GetHighlightTexture and btn:GetHighlightTexture(), 0.12)
	for _, r in ipairs({ btn:GetRegions() }) do
		if IsTexture(r) and r ~= normal and r:GetDrawLayer() == "BACKGROUND" then r:SetColorTexture(0, 0, 0, 0.35) end
	end
	Kit.Outline(btn, 1, "icon")
end

-- Its "Pawn" picture buttons (character, inspect, socketing windows, its settings page): a
-- DaylightUI button reading "Pawn". (Its picture is a whole button of its own art; the button look
-- hides it, and any later walk over those windows then finds the button already dressed.)
local function PawnButton(btn, Kit)
	if Kind(btn) ~= "Button" or not Controls() then return end
	if (btn:GetText() or "") == "" then btn:SetText("Pawn") end
	Kit.Button(btn)
end

-- A string dialog (single or multi line): window shell, its controls by the walk.
local function Dialog(f, Kit)
	if not Usable(f) or not ns.Once(f) then return end
	ns.NoBackdrop(f)
	ns.Shell(f, { window = true }, KEY)
	Ink(f.PromptText, "TEXT")
	if Kind(f.TextBox) == "EditBox" then ns.FollowFont(f.TextBox, KEY) end
	if ns.Walk then ns.Walk(Kit, f, nil, nil, function(frame) Each(frame, Kit, f) end, KEY) end
end

-- A loot roll callout: the window shell in place of the glow box, its arrow off.
local function Callout(f, Kit)
	if not Usable(f) or not ns.Once(f) then return end
	Kit.Strip(f)
	if Usable(f.arrow) then Kit.Hide(f.arrow) end
	ns.Shell(f, { window = true }, KEY)
	local text = f.text
	if Kind(text) == "FontString" then
		ns.FollowFont(text, KEY)
		Kit.Light(text)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Lists rebuilt by Pawn (post-hooks on the functions that build them)
-- ---------------------------------------------------------------------------------------------

local function EachNamed(prefix, fn)
	for i = 1, 1000 do
		local f = _G[prefix .. i]
		if not f then break end
		Guard(fn, f, i)
	end
end

local function ScaleLines()
	EachNamed("PawnUIScaleLine", ListRow)
end

local function StatLines()
	EachNamed("PawnUIFrame_StatsList_Item", ListRow)
end

local function CompareLines()
	EachNamed("PawnUICompareStatLine", function(_, i)
		local name = "PawnUICompareStatLine" .. i
		for _, part in ipairs({ "Name", "Quantity1", "Quantity2", "Difference1", "Difference2" }) do
			local fs = _G[name .. part]
			if Kind(fs) == "FontString" then
				ns.FollowFont(fs, KEY)
				-- (Gold quantities to the label ink; red, green, white and blue headings as below.)
				local r, g, b = fs:GetTextColor()
				if math.abs(r - 1) < 0.05 and math.abs(g - 0.82) < 0.05 and b < 0.1 then Ink(fs, "LABEL") end
			end
		end
		-- A header line (PawnFontBlueSmall): the label ink.
		if not _G[name .. "Quantity1"] then Ink(_G[name .. "Name"], "LABEL") end
	end)
end

local function GemLines()
	EachNamed("PawnUIGemLine", function(line, i)
		local name = _G["PawnUIGemLine" .. i .. "Name"]
		if Kind(name) == "FontString" then
			ns.FollowFont(name, KEY)
			-- A header line has no icon: the label ink.
			if not _G["PawnUIGemLine" .. i .. "Icon"] then Ink(name, "LABEL") end
		end
		if ns.Once(line) and line.GetHighlightTexture then Wash(line:GetHighlightTexture(), 0.06) end
	end)
end

-- ---------------------------------------------------------------------------------------------
-- The window
-- ---------------------------------------------------------------------------------------------

local TABS = 7

-- Its tabs are sized by the game to their words in the game's font: measured again in the player's.
local function FitTabs()
	for i = 1, TABS do
		local tab = _G["PawnUIFrameTab" .. i]
		if Usable(tab) and type(PanelTemplates_TabResize) == "function" then
			local label = tab.Text or (tab.GetFontString and tab:GetFontString())
			if Kind(label) == "FontString" then label:SetWidth(0) end
			pcall(PanelTemplates_TabResize, tab, 15)
		end
	end
end

local function Window(f, Kit)
	if not ns.Once(f) then return end
	ns.NoBackdrop(f)
	Kit.Window(f)
	ns.Shell(f, { window = true }, KEY)
	local header = _G.PawnUIHeader
	if Kind(header) == "FontString" then
		ns.FollowFont(header, KEY)
		Kit.Light(header, ns.Colors().VALUE)
	end
	if Controls() then
		Choice(_G.PawnUIFrame_AutoSelectScalesOnButton, Kit)
		Choice(_G.PawnUIFrame_AutoSelectScalesOffButton, Kit)
		Swatch(_G.PawnUIFrame_ScaleColorSwatch, Kit)
		for _, n in ipairs({ "PawnUICompareItemIcon1", "PawnUICompareItemIcon2", "PawnUICompareItemShortcut1",
			"PawnUICompareItemShortcut2", "PawnUICompareItemShortcut3", "PawnUICompareItemShortcut4" }) do
			Slot(_G[n], Kit)
		end
		local clear = _G.PawnUIFrame_ClearItemsButton
		if Kind(clear) == "Button" then Kit.IconButton(clear, 4, ns.API.Media("ui-reset.png")) end
	end
	PickFrame(_G.PawnUIFrame_ScaleSelector_HighlightFrame)
	Pick(_G.PawnUIFrame_StatsList_Highlight)
	-- The stat list's rows exist from the start.
	StatLines()
	if ns.Walk then
		ns.Walk(Kit, f, nil, function() FitTabs() end, function(frame) Each(frame, Kit, f) end, KEY)
	end
	f:HookScript("OnShow", function()
		if On() then C_Timer.After(0, function() Later("tabs", FitTabs) end) end
	end)
end

local function Dress(Kit)
	local f = _G.PawnUIFrame
	if not Usable(f) then return false end
	Window(f, Kit)
	Dialog(_G.PawnUIStringDialogSingleLine, Kit)
	Dialog(_G.PawnUIStringDialogMultiLine, Kit)
	if Controls() then
		PawnButton(_G.PawnUI_InventoryPawnButton, Kit)
		PawnButton(_G.PawnUI_InspectPawnButton, Kit)
		PawnButton(_G.PawnUI_SocketingPawnButton, Kit)
		PawnButton(_G.PawnInterfaceOptionsFrame_PawnButton, Kit)
	end
	for i = 1, 4 do Callout(_G["PawnUI_LootUpgradeAdvisor" .. i], Kit) end
	ScaleLines()
	CompareLines()
	GemLines()
	return true
end

-- A Pawn function, post-hooked when it's there: fn runs after it, out of combat.
local function After(name, job, fn)
	if type(_G[name]) ~= "function" then return end
	hooksecurefunc(name, function()
		if On() then Later(job, fn) end
	end)
end

ns.Pack(KEY, "Pawn", function(Kit)
	if not Usable(_G.PawnUIFrame) then return false end
	Later("dress", function() Dress(Kit) end)
	-- Lists it builds again and again.
	After("PawnUIFrame_ScaleSelector_Refresh", "scales", ScaleLines)
	After("PawnUIFrame_StatsList_Update", "stats", StatLines)
	After("PawnUIFrame_StatsList_UpdateStat", "stats", StatLines)
	After("PawnUI_CompareItems", "compare", CompareLines)
	After("PawnUI_DeleteComparisonLines", "compare", CompareLines)
	After("PawnUI_ShowBestGems", "gems", GemLines)
	-- Which of Automatic / Manual is picked.
	After("PawnUI_ScalesTab_SelectFrame", "choices", PaintChoices)
	-- Its buttons made when the inspect and socketing windows first load.
	After("PawnUI_InspectPawnButton_Attach", "inspect", function()
		if Controls() then PawnButton(_G.PawnUI_InspectPawnButton, Kit) end
	end)
	After("PawnUI_SocketingPawnButton_Attach", "socket", function()
		if Controls() then PawnButton(_G.PawnUI_SocketingPawnButton, Kit) end
	end)
end, CAPS)

ns.me.On("StyleChanged", function()
	if not On() then return end
	Guard(PaintPicks)
	PaintChoices()
end)
ns.me.On("SettingChanged", function(scope)
	if scope ~= "DaylightAddonSkins" or not On() then return end
	Guard(PaintPicks)
	PaintChoices()
end)
