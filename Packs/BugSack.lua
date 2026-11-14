-- BugSack: the sack window (BugSackFrame), made the first time it's opened, and everything in it:
-- the title row (the error's date, sender and session, the "3/12" count, and the filter box a
-- double-click opens), the error text and its scroll bar, the Previous / Send bugs / Next buttons,
-- the four tabs under the window (All bugs, Current session, Previous session, Options), and the
-- Options page (its checkboxes, the font size and sound dropdowns, and Wipe saved bugs).
-- Left to DaylightUI: the minimap button (LibDBIcon, gathered by DaylightUI's drawer), the "Send
-- bugs" popup (the game's StaticPopup), tooltips and the dropdowns' menus.
local _, ns = ...
if not ns.ok then return end

local KEY = "BugSack"
local API = ns.API

-- The title row's left edge. BugSack places its words past the portrait, which the window look
-- takes away; they start where DaylightUI's titles do instead.
local TITLE_X = 16
local function TitleLeft(frame, tc, region)
	if not ns.Usable(region) or not region.GetNumPoints then return end
	-- The title row's own offset from the window, so the words land TITLE_X from the window's edge.
	local tcX = 0
	for i = 1, tc:GetNumPoints() do
		local point, rel, _, x = tc:GetPoint(i)
		if point == "TOPLEFT" and (rel == frame or rel == nil) and type(x) == "number" then tcX = x end
	end
	for i = 1, region:GetNumPoints() do
		local point, rel, relPoint, _, y = region:GetPoint(i)
		if (point == "TOPLEFT" or point == "BOTTOMLEFT") and rel == tc then
			region:SetPoint(point, tc, relPoint, TITLE_X - tcX, y)
		end
	end
end

-- The session line is a button whose words come from its font objects (plain, and brighter under
-- the mouse), so the look goes on its own copies of them. Its colored parts (who sent it, the
-- session number) are color codes in the text and stay.
local titleFont, titleHover
local function TitleFonts()
	if titleFont then return titleFont, titleHover end
	local base = _G.GameFontNormalLeft
	local _, size, flags = base:GetFont()
	local face
	local ok, f = pcall(API.Font)
	if ok and type(f) == "string" then face = f end
	face, size, flags = ns.FontFor(KEY, face or (base:GetFont()), size, flags)
	local c = ns.Colors()
	titleFont = CreateFont("DaylightAddonSkinsBugSackTitle")
	titleFont:CopyFontObject(base)
	titleFont:SetFont(face, size, flags or "")
	local v = c.VALUE or { 1, 1, 1 }
	titleFont:SetTextColor(v[1], v[2], v[3])
	titleHover = CreateFont("DaylightAddonSkinsBugSackTitleHover")
	titleHover:CopyFontObject(titleFont)
	local t = c.TEXT or { 1, 1, 1 }
	titleHover:SetTextColor(t[1], t[2], t[3])
	return titleFont, titleHover
end

local function Ink(Kit, fs, role)
	if not ns.Usable(fs) then return end
	local c = ns.Colors()[role]
	ns.Guard(Kit.Font, fs, nil, type(c) == "table" and c or nil)
end

-- The title row's pieces, told apart by what they are: the session line (a button), the filter box
-- (an edit box), the count (anchored to the close button) and the "Filter:" label (the other
-- string; the template's own title text is left to the window look).
local function TitleRow(frame, Kit, skip)
	local tc = frame.TitleContainer
	if not ns.Usable(tc) then return end
	local titleText = tc.TitleText
	for _, child in ipairs({ tc:GetChildren() }) do
		local t = ns.Usable(child) and child:GetObjectType()
		if t == "Button" and child ~= frame.CloseButton and child.SetNormalFontObject then
			skip[child] = true
			TitleLeft(frame, tc, child)
			local normal, hover = TitleFonts()
			child:SetNormalFontObject(normal)
			child:SetHighlightFontObject(hover)
		elseif t == "EditBox" then
			skip[child] = true
			if ns.Controls(KEY) then ns.Guard(Kit.EditBox, child) end
			ns.Guard(Kit.Font, child)
		end
	end
	for _, region in ipairs({ tc:GetRegions() }) do
		if region ~= titleText and ns.Usable(region) and region:GetObjectType() == "FontString" then
			local _, rel = region:GetPoint(1)
			if rel == frame.CloseButton then
				Ink(Kit, region, "VALUE")    -- the count
			else
				TitleLeft(frame, tc, region)
				Ink(Kit, region, "LABEL")    -- "Filter:"
			end
		end
	end
end

-- Its tabs are the game's PanelTabButtonTemplate, picked with PanelTemplates_SelectTab (which shows
-- their "active" art; the look only fades that art, so whether it's shown still says which is
-- picked). While a filter is typed none is picked.
local TABS = { "BugSackTabAll", "BugSackTabSession", "BugSackTabLast", "BugSackTabOptions" }
local function Picked(tab)
	local active = tab.LeftActive or tab.MiddleActive
	return ns.Usable(active) and active:IsShown() == true
end

-- The tab template sizes each tab on show with an 88 px cap, which cuts "Current session" and
-- "Previous session" short: sized again right after, to its whole name.
local TAB_PAD, TAB_MIN = 15, 36
local function Widen(tab)
	if type(PanelTemplates_TabResize) == "function" then
		ns.Guard(PanelTemplates_TabResize, tab, TAB_PAD, nil, TAB_MIN)
	end
end

-- The tabs hang below the window: a panel behind them, from the window's left edge to just past the
-- last tab, its top tucked under the window's bottom edge so the two read as one.
local function TabShelf(frame)
	local first, last = _G[TABS[1]], _G[TABS[#TABS]]
	if not (ns.Usable(first) and ns.Usable(last)) then return end
	local shelf = CreateFrame("Frame", nil, frame)
	shelf:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 2)
	shelf:SetPoint("BOTTOMRIGHT", last, "BOTTOMRIGHT", 8, -2)
	-- Below the window (and so below the tabs, which sit on it).
	shelf:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
	shelf:EnableMouse(false)
	ns.Shell(shelf, nil, KEY)
end

local function Dress(frame, Kit)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	ns.Guard(Kit.Window, frame)
	local skip = {}
	TitleRow(frame, Kit, skip)

	for _, name in ipairs(TABS) do
		local tab = _G[name]
		if ns.Usable(tab) then
			-- (Not walked below: their three-piece art would read as a button's.)
			skip[tab] = true
			if ns.Controls(KEY) then ns.Guard(Kit.Tab, tab, Picked) end
			Widen(tab)
			tab:HookScript("OnShow", function(self) if ns.Enabled(KEY) then Widen(self) end end)
		end
	end
	TabShelf(frame)
	if ns.Controls(KEY) then
		-- Previous, Send bugs, Next, Wipe saved bugs: the game's red SharedButtonTemplate.
		for _, name in ipairs({ "BugSackPrevButton", "BugSackSendButton", "BugSackNextButton", "BugSackWipeButton" }) do
			local b = _G[name]
			if ns.Usable(b) then ns.Guard(Kit.Button, b) end
		end
		-- The rest by shape: the close button, the text's scroll bar, the Options page's checkboxes and
		-- dropdowns (that page is made hidden, and walked all the same), its gold labels inked.
		ns.Guard(Kit.Auto, frame, { rows = false, skip = skip })
	end

	-- The error text: the font size picked on the Options page is a font object it swaps in, so the
	-- look goes back on after each pick.
	local text = _G.BugSackScrollText
	if ns.Usable(text) then
		ns.Guard(Kit.Font, text)
		hooksecurefunc(text, "SetFontObject", function(self)
			if ns.Enabled(KEY) then ns.Guard(Kit.Font, self) end
		end)
	end

	-- The player's text look on the rest of the words (labels, checkbox names, tab names).
	-- (Its controls are done above.)
	ns.Dress(frame, { skip = skip, checks = false, scrollBars = false })
end

local function Now()
	local frame = _G.BugSackFrame
	if not ns.Usable(frame) or not ns.Enabled(KEY) then return end
	ns.WithKit(function(Kit) Dress(frame, Kit) end)
end

ns.Pack("BugSack", "BugSack", function()
	-- The window is made on its first opening. Dressed straight after the minimap button's click
	-- or /bugsack opened it; when it pops up by itself on an error, as soon as it's found.
	local ldb = type(LibStub) == "table" and LibStub("LibDataBroker-1.1", true)
	local obj = ldb and ldb:GetDataObjectByName("BugSack")
	if type(obj) == "table" and type(obj.OnClick) == "function" then
		hooksecurefunc(obj, "OnClick", function() ns.Guard(Now) end)
	end
	local slash = _G.SlashCmdList
	if type(slash) == "table" and type(slash.BugSack) == "function" then
		hooksecurefunc(slash, "BugSack", function() ns.Guard(Now) end)
	end
	ns.Watch(KEY, "BugSackFrame", function(frame, Kit) Dress(frame, Kit) end)
end, { window = true, controls = true, text = true })
