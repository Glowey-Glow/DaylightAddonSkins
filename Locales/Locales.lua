-- This plugin's own text in the player's language. The English text is the key and the fallback:
-- L["Font"] gives "Font" when the language has no line for it, so a missing line never breaks
-- anything. A line the language file doesn't have is looked up in DaylightUI's own translations
-- (the same phrase in DaylightUI's options reads the same here); nothing is stored on a miss.
--
-- Each language has a file next to this one that returns at once unless the client is in it:
--   local _, ns = ...
--   if ns.LOCALE ~= "deDE" then return end
--   local L = ns.L
--   L["Font"] = "Schrift"
-- Whole sentences with string.format holes, never sentences glued from pieces (word order
-- differs). Saved things stay English: setting keys, dropdown keys, slash words, addon names.
local _, ns = ...

-- The language of the plugin's text: Daylight UI's own pick (its Home > Language, since 2.2.5), on
-- from its ADDON_LOADED, which comes before this plugin loads (DaylightUI/Locales/Locales.lua:16-20,
-- Core.lua:984-992); its saved pick should it not be on yet; else the game's. enGB reads enUS, esMX
-- esES. The game's own words (GAME below) stay in the game's language.
local CLIENT = GetLocale and GetLocale() or "enUS"
local FOLD = { enGB = "enUS", esMX = "esES" }
local HAVE = { enUS = true, deDE = true, esES = true, frFR = true, ruRU = true, koKR = true, zhCN = true }
local LOCALE
do
	local D = rawget(_G, "DaylightUI")
	local pick = type(D) == "table" and D.LOCALE or nil
	local db = rawget(_G, "DaylightUIDB")
	local saved = type(db) == "table" and db.language
	if type(saved) == "string" and saved ~= "auto" and type(D) == "table" and pick == D.CLIENT_LOCALE then pick = saved end
	pick = type(pick) == "string" and (FOLD[pick] or pick) or nil
	LOCALE = (pick and HAVE[pick]) and pick or (FOLD[CLIENT] or CLIENT)
end
ns.LOCALE = LOCALE

-- DaylightUI's translation of `key`, or nil (its table answers a miss with the key itself; rawget
-- reads only the lines it has).
local function Daylight(key)
	local D = _G.DaylightUI
	local L = type(D) == "table" and D.L
	if type(L) ~= "table" then return nil end
	local v = rawget(L, key)
	if type(v) == "string" then return v end
	return nil
end

-- Keys whose English is word for word one of the game's global strings (same case, punctuation
-- and holes), in the same sense: on a non-English client the game's own translation comes first,
-- before this plugin's line and DaylightUI's; ours stays as the fallback when the client lacks the
-- global. English clients keep ours. Left out on purpose: same words in another sense (Guide,
-- Controls, Border, Appearance, Hostile NPCs), and Friendly NPCs, whose game word would not match
-- its Hostile and Neutral neighbors.
-- (Not on an English game, nor for text picked in another language than the game's.)
local ENGLISH = CLIENT:sub(1, 2) == "en" or LOCALE ~= (FOLD[CLIENT] or CLIENT)
local GAME = {
	["%s, %s"] = "LIST_DELIMITER",
	["Always"] = "ALWAYS",
	["Apply"] = "APPLY",
	["Minimap"] = "MINIMAP_LABEL",
	["None"] = "NONE",
	["Off"] = "OFF",
	["Style"] = "UNIT_NAMEPLATES_STYLE",
}

-- The game's text for a key in GAME, on a non-English client that has it; else nil.
local function Game(key)
	local global = not ENGLISH and GAME[key]
	local v = global and _G[global]
	if type(v) == "string" and v ~= "" then return v end
	return nil
end

-- A language file's line for a key in GAME is kept only where the game has no text for it.
local L = setmetatable({}, {
	__index = function(_, key) return Game(key) or Daylight(key) or key end,
	__newindex = function(t, key, value) rawset(t, key, Game(key) or value) end,
})
ns.L = L

-- A DaylightUI module's name as its options list shows it in this language. The text here names
-- three of them a little differently from their sidebar label (the English stays as it was).
local MODULE = { ["Window Skins"] = "Game window skins", Tooltip = "Tooltips", Quests = "Quest Tracker" }
function ns.Module(name)
	return Daylight(MODULE[name] or name) or Daylight(name) or name
end

-- "what (Module)" or "what (Module, Tab)": what DaylightUI does, and where it lives in its options.
function ns.In(what, module, tab)
	local where = ns.Module(module)
	if tab then where = string.format(L["%s, %s"], where, ns.Module(tab)) end
	return string.format(L["%s (%s)"], what, where)
end

-- The form of a word for a count: one, many and (Russian) few. Korean and Chinese have one form.
function ns.Plural(n, one, many, few)
	n = math.abs(math.floor(tonumber(n) or 0))
	if LOCALE == "koKR" or LOCALE == "zhCN" or LOCALE == "zhTW" then return many or one end
	if LOCALE == "ruRU" then
		local d, h = n % 10, n % 100
		if d == 1 and h ~= 11 then return one end
		if d >= 2 and d <= 4 and (h < 12 or h > 14) then return few or many end
		return many
	end
	if LOCALE == "frFR" then return (n <= 1) and one or many end
	return (n == 1) and one or many
end
