-- Keep or Toss: three ButtonFrameTemplate windows (the item page, its detail pane, the intro), and
-- the notice it shows under the game's "delete this item?" popup (KeepOrTossDeleteNotice, a game
-- tooltip of its own, made the first time it's needed): DaylightUI's tooltip shell.
-- The page's item rows and category headers and the detail pane's quest, recipe and reward rows
-- light under the mouse with the game's blue quest-title art: a faint white wash instead. Those
-- rows are made as they're first needed, while the window is open, so each redraw (the end of
-- which sets its list's height) queues a look over the new ones and the window's walk again (their
-- gold header text inked).
-- Left as it is: the rows' own marks (the green tint on items Forever added, the detail pane's
-- every-other-row stripe), item names in their quality colors, and the notice's lines (their
-- colors say how much the item is still needed).
local _, ns = ...
if not ns.ok then return end

local KEY = "KeepOrToss"

-- The rows' blue highlight art, told apart from the scroll bars' own buttons by its file.
local QUEST_HIGHLIGHT = "Interface\\QuestFrame\\UI-QuestTitleHighlight"
local highlightFiles
local function QuestHighlight(tex)
	if not ns.Usable(tex) then return false end
	highlightFiles = highlightFiles or ns.FileIDs({ [QUEST_HIGHLIGHT] = true })
	local ok, file = pcall(tex.GetTexture, tex)
	if not ok or file == nil then return false end
	if type(file) == "string" then file = string.lower(file) end
	return highlightFiles[file] == true
end

-- Each button is looked at once (its highlight art is set as it's made).
local looked = setmetatable({}, { __mode = "k" })
local function Washes(Kit, depth, ...)
	for i = 1, select("#", ...) do
		local child = select(i, ...)
		if ns.Usable(child) then
			if child:GetObjectType() == "Button" then
				if not looked[child] then
					looked[child] = true
					local hl = child.GetHighlightTexture and child:GetHighlightTexture()
					if QuestHighlight(hl) then
						hl:SetColorTexture(1, 1, 1, type(Kit.HOVER_WASH) == "number" and Kit.HOVER_WASH or 0.06)
					end
				end
			elseif depth > 0 then
				-- (The detail pane's long lists sit in an inset with a scroll frame of their own.)
				Washes(Kit, depth - 1, child:GetChildren())
			end
		end
	end
end

-- The list a window's scroll frame shows (the redraw ends by setting its height).
local function ListOf(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if ns.Usable(child) and child:GetObjectType() == "ScrollFrame" and child.GetScrollChild then
			local list = child:GetScrollChild()
			if ns.Usable(list) then return list end
		end
	end
end

local function Again(frame, Kit)
	local list = ListOf(frame)
	local counted = -1      -- the list's children at the last look (the page's rows are reused)
	local queued
	local function run()
		queued = nil
		if not frame:IsShown() or not ns.Enabled(KEY) then return end
		if list then
			-- The page is redrawn on every bag change; only new rows need a look.
			local n = list:GetNumChildren()
			if n == counted and frame == _G.KeepOrTossFrame then return end
			counted = n
			Washes(Kit, 3, list:GetChildren())
		end
		if ns.Controls(KEY) then ns.Guard(Kit.Auto, frame, { rows = false }) end
	end
	local function later()
		if queued then return end
		queued = true
		C_Timer.After(0, run)
	end
	frame:HookScript("OnShow", later)
	if type(frame.SetTitle) == "function" then hooksecurefunc(frame, "SetTitle", later) end
	if list then hooksecurefunc(list, "SetHeight", later) end
	later()
end

local function Window(frame, Kit)
	if not ns.Usable(frame) or not ns.Once(frame) then return end
	ns.Guard(Kit.Window, frame)
	if ns.Controls(KEY) then ns.Guard(Kit.Auto, frame, { rows = false }) end
	Again(frame, Kit)
end

-- The delete notice: the game's tooltip edge out of sight on every showing, DaylightUI's shell in
-- its place (DaylightUI's own tooltip look reaches only the game's tooltips).
local function Notice(tip)
	if not ns.Usable(tip) or not ns.Once(tip) then return end
	local function Hide()
		if ns.Enabled(KEY) and ns.Usable(tip.NineSlice) then tip.NineSlice:SetAlpha(0) end
	end
	Hide()
	tip:HookScript("OnShow", Hide)
	ns.Shell(tip, { noBevel = true }, KEY)
end

ns.Pack(KEY, "Keep or Toss", function(Kit)
	if not _G.KeepOrTossFrame then return false end
	Window(_G.KeepOrTossFrame, Kit)
	Window(_G.KeepOrTossDetailFrame, Kit)
	ns.Watch(KEY, "KeepOrTossIntroFrame", Window)
	ns.Watch(KEY, "KeepOrTossDeleteNotice", Notice)
end, { controls = true })
