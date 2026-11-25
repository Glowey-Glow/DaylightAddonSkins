-- Spoken: the welcome window, the contribute dialogs, Azeroth's Compendium, the two narrator
-- windows (Large and Small, the Small one's menu rows lit in the accent), the Places panel beside
-- the world map and its side tab, its text buttons on the game's quest, gossip and book
-- windows (Listen / Stop, Contribute, Play), and its subtitles (a solid plate behind the words
-- in place of its soft shade, the speaker's row in DaylightUI's inks), and under the controller UI
-- its question dialog and the Compendium's filter menu. Left alone: the
-- DialogueUI-style narrator (drawn in DialogueUI's art on purpose), the minimap button, the
-- Compendium's and the Places panel's parchment pages and list rows (dark ink on paper, redrawn on
-- every render), and the settings pages, which sit inside the game's own Settings window.
local _, ns = ...
if not ns.ok then return end

local KEY = "Spoken"

local function Env(name)
	local env = _G.SpokenEnv
	if type(env) ~= "table" then return nil end
	local value = rawget(env, name)
	return type(value) == "table" and value or nil
end

local function Templated(frame, Kit)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	ns.Guard(Kit.Window, frame)
	if ns.Controls(KEY) then ns.Guard(Kit.Auto, frame, { rows = false }) end
end

-- Large Window: its box art is drawn again on every refresh, but only the texture, never the alpha.
local function Large()
	local player = Env("PlayerFrame")
	local frame = player and player.frame
	if not ns.Usable(frame) or not ns.Enabled(KEY) then return end
	if ns.Usable(frame.background) then frame.background:SetAlpha(0) end
	if ns.Once(frame) then ns.Shell(frame, { window = true }, KEY) end
end

-- A text of Spoken's in one of DaylightUI's inks, with the shadow light words need.
local function Ink(fs, color)
	if not ns.Usable(fs) or type(color) ~= "table" or type(fs.SetTextColor) ~= "function" then return end
	fs:SetTextColor(color[1], color[2], color[3])
	if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 1) end
end

-- Small Window: DaylightUI's shell whichever background Spoken is set to. Its Parchment setting
-- is dark ink on paper, and a paper page inside the dark shell was the hardest thing of Spoken's
-- to read: the paper is put away there too, and the words Spoken has just written in ink
-- (MinimalPlayer:Dress, its "parchment" look) are written light again, as its own Dark setting
-- writes them. Its captions take their color through its own Transcript:SetStyle, the call its
-- looks use. Run after each Dress, so a refresh of Spoken's never leaves ink on the shell.
local function Small()
	local mini = Env("MinimalPlayer")
	local panel = mini and mini.panel
	if not ns.Usable(panel) then return end
	if not ns.Enabled(KEY) then
		-- (Switched off after it was dressed: Spoken's paper back; its next Dress inks the words.)
		if ns.Usable(mini.paper) then mini.paper:SetAlpha(1) end
		return
	end
	local addon = Env("Addon")
	local frameSettings = addon and addon.db and addon.db.profile and addon.db.profile.Frame
	local dark = type(frameSettings) == "table" and frameSettings.MinimalBackground == "dark"
	if ns.Once(panel) then
		ns.NoBackdrop(panel)
		ns.Shell(panel, { window = true }, KEY)
	end
	if ns.Usable(mini.paper) then mini.paper:SetAlpha(0) end
	if not dark then
		local c = ns.Colors()
		Ink(mini.name, c.TITLE)
		Ink(type(mini.title) == "table" and mini.title.text or nil, c.LABEL)
		for _, k in ipairs({ "stopped", "count", "held" }) do Ink(mini[k], c.LABEL) end
		local transcript = Env("Transcript")
		if transcript and type(transcript.SetStyle) == "function" and type(c.TEXT) == "table" then
			ns.Guard(transcript.SetStyle, transcript, { color = { c.TEXT[1], c.TEXT[2], c.TEXT[3] } })
		end
	end
	local menu = mini.menu
	if ns.Usable(menu) and ns.Once(menu) then
		ns.NoBackdrop(menu)
		ns.Shell(menu, nil, KEY)
	end
end

-- The Small Window's menu: its rows (made as the menu opens) gold, lit in yellow; DaylightUI's text
-- color, lit in the accent. Painted on every open, so a change of the accent shows the next time.
local function MenuRows(mini)
	local menu = mini and mini.menu
	if not ns.Usable(menu) or not ns.Enabled(KEY) then return end
	local c = ns.Colors().VALUE
	for _, row in ipairs({ menu:GetChildren() }) do
		if ns.Usable(row.text) and row.GetHighlightTexture then
			local hl = row:GetHighlightTexture()
			if ns.Usable(hl) then
				hl:SetAlpha(1)
				ns.FillAccent(hl, 0.2, nil, KEY)
			end
			if type(c) == "table" then row.text:SetTextColor(c[1], c[2], c[3]) end
		end
	end
end

-- Subtitles: white words over the world on a soft, see-through shade that fades to nothing at
-- its edges, with the speaker's title and the small labels in mid gray. Behind them now a flat
-- dark plate with a hairline rim, as solid as Spoken's own Subtitle Shadow setting asks and then
-- some (its 60% is 80% here, its 100% solid; at 0 there is no plate, as there was no shade), so
-- the words have the same ground under every letter. The plate is two textures on Spoken's own
-- frame, sized to its shade (which it fits to the words), so nothing of its layout is touched;
-- its shade is only made see-through, which it undoes itself on its next Update when the pack
-- is off. The speaker's row: DaylightUI's title ink for the name, its label ink for the rest.
local plates = setmetatable({}, { __mode = "k" })
local function Subtitles(sub)
	local frame, shade = sub and sub.frame, sub and sub.shadow
	if not ns.Usable(frame) or not ns.Usable(shade) then return end
	local plate = plates[frame]
	if not ns.Enabled(KEY) then
		if plate then
			plate.fill:Hide()
			plate.rim:Hide()
		end
		return
	end
	if not plate then
		plate = {}
		plate.rim = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
		plate.rim:SetPoint("TOPLEFT", shade, "TOPLEFT", -1, 1)
		plate.rim:SetPoint("BOTTOMRIGHT", shade, "BOTTOMRIGHT", 1, -1)
		plate.rim:SetColorTexture(1, 1, 1, 1)
		plate.fill = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
		plate.fill:SetAllPoints(shade)
		plate.fill:SetColorTexture(0.04, 0.04, 0.05, 1)
		plates[frame] = plate
	end
	-- (How dark Spoken's Subtitle Shadow setting asks for, read where it keeps it: its profile's
	-- Transcript.SubtitleShadow, 0.5 when unset as in its own Update. Its shade is put away.)
	local addon = Env("Addon")
	local t = addon and addon.db and addon.db.profile and addon.db.profile.Transcript
	local asked = type(t) == "table" and tonumber(t.SubtitleShadow) or 0.5
	shade:SetAlpha(0)
	local on = asked > 0.01
	plate.fill:SetShown(on)
	plate.rim:SetShown(on)
	if on then
		plate.fill:SetAlpha(0.5 + 0.5 * math.min(1, asked))
		plate.rim:SetAlpha(0.12)
	end
	local c = ns.Colors()
	if type(c.TITLE) == "table" and ns.Usable(sub.title) then sub.title:SetTextColor(c.TITLE[1], c.TITLE[2], c.TITLE[3]) end
	if type(c.LABEL) == "table" then
		-- (3.12: also why a line is held and how many wait, "· (Waiting for combat to end.)" "· +2",
		-- in the same mid gray.)
		for _, k in ipairs({ "dot", "label", "pausedLabel", "heldDot", "held", "moreDot", "more" }) do
			if ns.Usable(sub[k]) then sub[k]:SetTextColor(c.LABEL[1], c.LABEL[2], c.LABEL[3]) end
		end
	end
end

-- Under the controller UI (3.12) Spoken asks its questions in a dialog of its own in place of the
-- game's popup (SpokenLayoutPrompt: the game's dark dialog ground under its diamond-cornered
-- border, a tooltip-edged box to type a name in, two red text buttons). DaylightUI's window here,
-- the box and buttons in its look. Made on its first question (Layout.Ask / Layout.Confirm), shown
-- in the same call.
local function Prompt(frame, Kit)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	for _, region in ipairs({ frame:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			ns.Kill(region)
		end
	end
	ns.Shell(frame, { window = true }, KEY)
	Kit.InkGameText(frame)
	-- (The box is no template the walk knows: its tooltip edge off, DaylightUI's box on. The
	-- buttons are the walk's.)
	if ns.Controls(KEY) then
		for _, child in ipairs({ frame:GetChildren() }) do
			if ns.Usable(child) and child:GetObjectType() == "EditBox" and ns.Once(child) then
				ns.NoBackdrop(child)
				ns.Guard(Kit.EditBox, child)
			end
		end
	end
	ns.Dress(frame, nil, 0, KEY)
end

local function PromptNow()
	local Kit = ns.Kit
	local frame = _G.SpokenLayoutPrompt
	if Kit and ns.Enabled(KEY) and ns.Usable(frame) then ns.Guard(Prompt, frame, Kit) end
end

-- The Compendium's filter under the controller UI (3.12, SpokenCompendiumWindowFilterPad): a menu
-- of Spoken's own drawn as the game's (its dropdown ground, check boxes and yellow ticks, the quest
-- log's highlight), made on its first opening. DaylightUI's menu look, as the game's menus have it
-- here: its shell, no empty box, the tick in the accent, the hover a wash in the accent (its white
-- words kept). Spoken draws each row's tick again on every click, and lays the rows out
-- again on every opening, before it shows it: dressed on each show and after each click. (Its
-- opener is Spoken's own to itself: the menu is found by its watch on its first opening.)
local function FilterRows(frame, Kit)
	if not ns.Usable(frame) or not ns.Enabled(KEY) then return end
	if type(frame.rows) == "table" then
		for _, row in ipairs(frame.rows) do
			if ns.Usable(row) then
				if ns.Controls(KEY) then
					if ns.Usable(row.mark) then row.mark:SetAlpha(0) end
					if ns.Usable(row.tick) then
						row.tick:SetDesaturated(true)
						ns.PaintAccent(row.tick, 1, nil, KEY)
					end
					local hover = row.GetHighlightTexture and row:GetHighlightTexture()
					if ns.Usable(hover) then
						ns.FillAccent(hover, 0.18, nil, KEY)
						hover:SetBlendMode("BLEND")
					end
					ns.ScriptOnce(row, "OnClick", function() ns.Guard(FilterRows, frame, Kit) end, KEY)
				end
				Kit.InkGameText(row)
			end
		end
	end
	ns.Dress(frame, nil, 0, KEY)
end

local function FilterPad(frame, Kit)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	for _, region in ipairs({ frame:GetRegions() }) do
		if ns.Usable(region) and region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then
			ns.Kill(region)
		end
	end
	ns.Shell(frame, nil, KEY)
	ns.ScriptOnce(frame, "OnShow", function() ns.Guard(FilterRows, frame, Kit) end, KEY)
	FilterRows(frame, Kit)
end

-- The Places panel beside the world map: the game's flat panel (or, on a client without it, a
-- dialog box) on DaylightUI's shell, its quest-log rim round the page hidden; the page is
-- parchment and stays. It shows and hides with the map, so no fade and no closing ghost.
local function PlacesPanel(frame, Kit)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	if frame.templated then
		if type(Kit.GHOST) == "table" then Kit.GHOST[frame:GetName() or ""] = true end
		ns.Guard(Kit.Window, frame, { ownFade = true })
	else
		ns.NoBackdrop(frame)
		ns.Shell(frame, { window = true }, KEY)
	end
	if ns.Usable(frame.rim) then frame.rim:SetAlpha(0) end
	if ns.Controls(KEY) and ns.Usable(frame.close) and ns.Once(frame.close) then ns.Guard(Kit.Close, frame.close) end
end

-- Its side tab on the map's edge (the game's large side tab): a tile; it only ever opens, so it is
-- never shown picked. (The round button of a client without that template is left as it is.)
local function NeverPicked() return false end
local function PlacesToggle(tab, Kit)
	if not ns.Usable(tab) or not ns.Controls(KEY) or not ns.Usable(tab.Icon) or not ns.Once(tab) then return end
	for _, k in ipairs({ "Background", "Border", "SelectedTexture" }) do
		if ns.Usable(tab[k]) then Kit.Hide(tab[k]) end
	end
	for _, k in ipairs({ "HighlightTexture", "TabGlow" }) do
		if ns.Usable(tab[k]) then Kit.Erase(tab[k]) end
	end
	if tab.GetHighlightTexture and ns.Usable(tab:GetHighlightTexture()) then Kit.Hide(tab:GetHighlightTexture()) end
	if not ns.SideTile(tab, { picked = NeverPicked, key = KEY, pad = 2 }) then return end
	-- (The game fits its icon again on SetChecked: the tile's crop back after it.)
	if type(tab.SetChecked) == "function" then
		ns.HookOnce(tab, "SetChecked", function(self)
			if ns.Usable(self.Icon) then self.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
			ns.SideTilePaint(self)
		end, KEY)
	end
end

-- Its red text buttons: Listen / Stop and Contribute (Spoken_Quests, on the game's quest and gossip
-- windows, made once as it starts) and Play on the book window (Spoken_Readables).
local function TextButton(button, Kit)
	if ns.Usable(button) and ns.Controls(KEY) then ns.Guard(Kit.Button, button) end
end

local function QuestsButton(name)
	return function()
		local vo = _G.VoiceOver
		local part = type(vo) == "table" and rawget(vo, name)
		return type(part) == "table" and part.button or nil
	end
end

local function BookButton()
	local readables = _G.SpokenReadables
	return type(readables) == "table" and readables.playButton or nil
end

ns.Pack("Spoken", "Spoken", function(Kit)
	local player, mini = Env("PlayerFrame"), Env("MinimalPlayer")
	if not player then return false end

	if type(player.RefreshConfig) == "function" then
		ns.HookOnce(player, "RefreshConfig", function() ns.Guard(Large) end, KEY)
	end
	if mini and type(mini.RefreshConfig) == "function" then
		ns.HookOnce(mini, "RefreshConfig", function() ns.Guard(Small) end, KEY)
	end
	-- (Its Dress writes the words in the background's own colors: ours after each one.)
	if mini and type(mini.Dress) == "function" then
		ns.HookOnce(mini, "Dress", function() ns.Guard(Small) end, KEY)
	end
	-- (Subtitles: its Update sets the shade on every line and setting change.)
	local sub = Env("Subtitle")
	if sub and type(sub.Update) == "function" then
		ns.HookOnce(sub, "Update", function(self) ns.Guard(Subtitles, self) end, KEY)
	end
	if mini and type(mini.ToggleMenu) == "function" then
		ns.HookOnce(mini, "ToggleMenu", function(self) ns.Guard(MenuRows, self) end, KEY)
	end
	ns.Watch(KEY, "SpokenPlayerFrame", function() Large() end)
	ns.Watch(KEY, "SpokenMinimalPlayerFrame", function() Small() end)

	ns.Watch(KEY, "SpokenWelcomeFrame", Templated)
	ns.Watch(KEY, "SpokenContributeBox", function(frame) ns.PlainWindow(frame) end)
	ns.Watch(KEY, "SpokenGatheredLines", function(frame) ns.PlainWindow(frame) end)
	ns.Watch(KEY, "SpokenMinimapMenu", function(frame) ns.PlainWindow(frame) end)
	-- (3.13.0: the profile Export / Import window, made on its first use; Import shows it from a
	-- local function, so it's watched for, not hooked.)
	ns.Watch(KEY, "SpokenProfileTransfer", function(frame) ns.PlainWindow(frame) end)

	-- (Its controller dialog: looked for right after the calls that make and show it, so it's
	-- dressed before it's drawn. Only ever made there: no watch, which a player without the
	-- controller UI would keep waiting on.)
	local layout = _G.SpokenLayout
	if type(layout) == "table" then
		for _, method in ipairs({ "Ask", "Confirm" }) do
			if type(layout[method]) == "function" then ns.HookOnce(layout, method, PromptNow, KEY) end
		end
	end

	ns.Watch(KEY, "SpokenPlacesPanel", PlacesPanel)
	ns.Watch(KEY, "SpokenPlacesPanelToggle", PlacesToggle)
	ns.Watch(KEY, QuestsButton("DialogPlayButton"), TextButton)
	ns.Watch(KEY, QuestsButton("ContributeButton"), TextButton)
	ns.Watch(KEY, BookButton, TextButton)

	ns.Watch(KEY, "SpokenCompendiumWindow", function(frame)
		if not ns.Usable(frame) or not ns.Once(frame) then return end
		if frame.templated then
			ns.Guard(Kit.Window, frame)
		else
			ns.NoBackdrop(frame)
			ns.Shell(frame, { window = true }, KEY)
			if ns.Usable(frame.CloseButton) and ns.Controls(KEY) and ns.Once(frame.CloseButton) then ns.Guard(Kit.Close, frame.CloseButton) end
		end
		-- Tabs and each part's list (search box, inset, filter) are made as parts are opened.
		local function parts()
			for i = 1, 12 do
				local tab = _G["SpokenCompendiumWindowTab" .. i]
				if not tab then break end
				if ns.Controls(KEY) and ns.Once(tab) then ns.Guard(Kit.Tab, tab) end
			end
			if ns.Controls(KEY) then ns.Guard(Kit.Auto, frame, { rows = false, shownOnly = true }) end
		end
		local queued
		local function later()
			if queued then return end
			queued = true
			C_Timer.After(0.05, function() queued = nil if frame:IsShown() then parts() end end)
		end
		ns.ScriptOnce(frame, "OnShow", later, KEY)
		local compendium = _G.SpokenCompendium
		if type(compendium) == "table" and type(compendium.Select) == "function" then
			ns.HookOnce(compendium, "Select", later, KEY)
		end
		parts()
		later()
		-- (Its controller filter menu, from the window's filter arrow: looked for once the window
		-- is there.)
		ns.Watch(KEY, "SpokenCompendiumWindowFilterPad", FilterPad)
	end)
end, { window = true, controls = true, text = true, shadow = true })
