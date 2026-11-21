-- LootTriage: its settings window (1.2.0 on: /lt, or the Open button on its page in the game's
-- options; with the gamepad UI on it keeps its settings in the options instead), its "What's New"
-- dialog, and the delete button it puts on the loot window's title bar.
-- (Checked against LootTriage 1.2.1.)
-- * The settings window (an unnamed ButtonFrameTemplate window): DaylightUI's window shell (its logo
--   portrait, stone inset and brown title strip go with the template's art), its page list as
--   DaylightUI's line rows (the picked page in the accent wash, its words lit), its section headings
--   in DaylightUI's value ink over an accent line, its checkboxes, sliders, dropdowns and buttons
--   DaylightUI's (the walk), its gold labels in DaylightUI's inks, its "What's New" link in the accent
--   (lit under the mouse). Gray (disabled) labels, the red price-addon note and the version stay.
-- * The "What's New" dialog: DaylightUI's window shell, its Okay button, and its two page arrows at
--   the top right (unnamed buttons with the spellbook's page art: the right one turns to older notes,
--   the one left of it to newer) as DaylightUI's page buttons, grayed by the addon at either end as
--   before. Left as it is: the gold version and section headings and item names in the notes (color
--   codes in the text, readable on the dark shell).
-- * The loot window's delete button (its "Delete button" option, shown with full bags): its red
--   trash picture kept, in DaylightUI's control box, while DaylightUI dresses the loot window.
-- Bag marks, loot marks and tooltip lines are its display and are left alone.
-- Fast path: everything of LootTriage's is private. /lt (its slash handler) is post-hooked and its
-- window dressed in that same call; opened from the Open button on its options page, it is looked
-- for every frame while that page is showing (ns.Watch, the fallback). Its What's New dialog is
-- looked for right after a click on either What's New button (the window's link or the one beside
-- the options' Defaults), or every fifth frame while one of them is on screen. The delete button is
-- made in its loot code, never reachable: watched for (one IsShown a frame) while the loot window is
-- open, until it turns up.
local _, ns = ...
if not ns.ok then return end

local KEY = "LootTriage"
local BORDER = "UI-DiamondDialogBox-Border"
local DELETE = "128-RedButton-Delete"

local function HasAtlas(frame, atlas)
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == "Texture" then
			local ok, name = pcall(region.GetAtlas, region)
			if ok and name == atlas then return true end
		end
	end
	return false
end

-- ---------------------------------------------------------------------------------------------
-- The settings window
-- ---------------------------------------------------------------------------------------------

local window -- the window, once found

local function IsWindow(f)
	return f:GetObjectType() == "Frame" and not f:GetName() and type(f.Refresh) == "function"
		and type(f.pages) == "table" and type(f.list) == "table" and ns.Usable(f.news) and ns.Usable(f.Inset)
end

local function FindWindow()
	for _, child in ipairs({ UIParent:GetChildren() }) do
		if ns.Usable(child) and IsWindow(child) then return child end
	end
end

-- Whether the game's options show LootTriage's own page (its Open button is there).
local function OnItsPage()
	local panel = _G.SettingsPanel
	if not panel or not panel:IsShown() or type(panel.GetCurrentCategory) ~= "function" then return false end
	local ok, cat = pcall(panel.GetCurrentCategory, panel)
	if not ok or type(cat) ~= "table" or type(cat.GetName) ~= "function" then return false end
	local ok2, name = pcall(cat.GetName, cat)
	return ok2 and name == "LootTriage"
end

local asked = false -- /lt just ran: look now, once
local function WindowWanted()
	if not asked and not OnItsPage() then return end
	return FindWindow()
end

-- A page heading (a frame with its words and a gold line fading out under them).
local function Heading(f)
	if not ns.Usable(f.text) or f.text:GetObjectType() ~= "FontString" then return end
	local value = ns.Colors().VALUE
	if type(value) == "table" then f.text:SetTextColor(value[1], value[2], value[3]) end
	local r, g, b = ns.AccentOf(KEY)
	for _, region in ipairs({ f:GetRegions() }) do
		if region:GetObjectType() == "Texture" and region.SetGradient and CreateColor then
			region:SetColorTexture(1, 1, 1, 1)
			region:SetGradient("HORIZONTAL", CreateColor(r, g, b, 0.67), CreateColor(r, g, b, 0))
		end
	end
end

local function Headings(win)
	for _, page in ipairs(win.pages) do
		if ns.Usable(page) then
			if ns.Usable(page.title) then
				local value = ns.Colors().VALUE
				if type(value) == "table" then page.title:SetTextColor(value[1], value[2], value[3]) end
			end
			for _, column in ipairs(type(page.columns) == "table" and page.columns or {}) do
				for _, part in ipairs(column) do
					if ns.Usable(part) and part.text and not part.row then Heading(part) end
				end
			end
		end
	end
end

-- The page list after each Refresh (it sets each entry's font object again: the picked one white,
-- the rest gold): the picked one's words in the value ink, the rest in the text ink.
local function ListWords(win, Kit)
	local value, text = ns.Colors().VALUE, Kit.TEXT
	for _, item in ipairs(win.list) do
		if ns.Usable(item) then
			if type(Kit.RepaintRow) == "function" then Kit.RepaintRow(item) end
			local fs = item.text
			if ns.Usable(fs) then
				local picked = ns.Usable(item.selected) and item.selected:IsShown()
				local c = picked and type(value) == "table" and value or text
				fs:SetTextColor(c[1], c[2], c[3])
			end
		end
	end
end

-- Its "What's New" link (a notes icon and gold words, white under the mouse, set by font object on
-- every enter and leave): the words in the accent, the value ink under the mouse.
local function NewsLink(news, over)
	local fs = news.label
	if not ns.Usable(fs) then return end
	if over then
		local value = ns.Colors().VALUE
		if type(value) == "table" then fs:SetTextColor(value[1], value[2], value[3]) end
	else
		fs:SetTextColor(ns.AccentOf(KEY))
	end
end

local DialogClicked -- (below)

local function DressWindow(win, Kit)
	if not ns.Once(win) then return end
	window = win
	ns.Guard(Kit.Window, win)
	if not ns.Controls(KEY) then return end
	-- The list: its own lighter ground off, its divider in DaylightUI's neutral; the entries line rows.
	local first = win.list[1]
	local listFrame = ns.Usable(first) and first:GetParent()
	local skip = { [win.news] = true }
	if ns.Usable(listFrame) then
		skip[listFrame] = true
		local n = Kit.ROW_BORDER
		for _, region in ipairs({ listFrame:GetRegions() }) do
			if region:GetObjectType() == "Texture" then
				if region:GetDrawLayer() == "BACKGROUND" then
					region:SetAlpha(0)
				elseif type(n) == "table" then
					region:SetColorTexture(n[1], n[2], n[3], 1)
				end
			end
		end
	end
	for _, item in ipairs(win.list) do
		if ns.Usable(item) then
			ns.Guard(Kit.Row, item, nil, item.selected, false)
			ns.ScriptOnce(item, "OnClick", function() ns.Guard(ListWords, win, Kit) end, KEY)
		end
	end
	local again   -- the window's walk, asked for again (set below)
	ns.HookOnce(win, "Refresh", function()
		ns.Guard(ListWords, win, Kit)
		if again then again() end
	end, KEY)
	-- The What's New link.
	local news = win.news
	ns.ScriptOnce(news, "OnEnter", function() NewsLink(news, true) end, KEY)
	ns.ScriptOnce(news, "OnLeave", function() NewsLink(news, false) end, KEY)
	ns.ScriptOnce(news, "OnClick", DialogClicked, KEY)
	NewsLink(news, false)
	-- 1.2.1 makes a page's controls the first time that page is shown (its Refresh; before, all of
	-- them with the window). Each page not made yet is shown to it once here, through its own
	-- Refresh, and the page it was on put back: the walk below then finds every control, so no
	-- page is first seen undressed. (The walk is asked for again after each Refresh all the same.)
	if type(win.Refresh) == "function" then
		local was = win.page
		for _, page in ipairs(win.pages) do
			if type(page) == "table" and type(page.rows) == "table" and not page.built then
				win.page = page
				pcall(win.Refresh)
			end
		end
		if win.page ~= was then
			win.page = was
			pcall(win.Refresh)
		end
	end
	-- Its pages: the controls, walked (hidden pages too, again as each shows).
	if ns.Walk then
		again = ns.Walk(Kit, win, { skip = skip }, function() ns.Guard(Headings, win) end, nil, KEY)
	else
		ns.Guard(Kit.Auto, win, { skip = skip })
		ns.Guard(Headings, win)
	end
	ns.Guard(ListWords, win, Kit)
end

-- ---------------------------------------------------------------------------------------------
-- The What's New dialog
-- ---------------------------------------------------------------------------------------------

-- The dialog is made the first time it opens, from the What's New link in its window or the What's
-- New button atop its options pages: a click on either looks at once, so the dialog is dressed
-- before it's drawn. Otherwise it's looked for only while the window or the game's Settings window
-- is open, every fifth frame. (DIALOG strata before 1.2.0, FULLSCREEN_DIALOG from it.)
local STRATA = { DIALOG = true, FULLSCREEN_DIALOG = true }
local beat = 0
local clicked = false
local function FindDialog()
	if clicked then
		clicked = false
	else
		local settings = _G.SettingsPanel
		local open = (settings and settings:IsShown()) or (window and window:IsShown())
		if not open then return end
		beat = beat + 1
		if beat % 5 ~= 0 then return end
	end
	for _, child in ipairs({ UIParent:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Frame" and not child:GetName()
			and child:IsShown() and STRATA[child:GetFrameStrata()] and HasAtlas(child, BORDER) then
			return child
		end
	end
end

-- The options' What's New button: an unnamed button of the addon's, on the game's Defaults button
-- (which is only read, and left as it is). Every such button there is hooked, in case another
-- addon puts one of its own in the same place.
local function NewsButtons()
	local list = _G.SettingsPanel and _G.SettingsPanel.Container and _G.SettingsPanel.Container.SettingsList
	local defaults = list and list.Header and list.Header.DefaultsButton
	local found = {}
	if not defaults then return found end
	for _, child in ipairs({ defaults:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" and not child:GetName()
			and child:GetText() == _G.GAMEMENU_NEW_BUTTON then
			local _, rel = child:GetPoint(1)
			if rel == defaults then found[#found + 1] = child end
		end
	end
	return found
end

DialogClicked = function()
	clicked = true
	ns.WatchNow()
end

local function DressDialog(dialog, Kit)
	if not ns.Once(dialog) then return end
	for _, region in ipairs({ dialog:GetRegions() }) do
		if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then ns.Kill(region) end
	end
	ns.Shell(dialog, { window = true })
	if not ns.Controls(KEY) then return end
	for _, child in ipairs({ dialog:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" then
			local text = child:GetText()
			if text and text ~= "" then
				if ns.Once(child) then ns.Guard(Kit.Button, child) end
			elseif ns.Once(child) then
				-- A page arrow: the one pinned to the dialog's top right shows older notes (a right
				-- arrow); the other sits left of it and shows newer ones.
				local point, rel = child:GetPoint(1)
				local older = point == "TOPRIGHT" and rel == dialog
				ns.Guard(Kit.PageButton, child, older and "right" or "left")
			end
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The loot window's delete button
-- ---------------------------------------------------------------------------------------------

local function FindDelete()
	local loot = _G.LootFrame
	if not ns.Usable(loot) or not loot:IsShown() then return end
	for _, child in ipairs({ loot:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" and not child:GetName() then
			local art = child:GetNormalTexture()
			local ok, atlas = false, nil
			if art then ok, atlas = pcall(art.GetAtlas, art) end
			if ok and atlas == DELETE then return child end
		end
	end
end

local function DressDelete(btn, Kit)
	if not ns.Controls(KEY) or not ns.DaylightDressesGame("system") or not ns.Once(btn) then return end
	-- (Not twice: a loot window walk of DaylightUI's may have made it a button already.)
	if (Kit.ButtonOf and Kit.ButtonOf(btn)) or (Kit.ShellOf and Kit.ShellOf(btn)) then return end
	ns.Guard(Kit.ArtButton, btn, 2)
end

-- ---------------------------------------------------------------------------------------------

ns.Pack(KEY, "LootTriage", function()
	ns.Watch(KEY, WindowWanted, DressWindow)
	if type(SlashCmdList) == "table" and type(SlashCmdList.LOOTTRIAGE) == "function" then
		ns.HookOnce(SlashCmdList, "LOOTTRIAGE", function()
			asked = true
			ns.WatchNow()
			asked = false
		end, KEY)
	end
	ns.Watch(KEY, function() return NewsButtons()[1] end, function()
		for _, button in ipairs(NewsButtons()) do
			ns.ScriptOnce(button, "OnClick", DialogClicked, KEY)
		end
	end)
	ns.Watch(KEY, FindDialog, DressDialog)
	ns.Watch(KEY, FindDelete, DressDelete)
end, { window = true, controls = true })
