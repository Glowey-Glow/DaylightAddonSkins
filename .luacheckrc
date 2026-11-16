-- luacheck config: run `luacheck .` from this folder.
std = "lua51"
max_line_length = false
exclude_files = { "Libs/", ".release/" }
-- Unused arguments and loop variables named _ or _name are placeholders.
ignore = { "212/_.*", "213/_.*" }

-- Globals this addon sets: its saved variables and slash commands.
globals = {
	"SLASH_DASSCAN1",
	"SlashCmdList",
}

-- The WoW client's API, frames and constants this addon reads.
read_globals = {
	"C_AddOns",
	"C_Item",
	"C_Timer",
	"CreateFont",
	"CreateFrame",
	"CreateColor",
	"EnumerateFrames",
	"ExecuteFrameScript",
	"GameFontHighlight",
	"GameFontNormal",
	"GameFontNormalLarge",
	"GameTooltip",
	"GetLocale",
	"GetTime",
	"InCombatLockdown",
	"IsInInstance",
	"IsLoggedIn",
	"IsControlKeyDown",
	"IsShiftKeyDown",
	"LibStub",
	"PanelTemplates_TabResize",
	"PixelUtil",
	"ReloadUI",
	"ScrollUtil",
	"Settings",
	"TRP3_API",
	"TRP3_Addon",
	"UIParent",
	"UISpecialFrames",
	"UnitClass",
	"WorldFrame",
	"date",
	"geterrorhandler",
	"hooksecurefunc",
	"issecretvalue",
	"wipe",
}
