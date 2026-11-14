-- TrueshotLodge: its window (TrueshotLodgeFrame, made the first time it's opened) and everything
-- in it: the side tabs down its edges (on either side, as the player drags them), the gear and
-- "?" buttons by the close button, the Level / Zone / Pet / Faction filter buttons and their
-- Filters box, the search box and the +/- button over the list, the list itself (its headings
-- and rows, the picked row in the accent), the details pane (the round icon, the name link,
-- the Learnable By row, the family and look widgets, the creature rows and their Map buttons,
-- the Trainers tab's map button), the Options tab's switches, UI Scale slider and Reset Tab
-- Order button, the Collected Data tab's Clear All Data button, the Stable tab (its panels,
-- slots, statistics list and experience bar) and the pet profile (Back, its list, the model box
-- and its Map button).
-- Kept as they are: the logo, 3D models, spell and family icons, the trainers' small zone map
-- and its pin, the map pins, the state colors of the list (known gold, available green,
-- unavailable gray), faction colors, the rare glow, the elite skull, the Forever mark, the
-- tamed dot, the NEW badges and their sparkles, and the red of a stable slot not bought yet.
-- Left to DaylightUI: the minimap button (LibDBIcon, in DaylightUI's drawer), the Clear All Data
-- and delete popups (the game's StaticPopup) and every tooltip (GameTooltip).
local _, ns = ...
if not ns.ok then return end

local KEY = "TrueshotLodge"
local API = ns.API

local Kit
local abs = math.abs

-- Frames this pack dresses itself: the Kit's walk and this pack's own walk leave them alone.
local skip = {}

local function Usable(obj) return ns.Usable(obj) end

local function IsTexture(obj)
	return Usable(obj) and obj:GetObjectType() == "Texture"
end

local function Near(r, g, b, c)
	return type(r) == "number" and abs(r - c[1]) <= 0.03 and abs(g - c[2]) <= 0.03 and abs(b - c[3]) <= 0.03
end

local GOLD = { 1, 0.82, 0 }      -- the game's gold text (TSL's "on", and its labels)
local GRAY = { 0.6, 0.6, 0.6 }   -- TSL's "off"

-- A text in one of DaylightUI's inks (its color only: the font stays the addon's, or the
-- player's text look where one is set).
local function Ink(fs, role)
	if not Usable(fs) or not fs.SetTextColor then return end
	local c = ns.Colors()[role]
	if type(c) == "table" then fs:SetTextColor(c[1], c[2], c[3]) end
end

local function PixelHeight(region, px)
	if PixelUtil and PixelUtil.SetHeight then PixelUtil.SetHeight(region, px) else region:SetHeight(px) end
end

-- ---------------------------------------------------------------------------------------------
-- The accent, on the few pieces that carry it (repainted when the style changes)
-- ---------------------------------------------------------------------------------------------

local picks = setmetatable({}, { __mode = "k" })      -- a list row's picked overlay
local accentLines = setmetatable({}, { __mode = "k" }) -- the filter buttons' "on" lines, the name link
local headerLabels = setmetatable({}, { __mode = "k" }) -- the list headings' words
local lastAccent = { 0, 0, 0 }

local function PaintPick(tex)
	local r, g, b = ns.AccentOf(KEY)
	tex:SetColorTexture(r, g, b, Kit and Kit.ROW_PICK or 0.16)
end

local function PaintLine(tex)
	local r, g, b = ns.AccentOf(KEY)
	tex:SetColorTexture(r, g, b, 1)
end

-- A list heading's words: the game's gold becomes the accent, as DaylightUI's own list
-- sections; white (under the mouse) stays. Its words are put back in gold by its template on
-- every hover, so this runs again each time.
-- Always: the accent at rest, DaylightUI's bright text under the mouse. (Its template turns the
-- words gold on hover and doesn't always turn them back, so the color is set outright, after its
-- every font or color change and on the mouse going on or off the heading.)
local inking = false
local function HeaderInk(label)
	if inking then return end
	inking = true
	-- (A tint left on the words would color over ours.)
	if label.SetVertexColor then label:SetVertexColor(1, 1, 1) end
	local row = label:GetParent()
	if row and row.IsMouseOver and row:IsMouseOver() then
		local t = Kit and Kit.TEXT or { 1, 1, 1 }
		label:SetTextColor(t[1], t[2], t[3])
	else
		local ar, ag, ab = ns.AccentOf(KEY)
		label:SetTextColor(ar, ag, ab)
	end
	inking = false
end

local function HeaderFontSet(label)
	if ns.Enabled(KEY) then HeaderInk(label) end
end

-- ---------------------------------------------------------------------------------------------
-- The outline buttons (the Map buttons, Back, the bounty link): no template, a bronze edge and
-- fonts of its own. The fonts are its global font objects, so their words are inked once there,
-- and TrueshotLodge still sizes each button from its words.
-- ---------------------------------------------------------------------------------------------

local OUTLINE_FONTS = {
	TrueshotLodgeOutlineButtonNormalFont = "TEXT",
	TrueshotLodgeOutlineButtonHighlightFont = "VALUE",
	TrueshotLodgeOutlineButtonDisableFont = "OFF",
}
local fontBase = {}

local function OutlineFonts()
	local c = ns.Colors()
	for name, role in pairs(OUTLINE_FONTS) do
		local font = _G[name]
		if type(font) == "table" and font.SetTextColor and font.GetFont then
			local base = fontBase[name]
			if not base then
				local path, size, flags = font:GetFont()
				base = { path, size, flags }
				fontBase[name] = base
			end
			local face, size, flags = ns.FontFor(KEY, base[1], base[2], base[3])
			if face and size and size > 0 then font:SetFont(face, size, flags or "") end
			local ink = c[role]
			if type(ink) == "table" then font:SetTextColor(ink[1], ink[2], ink[3]) end
		end
	end
end

local function IsOutlineButton(btn)
	local normal = _G.TrueshotLodgeOutlineButtonNormalFont
	return normal ~= nil and btn.GetNormalFontObject and btn:GetNormalFontObject() == normal
end

local outlined = setmetatable({}, { __mode = "k" })
local function OutlineButton(btn)
	if not Usable(btn) or outlined[btn] or not ns.Controls(KEY) then return end
	outlined[btn] = true
	-- Its dark fill and both edges (bronze, and gold under the mouse) give way to DaylightUI's.
	Kit.Strip(btn)
	ns.Guard(Kit.ArtButton, btn)
end

-- ---------------------------------------------------------------------------------------------
-- The list rows (the list on the left, the creatures under the details, the Stable tab's and the
-- pet profile's lists). Each row is dressed as the list fills it (its OnInitializedFrame), so
-- scrolling costs one look at each new row and nothing else.
-- ---------------------------------------------------------------------------------------------

local rowDone = setmetatable({}, { __mode = "k" })
local rowText = setmetatable({}, { __mode = "k" })
local TEXT_OPTS = { checks = false, scrollBars = false }

-- A texture of `frame`'s in the HIGHLIGHT layer (the row's hover wash), as a quiet white one.
local function WashHighlight(frame, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if IsTexture(r) and r:GetDrawLayer() == "HIGHLIGHT" then
			r:SetColorTexture(1, 1, 1, Kit.HOVER_WASH or 0.08)
			r:SetBlendMode("BLEND")
		end
	end
end

-- A row of the profession list template (an ability's rank, a trainer, a family, a look...):
-- its picked overlay in the accent, its hover overlay a white wash. TrueshotLodge still shows and
-- hides both. Its words keep the colors it gives them (the rank states, the factions, a look only
-- one creature has).
local function RecipeRow(row)
	if rowDone[row] then return end
	rowDone[row] = true
	local sel, hover = row.SelectedOverlay, row.HighlightOverlay
	if IsTexture(sel) then
		sel:SetBlendMode("BLEND")
		picks[sel] = true
		PaintPick(sel)
	end
	if IsTexture(hover) then
		hover:SetColorTexture(1, 1, 1, Kit.HOVER_WASH or 0.08)
		hover:SetBlendMode("BLEND")
	end
end

-- The header template differs between game versions. Retail's has named parts (a three-piece
-- bar, a CollapseIcon, a Label). This client's is a plain button whose brown bar and gold +
-- are one piece of art ("common-button-list-collapseExpand", its normal texture and an ARTWORK
-- copy), with its words as its one font string. Both are told apart here by their art.
local function AtlasOf(tex)
	if not IsTexture(tex) or not tex.GetAtlas then return nil end
	local ok, atlas = pcall(tex.GetAtlas, tex)
	return ok and type(atlas) == "string" and string.lower(atlas) or nil
end
local function IsHeaderArt(atlas)
	return atlas ~= nil and (atlas:find("header", 1, true) or atlas:find("collapseexpand", 1, true)) ~= nil
end

-- Whether a list row is a heading.
local function IsHeader(row)
	if row.CollapseIcon then return true end
	if row.GetNormalTexture and IsHeaderArt(AtlasOf(row:GetNormalTexture())) then return true end
	for i = 1, row:GetNumRegions() do
		if IsHeaderArt(AtlasOf((select(i, row:GetRegions())))) then return true end
	end
	return false
end

-- Its words: the template's Label, or its one font string.
local function HeaderLabel(row)
	if Usable(row.Label) then return row.Label end
	for i = 1, row:GetNumRegions() do
		local r = select(i, row:GetRegions())
		if Usable(r) and r:GetObjectType() == "FontString" then return r end
	end
end

-- Retail's +/- (its own texture): in DaylightUI's text color, also after the game sets its art
-- again on each open and close.
local toggles = setmetatable({}, { __mode = "k" })
local function ToggleInk(icon)
	if not ns.Enabled(KEY) then return end
	icon:SetDesaturated(true)
	local t = Kit.TEXT
	icon:SetVertexColor(t[1], t[2], t[3])
end

-- This client's +/- is part of the bar's art, which goes: ours is a "+" or a minus sign in
-- DaylightUI's text color, following the heading's open or closed state (the list's node, read
-- when the row is filled, and each UpdateCollapsedState after).
local glyphs = setmetatable({}, { __mode = "k" })
local MINUS = "-"   -- (plain: the font has no true minus sign)
local function GlyphState(row, collapsed)
	local g = glyphs[row]
	if not g then return end
	if collapsed == nil and row.GetElementData then
		local ok, node = pcall(row.GetElementData, row)
		if ok and type(node) == "table" and node.IsCollapsed then collapsed = node:IsCollapsed() end
	end
	g:SetText(collapsed == false and MINUS or "+")
	local t = Kit.TEXT
	g:SetTextColor(t[1], t[2], t[3])
end
local function OnCollapsed(row, collapsed)
	if ns.Enabled(KEY) then GlyphState(row, collapsed) end
end

-- A heading of the list: its bar off (a faint band in its place), its +/- in DaylightUI's text
-- color, its words in the accent.
local headerLabelOf = setmetatable({}, { __mode = "k" })   -- row -> its words (false: none)
local function HeaderRow(row)
	if not rowDone[row] then
		rowDone[row] = true
		local icon = IsTexture(row.CollapseIcon) and row.CollapseIcon or nil
		for _, key in ipairs({ "LeftPiece", "RightPiece", "CenterPiece" }) do ns.Kill(row[key]) end
		if not icon then
			-- This client's art (the gold + on the row and on its little button) is set again on every
			-- open and close: masked out for good rather than faded.
			for i = 1, row:GetNumRegions() do
				local r = select(i, row:GetRegions())
				if IsTexture(r) then ns.Guard(Kit.Erase, r) end
			end
			for _, get in ipairs({ "GetNormalTexture", "GetHighlightTexture", "GetPushedTexture" }) do
				local t = row[get] and row[get](row)
				if IsTexture(t) then ns.Guard(Kit.Erase, t) end
			end
			for i = 1, row:GetNumChildren() do
				local c = select(i, row:GetChildren())
				if Usable(c) and c:GetObjectType() == "Button" then
					for j = 1, c:GetNumRegions() do
						local r = select(j, c:GetRegions())
						if IsTexture(r) then ns.Guard(Kit.Erase, r) end
					end
				end
			end
		end
		local keep = {}
		if icon then keep[icon] = true end
		-- (Every other texture of the row's, its normal and highlight art included, goes.)
		ns.Guard(Kit.Row, row, keep, nil, false)
		local band = row:CreateTexture(nil, "BACKGROUND")
		band:SetAllPoints(row)
		band:SetColorTexture(1, 1, 1, 0.05)
		if icon then
			if not toggles[icon] then
				toggles[icon] = true
				hooksecurefunc(icon, "SetAtlas", ToggleInk)
			end
			ToggleInk(icon)
		else
			local label = HeaderLabel(row)
			local g = row:CreateFontString(nil, "OVERLAY")
			if Usable(label) then g:SetFontObject(label:GetFontObject() or GameFontNormal) else g:SetFontObject(GameFontNormal) end
			g:SetPoint("RIGHT", row, "RIGHT", -10, 0)
			glyphs[row] = g
			if type(row.UpdateCollapsedState) == "function" then hooksecurefunc(row, "UpdateCollapsedState", OnCollapsed) end
		end
		local label = HeaderLabel(row)
		if Usable(label) and label.SetTextColor then
			headerLabels[label] = true
			hooksecurefunc(label, "SetFontObject", HeaderFontSet)
			hooksecurefunc(label, "SetTextColor", HeaderFontSet)
			if label.SetVertexColor then hooksecurefunc(label, "SetVertexColor", HeaderFontSet) end
			local function again() HeaderFontSet(label) end
			row:HookScript("OnEnter", again)
			row:HookScript("OnLeave", again)
		end
	end
	GlyphState(row)
	local label = headerLabelOf[row]
	if label == nil then
		label = HeaderLabel(row) or false
		headerLabelOf[row] = label
	end
	if label and Usable(label) then HeaderInk(label) end
end

-- A creature row under the details: its gold hover a white wash, its Map button DaylightUI's,
-- its level and zone line in DaylightUI's dim ink. Its name color, the rare glow and edge, the
-- skull, the Forever mark and the tamed dot stay.
local function CreatureRow(row)
	if rowDone[row] then return end
	rowDone[row] = true
	WashHighlight(row, row:GetRegions())
	OutlineButton(row.MapButton)
	Kit.InkGameText(row)
end

-- A row of the Stable tab's and the pet profile's facts: its gold hover a white wash; its label
-- (put back in the game's gold each time the row is filled) in DaylightUI's label ink.
local function StatRow(row)
	if not rowDone[row] then
		rowDone[row] = true
		WashHighlight(row, row:GetRegions())
	end
	Kit.InkGameText(row)
end

-- What each row was found to be, the first time: a pooled row keeps its template, so on every later
-- fill and list update it goes straight to its kind (no look over its art again).
local rowKind = setmetatable({}, { __mode = "k" })
local KIND_FN = { recipe = RecipeRow, header = HeaderRow, creature = CreatureRow, stat = StatRow }

local function RowFn(row)
	if not Usable(row) then return end
	local kind = rowKind[row]
	if kind then
		KIND_FN[kind](row)
	elseif row.SelectedOverlay and row.HighlightOverlay then
		rowKind[row] = "recipe"
		RecipeRow(row)
	elseif IsHeader(row) then
		rowKind[row] = "header"
		HeaderRow(row)
	elseif row.MapButton and row.RareGlow then
		rowKind[row] = "creature"
		CreatureRow(row)
	elseif row.Plate and row.Hover then
		rowKind[row] = "stat"
		StatRow(row)
	end
	-- The player's text look on its words, once (where one is set).
	if not rowText[row] and not ns.PlainText(KEY) then
		rowText[row] = true
		ns.Dress(row, TEXT_OPTS, 0, KEY)
	end
end

local function OnRow(_, row)
	if ns.Enabled(KEY) then ns.Guard(RowFn, row) end
end
local function OnRowEach(row)
	if ns.Enabled(KEY) then RowFn(row) end
end

local boxes = setmetatable({}, { __mode = "k" })
local ROW_OWNER = {}
local function Rows(box)
	if boxes[box] then return end
	boxes[box] = true
	local mixin = _G.ScrollBoxListMixin
	local event = type(mixin) == "table" and type(mixin.Event) == "table" and mixin.Event.OnInitializedFrame
	-- Both ways: each row as the list fills it (where the list says so), and the Kit's pass over the
	-- shown rows after each list update (always there). A row is dressed once either way.
	if event and type(box.RegisterCallback) == "function" then
		pcall(box.RegisterCallback, box, event, OnRow, ROW_OWNER)
	end
	Kit.EachRow(box, OnRowEach, KEY)
end

-- ---------------------------------------------------------------------------------------------
-- The pieces of the window TrueshotLodge draws itself
-- ---------------------------------------------------------------------------------------------

-- A pane's inset border (a NineSlicePanelTemplate child with the InsetFrameTemplate layout).
local function NineBorder(frame)
	for i = 1, frame:GetNumChildren() do
		local c = select(i, frame:GetChildren())
		if Usable(c) and c:GetObjectType() == "Frame" and IsTexture(c.TopLeftCorner)
			and IsTexture(c.BottomRightCorner) and IsTexture(c.TopEdge) then
			return c
		end
	end
end

-- A pane (the list, the details, the Stable tab's and the profile's two halves): its inset
-- border and its parchment or dark fill give way to DaylightUI's darker inset.
local panels = setmetatable({}, { __mode = "k" })
local function Panel(frame)
	if not Usable(frame) or panels[frame] then return end
	local border = NineBorder(frame)
	if not border then return end
	panels[frame] = true
	border:SetAlpha(0)
	ns.Guard(Kit.Inset, frame)
end

-- A stable slot: the gold quick-slot frame and the game's checked glow off, a thin DaylightUI
-- outline instead (in the accent on the picked slot), the icon cropped, the hover a white wash.
-- The gray empty-slot ground stays (TrueshotLodge turns it red on a slot not bought yet).
local slotShells = setmetatable({}, { __mode = "k" })
local function SlotPaint(btn)
	local s = slotShells[btn]
	if not s then return end
	local on = Usable(btn.Selected) and btn.Selected:IsShown()
	Kit.Paint(s, on and Kit.SELECTED or Kit.TAB_BORDER)
end

local function SelectedShown(tex)
	local btn = tex:GetParent()
	if ns.Enabled(KEY) then SlotPaint(btn) end
end

local function Slot(btn)
	if slotShells[btn] then return end
	for i = 1, btn:GetNumRegions() do
		local r = select(i, btn:GetRegions())
		if IsTexture(r) and r ~= btn.Empty and r ~= btn.Icon and r ~= btn.Selected then
			if r:GetDrawLayer() == "HIGHLIGHT" then
				r:SetColorTexture(1, 1, 1, Kit.HOVER_WASH or 0.08)
				r:SetBlendMode("BLEND")
			else
				ns.Kill(r)
			end
		end
	end
	if IsTexture(btn.Icon) then Kit.KeepCrop(btn.Icon, 0.07) end
	-- (Over the slot: the empty-slot art is drawn larger than the button and would cover it.)
	slotShells[btn] = Kit.Outline(btn, 2, "outline", true)
	if IsTexture(btn.Selected) then
		btn.Selected:SetAlpha(0)
		hooksecurefunc(btn.Selected, "SetShown", SelectedShown)
		hooksecurefunc(btn.Selected, "Show", SelectedShown)
		hooksecurefunc(btn.Selected, "Hide", SelectedShown)
	end
	SlotPaint(btn)
end

-- The Stable tab's experience bar: its gold edge off, DaylightUI's bar edge instead. Its green
-- fill and its section lines stay.
local function XPBar(bar)
	if panels[bar] then return end
	panels[bar] = true
	for i = 1, bar:GetNumRegions() do
		local r = select(i, bar:GetRegions())
		if IsTexture(r) and r ~= bar.Fill then
			local layer, sub = r:GetDrawLayer()
			if layer == "OVERLAY" and sub ~= -1 then ns.Kill(r) end
		end
	end
	Kit.Shell(bar, "bar")
end

-- The 3D model's box (the Looks tab, the pet profile): its bronze edge and dark ground off, a
-- DaylightUI inset instead. The model stays.
local function ModelBox(box)
	if panels[box] then return end
	panels[box] = true
	ns.Guard(Kit.Inset, box)
end

-- The Learnable By row: its line (the inset border's bronze top edge) a faint hairline.
local function LearnLine(row)
	if panels[row] then return end
	panels[row] = true
	local line = row.line
	if IsTexture(line) then
		line:SetColorTexture(1, 1, 1, 0.08)
		PixelHeight(line, 1)
	end
end

-- The UI Scale slider (MinimalSliderWithSteppersTemplate): a thin track with the accent fill up
-- to a round knob; its two arrows as DaylightUI's bare chevrons; its percentage in DaylightUI's ink.
local KNOB_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local sliderFills = setmetatable({}, { __mode = "k" })

local function SliderPaint(slider)
	local s = sliderFills[slider]
	if not s then return end
	local r, g, b = ns.AccentOf(KEY)
	s.fill:SetColorTexture(r, g, b, 1)
	s.knob:SetVertexColor(1, 1, 1, (not slider.IsEnabled or slider:IsEnabled()) and 1 or 0.4)
end

local function SliderEnter(slider) if sliderFills[slider] then sliderFills[slider].knob:SetSize(14, 14) end end
local function SliderLeave(slider) if sliderFills[slider] then sliderFills[slider].knob:SetSize(12, 12) end end

local function SliderLook(slider)
	if not Usable(slider) or sliderFills[slider] or slider:GetObjectType() ~= "Slider" then return end
	local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
	if not IsTexture(thumb) then return end
	for i = 1, slider:GetNumRegions() do
		local r = select(i, slider:GetRegions())
		if r ~= thumb and IsTexture(r) then r:SetAlpha(0) end
	end
	thumb:SetAlpha(0)
	local track = slider:CreateTexture(nil, "ARTWORK")
	track:SetColorTexture(1, 1, 1, 0.14)
	track:SetPoint("LEFT", slider, "LEFT", 0, 0)
	track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
	PixelHeight(track, 4)
	local fill = slider:CreateTexture(nil, "ARTWORK", nil, 1)
	fill:SetPoint("LEFT", track, "LEFT", 0, 0)
	fill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)
	PixelHeight(fill, 4)
	local knob = slider:CreateTexture(nil, "OVERLAY")
	knob:SetColorTexture(1, 1, 1, 1)
	knob:SetSize(12, 12)
	knob:SetPoint("CENTER", thumb, "CENTER", 0, 0)
	local mask = slider:CreateMaskTexture()
	mask:SetTexture(KNOB_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(knob)
	knob:AddMaskTexture(mask)
	sliderFills[slider] = { fill = fill, knob = knob }
	SliderPaint(slider)
	slider:HookScript("OnEnter", SliderEnter)
	slider:HookScript("OnLeave", SliderLeave)
	slider:HookScript("OnShow", SliderPaint)
	slider:HookScript("OnEnable", SliderPaint)
	slider:HookScript("OnDisable", SliderPaint)
end

local function Steppers(frame)
	skip[frame] = true
	if ns.Controls(KEY) then
		SliderLook(frame.Slider)
		if Usable(frame.Back) then ns.Guard(Kit.BareButton, frame.Back, "left") end
		if Usable(frame.Forward) then ns.Guard(Kit.BareButton, frame.Forward, "right") end
	end
	for i = 1, frame:GetNumRegions() do
		local r = select(i, frame:GetRegions())
		if Usable(r) and r:GetObjectType() == "FontString" then Ink(r, "TEXT") end
	end
end

-- One frame of the window, looked at once: which of TrueshotLodge's pieces it is.
local function Piece(f)
	if f.ForEachFrame and type(f.ScrollTarget) == "table" then
		Rows(f)
		return
	end
	local t = f:GetObjectType()
	if t == "Button" then
		if f.Empty and f.Selected and f.Level then
			Slot(f)
		elseif IsOutlineButton(f) then
			OutlineButton(f)
		end
	elseif t == "Frame" then
		if f.model and f.noModel then
			ModelBox(f)
		elseif f.Fill and type(f.Dividers) == "table" then
			XPBar(f)
		elseif type(f.icons) == "table" and f.line then
			LearnLine(f)
		elseif f.Slider and f.Back and f.Forward then
			Steppers(f)
		end
	end
end

-- ---------------------------------------------------------------------------------------------
-- The passes over the window: when it opens, when a tab is picked, and when one of its panes is
-- shown (the panes are made and filled as tabs are first opened). Queued to the next frame and
-- run once however many asked; list rows are never walked (they are dressed as they fill).
-- ---------------------------------------------------------------------------------------------

local seen = setmetatable({}, { __mode = "k" })
local paged = setmetatable({}, { __mode = "k" })
local AUTO = { rows = false, skip = skip }
local DRESS_OPTS = { skip = skip, checks = false, scrollBars = false }
local Queue
local Visit

-- Each child once from a single GetChildren (a select over a fresh GetChildren per child is n² calls).
local function VisitEach(depth, ...)
	for i = 1, select("#", ...) do
		Visit((select(i, ...)), depth)
	end
end

function Visit(f, depth)
	if depth > 10 or skip[f] or not Usable(f) then return end
	if f.IsProtected and f:IsProtected() then return end
	if not seen[f] then
		seen[f] = true
		Piece(f)
		if skip[f] then return end
	end
	Kit.InkGameText(f)
	-- (A list's rows are dressed as they fill: not walked.)
	if f.ScrollTarget then return end
	local n = f.GetNumChildren and f:GetNumChildren() or 0
	if n == 0 then return end
	if depth >= 1 and depth <= 4 and not paged[f] and f:GetObjectType() == "Frame" and f.HookScript then
		paged[f] = true
		f:HookScript("OnShow", Queue)
	end
	VisitEach(depth + 1, f:GetChildren())
end

local combatWait = false
local function AfterCombat()
	combatWait = false
	Queue()
end

local function Pass(frame)
	Visit(frame, 0)
	if ns.Controls(KEY) then
		if Kit.Walking(frame) then
			-- A walk still under way (a fight pauses it) drops a second one: asked again a moment later,
			-- or, in a fight, once it's over (not a whole pass of the window ten times a second meanwhile).
			if InCombatLockdown() then
				if not combatWait then
					combatWait = true
					ns.OutOfCombat(AfterCombat)
				end
			else
				C_Timer.After(0.1, Queue)
			end
		else
			ns.Guard(Kit.Auto, frame, AUTO)
		end
	end
	if not ns.PlainText(KEY) then ns.Dress(frame, DRESS_OPTS, 0, KEY) end
	-- The side tabs say which is picked through their checked art, which TrueshotLodge sets
	-- without a click when it changes tab itself (the gear, "?", a profile's links).
	Kit.RepaintSoon()
end

local queued = false
local function RunQueued()
	queued = false
	local frame = _G.TrueshotLodgeFrame
	if Usable(frame) and frame:IsShown() and ns.Enabled(KEY) then ns.Guard(Pass, frame) end
end

function Queue()
	if queued then return end
	queued = true
	C_Timer.After(0, RunQueued)
end

-- ---------------------------------------------------------------------------------------------
-- The window's own controls
-- ---------------------------------------------------------------------------------------------

-- The side tabs (LargeSideTabButtonTemplate frames): DaylightUI's icon tab, joined to the
-- window's edge, the picked one in the accent. They can sit on either edge (TrueshotLodge mirrors
-- their parts for the left one; DaylightUI's look is the same both ways round).
local function TabPicked(tab)
	if tab.GetChecked then
		local ok, on = pcall(tab.GetChecked, tab)
		if ok and on ~= nil then return on == true or on == 1 end
	end
	local s = tab.SelectedTexture
	return IsTexture(s) and s:IsShown() == true
end

-- Each tab as a clean tile (ns.SideTile, shared with the Questie and OpenMap packs). Its icon is
-- drawn again on the tile: the template draws its own larger than the tab and nudges it toward
-- the window (more so while pressed), and TrueshotLodge mirrors a left tab's textures (the tile is
-- a child frame, which it only moves, and its anchors read the same mirrored).
local function SideTab(tab)
	skip[tab] = true
	tab:HookScript("OnMouseUp", Queue)
	if not ns.Controls(KEY) or not IsTexture(tab.Icon) then return end
	Kit.Strip(tab)
	if not ns.SideTile(tab, { picked = TabPicked, copy = true, key = KEY }) then return end
	-- Picked or not, when TrueshotLodge shows or hides a tab's checked art itself (the gear, "?",
	-- a profile's links).
	if type(tab.SetChecked) == "function" then hooksecurefunc(tab, "SetChecked", ns.SideTilesPaintSoon) end
	local sel = tab.SelectedTexture
	if IsTexture(sel) then
		hooksecurefunc(sel, "Show", ns.SideTilesPaintSoon)
		hooksecurefunc(sel, "Hide", ns.SideTilesPaintSoon)
		hooksecurefunc(sel, "SetShown", ns.SideTilesPaintSoon)
	end
end

-- The gear (Options) and "?" (Help) by the close button: DaylightUI buttons, their symbol in
-- DaylightUI's text color, in the accent while their section shows (TrueshotLodge locks their
-- highlight then).
local function TitleTint(btn, on)
	local r, g, b
	if on then
		r, g, b = ns.AccentOf(KEY)
	else
		local t = ns.Colors().TEXT
		r, g, b = t[1], t[2], t[3]
	end
	if IsTexture(btn.icon) then
		btn.icon:SetDesaturated(true)
		btn.icon:SetVertexColor(r, g, b)
	end
	if Usable(btn.label) and btn.label.SetTextColor then btn.label:SetTextColor(r, g, b) end
end

local titleOn = setmetatable({}, { __mode = "k" })
local function TitleLock(btn) titleOn[btn] = true if ns.Enabled(KEY) then TitleTint(btn, true) end end
local function TitleUnlock(btn) titleOn[btn] = false if ns.Enabled(KEY) then TitleTint(btn, false) end end

local function TitleButton(btn)
	skip[btn] = true
	if ns.Controls(KEY) then ns.Guard(Kit.Button, btn) end
	local on = false
	if btn.IsHighlightLocked then
		local ok, locked = pcall(btn.IsHighlightLocked, btn)
		on = ok and locked == true
	end
	titleOn[btn] = on
	TitleTint(btn, on)
	hooksecurefunc(btn, "LockHighlight", TitleLock)
	hooksecurefunc(btn, "UnlockHighlight", TitleUnlock)
	btn:HookScript("OnClick", Queue)
end

-- The filter buttons: DaylightUI buttons. TrueshotLodge says a filter is on with gold words, a
-- pulsing gold glow and the red art; off with gray words and the art grayed. Here: on = bright
-- words and an accent line along the bottom, off = DaylightUI's label ink, and no glow.
local filterLines = setmetatable({}, { __mode = "k" })  -- button -> its line
local filterOf = setmetatable({}, { __mode = "k" })     -- font string -> button
local inking = false

local function NoGlow(btn)
	local glow = btn.ftGlow
	if IsTexture(glow) then Kit.Erase(glow) end
end

local glowQueued = false
local function NoGlows()
	glowQueued = false
	for btn in pairs(filterLines) do NoGlow(btn) end
end

local function FilterState(btn, on)
	local line = filterLines[btn]
	if line then line:SetShown(on) end
	local fs = btn:GetFontString()
	if Usable(fs) then
		inking = true
		if on then
			Ink(fs, "VALUE")
		elseif btn.IsEnabled and not btn:IsEnabled() then
			Ink(fs, "OFF")
		else
			Ink(fs, "LABEL")
		end
		inking = false
	end
	NoGlow(btn)
end

local function FilterInk(fs, r, g, b)
	if inking or not ns.Enabled(KEY) then return end
	local btn = filterOf[fs]
	if not btn then return end
	if Near(r, g, b, GOLD) then
		FilterState(btn, true)
	elseif Near(r, g, b, GRAY) then
		FilterState(btn, false)
	else
		return
	end
	-- (Its glow is made right after its words are colored, the first time it's on.)
	if not glowQueued then
		glowQueued = true
		C_Timer.After(0, NoGlows)
	end
end

local function FilterButton(btn)
	skip[btn] = true
	if ns.Controls(KEY) then ns.Guard(Kit.Button, btn) end
	local line = btn:CreateTexture(nil, "OVERLAY", nil, 7)
	PixelHeight(line, 2)
	line:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 4, 3)
	line:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -4, 3)
	PaintLine(line)
	accentLines[line] = true
	filterLines[btn] = line
	local fs = btn:GetFontString()
	if Usable(fs) then
		filterOf[fs] = btn
		hooksecurefunc(fs, "SetTextColor", FilterInk)
	end
	-- What it is now: its glow shows while it's on.
	local glow = btn.ftGlow
	FilterState(btn, IsTexture(glow) and glow:IsShown() == true)
end

-- The details pane's words: its rank line swaps font objects as tabs change (back to the game's
-- gold each time), so the pane's words are inked again after each swap.
local function DetailsInk(fs)
	if not ns.Enabled(KEY) then return end
	local parent = fs:GetParent()
	if Usable(parent) then Kit.InkGameText(parent) end
end

local function Details(details)
	for i = 1, details:GetNumRegions() do
		local r = select(i, details:GetRegions())
		if Usable(r) and r:GetObjectType() == "FontString" then hooksecurefunc(r, "SetFontObject", DetailsInk) end
	end
	for i = 1, details:GetNumChildren() do
		local c = select(i, details:GetChildren())
		if Usable(c) and c:GetObjectType() == "Button" and not IsOutlineButton(c) then
			local w, h = c:GetSize()
			local _, rel = c:GetPoint(1)
			if c.IconBorder then
				-- (The game's round item button, if TrueshotLodge goes back to it: its bronze ring neutral.)
				skip[c] = true
				if IsTexture(c.IconBorder) then
					local n = Kit.TAB_BORDER
					c.IconBorder:SetVertexColor(n[1], n[2], n[3])
				end
			elseif type(w) == "number" and w >= 50 and abs(w - h) < 1 and not c:GetFontString() then
				-- The round icon: its bronze ring in DaylightUI's neutral edge color.
				skip[c] = true
				for j = 1, c:GetNumRegions() do
					local r = select(j, c:GetRegions())
					if IsTexture(r) and r:GetDrawLayer() == "BACKGROUND" then
						local n = Kit.TAB_BORDER
						r:SetColorTexture(n[1], n[2], n[3], 1)
					end
				end
			elseif Usable(rel) and rel.GetObjectType and rel:GetObjectType() == "FontString" then
				-- The name's link to a creature's profile: its gold underline in the accent.
				for j = 1, c:GetNumRegions() do
					local r = select(j, c:GetRegions())
					if IsTexture(r) and r:GetDrawLayer() == "HIGHLIGHT" then
						PaintLine(r)
						r:SetAlpha(0.8)
						accentLines[r] = true
					end
				end
			end
		end
	end
end

-- The title past the logo (it sits over the window's corner, where DaylightUI's titles start),
-- up to the gear and "?" buttons.
local TITLE_X, TITLE_RIGHT = 84, 100

local function Title(frame)
	local tc = frame.TitleContainer
	local title = Usable(tc) and tc.TitleText
	if not Usable(title) then return end
	local top = Kit.TITLE_TOP or 6
	title:ClearAllPoints()
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", TITLE_X, -top)
	title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -TITLE_RIGHT, -top)
end

local dressed = false
local function Dress(frame, K)
	if dressed or not Usable(frame) then return end
	dressed = true
	Kit = K
	OutlineFonts()
	ns.Guard(Kit.Window, frame)
	Title(frame)

	-- The tab's title (bright) and the count under it.
	for i = 1, frame:GetNumRegions() do
		local r = select(i, frame:GetRegions())
		if Usable(r) and r:GetObjectType() == "FontString" then
			local _, rel = r:GetPoint(1)
			if rel == frame or rel == nil then Ink(r, "VALUE") else Ink(r, "LABEL") end
		end
	end

	local list
	for i = 1, frame:GetNumChildren() do
		local c = select(i, frame:GetChildren())
		if Usable(c) then
			local t = c:GetObjectType()
			if type(c.key) == "string" and c.Icon and c.SetChecked then
				SideTab(c)
			elseif t == "Button" and type(c.filter) == "table" then
				FilterButton(c)
			elseif t == "Frame" then
				for j = 1, c:GetNumChildren() do
					local g = select(j, c:GetChildren())
					if Usable(g) and g:GetObjectType() == "EditBox" and g.searchIcon then list = c end
				end
			end
		end
	end
	local tc = frame.TitleContainer
	if Usable(tc) then
		for i = 1, tc:GetNumChildren() do
			local c = select(i, tc:GetChildren())
			if Usable(c) and c.section then TitleButton(c) end
		end
	end

	-- The Filters box: its tan line a faint hairline (its label is inked by the pass).
	for btn in pairs(filterLines) do
		local _, group = btn:GetPoint(1)
		if Usable(group) and not panels[group] then
			panels[group] = true
			for i = 1, group:GetNumRegions() do
				local r = select(i, group:GetRegions())
				if IsTexture(r) then r:SetColorTexture(1, 1, 1, 0.1) end
			end
		end
	end

	-- The panes: the list and the details, and the halves of the Stable tab and the pet profile.
	for i = 1, frame:GetNumChildren() do
		local c = select(i, frame:GetChildren())
		if Usable(c) and c:GetObjectType() == "Frame" and c ~= frame.NineSlice and not skip[c] then
			Panel(c)
			for j = 1, c:GetNumChildren() do
				local g = select(j, c:GetChildren())
				if Usable(g) and g:GetObjectType() == "Frame" then Panel(g) end
			end
			local _, rel = c:GetPoint(1)
			if list and rel == list then Details(c) end
		end
	end

	frame:HookScript("OnShow", Queue)
	Pass(frame)
	Queue()
end

local function Now()
	local frame = _G.TrueshotLodgeFrame
	if not Usable(frame) or not ns.Enabled(KEY) then return end
	ns.WithKit(function(K) Dress(frame, K) end)
end

-- ---------------------------------------------------------------------------------------------

local function Repaint()
	if not (Kit and dressed) or not ns.Enabled(KEY) then return end
	OutlineFonts()
	for tex in pairs(picks) do PaintPick(tex) end
	for tex in pairs(accentLines) do PaintLine(tex) end
	for label in pairs(headerLabels) do HeaderInk(label) end
	for slider in pairs(sliderFills) do SliderPaint(slider) end
	for btn, on in pairs(titleOn) do TitleTint(btn, on) end
	for btn in pairs(slotShells) do SlotPaint(btn) end
	lastAccent[1], lastAccent[2], lastAccent[3] = ns.AccentOf(KEY)
end

local hooked = false
local function Hooks()
	if hooked then return end
	local slash = _G.SlashCmdList
	if type(slash) ~= "table" or type(slash.TRUESHOTLODGE) ~= "function" then return end
	hooked = true
	-- /tsl and /trueshotlodge: dressed straight after the command made and opened the window.
	hooksecurefunc(slash, "TRUESHOTLODGE", function() ns.Guard(Now) end)
	-- The minimap button.
	local ldb = type(LibStub) == "table" and LibStub("LibDataBroker-1.1", true)
	local obj = ldb and ldb:GetDataObjectByName("TrueshotLodge")
	if type(obj) == "table" and type(obj.OnClick) == "function" then
		hooksecurefunc(obj, "OnClick", function() ns.Guard(Now) end)
	end
end

ns.Pack(KEY, "TrueshotLodge", function()
	lastAccent[1], lastAccent[2], lastAccent[3] = ns.AccentOf(KEY)
	-- Its slash command and minimap button are set up as its own load finishes: hooked once they're there.
	Hooks()
	if not hooked then C_Timer.After(0, Hooks) end
	-- However else it opens, as soon as it's found.
	ns.Watch(KEY, "TrueshotLodgeFrame", function(frame, K) Dress(frame, K) end)
	ns.me.On("StyleChanged", function() ns.Guard(Repaint) end)
	ns.me.On("SettingChanged", function(scope, path)
		if scope == "DaylightAddonSkins" and type(path) == "string"
			and string.find(path, "look." .. KEY .. ".", 1, true) == 1 then
			C_Timer.After(0, function() ns.Guard(Repaint) end)
		end
	end)
end, { window = true, controls = true, text = true })
