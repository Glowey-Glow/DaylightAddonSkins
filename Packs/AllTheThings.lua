-- ALL THE THINGS (folder "AllTheThings"): its list windows, its text dialog, its tabs on the auction
-- house and the profession window and the box beside its tooltips in the Daylight UI look.
-- Presentation only: nothing of its data, filters, rows' order or settings is changed (but for the
-- one hand-over below). Built against ALL THE THINGS 5.4.14, checked again for 5.4.18 (the Forever build: AllTheThings.toc,
-- src/UI/Window Definitions.lua, src/base.lua, src/UI/Game Tooltip.lua, src/UI/Windows/Auctions.lua,
-- src/UI/Windows/Retail/Tradeskills.lua, src/Settings).
--
-- Dressed here:
--   * Every list window (ATTWindow<name>: the main list, the mini list, popouts, the auction and
--     profession lists, every /att window), each a plain BackdropTemplate frame: its backdrop's
--     pieces out of sight (kept, not removed: the addon records GetBackdrop() and its colors in its
--     profile, and lays the backdrop again when "hide borders" is toggled, which is followed by a
--     post-hook on the window's SetBackdrop) and Daylight UI's window shell behind it (the player's
--     opacity, border and bevel, reshaped as the window is resized). The X (UIPanelCloseButton)
--     Daylight UI's close button; its bare scroll bar (UIPanelScrollBarTemplate as a Slider of its
--     own, with its gray track) Daylight UI's thin track and pill thumb, the stepper arrows still
--     there to click; its corner grip (a plain texture of its own art, only a sign that the window
--     can be resized) Daylight UI's grip in the label ink.
--   * The rows: the blue hover / search highlight (Options_List_Active, also locked on a search
--     result) an accent wash; the player's font face and outline on each row's name and progress
--     (their size stays ATT's: it measures each row's height from it); words still in the game's
--     gold (GameFontNormal, the header's GameFontNormalLarge) in the label ink (the header in the
--     value ink). Rows are made as a window first needs them (a private builder): they are dressed
--     from a post-hook on the window's own Redraw, which every fill and scroll goes through, in the
--     same frame (rows are looked up with rawget, so none is ever made here).
--   * Its text dialog (ATTEditBox, the report / export / import box, DialogBoxFrame with a
--     backdrop): Daylight UI's window shell, the Okay button, the scroll bar, a quiet well behind
--     the text, its title in the value ink, its resize grip (the game's size grabber art)
--     Daylight UI's grip; the player's font on the text. Dressed from a post-hook on
--     app:ShowPopupDialogWithMultiLineEditBox, which builds and opens it.
--   * Its side tab on the auction house and the profession window (AllTheThings_Tab, from the
--     game's QuestLogTabButtonTemplate / LargeSideTabButtonTemplate): a clean tile (ns.SideTile,
--     as the professions pack does the game's own side tabs), the picked one edged in the accent;
--     its logo kept whole. Dressed from post-hooks on the windows' own UpdatePosition and
--     SetTSMCraftingVisible, which make the tabs. Quiet (no script of ours on the tab's showing:
--     it is shown inside the game's opening of those windows); repainted from its SetChecked.
--   * The 3D model box it hangs beside the game's tooltip (a BackdropTemplate frame): its backdrop
--     off and Daylight UI's tooltip look (at its tooltip opacity), only while Daylight UI's Tooltip
--     module is on.
--   * Its options pages (Esc > Options > AddOns > ALL THE THINGS, canvas pages): the Game settings
--     window pack's canvas pass dresses their buttons, checkboxes, dropdowns and words (and the
--     window buttons the Windows page makes on its first show). What that pass leaves to the
--     addon's pack is done here once, out of combat, only while that window's own skin is on:
--     sliders (MinimalSliderTemplate) through ns.Slider, scroll bars (the profile list's
--     ScrollFrameTemplate), text boxes (InputBoxTemplate, quietly, with the settings window as
--     their host: no script of ours runs inside the settings window's showing), the sound pack
--     dropdown (UIDropDownMenuTemplate) through ns.OldDropdown, the mode menu's arrow button a
--     chevron, each page's bright header rule a faint hairline.
-- Kept as ALL THE THINGS draws them (they carry meaning): every row's icon, portrait ring and
-- indicator, the collected / not collected colors and every color code in its text, the progress
-- numbers and percentages, the map-highlight band behind rows of the current zone, its tooltips'
-- lines and icons (Daylight UI's tooltip look is Daylight UI's), the logo and version on its
-- options pages. Its own window colors (Interface > Accessibility: background and border color,
-- class colored border) stay saved in ALL THE THINGS and come back with this skin off; with it on,
-- the window shell follows Daylight UI's look (or this addon's own look page).
-- Not here: its minimap button (Daylight UI's button collector), its world map button (nothing
-- under the world map is touched here: scripts there taint the gamepad's interact key), its menus
-- (the game's Menu, which Daylight UI dresses), its confirmation popups (the game's StaticPopup).
-- Controller: nothing mouse-only is added (its buttons, scroll steppers and keys work as before).
-- Its windows are not announced to the game's controller layer: the mini list stays open while
-- playing, and a listed window would take the D-pad and face buttons from the action bars.
-- Hand-over: its "Automatically Skip Cutscenes" (off by default) does what Daylight UI's Skip
-- cinematics (Quality of Life) does: Daylight UI's by default, asked on first load as every pack's.
-- Taint: hooks only (post-hooks on ALL THE THINGS' own functions and frames, the settings window
-- only as its edit boxes' quiet host, as the Game settings window pack does); no field of the
-- game's written; no polling (no ns.Watch: every window is found through app.Windows at load and
-- app:GetWindow after).
local _, ns = ...
if not ns.ok then return end

local L = ns.L
local API = ns.API

local KEY = "AllTheThings"
-- (The player's font goes on its rows, its dialog's text and its options' words.)
local CAPS = { window = true, controls = true, text = true, font = "daylight" }
ns.Target(KEY, "AllTheThings", CAPS)

local Usable, Guard = ns.Usable, ns.Guard
local pairs, ipairs, type, rawget = pairs, ipairs, type, rawget
local abs = math.abs

local function On() return ns.Enabled(KEY) end
local function Controls() return ns.Controls(KEY) end
local function Kind(x) return Usable(x) and x:GetObjectType() or nil end
local function IsTexture(x) return Kind(x) == "Texture" end

local function weak() return setmetatable({}, { __mode = "k" }) end
local dressed = weak()      -- windows, dialogs, tabs, frames already done

-- ALL THE THINGS' own table (its base.lua hands it out as _G.AllTheThings).
local function App()
	local app = _G.AllTheThings
	if type(app) == "table" and type(app.Windows) == "table" and type(app.GetWindow) == "function" then return app end
end

-- ---------------------------------------------------------------------------------------------
-- Rows
-- ---------------------------------------------------------------------------------------------

local ROW_WASH = 0.14
local washes = weak()       -- the rows' highlight textures (repainted as the accent changes)

local function PaintWash(tex)
	ns.FillAccent(tex, ROW_WASH, nil, KEY)
	tex:SetBlendMode("BLEND")
end

-- The player's face and outline on a row's string, its size kept (the row's height is measured
-- from it). Words in letters the face lacks keep ATT's face (ns.Foreign).
local ownFace = weak()      -- string -> ATT's face (its font object's)
local setFace = weak()      -- string -> the face this last put on it
-- What the last look was worked out for (a string's text, the face and outline asked for, and the
-- face it then had), so a row redrawn with the same words skips ns.Foreign's letter check.
local doneText, doneFace, doneOutline, donePath = weak(), weak(), weak(), weak()

local function RowFont(fs)
	if ns.PlainText(KEY) then return end
	local ok, path, size, flags = pcall(fs.GetFont, fs)
	if not ok or type(size) ~= "number" or size <= 0 then return end
	if path ~= setFace[fs] then ownFace[fs] = path end
	local face, _, outline = ns.FontFor(KEY, path, size, flags)
	outline = outline or flags or ""
	local text = fs:GetText()
	if path == donePath[fs] and text == doneText[fs] and face == doneFace[fs] and outline == doneOutline[fs] then
		return
	end
	local want = face
	if want ~= ownFace[fs] and ns.Foreign(text, want) then want = ownFace[fs] end
	if want and (want ~= path or outline ~= (flags or "")) then
		fs:SetFont(want, size, outline)
		setFace[fs] = want
		path = want
	end
	doneText[fs], doneFace[fs], doneOutline[fs], donePath[fs] = text, face, outline, path
end

-- The game's gold (its row font objects') in Daylight UI's inks; any other color (a font object
-- of another color, color codes in the text) is left as it is.
local inked = weak()        -- string -> the ink it was last given
local function Near(r, g, b, c)
	return abs(r - c[1]) < 0.03 and abs(g - c[2]) < 0.03 and abs(b - c[3]) < 0.03
end
local GOLD = { 1, 0.82, 0 }

local function RowInk(fs, name)
	local r, g, b = fs:GetTextColor()
	if type(r) ~= "number" or (issecretvalue and (issecretvalue(r) or issecretvalue(g) or issecretvalue(b))) then return end
	local c = ns.Colors()[name]
	if not c then return end
	local was = inked[fs]
	if Near(r, g, b, GOLD) or (was and Near(r, g, b, was) and not Near(r, g, b, c)) then
		fs:SetTextColor(c[1], c[2], c[3])
		inked[fs] = c
	end
end

local rowDone = weak()
local function Row(row)
	if not Usable(row) then return end
	if not rowDone[row] then
		rowDone[row] = true
		local hl = row.GetHighlightTexture and row:GetHighlightTexture()
		if IsTexture(hl) then
			washes[hl] = true
			PaintWash(hl)
		end
	end
	if not row:IsShown() then return end
	-- (Its header row, the first, is in GameFontNormalLarge: the value ink.)
	local ink = row.lastFont == "GameFontNormalLarge" and "VALUE" or "LABEL"
	for _, fs in ipairs({ row.Label, row.Summary }) do
		if Kind(fs) == "FontString" then
			RowFont(fs)
			RowInk(fs, ink)
		end
	end
end

-- Every row a window has made so far (rawget: its rows table makes a row on any other lookup).
local function Rows(w)
	local container = Usable(w) and w.Container
	local rows = Usable(container) and container.rows
	if type(rows) ~= "table" then return end
	for i = 1, 1000 do
		local row = rawget(rows, i)
		if not row then break end
		Row(row)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Pieces
-- ---------------------------------------------------------------------------------------------

-- Its corner grip, a plain texture: Daylight UI's grip in the label ink.
local grips = weak()
local function PaintGrip(tex)
	local c = ns.Colors().LABEL
	if c then tex:SetVertexColor(c[1], c[2], c[3], 0.6) end
end
local function Grip(tex)
	if not IsTexture(tex) or grips[tex] then return end
	grips[tex] = true
	tex:SetTexture(API.Media("ui-grip.png"))
	tex:SetTexCoord(0, 1, 0, 1)
	PaintGrip(tex)
end

-- Its side tab (LargeSideTabButtonTemplate): a clean tile, its logo whole.
local SIDE_ART = { "Background", "SelectedTexture", "HighlightTexture" }
local function TabPicked(tab)
	local s = tab.SelectedTexture
	return IsTexture(s) and s:IsShown() == true
end

local function SideTab(tab)
	local Kit = ns.Kit
	if not Kit or not Controls() or not Usable(tab) or not IsTexture(tab.Icon) or dressed[tab] then return end
	dressed[tab] = true
	for _, k in ipairs(SIDE_ART) do
		if IsTexture(tab[k]) then Kit.Hide(tab[k]) end
	end
	-- (Its glow is animated in and out: erased for good.)
	if IsTexture(tab.TabGlow) then Kit.Erase(tab.TabGlow) end
	if not ns.SideTile(tab, { picked = TabPicked, key = KEY, pad = 2, quiet = true }) then return end
	-- (A logo, not an icon with a frame of its own: not cropped.)
	tab.Icon:SetTexCoord(0, 1, 0, 1)
	ns.HookOnce(tab, "SetChecked", function() ns.SideTilesPaintSoon() end, KEY)
end

local function AuctionTab()
	local app = App()
	if app then SideTab(app.AuctionHouseTab) end
end

local function ProfessionTab()
	local app = App()
	if app then SideTab(app.TradeskillTab) end
end

-- The backdrop it lays again (hide borders on and off): its pieces out of sight.
local function Backdropped(w)
	local Kit = ns.Kit
	if Kit then Kit.Backdrop(w) end
end

-- ---------------------------------------------------------------------------------------------
-- Windows
-- ---------------------------------------------------------------------------------------------

local windows = weak()      -- the list windows dressed (repainted as the look changes)

local function Window(w)
	local Kit = ns.Kit
	if not Kit or not Usable(w) or dressed[w] then return end
	dressed[w] = true
	windows[w] = true
	Kit.Backdrop(w)
	ns.HookOnce(w, "SetBackdrop", Backdropped, KEY)
	ns.Shell(w, { window = true }, KEY)
	if Controls() then
		if Usable(w.CloseButton) then Kit.Close(w.CloseButton) end
		if Usable(w.ScrollBar) then Kit.ScrollBar(w.ScrollBar) end
		Grip(w.Grip)
	end
	ns.HookOnce(w, "Redraw", Rows, KEY)
	-- The auction list makes its tab in UpdatePosition, the profession list in
	-- SetTSMCraftingVisible (each only on its own window).
	if ns.HookOnce(w, "UpdatePosition", AuctionTab, KEY) then AuctionTab() end
	if ns.HookOnce(w, "SetTSMCraftingVisible", ProfessionTab, KEY) then ProfessionTab() end
	Rows(w)
end

local function AllWindows()
	local app = App()
	if not app then return end
	for _, w in pairs(app.Windows) do Window(w) end
end

-- ---------------------------------------------------------------------------------------------
-- Its text dialog (ATTEditBox)
-- ---------------------------------------------------------------------------------------------

local function EditDialog()
	local Kit = ns.Kit
	local f = _G.ATTEditBox
	if not Kit or not Usable(f) or dressed[f] then return end
	dressed[f] = true
	ns.NoBackdrop(f)
	ns.Shell(f, { window = true }, KEY)
	local label = f.Label
	if Kind(label) == "FontString" then
		ns.FollowFont(label, KEY)
		Kit.Light(label, ns.Colors().VALUE)
	end
	local sf = f.ScrollFrame
	if Usable(sf) then Kit.Inset(sf) end
	if Kind(f.EditBox) == "EditBox" then ns.FollowFont(f.EditBox, KEY) end
	if Controls() then
		local okay = _G.ATTEditBoxButton
		if ns.TextButton(okay) then Kit.Button(okay) end
		if Usable(sf) and Usable(sf.ScrollBar) then Kit.ScrollBar(sf.ScrollBar) end
		ns.Grip(_G.ATTEditBoxResizeButton)
	end
end

-- ---------------------------------------------------------------------------------------------
-- The model box beside the game's tooltip (Daylight UI's tooltip look, while its Tooltip module
-- is on)
-- ---------------------------------------------------------------------------------------------

-- (ns.TipLook, Core.lua: from Daylight UI 2.0 the border is the tooltips' own size or General's,
-- 2.0 DaylightUI_Tooltip\Tooltip.lua:61-64 and :144; before 2.0 the fixed 3 px, 1.9.6
-- Tooltip.lua:28. Gate: ns.DaylightAtLeast(2, 0), in ns.TipLook.)
-- In the Rich look (2.0) the box sits against Daylight UI's card over the game's tooltip, not its
-- Simple shell: it takes the card's ground opacity (ns.TipAlpha("rich"): Tooltip richAlpha, 2.0
-- DaylightUI_Tooltip\Rich\Panel.lua:185). Feature-detected: ns.TipStyle is nil on 1.9.x. The card's
-- square, cut corner stays the card's (not an option of API.Skin).
local function TipLook()
	local look = ns.TipLook()
	if ns.TipStyle() == "rich" then look.bgAlpha = ns.TipAlpha("rich") or look.bgAlpha end
	return look
end

local modelBox
local function ModelBox()
	local Kit = ns.Kit
	local model = _G.ATTGameTooltipModel1
	local f = Usable(model) and model:GetParent()
	if not Kit or not Usable(f) or dressed[f] or not f.GetBackdrop or not ns.ModuleOn("Tooltip") then return end
	dressed[f] = true
	modelBox = f
	Kit.Backdrop(f)
	Guard(API.Skin, f, TipLook())
end

-- ---------------------------------------------------------------------------------------------
-- Its options pages: what the Game settings window pack's canvas pass leaves to the addon's pack
-- ---------------------------------------------------------------------------------------------

local MODE_ARROW = "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up"
local arrowIds

-- The General page's mode menu button (UIDropDownMenuButtonScriptTemplate with the chat's
-- scroll-down arrow as its art).
local function ModeArrow(btn)
	arrowIds = arrowIds or ns.FileIDs({ [MODE_ARROW] = true })
	local tex = btn.GetNormalTexture and btn:GetNormalTexture()
	if not IsTexture(tex) then return false end
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return false end
	if type(file) == "string" then file = string.lower(file) end
	return arrowIds[file] == true
end

local function Part(Kit, f, host, depth)
	if depth > 12 or not Usable(f) then return end
	local kind = f:GetObjectType()
	if kind == "Slider" then
		if ns.IsScrollBar(f) then Kit.ScrollBar(f) else ns.Slider(f) end
		return
	elseif kind == "EventFrame" then
		if ns.IsScrollBar(f) then Kit.ScrollBar(f) end
		return
	elseif kind == "EditBox" then
		if host and IsTexture(f.Left) and IsTexture(f.Right) then Kit.EditBox(f, host) end
		return
	elseif kind == "Button" then
		if ModeArrow(f) then Kit.BareButton(f, "down") end
		return
	elseif kind == "CheckButton" then
		return
	elseif kind == "ScrollFrame" then
		local bar = f.ScrollBar
		if Usable(bar) and ns.IsScrollBar(bar) then Kit.ScrollBar(bar) end
	elseif kind == "Frame" then
		ns.OldDropdown(f)
	end
	for _, c in ipairs({ f:GetChildren() }) do Part(Kit, c, host, depth + 1) end
end

local function OptionsPages()
	local Kit = ns.Kit
	local app = App()
	local settings = app and app.Settings
	if not Kit or type(settings) ~= "table" or type(settings.Objects) ~= "table" then return end
	if not ns.Enabled("BlizzardSettings") or not Controls() then return end
	local panel = _G.SettingsPanel
	local host = Usable(panel) and panel or nil
	for _, page in ipairs(settings.Objects) do
		if Kind(page) == "Frame" and type(page.category) == "table" and not dressed[page] then
			dressed[page] = true
			if IsTexture(page.separator) then page.separator:SetColorTexture(1, 1, 1, 0.12) end
			Part(Kit, page, host, 0)
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The pack
-- ---------------------------------------------------------------------------------------------

ns.Pack(KEY, "AllTheThings", function()
	local app = App()
	if not app then return false end
	-- Windows made before this ran (the main and mini lists at startup), then every other as
	-- ALL THE THINGS builds it: app:GetWindow is the only way to its window builder.
	AllWindows()
	ns.HookOnce(app, "GetWindow", function(_, suffix)
		local w = app.Windows[suffix]
		if w and not dressed[w] then Window(w) end
	end, KEY)
	-- Its text dialog, built on first use.
	EditDialog()
	ns.HookOnce(app, "ShowPopupDialogWithMultiLineEditBox", EditDialog, KEY)
	ModelBox()
	-- (Its options pages are there from load; the settings window's own skin may come later.)
	ns.OutOfCombat(function()
		if On() then Guard(OptionsPages) end
	end)
end, CAPS)

-- The accent or the inks changed: the washes, grips and inked words follow; the model box follows
-- Daylight UI's tooltip opacity and, from 2.0, its tooltip border size.
local function Repaint()
	if not On() then return end
	for tex in pairs(washes) do Guard(PaintWash, tex) end
	for tex in pairs(grips) do Guard(PaintGrip, tex) end
	for w in pairs(windows) do Guard(Rows, w) end
end
ns.me.On("StyleChanged", Repaint)
ns.me.On("SettingChanged", function(scope, path)
	if scope == "DaylightAddonSkins" then Repaint() end
	if modelBox and ns.TipLookChanged(scope, path) and On() then Guard(API.Skin, modelBox, TipLook()) end
end)

-- ---------------------------------------------------------------------------------------------
-- Hand-over: its "Automatically Skip Cutscenes" (Features page; a tooltip setting, kept per ATT
-- profile) does what Daylight UI's Skip cinematics does.
-- ---------------------------------------------------------------------------------------------

local function Options()
	local app = App()
	local settings = app and app.Settings
	if type(settings) == "table" and settings._Initialize == true and type(settings.GetTooltipSetting) == "function"
		and type(settings.SetTooltipSetting) == "function" then
		return settings
	end
end

local SETTING = { cutscenes = "Skip:Cutscenes" }

ns.Handover(KEY, {
	ready = function() return Options() ~= nil end,
	get = function(key)
		local s = Options()
		if not s or not SETTING[key] then return nil end
		return s:GetTooltipSetting(SETTING[key])
	end,
	set = function(key, value)
		local s = Options()
		if not s or not SETTING[key] then return end
		s:SetTooltipSetting(SETTING[key], value)
	end,
	list = {
		{ key = "cutscenes", label = L["Skip Cutscenes"], daylight = ns.In(L["skip cinematics"], "Quality of Life"),
		  ours = function() return ns.DaylightHas("QoL", "skipCinematics") end },
	},
})
