-- The skin switches: what the options page's two grids list (Options.lua), and what the Blizzard
-- packs ask before they dress a window.
--   Addons: every addon target (ns.Target), its switch the target's own key, as it always was.
--     An addon that isn't installed gets a "Get Addon" link to its CurseForge page (LINKS below).
--   Blizzard: the game's windows this plugin dresses, one switch each ("blizz.<id>"), plus the
--     two Blizzard targets that already had a switch of their own (the settings window and the
--     dungeon-ready dialog). Every window the Blizzard packs dress belongs to one id: by its
--     global name (frames below), or an id handed over by the pack itself. A name not listed here
--     falls under "misc".
-- A switch takes hold after a reload, as the addon switches always have.
local _, ns = ...
if not ns.ok then return end

local L = ns.L

-- CurseForge pages, by addon key (a link is only shown for an addon that isn't installed).
ns.LINKS = {
	["AllTheThings"] = "https://www.curseforge.com/wow/addons/all-the-things",
	["Altoholic"] = "https://www.curseforge.com/wow/addons/altoholic",
	["AtlasLootContinued"] = "https://www.curseforge.com/wow/addons/atlasloot-continued",
	["Auctionator"] = "https://www.curseforge.com/wow/addons/auctionator",
	["BugSack"] = "https://www.curseforge.com/wow/addons/bugsack",
	["CampingKit"] = "https://www.curseforge.com/wow/addons/camping-kit",
	["Details"] = "https://www.curseforge.com/wow/addons/details",
	["DialogueUI"] = "https://www.curseforge.com/wow/addons/dialogueui",
	["DoesItDie"] = "https://www.curseforge.com/wow/addons/does-it-die",
	["ForeverDungeonJournal"] = "https://www.curseforge.com/wow/addons/dungeonjournal",
	["ForeverFishing"] = "https://www.curseforge.com/wow/addons/forever-fishing",
	["ForeverLevelingBiS"] = "https://www.curseforge.com/wow/addons/forever-leveling-bis",
	["Guildy"] = "https://www.curseforge.com/wow/addons/guildy",
	["HighFidelityWorldMap"] = "https://www.curseforge.com/wow/addons/hfwm",
	["Journey"] = "https://www.curseforge.com/wow/addons/journey",
	["KeepOrToss"] = "https://www.curseforge.com/wow/addons/keep-or-toss-forever",
	["Kerzo Classic Quest Log"] = "https://www.curseforge.com/wow/addons/kerzo-classic-quest-log",
	["Kerzo Quest Expansion"] = "https://www.curseforge.com/wow/addons/kerzo-quest-expansion",
	["LayerSwap"] = "https://www.curseforge.com/wow/addons/layer",
	["Leatrix_Plus"] = "https://www.curseforge.com/wow/addons/leatrix-plus",
	["LFGForever"] = "https://www.curseforge.com/wow/addons/lfg-forever",
	["LootTriage"] = "https://www.curseforge.com/wow/addons/loot-triage",
	["OneForAll"] = "https://www.curseforge.com/wow/addons/oneforall-forever",
	["OpenMap"] = "https://www.curseforge.com/wow/addons/openmap",
	["Pawn"] = "https://www.curseforge.com/wow/addons/pawn",
	["Polestar"] = "https://www.curseforge.com/wow/addons/polestar-guides",
	["Questie"] = "https://www.curseforge.com/wow/addons/questie",
	["RareScanner"] = "https://www.curseforge.com/wow/addons/rarescanner",
	["ShortestPathForever"] = "https://www.curseforge.com/wow/addons/shortest-path-forever",
	["Spoken"] = "https://www.curseforge.com/wow/addons/spoken",
	["totalRP3"] = "https://www.curseforge.com/wow/addons/total-rp-3",
	["TrueshotLodge"] = "https://www.curseforge.com/wow/addons/trueshotlodge",
}

-- The game's windows: id, the label in the grid, the global names of the frames in it.
ns.BLIZZ = {
	{ id = "alerts", label = L["Alert Frames"], frames = { "EventToastManagerFrame", "VoiceChatPromptActivateChannel",
		"VoiceChatChannelActivatedNotification" } },
	{ id = "auction", label = L["Auctions"], frames = { "AuctionHouseFrame", "AuctionHouseMultisellProgressFrame" } },
	{ id = "bags", label = L["Bags"], frames = { "ContainerFrame1", "ContainerFrame2", "ContainerFrame3", "ContainerFrame4",
		"ContainerFrame5", "ContainerFrame6", "ContainerFrame7", "ContainerFrameCombinedBags" } },
	{ id = "bank", label = L["Bank"], frames = { "BankFrame", "BankCleanUpConfirmationPopup" } },
	{ id = "battlefieldmap", label = L["BG Map"], frames = { "BattlefieldMapFrame" } },
	{ id = "calendar", label = L["Calendar Frame"], frames = { "CalendarFrame" } },
	{ id = "channels", label = L["Channels"], frames = { "ChannelFrame", "CreateChannelPopup" } },
	{ id = "character", label = L["Character Frame"], frames = { "CharacterFrame", "GearManagerPopupFrame" } },
	{ id = "chatsettings", label = L["Chat Settings"], frames = { "ChatConfigFrame" } },
	{ id = "clickcasting", label = L["Click Casting"], frames = { "ClickBindingFrame" } },
	{ id = "collections", label = L["Collections"], frames = { "CollectionsJournal" } },
	{ id = "colorpicker", label = L["Color Picker"], frames = { "ColorPickerFrame", "OpacityFrame" } },
	{ id = "communities", label = L["Communities"], frames = { "CommunitiesSettingsDialog", "CommunitiesTicketManagerDialog",
		"CommunitiesAvatarPickerDialog" } },
	{ id = "cooldowns", label = L["Cooldown Manager"], frames = { "CooldownViewerSettings", "CooldownViewerSettingsEditAlert",
		"GroupBuffFilterEditVisualAlert" } },
	{ id = "damagemeter", label = L["Damage Meter"], frames = { "DamageMeter" } },
	{ id = "deathrecap", label = L["Death Recap"], frames = { "DeathRecapFrame", "GhostFrame" } },
	{ id = "dropdowns", label = L["Dropdown Menus"], frames = { "DropDownList1" } },
	{ key = "BlizzardDungeonReady", label = L["Dungeon Ready"] },
	{ id = "friends", label = L["Friends"], frames = { "SocialUIFrame", "FriendsFrame", "AddFriendFrame",
		"BattleNetInviteFrame", "FriendsFriendsFrame" } },
	{ key = "BlizzardSettings", label = L["Game Settings"] },
	{ id = "gmchat", label = L["GM Chat"], frames = { "GMChatFrame", "GMChatStatusFrame", "TicketStatusFrame" } },
	{ id = "gossip", label = L["Gossip Frame"], frames = { "GossipFrame" } },
	{ id = "groupfinder", label = L["Group Finder"], frames = { "LFGInvitePopup", "QuickJoinRoleSelectionFrame",
		"QueueStatusFrame", "LFGBrowseSearchEntryTooltip", "RolePollPopup" } },
	{ id = "guild", label = L["Guild"], frames = { "GuildInviteFrame", "GuildRenameFrame", "GuildControlUI" } },
	{ id = "guildbank", label = L["Guild Bank"], frames = { "GuildBankFrame", "GuildBankPopupFrame" } },
	{ id = "help", label = L["Help Frame"], frames = { "HelpFrame", "BrowserSettingsTooltip", "WowSurveyStatusFrame" } },
	{ id = "keybinds", label = L["Key Bindings"], frames = { "QuickKeybindFrame" } },
	{ id = "loot", label = L["Loot Frames"], frames = { "MasterLooterFrame", "GroupLootHistoryFrame" } },
	{ id = "macros", label = L["Macros"], frames = { "MacroPopupFrame" } },
	{ id = "mail", label = L["Mail Frame"], frames = { "MailFrame", "OpenMailFrame" } },
	{ id = "merchant", label = L["Merchant Frame"], frames = { "MerchantFrame" } },
	{ id = "misc", label = L["Misc Frames"], frames = { "AddonDialog", "BasicMessageDialog", "CoinPickupFrame",
		"ModelPreviewFrame", "MovePadFrame", "AutoCompleteBox", "IMECandidatesFrame", "InstanceAbandonPopup",
		"QuestSessionManager", "SubscriptionInterstitialFrame", "ExternalDefensivesFrame" } },
	{ id = "objectives", label = L["Objectives"], frames = { "ObjectiveTrackerFrame", "QuestTimerFrame" } },
	{ id = "professions", label = L["Professions"], frames = { "ProfessionsFrame" } },
	{ id = "pvp", label = L["PvP Frames"], frames = { "PVPReadyDialog", "PVPRoleCheckPopup", "PVPFramePopup",
		"PVPReadyPopup", "PVPMatchScoreboard", "PVPMatchResults" } },
	{ id = "quest", label = L["Quest Frame"], frames = { "QuestFrame", "QuestLogPopupDetailFrame" } },
	{ id = "raid", label = L["Raid Frame"], frames = { "RaidInfoFrame", "RaidParentFrame" } },
	{ id = "readycheck", label = L["Ready Check"], frames = { "ReadyCheckFrame" } },
	{ id = "report", label = L["Report Frames"], frames = { "ReportFrame", "ReportCheatingDialog",
		"BehavioralMessagingTray", "BehavioralMessagingDetails" } },
	{ id = "spellbook", label = L["Spells and Talents"], frames = { "PlayerSpellsFrame" } },
	{ id = "popups", label = L["Static Popups"], frames = { "StaticPopup1", "StaticPopup2", "StaticPopup3", "StaticPopup4" } },
	{ id = "widgets", label = L["Status Widgets"], frames = { "UIWidgetTopCenterContainerFrame",
		"UIWidgetBelowMinimapContainerFrame" } },
	{ id = "stopwatch", label = L["Stopwatch"], frames = { "StopwatchFrame" } },
	{ id = "trainer", label = L["Trainer Frame"], frames = { "ClassTrainerFrame" } },
	{ id = "tutorials", label = L["Tutorials"], frames = { "TutorialFrame", "NamePlatesTutorial", "HelpPlateTooltip",
		"TutorialKeyboardMouseFrame_Frame", "TutorialMainFrame_Frame", "TutorialSingleKey_Frame",
		"TutorialDoubleKey_Frame", "TutorialWalk_Frame" } },
	{ id = "worldmap", label = L["World Map"], frames = { "WorldMapFrame" } },
}

-- Each entry's settings key; a frame's id.
local idOf = {}
for _, w in ipairs(ns.BLIZZ) do
	if w.id then
		w.key = "blizz." .. w.id
		for _, name in ipairs(w.frames) do idOf[name] = w.id end
	end
end

-- The id a Blizzard frame name belongs to ("misc" for one not listed).
function ns.BlizzIdOf(name)
	if type(name) ~= "string" then return "misc" end
	return idOf[name] or "misc"
end

-- Whether the game window `id` is to be dressed (its switch; on unless turned off).
function ns.BlizzOn(id)
	return ns.Setting("blizz." .. (id or "misc")) ~= false
end

-- Before these switches there was one "Game windows" switch (key "Blizzard") for all of them. A
-- player who had it off gets every window's switch off once, and the old switch (no longer
-- shown) back on, so the windows' own switches decide from now on.
ns.me.On("Login", function()
	local db = _G.DaylightAddonSkinsDB
	if type(db) ~= "table" then
		db = {}
		_G.DaylightAddonSkinsDB = db
	end
	if db.blizzSplit then return end
	db.blizzSplit = true
	local ok, old = pcall(ns.API.GetSetting, "DaylightAddonSkins", "Blizzard")
	if not ok or old ~= false then return end
	local DUI = _G.DaylightUI
	ns.Guard(function()
		for _, w in ipairs(ns.BLIZZ) do
			if w.id then DUI:Set("DaylightAddonSkins", w.key, false) end
		end
		DUI:Set("DaylightAddonSkins", "Blizzard", true)
	end)
end)
