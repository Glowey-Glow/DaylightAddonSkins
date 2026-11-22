-- OneForAll: its main window and every popup (confirmations, bug report, Discord, craft list,
-- trainer list, low ranks, quest chain, weight editor, profiles, talent code, Library Books,
-- welcome, what's new, nearby alerts, copy chat, bags full, flight timer, the world map menu,
-- the dropdown menu, and since 6.2.12 Guild Games with its invite and "your turn" popups). It draws them all through two helpers of its kit (OneForAll.UI.FramedPanel:
-- the dark rounded ground and its line; OneForAll.UI.WindowFrame: the gold ring and corner
-- glows), so those two are followed here and what they drew is swapped for DaylightUI's shell.
-- The main window draws its own ground (decorateWindow, kept private): found by name.
-- Left as it draws them: its banner, its gold plate buttons and tabs, its pill switches and slim
-- scroll bars (it repaints them itself), list rows, talent trees, maps, pins and every icon.
-- Its buff reminder, loot feed, info bar and minimap collector bar keep their own card art.
--
-- Hand-over: its own copies of what DaylightUI already does go to DaylightUI by default (asked
-- once, on first load), switched off through OneForAll.QoL.Set while DaylightUI's copy is on, and
-- given back from its page.
local _, ns = ...
if not ns.ok then return end
local L = ns.L

local KEY = "OneForAll"

-- (font = "daylight": its windows' words, from the game's serif templates, in the player's font;
-- the walks below pass fonts = true, since that look keeps the generic walk off text.)
ns.Target(KEY, "OneForAll", { window = true, controls = true, text = true, shadow = true, colors = true,
	font = "daylight",
	defaults = { hideMapButton = false }, extraTab = "DaylightUI",
	extra = function(at)
		return {
			ns.HandoverGroup(KEY),
			{ label = L["World Map"], items = {
				{ type = "toggle", key = at .. "hideMapButton", label = L["Hide OneForAll's World Map Button"],
				  desc = L["The \"1\" logo at the top left of the world map (its quick list of map switches). Switched off in OneForAll's own settings; turn this off again and it comes back. The same switches stay in OneForAll's Quality of Life tab, under World Map."] },
			} },
		}
	end })

local OFA = _G.OneForAll
local UI = type(OFA) == "table" and OFA.UI
if type(UI) ~= "table" or type(UI.FramedPanel) ~= "function" or type(UI.WindowFrame) ~= "function" then return end

-- Its pill switches and slim scroll bars stay its own (it overrides their SetChecked and paints them).
local DRESS = { checks = false, scrollBars = false, fonts = true }

local function Snapshot(frame)
	local seen = {}
	for _, region in ipairs({ frame:GetRegions() }) do seen[region] = true end
	return seen
end

local function KillAdded(frame, before)
	for _, region in ipairs({ frame:GetRegions() }) do
		if not before[region] then ns.Kill(region) end
	end
end

-- ---------------------------------------------------------------------------------------------
-- Colors: it hands almost every color it draws (lines, text, grounds, its tabs and rows)
-- through one function of its own, OneForAll.SkinC, a pass-through left for re-skinning. Its gold
-- comes back in DaylightUI's colors: strong gold as the accent, pale gold text as plain light
-- text, and its warm brown grounds as neutral darks. Every other color (item qualities, the
-- green and red of its numbers) passes as it was.
-- ---------------------------------------------------------------------------------------------

local max, min = math.max, math.min

local function Accent() return ns.AccentOf(KEY) end

-- r, g, b of the accent at brightness v (its own shade kept).
local function AccentAt(v)
	local r, g, b = Accent()
	local top = max(r, g, b, 0.001)
	local k = v / top
	return min(1, r * k), min(1, g * k), min(1, b * k)
end

local function Hue(r, g, b)
	local hi, lo = max(r, g, b), min(r, g, b)
	local d = hi - lo
	if d <= 0 then return 0, 0, hi end
	local h
	if hi == r then h = ((g - b) / d) % 6
	elseif hi == g then h = (b - r) / d + 2
	else h = (r - g) / d + 4 end
	return h * 60, d / hi, hi
end

local function Daylight(r, g, b)
	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return r, g, b end
	local h, s, v = Hue(r, g, b)
	-- Its warm dark grounds (browns, low and dim): neutral darks.
	if v < 0.3 and h >= 15 and h <= 60 and s > 0.05 then
		if ns.Look(KEY, "daylightColors") == false then return r, g, b end
		local n = (r + g + b) / 3
		return n * 0.96, n * 0.96, n * 1.04
	end
	-- Gold (not the orange of legendary items, not yellow-green).
	if h >= 33 and h <= 56 and s > 0.25 then
		if s >= 0.55 then return AccentAt(v) end
		if ns.Look(KEY, "daylightColors") == false then return r, g, b end
		local n = v * 0.96
		return n, n, n
	end
	return r, g, b
end

local origSkinC = OFA.SkinC
if type(origSkinC) == "function" then
	OFA.SkinC = function(r, g, b, ...)
		if ns.Enabled(KEY) then
			local ok, nr, ng, nb = pcall(Daylight, r, g, b)
			if ok then return origSkinC(nr, ng, nb, ...) end
		end
		return origSkinC(r, g, b, ...)
	end
end

-- Its button plates (gold art: at rest, picked, the glow round a picked one) are files, not
-- colors. The game hands its files a number of its own for the session: each is set once on a
-- hidden texture here to learn it, and a plate showing one is grayed and tinted.
local ASSETS = "Interface\\AddOns\\OneForAll\\Assets\\"
local plateKind = ns.FileIDs({ [ASSETS .. "btn_m_normal"] = "rest", [ASSETS .. "btn_m_active"] = "picked",
	[ASSETS .. "btn_glow"] = "picked" })

local plates = setmetatable({}, { __mode = "k" })   -- texture -> its kind, once painted

local painting = false
local function PaintPlate(tex, kind)
	painting = true
	tex:SetDesaturated(true)
	if kind == "picked" then
		tex:SetVertexColor(AccentAt(0.85))
	else
		tex:SetVertexColor(0.42, 0.42, 0.45)
	end
	painting = false
end

-- Since 6.2.12 it can tint a plate (the green "Open guide" button of the Skill-Up Helper) and
-- puts white back to end the tint. A tint means something and is kept, over the grayed art; white
-- is this pack's paint again.
local function White(r, g, b)
	return type(r) == "number" and type(g) == "number" and type(b) == "number" and r > 0.99 and g > 0.99 and b > 0.99
end

local function FollowPlate(tex, kind)
	if White(tex:GetVertexColor()) then PaintPlate(tex, kind) else tex:SetDesaturated(true) end
	ns.HookOnce(tex, "SetVertexColor", function(self, r, g, b)
		if not painting and White(r, g, b) then PaintPlate(self, kind) end
	end, KEY)
end

-- A color it set straight on a piece (not through SkinC: its side lists' headings, some lines
-- and arrows), when it is gold.
local function Regold(r, g, b)
	if type(r) ~= "number" then return nil end
	local nr, ng, nb = Daylight(r, g, b)
	if math.abs(nr - r) + math.abs(ng - g) + math.abs(nb - b) < 0.01 then return nil end
	return nr, ng, nb
end

local function Plates(root, depth)
	if not ns.Usable(root) or depth > 12 then return end
	for _, region in ipairs({ root:GetRegions() }) do
		local kind = region:GetObjectType()
		if kind == "Texture" then
			if not plates[region] then
				local ok, id = pcall(region.GetTexture, region)
				local plate = ok and id ~= nil and plateKind[id]
				if plate then
					plates[region] = plate
					FollowPlate(region, plate)
				else
					local r, g, b, a = region:GetVertexColor()
					local nr, ng, nb = Regold(r, g, b)
					if nr then region:SetVertexColor(nr, ng, nb, a) end
				end
			end
		elseif kind == "FontString" then
			local r, g, b, a = region:GetTextColor()
			local nr, ng, nb = Regold(r, g, b)
			if nr then region:SetTextColor(nr, ng, nb, a) end
		end
	end
	for _, child in ipairs({ root:GetChildren() }) do Plates(child, depth + 1) end
end

-- It sets a plate's gray on and off as a button is enabled and disabled: kept gray.
if type(OFA.Desat) == "function" then
	local origDesat = OFA.Desat
	OFA.Desat = function(t, v, ...)
		if plates[t] and ns.Enabled(KEY) then v = true end
		return origDesat(t, v, ...)
	end
end

local function PlatesIn(frame)
	if ns.Enabled(KEY) and ns.Controls(KEY) then Plates(frame, 0) end
end

-- Its pages, side lists and views are built when first opened: after a click inside one of its
-- windows, that window's plates are looked for again (one walk at most every 0.3 s; a click
-- anywhere else costs nothing but the test).
local watched = setmetatable({}, { __mode = "k" })
local clicks = CreateFrame("Frame")
local pending = setmetatable({}, { __mode = "k" })
local queued = false
local function Walk()
	queued = false
	for frame in pairs(pending) do
		pending[frame] = nil
		if ns.Usable(frame) and frame:IsShown() then ns.Guard(PlatesIn, frame) end
	end
end
clicks:SetScript("OnEvent", function()
	local any = false
	for frame in pairs(watched) do
		if frame:IsShown() then
			any = true
			if frame:IsMouseOver() then pending[frame] = true end
		end
	end
	if not any then
		clicks:UnregisterEvent("GLOBAL_MOUSE_UP")
	elseif next(pending) and not queued then
		queued = true
		C_Timer.After(0.3, Walk)
	end
end)
local function Watched(frame)
	watched[frame] = true
	ns.ScriptOnce(frame, "OnShow", function() clicks:RegisterEvent("GLOBAL_MOUSE_UP") end, KEY)
	if frame:IsShown() then clicks:RegisterEvent("GLOBAL_MOUSE_UP") end
end

-- ---------------------------------------------------------------------------------------------
-- Popups: FramedPanel's ground and line, WindowFrame's ring and glows
-- ---------------------------------------------------------------------------------------------

-- Guild Games (6.2.12, OneForAllGuildGames): a FramedPanel popup like the rest, with a tiled wood
-- ground of its own laid over the panel right after (the game's garrison background); that goes
-- too, so DaylightUI's shell is its ground. Its card table, seats, chips and marks are the game
-- and stay. Looked for on each show (it is added after FramedPanel returns).
local GAMES = "OneForAllGuildGames"
local woodKind
local woodGone = setmetatable({}, { __mode = "k" })
local function GamesGround(frame)
	if woodGone[frame] or not ns.Enabled(KEY) or not frame.GetName or frame:GetName() ~= GAMES then return end
	woodKind = woodKind or ns.FileIDs({ ["Interface\\Garrison\\GarrisonUIBackground"] = true })
	for _, region in ipairs({ frame:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			local ok, id = pcall(region.GetTexture, region)
			if ok and type(id) == "string" then id = string.lower(id) end
			if ok and id ~= nil and woodKind[id] then
				ns.Kill(region)
				woodGone[frame] = true
			end
		end
	end
end

local function PopupExtra(frame)
	PlatesIn(frame)
	GamesGround(frame)
end

local origFramed, origWindowFrame = UI.FramedPanel, UI.WindowFrame

UI.FramedPanel = function(f, ...)
	if type(f) ~= "table" or not f.GetRegions or not ns.Enabled(KEY) then return origFramed(f, ...) end
	local before = Snapshot(f)
	local a, b, c = origFramed(f, ...)
	local ok, err = pcall(function()
		KillAdded(f, before)
		-- A window of its own on the screen, or a panel inside one.
		local onScreen = f.GetParent and f:GetParent() == UIParent
		ns.Shell(f, onScreen and { window = true } or nil, KEY)
		if ns.Once(f) and f.HookScript then
			ns.WithKit(function() ns.DressOnShow(f, DRESS, PopupExtra, KEY) end)
			-- Guild Games builds its tables, invite rows and pages as they're clicked, like the main
			-- window: its plates are looked for again after a click inside it.
			if onScreen and f.GetName and f:GetName() == GAMES then Watched(f) end
		end
	end)
	if not ok then geterrorhandler()(err) end
	return a, b, c
end

UI.WindowFrame = function(deco, frame, ...)
	if type(deco) ~= "table" or not deco.GetRegions or not ns.Enabled(KEY) then return origWindowFrame(deco, frame, ...) end
	local before = Snapshot(deco)
	local ring = origWindowFrame(deco, frame, ...)
	local ok, err = pcall(KillAdded, deco, before)
	if not ok then geterrorhandler()(err) end
	return ring
end

-- ---------------------------------------------------------------------------------------------
-- The main window: its rounded ground (a BACKGROUND RoundRect) and its inset's ground go; its
-- banner, title and buttons stay.
-- ---------------------------------------------------------------------------------------------

ns.Watch(KEY, "OneForAllFrame", function(frame)
	if not ns.Once(frame) then return end
	for _, region in ipairs({ frame:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			ns.Kill(region)
		end
	end
	local inset = frame.Inset
	if type(inset) == "table" then ns.Kill(inset.Bg) end
	ns.Shell(frame, { window = true })
	ns.DressOnShow(frame, DRESS, PlatesIn)
	Watched(frame)
end)

-- The "target it" button of its nearby alerts (secure: its plate only recolored, never moved).
ns.Watch(KEY, "OneForAllAlertTargetButton", function(button)
	if not ns.Once(button) then return end
	PlatesIn(button)
	button:HookScript("OnShow", PlatesIn)
end)

-- The quest share popup is the game's plain template window (only its title bar tinted).
ns.Watch(KEY, "OneForAllQuestSharePopup", function(frame, Kit)
	if not ns.Once(frame) then return end
	ns.Guard(Kit.Window, frame)
	ns.DressOnShow(frame, DRESS)
end)

ns.Pack(KEY)

-- ---------------------------------------------------------------------------------------------
-- Hand-over
-- ---------------------------------------------------------------------------------------------

local QoL = OFA.QoL
if type(QoL) ~= "table" or type(QoL.Get) ~= "function" or type(QoL.Set) ~= "function" then return end

local has = ns.DaylightHas
local function notOne(v) return type(v) == "number" and v ~= 1 end
local function moduleOn(name) return function() return ns.ModuleOn(name) end end
local function C(key, label, daylight, ours, extra)
	local item = { key = key, label = label, daylight = daylight, ours = ours }
	if extra then for k, v in pairs(extra) do item[k] = v end end
	return item
end
local RELOAD = { reload = true }

-- (From an audit of OneForAll 6.2.10 against every DaylightUI module, checked again for 6.2.11 and
-- 6.2.12: its new junk list key, gray map quests, walking routes and Guild Games have no
-- DaylightUI twin. 6.2.13: its per-service gossip skips, below. Left out: its NPC tooltip quests, which turn themselves off while Questie is loaded; its chat font size, which has no
-- off to give back.)
ns.Handover(KEY, {
	ready = function() return type(_G.OneForAllDB) == "table" end,
	get = function(key) return QoL.Get(key) end,
	set = function(key, value)
		-- (Since 6.2.10 switching its sparkles off resets the game's outline settings and asks for a
		-- restart, while DaylightUI's own sparkles turn them straight back on: handed over quietly.)
		if key == "questSparkles" and value == false and type(_G.OneForAllDB) == "table" then
			_G.OneForAllDB.qol = _G.OneForAllDB.qol or {}
			_G.OneForAllDB.qol.questSparkles = false
			return
		end
		QoL.Set(key, value)
	end,
	list = {
		-- Chat: DaylightUI_Chat draws its own panel over the game's chat windows.
		C("chatHide", L["Chat Hide Button (the Speech Bubble on the Chat)"],
			L["its chat panel; OneForAll's button hides the chat windows Daylight UI's chat is built on"], moduleOn("Chat")),
		C("chatAutoHide", L["Hide the Chat After a While"], ns.In(L["the chat's own fading"], "Chat"), moduleOn("Chat"), { off = 0 }),
		C("copyChat", L["Copy Buttons on the Chat"], ns.In(L["the chat's Copy button"], "Chat"),
			function() return has("Chat", "copyButton") end),
		C("chatHistory", L["Up and Down Bring Back Sent Messages"], ns.In(L["the same in its chat box"], "Chat"),
			function() return has("Chat", "arrowHistory") end, RELOAD),
		-- Minimap
		C("mmCollect", L["Minimap Button Collector"], ns.In(L["the addon drawer under the minimap"], "Info Panel"),
			function() return has("InfoPanel", "map.enabled") and has("InfoPanel", "map.drawer") end),
		C("mmSquare", L["Square Minimap"], ns.In(L["its own square minimap"], "Info Panel"),
			function() return has("InfoPanel", "map.enabled") end),
		-- World map
		C("lmDungeons", L["Dungeon Entrances on the World Map"], ns.In(L["map pins"], "Window Skins"),
			function() return has("Skins", "mapDungeons") end),
		C("lmFlight", L["Flight Masters on the World Map"], ns.In(L["map pins"], "Window Skins"),
			function() return has("Skins", "mapFlights") end),
		C("lmTransport", L["Boats, Zeppelins and the Tram on the World Map"], ns.In(L["map pins"], "Window Skins"),
			function() return has("Skins", "mapTravel") end),
		C("mapFog", L["Remove the Map's Fog"], ns.In(L["map reveal"], "Window Skins"),
			function() return has("Skins", "mapReveal") end),
		C("flightMapNow", L["Open the Flight Map at Once"], ns.In(L["its NPC window and skip-gossip"], "Quality of Life"),
			function() return has("NPC", "enabled") or has("QoL", "skipGossip") end),
		-- NPCs (6.2.13, QoL.GOSSIP_SERVICES: one switch per service, all off until the player ticks them
		-- in its "Skip the talk at service NPCs" list): the NPC's one service button pressed at once,
		-- as DaylightUI's skip-gossip does for every service.
		C("gossipVendor", L["Skip the Talk at Vendors"], ns.In(L["skip gossip"], "Quality of Life"),
			function() return has("QoL", "skipGossip") end),
		C("gossipBank", L["Skip the Talk at Bankers"], ns.In(L["skip gossip"], "Quality of Life"),
			function() return has("QoL", "skipGossip") end),
		C("gossipTrainer", L["Skip the Talk at Trainers"], ns.In(L["skip gossip"], "Quality of Life"),
			function() return has("QoL", "skipGossip") end),
		C("gossipAuction", L["Skip the Talk at Auctioneers"], ns.In(L["skip gossip"], "Quality of Life"),
			function() return has("QoL", "skipGossip") end),
		C("gossipStable", L["Skip the Talk at Stable Masters"], ns.In(L["skip gossip"], "Quality of Life"),
			function() return has("QoL", "skipGossip") end),
		C("gossipGuildBank", L["Skip the Talk at the Guild Bank"], ns.In(L["skip gossip"], "Quality of Life"),
			function() return has("QoL", "skipGossip") end),
		C("gossipTabard", L["Skip the Talk at Guild Tabard Vendors"], ns.In(L["skip gossip"], "Quality of Life"),
			function() return has("QoL", "skipGossip") end),
		C("gossipBattle", L["Skip the Talk at Battlemasters"], ns.In(L["skip gossip"], "Quality of Life"),
			function() return has("QoL", "skipGossip") end),
		-- Quality of life
		C("flightTimes", L["Flight Timer"], ns.In(L["the flight timer"], "Quality of Life"),
			function() return has("QoL", "flightTimer") end),
		C("lootFeed", L["Loot Feed"], ns.In(L["the loot feed"], "Quality of Life"),
			function() return has("QoL", "lootFeed") end),
		C("quickLoot", L["Faster Looting"], ns.In(L["fast loot"], "Quality of Life"),
			function() return has("QoL", "fastLoot") end),
		C("questSparkles", L["Quest Loot Sparkles"], ns.In(L["loot sparkles"], "Quality of Life"),
			function() return has("QoL", "lootSparkles") end, RELOAD),
		-- DaylightUI 1.7.3 removed its object glow, so nothing does this on its side any more: kept
		-- only so a sparkle handed over before is given back to OneForAll (never asked, never listed).
		C("nodeGlow", L["Herb and Ore Sparkle"], ns.In(L["object glow"], "Quality of Life"),
			function() return false end, { reload = true, gone = true }),
		C("cameraZoom", L["Farther Camera Zoom"], ns.In(L["camera distance"], "Quality of Life"),
			function() return has("QoL", "cameraZoom", notOne) end, RELOAD),
		C("hideErrors", L["Hide Error Messages"], ns.In(L["quiet errors and its own error text"], "Quality of Life"),
			function() return has("QoL", "quietErrors") or has("QoL", "errorText") end),
		C("autoAccept", L["Accept Quests Automatically"], ns.In(L["auto accept"], "Quality of Life"),
			function() return has("QoL", "questAccept") end),
		C("autoTurnIn", L["Turn in Quests Automatically"], ns.In(L["auto turn in"], "Quality of Life"),
			function() return has("QoL", "questTurnIn") end),
		-- Windows
		C("moveWindows", L["Move the Game's Windows"], ns.In(L["moving windows and its own windows"], "Window Skins"),
			function() return ns.Enabled() end, RELOAD),
		C("resizeWindows", L["Resize the Game's Windows"], ns.In(L["Ctrl + wheel sizing"], "Window Skins"),
			function() return ns.Enabled() end),
		-- Vendors
		C("autoRepair", L["Repair at Vendors"], ns.In(L["auto repair"], "Bags"), function() return has("Bags", "autoRepair") end),
		C("sellJunk", L["Sell Junk at Vendors"], ns.In(L["sell junk"], "Bags"), function() return has("Bags", "sellJunk") end),
		-- Tooltip, nameplates, info
		C("unitTarget", L["\"Target:\" Line in Unit Tooltips"], ns.In(L["the target line"], "Tooltip"),
			function() return has("Tooltip", "showTarget") end),
		-- (6.2.7: it moves the tooltip to the mouse every frame, over DaylightUI's own anchor.)
		C("tipMouse", L["Tooltip at the Mouse"], ns.In(L["the tooltip's anchor (the game's spot or the mouse)"], "Tooltip"),
			moduleOn("Tooltip")),
		C("questMarks", L["Quest Marks on Nameplates"], ns.In(L["quest marks on its nameplates"], "Nameplates"),
			function() return has("Nameplates", "quest") end),
		C("infoBar", L["OneForAll's Info Bar"], ns.In(L["the data texts"], "Info Panel"),
			function() return has("InfoPanel", "data.enabled") end),
		-- The game's frames DaylightUI hides: work done on bars no one sees.
		C("classColors", L["Class Colors on the Game's Unit Frames"], ns.In(L["its own unit frames"], "Unit Frames"),
			moduleOn("UnitFrames")),
		C("bagSlots", L["Free Slots on the Game's Backpack Button"], ns.In(L["the bags data text and its bags"], "Bags"),
			moduleOn("Bags")),
		C("questXP", L["Quest XP on the Game's Experience Bar"], ns.In(L["its experience bar with banked quest XP"], "Info Panel"),
			function() return has("InfoPanel", "xp.enabled") end),
		-- A plain option of this pack's, not a conflict.
		{ key = "mapButton", switch = "hideMapButton", ours = function() return true end },
	},
})
