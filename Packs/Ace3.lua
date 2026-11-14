-- Every addon's AceConfig / AceGUI settings: tree lines in DaylightUI's inks instead of the
-- game's gold, and AceConfig's gold value text (e.g. AceDBOptions' "Current Profile") in the value
-- ink. Not tied to any one addon: started once the Kit is there, whichever addons are loaded.
local _, ns = ...
if not ns.ok then return end

-- ---------------------------------------------------------------------------------------------
-- Every AceGUI tree's lines, and AceConfig's gold value text (for every addon, not only this one)
-- ---------------------------------------------------------------------------------------------
-- AceGUI's TreeGroup sets each line's font again on every refresh: GameFontNormal (gold) at rest
-- and GameFontHighlight (white) under the mouse and on the picked line, which it keeps
-- highlighted. DaylightUI's Ace3 skin dresses the lines' font and wash but leaves those colors.
-- Every AceConfig tree (RareScanner's settings, and any other addon's) is the same widget, so
-- this block covers them all: after each refresh, every line gets two font objects of ours,
-- DaylightUI's label ink at rest and its value ink under the mouse or picked. They're font
-- objects, so the game switches them itself as a line is hovered or picked, with nothing to
-- redo on hover. Their face, size, outline and shadow are those DaylightUI gives text (read off a
-- hidden string of ours it dresses and repaints), so the lines keep DaylightUI's font. Text an
-- addon colored itself (a color code, a grayed-out line) keeps its color. Only trees
-- DaylightUI's Ace3 skin dressed are inked (their highlight is its wash), so this follows that
-- skin's switch.
-- AceConfig text (Label widgets) with a run in GameFontNormal's color code, such as
-- AceDBOptions' "Current Profile:" value, gets that run in the value ink; any other color code
-- is kept.
-- How they're found: AceGUI's RegisterAsWidget and RegisterAsContainer (each widget as it's
-- made) and Release (one made before this ran, as it's handed back to be used again); at start,
-- the tree lines already made (by name; each knows its tree) and the labels in AceGUI's pool.
-- Self-contained and started once (AceInks.Start), whichever pack starts it.
local AceInks = {
	started = false,
	hooked = {},                                       -- library method -> what was hooked
	trees = setmetatable({}, { __mode = "k" }),        -- TreeGroup widget -> true
	labels = setmetatable({}, { __mode = "k" }),       -- Label widget -> true
	washed = setmetatable({}, { __mode = "k" }),       -- tree line DaylightUI dressed -> true
}
local LABEL_TYPES = { Label = true, InteractiveLabel = true }
local ACE_METHODS = { "RegisterAsWidget", "RegisterAsContainer", "Release" }

-- The fonts: [1] a top line at rest, [2] hovered or picked, [3] and [4] the same for sub-lines.
local treeFonts
local probeBig, probeSmall          -- strings DaylightUI dresses, to read its look off
local filledColors, filledBig, filledBigSize, filledBigFlags, filledSmall, filledSmallSize,
	filledSmallFlags
local WASH                          -- DaylightUI's wash texture, as a texture reports it

local function FillOne(font, base, probe, ink)
	if type(base) == "table" then font:CopyFontObject(base) end
	local face, size, flags = probe:GetFont()
	if face and type(size) == "number" and size > 0 then font:SetFont(face, size, flags or "") end
	font:SetShadowOffset(probe:GetShadowOffset())
	font:SetShadowColor(probe:GetShadowColor())
	font:SetTextColor(ink[1], ink[2], ink[3])
end

-- Refilled only when DaylightUI's inks or its text look changed since (no table made otherwise).
local function TreeFontsReady()
	if not treeFonts then return false end
	local c = ns.Colors()
	local f1, s1, g1 = probeBig:GetFont()
	local f2, s2, g2 = probeSmall:GetFont()
	if c == filledColors and f1 == filledBig and s1 == filledBigSize and g1 == filledBigFlags
		and f2 == filledSmall and s2 == filledSmallSize and g2 == filledSmallFlags then
		return true
	end
	local label = c.LABEL or { 0.76, 0.71, 0.62 }
	local value = c.VALUE or { 1, 1, 1 }
	FillOne(treeFonts[1], _G.GameFontNormal, probeBig, label)
	FillOne(treeFonts[2], _G.GameFontHighlight, probeBig, value)
	FillOne(treeFonts[3], _G.GameFontHighlightSmall, probeSmall, label)
	FillOne(treeFonts[4], _G.GameFontHighlightSmall, probeSmall, value)
	filledColors = c
	filledBig, filledBigSize, filledBigFlags = f1, s1, g1
	filledSmall, filledSmallSize, filledSmallFlags = f2, s2, g2
	return true
end

-- Whether DaylightUI's Ace3 skin dressed this line (it swaps the highlight for its wash).
local function Washed(b)
	if AceInks.washed[b] then return true end
	local hl = b.GetHighlightTexture and b:GetHighlightTexture()
	if not ns.Usable(hl) then return false end
	local tex = hl:GetTexture()
	if tex == nil then return false end
	if type(tex) == "string" then tex = string.lower(tex) end
	if not WASH[tex] then return false end
	AceInks.washed[b] = true
	return true
end

local function InkTree(w)
	if not ns.Enabled() or type(w) ~= "table" then return end
	local buttons = w.buttons
	if type(buttons) ~= "table" or not buttons[1] or not TreeFontsReady() then return end
	for i = 1, #buttons do
		local b = buttons[i]
		if ns.Usable(b) and b.SetNormalFontObject and Washed(b) then
			-- level is AceGUI's own (1 = a top line, set on every refresh).
			if b.level == nil or b.level == 1 then
				b:SetNormalFontObject(treeFonts[1])
				b:SetHighlightFontObject(treeFonts[2])
			else
				b:SetNormalFontObject(treeFonts[3])
				b:SetHighlightFontObject(treeFonts[4])
			end
		end
	end
end

local function InkTreeSafe(w) ns.Guard(InkTree, w) end

local function HookTree(w)
	if AceInks.trees[w] or type(w.RefreshTree) ~= "function" then return end
	AceInks.trees[w] = true
	-- Each tree carries its own copy of RefreshTree; hooked after DaylightUI's (it hooks first).
	hooksecurefunc(w, "RefreshTree", InkTreeSafe)
	InkTreeSafe(w)
end

-- GameFontNormal's gold as a color code in a label's text: the value ink.
local goldCode, goldPattern, valueOf, valueCode
local function LabelText(w)
	if not ns.Enabled() or type(w) ~= "table" then return end
	local fs = w.label
	if not ns.Usable(fs) or not fs.GetText then return end
	local text = fs:GetText()
	if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return end
	local code = _G.NORMAL_FONT_COLOR_CODE
	if type(code) ~= "string" or code == "" or not string.find(text, code, 1, true) then return end
	if code ~= goldCode then
		goldCode = code
		goldPattern = string.gsub(code, "%W", "%%%0")
	end
	local c = ns.Colors()
	if c ~= valueOf then
		valueOf = c
		local v = c.VALUE or { 1, 1, 1 }
		valueCode = string.format("|cff%02x%02x%02x", math.floor(v[1] * 255 + 0.5),
			math.floor(v[2] * 255 + 0.5), math.floor(v[3] * 255 + 0.5))
	end
	fs:SetText((string.gsub(text, goldPattern, valueCode)))
end

local function LabelTextSafe(w) ns.Guard(LabelText, w) end

local function HookLabel(w)
	if AceInks.labels[w] or type(w.SetText) ~= "function" then return end
	AceInks.labels[w] = true
	hooksecurefunc(w, "SetText", LabelTextSafe)
	LabelTextSafe(w)
end

local function AceSeen(_, w)
	if type(w) ~= "table" then return end
	local t = w.type
	if t == "TreeGroup" then
		ns.Guard(HookTree, w)
	elseif LABEL_TYPES[t] then
		ns.Guard(HookLabel, w)
	end
end

-- AceGUI is shared and a newer copy may replace it when another addon loads: hooked again then.
function AceInks.Hook()
	local AG = LibStub("AceGUI-3.0", true)
	if type(AG) ~= "table" then return end
	for _, m in ipairs(ACE_METHODS) do
		if type(AG[m]) == "function" and AG[m] ~= AceInks.hooked[m] then
			hooksecurefunc(AG, m, AceSeen)
			AceInks.hooked[m] = AG[m]
		end
	end
end

-- What AceGUI made before this ran: tree lines by name (each knows its tree), pooled labels.
local function AceEarlier()
	local AG = LibStub("AceGUI-3.0", true)
	if type(AG) ~= "table" then return end
	local n = type(AG.counts) == "table" and AG.counts.TreeGroupButton
	if type(n) == "number" then
		for i = 1, n do
			local b = _G["AceGUI30TreeButton" .. i]
			if type(b) == "table" and type(b.obj) == "table" and b.obj.type == "TreeGroup" then
				ns.Guard(HookTree, b.obj)
			end
		end
	end
	local pools = AG.objPools
	if type(pools) == "table" then
		for t in pairs(LABEL_TYPES) do
			if type(pools[t]) == "table" then
				for w in pairs(pools[t]) do AceSeen(nil, w) end
			end
		end
	end
end

local inkQueued = false
local function InkFontsNow()
	inkQueued = false
	if ns.Enabled() and treeFonts then TreeFontsReady() end
end

function AceInks.Start(Kit)
	if AceInks.started or type(Kit) ~= "table" or type(Kit.Font) ~= "function" then return end
	AceInks.started = true
	WASH = ns.FileIDs({ ["Interface\\Buttons\\WHITE8X8"] = true })
	local holder = CreateFrame("Frame")
	holder:Hide()
	probeBig = holder:CreateFontString(nil, "OVERLAY")
	probeBig:SetFontObject(_G.GameFontNormal)
	Kit.Font(probeBig)
	probeSmall = holder:CreateFontString(nil, "OVERLAY")
	probeSmall:SetFontObject(_G.GameFontHighlightSmall)
	Kit.Font(probeSmall)
	treeFonts = {
		CreateFont("DaylightAddonSkinsAceTree"),
		CreateFont("DaylightAddonSkinsAceTreeHover"),
		CreateFont("DaylightAddonSkinsAceTreeSub"),
		CreateFont("DaylightAddonSkinsAceTreeSubHover"),
	}
	AceInks.Hook()
	AceEarlier()
	local loads = CreateFrame("Frame")
	loads:RegisterEvent("ADDON_LOADED")
	loads:SetScript("OnEvent", function() AceInks.Hook() end)
	-- DaylightUI's inks or font changed: the fonts are refilled (every line using them follows).
	ns.me.On("StyleChanged", function()
		if inkQueued or not treeFonts then return end
		inkQueued = true
		C_Timer.After(0, InkFontsNow)
	end)
end

ns.WithKit(function(Kit) AceInks.Start(Kit) end)
