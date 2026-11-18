-- Kerzo Quest Expansion: its own windows in the DaylightUI look. What it adds to the quest log
-- (the colored marker before a quest's name, the expansion logo, the tint behind a quest's text, the
-- badge on a quest giver's window) and its tooltip lines are its content and stay as they are.
-- With Kerzo Classic Quest Log on, it runs as that addon's library: no settings page and nothing
-- added to the game's windows, only the two windows the quest log opens.
-- Dressed here:
--   * Summary (KQEVentanaResumen, built on its first open): its dialog backdrop and the dark plate
--     under it give way to the window shell; its X, Close button and scroll bar DaylightUI's; its
--     gold title, column headings and total in DaylightUI's inks (a heading's white hover the
--     value ink); its striped rows quiet (every second row a faint wash), redone each time it
--     fills the list (every open and every sort). The expansion logos stay.
--   * Tints (KQEVentanaTintes, built on its first open): the same shell; its four preset buttons,
--     Close, X, the opacity slider, the inset well round the list, the list's scroll bar and each
--     expansion's checkbox DaylightUI's; its row stripes quiet. Each expansion's color swatch (and
--     its black edge) stays: it is the color you picked. The game's color picker it opens is the
--     Game windows pack's.
--   * Its settings page (KQEPanelAjustesBlizzard, only when it runs on its own: filled at login,
--     shown inside the game's Settings window): its own drawn checkboxes become a box of the input
--     look with an accent square when on (the game's minimal check art and its additive glow off);
--     an option's gold name in the label ink (value ink under the mouse, where it went pale gold),
--     its warm gray line in the text ink; the section headings in the label ink and their bronze
--     rules faint neutral lines; the title's gold color code taken out; its two buttons, the
--     old-style dropdowns (tooltip mode, language) and the scroll bar DaylightUI's. The dropdown's list is the Game windows pack's.
local _, ns = ...
if not ns.ok then return end

local KEY = "Kerzo Quest Expansion"
-- (Its words are the game's font objects: the player's font goes on all of them.)
ns.Target(KEY, "Kerzo Quest Expansion", { window = true, controls = true, text = true, shadow = true, font = "daylight" })

local Usable = ns.Usable

local function Ink(fs, name)
	if not Usable(fs) or not fs.SetTextColor then return end
	local c = ns.Colors()[name]
	if c then fs:SetTextColor(c[1], c[2], c[3]) end
end

local function IsTexture(x) return Usable(x) and x:GetObjectType() == "Texture" end

-- A colored line of its own (bronze rules, gray column rules): a faint neutral one.
local function Quiet(tex)
	if IsTexture(tex) then tex:SetColorTexture(1, 1, 1, 0.08) end
end

-- The flat plate it draws under its dialog backdrop (a BACKGROUND color texture on the window).
local function PlateOff(f)
	for _, r in ipairs({ f:GetRegions() }) do
		if IsTexture(r) and r:GetDrawLayer() == "BACKGROUND" then ns.Kill(r) end
	end
end

-- Its 1 px rules: thin ARTWORK color lines straight on a frame.
local function QuietRules(f)
	if not Usable(f) or not f.GetRegions then return end
	for _, r in ipairs({ f:GetRegions() }) do
		if IsTexture(r) and r:GetDrawLayer() == "ARTWORK" and (r:GetHeight() or 0) <= 1.5 then Quiet(r) end
	end
end

-- A striped row: every second one a faint wash, the others clear.
local function Stripe(tex, even)
	if not IsTexture(tex) then return end
	if even then tex:SetColorTexture(1, 1, 1, 0.03) else tex:SetColorTexture(0, 0, 0, 0) end
end

-- Its text look (font, size, outline, shadow from its page), on the strings there are now.
local TEXT_OPTS = { checks = false, scrollBars = false, fonts = true }
local function TextLook(f)
	if not ns.PlainText(KEY) then ns.Dress(f, TEXT_OPTS, 0, KEY) end
end

-- One of its two windows: the shell, its X, and DaylightUI's walk over it (buttons, checks, the
-- slider, scroll bars, gold text), again on every show.
local function Window(f, Kit, after)
	if not ns.Once(f) then return end
	ns.NoBackdrop(f)
	PlateOff(f)
	ns.Shell(f, { window = true }, KEY)
	if ns.Controls(KEY) and Usable(f.BotonCerrarX) then Kit.Close(f.BotonCerrarX) end
	Ink(f.Titulo, "VALUE")
	Ink(f.Desc, "TEXT")
	if ns.Controls(KEY) and ns.Walk then ns.Walk(Kit, f, nil, after, nil, KEY) end
	TextLook(f)
end

-- ---------------------------------------------------------------------------------------------
-- Summary
-- ---------------------------------------------------------------------------------------------

local SummaryRows
local function SortHeading(btn, f)
	if not Usable(btn) or not Usable(btn.Texto) or not ns.Once(btn) then return end
	Ink(btn.Texto, "LABEL")
	-- A sort fills the list again through a function of its own (no Refrescar): striped again.
	btn:HookScript("OnClick", function() SummaryRows(f) end)
	btn:HookScript("OnEnter", function() if ns.Enabled(KEY) then Ink(btn.Texto, "VALUE") end end)
	btn:HookScript("OnLeave", function() if ns.Enabled(KEY) then Ink(btn.Texto, "LABEL") end end)
end

function SummaryRows(f)
	if not ns.Enabled(KEY) then return end
	local rows = f.filasCreadas
	if type(rows) == "table" then
		for i, row in ipairs(rows) do Stripe(row.Fondo, i % 2 == 0) end
	end
	Ink(f.TextoTotal, "VALUE")
	TextLook(f)
end

local function Summary(f, Kit)
	Window(f, Kit, function() SummaryRows(f) end)
	-- The column headings (an unnamed bar above the list) and the rules under it and the list.
	for _, child in ipairs({ f:GetChildren() }) do
		if Usable(child) and child:GetObjectType() == "Frame" and child ~= f.Contenido then
			QuietRules(child)
			if Usable(child.LblPorcentaje) then Ink(child.LblPorcentaje, "LABEL") end
			for _, b in ipairs({ child:GetChildren() }) do
				if Usable(b) and b:GetObjectType() == "Button" then SortHeading(b, f) end
			end
		elseif Usable(child) and child:GetObjectType() == "Button" and Usable(child.Texto) then
			SortHeading(child, f)
		end
	end
	QuietRules(f)
	if type(f.Refrescar) == "function" then
		hooksecurefunc(f, "Refrescar", function() SummaryRows(f) end)
	end
	SummaryRows(f)
end

-- ---------------------------------------------------------------------------------------------
-- Tints
-- ---------------------------------------------------------------------------------------------

local function Tints(f, Kit)
	Window(f, Kit)
	local scroll = _G.KQEScrollTintesExp
	local inset = Usable(scroll) and scroll:GetParent()
	if ns.Controls(KEY) and Usable(inset) and inset ~= f then Kit.Inset(inset) end
	if type(f.filasCreadas) == "table" then
		for i, row in ipairs(f.filasCreadas) do
			-- The stripe is the row's own BACKGROUND texture; the swatch and its edge are the
			-- color button's and stay.
			for _, r in ipairs({ row:GetRegions() }) do
				if IsTexture(r) and r:GetDrawLayer() == "BACKGROUND" then Stripe(r, i % 2 == 0) end
			end
			Ink(row.Nombre, "TEXT")
		end
	end
	Ink(f.TextoOpacidad, "LABEL")
	if ns.Controls(KEY) and ns.Slider and Usable(f.SliderOpacidad) then ns.Slider(f.SliderOpacidad) end
end

-- ---------------------------------------------------------------------------------------------
-- Settings page (standalone only)
-- ---------------------------------------------------------------------------------------------

-- Its checkbox rows: a Button with three textures (box, glow, check) and two strings.
local function CheckRow(row, Kit)
	if not ns.Once(row) then return end
	local box, glow, mark
	for _, r in ipairs({ row:GetRegions() }) do
		if IsTexture(r) then
			local layer = r:GetDrawLayer()
			if layer == "BACKGROUND" then box = r
			elseif layer == "BORDER" then glow = r
			elseif layer == "ARTWORK" then mark = r end
		end
	end
	if not (box and mark) then return end
	-- Out of sight but kept: the row shows and hides its check itself.
	box:SetAlpha(0)
	mark:SetAlpha(0)
	if glow then glow:SetAlpha(0) end
	local holder = CreateFrame("Frame", nil, row)
	holder:SetSize(16, 16)
	holder:SetPoint("CENTER", box, "CENTER", 0, 0)
	holder:EnableMouse(false)
	local shell = Kit.Shell(holder, "input")
	local fill = holder:CreateTexture(nil, "OVERLAY")
	fill:SetSize(8, 8)
	fill:SetPoint("CENTER")
	local function paint()
		ns.FillAccent(fill, 1, nil, KEY)
		fill:SetShown(mark:IsShown())
	end
	hooksecurefunc(mark, "Show", paint)
	hooksecurefunc(mark, "Hide", paint)
	paint()
	Ink(row.labelTitulo, "LABEL")
	Ink(row.labelDesc, "TEXT")
	row:HookScript("OnEnter", function()
		if not ns.Enabled(KEY) then return end
		Ink(row.labelTitulo, "VALUE")
		Kit.Paint(shell, Kit.ROW_HOVER)
	end)
	row:HookScript("OnLeave", function()
		if not ns.Enabled(KEY) then return end
		Ink(row.labelTitulo, "LABEL")
		Kit.Paint(shell, nil)
	end)
	row:HookScript("OnShow", paint)
end

local function Heading(h)
	if not ns.Once(h) then return end
	Ink(h.etiqueta, "LABEL")
	QuietRules(h)
	for _, r in ipairs({ h:GetRegions() }) do
		if IsTexture(r) then Quiet(r) end
	end
end

local function PlainTitle(panel)
	local t = panel.Titulo
	if not Usable(t) then return end
	local text = t:GetText()
	if type(text) == "string" and text:find("|cff", 1, true) then
		local off = ns.Colors().OFF
		local dim = off and string.format("|cff%02x%02x%02x", off[1] * 255, off[2] * 255, off[3] * 255) or ""
		text = text:gsub("|cffffd200(.-)|r", "%1"):gsub("|cff888888", dim)
		t:SetText(text)
	end
	Ink(t, "VALUE")
end

local function SettingsTexts(panel, Kit)
	if not ns.Enabled(KEY) then return end
	PlainTitle(panel)
	Ink(panel.Subtitulo, "TEXT")
	Ink(panel.EtiquetaModoTooltip, "LABEL")
	Ink(panel.DescModoTooltip, "TEXT")
	-- (2.1.0's language row: its gold label and warm gray line.)
	Ink(panel.EtiquetaIdioma, "LABEL")
	Ink(panel.DescIdioma, "TEXT")
	local content = panel.Contenido
	if not Usable(content) then return end
	for _, c in ipairs({ content:GetChildren() }) do
		if Usable(c) then
			if c.claveVar ~= nil and c.labelTitulo then
				CheckRow(c, Kit)
			elseif c.claveTexto ~= nil and c.etiqueta then
				Heading(c)
			else
				-- The tints button's holder row and the dropdown's.
				for _, cc in ipairs({ c:GetChildren() }) do
					if Usable(cc) and cc.claveVar ~= nil and cc.labelTitulo then CheckRow(cc, Kit) end
				end
			end
		end
	end
end

local function Settings(panel, Kit)
	if not ns.Once(panel) then return end
	Quiet(panel.LineaSeparadoraCabecera)
	if ns.Controls(KEY) then
		-- (2.1.0 added the Expansion Summary button beside the tints one, and the language dropdown.)
		for _, b in ipairs({ panel.BotonConfigTinte, panel.BotonResumenExp }) do
			if Usable(b) then Kit.Button(b) end
		end
		for _, d in ipairs({ panel.DropdownModoTooltip, panel.DropdownIdioma }) do
			if ns.OldDropdown and Usable(d) then ns.OldDropdown(d) end
		end
		local bar = _G.KQEPanelAjustesScrollScrollBar
		if Usable(bar) then Kit.ScrollBar(bar) end
	end
	SettingsTexts(panel, Kit)
	TextLook(panel)
	-- Its texts (title included) are set again on every show and language change.
	for _, m in ipairs({ "ActualizarTextosLocalizados", "Refrescar" }) do
		if type(panel[m]) == "function" then
			hooksecurefunc(panel, m, function() SettingsTexts(panel, Kit) end)
		end
	end
	panel:HookScript("OnShow", function() SettingsTexts(panel, Kit) end)
end

-- Its windows are made, shown and filled in one call: dressed right after it (no undressed first
-- frames), through its public API, the way Kerzo Classic Quest Log opens them. The watches stay for
-- the settings page's own Tints and Expansion Summary buttons and its /kqe command, which go round
-- the API.
local function OnOpen(name, fn)
	return function()
		local f, Kit = _G[name], ns.Kit
		if Usable(f) and Kit and ns.Enabled(KEY) then ns.Guard(fn, f, Kit) end
	end
end

ns.Pack(KEY, "Kerzo Quest Expansion", function()
	local api = _G.KerzoQuestExpansion
	if type(api) == "table" then
		for _, m in ipairs({ "AbrirVentanaResumen", "OpenOverviewWindow" }) do
			if type(api[m]) == "function" then hooksecurefunc(api, m, OnOpen("KQEVentanaResumen", Summary)) end
		end
		for _, m in ipairs({ "AbrirVentanaTintes", "OpenTintWindow" }) do
			if type(api[m]) == "function" then hooksecurefunc(api, m, OnOpen("KQEVentanaTintes", Tints)) end
		end
	end
	ns.Watch(KEY, "KQEVentanaResumen", Summary)
	ns.Watch(KEY, "KQEVentanaTintes", Tints)
	-- Filled at login only when it runs on its own; empty (and never shown) as a library.
	ns.Watch(KEY, function()
		local p = _G.KQEPanelAjustesBlizzard
		return Usable(p) and Usable(p.BotonConfigTinte) and p or nil
	end, Settings)
end, { window = true, controls = true, text = true, shadow = true })
