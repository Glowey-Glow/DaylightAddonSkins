-- Dialogue UI: a DaylightUI theme for it, laid over whichever of its own two themes is picked.
-- Its talk window (DUIQuestFrame: gossip, quest text, rewards) and settings window
-- (DUIDialogSettings) stand on DaylightUI's shell in place of its paper and tiled ground; its text
-- takes DaylightUI's text colours, accent and font (a font picked in Dialogue UI's own settings is
-- kept); and its controls (option rows, hotkey labels, reward and item buttons, dividers, the
-- settings' checkboxes and arrows) take the art of its own Dark theme wherever its Brown theme's
-- would show, since those are drawn for dark text on paper.
-- It has no license (all rights reserved to its authors): none of its files are changed and none
-- of its art copied. Its internals are private, so it is followed from outside: its global
-- mixins and the two windows' own methods (after each theme load, page and tab), and its global
-- font objects (DUIFont_*), which get DaylightUI's font and colours each time it sets them.
-- Left as it draws them: the portrait model, each quest's background picture, its own tooltip,
-- the book window (paper or metal on purpose), the camera and its hide-the-UI mode.
-- Nothing is written to its saved settings.
--
-- With Dialogue UI on, it takes the game's gossip and quest windows before DaylightUI's own
-- NPC window can open them (DaylightUI's vendor and trainer windows are unaffected).
local _, ns = ...
if not ns.ok then return end

local KEY = "DialogueUI"

ns.Target(KEY, "Dialogue UI", { window = true, text = true, colors = true, font = "daylight",
	extraTab = "DaylightUI", extra = function() return { ns.HandoverGroup(KEY) } end })

if type(_G.DUIQuestFrame) ~= "table" then return end

local lower, find, sub = string.lower, string.find, string.sub

local function On()
	return ns.Enabled(KEY)
end

local function DB(name)
	local db = _G.DialogueUI_DB
	return type(db) == "table" and db[name] or nil
end

-- Its own font choice ("default" = its bundled one, "system" = the game's): anything else is a
-- font the player picked there, and stays.
local function OwnFont()
	local f = DB("FontText")
	return f ~= nil and f ~= "default" and f ~= "system"
end

-- ---------------------------------------------------------------------------------------------
-- Art: a texture showing a file of its Brown theme is pointed at the same file of its Dark one.
-- ---------------------------------------------------------------------------------------------

-- The game hands an addon's own image files a number of its own for the session (negative), and
-- that number is what a texture reports. So each file of its Brown theme is set once on a hidden
-- texture here, and the number it gets is matched to the same file of its Dark theme. (Its two
-- theme folders hold the same file names.)
local ART = "Interface/AddOns/DialogueUI/Art/"
local FILES = {
	"ButtonHighlight-Add.png", "ButtonHighlight-Front.png", "ButtonHighlight-Gossip.png", "ButtonLockProgress.png",
	"D-PAD-LEFT.png", "D-PAD-RIGHT.png", "DropdownMenu-Background.jpg", "DropdownMenu-Component.png",
	"FriendshipBar.png", "FriendshipDigits.tga", "GenericFrame-Tiled-Large.png", "HotkeyBackground-LB.png",
	"HotkeyBackground-RB.png", "HotkeyBackground.png", "InputBox-SingleLine.png", "ItemBorder.png",
	"ItemButtonBackground.png", "ItemOverlays.png", "LabelBackground.png", "OptionBackground-Blue.png",
	"OptionBackground-Common.png", "OptionBackground-Grey.png", "OptionBackground-Hollow.png", "Parchment.png",
	"QuestItemDisplay-UI.png", "RewardChoice-Highlight-Back.png", "RewardChoice-Highlight.png",
	"RewardChoice-ItemBorder.png", "RewardChoice-Pending.png", "RewardChoice-Sheen.png",
	"Settings-ArrowOption.png", "Settings-BackgroundShadow.png", "Settings-ButtonHighlight.png",
	"Settings-Checkbox.png", "Settings-CloseButton.png", "Settings-Divider-H.png", "Settings-Divider-V.png",
	"Settings-DropdownButton.png", "Settings-Keybinding.png", "Settings-Move.png", "Settings-PreviewBorder.png",
	"Settings-Reset.png", "Settings-SubOptionIcon.png", "Settings-TabButton-Selection.png",
	"SubHeaderBackground.png", "TooltipBackground-Temp.png", "TooltipBackground.png", "WarbandCompleted.png",
	"WarningIcon.png",
}
-- A Brown file's number (or its path, lower case) -> the Dark file's path.
local toDark
do
	local paths = {}
	for _, file in ipairs(FILES) do paths[ART .. "Theme_Brown/" .. file] = ART .. "Theme_Dark/" .. file end
	toDark = ns.FileIDs(paths)
end

local function Darken(tex)
	if not ns.Usable(tex) or tex:GetObjectType() ~= "Texture" then return end
	local ok, id = pcall(tex.GetTexture, tex)
	if not ok or id == nil then return end
	local dark = toDark[id]
	if not dark and type(id) == "string" then
		local key = lower(id):gsub("\\", "/")
		dark = toDark[key]
		if not dark then
			local s, e = find(key, "theme_brown", 1, true)
			if s then dark = sub(id, 1, s - 1) .. "Theme_Dark" .. sub(id, e + 1) end
		end
	end
	if dark then tex:SetTexture(dark) end
end

local function DarkenTree(frame, depth)
	if not ns.Usable(frame) then return end
	depth = depth or 0
	for _, region in ipairs({ frame:GetRegions() }) do Darken(region) end
	if depth >= 8 then return end
	for _, child in ipairs({ frame:GetChildren() }) do DarkenTree(child, depth + 1) end
end

-- For hooks: the frame whose method ran, whatever that method was given.
local function Tree(frame)
	DarkenTree(frame, 0)
end

-- After a method of a global mixin (pooled widgets made from now on) or of a frame.
local function After(owner, method, fn)
	if type(owner) == "table" and type(owner[method]) == "function" then
		hooksecurefunc(owner, method, function(self, ...)
			if On() then ns.Guard(fn, self, ...) end
		end)
	end
end

After(_G.DUIDialogOptionButtonMixin, "SetButtonArt", Tree)
After(_G.DUIDialogOptionButtonMixin, "LoadTheme", Tree)
After(_G.DUIDialogOptionButtonMixin, "SetParentHighlightTexture", function(_, highlight) DarkenTree(highlight, 0) end)
After(_G.DUIDialogHotkeyFrameMixin, "LoadTheme", Tree)
After(_G.DUIDialogHotkeyFrameMixin, "SetTheme", Tree)
After(_G.DUIDialogItemButtonMixin, "SetBackgroundTexture", Tree)
After(_G.DUIDialogItemButtonMixin, "LoadTheme", Tree)
After(_G.DUIDialogSmallItemButtonMixin, "SetBackgroundTexture", Tree)
After(_G.DUIDialogOptionButtonLockMixin, "LoadTheme", Tree)
After(_G.DUIDialogInputBoxMixin, "SetBackgroundTexture", Tree)

-- ---------------------------------------------------------------------------------------------
-- Colours: its font objects (it sets their colour on each theme load) and the item names it
-- colours itself.
-- ---------------------------------------------------------------------------------------------

-- Each font object's role: a DaylightUI text colour, or "accent".
local ROLE = {
	DUIFont_Quest_Title_18 = "VALUE", DUIFont_Quest_Title_16 = "VALUE", DUIFont_Quest_SubHeader = "VALUE",
	DUIFont_Quest_Paragraph = "TEXT", DUIFont_Quest_Gossip = "LABEL", DUIFont_Quest_Quest = "VALUE",
	DUIFont_Quest_Disabled = "OFF", DUIFont_Quest_MultiLanguage = "OFF", DUIFont_Settings_Disabled = "OFF",
	DUIFont_Item = "VALUE", DUIFont_ItemSelect = "accent",
	DUIFont_QuestType_Left = "VALUE", DUIFont_QuestType_Right = "LABEL",
	DUIFont_Constant_10 = "TEXT", DUIFont_Constant_8 = "TEXT",
	DUIFont_MenuButton_Normal = "VALUE", DUIFont_MenuButton_Highlight = "VALUE",
}

local function Accent() return ns.AccentOf(KEY) end

-- r, g, b for a role, or nil while its own colours are kept.
local function RoleColor(role)
	if role == "accent" then return Accent() end
	if ns.Look(KEY, "daylightColors") == false then return nil end
	local c = ns.Colors()[role]
	if type(c) == "table" then return c[1], c[2], c[3] end
end

local ownColor = {}  -- font object -> { r, g, b } as it set them
local coloring = false

local function Recolor(font)
	local role = ROLE[font:GetName() or ""]
	local o = ownColor[font]
	if not role or not o then return end
	local r, g, b
	if On() then r, g, b = RoleColor(role) end
	coloring = true
	if r then font:SetTextColor(r, g, b) else font:SetTextColor(o[1], o[2], o[3]) end
	coloring = false
end

for name in pairs(ROLE) do
	local font = _G[name]
	if type(font) == "table" and type(font.SetTextColor) == "function" then
		ownColor[font] = { font:GetTextColor() }
		hooksecurefunc(font, "SetTextColor", function(self, r, g, b)
			if coloring then return end
			ownColor[self] = { r, g, b }
			ns.Guard(Recolor, self)
		end)
	end
end

local function RecolorAll()
	for font in pairs(ownColor) do ns.Guard(Recolor, font) end
end

-- Item names: its Brown theme writes them all in dark brown. The item's quality colour, or the
-- accent on a reward still to be picked.
After(_G.DUIDialogItemButtonMixin, "UpdateNameColor", function(self, quality)
	local name = self.Name
	if not ns.Usable(name) then return end
	if self.backgroundID == 2 then
		name:SetTextColor(Accent())
		return
	end
	quality = quality or self.quality or 0
	local get = C_Item and C_Item.GetItemQualityColor or _G.GetItemQualityColor
	if type(get) ~= "function" then return end
	local r, g, b = get(quality)
	if type(r) == "number" then name:SetTextColor(r, g, b) end
end)

-- ---------------------------------------------------------------------------------------------
-- Fonts: what it set on each font object is kept, and the look laid over that, so a change of its
-- text size, or of ours, never adds up. The book's fonts are its own.
-- ---------------------------------------------------------------------------------------------

local FONTS = { "Quest_Title_18", "Quest_Title_16", "Quest_SubHeader", "Quest_Paragraph", "Quest_Gossip",
	"Quest_Quest", "Quest_Disabled", "Quest_MultiLanguage", "Settings_Disabled", "ItemCount", "Item", "ItemSelect",
	"QuestType_Right", "QuestType_Left", "Hotkey", "AlertFont", "ChatFont", "Tooltip_Large", "Tooltip_Medium",
	"Tooltip_Small", "NameplateGossip", "MenuButton_Normal", "MenuButton_Highlight", "AlertHeader",
	"Constant_10", "Constant_8" }
local ownFont = {}   -- font object -> { path, size, flags } as it set them
local fonting = false

local function Refont(font)
	local o = ownFont[font]
	if not o or not o[1] or not o[2] then return end
	fonting = true
	local ok, err = pcall(function()
		if On() and not OwnFont() and not ns.PlainText(KEY) then
			local path, size, flags = ns.FontFor(KEY, o[1], o[2], o[3])
			font:SetFont(path, size, flags or "")
		else
			font:SetFont(o[1], o[2], o[3] or "")
		end
	end)
	fonting = false
	if not ok then geterrorhandler()(err) end
end

for _, name in ipairs(FONTS) do
	local font = _G["DUIFont_" .. name]
	if type(font) == "table" and type(font.GetFont) == "function" and type(font.SetFont) == "function" then
		ownFont[font] = { font:GetFont() }
		hooksecurefunc(font, "SetFont", function(self, path, size, flags)
			if fonting then return end
			ownFont[self] = { path, size, flags }
			Refont(self)
		end)
	end
end

local function RefontAll()
	for font in pairs(ownFont) do Refont(font) end
end

-- ---------------------------------------------------------------------------------------------
-- The talk window
-- ---------------------------------------------------------------------------------------------

local BARE = { noBorder = true, noBackground = true, noBevel = true }
local shelled = setmetatable({}, { __mode = "k" })   -- frames the shell is on

-- The shell on while dressed; bare again when not.
local function Ground(frame, dressed)
	if dressed then
		shelled[frame] = true
		ns.Shell(frame, { window = true }, KEY)
	elseif shelled[frame] then
		shelled[frame] = nil
		ns.Shell(frame, BARE, KEY)
	end
end

local talk = _G.DUIQuestFrame

local function Talk()
	local dressed = On()
	local alpha = dressed and 0 or 1
	if type(talk.Parchments) == "table" then
		for _, piece in ipairs(talk.Parchments) do
			if ns.Usable(piece) then piece:SetAlpha(alpha) end
		end
	end
	local ff = talk.FrontFrame
	local header = type(ff) == "table" and ff.Header
	if type(header) == "table" and ns.Usable(header.TopLight) then header.TopLight:SetAlpha(alpha) end
	Ground(talk, dressed)
	if dressed then DarkenTree(talk, 0) end
end

After(talk, "LoadTheme", Talk)
-- Each page lays out fresh rows, text backgrounds and rewards.
for _, method in ipairs({ "HandleGossip", "HandleQuestDetail", "HandleQuestProgress", "HandleQuestComplete",
	"HandleQuestGreeting", "HandleGossipConfirm", "HandleGossipEnterCode", "UpdateRewards", "UpdateGossipQuests",
	"ShowUI" }) do
	After(talk, method, Tree)
end
local focus = talk.GamePadFocusIndicator
After(focus, "LoadTheme", Tree)
After(focus, "SetTheme", Tree)

-- Its Brown theme tints the speaker's portrait sepia: kept in its own colours.
do
	local header = type(talk.FrontFrame) == "table" and talk.FrontFrame.Header
	local portrait = type(header) == "table" and header.Portrait
	if ns.Usable(portrait) and portrait.SetVertexColor then
		local busy = false
		hooksecurefunc(portrait, "SetVertexColor", function(self)
			if busy or not On() then return end
			busy = true
			self:SetVertexColor(1, 1, 1)
			busy = false
		end)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Settings window: made on first open. Its tiled ground (BackgroundFrame.Background) under the
-- shell; its widgets come from pools as each tab is shown.
-- ---------------------------------------------------------------------------------------------

local settings = _G.DUIDialogSettings

local function Settings()
	if not ns.Usable(settings) then return end
	local back = settings.BackgroundFrame
	local dressed = On()
	if type(back) == "table" then
		if ns.Usable(back.Background) then back.Background:SetAlpha(dressed and 0 or 1) end
		Ground(back, dressed)
	end
	if not dressed then return end
	-- The picture behind it, drawn the way its Dark theme draws it.
	local decor = settings.BackgroundDecor
	if ns.Usable(decor) then
		decor:SetBlendMode("ADD")
		decor:SetAlpha(1)
		decor:SetVertexColor(0.2, 0.2, 0.2)
	end
	DarkenTree(settings, 0)
end

if ns.Usable(settings) then
	After(settings, "LoadTheme", Settings)
	After(settings, "SelectTabByID", Tree)
	After(settings, "UpdateCurrentTab", Tree)
	settings:HookScript("OnShow", function()
		C_Timer.After(0, function() if settings:IsShown() then ns.Guard(Settings) end end)
	end)
end

-- ---------------------------------------------------------------------------------------------
-- Everything again when the look changes (one pass a frame at most)
-- ---------------------------------------------------------------------------------------------

local queued = false
local function Again()
	if queued then return end
	queued = true
	C_Timer.After(0, function()
		queued = false
		RefontAll()
		RecolorAll()
		ns.Guard(Talk)
		ns.Guard(Settings)
	end)
end

RefontAll()
RecolorAll()

ns.me.On("StyleChanged", Again)
ns.me.On("Login", Again)
ns.me.On("SettingChanged", function(scope, path)
	if scope ~= "DaylightAddonSkins" or type(path) ~= "string" then return end
	if path == KEY or path == "followDaylight" or sub(path, 1, 16) == "look.DialogueUI." then Again() end
end)

-- ---------------------------------------------------------------------------------------------
-- Conflicts (Core.lua): what it does that DaylightUI already does. Its settings are its saved
-- table (DialogueUI_DB); it reads most of them once, as it loads, so those take a /reload. Its
-- taking over the NPC talk windows (DaylightUI's NPC window never opens for gossip and quests) has
-- no setting: only turning Dialogue UI off gives them back, so it isn't offered here.
-- ---------------------------------------------------------------------------------------------

-- "Use the game's tooltip" is the other way round: DaylightUI's tooltip is in use when it's on.
local INVERTED = { UseBlizzardTooltip = true }

ns.Handover(KEY, {
	ready = function() return type(_G.DialogueUI_DB) == "table" end,
	get = function(key)
		local v = _G.DialogueUI_DB[key]
		if INVERTED[key] then return not v end
		return v
	end,
	set = function(key, value)
		if INVERTED[key] then value = not value end
		_G.DialogueUI_DB[key] = value
	end,
	list = {
		{ key = "AutoSelectGossip", label = "Pick an NPC's only gossip option",
		  daylight = "skip gossip (Quality of Life)",
		  ours = function() return ns.DaylightHas("QoL", "skipGossip") end },
		{ key = "AutoCompleteQuest", label = "Turn in quests automatically",
		  daylight = "auto turn in (Quality of Life)",
		  ours = function() return ns.DaylightHas("QoL", "questTurnIn") end },
		{ key = "BookUIEnabled", label = "Its own window for books and letters",
		  daylight = "the game's book window in the DaylightUI look (Window Skins)", reload = true,
		  ours = function() return ns.Enabled() end },
		{ key = "UseBlizzardTooltip", label = "Its own tooltip for rewards",
		  daylight = "its tooltip, with item level and quality (Tooltip)", reload = true,
		  ours = function() return ns.ModuleOn("Tooltip") end },
	},
})
