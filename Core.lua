-- Addon Skins: a DaylightUI plugin
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

-- An error inside ns.Guard: put down against the pack whose code raised it (Broken skins, below),
-- or handed to the game's error handler as before when no pack's file is in it.
local GuardError

local function Guard(fn, ...)
	return xpcall(fn, GuardError, ...)
end
ns.Guard = Guard

-- ---------------------------------------------------------------------------------------------
-- Targets that come in several folders, and what the game says of each folder
-- ---------------------------------------------------------------------------------------------

-- key -> the addon's folders, its main one first (caps.folders on ns.Target; a target with none
-- is the one folder named as its key). The pack runs as the main folder loads; the others are
-- for "installed / enabled / loaded" and the version, and a pack reaches them with ns.OnLoad
-- (never loaded by this plugin: a load-on-demand part is dressed when the addon loads it).
ns.folders = { ForeverDungeonJournal = { "ForeverDungeonJournal", "ForeverCore" } }
local singleFolder = {}
function ns.Folders(key)
	local list = ns.folders[key]
	if list then return list end
	list = singleFolder[key]
	if not list then
		list = { key }
		singleFolder[key] = list
	end
	return list
end

local A = _G.C_AddOns

-- Whether the folder is in the AddOns folder at all.
function ns.AddonExists(folder)
	if A and type(A.DoesAddOnExist) == "function" then
		local ok, yes = pcall(A.DoesAddOnExist, folder)
		if ok then return yes and true or false end
	end
	local info = A and A.GetAddOnInfo or _G.GetAddOnInfo
	if type(info) ~= "function" then return true end
	local ok, name, _, _, _, reason = pcall(info, folder)
	if not ok then return true end
	return name ~= nil and reason ~= "MISSING"
end

-- Whether the folder is ticked in the addon list for the character playing now (the game's own
-- test: C_AddOns.GetAddOnEnableState(name, UnitGUID("player")) above None; the name alone, for
-- all characters, where a character can't be named).
function ns.AddonEnabledHere(folder)
	local get = A and A.GetAddOnEnableState
	if type(get) ~= "function" then return true end
	local guid = _G.UnitGUID and _G.UnitGUID("player")
	local ok, state
	if guid then ok, state = pcall(get, folder, guid) end
	if not ok or type(state) ~= "number" then ok, state = pcall(get, folder) end
	if not ok or type(state) ~= "number" then return true end
	return state > 0
end

function ns.AddonLoaded(folder)
	if not (A and type(A.IsAddOnLoaded) == "function") then return false end
	local ok, loaded = pcall(A.IsAddOnLoaded, folder)
	return ok and loaded and true or false
end

local function LoadOnDemand(folder)
	if not (A and type(A.IsAddOnLoadOnDemand) == "function") then return false end
	local ok, lod = pcall(A.IsAddOnLoadOnDemand, folder)
	return ok and lod and true or false
end

-- Why an enabled folder didn't load (the game's own words, "Dependency missing" and the like).
local function NotLoadedReason(folder)
	local info = A and A.GetAddOnInfo
	if type(info) ~= "function" then return nil end
	local ok, _, _, _, _, reason = pcall(info, folder)
	if not ok or type(reason) ~= "string" or reason == "" then return nil end
	local text = _G["ADDON_" .. reason]
	return type(text) == "string" and text or reason
end

local function Meta(folder, field)
	local get = A and A.GetAddOnMetadata or _G.GetAddOnMetadata
	if type(get) ~= "function" then return nil end
	local ok, value = pcall(get, folder, field)
	if ok and type(value) == "string" and value ~= "" then return value end
	return nil
end
ns.Meta = Meta

-- The game's windows: targets named "Blizzard..." (the game windows, the settings window, the
-- dungeon-ready dialog). Always there; their "version" is the game's build.
local function IsGame(key)
	return type(key) == "string" and key:sub(1, 8) == "Blizzard"
end
ns.IsGameTarget = IsGame

function ns.GameVersion()
	local version, build = _G.GetBuildInfo()
	return string.format("%s (%s)", tostring(version), tostring(build))
end

-- This plugin's version ("@project-version@" when run from its source folder: a version too).
function ns.OurVersion() return Meta(ADDON, "Version") or "?" end

-- The version of `key`'s addon: each installed folder's, joined (a change in any one counts);
-- "-" when none is installed.
local function TargetVersion(key)
	if IsGame(key) then return ns.GameVersion() end
	local out
	for _, folder in ipairs(ns.Folders(key)) do
		if ns.AddonExists(folder) then
			local v = Meta(folder, "Version") or "?"
			out = out and (out .. " / " .. v) or v
		end
	end
	return out or "-"
end
ns.TargetVersion = TargetVersion

local failedNow          -- (Broken skins, below)

-- Where `key` stands, for the status list and the grids: "error" (its pack is off after an
-- error), "missing" (no folder of it installed), "disabled" (not ticked for this character),
-- "off" (its switch, or DaylightUI's Skins module), "active" (loaded and dressed), "lod" (a
-- load-on-demand addon not loaded yet), "notloaded" (ticked but not loaded; second return: the
-- game's reason). The game's own windows are always there.
function ns.TargetState(key)
	if failedNow[key] then return "error", failedNow[key].err end
	if IsGame(key) then
		if not ns.SwitchedOn(key) then return "off" end
		return "active"
	end
	local any, enabled, loaded, lod, reason = false, false, false, false, nil
	for _, folder in ipairs(ns.Folders(key)) do
		if ns.AddonExists(folder) then
			any = true
			if ns.AddonEnabledHere(folder) then
				enabled = true
				if ns.AddonLoaded(folder) then
					loaded = true
				elseif LoadOnDemand(folder) then
					lod = true
				else
					reason = reason or NotLoadedReason(folder)
				end
			end
		end
	end
	if not any then return "missing" end
	if not enabled then return "disabled" end
	if not ns.SwitchedOn(key) then return "off" end
	if loaded then return "active" end
	if lod then return "lod" end
	return "notloaded", reason
end

-- fn(folder) once `folder` has loaded: now, or as it loads (never loaded by this: a load-on-demand
-- part of an addon is dressed when the addon loads it). For a pack whose addon comes in several
-- folders (caps.folders): ns.OnLoad("DBM-GUI", function() ... end).
local onLoad = {}        -- folder -> { fn, ... }
local loadWatch
function ns.OnLoad(folder, fn)
	if type(folder) ~= "string" or type(fn) ~= "function" then return end
	if ns.AddonLoaded(folder) then
		Guard(fn, folder)
		return
	end
	local list = onLoad[folder]
	if not list then
		list = {}
		onLoad[folder] = list
	end
	list[#list + 1] = fn
	if not loadWatch then
		loadWatch = CreateFrame("Frame")
		loadWatch:SetScript("OnEvent", function(self, _, name)
			local fns = onLoad[name]
			if not fns then return end
			onLoad[name] = nil
			for i = 1, #fns do Guard(fns[i], name) end
			if next(onLoad) == nil then self:UnregisterEvent("ADDON_LOADED") end
		end)
	end
	loadWatch:RegisterEvent("ADDON_LOADED")
end

-- ---------------------------------------------------------------------------------------------
-- Broken skins. Another addon's update can break a pack. An error in a pack (its ns.Pack function,
-- a watch's dressing, or a hook of its that runs through ns.Guard, ns.HookOnce, ns.ScriptOnce or
-- ns.Queue) is put down once, with one line in chat, as
--   DaylightAddonSkinsDB.failed[key] = { ours = this plugin's version, target = the addon's,
--     err = the error's first line, at = time() }
-- and from then on the pack is skipped: ns.Enabled(key) says no (every pack's hooks ask it), its
-- watches are dropped, and its ns.Pack function isn't run after a reload. Its card on All Windows
-- shows the error. As soon as either version changes, the record goes and the pack is tried again;
-- ns.Retry(key) (the card's right-click, /skins retry) does it by hand.
-- Which pack an error belongs to: the key it ran under when known, else the first of this plugin's
-- Packs files in the error and its stack (each file is the pack of the first target it registers;
-- the Blizzard* files without one are the game windows').
-- ---------------------------------------------------------------------------------------------

failedNow = {}           -- key -> record: the packs off for this session
local svLoaded = false   -- (this plugin's saved variables are only there from its ADDON_LOADED)
local listeners = {}
local fileKey = {}       -- "Questie" (Packs/Questie.lua) -> its target key

local debugstack = _G.debugstack
local CHAT = "|cffa335eeAddon Skins|r: "

-- "Questie" for a path to this plugin's Packs/Questie.lua in an error or a stack. The game cuts a
-- long path's start to "..." ("...ddonSkins/Packs/Questie.lua"): what's left must end the way this
-- plugin's folder does (so DaylightUI_Skins' own Packs files never count).
local OURS = ("interface/addons/" .. ADDON .. "/"):lower()
local OURS_DIR = "/" .. ADDON:lower() .. "/"
local function PackFileIn(text)
	if type(text) ~= "string" then return nil end
	for before, name in text:gmatch("([^%s\"'%[%]]*)[/\\]Packs[/\\]([%w_]+)%.lua") do
		local head = (before:gsub("\\", "/")):lower()
		head = (head:gsub("^@", ""))
		if head:sub(1, 3) == "..." then
			local tail = head:sub(4) .. "/"
			if #tail > 1 and OURS:sub(-#tail) == tail then return name end
		elseif ("/" .. head .. "/"):sub(-#OURS_DIR) == OURS_DIR then
			return name
		end
	end
	return nil
end

local function KeyOfFile(file)
	if not file then return nil end
	local key = fileKey[file]
	if not key and file:sub(1, 8) == "Blizzard" then key = "Blizzard" end
	return key
end

-- The pack file that called the function asking (a registration: ns.Target, ns.Pack).
local function CallerFile()
	if type(debugstack) ~= "function" then return nil end
	local ok, stack = pcall(debugstack, 3, 4, 0)
	return ok and PackFileIn(stack) or nil
end

local function NoteFile(key)
	local file = CallerFile()
	if file and not fileKey[file] then fileKey[file] = key end
end

-- The target an error came from, or nil.
local function KeyOfError(err)
	local file = PackFileIn(err)
	if not file and type(debugstack) == "function" then
		local ok, stack = pcall(debugstack, 2)
		if ok then file = PackFileIn(stack) end
	end
	local key = KeyOfFile(file)
	if key and ns.targets[key] then return key end
	return nil
end

local function FailedDB()
	if not svLoaded then return nil end
	local db = _G.DaylightAddonSkinsDB
	if type(db) ~= "table" then
		db = {}
		_G.DaylightAddonSkinsDB = db
	end
	if type(db.failed) ~= "table" then db.failed = {} end
	return db.failed, db
end

-- The full error as well (to the game's error handler, BugSack's) only for a copy run from its
-- source folder or with DaylightUI_Dev loaded, as DaylightUI does for its own addon skins.
local function Dev()
	return ns.OurVersion() == "@project-version@" or ns.AddonLoaded("DaylightUI_Dev")
end

local function FirstLine(err)
	local line = tostring(err or "?"):match("^[^\n]*") or "?"
	line = line:gsub("^.-[Ii]nterface[/\\][Aa]dd[Oo]ns[/\\]" .. ADDON .. "[/\\]", "")
	if #line > 300 then line = line:sub(1, 300) end
	return line
end

local function StatusChanged()
	for i = 1, #listeners do xpcall(listeners[i], geterrorhandler()) end
end

-- fn() whenever a pack fails or is tried again (to repaint what shows it).
function ns.OnStatusChange(fn)
	if type(fn) == "function" then listeners[#listeners + 1] = fn end
end

-- The record of `key`'s error while its pack is off, or nil.
function ns.Failed(key)
	return key and failedNow[key] or nil
end

function ns.AnyFailed()
	return next(failedNow) ~= nil
end

-- "until Questie or Addon Skins updates" in a sentence: the game for its own windows.
function ns.RetryWhen(key)
	if IsGame(key) then return ns.L["Retried when the game or Addon Skins updates."] end
	return string.format(ns.L["Retried when %s or Addon Skins updates."], ns.targets[key] or key)
end

-- Puts down `key`'s error and switches its pack off (true), once: false when `key` isn't a
-- target or is already off.
function ns.Fail(key, err)
	if type(key) ~= "string" or not ns.targets[key] or failedNow[key] then return false end
	local rec = { ours = ns.OurVersion(), target = TargetVersion(key), err = FirstLine(err), at = _G.time() }
	failedNow[key] = rec
	local db = FailedDB()
	if db then db[key] = rec end
	local L = ns.L
	local label = ns.targets[key] or key
	if IsGame(key) then
		print(CHAT .. string.format(L["Couldn't dress %s: it hit an error, so it's left as it is until the game or Addon Skins updates. /skins status has the details."], label))
	else
		print(CHAT .. string.format(L["Couldn't dress %s: it hit an error, so it's left as it is until %s or Addon Skins updates. /skins status has the details."], label, label))
	end
	if Dev() then xpcall(function() geterrorhandler()(err) end, function() end) end
	StatusChanged()
	return true
end

-- `key`'s pack tried again (after a reload: its windows were left as they were). Nothing when
-- it isn't off.
function ns.Retry(key)
	local was = failedNow[key]
	failedNow[key] = nil
	local db, all = FailedDB()
	if db then db[key] = nil end
	if all and all.testFail == key then all.testFail = nil end
	if was then StatusChanged() end
	return was ~= nil
end

function ns.RetryAll()
	local any = false
	for key in pairs(failedNow) do
		if ns.Retry(key) then any = true end
	end
	local db, all = FailedDB()
	if db then wipe(db) end
	if all then all.testFail = nil end
	return any
end

-- /skins test <addon>: `key`'s pack fails once on purpose, as it next runs (after a reload).
function ns.TestFail(key)
	local _, all = FailedDB()
	if all then all.testFail = key end
end

local function TakeTestFail(key)
	local db = svLoaded and _G.DaylightAddonSkinsDB
	if type(db) == "table" and key and db.testFail == key then
		db.testFail = nil
		return true
	end
	return false
end

GuardError = function(err)
	local key = KeyOfError(err)
	if key then
		-- (Once: the same hook failing on every frame says nothing more.)
		if failedNow[key] or ns.Fail(key, err) then return end
	end
	geterrorhandler()(err)
end

-- A function run for `pack` (a hook's, a queued refresh's): not while the pack is off; the shared
-- helpers read its look while it runs (current, below); an error switches the pack off.
local running            -- the pack whose function is running
local function RunError(err)
	local pack = running
	if pack and (failedNow[pack] or ns.Fail(pack, err)) then return end
	GuardError(err)
end

-- The saved records, read as this plugin's saved variables come: kept while both versions are
-- the same, else gone (tried again), with one line in chat naming them.
local svWatch = CreateFrame("Frame")
svWatch:RegisterEvent("ADDON_LOADED")
svWatch:SetScript("OnEvent", function(self, _, name)
	if name ~= ADDON then return end
	self:UnregisterEvent("ADDON_LOADED")
	svLoaded = true
	local db = FailedDB()
	local again = {}
	local ours = ns.OurVersion()
	for key, rec in pairs(db) do
		if type(rec) == "table" and ns.targets[key] and rec.ours == ours and rec.target == TargetVersion(key) then
			if not failedNow[key] then failedNow[key] = rec end
		else
			db[key] = nil
			if type(rec) == "table" and ns.targets[key] then again[#again + 1] = ns.targets[key] end
		end
	end
	-- (Errors from before the saved variables came.)
	for key, rec in pairs(failedNow) do db[key] = rec end
	if #again > 0 then
		table.sort(again)
		print(CHAT .. string.format(ns.L["Trying again after an update: %s."], table.concat(again, ", ")))
	end
	if next(failedNow) then StatusChanged() end
end)

-- An addon this plugin dresses, for the options list. caps = what of its look can be set on its
-- own page: window (shell), controls (buttons, boxes, scroll bars), text (font, size, outline),
-- shadow (text shadow), colors (text colors and accent), font = the font it starts on
-- ("daylight" where the pack already puts the player's font on its text, else "addon").
-- A pack with settings of its own adds defaults = { name = value } (kept under look.<addon>.<name>
-- like the rest) and extra = function(at, following, hint) returning option groups, shown on its
-- page under the tab extraTab.
-- An addon split across folders lists them: caps.folders = { "DBM-Core", "DBM-GUI" } (the main
-- one first; caps.targets is read the same way). One switch, one card and one pack cover them all.
function ns.Target(addon, label, caps)
	local folders = caps and (caps.folders or caps.targets)
	if type(folders) == "table" and #folders > 0 then ns.folders[addon] = folders end
	NoteFile(addon)
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
local colors             -- DaylightUI's inks (ns.Colors below), nil = not asked yet

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
	colors = nil
end

-- A setting of this plugin's as it is saved, whatever the "own settings" switches say.
ns.Setting = Setting

-- DaylightUI's inks ({ VALUE = { r, g, b }, ... }, as API.Colors gives them). API.Colors makes a
-- fresh copy of every ink on each call, and the packs ask for one on every color they set: the
-- copy is kept until DaylightUI's style changes. Read it only; it is shared.
function ns.Colors()
	local c = colors
	if not c then
		c = API.Colors()
		colors = c
	end
	return c
end

-- Daylight UI 2.1.2 gave every window and panel a look of its own ("Use Daylight UI global style"),
-- and the tooltips' opacity and border moved into theirs: Tooltip bgAlpha, bgAlphaOwn, borderPx and
-- richAlpha are gone (cleared from saved profiles too, 2.1.2 DB.lua:588-598), Tooltip frameStyle is
-- in their place (DaylightUI_Tooltip\Defaults.lua:38), read through Style.LookOf("Tooltip")
-- (Style.lua:361). Its Style when it has those looks, else nil.
local function LookStyle()
	local Style = type(DUI) == "table" and DUI.Style
	if type(Style) == "table" and type(Style.LookOf) == "function" and type(Style.LookOwn) == "function"
		and type(Style.BackAlpha) == "function" then
		return Style
	end
	return nil
end

-- DaylightUI's tooltip background opacity. From 2.1.2 the tooltips' look says (Style.BackAlpha
-- ("Tooltip"), Style.lua:394: their own, or on the global style the 0.92 they have by design), as
-- its Tooltip module reads it (Tooltip.lua:49). Before: its own (Tooltip bgAlpha) while "Separate
-- tooltip background opacity" is on, else the shared window opacity (General windowAlpha). nil
-- when it can't be read.
-- which == "rich": the ground of its Rich tooltip cards instead (2.1.2 Tooltip.lua:56-62: 0.95 on
-- the global style, the look's own opacity otherwise; 2.0 and 2.1: Tooltip richAlpha in place of
-- bgAlpha, under the same switch).
local RICH_ALPHA = 0.95
function ns.TipAlpha(which)
	local Style = LookStyle()
	if Style then
		if which == "rich" then
			local okOwn, own = pcall(Style.LookOwn, "Tooltip")
			if okOwn and own ~= true then return RICH_ALPHA end
		end
		local ok, alpha = pcall(Style.BackAlpha, "Tooltip")
		return ok and type(alpha) == "number" and alpha or nil
	end
	local okOwn, own = pcall(API.GetSetting, "Tooltip", "bgAlphaOwn")
	local scope, path = "Tooltip", which == "rich" and "richAlpha" or "bgAlpha"
	if okOwn and own == false then scope, path = "general", "windowAlpha" end
	local ok, alpha = pcall(API.GetSetting, scope, path)
	return ok and type(alpha) == "number" and alpha or nil
end

-- The border size DaylightUI's tooltips have of their own, in screen pixels, or nil when they
-- take General's (leave borderPx out of the shell's opts then: the shell reads General's itself
-- and follows it). DaylightUI 2.0 dropped the fixed 3 px tooltip border (1.9.6
-- DaylightUI_Tooltip\Tooltip.lua:28, Tip.BORDER = 3, used at :129). 2.0 and 2.1: Tooltip borderPx
-- while "Own border and background" (Tooltip bgAlphaOwn) is on, else General's. From 2.1.2: the
-- tooltip look's borderPx while its global style is off (Tooltip frameStyle.global == false). Read
-- the supported way, API.GetSetting (API.lua:892). nil before 2.0.
function ns.TipBorder()
	if not ns.DaylightAtLeast(2, 0) then return nil end
	if LookStyle() then
		local okOwn, global = pcall(API.GetSetting, "Tooltip", "frameStyle.global")
		if not okOwn or global ~= false then return nil end
		local ok, px = pcall(API.GetSetting, "Tooltip", "frameStyle.borderPx")
		return ok and tonumber(px) or nil
	end
	local okOwn, own = pcall(API.GetSetting, "Tooltip", "bgAlphaOwn")
	if not okOwn or own ~= true then return nil end
	local ok, px = pcall(API.GetSetting, "Tooltip", "borderPx")
	if not ok then return nil end
	return tonumber(px)
end

-- DaylightUI's tooltip look as API.Skin opts, for an addon's tooltip a pack dresses: the shell
-- its Tooltip module puts on every tooltip that isn't one of its own cards. From 2.1.2 that is
-- { look = "Tooltip", flat, noBevel } (Tooltip.lua:146): the shell reads the tooltips' border,
-- corners, shadow, background color and opacity itself and DaylightUI lays it out again as any of
-- them changes (Style.lua:3301-3321); API.Skin hands the opts on as they are (API.lua:957-964).
-- 2.0 and 2.1: flat, no bevel, the tooltip opacity, the tooltip border. Before 2.0 the border is
-- the fixed 3 px. A fresh table each call. The same in the Simple and the Rich look: DaylightUI
-- draws its Rich cards over the game's main and compare tooltips only and gives every other
-- tooltip, addons' included, this shell in both.
-- Titles, text and small text need nothing here: an addon tooltip made from the game's tooltip
-- template draws with the game's three tooltip fonts, which DaylightUI sets to the Tooltip
-- sizes and fonts itself.
function ns.TipLook()
	if LookStyle() then return { flat = true, noBevel = true, look = "Tooltip" } end
	local look = { flat = true, noBevel = true, bgAlpha = ns.TipAlpha() }
	if ns.DaylightAtLeast(2, 0) then
		look.borderPx = ns.TipBorder()
	else
		look.borderPx = 3
	end
	return look
end

-- DaylightUI's tooltip look (2.0, API 1.12): "rich" (its own cards over the game's main and
-- compare tooltips), "simple", or nil while its Tooltip module is off or another addon draws the
-- tooltips (API.TooltipStyle, 2.0 API.lua:820-825; not there on 1.9.x: nil).
function ns.TipStyle()
	if type(API.TooltipStyle) ~= "function" then return nil end
	local ok, style = pcall(API.TooltipStyle)
	return ok and style or nil
end

-- Whether a DaylightUI setting change (SettingChanged's scope, path) moves ns.TipLook: the
-- tooltip opacity, or from 2.0 the tooltips' own border size, the Rich / Simple pick and the
-- cards' opacity (for what sits against a card). (General's border needs no word here: a shell
-- with no borderPx of its own is laid out again by DaylightUI as General changes.)
-- From 2.1.2 the opacity and border are in the tooltips' look table: Tooltip frameStyle, or a key
-- under it ("frameStyle.windowAlpha"; a reset writes the table itself).
local TIP_PATHS = { bgAlpha = true, bgAlphaOwn = true, borderPx = true, style = true, richAlpha = true, frameStyle = true }
function ns.TipLookChanged(scope, path)
	if scope == "Tooltip" then
		return TIP_PATHS[path] == true or (type(path) == "string" and path:sub(1, 11) == "frameStyle.")
	end
	return scope == "general" and path == "windowAlpha"
end
ns.TipAlphaChanged = ns.TipLookChanged

-- Whether `key`'s switch is on (and DaylightUI's Skins module), whatever became of its pack.
local function SwitchedOn(key)
	local on = skinsOn
	if on == nil then
		local ok, value = pcall(API.IsModuleEnabled, "Skins")
		on = ok and value ~= false
		if ready then skinsOn = on end
	end
	if not on then return false end
	return not key or Setting(key) ~= false
end
ns.SwitchedOn = SwitchedOn

-- Whether `key`'s windows are to be dressed: its switch is on and its pack isn't off after an
-- error (Broken skins, above).
function ns.Enabled(key)
	if key and failedNow[key] then return false end
	return SwitchedOn(key)
end

-- ---------------------------------------------------------------------------------------------
-- The look of one addon's windows. While "Use DaylightUI's settings for all windows" is on (the
-- way it starts), every answer is the default: the player's DaylightUI look, nothing of their own.
-- ---------------------------------------------------------------------------------------------

ns.LOOK = {
	own = false,
	font = "addon", size = 1, outline = "keep", shadow = false,
	daylightColors = true, daylightAccent = true, accentMode = "daylight", accent = { 0.25, 0.85, 0.6 },
	ownOpacity = false, opacity = 0.85, border = true, ownBorder = false, borderPx = 8, bevel = true,
	gradientBorder = false,
	controls = true,
}
-- The ones a shell is drawn from: a change to any other leaves the shells as they are.
local SHELL_LOOK = { own = true, ownOpacity = true, opacity = true, border = true, ownBorder = true, borderPx = true, bevel = true,
	accentMode = true, daylightAccent = true, gradientBorder = true }

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

-- The path of one of `key`'s look settings ("look.<key>.<name>"), joined once: a font hook asks for
-- these many times a second, and a new string each time would be thrown away at once.
local lookPaths = {}     -- key -> name -> path
local function LookPath(key, name)
	local byName = lookPaths[key]
	if not byName then
		byName = {}
		lookPaths[key] = byName
	end
	local path = byName[name]
	if not path then
		path = "look." .. key .. "." .. name
		byName[name] = path
	end
	return path
end

-- Whether `key`'s windows follow DaylightUI's settings: yes, unless the player turned on "Custom
-- settings" on its page. (No key: the switch for all windows alone.) The switch for all windows only
-- holds the addons that weren't given settings of their own.
local function Following(key)
	if key and Setting(LookPath(key, "own")) == true then return false end
	return Setting("followDaylight") ~= false
end
ns.Following = Following

local function Look(key, name)
	if not key or Following(key) then return LookDefault(key, name) end
	local value = Setting(LookPath(key, name))
	if value ~= nil then return value end
	return LookDefault(key, name)
end
ns.Look = Look

-- ---------------------------------------------------------------------------------------------
-- Small helpers the packs share
-- ---------------------------------------------------------------------------------------------

-- The addon whose windows are being dressed right now: set round a pack's function and a watch's,
-- so the shared helpers below know whose look to read without being told each time.
local current

-- The accent an addon's page can pick, the same choices as DaylightUI's own Accent setting:
-- "daylight" (DaylightUI's accent as the player set it, a gradient one included), the Daylight
-- gradient, the class color, the class gradient, a custom color, or DaylightUI's custom gradient
-- (its General > Appearance colors, DaylightUI 1.9.2 on).
ns.ACCENT_MODES = { daylight = true, gradient = true, class = true, classGradient = true, custom = true,
	customGradient = true }

local function DStyle()
	local Style = type(DUI) == "table" and DUI.Style
	return type(Style) == "table" and Style or nil
end

-- Which accent `key`'s windows use (one of ns.ACCENT_MODES). A page saved before the choices
-- came (only "Use DaylightUI's accent" off) is its custom color.
local function AccentMode(key)
	if not key then return "daylight" end
	local mode = Look(key, "accentMode")
	if not ns.ACCENT_MODES[mode] then mode = "daylight" end
	if mode == "daylight" and Look(key, "daylightAccent") == false then mode = "custom" end
	return mode
end
ns.AccentMode = AccentMode

-- Whether DaylightUI's gradients are on at all (General > Gradients off makes every accent one
-- color, its own gradient accents too; an addon's own gradient follows that).
local function GradientsOn()
	local G = type(DUI) == "table" and DUI.Gradients
	if type(G) ~= "table" or type(G.Flat) ~= "function" then return true end
	local ok, flat = pcall(G.Flat)
	return not (ok and flat)
end

local function ClassPair()
	local Style = DStyle()
	if not Style or type(Style.ClassAccentPair) ~= "function" then return nil end
	local ok, lo, hi = pcall(Style.ClassAccentPair)
	if ok and type(lo) == "table" and type(hi) == "table" then return lo, hi end
	return nil
end

-- DaylightUI's custom gradient: its colors, left to right (two to five; shared tables), or nil
-- (a DaylightUI before 1.9.2).
local function CustomStops()
	local Style = DStyle()
	if not Style or type(Style.CustomAccentStops) ~= "function" then return nil end
	local ok, stops = pcall(Style.CustomAccentStops)
	if ok and type(stops) == "table" and #stops >= 2 then return stops end
	return nil
end

-- The stops `key`'s gradient text runs through when its accent is one with more than two colors
-- (its own custom gradient pick, or DaylightUI's accent while that is the custom gradient).
local function TextStops(key)
	local mode = AccentMode(key)
	if mode == "customGradient" then return CustomStops() end
	local Style = DStyle()
	if mode == "daylight" and Style and type(Style.AccentStops) == "function" then
		local ok, stops = pcall(Style.AccentStops)
		if ok and type(stops) == "table" then return stops end
	end
	return nil
end

-- The spot t (0 to 1) along a list of { r, g, b } stops, evenly spaced (DaylightUI's StopsAt).
local function StopsAt(stops, t)
	t = math.max(0, math.min(1, t)) * (#stops - 1)
	local i = math.min(#stops - 1, floor(t) + 1)
	local f, a, b = t - (i - 1), stops[i], stops[i + 1]
	return a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f
end

-- The two ends of `key`'s accent when it's a gradient ({ r, g, b } each, left to right; shared
-- tables, not to be changed), or nil for a single-color accent.
function ns.AccentPairOf(key)
	local mode = AccentMode(key)
	local Style = DStyle()
	if not Style then return nil end
	if mode == "daylight" then
		if type(Style.AccentPair) ~= "function" then return nil end
		local ok, lo, hi = pcall(Style.AccentPair)
		if ok and type(lo) == "table" and type(hi) == "table" then return lo, hi end
		return nil
	end
	if not GradientsOn() then return nil end
	if mode == "gradient" then
		local shape = Style.GRADIENT_SHAPE
		if type(shape) == "table" and type(shape[1]) == "table" then return shape[1], shape[2] end
		return nil
	end
	if mode == "classGradient" then return ClassPair() end
	if mode == "customGradient" then
		local stops = CustomStops()
		if stops then return stops[1], stops[#stops] end
	end
	return nil
end

-- The accent `key`'s windows use, as one color (text, thin lines, a single mark): its own, when
-- picked on its page, or DaylightUI's. A gradient accent gives its middle, as DaylightUI does.
function ns.AccentOf(key)
	local mode = AccentMode(key)
	if mode == "custom" then
		local own = Look(key, "accent")
		if type(own) == "table" and type(own[1]) == "number" then return own[1], own[2], own[3] end
	elseif mode == "gradient" then
		local Style = DStyle()
		local m = Style and Style.GRADIENT_MID
		if type(m) == "table" and type(m[1]) == "number" then return m[1], m[2], m[3] end
	elseif mode == "classGradient" then
		local lo, hi = ClassPair()
		if lo then return (lo[1] + hi[1]) / 2, (lo[2] + hi[2]) / 2, (lo[3] + hi[3]) / 2 end
	elseif mode == "customGradient" then
		-- (Its middle, as DaylightUI's accent gives it, Gradients off or not.)
		local stops = CustomStops()
		if stops then return StopsAt(stops, 0.5) end
	end
	if mode == "class" or mode == "classGradient" then
		local _, token = UnitClass("player")
		local Style = DStyle()
		if Style and type(Style.RawClassColor) == "function" then
			local ok, r, g, b = pcall(Style.RawClassColor, token)
			if ok and type(r) == "number" then return r, g, b end
		end
	end
	return API.Accent()
end

-- A texture with a picture in `key`'s accent: tinted along the gradient when the accent is one
-- (orientation "HORIZONTAL" by default; "VERTICAL" runs dark at the bottom to light at the top),
-- otherwise the one color.
function ns.PaintAccent(tex, alpha, orientation, key)
	if not tex then return end
	alpha = alpha or 1
	local lo, hi = ns.AccentPairOf(key or current)
	if lo and tex.SetGradient and CreateColor then
		tex:SetVertexColor(1, 1, 1, alpha)
		tex:SetGradient(orientation or "HORIZONTAL", CreateColor(lo[1], lo[2], lo[3], alpha), CreateColor(hi[1], hi[2], hi[3], alpha))
		return
	end
	local r, g, b = ns.AccentOf(key or current)
	tex:SetVertexColor(r, g, b, alpha)
end

-- A plain filled shape (a bar's fill, a line, a mark) in `key`'s accent: the gradient across it
-- when the accent is one, otherwise the one color. Takes the place of tex:SetColorTexture(accent).
function ns.FillAccent(tex, alpha, orientation, key)
	if not tex then return end
	alpha = alpha or 1
	local lo, hi = ns.AccentPairOf(key or current)
	if lo and tex.SetGradient and CreateColor then
		tex:SetColorTexture(1, 1, 1, 1)
		tex:SetVertexColor(1, 1, 1, alpha)
		tex:SetGradient(orientation or "HORIZONTAL", CreateColor(lo[1], lo[2], lo[3], alpha), CreateColor(hi[1], hi[2], hi[3], alpha))
		return
	end
	local r, g, b = ns.AccentOf(key or current)
	tex:SetColorTexture(r, g, b, alpha)
	-- (A plain vertex color clears a gradient put on before, when the accent was one.)
	tex:SetVertexColor(1, 1, 1, 1)
end

-- Text in `key`'s accent: letter by letter along the gradient when the accent is one (the font
-- string drawn white), otherwise the one color. Anything but a plain string is set as it is.
function ns.AccentText(fs, text, key)
	if not fs then return end
	key = key or current
	local lo, hi = ns.AccentPairOf(key)
	if lo and type(text) == "string" and text ~= "" and not (issecretvalue and issecretvalue(text)) then
		local mode = AccentMode(key)
		local colored
		if (mode == "gradient" or (mode == "daylight" and DStyle() and DStyle().AccentSweep and DStyle().AccentSweep() == "daylight"))
			and type(DUI.GradientText) == "function" then
			colored = DUI.GradientText(text)
		else
			-- (Every color of a custom gradient, not only its two ends.)
			local stops = TextStops(key) or { lo, hi }
			local chars, out = {}, {}
			for ch in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do chars[#chars + 1] = ch end
			local n = #chars
			for i, ch in ipairs(chars) do
				local r, g, b = StopsAt(stops, n > 1 and (i - 1) / (n - 1) or 0.5)
				out[i] = string.format("|cff%02x%02x%02x%s", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5), ch)
			end
			colored = table.concat(out) .. "|r"
		end
		fs:SetText(colored)
		fs:SetTextColor(1, 1, 1)
		return
	end
	fs:SetText(text)
	fs:SetTextColor(ns.AccentOf(key))
end

-- A shell lit in `key`'s accent (a picked tab's edge): its outline along the gradient when the
-- accent is one. border = the single color to use otherwise ({ r, g, b }).
function ns.LightShell(s, border, key)
	local Kit = ns.Kit
	if not s or not Kit then return end
	local lo, hi = ns.AccentPairOf(key or current)
	local Style = DStyle()
	if lo and not s.lite and Style and type(Style.SetShellColors) == "function" and type(s.opts) == "table" then
		Guard(Style.SetShellColors, s, border, nil, { lo, hi })
		return
	end
	Kit.Paint(s, border)
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


function ns.Controls(key)
	return Look(key or current, "controls") ~= false
end

local LSM = type(LibStub) == "table" and LibStub("LibSharedMedia-3.0", true) or nil
ns.LSM = LSM

local OUTLINES = { none = "", thin = "OUTLINE", thick = "THICKOUTLINE" }

-- Other alphabets. A font file draws only the letters it has: DaylightUI's fonts have no Korean or
-- Chinese ones, and only some have Russian. DaylightUI's own text goes through font families that
-- take those letters from the game's fonts; a plain SetFont here has no family, so on a Korean or
-- Chinese client (unless DaylightUI's "Use my language's font" is on, which makes its font the
-- game's) and on a Russian one with a font lacking Russian, the player's font isn't put on: the
-- string keeps the game's or the addon's face, its size, outline and colors still change. Every
-- other client keeps every face. Shared fonts picked for one addon are left as LibSharedMedia
-- lists them (it lists only the fonts with the client's letters).
local LOCALE = type(GetLocale) == "function" and GetLocale() or ""
local CJK = { koKR = true, zhCN = true, zhTW = true }
-- DaylightUI's default (Expressway) has Russian; used when DaylightUI's own list can't be read.
local CYRILLIC = { ["expresswayfree.ttf"] = true, ["frizqt___cyr.ttf"] = true }
local cyrillicOf = {}    -- face -> whether it has Russian, worked out once
local function HasCyrillic(face)
	local known = cyrillicOf[face]
	if known ~= nil then return known end
	local name = string.lower(string.match(face, "([^\\/]+)$") or face)
	local Style = type(_G.DaylightUI) == "table" and _G.DaylightUI.Style
	local list = type(Style) == "table" and type(Style.CYRILLIC) == "table" and Style.CYRILLIC or CYRILLIC
	known = list[name] == true
	cyrillicOf[face] = known
	return known
end

-- face, when this client can draw its words in it; nil when the string should keep its own.
function ns.SafeFace(face)
	if type(face) ~= "string" then return nil end
	if CJK[LOCALE] then
		local db = type(_G.DaylightUI) == "table" and _G.DaylightUI.DB
		local ok, own = false, false
		if type(db) == "table" and type(db.UseLocalFont) == "function" then ok, own = pcall(db.UseLocalFont) end
		return ok and own == true and face or nil
	end
	if LOCALE == "ruRU" and not HasCyrillic(face) then return nil end
	return face
end

-- Whether a string's text has letters a face has no glyphs for (they'd draw as empty boxes): on
-- any client, a menu or list may name a language in its own alphabet (Ελληνικά, 한국어). By the
-- UTF-8 lead byte, looked at only when the text has a byte from 0xCD up: Greek (U+0370 on: CD B0-BF,
-- CE, CF; Greek Extended E1 BC-BF), Cyrillic (D0-D3: when the face lacks it, ns.SafeFace's list),
-- Armenian, Hebrew, Arabic and the rest of the two-byte scripts (D4-DF), Indic and Thai (E0),
-- Georgian, Hangul Jamo and the like (E1 80-B7), CJK, kana and Hangul (E3-ED) and the four-byte
-- planes (F0-F4). Latin-1 and Latin Extended (C2-CC, E1 B8-BB) and punctuation (E2) are drawn.
local function Foreign(text, face)
	if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return false end
	if not text:find("[\205-\255]") then return false end
	if text:find("\205[\176-\191]") or text:find("[\206\207\212-\224\227-\237\240-\244]")
		or text:find("\225[\128-\183\188-\191]") then
		return true
	end
	if text:find("[\208-\211]") then return not (type(face) == "string" and HasCyrillic(face)) end
	return false
end
ns.Foreign = Foreign

-- Strings given a face of ours: the string's own face (to go back to when its text turns to
-- another alphabet), the face of ours it should have, and the ones kept on their own face for
-- their text. Rechecked by every font follow (ns.FollowFont: each walk over a window), and as the
-- text is set on a string whose addon gave it a SetText of its own (Mastercraft's, ns.Text): the
-- game's own strings are never hooked (a field written on them would taint the game's calls).
local ownFace = setmetatable({}, { __mode = "k" })
local ourFace = setmetatable({}, { __mode = "k" })
local keptFace = setmetatable({}, { __mode = "k" })
local textHooked = setmetatable({}, { __mode = "k" })

local function Recheck(fs)
	local face = ourFace[fs]
	if not face then return end
	local ok, path, size, flags = pcall(fs.GetFont, fs)
	if not ok or type(size) ~= "number" or size <= 0 then return end
	local text = fs:GetText()
	if Foreign(text, face) then
		if path == face then
			keptFace[fs] = true
			fs:SetFont(ownFace[fs] or _G.STANDARD_TEXT_FONT, size, flags or "")
		end
	elseif keptFace[fs] and path ~= face then
		keptFace[fs] = nil
		fs:SetFont(face, size, flags or "")
	end
end

-- The face fs gets: face, or its own (path) when its text needs letters face lacks. Strings (and
-- text boxes) only: a font object has no text of its own.
local function FaceFor(fs, path, face)
	if face == nil or face == path then return face or path end
	local kind = fs.GetObjectType and fs:GetObjectType()
	if kind ~= "FontString" and kind ~= "EditBox" then return face end
	if ownFace[fs] == nil and path ~= nil and path ~= face then ownFace[fs] = path end
	ourFace[fs] = face
	if not textHooked[fs] then
		textHooked[fs] = true
		if type(rawget(fs, "SetText")) == "function" then hooksecurefunc(fs, "SetText", Recheck) end
	end
	if Foreign(fs:GetText(), face) then
		keptFace[fs] = true
		return ownFace[fs] or path
	end
	keptFace[fs] = nil
	return face
end
ns.FaceFor = FaceFor

-- The player's font (DaylightUI's), when this client can draw in it.
function ns.PlayerFace()
	local ok, face = pcall(API.Font)
	return ok and ns.SafeFace(face) or nil
end

-- The text look of `key`, worked out once: face (nil = the addon's own), scale (nil = as it is),
-- flags (nil = the addon's own outline), shadow, and plain = nothing of the text is changed.
local function Text(key)
	local t = texts[key]
	if t then return t end
	t = {}
	local font = Look(key, "font")
	if font == "daylight" then
		t.face = ns.PlayerFace()
		t.dropped = t.face == nil
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

-- Whether `key`'s look asks for DaylightUI's font and this client can't draw in it (ns.SafeFace).
function ns.FaceDropped(key)
	return Text(key).dropped == true
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
	local face = t.face and FaceFor(fs, path, t.face) or path
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
	-- "Gradient window borders" of its own: the outline along the addon's gradient accent, or kept
	-- plain (DaylightUI's own switch would otherwise sweep it along DaylightUI's accent).
	if not out.noBorder and not out.borderColor and not out.borderPair then
		local lo, hi
		if Look(key, "gradientBorder") == true then lo, hi = ns.AccentPairOf(key) end
		local Style = DStyle()
		if lo then
			out.borderPair = { lo, hi }
		elseif Style and type(Style.BORDER) == "table" and type(Style.BAND) == "table" then
			out.borderColor, out.bandColor = Style.BORDER, Style.BAND
		end
	end
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

-- Kit.EachRow asks a list for its rows right away, and a game list has none to ask before its
-- view is set (ScrollBox.lua: ForEachFrame reads self:GetView()). Some lists get theirs only on
-- their first show: the macro window's grid and every icon picker (ScrollBoxSelectorMixin:OnShow
-- -> Init), so a walk over such a window before then (DaylightUI's own or a pack's) raised
-- "ScrollBox.lua:595: attempt to index a nil value". Here such a list is held back until the game
-- gives it a view (a secure hook on its SetView, once per list), then handed to the Kit in the
-- order it was asked for: the first one unnamed becomes the Kit's default as before, a key asked
-- again replaces its function. Everything else goes straight through.
local rowsHeld = setmetatable({}, { __mode = "k" })   -- list -> { fn or false, key, ... }
local rowsHooked = setmetatable({}, { __mode = "k" })

local function GuardRows(Kit)
	local EachRow = type(Kit) == "table" and Kit.EachRow
	if type(EachRow) ~= "function" or ns.rowsGuarded then return end
	ns.rowsGuarded = true
	local function release(box)
		local held = rowsHeld[box]
		if not held then return end
		rowsHeld[box] = nil
		for i = 1, #held do Guard(EachRow, box, held[i].fn, held[i].key) end
	end
	Kit.EachRow = function(box, fn, key, ...)
		if type(box) == "table" and box.ForEachFrame and type(box.GetView) == "function"
			and type(box.SetView) == "function" and type(fn) == "function" then
			local ok, view = pcall(box.GetView, box)
			if ok and view == nil then
				local held = rowsHeld[box]
				if not held then
					held = {}
					rowsHeld[box] = held
				end
				local at
				for i = 1, #held do
					if held[i].key == key then at = i break end
				end
				if not at then
					held[#held + 1] = { fn = fn, key = key }
				elseif key ~= nil then
					held[at].fn = fn
				end
				if not rowsHooked[box] then
					rowsHooked[box] = true
					hooksecurefunc(box, "SetView", release)
				end
				return
			end
		end
		return EachRow(box, fn, key, ...)
	end
end

local function GotKit(Kit)
	GuardRows(Kit)
	if ns.Kit or not Kit then return end
	ns.Kit = Kit
	local list = waiting
	waiting = {}
	for i = 1, #list do Guard(list[i], Kit) end
end

-- The guard goes on as this file loads: DaylightUI starts its window skins (the always-loaded
-- windows, the character window's icon picker among them) before it fires "Login", and before any
-- pack has been handed the Kit. DaylightUI's skins load ahead of this plugin (OptionalDeps) and
-- use the same Kit; DaylightUI.Skins.Kit is its door for plugins. "Login" is the second chance.
local function GuardRowsNow()
	local skins = type(_G.DaylightUI) == "table" and _G.DaylightUI.Skins
	if type(skins) ~= "table" or type(skins.Kit) ~= "function" then return end
	local ok, Kit = pcall(skins.Kit)
	if ok then GuardRows(Kit) end
end
GuardRowsNow()
me.On("Login", GuardRowsNow)

function ns.WithKit(fn)
	if ns.Kit then
		Guard(fn, ns.Kit)
	else
		waiting[#waiting + 1] = fn
	end
end

-- ns.Pack(addon, label, fn, caps): fn(Kit) runs once `addon` has loaded; return false to be asked
-- again. caps: see ns.Target. A target split across folders (caps.folders) runs as its main
-- folder loads. An error in fn switches the pack off (Broken skins, above); a pack that's off
-- isn't run.
function ns.Pack(addon, label, fn, caps)
	if label then ns.Target(addon, label, caps) end
	-- The target it dresses: its own, or (a Blizzard_* addon's) its file's.
	local key = (label or ns.targets[addon]) and addon or KeyOfFile(CallerFile())
	local folder = addon
	local list = ns.folders[addon]
	if list and list[1] then
		folder = list[1]
		for _, f in ipairs(list) do
			if f == addon then folder = addon break end
		end
	end
	me.RegisterSkin(folder, function(Kit)
		GotKit(Kit)
		if key and failedNow[key] then return end
		local run = fn
		if key and TakeTestFail(key) then
			run = function() error("Addon Skins test error (/skins test " .. key .. ")", 0) end
		end
		if not run or not ns.Enabled(label and addon or nil) then return end
		local was = current
		if label then current = addon end
		local ok, out = pcall(run, Kit)
		current = was
		if not ok then
			if key and ns.targets[key] then
				ns.Fail(key, out)
				return
			end
			error(out, 0)
		end
		return out
	end)
end

-- ---------------------------------------------------------------------------------------------
-- Frames made late (on a window's first open): looked for, only after something that can make one
-- ---------------------------------------------------------------------------------------------

-- The fast path is the rule: a pack hooks the call that makes or opens a window and dresses it
-- right there (ns.WatchNow() runs every pending watch at once, for hooks that only know "something
-- may have been made"). The watches below are the safety net. Nothing runs while nothing happens:
-- they look every frame for a short while after something that can make or open a window (a click
-- anywhere, an addon loading, a loading screen, a window the game opens, a pack's hook asking),
-- and for a moment after a frame is made (the CreateFrame hook below: a window a keybind or a
-- slash command makes, with no click). A window made then is found in that same frame, before the
-- game draws it, so it never shows undressed. A watch whose frame is found leaves the list; once
-- the burst is over (or no watch is left) the looking frame hides and costs nothing. Each look is
-- a name lookup or a small function per waiting window.
local watches = {}
local watcher = CreateFrame("Frame")
watcher:Hide()
local ticking = false
local BURST = 2      -- seconds of a look every frame after a trigger
local MADE = 0.25    -- seconds of a look every frame after a frame was made
local burstLeft = 0
local names = {}     -- frame name -> how many watches wait for it (the CreateFrame hook's test)
local getters = 0    -- how many watches wait on a function instead of a name

local function Listed(w, by)
	if type(w.get) == "string" then
		local n = (names[w.get] or 0) + by
		names[w.get] = n > 0 and n or nil
	else
		getters = getters + by
	end
end

-- A watch for an addon that isn't there (not installed, switched off in the addon list, or one that
-- couldn't load and isn't loaded on demand): its window never comes this session. Asked once per
-- watch, after login; the game's own windows and a pack's own keys are always looked for.
local function NeverComes(w)
	if w.checked then return false end
	w.checked = true
	if not ns.targets[w.key] or IsGame(w.key) then return false end
	local state = ns.TargetState(w.key)
	return state == "missing" or state == "disabled" or state == "notloaded"
end

local function Found(w, frame)
	ns.WithKit(function(Kit)
		if failedNow[w.key] then return end
		local was = current
		current = w.key
		local ok, err = pcall(w.fn, frame, Kit)
		current = was
		if not ok then
			-- (Put down against its pack; the game's error handler only for one that isn't a target.)
			if ns.Fail(w.key, err) or failedNow[w.key] then return end
			error(err, 0)
		end
	end)
end

local function Tick()
	-- (A window found can make another watch, or a hook can ask again mid-look: one look at a time.)
	if ticking then return end
	ticking = true
	for i = #watches, 1, -1 do
		local w = watches[i]
		-- (Its switch asked once, the first look after login: a switch takes hold after a reload.
		-- Asking every watch's switch on every frame of a burst was most of this loop's time; only
		-- a pack turned off by an error since is still looked for each time.)
		if ready and not w.on then
			w.on = ns.Enabled(w.key) and not NeverComes(w) or nil
		end
		if ready and (not w.on or failedNow[w.key]) then
			-- Its addon is switched off (a switch takes hold after a reload), or isn't there: not
			-- looked for again.
			table.remove(watches, i)
			Listed(w, -1)
		else
			local get, frame = w.get
			if type(get) == "string" then
				frame = _G[get]
			else
				local ok, found = pcall(get)
				frame = ok and found or nil
			end
			if frame and (ready or ns.Enabled(w.key)) then
				table.remove(watches, i)
				Listed(w, -1)
				Found(w, frame)
			end
		end
	end
	ticking = false
	if #watches == 0 then watcher:Hide() end
end

-- Shown only for a burst: a look every frame for its first EVERY seconds (a window a click makes
-- comes then, found before it's drawn), then one look at each of LATER's marks (one an addon
-- makes a moment later), not every frame (Perfy, 2026-11-25: 2 s of looks every frame after each
-- click or frame made kept this running a third of the time). Hidden the frame it runs out (Tick
-- hides it too, with no watch left).
local EVERY = 0.25
local LATER = { 0.5, 1, 2 }
local age, nextMark = 0, 1
watcher:SetScript("OnUpdate", function(self, elapsed)
	burstLeft = burstLeft - elapsed
	age = age + elapsed
	if burstLeft <= 0 then self:Hide() end
	if age <= EVERY then
		Tick()
	elseif LATER[nextMark] and age >= LATER[nextMark] then
		while LATER[nextMark] and age >= LATER[nextMark] do nextMark = nextMark + 1 end
		Tick()
	elseif burstLeft <= 0 then
		Tick()
	end
end)

-- Something that may make a window: looks for the next `seconds` (BURST), as above.
local function Burst(seconds)
	seconds = type(seconds) == "number" and seconds or BURST
	if seconds > burstLeft then burstLeft = seconds end
	age, nextMark = 0, 1
	if ns.loggedIn and #watches > 0 then watcher:Show() end
end

-- ns.Watch(key, get, fn): `get` = a global frame name or a function returning the frame (or nil);
-- fn(frame, Kit) runs once, when it exists. The fallback: pair it with a hook on the call that
-- makes the window (and ns.WatchNow() or the dressing called from that hook).
function ns.Watch(key, get, fn)
	local w = { key = key, get = get, fn = fn }
	watches[#watches + 1] = w
	Listed(w, 1)
	if ns.loggedIn then Burst() end
end

-- Every pending watch looked at now (from a hook on an addon's open / build call), and every frame
-- for the next while (what the call opens may be made a frame or two later).
function ns.WatchNow()
	if ns.loggedIn and #watches > 0 then
		Burst()
		Guard(Tick)
	end
end

-- The triggers: a click anywhere (most windows open from one), an addon loading, a loading screen,
-- a window the game opens for an NPC (a merchant, a trainer, the auction house: also opened with
-- the interact key, no click) or for loot.
local triggers = CreateFrame("Frame")
triggers:RegisterEvent("GLOBAL_MOUSE_UP")
triggers:RegisterEvent("ADDON_LOADED")
triggers:RegisterEvent("PLAYER_ENTERING_WORLD")
triggers:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
triggers:RegisterEvent("LOOT_OPENED")
triggers:SetScript("OnEvent", function() Burst() end)

-- A window the game's panel manager opens (a keybind's character or spellbook window, a panel an
-- addon opens the game's way): Blizzard_UIParentPanelManager Shared/UIParentPanelManager.lua:871.
-- A post-hook: it runs after the game's call and only starts our looking frame.
if type(_G.ShowUIPanel) == "function" then
	hooksecurefunc("ShowUIPanel", function() Burst() end)
end

-- A frame made: when it's one a watch waits for by name, or any frame while a watch waits on a
-- function (what it returns is often a field set as the window is built), a short burst of looks.
-- This is what finds a window first made by a keybind or a slash command, with no click before
-- it. A post-hook, so the game's own call is untouched; the test is a table lookup. Frames made
-- by addons that kept their own copy of CreateFrame before this file loaded aren't seen here
-- (the other triggers still are). ns.OnFrameMade(fn): fn(kind, name, parent) on each one too
-- (Auto.lua); it must be as cheap.
local madeFns = {}
function ns.OnFrameMade(fn)
	if type(fn) == "function" then madeFns[#madeFns + 1] = fn end
end
-- (A function watch only for a top-level frame, parent none or UIParent, as windows are: some of
-- those watches wait all session, and the many frames made inside windows, pools and nameplates,
-- in a fight too, must not start looks.)
hooksecurefunc("CreateFrame", function(kind, name, parent)
	if (name ~= nil and names[name]) or (getters > 0 and (parent == nil or parent == UIParent)) then Burst(MADE) end
	for i = 1, #madeFns do madeFns[i](kind, name, parent) end
end)

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	ns.loggedIn = true
	if #watches > 0 then
		Burst()
		Tick()
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
	-- (pcall: a prototype table that only reaches frame methods through its metatable, like
	-- LibQTip's, errors here; it isn't a frame, so it isn't forbidden.)
	if obj.IsForbidden then
		local ok, no = pcall(obj.IsForbidden, obj)
		if ok and no then return false end
	end
	return true
end
ns.Usable = Usable

-- ns.Usable, and not one of the game's protected frames: what ns.HookOnce and ns.ScriptOnce
-- accept. (ns.Usable itself still lets protected frames through, as the packs expect.)
local function Unprotected(obj)
	if not Usable(obj) then return false end
	if obj.IsProtected then
		local ok, protected = pcall(obj.IsProtected, obj)
		if ok and protected then return false end
	end
	return true
end
ns.Unprotected = Unprotected

-- ---------------------------------------------------------------------------------------------
-- Shared refresh helpers, for packs that follow an addon's own calls (the migration pass moves
-- the packs' hand-made queues and hook flags onto these).
--
-- Rules (see the Taint notes in Packs/Blizzard.lua): hook the target addon's own functions and
-- frames only. Never hooksecurefunc the game's protected frames, nor a function the game runs
-- from secure code (an action button's update, a frame shown from its event code); never hook a
-- function the addon hands to C_Timer (it runs from the timer, not from the call that set it).
-- Looks only inside the callbacks: textures, fonts, colors, DaylightUI's shells.
--
--   ns.Queue(id, fn, pack)
--     Coalesces a burst: however often it's asked in one frame, fn runs once, on the next frame
--     (C_Timer.After(0)). id = anything (a string, a frame); the last fn given for an id runs.
--     In a fight it waits for the fight's end (then runs once). Skipped while `pack` is off.
--   ns.HookOnce(obj, method, fn, pack)
--     hooksecurefunc(obj, method, fn) once per object, method and pack (a second call is a
--     no-op: safe to call from code that runs on every show). obj = nil hooks the global
--     function `method`. Refused (false) for a protected or forbidden frame.
--   ns.ScriptOnce(frame, script, fn, pack)
--     frame:HookScript(script, fn), once per frame, script and pack. Refused for a protected
--     or forbidden frame, or one without that script.
-- `pack` = the target key; left out, the pack being dressed as it's called (inside a pack's
-- function or a watch). fn runs only while ns.Enabled(pack), with the shared helpers reading
-- that pack's look, and an error in it switches the pack off (Broken skins) instead of
-- repeating every frame. Example:
--   ns.HookOnce(SomeAddon, "RefreshList", function() ns.Queue("SomeAddon:list", Repaint) end, KEY)
--   ns.ScriptOnce(SomeAddonFrame, "OnShow", function(f) ns.Queue(f, function() Dress(f) end) end, KEY)
-- ---------------------------------------------------------------------------------------------

-- fn(...) for `pack`, guarded (RunError: Broken skins, above).
local function Run(pack, fn, ...)
	if pack and not ns.Enabled(pack) then return end
	local was, wasRunning = current, running
	if pack then current = pack end
	running = pack
	xpcall(fn, RunError, ...)
	current, running = was, wasRunning
end

local function Wrap(fn, pack)
	return function(...) Run(pack, fn, ...) end
end

local hookedOnce = setmetatable({}, { __mode = "k" })   -- obj -> { ["method:pack"] = true }
local hookedGlobal = {}                                   -- "name:pack" -> true

-- test(...), when given: a cheap test of the call's arguments run first, outside the guarded call
-- (for a global the game calls for every button or tab, when only a few of them are ours). It
-- must not error: only a table lookup or the like.
function ns.HookOnce(obj, method, fn, pack, test)
	pack = pack or current
	if type(method) ~= "string" or type(fn) ~= "function" then return false end
	local id = method .. ":" .. tostring(pack)
	if obj == nil then
		if type(_G[method]) ~= "function" then return false end
		if hookedGlobal[id] then return true end
		hookedGlobal[id] = true
		local run = Wrap(fn, pack)
		if type(test) == "function" then
			hooksecurefunc(method, function(...) if test(...) then run(...) end end)
		else
			hooksecurefunc(method, run)
		end
		return true
	end
	if type(obj) ~= "table" or type(obj[method]) ~= "function" then return false end
	if obj.GetObjectType and not Unprotected(obj) then return false end
	local set = hookedOnce[obj]
	if not set then
		set = {}
		hookedOnce[obj] = set
	end
	if set[id] then return true end
	set[id] = true
	hooksecurefunc(obj, method, Wrap(fn, pack))
	return true
end

function ns.ScriptOnce(frame, script, fn, pack)
	pack = pack or current
	if type(script) ~= "string" or type(fn) ~= "function" or not Unprotected(frame) then return false end
	if not (frame.HasScript and frame:HasScript(script)) then return false end
	local id = "script:" .. script .. ":" .. tostring(pack)
	local set = hookedOnce[frame]
	if not set then
		set = {}
		hookedOnce[frame] = set
	end
	if set[id] then return true end
	set[id] = true
	frame:HookScript(script, Wrap(fn, pack))
	return true
end

-- Two lists swapped on each run, so a function that queues again lands in the next one.
local queueFns, queuePacks = {}, {}
local spare, sparePack = {}, {}
local queueSoon, heldForFight = false, false
local FlushQueue

local function AfterFight()
	heldForFight = false
	FlushQueue()
end

FlushQueue = function()
	queueSoon = false
	if next(queueFns) == nil then return end
	if InCombatLockdown() then
		-- (Kept as they are: one run once the fight is over.)
		if not heldForFight then
			heldForFight = true
			ns.OutOfCombat(AfterFight)
		end
		return
	end
	local list, packs = queueFns, queuePacks
	queueFns, queuePacks = spare, sparePack
	for id, fn in pairs(list) do
		local pack = packs[id]
		Run(pack ~= false and pack or nil, fn)
	end
	wipe(list)
	wipe(packs)
	spare, sparePack = list, packs
end

function ns.Queue(id, fn, pack)
	if id == nil or type(fn) ~= "function" then return end
	queueFns[id] = fn
	queuePacks[id] = pack or current or false
	if not queueSoon and not heldForFight then
		queueSoon = true
		C_Timer.After(0, FlushQueue)
	end
end

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

-- The frames resized this frame are reshelled together on the next (one timer, not one per frame,
-- while a window is being dragged to a new size). They are listed first: a reshell that resizes a
-- frame marks it again, for the frame after.
local resizeQueued = false
local resizing = {}      -- reused list of the frames being reshelled
local function ReshellResized()
	resizeQueued = false
	local n = 0
	for frame in pairs(dirty) do
		n = n + 1
		resizing[n] = frame
	end
	for i = 1, n do
		local frame = resizing[i]
		resizing[i] = nil
		dirty[frame] = nil
		Reshell(frame)
	end
end

local function Resized(self)
	if dirty[self] then return end
	dirty[self] = true
	if not resizeQueued then
		resizeQueued = true
		C_Timer.After(0, ReshellResized)
	end
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
	-- (A trace left by a test build of the profession window skin: gone.)
	if type(_G.DaylightAddonSkinsDB) == "table" then _G.DaylightAddonSkinsDB.profTrace = nil end
	-- A page saved before the accent choices came, with "Use DaylightUI's accent" off: its custom
	-- color is now the "Custom color" choice (the old switch is put back on as that's set).
	for addon in pairs(ns.targets) do
		if Setting(LookPath(addon, "daylightAccent")) == false and Setting(LookPath(addon, "accentMode")) ~= "custom" then
			Guard(function() DUI:Set(ADDON, LookPath(addon, "accentMode"), "custom") end)
		end
	end
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
		-- The accent is one choice now: the old "Use DaylightUI's accent" switch goes back on, so
		-- picking DaylightUI's accent again isn't read as the custom color.
		if name == "accentMode" and Setting(LookPath(key, "daylightAccent")) == false then
			Guard(function() DUI:Set(ADDON, LookPath(key, "daylightAccent"), true) end)
		end
		redoKeys[key] = true
	end
	if not redoQueued then
		redoQueued = true
		C_Timer.After(0, Redo)
	end
end)

-- ---------------------------------------------------------------------------------------------
-- This plugin's own windows (the choice window, the copy box) and texts in Daylight UI's look
-- ---------------------------------------------------------------------------------------------
-- Roles: an ink of API.Colors() (TITLE VALUE TEXT LABEL OFF GOOD WARN BAD DAMAGE MONEY,
-- DaylightUI/API.lua:1066-1074), or "pop" for the accent (API.Accent).
do
	local inks = setmetatable({}, { __mode = "k" })     -- region -> { role, alpha, how }
	local scaled = setmetatable({}, { __mode = "k" })   -- frame -> its own scale (number or function)

	local function RoleColor(role, inkSet)
		if role == "pop" then
			local ok, r, g, b = pcall(API.Accent)
			if ok and type(r) == "number" then return r, g or r, b or r end
			return 1, 1, 1
		end
		local c = type(inkSet) == "table" and (inkSet[role] or inkSet.TEXT)
		if type(c) == "table" then return c[1] or 1, c[2] or 1, c[3] or 1 end
		return 1, 1, 1
	end

	local function Paint(region, e, inkSet)
		local r, g, b = RoleColor(e.role, inkSet)
		local a = e.alpha or 1
		if e.how == "text" then region:SetTextColor(r, g, b, a)
		elseif e.how == "vertex" then region:SetVertexColor(r, g, b, a)
		else region:SetColorTexture(r, g, b, a) end
	end

	local function Track(region, e)
		inks[region] = e
		pcall(Paint, region, e, ns.Colors())
	end

	-- A font string in a role's color, now and after every look change. Again on the same one: a
	-- new role. ns.Untrack(region) before coloring it by hand.
	function ns.Ink(fs, role, alpha)
		if type(fs) ~= "table" or type(fs.SetTextColor) ~= "function" then return end
		Track(fs, { role = role or "TEXT", alpha = alpha, how = "text" })
	end
	-- A texture the same way (SetColorTexture; vertex: SetVertexColor, for one with its own art).
	function ns.Tint(tex, role, alpha, vertex)
		if type(tex) ~= "table" or type(tex.SetVertexColor) ~= "function" then return end
		Track(tex, { role = role or "TEXT", alpha = alpha, how = vertex and "vertex" or "color" })
	end
	function ns.Untrack(region) if region then inks[region] = nil end end

	-- Hover tips in Daylight UI's tooltip roles (DaylightUI/Tips.lua:1-15): the title in TITLE, the
	-- text in TEXT, a click hint in the accent. fn(t) for longer ones: t.Line(text, role, wrap).
	function ns.TipLines(owner, fn, anchor)
		local tip = GameTooltip
		if not tip or type(owner) ~= "table" or type(fn) ~= "function" then return end
		tip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
		local inkSet = ns.Colors()
		local t = {}
		function t.Line(text, role, wrap)
			local r, g, b = RoleColor(role or "TEXT", inkSet)
			tip:AddLine(tostring(text or ""), r, g, b, wrap and true or false)
		end
		Guard(fn, t)
		tip:Show()
	end
	function ns.Tip(owner, title, text, hint, anchor)
		ns.TipLines(owner, function(t)
			if title then t.Line(title, "TITLE") end
			if text then t.Line(text, "TEXT", true) end
			if hint then t.Line(hint, "pop", true) end
		end, anchor)
	end

	-- Daylight UI's global scale (general.scale, "every DaylightUI frame and window",
	-- DaylightUI/DB.lua:43) times a window's own. Only for windows that float free: one docked to a
	-- Daylight UI or game frame has that frame's scale already.
	local function GlobalScale()
		local ok, v = pcall(API.GetSetting, "general", "scale")
		return ok and type(v) == "number" and v > 0 and v or 1
	end
	function ns.Scale(own) return (tonumber(own) or 1) * GlobalScale() end
	local function ApplyScale(frame, own)
		if type(own) == "function" then
			local ok, v = pcall(own)
			own = ok and v or 1
		end
		if InCombatLockdown() and frame:IsProtected() then return end
		local s = ns.Scale(own)
		if math.abs((frame:GetScale() or 1) - s) > 0.001 then frame:SetScale(s) end
	end
	-- A free-floating window at its own scale times Daylight UI's, now and whenever either changes.
	function ns.Scaled(frame, own)
		if type(frame) ~= "table" or type(frame.SetScale) ~= "function" then return end
		scaled[frame] = own or 1
		pcall(ApplyScale, frame, scaled[frame])
	end

	local function Restyle()
		local ok, inkSet = pcall(API.Colors)
		if ok and type(inkSet) == "table" then
			for region, e in pairs(inks) do pcall(Paint, region, e, inkSet) end
		end
		for frame, own in pairs(scaled) do pcall(ApplyScale, frame, own) end
	end
	me.On("StyleChanged", Restyle)
	me.On("Login", Restyle)
	me.On("SettingChanged", function(scope, path)
		if scope == "general" and path == "scale" then
			for frame, own in pairs(scaled) do pcall(ApplyScale, frame, own) end
		end
	end)

	-- Escape, the open and close sounds, the appear fade and the controller (B closes) in one:
	-- Daylight UI's own window wiring, DaylightUI.Motion.Window (DaylightUI/Motion.lua:203-238;
	-- Escape through a stand-in in UISpecialFrames, DUI.Pad.Follow at :225). It's not in API.md:
	-- only from Daylight UI 2.2.5, where it was read, only after a type check, and pcall'd.
	local newEnough
	local function NewEnough()
		if newEnough ~= nil then return newEnough end
		local get = A and A.GetAddOnMetadata
		local ok, v = false, nil
		if type(get) == "function" then ok, v = pcall(get, "DaylightUI", "Version") end
		local have = {}
		if ok and type(v) == "string" then for n in v:gmatch("%d+") do have[#have + 1] = tonumber(n) end end
		-- (No numbers: a copy from source, which counts as the newest.)
		newEnough = true
		local want = { 2, 2, 5 }
		if #have > 0 then
			for i = 1, #want do
				local h = have[i] or 0
				if h ~= want[i] then
					newEnough = h > want[i]
					break
				end
			end
		end
		return newEnough
	end
	local function Inside(name, ...)
		if not NewEnough() then return nil end
		local t = rawget(DUI, name)
		if type(t) ~= "table" then return nil end
		for i = 1, select("#", ...) do
			if type(t[select(i, ...)]) ~= "function" then return nil end
		end
		return t
	end

	-- Once per window. escName: the window's own name for UISpecialFrames, used only when
	-- Motion.Window can't wire it. DUI.Pad.Follow is not safe to call twice on a frame
	-- (DaylightUI/Pad.lua:1093-1104 hooks OnShow / OnHide each time): followed frames are marked.
	function ns.Window(frame, escName, rise)
		if type(frame) ~= "table" or frame.__gloweyWin then return end
		local M = not frame.__gloweyFollowed and Inside("Motion", "Window", "Vanish", "Shown")
		if M and pcall(M.Window, frame, rise or 6, false) then
			frame.__gloweyWin = "motion"
			frame.__gloweyFollowed = true
			return
		end
		frame.__gloweyWin = "own"
		if escName and type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, escName) end
		-- (A Motion.Window that broke part way may have followed it already: __duiWired.)
		local P = not frame.__gloweyFollowed and not frame.__duiWired and Inside("Pad", "Follow")
		if P and pcall(P.Follow, frame, function() frame:Hide() end) then frame.__gloweyFollowed = true end
	end
	-- Closes it: faded out with Daylight UI's close sound when wired so, else hidden.
	function ns.CloseWindow(frame)
		if type(frame) ~= "table" then return end
		local M = frame.__gloweyWin == "motion" and Inside("Motion", "Vanish")
		if M and pcall(M.Vanish, frame) then return end
		frame:Hide()
	end
	-- Shown and not on its way out (a toggle's test).
	function ns.WindowShown(frame)
		if type(frame) ~= "table" or not frame:IsShown() then return false end
		local M = frame.__gloweyWin == "motion" and Inside("Motion", "Shown")
		if M then
			local ok, v = pcall(M.Shown, frame)
			if ok then return v and true or false end
		end
		return true
	end
end

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
		local face = ns.PlayerFace()
		if face then fs:SetFont(FaceFor(fs, path, face), size, flags or "") end
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

-- The world map's round corner buttons DaylightUI's own map skin doesn't dress (the map pin button,
-- the quest "!" and the like) wear the game's gold tracking ring: off, the icon alone. Found by the
-- ring's file, on the map's overlay buttons and the buttons along its edge. Shared by the packs
-- whose addons put buttons in that corner (OpenMap, RareScanner), so the corner looks the same
-- with either loaded; with both, each button is still looked over once.
-- (Each button looked over once, ring or not: the map refreshes its overlays on every zoom and map
-- change, and the buttons never take a ring later.)
local ringed = setmetatable({}, { __mode = "k" })
local RING_IDS
local function IsRing(tex)
	if not RING_IDS then RING_IDS = ns.FileIDs({ ["Interface\\Minimap\\MiniMap-TrackingBorder"] = true }) end
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return false end
	if type(file) == "string" then file = string.lower(file) end
	return RING_IDS[file] == true
end

-- The dark round ground behind such a button's icon is placed for the ring (a fixed spot from the
-- button's corner, each button's a little different), so with the ring gone it sits off to one
-- side of the icon. It's centered on the icon instead (and moves with it as it's pressed).
local GROUND_IDS
local function IsGround(tex)
	if not GROUND_IDS then GROUND_IDS = ns.FileIDs({ ["Interface\\Minimap\\UI-Minimap-Background"] = true }) end
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return false end
	if type(file) == "string" then file = string.lower(file) end
	return GROUND_IDS[file] == true
end

-- The first ground among a button's regions, gone through as the game hands them back.
local function GroundAmong(icon, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if r:GetObjectType() == "Texture" and r ~= icon and IsGround(r) then return r end
	end
end

local grounded = setmetatable({}, { __mode = "k" })
function ns.MapIconGround(btn)
	if not Usable(btn) or grounded[btn] or not btn.GetRegions then return end
	local icon = btn.Icon or btn.icon
	if not (Usable(icon) and icon.GetObjectType and icon:GetObjectType() == "Texture") then return end
	local ground = btn.Background
	if not (Usable(ground) and ground.GetObjectType and ground:GetObjectType() == "Texture" and IsGround(ground)) then
		ground = GroundAmong(icon, btn:GetRegions())
	end
	if not ground then return end
	grounded[btn] = true
	ground:ClearAllPoints()
	ground:SetPoint("CENTER", icon, "CENTER", 0, 0)
end

local function RingOff(btn, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if r:GetObjectType() == "Texture" and (r == btn.Border or IsRing(r)) then
			ringed[btn] = true
			r:SetAlpha(0)
		end
	end
end

local function Ring(btn)
	-- (Asked first: a button already looked over is most of them, on every map change.)
	if ringed[btn] ~= nil or not Usable(btn) or not btn.GetRegions then return end
	ringed[btn] = false
	RingOff(btn, btn:GetRegions())
	if ringed[btn] then ns.MapIconGround(btn) end
end

local function RingChildren(filter, ...)
	for i = 1, select("#", ...) do
		local c = select(i, ...)
		if c ~= filter and ringed[c] == nil and Usable(c) and c:GetObjectType() == "Button" then Ring(c) end
	end
end

function ns.MapRings()
	local map = _G.WorldMapFrame
	if not Usable(map) then return end
	local filter = map.WorldMapTrackingOptionsButton
	local overlays = map.overlayFrames
	if type(overlays) == "table" then
		for i = 1, #overlays do
			local o = overlays[i]
			if o ~= filter then Ring(o) end
		end
	end
	RingChildren(filter, map:GetChildren())
	local sc = map.ScrollContainer
	if Usable(sc) then RingChildren(filter, sc:GetChildren()) end
end

-- The passes over the map's corner, for every pack that asks: hooked once (on the map's showing and
-- each refresh of its corner buttons), and run while any of the packs that asked is on. With both
-- OpenMap and RareScanner loaded, the corner is looked over once each time, not once for each.
local ringKeys = {}      -- the packs that asked
local ringsFollowed = false

local function RingsWanted()
	for key in pairs(ringKeys) do
		if ns.Enabled(key) then return true end
	end
	return false
end

local function RingsNow()
	if RingsWanted() then Guard(ns.MapRings) end
end

function ns.FollowMapRings(key)
	ringKeys[key] = true
	if ringsFollowed then return end
	local map = _G.WorldMapFrame
	if not Usable(map) or not map.HookScript then return end
	ringsFollowed = true
	map:HookScript("OnShow", RingsNow)
	if type(map.RefreshOverlayFrames) == "function" then hooksecurefunc(map, "RefreshOverlayFrames", RingsNow) end
end

local function IsPanelButton(b)
	return b.Left and b.Middle and b.Right and true or false
end

-- What a button's art is (its atlas lower-cased, else the file it reports: a number on this
-- client, or a lower-cased path), for telling the game's standard pieces from an addon's own.
-- (Files and atlases checked against the Forever source, wow-ui-source branch "forever".)
local Art = {}
function Art.Of(tex)
	if not Usable(tex) or tex:GetObjectType() ~= "Texture" then return nil end
	local ok, atlas = pcall(tex.GetAtlas, tex)
	if ok and type(atlas) == "string" and atlas ~= "" then return string.lower(atlas), true end
	local ok2, file = pcall(tex.GetTexture, tex)
	if not ok2 or file == nil or (issecretvalue and issecretvalue(file)) then return nil end
	if type(file) == "string" then file = string.lower(file) end
	return file, false
end
function Art.Normal(btn)
	if not btn.GetNormalTexture then return nil end
	local ok, tex = pcall(btn.GetNormalTexture, btn)
	if ok then return Art.Of(tex) end
end
function Art.Ids(kind)
	local ids = Art[kind]
	if ids then return ids end
	local paths = Art.PATHS[kind]
	ids = ns.FileIDs(paths)
	Art[kind] = ids
	return ids
end
Art.PATHS = {
	-- UIRadioButtonTemplate (and SendMailRadioButtonTemplate, which inherits it).
	radio = { ["Interface\\Buttons\\UI-RadioButton"] = true },
	-- UICheckButtonArtTemplate (UICheckButtonTemplate, ChatConfig, Options check buttons).
	check = { ["Interface\\Buttons\\UI-CheckBox-Up"] = true },
	-- PanelResizeButtonTemplate and the chat windows' size grabber.
	grip = { ["Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"] = true },
	-- The old close X (UIPanelCloseButton before the red one; addons still set it by hand).
	close = { ["Interface\\Buttons\\UI-Panel-MinimizeButton-Up"] = true },
}

-- A round radio button: UIRadioButtonTemplate's file, UIRadialButtonTemplate's
-- common-dropdown-tickradial, the common-radiobutton-circle atlas, or "Radio" in its name.
-- DaylightUI has no radio look (its own skins keep the game's dots), and its switch reads as an
-- on/off of its own rather than one choice of a set, so radios keep the game's art.
-- (Worked out once per check button: its art is set when it's made. A button with no art yet
-- isn't remembered.)
local checkKind = setmetatable({}, { __mode = "k" })   -- check button -> "radio" / "game" / "own"
local function CheckKind(cb)
	local k = checkKind[cb]
	if k then return k end
	if not Usable(cb) or cb:GetObjectType() ~= "CheckButton" then return "own" end
	local art, atlas = Art.Normal(cb)
	local name = cb.GetName and cb:GetName()
	-- (Atlas names "radio" or "tickradial" only: "radi" alone is in "gradient" too.)
	if (atlas and (string.find(art, "radio", 1, true) or string.find(art, "tickradial", 1, true)))
		or (not atlas and art ~= nil and Art.Ids("radio")[art])
		or (type(name) == "string" and string.find(string.lower(name), "radio", 1, true)) then
		k = "radio"
	elseif (atlas and string.find(art, "checkbox", 1, true)) or (not atlas and art ~= nil and Art.Ids("check")[art]) then
		k = "game"
	else
		k = "own"
	end
	if art ~= nil then checkKind[cb] = k end
	return k
end
function ns.IsRadio(cb) return CheckKind(cb) == "radio" end

-- A check button in the game's own checkbox art (UICheckButtonArtTemplate's UI-CheckBox-Up, or a
-- checkbox atlas: MinimalCheckboxArtTemplate's checkbox-minimal), not a radio. An addon's own
-- (toggle tabs, its own boxes and dots) answers false.
function ns.GameCheck(cb) return CheckKind(cb) == "game" end

-- The game's size grabber (PanelResizeButtonTemplate, UI-ChatIM-SizeGrabber) in DaylightUI's
-- grip look (its Win.Grip: ui-grip.png in the label ink, the accent on hover). The game's
-- clicks and scripts stay; only its three textures are redrawn.
-- (Worked out once per button, as check buttons are above.)
local buttonKind = setmetatable({}, { __mode = "k" })   -- button -> "close" / "grip" / "other"
local function ButtonKind(btn)
	local k = buttonKind[btn]
	if k then return k end
	if not Usable(btn) or btn:GetObjectType() ~= "Button" then return "other" end
	local art, atlas = Art.Normal(btn)
	if atlas then
		k = art == "redbutton-exit" and "close" or "other"
	elseif art ~= nil and Art.Ids("close")[art] then
		k = "close"
	elseif art ~= nil and Art.Ids("grip")[art] then
		k = "grip"
	else
		k = "other"
	end
	if art ~= nil then buttonKind[btn] = k end
	return k
end
function ns.IsGrip(btn) return ButtonKind(btn) == "grip" end
local gripped = setmetatable({}, { __mode = "k" })
local GRIP_FILE = "Interface\\AddOns\\DaylightUI\\Media\\ui-grip.png"
function ns.Grip(btn)
	if not ns.IsGrip(btn) or gripped[btn] then return end
	gripped[btn] = true
	local label = ns.Colors().LABEL
	for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture" }) do
		local tex = btn[get] and btn[get](btn)
		if Usable(tex) then
			tex:SetTexture(GRIP_FILE)
			tex:SetTexCoord(0, 1, 0, 1)
			if type(label) == "table" then tex:SetVertexColor(label[1], label[2], label[3], 0.6) end
		end
	end
	local lit = btn.GetHighlightTexture and btn:GetHighlightTexture()
	if Usable(lit) then
		lit:SetTexture(GRIP_FILE)
		lit:SetTexCoord(0, 1, 0, 1)
		lit:SetBlendMode("BLEND")
		ns.PaintAccent(lit, 1)
	end
end

-- A close X in the game's art (UIPanelCloseButton's RedButton-Exit atlas, or the old
-- UI-Panel-MinimizeButton-Up file), whatever its name or place.
function ns.IsGameClose(btn) return ButtonKind(btn) == "close" end

-- A modern scroll bar (MinimalScrollBar, WowTrimScrollBar, WowClassicScrollBar: an EventFrame
-- with a Track and Back / Forward steppers) or an old one made bare (UIPanelScrollBarTemplate
-- as a Slider of its own, not under a ScrollFrame: its ScrollUpButton / ScrollDownButton).
function ns.IsScrollBar(bar)
	if not Usable(bar) then return false end
	if type(rawget(bar, "Track")) == "table" and (type(rawget(bar, "Back")) == "table" or type(rawget(bar, "Forward")) == "table") then
		return true
	end
	return type(rawget(bar, "ScrollUpButton")) == "table" or type(rawget(bar, "ScrollDownButton")) == "table"
end

-- The walk behind ns.Dress. The look is read once at the top and handed down, and children and
-- regions are gone through as they come (no table made of them): it runs on every show.
local Walk

-- The face and size each string was last left at by the walk: a string the addon has put its own
-- font back on since (a refresh, a pooled row, SetFontObject on a state change) is done again;
-- one that's still as it was left isn't touched (so a size scale is never applied twice).
local leftFace = setmetatable({}, { __mode = "k" })
local leftSize = setmetatable({}, { __mode = "k" })

-- The player's font for `key` on a string, unless it's still as this left it.
function ns.FollowFont(fs, key)
	if not Usable(fs) or not fs.GetFont then return end
	local ok, path, size = pcall(fs.GetFont, fs)
	if not ok or not size or size <= 0 then return end
	if leftFace[fs] == path and leftSize[fs] == size then
		-- (Its text may have turned to an alphabet our face lacks, or back.)
		if ourFace[fs] then
			Recheck(fs)
			local ok3, nowPath, nowSize = pcall(fs.GetFont, fs)
			if ok3 then leftFace[fs], leftSize[fs] = nowPath, nowSize end
		end
		return
	end
	ns.Refont(fs, key)
	local ok2, nowPath, nowSize = pcall(fs.GetFont, fs)
	if ok2 then leftFace[fs], leftSize[fs] = nowPath, nowSize end
end

-- Every string (and text box) in a window at any depth, through ns.FollowFont: check buttons'
-- labels and edit boxes included, which the dressing walk below doesn't open up. For windows an
-- addon fills with game font templates its own font code never reaches. A string already in key's
-- face is passed over: a pack's own font hook put it there, with any size scale already applied.
-- Regions and children are gone through as the game hands them back (no table made): it runs on
-- every show.
local FONT_SKIP = { GameTooltip = true, Model = true, PlayerModel = true, DressUpModel = true,
	ModelScene = true, Cooldown = true, SimpleHTML = true, MessageFrame = true, Minimap = true }
local FontsIn

local function FontOn(fs, key, face)
	if face then
		local ok, path = pcall(fs.GetFont, fs)
		if ok and path == face then
			if ourFace[fs] then Recheck(fs) end
			return
		end
	end
	ns.FollowFont(fs, key)
end

local function FontsAmong(key, face, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if Usable(r) and r:GetObjectType() == "FontString" then FontOn(r, key, face) end
	end
end

local function FontsBelow(key, face, depth, ...)
	for i = 1, select("#", ...) do FontsIn((select(i, ...)), key, face, depth) end
end

FontsIn = function(f, key, face, depth)
	if depth > 10 or not Usable(f) then return end
	local kind = f:GetObjectType()
	if FONT_SKIP[kind] then return end
	if f.GetRegions then FontsAmong(key, face, f:GetRegions()) end
	if kind == "EditBox" then FontOn(f, key, face) end
	if f.GetChildren then FontsBelow(key, face, depth + 1, f:GetChildren()) end
end

-- key's text look on every string under root (left alone when key's text is the addon's own).
function ns.FontsIn(root, key)
	key = key or current
	if not key then return end
	local t = Text(key)
	if t.plain then return end
	FontsIn(root, key, t.face, 0)
end

local function WalkRegions(key, ...)
	for i = 1, select("#", ...) do
		local region = select(i, ...)
		if Usable(region) and region:GetObjectType() == "FontString" then ns.FollowFont(region, key) end
	end
end

-- A protected frame the walk stays out of. opts.implicit: a frame protected only by holding a
-- secure child (IsProtected's second return false) is walked out of combat; its secure children
-- themselves stay out.
local function Shut(child, opts)
	if not child.IsProtected then return false end
	local p, explicit = child:IsProtected()
	if not p then return false end
	return explicit or not opts.implicit or InCombatLockdown()
end

local function WalkChildren(Kit, opts, depth, key, controls, fonts, ...)
	local skip, soften = opts.skip, opts.soften
	for i = 1, select("#", ...) do
		local child = select(i, ...)
		if Usable(child) and not (skip and skip[child]) and not Shut(child, opts) then
			local kind = child:GetObjectType()
			local walk = true
			if kind == "Button" then
				if IsPanelButton(child) then
					if controls and Once(child) then Guard(Kit.Button, child) end
					walk = false
				elseif opts.closes and controls and ns.IsGameClose(child) then
					if Once(child) then Guard(Kit.Close, child) end
					walk = false
				elseif opts.grips and controls and ns.IsGrip(child) then
					Guard(ns.Grip, child)
					walk = false
				elseif soften and not done[child] and child.GetBackdrop and child:GetBackdrop() then
					done[child] = true
					ns.Soften(child, 0.35)
				end
			elseif kind == "CheckButton" then
				-- Radios keep the game's dots (ns.IsRadio); with gameChecks, only check buttons in the
				-- game's checkbox art become switches (an addon's own toggles and dots stay its own).
				if ns.IsRadio(child) or (opts.gameChecks and not ns.GameCheck(child)) then
					if fonts then WalkRegions(key, child:GetRegions()) end
				elseif controls and opts.checks ~= false and Once(child) then
					Guard(Kit.Check, child)
				end
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
				-- (opts.sliders: a bare scroll bar in DaylightUI's scroll look, any other slider through
				-- ns.Slider. A ScrollFrame's own bar was done above and Kit.ScrollBar does each bar once.)
				if opts.sliders and controls then
					if ns.IsScrollBar(child) then
						if opts.scrollBars ~= false and not done[child] then
							done[child] = true
							Guard(Kit.ScrollBar, child)
						end
					elseif ns.Slider then
						Guard(ns.Slider, child)
					end
				end
				walk = false
			elseif kind == "EventFrame" then
				-- (opts.modernBars: MinimalScrollBar / WowTrimScrollBar, which an addon may put beside
				-- a ScrollBox or a scrolling edit box.)
				if opts.modernBars and controls and opts.scrollBars ~= false and not done[child] and ns.IsScrollBar(child) then
					done[child] = true
					Guard(Kit.ScrollBar, child)
				end
				walk = false
			elseif kind == "Frame" then
				if soften and not done[child] and child.GetBackdrop and child:GetBackdrop() then
					done[child] = true
					ns.Soften(child)
				end
				-- (opts.oldDropdowns: UIDropDownMenuTemplate and its copies, Left / Middle / Right art,
				-- Text and an arrow Button: ns.OldDropdown, which passes over any other frame at once.)
				if opts.oldDropdowns and controls and ns.OldDropdown then Guard(ns.OldDropdown, child) end
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
-- Radio buttons (ns.IsRadio) keep the game's dots for every pack: DaylightUI has no radio look.
-- opts: skip (a set of frames left alone, their children too), checks = false, scrollBars = false
-- (the addon draws its own and they are left as they are), soften = true
-- (flat backdrop boxes become quiet wells), fonts = true (the player's font on every string).
-- More controls, asked for by the Auto Skinner (any pack may): sliders = true (bare scroll bars
-- and sliders), modernBars = true (MinimalScrollBar / WowTrimScrollBar), oldDropdowns = true,
-- closes = true (a close X in the game's art anywhere), grips = true (the game's size grabber),
-- gameChecks = true (only check buttons in the game's checkbox art become switches).
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
-- Icon tabs as clean tiles (the game's "side tab" look other addons borrow: TrueshotLodge's tabs,
-- Questie's settings tabs, OpenMap's tabs on the map's edge). Each becomes a square of DaylightUI's
-- tab look with the icon cropped and centered in an even margin; the picked one's edge is the
-- accent (flat), the others neutral with their icon a little dimmed until the mouse is on them.
-- ns.SideTile(tab, opts): opts.picked(tab) says whether it's picked (required); opts.icon = its
-- icon texture (default tab.Icon or tab.icon); opts.mouse = the frame that takes the mouse
-- (default tab); opts.key = the addon whose accent it follows; opts.quiet: no script of ours on the
-- tab's showing (a window the game shows from secure code): only the mouse is hooked, and the
-- caller repaints from its own post-hooks (ns.SideTilesPaintSoon). Two ways of placing it:
--   opts.copy: the icon is drawn again on a tile of ours (size opts.size, at opts.point of the tab,
--     default its LEFT; a small symbol keeps its size with opts.iconSize) and the original hidden,
--     for a template that moves, mirrors or masks its icon;
--   otherwise the tile sits round the icon where it is (opts.pad, default 4), the icon kept.
-- Call ns.SideTilePaint(tab) whenever the addon may have changed which one is picked.
-- ---------------------------------------------------------------------------------------------

local tiles = setmetatable({}, { __mode = "k" })   -- tab -> its tile
local TILE_PAD, TILE_DIM = 4, 0.72

function ns.SideTilePaint(tab)
	local t = tiles[tab]
	local Kit = ns.Kit
	if not t or not Kit or not ns.Enabled(t.key) then return end
	local on = t.picked(tab) == true
	local hover = Usable(t.mouse) and t.mouse:IsMouseOver() == true
	local border
	if on then
		border = t.accent
		border[1], border[2], border[3] = ns.AccentOf(t.key)
	elseif hover then
		border = Kit.ROW_HOVER or Kit.TAB_BORDER
	else
		border = Kit.TAB_BORDER
	end
	if t.shell then
		if on then ns.LightShell(t.shell, border, t.key) else Kit.Paint(t.shell, border) end
	end
	t.icon:SetAlpha((on or hover) and 1 or TILE_DIM)
end

local function PaintAllTiles()
	for tab in pairs(tiles) do Guard(ns.SideTilePaint, tab) end
end
local tilesQueued = false
local function PaintTilesSoon()
	if tilesQueued then return end
	tilesQueued = true
	C_Timer.After(0, function() tilesQueued = false PaintAllTiles() end)
end
ns.SideTilesPaintSoon = PaintTilesSoon

function ns.SideTile(tab, opts)
	local Kit = ns.Kit
	if not Kit or not Usable(tab) or tiles[tab] or type(opts) ~= "table" or type(opts.picked) ~= "function" then return end
	local source = opts.icon or tab.Icon or tab.icon
	if not (Usable(source) and source.GetObjectType and source:GetObjectType() == "Texture") then return end
	local key = opts.key or current
	local mouse = Usable(opts.mouse) and opts.mouse or tab
	local tile = CreateFrame("Frame", nil, tab)
	tile:EnableMouse(false)
	local icon
	if opts.copy then
		local size = opts.size or math.floor((tab:GetHeight() or 40) - 4 + 0.5)
		tile:SetSize(size, size)
		local point = opts.point or "LEFT"
		tile:SetPoint(point, tab, point, 0, 0)
		icon = tile:CreateTexture(nil, "ARTWORK")
		-- A picture fills the tile's inside (cropped of its own frame); a small symbol (opts.iconSize)
		-- keeps its size, centered.
		local small = opts.iconSize
		if small then
			icon:SetSize(small, small)
			icon:SetPoint("CENTER", tile, "CENTER", 0, 0)
		else
			icon:SetPoint("TOPLEFT", tile, "TOPLEFT", TILE_PAD, -TILE_PAD)
			icon:SetPoint("BOTTOMRIGHT", tile, "BOTTOMRIGHT", -TILE_PAD, TILE_PAD)
		end
		local function crop() if not small then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end end
		local ok, atlas = pcall(source.GetAtlas, source)
		if ok and type(atlas) == "string" and atlas ~= "" then icon:SetAtlas(atlas) else icon:SetTexture(source:GetTexture()) crop() end
		hooksecurefunc(source, "SetTexture", function(_, file) icon:SetTexture(file) crop() end)
		hooksecurefunc(source, "SetAtlas", function(_, a) icon:SetAtlas(a) end)
		Kit.Erase(source)
	else
		-- Behind the tab's own parts, round the icon.
		local pad = opts.pad or TILE_PAD
		tile:SetFrameLevel(math.max(0, tab:GetFrameLevel() - 1))
		tile:SetPoint("TOPLEFT", source, "TOPLEFT", -pad, pad)
		tile:SetPoint("BOTTOMRIGHT", source, "BOTTOMRIGHT", pad, -pad)
		if source.GetNumMaskTextures and source.RemoveMaskTexture then
			for i = source:GetNumMaskTextures(), 1, -1 do pcall(source.RemoveMaskTexture, source, source:GetMaskTexture(i)) end
		end
		source:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		icon = source
	end
	local t = { key = key, picked = opts.picked, mouse = mouse, icon = icon, accent = { 1, 1, 1 }, tile = tile }
	t.shell = Kit.Shell(tile, "tab")
	tiles[tab] = t
	local function paint() ns.SideTilePaint(tab) end
	mouse:HookScript("OnEnter", paint)
	mouse:HookScript("OnLeave", paint)
	-- A click anywhere may pick another tab: all of them, next frame.
	mouse:HookScript("OnMouseUp", PaintTilesSoon)
	if not opts.quiet then tab:HookScript("OnShow", PaintTilesSoon) end
	ns.SideTilePaint(tab)
	return t
end

me.On("StyleChanged", PaintTilesSoon)
me.On("SettingChanged", function(scope) if scope == ADDON then PaintTilesSoon() end end)

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
-- An entry marked `gone` is one DaylightUI no longer does: never asked about or listed, only kept so
-- a setting handed over before is given back (its `ours` says false).
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
	-- (The switch alone: a pack off after an error keeps the player's handover choices.)
	local enabled = SwitchedOn(addon)
	for _, item in ipairs(h.list) do
		local want = false
		if enabled then
			if item.switch then
				want = Setting(LookPath(addon, item.switch)) == true and Ours(item)
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
	local pending = false
	local sv = SV()
	-- One repair pass: settings given to DaylightUI before the fix were cleared instead of switched
	-- off (so the addon read its default, on). Each addon's own pass, once its settings are there.
	if type(sv.repaired) ~= "table" then sv.repaired = {} end
	for addon, h in pairs(handovers) do
		local repair = not sv.repaired[addon]
		local ok, finished = xpcall(ApplyHandover, geterrorhandler(), addon, h, repair)
		if ok and finished == false then
			pending = true
		elseif ok and repair then
			sv.repaired[addon] = true
		end
	end
	return pending
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

-- Whether the DaylightUI in use is this version or later (DaylightUI's toc version).
function ns.DaylightAtLeast(a, b, c)
	local get = C_AddOns and C_AddOns.GetAddOnMetadata
	local ok, version = pcall(get, "DaylightUI", "Version")
	if not ok or type(version) ~= "string" then return false end
	local x, y, z = version:match("^v?(%d+)%.(%d+)%.?(%d*)")
	x, y, z = tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0
	if x ~= a then return x > a end
	if y ~= b then return y > b end
	return z >= (c or 0)
end

-- Whether DaylightUI's own Auction House window (2.0) stands in for the game's AuctionHouseFrame
-- now: the game's frame is parked out of sight under it (alpha 0, clipped off screen), or will
-- be when the Auction House opens. False once the player picks the game's window (the swap icon
-- on DaylightUI's window header, or Auction House > Enabled off), while a fight keeps the game's
-- window, with DaylightMogul (which owns the Auction House), and on 1.9.x. The signal is
-- DaylightUI.ahCovers (2.0 DaylightUI_AuctionHouse\Window.lua:403-407, set at :417), the one
-- DaylightUI's own Window Skins stand down on (2.0 DaylightUI_Skins\Packs\System.lua:656-661).
-- It is not in API.md, so it is feature-detected and called guarded; absent in 1.9.6.
function ns.DaylightCoversAH()
	local covers = DUI.ahCovers
	if type(covers) ~= "function" then return false end
	local ok, yes = pcall(covers)
	return ok and yes == true
end

-- The color behind DaylightUI's windows and panels: its own dark, from 1.8.4 the player's pick
-- (General > Appearance > Background color: Daylight, a class tint or a custom color). Read
-- when painting; a fresh table each time.
local FALLBACK_BACK = { 0.078, 0.078, 0.090 }
function ns.BackColor()
	local Style = DUI and DUI.Style
	local c
	if type(Style) == "table" then
		if type(Style.BackColor) == "function" then
			local ok, v = pcall(Style.BackColor)
			if ok and type(v) == "table" then c = v end
		end
		if not c and type(Style.BACKGROUND) == "table" then c = Style.BACKGROUND end
	end
	c = c or FALLBACK_BACK
	return { c[1], c[2], c[3] }
end

-- A texture of ours (or one of an addon's taken over) as a window's ground, in that color at
-- `alpha`, painted again whenever the look changes.
local backs = setmetatable({}, { __mode = "k" })   -- texture -> alpha
function ns.PaintBack(tex, alpha)
	if type(tex) ~= "table" or type(tex.SetColorTexture) ~= "function" then return end
	backs[tex] = alpha or 1
	local c = ns.BackColor()
	tex:SetColorTexture(c[1], c[2], c[3], backs[tex])
end
me.On("StyleChanged", function()
	local c = ns.BackColor()
	for tex, a in pairs(backs) do tex:SetColorTexture(c[1], c[2], c[3], a) end
end)

-- DaylightUI 1.8.4 and later dress the game's own windows in its look whenever the player picks
-- them over DaylightUI's (or DaylightUI lends one out), through its Window Skins: the "npc" pack
-- (gossip, quests, the vendor, the trainer), "social" (the mailbox, a letter, the social window)
-- and "system" (the character window, the spellbook and talents). While that pack is on, those
-- windows are DaylightUI's to dress, and the Game windows skin here leaves them alone.
function ns.DaylightDressesGame(pack)
	if not ns.DaylightAtLeast(1, 8, 4) or not ns.ModuleOn("Skins") then return false end
	return ns.DaylightHas("Skins", "packs." .. pack)
end

-- The conflicts to show: `all` = every one that is live or was given to DaylightUI; otherwise only
-- the live ones not answered yet. Each: { addon, item, daylight = the current pick }.
function ns.Conflicts(all)
	local out = {}
	for _, addon in ipairs(ns.order) do
		local h = handovers[addon]
		if h and SwitchedOn(addon) and (type(h.ready) ~= "function" or h.ready()) then
			local asked, rec = Asked(addon), Handed(addon)
			for _, item in ipairs(h.list) do
				if not item.switch and not item.gone then
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
	local L = ns.L
	local label = ns.targets[addon] or addon
	local items = {}
	for _, item in ipairs(h and h.list or {}) do
		if not item.switch and not item.gone then
			items[#items + 1] = { type = "toggle", key = UsePath(addon, item.key),
				label = item.label or item.key,
				-- Shown flipped, as in the choice window: on = the addon's own, off = Daylight UI's
				-- (the stored setting stays true = Daylight UI).
				invert = true,
				desc = item.daylight
					and string.format(L["On: %s's own, as it was. Off: Daylight UI does this (%s) and %s's own is switched off."], label, item.daylight, label)
					or string.format(L["On: %s's own, as it was. Off: Daylight UI does this and %s's own is switched off."], label, label),
				reload = item.reload or nil }
		end
	end
	items[#items + 1] = { type = "button", label = string.format(L["Give Everything Back to %s"], label),
		desc = string.format(L["Puts back every one of %s's settings this plugin switched off, as they were."], label),
		func = function() ns.GiveBack(addon) end }
	return { label = string.format(L["Daylight UI or %s"], label), items = items }
end

-- Got the Kit as early as DaylightUI will give it.
ns.Pack("DaylightUI_Skins")

-- Settings: one switch per addon, kept in the player's DaylightUI profile. `pages` (Options.lua)
-- go in this plugin's own section of the options window, under the Plugins heading.
function ns.RegisterSettings(pages)
	defaults.followDaylight = true
	-- The addon the Look and Feel page shows (picked from its tabs' "Applies to" lists).
	defaults.lookPick = ns.lookPickDefault or "Blizzard"
	-- One switch per game window (Windows.lua).
	defaults.blizz = {}
	for _, w in ipairs(ns.BLIZZ or {}) do
		if w.id then defaults.blizz[w.id] = true end
	end
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
			title = ns.L["Addon Skins"],
			icon = "Interface\\AddOns\\" .. ADDON .. "\\Media\\icon-glyph.png",
			needs = { 1, 1 },
			short = ns.L["Addons"],
			blurb = ns.L["Your other addons' windows in the Daylight UI look."],
		})
		DUI:RegisterModule(ADDON, { plugin = ADDON, label = ns.L["Addon Skins"], defaults = defaults,
			options = pages and { pages = pages } or nil })
	end)
end
