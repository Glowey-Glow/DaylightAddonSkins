-- Shortest Path Forever: its Nearby services panel in the world map's quest log (its paper ground
-- and border gone, DaylightUI's look on its search box, scroll bar and side tab), and the windows
-- ForeverCore opens for it (report, issue, leaderboards, thanks, the Forever addons link) and
-- ForeverCore's right-click menu (the tracker's header and lines).
-- Left alone: everything it draws on the world map and minimap (route lines, pins, docks,
-- portals), the direction arrow and compass (on-screen guides with settings of their own), its
-- settings (the game's Settings window). Its tracker sections: docked under DaylightUI's quest
-- tracker, in its look (below).
--
-- DaylightUI's in-world marker (Quests > Navigation, "marker"): Shortest Path puts the game's
-- marker icon back on every waypoint change, and lays its own pin over it, which showed under
-- DaylightUI's marker. While DaylightUI's marker is on, both are kept at nothing again after it.
--
-- "Hand over to DaylightUI" (off until turned on on its page): its flight master, boat and
-- zeppelin pins on the world map step aside while DaylightUI's map pins show the same.
local _, ns = ...
if not ns.ok then return end

local KEY = "ShortestPathForever"

ns.Target(KEY, "Shortest Path Forever", { window = true, controls = true, text = true, shadow = true,
	defaults = { dock = true }, extraTab = "DaylightUI",
	extra = function(at)
		return {
			{ label = "Quest tracker", items = {
				{ type = "toggle", key = at .. "dock", label = "Put the Forever sections under DaylightUI's quest tracker",
				  desc = "Shortest Path's lifts, boats and journey steps (and any other Forever addon's tracker sections) sit right under your quest list and look like it. Off: ForeverCore places them as it does without DaylightUI." },
			} },
			ns.HandoverGroup(KEY),
		}
	end })

if type(_G.ShortestPathForever) ~= "table" then return end

-- ---------------------------------------------------------------------------------------------
-- Nearby services panel (made when the world map loads)
-- ---------------------------------------------------------------------------------------------

ns.Watch(KEY, "ShortestPathForeverServicesPanel", function(panel, Kit)
	if not ns.Once(panel) then return end
	-- Its ground: the quest log's paper, a BACKGROUND texture of its own. DaylightUI's map window
	-- shows through, as it does behind the game's own quest log.
	for _, region in ipairs({ panel:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			ns.Kill(region)
		end
	end
	-- The quest log's gold border round its list: the first child of its body (the child holding
	-- the scroll list), with every piece of art of its own and of its children.
	local function strip(frame, depth)
		ns.Guard(Kit.Strip, frame)
		if depth > 3 then return end
		for _, child in ipairs({ frame:GetChildren() }) do
			if ns.Usable(child) and child:GetObjectType() == "Frame" then strip(child, depth + 1) end
		end
	end
	for _, body in ipairs({ panel:GetChildren() }) do
		if ns.Usable(body) and body:GetObjectType() == "Frame" and body:GetNumChildren() >= 2 then
			local first, second = body:GetChildren()
			if ns.Usable(first) and first:GetObjectType() == "Frame" and ns.Usable(second)
				and select("#", second:GetChildren()) > 0 then
				local inner = second:GetChildren()
				if ns.Usable(inner) and inner:GetObjectType() == "ScrollFrame" then strip(first, 0) end
			end
		end
	end
	ns.DressOnShow(panel)
end)

ns.Watch(KEY, "ShortestPathForeverServicesTab", function(tab, Kit)
	if ns.Controls(KEY) and ns.Once(tab) then ns.Guard(Kit.SideTab, tab) end
end)

-- ---------------------------------------------------------------------------------------------
-- ForeverCore's windows (the game's portrait window template) and its menu
-- ---------------------------------------------------------------------------------------------

local function Templated(frame, Kit)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	ns.Guard(Kit.Window, frame)
	if not ns.Controls(KEY) then return end
	local function walk()
		if frame:IsShown() then ns.Guard(Kit.Auto, frame, { rows = false, shownOnly = true }) end
	end
	frame:HookScript("OnShow", function() C_Timer.After(0.05, walk) end)
	walk()
end

for _, name in ipairs({ "ShortestPathForeverReport", "ShortestPathForeverIssue", "ForeverLeaderboardsFrame",
	"ForeverCreditsFrame", "ForeverFamilyLink" }) do
	ns.Watch(KEY, name, Templated)
end

-- Leaderboards: its side tabs (one per board), the inset's marble, and its rows' gold (the picked
-- row's auction-house highlight, the progress bar, the line over your own pinned row) in the accent.
local function AccentRow(row)
	if not ns.Usable(row) then return end
	local r, g, b = ns.API.Accent()
	if ns.Usable(row.highlight) then
		row.highlight:SetDesaturated(true)
		row.highlight:SetVertexColor(r, g, b, 0.55)
	end
	if ns.Usable(row.bar) then row.bar:SetColorTexture(r, g, b, 0.55) end
end

ns.Watch(KEY, "ForeverLeaderboardsFrame", function(frame, Kit)
	if not ns.Controls(KEY) then return end
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" and child.Icon and child.key then
			ns.Guard(Kit.SideTab, child)
		end
	end
	local inset = frame.inset
	if ns.Usable(inset) then
		ns.Guard(Kit.Inset, inset)
		for _, region in ipairs({ inset:GetRegions() }) do
			if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "ARTWORK" and region ~= frame.pinnedSeparator then
				-- (Its divider: a strip of the game's frame art under the column heads.)
				local ok, atlas = pcall(region.GetAtlas, region)
				if ok and atlas == "_UI-Frame-InnerTopTile" then region:SetAlpha(0) end
			end
		end
	end
	AccentRow(frame.pinned)
	if ns.Usable(frame.pinnedSeparator) then
		local r, g, b = ns.API.Accent()
		frame.pinnedSeparator:SetColorTexture(r, g, b, 0.35)
	end
	if ns.Usable(frame.scroll) then
		ns.Guard(Kit.EachRow, frame.scroll, AccentRow, "DaylightAddonSkins")
	end
end)

ns.Watch(KEY, "ForeverCoreContextMenu", function(menu, Kit)
	if not ns.Once(menu) then return end
	for _, region in ipairs({ menu:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			ns.Kill(region)
		end
	end
	ns.Shell(menu)
	local scroll = menu.scroll
	if ns.Controls(KEY) and type(scroll) == "table" and ns.Usable(scroll.ScrollBar) then ns.Guard(Kit.ScrollBar, scroll.ScrollBar) end
	ns.DressOnShow(menu, { scrollBars = false })
end)

-- ---------------------------------------------------------------------------------------------
-- The Forever column (ForeverTrackerCompanion: Shortest Path's Lifts, boats and journey steps, and
-- every other Forever addon's tracker sections). ForeverCore hangs it under the game's quest
-- tracker, which DaylightUI hides, so it floated where that tracker would be.
-- Docked here under DaylightUI's quest tracker (look.ShortestPathForever.dock, on unless turned
-- off): its spot is handed to ForeverCore's own settings (ForeverTrackerHost.SetAttached(false),
-- SavePosition), the way its own grip does, and kept up as the tracker grows, shrinks or moves. The
-- tracker is only read, never moved or anchored to (the same way ForeverCore follows Questie's).
-- Its sections take the tracker's look: heads like its Quests header (caps, the header color and
-- size, a line under it), each entry's name like a quest title, each line like an objective, all
-- from DaylightUI's Quests settings, in the tracker's font. It fades with the tracker.
-- ---------------------------------------------------------------------------------------------

local API = ns.API
local upper = string.upper

-- DaylightUI's Quests settings, read once and kept until one of them (or the look) changes: the
-- column is restyled on every tracker layout and timer tick.
local qcache, NONE = {}, {}
local function Quests(path)
	local v = qcache[path]
	if v == nil then
		local ok, got = pcall(API.GetSetting, "Quests", path)
		if ok and got ~= nil then v = got else v = NONE end
		qcache[path] = v
	end
	if v == NONE then return nil end
	return v
end
local function ForgetQuests() wipe(qcache) end

local function QColor(name, fallback)
	local v = Quests("colors." .. name)
	if type(v) == "table" and type(v[1]) == "number" then return v[1], v[2], v[3] end
	local c = ns.Colors()[fallback]
	if type(c) == "table" then return c[1], c[2], c[3] end
	return 1, 1, 1
end

local function QSize(name, fallback)
	local v = Quests("sizes." .. name)
	return type(v) == "number" and v or fallback
end

local function HeaderColor()
	local mode = Quests("colors.headerMode")
	if mode == "accent" then return API.Accent() end
	if mode == "class" or mode == "gradient" then
		local _, token = UnitClass("player")
		local ok, r, g, b = pcall(API.ClassColor, token)
		if ok and r then return r, g, b end
	end
	return QColor("header", "VALUE")
end

local function LineColor()
	local mode = Quests("colors.headerLineMode")
	if mode ~= "custom" and mode ~= nil then return API.Accent() end
	return QColor("headerLine", "LABEL")
end

-- Blizzard's tracker colors (OBJECTIVE_TRACKER_COLOR): a text in one of these is the section's
-- plain text and takes the tracker's colors; any other (a warning, a countdown) is kept.
local function Plain(fs)
	local r, g, b = fs:GetTextColor()
	local set = _G.OBJECTIVE_TRACKER_COLOR
	if type(set) ~= "table" or not r then return true end
	for _, name in ipairs({ "Normal", "NormalHighlight", "Header", "HeaderHighlight" }) do
		local c = set[name]
		if type(c) == "table" and c.r and math.abs(c.r - r) + math.abs(c.g - g) + math.abs(c.b - b) < 0.03 then return true end
	end
	return false
end

local function Ink(fs, size, r, g, b)
	if not ns.Usable(fs) or not fs.SetFont then return end
	if size then
		local face = API.Font()
		local cur, curSize, flags = fs:GetFont()
		if cur ~= face or not curSize or math.abs(curSize - size) > 0.05 then
			pcall(fs.SetFont, fs, face, size, flags or "")
		end
	end
	if r then fs:SetTextColor(r, g, b) end
end

-- How much larger a size must be on the column to look the size it is on DaylightUI's tracker
-- (the column is scaled to the tracker's width).
local zoom = 1

-- The font objects its entries and lines are drawn with (the game's tracker fonts, the native
-- tracker hidden under DaylightUI's): given the tracker's font and sizes while docked, so the
-- column measures its lines in them; what they were is kept and put back when it isn't.
local fontObjects = {}   -- font object -> { role, path, size, flags }

local function Dressed() return ns.Enabled(KEY) and ns.Setting("look." .. KEY .. ".dock") ~= false end

local function PaintFont(obj)
	local f = fontObjects[obj]
	if not f then return end
	if Dressed() and _G.DaylightUIQuestTracker then
		local size = f.role == "title" and QSize("title", 12) or QSize("objective", 11)
		pcall(obj.SetFont, obj, API.Font(), math.floor(size * zoom + 0.5), f.flags or "")
	else
		pcall(obj.SetFont, obj, f.path, f.size, f.flags or "")
	end
end

local function NoteFont(fs, role)
	local obj = fs.GetFontObject and fs:GetFontObject()
	local name = type(obj) == "table" and obj.GetName and obj:GetName()
	-- Only the tracker's own font objects: a shared one (GameFontNormal...) would change text
	-- all over the screen. Text on any other gets its font on itself.
	if type(name) ~= "string" or string.sub(name, 1, 16) ~= "ObjectiveTracker" then
		local size = role == "title" and QSize("title", 12) or QSize("objective", 11)
		Ink(fs, math.floor(size * zoom + 0.5))
		return
	end
	if fontObjects[obj] or not obj.GetFont then return end
	local path, size, flags = obj:GetFont()
	fontObjects[obj] = { role = role, path = path, size = size, flags = flags }
	PaintFont(obj)
end

local function PaintFonts()
	for obj in pairs(fontObjects) do PaintFont(obj) end
end

local lines = setmetatable({}, { __mode = "k" })   -- section -> the line under its head

-- A section's entries and lines, wherever they hang (the tracker keeps them in a contents frame).
local function Entries(frame, depth, head, fn)
	if depth > 4 then return end
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and child ~= head then
			if child.HeaderText or child.Text or child.Dash then fn(child) end
			Entries(child, depth + 1, head, fn)
		end
	end
end

local function StyleSection(module, Kit)
	if not ns.Usable(module) or not Dressed() then return end
	local head = module.Header
	if ns.Usable(head) then
		if ns.Usable(head.Background) then head.Background:SetAlpha(0) end
		local text = head.Text
		if ns.Usable(text) then
			local words = text:GetText()
			if type(words) == "string" and words ~= upper(words) then text:SetText(upper(words)) end
			Ink(text, math.floor(QSize("header", 12) * zoom + 0.5), HeaderColor())
		end
		local line = lines[module]
		if not line then
			line = head:CreateTexture(nil, "ARTWORK")
			line:SetHeight(1)
			line:SetPoint("BOTTOMLEFT", head, "BOTTOMLEFT", 0, 0)
			line:SetPoint("BOTTOMRIGHT", head, "BOTTOMRIGHT", 0, 0)
			lines[module] = line
		end
		local r, g, b = LineColor()
		line:SetColorTexture(r, g, b, 0.6)
		if Kit and ns.Usable(head.MinimizeButton) and ns.Controls(KEY) and ns.Once(head.MinimizeButton) then
			ns.Guard(Kit.CollapseButton, head.MinimizeButton)
		end
	end
	local tr, tg, tb = QColor("title", "VALUE")
	local orr, og, ob = QColor("objective", "TEXT")
	Entries(module, 0, head, function(item)
		local name = item.HeaderText
		if ns.Usable(name) then
			NoteFont(name, "title")
			if Plain(name) then name:SetTextColor(tr, tg, tb) end
		end
		for _, key in ipairs({ "Text", "Dash" }) do
			local fs = item[key]
			if ns.Usable(fs) and fs.GetTextColor then
				NoteFont(fs, "objective")
				if Plain(fs) then fs:SetTextColor(orr, og, ob) end
			end
		end
	end)
end

local styled = setmetatable({}, { __mode = "k" })

local function Styled(module) ns.Guard(StyleSection, module, ns.Kit) end

-- Every section on the column, as they come (a Forever addon adds its own when it loads). Each
-- gets one hook: after its layout ends (the last of the tracker's layout steps it has).
local knownKids = -1
local function Sections(host)
	local kids = host:GetNumChildren()
	if kids == knownKids then return end
	knownKids = kids
	for _, module in ipairs({ host:GetChildren() }) do
		if ns.Usable(module) and module.Header and not styled[module] then
			styled[module] = true
			for _, method in ipairs({ "EndLayout", "LayoutContents", "Update" }) do
				if type(module[method]) == "function" then
					hooksecurefunc(module, method, Styled)
					break
				end
			end
			Styled(module)
		end
	end
end
local function Restyle(host)
	PaintFonts()
	for module in pairs(styled) do
		if ns.Usable(module) and module:GetParent() == host then Styled(module) end
	end
	if host.MarkDirty then pcall(host.MarkDirty, host) end
end
-- Its text changes on a timer (departures counting down) through ForeverCore's own function.
local section = type(_G.ForeverCore) == "table" and _G.ForeverCore.TrackerSection
if type(section) == "table" and type(section.UpdateText) == "function" then
	hooksecurefunc(section, "UpdateText", Styled)
end

-- ---------------------------------------------------------------------------------------------
-- Docking
-- ---------------------------------------------------------------------------------------------

local GAP = 8            -- between the tracker's box and the column's
local PAD = { 8, 6 }     -- the box past the list (DaylightUI's tracker uses the same)
local GRIP = 24          -- ForeverCore's grip strip along the column's top (empty while locked)

-- ForeverCore's grip: a button along the column's top holding one label ("Forever tracker", shown
-- while unlocked or under the mouse). Kept at nothing while docked, put back after.
local function GripLabel(host, alpha)
	for _, child in ipairs({ host:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "Button" and not child.Header then
			for _, region in ipairs({ child:GetRegions() }) do
				if region:GetObjectType() == "FontString" then region:SetAlpha(alpha) end
			end
		end
	end
end

local function TrackerList(holder)
	for _, child in ipairs({ holder:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "ScrollFrame" then return child end
	end
end

local function Column()
	local host, api = _G.ForeverTrackerCompanion, _G.ForeverTrackerHost
	if not ns.Usable(host) or type(api) ~= "table" or type(api.SavePosition) ~= "function"
		or type(api.SetAttached) ~= "function" then
		return
	end
	local db = _G.DaylightAddonSkinsDB
	if type(db) ~= "table" then db = {} _G.DaylightAddonSkinsDB = db end
	local uiScale = function() return UIParent:GetEffectiveScale() end

	-- The box behind the sections, like the tracker's (Quests > box), on a frame of ours under them.
	local box = CreateFrame("Frame", nil, host)
	box:SetFrameLevel(math.max(0, host:GetFrameLevel()))
	box:EnableMouse(false)
	box:Hide()
	local function PaintBox()
		if Quests("box") ~= true then box:Hide() return end
		local opts = { noBorder = Quests("boxBorder") == false }
		if Quests("boxAlphaOwn") == true and type(Quests("boxAlpha")) == "number" then
			opts.bgAlpha = Quests("boxAlpha")
		else
			opts.window = true
		end
		pcall(API.Skin, box, opts)
		box:Show()
	end

	local list, settled, boxX, boxY
	-- The last look's place, size, alpha and scales; empty = look again.
	local last = {}
	local function Moved(...)
		local moved = false
		for i = 1, select("#", ...) do
			local v = select(i, ...)
			if last[i] ~= v then
				last[i] = v
				moved = true
			end
		end
		return moved
	end

	local function Undock()
		wipe(last)
		settled, boxX, boxY = nil, nil, nil
		if db.foreverDocked then
			db.foreverDocked = nil
			pcall(api.SetAttached, true)
			if type(api.SetScale) == "function" and type(db.foreverScale) == "number" then pcall(api.SetScale, db.foreverScale) end
			if type(api.SetLocked) == "function" and db.foreverLocked ~= nil then pcall(api.SetLocked, db.foreverLocked) end
			db.foreverScale, db.foreverLocked = nil, nil
			zoom = 1
			PaintFonts()
			GripLabel(host, 1)
		end
		box:Hide()
		if host:GetAlpha() ~= 1 then host:SetAlpha(1) end
	end

	local function Tick()
		Sections(host)
		local holder = _G.DaylightUIQuestTracker
		if not Dressed() or not ns.Usable(holder) or not holder:IsShown() then
			Undock()
			return
		end
		-- (The tracker's list: found once; the handle stands in until it is there.)
		list = list or TrackerList(holder)
		local list = list or holder
		-- Nothing moved, grew, faded or changed size since the last look: nothing to do.
		-- (Compared value by value: a string of them, made four times a second, was garbage.)
		if not Moved(list:GetRight() or 0, list:GetTop() or 0, list:GetBottom() or 0, host:GetWidth() or 0,
			host:GetHeight() or 0, holder:GetAlpha() or 1, host:GetLeft() or 0, host:GetTop() or 0,
			list:GetEffectiveScale(), host:GetEffectiveScale()) then
			return
		end
		local le = list:GetEffectiveScale() / uiScale()
		local he = host:GetEffectiveScale() / uiScale()
		local right, top, bottom = list:GetRight(), list:GetTop(), list:GetBottom()
		local hw, hh = host:GetWidth(), host:GetHeight()
		if not (right and top and bottom and hw and hw > 0) then return end
		right, top, bottom = right * le, top * le, bottom * le
		local listW = (list:GetWidth() or 0) * le

		if not db.foreverDocked then
			db.foreverDocked = true
			if type(api.GetScale) == "function" then db.foreverScale = api.GetScale() end
			pcall(api.SetAttached, false)
		end
		-- Locked while docked: nothing to drag, and its grip's "Forever tracker" label goes with it.
		-- (Once a session: a column docked before this was added was never locked.)
		if not settled then
			settled = true
			if type(api.IsLocked) == "function" and type(api.SetLocked) == "function" and not api.IsLocked() then
				if db.foreverLocked == nil then db.foreverLocked = false end
				pcall(api.SetLocked, true)
			end
			GripLabel(host, 0)
		end

		-- As wide as the tracker's list, through ForeverCore's own scale; text sizes make up for it.
		if listW > 0 and type(api.SetScale) == "function" and type(api.GetScale) == "function" then
			local want = (api.GetScale() or 1) * listW / (hw * he)
			if math.abs(want - (api.GetScale() or 1)) > 0.01 then pcall(api.SetScale, want) end
		end
		local z = (list:GetEffectiveScale()) / host:GetEffectiveScale()
		if math.abs(z - zoom) > 0.01 then
			zoom = z
			Restyle(host)
		end

		-- Under the tracker's box (or over it, with a list that grows upward), box to box.
		local pad = PAD[2] * le
		local grip = GRIP * he
		local contentH = math.max(0, hh * he - grip)
		local contentTop
		if Quests("growUp") == true then
			contentTop = top + pad + GAP + pad + contentH
		else
			contentTop = bottom - pad - GAP - pad
		end
		local x = right - hw * he
		local y = contentTop + grip - UIParent:GetTop()
		local hl, ht = host:GetLeft(), host:GetTop()
		local at = hl and ht and math.abs(hl * he - x) < 1 and math.abs(ht * he - UIParent:GetTop() - y) < 1
		if not at then pcall(api.SavePosition, x, y) end

		-- The box round the sections (below the grip strip): placed again only when the scales change.
		local px, py = PAD[1] * le / he, PAD[2] * le / he
		if px ~= boxX or py ~= boxY then
			boxX, boxY = px, py
			box:ClearAllPoints()
			box:SetPoint("TOPLEFT", host, "TOPLEFT", -px, -GRIP + py)
			box:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", px, -py)
		end
		if not box:IsShown() and Quests("box") == true then PaintBox() end
		-- It fades with the tracker.
		local a = holder:GetAlpha() or 1
		if host:GetAlpha() ~= a then host:SetAlpha(a) end
	end

	C_Timer.NewTicker(0.25, function() ns.Guard(Tick) end)
	ns.Guard(Tick)
	ns.me.On("StyleChanged", function()
		ForgetQuests()
		wipe(last)
		ns.Guard(PaintBox)
		ns.Guard(Restyle, host)
	end)
	ns.me.On("SettingChanged", function(scope)
		if scope == "Quests" or scope == "general" or scope == "DaylightAddonSkins" then
			ForgetQuests()
			wipe(last)
			ns.Guard(PaintBox)
			ns.Guard(Restyle, host)
		end
	end)
end

ns.me.On("Login", function() C_Timer.After(1, function() ns.Guard(Column) end) end)


ns.Pack(KEY)

-- ---------------------------------------------------------------------------------------------
-- DaylightUI's in-world marker
-- ---------------------------------------------------------------------------------------------

local PIN = "interface\\addons\\shortestpathforever\\media\\pin"

local function IsTheirPin(child, icon)
	if not ns.Usable(child) or child:GetObjectType() ~= "Frame" or child:GetName() then return false end
	if child:GetNumRegions() ~= 1 then return false end
	local tex = child:GetRegions()
	if not ns.Usable(tex) or tex:GetObjectType() ~= "Texture" then return false end
	local file = tex:GetTexture()
	if type(file) == "string" then return string.lower(file) == PIN end
	-- (A file id: told by where it sits, on the marker's icon.)
	local _, rel = tex:GetPoint(1)
	return rel == icon
end

local hidden = setmetatable({}, { __mode = "k" })   -- its pins kept at nothing here

local function Marker()
	local f = _G.SuperTrackedFrame
	if type(f) ~= "table" or not ns.Usable(f.Icon) then return end
	if not ns.Enabled(KEY) or not ns.DaylightHas("Quests", "nav.marker") then
		-- DaylightUI puts the game's icon back itself when its marker goes off; its pin is ours to.
		for pin in pairs(hidden) do
			if ns.Usable(pin) then pin:SetAlpha(1) end
			hidden[pin] = nil
		end
		return
	end
	f.Icon:SetAlpha(0)
	if ns.Usable(f.IconBorder) then f.IconBorder:SetAlpha(0) end
	for _, child in ipairs({ f:GetChildren() }) do
		if IsTheirPin(child, f.Icon) then
			child:SetAlpha(0)
			hidden[child] = true
		end
	end
end

local function Soon()
	-- After Shortest Path's own handler, which runs in the same moment.
	C_Timer.After(0, function() ns.Guard(Marker) end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("SUPER_TRACKING_CHANGED")
events:RegisterEvent("USER_WAYPOINT_UPDATED")
events:SetScript("OnEvent", Soon)
ns.me.On("SettingChanged", function(scope, path)
	if (scope == "Quests" and path == "nav.marker") or (scope == "DaylightAddonSkins" and path == KEY) then Soon() end
end)

-- ---------------------------------------------------------------------------------------------
-- Hand-over: map pins
-- ---------------------------------------------------------------------------------------------

ns.Handover(KEY, {
	ready = function() return type(_G.ShortestPathForeverDB) == "table" end,
	get = function(key) return _G.ShortestPathForeverDB[key] end,
	-- Through the game's Settings, where it registered each of them: its own refresh runs and the
	-- change shows at once. (Its saved table straight, when that isn't there.)
	set = function(key, value)
		local setting = type(Settings) == "table" and type(Settings.GetSetting) == "function"
			and Settings.GetSetting("ShortestPathForever_" .. key)
		if setting and type(setting.SetValue) == "function" and pcall(setting.SetValue, setting, value) then return end
		_G.ShortestPathForeverDB[key] = value
	end,
	list = {
		{ key = "mapFlightMasters", label = "Flight master pins on the world map",
		  daylight = "map pins (Window Skins)",
		  ours = function() return ns.DaylightHas("Skins", "mapFlights") end },
		{ key = "pins", label = "Boat and zeppelin pins on the world map",
		  daylight = "map pins (Window Skins)",
		  ours = function() return ns.DaylightHas("Skins", "mapTravel") end },
		{ key = "destinationPin", label = "Pin over the destination",
		  daylight = "the in-world quest marker (Quests, Navigation)",
		  ours = function() return ns.DaylightHas("Quests", "nav.marker") end },
		{ key = "arrow", label = "Direction arrow (and the route marker it sets)",
		  daylight = "the quest arrow (Quests, Navigation); with Shortest Path's off, routes no longer steer the marker",
		  ours = function() return ns.DaylightHas("Quests", "nav.arrow") end },
	},
})
