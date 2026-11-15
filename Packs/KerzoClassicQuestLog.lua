-- Kerzo Classic Quest Log: its quest log window, its settings, dialogs, What's New, menus and
-- tooltips in the DaylightUI look.
-- The addon re-applies its own art all the time: its theme pass (Barra:AplicarTemaVisual), the
-- window layout pass, and every refresh of the bar, list and detail panels re-show its frames,
-- set their alpha back to 1 and set their atlases again. So its art is taken off with
-- DaylightUI's eraser (a see-through mask that outlasts any Show, SetAlpha or new art), and the
-- colors it sets are put back to ours after each of those passes.
-- Its theme is kept on Dark while this skin is on (its light text for a dark window: every part
-- that tests for a dark theme draws bright text); the theme it had is given back when the skin is
-- turned off (at the next login).
-- Dressed here:
--   * The window (ButtonFrameTemplate): portrait, book icon, stone ground, gold frame and inset
--     off, the window shell, its title in the value ink, the X DaylightUI's (its minimize art,
--     set again on every theme pass, erased).
--   * The top bar: the quest counter box (its inset art off, a box of the input look; the ready
--     count keeps its green), the icon buttons' gold square hover a white wash, the Abandon /
--     Share / Track / Close buttons DaylightUI's (white when on, gray when off), the center
--     divider of the two-column layout (its gold line faint, its arrow in the text ink, the accent
--     under the mouse), the What's New button.
--   * The quest list: its parchment / dark ground and inset art off, an inset well; every row a
--     faint white wash under the mouse; the picked quest's bar in the accent (not its difficulty
--     color); headings in the label ink, their fold arrows in the text ink, the plus glow off; the
--     tracked check in the accent; the expand-all tab's art off, its + / - in the text ink. Quest
--     difficulty colors, the multi-select green check, the ready / failed / daily tags, the
--     time-left red and the quick-abandon X stay. The search box, its X and the bulk-action
--     buttons DaylightUI's; the search label in the label ink; the hidden-quests eye's hover a
--     wash.
--   * The detail panel: ground and inset art off, an inset well; the quest title in the title
--     ink, the section headings in the label ink; each reward's parchment name plate a flat box of
--     the input look (quality edge, best-price ring and coin kept); the spell objective's plate
--     and gold rim off; the party progress box quiet; the quest chain's hover a wash and its dark
--     brown / red / green / blue words lightened so they read on a dark ground; the integration
--     buttons' gold slot rings off; the hidden tab's arrow in the text ink; the Questie card a
--     flat dark box; the quest item button's gold rim neutral.
--   * Settings (its own window, or inside the game's Settings): the window shell; the section
--     headings flat (open: a brighter box and value ink; closed: text ink; hover lighter), their
--     + / - in the text ink, the gold glow off; its drawn checkboxes a box of the input look with an
--     accent square when on (dim when locked or off), names in the label ink (value under the
--     mouse, gray when unavailable), lines in the text ink; the two layout cards with the picked
--     one's edge in the accent; the old-style dropdowns, sliders, small checkboxes and buttons
--     DaylightUI's; the integrations box, add-on sub-headings and KQE banner quiet flat boxes;
--     labels in the label ink; the header's gold color code taken out. The mascot watermark stays.
--   * Dialogs (abandon, About, Forever notice, reset, difficulty colors, the KQE download window):
--     the window shell, their buttons, boxes and scroll bars DaylightUI's, titles in the value ink;
--     logos, alert icons and the difficulty swatches and preview colors stay.
--   * What's New: the window shell; the parchment cards flat dark boxes with light words; the
--     notice and scroll boxes quiet; buttons, box, X and scroll bar DaylightUI's. The mascot, its
--     speech bubble and the green NEW badge stay.
--   * Its right-click menu: a flat dark box, a neutral edge, the hover in the accent, titles in the
--     label ink.
--   * Its tooltip and compare tooltips: made as it loads so DaylightUI's tooltip skin takes them
--     (DaylightUI only finds tooltips that exist at the first loading screen).
-- Not here: the minimap button (DaylightUI's addon button drawer), the copy / chain popups
-- (the game's StaticPopup, DaylightUI's), the quest marks over nameplates and the lines it adds
-- to item tooltips (its content), Spoken's play buttons (Spoken's), the campaign panel and weekly
-- tracker (Retail only: never shown on this client), the gamepad focus frame (gamepad only).
local _, ns = ...
if not ns.ok then return end

local KEY = "Kerzo Classic Quest Log"
-- Its words in the player's font: it puts its own fonts back on every refresh (its font setting),
-- so the player's goes on right after, in the same two calls of its own every text goes through.
-- A font picked in its own settings (OpenDyslexic, Arial...) is the player's choice and stays; its
-- "Default" (the game's font) is the one that turns into DaylightUI's.
local CAPS = { window = true, controls = true, text = true, shadow = true, font = "daylight" }
ns.Target(KEY, "Kerzo Classic Quest Log", CAPS)

local Usable = ns.Usable
local FLAT = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
local DARK = { dark = true, elvui = true, ellesmere = true }

local function On() return ns.Enabled(KEY) end
local function Kind(x) return Usable(x) and x:GetObjectType() or nil end
local function IsTexture(x) return Kind(x) == "Texture" end

local function Ink(fs, name)
	if Kind(fs) ~= "FontString" then return end
	local c = ns.Colors()[name]
	if c then fs:SetTextColor(c[1], c[2], c[3]) end
end

local function Wash(tex, alpha)
	if not IsTexture(tex) then return end
	tex:SetColorTexture(1, 1, 1, alpha)
	tex:SetBlendMode("BLEND")
end

local function Quiet(tex)
	if IsTexture(tex) then tex:SetColorTexture(1, 1, 1, 0.08) end
end

-- Gold art kept for its shape (+ / -, arrows), in the text ink.
local function Tint(tex, ink)
	if not IsTexture(tex) then return end
	tex:SetDesaturated(true)
	local c = ns.Colors()[ink or "TEXT"]
	if c then tex:SetVertexColor(c[1], c[2], c[3]) end
end

local function AccentTint(tex)
	if not IsTexture(tex) then return end
	tex:SetDesaturated(true)
	tex:SetVertexColor(ns.AccentOf(KEY))
end

local function Erase(tex)
	local Kit = ns.Kit
	if Kit and IsTexture(tex) then Kit.Erase(tex) end
end

-- Every texture a frame holds itself.
local function EraseAll(f)
	if not Usable(f) or not f.GetRegions then return end
	for _, r in ipairs({ f:GetRegions() }) do
		if IsTexture(r) then Erase(r) end
	end
end

local function EraseNine(f)
	if Usable(f) and Usable(f.NineSlice) then EraseAll(f.NineSlice) end
end

-- Inline color codes out of a string it builds itself (|cffffd200Title|r |cff888888v1|r).
local function Plain(fs)
	if Kind(fs) ~= "FontString" then return end
	local text = fs:GetText()
	if type(text) ~= "string" or not text:find("|c", 1, true) then return end
	fs:SetText((text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")))
end

-- One of its inline color codes swapped for one of DaylightUI's inks (the rest of the string kept).
local function Hex(ink)
	local c = ns.Colors()[ink]
	if not c then return nil end
	return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end
local function Recode(fs, code, ink)
	if Kind(fs) ~= "FontString" then return end
	local text, hex = fs:GetText(), Hex(ink)
	if type(text) ~= "string" or not hex then return end
	local out = text:gsub(code, hex)
	if out ~= text then fs:SetText(out) end
end

-- A box of the input look under a frame (a child below its level: the frame's own art and words
-- stay on top). Kept apart from its backdrop, which the addon clears and sets again.
local function Box(f, inset)
	local Kit = ns.Kit
	if not Kit or not Usable(f) then return end
	local box = CreateFrame("Frame", nil, f)
	box:SetPoint("TOPLEFT", f, "TOPLEFT", inset or 0, -(inset or 0))
	box:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -(inset or 0), inset or 0)
	box:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
	box:EnableMouse(false)
	Kit.Shell(box, "input")
	return box
end

-- A flat dark box in place of a tooltip-border backdrop.
local function FlatBox(f, alpha)
	if not Usable(f) or not f.SetBackdrop then return end
	if ns.Once(f) then f:SetBackdrop(FLAT) end
	ns.Soften(f, alpha)
end

-- The template text buttons' art (UIPanelButtonTemplate, MagicButtonTemplate), kept out of sight
-- through the addon's own "flat button" passes, which set every piece's alpha back to 1.
local PIECES = { "Left", "Middle", "Right", "LeftSeparator", "RightSeparator" }
local BUTTON_ART = { "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }
local function EraseButtonArt(b)
	if not Usable(b) then return end
	local name = b.GetName and b:GetName()
	for _, k in ipairs(PIECES) do
		Erase(b[k])
		if name then Erase(_G[name .. k]) end
	end
	-- (DaylightUI's button look is drawn on textures of its own: the game's four go for good.)
	for _, get in ipairs(BUTTON_ART) do
		if b[get] then Erase(b[get](b)) end
	end
end

local function TextButton(b, Kit)
	if not Usable(b) then return end
	if ns.Once(b) then Kit.Button(b) end
	EraseButtonArt(b)
end

-- ---------------------------------------------------------------------------------------------
-- Theme: Dark while the skin is on
-- ---------------------------------------------------------------------------------------------

local function DB()
	local db = _G.DaylightAddonSkinsDB
	if type(db) ~= "table" then
		db = {}
		_G.DaylightAddonSkinsDB = db
	end
	return db
end

local function KeepDark(kql)
	local api = _G.KerzosQuestLogAPI
	if not api or type(kql.TemaVisual) ~= "function" then return end
	local ok, theme = pcall(kql.TemaVisual, kql)
	if not ok or DARK[theme] then return end
	local db = DB()
	if db.kcqlTheme == nil then db.kcqlTheme = theme end
	pcall(api.ApplyTheme, api, "dark")
end

-- At login with the skin off: its own theme back, once.
local function GiveThemeBack(kql)
	local db = DB()
	local was = db.kcqlTheme
	if was == nil then return end
	db.kcqlTheme = nil
	local api = _G.KerzosQuestLogAPI
	if api and type(kql.TemaVisual) == "function" and kql:TemaVisual() == "dark" then
		pcall(api.ApplyTheme, api, was)
	end
end

-- ---------------------------------------------------------------------------------------------
-- The window and its top bar
-- ---------------------------------------------------------------------------------------------

local WINDOW_ART = { "Bg", "TopTileStreaks", "IconLibro", "ElvuiFondo", "ElvuiBarraSuperior",
	"VanillaBgTopLeft", "VanillaBgTopRight", "VanillaBgBotLeft", "VanillaBgBotRight" }
local ICON_BUTTONS = { "BotonConfig", "BotonMapaMundi", "BotonFastAbandon", "BotonShowNameplates", "BotonWeeklyTracker" }

local function CloseArt(btn)
	if not Usable(btn) then return end
	for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }) do
		local art = btn[get] and btn[get](btn)
		Erase(art)
	end
end

local function Divider(kql)
	local d = kql.DivisorCentral
	if not Usable(d) or not ns.Once(d) then return end
	local function paint()
		if not On() then return end
		local over = d:IsMouseOver()
		-- (Both are WHITE8X8 its own scripts tint: tinted again after them.)
		if IsTexture(d.Linea) then
			if over then
				local r, g, b = ns.AccentOf(KEY)
				d.Linea:SetVertexColor(r, g, b, 0.8)
			else
				d.Linea:SetVertexColor(1, 1, 1, 0.12)
			end
		end
		if IsTexture(d.FlechaFondo) then d.FlechaFondo:SetVertexColor(0, 0, 0, 0.3) end
		Tint(d.Flecha, over and "VALUE" or "TEXT")
	end
	d:HookScript("OnEnter", paint)
	d:HookScript("OnLeave", paint)
	paint()
end

local function Bar(kql, Kit)
	local bar = kql.Barra
	if not Usable(bar) then return end
	local ind = bar.IndicadorMisiones
	if Usable(ind) then
		EraseNine(ind)
		EraseAll(ind)
		if ns.Once(ind) then Box(ind) end
		Ink(ind.Text, "LABEL")
		-- (The vanilla layout's label is gold inline; the counts' white and the ready green stay.)
		Recode(ind.Text, "|cffffd100", "LABEL")
	end
	local grip = bar.AsaRedimensionar
	if Usable(grip) then
		for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture" }) do
			local tex = grip[get] and grip[get](grip)
			if IsTexture(tex) then tex:SetDesaturated(true) end
		end
	end
	local radio = bar.ControlSeguirVanilla
	if Usable(radio) then Tint(radio.RadioRing, "LABEL") end
	for _, k in ipairs(ICON_BUTTONS) do
		local b = bar[k]
		if Usable(b) and b.GetHighlightTexture then Wash(b:GetHighlightTexture(), 0.1) end
	end
	if type(bar.ArrayBotonesAccion) == "table" then
		for _, b in ipairs(bar.ArrayBotonesAccion) do
			TextButton(b, Kit)
			local fs = b.Text or (b.GetFontString and b:GetFontString())
			Ink(fs, b:IsEnabled() and "VALUE" or "OFF")
		end
	end
end

local function Chrome(kql, Kit)
	if not On() then return end
	EraseNine(kql)
	for _, k in ipairs(WINDOW_ART) do Erase(kql[k]) end
	local pc = kql.PortraitContainer
	if Usable(pc) then
		EraseAll(pc)
		for _, c in ipairs({ pc:GetChildren() }) do EraseAll(c) end
	end
	if Usable(kql.Inset) then
		EraseNine(kql.Inset)
		Erase(kql.Inset.Bg)
	end
	local tc = kql.TitleContainer
	if Usable(tc) then Ink(tc.TitleText, "VALUE") end
	CloseArt(_G.KerzosQuestLogCloseButton or kql.CloseButton)
	Bar(kql, Kit)
	Divider(kql)
	local news = kql.BotonNovedadesCabecera
	if Usable(news) then
		TextButton(news, Kit)
		if IsTexture(news.tinteNov) then
			local r, g, b = ns.AccentOf(KEY)
			news.tinteNov:SetColorTexture(r, g, b, 0.15)
		end
		Plain(news.GetFontString and news:GetFontString())
	end
end

-- ---------------------------------------------------------------------------------------------
-- Quest list
-- ---------------------------------------------------------------------------------------------

local rowWash = setmetatable({}, { __mode = "k" })

local function ListRow(row)
	if not rowWash[row] then
		local w = row:CreateTexture(nil, "HIGHLIGHT")
		w:SetAllPoints(row)
		w:SetColorTexture(1, 1, 1, 0.05)
		rowWash[row] = w
		Erase(row.BrilloExpandir)
	end
	local info = row.info
	if type(info) ~= "table" then return end
	if info.isHeader then
		Ink(row.Text, "LABEL")
		Tint(row.BotonExpandir)
		return
	end
	local sel = row.Seleccion
	if IsTexture(sel) and sel:IsShown() then
		local r, g, b = ns.AccentOf(KEY)
		sel:SetColorTexture(r, g, b, 0.2)
		-- (It tints the bar by the quest's difficulty first; that tint would multiply in.)
		sel:SetVertexColor(1, 1, 1, 1)
		sel:SetBlendMode("BLEND")
	end
	AccentTint(row.Marca)
end

-- Its scroll bars' track pieces, which its theme pass shows again (Track.Middle at 0.2).
local function Track(sf)
	local bar = Usable(sf) and sf.ScrollBar
	local track = Usable(bar) and bar.Track
	if not Usable(track) then return end
	for _, k in ipairs({ "Begin", "Middle", "End" }) do Erase(track[k]) end
end

local function List(kql, Kit)
	local p = kql.RegistroMisiones
	if not Usable(p) or not On() then return end
	EraseNine(p)
	Erase(p.Bg)
	Erase(p.Back)
	if ns.Once(p) then
		Kit.Inset(p)
		local sf = p.ScrollFrame
		if Usable(sf) and Usable(sf.ScrollBar) then Kit.ScrollBar(sf.ScrollBar) end
	end
	Track(p.ScrollFrame)
	local content = p.ScrollFrame and p.ScrollFrame.Content
	if Usable(content) and type(content.Buttons) == "table" then
		for _, row in ipairs(content.Buttons) do
			if Usable(row) and row:IsShown() then ListRow(row) end
		end
	end
	local all = p.BotonExpandirTodo
	if Usable(all) then
		if type(all.KQLTexturasTab) == "table" then
			for _, t in pairs(all.KQLTexturasTab) do Erase(t) end
		end
		Tint(all:GetNormalTexture())
		Tint(all:GetPushedTexture())
		Tint(all:GetDisabledTexture(), "OFF")
		Wash(all:GetHighlightTexture(), 0.08)
		Ink(all:GetFontString(), "LABEL")
	end
	local bulk = p.BarraMasiva
	if Usable(bulk) then
		for _, k in ipairs({ "BotonCerrar", "BotonOcultar", "BotonAbandonar" }) do TextButton(bulk[k], Kit) end
	end
end

local function Search(kql, Kit)
	local p = kql.RegistroMisiones
	if not Usable(p) or not On() then return end
	if Usable(p.InputBusqueda) and ns.Once(p.InputBusqueda) then Kit.EditBox(p.InputBusqueda) end
	TextButton(p.BotonLimpiar, Kit)
	Ink(p.SearchLabel, "LABEL")
	local eye = p.BotonOcultas
	if Usable(eye) and eye.GetHighlightTexture then Wash(eye:GetHighlightTexture(), 0.1) end
end

-- ---------------------------------------------------------------------------------------------
-- Detail panel
-- ---------------------------------------------------------------------------------------------

-- Its quest-chain lines are written in dark inks for parchment: each made light.
local CHAIN_INKS = {
	["|cff8b0000"] = "|cffff7070", ["|cff1b6e1b"] = "|cff66d066", ["|cff104e8b"] = "|cff78b4ec",
	["|cff4a3b2c"] = "|cffc8bca8",
}
local function LightChain(fs)
	if Kind(fs) ~= "FontString" then return end
	local text = fs:GetText()
	if type(text) ~= "string" then return end
	local out = text:gsub("|cff%x%x%x%x%x%x", function(code) return CHAIN_INKS[code:lower()] or code end)
	if out ~= text then fs:SetText(out) end
end

local function Chain(v)
	local content = v.ScrollFrame and v.ScrollFrame.Content
	local chain = content and content.QuestChainFrame
	if not Usable(chain) then return end
	Ink(chain.cabecera, "LABEL")
	if type(chain.filas) == "table" then
		for _, row in ipairs(chain.filas) do
			if Usable(row) then
				Wash(row.resaltado, 0.06)
				LightChain(row.texto)
			end
		end
	end
end

local function Party(v)
	local content = v.ScrollFrame and v.ScrollFrame.Content
	local party = content and content.PartyProgressFrame
	if not Usable(party) then return end
	Ink(party.cabecera, "LABEL")
	if Usable(party.caja) then ns.Soften(party.caja, 0.3) end
end

local function AuxBar(v)
	local aux = _G.KQL_BarraAuxiliarDetalle or v.BarraAuxiliar
	if Usable(aux) then
		if IsTexture(aux.Fondo) and ns.Once(aux.Fondo) then aux.Fondo:SetColorTexture(0.1, 0.1, 0.11, 1) end
		for _, r in ipairs({ aux:GetRegions() }) do
			if IsTexture(r) and r ~= aux.Fondo and r:GetDrawLayer() == "BORDER" then Quiet(r) end
		end
	end
	local tab = _G.KQL_PestanhaBarraAuxiliar or v.PestanhaBarraAuxiliar
	if Usable(tab) then
		Tint(tab.Flecha, tab:IsMouseOver() and "VALUE" or "TEXT")
		if ns.Once(tab) then
			tab:HookScript("OnEnter", function() if On() then Tint(tab.Flecha, "VALUE") end end)
			tab:HookScript("OnLeave", function() if On() then Tint(tab.Flecha, "TEXT") end end)
		end
	end
end

local INTEGRATIONS = { "KQL_BotonQuestieDetalle", "KQL_BotonTomTomDetalle", "KQL_BotonForeverHUNDetalle" }

local function Detail(kql, Kit)
	local v = kql.VisorDetalle
	if not Usable(v) or not On() then return end
	EraseNine(v)
	Erase(v.Bg)
	Erase(v.Back)
	if ns.Once(v) then
		Kit.Inset(v)
		local sf = v.ScrollFrame
		if Usable(sf) and Usable(sf.ScrollBar) then Kit.ScrollBar(sf.ScrollBar) end
	end
	Track(v.ScrollFrame)
	local c = v.ScrollFrame and v.ScrollFrame.Content
	if Usable(c) then
		Ink(c.TitleHeader, "TITLE")
		Ink(c.DescriptionHeader, "LABEL")
		if Usable(c.RewardsFrame) then Ink(c.RewardsFrame.Header, "LABEL") end
		local special = c.SpecialObjectivesFrame
		if Usable(special) and Usable(special.SpellObjectiveFrame) then
			Erase(special.SpellObjectiveFrame.NameFrame)
			Erase(special.SpellObjectiveFrame.SpellBorder)
		end
	end
	Party(v)
	Chain(v)
	AuxBar(v)
	for _, name in ipairs(INTEGRATIONS) do
		local b = _G[name]
		if Usable(b) then
			Erase(b.Borde)
			Wash(b.Resalte, 0.1)
		end
	end
	local item = _G.KQLBotonObjetoMision
	if Usable(item) and IsTexture(item.Border) then item.Border:SetVertexColor(0.5, 0.5, 0.5) end
end

-- A reward button (pooled; filled one by one): its parchment name plate off, a flat box under it.
local function Reward(btn)
	if not Usable(btn) or not On() then return end
	Erase(btn.Back)
	if ns.Once(btn) then Box(btn, 1) end
end

local function Card()
	local card = _G.KQL_CardTooltipQuestie
	if not Usable(card) or not On() then return end
	if ns.Once(card) then card:SetBackdrop(FLAT) end
	card:SetBackdropColor(0.06, 0.06, 0.07, 0.96)
	card:SetBackdropBorderColor(1, 1, 1, 0.1)
	Quiet(card.Separador)
	Ink(card.Cabecera, "VALUE")
end

-- ---------------------------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------------------------

-- Its drawn checkbox (KQLCasillaOpcionTemplate: box, glow and check textures on a Button).
local casillas = setmetatable({}, { __mode = "k" })

local function PaintCasilla(row)
	local s = casillas[row]
	if not s then return end
	local on = IsTexture(row.CheckMark) and row.CheckMark:IsShown()
	s.fill:SetColorTexture(ns.AccentOf(KEY))
	s.fill:SetShown(on)
	local off = row.deshabilitada == true
	s.box:SetAlpha(off and 0.4 or 1)
	s.fill:SetAlpha((off or row.bloqueadoActivo) and 0.5 or 1)
	if row:IsMouseOver() and not off then
		Ink(row.Text, "VALUE")
	else
		Ink(row.Text, off and "OFF" or "LABEL")
	end
	Ink(row.Desc, off and "OFF" or "TEXT")
end

local function Casilla(row, Kit)
	if not Usable(row) then return end
	if not casillas[row] then
		local box = IsTexture(row.CheckButton) and row.CheckButton
		if not box then return end
		local holder = CreateFrame("Frame", nil, row)
		holder:SetSize(16, 16)
		holder:SetPoint("CENTER", box, "CENTER", 0, 0)
		holder:EnableMouse(false)
		Kit.Shell(holder, "input")
		local fill = holder:CreateTexture(nil, "OVERLAY")
		fill:SetSize(8, 8)
		fill:SetPoint("CENTER")
		casillas[row] = { box = holder, fill = fill }
		local function paint() if On() then PaintCasilla(row) end end
		if IsTexture(row.CheckMark) then
			hooksecurefunc(row.CheckMark, "Show", paint)
			hooksecurefunc(row.CheckMark, "Hide", paint)
			hooksecurefunc(row.CheckMark, "SetShown", paint)
		end
		row:HookScript("OnEnter", paint)
		row:HookScript("OnLeave", paint)
	end
	-- (Its theme pass sets the atlases, alpha and color of these again on every refresh.)
	Erase(row.CheckButton)
	Erase(row.Highlight)
	Erase(row.CheckMark)
	PaintCasilla(row)
end

local function PaintHeader(sec)
	local h = sec.Cabecera
	if not Usable(h) then return end
	local open = Usable(sec.Cuerpo) and sec.Cuerpo:IsShown()
	local over = h:IsMouseOver()
	h:SetBackdropColor(1, 1, 1, over and 0.08 or open and 0.06 or 0.03)
	local a = open and 0.14 or 0.08
	if type(h.EstablecerColorBorde) == "function" then
		pcall(h.EstablecerColorBorde, h, 1, 1, 1, over and 0.2 or a)
	end
	Ink(h.Texto, (open or over) and "VALUE" or "TEXT")
	Tint(h.Icono, (open or over) and "VALUE" or "TEXT")
end

local function Header(sec)
	local h = sec.Cabecera
	if not Usable(h) then return end
	if ns.Once(h) then
		h:SetBackdrop(FLAT)
		Erase(h.Resalte)
		h:HookScript("OnEnter", function() if On() then PaintHeader(sec) end end)
		h:HookScript("OnLeave", function() if On() then PaintHeader(sec) end end)
	end
	PaintHeader(sec)
end

-- The two layout cards: the picked one (the window style in use) with the accent edge.
local function Cards(kql)
	local content = kql.PanelAjustes and kql.PanelAjustes.ScrollFrame and kql.PanelAjustes.ScrollFrame.Content
	if not Usable(content) then return end
	local vanilla = type(kql.cfg) == "table" and kql.cfg.EstiloVentana == "vanilla"
	for _, k in ipairs({ "TarjetaVanilla", "TarjetaClassic" }) do
		local card = content[k]
		if Usable(card) and card.SetBackdropBorderColor then
			local picked = (k == "TarjetaVanilla") == vanilla
			local r, g, b = ns.AccentOf(KEY)
			if picked then
				card:SetBackdropBorderColor(r, g, b, 1)
			else
				card:SetBackdropBorderColor(1, 1, 1, card:IsMouseOver() and 0.3 or 0.12)
			end
			card:SetBackdropColor(1, 1, 1, 0.04)
			if IsTexture(card.Resalte) then card.Resalte:SetColorTexture(r, g, b, 0.12) end
			Ink(card.Etiqueta, picked and "VALUE" or "TEXT")
			if ns.Once(card) then
				card:HookScript("OnEnter", function() if On() then Cards(kql) end end)
				card:HookScript("OnLeave", function() if On() then Cards(kql) end end)
			end
		end
	end
end

local DROPDOWNS = { "KQL_ThemeDropdown", "KQL_LanguageDropdown", "KQL_FontDropdown", "KQL_TrackerDropdown",
	"KQL_ReadyHeadersDropdown", "KQL_ReadyStyleDropdown", "KQL_PresetDropdown", "KQL_LayoutDropdown" }
local LABELS = { "LayoutLabel", "ThemeLabel", "LanguageLabel", "FontLabel", "TrackerLabel", "ReadyHeadersLabel",
	"ReadyStyleLabel", "PresetLabel" }

local function Settings(kql, Kit)
	local panel = kql.PanelAjustes
	if not Usable(panel) or not On() then return end
	local content = panel.ScrollFrame and panel.ScrollFrame.Content
	if not Usable(content) then return end
	local head = panel.CabeceraAjustes
	if Usable(head) then
		Plain(head.Titulo)
		Ink(head.Titulo, "VALUE")
		Ink(head.Subtitulo, "TEXT")
		Quiet(head.Linea)
	end
	if type(content.PanelesCategorias) == "table" then
		for _, sec in pairs(content.PanelesCategorias) do
			if Usable(sec) then Header(sec) end
		end
	end
	if type(content.CheckButtons) == "table" then
		for _, row in ipairs(content.CheckButtons) do Casilla(row, Kit) end
	end
	Cards(kql)
	for _, name in ipairs(DROPDOWNS) do
		local dd = _G[name]
		if Usable(dd) then
			if ns.OldDropdown then ns.OldDropdown(dd) end
			-- (Its theme pass sets every piece of these back to full alpha.)
			for _, k in ipairs({ "Left", "Middle", "Right" }) do
				Erase(dd[k])
				Erase(_G[name .. k])
			end
		end
	end
	for _, k in ipairs(LABELS) do
		local fs = content[k]
		-- (A label it grays because its control is off stays gray.)
		if Kind(fs) == "FontString" then
			local r = fs:GetTextColor()
			if r > 0.6 then Ink(fs, "LABEL") end
		end
	end
	for _, k in ipairs({ "ScaleSlider", "FontSizeSlider" }) do
		local s = content[k]
		if Usable(s) then
			if ns.Slider then ns.Slider(s) end
			Ink(s.Label, "LABEL")
		end
	end
	local box = content.CajaIntegraciones
	if Usable(box) then
		FlatBox(box, 0.3)
		Ink(box.Titulo, "LABEL")
		if type(box.Filas) == "table" then
			for _, f in ipairs(box.Filas) do
				local row = type(f) == "table" and f.marco
				if Usable(row) then
					for _, r in ipairs({ row:GetRegions() }) do
						if IsTexture(r) and r:GetDrawLayer() == "HIGHLIGHT" then Wash(r, 0.06) end
					end
				end
			end
		end
	end
	local banner = content.BannerKQE
	if Usable(banner) then
		FlatBox(banner, 0.3)
		if IsTexture(banner.BordeIzq) then banner.BordeIzq:SetColorTexture(ns.AccentOf(KEY)) end
		Ink(banner.Titulo, "VALUE")
		Ink(banner.Desc, "TEXT")
	end
	local third = _G.KQLSeccion_THIRD_PARTY
	if Usable(third) and type(third.SubCabeceras) == "table" then
		local opened = type(content.SubSeccionesAbiertas) == "table" and content.SubSeccionesAbiertas or {}
		for id, sub in pairs(third.SubCabeceras) do
			if Usable(sub) then
				FlatBox(sub, 0.25)
				local open = opened[id] ~= false
				Ink(sub.Texto, open and "VALUE" or "TEXT")
				Tint(sub.Icono, open and "VALUE" or "TEXT")
			end
		end
	end
	-- Its theme pass colors three buttons' words (gold About and Difficulty colors, orange Reset).
	for k, ink in pairs({ AboutButton = "VALUE", DifficultyColorsButton = "VALUE", ResetDefaultsButton = "WARN" }) do
		local b = content[k]
		if Usable(b) then Ink(b.Text or (b.GetFontString and b:GetFontString()), b:IsEnabled() and ink or "OFF") end
	end
end

-- Locales whose letters only the game's fonts have: Kerzo's own font choice there stays.
local LOCAL_FONTS = { koKR = true, zhCN = true, zhTW = true, ruRU = true }

-- Whether its words get the player's font now: the skin on, a text look, its own pick "Default"
-- and a locale DaylightUI's fonts have the letters of.
local function Ours(kql)
	if not On() or ns.PlainText(KEY) then return false end
	local locale = _G.GetLocale and _G.GetLocale() or ""
	if LOCAL_FONTS[locale] then return false end
	local ok, pick = pcall(kql.ObtenerFuenteSeleccionada, kql)
	return ok and (pick == nil or pick == "default")
end

-- Every string in one of its windows, Kerzo's own font calls or not (its settings checkboxes,
-- the URL box, menu rows, What's New): only while its pick is "Default" (a font picked there
-- stays on what it reaches).
local function WindowFonts(f)
	local kql = _G.KerzosQuestLog
	if Usable(f) and Usable(kql) and type(kql.ObtenerFuenteSeleccionada) == "function" and Ours(kql) then
		ns.FontsIn(f, KEY)
	end
end

-- Now and on every show (rows and boxes it fills in late). Once per window.
local fontsFollowed = setmetatable({}, { __mode = "k" })
local function FollowWindowFonts(f)
	if not Usable(f) then return end
	WindowFonts(f)
	if fontsFollowed[f] then return end
	fontsFollowed[f] = true
	f:HookScript("OnShow", function(self) WindowFonts(self) end)
end

-- Its settings window (the panel above is moved into it on each show).
local function SettingsWindow(f, Kit)
	ns.NoBackdrop(f)
	for _, r in ipairs({ f:GetRegions() }) do
		if IsTexture(r) and r ~= f.MascotaFondo and r:GetDrawLayer() == "BACKGROUND" then ns.Kill(r) end
	end
	ns.Shell(f, { window = true }, KEY)
	local close = ns.FindClose(f)
	if close and ns.Once(close) then Kit.Close(close) end
	if ns.Walk then ns.Walk(Kit, f, nil, nil, nil, KEY) end
	FollowWindowFonts(f)
end

-- ---------------------------------------------------------------------------------------------
-- Dialogs, What's New, the menu
-- ---------------------------------------------------------------------------------------------

-- A dialog made from DialogBorderDarkTemplate (the frame is the nine-slice itself): its art off,
-- the window shell, its controls by DaylightUI's walk. keep: textures of its own to leave.
local function Dialog(f, Kit, keep, after)
	if not Usable(f) or not ns.Once(f) then return end
	-- (keep: the texture keys Kit.Window leaves, by name.)
	Kit.Window(f, { keep = keep or {} })
	Ink(f.Title or f.Titulo, "VALUE")
	if ns.Walk then ns.Walk(Kit, f, nil, after, nil, KEY) end
	FollowWindowFonts(f)
end

-- A window drawn on a dialog backdrop with a solid plate under it.
local function BackdropWindow(f, Kit, after)
	if not Usable(f) or not ns.Once(f) then return end
	ns.NoBackdrop(f)
	for _, r in ipairs({ f:GetRegions() }) do
		if IsTexture(r) and r:GetDrawLayer() == "BACKGROUND" then ns.Kill(r) end
	end
	ns.Shell(f, { window = true }, KEY)
	local close = f.BotonCerrarX or ns.FindClose(f)
	if Usable(close) and ns.Once(close) then Kit.Close(close) end
	if ns.Walk then ns.Walk(Kit, f, nil, after, nil, KEY) end
	FollowWindowFonts(f)
end

-- Its boxes inside a window (tooltip-border backdrops, flat bronze-edged ones): quiet flat boxes.
local function QuietBoxes(f, depth)
	if not Usable(f) or (depth or 0) > 3 then return end
	for _, c in ipairs({ f:GetChildren() }) do
		if Usable(c) and c.GetBackdrop and c:GetBackdrop() and not (c.IsProtected and c:IsProtected()) then
			FlatBox(c, 0.3)
		end
		QuietBoxes(c, (depth or 0) + 1)
	end
end

local function Download(f)
	if not On() then return end
	QuietBoxes(f)
	Ink(f.Titulo, "VALUE")
	Ink(f.Subtitulo, "TEXT")
	Ink(f.FeaturesHeader, "LABEL")
	Ink(f.FeaturesList, "TEXT")
	Ink(f.Explicacion, "TEXT")
	Ink(f.TextoNotas, "TEXT")
	local r, g, b = ns.AccentOf(KEY)
	for _, k in ipairs({ "bordeIzqFeat", "bordeIzqNotas" }) do
		if IsTexture(f[k]) then f[k]:SetColorTexture(r, g, b, 0.8) end
	end
	Quiet(f.lineaBanner)
	Recode(f.TextoNotas, "|cffffd200", "LABEL")
	Recode(f.FeaturesList, "|cffd4af37", "LABEL")
end

local function Colors(f)
	if not On() then return end
	Ink(f.Desc, "TEXT")
	Ink(f.TextoTituloPreview, "LABEL")
	QuietBoxes(f)
end

local function News(f)
	if not On() then return end
	Plain(f.Titulo)
	Ink(f.Titulo, "VALUE")
	Ink(f.TxtAvisoIngles, "LABEL")
	Ink(f.TxtVisitaWeb, "LABEL")
	Quiet(f.sepTop)
	QuietBoxes(f)
	if type(f.Pergaminos) == "table" then
		for _, card in ipairs(f.Pergaminos) do
			if Usable(card) then
				FlatBox(card, 0.3)
				if IsTexture(card.fondoBase) then card.fondoBase:SetColorTexture(1, 1, 1, 0.03) end
				Erase(card.texPapiro)
				Quiet(card.lineaTinta)
				Plain(card.cabVersion)
				Ink(card.cabVersion, "VALUE")
				if type(card.filas) == "table" then
					for _, row in ipairs(card.filas) do
						if type(row) == "table" then
							Ink(row.TxtDesc, "TEXT")
							-- (Its bullet is an unnamed bullet string beside the line, in dark brown.)
							if row.GetRegions then
								for _, r in ipairs({ row:GetRegions() }) do
									if Kind(r) == "FontString" and r ~= row.TxtDesc then Ink(r, "LABEL") end
								end
							end
						end
					end
				end
			end
		end
	end
end

local function Menu()
	local m = _G.KQLMenuContextualFlotante
	if not Usable(m) or not On() then return end
	-- (Its rows go through its font calls; this catches any that don't.)
	WindowFonts(m)
	if m.SetBackdropColor then
		m:SetBackdropColor(0.06, 0.06, 0.07, 0.97)
		m:SetBackdropBorderColor(1, 1, 1, 0.1)
	end
	if type(m.filas) ~= "table" then return end
	local r, g, b = ns.AccentOf(KEY)
	for _, row in ipairs(m.filas) do
		if Usable(row) and row:IsShown() then
			if IsTexture(row.fondoHover) then row.fondoHover:SetColorTexture(r, g, b, 0.18) end
			Quiet(row.lineaSep)
			local fs = row.texto
			if Kind(fs) == "FontString" then
				local tr, tg, tb = fs:GetTextColor()
				if tr > 0.95 and tg > 0.75 and tg < 0.9 and tb < 0.2 then Ink(fs, "LABEL") end
			end
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- Wiring
-- ---------------------------------------------------------------------------------------------

local function Hook(owner, method, fn)
	if type(owner) == "table" and type(owner[method]) == "function" then
		hooksecurefunc(owner, method, fn)
		return true
	end
end

-- With the skin off, nothing of the pack runs (its watches and skin function are skipped): its
-- own theme is given back from here, once the world is up.
local giveBack = CreateFrame("Frame")
giveBack:RegisterEvent("PLAYER_ENTERING_WORLD")
giveBack:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	C_Timer.After(2, function()
		local kql = _G.KerzosQuestLog
		if Usable(kql) and type(kql.cfg) == "table" and not On() then GiveThemeBack(kql) end
	end)
end)

-- (fs: a string, or one of its font objects.)
local function DaylightFace(kql, fs, size)
	if not fs or type(fs.GetFont) ~= "function" or not Ours(kql) then return end
	local okF, path, now, flags = pcall(fs.GetFont, fs)
	size = size or now
	if okF and path and type(size) == "number" and size > 0 then ns.SetFont(KEY, fs, path, size, flags) end
end

-- Is this old-style dropdown one of its own (its test, which it keeps local)?
local function OwnDropdown(menu)
	menu = menu or _G.UIDROPDOWNMENU_OPEN_MENU
	if type(menu) ~= "table" then return false end
	if menu.esDropdownKQL then return true end
	local name = menu.GetName and menu:GetName()
	return type(name) == "string" and name:sub(1, 4) == "KQL_"
end

local fontsHooked = false
local function FollowFonts(kql)
	if fontsHooked or type(kql.ObtenerFuenteSeleccionada) ~= "function" then return end
	fontsHooked = true
	-- With its pick on "Default" it sends most strings (quest list rows, headings, its menu)
	-- through its two font calls only when a size change is set, so the hooks below never saw
	-- them. While its words are ours its test says yes; its own answer otherwise.
	local should = kql.DebeUsarTipografiaPersonalizada
	if type(should) == "function" then
		kql.DebeUsarTipografiaPersonalizada = function(self, fs, ...)
			if Ours(self) then return true end
			return should(self, fs, ...)
		end
	end
	for _, method in ipairs({ "AplicarTipografiaPersonalizada", "RestaurarTipografiaOriginal" }) do
		Hook(kql, method, function(self, fs) if Kind(fs) == "FontString" then DaylightFace(self, fs) end end)
	end
	-- Its dropdown words are set to Nowar Sans 11 apart from its font setting (the font object
	-- its dropdowns use, and the open list's rows): the player's font on them, at its 11.
	Hook(kql, "ObtenerFontObjectDropdown", function(self)
		DaylightFace(self, _G.KQL_DropdownFont, 11)
	end)
	Hook(kql, "ActualizarTipografiaDropdownLists", function(self, menu)
		if not OwnDropdown(menu) or not Ours(self) then return end
		local most = _G.UIDROPDOWNMENU_MAXBUTTONS or 32
		for level = 1, 2 do
			for i = 1, most do
				local fs = _G["DropDownList" .. level .. "Button" .. i .. "NormalText"]
				if Kind(fs) == "FontString" then DaylightFace(self, fs, 11) end
			end
		end
	end)
	-- Once now, over everything it has made (its own pass, which the two hooks follow).
	if type(kql.ActualizarTipografiaGlobal) == "function" then pcall(kql.ActualizarTipografiaGlobal, kql) end
end

local function Setup(kql, Kit)
	if not On() then return end
	FollowFonts(kql)
	KeepDark(kql)
	-- A theme picked in its settings is remembered as the one to give back (its dropdown reloads
	-- the UI straight after, so this is the only moment to see it); Dark again after.
	Hook(kql, "FijarTemaVisual", function(_, theme)
		if not On() then return end
		if type(theme) == "string" and not DARK[theme] then DB().kcqlTheme = theme end
		C_Timer.After(0, function() KeepDark(kql) end)
	end)

	-- The window.
	Kit.Window(kql)
	local close = _G.KerzosQuestLogCloseButton or kql.CloseButton
	if Usable(close) and ns.Once(close) then Kit.Close(close) end
	local function chrome() Chrome(kql, Kit) end
	-- (Once a frame at most: the divider being dragged lays the window out every frame.)
	local queued = false
	local function chromeSoon()
		if queued then return end
		queued = true
		C_Timer.After(0, function() queued = false chrome() end)
	end
	if Usable(kql.Barra) then
		Hook(kql.Barra, "AplicarTemaVisual", chrome)
		Hook(kql.Barra, "Refrescar", chrome)
	end
	Hook(kql, "AplicarDistribucionVentana", chrome)
	Hook(kql, "AplicarGeometriaDual", chromeSoon)
	-- Its header pass centers the title again; DaylightUI's window title sits on the left.
	Hook(kql, "CalibrarCabeceraYCierre", function()
		local tc = kql.TitleContainer
		if On() and Usable(tc) and Kind(tc.TitleText) == "FontString" then Kit.Title(kql, tc.TitleText) end
	end)
	Hook(kql, "ActualizarVisibilidadBotonNovedades", chrome)
	kql:HookScript("OnShow", chrome)
	chrome()

	-- The list and detail panels.
	local function list() List(kql, Kit) end
	local function search() Search(kql, Kit) end
	local function detail() Detail(kql, Kit) end
	if Usable(kql.RegistroMisiones) then
		Hook(kql.RegistroMisiones, "Refrescar", function() list() search() end)
		Hook(kql.RegistroMisiones, "RefrescarWidgetsBusqueda", search)
	end
	local v = kql.VisorDetalle
	if Usable(v) then
		Hook(v, "Refrescar", detail)
		Hook(v, "RellenarPremio", function(_, btn) Reward(btn) end)
		Hook(v, "RenderizarProgresoGrupo", function() if On() then Party(v) end end)
		Hook(v, "RenderizarCadenaMisiones", function() if On() then Chain(v) end end)
		Hook(v, "AplicarTemaBarraAuxiliar", function() if On() then AuxBar(v) end end)
		Hook(v, "MostrarTooltipCardQuestie", Card)
	end
	list()
	search()
	detail()

	-- Settings.
	local panel = kql.PanelAjustes
	if Usable(panel) then
		local function settings() Settings(kql, Kit) end
		Hook(panel, "Refrescar", settings)
		Hook(panel, "ActualizarLayoutAcordeon", settings)
		local content = panel.ScrollFrame and panel.ScrollFrame.Content
		if Usable(content) then Hook(content, "ActualizarTarjetasDiseno", function() if On() then Cards(kql) end end) end
		if ns.Walk then ns.Walk(Kit, panel, nil, settings, nil, KEY) end
		FollowWindowFonts(panel)
		-- Inside the game's Options window it pins Reset Defaults / About / "Hide options not
		-- available" to the page's bottom edge but leaves its list running to that edge, so the
		-- list's last rows show through the buttons. The list ends above them there (its own window
		-- keeps a strip for them already, so its 16 px stays).
		local function listBottom(y)
			local sf = panel.ScrollFrame
			if On() and Usable(sf) then sf:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, y) end
		end
		Hook(panel, "MostrarEnBlizzard", function() listBottom(50) end)
		Hook(panel, "MostrarEnModal", function() listBottom(16) end)
		if panel.enBlizzardSettings then listBottom(50) end
	end
	ns.Watch(KEY, "KQLModalAjustes", function(f, K) if ns.Once(f) then SettingsWindow(f, K) end end)
	-- (Made and shown in one call: dressed right after it is made, before its first show.)
	Hook(kql, "CrearModalAjustes", function()
		local f = _G.KQLModalAjustes
		if On() and Usable(f) and ns.Once(f) then SettingsWindow(f, Kit) end
	end)

	-- Dialogs.
	ns.Watch(KEY, "KQLVentanaDialogoConfirmacion", function(f, K) Dialog(f, K) end)
	ns.Watch(KEY, "KQLVentanaInfo", function(f, K)
		Dialog(f, K, { "Divider" }, function(w)
			if not On() then return end
			Ink(w.TxtVisitaWeb, "LABEL")
			local more = w.BotonVerNovedades
			if Usable(more) then Plain(more.GetFontString and more:GetFontString()) end
			local body = w.ScrollFrame and w.ScrollFrame.Content and w.ScrollFrame.Content.Body
			Recode(body, "|cffffd200", "LABEL")
		end)
		Quiet(f.Divider)
	end)
	ns.Watch(KEY, "KQLAvisoForever", function(f, K)
		Dialog(f, K, { "Logo" })
		Ink(f.Headline, "VALUE")
	end)
	ns.Watch(KEY, "KQLModalResetAjustes", function(f, K)
		Dialog(f, K, { "IconoAlerta" })
		Ink(f.Titulo, "VALUE")
		Ink(f.TextoExplicativo, "TEXT")
	end)
	ns.Watch(KEY, "KQLVentanaColoresDificultad", function(f, K)
		Dialog(f, K, nil, Colors)
		Colors(f)
	end)
	ns.Watch(KEY, "KQLVentanaCurseForgeKQE", function(f, K)
		BackdropWindow(f, K, Download)
		Download(f)
	end)
	ns.Watch(KEY, "KQL_VentanaNovedades", function(f, K)
		BackdropWindow(f, K, News)
		News(f)
	end)
	Hook(kql, "AbrirModalNovedades", function()
		local f = _G.KQL_VentanaNovedades
		if not Usable(f) or not On() then return end
		BackdropWindow(f, Kit, News)
		News(f)
		-- (It lays its cards out again a moment later.)
		C_Timer.After(0.1, function() News(f) WindowFonts(f) end)
	end)

	-- Dialogs made and shown in one call: dressed right after.
	local dialogs = kql.VentanaDialogo
	if type(dialogs) == "table" then
		Hook(dialogs, "AbrirColoresDificultad", function()
			local f = _G.KQLVentanaColoresDificultad
			if On() and Usable(f) then Dialog(f, Kit, nil, Colors) Colors(f) end
		end)
		Hook(dialogs, "MostrarModalDescargaKQE", function()
			local f = _G.KQLVentanaCurseForgeKQE
			if On() and Usable(f) then BackdropWindow(f, Kit, Download) Download(f) end
		end)
	end

	-- The menu.
	Hook(kql, "MostrarMenuContextual", Menu)
end

ns.Pack(KEY, "Kerzo Classic Quest Log", function()
	local kql = _G.KerzosQuestLog
	-- Made now, while it loads: DaylightUI's tooltip skin takes the tooltips that exist at the
	-- first loading screen.
	if kql and On() and type(kql.ObtenerTooltipAddon) == "function" then pcall(kql.ObtenerTooltipAddon, kql) end
	-- The rest once it has set itself up at login (its settings, bar and panels).
	ns.Watch(KEY, function()
		local k = _G.KerzosQuestLog
		return Usable(k) and type(k.cfg) == "table" and Usable(k.Barra) and Usable(k.Barra.IndicadorMisiones)
			and Usable(k.RegistroMisiones) and k.RegistroMisiones.SearchLabel and k or nil
	end, Setup)
end, CAPS)
