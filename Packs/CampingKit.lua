-- Camping Kit: every window it draws for you to read or set something.
-- The "This campfire" panel (CampingKitCampPanel): its menu ground off, the DaylightUI shell, close
-- and Announce buttons; its gold title, fire name and "Looking for" label in DaylightUI's inks; a
-- wanted object's gold ring in your accent.
-- The shared Kits menu (KitDockMenu): shell, checkboxes, gear buttons, its gold "Kits" title inked.
-- The settings window (CampingKitOptions, its only settings UI; the game's options page only has
-- an Open button): shell and close; the picked section in your accent (fill, bar and name), hover as
-- a faint wash; the gold header line, section line, page and sub-heading lines as quiet hairlines;
-- its ticks and dropdowns with DaylightUI's warm control edge, the tick and slider fill and knob in
-- your accent, the dropdown arrow in DaylightUI's text ink; its scroll bar as DaylightUI's quiet
-- track and pill; its buttons DaylightUI's; gold and gray text in DaylightUI's inks. Pages are
-- built the first time they're opened, and each is dressed as it's built.
-- The announce message editor (CampingKitAnnounceEditor): ground off, shell, close and buttons, the
-- text well as a quiet DaylightUI box (its edge in your accent while you type), its text inked.
-- The placement bar (KitCoreMoveBar, while placing the reminder panel): shell, buttons, the Snap
-- tick in your accent, its text inked.
-- The "Campfire..." label beside the tent: its gold words in DaylightUI's label ink.
-- Left as it is on purpose: the kit itself (tent, slots, flyouts, dials, dock, map pins) is a secure
-- action HUD; the gold "Kit reminders" box and grid shown over the screen while placing the reminder
-- panel are a placement guide over the game world, not window chrome; the menus its dropdowns open
-- (the game's menus, already DaylightUI's); icons, item art and the green, orange and gray tooltip
-- lines.
local _, ns = ...
if not ns.ok then return end

local KEY = "CampingKit"
local WHITE8 = "Interface\\Buttons\\WHITE8X8"
local HAIRLINE = 0.08   -- alpha of a quiet white hairline
local WASH = 0.06       -- alpha of the hover wash

-- The panel's ground is one of three things, by what the client has: a menu-style child frame one
-- level under the panel, a dropdown atlas texture, or a backdrop on the panel itself.
local function ClearGround(panel)
	local level = panel:GetFrameLevel()
	for _, child in ipairs({ panel:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Frame" and child:GetFrameLevel() < level
			and not child:IsMouseEnabled() and child:GetNumRegions() > 0 then
			ns.Kill(child)
		end
	end
	for _, region in ipairs({ panel:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			local ok, atlas = pcall(region.GetAtlas, region)
			if ok and atlas == "common-dropdown-bg" then ns.Kill(region) end
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- Accent paint: what wears the accent, painted again when DaylightUI's style or this look changes
-- ---------------------------------------------------------------------------------------------

local accented = setmetatable({}, { __mode = "k" })   -- region -> "color" | "vertex" | "text"
local alphas = setmetatable({}, { __mode = "k" })

local function PaintAccent(region)
	local how = accented[region]
	if not how or not ns.Usable(region) then return end
	local r, g, b = ns.AccentOf(KEY)
	if how == "color" then
		region:SetColorTexture(r, g, b, alphas[region] or 1)
	elseif how == "vertex" then
		region:SetVertexColor(r, g, b, alphas[region] or 1)
	else
		region:SetTextColor(r, g, b)
	end
end

local function Accent(region, how, alpha)
	if not ns.Usable(region) then return end
	accented[region], alphas[region] = how, alpha
	PaintAccent(region)
end

local repaintQueued = false
local function Repaint()
	repaintQueued = false
	if not ns.Enabled(KEY) then return end
	for region in pairs(accented) do PaintAccent(region) end
end
local function QueueRepaint()
	if repaintQueued or not next(accented) then return end
	repaintQueued = true
	C_Timer.After(0, Repaint)
end
ns.me.On("StyleChanged", QueueRepaint)
ns.me.On("SettingChanged", function(scope, path)
	if scope ~= "DaylightAddonSkins" or type(path) ~= "string" then return end
	if path == "followDaylight" or string.sub(path, 1, 16) == "look.CampingKit." then QueueRepaint() end
end)

-- ---------------------------------------------------------------------------------------------
-- Small pieces
-- ---------------------------------------------------------------------------------------------

local function Hairline(tex)
	if ns.Usable(tex) then tex:SetColorTexture(1, 1, 1, HAIRLINE) end
end

-- The faint white wash under the mouse, in place of the gold one on a frame's HIGHLIGHT layer.
local function Wash(frame)
	for _, region in ipairs({ frame:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "HIGHLIGHT" then
			region:SetColorTexture(1, 1, 1, WASH)
		end
	end
end

-- The settings window's control box (a dark fill and four gold one-pixel edges): a lighter fill and
-- DaylightUI's warm control edge. tickAccent: its OVERLAY texture is a tick, put in the accent;
-- otherwise it's the dropdown's arrow, put in the text ink.
local function Box(frame, Kit, tickAccent)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	local edge = Kit.CONTROL_BORDER or { 0.24, 0.21, 0.16 }
	for _, region in ipairs({ frame:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" then
			local layer = region:GetDrawLayer()
			if layer == "BACKGROUND" then
				region:SetColorTexture(0, 0, 0, 0.35)
			elseif layer == "BORDER" then
				region:SetColorTexture(edge[1], edge[2], edge[3], 1)
			elseif layer == "OVERLAY" then
				if tickAccent then
					Accent(region, "vertex")
				else
					local t = Kit.TEXT or { 1, 1, 1 }
					region:SetVertexColor(t[1], t[2], t[3])
				end
			end
		end
	end
end

local function InkOnShow(frame, Kit, extra)
	local function ink()
		if not ns.Enabled(KEY) then return end
		ns.Guard(Kit.InkGameText, frame)
		if extra then ns.Guard(extra, frame) end
	end
	frame:HookScript("OnShow", ink)
	ink()
end

-- ---------------------------------------------------------------------------------------------
-- The settings window
-- ---------------------------------------------------------------------------------------------

-- A section in the list down the left: its fill and bar in the accent, hover a wash, and its name
-- in the accent while picked (the kit gives the picked name the gold font object on every pick).
local function IsPickedFont(obj)
	return obj == "GameFontNormal" or obj == _G.GameFontNormal
end

local function NavButton(b)
	if not ns.Once(b) then return end
	Accent(b.sel, "color", 0.14)
	Accent(b.bar, "color", 1)
	Wash(b)
	local fs = b.text
	if not ns.Usable(fs) then return end
	local function Pick(on)
		if on then
			Accent(fs, "text")
		else
			accented[fs] = nil
		end
	end
	hooksecurefunc(fs, "SetFontObject", function(self, obj)
		if not ns.Enabled(KEY) then return end
		Pick(IsPickedFont(obj))
		ns.Refont(self, KEY)
	end)
	Pick(ns.Usable(b.bar) and b.bar:IsShown())
end

-- The slim gold scroll bar beside the page: a faint track, and DaylightUI's pill color (brighter
-- under the mouse or while dragged, when the kit lights it).
local function ScrollTrack(track, Kit)
	local thumb = track:GetChildren()
	local bar = ns.Usable(thumb) and thumb:GetRegions()
	if not ns.Usable(bar) or bar:GetObjectType() ~= "Texture" or not ns.Once(track) then return end
	local S = Kit.SCROLL or { track = { 1, 1, 1, 0.04 }, thumb = { 1, 1, 1, 0.22 }, thumbHover = { 1, 1, 1, 0.38 } }
	local line = track:CreateTexture(nil, "BACKGROUND")
	line:SetPoint("TOPRIGHT", track, "TOPRIGHT", -2, 0)
	line:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", -2, 0)
	line:SetWidth(3)
	line:SetColorTexture(S.track[1], S.track[2], S.track[3], S.track[4] or 1)
	local busy = false
	local function Tint(self, _, _, _, a)
		if busy or not ns.Enabled(KEY) then return end
		local c = (type(a) == "number" and a > 0.8) and S.thumbHover or S.thumb
		busy = true
		self:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
		busy = false
	end
	hooksecurefunc(bar, "SetColorTexture", Tint)
	Tint(bar, nil, nil, nil, 0)
end

local function Row(row, Kit)
	if not ns.Once(row) then return end
	local kind = type(row.item) == "table" and row.item.kind
	if kind == "check" then
		Wash(row)
		for _, child in ipairs({ row:GetChildren() }) do
			if ns.Usable(child) and child:GetObjectType() == "Frame" then Box(child, Kit, true) end
		end
	elseif kind == "slider" then
		for _, child in ipairs({ row:GetChildren() }) do
			if ns.Usable(child) and child:GetObjectType() == "Slider" then
				local thumb = child:GetThumbTexture()
				for _, region in ipairs({ child:GetRegions() }) do
					if ns.Usable(region) and region:GetObjectType() == "Texture" then
						if region == thumb then
							Accent(region, "color", 1)
						elseif region:GetDrawLayer() == "BACKGROUND" then
							region:SetColorTexture(1, 1, 1, 0.1)
						elseif region:GetDrawLayer() == "ARTWORK" then
							Accent(region, "color", 0.75)
						end
					end
				end
			end
		end
	elseif kind == "dropdown" then
		for _, child in ipairs({ row:GetChildren() }) do
			if ns.Usable(child) and child:GetObjectType() == "Button" then
				Box(child, Kit, false)
				Wash(child)
				ns.Guard(Kit.InkGameText, child)
			end
		end
	elseif kind == "sub" then
		for _, region in ipairs({ row:GetRegions() }) do
			if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BORDER" then
				Hairline(region)
			end
		end
	end
	-- Labels stay white; gold values and sub-headings, and gray descriptions, take DaylightUI's inks.
	ns.Guard(Kit.InkGameText, row)
end

local function Page(page, Kit)
	ns.Guard(Kit.InkGameText, page)
	for _, region in ipairs({ page:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BORDER" then
			Hairline(region)
		end
	end
	local rows = type(page.rows) == "table" and page.rows or { page:GetChildren() }
	for _, row in ipairs(rows) do
		if ns.Usable(row) then Row(row, Kit) end
	end
end

-- The window's own pieces: the header line and the line beside the sections (one pixel wide or
-- tall: its backdrop's edge pieces are gone with the backdrop), the section buttons, the scroll bar,
-- and the scroll frame holding the pages.
local function Options(f, Kit)
	local scroll
	for _, region in ipairs({ f:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BORDER" then
			local w, h = region:GetWidth() or 0, region:GetHeight() or 0
			if math.abs(w - 1) < 0.05 or math.abs(h - 1) < 0.05 then Hairline(region) end
		end
	end
	for _, child in ipairs({ f:GetChildren() }) do
		if ns.Usable(child) then
			local kind = child:GetObjectType()
			if kind == "Button" and child.sel and child.bar and child.text then
				NavButton(child)
			elseif kind == "ScrollFrame" then
				scroll = child
			elseif kind == "Frame" and child:IsMouseEnabled() and child:GetNumChildren() == 1
				and math.abs((child:GetWidth() or 0) - 14) < 1 then
				ScrollTrack(child, Kit)
			end
		end
	end
	return scroll and scroll:GetScrollChild()
end

local function OptionsWindow(f, Kit)
	-- (Its own lines first, before the shell is on it.)
	local pages = Options(f, Kit)
	ns.PlainWindow(f)
	ns.Guard(Kit.InkGameText, f)
	local queued = false
	local counted = -1   -- pages at the last look (they're only ever added)
	local function Pass()
		queued = false
		if not ns.Enabled(KEY) or not ns.Usable(pages) then return end
		-- (A dynamic page's relayout sets the height again on every change: nothing new then.)
		local n = pages:GetNumChildren()
		if n == counted then return end
		counted = n
		local fresh = false
		for _, page in ipairs({ pages:GetChildren() }) do
			if ns.Usable(page) and ns.Once(page) then
				fresh = true
				Page(page, Kit)
			end
		end
		-- The template buttons on a page built after the window's last walk (the window walks
		-- itself again on every show).
		if fresh then ns.Dress(f, nil, 0, KEY) end
	end
	local function Queue()
		if queued then return end
		queued = true
		C_Timer.After(0, Pass)
	end
	-- Every page shown (built the first time) sets the scroll child's height to the page's.
	if ns.Usable(pages) then hooksecurefunc(pages, "SetHeight", Queue) end
	Pass()
end

-- ---------------------------------------------------------------------------------------------
-- The announce message editor
-- ---------------------------------------------------------------------------------------------

-- The text well: a flat one-pixel box, a quiet fill, DaylightUI's warm control edge at rest and the
-- accent while typing.
local function InputWell(well, box, Kit)
	if not ns.Usable(well) or not well.SetBackdrop or not ns.Once(well) then return end
	well:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
	well:SetBackdropColor(0, 0, 0, 0.3)
	local edge = Kit.CONTROL_BORDER or { 0.24, 0.21, 0.16 }
	local function Edge(focused)
		if focused then
			local r, g, b = ns.AccentOf(KEY)
			well:SetBackdropBorderColor(r, g, b, 1)
		else
			well:SetBackdropBorderColor(edge[1], edge[2], edge[3], 1)
		end
	end
	Edge(box:HasFocus())
	box:HookScript("OnEditFocusGained", function() if ns.Enabled(KEY) then Edge(true) end end)
	box:HookScript("OnEditFocusLost", function() if ns.Enabled(KEY) then Edge(false) end end)
end

-- The {word} buttons are sized from their words in the game's font: wide enough again in ours.
local function FitTokens(editor)
	for _, child in ipairs({ editor:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" and child.GetFontString then
			local fs = child:GetFontString()
			local text = ns.Usable(fs) and fs:GetText()
			if type(text) == "string" and string.sub(text, 1, 1) == "{" then
				local w = fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth()
				local need = math.ceil((w or 0) + 14)
				if need > (child:GetWidth() or 0) then child:SetWidth(need) end
			end
		end
	end
end

local function Editor(editor, Kit)
	ClearGround(editor)
	ns.PlainWindow(editor)
	local box = editor.box
	if ns.Usable(box) then InputWell(box:GetParent(), box, Kit) end
	InkOnShow(editor, Kit, FitTokens)
	C_Timer.After(0, function() if ns.Enabled(KEY) then ns.Guard(FitTokens, editor) end end)
end

-- ---------------------------------------------------------------------------------------------
-- The pack
-- ---------------------------------------------------------------------------------------------

ns.Pack(KEY, "Camping Kit", function()
	ns.Watch(KEY, "CampingKitCampPanel", function(panel, Kit)
		ClearGround(panel)
		ns.PlainWindow(panel)
		InkOnShow(panel, Kit)
		-- A wanted object's ring is tinted gold when picked (gray when not): the accent instead.
		for _, b in ipairs(type(panel.wants) == "table" and panel.wants or {}) do
			local ring = ns.Usable(b) and b.ring
			if ns.Usable(ring) and ns.Once(ring) then
				local busy = false
				-- (Told apart by the kit's two tints: the accent painted here, and again on a style
				-- change, comes through this hook too and is left as it is.)
				hooksecurefunc(ring, "SetVertexColor", function(self, r, g)
					if busy or not ns.Enabled(KEY) or type(r) ~= "number" or type(g) ~= "number" then return end
					if r == 1 and math.abs(g - 0.82) < 0.01 then
						accented[self] = "vertex"
						busy = true
						PaintAccent(self)
						busy = false
					elseif math.abs(r - 0.55) < 0.01 and math.abs(g - 0.55) < 0.01 then
						accented[self] = nil
					end
				end)
			end
		end
	end)
	ns.Watch(KEY, "KitDockMenu", function(menu, Kit)
		ns.PlainWindow(menu)
		InkOnShow(menu, Kit)
	end)
	-- The "Campfire..." label beside the tent (at a campfire): its gold words in DaylightUI's label
	-- ink. The kit puts the gold back each time the mouse leaves it, so its color is followed;
	-- white under the mouse stays.
	ns.Watch(KEY, "CampingKitCampLabel", function(label)
		local fs = label.text
		if not ns.Usable(fs) or not fs.SetTextColor then return end
		local busy = false
		local function ink(self)
			if busy or not ns.Enabled(KEY) or ns.Look(KEY, "daylightColors") == false then return end
			local r, g, b = self:GetTextColor()
			if not (r and math.abs(r - 1) < 0.06 and math.abs(g - 0.82) < 0.08 and b < 0.25) then return end
			local c = ns.Colors().LABEL
			if type(c) ~= "table" then return end
			busy = true
			self:SetTextColor(c[1], c[2], c[3])
			busy = false
		end
		hooksecurefunc(fs, "SetTextColor", ink)
		ink(fs)
	end)
	ns.Watch(KEY, "CampingKitOptions", OptionsWindow)
	ns.Watch(KEY, "CampingKitAnnounceEditor", Editor)
	ns.Watch(KEY, "KitCoreMoveBar", function(bar, Kit)
		ns.PlainWindow(bar)
		local tick = bar.tick
		if ns.Usable(tick) then Box(tick:GetParent(), Kit, true) end
		InkOnShow(bar, Kit)
	end)
end, { window = true, controls = true, text = true, shadow = true })
