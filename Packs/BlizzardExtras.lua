-- Game windows, part two: the pieces of the game's windows that DaylightUI's Window Skins dress
-- but pass over, and a few windows of their own. Same rules as Blizzard.lua (whose helpers and
-- entry list this uses, through ns.Blizz): built against the client's own interface code
-- (wow-ui-source, branch "forever"), looks only, post-hooks only, nothing protected called, and
-- every entry here is dressed by Blizzard.lua's passes (at login and as each Blizzard addon loads,
-- out of combat). The pieces that complete a DaylightUI window are only dressed while that
-- window's DaylightUI skin is on (its pack in DaylightUI's Window Skins).
--   Collections (CollectionsJournal; DaylightUI's "collections" pack): the side tabs
--     (TabContainer.Tabs, LargeSideTabButtonTemplate) as DaylightUI's icon tabs, the picked one in
--     the accent; the "filters changed" badge (WowStyle1FilterDropdownTemplate's ResetButton) of
--     the mount, pet, toy, heirloom and appearance filters.
--   Calendar ("social" pack): the filter's badge; the side panels (holiday, raid reset, event,
--     create event, mass invite, event picker, icon picker) lose their dark dialog border and the
--     header's gold plate for a window shell; the description boxes are wells.
--   Click casting (ClickBindingFrame, Blizzard_ClickBindingUI; Options > Keybindings > Click
--     Casting, or /click): the window and its walk; the binding rows as lines (the new, unsaved
--     one picked in the accent), their delete X; the spellbook and macro portraits as icon tabs
--     (the open one picked); the list's well; the tutorial beside it.
--   The cooldown manager's settings (CooldownViewerSettings): art only, no hook on any part of it
--     (Edit Mode opens it): the side tabs, the layout and settings dropdowns, the category
--     headers. Its cooldown icons and bars are the game's preview of the real bars and stay.
--   Communities ("social" pack): the edit-channel, notification-settings and recruitment dialogs
--     inside the communities window lose their dialog art for a window shell.
--   Guild bank ("social" pack): the tabs down its side (GuildBankTab1..8) as icon tabs, the
--     picked one in the accent.
--   Confirm boxes (StaticPopup1..4; DaylightUI's "system" pack dresses them quietly): what it
--     leaves, just as quietly: the gold / silver / copper boxes, the money amount's coins, the
--     item line (its parchment name frame off, the item outlined in its quality), the dropdown, the
--     close button (a down chevron while the game has it minimize the box), the small gold text.
--   World map: the pin button (WorldMapTrackingPinButton, top left of the map): its gold ring off,
--     its dark round ground centered on the icon (the shared ns.MapRings pass), its hover and
--     "on" glows centered on the icon, the "on" one in the accent.
--   Auction house (only without DaylightMogul): the filter's badge, the buy dialog's border.
local _, ns = ...
if not ns.ok then return end
local B = ns.Blizz
if not B then return end

local Usable, Guard = ns.Usable, ns.Guard
local ipairs, type = ipairs, type
local KEY = B.KEY
local Entry, Kind, IsTexture, FontOf = B.Entry, B.Kind, B.IsTexture, B.FontOf

local dressed = setmetatable({}, { __mode = "k" })   -- parts of ours already done

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end

-- Whether DaylightUI's Window Skins dress the windows of one of their packs ("collections",
-- "social", "system"): nil while that module is off.
local function DaylightPack(name)
	return ns.DaylightHas("Skins", "packs." .. name)
end

-- Repaints only the given rows (not every row of every window, as Kit.RepaintSoon would).
local function RepaintRows(list)
	local Kit = ns.Kit
	if not Kit or not On() or type(list) ~= "table" then return end
	for i = 1, #list do Kit.RepaintRow(list[i]) end
end

-- A picked icon tab's tint in the Game windows accent (along its gradient when it is one):
-- Kit.Row paints it in one color on each repaint (click, hover), so it's painted again after.
local function PickFill(btn, picked)
	local Kit = ns.Kit
	local r = Kit and Kit.RowOf(btn)
	if r and IsTexture(r.fill) and picked(btn) then ns.FillAccent(r.fill, Kit.ROW_SELECTED_FILL, nil, KEY) end
end

local function AccentPick(btn, picked)
	PickFill(btn, picked)
	-- (Kit.Row's own hover hooks ran first, so these follow them; the mouse only.)
	ns.ScriptOnce(btn, "OnEnter", function() PickFill(btn, picked) end, KEY)
	ns.ScriptOnce(btn, "OnLeave", function() PickFill(btn, picked) end, KEY)
end

local function RepaintPicked(list, picked)
	RepaintRows(list)
	for i = 1, #list do PickFill(list[i], picked) end
end

-- The "filters changed" badges (UIResetButtonTemplate: a red circle with a yellow X) of every
-- filter dropdown under root, to depth.
local function ResetBadges(Kit, root, depth)
	if not Usable(root) or not root.GetChildren then return end
	for _, c in ipairs({ root:GetChildren() }) do
		if Usable(c) then
			local reset = c.ResetButton
			if (c.intrinsic == "DropdownButton" or c:GetObjectType() == "DropdownButton") and Usable(reset) then
				Guard(Kit.ResetBadge, reset)
			elseif depth > 0 then
				ResetBadges(Kit, c, depth - 1)
			end
		end
	end
end

-- Collections -----------------------------------------------------------------------------------
-- CollectionsJournal.TabContainer.Tabs: CollectionsJournalTab (Camelot's
-- Blizzard_CollectionsTabs.xml: LargeSideTabButtonTemplate, Background / Icon (masked) /
-- SelectedTexture / TabGlow / HighlightTexture), picked with SetChecked (SelectedTexture shown).
-- The journals' filters: MountJournal, PetJournal, ToyBox, HeirloomsJournal (FilterDropdown) and
-- WardrobeCollectionFrame (FilterButton).

local collectionsOwner = {}
local JOURNALS = { "MountJournal", "PetJournal", "ToyBox", "HeirloomsJournal", "WardrobeCollectionFrame" }
local collectionTabs = {}

Entry("CollectionsJournal", function(f, Kit)
	if not DaylightPack("collections") then return end
	local box = f.TabContainer
	local tabs = Usable(box) and box.Tabs
	if type(tabs) == "table" then
		for _, tab in ipairs(tabs) do
			if Usable(tab) then
				-- (The "new" glow pulses its alpha by animation: erased, not faded.)
				if IsTexture(tab.TabGlow) then Kit.Erase(tab.TabGlow) end
				Kit.SideTab(tab, nil, Kit.SIDE_TAB_CROP)
				collectionTabs[#collectionTabs + 1] = tab
			end
		end
	end
	-- The picked tab also changes from the game's own code (a keybind, the window reopening on the
	-- last tab): its EventRegistry event, run apart from the game's code (after the tabs are set).
	local reg = _G.EventRegistry
	if type(reg) == "table" and type(reg.RegisterCallback) == "function" then
		reg:RegisterCallback("CollectionsJournal.TabSet", function() RepaintRows(collectionTabs) end, collectionsOwner)
	end
	if Controls() then
		for _, name in ipairs(JOURNALS) do ResetBadges(Kit, _G[name], 4) end
	end
end)

-- Calendar --------------------------------------------------------------------------------------
-- Mainline/Blizzard_Calendar.xml: CalendarFrame.FilterButton (WowStyle1FilterDropdownTemplate);
-- the side panels, each with Border (DialogBorderDarkTemplate) and Header (DialogHeaderTemplate);
-- the holiday's picture (CalendarViewHolidayFrame.Texture) and the event's icon
-- (CalendarCreateEventIcon) stay; the description boxes (TooltipBackdropTemplate).

local CALENDAR_PANELS = { "CalendarViewHolidayFrame", "CalendarViewRaidFrame", "CalendarViewEventFrame",
	"CalendarCreateEventFrame", "CalendarMassInviteFrame", "CalendarEventPickerFrame", "CalendarTexturePickerFrame" }
local CALENDAR_WELLS = { "CalendarViewEventDescriptionContainer", "CalendarCreateEventDescriptionContainer" }

Entry("CalendarFrame", function(f, Kit)
	if not DaylightPack("social") then return end
	if Controls() and Usable(f.FilterButton) and Usable(f.FilterButton.ResetButton) then
		Kit.ResetBadge(f.FilterButton.ResetButton)
	end
	for _, name in ipairs(CALENDAR_PANELS) do
		local p = _G[name]
		if Usable(p) then
			local keep = {}
			if IsTexture(p.Texture) then keep[p.Texture] = true end
			local icon = _G.CalendarCreateEventIcon
			if IsTexture(icon) then keep[icon] = true end
			B.ShellWindow(Kit, p, keep)
		end
	end
	for _, name in ipairs(CALENDAR_WELLS) do
		local w = _G[name]
		if Usable(w) and not dressed[w] then
			dressed[w] = true
			Kit.Hide(w.NineSlice)
			Kit.Backdrop(w)
			Kit.Inset(w)
		end
	end
end)

-- Click casting ---------------------------------------------------------------------------------
-- Blizzard_ClickBindingUI.xml: ClickBindingFrame (PortraitFrameTemplate): ScrollBoxBackground
-- (TooltipBackdropTemplate), ScrollBox of ClickBindingLineTemplate rows (Background, Icon, Name,
-- BindingText, NewOutline (the new, unsaved binding), IconHighlight / EmptySlotIconHighlight,
-- FrameHighlight, DeleteButton) and ClickBindingHeaderTemplate rows, ScrollBar, Save / Add Binding /
-- Reset to Default (UIPanelButtonTemplate), EnableMouseoverCastCheckbox, MouseoverCastKeyDropdown
-- (WowStyle1), PlayerSpellsPortrait / MacrosPortrait (ClickBindingFramePortraitTemplate: Portrait,
-- Frame, UnselectedFrame shown on the one not open, Highlight), TutorialFrame (PortraitFrameTemplate
-- round its picture), TutorialButton (the help plate "?", kept), UnboundText (red, kept).

local function NewBinding(row)
	local o = row.NewOutline
	return IsTexture(o) and o:IsShown() == true
end

local lineKeep = setmetatable({}, { __mode = "k" })   -- row -> the textures of its that stay

local function BindingRow(Kit, row)
	if not Usable(row) then return end
	if IsTexture(row.Icon) and IsTexture(row.Background) then
		local keep = lineKeep[row]
		if not keep then
			keep = { [row.Icon] = true }
			if IsTexture(row.IconHighlight) then keep[row.IconHighlight] = true end
			if IsTexture(row.EmptySlotIconHighlight) then keep[row.EmptySlotIconHighlight] = true end
			lineKeep[row] = keep
		end
		-- (Again on every refill: the row's pick follows the binding it now shows.)
		Kit.Row(row, keep, NewBinding, false)
		if not dressed[row] then
			dressed[row] = true
			Kit.Outline(row.Icon, 1, "outline")
			if Usable(row.DeleteButton) then Kit.Close(row.DeleteButton) end
		end
		FontOf(Kit, row.Name)
		FontOf(Kit, row.BindingText)
	elseif Kind(row.Name) == "FontString" then
		FontOf(Kit, row.Name)
	end
end

local function PortraitPicked(b)
	local u = b.UnselectedFrame
	return not (IsTexture(u) and u:IsShown())
end

local function Portrait(Kit, b)
	if not Usable(b) or dressed[b] or not IsTexture(b.Portrait) then return end
	dressed[b] = true
	Kit.Row(b, { [b.Portrait] = true }, PortraitPicked, Kit.Outline(b.Portrait, 0, "icon", true))
	AccentPick(b, PortraitPicked)
	-- The open window changes from the game's own code (SetFocusedFrame): repainted after it.
	if type(b.SetSelectedState) == "function" then
		local one = { b }
		ns.HookOnce(b, "SetSelectedState", function() RepaintPicked(one, PortraitPicked) end, KEY)
	end
end

Entry("ClickBindingFrame", function(f, Kit)
	local tutorial = f.TutorialFrame
	local skip = {}
	if Usable(tutorial) then skip[tutorial] = true end
	if Usable(f.TutorialButton) then skip[f.TutorialButton] = true end
	if Usable(f.ScrollBox) then skip[f.ScrollBox] = true end
	local back = f.ScrollBoxBackground
	if Usable(back) then
		Kit.Hide(back.NineSlice)
		Kit.Backdrop(back)
		Kit.Inset(back)
	end
	B.Panel(Kit, f, { skip = skip }, function() B.Words(Kit, f, 2) end)
	if Usable(tutorial) then
		local keep = {}
		if IsTexture(tutorial.Tutorial) then keep[tutorial.Tutorial] = true end
		-- (Shown from the window's own OnShow: the plain shell, nothing hooked on it.)
		B.ShellWindow(Kit, tutorial, keep)
		Kit.Close(tutorial.CloseButton)
		B.Words(Kit, tutorial, 0)
	end
	if not Controls() then return end
	for _, b in ipairs({ f.PlayerSpellsPortrait, f.MacrosPortrait }) do Portrait(Kit, b) end
	if Usable(f.ScrollBox) then
		Kit.EachRow(f.ScrollBox, function(row) BindingRow(Kit, row) end, "dui-clickbinding")
	end
end)

-- Cooldown manager settings ---------------------------------------------------------------------
-- CooldownViewerSettings.xml: SpellsTab / AurasTab / GroupBuffsTab (LargeSideTabButtonTemplate:
-- Background, Icon with its Mask, SelectedTexture shown on the picked one, TabGlow,
-- HighlightTexture; the "new" dot NewOptionsFrame kept), SettingsDropdown
-- (UIPanelIconDropdownButtonTemplate: the gear Icon), LayoutDropdown (WowStyle1: Background, Arrow,
-- Text), the categories (CooldownScroll.Content's children, pooled: Header is a
-- ListHeaderThreeSliceTemplate with Left / Middle / Right (its +/- drawn in Right) and their
-- highlight copies, Name; Container holds the cooldown icons and bars).
-- Art only: nothing is hooked on any part of the window, nothing of the game's called. Its
-- categories are made as a tab is first shown, so the headers are looked over again after the
-- game's own EventRegistry events (run apart from its code) and a tab's click (the mouse only),
-- the next frame, out of combat. Its cooldown icons are left alone on purpose: their art can be
-- a secret value, and the game keeps their bounds out of the window's for that reason; an
-- outline of ours anchored to one would read it.

local TAB_PICK, TAB_HOVER, HEADER_HOVER = 0.18, 0.08, 0.08
local CDM_TABS = { "SpellsTab", "AurasTab", "GroupBuffsTab" }
local cdmTabs = {}

local function TabPick(tab)
	local sel = tab.SelectedTexture
	if IsTexture(sel) then
		ns.FillAccent(sel, TAB_PICK, nil, KEY)
		sel:SetBlendMode("BLEND")
	end
end

local function StaticSideTab(Kit, tab)
	if not Usable(tab) or dressed[tab] or not IsTexture(tab.Icon) then return end
	dressed[tab] = true
	local icon = tab.Icon
	if IsTexture(tab.Background) then Kit.Hide(tab.Background) end
	if IsTexture(tab.TabGlow) then Kit.Erase(tab.TabGlow) end
	if tab.Mask and icon.RemoveMaskTexture then pcall(icon.RemoveMaskTexture, icon, tab.Mask) end
	-- (A frame of ours over the icon's edge, with no script on it.)
	Kit.Outline(icon, 0, "icon", true)
	local sel = tab.SelectedTexture
	if IsTexture(sel) then
		sel:ClearAllPoints()
		sel:SetAllPoints(icon)
	end
	TabPick(tab)
	local hl = tab.HighlightTexture
	if IsTexture(hl) then
		hl:ClearAllPoints()
		hl:SetAllPoints(icon)
		hl:SetColorTexture(1, 1, 1, TAB_HOVER)
		hl:SetBlendMode("BLEND")
	end
	cdmTabs[#cdmTabs + 1] = tab
end

local function StaticDropdown(Kit, dd)
	if not Usable(dd) or dressed[dd] then return end
	dressed[dd] = true
	if IsTexture(dd.Background) then Kit.Hide(dd.Background) end
	Kit.Shell(dd, "input")
	local arrow, c = dd.Arrow, ns.Colors().LABEL
	-- (The game swaps the arrow's atlas on hover and press; the gray stays on it.)
	if IsTexture(arrow) and c then
		arrow:SetDesaturated(true)
		arrow:SetVertexColor(c[1], c[2], c[3])
	end
	FontOf(Kit, dd.Text)
end

local HEADER_OFF = { "Left", "Middle", "HighlightLeft" }

local function CategoryHeader(Kit, h)
	if not Usable(h) or dressed[h] then return end
	dressed[h] = true
	for _, k in ipairs(HEADER_OFF) do
		if IsTexture(h[k]) then Kit.Hide(h[k]) end
	end
	-- The right piece holds the +/- (the game swaps its atlas as the category opens and closes):
	-- kept, in gray.
	local c = ns.Colors().LABEL
	for _, k in ipairs({ "Right", "HighlightRight" }) do
		local t = h[k]
		if IsTexture(t) and c then
			t:SetDesaturated(true)
			t:SetVertexColor(c[1], c[2], c[3])
		end
	end
	local hl = h.HighlightMiddle
	if IsTexture(hl) then
		hl:ClearAllPoints()
		hl:SetAllPoints(h)
		hl:SetColorTexture(1, 1, 1, HEADER_HOVER)
		hl:SetBlendMode("BLEND")
		-- (Its XML alpha, 0.4, would leave the wash all but invisible.)
		hl:SetAlpha(1)
	end
	Kit.Shell(h, "row")
	FontOf(Kit, h.Name)
end

local function CategoryHeaders(Kit, f)
	local scroll = f.CooldownScroll
	local content = Usable(scroll) and scroll.Content
	if not Usable(content) then return end
	for _, cat in ipairs({ content:GetChildren() }) do
		if Usable(cat) and Usable(cat.Header) then CategoryHeader(Kit, cat.Header) end
	end
end

local cdmOwner = {}

local function CooldownPass()
	local f, Kit = _G.CooldownViewerSettings, ns.Kit
	if not (Usable(f) and Kit and On() and Controls()) then return end
	if InCombatLockdown() then
		ns.OutOfCombat(CooldownPass)
		return
	end
	CategoryHeaders(Kit, f)
	-- (The accent can have changed since: the picked wash again.)
	for i = 1, #cdmTabs do TabPick(cdmTabs[i]) end
end

local function CooldownSoon()
	if not On() then return end
	ns.Queue("Blizzard:cooldownSettings", CooldownPass, KEY)
end

Entry("CooldownViewerSettings", function(f, Kit)
	if not Controls() then return end
	for _, k in ipairs(CDM_TABS) do
		local tab = f[k]
		StaticSideTab(Kit, tab)
		-- (The mouse only: a click on the tab, never the game's own calls.)
		if Usable(tab) and tab.HookScript then ns.ScriptOnce(tab, "OnMouseUp", CooldownSoon, KEY) end
	end
	StaticDropdown(Kit, f.LayoutDropdown)
	local gear = f.SettingsDropdown
	local icon = Usable(gear) and gear.Icon
	if IsTexture(icon) and not dressed[gear] then
		dressed[gear] = true
		local c = ns.Colors().TEXT
		icon:SetDesaturated(true)
		if c then icon:SetVertexColor(c[1], c[2], c[3]) end
	end
	local reg = _G.EventRegistry
	if type(reg) == "table" and type(reg.RegisterCallback) == "function" then
		for _, event in ipairs({ "CooldownViewerSettings.OnShow", "CooldownViewerSettings.OnDataChanged" }) do
			reg:RegisterCallback(event, CooldownSoon, cdmOwner)
		end
	end
	CategoryHeaders(Kit, f)
end)

-- Communities' inner dialogs --------------------------------------------------------------------
-- CommunitiesFrame.EditStreamDialog (CommunitiesStreams.xml: BG, a DialogBorderDarkTemplate;
-- TitleLabel), .NotificationSettingsDialog (BG, a plain dark texture; Selector, TitleLabel) and
-- .RecruitmentDialog (ClubFinder.xml: BG, a DialogBorderDarkTemplate; DialogLabel). Their controls
-- are the communities window's (DaylightUI's walk over it).

local COMMUNITY_INNER = { { "EditStreamDialog", "TitleLabel" }, { "NotificationSettingsDialog", "TitleLabel" },
	{ "RecruitmentDialog", "DialogLabel" } }

for _, spec in ipairs(COMMUNITY_INNER) do
	local key, titleKey = spec[1], spec[2]
	Entry(function()
		local c = _G.CommunitiesFrame
		return Usable(c) and c[key] or nil
	end, function(f, Kit)
		if not DaylightPack("social") then return end
		B.ShellWindow(Kit, f)
		if Usable(f.Selector) then Kit.Strip(f.Selector) end
		local title = f[titleKey]
		if Kind(title) == "FontString" then
			FontOf(Kit, title)
			Kit.Light(title, ns.Colors().VALUE)
		end
		B.Words(Kit, f, 1)
	end, "communities")
end

-- Guild bank tabs -------------------------------------------------------------------------------
-- Mainline/Blizzard_GuildBankUI.xml: GuildBankTab1..8 (GuildBankTabTemplate: its unnamed
-- UI-GuildBankFrame-Tab backing) each hold .Button (a CheckButton: IconTexture, Count,
-- SearchOverlay (kept: it dims a tab the search doesn't match), UI-Quickslot2 normal art, pushed,
-- highlight and checked art). GuildBankFrameMixin:UpdateTabs checks the picked one.

local function BankTabPicked(b) return b:GetChecked() == true end

local function BankTab(Kit, tab)
	if not Usable(tab) or dressed[tab] then return end
	local b = tab.Button
	local icon = Usable(b) and b.IconTexture
	if not IsTexture(icon) then return end
	dressed[tab] = true
	Kit.Strip(tab)
	Kit.KeepCrop(icon, Kit.SIDE_TAB_CROP)
	local keep = { [icon] = true }
	if IsTexture(b.SearchOverlay) then keep[b.SearchOverlay] = true end
	Kit.Row(b, keep, BankTabPicked, Kit.Outline(icon, 0, "icon", true))
	-- The picked tint and hover wash inside the outline, over the icon (as DaylightUI's icon tabs).
	local r = Kit.RowOf(b)
	if r then
		for _, t in ipairs({ r.fill, r.wash }) do
			if IsTexture(t) then
				t:ClearAllPoints()
				t:SetAllPoints(icon)
			end
		end
	end
	Kit.RepaintRow(b)
	AccentPick(b, BankTabPicked)
	return b
end

local bankButtons = {}

Entry("GuildBankFrame", function(f, Kit)
	if not DaylightPack("social") or not Controls() then return end
	for i = 1, 8 do
		local b = BankTab(Kit, _G["GuildBankTab" .. i])
		if b then bankButtons[#bankButtons + 1] = b end
	end
	-- (After the game has checked the picked tab: only these eight repainted.)
	if type(f.UpdateTabs) == "function" then
		ns.HookOnce(f, "UpdateTabs", function() RepaintPicked(bankButtons, BankTabPicked) end, KEY)
	end
end)

-- Confirm boxes ---------------------------------------------------------------------------------
-- GameDialog.xml (StaticPopupTemplate): MoneyInputFrame (MoneyInputFrameTemplate: gold / silver
-- / copper boxes), MoneyFrame (SmallMoneyFrameTemplate), ItemFrame (NameFrame: the quest
-- reward's parchment; Text, the item's name in its quality color, kept; Item, an ItemButton),
-- Dropdown (WowStyle1), CloseButton (UIPanelCloseButton), ConfirmText and SubText (small gold).
-- Quiet, as DaylightUI dresses the boxes: with the controller UI on, the game stores a box's focus
-- actions as it opens, and a hook inside it that the game's Show set off would taint them. So the
-- boxes are dressed with the box as their host (Kit.EditBox's quiet look: only the mouse hooked),
-- the dropdown hooks only the mouse, the coins follow the game's global MoneyFrame_Update, and
-- nothing is hooked on the box itself or anything inside it. The item and the X are drawn with
-- shells and textures that carry no script (Kit.Item's quality edge would put an OnShow on a
-- frame inside the box): the item's outline takes its quality color from post-hooks on the global
-- SetItemButtonQuality and StaticPopup_Show, and the X becomes a down chevron while the game has
-- set the box's close button to minimize (SetCloseButtonToMinimize: the "MiniCondense" art). Each
-- box the game shows sets the small text's font object again (its gold with it): put back after
-- StaticPopup_Show has returned (after the box's own Show and its focus setup).

local COINS = { "gold", "silver", "copper" }
local popups = {}      -- the boxes dressed here
local popupItems = {}  -- a box's item button -> { shell, icon } of ours
local popupClose = {}  -- a box -> { x, chevron } drawn on its close button
local ITEM_CROP = 0.08
local CLOSE_ICON, CLOSE_CHEVRON = 10, 10

local function ItemEdge(btn)
	local p = popupItems[btn]
	if not p then return end
	local icon, border = p.icon, btn.IconBorder
	icon:SetTexCoord(ITEM_CROP, 1 - ITEM_CROP, ITEM_CROP, 1 - ITEM_CROP)
	local color
	if IsTexture(border) and border:IsShown() then
		local r, g, b = border:GetVertexColor()
		if type(r) == "number" and not (issecretvalue and issecretvalue(r)) then color = { r, g, b } end
	end
	ns.Kit.Paint(p.shell, color or ns.Kit.EMPTY_ITEM_BORDER)
end

local function PopupItem(Kit, btn)
	if not Usable(btn) or popupItems[btn] then return end
	local icon = btn.icon or btn.Icon
	if not IsTexture(icon) then return end
	if btn.GetNormalTexture then Kit.Hide(btn:GetNormalTexture()) end
	if IsTexture(btn.IconBorder) then Kit.Hide(btn.IconBorder) end
	local back = btn:CreateTexture(nil, "BACKGROUND", nil, -8)
	back:SetAllPoints(icon)
	back:SetColorTexture(0, 0, 0, 1)
	-- (Over the icon's edge, on a frame of ours with no script.)
	popupItems[btn] = { shell = Kit.Outline(icon, 1, "outline", true, B.QUIET), icon = icon }
	ItemEdge(btn)
end

-- DaylightUI's media folder, from a file of its the Kit names (for its X and chevron art).
local function Media(Kit)
	return type(Kit.ERASE) == "string" and Kit.ERASE:match("^(.*[\\/])") or nil
end

local function Glyph(btn, file, size)
	local ink = ns.Colors().LABEL or { 0.7, 0.7, 0.7 }
	local t = btn:CreateTexture(nil, "OVERLAY", nil, 7)
	t:SetTexture(file)
	t:SetSize(size, size)
	t:SetPoint("CENTER", btn, "CENTER", 0, 0)
	t:SetVertexColor(ink[1], ink[2], ink[3])
	return t
end

local function CloseArt(Kit, f)
	local btn = f.CloseButton
	if not Usable(btn) or popupClose[f] then return end
	local media = Media(Kit)
	if not media then return end
	popupClose[f] = { media = media, down = Glyph(btn, media .. "ui-chevron.png", CLOSE_CHEVRON) }
	popupClose[f].down:Hide()
end

local STATE_ART = { "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }

-- DaylightUI's X on the button (its window skin dresses the box's close button): the one texture
-- on its overlay layer that is neither the game's state art nor ours.
local function TheirX(btn, c, state)
	for _, r in ipairs({ btn:GetRegions() }) do
		if IsTexture(r) and r ~= c.down and r ~= c.own and not state[r] and r:GetDrawLayer() == "OVERLAY" then return r end
	end
end

-- The game's art off again (it sets the close button's art on each box) and the glyph for it.
local function CloseState(f)
	local c, btn = popupClose[f], f.CloseButton
	if not c then return end
	local atlas
	local state = {}
	for _, get in ipairs(STATE_ART) do
		local t = btn[get] and btn[get](btn)
		if IsTexture(t) then
			state[t] = true
			if get == "GetNormalTexture" then atlas = t.GetAtlas and t:GetAtlas() end
			t:SetAlpha(0)
		end
	end
	if not c.x then
		c.x = TheirX(btn, c, state)
		-- (No X of DaylightUI's on it: one of ours, with no script.)
		if not c.x then
			c.own = Glyph(btn, c.media .. "ui-close.png", CLOSE_ICON)
			c.x = c.own
		end
	end
	local mini = type(atlas) == "string" and string.find(string.lower(atlas), "minicondense", 1, true) ~= nil
	-- (Shown and hidden, never faded: DaylightUI's X sets its own alpha as the mouse moves.)
	c.x:SetShown(not mini)
	c.down:SetShown(mini)
end

local function PopupText(Kit, f)
	for _, k in ipairs({ "ConfirmText", "SubText" }) do
		if Kind(f[k]) == "FontString" then Kit.Refont(f[k]) end
	end
	-- The small gold words in DaylightUI's label ink (the game's other colors kept).
	Kit.InkGameText(f)
	-- (Only on a box the game is showing: by then DaylightUI's own skin has dressed it.)
	if f:IsShown() then CloseState(f) end
	local item = f.ItemFrame
	if Usable(item) and Usable(item.Item) then ItemEdge(item.Item) end
end

local function PopupExtras(Kit, f)
	if Usable(f.MoneyFrame) then Kit.Money(f.MoneyFrame) end
	local item = f.ItemFrame
	if Usable(item) then
		if IsTexture(item.NameFrame) then Kit.Hide(item.NameFrame) end
		FontOf(Kit, item.Text)
	end
	FontOf(Kit, f.ConfirmText)
	FontOf(Kit, f.SubText)
	popups[#popups + 1] = f
	if Controls() then
		CloseArt(Kit, f)
		if Usable(item) then PopupItem(Kit, item.Item) end
	end
	PopupText(Kit, f)
	if not Controls() then return end
	local money = f.MoneyInputFrame
	if Usable(money) then
		for _, coin in ipairs(COINS) do
			if Kind(money[coin]) == "EditBox" then Kit.EditBox(money[coin], f) end
		end
		-- (Its boxes are done above, quietly: this only puts DaylightUI's coins on them.)
		Kit.MoneyInput(money)
	end
	if Usable(f.Dropdown) then Kit.Dropdown(f.Dropdown) end
end

for i = 1, 4 do
	Entry("StaticPopup" .. i, function(f, Kit)
		if DaylightPack("system") then PopupExtras(Kit, f) end
	end)
end

if type(_G.StaticPopup_Show) == "function" then
	ns.HookOnce(nil, "StaticPopup_Show", function()
		local Kit = ns.Kit
		if not Kit or #popups == 0 or not On() then return end
		for i = 1, #popups do
			local f = popups[i]
			if f:IsShown() then Guard(PopupText, Kit, f) end
		end
	end, KEY)
end

-- The item's quality, set again as its data arrives (the box shows before the item is cached).
-- (The game calls this for every item button it draws: only a box's button goes on to the guarded
-- call, the rest stop at the lookup.)
local function IsPopupItem(btn) return popupItems[btn] ~= nil end
if type(_G.SetItemButtonQuality) == "function" then
	ns.HookOnce(nil, "SetItemButtonQuality", function(btn)
		if popupItems[btn] and ns.Kit and On() then Guard(ItemEdge, btn) end
	end, KEY, IsPopupItem)
end

-- The world map's pin button --------------------------------------------------------------------
-- Blizzard_WorldMapTemplates.xml (WorldMapTrackingPinButtonTemplate; Camelot's
-- Blizzard_WorldMap.lua puts it at the map's top left): Background (UI-Minimap-Background, the
-- dark disc), Icon, IconOverlay, Border (MiniMap-TrackingBorder, the gold ring), ActiveTexture
-- (shown while the pin mode is on), an ADD highlight. The ring and the ground: the shared corner
-- pass (ns.MapRings, also OpenMap's and RareScanner's), followed here for this pack too.
-- (OpenMap's pack post-hooks this button's SetActive; nothing here touches its scripts.)

local PIN_GLOW = 30   -- px: the hover and "on" glows round the icon (its ground is 25)
local pinActive, pinHighlight   -- the button's "on" and hover glows, once dressed
local pinOwner = {}

-- Gray glows, the "on" one in the accent. Again after each Refresh of the button (every map
-- change: RefreshOverlayFrames), whose DesaturateHierarchy puts the game's colors back on them.
local function PinAccent()
	if not On() then return end
	if IsTexture(pinHighlight) then pinHighlight:SetDesaturated(true) end
	if IsTexture(pinActive) then
		pinActive:SetDesaturated(true)
		ns.PaintAccent(pinActive, 1, nil, KEY)
	end
end

local function PinButton(btn)
	if not Usable(btn) or dressed[btn] then return end
	local icon = btn.Icon
	if not IsTexture(icon) then return end
	dressed[btn] = true
	local hl = btn.GetHighlightTexture and btn:GetHighlightTexture()
	if IsTexture(hl) then
		hl:ClearAllPoints()
		hl:SetPoint("CENTER", icon, "CENTER", 0, 0)
		hl:SetSize(PIN_GLOW, PIN_GLOW)
		hl:SetVertexColor(1, 1, 1, 0.5)
		pinHighlight = hl
	end
	local active = btn.ActiveTexture
	if IsTexture(active) then
		active:ClearAllPoints()
		active:SetPoint("CENTER", icon, "CENTER", 0, 0)
		active:SetSize(PIN_GLOW, PIN_GLOW)
		pinActive = active
	end
	PinAccent()
	-- (A post-hook on the button's own Refresh: after the game's DesaturateHierarchy.)
	if type(btn.Refresh) == "function" then ns.HookOnce(btn, "Refresh", function() Guard(PinAccent) end, KEY) end
end

Entry("WorldMapFrame", function(map)
	ns.FollowMapRings(KEY)
	Guard(ns.MapRings)
	PinButton(map.WorldMapTrackingPinButton)
	-- (The accent can change while the map is closed: painted again as it opens, through the
	-- game's EventRegistry event, which runs apart from the map's own code.)
	local reg = _G.EventRegistry
	if pinActive and type(reg) == "table" and type(reg.RegisterCallback) == "function" then
		reg:RegisterCallback("WorldMapOnShow", PinAccent, pinOwner)
	end
end)

-- Auction house (without DaylightMogul) ---------------------------------------------------------
-- Blizzard_AuctionHouseFrame.xml: SearchBar.FilterButton (AuctionHouseFilterButtonTemplate, a
-- WowStyle1FilterDropdownTemplate), BuyDialog (AuctionHouseBuyDialogTemplate: Border, a
-- DialogBorderDarkTemplate; its buttons are the window's, DaylightUI's walk). DaylightUI's
-- "system" pack dresses the window.

local function MogulLoaded()
	local api = _G.C_AddOns
	return api ~= nil and type(api.IsAddOnLoaded) == "function" and api.IsAddOnLoaded("DaylightMogul") == true
end

Entry("AuctionHouseFrame", function(f, Kit)
	if MogulLoaded() or not DaylightPack("system") then return end
	local bar = f.SearchBar
	local filter = Usable(bar) and bar.FilterButton
	if Controls() and Usable(filter) and Usable(filter.ResetButton) then Kit.ResetBadge(filter.ResetButton) end
	local buy = f.BuyDialog
	if Usable(buy) then B.ShellWindow(Kit, buy) end
end)

-- A game window Daylight UI gives back (2.x: its Auction House, profession, trainer and other
-- windows stand in for the game's, whose own is "parked" meanwhile: DaylightUI\Windows\
-- Follow.lua). Parked "aside", a window is scaled to 0.001 and widened to Daylight UI's window
-- (writeWidth), and what is measured or laid out there stays so when it comes back. Daylight UI
-- refits the game's fit-to-text buttons then (refit), but two things it doesn't:
--   * Its own "Daylight UI window" link on the game's header (DaylightUI\Windows\Swap.lua, a
--     Widgets.Link): its width is its label's GetStringWidth, read when it is labeled. Labeled
--     while parked, it came back as wide as the header and further: a press anywhere on the
--     header swapped windows, and its hover line ran off the window's left edge.
--   * The game's Auction House lists (AuctionHouseItemListMixin, Blizzard_AuctionHouseItemList.lua
--     on the forever branch): their columns are laid out once, from the list's width then
--     (UpdateTableBuilderLayout: SetTableWidth(ScrollBox:GetWidth()), Arrange), and again only when
--     marked dirty. Laid out at the parked width, the Available column ran past the window.
-- So when Daylight UI says it has given a window back ("GameWindowBack", fired from giveBack:
-- internal, so looked for and called guarded), the link is sized to its words again and every
-- such list is marked dirty and laid out again at the window's own width (one hidden now lays
-- itself out as it shows: its OnShow). Once the window has its own size (the next frame), and
-- once more a moment later, as Daylight UI's own refit does.
local function RefitLink(g)
	if not g.GetChildren then return end
	for _, c in ipairs({ g:GetChildren() }) do
		local text = type(c) == "table" and c.text
		if type(c.SetLabel) == "function" and type(c.line) == "table" and type(text) == "table"
			and type(text.GetStringWidth) == "function" then
			local w, now = text:GetStringWidth(), c:GetWidth()
			if type(w) == "number" and w > 0 and type(now) == "number" and now > w + 1 then c:SetWidth(w) end
		end
	end
end

local function Relayout(frame, depth)
	if depth > 6 or not frame.GetChildren then return end
	for _, c in ipairs({ frame:GetChildren() }) do
		if type(c) == "table" then
			if type(c.UpdateTableBuilderLayout) == "function" and type(c.tableBuilderLayoutFunction) == "function" then
				c.tableBuilderLayoutDirty = true
				if c:IsShown() then pcall(c.UpdateTableBuilderLayout, c) end
			end
			Relayout(c, depth + 1)
		end
	end
end

local function Back(g)
	if not On() or type(g) ~= "table" or (g.IsForbidden and g:IsForbidden()) then return end
	if g:GetParent() ~= UIParent then return end   -- (parked again meanwhile)
	Guard(RefitLink, g)
	Guard(Relayout, g, 1)
end

do
	local D = _G.DaylightUI
	if type(D) == "table" and type(D.On) == "function" then
		pcall(D.On, "GameWindowBack", function(_, _, g)
			C_Timer.After(0, function() Back(g) end)
			C_Timer.After(0.2, function() Back(g) end)
		end)
	end
end
