-- Buttons keep DaylightUI's font after the mouse has been over them.
-- DaylightUI's button look (Kit.Button) puts its font straight on a button's label. A button made
-- from the game's templates also carries font objects, one each for its normal, highlight and
-- disabled states (the game menu's: GameFontHighlightLarge), and the game puts the matching one
-- back on the label each time the state changes: on mouse over, on mouse out, and on Enable or
-- Disable. So a button you had pointed at showed the game's large serif font again until the
-- window was dressed anew (the game menu's Options and Exit Game, and any other window's).
-- Here, right after Kit.Button dresses a button that has font objects, all three are swapped for
-- a font object of ours made from exactly what DaylightUI just put on its label (font, size,
-- outline, shadow, ink). Whatever the game swaps in is then DaylightUI's font. (DaylightUI does the
-- same for Bagnon's title, a button the game re-fonts on every refresh.)
-- Only font objects are set: no script is hooked on the button, so the game's own buttons (the game
-- menu's, shown from its code) are no more touched than DaylightUI's look already touches them.
-- One font object per look (normally a single one), kept on the player's font and ink when
-- DaylightUI's style changes.
local _, ns = ...
if not ns.ok then return end

local API, me = ns.API, ns.me

local made = {}                                   -- "path:size:flags" -> our font object
local count = 0
local done = setmetatable({}, { __mode = "k" })   -- button -> true once given our font objects

local function Usable(x)
	return type(x) == "table" and type(x.GetObjectType) == "function"
		and not (x.IsForbidden and x:IsForbidden())
end

-- Our font object for the look on `fs` now (DaylightUI's font, size and outline, its ink).
local function FontLike(fs)
	local ok, path, size, flags = pcall(fs.GetFont, fs)
	if not ok or type(path) ~= "string" or type(size) ~= "number" or size <= 0 then return nil end
	-- A plain font object has no other alphabets' fonts (ns.SafeFace): where this client's
	-- letters aren't in it, the button keeps the font objects it has.
	if not ns.SafeFace(path) then return nil end
	flags = flags or ""
	local key = path .. ":" .. size .. ":" .. flags
	local f = made[key]
	if f then return f end
	count = count + 1
	f = CreateFont("DaylightAddonSkinsButtonFont" .. count)
	f:SetFont(path, size, flags)
	local r, g, b = fs:GetTextColor()
	if r then f:SetTextColor(r, g, b) end
	local sr, sg, sb, sa = fs:GetShadowColor()
	if sr then f:SetShadowColor(sr, sg, sb, sa) end
	local sx, sy = fs:GetShadowOffset()
	if sx then f:SetShadowOffset(sx, sy) end
	if fs.GetJustifyH then f:SetJustifyH(fs:GetJustifyH()) end
	f.daylightSize, f.daylightFlags = size, flags
	made[key] = f
	return f
end

local function AfterButton(btn)
	if done[btn] or not Usable(btn) or btn:GetObjectType() ~= "Button" then return end
	-- (A button with no font objects keeps the font put on its label: nothing to do.)
	if not btn.GetNormalFontObject or not btn:GetNormalFontObject() then return end
	local fs = btn.GetFontString and btn:GetFontString()
	if not Usable(fs) then return end
	local f = FontLike(fs)
	if not f then return end
	done[btn] = true
	btn:SetNormalFontObject(f)
	btn:SetHighlightFontObject(f)
	btn:SetDisabledFontObject(f)
end

ns.WithKit(function(Kit)
	if type(Kit.Button) ~= "function" then return end
	hooksecurefunc(Kit, "Button", function(btn)
		local ok, err = pcall(AfterButton, btn)
		if not ok then geterrorhandler()(err) end
	end)
end)

-- The player's font or ink changed: our font objects follow (sizes and outlines kept), and every
-- button using one shows it at once.
me.On("StyleChanged", function()
	if count == 0 then return end
	local face = ns.PlayerFace()
	local ink = API.Colors().TEXT
	for _, f in pairs(made) do
		if type(face) == "string" then f:SetFont(face, f.daylightSize, f.daylightFlags) end
		if ink then f:SetTextColor(ink[1], ink[2], ink[3]) end
	end
end)
