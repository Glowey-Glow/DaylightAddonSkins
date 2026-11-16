-- Game windows, part three: the rarely seen ones. Same rules as Blizzard.lua (whose helpers and
-- entry list this uses, through ns.Blizz): built against the client's own interface code
-- (wow-ui-source, branch "forever"; Mainline plus the Camelot overrides), looks only, post-hooks
-- only, nothing protected called, no field of the game's written, and every entry dressed by
-- Blizzard.lua's passes (at login and as each Blizzard addon loads, out of combat). Most of these
-- are shown from the game's own event code, often in a fight, so they're dressed ahead of time and
-- quietly: shells with no script on them, no hook on a control inside them, only the mouse hooked
-- on an X.
--   External defensives (ExternalDefensivesFrame, with the game's "External defensives" option on):
--     its five aura buttons' icons squared off in an outline, the time left in the player's font
--     (its gold / white warning colors kept). DaylightUI's Buffs hide only the buff and debuff
--     frames. (On zhTW the game sets the time's font object again on every update: there it
--     keeps the game's font.)
--   The new-player tutorials: the instruction banners (TutorialMainFrame_Frame, the one- and
--     two-key prompts, the walk prompt), the keyboard and mouse intro with its Okay / Skip buttons,
--     their key caps as DaylightUI keys; the pointer boxes (TutorialPointerFrame_n, made as the
--     tutorial needs them) as windows, their arrows and pulsing glow in the accent, their words in
--     the player's font before the game sizes the box round them.
--   The status widgets at the top of the screen and under the minimap (battleground score bars,
--     progress and timer bars, the two-sided resource bars): the bars' gold frames off, a
--     DaylightUI bar edge round each, their glows in the accent. The fills, faction icons, a
--     bar's colored ground (a texture kit's own), the plate behind a bar's title and every color
--     that means something stay; so do the widgets' words (the game sets their font again on
--     every update) and the capture bar (its frame is cut to its own zone marks).
--   The subscription offer (SubscriptionInterstitialFrame): the window shell and X; its
--     artwork, the offer itself, stays.
--   Voice chat toasts (VoiceChatPromptActivateChannel, VoiceChatChannelActivatedNotification):
--     they go through AlertFrame_ShowNewAlert, so Blizzard.lua's toast pass gives them their box;
--     here only the X, the Join button and the player's font. The icon and the channel's color
--     stay.
--   The GM chat window (GMChatFrame, GMChatTab): one window shell round the tab and the
--     messages, the tab's title, X, scroll bar and the reply box.
--   Behavior notices (BehavioralMessagingTray's notices, BehavioralMessagingDetails): the notices'
--     stacked boxes and the details window in the window look; the watermark stays.
--   The game's own damage meter (DamageMeter's session windows and their breakdown), only while
--     DaylightUI's meter is off (which switches the game's off): window chrome only. The bars are
--     the game's: their numbers can be secret in a fight.
--   The auction house's posting bar (AuctionHouseMultisellProgressFrame, without DaylightMogul).
--   The world map's coordinates (WorldMapCoordsPanelTemplate) in the player's font, a size
--     smaller where a row would cut it off.
-- Left alone: HelpTip's pooled tips (see Blizzard.lua: shown from inside action button updates),
-- the script errors window and Edit Mode.
local _, ns = ...
if not ns.ok then return end
local B = ns.Blizz
if not B then return end

local Usable, Guard = ns.Usable, ns.Guard
local ipairs, pairs, type = ipairs, pairs, type
local KEY = B.KEY
local Entry, Kind, IsTexture, FontOf = B.Entry, B.Kind, B.IsTexture, B.FontOf
local QUIET = B.QUIET

local dressed = setmetatable({}, { __mode = "k" })   -- parts of ours already done

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end

local ICON_PAD, ICON_CROP = 2, 0.08

-- A picture in the accent (an arrow, a glow): gray first, so the tint reads as the accent.
local function Tint(tex)
	if not IsTexture(tex) then return end
	tex:SetDesaturated(true)
	ns.PaintAccent(tex, 1, nil, KEY)
end

-- Every texture a frame holds itself, in the accent.
local function TintAll(frame)
	if not Usable(frame) then return end
	for _, r in ipairs({ frame:GetRegions() }) do Tint(r) end
end

-- One fight's worth of passes, run once when it ends.
local function AfterCombat(flags, key, fn)
	if flags[key] then return end
	flags[key] = true
	ns.OutOfCombat(function()
		flags[key] = false
		Guard(fn)
	end)
end
local waits = {}

-- External defensives --------------------------------------------------------------------------
-- Blizzard_BuffFrame: ExternalDefensivesFrame (BaseAuraFrameTemplate, maxAuras 5) makes its
-- AuraButtonTemplate buttons at load (auraFrames): Icon (BACKGROUND), Duration
-- (GameFontNormalSmall, tinted gold / white by the game as time runs low), Count (the game's
-- number font, kept), DebuffBorder / TempEnchantBorder (shown for debuffs and enchants only).
-- The game updates them on every aura change, in a fight too: the crop and outline are set once
-- (SetTexture keeps the crop) and nothing is hooked.

Entry("ExternalDefensivesFrame", function(f, Kit)
	local list = f.auraFrames
	if type(list) ~= "table" then return end
	for _, b in ipairs(list) do
		local icon = Usable(b) and b.Icon
		if IsTexture(icon) and not dressed[b] then
			dressed[b] = true
			icon:SetTexCoord(ICON_CROP, 1 - ICON_CROP, ICON_CROP, 1 - ICON_CROP)
			-- (A frame of ours under the icon, no script on it.)
			Kit.Outline(icon, ICON_PAD, "outline", nil, QUIET)
			FontOf(Kit, b.Duration)
		end
	end
end)

-- New-player tutorials ---------------------------------------------------------------------------
-- Blizzard_TutorialManager (TutorialMainFrame.xml): TutorialMainFrame_Frame, TutorialSingleKey_Frame
-- and TutorialDoubleKey_Frame, ResizeLayoutFrames whose OnLoad lays the "NewPlayerTutorial" nine
-- slice on the frame itself; ContainerFrame holds Icon (kept), Text (GameFontNormalHuge2 in
-- TUTORIAL_FONT_COLOR), Separator, KeyBind / KeyBind1 / KeyBind2 (KeyBindingTemplate: the
-- KeyIcon key cap, KeyBind in black). Camelot's Blizzard_NewPlayerExperience
-- (TutorialKeyboardMouseFrame.xml): TutorialKeyboardMouseFrame_Frame (the Keyboard picture kept,
-- Text, ConfirmButton and SkipTutorialButton: UIPanelButtonTemplate, the skip prompt on the
-- latter) and TutorialWalk_Frame (four key caps). All shown and faded by the tutorial's own
-- event code: dressed ahead of time, quietly.
-- TutorialPointerFrame (TutorialPointerFrame.xml): made as needed (TutorialPointerFrame_1..n,
-- from :Show), pooled; Content (GlowBoxTemplate, Text), Glow (a pulsing callout backdrop),
-- Arrow_UP1 .. Arrow_RIGHT2 (Tutorial_Pointer* frames: the arrow and its ADD glow). A pointer can
-- be anchored to an action button, which shows it from its own OnShow: nothing of ours on it but
-- art, dressed right after the game's :Show (a post-hook on the pointer manager, out of combat).
-- :Show sizes Content from its Text right after _GetFrame: the player's font goes on the Text in
-- a post-hook on _GetFrame (a font only, so in a fight too), before the game measures it.

local TUTORIAL_KEYS = { "KeyBind", "KeyBind1", "KeyBind2", "MOVEFORWARD", "STRAFELEFT", "MOVEBACKWARD", "STRAFERIGHT" }
local TUTORIAL_TEXT = { "Text", "Separator" }

local function KeyCap(Kit, k)
	if not Usable(k) or dressed[k] then return end
	dressed[k] = true
	if IsTexture(k.KeyIcon) then Kit.Hide(k.KeyIcon) end
	-- (Lite: four edges and a ground on the key's own frame, no script.)
	Kit.Shell(k, "control")
	if Kind(k.KeyBind) == "FontString" then
		FontOf(Kit, k.KeyBind)
		Kit.Light(k.KeyBind, ns.Colors().VALUE)
	end
end

local function Lit(Kit, fs)
	if Kind(fs) ~= "FontString" then return end
	FontOf(Kit, fs)
	Kit.Light(fs)
end

local function TutorialBox(Kit, f, keepKey)
	local keep
	if keepKey and IsTexture(f[keepKey]) then keep = { [f[keepKey]] = true } end
	-- (The window shell with nothing hooked: the frame's own nine slice stripped.)
	B.ShellWindow(Kit, f, keep)
	local c = Usable(f.ContainerFrame) and f.ContainerFrame or f
	for _, k in ipairs(TUTORIAL_TEXT) do
		Lit(Kit, c[k])
		Lit(Kit, f[k])
	end
	for _, k in ipairs(TUTORIAL_KEYS) do KeyCap(Kit, c[k]) end
	local skip = f.SkipTutorialButton
	if Usable(skip) then Lit(Kit, skip.SkipTutorialPrompt) end
	if Controls() then
		B.StaticButton(Kit, f.ConfirmButton)
		B.StaticButton(Kit, skip)
	end
end

local function PointerFrame(Kit, f)
	if not Usable(f) or dressed[f] then return end
	dressed[f] = true
	local box = f.Content
	if Usable(box) then
		-- (GlowBoxTemplate: the same art Blizzard.lua takes off the help plates.)
		B.GlowBox(Kit, box)
		Lit(Kit, box.Text)
	end
	local glow = f.Glow
	if Usable(glow) then
		for _, k in ipairs(Kit.BACKDROP or {}) do Tint(glow[k]) end
	end
	for _, dir in ipairs({ "UP", "DOWN", "LEFT", "RIGHT" }) do
		for i = 1, 2 do TintAll(f["Arrow_" .. dir .. i]) end
	end
end

local function Pointers()
	local Kit, P = ns.Kit, _G.TutorialPointerFrame
	if not Kit or not On() or type(P) ~= "table" then return end
	local n = tonumber(P.FrameCount) or 0
	for i = 1, n do PointerFrame(Kit, _G["TutorialPointerFrame_" .. i]) end
end

for _, name in ipairs({ "TutorialMainFrame_Frame", "TutorialSingleKey_Frame", "TutorialDoubleKey_Frame", "TutorialWalk_Frame" }) do
	Entry(name, function(f, Kit) TutorialBox(Kit, f) end)
end
Entry("TutorialKeyboardMouseFrame_Frame", function(f, Kit) TutorialBox(Kit, f, "Keyboard") end)

-- (Hooked with the main frame: both are Blizzard_TutorialManager's.)
Entry("TutorialMainFrame_Frame", function()
	local P = _G.TutorialPointerFrame
	if type(P) ~= "table" or type(P.Show) ~= "function" then return end
	if type(P._GetFrame) == "function" then
		hooksecurefunc(P, "_GetFrame", function(_, parent)
			local Kit = ns.Kit
			local f = Kit and On() and type(parent) == "table" and parent.currentNPEPointer
			local box = Usable(f) and f.Content
			if Usable(box) then FontOf(Kit, box.Text) end
		end)
	end
	hooksecurefunc(P, "Show", function()
		if not On() then return end
		if InCombatLockdown() then
			AfterCombat(waits, "pointers", Pointers)
		else
			Guard(Pointers)
		end
	end)
	Pointers()
end)

-- Status widgets ---------------------------------------------------------------------------------
-- Blizzard_UIWidgets: UIWidgetTopCenterContainerFrame and UIWidgetBelowMinimapContainerFrame
-- (UIWidgetContainerTemplate) acquire their widget frames from pools in ProcessWidget, run the
-- widget's Setup, then lay them out on their next frame. Dressed after ProcessWidget (a post-hook
-- on each of the two containers; out of combat, else once the fight ends), art only and only on
-- the bars (StatusBars of the widget's own, never a layout frame: the widget system lays out the
-- widget frames by their children and regions).
--   UIWidgetTemplateStatusBar: Bar (BGLeft / BGRight / BGCenter, BorderLeft / BorderRight /
--     BorderCenter, BackgroundGlow, GlowLeft / GlowRight / GlowCenter pulsed by GlowPulseAnim,
--     Spark tinted by the bar's color, the fill per texture kit, Label), LabelBG and
--     LabelBGDivider behind the title. SetupTextureKitOnRegions shows / hides and sets the atlas
--     on each Setup; neither touches the alpha set here.
--   UIWidgetTemplateDoubleStatusBar: LeftBar / RightBar (BG, BorderLeft / BorderRight /
--     BorderCenter, Spark, Icon (the side's emblem, kept), IconGlow, SparkGlow, BorderGlow flashed
--     by the Flash animation).

-- The gold frame (always off) and the ground (BGLeft / BGRight / BGCenter, BackgroundGlow: the
-- texture kit's own, "%s-bgcenter-%s", which can be a color that means something): off only on
-- the plain "white" kit, set again after each Setup (a pooled bar can come back with another kit).
-- The double bars' BG is their kit's (%s-bar-background): kept. The title's plate (LabelBG,
-- LabelBGDivider) stays, so the title reads over the world.
local SINGLE_ART = { "BorderLeft", "BorderRight", "BorderCenter" }
local SINGLE_GROUND = { "BGLeft", "BGRight", "BGCenter", "BackgroundGlow" }
local SINGLE_GLOW = { "GlowLeft", "GlowRight", "GlowCenter" }
local DOUBLE_ART = { "BorderLeft", "BorderRight", "BorderCenter" }
local DOUBLE_GLOW = { "BorderGlow" }
local PLAIN_KIT = "white"

local function WidgetBar(Kit, bar, art, glows)
	if Kind(bar) ~= "StatusBar" or dressed[bar] then return end
	dressed[bar] = true
	for _, k in ipairs(art) do
		if IsTexture(bar[k]) then Kit.Hide(bar[k]) end
	end
	for _, k in ipairs(glows) do Tint(bar[k]) end
	-- (Lite: four edges and a ground on the bar itself, under its fill's edge, no script.)
	Kit.Shell(bar, "bar")
end

-- A single bar's ground: off on the plain kit, the game's on any other.
local function Ground(w, bar)
	local kit = w.textureKit
	local alpha = (kit == nil or kit == PLAIN_KIT) and 0 or 1
	for i = 1, #SINGLE_GROUND do
		local t = bar[SINGLE_GROUND[i]]
		if IsTexture(t) then t:SetAlpha(alpha) end
	end
end

local function Side(Kit, side)
	if Usable(side) and Kind(side) == "StatusBar" and IsTexture(side.BG) and IsTexture(side.BorderCenter) then
		WidgetBar(Kit, side, DOUBLE_ART, DOUBLE_GLOW)
	end
end

-- widget -> its single bar (or false: none), once looked over (a pool's frames keep their template).
local widgets = setmetatable({}, { __mode = "k" })

local function Widget(Kit, w)
	if not Usable(w) then return end
	local single = widgets[w]
	if single == nil then
		local bar = w.Bar
		single = Usable(bar) and IsTexture(bar.BorderCenter) and IsTexture(bar.BGCenter) and bar or false
		widgets[w] = single
		if single then WidgetBar(Kit, single, SINGLE_ART, SINGLE_GLOW) end
		Side(Kit, w.LeftBar)
		Side(Kit, w.RightBar)
	end
	if single then Ground(w, single) end
end

local CONTAINERS = { "UIWidgetTopCenterContainerFrame", "UIWidgetBelowMinimapContainerFrame" }

local function WidgetPass()
	local Kit = ns.Kit
	if not Kit or not On() then return end
	for _, name in ipairs(CONTAINERS) do
		local c = _G[name]
		local frames = Usable(c) and c.widgetFrames
		if type(frames) == "table" then
			for _, w in pairs(frames) do Guard(Widget, Kit, w) end
		end
	end
end

for _, name in ipairs(CONTAINERS) do
	Entry(name, function(c)
		if type(c.ProcessWidget) ~= "function" then return end
		hooksecurefunc(c, "ProcessWidget", function(self, id)
			if not On() or not ns.Kit then return end
			if InCombatLockdown() then
				AfterCombat(waits, "widgets", WidgetPass)
				return
			end
			local frames = self.widgetFrames
			local w = type(frames) == "table" and frames[id]
			if w then Guard(Widget, ns.Kit, w) end
		end)
		WidgetPass()
	end)
end

-- Subscription offer -----------------------------------------------------------------------------
-- Blizzard_SubscriptionInterstitialUI (and its Camelot file): SubscriptionInterstitialFrame
-- (DefaultPanelTemplate; Camelot hides its Bg, TopTileStreaks, Inset and ClosePanelButton),
-- CloseButton, SubscribeButton / UpgradeButton (the offer's artwork, its words and bullets: the
-- game's content, kept), the upgrade's insideFrame border (a frame Camelot makes in the window).
-- Opened by the game's event through ShowUIPanel: quiet.

Entry("SubscriptionInterstitialFrame", function(f, Kit)
	-- (Camelot hides the Inset for good: no shade of ours for it.)
	B.ShellWindow(Kit, f, nil, true)
	Kit.Close(f.CloseButton)
	local up = f.UpgradeButton
	if Usable(up) and IsTexture(up.insideFrame) then Kit.Hide(up.insideFrame) end
	if Controls() then B.StaticButton(Kit, f.ClosePanelButton) end
end)

-- Voice chat toasts -----------------------------------------------------------------------------
-- Blizzard_Channels (VoiceChatPrompt.xml, on SocialToastTemplate: a BackdropTemplate toast with
-- $parentGlowFrame and a close button): VoiceChatPromptActivateChannel (Icon, Text, AcceptButton)
-- and VoiceChatChannelActivatedNotification (Icon, Text, Text2). Shown by ChatAlertFrame from the
-- game's voice events, through AlertFrame_ShowNewAlert (VoiceChatPrompt.lua), so Blizzard.lua's
-- toast pass already erases their art (the glow too) and draws their box: here only what that
-- pass leaves, quietly. The words carry the channel's color as an escape code: kept.

local function VoiceToast(Kit, f)
	if dressed[f] then return end
	dressed[f] = true
	FontOf(Kit, f.Text)
	FontOf(Kit, f.Text2)
	Kit.Close(f.CloseButton)
	if Controls() then B.StaticButton(Kit, f.AcceptButton) end
end

Entry("VoiceChatPromptActivateChannel", function(f, Kit) VoiceToast(Kit, f) end)
Entry("VoiceChatChannelActivatedNotification", function(f, Kit) VoiceToast(Kit, f) end)

-- GM chat ---------------------------------------------------------------------------------------
-- Blizzard_GMChatUI: GMChatFrame (FloatingChatFrameTemplate: the CHAT_FRAME_TEXTURES pieces, its
-- buttonFrame, ScrollBar (MinimalScrollBar), ScrollToBottomButton and ResizeButton kept; the
-- $parentTopLeft / TopRight / Top / Left / Right thin border round it and its tab), GMChatTab (two
-- textures named GMChatTabBG, NubL / NubR, the Blizzard icon kept, GMChatTabText),
-- GMChatFrameCloseButton, GMChatFrameEditBox (ChatFrameEditBoxTemplate: $parentLeft / Right / Mid
-- and the focus pieces). DaylightUI's Chat dresses only the windows in CHAT_FRAMES, and this one
-- isn't. The messages keep the chat font; the reply box keeps it too (nothing hooked on it:
-- it's a chat box).

local GM_BORDER = { "TopLeft", "TopRight", "Top", "Left", "Right" }
local CHAT_INPUT_ART = { "Left", "Right", "Mid", "FocusLeft", "FocusRight", "FocusMid" }

Entry("GMChatFrame", function(f, Kit)
	if dressed[f] then return end
	dressed[f] = true
	local name = f:GetName() or "GMChatFrame"
	for _, s in ipairs(_G.CHAT_FRAME_TEXTURES or {}) do
		if IsTexture(_G[name .. s]) then Kit.Hide(_G[name .. s]) end
	end
	for _, s in ipairs(GM_BORDER) do
		if IsTexture(_G[name .. s]) then Kit.Hide(_G[name .. s]) end
	end
	-- One window shell round the tab and the messages, on a frame of ours under them.
	local tab = _G.GMChatTab
	local box = CreateFrame("Frame", nil, f)
	box:SetPoint("TOPLEFT", Usable(tab) and tab or f, "TOPLEFT", 0, 0)
	box:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 4, -4)
	box:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
	box:EnableMouse(false)
	Kit.Shell(box, "window", QUIET)
	if Usable(tab) then
		local icon = _G.GMChatTabIcon
		Kit.Strip(tab, IsTexture(icon) and { [icon] = true } or nil)
		local title = _G.GMChatTabText
		if Kind(title) == "FontString" then
			FontOf(Kit, title)
			Kit.Light(title, ns.Colors().VALUE)
		end
	end
	Kit.Close(_G.GMChatFrameCloseButton)
	local eb = _G.GMChatFrameEditBox or f.editBox
	if Kind(eb) == "EditBox" then
		local ebName = eb:GetName()
		for _, k in ipairs(CHAT_INPUT_ART) do
			if ebName and IsTexture(_G[ebName .. k]) then Kit.Hide(_G[ebName .. k]) end
		end
		for _, k in ipairs({ "focusLeft", "focusRight", "focusMid" }) do
			if IsTexture(eb[k]) then Kit.Hide(eb[k]) end
		end
		Kit.Shell(eb, "input")
	end
	if Controls() and Usable(f.ScrollBar) then Kit.ScrollBar(f.ScrollBar) end
end)

-- Behavior notices --------------------------------------------------------------------------------
-- Blizzard_BehavioralMessaging: BehavioralMessagingTray (HorizontalLayoutFrame) holds pooled
-- BehaviorMessagingNotificationTemplate buttons (TitleText gold, SubtitleText, Icon kept), each
-- with one or two stacked BehaviorMessagingBackgroundTemplate boxes (TooltipBackdropTemplate,
-- pooled, made again as the count changes). The tray is laid out in EvaluateLayout after every
-- notice: dressed after it (a post-hook on the tray, out of combat). BehavioralMessagingDetails
-- (Border with the "Dialog" nine slice, TopInset / BottomInset rock and their metal edges, a dark
-- ground, Text, Body (TitleText, BodyText, the Blizzard watermark kept), CloseButton
-- (UIPanelButtonTemplate)): opened with ShowUIPanel from a notice's click.

local function Notices()
	local Kit, tray = ns.Kit, _G.BehavioralMessagingTray
	if not Kit or not On() or not Usable(tray) then return end
	for _, n in ipairs({ tray:GetChildren() }) do
		if Usable(n) then
			for _, box in ipairs({ n:GetChildren() }) do
				if Usable(box) and Usable(box.NineSlice) then B.TipPanel(Kit, box) end
			end
		end
	end
end

-- A notice's words, in the player's font before the game measures them: after its Init (a
-- post-hook on the mixin, which the pool's later buttons are made from), the PushInstance that
-- follows sizes the button round them. A font and a color only, so in a fight too.
local function NoticeWords(n)
	local Kit = ns.Kit
	if not Kit or not On() or not Usable(n) or Kind(n.TitleText) ~= "FontString" then return end
	FontOf(Kit, n.TitleText)
	Kit.Light(n.TitleText, ns.Colors().VALUE)
	FontOf(Kit, n.SubtitleText)
end

Entry("BehavioralMessagingTray", function(tray)
	local mixin = _G.BehavioralMessagingNotificationMixin
	if type(mixin) == "table" and type(mixin.Init) == "function" then
		hooksecurefunc(mixin, "Init", function(n) Guard(NoticeWords, n) end)
	end
	-- (Notices made before this: their words now.)
	for _, n in ipairs({ tray:GetChildren() }) do NoticeWords(n) end
	if type(tray.EvaluateLayout) == "function" then
		hooksecurefunc(tray, "EvaluateLayout", function()
			if not On() then return end
			if InCombatLockdown() then
				AfterCombat(waits, "notices", Notices)
			else
				Guard(Notices)
			end
		end)
	end
	Notices()
end)

Entry("BehavioralMessagingDetails", function(f, Kit)
	B.Quiet(Kit, f)
	local value = ns.Colors().VALUE
	local title = f.Text
	if Kind(title) == "FontString" then
		Kit.Light(title, value)
		Kit.Title(f, title)
	end
	local body = f.Body
	if Usable(body) and Kind(body.TitleText) == "FontString" then Kit.Light(body.TitleText, value) end
end)

-- The game's damage meter -------------------------------------------------------------------------
-- Blizzard_DamageMeter: DamageMeter (an Edit Mode system) makes its session windows in
-- SetupSessionWindow (DamageMeterSessionWindow1..n: Header bar, SessionTimer, MinimizeButton,
-- SettingsDropdown, SessionDropdown (SessionName, kept: the dropdown is 18 / 32 px wide),
-- DamageMeterTypeDropdown (TypeName), and
-- MinimizeContainer, hidden while minimized: Background (its alpha is the player's background
-- opacity, kept), NotActive, the entries' ScrollBox, ScrollBar, ResizeButton, SourceWindow (the
-- breakdown: Background, CloseButton)). Only while DaylightUI's own meter is off: with it on,
-- DaylightUI switches the game's meter off. Chrome only and nothing hooked on the window but its
-- SetMinimized (after it): the entries are the game's bars, refreshed through a fight with
-- numbers that can be secret, and stay as they are; so do the dropdowns (the meter's settings).

local MAX_METERS = 10

local function MeterStrip(w)
	local m = dressed[w]
	local box = w.MinimizeContainer
	if type(m) == "table" and Usable(box) then m:SetShown(not box:IsShown()) end
end

local function MeterWindow(Kit, w)
	if not Usable(w) or dressed[w] then return end
	local box = w.MinimizeContainer
	if not Usable(box) then return end
	if IsTexture(w.Header) then Kit.Hide(w.Header) end
	-- The open window: a window shell on its container (hidden with it), the game's own background
	-- (and its opacity setting) kept under it.
	Kit.Shell(box, "window", { quiet = true, noBackground = true })
	-- Minimized: only the header row shows, in a shell of its own.
	local strip = CreateFrame("Frame", nil, w)
	strip:SetPoint("TOPLEFT", w, "TOPLEFT", 0, 0)
	strip:SetPoint("TOPRIGHT", w, "TOPRIGHT", 0, 0)
	strip:SetHeight(IsTexture(w.Header) and w.Header:GetHeight() or 32)
	strip:SetFrameLevel(math.max(0, w:GetFrameLevel() - 1))
	strip:EnableMouse(false)
	Kit.Shell(strip, "window", QUIET)
	dressed[w] = strip
	MeterStrip(w)
	if type(w.SetMinimized) == "function" then
		hooksecurefunc(w, "SetMinimized", function(self) Guard(MeterStrip, self) end)
	end
	B.Words(Kit, w, 0)
	-- (The session dropdown is 18 or 32 px wide: its SessionName keeps the game's narrower font.)
	local dd = w.DamageMeterTypeDropdown
	if Usable(dd) then FontOf(Kit, dd.TypeName) end
	FontOf(Kit, box.NotActive)
	local src = box.SourceWindow
	if Usable(src) and not dressed[src] then
		dressed[src] = true
		if IsTexture(src.Background) then Kit.Hide(src.Background) end
		Kit.Shell(src, "window", QUIET)
		Kit.Close(src.CloseButton)
	end
end

local function Meters()
	local Kit = ns.Kit
	if not Kit or not On() then return end
	for i = 1, MAX_METERS do MeterWindow(Kit, _G["DamageMeterSessionWindow" .. i]) end
end

Entry("DamageMeter", function(f)
	if ns.DaylightHas("InfoPanel", "meter.enabled") then return end
	-- (New windows: from the meter's settings, a click.)
	if type(f.SetupSessionWindow) == "function" then
		hooksecurefunc(f, "SetupSessionWindow", function()
			if not On() then return end
			if InCombatLockdown() then
				AfterCombat(waits, "meters", Meters)
			else
				Guard(Meters)
			end
		end)
	end
	Meters()
end)

-- Auction house posting bar (without DaylightMogul) --------------------------------------------
-- Blizzard_AuctionHouseUI (Blizzard_AuctionHouseMultisell.xml): AuctionHouseMultisellProgressFrame
-- (a bottom managed frame: Fill, Left / Middle / Right end caps), ProgressBar
-- (CastingBarFrameBaseTemplate with its scripts emptied: Border, TextBorder, Background, glows,
-- Icon (the item, kept), Text), CancelButton (the red X art). Shown while several auctions post.

local function MogulLoaded()
	local api = _G.C_AddOns
	return api ~= nil and type(api.IsAddOnLoaded) == "function" and api.IsAddOnLoaded("DaylightMogul") == true
end

Entry("AuctionHouseMultisellProgressFrame", function(f, Kit)
	if MogulLoaded() then return end
	B.ShellWindow(Kit, f)
	local bar = f.ProgressBar
	if Kind(bar) == "StatusBar" then
		local icon = bar.Icon
		Kit.StatusBar(bar)
		bar:SetStatusBarColor(ns.AccentOf(KEY))
		if IsTexture(icon) then
			-- (Kit.StatusBar fades every texture of the bar's but its fill: the item's icon back.)
			icon:SetAlpha(1)
			icon:SetTexCoord(ICON_CROP, 1 - ICON_CROP, ICON_CROP, 1 - ICON_CROP)
			Kit.Outline(icon, ICON_PAD, "outline", nil, QUIET)
		end
	end
	Kit.Close(f.CancelButton)
end)

-- World map coordinates -------------------------------------------------------------------------
-- Blizzard_WorldMapTemplates.xml (WorldMapCoordsPanelTemplate, added as an overlay frame by
-- WorldMapMixin:AddOverlayFrames): CursorCoords, CrosshairCoords and PlayerCoords, each a Label
-- in GameFontHighlightSmall; the game only sets their text. DaylightUI's world map skin passes
-- them over. The rows are 100 x 15: a label the player's font would cut off goes down a size
-- (looked at as the map opens, after the game's first update has set the words; through the
-- game's EventRegistry event, apart from the map's own code).

local COORD_ROWS = { "CursorCoords", "CrosshairCoords", "PlayerCoords" }
local COORD_MIN = 8
local coordPanel
local coordOwner = {}

local function FitCoords()
	if not Usable(coordPanel) or not On() then return end
	for _, k in ipairs(COORD_ROWS) do
		local row = coordPanel[k]
		local fs = Usable(row) and row.Label
		if Kind(fs) == "FontString" and fs.IsTruncated then
			for _ = 1, 4 do
				if not fs:IsTruncated() then break end
				local file, size, flags = fs:GetFont()
				if type(size) ~= "number" or size <= COORD_MIN then break end
				fs:SetFont(file, size - 1, flags)
			end
		end
	end
end

Entry(function()
	local map = _G.WorldMapFrame
	local list = Usable(map) and map.overlayFrames
	if type(list) ~= "table" then return nil end
	for _, o in ipairs(list) do
		if Usable(o) and Usable(o.CursorCoords) and Usable(o.PlayerCoords) then return o end
	end
end, function(p, Kit)
	coordPanel = p
	for _, k in ipairs(COORD_ROWS) do
		local row = p[k]
		if Usable(row) then FontOf(Kit, row.Label) end
	end
	local reg = _G.EventRegistry
	if type(reg) == "table" and type(reg.RegisterCallback) == "function" then
		reg:RegisterCallback("WorldMapOnShow", function()
			C_Timer.After(0.1, function() Guard(FitCoords) end)
		end, coordOwner)
	end
	FitCoords()
end, "worldmap")
