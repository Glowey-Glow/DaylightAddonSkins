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

local LOCALE = GetLocale and GetLocale() or "enUS"
if LOCALE == "esMX" then LOCALE = "esES" end
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

local L = setmetatable({}, { __index = function(_, key) return Daylight(key) or key end })
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
