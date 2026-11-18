-- Game windows, part two: the game's own windows that show when a DaylightUI window that replaces
-- them is switched off (or when DaylightUI has none for this client's layout), which DaylightUI
-- leaves exactly as the game draws them (from DaylightUI 1.8.4 its Window Skins dress the NPC,
-- mail and social windows themselves while their pack is on: those are left to it). Same switch as the Blizzard pack ("Game windows"), same
-- look through the Kit, built against the client's own interface code (wow-ui-source, branch
-- "forever": the Mainline files plus their Camelot overrides).
--   Gossip (GossipFrame) and the quest window (QuestFrame: greeting, details, progress, rewards,
--     the quest text QuestInfo_Display moves into it): while DaylightUI's NPC window is off.
--   The vendor (MerchantFrame: goods, buyback, the item slots, money, repair and junk buttons,
--     filter, tabs, page buttons): while neither DaylightUI's vendor page nor DaylightMogul's
--     vendor window is in use.
--   The trainer (ClassTrainerFrame, Blizzard_TrainerUI): while DaylightUI's "Trainer window" is
--     off. With it on, the game's window is only lent for Beast Training and DaylightUI's Window
--     Skins dress it then; only the filter's reset badge is added here.
--   The mailbox (MailFrame with its inbox and send pages, OpenMailFrame): while neither
--     DaylightUI's mailbox nor DaylightMogul's is in use.
--   The social window (SocialUIFrame) while DaylightUI's Social window is off, and the older
--     friends window (FriendsFrame: contacts, recent allies, raid tab, ignore list) the game shows
--     when its social window is switched off; the raid info window (RaidInfoFrame).
--   Bags (ContainerFrame1..7, ContainerFrameCombinedBags) and the bank (BankFrame / BankPanel):
--     while DaylightUI's Bags module is off.
--   The quest tracker (ObjectiveTrackerFrame): its headers and collapse buttons, while
--     DaylightUI's quest tracker doesn't replace it.
-- Each window is dressed only while it is really on screen: never while DaylightUI or
-- DaylightMogul has parked it out of sight under its own window (a hidden parent, or a parent
-- faded to nothing), and never for a window they own. What DaylightUI's Window Skins dress (the
-- NPC pack's books, taxi, tabard, stable; the guild bank, trade and the rest) isn't touched.
-- Left as the game draws them: the quest NPC portrait beside the quest window (QuestModelScene),
-- the friendship bar, the tracker's quest lines, bars and item buttons (secure, and sized by Edit
-- Mode), and the gamepad page indicators (controller only).
--
-- Taint: looks only, post-hooks (hooksecurefunc, HookScript) only, nothing protected called, no
-- field of the game's written. Every window is first dressed out of combat; later passes (rows
-- filled, a page shown) wait for the fight to end. Nothing here loads a Blizzard addon.
local _, ns = ...
if not ns.ok then return end

local KEY = "Blizzard"   -- the Blizzard pack's target: "Game windows"
local DUI = _G.DaylightUI
local Usable, Guard = ns.Usable, ns.Guard
local ipairs, type, select, pcall = ipairs, type, select, pcall

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end

local function Kind(x)
	if not Usable(x) then return nil end
	return x:GetObjectType()
end

local function IsTexture(x) return Kind(x) == "Texture" end

local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) end

local dressed = setmetatable({}, { __mode = "k" })   -- frames and controls of this file's, done once
local live = setmetatable({}, { __mode = "k" })      -- windows dressed here (their refills follow)

local function Once(x)
	if not Usable(x) or dressed[x] then return false end
	dressed[x] = true
	return true
end

-- ---------------------------------------------------------------------------------------------
-- Who owns what
-- ---------------------------------------------------------------------------------------------

local function Flag(name) return type(DUI) == "table" and DUI[name] == true end

local function Setting(scope, path)
	local ok, v = pcall(ns.API.GetSetting, scope, path)
	if ok then return v end
	return nil
end

-- DaylightMogul's own windows (its API: <part>.Owns() is true while its window is in use).
local function MogulOwns(part)
	local mog = _G.DaylightMogul
	local api = type(mog) == "table" and mog.API
	local p = type(api) == "table" and api[part]
	if type(p) ~= "table" or type(p.Owns) ~= "function" then return false end
	local ok, owns = pcall(p.Owns)
	return ok and owns == true
end

-- Dialogue UI takes the game's gossip and quest windows over with its own talk window
-- (DUIQuestFrame) whenever it's loaded, so those two are its, not ours.
local function DialogueOwns()
	if type(_G.DUIQuestFrame) == "table" then return true end
	local loaded = C_AddOns and C_AddOns.IsAddOnLoaded
	return type(loaded) == "function" and loaded("DialogueUI") == true
end
-- (DaylightUI 1.8.4 and later dress the game's own NPC, mail and social windows themselves while
-- their Window Skins pack is on: ns.DaylightDressesGame. Those count as DaylightUI's too.)
local function NpcSkin() return ns.DaylightDressesGame("npc") end
local function NpcOwned() return Flag("npcOwnWindow") or DialogueOwns() or NpcSkin() end
local function VendorOwned() return Flag("npcOwnVendor") or Flag("vendorMogul") or MogulOwns("Vendor") or NpcSkin() end
local function TrainerOwned() return Flag("npcOwnTrainer") end
-- DaylightUI's trainer skin only runs with its NPC module there (DaylightUI.Npc); without it, ours.
local function TrainerSkin() return NpcSkin() and type(DUI) == "table" and type(DUI.Npc) == "table" end
local function MailOwned()
	return Flag("mailOwnWindow") or Flag("mailMogul") or MogulOwns("Mail") or ns.DaylightDressesGame("social")
end
local function SocialOwned()
	return (ns.ModuleOn("Social") and Setting("Social", "enabled") == true) or ns.DaylightDressesGame("social")
end
local function BagsOwned() return ns.ModuleOn("Bags") and Setting("Bags", "enabled") ~= false end
local function TrackerOwned() return Flag("questsOwnTracker") end

-- Really on screen: shown under a shown parent, not faded to nothing itself (an addon that hides a
-- game window it replaces by its alpha: the window's own fade-in from Kit.Window would bring it
-- back over that addon's), and not parked under a frame faded to nothing (DaylightUI and
-- DaylightMogul park the game windows they replace under a hidden frame, or a see-through one
-- for windows that check IsVisible).
local function Really(f)
	if not Usable(f) or not f:IsVisible() then return false end
	local own = f:GetAlpha()
	if type(own) == "number" and not Secret(own) and own < 0.01 then return false end
	local p = f:GetParent()
	if Usable(p) and p ~= UIParent and p.GetEffectiveAlpha then
		local a = p:GetEffectiveAlpha()
		if type(a) == "number" and not Secret(a) and a < 0.01 then return false end
	end
	return true
end

local function Under(region, root)
	local p = Usable(region) and region.GetParent and region:GetParent()
	for _ = 1, 12 do
		if not Usable(p) then return false end
		if p == root then return true end
		p = p:GetParent()
	end
	return false
end

-- ---------------------------------------------------------------------------------------------
-- Text
-- ---------------------------------------------------------------------------------------------

local DARK = 0.3   -- text this dark or darker was written for parchment

local function Dark(r, g, b)
	if type(r) ~= "number" or Secret(r) or Secret(g) or Secret(b) then return false end
	return (0.3 * r + 0.59 * g + 0.11 * b) <= DARK
end

-- One string: dark ink (and dark color codes inside it) to DaylightUI's text ink; any other color
-- (quality, red, green, gray) kept.
local function LightString(Kit, fs)
	local r, g, b = fs:GetTextColor()
	if Dark(r, g, b) then
		Kit.Light(fs)
		return
	end
	local text = fs:GetText()
	if type(text) == "string" and not Secret(text) and string.find(text, "|c", 1, true) then
		local new = Kit.LightRuns(text)
		if new ~= text then fs:SetText(new) end
	end
end

local function ParchAmong(Kit, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if Kind(r) == "FontString" then LightString(Kit, r) end
	end
end

-- Parchment text under a frame to depth: dark ink lit, the game's gold in DaylightUI's label ink.
-- Runs on every fill (the game colors this text again each time).
local Parch
local function ParchChildren(Kit, depth, ...)
	for i = 1, select("#", ...) do Parch(Kit, (select(i, ...)), depth) end
end
Parch = function(Kit, frame, depth)
	if not Usable(frame) or not frame.GetRegions then return end
	ParchAmong(Kit, frame:GetRegions())
	Kit.InkGameText(frame)
	if depth > 0 and frame.GetChildren then ParchChildren(Kit, depth - 1, frame:GetChildren()) end
end

local function Font(Kit, fs)
	local k = Kind(fs)
	if k ~= "FontString" and k ~= "EditBox" then return end
	local ok, _, size = pcall(fs.GetFont, fs)
	if ok and type(size) == "number" and size > 0 then Kit.Font(fs) end
end

local function Head(Kit, fs)
	if Kind(fs) ~= "FontString" then return end
	Font(Kit, fs)
	Kit.Light(fs, Kit.HEADER)
end

-- ---------------------------------------------------------------------------------------------
-- Shared pieces
-- ---------------------------------------------------------------------------------------------

-- A dialog-style frame inside a window (a broadcast box, a side window): its dialog border frame
-- and old art off, DaylightUI's window shell.
local function SubWindow(Kit, f)
	if not Once(f) then return end
	if Usable(f.TitleContainer) or Usable(f.PortraitContainer) then
		Kit.Window(f)
		return
	end
	if Kind(f.Border) == "Frame" then Kit.Hide(f.Border) end
	if Usable(f.Header) then Kit.Strip(f.Header) end
	if Usable(f.NineSlice) then Kit.Hide(f.NineSlice) end
	Kit.Backdrop(f)
	Kit.Strip(f)
	Kit.Shell(f, "window")
	local close = f.CloseButton or (f.GetName and f:GetName() and _G[f:GetName() .. "CloseButton"])
	if Usable(close) then Kit.Close(close) end
end

-- A button whose icon is the point (repair, sell junk): the slot art off, the icon kept as the
-- game colors it (gray when it can't be used), a control outline round it and a hover wash.
local function IconSlot(Kit, b)
	if not Once(b) then return end
	local icon = b.Icon
	Kit.Strip(b, IsTexture(icon) and { [icon] = true } or nil)
	for _, get in ipairs({ "GetPushedTexture", "GetHighlightTexture" }) do
		local t = b[get] and b[get](b)
		if IsTexture(t) then Kit.Hide(t) end
	end
	if IsTexture(icon) then Kit.Outline(icon, 1, "control") end
	Kit.HoverWash(b)
end

-- A list row as a plain line: the game's art and highlight off, a hover wash; keep = textures
-- that stay (icons that mean something).
local function LineRow(Kit, row, keep, selected)
	if Kind(row) ~= "Button" or not Controls() then return end
	Kit.Row(row, keep, selected, false)
end

-- Icon tabs down a window's side (the game's side tabs, the bank's tab buttons): a tile of
-- DaylightUI's tab look round the icon, the picked one in the accent. symbol: the icon is an atlas
-- symbol the game swaps (a side tab's active / inactive art), so it's drawn again on the tile at
-- its own size rather than cropped in place (a crop would cut the atlas).
local SYMBOL = 24
local function IconTab(Kit, tab, picked, symbol)
	if not Once(tab) or not Controls() then return end
	for _, k in ipairs({ "Background", "Border" }) do
		if IsTexture(tab[k]) then Kit.Hide(tab[k]) end
	end
	for _, k in ipairs({ "HighlightTexture", "TabGlow" }) do
		if IsTexture(tab[k]) then Kit.Erase(tab[k]) end
	end
	-- (Kept shown or hidden by the game, only out of sight: it still says which one is picked.)
	if IsTexture(tab.SelectedTexture) then Kit.Hide(tab.SelectedTexture) end
	if tab.GetHighlightTexture and IsTexture(tab:GetHighlightTexture()) then Kit.Hide(tab:GetHighlightTexture()) end
	if symbol then
		local h = tab:GetHeight()
		local size = (type(h) == "number" and not Secret(h) and h > 8) and math.floor(h - 4 + 0.5) or 40
		ns.SideTile(tab, { picked = picked, key = KEY, copy = true, size = size, iconSize = SYMBOL })
	else
		ns.SideTile(tab, { picked = picked, key = KEY, pad = 2 })
	end
	if type(tab.SetChecked) == "function" then
		ns.HookOnce(tab, "SetChecked", function() Guard(ns.SideTilePaint, tab) end, KEY)
	end
end

local RaidInfo   -- (the raid info windows; below, with the social window)

local function SelectedShown(tab)
	local t = tab.SelectedTexture
	return IsTexture(t) and t:IsShown() == true
end

-- ---------------------------------------------------------------------------------------------
-- The fallbacks: get() = the game's window (nil while it isn't there), owned() = DaylightUI or
-- DaylightMogul has it, dress(f, Kit) once, again(f, Kit) on every show after that. Hooked on the
-- window's own OnShow, the moment it exists; dressed only while it is really on screen.
-- ---------------------------------------------------------------------------------------------

local defs = {}

-- (The name each get looks up, for the window switches: Windows.lua.)
local nameOf = {}
local function Named(name)
	local get = function() return _G[name] end
	nameOf[get] = name
	return get
end

local function Fallback(get, owned, dress, again)
	defs[#defs + 1] = { get = get, owned = owned, dress = dress, again = again, id = ns.BlizzIdOf(nameOf[get]) }
end

local Try
Try = function(d, f)
	if not On() or not ns.BlizzOn(d.id) or (d.owned and d.owned()) or not Really(f) then return end
	if InCombatLockdown() then
		if not d.waiting then
			d.waiting = true
			ns.OutOfCombat(function() d.waiting = false Try(d, f) end)
		end
		return
	end
	local Kit = ns.Kit
	if not Kit then
		if not d.kit then
			d.kit = true
			ns.WithKit(function() d.kit = false Try(d, f) end)
		end
		return
	end
	if not d.done then
		d.done = true
		live[f] = true
		Guard(d.dress, f, Kit)
	elseif d.again then
		Guard(d.again, f, Kit)
	end
end


local left = 0
local function HookAll()
	left = 0
	for i = 1, #defs do
		local d = defs[i]
		if not d.hooked then
			local ok, f = pcall(d.get)
			if ok and Usable(f) and f.HookScript then
				d.hooked = true
				f:HookScript("OnShow", function(self) Try(d, self) end)
				Try(d, f)
			else
				left = left + 1
			end
		end
	end
end

-- After a refill: run fn(Kit) now if the window is dressed and on screen, out of combat.
local function Refill(f, fn)
	if not On() or not ns.Kit or not live[f] or not Really(f) then return end
	if InCombatLockdown() then return end
	Guard(fn, ns.Kit)
end

-- ---------------------------------------------------------------------------------------------
-- Gossip
-- GossipFrame (ButtonFrameTemplate): Background, GreetingPanel (its parchment pieces,
-- GoodbyeButton, ScrollBox of GossipTitle*ButtonTemplate rows and GossipGreetingTextTemplate
-- text), ScrollBar (MinimalScrollBar), FriendshipStatusBar (kept).
-- ---------------------------------------------------------------------------------------------

local function GossipRow(Kit, row)
	if not Usable(row) then return end
	if Kind(row.GreetingText) == "FontString" then
		Font(Kit, row.GreetingText)
		LightString(Kit, row.GreetingText)
		return
	end
	local fs = Kind(row) == "Button" and row.GetFontString and row:GetFontString()
	if Kind(fs) ~= "FontString" then return end
	LineRow(Kit, row, IsTexture(row.Icon) and { [row.Icon] = true } or nil)
	Font(Kit, fs)
	LightString(Kit, fs)
end

Fallback(Named("GossipFrame"), NpcOwned, function(f, Kit)
	Kit.Window(f)
	if IsTexture(f.Background) then Kit.Hide(f.Background) end
	local panel = f.GreetingPanel
	if Usable(panel) then
		Kit.Strip(panel)
		Kit.EachRow(panel.ScrollBox, function(row) GossipRow(Kit, row) end, "AddonSkinsGossip")
	end
	if Controls() then ns.Walk(Kit, f, { rows = false }) end
end)

-- ---------------------------------------------------------------------------------------------
-- Quests
-- QuestFrame (ButtonFrameTemplate; QuestNpcNameFrame, AccountCompletedNotice) and its four
-- QuestFramePanelTemplate panels (Bg, Material*, SealMaterialBG): QuestFrameGreetingPanel
-- (GreetingText, CurrentQuestsText, AvailableQuestsText, the break, a pool of
-- QuestTitleButtonTemplate rows), QuestFrameDetailPanel / QuestFrameRewardPanel (the QuestInfo
-- elements moved into their scroll child: headers, text, objectives, QuestInfoRewardsFrame with
-- its reward buttons, spell / reputation pools, money, XP), QuestFrameProgressPanel
-- (QuestProgressItem1..6, the required money). Each panel's own OnShow fills it (and recolors it
-- for parchment), so the text is lit after it; QUEST_LOG_UPDATE refills the greeting by calling
-- QuestFrameGreetingPanel_OnShow, QUEST_ITEM_UPDATE the rewards (QuestInfo_ShowRewards) and the
-- progress items. The world map's quest log shares the QuestInfo text: only what sits in this
-- window is touched (DaylightUI's map skin lights it there itself).
-- ---------------------------------------------------------------------------------------------

local QUEST_SCROLLS = { "QuestDetailScrollChildFrame", "QuestRewardScrollChildFrame", "QuestProgressScrollChildFrame",
	"QuestGreetingScrollChildFrame" }
local QUEST_HEADS = { "QuestInfoTitleHeader", "QuestInfoDescriptionHeader", "QuestInfoObjectivesHeader", "QuestProgressTitleText",
	"QuestProgressRequiredItemsText", "CurrentQuestsText", "AvailableQuestsText" }
local QUEST_PANELS = { "QuestFrameGreetingPanel", "QuestFrameDetailPanel", "QuestFrameProgressPanel", "QuestFrameRewardPanel" }
local REWARD_KEYS = { "HonorFrame", "SkillPointFrame", "ArtifactXPFrame", "WarModeBonusFrame" }
local REWARD_POOLS = { "spellRewardPool", "reputationRewardPool" }

local picks = setmetatable({}, { __mode = "k" })   -- reward button -> its accent wash

-- The chosen reward: an accent wash on its button (the game's gold highlight frame is faded out).
local function PaintPicks()
	local selected = _G.QuestInfoItem_IsSelected
	for b, wash in pairs(picks) do
		local on = false
		if type(selected) == "function" and Usable(b) and b:IsShown() then
			local ok, got = pcall(selected, b)
			on = ok and got == true
		end
		if on then ns.FillAccent(wash, 0.18, nil, KEY) end
		wash:SetShown(on)
	end
end

local function RewardButton(Kit, b)
	if not Usable(b) or not b.CreateTexture then return end
	Kit.Item(b)
	if not picks[b] then
		local wash = b:CreateTexture(nil, "BACKGROUND", nil, 1)
		wash:SetAllPoints(b)
		wash:Hide()
		picks[b] = wash
	end
end

local function QuestText(Kit)
	local qf = _G.QuestFrame
	if not Usable(qf) or not live[qf] or not qf:IsVisible() then return end
	for _, n in ipairs(QUEST_SCROLLS) do
		local child = _G[n]
		if Usable(child) and child:IsVisible() then Parch(Kit, child, 5) end
	end
	for _, n in ipairs(QUEST_HEADS) do
		local fs = _G[n]
		if Kind(fs) == "FontString" and Under(fs, qf) then Head(Kit, fs) end
	end
	-- The required money: the game grays it while you can't pay.
	local money = _G.QuestProgressRequiredMoneyText
	if Kind(money) == "FontString" and money:IsVisible() then
		local need = _G.GetQuestMoneyToGet and _G.GetQuestMoneyToGet() or 0
		local have = _G.GetMoney and _G.GetMoney() or 0
		Kit.Light(money, (type(need) == "number" and type(have) == "number" and need > have) and Kit.DIM or Kit.TEXT)
	end
	local rewards = _G.QuestInfoRewardsFrame
	if Usable(rewards) and Under(rewards, qf) then
		Head(Kit, rewards.Header)
		if type(rewards.RewardButtons) == "table" then
			for _, b in ipairs(rewards.RewardButtons) do RewardButton(Kit, b) end
		end
		for _, k in ipairs(REWARD_KEYS) do
			if Usable(rewards[k]) then Kit.Item(rewards[k]) end
		end
		for _, k in ipairs(REWARD_POOLS) do
			local pool = rewards[k]
			if type(pool) == "table" and type(pool.EnumerateActive) == "function" then
				for b in pool:EnumerateActive() do Kit.Item(b) end
			end
		end
		if Usable(rewards.ItemHighlight) and Once(rewards.ItemHighlight) then Kit.Strip(rewards.ItemHighlight) end
	end
	for i = 1, 6 do
		local b = _G["QuestProgressItem" .. i]
		if Usable(b) then Kit.Item(b) end
	end
	local greeting = _G.QuestFrameGreetingPanel
	local pool = Usable(greeting) and greeting.titleButtonPool
	if type(pool) == "table" and type(pool.EnumerateActive) == "function" then
		for b in pool:EnumerateActive() do
			LineRow(Kit, b, IsTexture(b.Icon) and { [b.Icon] = true } or nil)
			local fs = b.GetFontString and b:GetFontString()
			Font(Kit, fs)
			if Kind(fs) == "FontString" then LightString(Kit, fs) end
		end
	end
	if IsTexture(_G.QuestGreetingFrameHorizontalBreak) then Kit.Hide(_G.QuestGreetingFrameHorizontalBreak) end
	PaintPicks()
end

-- The quest text the world map's quest log (and the tracker's quest popup) shares with this
-- window: lit here, it would stay lit on the map's parchment, since QuestInfo_Display colors it
-- again only when the parchment changes. So it gets the game's colors back as this window closes
-- and whenever the text is shown outside it (the popup lights it again itself), unless
-- DaylightUI's own System skins are on, which light it on the map and look after it there.
local QUEST_SHARED_HEADS = { "QuestInfoTitleHeader", "QuestInfoDescriptionHeader", "QuestInfoObjectivesHeader" }
local QUEST_SHARED_TEXT = { "QuestInfoDescriptionText", "QuestInfoObjectivesText", "QuestInfoGroupSize", "QuestInfoRewardText",
	"QuestInfoQuestType", "QuestInfoTimerText", "QuestInfoSpellObjectiveLearnLabel", "QuestInfoRequiredMoneyText" }

local function SystemSkinsOn()
	local packs = Setting("Skins", "packs")
	return not (type(packs) == "table" and packs.system == false)
end

local function QuestTextBack(Kit)
	if SystemSkinsOn() then return end
	local text, title
	local colors = _G.GetMaterialTextColors
	if type(colors) == "function" then
		local info = _G.QuestInfoFrame
		local contrast = _G.QuestTextContrast
		local stone = type(contrast) == "table" and type(contrast.UseLightText) == "function" and contrast.UseLightText() == true
		local material = stone and "Stone" or (type(info) == "table" and info.material) or "Parchment"
		local ok, a, b = pcall(colors, material)
		if ok then text, title = a, b end
	end
	for _, n in ipairs(QUEST_SHARED_HEADS) do Kit.Unlight(_G[n], title) end
	for _, n in ipairs(QUEST_SHARED_TEXT) do Kit.Unlight(_G[n], text) end
	local objectives = _G.QuestInfoObjectivesFrame
	if Usable(objectives) and type(objectives.Objectives) == "table" then
		-- (The game colors each objective line on every fill.)
		for _, fs in ipairs(objectives.Objectives) do Kit.Unlight(fs) end
	end
	local seal = _G.QuestInfoSealFrame
	if Usable(seal) then Kit.Unlight(seal.Text) end
end

local function InQuestWindows(frame)
	local qf, popup = _G.QuestFrame, _G.QuestLogPopupDetailFrame
	return (Usable(qf) and (frame == qf or Under(frame, qf))) or (Usable(popup) and (frame == popup or Under(frame, popup)))
end

Fallback(Named("QuestFrame"), NpcOwned, function(f, Kit)
	ns.ScriptOnce(f, "OnHide", function() if ns.Kit then Guard(QuestTextBack, ns.Kit) end end, KEY)
	Kit.Window(f)
	for _, n in ipairs(QUEST_PANELS) do
		local panel = _G[n]
		if Usable(panel) then
			Kit.Strip(panel)
			-- (After the panel's own OnShow, which fills and recolors it.)
			ns.ScriptOnce(panel, "OnShow", function() Refill(f, QuestText) end, KEY)
		end
	end
	for _, n in ipairs({ "QuestDetailScrollFrame", "QuestRewardScrollFrame", "QuestProgressScrollFrame", "QuestGreetingScrollFrame" }) do
		if Usable(_G[n]) then Kit.Inset(_G[n]) end
	end
	ns.Words(_G.QuestNpcNameFrame, 1)
	for _, fn in ipairs({ "QuestFrameGreetingPanel_OnShow", "QuestInfo_ShowRewards", "QuestFrameProgressItems_Update" }) do
		if type(_G[fn]) == "function" then ns.HookOnce(nil, fn, function() Refill(f, QuestText) end, KEY) end
	end
	if type(_G.QuestInfoItem_OnClick) == "function" then
		ns.HookOnce(nil, "QuestInfoItem_OnClick", function() Refill(f, PaintPicks) end, KEY)
	end
	if type(_G.QuestInfo_Display) == "function" then
		ns.HookOnce(nil, "QuestInfo_Display", function(_, parent)
			if ns.Kit and Usable(parent) and not InQuestWindows(parent) then Guard(QuestTextBack, ns.Kit) end
		end, KEY)
	end
	if Controls() then ns.Walk(Kit, f, nil, function() QuestText(Kit) end) end
	QuestText(Kit)
end, function(_, Kit) QuestText(Kit) end)

-- ---------------------------------------------------------------------------------------------
-- The vendor
-- MerchantFrame (ButtonFrameTemplate; BuybackBG, MerchantFrameBottomLeftBorder, MerchantPageText),
-- MerchantItem1..12 (MerchantItemTemplate: SlotTexture, NameFrame, Name, ItemButton, a money and
-- an alternate currency frame) and MerchantBuyBackItem, the repair / junk buttons (an icon on
-- slot art), MerchantPrevPageButton / MerchantNextPageButton (their PREV / NEXT words),
-- MerchantFrameTab1..2 (PanelTabButtonTemplate), FilterDropdown (WowStyle1), the money and extra
-- currency insets with their ThinGoldEdge boxes, MerchantToken1..n (made when a vendor takes
-- other currencies). Every page and tab is refilled by MerchantFrame_Update; the tokens by
-- MerchantFrame_UpdateCurrencies.
-- ---------------------------------------------------------------------------------------------

local MERCHANT_SLOTS = 12
local MERCHANT_ICONS = { "MerchantSellAllJunkButton", "MerchantRepairAllButton", "MerchantRepairItemButton",
	"MerchantGuildBankRepairButton" }

local function MerchantSlot(Kit, item)
	if not Usable(item) then return end
	if Once(item) then
		Kit.Strip(item)
		local name = item:GetName()
		if name and IsTexture(_G[name .. "NameFrame"]) then Kit.Hide(_G[name .. "NameFrame"]) end
		Kit.Item(item.ItemButton)
		Font(Kit, item.Name)
	end
	Kit.InkGameText(item)
end

local function MerchantFill(Kit)
	for i = 1, MERCHANT_SLOTS do MerchantSlot(Kit, _G["MerchantItem" .. i]) end
	MerchantSlot(Kit, _G.MerchantBuyBackItem)
	if Kind(_G.MerchantPageText) == "FontString" then Kit.InkGameText(_G.MerchantFrame) end
	for i = 1, 6 do
		local token = _G["MerchantToken" .. i]
		if Usable(token) and Once(token) then ns.Words(token, 1) end
	end
end

Fallback(Named("MerchantFrame"), VendorOwned, function(f, Kit)
	Kit.Window(f)
	for _, n in ipairs({ "MerchantExtraCurrencyBg", "MerchantMoneyBg" }) do
		if Usable(_G[n]) then Kit.Strip(_G[n]) end
	end
	for _, n in ipairs({ "MerchantExtraCurrencyInset", "MerchantMoneyInset" }) do
		if Usable(_G[n]) then Kit.Inset(_G[n]) end
	end
	if Controls() then
		for _, n in ipairs(MERCHANT_ICONS) do
			if Usable(_G[n]) then IconSlot(Kit, _G[n]) end
		end
		if Usable(_G.MerchantPrevPageButton) then Kit.PageButton(_G.MerchantPrevPageButton, "left") end
		if Usable(_G.MerchantNextPageButton) then Kit.PageButton(_G.MerchantNextPageButton, "right") end
	end
	Font(Kit, _G.MerchantPageText)
	MerchantFill(Kit)
	for _, fn in ipairs({ "MerchantFrame_Update", "MerchantFrame_UpdateCurrencies" }) do
		if type(_G[fn]) == "function" then ns.HookOnce(nil, fn, function() Refill(f, MerchantFill) end, KEY) end
	end
	if Controls() then ns.Walk(Kit, f, nil, function() MerchantFill(Kit) end) end
end, function(_, Kit) MerchantFill(Kit) end)

-- ---------------------------------------------------------------------------------------------
-- The trainer (Blizzard_TrainerUI, loaded on demand)
-- ClassTrainerFrame (ButtonFrameTemplate; MoneyBg, BG), ClassTrainerStatusBar (its Left / Right /
-- Middle / Background art, rankText), FilterDropdown (WowStyle1Filter, its ResetButton badge),
-- TrainButton (MagicButtonTemplate), money, trainingPoints, skillStepButton and the ScrollBox of
-- TrainerUICategoryTemplate headers (LeftPiece / CenterPiece / RightPiece, CollapseIcon, Label)
-- and ClassTrainerSkillButtonTemplate rows (icon, name, subText, money, selectedTex, lock,
-- disabledBG), bottomInset. The game's text colors stay: they say what you can learn.
-- ClassTrainerFrame_InitServiceButton shows or hides a row's selection art, so rows repaint
-- after it.
-- ---------------------------------------------------------------------------------------------

local function TrainerRow(Kit, r)
	if not Usable(r) or not Controls() then return end
	if IsTexture(r.icon) then
		local keep = { [r.icon] = true }
		if IsTexture(r.lock) then keep[r.lock] = true end
		Kit.Row(r, keep, r.selectedTex)
		if Once(r.icon) then r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
		Font(Kit, r.name)
		Font(Kit, r.subText)
	elseif Kind(r.Label) == "FontString" then
		local keep = {}
		if IsTexture(r.CollapseIcon) then keep[r.CollapseIcon] = true end
		if IsTexture(r.CollapseIconAlphaAdd) then keep[r.CollapseIconAlphaAdd] = true end
		Kit.Row(r, keep, nil, false)
		Font(Kit, r.Label)
		Kit.Light(r.Label, Kit.HEADER)
	end
end

local function TrainerBadge(Kit, f)
	local dd = f.FilterDropdown
	if Usable(dd) and Usable(dd.ResetButton) and Controls() then Kit.ResetBadge(dd.ResetButton) end
end

Fallback(Named("ClassTrainerFrame"), function() return TrainerOwned() or TrainerSkin() end, function(f, Kit)
	Kit.Window(f)
	if Usable(f.bottomInset) then Kit.Inset(f.bottomInset) end
	if Controls() then
		if Kind(_G.ClassTrainerStatusBar) == "StatusBar" then Kit.StatusBar(_G.ClassTrainerStatusBar) end
		TrainerBadge(Kit, f)
		TrainerRow(Kit, f.skillStepButton)
		Kit.EachRow(f.ScrollBox, function(r) TrainerRow(Kit, r) end, "AddonSkinsTrainer")
		if type(_G.ClassTrainerFrame_InitServiceButton) == "function" then
			ns.HookOnce(nil, "ClassTrainerFrame_InitServiceButton", function(b) Kit.RepaintRow(b) end, KEY)
		end
		ns.Walk(Kit, f, { rows = false })
	end
end)

-- Lent by DaylightUI's NPC window for Beast Training (or, from DaylightUI 1.8.4, the game's trainer
-- picked over DaylightUI's): DaylightUI's Window Skins dress the window, all but the filter's
-- reset badge.
Fallback(Named("ClassTrainerFrame"), function() return not (TrainerOwned() or TrainerSkin()) end, function(f, Kit)
	TrainerBadge(Kit, f)
end)

-- ---------------------------------------------------------------------------------------------
-- The mailbox (Blizzard_MailFrame)
-- MailFrame (ButtonFrameTemplate, trialError, MailFrameTab1..2), InboxFrame (InboxFrameBg,
-- InboxCurrentPage, MailItem1..7 of MailItemTemplate: border art, Sender, Subject, ExpireTime, a
-- Button with Icon / IconBorder / Count; PrevPageButton / NextPageButton, OpenAllMail,
-- InboxTooMuchMail), SendMailFrame (its bars, SendMailScrollFrame with the stationery and
-- SendMailBodyEditBox, SendMailNameEditBox / SendMailSubjectEditBox (three-piece boxes),
-- SendMailAttachment1..16, SendMailMoney (MoneyInputFrame), the two radio buttons, cost and
-- money frames, its ThinGoldEdge box and inset, Cancel / Send), OpenMailFrame (ButtonFrameTemplate:
-- sender, subject, OpenMailScrollFrame with the stationery and OpenMailBodyText (SimpleHTML),
-- the invoice and crafting order texts and money frames, OpenMailLetterButton,
-- OpenMailAttachmentButton1..16, OpenMailMoneyButton, Reply / Delete / Close / Report spam).
-- InboxFrame:Update refills the inbox, SendMailFrame_Update the send page, OpenMailFrame:Update
-- the open letter.
-- ---------------------------------------------------------------------------------------------

local function InboxFill(Kit)
	for i = 1, 7 do
		local item = _G["MailItem" .. i]
		if Usable(item) then
			if Once(item) then
				Kit.Strip(item)
				if Usable(item.Button) then Kit.Item(item.Button) end
				local name = item:GetName()
				Font(Kit, _G[name .. "Sender"])
				Font(Kit, _G[name .. "Subject"])
			end
			Kit.InkGameText(item)
		end
	end
	local inbox = _G.InboxFrame
	if Usable(inbox) then Kit.InkGameText(inbox) end
end

local function SendFill(Kit)
	local body = _G.SendMailBodyEditBox
	if Kind(body) == "EditBox" then
		local c = Kit.TEXT
		body:SetTextColor(c[1], c[2], c[3])
	end
	for _, n in ipairs({ "SendStationeryBackgroundLeft", "SendStationeryBackgroundRight" }) do
		if IsTexture(_G[n]) then Kit.Hide(_G[n]) end
	end
	Kit.InkGameText(_G.SendMailFrame)
end

Fallback(Named("MailFrame"), MailOwned, function(f, Kit)
	Kit.Window(f)
	local inbox = _G.InboxFrame
	if Usable(inbox) then
		Kit.Strip(inbox)
		if Controls() then
			if Usable(inbox.PrevPageButton) then Kit.PageButton(inbox.PrevPageButton, "left") end
			if Usable(inbox.NextPageButton) then Kit.PageButton(inbox.NextPageButton, "right") end
		end
		if type(inbox.Update) == "function" then
			ns.HookOnce(inbox, "Update", function() Refill(f, InboxFill) end, KEY)
		end
	end
	local send = _G.SendMailFrame
	if Usable(send) then
		Kit.Strip(send, IsTexture(_G.SendMailErrorCoin) and { [_G.SendMailErrorCoin] = true } or nil)
		if Usable(_G.SendMailScrollFrame) then Kit.Inset(_G.SendMailScrollFrame) end
		if Usable(_G.SendMailMoneyBg) then Kit.Strip(_G.SendMailMoneyBg) end
		if Usable(_G.SendMailMoneyInset) then Kit.Inset(_G.SendMailMoneyInset) end
		if type(_G.SendMailFrame_Update) == "function" then
			ns.HookOnce(nil, "SendMailFrame_Update", function() Refill(f, SendFill) end, KEY)
		end
		Font(Kit, _G.SendMailBodyEditBox)
	end
	InboxFill(Kit)
	SendFill(Kit)
	if Controls() then ns.Walk(Kit, f, nil, function() InboxFill(Kit) SendFill(Kit) end) end
end, function(_, Kit) InboxFill(Kit) SendFill(Kit) end)

-- The open letter: written for stationery, so its words (the letter, an invoice, a crafting order
-- note) are lit and the paper is faded out. The letter's HTML box takes a new color only as its
-- text is set, so the game's own text is set again after the color.
local function LetterFill(Kit)
	local of = _G.OpenMailFrame
	if not Usable(of) then return end
	for _, n in ipairs({ "OpenStationeryBackgroundLeft", "OpenStationeryBackgroundRight" }) do
		if IsTexture(_G[n]) then Kit.Hide(_G[n]) end
	end
	local html = _G.OpenMailBodyText
	local inbox = _G.InboxFrame
	if Kind(html) == "SimpleHTML" and Usable(inbox) and type(_G.GetInboxText) == "function" then
		local c = Kit.TEXT
		html:SetTextColor(c[1], c[2], c[3])
		local id = inbox.openMailID
		if id then
			local ok, text = pcall(_G.GetInboxText, id)
			if ok and type(text) == "string" and not Secret(text) then html:SetText(text, true) end
		end
	end
	Parch(Kit, of, 4)
end

Fallback(Named("OpenMailFrame"), MailOwned, function(f, Kit)
	Kit.Window(f)
	if Usable(_G.OpenMailScrollFrame) then Kit.Inset(_G.OpenMailScrollFrame) end
	if type(f.Update) == "function" then
		ns.HookOnce(f, "Update", function() Refill(f, LetterFill) end, KEY)
	end
	LetterFill(Kit)
	if Controls() then ns.Walk(Kit, f, nil, function() LetterFill(Kit) end) end
end, function(_, Kit) LetterFill(Kit) end)

-- ---------------------------------------------------------------------------------------------
-- The social window (Blizzard_SocialUI) while DaylightUI's Social window is off
-- SocialUIFrame (PortraitFrameTemplate: TopFade / BottomFade, BattleNetBar with its Background and
-- ControlsContainer (OnlineStatusDropdown WowStyle1, BattleNetMenuButton, PersonalBattleTagDisplay,
-- BattleNetBackground), the side windows IgnoreListFrame (ButtonFrameTemplate), BattleNetBroadcastFrame
-- / BattleNetUnavailableNoticeFrame (dialog borders), the raid info side window, and the content
-- frames made for each tab (friends, recent allies, quick join, requests, Recruit-A-Friend, raid).
-- Its tabs (SocialUITabTemplate: LargeSideTabButtonTemplate) come from socialTabPool, made again
-- in RefreshTabs; SetChecked shows a tab's SelectedTexture. The walk follows every page shown.
-- ---------------------------------------------------------------------------------------------

-- A raid info window, the old one (RaidInfoFrame) or the social window's side window
-- (SocialUIRaidInfoFrameTemplate: TopInset / BottomInset rock art and their edges, the INSTANCE /
-- LOCK_EXPIRE labels, Border, CloseButton, ScrollBox of SocialUIRaidInfoContentFrameTemplate rows
-- (name, difficulty, reset, extended), ScrollBar, ExtendButton): the shell, its words in
-- DaylightUI's inks, the rows as lines.
local raidRows = setmetatable({}, { __mode = "k" })
RaidInfo = function(Kit, f)
	SubWindow(Kit, f)
	if Usable(f.Header) then ns.Words(f.Header, 1) end
	if Usable(f.CloseButton) then Kit.Close(f.CloseButton) end
	ns.Words(f, 0)
	if Usable(f.ScrollBox) and not raidRows[f] then
		raidRows[f] = true
		Kit.EachRow(f.ScrollBox, function(r)
			if Kind(r) == "Button" then
				LineRow(Kit, r)
				ns.Words(r, 0)
			end
		end, "AddonSkinsRaidInfo")
	end
end

local SOCIAL_SIDE = { "IgnoreListFrame", "BattleNetBroadcastFrame", "BattleNetUnavailableNoticeFrame", "RaidInfoFrame" }

local function SocialParts(Kit, f)
	local pool = f.socialTabPool
	if type(pool) == "table" and type(pool.EnumerateActive) == "function" then
		for tab in pool:EnumerateActive() do IconTab(Kit, tab, SelectedShown, true) end
	end
	for _, k in ipairs(SOCIAL_SIDE) do
		if Usable(f[k]) then
			if k == "RaidInfoFrame" then RaidInfo(Kit, f[k]) else SubWindow(Kit, f[k]) end
		end
	end
end

Fallback(Named("SocialUIFrame"), SocialOwned, function(f, Kit)
	Kit.Window(f)
	local bar = f.BattleNetBar
	local skip = {}
	if Usable(bar) then
		Kit.Strip(bar)
		local cc = bar.ControlsContainer
		if Usable(cc) then
			Kit.Strip(cc)
			if Usable(cc.BattleNetMenuButton) then
				skip[cc.BattleNetMenuButton] = true
				if Controls() then Kit.IconButton(cc.BattleNetMenuButton, 2) end
			end
		end
	end
	SocialParts(Kit, f)
	if type(f.RefreshTabs) == "function" then
		ns.HookOnce(f, "RefreshTabs", function() Refill(f, function(K) SocialParts(K, f) ns.SideTilesPaintSoon() end) end, KEY)
	end
	if Controls() then ns.Walk(Kit, f, { skip = skip }, function() SocialParts(Kit, f) end) end
end)

-- ---------------------------------------------------------------------------------------------
-- The friends window the game falls back on when its social window is switched off
-- (Blizzard_FriendsFrame, Camelot): FriendsFrame (ButtonFrameTemplate, FriendsFrameTab1 / 3 / 4
-- (PanelTabButtonTemplate), FriendsTabHeader.TabSystem (TabSystemButtonTemplate), BattlenetFrame
-- (ContactsMenuButton, BroadcastFrame with its dialog border, UnavailableInfoFrame),
-- StatusDropdown (WowStyle1)), FriendsListFrame (ScrollBox of FriendsListButtonTemplate rows:
-- background, status, gameIcon, Favorite, travelPassButton, summonButton; headers, dividers and
-- invites; the add friend / send message buttons, RIDWarning), RecentAlliesFrame (its list),
-- IgnoreListWindow (ButtonFrameTemplate, ScrollBox of IgnoreListButtonTemplate rows and headers,
-- the remove button), the raid tab (RaidFrame from Blizzard_RaidFrame, claimed into this window),
-- FriendsTooltip. This client has no Who list.
-- ---------------------------------------------------------------------------------------------

local function FriendRow(Kit, row)
	if Kind(row) ~= "Button" then return end
	if IsTexture(row.status) then
		local keep = { [row.status] = true }
		if IsTexture(row.gameIcon) then keep[row.gameIcon] = true end
		if IsTexture(row.Favorite) then keep[row.Favorite] = true end
		LineRow(Kit, row, keep)
		Font(Kit, row.name)
		Font(Kit, row.info)
	elseif Kind(row.name) == "FontString" then
		LineRow(Kit, row)
		Font(Kit, row.name)
	end
end

local function FriendsTip(Kit)
	local tip = _G.FriendsTooltip
	if not Once(tip) then return end
	if Usable(tip.NineSlice) then Kit.Hide(tip.NineSlice) end
	Kit.Backdrop(tip)
	Kit.Shell(tip, "window", { quiet = true })
end

Fallback(Named("FriendsFrame"), nil, function(f, Kit)
	Kit.Window(f)
	local skip = {}
	local bn = f.BattlenetFrame
	if Usable(bn) then
		Kit.Strip(bn)
		if Usable(bn.ContactsMenuButton) then
			skip[bn.ContactsMenuButton] = true
			if Controls() then Kit.IconButton(bn.ContactsMenuButton, 2) end
		end
		if Usable(bn.BroadcastFrame) then SubWindow(Kit, bn.BroadcastFrame) end
		if Usable(bn.UnavailableInfoFrame) then SubWindow(Kit, bn.UnavailableInfoFrame) end
	end
	local list = _G.FriendsListFrame
	if Usable(list) then Kit.EachRow(list.ScrollBox, function(r) FriendRow(Kit, r) end, "AddonSkinsFriends") end
	local ignore = f.IgnoreListWindow
	if Usable(ignore) then
		SubWindow(Kit, ignore)
		Kit.EachRow(ignore.ScrollBox, function(r) FriendRow(Kit, r) end, "AddonSkinsIgnore")
	end
	FriendsTip(Kit)
	if Controls() then ns.Walk(Kit, f, { skip = skip }) end
end)

-- The raid info window (RaidInfoFrame: Border (DialogBorderDark), Header (DialogHeader),
-- RaidInfoInstanceLabel / RaidInfoIDLabel headers, RaidInfoCloseButton, ScrollBox of
-- RaidInfoInstanceTemplate rows, Extend / Close buttons), opened from the raid tab.
Fallback(Named("RaidInfoFrame"), nil, function(f, Kit)
	RaidInfo(Kit, f)
	if Usable(_G.RaidInfoCloseButton) then Kit.Close(_G.RaidInfoCloseButton) end
	for _, n in ipairs({ "RaidInfoInstanceLabel", "RaidInfoIDLabel" }) do
		if Usable(_G[n]) then
			Kit.Strip(_G[n])
			ns.Words(_G[n], 1)
		end
	end
	if Controls() then ns.Walk(Kit, f, { rows = false }) end
end)

-- RaidParentFrame (ButtonFrameTemplate with its Raid / Looking for Raid tabs), where the game shows
-- the raid list on its own.
Fallback(Named("RaidParentFrame"), nil, function(f, Kit)
	Kit.Window(f)
	if Controls() then ns.Walk(Kit, f) end
end)

-- ---------------------------------------------------------------------------------------------
-- Bags while DaylightUI's Bags module is off
-- ContainerFrame1..7 (ContainerFrameTemplate on PortraitFrameFlatTemplate: Background1Slot, the
-- bag's portrait and its PortraitButton (the bag menu, kept), FilterIcon; ContainerFrame1 also
-- MoneyFrame (ContainerMoneyFrameTemplate with its Border), BagItemSearchBox, BagItemAutoSortButton)
-- and ContainerFrameCombinedBags (the same plus CountContainer, SearchBoxIcon). Item buttons
-- (ContainerFrameItemButtonTemplate) come from each bag's itemButtonPool in UpdateItemSlots, on
-- every open: each is dressed as it comes (the item's quality outline follows the game's border).
-- ---------------------------------------------------------------------------------------------

local bagWaiting = setmetatable({}, { __mode = "k" })   -- bag -> waiting for the fight to end

local function BagItems(Kit, f)
	if type(f.Items) ~= "table" then return end
	for _, b in ipairs(f.Items) do
		if Usable(b) then Kit.Item(b) end
	end
end

local function Bag(Kit, f)
	Kit.Window(f)
	-- The bag's own picture (its portrait, the bag menu's face) stays.
	if Usable(f.PortraitContainer) then f.PortraitContainer:SetAlpha(1) end
	local skip = {}
	if Usable(f.PortraitButton) then skip[f.PortraitButton] = true end
	if Usable(f.MoneyFrame) and Usable(f.MoneyFrame.Border) then Kit.Strip(f.MoneyFrame.Border) end
	BagItems(Kit, f)
	if type(f.UpdateItemSlots) == "function" then
		ns.HookOnce(f, "UpdateItemSlots", function(self)
			if not On() or not ns.Kit or not live[self] then return end
			if InCombatLockdown() then
				-- (One wait per bag, however many times it refills in the fight.)
				if not bagWaiting[self] then
					bagWaiting[self] = true
					ns.OutOfCombat(function() bagWaiting[self] = nil BagItems(ns.Kit, self) end)
				end
			else
				BagItems(ns.Kit, self)
			end
		end, KEY)
	end
	if Controls() then
		if f == _G.ContainerFrame1 and Usable(_G.BagItemAutoSortButton) and Once(_G.BagItemAutoSortButton) then
			Kit.ArtButton(_G.BagItemAutoSortButton, 2)
		end
		ns.Walk(Kit, f, { rows = false, skip = skip })
	end
end

for i = 1, 7 do
	Fallback(Named("ContainerFrame" .. i), BagsOwned, Bag, function(f, Kit) BagItems(Kit, f) end)
end
Fallback(Named("ContainerFrameCombinedBags"), BagsOwned, Bag, function(f, Kit) BagItems(Kit, f) end)

-- ---------------------------------------------------------------------------------------------
-- The bank while DaylightUI's Bags module is off
-- BankFrame (BankFrameTemplate on PortraitFrameTemplate, its TabSystem (Character / Account), BagCost
-- and BagText, the bag slot buttons (BankItemButtonBagTemplate)) and BankPanel (BankPanelTemplate:
-- the tab buttons from bankTabPool (BankPanelTabTemplate: Border, Icon, SelectedTexture), the item
-- buttons from itemButtonPool, made again by GenerateItemSlotsForSelectedTab, its search box,
-- auto-sort and deposit buttons, money frame (ThinGoldEdge border) with withdraw / deposit, the
-- include-reagents checkbox, the edge shadows and the lock / purchase prompts, and the tab
-- settings menu with its checkboxes and expansion dropdown).
-- ---------------------------------------------------------------------------------------------

local BANK_ART = { "LeftTopCorner-Shadow", "TopLeftInner" }   -- a shadow frame, a prompt's frame art

local function BankTabPicked(tab)
	if type(tab.IsSelected) ~= "function" then return SelectedShown(tab) end
	local ok, on = pcall(tab.IsSelected, tab)
	return ok and on == true
end

local function BankParts(Kit, f)
	-- The page tabs down the bank's right side (this client's: BankPageTabTemplate, a
	-- LargeSideTabButtonTemplate filled to its inside with a picture, from bankPageTabPool, made
	-- again in RefreshPageTabs; SetChecked shows the current page's SelectedTexture).
	local pages = f.bankPageTabPool
	if type(pages) == "table" and type(pages.EnumerateActive) == "function" then
		for tab in pages:EnumerateActive() do IconTab(Kit, tab, SelectedShown) end
	end
	local panel = f.BankPanel
	if not Usable(panel) then
		ns.SideTilesPaintSoon()
		return
	end
	local pool = panel.bankTabPool
	if type(pool) == "table" and type(pool.EnumerateActive) == "function" then
		for tab in pool:EnumerateActive() do IconTab(Kit, tab, BankTabPicked) end
	end
	if type(panel.EnumerateValidItems) == "function" then
		local ok, it, state, start = pcall(panel.EnumerateValidItems, panel)
		if ok and type(it) == "function" then
			-- (A pool's active set: the buttons are its keys.)
			for b in it, state, start do
				if Usable(b) then Kit.Item(b) end
			end
		end
	end
	ns.SideTilesPaintSoon()
end

local function BankEach(Kit, frame)
	for _, k in ipairs(BANK_ART) do
		if IsTexture(frame[k]) and Once(frame) then
			Kit.Strip(frame)
			return
		end
	end
	if Usable(frame.Border) and Kind(frame.MoneyDisplay) == "Frame" and Once(frame.Border) then Kit.Strip(frame.Border) end
end

Fallback(Named("BankFrame"), BagsOwned, function(f, Kit)
	Kit.Window(f)
	local panel = f.BankPanel
	if Usable(panel) then
		for _, fn in ipairs({ "GenerateItemSlotsForSelectedTab", "RefreshBankTabs", "SelectTab" }) do
			if type(panel[fn]) == "function" then
				ns.HookOnce(panel, fn, function() Refill(f, function(K) BankParts(K, f) end) end, KEY)
			end
		end
	end
	if type(f.RefreshPageTabs) == "function" then
		ns.HookOnce(f, "RefreshPageTabs", function() Refill(f, function(K) BankParts(K, f) end) end, KEY)
	end
	BankParts(Kit, f)
	if Controls() then
		ns.Walk(Kit, f, nil, function() BankParts(Kit, f) end, function(frame) BankEach(Kit, frame) end)
	end
end, function(f, Kit) BankParts(Kit, f) end)

-- ---------------------------------------------------------------------------------------------
-- The quest tracker while DaylightUI's tracker doesn't replace it
-- ObjectiveTrackerFrame (ObjectiveTrackerContainerTemplate: NineSlice (Edit Mode's background,
-- kept), Header (ObjectiveTrackerContainerHeaderTemplate: Background, Text, MinimizeButton,
-- FilterButton)) and its modules (ObjectiveTrackerFrame.modules; each a Header of
-- ObjectiveTrackerModuleHeaderTemplate: Background, Text, MinimizeButton). A header's SetCollapsed
-- swaps its button's art: the chevron turns with it.
-- ---------------------------------------------------------------------------------------------

local function Collapsed(owner)
	if not Usable(owner) or type(owner.IsCollapsed) ~= "function" then return false end
	local ok, c = pcall(owner.IsCollapsed, owner)
	return ok and c == true
end

local function TrackerHeader(Kit, header)
	if not Usable(header) or not Once(header) then return end
	if IsTexture(header.Background) then Kit.Hide(header.Background) end
	if Kind(header.Text) == "FontString" then
		Font(Kit, header.Text)
		Kit.Light(header.Text, ns.Colors().VALUE)
	end
	local btn = header.MinimizeButton
	if Usable(btn) and Controls() then
		local chevron = Kit.BareButton(btn, "down")
		if IsTexture(chevron) then
			local function turn(collapsed) chevron:SetRotation(collapsed and Kit.ROTATION.right or Kit.ROTATION.down) end
			turn(Collapsed(header:GetParent()))
			if type(header.SetCollapsed) == "function" then
				ns.HookOnce(header, "SetCollapsed", function(_, collapsed) turn(collapsed == true) end, KEY)
			end
		end
	end
end

local function TrackerHeaders(Kit, f)
	TrackerHeader(Kit, f.Header)
	if type(f.modules) == "table" then
		for _, m in ipairs(f.modules) do
			if Usable(m) then TrackerHeader(Kit, m.Header) end
		end
	end
end

Fallback(Named("ObjectiveTrackerFrame"), TrackerOwned, function(f, Kit)
	TrackerHeaders(Kit, f)
	-- Modules are added as the tracker sets itself up and as content appears (a scenario, a
	-- tracked recipe): looked over after each update, out of combat (each header once).
	if type(f.Update) == "function" then
		ns.HookOnce(f, "Update", function() Refill(f, function(K) TrackerHeaders(K, f) end) end, KEY)
	end
end, function(f, Kit) TrackerHeaders(Kit, f) end)

-- ---------------------------------------------------------------------------------------------
-- When: at login (every window that's there), and as Blizzard addons load (the trainer loads on
-- demand). Nothing here loads one.
-- ---------------------------------------------------------------------------------------------

ns.me.On("Login", function() Guard(HookAll) end)

local loads = CreateFrame("Frame")
loads:RegisterEvent("ADDON_LOADED")
loads:SetScript("OnEvent", function(self, _, name)
	if not ns.loggedIn then return end
	if type(name) ~= "string" or string.sub(name, 1, 9) ~= "Blizzard_" then return end
	Guard(HookAll)
	if left == 0 then self:UnregisterEvent("ADDON_LOADED") end
end)
