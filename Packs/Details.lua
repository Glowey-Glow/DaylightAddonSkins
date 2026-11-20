-- Details! Damage Meter: its meter windows in the look of Daylight UI's own damage meter, and its
-- other windows, menus and tooltips in the Daylight UI look. Presentation only: nothing is moved,
-- docked or reparented (never into a chat panel), and no combat data is touched.
--
-- The meter windows (Details' classic windows, one per instance):
--   * Through Details' own window settings, the ones its options and skins write (so they survive
--     Details updates and its own redraws): bars in Daylight UI's meter bar texture and track,
--     class colored or in the meter's custom color as Daylight UI's meter is set, row height and
--     gap, the meter's font, size, outline and shadow on the row texts, names in the meter's name
--     color (or class colors), no row borders, icons off when the meter shows none; the title in
--     the player's font and the text ink, the toolbar on top in the label ink (desaturated, the
--     accent under the mouse); its own ground, side bars, rounded corners and borders off.
--     What each setting was is recorded (per Details profile and window, in
--     DaylightAddonSkinsDB.details) before it is first changed. A setting the player changes in
--     Details afterwards is theirs from then on: never set again, never given back. Switched off
--     (this addon's switch or Daylight UI's Window Skins), every setting still as this left it
--     goes back as it was at the next login (out of combat).
--   * A Daylight UI window shell of ours behind each window (title row to the bottom edge, the
--     status bar's strip included when it shows): the player's window opacity, border and bevel.
--     The skin's art (title band, corners, side bars, footer) is erased (Details' skin file is
--     drawn on the same textures by every skin, so it's the textures, not one skin's file).
--   * Dressed in the frame Details applies a skin (a post-hook on Details:ChangeSkin, which every
--     new, reopened or re-skinned window goes through) and again when Details switches profile.
--     Never first dressed in combat: queued for the end of the fight.
-- Its other windows (all built by its framework, DetailsFramework): the options window and the
--   plugin window that holds it, the breakdown window (Forever's and the classic one), the report
--   window, the welcome window and every simple panel it opens (news, macros, bookmarks, class
--   colors, custom displays, Plater integration...): their ground and rounded corners off,
--   Daylight UI's window shell, the X dressed, titles in the value ink, the game's template
--   controls and scroll bars Daylight UI's (ns.Dress), gold words in the label ink. Built on first
--   open: dressed from post-hooks on Details' openers (OpenOptionsWindow, OpenBreakdownWindow,
--   Reportar, CreatePluginWindowContainer) and on the framework's CreateSimplePanel /
--   CreateTitleBar (only frames named "Details..."); ns.Watch only for the welcome window.
-- Its framework's own controls (flat buttons, switches, dropdowns, sliders, text boxes) take their
--   colors from the framework's templates when they're made: the templates are recolored to
--   Daylight UI's (dark fill, neutral edge, the accent for hover, picked and "on"), so every one
--   Details makes after load comes out in the Daylight UI colors. The templates are shared with any
--   other addon on the same framework (Plater...): their new controls follow too.
-- Its menus and tooltips (the framework's Cooltip): Daylight UI's shell on its two frames, its
--   ground, gradient, wallpaper and rounded corners off, the picked line and hover in the accent /
--   a faint wash, gold words in the text ink; Details' tooltip settings (font, header and value
--   colors, rounded corners, menu wallpaper) set like the window settings above, recorded and
--   given back the same way.
-- Left as Details draws them: its class colors (Details' own table), class / spec icons, the
--   numbers and every data color, the all-in-one window (window2, an optional second window type
--   with its own private settings), plugin contents (Encounter Details, Tiny Threat, Streamer...)
--   beyond what the templates give them, the minimap button (Daylight UI's addon drawer).
--
-- Hand-over: Daylight UI has a damage meter of its own (Info Panel). While both are on, Daylight
-- UI's meter is the one shown by default: Details' open windows are closed (asked once, on first
-- load; which ones were open is kept, and given back from its page).
local _, ns = ...
if not ns.ok then return end
local L = ns.L

local KEY = "Details"
local CAPS = { window = true, controls = true, colors = true,
	note = L["Its meter windows take the look of Daylight UI's damage meter through its own settings, which go back as they were when this is switched off (after a reload)."] }
ns.Target(KEY, "Details!", CAPS)

local Usable, Guard = ns.Usable, ns.Guard
local API = ns.API
local pairs, ipairs, type, tonumber = pairs, ipairs, type, tonumber
local floor, abs, max, min = math.floor, math.abs, math.max, math.min

local function On() return ns.Enabled(KEY) end
local function Kind(x) return Usable(x) and x:GetObjectType() or nil end

local function DetailsReady()
	local D = _G.Details
	return type(D) == "table" and type(D.IsLoaded) == "function" and D.IsLoaded() == true
		and type(D.tabela_instancias) == "table"
end

-- ---------------------------------------------------------------------------------------------
-- Saved records: DaylightAddonSkinsDB.details.profiles[<Details profile>] = { win = { [id] = rec },
-- tip = rec }, rec = { orig = { path = value }, applied = { path = value }, left = { path = true } }.
-- ---------------------------------------------------------------------------------------------

local NIL = "__DaylightAddonSkinsNil__"

local function DB()
	local db = _G.DaylightAddonSkinsDB
	if type(db) ~= "table" then
		db = {}
		_G.DaylightAddonSkinsDB = db
	end
	if type(db.details) ~= "table" then db.details = {} end
	if type(db.details.profiles) ~= "table" then db.details.profiles = {} end
	return db.details
end

local function ProfileName()
	local D = _G.Details
	local ok, name = pcall(D.GetCurrentProfileName, D)
	return ok and type(name) == "string" and name or "default"
end

local function Profile(create)
	local all = DB().profiles
	local name = ProfileName()
	local p = all[name]
	if not p and create then
		p = { win = {}, tip = {} }
		all[name] = p
	end
	return p, name
end

local function Rec(t)
	if type(t.orig) ~= "table" then t.orig = {} end
	if type(t.applied) ~= "table" then t.applied = {} end
	if type(t.left) ~= "table" then t.left = {} end
	return t
end

-- "row_info.texts.1.font.outline" -> { "row_info", "texts", 1, "font", "outline" }, kept.
local paths = {}
local function Split(path)
	local parts = paths[path]
	if parts then return parts end
	parts = {}
	for piece in string.gmatch(path, "[^%.]+") do
		parts[#parts + 1] = tonumber(piece) or piece
	end
	paths[path] = parts
	return parts
end

-- The value at path under root, and whether every table on the way is there.
local function Get(root, path)
	local parts = Split(path)
	local t = root
	for i = 1, #parts - 1 do
		t = t[parts[i]]
		if type(t) ~= "table" then return nil, false end
	end
	return t[parts[#parts]], true
end

local function Put(root, path, value)
	local parts = Split(path)
	local t = root
	for i = 1, #parts - 1 do
		t = t[parts[i]]
		if type(t) ~= "table" then return end
	end
	t[parts[#parts]] = value
end

local function Copy(v)
	if type(v) ~= "table" then return v end
	local out = {}
	for k, x in pairs(v) do out[k] = Copy(x) end
	return out
end

local function Same(a, b)
	if type(a) == "number" and type(b) == "number" then return abs(a - b) < 0.0005 end
	if type(a) ~= "table" or type(b) ~= "table" then return a == b end
	for k, x in pairs(a) do
		if not Same(x, b[k]) then return false end
	end
	for k in pairs(b) do
		if a[k] == nil then return false end
	end
	return true
end

local function Unwrap(v)
	if v == NIL then return nil end
	return v
end

-- Puts `wanted` (path -> value, NIL for "none") on root, recording what each was first. Returns
-- whether anything changed.
local function Apply(rec, root, wanted)
	Rec(rec)
	local changed = false
	for path, want in pairs(wanted) do
		if not rec.left[path] then
			local cur, there = Get(root, path)
			if there then
				local was = rec.applied[path]
				local mine = true
				if was == nil then
					rec.orig[path] = cur == nil and NIL or Copy(cur)
				elseif not Same(cur, Unwrap(was)) then
					-- Changed in Details since this set it: the player's from now on.
					rec.left[path] = true
					rec.orig[path], rec.applied[path] = nil, nil
					mine = false
				end
				if mine then
					local value = Unwrap(want)
					if not Same(cur, value) then
						Put(root, path, Copy(value))
						changed = true
					end
					rec.applied[path] = value == nil and NIL or Copy(value)
				end
			end
		end
	end
	return changed
end

-- Every setting still as Apply left it, back as it was. Returns whether anything changed.
local function Restore(rec, root)
	if type(rec) ~= "table" or type(rec.orig) ~= "table" then return false end
	local changed = false
	for path, orig in pairs(rec.orig) do
		local cur, there = Get(root, path)
		local applied = rec.applied and rec.applied[path]
		if there and applied ~= nil and Same(cur, Unwrap(applied)) then
			Put(root, path, Copy(Unwrap(orig)))
			changed = true
		end
	end
	rec.orig, rec.applied, rec.left = {}, {}, {}
	return changed
end

-- ---------------------------------------------------------------------------------------------
-- Daylight UI's meter look, read from its settings (Info Panel > Meters) and its style
-- ---------------------------------------------------------------------------------------------

local function Meter(path, default)
	local ok, v = pcall(API.GetSetting, "InfoPanel", "meter." .. path)
	if ok and v ~= nil then return v end
	return default
end

local function General(path, default)
	local ok, v = pcall(API.GetSetting, "general", path)
	if ok and v ~= nil then return v end
	return default
end

local function DStyle()
	local D = _G.DaylightUI
	return type(D) == "table" and type(D.Style) == "table" and D.Style or nil
end

local function StyleCall(name, ...)
	local Style = DStyle()
	if not Style or type(Style[name]) ~= "function" then return nil end
	local ok, a = pcall(Style[name], ...)
	if ok then return a end
	return nil
end

-- The meter's own picks (InfoPanel's media slots "panel.meter" and "panel.font.meter"), else the
-- player's.
local function BarFile() return StyleCall("BarFile", nil, "panel.meter") end
local function BackFile() return StyleCall("BackFile", "panel.meter.back") end
local function FontFile()
	local face = StyleCall("FontFile", "panel.font.meter")
	if type(face) ~= "string" then
		local ok, f = pcall(API.Font)
		face = ok and f or nil
	end
	return ns.SafeFace(face)
end

-- The name a file is listed under in LibSharedMedia (Details keeps names next to its files).
local function MediaName(kind, file)
	local lsm = ns.LSM
	if not lsm or type(file) ~= "string" then return nil end
	local ok, list = pcall(lsm.HashTable, lsm, kind)
	if not ok or type(list) ~= "table" then return nil end
	local want = (string.gsub(string.lower(file), "/", "\\"))
	for name, path in pairs(list) do
		if type(path) == "string" and (string.gsub(string.lower(path), "/", "\\")) == want then return name end
	end
	return nil
end

local function Ink(name, alpha)
	local c = ns.Colors()[name] or { 1, 1, 1 }
	return { c[1], c[2], c[3], alpha or 1 }
end

local function AccentColor(alpha)
	local r, g, b = ns.AccentOf(KEY)
	return { r, g, b, alpha or 1 }
end

local HEADER_H = 20      -- Daylight UI's meter header (MeterHeader.H)
local STATUS_H = 14      -- Details' status bar strip under a window

-- What each window's settings should be (path -> value).
local function WindowWanted()
	local w = {}
	local scale = General("fontScale", 1)
	if type(scale) ~= "number" or scale <= 0 then scale = 1 end
	local shadowA = General("textShadow", true) == false and 0 or 0.6
	local outline = StyleCall("Outline")
	if type(outline) ~= "string" then outline = "" end
	-- The window: our shell is its ground and edge.
	w["bg_alpha"] = 0
	w["show_sidebars"] = false
	w["rounded_corner_enabled"] = false
	w["fullborder_shown"] = false
	w["rowareaborder_shown"] = false
	w["titlebar_shown"] = true
	w["titlebar_height"] = HEADER_H
	w["titlebar_texture_color"] = { 0, 0, 0, 0 }
	w["toolbar_side"] = 1
	w["desaturated_menu"] = true
	w["color_buttons"] = Ink("LABEL")
	-- The title.
	w["attribute_text.enabled"] = true
	w["attribute_text.side"] = 1
	w["attribute_text.text_size"] = floor(12 * scale + 0.5)
	w["attribute_text.text_color"] = Ink("TEXT")
	w["attribute_text.shadow"] = shadowA > 0
	-- The rows.
	local rowH = tonumber(Meter("rowHeight", 22)) or 22
	local gap = tonumber(Meter("rowGap", 1)) or 1
	w["row_info.height"] = max(8, floor(rowH + 0.5))
	w["row_info.space.between"] = max(0, floor(gap + 0.5))
	w["row_info.alpha"] = 1
	w["row_info.backdrop.enabled"] = false
	w["row_info.texture_custom"] = ""
	local bar = BarFile()
	if type(bar) == "string" then
		w["row_info.texture_file"] = bar
		local name = MediaName("statusbar", bar)
		if name then w["row_info.texture"] = name end
	end
	local back = BackFile()
	if type(back) == "string" then
		w["row_info.texture_background_file"] = back
		local name = MediaName("statusbar", back)
		if name then w["row_info.texture_background"] = name end
	end
	-- The track: a dim, quiet strip behind every fill (its opacity the meter's "track" setting).
	local track = tonumber(Meter("trackAlpha", 1)) or 1
	w["row_info.texture_background_class_color"] = false
	w["row_info.fixed_texture_background_color"] = { 0.16, 0.16, 0.18, 0.8 * max(0, min(1, track)) }
	if Meter("barColor", "class") == "custom" then
		local c = Meter("barCustom", { 0.72, 0.70, 0.66 })
		w["row_info.texture_class_colors"] = false
		if type(c) == "table" then w["row_info.fixed_texture_color"] = { c[1] or 1, c[2] or 1, c[3] or 1, 1 } end
	else
		w["row_info.texture_class_colors"] = true
	end
	local face = FontFile()
	if face then
		w["row_info.font_face_file"] = face
		local name = MediaName("font", face)
		if name then
			w["row_info.font_face"] = name
			w["attribute_text.text_face"] = name
		end
	end
	local size = tonumber(Meter("textSize", 11)) or 11
	w["row_info.font_size"] = floor(size * scale + 0.5)
	local nameColor = Meter("nameColor", { 1, 1, 1 })
	if type(nameColor) == "table" then w["row_info.fixed_text_color"] = { nameColor[1] or 1, nameColor[2] or 1, nameColor[3] or 1 } end
	local classText = Meter("classText", false) == true
	w["row_info.no_icon"] = Meter("icons", "class") == "none"
	for i = 1, 4 do
		local at = "row_info.texts." .. i
		-- (Each text inherits the row font and size; one picked per text in Details is cleared.)
		w[at .. ".font.face"] = NIL
		w[at .. ".font.size"] = NIL
		w[at .. ".font.outline"] = outline
		w[at .. ".shadow.color"] = { 0, 0, 0, shadowA }
		w[at .. ".shadow.offset"] = { 1, -1 }
		if i == 1 then
			w[at .. ".color.byClass"] = classText or Meter("nameColorBy", "custom") == "class"
		else
			w[at .. ".color.byClass"] = classText
		end
	end
	return w
end

-- Details' tooltip and menu settings (on the Details table itself).
local function TipWanted()
	local w = {}
	local face = FontFile()
	local name = face and MediaName("font", face)
	if name then
		w["tooltip.fontface"] = name
		w["font_faces.menus"] = name
	end
	w["tooltip.fontcolor"] = Ink("TEXT")
	w["tooltip.fontcolor_right"] = Ink("VALUE")
	w["tooltip.header_text_color"] = Ink("LABEL")
	w["tooltip.rounded_corner"] = false
	w["tooltip.submenu_wallpaper"] = false
	w["tooltip.menus_bg_color"] = { 0, 0, 0, 0 }
	w["tooltip.show_border_shadow"] = false
	w["tooltip.border_color"] = { 0, 0, 0, 0 }
	w["tooltip.divisor_color"] = { 1, 1, 1, 0.12 }
	w["tooltip.bar_color"] = { 0.28, 0.28, 0.3, 0.6 }
	return w
end

-- ---------------------------------------------------------------------------------------------
-- The windows' frames: our shell, the skin's art erased, the toolbar's hover
-- ---------------------------------------------------------------------------------------------

local holders = setmetatable({}, { __mode = "k" })   -- baseframe -> our shell's frame
local hovered = setmetatable({}, { __mode = "k" })   -- toolbar buttons hooked

local ART = {
	{ "cabecalho", "ball" }, { "cabecalho", "emenda" }, { "cabecalho", "ball_r" }, { "cabecalho", "top_bg" },
	{ "barra_esquerda" }, { "barra_direita" }, { "barra_fundo" },
	{ "scroll_up" }, { "scroll_down" }, { "scroll_middle" },
	{ "rodape", "top_bg" }, { "rodape", "esquerdo" }, { "rodape", "direita" },
	{ "rodape", "esquerdo_nostatusbar" }, { "rodape", "direita_nostatusbar" },
}
local TOOLBAR = { "modo_selecao", "segmento", "atributo", "report", "reset", "fechar" }

local function ButtonColor(btn, c)
	local tex = btn.GetNormalTexture and btn:GetNormalTexture()
	if Kind(tex) == "Texture" and type(c) == "table" then tex:SetVertexColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1) end
end

local function Toolbar(instance, bf)
	local head = bf.cabecalho
	if type(head) ~= "table" then return end
	for _, k in ipairs(TOOLBAR) do
		local btn = head[k]
		if Kind(btn) == "Button" and not hovered[btn] then
			hovered[btn] = true
			btn:HookScript("OnEnter", function(self)
				if On() then ButtonColor(self, AccentColor()) end
			end)
			btn:HookScript("OnLeave", function(self)
				if On() then ButtonColor(self, instance.color_buttons) end
			end)
		end
	end
end

local function Decorate(instance)
	local Kit = ns.Kit
	local bf = type(instance) == "table" and instance.baseframe
	if not Kit or not Usable(bf) or not On() then return end
	for _, keys in ipairs(ART) do
		local t = bf[keys[1]]
		if keys[2] and type(t) == "table" then t = t[keys[2]] end
		if Kind(t) == "Texture" then Kit.Erase(t) end
	end
	local holder = holders[bf]
	if not holder then
		holder = CreateFrame("Frame", nil, bf)
		holder:EnableMouse(false)
		holders[bf] = holder
		ns.Shell(holder, { window = true }, KEY)
	end
	holder:SetFrameLevel(bf:GetFrameLevel())
	holder:ClearAllPoints()
	local top = Usable(bf.titleBar) and bf.titleBar or bf
	local below = instance.show_statusbar and STATUS_H or 0
	holder:SetPoint("TOPLEFT", top, "TOPLEFT", 0, 0)
	holder:SetPoint("TOPRIGHT", top, "TOPRIGHT", 0, 0)
	holder:SetPoint("BOTTOMLEFT", bf, "BOTTOMLEFT", 0, -below)
	holder:SetPoint("BOTTOMRIGHT", bf, "BOTTOMRIGHT", 0, -below)
	Toolbar(instance, bf)
end

-- ---------------------------------------------------------------------------------------------
-- Settings on, settings back
-- ---------------------------------------------------------------------------------------------

local applying = false
local applyQueued, waitingFight = false, false

local function Reskin(instance)
	if not (instance.baseframe and instance.IsEnabled and instance:IsEnabled()) then return end
	applying = true
	local ok, err = pcall(instance.ChangeSkin, instance)
	applying = false
	if not ok then geterrorhandler()(err) end
end

local function ApplyAll()
	applyQueued = false
	if not On() or not DetailsReady() then return end
	if InCombatLockdown() then
		if not waitingFight then
			waitingFight = true
			ns.OutOfCombat(function() waitingFight = false ApplyAll() end)
		end
		return
	end
	local D = _G.Details
	local p = Profile(true)
	local wanted = WindowWanted()
	for _, instance in ipairs(D:GetAllInstances()) do
		local id = type(instance) == "table" and instance.meu_id
		if id then
			if type(p.win[id]) ~= "table" then p.win[id] = {} end
			if Apply(p.win[id], instance, wanted) then Reskin(instance) end
			Guard(Decorate, instance)
		end
	end
	Apply(p.tip, D, TipWanted())
end

local function ApplySoon(delay)
	if applyQueued then return end
	applyQueued = true
	C_Timer.After(delay or 0, ApplyAll)
end

-- Off (this addon's switch or Window Skins): everything still as this left it, back.
local function RestoreAll()
	if On() or not DetailsReady() then return false end
	local p = Profile(false)
	if not p then return true end
	if InCombatLockdown() then
		ns.OutOfCombat(RestoreAll)
		return true
	end
	local D = _G.Details
	for _, instance in ipairs(D:GetAllInstances()) do
		local id = type(instance) == "table" and instance.meu_id
		local rec = id and p.win[id]
		if rec and Restore(rec, instance) then Reskin(instance) end
	end
	Restore(p.tip, D)
	DB().profiles[ProfileName()] = nil
	return true
end

ns.me.On("Login", function()
	local tries = 0
	local function try()
		tries = tries + 1
		local done
		if On() then
			local ready = DetailsReady()
			if ready then ApplySoon() end
			done = ready or type(_G.Details) ~= "table"
		else
			done = type(_G.Details) ~= "table" or RestoreAll()
		end
		if not done and tries < 30 then C_Timer.After(1, try) end
	end
	C_Timer.After(0.5, try)
end)

-- ---------------------------------------------------------------------------------------------
-- The framework's templates (the colors its controls are made in)
-- ---------------------------------------------------------------------------------------------

local function Goldish(DF, color)
	if color == nil then return false end
	local ok, r, g, b = pcall(DF.ParseColors, DF, color)
	if not ok or type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return false end
	-- (A color read back from a string drawn with a secret value can be secret itself.)
	if issecretvalue and (issecretvalue(r) or issecretvalue(g) or issecretvalue(b)) then return false end
	local hi, lo = max(r, g, b), min(r, g, b)
	if hi < 0.5 or hi <= 0 then return false end
	local s = (hi - lo) / hi
	if s < 0.55 then return false end
	local h
	local d = hi - lo
	if hi == r then h = ((g - b) / d) % 6 elseif hi == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
	h = h * 60
	return h >= 33 and h <= 62
end

local ACCENT_KEYS = { "toggle_knob_color_on", "thumbcolor", "track_fill_color", "track_fill_color_active",
	"thumbcolor_active", "checked_color" }

local function Fill(alpha)
	local c = ns.BackColor()
	return { min(1, c[1] + 0.06), min(1, c[2] + 0.06), min(1, c[3] + 0.07), alpha or 0.92 }
end

local function Neutral()
	local Kit = ns.Kit
	local c = Kit and Kit.TAB_BORDER or { 0.3, 0.3, 0.32 }
	return { c[1], c[2], c[3], 1 }
end

local litEdge = setmetatable({}, { __mode = "k" })   -- template -> its edge is the accent

local function RecolorTemplate(DF, tpl, name, isFont, fontName)
	if type(tpl) ~= "table" then return end
	if isFont then
		if tpl.color ~= nil and Goldish(DF, tpl.color) then tpl.color = Ink("LABEL") end
		if fontName then tpl.font = fontName end
		return
	end
	local picked = type(name) == "string" and string.find(name, "SELECTED", 1, true) ~= nil
	if type(tpl.backdrop) == "table" and tpl.backdrop.bgFile then
		local b = Copy(tpl.backdrop)
		b.bgFile = "Interface\\Buttons\\WHITE8X8"
		tpl.backdrop = b
	end
	if tpl.backdropcolor ~= nil then tpl.backdropcolor = Fill(picked and 0.98 or 0.92) end
	if tpl.backdropbordercolor ~= nil then
		-- (Whether its edge is a lit one is decided on its first pass: by then it's no longer gold.)
		local lit = litEdge[tpl]
		if lit == nil then
			lit = picked or Goldish(DF, tpl.backdropbordercolor)
			litEdge[tpl] = lit
		end
		tpl.backdropbordercolor = lit and AccentColor() or Neutral()
	end
	if tpl.onentercolor ~= nil then
		local c = Fill(0.98)
		tpl.onentercolor = { min(1, c[1] + 0.05), min(1, c[2] + 0.05), min(1, c[3] + 0.05), c[4] }
	end
	if tpl.onenterbordercolor ~= nil then tpl.onenterbordercolor = AccentColor() end
	if tpl.onleavebordercolor ~= nil then tpl.onleavebordercolor = picked and AccentColor() or Neutral() end
	if tpl.enabled_backdropcolor ~= nil then tpl.enabled_backdropcolor = Fill(0.92) end
	if tpl.disabled_backdropcolor ~= nil then tpl.disabled_backdropcolor = Fill(0.5) end
	if tpl.track_color ~= nil then tpl.track_color = { 0.22, 0.22, 0.24, 1 } end
	for _, k in ipairs(ACCENT_KEYS) do
		if tpl[k] ~= nil then tpl[k] = AccentColor() end
	end
	if tpl.textcolor ~= nil and Goldish(DF, tpl.textcolor) then tpl.textcolor = Ink("TEXT") end
end

local function TemplateTable(DF, category)
	category = string.lower(category or "")
	if category == "font" then return DF.font_templates, true end
	if category == "dropdown" then return DF.dropdown_templates end
	if category == "button" then return DF.button_templates end
	if category == "switch" then return DF.switch_templates end
	if category == "slider" then return DF.slider_templates end
end

local function RecolorAll(DF)
	local face = FontFile()
	local fontName = face and MediaName("font", face)
	for _, cat in ipairs({ "font", "dropdown", "button", "switch", "slider" }) do
		local t, isFont = TemplateTable(DF, cat)
		if type(t) == "table" then
			for name, tpl in pairs(t) do RecolorTemplate(DF, tpl, name, isFont, fontName) end
		end
	end
	-- Details' own gold names for its headers and plugin buttons.
	local alias = DF.alias_text_colors
	if type(alias) == "table" then
		for _, n in ipairs({ "DETAILS_HEADER_YELLOW", "DETAILS_PLUGIN_BUTTONTEXT_COLOR" }) do
			if type(alias[n]) == "table" then
				local c = Ink(n == "DETAILS_HEADER_YELLOW" and "LABEL" or "TEXT")
				alias[n][1], alias[n][2], alias[n][3] = c[1], c[2], c[3]
			end
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- Its framework windows
-- ---------------------------------------------------------------------------------------------

local GOLD_DEPTH = 8

-- Gold words (its headers, labels) in the label ink; item and data colors stay.
local function Regold(DF, f, depth)
	if depth > GOLD_DEPTH or not Usable(f) then return end
	if f.GetRegions then
		for _, r in ipairs({ f:GetRegions() }) do
			if Kind(r) == "FontString" then
				local cr, cg, cb = r:GetTextColor()
				if Goldish(DF, { cr, cg, cb }) then
					local c = ns.Colors().LABEL
					if c then r:SetTextColor(c[1], c[2], c[3]) end
				end
			end
		end
	end
	if f.GetChildren then
		for _, c in ipairs({ f:GetChildren() }) do
			if not (c.IsForbidden and c:IsForbidden()) then Regold(DF, c, depth + 1) end
		end
	end
end

local function Unround(f)
	if type(f) == "table" and f.__rcorners and type(f.DisableRoundedCorners) == "function" then
		pcall(f.DisableRoundedCorners, f)
	end
end

local CLOSE_KEYS = { "CloseButton", "closeButton", "Close" }

local function CloseOf(f)
	for _, k in ipairs(CLOSE_KEYS) do
		if Kind(f[k]) == "Button" then return f[k] end
	end
	local name = f.GetName and f:GetName()
	if type(name) == "string" then
		local b = _G[name .. "CloseButton"] or _G[name .. "TitleBarCloseButton"]
		if Kind(b) == "Button" then return b end
	end
	if f.TitleBar and Kind(f.TitleBar.CloseButton) == "Button" then return f.TitleBar.CloseButton end
	return ns.FindClose(f)
end

local function TitleOf(f)
	local t = f.Title or f.TitleText or f.TitleLabel
	if type(t) == "table" and Kind(t) ~= "FontString" and Kind(t.widget) == "FontString" then t = t.widget end
	if Kind(t) == "FontString" then return t end
	if f.TitleBar and Kind(f.TitleBar.Text) == "FontString" then return f.TitleBar.Text end
	return nil
end

local DRESS = { checks = false }

-- Rounded panels inside a window (a side menu, a section's well) as quiet insets.
local function InnerPanels(f, depth)
	if depth > 3 or not f.GetChildren then return end
	for _, c in ipairs({ f:GetChildren() }) do
		if Usable(c) and c.__rcorners then
			local w, h = c:GetSize()
			if type(w) == "number" and type(h) == "number" and w >= 100 and h >= 100 then
				Unround(c)
				if ns.Kit and ns.Once(c) then ns.Kit.Inset(c) end
			end
		end
		if Usable(c) then InnerPanels(c, depth + 1) end
	end
end

local shown = setmetatable({}, { __mode = "k" })

local function Panel(f)
	local Kit, DF = ns.Kit, _G.DetailsFramework
	if not Kit or not Usable(f) or not On() then return end
	if InCombatLockdown() and not shown[f] then
		ns.OutOfCombat(function() Panel(f) end)
		return
	end
	if not shown[f] then
		shown[f] = true
		Unround(f)
		ns.NoBackdrop(f)
		ns.Shell(f, { window = true }, KEY)
		local bar = f.TitleBar
		if Usable(bar) then ns.NoBackdrop(bar) end
		local close = CloseOf(f)
		if close and ns.Controls(KEY) and ns.Once(close) then Guard(Kit.Close, close) end
		local title = TitleOf(f)
		if title then
			Kit.Font(title)
			Kit.Light(title, ns.Colors().VALUE)
		end
		local function pass()
			if not On() or not f:IsShown() then return end
			ns.Dress(f, DRESS, 0, KEY)
			InnerPanels(f, 0)
			if DF then Regold(DF, f, 0) end
		end
		f:HookScript("OnShow", function() C_Timer.After(0, pass) end)
		pass()
		C_Timer.After(0, pass)
	end
end

-- A frame by its global name (a framework panel object is a table holding the frame).
local function Named(name)
	local f = _G[name]
	if type(f) == "table" and not f.GetObjectType and type(f.frame) == "table" then f = f.frame end
	if type(f) == "table" and f.GetObjectType then return f end
	return nil
end

local function PanelNamed(name)
	local f = Named(name)
	if f then Guard(Panel, f) end
end

local BREAKDOWN = { "DetailsBreakdownWindow", "DetailsBreakdownMidnightMainPanel1", "DetailsBreakdownMidnightMainPanel2",
	"DetailsBreakdownMidnightMainPanel3" }

local function Breakdowns()
	for _, n in ipairs(BREAKDOWN) do PanelNamed(n) end
end

local function IsOurs(name)
	return type(name) == "string" and string.sub(name, 1, 7) == "Details"
end

-- ---------------------------------------------------------------------------------------------
-- Its menus and tooltips (Cooltip)
-- ---------------------------------------------------------------------------------------------

local tipShells = setmetatable({}, { __mode = "k" })
local washed = setmetatable({}, { __mode = "k" })

-- The window shell at Daylight UI's tooltip opacity; from Daylight UI 2.0 also at its tooltips'
-- own border size while they have one (ns.TipBorder, Core.lua: 2.0
-- DaylightUI_Tooltip\Tooltip.lua:61-64; nil on 1.9.x and while the tooltips take General's, which
-- is what this shell had before). Gate: ns.DaylightAtLeast(2, 0), in ns.TipBorder.
local function CooltipLook()
	return { bgAlpha = ns.TipAlpha() or 0.9, borderPx = ns.TipBorder() }
end

local function TipFrame(DF, frame)
	if not Usable(frame) then return end
	if not tipShells[frame] then
		tipShells[frame] = true
		ns.Shell(frame, CooltipLook(), KEY)
	end
	Unround(frame)
	if frame.SetBackdropColor and frame.GetBackdrop and frame:GetBackdrop() then
		frame:SetBackdropColor(0, 0, 0, 0)
		frame:SetBackdropBorderColor(0, 0, 0, 0)
	end
	for _, k in ipairs({ "frameBackgroundTexture", "gradientTexture", "frameWallpaper" }) do
		if Kind(frame[k]) == "Texture" then frame[k]:SetAlpha(0) end
	end
	local a = AccentColor(0.22)
	for _, k in ipairs({ "selectedTop", "selectedBottom", "selectedMiddle" }) do
		if Kind(frame[k]) == "Texture" then frame[k]:SetColorTexture(a[1], a[2], a[3], a[4]) end
	end
	local lines = frame.Lines
	if type(lines) == "table" then
		for _, line in ipairs(lines) do
			if Usable(line) and line:IsShown() then
				local bg = line.background
				if Kind(bg) == "Texture" and not washed[bg] then
					washed[bg] = true
					bg:SetColorTexture(1, 1, 1, 0.08)
				end
			end
		end
	end
	if frame:IsShown() then
		for _, r in ipairs({ frame:GetRegions() }) do
			if Kind(r) == "FontString" then
				local cr, cg, cb = r:GetTextColor()
				if Goldish(DF, { cr, cg, cb }) then
					local c = ns.Colors().TEXT
					r:SetTextColor(c[1], c[2], c[3])
				end
			end
		end
		if type(lines) == "table" then
			for _, line in ipairs(lines) do
				if Usable(line) and line:IsShown() then Regold(DF, line, GOLD_DEPTH - 2) end
			end
		end
	end
end

local function Cooltip()
	if not On() then return end
	local DF = _G.DetailsFramework
	local tip = _G.GameCooltip2 or _G.GameCooltip
	if type(DF) ~= "table" or type(tip) ~= "table" then return end
	TipFrame(DF, tip.frame1)
	TipFrame(DF, tip.frame2)
end

-- ---------------------------------------------------------------------------------------------
-- The pack
-- ---------------------------------------------------------------------------------------------

local hooked = false

local function Hooks()
	if hooked then return end
	local D, DF = _G.Details, _G.DetailsFramework
	if type(D) ~= "table" or type(D.ChangeSkin) ~= "function" then return false end
	hooked = true
	-- Every meter window, as Details applies its skin (new, reopened, re-skinned, profile loaded).
	hooksecurefunc(D, "ChangeSkin", function(instance)
		if not On() then return end
		if InCombatLockdown() and not (instance.baseframe and holders[instance.baseframe]) then
			ns.OutOfCombat(function() Guard(Decorate, instance) end)
		else
			Guard(Decorate, instance)
		end
		-- A window not seen before (made now): its settings, next frame.
		if not applying and DetailsReady() then
			local p = Profile(false)
			local id = instance.meu_id
			if not (p and id and p.win[id]) then ApplySoon() end
		end
	end)
	if type(D.CreateEventListener) == "function" then
		local ok, listener = pcall(D.CreateEventListener, D)
		if ok and type(listener) == "table" and listener.RegisterEvent then
			pcall(listener.RegisterEvent, listener, "DETAILS_PROFILE_APPLYED", function() if On() then ApplySoon(0.2) end end)
		end
	end
	-- Its other windows, from the calls that open them.
	if type(D.OpenOptionsWindow) == "function" then
		hooksecurefunc(D, "OpenOptionsWindow", function()
			PanelNamed("DetailsPluginContainerWindow")
			PanelNamed("DetailsOptionsWindow")
		end)
	end
	if type(D.CreatePluginWindowContainer) == "function" then
		hooksecurefunc(D, "CreatePluginWindowContainer", function() PanelNamed("DetailsPluginContainerWindow") end)
	end
	PanelNamed("DetailsPluginContainerWindow")
	if type(D.OpenPlugin) == "function" then
		hooksecurefunc(D, "OpenPlugin", function() PanelNamed("DetailsPluginContainerWindow") end)
	end
	for _, fn in ipairs({ "OpenBreakdownWindow", "OpenSpecificBreakdownWindow" }) do
		if type(D[fn]) == "function" then hooksecurefunc(D, fn, Breakdowns) end
	end
	if type(D.Reportar) == "function" then
		hooksecurefunc(D, "Reportar", function() PanelNamed("DetailsReportWindow") end)
	end
	ns.Watch(KEY, "DetailsWelcomeWindow", function(f) Panel(f) end)
	if type(DF) == "table" then
		-- Panels named "Details...", made by its framework.
		if type(DF.CreateSimplePanel) == "function" then
			hooksecurefunc(DF, "CreateSimplePanel", function(_, _, _, _, _, frameName)
				if IsOurs(frameName) then PanelNamed(frameName) end
			end)
		end
		if type(DF.CreateTitleBar) == "function" then
			hooksecurefunc(DF, "CreateTitleBar", function(_, parent)
				local name = Usable(parent) and parent.GetName and parent:GetName()
				if IsOurs(name) and parent:GetParent() == UIParent then Guard(Panel, parent) end
			end)
		end
		-- Its control templates, now and as more are installed.
		Guard(RecolorAll, DF)
		if type(DF.InstallTemplate) == "function" then
			hooksecurefunc(DF, "InstallTemplate", function(_, category, name)
				if not On() then return end
				local t, isFont = TemplateTable(DF, category)
				if type(t) == "table" then
					local face = isFont and FontFile()
					Guard(RecolorTemplate, DF, t[name], name, isFont, face and MediaName("font", face))
				end
			end)
		end
		-- Its menus and tooltips.
		local tip = _G.GameCooltip2 or _G.GameCooltip
		if type(tip) == "table" and type(tip.ShowCooltip) == "function" then
			hooksecurefunc(tip, "ShowCooltip", function() Guard(Cooltip) end)
		end
	end
	ns.me.On("StyleChanged", function()
		if not On() then return end
		if type(DF) == "table" then Guard(RecolorAll, DF) end
		ApplySoon(0.3)
	end)
	ns.me.On("SettingChanged", function(scope, path)
		if On() and (scope == "InfoPanel" or scope == "general") then ApplySoon(0.3) end
		-- Daylight UI's tooltip opacity (from 2.0 its tooltip border size too) changed: Cooltip's
		-- shells follow.
		if On() and ns.TipLookChanged(scope, path) then
			for frame in pairs(tipShells) do
				if Usable(frame) then ns.Shell(frame, CooltipLook(), KEY) end
			end
		end
	end)
	if DetailsReady() then ApplySoon() end
	return true
end

ns.Pack(KEY, "Details!", function()
	return Hooks()
end, CAPS)

-- ---------------------------------------------------------------------------------------------
-- Hand-over: Daylight UI's own damage meter (Info Panel) is the one shown while both are on
-- ---------------------------------------------------------------------------------------------

local function OpenIds()
	local out = {}
	local D = _G.Details
	for _, instance in ipairs(D:GetAllInstances()) do
		if type(instance) == "table" and instance.IsEnabled and instance:IsEnabled() and instance.baseframe then
			out[#out + 1] = instance.meu_id
		end
	end
	return out
end

ns.Handover(KEY, {
	ready = DetailsReady,
	get = function(key)
		if key ~= "meter" then return nil end
		return #OpenIds() > 0
	end,
	set = function(key, value)
		if key ~= "meter" then return end
		ns.OutOfCombat(function()
			local D = _G.Details
			local db = DB()
			if value == false then
				local ids = OpenIds()
				db.closed = ids
				for _, id in ipairs(ids) do
					local instance = D:GetInstance(id)
					if instance and instance.ShutDown then instance:ShutDown(true) end
				end
			else
				local ids = type(db.closed) == "table" and db.closed or { 1 }
				db.closed = nil
				for _, id in ipairs(ids) do
					local instance = D:GetInstance(tonumber(id) or 1)
					if instance and instance.EnableInstance and not instance:IsEnabled() then instance:EnableInstance() end
				end
			end
		end)
	end,
	list = {
		{ key = "meter", label = L["Damage Meter Windows"], daylight = ns.In(L["its damage meter"], "Info Panel"),
			ours = function() return ns.DaylightHas("InfoPanel", "meter.enabled") end },
	},
})

