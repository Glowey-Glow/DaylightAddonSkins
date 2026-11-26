# Addon Skins (DaylightUI Plugin)

## 1.20.0
- RestedXP Guides: a Guide Window choice on its page docks RestedXP's guide to the quest tracker (Daylight UI's, or the game's): under the list at its width, or in the tracker's place with the tracker put away. It follows the tracker by itself, and RestedXP still saves the spot you gave the guide. Off by default.
- RestedXP Guides: the dock's Guide Window choice is on the All Windows page in a RestedXP Guides section, it no longer keeps resizing the guide when there isn't room under the tracker, and it leaves room for RestedXP's current-step panel so it doesn't sit over the minimap.
- Leatrix Plus: the redesigned Sell Junk exceptions and Mute Game Sounds panels match Daylight UI: their search and ID boxes, sort headings, picked rows, Add, Play and Stop buttons, help overlays and tabs. Dragging an item over the list shows an accent outline, and the bag and bank counts in the right-click menu read as information again.
- RareScanner: Wanted alerts show on the same dark panel as other rare alerts (no red parchment over it, the heart stays), and the explorer's new Wanted settings panel is dressed like the rest of the explorer.
- Polestar: the guide window's edge tabs and side strip look like tabs joined to the window, a toast border set in Polestar no longer draws over the Daylight UI frame, and Polestar Arcade's Tetris window is dressed.
- Questie: the tracker's quest tooltip (shown in a group) and the profiler window are dressed.
- Shortest Path Forever: the Quick Nearby button on the world map is dressed.
- Forever Leveling BiS: the stat weights editor's "Save your changes?" question has the Daylight UI look.
- Spoken: the Contribute button on the world map's quest details has the Daylight UI look.
- ALL THE THINGS: the redesigned Information settings page is dressed the moment it opens, folds open or shows search results.
- Details!: the link copy box and the copy-value box have the Daylight UI look.
- Journey Guides: Custom Link Colors also color the arrow's location labels, and the logo's ring hides with the logo.
- Removed the dead Get Addon link for Mastercraft (its CurseForge page is gone) and checks for windows Questie and Shortest Path Forever no longer have.
- Dungeon Journal 2.1.7: the new menus (a quest row's Share and Abandon, the PvP icon's Hide, Edit Mode's Reorder and View), Edit Mode's Reset UI question and first-time note, and the Honor & Ranks class list are dressed like its other popups.
- With another of Glowey's plugins on, Addon Skins' pages sit under one "Glowey's" entry on Daylight UI's options rail.

## 1.19.2
- The game's Options window: rows are dressed for a moment after each click, scroll, key or hover onto a control, instead of ten times a second for as long as the mouse rested on the window.
- Shortest Path Forever: the tracker's departure countdown restyles without making new tables each second, and leaves the section head alone when its words haven't changed.
- Auto Skinner: a click re-dresses only the window it was in, not every dressed window open.

## 1.19.1
- Addon Skins never adds a mouse hook to a frame of another addon that doesn't already take the mouse, so a skinned panel can't start catching hovers and clicks meant for what sits under it (data text panels, addon drawers).
- An error in a skin while another addon's window opens or is hovered is caught, so that addon's own work goes on.
- Guildy: if Guildy doesn't take over the guild window, the game's guild window comes back fully visible instead of open but invisible and still in the way of clicks.
- OpenMap: every Dungeon Journal map marker comes back when the dungeon view closes, including one the journal moved or reused.
- BugSack reports now end with this addon's name and version on its own errors, so a report says which version it came from.

## 1.19.0
- No more checking several times a second while nothing happens. Addon Skins looked for windows to dress twice a second for as long as you played; now it looks only right after something that can open one (a click, an addon loading, a loading screen, a merchant, trainer, Auction House or loot window, the game opening a panel, or a new window being made), for a quarter second and then a few single looks. The Auto Skinner's 2-second check is gone the same way, and so are the menu-font watcher's five looks a second while a game menu is open.
- Packs that kept watching on a timer now follow their addon's own changes instead: Guildy, Mastercraft, Shortest Path Forever (its tracker dock was re-measured four times a second), the game's Options window (ten times a second while open), Forever Leveling BiS and the LayerSwap minimap button.
- The conflict question at login no longer re-checks every 3 seconds while Daylight UI is busy or you're in a fight: it asks again after the fight or your next click.
- New: Curator. Its album and every page in it (inventory, albums, social, contracts, achievements, profile, quests, talents, inns, discovery, Winter Veil, statistics, boosters), the Exchange (all four pages, the sheet, the picker, the price popup), the merchant, the reseller, the Ruby Counter, the inn counter and bet, golden quests, the bank, restoration and copy panels, the card view, news, gift, search, leads, the tour, the options and the small windows: the Daylight UI window, buttons, tabs, side tabs, dropdowns, checkboxes, bars, lists and scroll bars, your font face and inks. The cards, boxes, scenes, celebrations, rarity colors and the gold Claim buttons stay as Curator draws them, and text keeps Curator's own sizes so nothing it fits is cut short. The skin never touches Curator's card data, so Curator's own guard never stops your rewards.

## 1.18.14
- TrueshotLodge 1.60.1.47: its window is dressed again. The pet profile's new Target button is one of the game's protected buttons, and it made the whole window protected outside fights, so the skin left all of it as TrueshotLodge draws it. The window is dressed again out of combat (the Target button itself stays the game's). The new Database Search tab is dressed too: its six filter menus, its column heads and its lines, and the Map button's "Instance" word. The creature details pane also gets its look when the window first opens on Database Search.
- Forever Fishing 0.9.251: after you switch between its windows (Journal, Settings, Session Goals, the Tracker), the Daylight UI window frame stays under each window's own words and art. Forever Fishing's new window stacking had lifted it over them.
- LayerSwap 1.14.56: the minimap layer button reads "Layer: Current" or "Layer: New" on WoW Forever, where LayerSwap now names your layer that way, instead of "Layer: ?".
- ALL THE THINGS 5.4.19: on its rebuilt Information settings page, the checkbox words are in your text color again, and its group headings get your heading color and a plain + / - in place of the round gold buttons.
- Spoken 3.13.0: the new profile Export / Import window gets the Daylight UI window.
- Forever Leveling BiS 1.5.0: the wish-list picker opened from the on-screen tracker's title is dressed like the one in the main window.
- Checked against today's updates, nothing else to change: Daylight UI 2.2.7, Guildy 1.15.0, LFG Forever 2.7.0, and (from CurseForge) AtlasLoot Continued 13001, Camping Kit 1.11.2, Details!, DoesItDie 0.10.1, Journey 4.00.14, Kerzo Classic Quest Log 6.6.3, Kerzo Quest Expansion 2.1.2, Questie 12.14.0, RareScanner 1.60.1.12 and Shortest Path Forever 1.45.8.

## 1.18.13
- No more hitches every few seconds. The search for other addons' windows (the Auto Skinner's, which runs even with all its switches off) is meant to look only at frames made since its last look, but it often kept its place on one of the game's buff icons, which the game later no longer finds. Then it went through every frame in the game again at once: about 27,000 frames, a hitch of over 100 ms every 8 to 10 seconds. It now never keeps its place on a buff icon, skips frames it has already looked at, and does at most a set amount of work in one frame, finishing on the next ones.
- Windows that haven't been made yet are looked for with less work after each click: whether each one's skin is on is asked once, not on every frame.

## 1.18.12
- The game's Auction House window, once Daylight UI hands it back (you picked the game's window, or a fight started), is laid out at its own size again. While Daylight UI's window stood in for it, the game's was kept tiny and as wide as Daylight UI's, and two things stayed that way: the "Daylight UI window" link on its header grew across the whole header and past its left edge (a click anywhere there swapped windows), and the list's columns ran past the window (Available outside it). The link is sized to its words again and the lists' columns laid out again at the window's width.
- Lighter: less work every frame and on every click. Waiting windows are looked for a few times a second instead of every frame (every frame for a moment after a click), skins for addons you don't have no longer wait for them, open game menus and the AtlasLoot Continued, ALL THE THINGS and Guildy windows are kept up for less, and the game's item buttons and chat tabs pass through quicker.

## 1.18.11
- The choice window and the copy box follow Daylight UI's look, scale and window feel: their colors and the hover tips on the options pages change with your look, they open and close with Daylight UI's sounds and fade, Escape closes them, and they work with a controller.
- LFG Forever 2.6.0: Compact mode's arrow (left of the Filters tab) is a Daylight UI page button, its chevron turning the way it acts. Checked against ALL THE THINGS 5.4.18, AtlasLoot Continued 12997 and Shortest Path Forever 1.45.5: nothing to change.

## 1.18.10
- Checked against Daylight UI 2.2.5 (from 2.2.2: 2.2.3, 2.2.4 and 2.2.5). Nothing to change: dressed windows, tooltips, the bag marks and the overlap window work as before.
- Sits under the DaylightUI Plugins heading in the AddOns list.
- Dungeon Journal 2.1.4: the new red "Best done together with:" line on a quest's page (the Mallet of Zul'Farrak) keeps a warning color under Daylight UI's journal skin, like the journal's other warnings. Its quest button beside it is dressed by Daylight UI's journal skin.
- Questie 12.13.0: its settings window's new Search box and label take your font and Daylight UI's look. Each tab, now built out of sight and swapped in when done (and built again on every letter typed in the search), keeps its thin rule, scroll bar and your font, and the "No matching options" line is in the text color.
- High Fidelity World Map 1.4.14: the cave window's ground moved, so on the first cave of a session its tiled dialog ground showed again, "Cave map opacity" stopped reaching the Daylight UI window and the depth slider and floor menu stayed undressed. Fixed: the ground is found where it now lives, on every cave until found. The new maximize / restore pair is Daylight UI's bare chevrons, as on the world map.
- LayerSwap 1.14.49: the new event box (what just happened, in the layer list's place) is in your font and Daylight UI's colors, its green, orange and blue marks kept. Its lines that grow to fit their words are now measured in your font, so long status lines are no longer cut short.
- DoesItDie 0.10.0: each options tab is now a scrolling page; its scroll bar's thumb keeps the size of the page after the Daylight UI look goes on.
- OneForAll 6.2.16: its new Dungeon tracker window takes the Daylight UI window like its others. Its own Opacity slider has no effect under the Daylight UI window.
- Checked against today's updates of the addons you have installed: Keep or Toss 2.5.1: nothing to change.
- Checked against today's releases of the addons you may not have installed: ALL THE THINGS 5.4.17, AtlasLoot Continued 12993, Auctionator 352, Forever Leveling BiS 1.4.7, Kerzo Classic Quest Log 6.6.2, Mastercraft 2.1.1, Shortest Path Forever 1.45.4 and Spoken 3.12.1: nothing to change. The other supported addons have no new release.

## 1.18.9
- Checked against Daylight UI 2.2.2 (from 2.1.3: 2.2, 2.2.1 and 2.2.2). Nothing to change: dressed windows, tooltips, the bag marks and the overlap window work as before, including with its new way of holding the game's spellbook, profession and Auction House windows out of sight.
- AtlasLoot Continued 12987: its new Atlas Nav look (now its default) is left as AtlasLoot draws it: the window, Favourites, What's New, the theme chooser and its new settings window. Before, the Daylight UI look was laid over Nav's own, so the two fought (a box inside a box, light words on its light panels). With the legacy look (/al style legacy) everything is dressed as before.
- LFG Forever 2.5.0: the new red x that takes your own listing down gets the Daylight UI button, like Invite and Ask to Join.
- Dungeon Journal 2.1.3: the reset question the tracker asks with a controller connected takes the Daylight UI window and buttons, and the "Click the item to see location" note on a quest's page gets its box back (it showed as words floating over the page).
- OneForAll 6.2.13: its new switches that skip the talk at vendors, bankers, trainers, auctioneers, stable masters, the guild bank, tabard vendors and battlemasters are the same as Daylight UI's skip-gossip. If you turned any on, the overlap window asks once who handles it (Daylight UI by default), and each one can be put back on the OneForAll page.
- Shortest Path Forever 1.45.3: the Quests tab beside the quest log is a Daylight UI side tab, clicking it clears the services tab's outline again, and the "Reset tab position" menu opens already dressed.
- Spoken 3.12.0 with a controller: the profile questions (copy, delete, new, forget visited places) take the Daylight UI window, and the Compendium's filter looks like a Daylight UI menu. On subtitles, "(Waiting...)" and "+2" are in the label color like the rest.
- Mastercraft 2.0.9: hovering a "Some" tile on the craft orders board shows your accent instead of gold.
- Questie 12.12.0: its right-click menus are now the game's own and take Daylight UI's menu look; the skin no longer looks for its old menus there.
- Checked against today's updates of the addons you have installed: Keep or Toss 2.4.1, OpenMap v0.8.13 and Polestar 0.4.2.2. Nothing to change for Keep or Toss and Polestar. OpenMap: its own map-pin button handling (0.8.12) is left to it.
- Checked against today's releases of the addons you may not have installed: ALL THE THINGS 5.4.16, Auctionator 351, Forever Leveling BiS 1.4.5, High Fidelity World Map 1.4.13, Kerzo Classic Quest Log 6.6.1, Leatrix Plus 1.60.37, Pawn 2.14.8 and RareScanner 1.60.1.11: nothing to change. The other supported addons have no new release.

## 1.18.8
- Spoken, easier to read (checked against Spoken 3.11.0):
  - Subtitles: a flat dark plate behind the words in place of Spoken's soft, see-through shade, so every letter has the same ground under it. It follows Spoken's own Subtitle Shadow setting and is more solid at each step (its 60% is 80% here; at 0 there is no plate). The speaker's name is in Daylight UI's title color and the small gray labels in its label color.
  - Small Window: no more paper page inside the dark frame. With Spoken's background set to Parchment its words were dark ink on paper; the paper is put away and the name, title, counters and captions are written light, as on its Dark setting.
  - Sizes stay Spoken's to set: Subtitle Size (or Ctrl and the mouse wheel over a subtitle) and Window Size in its options. Its narrator windows start at 70%.
- Dialogue UI: a quest's rewards to choose from keep their item colors. While a reward was waiting to be picked, each choice sat on Dialogue UI's bright red plate (its Dark theme's own art, which on the dark shell read as "you can't use this"), and the skin wrote every name in your accent color, so a pink accent made common items look epic. The names are now in each item's quality color, there as everywhere else, and the plate is the same art without its red.

## 1.18.7
- Fixed: opening the macro window raised an error ("ScrollBox.lua:595: attempt to index a nil value"). The game builds some lists the first time they are shown: the macro grid, the icon grid of every icon picker (macros, equipment sets, guild bank and bank tabs) and the Auction House's item lists. Daylight UI's window skins asked those lists for their rows before that. Such a list now waits until the game has built it, then its rows are dressed as usual. Nothing changes for lists that are ready.
- Fixed: the game's own letter window (Daylight UI's mailbox off) set its text color in a form the game no longer takes, which could raise an error when a letter was opened and switch the Game Windows skins off.
- Fixed: with the Spells and Talents switch off, the character window and the currency transfer window were not dressed either. Each now follows its own switch (Character Frame).
- Fixed: the small hide button on the dungeon-ready dialog and its "waiting" box takes the Daylight UI look.
- Every game window skin, Daylight UI's and this plugin's, was read against the game's own code for errors; the fixes above are what that turned up.

## 1.18.6
- Checked against today's later releases of the addons you may not have installed: Camping Kit 1.11.1, Forever Fishing 0.9.224, Forever Leveling BiS 1.4.4, Leatrix Plus 1.60.36, LootTriage 1.2.1, Mastercraft 2.0.8, Pawn 2.14.7 and Shortest Path Forever 1.43.10. Nothing to change for Forever Fishing, Leatrix Plus and Pawn; the other supported addons have no newer release.
- Camping Kit 1.11.1: its redrawn settings window is dressed throughout: the new Find a Setting box, the cards round each group of settings, choice buttons and chips (the picked one in your accent), color squares and their Custom button, the tick box table with its fold arrows, the small dark buttons, and the search results. The Snap tick on the placement bar is in your accent again, and the new layout editing bar takes the Daylight UI window.
- Forever Leveling BiS 1.4.4: the wish list panel is dressed once instead of twice, and folded, its new star tab takes the Daylight UI look.
- LootTriage 1.2.1: every page of its settings window is dressed the first time you open it. LootTriage now builds a page when you first click it, so the new pages' checkboxes, dropdowns and headings showed in the game's look until the window was opened again.
- Mastercraft 2.0.8: its new windows are dressed (the address copy box, the Food to Keep and Never Suggest lists, the craft orders pop-up), and on the craft orders board and the new Professions road the gold-brown row edges are Daylight UI's neutral lines and the gold hover is your accent.
- Mastercraft: whether its skin is on is now remembered per character by the character itself instead of by "Name-Realm". The game stopped telling addons the realm name, so two characters with the same name shared one record and earlier records were no longer found; Mastercraft could then start in the wrong style until the next reload. What was recorded before is taken over, nothing is lost.
- Shortest Path Forever 1.43.10: the notice ForeverCore shows when a separately installed ForeverCore is older than the one built into your addons is now a small window of its own, and it takes the Daylight UI look.
- Checked against today's later updates of the addons you have installed: Dungeon Journal 2.1.1, LayerSwap 1.14.41 and OpenMap v0.8.11 (nothing to change for LayerSwap: its panel, mini bar, menus and the Layer button work as before with the game's new layer numbers).
- Dungeon Journal 2.1.1: its warnings, now blue, stay in Daylight UI's warning color like the red ones before, including the line under a boss's name and "Requires: ..." under Starts At. A reputation you don't have no longer shows in green after a quest whose reputation you had.
- Dungeon Journal 2.1.1: on a quest's page, the level in "Available from Level ..." is red again while your character is too low (Daylight UI's journal skin had turned it plain), and "Dungeon Chain Step" keeps its light blue.
- Dungeon Journal 2.1.1: the one-time note under the new Export button gets the Daylight UI window and button instead of being see-through, and the flight bar under its arrow is a Daylight UI bar in your accent color.
- Dungeon Journal 2.1.1 with a controller: the frame around what you've picked shows in your accent color. Daylight UI's journal skin hid the journal's gold frame after the first button press, so nothing marked your pick.
- OpenMap v0.8.11: the new "The game's map" button on its dungeon map is widened when your font needs it, and after you click it Dungeon Journal's dungeon map comes up right away instead of the next time you open the map.
- Checked against Daylight UI 2.1.3: its fuller Auction House (bids, Sell and My Auctions changes, your gold on the header), loot roll cards, Rich tooltips as the default for new profiles, and the flight timer's land button. Nothing to change: dressed windows and tooltips look and work as before.

## 1.18.5
- Auto Skinner: an addon it has found stays on its list under All Windows. Before, the list only held addons whose windows had been opened since you logged in, so a switch you had turned on was missing from the list after a login until that window was opened again. An addon found while the options are open now shows there at once.
- Checked against Daylight UI 2.1.2: its new setup guide, the per-window "Use Daylight UI global style" switch, gradient bars, the game's roll popups in Daylight UI style and the profession window's Profit. Nothing is dressed twice, and the overlap window still waits for the setup guide.
- Fixed for Daylight UI 2.1.2: tooltips dressed by a skin follow the tooltips' own look again (Tooltips > Borders and background): border, corners, shadow, background color and opacity. Daylight UI 2.1.2 moved those settings, so dressed tooltips had fallen back to the General look. This covers ALL THE THINGS' model box, Keep or Toss's sample item, Questie's, RareScanner's and Total RP 3's tooltips and Details!' menus and tooltips.
- Fixed for Daylight UI 2.1.2: Shortest Path Forever's sections docked under Daylight UI's quest tracker have the tracker box's look again (Quests > Borders and background), with or without the global style.

## 1.18.4
- Fixed: with Daylight UI's Bags off, opening the game's own bags raised an error ("BlizzardFallbacks.lua:952: attempt to call a nil value") and the bags were left undressed. The game's bags, separate or combined, are dressed again.

## 1.18.3
- Checked against Daylight UI 2.1.1. Its game windows now follow the Daylight UI scale; dressed windows follow along.
- Checked against today's updates of the addons you have installed: Keep or Toss 2.3.0 and LayerSwap 1.14.40. Nothing to change for either.
- Keep or Toss 2.3.0: its new Lookup page (the "Item name, link, or ID" field above the journal) sits on Daylight UI's window in the Minimal dark look like the rest of the journal, with its words in your font. Its result rows, scroll bar and colors stay its own, as on its other pages.
- LayerSwap 1.14.40: only its timing changed (it leaves the host's group 4 seconds after joining), so its panel, mini bar, menus and the Layer button look and work as before.
- Checked against today's releases of the addons you may not have installed: ALL THE THINGS 5.4.15, AtlasLoot Continued 12981, Forever Leveling BiS 1.4.2, Kerzo Classic Quest Log 6.6.0, RareScanner 1.60.1.10, Shortest Path Forever 1.43.9 and Camping Kit 1.11. Nothing to change for ALL THE THINGS, AtlasLoot Continued, Forever Leveling BiS, RareScanner and Camping Kit; the other supported addons have no new release.
- Shortest Path Forever 1.43.9: the skin works again. Since 1.43.6 Shortest Path carries ForeverCore inside itself and starts at login instead of while the game loads, so the skin no longer found it: nothing of it was dressed, the Forever sections were not put under Daylight UI's quest tracker, and its overlaps were not offered. All of that is back, with or without a separate ForeverCore installed.
- Shortest Path Forever 1.43.9: its right-click menu's submenus, which now open beside the menu as windows of their own, take the Daylight UI look too, and a row under the mouse is lit in your accent instead of the game's blue.
- Shortest Path Forever 1.43.9: turning the dock under Daylight UI's quest tracker on or off keeps your Tracker Position choice (Under or Left of the quest tracker) instead of resetting it.
- Kerzo Classic Quest Log 6.6.0: its new Quest Details window (the tracker's "Open Quest Details Only" click mode) is dressed: the Daylight UI window, its Open Quest Log, Abandon, Share and Track buttons, and the quest's details as in the quest log.
- Kerzo Classic Quest Log 6.6.0: in its reorganized settings, every group's sub-headings are flat Daylight UI boxes (bright when open) and the new Expand All button is a Daylight UI button. In the difficulty colors window, the new color buttons have a quiet edge that turns your accent color under the mouse; the colors themselves stay yours.

## 1.18.2
- Checked against Daylight UI 2.0, released today: its new Auction House window, Rich tooltips, loot roll cards, portraits, nameplate options and welcome window. Nothing is dressed twice, and everything works as before on Daylight UI 1.9.
- The overlap window (the one that asks who handles a feature both an addon and Daylight UI have) no longer opens on top of Daylight UI's "Welcome to Daylight UI 2.0" window. It now waits for that window, Daylight UI's setup guide, tour and questions, and the welcome of any other Glowey plugin, and opens once the screen is free. If you log out first, it asks at your next login.
- Tooltips dressed by a skin get the same border as Daylight UI 2.0's own tooltips: the thickness set under Tooltips > "Own border and background", or General's when that's off, and they follow it as you change it. Before, they kept the thin border of older versions. This covers ALL THE THINGS' model box beside the tooltip, Keep or Toss's sample item, Questie's minimap and gamepad tooltips, RareScanner's tooltips, Total RP 3's tooltips and Details!' menus and tooltips. (Rich tooltip cards are Daylight UI's own, for the game's tooltip: addon tooltips keep the Simple look in both styles, as they do in Daylight UI itself.)
- Auctionator and Mastercraft: while Daylight UI 2.0's own Auction House window is the one you use, their pages, tabs and buttons on the game's hidden window are no longer dressed at every opening. Switch to the game's window (the swap icon on Daylight UI's Auction House header) and they're dressed right away.
- /skins report now also lists Daylight UI 2.0's tooltip look and border, which Auction House window is in use, and whether its loot roll cards are on.

## 1.18.1
- Checked against today's updates of the addons you have installed: Daylight UI 1.9.6, Dungeon Journal 2.1.0, LayerSwap 1.14.39 and LFG Forever 2.3.0 (nothing to change for LFG Forever).
- Dungeon Journal 2.1.0: on a quest's page, the new red note under the objective and the other red warnings stay red, "Requires Neutral with Timbermaw Hold" is green or red by your standing, its reputation bar takes the Daylight UI look (standing color kept), and the mark around a required item from the dungeon you're viewing is your accent color.
- Dungeon Journal: the buttons under its arrow ("Skip for now", "Not found? Next spot") are Daylight UI buttons, widened when your font needs it.
- LayerSwap 1.14.39: the new Swap button on its mini bar takes Daylight UI's colors (your accent under the mouse, dim while it can't swap) instead of gold, and a mini bar set to On Hover fades out again when the mouse leaves over that button. The panel is dressed at once when its new key bindings or the Swap button make it.
- New overlap, asked once: Polestar's flight timer. Daylight UI 1.9.6 turned its own flight timer into a banner over the world with your route, so both showed on every flight. Daylight UI's is the default; switch it back on the overlap window.
- Checked against today's releases of the addons you may not have installed: AtlasLoot Continued 12978, Forever Fishing 0.9.220, Forever Leveling BiS 1.4.1, Journey 4.00.13, Leatrix Plus 1.60.35, OneForAll 6.2.12, Questie 12.11.1 (QuestieTrace 1.13.0) and Spoken 3.10.1. Nothing to change for Forever Fishing, Forever Leveling BiS, Journey, Leatrix Plus, Questie and Spoken; the other supported addons have no new release.
- AtlasLoot Continued 12978: its new What's New window (shown once after an update, or /al changelog) is dressed: the Daylight UI window in place of its teal ground and header art, the list in an inset with Daylight UI's scroll bar, its checkbox and Close button, section headings in Daylight UI's colors. Item names keep their quality colors.
- OneForAll 6.2.12: the new Guild Games window and its invite and "your turn" pop-ups take the Daylight UI window (the wood ground behind the card table is gone, the table itself stays), and its buttons are recolored as you click through its games. The Skill-Up Helper's new green "Open guide" button stays green, and goes back to the gray plate when it's switched off.

## 1.18.0
- New skins: ALL THE THINGS (its list windows, mini list and popouts, the report box, its side tabs on the auction house and profession windows, and its settings pages), Auctionator (its tabs, result lists, shopping lists, selling bag, dialogs and pop-ups, and its panel on the profession window), Altoholic (its window and all seven tabs, lists, sort headers, dropdowns, calendar and grids) and Leatrix Plus (its options window, every settings panel, its dropdown lists and its own small windows).
- New overlaps, asked once (switch any back): ALL THE THINGS' Skip Cutscenes; Altoholic's item counts and item IDs in tooltips; and 21 Leatrix Plus options Daylight UI also has (quest automation, sell junk, repair, faster looting, error messages, camera zoom, Train All, the minimap, tooltips, chat buttons, fading, history and arrow keys, action bar text and range coloring, and more). Leatrix Plus reads its settings only as it loads, so its hand-overs take effect after a reload.
- Auto Skinner (BETA): sliders, old-style dropdowns and the newer slim scroll bars are dressed now, backdrop windows get the Daylight UI close button and resize grip, and dialogs on the tooltip layer are found. Round radio buttons keep their dots instead of turning into square boxes, and an addon's own custom checkboxes and toggle tabs keep their look.
- Radio buttons keep the game's round dots in every skin, instead of becoming switches.

## 1.17.0
- Checked against today's updates, including the addons you may not have installed: Polestar 0.4.1.1, Keep or Toss 2.2.0, Dungeon Journal 2.0.12, LayerSwap 1.14.35, Questie 12.11.0, RareScanner 1.60.1.9, Mastercraft 2.0.7, LootTriage 1.2.0.1, Shortest Path Forever 1.43.2, Kerzo Classic Quest Log 6.5.2, Kerzo Quest Expansion 2.1.1, Forever Leveling BiS 1.3.5, AtlasLoot Continued and Dialogue UI.
- LootTriage 1.2: its new settings window (/lt) is dressed: its page list, headings, checkboxes, sliders, dropdowns, buttons and What's New link. What's New is dressed again (it moved to a higher layer), and the new Delete button on the loot window gets the Daylight UI button look.
- Keep or Toss 2.2: the sample item on its settings page takes Daylight UI's tooltip look instead of the game's blue tooltip art.
- Shortest Path Forever 1.43: the Forever column docks flush under Daylight UI's quest tracker again (its grip bar is gone), and goes back to its own spot when you turn the dock off. ForeverCore's quest list is gone, so it's no longer asked about.
- Mastercraft 2.0.7: its network report window (/mc report) and its Chinese What's New and setup guide are dressed.
- Kerzo Classic Quest Log 6.5.2: the Expansion section's new dropdowns are dressed.
- Forever Leveling BiS 1.3.5: window titles in its Modern theme take Daylight UI's title color instead of gold.
- LayerSwap 1.14.35: the map button reads "Layer: ..." in flight instead of "Layer: ?".
- New overlap, asked once: Polestar's zone level ranges on the world map. Daylight UI 1.9.4 shows the hovered zone's range by its name, from different numbers, so both showed and disagreed. Daylight UI's is the default; switch it back on the overlap window (Polestar's continent map labels go with it).

## 1.16.1
- Renamed to Addon Skins (DaylightUI Plugin) in the AddOns list and on CurseForge, so it's clear it's a plugin and not part of Daylight UI. Inside Daylight UI it's still Addon Skins. Your settings are kept.

## 1.16.0
- New skins: Details! (its meter windows follow Daylight UI's own meter look: bars, track, font, rows; plus its options, breakdown, report windows, menus and tooltips), AtlasLoot Continued and Pawn. Details' meter windows join the Daylight UI overlaps (Daylight UI's damage meter by default).
- The overlap window now reads the other way round: on = the addon keeps its own, off = Daylight UI handles it. Daylight UI is still the default, and the choices you already made are kept. The switches on Look and Feel match.
- /skins: every addon's state (Active, Switched Off, Not Installed, Not Enabled on This Character, Error). /skins report opens a copy box with a full report for bug reports, /skins retry tries a skin again. All Windows has a Status card with the same list.
- A skin that runs into an error is switched off with one chat line instead of erroring again and again, its card shows the error, and it's tried again by itself once the addon or Addon Skins updates (or right-click its card).
- An addon that's installed but switched off on this character shows so on All Windows, without a Get Addon link.
- Every skin now hooks and refreshes through one shared layer: fewer repeated passes, and one skin's error can't break another. A few refresh passes now wait for a fight to end, as the game windows already did.
- LayerSwap: a Layer Button row in its settings menu (Shift + click: Always or On Hover), and its menus close when you click anywhere else.
- Labels and buttons in Title Case, and "Daylight UI" written with a space.

## 1.15.0
- Checked against today's addon updates, including the addons you may not have installed.
- No more doubled borders on game windows DaylightUI dresses itself: the Battle.net friend toast, the layering notice and its minimize button, the master looter's item, and the profession window (its side tabs, Create buttons and cards). The Game windows skin now leaves those to DaylightUI while its System skins are on, and still dresses them when they're off.
- The game's trainer window is dressed again with DaylightUI's NPC module off (neither DaylightUI nor this skin dressed it then).
- Keep or Toss 2.0: rewritten for its new journal. It switches to Keep or Toss's own Minimal dark look (a new switch on its page; your old look comes back when you turn it off) and gets DaylightUI's window shell and your font. Its tabs, buttons and boxes keep its own colors for now.
- Polestar 0.4.1: its guide window's own text size works with the skin on. Its new "Completed quest XP" joins the DaylightUI overlaps (DaylightUI's XP bar shows banked quest XP). Its new Arcade window takes the DaylightUI look.
- Questie 12.10.0: QuestieTrace's consent and export windows are dressed (they took over from Questie's debug offer).
- Dungeon Journal 2.0.10: the loot filter's slot box, the loot search progress, the resize notes, the Tier Sets page with its Hide menu and the "who drops it" box are dressed.
- Mastercraft 2.0.5: its new Looking For Crafter banner and panel in the game's Group Finder are dressed.
- Kerzo Classic Quest Log 6.5.0: its new "classic light parchment" setting no longer draws dark text on the dark skin.
- Kerzo Quest Expansion 2.1.0: the new Expansion Summary button and language dropdown are dressed.
- LFG Forever 2.2.0: the new note line on Quests & Zones rows uses your font.
- LayerSwap: its mini bar can fade like DaylightUI's minimap buttons (LayerSwap's mini bar: Always or On hover, on its page).

## 1.14.5
- Looting no longer hitches with addons that mark bag slots (Polestar's upgrade arrows and quest marks, Keep or Toss). Their refresh after each bag change made DaylightUI's bags ask every mark again for every slot of every bag and bank window, closed ones too, in one frame. Now open windows repaint at once and closed ones fill again in the background or as they open, marks included.

## 1.14.4
- **Auto Skinner (BETA):** a new section on All windows lists your addons that have no skin of their own and have windows (found on their own). Turn one on for a basic DaylightUI look on its windows: the window frame, title and close button, the game's standard buttons, boxes and scroll bars, your font, and DaylightUI's heading color in place of the game's gold. Copies of the game's old dropdown menus get DaylightUI's menu look too, ticks in your accent (BtWQuests' options menu). The addon's own art stays. Every one starts off. /skinsauto lists what was found. It's a beta: an addon it doesn't support yet may not be dressed properly, and that isn't a bug.
- Questie: its settings' text buttons no longer raise a Lua error each time they're drawn (this client's text has no word-wrap check; a label on more than one line now counts as wrapped).

## 1.14.3
- DaylightUI 1.9.2: its new Custom gradient accent reaches skinned windows. Gradient text runs through every one of its colors, not only the two ends, and an addon's own Accent can pick Custom gradient too.
- Look and Feel > General shows DaylightUI's custom gradient colors with its other accent settings.
- OpenMap 0.8.10 and Dungeon Journal: inside a dungeon, Dungeon Journal's map shows again. OpenMap 0.8.10 leaves dungeons Dungeon Journal knows to it, and the skin used to take Dungeon Journal's map down whenever OpenMap was loaded, so there was no map at all. Outside dungeons OpenMap's map stays the one you see.

## 1.14.2
- Kerzo Classic Quest Log: the ∞ mark Kerzo Quest Expansion puts before WoW Forever quests showed as an empty box in DaylightUI's font (and 16 other fonts without that letter). It now gets a font that has it, at the same size.
- Polestar: a note on its card and Window settings: the DaylightUI look goes on Polestar's own "Polestar" skin only; its other looks (Vellum, Beacon and the rest) are yours to use and stay as Polestar draws them.

## 1.14.1
- Polestar: its auto accept and auto turn in of the guide's quests join the DaylightUI overlaps too, the same as Journey Guides' (asked once, DaylightUI picked; switch either back on its page).

## 1.14.0
- Checked against today's addon updates, including the addons you may not have installed.
- Forever Leveling BiS 1.3.2: its windows have the DaylightUI look again (1.3.2 changed its window color, so they weren't found). My gear on DaylightUI's character window and the new Wish list dock are dressed too.
- Polestar 0.4.0: its new skins (Vellum, Beacon, Aurora and the rest) are left as Polestar draws them; only its house look takes the DaylightUI look. The new settings search list is dressed, and the house look's new edge lines no longer show around the shell.
- Polestar: its sell junk, repair, faster looting, single-option gossip, hide errors and open-the-flight-map switches join the DaylightUI overlaps (asked once, DaylightUI picked; switch any back on its page).
- OneForAll 6.2.10: its new "Tooltip at the mouse" joins the overlaps (DaylightUI's tooltip has its own mouse anchor). Handing over its quest loot sparkles no longer asks you to restart the game. Its nearby-alert target button is dressed.
- Shortest Path Forever 1.41: the Journey stops, Farming tour and Forever profile windows, the right-click menu, the nearby services list, the tracker's scroll bars and the "Journey" button under the minimap are dressed. ForeverCore's quest list joins the overlaps. Its column background is set clear while docked (given back when undocked). Fixed a check for the retired Forever Leaderboards window that kept running all session.
- Trueshot Lodge: the 3D model's zoom, turn and reset buttons are dressed, and stat values keep your text look when the list refills.
- Forever Fishing: the Session Tracker, bug report window and scan diagnostics card are dressed.
- Dungeon Journal 2.0.9: the "Show all dungeons anyway" button is dressed, and the summon warning on Gahz'rilla's quest stays red.
- LFG Forever 2.1.0: its tabs keep their wider room around the names, and opening it with its new Search key dresses it at once.
- Does It Die: its tabs, sliders, dropdown list and titles are dressed.
- Dialogue UI: its settings dropdown is dark like the rest of the window, and red gossip options are readable.
- Journey Guides: your custom link colors now reach every step's text, and the Hardcore progress bar stays red. Its guide-quest auto accept and turn in joins the overlaps.
- Spoken: the Places panel beside the world map and its side tab, the Small Window menu, and the Listen, Contribute and book Play buttons are dressed.
- DaylightUI 1.9.1: tooltips dressed here for Questie and RareScanner follow its new "Separate tooltip background opacity" switch.

## 1.13.0
- New: tells you when a newer version is out. Your copy and those of players in your guild and group trade version numbers in the background, and one chat line says when there is a newer one to get through CurseForge or WowUp (once a session). Turn it off with "Tell me when a newer version is out" on the plugin's first options page; then nothing is sent either.
- New layout for the switches: the All windows page now has two grids of switches, Addons and Blizzard, sorted A to Z. Each grid has Turn all on, Turn all off and Reload interface buttons, and fits as many columns as the window allows without cutting off a name.
- Addons you don't have show "Get Addon" in your accent beside their name. Click it to open a box with the addon's CurseForge link to copy.
- Blizzard: the single "Game windows" switch is now one switch per window (Bags, Character Frame, Chat Settings, Guild Bank, Mail Frame, World Map and the rest), along with the Game Settings and Dungeon Ready switches. If you had Game windows turned off, every window's switch starts off. Each switch takes effect after a reload.
- New Look and Feel page in place of one page per addon, laid out in tabs: General (the "Use DaylightUI's settings for all windows" switch and the list of addons and game windows to pick from), Text (font, text colors, accent), Window (background, border), Controls and Extras (an addon's own options and its DaylightUI or addon switches). Only the open tab's settings are drawn, so picking an addon doesn't move anything on the page, and the other tabs show the picked one's settings. A tab the picked addon has nothing for isn't shown. The left-hand list now has just two pages, All windows and Look and Feel. Every setting you had is kept.
- Look and Feel: under each tab's settings, "Applies to" lists the addons that tab reaches, each with its Custom Settings switch. Click a name to show that addon's settings above.
- Look and Feel, General tab: DaylightUI's own look is right there to change: its font, text outline and shadow, accent (with the custom color and gradient borders), window background opacity and color, and border thickness and opacity. They are DaylightUI's own settings (General > Appearance), so a change here changes them there too. "Reset page" on Look and Feel leaves them alone. The addon list moved off the General tab: pick an addon from "Applies to" on any other tab.
- Renamed: "Use my own settings for [addon]" is now "Custom Settings for [addon]", and likewise Custom background opacity, Custom border size and Custom link colors (Journey Guides).
- The font choice "The addon's own font" is now "Addon's font", and the accent choice "DaylightUI's accent" is now "DaylightUI accent", so neither is cut off in its box.

## 1.12.5
- Game windows: the profession window's title now stops short of whatever sits beside its X, measured each time the window opens: DaylightUI 1.8.4's "Daylight UI window" link, Daylight Recipes' swap button, or both. A long profession name no longer runs under them.
- DaylightUI 1.8.4's Background color (General > Appearance: Daylight, class tint or custom) now reaches the grounds drawn here: Mastercraft's window darks and OpenMap's quest log, side panel and hint grounds. They change as soon as you pick a new color. Windows on DaylightUI's shell already followed it.

## 1.12.4
- DaylightUI 1.8.4: when you pick the game's own window over DaylightUI's, DaylightUI now dresses it itself. Game windows now leave those windows to it, so they aren't dressed twice: gossip, quests, the vendor and the trainer (while DaylightUI's NPC window skins are on), the mailbox, letters and the social window (Social), and the character window and the spellbook and talents (System). The trainer's filter reset badge and the talent loadout dialogs are still added here. With an older DaylightUI, or that skin pack off, nothing changes.

## 1.12.3
- Translations tidied: lines for text the plugin no longer shows are taken out of all six languages.

## 1.12.2
- Game windows: the new-player tutorial banners, key prompts, keyboard and mouse intro, and pointer boxes use the DaylightUI look, their arrows and glow in your accent.
- Game windows: the battleground and status bars at the top of the screen and under the minimap get DaylightUI bar edges; their fills, faction icons and colors stay.
- Game windows: the external defensives buffs, the subscription offer window, the buttons and text of the voice chat toasts, the GM chat window, the behavior notices and their details window, and the auction house posting bar (without DaylightMogul) are dressed.
- Game windows: the game's own damage meter windows get the DaylightUI window look while DaylightUI's meter is off.
- Game windows: the world map's coordinates use DaylightUI's font, a size smaller where the row would cut them off.
- Translations: the new accent and gradient border settings in German, French, Spanish, Russian, Korean and Simplified Chinese.
- LayerSwap: the panel's two-line status no longer loses its second line in a larger font or text size: it steps down a size until both lines fit.

## 1.12.1
- Its own icon: in the game's AddOns list and other menus (instead of the blank "?"), and on its page in DaylightUI's options.

## 1.12.0
- New: Mastercraft. Its style is kept on Classic (the flat one) while the skin is on, so it takes the DaylightUI look from the moment it loads; the style you had comes back when the skin is off (a style you pick in Mastercraft meanwhile is the one that comes back, and the chat says so). Each character keeps its own choice, following its DaylightUI profile. Its main window, compact view, item tracker, farming HUD, fishing bar and catch card, mini guide, alt view, recipe details, Trade board, Map icons, What's New, setup guide, question box, toasts, request pop-up, mailbox helper and bank pop-up get the DaylightUI window shell and close button, with the accent line along the top. The fishing bar's secure buttons are never touched; its shell goes on outside combat.
- Mastercraft's colors become DaylightUI's as it paints them, through every hover, pick, scroll and refresh: its blue-gray panels and edges as DaylightUI's neutral darks, its words in DaylightUI's inks, its faction red or blue as your accent (gradients included: primary buttons, lighter under the mouse; picked tabs, rows and chips; switches, sliders, bars and marks), its gold highlights in your accent. Quality, class, good, warning and bad colors stay, and every word is in DaylightUI's font, its sub-tabs laid out again for it and labels shrunk to fit their buttons.
- Mastercraft's buttons in the game's windows (the Mastercraft and Share my crafts buttons in the profession window, Scan prices at the auction house) as DaylightUI's buttons and tab; its recipe card and the world map's Nodes button in DaylightUI's colors and font.
- Mastercraft and DaylightUI: selling junk, repairing, the item counts in item tooltips and double right-click fishing go to DaylightUI by default when both do them (in the first-load choices; switch any back on Mastercraft's page).
- Words in an alphabet DaylightUI's font doesn't have (a language menu's Ελληνικά or 한국어, Russian where the font lacks it, Arabic, Hebrew, Thai, Chinese, Japanese) keep the font they came with in every skinned window and the game's Settings window, instead of turning into empty boxes; their size and colors still follow the look.
- Gradients: with "Use DaylightUI's settings" on, skinned windows now keep your DaylightUI accent as it is, a Daylight gradient or class gradient included: slider fills, picked and hovered rows, accent lines and edges, picked tabs and boxes run along the gradient instead of showing one flat color. Window borders already followed DaylightUI's "Gradient window borders".
- An addon's own page picks its accent from the same choices as DaylightUI: DaylightUI's accent, Daylight gradient, Class color, Class gradient or Custom color (a custom accent you set before is kept). Pages with a window border also get "Gradient window borders" of their own.
- Shortest Path Forever: quest tracker headings and their underline follow DaylightUI's tracker gradients (class gradient or a gradient accent) instead of one flat color.
- DaylightUI 1.8.3: its own New Recipe Learned toast is left to it (no second box drawn over it) while its System window skins are on. The override window's Apply button has DaylightUI's main-button look and sits in the left corner, like DaylightUI's own Accept buttons.
- LayerSwap 1.14.25: the Host button shows when hosting is paused (grayed like DaylightUI's off buttons, still clickable), and its lock timer, the other buttons' labels and the options page's one-line notes shrink to fit instead of being cut off.
- Game windows: the game's profession window, for when DaylightUI's own isn't the one in use (Daylight Recipes' "The game's window", or DaylightUI's profession window off). The window on the DaylightUI shell with DaylightUI's close button, the title clear of it and of Daylight Recipes' swap button; the profession tabs down its side as clean icon tiles, the picked one in your accent; the recipe list and recipe form as quiet wells, the list's rows as plain lines with the picked recipe in your accent and its categories with a chevron, the skill bar as a DaylightUI bar in your accent; the search box, filter (its reset badge too), scroll bars, checkboxes, count box and the Create and Create All buttons (wide enough for their words) in the DaylightUI look; reagent, output, tool and gear slots with quality edges; the reagent picker, the guild's crafters list, a recipe link's window and the professions book (K) dressed the same. Skill-up colors (orange, yellow, green, gray), quality colors, icons and the red unlearn X stay the game's.
- OpenMap: the game's map pin button (top left of the map) places a pin again. OpenMap's own map took every click before the game could drop the pin, so the click zoomed instead; while OpenMap's map shows, the button now turns on OpenMap's pin mode and the next click drops a pin, as Ctrl-click does.

- Mastercraft 2.0.1: the Crafters page's chips, tabs and new tick boxes take DaylightUI's darks instead of brown plates; picked chips get a faint accent ground and the accent rim; the watched-recipe eye and ticks are in the accent.
- Mastercraft: the Crafters hub, lists, a crafter's page and Requests are dressed as they open from tiles and updates too, and their chips and buttons fit DaylightUI's font.
- Mastercraft: the mailbox helper's header band and rule, and the compact view's row hover, are in DaylightUI's neutral colors.
- Mastercraft: the question pop-up (now also "Notify me" and the new-version notice) is recognized at once and dressed again when it updates while open.
- Dungeon Journal 2.0.8: RPG Mode's "I already did this dungeon" box, the item set row (the piece you clicked framed in the accent), the Loot Filter's "no items match" panel and the update notice are skinned; the box's buttons are no longer cut short in DaylightUI's font.
- Kerzo Classic Quest Log: the band between the quest list and the details in the stacked layout is a faint line instead of a gray strip. The expansion tint Kerzo 6.4.1 now draws on the Dark theme is kept.
- OpenMap: Dungeon Journal's map markers no longer show over OpenMap's dungeon map when they're placed from the journal's own Show on Map buttons.
- Collections: the side tabs now match DaylightUI's icon tabs, with the picked tab in your accent. The mount, pet, toy, heirloom and appearance filters show a small accent X instead of the red "filters changed" badge.
- Calendar: the holiday, raid reset, event, create event, mass invite, event picker and icon picker panels are DaylightUI windows now, with no gold header plate. The filter's badge and the description boxes are dressed too.
- Click casting (Options > Keybindings > Click Casting): fully dressed: the binding list (a new, unsaved binding in your accent), delete buttons, Save, Add Binding and Reset, the mouseover-cast switch and key dropdown, the spellbook and macro buttons, and the tutorial.
- Cooldown manager settings: the side tabs, the layout and settings dropdowns and the category headers are dressed, without touching Edit Mode.
- Communities: the edit-channel, notification settings and guild recruitment dialogs lose their old dialog borders.
- Guild bank: the tabs down the side are DaylightUI icon tabs, the picked one in your accent.
- Confirm boxes: the gold, silver and copper boxes, coin amounts, item line, dropdown, close button and small gold text match the rest of the box.
- World map: the pin button loses its gold ring, its dark round ground sits centered on the icon, and its "on" glow is in your accent.
- Auction house (without DaylightMogul): the filter's badge and the buy dialog's border are dressed.
- Fix: the leader's role check pop-up was dressed twice (by DaylightUI and here); it's DaylightUI's now.
- Game windows: the game's character window (equipment, Reputation, Skills, Honor, Currency, Statistics) gets the DaylightUI look whenever it shows: with DaylightUI's character window off, or when "Transfer to another character" hands you the game's window. Side tabs as tiles, lists as rows with headers, the picked entry in your accent, detail panes, checkboxes as switches, dropdowns, buttons and items.
- Game windows: the currency transfer window (source dropdown, amount box, Max, Confirm, Cancel) and the transfer log are dressed.
- Game windows: the game's spellbook and talents also dress the loadout dropdown, the reset and undo buttons, Activate, the search suggestions, spell names and page headers, and the create, edit and import loadout dialogs.
- Game windows: the game's own gossip, quest, vendor, trainer and mailbox windows are in the DaylightUI look when DaylightUI's NPC window, vendor page, trainer window or mailbox is switched off. Quest text, rewards and letters are lit for the dark window, and the reward you pick shows in your accent.
- Game windows: the game's social window (with DaylightUI's Social window off), its older friends window, the raid info window, the bags and the bank, its page tabs included (with DaylightUI's Bags off), and the quest tracker's headers and collapse buttons (when DaylightUI's tracker isn't in use) are dressed too.
- The trainer's filter reset badge is a small accent X when DaylightUI lends the game's trainer window for Beast Training.
- New: High Fidelity World Map. Its HD/SD button on the world map is a DaylightUI button, its "blend" dot in your accent; the blend slider it opens on a right click is on the DaylightUI shell with DaylightUI's slider and a quiet pin.
- High Fidelity World Map's cave map window gets the DaylightUI window shell instead of the game-menu border and header: the area name in the value ink, DaylightUI's close button, a background that still follows its Cave map opacity, the depth slider and height window in the scroll bar look (the grips' glow in your accent), and the floor dropdown in DaylightUI's box. The "Open cave map" button is a DaylightUI control with its map icon. Long area names and floor names shrink to fit instead of being cut off, and the window's drag strip no longer covers the map above it.
- High Fidelity World Map's settings pages: Reset to Defaults and Open preview are DaylightUI's buttons, and each section's reset arrows are in the text ink.
- High Fidelity World Map and DaylightUI: zone maps without Fog of War (on the Hybrid background, showing unexplored areas) go to DaylightUI's map reveal by default when both are on (in the first-load choices; switch it back on its page's DaylightUI tab). An open map is redrawn at once.
- Addon options (Ace3): the hooks this plugin puts on AceGUI are no longer added again with every addon that loads.
- Game windows: the profession window's crafting count box loses the game's border pieces too (it carries two sets).
## 1.11.0
- On German, French, Spanish, Russian, Korean and Chinese clients, words the game already translates (like Always, None, Off and Apply) use the game's own translation instead of our draft.
- New: Guildy. Its guild window on the DaylightUI shell with DaylightUI's close button, the title beside the guild emblem (the tabard stays) and the version note after it; its bottom tabs as DaylightUI tabs on a panel under the window, each wide enough for its whole name, the picked one in your accent; the guild and communities side tabs as clean icon tiles (the emblem and the "something new" dot kept), also the one it puts on the game's guild window to come back to Guildy.
- Every page's dark boxes lose their gold edge for DaylightUI's quiet panels; its buttons, menu buttons, search and text boxes, checkboxes (as switches), scroll bars, the chat's timeline rail, the size slider and progress bar in the DaylightUI look, buttons sized again for DaylightUI's font so no word is cut short. Choices like the Bank's kinds light the picked one in your accent instead of graying it out. Buttons that hand their click to the game's own (invite, notes, message of the day, rank, removal) light up under the mouse like the rest.
- Lists: the gold hover and picked bands become DaylightUI's soft hover and your accent, rules and section lines faint, each row dressed as the list fills or scrolls it. Customizing a tab (Customize): the box strips, free places, the add-below bar, the drag markers and the column handles in your accent instead of gold.
- All of its text in DaylightUI's font (its serif headings too) and colors, kept through every refresh. Class colors, online green, red for removal, the activity score's colors, charts, portraits, models and icons stay its own.
- Its menus, the member card and activity score panel, the item tooltips, the remove and copy boxes, the invite suggestions, its Options window (tabs, switches, the style cards with the picked one in your accent) and the level-60 banner (its lines and seal in your accent) in the DaylightUI look.
- The game's guild window Guildy keeps hidden under its own stays hidden: its chat no longer shows below Guildy's window when DaylightUI fades windows in. Guildy's tabs keep DaylightUI's font under the mouse.
- Guildy's guild actions run through the game's own buttons; the skin leaves those, and the game's frames Guildy shows with it (the member panel, the text editor, the rank editor, the invite popup), to the game and DaylightUI.

## 1.10.1
- Addon Skins' own text (its options, the Override window) in German, French, Spanish, Russian, Korean and Simplified Chinese (machine drafts, corrections welcome).
- Fixes for non-English game clients: on Korean and Chinese clients, and on Russian ones with a font that has no Russian letters, words in skinned windows no longer turn into boxes or go blank. Text there keeps the game's font (its size, outline and colors still follow the look) unless DaylightUI's "Use my language's font" is on. Russian clients now get DaylightUI's font in Kerzo Classic Quest Log and Dungeon Journal when it has Russian letters (Expressway does).
- The game's language menus (Settings > Languages, Text and Audio; the Communities finder's language) show the language names again instead of blank bars (DaylightUI's menu skin painted their pictures over as hover bars).
- Shortest Path Forever: headings with letters outside A to Z (such as "über") are no longer half in capitals.

## 1.10.0
- New: skins for Kerzo Classic Quest Log (its theme kept on Dark while skinned, given back when the skin is off), Kerzo Quest Expansion and LFG Forever (1.5.0's Player ratings tab included).
- Every text in a skinned window is in DaylightUI's font from the first open, and stays in it: a refresh, a reused list row or a hover that puts the addon's own font back is followed. Kerzo (its "Default" font; one you pick in its settings stays), Questie's settings, Dungeon Journal, OpenMap's panels, LFG Forever, OneForAll and Shortest Path Forever now use it; tabs and buttons sized for the game's narrower font are measured again, so nothing is cut short. Game windows' labels, the combat log's tabs, tutorials and the Settings window's addon pages too; a label too long for the space shrinks a pixel or two instead of going back to the game's font. Item counts keep the game's number font.
- Buttons keep DaylightUI's font after the mouse has been over them (the game menu's Options and Exit Game showed the game's large serif).
- Alert toasts (a recipe learned, an achievement, a dungeon done, a new pet or mount...) are in DaylightUI's look every time, not only the first: their art is masked for good, and a recipe's toast shows the square icon of what it makes.
- The game's settings dropdowns are DaylightUI's; RareScanner's Loot, Map and Chat option trees are no longer gold; Kerzo's options no longer overlap their footer in the game's AddOn Options.
- Windows are dressed in the very frame they open (hooked where each addon builds or opens them), so there's no flash of the old look.

## 1.9.0
- The game's pop-up menus (right-click menus, dropdowns, the world map's Show: filters, every addon's) lose their last gold: headings in DaylightUI's label color, ticks and radio dots in your accent, submenu arrows light gray.
- Every addon's AceConfig settings (RareScanner's, and any other's): the side menu's items in DaylightUI's colors instead of gold, the picked and hovered one bright; the profile page's "Current Profile" name no longer gold.
- Questie: its pages in the game's Options window (Esc > Options > AddOns > Questie) get the same look as its own settings window.
- OpenMap: its What's new window dressed throughout (the count box and version list as quiet wells, the picked version in your accent, DaylightUI buttons and link box; its parchment notes page stays), and its windows have a solid ground so the map no longer shows through.
- New: the game's own windows that DaylightUI's Window Skins leave bare, under "Game windows", checked against this client's own interface code: the ready check, role check and every queue, invite and PvP popup; the color picker (its wheel and swatches stay the game's); the "Return to graveyard" button and death recap; the stopwatch and Quick Keybind; chat settings, the chat tabs' picked state and the channels window; the zone map (Shift-M) border, tab and opacity panel; alert toasts (icons, quality edges and achievement points kept; loot and money toasts stay DaylightUI's); the old-style dropdown lists many addons still use; add friend, friends of friends, community settings and invites, guild rename and invite, guild ranks; help, report a player, the quest details popup and quest timers, group loot history and master loot, the money split box, the macro, guild bank and equipment set icon pickers, the PvP scoreboard, help tips and tutorials, name autocomplete and the queue status panel.
- New: the game's Options window (Esc > Options) and the dungeon-ready dialog, each with its own switch ("Game settings window", "Dungeon ready dialog"): the window, its tabs, the category list with the picked one in your accent, and every setting (checkboxes, sliders, dropdowns, buttons, key bindings, headings). Pages addons draw themselves inside it stay as their addon draws them. Built to stay out of the game's protected code; if a blocked-action error ever names Addon Skins there, turn its switch off and reload.
- Icon tabs as clean tiles, the same in every window that uses them: TrueshotLodge's side tabs, Questie's settings tabs and OpenMap's tabs on the map's edge. Each icon cropped and centered in an even margin on DaylightUI's tab look, the picked one edged in your accent, the others a little dimmed until the mouse is on them.
- New: TrueshotLodge. Its window on the DaylightUI shell with DaylightUI's close button, the title clear of the logo; its side tabs as DaylightUI icon tabs, the picked one in your accent; the gear and "?" lit in your accent while Options or Help shows; the Level, Zone, Pet and Faction filters as DaylightUI buttons with an accent line while on; its panes as quiet wells; its lists as plain lines with the picked row and headings in your accent; the search box, scroll bars, switches, UI Scale slider and buttons in the DaylightUI look; the Stable tab's slots and experience bar in DaylightUI edges. Its logo, 3D models, icons, maps, pins and the colors that mean something (rank states, factions, rares, NEW badges) stay its own.
- Dungeon Journal, more of it dressed: the Dungeon Tracker (its X, reset button, title, labels and boss loot line), the quest trackers (the copied game frame and plum ground gone), the mode chooser and RPG Mode check, its six right-click menus, its notes and hints (red arrows kept), the page-unlocked toast, the export, import and copy windows, and the "Hide quests" box on its maps. Inside the journal, the bug report window, search results and language list are no longer see-through, and the RPG Mode note's text is readable again.
- Polestar: windows, menus and alerts sit on DaylightUI's dark ground instead of navy (alert, toast and header fades, zone-art fades, the world map's info bar), and picked rows use your accent. Its dropdown lists, minimap menu, party loot list and level-gain panel get DaylightUI's shell; its button in the game menu matches the others; its minimap button loses its round back in DaylightUI's drawer.
- Camping Kit, skinned throughout: its settings window (the picked section in your accent, quiet hairlines, ticks, sliders and dropdowns with DaylightUI's edge and accent, a DaylightUI scroll bar), the announce message editor and the reminder placement bar. The campfire panel's and Kits menu's gold titles take DaylightUI's inks, and a "Looking for" pick's ring is in your accent.
- Questie: its popups' buttons and text box, its right-click menus (a quiet hover, marks in your accent, gray arrows), the settings side tabs' hover and picked outline, its sound buttons, color swatches and rules, the scroll bar of a tab opened for the first time, its minimap waypoint and gamepad tooltips and its debug offer window. Its world map corner button loses the gold ring even without OpenMap or RareScanner.
- OpenMap: with "Buttons as edge tabs" off, the corner button, favorites and fold arrow are dressed; the full-screen map's quest log toggle matches the game's; the draw tray's picked tool is in your accent; search results that appear as you type get the quiet hover.
- Keep or Toss: rows and headers light with DaylightUI's soft hover instead of the blue bar, and the delete-item notice gets DaylightUI's tooltip look. LayerSwap: the "Ask your guild" entry in DaylightUI's inks and accent. LootTriage: the What's New page arrows as DaylightUI page buttons. Forever Leveling BiS: the selector list beside the Character frame is dressed from the first click. BugSack: the title line follows font and color changes without a reload.

## 1.8.0
- New: BugSack. Its window on the DaylightUI shell with DaylightUI's close button; the title row's error date, sender and session in your font from the window's edge (the portrait is gone), the count bright, the filter box (double-click the title) as a DaylightUI box; the error text in your font at the size picked on its Options page, its scroll bar DaylightUI's; Previous, Send bugs, Next and Wipe saved bugs as DaylightUI buttons, grayed while they can't be used; its four tabs on a DaylightUI panel under the window, each wide enough for its whole name, with the picked one in your accent; and its Options page with DaylightUI's switches and dropdowns, its gold labels in DaylightUI's colors. Its red and green parts of the title, the error text's own colors and the sound preview icon stay its own. Its minimap button, the Send bugs popup, tooltips and menus already wear DaylightUI's look.

## 1.7.0
- New: LayerSwap. A "Layer: B" button in the bottom-left corner of DaylightUI's minimap, made like DaylightUI's own corner buttons: left-click opens LayerSwap's panel, right-click its layer menu, shift + right-click its settings. Shown all the time, only with the mouse over the map, or off (its page, Minimap tab); it sits above the queue eye when that shows. Its panel, layer menu and settings menu on the DaylightUI shell with DaylightUI's close button and buttons, your font and DaylightUI's text inks (its Swap button keeps them through every refresh), its mini bar with a thin DaylightUI edge, and its options page with DaylightUI's switches, buttons and sliders. Its logo and its green, gray and orange status words stay its own.
- Lighter: the LayerSwap minimap button no longer runs every frame (it checks the mouse as it moves onto or off the map, and its layer once a second only while shown), and its width is only set when it changes. Its dropdown's choices are short enough to show in full (Always, On hover, Off).
- OneForAll: DaylightUI 1.7.3 removed its object glow, so "Herb and ore sparkle" is no longer offered to DaylightUI. If you gave it to DaylightUI before, OneForAll's own sparkle is switched back on for you.

## 1.6.2
- New: RareScanner. Its rare alert as a flat DaylightUI panel (the name bright, "click to target" as a label, the edge lit under the mouse, DaylightUI's close button, the navigation arrows in gray, the loot icons in a thin edge); its map pin and chat link tooltips in DaylightUI's tooltip look with plain hairlines for its gold separators; its search box moved off the map into the world map's top bar, beside the filter button, as a slim DaylightUI box that suggests the rares on the map as you type, keeps your search when you click back into it, and clears with its little X; its map button without the gold ring; its route progress bar and its popups. The explorer on the DaylightUI shell: its panels as quiet wells with the stone frames and parchment gone, its filters, dropdowns, switches, red buttons, search and text boxes and scroll bars DaylightUI's, its lists as plain lines with the picked rare and picked group in your accent, every loot icon in a thin edge, the custom loot editor (its empty-group text readable again) and the scan page. Also its target marker picker, About page, NPC import window and telemetry export window. Its 3D model, item icons and quality colors, portraits, map pins and routes, and the explorer's map stay its own.
- Lighter on play: the menu font fix makes no garbage while a menu is open and only touches a text that lost its font, Shortest Path Forever's docked sections compare positions instead of building a string four times a second, and the world map's corner buttons are looked over once per map change however many skins want them. OpenMap's hidden dungeon view is no longer dressed again on every map open, its coordinate readouts no longer run the recoloring on every update, and its dressing skips what's already done. Colors are read once per style change instead of on every paint, across every skin. RareScanner's skin waits for its own window before reacting to the game's menus, and its suggestions sort without rework on each key press.
- OpenMap, skinned throughout: the dungeon map view (its bar with the floor arrows and the way back, the floor list, the side panel with its tabs, rows, buttons and the floors' pictures in a thin edge, the picked one in your accent), the tabs on the map's edge as clean icons with no frame (the lit one outlined in your accent), the coordinate labels, the menu's tiles, switches, sliders and scroll bar, and every dialog's buttons, boxes and scroll bars. Its gold and bronze become DaylightUI's colors wherever it sets them, also as it refreshes; the quest log paper and frame round the dungeon panel are gone. The map, the dungeon's picture and the icons on them stay its own.
- Dungeon Journal: the Boss icons size control on its dungeon maps in the DaylightUI look.
- With OpenMap loaded, Dungeon Journal's own dungeon map on the world map steps aside in dungeons, so it no longer pokes through OpenMap's dungeon view (its floor buttons, red World Map toggle and boss icon size). Its setting is untouched: without OpenMap it works as before.
- OpenMap: the dungeon side panel has a solid ground again, so the world map's quest log no longer shows through it, and its gold quest-log frame and filigree are gone.
- OpenMap's dungeon view: Dungeon Journal's markers on the world map and the game's own corner controls over the view (the map pin button, the floor dropdown) are out of sight and let clicks through while it's open, and come back when you return to the world map. The quest log toggle stays.
- World map, with OpenMap or RareScanner loaded: the round corner buttons DaylightUI's map skin leaves in the game's gold ring (the map pin button, the quest "!", RareScanner's button) lose the ring; just their icons show, with the dark round ground behind each icon centered on it.
- OpenMap: the dungeon side panel's title row has a solid ground too.

## 1.6.1
- Dungeon Journal: the Character Logs window and the Loot Filter popup take the DaylightUI look the moment they first open, instead of a couple of seconds later.

## 1.6.0
- Fix: the game's pop-up menus (the quest map's and world map's Show: filters, right-click menus) keep DaylightUI's font when you tick an option, instead of the text switching to the game's wider font until the menu is reopened.
- New: Dungeon Journal, beside DaylightUI's own skin of it. Its Character Logs window now has the DaylightUI shell (it was left in the game's portrait frame): the run list with the picked run in your accent, flat stat tiles and loot cards (loot keeps its quality edge), headings and lines in DaylightUI's colors, its buttons, scroll bars and party list. Each dungeon's faint picture stays.
- Dungeon Journal: the Loot Filter popup and its Armor, Weapon, Resistances and school menus get a window background again, so the home page no longer shows through them.
- New: Total RP 3, skinned throughout. Its main window, toolbar, target frame, glance bar, "Currently" and NPC speech frames, icon, color, image, music, pet, companion and background browsers, profile and import dialogs and link copy dialog on the DaylightUI shell; its parchment, wooden borders and slice art gone; its sidebar as plain rows with the picked page in your accent; panels and group boxes as quiet wells (a background you picked for your About page is kept); lists as plain lines with a hairline between rows (no doubled borders); tabs with the picked one underlined in your accent; buttons, switches, edit boxes, dropdowns and scroll bars in the DaylightUI look; sliders as a thin track with your accent fill and a round knob, their arrows gray; color pickers in a thin edge; help icons, divider lines, list headers, glance slot rings, progress and personality bars, reorder and collapse arrows and browser picks in DaylightUI's colors; its icon buttons square in a thin outline; its text in your font and DaylightUI's colors. Its own tooltips (character and companion cards, chat links, toasts) get DaylightUI's flat tooltip look. Hover washes no longer stay behind on its sidebar and lists after a click.
- DaylightUI Override for Total RP 3: its RP card hiding the game's unit tooltip (DaylightUI's tooltip stays and the RP card shows beside it) and its own name colors in chat (DaylightUI's class colors).

## 1.5.0
- New: OneForAll. Its main window and every popup on the DaylightUI shell; its gold in DaylightUI's colors (strong gold as your accent, pale gold text light, its brown grounds neutral dark) and its gold button plates gray, picked ones in your accent. Its banner, switches and scroll bars stay its own.
- New: Questie, beside DaylightUI's own Questie support. Its settings window (shell, side tabs, every switch, radio, slider, dropdown and button, its group boxes and text in DaylightUI's colors), its right-click menus, its popups and tutorial, and its own tracker when you use Questie's tracker (the shell follows its backdrop switch, opacity and fader).
- New: Dialogue UI, a DaylightUI theme over either of its own. Its talk window and settings window on the DaylightUI shell; its text in DaylightUI's colors, accent and your font (a font you picked in Dialogue UI is kept); option rows, hotkeys, rewards and settings controls in its Dark art, so its Brown theme no longer shows paper behind light text. Its text colors and accent can be set on its own page.
- New: Shortest Path Forever. Its Nearby services panel in the quest log, ForeverCore's report, issue, leaderboards and thanks windows, and its right-click menu.
- Shortest Path Forever: the Forever sections (its lifts, boats and journey steps, and any other Forever addon's tracker sections) sit right under DaylightUI's quest tracker, follow it as it grows, moves and fades, and take its look: heads like its Quests header, names like quest titles, lines like objectives, from your Quests settings. A switch on its page puts them back where ForeverCore places them.
- OpenMap: the quill's "Draw on the map" tray is shrunk to fit DaylightUI's narrower world map instead of running past both sides.
- OneForAll: a "Hide OneForAll's world map button" switch on its page (put back when turned off).
- Shortest Path Forever no longer brings the game's waypoint icon, and its own pin, back under DaylightUI's in-world marker.
- New: DaylightUI Override. What OneForAll, Questie, Shortest Path Forever and Dialogue UI do that DaylightUI already does (OneForAll's chat hide button that hid DaylightUI's chat, its copy buttons, arrow-key history, minimap button collector, map pins, flight timer, loot feed, camera zoom, window moving and more; Questie's nameplate icons, tooltip lines, sound and auto quests; Shortest Path's map pins, destination pin and arrow; Dialogue UI's auto turn-in, book window and reward tooltip) is DaylightUI's: a window on first load lists each, DaylightUI picked, and you choose. Each addon's DaylightUI tab has a switch per feature and "Give everything back"; "Show the choices again" is on the All windows page.
- Lighter on play: the docked Forever sections only do work when the tracker moves, grows or fades; OneForAll's recoloring only runs after a click in its own window; settings are read once and kept until they change.

## 1.4.0
- Journey Guides: "DaylightUI buttons" for step buttons no longer leaves them as bare text.
- Journey Guides: the old glue-tooltip backdrop is now fully cleared under the DaylightUI shell.
- Journey Guides: link colors follow Journey's current color table, and its own colors are read at login.
- Journey Guides: secure buttons are left alone outside of the item buttons, which are dressed out of combat only.
- Journey Guides: flat step buttons keep their white text, menu rows without a check mark no longer error, and settings changes repaint once per frame.
- A window's border, opacity and bevel go back to DaylightUI's when you turn its own settings off.
- Windows that never open are looked for less often after the first minute.

## 1.3.1
- Every addon page has its own "Use my own settings" switch, so one addon can have its own look without turning off DaylightUI's settings for all windows.

## 1.3.0
- New: Journey Guides. Guide window, step boxes, step buttons, item buttons, menus, Advanced Options, popup, tooltip and HUD arrow, with a Guide tab of its own settings (logo, progress bar, step button style, link colors and more).
- Addon pages can now carry settings of their own.

## 1.2.0
- New: Forever Leveling BiS (its Modern theme): window shells and the DaylightUI font.

## 1.1.0
- Keep or Toss, DoesItDie, Camping Kit, LootTriage, OpenMap, Spoken, Forever Fishing and Polestar.
