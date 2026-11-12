-- Addon Skins for DaylightUI
-- A plugin: it runs on top of DaylightUI through DaylightUI.API only (see DaylightUI's API.md) and
-- holds none of DaylightUI's code or art. Every look comes from API.Skin and the skin Kit that
-- DaylightUI hands to a registered skin, so the player's font, accent and opacity are followed.

local ADDON, ns = ...

local DUI = _G.DaylightUI
local API = DUI and DUI.API
if not API or API.major ~= 1 then return end

ns.API = API
ns.ok = true

local me = API.For(ADDON)
ns.me = me

local pcall, xpcall, type, select, pairs, wipe = pcall, xpcall, type, select, pairs, wipe
local floor = math.floor

-- The addons this plugin dresses: key = the addon's folder name, value = the label in the options.
ns.targets = {}
ns.order = {}
ns.caps = {}

local defaults = {}

local function Guard(fn, ...)
	return xpcall(fn, geterrorhandler(), ...)
end
ns.Guard = Guard

-- An addon this plugin dresses, for the options list. caps = what of its look can be set on its
-- own page: window (shell), controls (buttons, boxes, scroll bars), text (font, size, outline),
-- shadow (text shadow), colors (text colours and accent), font = the font it starts on
-- ("daylight" where the pack already puts the player's font on its text, else "addon").
-- A pack with settings of its own adds defaults = { name = value } (kept under look.<addon>.<name>
-- like the rest) and extra = function(at, following, hint) returning option groups, shown on its
-- page under the tab extraTab.
function ns.Target(addon, label, caps)
	if ns.targets[addon] then
		if caps then ns.caps[addon] = caps end
		return
	end
	ns.targets[addon] = label
	ns.caps[addon] = caps or {}
	ns.order[#ns.order + 1] = addon
end

-- ---------------------------------------------------------------------------------------------
-- Settings, read once. A font hook asks many times a second while a window draws, so every
-- answer is kept until DaylightUI says something changed (a setting of ours, the style, login).
-- Nothing is kept before login: the settings aren't there yet and every answer is the default.
-- ---------------------------------------------------------------------------------------------

local ready = false
local NONE = {}          -- stands for "asked, and there is none"
local cache = {}         -- path -> value or NONE
local texts = {}         -- key -> the resolved text look (Text below)
local skinsOn            -- DaylightUI's Skins module: true / false, nil = not asked yet

local function Setting(path)
	local value = cache[path]
	if value ~= nil then
		if value == NONE then return nil end
		return value
	end
	local ok, got = pcall(API.GetSetting, ADDON, path)
	if not ok then got = nil end
	if ready then
		if got == nil then cache[path] = NONE else cache[path] = got end
	end
	return got
end

local function Forget()
	wipe(cache)
	wipe(texts)
	skinsOn = nil
end

-- A setting of this plugin's as it is saved, whatever the "own settings" switches say.
ns.Setting = Setting

function ns.Enabled(key)
	local on = skinsOn
	if on == nil then
		local ok, value = pcall(API.IsModuleEnabled, "Skins")
		on = ok and value ~= false
		if ready then skinsOn = on end
	end
	if not on then return false end
	return not key or Setting(key) ~= false
end

-- ---------------------------------------------------------------------------------------------
-- The look of one addon's windows. While "Use DaylightUI's settings for all windows" is on (the
-- way it starts), every answer is the default: the player's DaylightUI look, nothing of their own.
-- ---------------------------------------------------------------------------------------------

ns.LOOK = {
	own = false,
	font = "addon", size = 1, outline = "keep", shadow = false,
	daylightColors = true, daylightAccent = true, accent = { 0.25, 0.85, 0.6 },
	ownOpacity = false, opacity = 0.85, border = true, ownBorder = false, borderPx = 8, bevel = true,
	controls = true,
}
-- The ones a shell is drawn from: a change to any other leaves the shells as they are.
local SHELL_LOOK = { own = true, ownOpacity = true, opacity = true, border = true, ownBorder = true, borderPx = true, bevel = true }

local function LookDefault(key, name)
	local caps = ns.caps[key]
	if name == "font" then
		return caps and caps.font or ns.LOOK.font
	end
	local own = caps and caps.defaults
	if own and own[name] ~= nil then return own[name] end
	return ns.LOOK[name]
end
ns.LookDefault = LookDefault

-- Whether `key`'s windows follow DaylightUI's settings: yes, unless the player turned on "Use my own
-- settings" on its page. (No key: the switch for all windows alone.) The switch for all windows only
-- holds the addons that weren't given settings of their own.
local function Following(key)
	if key and Setting("look." .. key .. ".own") == true then return false end
	return Setting("followDaylight") ~= false
end
ns.Following = Following

local function Look(key, name)
	if not key or Following(key) then return LookDefault(key, name) end
	local value = Setting("look." .. key .. "." .. name)
	if value ~= nil then return value end
	return LookDefault(key, name)
end
ns.Look = Look

-- ---------------------------------------------------------------------------------------------
-- Small helpers the packs share
-- ---------------------------------------------------------------------------------------------

-- The accent `key`'s windows use: its own, when picked on its page, or DaylightUI's.
function ns.AccentOf(key)
	if key and Look(key, "daylightAccent") == false then
		local own = Look(key, "accent")
		if type(own) == "table" and type(own[1]) == "number" then return own[1], own[2], own[3] end
	end
	return API.Accent()
end

-- Whether one of DaylightUI's modules is on.
function ns.ModuleOn(name)
	local ok, on = pcall(API.IsModuleEnabled, name)
	return ok and on == true
end

-- The game hands an addon's own image files a number of its own for the session, and a texture
-- reports that number rather than the path. `paths` = { path = value }: answers { number = value }
-- (and { lower-case path = value }, for a client that does report paths), each file set once on
-- one hidden texture to learn its number.
local scratch
function ns.FileIDs(paths)
	if not scratch then
		scratch = UIParent:CreateTexture(nil, "BACKGROUND")
		scratch:Hide()
	end
	local out = {}
	for path, value in pairs(paths) do
		out[string.lower(path)] = value
		scratch:SetTexture(path)
		local ok, id = pcall(scratch.GetTexture, scratch)
		if ok and id ~= nil then out[id] = value end
	end
	scratch:SetTexture(nil)
	return out
end

-- The addon whose windows are being dressed right now: set round a pack's function and a watch's,
-- so the shared helpers below know whose look to read without being told each time.
local current

function ns.Controls(key)
	return Look(key or current, "controls") ~= false
end

local LSM = type(LibStub) == "table" and LibStub("LibSharedMedia-3.0", true) or nil
ns.LSM = LSM

local OUTLINES = { none = "", thin = "OUTLINE", thick = "THICKOUTLINE" }

-- The text look of `key`, worked out once: face (nil = the addon's own), scale (nil = as it is),
-- flags (nil = the addon's own outline), shadow, and plain = nothing of the text is changed.
local function Text(key)
	local t = texts[key]
	if t then return t end
	t = {}
	local font = Look(key, "font")
	if font == "daylight" then
		local ok, face = pcall(API.Font)
		if ok and type(face) == "string" then t.face = face end
	elseif font ~= "addon" then
		local face = LSM and LSM:Fetch("font", font, true)
		if type(face) == "string" then t.face = face end
	end
	local scale = Look(key, "size")
	if type(scale) == "number" and scale ~= 1 then t.scale = scale end
	t.flags = OUTLINES[Look(key, "outline")]
	t.shadow = Look(key, "shadow") == true
	t.plain = not (t.face or t.scale or t.flags or t.shadow)
	if ready then texts[key] = t end
	return t
end

-- Whether `key`'s text is left exactly as the addon set it (a font hook can stop there).
function ns.PlainText(key)
	return Text(key).plain
end

-- The face, size and flags a string of `key`'s gets, from what the addon gave it.
function ns.FontFor(key, path, size, flags)
	local t = Text(key)
	if t.scale and type(size) == "number" then size = floor(size * t.scale + 0.5) end
	return t.face or path, size, t.flags or flags
end

-- `key`'s text look on a font string the addon just set to path, size, flags.
function ns.SetFont(key, fs, path, size, flags)
	local t = Text(key)
	if t.plain then return end
	if t.scale and type(size) == "number" then size = floor(size * t.scale + 0.5) end
	local face = t.face or path
	if face and size and size > 0 then fs:SetFont(face, size, t.flags or flags or "") end
	if t.shadow and fs.SetShadowOffset then
		fs:SetShadowColor(0, 0, 0, 0.9)
		fs:SetShadowOffset(1, -1)
	end
end

-- Whether the walk over `key`'s windows changes their text at all. Never where the pack follows
-- the addon's own font call (caps.font = "daylight"): those strings are done there already.
local function TextStyled(key)
	local caps = ns.caps[key]
	if not caps or not caps.text or caps.font == "daylight" then return false end
	return not Text(key).plain
end

-- A shell's opts with `key`'s own opacity, border and bevel laid over them.
local function ShellOpts(key, opts)
	-- ({} rather than nil: the shell keeps its last opts when given none.)
	if not key or Following(key) then return opts or {} end
	local out = {}
	if opts then for k, v in pairs(opts) do out[k] = v end end
	if Look(key, "ownOpacity") == true and not out.noBackground then out.bgAlpha = Look(key, "opacity") end
	if Look(key, "border") == false then out.noBorder = true end
	if Look(key, "ownBorder") == true then out.borderPx = Look(key, "borderPx") end
	if Look(key, "bevel") == false then out.noBevel = true end
	return out
end

-- Runs fn now, or when the fight ends: some addons' windows are protected frames.
local afterCombat = {}
function ns.OutOfCombat(fn)
	if InCombatLockdown() then
		afterCombat[#afterCombat + 1] = fn
	else
		xpcall(fn, geterrorhandler())
	end
end
local regen = CreateFrame("Frame")
regen:RegisterEvent("PLAYER_REGEN_ENABLED")
regen:SetScript("OnEvent", function()
	if #afterCombat == 0 then return end
	local list = afterCombat
	afterCombat = {}
	for i = 1, #list do xpcall(list[i], geterrorhandler()) end
end)

-- ---------------------------------------------------------------------------------------------
-- The Kit. DaylightUI hands it to a skin function only, so work that needs it waits for it.
-- ---------------------------------------------------------------------------------------------

local waiting = {}

local function GotKit(Kit)
	if ns.Kit or not Kit then return end
	ns.Kit = Kit
	local list = waiting
	waiting = {}
	for i = 1, #list do Guard(list[i], Kit) end
end

function ns.WithKit(fn)
	if ns.Kit then
		Guard(fn, ns.Kit)
	else
		waiting[#waiting + 1] = fn
	end
end

-- ns.Pack(addon, label, fn, caps): fn(Kit) runs once `addon` has loaded; return false to be asked
-- again. caps: see ns.Target.
function ns.Pack(addon, label, fn, caps)
	if label then ns.Target(addon, label, caps) end
	me.RegisterSkin(addon, function(Kit)
		GotKit(Kit)
		if not fn or not ns.Enabled(label and addon or nil) then return end
		local was = current
		if label then current = addon end
		local ok, out = pcall(fn, Kit)
		current = was
		if not ok then error(out, 0) end
		return out
	end)
end

-- ---------------------------------------------------------------------------------------------
-- Frames made late (on a window's first open): looked for by name until they turn up
-- ---------------------------------------------------------------------------------------------

local watches = {}
local ticker
local TICK, SLOW_TICK, SLOW_AFTER = 0.2, 2, 60
local tickSince, slow = nil, false

local function Found(w, frame)
	ns.WithKit(function(Kit)
		local was = current
		current = w.key
		local ok, err = pcall(w.fn, frame, Kit)
		current = was
		if not ok then error(err, 0) end
	end)
end

local function Tick()
	for i = #watches, 1, -1 do
		local w = watches[i]
		if ready and not ns.Enabled(w.key) then
			-- Its addon is switched off (a switch takes hold after a reload): not looked for again.
			table.remove(watches, i)
		else
			local get, frame = w.get, nil
			if type(get) == "string" then
				frame = _G[get]
			else
				local ok, found = pcall(get)
				frame = ok and found or nil
			end
			if frame and (ready or ns.Enabled(w.key)) then
				table.remove(watches, i)
				Found(w, frame)
			end
		end
	end
	if #watches == 0 and ticker then
		ticker:Cancel()
		ticker = nil
		return
	end
	-- A window not made in the first minute is looked for every few seconds from then on.
	if ticker and not slow and tickSince and GetTime() - tickSince > SLOW_AFTER then
		slow = true
		ticker:Cancel()
		ticker = C_Timer.NewTicker(SLOW_TICK, Tick)
	end
end

-- ns.Watch(key, get, fn): `get` = a global frame name or a function returning the frame (or nil);
-- fn(frame, Kit) runs once, when it exists.
function ns.Watch(key, get, fn)
	watches[#watches + 1] = { key = key, get = get, fn = fn }
	if not ticker and ns.loggedIn then
		tickSince, slow = GetTime(), false
		ticker = C_Timer.NewTicker(TICK, Tick)
	end
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	ns.loggedIn = true
	if #watches > 0 and not ticker then
		tickSince, slow = GetTime(), false
		ticker = C_Timer.NewTicker(TICK, Tick)
	end
end)

-- ---------------------------------------------------------------------------------------------
-- Helpers the packs share
-- ---------------------------------------------------------------------------------------------

local done = setmetatable({}, { __mode = "k" })     -- controls already dressed
local shells = setmetatable({}, { __mode = "k" })   -- frame -> { opts, key } its shell was made with
local dirty = setmetatable({}, { __mode = "k" })

function ns.Once(obj)
	if done[obj] then return false end
	done[obj] = true
	return true
end
local Once = ns.Once

local function Usable(obj)
	if not obj or type(obj) ~= "table" or not obj.GetObjectType then return false end
	if obj.IsForbidden and obj:IsForbidden() then return false end
	return true
end
ns.Usable = Usable

-- Hides a piece of another addon's art for good.
function ns.Kill(region)
	if not Usable(region) then return end
	region:SetAlpha(0)
	region:Hide()
end

function ns.NoBackdrop(frame)
	if Usable(frame) and frame.SetBackdrop then pcall(frame.SetBackdrop, frame, nil) end
end

local function Reshell(frame)
	local s = shells[frame]
	if s and Usable(frame) then Guard(API.Skin, frame, ShellOpts(s.key, s.opts)) end
end

local function Resized(self)
	if dirty[self] then return end
	dirty[self] = true
	C_Timer.After(0, function()
		dirty[self] = nil
		Reshell(self)
	end)
end

-- DaylightUI's shell on a frame; redone when the frame changes size, and when the look changes.
-- key = the addon whose look it follows (left out: the one being dressed right now).
function ns.Shell(frame, opts, key)
	if not Usable(frame) then return end
	local old = shells[frame]
	shells[frame] = { opts = opts, key = key or (old and old.key) or current }
	Reshell(frame)
	if not old and frame.HookScript then frame:HookScript("OnSizeChanged", Resized) end
end

local function ReshellAll()
	for frame in pairs(shells) do Reshell(frame) end
end

-- Shells to redo after a setting of ours changed: gathered, and done once on the next frame (a
-- slider being dragged changes its setting on every step).
local redoAll, redoKeys, redoQueued = false, {}, false
local function Redo()
	redoQueued = false
	for frame, s in pairs(shells) do
		if redoAll or redoKeys[s.key] then Reshell(frame) end
	end
	redoAll = false
	wipe(redoKeys)
end

me.On("StyleChanged", function()
	Forget()
	ReshellAll()
end)
me.On("Login", function()
	ready = true
	Forget()
	-- Shells made before the settings were there are DaylightUI's plain ones: right, unless the
	-- player has their own look on.
	ReshellAll()
end)
me.On("SettingChanged", function(scope, path)
	if scope ~= ADDON then return end
	Forget()
	if type(path) ~= "string" then return end
	if path == "followDaylight" then
		redoAll = true
	else
		local key, name = string.match(path, "^look%.([^.]+)%.(.+)$")
		if not key or not SHELL_LOOK[name] then return end
		redoKeys[key] = true
	end
	if not redoQueued then
		redoQueued = true
		C_Timer.After(0, Redo)
	end
end)

-- A flat one-pixel backdrop (the usual WHITE8X8 box) turned into a quiet darker well.
function ns.Soften(frame, alpha)
	if not Usable(frame) or not frame.GetBackdrop or not frame:GetBackdrop() then return end
	frame:SetBackdropColor(0, 0, 0, alpha or 0.28)
	frame:SetBackdropBorderColor(1, 1, 1, 0.07)
end

-- A font string in `key`'s text look. With no key: the player's font, its size and outline kept.
function ns.Refont(fs, key)
	if not Usable(fs) or not fs.GetFont then return end
	local path, size, flags = fs:GetFont()
	if not size or size <= 0 then return end
	if key then
		ns.SetFont(key, fs, path, size, flags)
	else
		fs:SetFont(API.Font(), size, flags or "")
	end
end

-- The unnamed UIPanelCloseButton in a window's top right corner.
local function CloseAmong(frame, ...)
	for i = 1, select("#", ...) do
		local child = select(i, ...)
		if Usable(child) and child:GetObjectType() == "Button" and child:GetNumPoints() >= 1 then
			local point, rel, relPoint = child:GetPoint(1)
			local text = child.GetText and child:GetText()
			local w, h = child:GetSize()
			if point == "TOPRIGHT" and (rel == frame or rel == nil) and relPoint == "TOPRIGHT"
				and (text == nil or text == "") and w > 0 and w <= 40 and math.abs(w - h) < 3
				and child:GetNormalTexture() then
				return child
			end
		end
	end
end
function ns.FindClose(frame)
	return CloseAmong(frame, frame:GetChildren())
end

local function IsPanelButton(b)
	return b.Left and b.Middle and b.Right and true or false
end

-- The walk behind ns.Dress. The look is read once at the top and handed down, and children and
-- regions are gone through as they come (no table made of them): it runs on every show.
local Walk

local function WalkRegions(key, ...)
	for i = 1, select("#", ...) do
		local region = select(i, ...)
		if not done[region] and Usable(region) and region:GetObjectType() == "FontString" then
			done[region] = true
			ns.Refont(region, key)
		end
	end
end

local function WalkChildren(Kit, opts, depth, key, controls, fonts, ...)
	local skip, soften = opts.skip, opts.soften
	for i = 1, select("#", ...) do
		local child = select(i, ...)
		if Usable(child) and not (skip and skip[child]) and not (child.IsProtected and child:IsProtected()) then
			local kind = child:GetObjectType()
			local walk = true
			if kind == "Button" then
				if IsPanelButton(child) then
					if controls and Once(child) then Guard(Kit.Button, child) end
					walk = false
				elseif soften and not done[child] and child.GetBackdrop and child:GetBackdrop() then
					done[child] = true
					ns.Soften(child, 0.35)
				end
			elseif kind == "CheckButton" then
				if controls and opts.checks ~= false and Once(child) then Guard(Kit.Check, child) end
				walk = false
			elseif kind == "EditBox" then
				if IsPanelButton(child) then
					if controls and Once(child) then Guard(Kit.EditBox, child) end
				elseif soften and not done[child] and child.GetBackdrop and child:GetBackdrop() then
					done[child] = true
					ns.Soften(child, 0.35)
				end
				walk = false
			elseif kind == "ScrollFrame" then
				local bar = child.ScrollBar
				if controls and opts.scrollBars ~= false and bar and not done[bar] and Usable(bar) then
					done[bar] = true
					Guard(Kit.ScrollBar, bar)
				end
			elseif kind == "Slider" then
				walk = false
			elseif kind == "Frame" then
				if soften and not done[child] and child.GetBackdrop and child:GetBackdrop() then
					done[child] = true
					ns.Soften(child)
				end
			else
				walk = false   -- models, cooldowns, status bars, tooltips: not ours to open up
			end
			if walk then Walk(Kit, child, opts, depth + 1, key, controls, fonts) end
		end
	end
end

function Walk(Kit, root, opts, depth, key, controls, fonts)
	if depth > 10 then return end
	if fonts and root.GetRegions then WalkRegions(key, root:GetRegions()) end
	if root.GetChildren then WalkChildren(Kit, opts, depth, key, controls, fonts, root:GetChildren()) end
end

-- Walks a custom-drawn window and dresses the controls made from the game's templates, one by one:
-- UIPanelButtonTemplate, InputBoxTemplate / SearchBoxTemplate, check buttons, template scroll bars.
-- Buttons an addon drew itself (rows, tiles, icons) are left as they are.
-- opts: skip (a set of frames left alone, their children too), checks = false, scrollBars = false
-- (the addon draws its own and they are left as they are), soften = true
-- (flat backdrop boxes become quiet wells), fonts = true (the player's font on every string).
-- key = the addon whose look it follows (left out: the one being dressed right now): its text look
-- goes on the strings when it has one, and its controls are left alone when it says so.
local NO_OPTS = {}
function ns.Dress(root, opts, depth, key)
	local Kit = ns.Kit
	if not Kit or not Usable(root) then return end
	opts = opts or NO_OPTS
	key = key or current
	local controls = ns.Controls(key)
	local fonts = opts.fonts or (key and TextStyled(key)) or false
	if not controls and not fonts and not opts.soften then return end
	Walk(Kit, root, opts, depth or 0, key, controls, fonts)
end

-- Dresses again on every show (and once on the next frame): pooled rows and late-made controls.
function ns.DressOnShow(frame, opts, extra, key)
	key = key or current
	local function run()
		if not Usable(frame) then return end
		ns.Dress(frame, opts, 0, key)
		if extra then Guard(extra, frame) end
	end
	local queued
	local function again()
		queued = nil
		-- Hidden again by now: its next show does it.
		if frame:IsShown() then run() end
	end
	local function later()
		if queued then return end
		queued = true
		C_Timer.After(0, again)
	end
	frame:HookScript("OnShow", function() run() later() end)
	run()
	if frame:IsShown() then later() end
	return later
end

-- A window an addon drew with its own backdrop: its backdrop off, DaylightUI's window shell on,
-- its close button and template controls dressed.
function ns.PlainWindow(frame, opts, key)
	local Kit = ns.Kit
	if not Kit or not Usable(frame) or not Once(frame) then return end
	key = key or current
	ns.NoBackdrop(frame)
	ns.Shell(frame, { window = true }, key)
	if ns.Controls(key) then
		local close = ns.FindClose(frame)
		if close and Once(close) then Guard(Kit.Close, close) end
	end
	return ns.DressOnShow(frame, opts, nil, key)
end

-- ---------------------------------------------------------------------------------------------
-- Conflicts: what an addon does that DaylightUI already does (or that fights a frame DaylightUI
-- owns). The rule for every pack: DaylightUI's copy wins by default. Each pack lists its
-- conflicts (ns.Handover); on first load the player is asked about each one that is live (both
-- copies on) in one window (Choices.lua), DaylightUI picked for each unless they say otherwise.
-- A feature given to DaylightUI is switched off through the addon's own setting, and what it was
-- is kept per account (DaylightAddonSkinsDB.handed): given back (on the addon's page, or with its
-- "give everything back" button), with DaylightUI's copy turned off, or with this plugin's switch
-- for the addon off, exactly that comes back. Nothing is switched before the player has answered
-- (DaylightAddonSkinsDB.asked). One the player turns back on in the addon itself is left on.
-- The choice: look.<addon>.use.<key> (true = DaylightUI, the default).
-- ns.Handover(addon, { list = { { key = "x", label = "Loot feed", daylight = "Loot feed (Quality of
--   Life)", ours = function() return DaylightUI's copy is on end, off = false }, ... },
--   ready = function() end, get = function(key) end, set = function(key, value) end })
-- An entry with `switch` instead is a plain option of the pack's (look.<addon>.<switch>), not a
-- conflict: not asked about, applied while that switch is on.
-- ---------------------------------------------------------------------------------------------

local handovers = {}
ns.handovers = handovers

local function SV()
	local db = _G.DaylightAddonSkinsDB
	if type(db) ~= "table" then
		db = {}
		_G.DaylightAddonSkinsDB = db
	end
	return db
end

local function Part(name, addon)
	local db = SV()
	if type(db[name]) ~= "table" then db[name] = {} end
	if type(db[name][addon]) ~= "table" then db[name][addon] = {} end
	return db[name][addon], db[name]
end

local function Handed(addon) return Part("handed", addon) end
local function Asked(addon) return (Part("asked", addon)) end

local function UsePath(addon, key) return "look." .. addon .. ".use." .. key end
ns.UsePath = UsePath

local function Ours(item)
	local ok, v = pcall(item.ours)
	return ok and v == true
end

-- Whether the player gave `item` to DaylightUI (the default).
local function Chosen(addon, item)
	return Setting(UsePath(addon, item.key)) ~= false
end

local function ApplyHandover(addon, h, repair)
	if type(h.ready) == "function" and not h.ready() then return false end
	local rec, all = Handed(addon)
	local asked = Asked(addon)
	local enabled = ns.Enabled(addon)
	for _, item in ipairs(h.list) do
		local want = false
		if enabled then
			if item.switch then
				want = Setting("look." .. addon .. "." .. item.switch) == true and Ours(item)
			else
				want = asked[item.key] == true and Chosen(addon, item) and Ours(item)
			end
		end
		-- What "off" is for this setting (false, unless it says otherwise: 0 for a timer).
		local off = item.off
		if off == nil then off = false end
		if want then
			if rec[item.key] == nil then
				local cur = h.get(item.key)
				if cur and cur ~= off then
					rec[item.key] = cur
					h.set(item.key, off)
				end
			elseif repair then
				-- (Once: before 1.5.0's fix these were left empty, and the addon read its default.)
				local cur = h.get(item.key)
				if cur and cur ~= off then h.set(item.key, off) end
			end
		elseif rec[item.key] ~= nil then
			local back = rec[item.key]
			rec[item.key] = nil
			h.set(item.key, back)
		end
	end
	if next(rec) == nil then all[addon] = nil end
	return true
end

local handQueued = false
local function ApplyAllHandovers()
	handQueued = false
	if not ready then return end
	local waiting = false
	local sv = SV()
	-- One repair pass: settings given to DaylightUI before the fix were cleared instead of switched
	-- off (so the addon read its default, on). Each addon's own pass, once its settings are there.
	if type(sv.repaired) ~= "table" then sv.repaired = {} end
	for addon, h in pairs(handovers) do
		local repair = not sv.repaired[addon]
		local ok, done = xpcall(ApplyHandover, geterrorhandler(), addon, h, repair)
		if ok and done == false then
			waiting = true
		elseif ok and repair then
			sv.repaired[addon] = true
		end
	end
	return waiting
end
-- Once, a moment after the last change: a slider being dragged in DaylightUI's options changes
-- its setting on every step.
local function QueueHandovers()
	if handQueued then return end
	handQueued = true
	C_Timer.After(0.3, ApplyAllHandovers)
end

function ns.Handover(addon, def)
	if type(def) ~= "table" or type(def.list) ~= "table" then return end
	handovers[addon] = def
	if ready then QueueHandovers() end
end

-- Whether DaylightUI's own copy of something is on: a setting of one of its modules (nil while
-- that module is off), or a test of the value.
function ns.DaylightHas(scope, path, test)
	local ok, value = pcall(API.GetSetting, scope, path)
	if not ok or value == nil then return false end
	if test then return test(value) == true end
	return value == true
end

-- The conflicts to show: `all` = every one that is live or was given to DaylightUI; otherwise only
-- the live ones not answered yet. Each: { addon, item, daylight = the current pick }.
function ns.Conflicts(all)
	local out = {}
	for _, addon in ipairs(ns.order) do
		local h = handovers[addon]
		if h and ns.Enabled(addon) and (type(h.ready) ~= "function" or h.ready()) then
			local asked, rec = Asked(addon), Handed(addon)
			for _, item in ipairs(h.list) do
				if not item.switch then
					local live = false
					if Ours(item) then
						local ok, cur = pcall(h.get, item.key)
						live = rec[item.key] ~= nil or (ok and cur and cur ~= item.off) and true or false
					end
					if live and (all or not asked[item.key]) then
						out[#out + 1] = { addon = addon, item = item, daylight = not asked[item.key] or Chosen(addon, item) }
					end
				end
			end
		end
	end
	return out
end

-- The player's pick for one conflict (true = DaylightUI); applied at once.
function ns.Choose(addon, key, daylight)
	Asked(addon)[key] = true
	Guard(function() DUI:Set(ADDON, UsePath(addon, key), daylight and true or false) end)
	QueueHandovers()
end

-- Everything of `addon`'s given to DaylightUI, back to the addon as it was.
function ns.GiveBack(addon)
	local h = handovers[addon]
	if not h then return end
	for _, item in ipairs(h.list) do
		if not item.switch then ns.Choose(addon, item.key, false) end
	end
end

me.On("Login", function()
	-- Some addons read their settings a little after login: asked again for a while.
	local tries = 0
	local function try()
		tries = tries + 1
		if ApplyAllHandovers() and tries < 20 then C_Timer.After(0.5, try) end
	end
	C_Timer.After(0.5, try)
end)
-- Any setting (DaylightUI's own copy turned on or off, a pick on a page of ours: that counts as
-- answered).
me.On("SettingChanged", function(scope, path)
	if scope == ADDON and type(path) == "string" then
		local addon, key = string.match(path, "^look%.([^.]+)%.use%.(.+)$")
		if addon and key then Asked(addon)[key] = true end
	end
	if ready then QueueHandovers() end
end)

-- The group on an addon's page: one switch per conflict, and the way back.
function ns.HandoverGroup(addon)
	local h = handovers[addon]
	local label = ns.targets[addon] or addon
	local items = {}
	for _, item in ipairs(h and h.list or {}) do
		if not item.switch then
			items[#items + 1] = { type = "toggle", key = UsePath(addon, item.key),
				label = item.label or item.key,
				desc = "On: DaylightUI does this" .. (item.daylight and (" (" .. item.daylight .. ")") or "")
					.. " and " .. label .. "'s own is switched off. Off: " .. label .. "'s own, as it was.",
				reload = item.reload or nil }
		end
	end
	items[#items + 1] = { type = "button", label = "Give everything back to " .. label,
		desc = "Puts back every one of " .. label .. "'s settings this plugin switched off, as they were.",
		func = function() ns.GiveBack(addon) end }
	return { label = "DaylightUI or " .. label, items = items }
end

-- Got the Kit as early as DaylightUI will give it.
ns.Pack("DaylightUI_Skins")

-- Settings: one switch per addon, kept in the player's DaylightUI profile. `pages` (Options.lua)
-- go in this plugin's own section of the options window, under the Plugins heading.
function ns.RegisterSettings(pages)
	defaults.followDaylight = true
	defaults.look = {}
	for addon in pairs(ns.targets) do
		defaults[addon] = true
		local look = {}
		for name, value in pairs(ns.LOOK) do
			if type(value) == "table" then
				look[name] = { value[1], value[2], value[3] }
			else
				look[name] = LookDefault(addon, name)
			end
		end
		local own = ns.caps[addon] and ns.caps[addon].defaults
		if own then
			for name, value in pairs(own) do
				if type(value) == "table" then
					look[name] = { value[1], value[2], value[3] }
				else
					look[name] = value
				end
			end
		end
		local h = handovers[addon]
		if h then
			look.use = {}
			for _, item in ipairs(h.list) do
				if not item.switch then look.use[item.key] = true end
			end
		end
		defaults.look[addon] = look
	end
	Guard(function()
		DUI:RegisterPlugin(ADDON, {
			needs = { 1, 1 },
			short = "Addons",
			blurb = "Your other addons' windows in the DaylightUI look.",
		})
		DUI:RegisterModule(ADDON, { plugin = ADDON, label = "Addon skins", defaults = defaults,
			options = pages and { pages = pages } or nil })
	end)
end
