-- OneForAll: its main window and every popup (confirmations, bug report, Discord, craft list,
-- trainer list, low ranks, quest chain, weight editor, profiles, talent code, Library Books,
-- welcome, what's new, nearby alerts, copy chat, bags full, flight timer, the world map menu,
-- the dropdown menu). It draws them all through two helpers of its kit (OneForAll.UI.FramedPanel:
-- the dark rounded ground and its line; OneForAll.UI.WindowFrame: the gold ring and corner
-- glows), so those two are followed here and what they drew is swapped for DaylightUI's shell.
-- The main window draws its own ground (decorateWindow, kept private): found by name.
-- Left as it draws them: its banner, its gold plate buttons and tabs, its pill switches and slim
-- scroll bars (it repaints them itself), list rows, talent trees, maps, pins and every icon.
-- Its buff reminder, loot feed, info bar and minimap collector bar keep their own card art.
--
-- "Hand over to DaylightUI" (off until turned on on its page): its own copies of what DaylightUI
-- already does are switched off through OneForAll.QoL.Set, while DaylightUI's copy is on.
local _, ns = ...
if not ns.ok then return end

local KEY = "OneForAll"

ns.Target(KEY, "OneForAll", { window = true, controls = true, text = true, shadow = true, colors = true,
	defaults = { hideMapButton = false }, extraTab = "DaylightUI",
	extra = function(at)
		return {
			ns.HandoverGroup(KEY),
			{ label = "World map", items = {
				{ type = "toggle", key = at .. "hideMapButton", label = "Hide OneForAll's world map button",
				  desc = "The \"1\" logo at the top left of the world map (its quick list of map switches). Switched off in OneForAll's own settings; turn this off again and it comes back. The same switches stay in OneForAll's Quality of Life tab, under World Map." },
			} },
		}
	end })

local OFA = _G.OneForAll
local UI = type(OFA) == "table" and OFA.UI
if type(UI) ~= "table" or type(UI.FramedPanel) ~= "function" or type(UI.WindowFrame) ~= "function" then return end

-- Its pill switches and slim scroll bars stay its own (it overrides their SetChecked and paints them).
local DRESS = { checks = false, scrollBars = false }

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

local API = ns.API
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

local function PaintPlate(tex, kind)
	tex:SetDesaturated(true)
	if kind == "picked" then
		tex:SetVertexColor(AccentAt(0.85))
	else
		tex:SetVertexColor(0.42, 0.42, 0.45)
	end
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
					PaintPlate(region, plate)
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
	frame:HookScript("OnShow", function() clicks:RegisterEvent("GLOBAL_MOUSE_UP") end)
	if frame:IsShown() then clicks:RegisterEvent("GLOBAL_MOUSE_UP") end
end

-- ---------------------------------------------------------------------------------------------
-- Popups: FramedPanel's ground and line, WindowFrame's ring and glows
-- ---------------------------------------------------------------------------------------------

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
			ns.WithKit(function() ns.DressOnShow(f, DRESS, PlatesIn, KEY) end)
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

-- (From an audit of OneForAll 6.2.5 against every DaylightUI module. Left out: its NPC tooltip
-- quests, which turn themselves off while Questie is loaded; its chat font size, which has no
-- off to give back.)
ns.Handover(KEY, {
	ready = function() return type(_G.OneForAllDB) == "table" end,
	get = function(key) return QoL.Get(key) end,
	set = function(key, value) QoL.Set(key, value) end,
	list = {
		-- Chat: DaylightUI_Chat draws its own panel over the game's chat windows.
		C("chatHide", "Chat hide button (the speech bubble on the chat)",
			"its chat panel; OneForAll's button hides the chat windows DaylightUI's chat is built on", moduleOn("Chat")),
		C("chatAutoHide", "Hide the chat after a while", "the chat's own fading (Chat)", moduleOn("Chat"), { off = 0 }),
		C("copyChat", "Copy buttons on the chat", "the chat's Copy button (Chat)",
			function() return has("Chat", "copyButton") end),
		C("chatHistory", "Up and Down bring back sent messages", "the same in its chat box (Chat)",
			function() return has("Chat", "arrowHistory") end, RELOAD),
		-- Minimap
		C("mmCollect", "Minimap button collector", "the addon drawer under the minimap (Info Panel)",
			function() return has("InfoPanel", "map.enabled") and has("InfoPanel", "map.drawer") end),
		C("mmSquare", "Square minimap", "its own square minimap (Info Panel)",
			function() return has("InfoPanel", "map.enabled") end),
		-- World map
		C("lmDungeons", "Dungeon entrances on the world map", "map pins (Window Skins)",
			function() return has("Skins", "mapDungeons") end),
		C("lmFlight", "Flight masters on the world map", "map pins (Window Skins)",
			function() return has("Skins", "mapFlights") end),
		C("lmTransport", "Boats, zeppelins and the tram on the world map", "map pins (Window Skins)",
			function() return has("Skins", "mapTravel") end),
		C("mapFog", "Remove the map's fog", "map reveal (Window Skins)",
			function() return has("Skins", "mapReveal") end),
		C("flightMapNow", "Open the flight map at once", "its NPC window and skip-gossip (Quality of Life)",
			function() return has("NPC", "enabled") or has("QoL", "skipGossip") end),
		-- Quality of life
		C("flightTimes", "Flight timer", "the flight timer (Quality of Life)",
			function() return has("QoL", "flightTimer") end),
		C("lootFeed", "Loot feed", "the loot feed (Quality of Life)",
			function() return has("QoL", "lootFeed") end),
		C("quickLoot", "Faster looting", "fast loot (Quality of Life)",
			function() return has("QoL", "fastLoot") end),
		C("questSparkles", "Quest loot sparkles", "loot sparkles (Quality of Life)",
			function() return has("QoL", "lootSparkles") end, RELOAD),
		C("nodeGlow", "Herb and ore sparkle", "object glow (Quality of Life)",
			function() return has("QoL", "objectGlow") end, RELOAD),
		C("cameraZoom", "Farther camera zoom", "camera distance (Quality of Life)",
			function() return has("QoL", "cameraZoom", notOne) end, RELOAD),
		C("hideErrors", "Hide error messages", "quiet errors and its own error text (Quality of Life)",
			function() return has("QoL", "quietErrors") or has("QoL", "errorText") end),
		C("autoAccept", "Accept quests automatically", "auto accept (Quality of Life)",
			function() return has("QoL", "questAccept") end),
		C("autoTurnIn", "Turn in quests automatically", "auto turn in (Quality of Life)",
			function() return has("QoL", "questTurnIn") end),
		-- Windows
		C("moveWindows", "Move the game's windows", "moving windows and its own windows (Window Skins)",
			function() return ns.Enabled() end, RELOAD),
		C("resizeWindows", "Resize the game's windows", "Ctrl + wheel sizing (Window Skins)",
			function() return ns.Enabled() end),
		-- Vendors
		C("autoRepair", "Repair at vendors", "auto repair (Bags)", function() return has("Bags", "autoRepair") end),
		C("sellJunk", "Sell junk at vendors", "sell junk (Bags)", function() return has("Bags", "sellJunk") end),
		-- Tooltip, nameplates, info
		C("unitTarget", "\"Target:\" line in unit tooltips", "the target line (Tooltip)",
			function() return has("Tooltip", "showTarget") end),
		C("questMarks", "Quest marks on nameplates", "quest marks on its nameplates (Nameplates)",
			function() return has("Nameplates", "quest") end),
		C("infoBar", "OneForAll's info bar", "the data texts (Info Panel)",
			function() return has("InfoPanel", "data.enabled") end),
		-- The game's frames DaylightUI hides: work done on bars no one sees.
		C("classColors", "Class colors on the game's unit frames", "its own unit frames (Unit Frames)",
			moduleOn("UnitFrames")),
		C("bagSlots", "Free slots on the game's backpack button", "the bags data text and its bags (Bags)",
			moduleOn("Bags")),
		C("questXP", "Quest XP on the game's experience bar", "its experience bar with banked quest XP (Info Panel)",
			function() return has("InfoPanel", "xp.enabled") end),
		-- A plain option of this pack's, not a conflict.
		{ key = "mapButton", switch = "hideMapButton", ours = function() return true end },
	},
})
