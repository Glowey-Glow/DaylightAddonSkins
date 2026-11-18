-- LFG Forever: its window in the DaylightUI look (built on its first open; dressed in the same
-- frame it opens, from /lfg, its key, the minimap button and the addon compartment).
-- Dressed here:
--   * The window (a PortraitFrameTemplate copy): its portrait, gold frame and stone ground give way
--     to the window shell (its own opacity, border and bevel when it has a look of its own); its X,
--     its size grip without the gold.
--   * Its four side tabs on the window's right edge (the game's Group Finder three and its own,
--     always picked) as DaylightUI's side tabs.
--   * The two wells (results, filters) as DaylightUI's insets; the filters' two top tabs (Filters,
--     Whispers) as DaylightUI's tabs; its dropdowns, buttons, level boxes and scroll bars
--     DaylightUI's (by its walk); every role, class and group filter checkbox as a switch (their
--     role and class icons kept).
--   * Section headings: gold titles in the label ink (value ink under the mouse), their plus /
--     minus in the text ink, the 4 px gold divider a faint 1 px line. The warning icon stays.
--   * Its text links (Reset, Save filter, Clear, Select all..., and each whisper's Remove /
--     Location / Invite) in the label ink, white under the mouse, gray when off; "My filters" (a
--     plain caret and label, left as it is drawn) and the report-a-bug link the same.
--   * Result rows (the game's Group Finder row templates in its own list): the blue bars (ground,
--     hover) a faint white wash; group / player dividers a quiet heading with a light label and
--     plus / minus; the invite, ask-to-join and delist buttons (silver menu buttons) DaylightUI's
--     buttons, their icons kept. Leader class colors, gray details, the delisted dimming, role
--     icons and the asked check stay; a name the game left gold (class unknown) in the value ink.
--     A Quests & Zones listing's details line (2.2.0, after a note icon) stays gray like the
--     activity line above it, in the window's text look.
--   * Whisper log rows: the blue hover a faint white wash; class-colored names stay.
--   * The Player ratings tab (1.5.0): its Recent allies heading and Clear link as the others; its
--     rows (the blue band and hover) a faint white wash. The stars (the rating itself) and the
--     red / silver / green rated names stay.
--   * The searching spinner and its label in the label ink; the settings cog without its brown.
-- Not here: the right-click menus (the game's menus, DaylightUI's), the listing tooltip and the
-- popups (Game windows), its settings page rows (they're built inside the game's protected
-- settings list; the Game settings window pack's pass covers the page), the minimap button
-- (DaylightUI's addon button drawer), the tab it adds to the game's Group Finder (DaylightUI's
-- Group Finder hides that window; with it off the tab stays as the game draws its neighbors).
-- The new-whisper flash on the Whispers tab stays.
local _, ns = ...
if not ns.ok then return end

local KEY = "LFGForever"
-- (Its words are the game's serif font objects: the player's font goes on all of them.)
local CAPS = { window = true, controls = true, text = true, shadow = true, font = "daylight" }
ns.Target(KEY, "LFG Forever", CAPS)

local Usable = ns.Usable

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

-- Gold art kept for its shape (+ / -, the spinner), in an ink.
local function Tint(tex, ink)
	if not IsTexture(tex) then return end
	tex:SetDesaturated(true)
	local c = ns.Colors()[ink or "TEXT"]
	if c then tex:SetVertexColor(c[1], c[2], c[3]) end
end

-- The game's gold, left on a name whose class it doesn't know.
local function IsGold(fs)
	if Kind(fs) ~= "FontString" then return false end
	local r, g, b = fs:GetTextColor()
	return math.abs(r - 1) < 0.05 and math.abs(g - 0.82) < 0.06 and b < 0.2
end

-- Its text look (font, size, outline, shadow from its page) on the strings there are now.
local TEXT_OPTS = { checks = false, scrollBars = false, fonts = true }
local function TextLook(f)
	if not ns.PlainText(KEY) then ns.Dress(f, TEXT_OPTS, 0, KEY) end
end

-- ---------------------------------------------------------------------------------------------
-- Text in font objects (links, section titles, report a bug): a button's font object sets its color
-- on every state change, so its words get font objects of ours in DaylightUI's inks (and its own
-- text look when it has one).
-- ---------------------------------------------------------------------------------------------

local fonts = {}
local function FontLike(base, ink)
	local name = "DaylightAddonSkinsLFGF" .. ink .. (base and base:GetName() or "")
	local f = fonts[name]
	if f then return f end
	f = CreateFont(name)
	if base then
		f:CopyFontObject(base)
		local path, size, flags = base:GetFont()
		if path and size and not ns.PlainText(KEY) then f:SetFont(ns.FontFor(KEY, path, size, flags)) end
	end
	local c = ns.Colors()[ink]
	if c then f:SetTextColor(c[1], c[2], c[3]) end
	fonts[name] = f
	return f
end

local function LinkFonts(btn)
	if Kind(btn) ~= "Button" or not ns.Once(btn) then return end
	local small = _G.GameFontNormalSmall
	btn:SetNormalFontObject(FontLike(small, "LABEL"))
	btn:SetHighlightFontObject(FontLike(small, "VALUE"))
	btn:SetDisabledFontObject(FontLike(small, "OFF"))
end

-- ---------------------------------------------------------------------------------------------
-- Rows
-- ---------------------------------------------------------------------------------------------

-- A silver menu button (UIMenuButtonStretchTemplate: nine pieces it swaps on press) as one of
-- DaylightUI's buttons: the pieces out of sight (their alpha outlasts the press swap), the Kit's
-- button look with its hover, press and off states.
local STRETCH = { "TopLeft", "TopRight", "BottomLeft", "BottomRight", "TopMiddle", "MiddleLeft",
	"MiddleRight", "BottomMiddle", "MiddleMiddle" }
local function FlatButton(btn, Kit)
	if not Controls() or Kind(btn) ~= "Button" or not ns.Once(btn) then return end
	for _, k in ipairs(STRETCH) do
		if IsTexture(btn[k]) then btn[k]:SetAlpha(0) end
	end
	Kit.Button(btn)
end

local function ResultRow(row, Kit)
	if not Usable(row) or not On() then return end
	local data = row.GetElementData and row:GetElementData()
	local divider = type(data) == "table" and type(data.data) == "table" and data.data.dividerType
	if divider or (IsTexture(row.ExpandIcon) and Kind(row.CategoryLabel) == "FontString") then
		Wash(row.ResultBG, 0.05)
		Wash(row.Highlight, 0.05)
		Tint(row.ExpandIcon)
		Tint(row.CollapseIcon)
		Ink(row.CategoryLabel, "LABEL")
		return
	end
	Wash(row.ResultBG, 0.03)
	Wash(row.Highlight, 0.06)
	Wash(row.Selected, 0.1)
	if IsGold(row.Name) then Ink(row.Name, "VALUE") end
	-- (2.2.0) A Quests & Zones listing's details line, made the first time its row shows one (after
	-- the window's text look went on): that look (left as is once it has it). Its gray stays.
	if Kind(row.LFGFNote) == "FontString" and not ns.PlainText(KEY) then ns.FollowFont(row.LFGFNote, KEY) end
	FlatButton(row.LFGFInvite, Kit)
	FlatButton(row.LFGFAskToJoin, Kit)
	if Usable(row.DataDisplay) then FlatButton(row.DataDisplay.DelistButton, Kit) end
end

local function WhisperRow(row)
	if not Usable(row) or not On() then return end
	Wash(row.ResultBG, 0.03)
	Wash(row.Highlight, 0.06)
	if IsGold(row.Name) then Ink(row.Name, "VALUE") end
	LinkFonts(row.RemoveLink)
	LinkFonts(row.LocationLink)
	LinkFonts(row.InviteLink)
end

-- A Player ratings row (its listing row: the Group Finder's blue band and bar, built on its first
-- fill): the band and hover a wash. Its stars are the rating and keep their gold.
local function RatingRow(row)
	if not Usable(row) or not On() then return end
	Wash(row.ResultBG, 0.03)
	Wash(row.Highlight, 0.06)
	if IsGold(row.Name) then Ink(row.Name, "VALUE") end
end

-- ---------------------------------------------------------------------------------------------
-- Filter panel
-- ---------------------------------------------------------------------------------------------

-- Its 4 px gold divider: faded, and a 1 px faint line of ours in its middle (its height is part of
-- the section's layout, so it isn't changed).
local function Rule(tex)
	if not IsTexture(tex) or not ns.Once(tex) then return end
	tex:SetAlpha(0)
	local line = tex:GetParent():CreateTexture(nil, "ARTWORK")
	line:SetColorTexture(1, 1, 1, 0.08)
	line:SetHeight(1)
	line:SetPoint("LEFT", tex, "LEFT", 0, 0)
	line:SetPoint("RIGHT", tex, "RIGHT", 0, 0)
end

local function Section(section, Kit)
	if not Usable(section) or not ns.Once(section) then return end
	Rule(section.Divider)
	local header = section.Header
	if Kind(header) == "Button" then
		Tint(header.Icon)
		if IsTexture(header.Icon) then
			ns.HookOnce(header.Icon, "SetAtlas", function(icon) if On() then Tint(icon) end end, KEY)
		end
		-- Its title is the header's own string: the button's font objects color it per state.
		local large = _G.GameFontNormalLarge
		header:SetNormalFontObject(FontLike(large, "LABEL"))
		header:SetHighlightFontObject(FontLike(large, "VALUE"))
	elseif Kind(section.Title) == "FontString" then
		Ink(section.Title, "LABEL")
	end
	LinkFonts(section.HeaderLink)
	-- Its role / class / group checkboxes carry an icon, which the walk takes for an icon button
	-- and leaves: switched here one by one (the icon is a texture beside it and stays).
	if Controls() and type(section.FilterChecks) == "table" then
		for _, cb in ipairs(section.FilterChecks) do
			if Kind(cb) == "CheckButton" and ns.Once(cb) then Kit.Check(cb) end
		end
	end
end

local function FilterPanel(fp, Kit)
	if Controls() then Kit.Inset(fp) end
	for _, s in ipairs(fp.FilterSections or {}) do Section(s, Kit) end
	Section(fp.WhispersSection, Kit)
	Section(fp.RatingsSection, Kit)
	for _, k in ipairs({ "ResetFiltersLink", "SaveNewFilterLink", "ClearChatLink", "UnselectAllClasses", "SelectAllClasses" }) do
		LinkFonts(fp[k])
	end
	-- "My filters": a bare caret and a label it swaps between two font objects on hover.
	local mine = fp.MyFiltersDropdown
	if Usable(mine) and ns.Once(mine) then
		Ink(mine.Label, "LABEL")
		Tint(mine.Arrow)
		local function paint(over)
			if not On() then return end
			if ns.Kit then ns.Kit.Refont(mine.Label) end
			Ink(mine.Label, over and "VALUE" or "LABEL")
		end
		ns.ScriptOnce(mine, "OnEnter", function() paint(true) end, KEY)
		ns.ScriptOnce(mine, "OnLeave", function() paint(false) end, KEY)
	end
	local gear = fp.SettingsGear
	if Usable(gear) and IsTexture(gear.Icon) then gear.Icon:SetDesaturated(true) end
	-- The level boxes sit 10 px apart round a dash: the Kit's box padding is put in as text insets
	-- first, so their numbers don't run into each other.
	local range = fp.LevelRange
	if Usable(range) then
		for _, box in ipairs({ range.MinLevel, range.MaxLevel }) do
			if Kind(box) == "EditBox" then box:SetTextInsets(6, 6, 0, 0) end
		end
	end
	local log = fp.WhisperLog
	if Usable(log) and Usable(log.ScrollBox) then
		Kit.EachRow(log.ScrollBox, WhisperRow, "DaylightAddonSkinsLFGFWhispers")
	end
	local ratings = fp.PlayerRatings
	if Usable(ratings) and Usable(ratings.ScrollBox) then
		Kit.EachRow(ratings.ScrollBox, RatingRow, "DaylightAddonSkinsLFGFRatings")
	end
end

-- ---------------------------------------------------------------------------------------------
-- The window
-- ---------------------------------------------------------------------------------------------

local SIDE_TABS = { "ListingTab", "BrowsingTab", "WhoListingTab", "BetterTab" }
local GRIP_ART = { "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture" }

local function Spinner(spinner)
	if not Usable(spinner) then return end
	Ink(spinner.Label, "LABEL")
	if Usable(spinner.BackgroundFrame) then Tint(spinner.BackgroundFrame.Background, "OFF") end
	if Usable(spinner.AnimFrame) then Tint(spinner.AnimFrame.Circle, "LABEL") end
end

-- The filter panel's top tabs (Filters, Whispers, Player ratings) are sized by the game to their
-- words in the game's font, with the words' width then fixed: in the player's (wider) font they're
-- cut short. Each tab is measured again from its words as they are now, and the row laid out anew.
-- A moment after the window shows, once the walk and the text look have put the font on.
local function FitTabs(fp)
	local tabs = Usable(fp) and fp.TabSystem
	if not Usable(tabs) or type(tabs.tabs) ~= "table" then return end
	for _, tab in ipairs(tabs.tabs) do
		local label = tab.Text
		if Kind(label) == "FontString" and tab.UpdateTabWidth then
			label:SetWidth(0)
			pcall(tab.UpdateTabWidth, tab)
			-- (Since 2.1.0 it gives each label 13 px a side, more than the game's 5: kept.)
			local need = (label:GetStringWidth() or 0) + 26
			if (tab:GetWidth() or 0) < need and tab.SetTabWidth then pcall(tab.SetTabWidth, tab, need) end
		end
	end
	if tabs.Layout then pcall(tabs.Layout, tabs) elseif tabs.MarkDirty then pcall(tabs.MarkDirty, tabs) end
end

local function FitTabsSoon(fp)
	C_Timer.After(0, function()
		C_Timer.After(0, function() if On() then FitTabs(fp) end end)
	end)
end

local function Window(f, Kit)
	local content = f.Content
	if not Usable(content) or not ns.Once(f) then return end
	Kit.Window(content)
	ns.Shell(content, { window = true }, KEY)
	if Controls() then
		if Usable(f.CloseButton) then Kit.Close(f.CloseButton) end
		-- (The picked one is the template's own SelectedTexture, shown by SetChecked.)
		for _, k in ipairs(SIDE_TABS) do
			if Usable(f[k]) then Kit.SideTab(f[k]) end
		end
	end
	local grip = f.ResizeButton
	if Usable(grip) then
		for _, get in ipairs(GRIP_ART) do
			local tex = grip[get] and grip[get](grip)
			if IsTexture(tex) then tex:SetDesaturated(true) end
		end
	end
	local bug = content.ReportBug
	if Kind(bug) == "Button" and ns.Once(bug) then
		local small = _G.GameFontNormalSmall
		bug:SetNormalFontObject(FontLike(small, "LABEL"))
		bug:SetHighlightFontObject(FontLike(small, "VALUE"))
	end
	local list, fp = content.ListPanel, content.FilterPanel
	local skip = {}
	if Usable(list) then
		if Controls() then Kit.Inset(list) end
		Spinner(list.SearchingSpinner)
		if Usable(list.ScrollBox) then
			Kit.EachRow(list.ScrollBox, function(row) ResultRow(row, Kit) end, "DaylightAddonSkinsLFGFResults")
		end
	end
	if Usable(fp) then
		FilterPanel(fp, Kit)
		if Usable(fp.MyFiltersDropdown) then skip[fp.MyFiltersDropdown] = true end
	end
	-- Every control of the game's templates inside, on every show (sections come and go). Its two
	-- lists' rows are this pack's (rows = false): the walk's own row look would fight it.
	if Controls() and ns.Walk then ns.Walk(Kit, f, { rows = false, skip = skip }, nil, nil, KEY) end
	TextLook(f)
	FitTabsSoon(fp)
	ns.ScriptOnce(f, "OnShow", function()
		if not On() then return end
		TextLook(f)
		FitTabsSoon(fp)
	end, KEY)
end

-- The window as soon as it's there (built and shown in one call): from each way it opens, then a
-- watch for anything else.
local function Now()
	local f, Kit = _G.LFGForeverFrame, ns.Kit
	if Usable(f) and Usable(f.Content) and Usable(f.Content.FilterPanel) and Kit and On() then
		ns.Guard(Window, f, Kit)
	end
end

ns.Pack(KEY, "LFG Forever", function()
	for _, name in ipairs({ "LFGForever_ToggleWindow", "LFGForever_OnAddonCompartmentClick" }) do
		if type(_G[name]) == "function" then ns.HookOnce(nil, name, Now, KEY) end
	end
	if type(_G.SlashCmdList) == "table" and type(_G.SlashCmdList.LFGFOREVER) == "function" then
		ns.HookOnce(_G.SlashCmdList, "LFGFOREVER", Now, KEY)
	end
	local mini = _G.LFGForeverMinimapButton
	if Usable(mini) then ns.ScriptOnce(mini, "OnClick", Now, KEY) end
	-- Its Search key (2.1.0, a key binding that clicks this button) opens the window too.
	local key = _G.LFGForeverSearchKeyButton
	if Usable(key) and key.HookScript then ns.ScriptOnce(key, "OnClick", Now, KEY) end
	ns.Watch(KEY, function()
		local f = _G.LFGForeverFrame
		return Usable(f) and Usable(f.Content) and Usable(f.Content.FilterPanel) and f or nil
	end, Window)
end, CAPS)
