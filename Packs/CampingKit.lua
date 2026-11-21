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
-- tick in your accent, its text inked. The layout editing bar (KitCoreEditBar, Kit Core 23 on): the
-- same.
-- Camping Kit 1.11.1 ships Kit Core 31, whose settings window is drawn anew: a search box in the
-- header, each sub-heading's rows on a card, short choices as a row of buttons (the picked one
-- lit), color squares with a Custom... button, on/off chips, a table of tick boxes with rows that
-- fold open, fold arrows, small dark buttons. All of them are made of the same few pieces (a dark
-- well with four gold one-pixel edges, a gold wash under the mouse, a gold fill and gold words on
-- the picked one, a gold arrow), so they are dressed piece by piece, wherever a row holds them
-- (Deep below): wells and edges as above, the picked fill and words in your accent, arrows in the
-- text ink, the edge round the color in use in your accent. A color square's color is the setting
-- and stays.
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
	if how == "color" then
		ns.FillAccent(region, alphas[region] or 1, nil, KEY)
	elseif how == "vertex" then
		ns.PaintAccent(region, alphas[region] or 1, nil, KEY)
	else
		region:SetTextColor(ns.AccentOf(KEY))
	end
end

local function Accent(region, how, alpha)
	if not ns.Usable(region) then return end
	accented[region], alphas[region] = how, alpha
	PaintAccent(region)
end

local function Repaint()
	if not ns.Enabled(KEY) then return end
	for region in pairs(accented) do PaintAccent(region) end
end
local function QueueRepaint()
	if not next(accented) then return end
	ns.Queue("CampingKit:accents", Repaint, KEY)
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
	ns.ScriptOnce(frame, "OnShow", ink, KEY)
	ink()
end

-- Words the kit paints gold while their button is the picked one (a choice button, a chip,
-- Custom...) and gray while it isn't, again on every repaint: the accent in place of the gold.
-- (Told apart by the kit's own colors: the accent painted here, and again on a style change, comes
-- through this hook too and is left as it is.)
local function FollowPick(fs)
	if not ns.Usable(fs) or not fs.SetTextColor or not fs.GetTextColor then return end
	local busy = false
	local function follow(self, r, g, b)
		if busy or not ns.Enabled(KEY) or type(r) ~= "number" or type(g) ~= "number" then return end
		if r == 1 and math.abs(g - 0.82) < 0.01 and (b or 0) < 0.05 then
			accented[self] = "text"
			busy = true
			PaintAccent(self)
			busy = false
		elseif (math.abs(r - 0.75) < 0.01 and math.abs(g - 0.72) < 0.01) or (math.abs(r - 0.6) < 0.01 and math.abs(g - 0.58) < 0.01) then
			accented[self] = nil
		end
	end
	if ns.HookOnce(fs, "SetTextColor", follow, KEY) then follow(fs, fs:GetTextColor()) end
end

-- Kit Core's pieces, wherever a row holds them (Kit Core 23 on; see the top), `depth` levels down.
-- Each frame once: the kit makes a row's pieces with the row and only shows, hides and recolors
-- them after.
local function Deep(f, Kit, depth)
	if depth > 6 or not ns.Usable(f) then return end
	local kind = f:GetObjectType()
	if kind ~= "Frame" and kind ~= "Button" then return end
	-- (A button of the game's template is the walk's.)
	if f.Left and f.Middle and f.Right then return end
	-- A color square: its color and its x are the setting; the gold edge round the one in use.
	if ns.Usable(f.fill) and ns.Usable(f.edge) then
		Accent(f.edge, "color", 1)
		return
	end
	local back, edges = false, nil
	for _, region in ipairs({ f:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" then
			local layer = region:GetDrawLayer()
			if layer == "HIGHLIGHT" then
				region:SetColorTexture(1, 1, 1, WASH)
			elseif layer == "BORDER" then
				edges = edges or {}
				edges[#edges + 1] = region
			elseif layer == "BACKGROUND" and region ~= f.sel and region ~= f.openBg then
				back = true
			end
		end
	end
	if edges then
		if #edges >= 4 and back and not f.sel then
			-- A well: a tick box (16 square) has a tick, any other an arrow or nothing.
			local w, h = f:GetSize()
			local tick = f.tick ~= nil or (math.abs((w or 0) - 16) < 1 and math.abs((h or 0) - 16) < 1)
			Box(f, Kit, tick)
		elseif #edges >= 4 then
			-- A chip or Custom...: its fill is its own (the picked one's below).
			local edge = Kit.CONTROL_BORDER or { 0.24, 0.21, 0.16 }
			for _, region in ipairs(edges) do region:SetColorTexture(edge[1], edge[2], edge[3], 1) end
		else
			for _, region in ipairs(edges) do Hairline(region) end
		end
	end
	if ns.Usable(f.sel) then
		Accent(f.sel, "color", 0.14)
		FollowPick(f.text)
	end
	-- (A table row folded open: its faint gold ground.)
	if ns.Usable(f.openBg) and f.openBg.SetColorTexture then f.openBg:SetColorTexture(1, 1, 1, 0.03) end
	if ns.Usable(f.arrow) and f.arrow.SetVertexColor then
		local t = Kit.TEXT or { 1, 1, 1 }
		f.arrow:SetVertexColor(t[1], t[2], t[3])
	end
	ns.Guard(Kit.InkGameText, f)
	for _, child in ipairs({ f:GetChildren() }) do Deep(child, Kit, depth + 1) end
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
	ns.HookOnce(fs, "SetFontObject", function(self, obj)
		if not ns.Enabled(KEY) then return end
		Pick(IsPickedFont(obj))
		ns.Refont(self, KEY)
	end, KEY)
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
	ns.HookOnce(bar, "SetColorTexture", Tint, KEY)
	Tint(bar, nil, nil, nil, 0)
end

local function Row(row, Kit)
	if not ns.Once(row) then return false end
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
	-- Every other piece in it (Kit Core 23 on: choice buttons, chips, color squares, table cells,
	-- fold arrows, small buttons).
	ns.Guard(Deep, row, Kit, 0)
	return true
end

-- A page: its heading and line once, then every row on it not dressed yet (Kit Core 23 on makes
-- rows after the page too: the search results page gets its rows with each search) and the cards
-- behind a sub-heading's rows (a faint ground and four gold edges: the edges quiet hairlines).
-- Says whether anything on it was new.
local function Page(page, Kit)
	local fresh = false
	if ns.Once(page) then
		fresh = true
		ns.Guard(Kit.InkGameText, page)
		for _, region in ipairs({ page:GetRegions() }) do
			if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BORDER" then
				Hairline(region)
			end
		end
	end
	for _, child in ipairs({ page:GetChildren() }) do
		if ns.Usable(child) then
			if type(child.item) == "table" then
				if Row(child, Kit) then fresh = true end
			elseif ns.Once(child) then
				fresh = true
				for _, region in ipairs({ child:GetRegions() }) do
					if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BORDER" then
						Hairline(region)
					end
				end
				ns.Guard(Kit.InkGameText, child)
			end
		end
	end
	return fresh
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
			elseif kind == "Button" and ns.Usable(child.text) and not child.sel then
				-- (Kit Core 23 on: "Move everything" and "Key bindings" under the sections.)
				Wash(child)
				ns.Guard(Kit.InkGameText, child)
			elseif kind == "EditBox" then
				-- (Kit Core 23 on: the "Find a setting" box, a well like the rest; its glass in the text ink.)
				Box(child, Kit, false)
				ns.Guard(Kit.InkGameText, child)
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
	local function Pass()
		if not ns.Enabled(KEY) or not ns.Usable(pages) then return end
		-- (A page's relayout sets the height again on every change: each page and row is looked
		-- at, and only what is new is dressed.)
		local fresh = false
		for _, page in ipairs({ pages:GetChildren() }) do
			if ns.Usable(page) and Page(page, Kit) then fresh = true end
		end
		-- The template buttons on a page built after the window's last walk (the window walks
		-- itself again on every show).
		if fresh then ns.Dress(f, nil, 0, KEY) end
	end
	-- Every page shown (built the first time; the search results with each search) sets the scroll
	-- child's height to the page's, its rows made and painted by then: dressed right there, before
	-- it's drawn.
	if ns.Usable(pages) then ns.HookOnce(pages, "SetHeight", function() ns.Guard(Pass) end, KEY) end
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
	ns.ScriptOnce(box, "OnEditFocusGained", function() if ns.Enabled(KEY) then Edge(true) end end, KEY)
	ns.ScriptOnce(box, "OnEditFocusLost", function() if ns.Enabled(KEY) then Edge(false) end end, KEY)
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
	ns.Queue("CampingKit:editorTokens", function() if ns.Enabled(KEY) then ns.Guard(FitTokens, editor) end end, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- The pack
-- ---------------------------------------------------------------------------------------------

-- Its windows are made the first time they open: each is dressed right after the call or click
-- that opens it, before it's drawn. The settings window and the placement bar open through Kit
-- Core's shared table; "This campfire..." opens from the four buttons by the tent; the Kits menu
-- from the shared minimap button. The watches below stay for every other way in (the kit's
-- right-click menu, and the panel opened by itself).
local OPENERS = {
	CampingKitCampHeader = "OnMouseUp",
	CampingKitCampListButton = "OnClick",
	CampingKitCampLabel = "OnClick",
	CampingKitCampFire = "OnClick",
	LibDBIcon10_KitDock = "OnClick",
}
local hooked = false
local function Now() ns.WatchNow() end

local function HookOpeners()
	if hooked then return end
	hooked = true
	local core = _G.KitCore
	if type(core) == "table" then
		if type(core.SetPanelUnlocked) == "function" then ns.HookOnce(core, "SetPanelUnlocked", Now, KEY) end
		local proto = core.proto
		if type(proto) == "table" and type(proto.OpenOptions) == "function" then
			ns.HookOnce(proto, "OpenOptions", Now, KEY)
		end
		-- (Kit Core 23 on: editing a kit's layout makes and shows its bar, KitCoreEditBar.)
		if type(proto) == "table" and type(proto.SetEdit) == "function" then
			ns.HookOnce(proto, "SetEdit", Now, KEY)
		end
	end
	-- (The buttons are made at login, the minimap button only once a second kit shares it.)
	for name, script in pairs(OPENERS) do
		ns.Watch(KEY, name, function(b)
			-- (Hooked directly: the tent's buttons are part of its secure HUD, and ns.ScriptOnce
			-- refuses a protected frame.)
			if ns.Usable(b) and b.HookScript then b:HookScript(script, Now) end
		end)
	end
end

ns.Pack(KEY, "Camping Kit", function()
	HookOpeners()
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
				ns.HookOnce(ring, "SetVertexColor", function(self, r, g)
					if busy or not ns.Enabled(KEY) or type(r) ~= "number" or type(g) ~= "number" then return end
					if r == 1 and math.abs(g - 0.82) < 0.01 then
						accented[self] = "vertex"
						busy = true
						PaintAccent(self)
						busy = false
					elseif math.abs(r - 0.55) < 0.01 and math.abs(g - 0.55) < 0.01 then
						accented[self] = nil
					end
				end, KEY)
			end
		end
	end)
	ns.Watch(KEY, "KitDockMenu", function(menu, Kit)
		ns.PlainWindow(menu)
		InkOnShow(menu, Kit)
	end)
	-- The "Campfire..." label beside the tent (at a campfire): its gold words in DaylightUI's label
	-- ink. The kit puts the gold back each time the mouse leaves it, so its color is followed;
	-- white under the mouse stays. (Made at login, hidden: the watch finds it before it can show.)
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
		-- (Hooked directly: the label is one of the tent's buttons, which may be protected.)
		hooksecurefunc(fs, "SetTextColor", ink)
		ink(fs)
	end)
	ns.Watch(KEY, "CampingKitOptions", OptionsWindow)
	-- The editor opens only from a call kept inside the kit (and only with an older Kit Core than
	-- the one it ships), so nothing can be hooked: the watch finds it, at most a frame later.
	ns.Watch(KEY, "CampingKitAnnounceEditor", Editor)
	ns.Watch(KEY, "KitCoreMoveBar", function(bar, Kit)
		ns.PlainWindow(bar)
		local tick = bar.tick
		if ns.Usable(tick) then
			Box(tick:GetParent(), Kit, true)
		else
			-- (Kit Core 23 on keeps the Snap tick to itself: its box is found among the bar's pieces.)
			for _, child in ipairs({ bar:GetChildren() }) do ns.Guard(Deep, child, Kit, 0) end
		end
		InkOnShow(bar, Kit)
	end)
	ns.Watch(KEY, "KitCoreEditBar", function(bar, Kit)
		ns.PlainWindow(bar)
		InkOnShow(bar, Kit)
	end)
end, { window = true, controls = true, text = true, shadow = true })
