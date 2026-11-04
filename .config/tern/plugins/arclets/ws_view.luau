--!nonstrict
-- Pure render of the Workspaces section: model (from ws.luau) -> Tern-native nodes. Each
-- session is a card with its tabs. Node keys carry the ids menus act on: ".w<session>",
-- ".t<tab>". Colors: working yellow (warning), blocked (waiting for you, or failed) red
-- (error), finished while you were away green (success).
local ui = tern.ui
local V = {}

local M = {
	newSession = "New Session…", expandAll = "Expand All", collapseAll = "Collapse All", filter = "Filter…",
	switch = "Switch to Session", newTab = "New Tab", rename = "Rename…",
	up = "Move Up", down = "Move Down", top = "Move to Top", move = "Move…",
	lock = "Lock Session", unlock = "Unlock Session", copyPath = "Copy Path", finder = "Reveal in Finder",
	collapseOthers = "Collapse Others", close = "Close",
	goTab = "Go to Tab", newPaneRight = "New Pane Right", newPaneDown = "New Pane Down",
	even = "Even Out Panes", toSession = "Move to Session…",
}
V.M = M

local function set(list)
	local s = {}
	for _, x in list do s[x] = true end
	return s
end
V.TAB = set({ M.goTab, M.rename, M.newPaneRight, M.newPaneDown, M.even, M.up, M.down, M.move, M.toSession, M.close })
V.LABELS = {}
for _, label in M do V.LABELS[label] = true end

-- A state's tone: what colors a tab's row and a session card's edge.
local TONE = { waiting = "error", failed = "error", working = "warning", running = "warning", done = "success" }
V.TONE = TONE

local function sessionMenu(ws)
	local menu = {}
	if not ws.current then table.insert(menu, M.switch) end
	for _, x in { M.newTab, M.rename, M.up, M.down, M.top, M.move, if ws.locked then M.unlock else M.lock,
		M.copyPath, M.finder, M.collapseOthers } do table.insert(menu, x) end
	if not ws.locked then table.insert(menu, M.close) end
	return menu
end

local function tabMenu(tab)
	local menu = { M.goTab, M.rename, M.newPaneRight, M.newPaneDown }
	if tab.panes > 1 then table.insert(menu, M.even) end
	for _, x in { M.up, M.down, M.move, M.toSession, M.close } do table.insert(menu, x) end
	return menu
end

-- The state at a tab row's right edge.
local function indicator(state)
	if state == "waiting" then
		return ui.node("icon", { key = "st", name = "bell", tone = "error", title = "Waiting for you" })
	elseif state == "failed" then
		return ui.node("icon", { key = "st", name = "x-circle", tone = "error", title = "Failed while you were away" })
	elseif state == "done" then
		return ui.node("icon", { key = "st", name = "check", tone = "success", title = "Finished while you were away" })
	elseif state == "working" or state == "running" then
		return ui.node("spinner", { key = "st", style = "dots", tone = "warning",
			title = if state == "working" then "Working" else "Running", aria = "Working" })
	end
	return nil
end

local function quick(key, icon, action, title)
	return ui.node("icon", { key = key, name = icon, role = "arc.btn", title = title, aria = title, actions = { click = action } })
end

local function slot(key, label, value, role)
	return ui.node("item", { key = key, label = label, icon = "corner-down-right", tone = "accent",
		role = role, actions = { click = "drop=" .. value } })
end

local function tabRow(ws, tab)
	local detail = nil
	if tab.where and tab.where ~= tab.name then detail = tab.where end
	if tab.panes > 1 then detail = (if detail then detail .. " · " else "") .. tab.panes .. " panes" end
	local children = {
		ui.node("item", {
			key = "i", grow = 1, label = tab.name, detail = detail,
			icon = if tab.git then "branch" else "folder", tone = TONE[tab.state],
			title = tab.where, actions = { click = "tab=" .. ws.id .. ":" .. tab.id, menu = tabMenu(tab) },
		}),
	}
	local ind = indicator(tab.state)
	if ind then table.insert(children, ind) end
	table.insert(children, quick("x", "x", "close=tab:" .. tab.id, "Close tab"))
	table.insert(children, quick("grip", "grip", "pick=tab:" .. tab.id, "Move tab"))
	return ui.node("row", { key = "t" .. tab.id, role = if tab.current then "arc.tabOn" else "arc.tab" }, children)
end

local function pill(key, text, tone, title)
	return ui.node("badge", { key = key, text = text, tone = tone, title = title })
end

local function card(ws, mv)
	local head = {
		ui.node("icon", { key = "fold", name = if ws.open then "chev" else "chev-r", role = "arc.fold",
			title = if ws.open then "Collapse" else "Expand", actions = { click = "fold=ws:" .. ws.id } }),
		ui.node("item", {
			key = "i", grow = 1, label = { ui.span(ws.name, "strong") },
			detail = if ws.host then "@" .. ws.host else (if ws.open then nil else #ws.tabs .. " tabs"),
			title = ws.folder, actions = { click = "ws=" .. ws.id, menu = sessionMenu(ws) },
		}),
	}
	if ws.blocked > 0 then table.insert(head, pill("blocked", ws.blocked .. " blocked", "error", "Waiting for you or failed")) end
	if ws.working > 0 then table.insert(head, pill("working", ws.working .. " working", "warning", "Agents or commands working")) end
	if ws.locked then table.insert(head, ui.node("icon", { key = "lock", name = "lock", tone = "muted", title = "Locked" })) end
	table.insert(head, quick("up", "chev-up", "wsup=" .. ws.id, "Move up"))
	table.insert(head, quick("down", "chev", "wsdown=" .. ws.id, "Move down"))
	table.insert(head, quick("new", "plus", "newtab=" .. ws.id, "New tab"))
	table.insert(head, quick("grip", "grip", "pick=ws:" .. ws.id, "Move session"))

	local children = { ui.node("row", { key = "h", role = "arc.cardHead" }, head) }
	local movingTab = mv and mv.kind == "tab"
	if ws.open then
		local tabs = {}
		for _, tab in ws.tabs do
			if movingTab and mv.ws == ws.id and tab.id ~= mv.id then
				table.insert(tabs, slot("d" .. tab.id, "Move here", "tab:" .. tab.id .. ":" .. ws.id, "arc.slotTab"))
			end
			table.insert(tabs, tabRow(ws, tab))
		end
		if movingTab and mv.ws == ws.id then table.insert(tabs, slot("dend", "Move to the end", "tab:0:" .. ws.id, "arc.slotTab")) end
		if #ws.tabs == 0 then
			table.insert(tabs, ui.node("text", { key = "none", role = "arc.note", spans = { ui.span("No tabs", "muted") } }))
		end
		table.insert(children, ui.node("col", { key = "l", role = "arc.tabs" }, tabs))
	end
	if movingTab and mv.ws ~= ws.id and mv.host == ws.hostId then
		table.insert(children, slot("dinto", "Move into " .. ws.name, "tab:0:" .. ws.id, "arc.slotTab"))
	end
	-- The card's edge takes the worst state of its tabs.
	local tone = if ws.blocked > 0 then "error" elseif ws.working > 0 then "warning" else nil
	return ui.node("col", {
		key = "w" .. ws.id, role = if ws.current then "arc.cardOn" else "arc.card", tone = tone,
		mark = if mv and mv.kind == "ws" and mv.id == ws.id then "pick" else nil,
	}, children)
end

function V.header(model)
	return ui.node("row", { key = "header", role = "arc.header",
		actions = { menu = { M.newSession, M.expandAll, M.collapseAll, M.filter } } }, {
		ui.node("text", { key = "title", text = "WORKSPACES", tone = "muted", grow = 1 }),
		ui.node("icon", { key = "filter", name = "search", tone = if model.filter then "accent" else "muted",
			title = "Filter", aria = "Filter", actions = { click = "filter" } }),
		ui.node("icon", { key = "new", name = "plus", tone = "muted", title = "New session from a folder",
			aria = "New session", actions = { click = "newsession" } }),
	})
end

function V.render(model)
	local nodes = {}
	local mv = model.moving
	if model.filter then
		table.insert(nodes, ui.node("row", { key = "filtering", role = "arc.bar" }, {
			ui.node("text", { key = "what", grow = 1, spans = { ui.span("Filter ", "muted"), ui.span(model.filter, "strong") } }),
			ui.node("item", { key = "clear", label = "Clear", icon = "x", actions = { click = "clearfilter" } }),
		}))
	end
	if mv then
		table.insert(nodes, ui.node("row", { key = "moving", role = "arc.bar" }, {
			ui.node("text", { key = "what", grow = 1, spans = { ui.span("Moving ", "muted"), ui.span(mv.name, "strong"),
				ui.span(" · click a slot", "muted") } }),
			ui.node("item", { key = "cancel", label = "Cancel", icon = "x", actions = { click = "cancelmove" } }),
		}))
	end
	local list = {}
	for _, ws in model.sessions do
		if mv and mv.kind == "ws" and ws.id ~= mv.id then
			table.insert(list, slot("d" .. ws.id, "Move here", "ws:" .. ws.id, "arc.slot"))
		end
		table.insert(list, card(ws, mv))
	end
	if mv and mv.kind == "ws" then table.insert(list, slot("dend", "Move to the end", "ws:0", "arc.slot")) end
	if #model.sessions == 0 then
		table.insert(list, ui.node("text", { key = "none", role = "arc.note", spans = {
			ui.span(if model.filter then "Nothing matches" else "No sessions", "muted") } }))
	end
	table.insert(nodes, ui.node("col", { key = "l", role = "arc.list" }, list))
	return nodes
end

return V
