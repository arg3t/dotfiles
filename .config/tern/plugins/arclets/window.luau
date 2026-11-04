--!nonstrict
-- The sidebar: one canvas pane per tab, opened at the left of the tab's content at the shared
-- width (`cx.canvas:open` with target, dir and ratio), with two sections: Workspaces (ws.luau)
-- and Arclets (arclets.luau). It never moves panes between tabs and never reloads plugins.
local ws = require("./ws")
local wsView = require("./ws_view")
local arclets = require("./arclets")
local AV = require("./arclets_view")

local PLUGIN = tern.plugin.id
local TITLE = "Arclets"
local ABOUT = "Workspaces and Arclets sidebar. Clicks switch sessions, tabs and panes, reorder and move them, and start, stop and set up Arclets as Tern hosts."
local DEFAULT_SHARE = 0.18
local POLL_MS = 5000

local problem = nil
local function report(cx, text)
	problem = tostring(text)
	tern.log.warn(PLUGIN .. ": " .. problem)
	pcall(function() cx:toast("error", tern.plugin.name, if #problem <= 80 then problem else "See Tern's log for details.") end)
end

local share = math.clamp(tonumber(tern.kv.get("panel-share")) or DEFAULT_SHARE, 0.08, 0.5)
local wantPanel = tern.kv.get("panel-open") ~= false
local rendered = {} -- pane -> signature of the view it shows
local leaves = ws.leaves

-- Canvases we opened that `cx.canvas:list()` does not report yet (it lags an open, more over a
-- remote host's relay, and the new pane can be missing from the window's panes and tabs for a
-- moment too): pane -> { at, tab }. Until listed (or 10 s) they count as the sidebar of the tab
-- they opened in, or the next event (the open's own pane_created, a focus) would see no
-- sidebar, treat the new canvas as content, and open another beside it. `openedAt` also keeps
-- a tab from a second open within those 10 s, whatever the lists say.
local pending = {}
local openedAt = {} -- tab -> tern.now() of our last open there
local PENDING_MS = 10000

-- Our canvases: pane set, and tab -> pane (one per tab; duplicates in a tab close). The Kai
-- fork (0.3) titled its canvases "Workspaces"; those close too.
local function ours(cx)
	local set, byTab = {}, {}
	for _, c in cx.canvas:list() do
		if c.owner == PLUGIN and c.title == TITLE then
			pending[c.pane] = nil
			set[c.pane] = true
			local tab = cx.session:tab_of(c.pane)
			if tab and not byTab[tab] then
				byTab[tab] = c.pane
			elseif tab then
				cx.layout:close(c.pane)
				rendered[c.pane] = nil
			end
		elseif c.owner == PLUGIN and c.title == "Workspaces" and cx.session:pane(c.pane) then
			cx.layout:close(c.pane)
		end
	end
	for pane, p in pending do
		if tern.now() - p.at > PENDING_MS then
			pending[pane] = nil
		else
			set[pane] = true
			local tab = cx.session:tab_of(pane) or p.tab
			byTab[tab] = byTab[tab] or pane
		end
	end
	return set, byTab
end

local function shownTab(cx)
	local focused = cx.session:focused()
	return focused and cx.session:tab_of(focused)
end

-- The tab's first content pane in layout order (left-to-right, top-to-bottom).
local function firstContent(cx, tab, own)
	local layout = cx.session:layout(tab)
	for _, p in leaves(layout and layout.root) do
		if not own[p] then return p end
	end
	return nil
end

-- The split whose left side is our pane, and that split's share of the tab's width (the
-- product of the left/right ratios above it). In a split tab the sidebar opens left of the
-- first content pane, so its split may be nested inside the tab's tree.
local function railSplit(tree, pane, frac)
	if not tree or tree.pane then return nil, nil end
	if tree.split == "right" then
		if tree[1] and tree[1].pane == pane then return tree, frac end
		local node, f = railSplit(tree[1], pane, frac * tree.ratio)
		if node then return node, f end
		return railSplit(tree[2], pane, frac * (1 - tree.ratio))
	end
	local node, f = railSplit(tree[1], pane, frac)
	if node then return node, f end
	return railSplit(tree[2], pane, frac)
end

-- Our pane's share of the tab's width, or nil when it is not the left side of a split.
local function railShare(cx, tab, pane)
	local layout = cx.session:layout(tab)
	local node, f = railSplit(layout and layout.root, pane, 1)
	return node and node.ratio * f or nil, f
end

-- Steers the sidebar to `want` of the tab's width: resize, measure, correct (at most 6 steps;
-- Tern resizes in cells, so the cells per share are learned from the first step).
local function sizeTo(cx, tab, pane, want)
	local r = railShare(cx, tab, pane)
	if not r then return end
	local step = math.floor((want - r) * 200 + 0.5)
	for _ = 1, 6 do
		if math.abs(r - want) < 0.006 or step == 0 then return end
		if not cx.layout:resize(pane, "right", step) then return end
		local after = railShare(cx, tab, pane)
		if not after or after == r then return end
		step = math.floor((want - after) * step / (after - r) + 0.5)
		r = after
	end
end

-- Gives the shown tab its sidebar at the shared width; remembers a width you dragged; closes a
-- sidebar left alone in its tab.
local lastShare = {} -- tab -> the share we last saw, to notice a drag
local function follow(cx)
	local own, byTab = ours(cx)
	for tab, pane in byTab do
		if not firstContent(cx, tab, own) then
			cx.layout:close(pane)
			rendered[pane], lastShare[tab] = nil, nil
		end
	end
	if not wantPanel then return end
	local tab = shownTab(cx)
	if not tab then return end
	-- The sidebar takes no keys, so it never keeps the focus (a closed neighbour can hand it over).
	if own[cx.session:focused() or -1] then
		local content = firstContent(cx, tab, own)
		if content then cx.layout:focus(content) end
	end
	local pane = byTab[tab]
	if pane then
		local r = railShare(cx, tab, pane)
		if r and lastShare[tab] == nil then
			-- A just-opened sidebar: `ratio` only sizes it within its own split, so set its width.
			if math.abs(r - share) > 0.01 then sizeTo(cx, tab, pane, share) end
			r = railShare(cx, tab, pane)
		elseif r and math.abs(r - lastShare[tab]) > 0.01 then
			share = math.clamp(r, 0.08, 0.5)
			tern.kv.set("panel-share", share)
		end
		lastShare[tab] = r
		return
	end
	if openedAt[tab] and tern.now() - openedAt[tab] < PENDING_MS then return end
	local target = firstContent(cx, tab, own)
	if not target then return end
	openedAt[tab] = tern.now()
	local opened, err = cx.canvas:open({
		title = TITLE, about = ABOUT, focus = false, target = target, dir = "left", ratio = share,
		view = tern.ui.col({ tern.ui.text({ tern.ui.span("Loading…", "muted") }) }),
	})
	if opened then pending[opened] = { at = tern.now(), tab = tab } else report(cx, err or "Could not open the sidebar") end
end

-- Drawing. Only the shown tab's sidebar redraws; the others catch up when shown. A draw is two
-- callbacks, each well inside the 50 ms budget: the model here, the view and update next.
local pendingDraw = nil
local function model(cx)
	local section = arclets.section()
	return {
		section = section,
		-- The Workspaces model always runs: it notices agents and commands finishing, and counts
		-- what waits for the status bar, whichever section shows.
		ws = (function()
			pcall(arclets.nameSessions, cx)
			local m = ws.model(cx)
			return if section == "workspaces" then m else nil
		end)(),
		arclets = if section == "arclets" then arclets.model(cx) else nil,
	}
end

local function render(data)
	local children = {}
	if data.section == "arclets" then
		table.insert(children, AV.header(data.arclets))
		table.insert(children, AV.sectionBar("arclets"))
		for _, n in AV.render(data.arclets) do table.insert(children, n) end
	else
		table.insert(children, wsView.header(data.ws))
		table.insert(children, AV.sectionBar("workspaces"))
		for _, n in wsView.render(data.ws) do table.insert(children, n) end
	end
	return tern.ui.node("col", { key = "s", role = "arc.root" }, children)
end

local function draw(cx)
	local _, byTab = ours(cx)
	local tab = shownTab(cx)
	local pane = tab and byTab[tab]
	if not pane then return end
	local data = model(cx)
	local signature = tern.json.encode(data)
	if rendered[pane] == signature then return end
	local first = pendingDraw == nil
	pendingDraw = { pane = pane, data = data, signature = signature }
	if not first then return end
	tern.timer(0, function(c)
		local job = pendingDraw
		pendingDraw = nil
		if not c or not job then return end
		local ok, err = pcall(function()
			c.canvas:set(job.pane, { view = render(job.data) })
			rendered[job.pane] = job.signature
		end)
		-- A canvas can refuse updates until its state reaches this window; the next draw retries.
		if not ok and not tostring(err):find("not a canvas", 1, true) and problem ~= tostring(err) then report(c, err) end
	end)
end

local drawQueued = false
local function redraw()
	if drawQueued then return end
	drawQueued = true
	tern.timer(0, function(cx)
		drawQueued = false
		if not cx then return end
		local ok, err = pcall(draw, cx)
		if not ok and problem ~= tostring(err) then report(cx, err) end
	end)
end

local function followAndDraw(cx)
	local ok, err = pcall(follow, cx)
	if not ok and problem ~= tostring(err) then report(cx, err) end
	redraw()
end

ws.init({ redraw = redraw, report = report, ours = function(cx) return (ours(cx)) end })
arclets.init({ redraw = redraw, later = function(ms, fn) tern.timer(ms, fn) end })

-- Clicks keep the tab's content focused, so the tab keeps its own title.
local function returnFocus(cx, pane)
	local own = ours(cx)
	if not own[cx.session:focused() or -1] then return end
	local tab = pane and cx.session:tab_of(pane)
	local target = tab and firstContent(cx, tab, own)
	if target then cx.layout:focus(target) end
end

tern.on("canvas_action", function(ev, cx)
	if ev.owner and ev.owner ~= PLUGIN then return nil end
	if ev.title and ev.title ~= TITLE then return nil end
	local act, value = ev.act, ev.value
	if value == nil then act, value = string.match(ev.act, "^([^=]+)=?(.*)$") end
	returnFocus(cx, ev.pane)
	tern.timer(0, function(c) if c then pcall(returnFocus, c, ev.pane) end end)
	for _, handler in { arclets.action, ws.action } do
		local ok, handled = pcall(handler, cx, act, value, ev.act, ev.node)
		if not ok then
			report(cx, handled)
			return true
		end
		if handled then
			followAndDraw(cx)
			return true
		end
	end
	return false
end)

-- Commands -----------------------------------------------------------------------------------

local function setWantPanel(want)
	wantPanel = want
	tern.kv.set("panel-open", want)
end

tern.command({ id = "toggle", title = "Show or hide the sidebar", icon = "sidebar", keys = { "cmd+\\" }, run = function(cx)
	local own = ours(cx)
	if wantPanel and next(own) ~= nil then
		setWantPanel(false)
		for pane in own do
			cx.layout:close(pane)
			rendered[pane] = nil
		end
		return
	end
	setWantPanel(true)
	followAndDraw(cx)
end })

for i = 1, 9 do
	tern.command({ id = "goto_" .. i, title = "Sidebar: go to session " .. i, icon = "sidebar", keys = { "cmd+ctrl+" .. i },
		run = function(cx) ws.gotoIndex(cx, i); followAndDraw(cx) end })
end
tern.command({ id = "attention", title = "Sidebar: next pane that needs you", icon = "bell", keys = { "cmd+ctrl+0" },
	run = function(cx) ws.attention(cx); followAndDraw(cx) end })
tern.command({ id = "filter", title = "Sidebar: filter sessions", icon = "search", keys = { "cmd+ctrl+f" },
	run = function(cx)
		arclets.setSection("workspaces")
		ws.action(cx, "filter", nil)
	end })
tern.command({ id = "arclets", title = "Arclets", icon = "server", keys = { "ctrl+cmd+a" },
	run = function(cx)
		arclets.setSection("arclets")
		setWantPanel(true)
		followAndDraw(cx)
	end })
tern.command({ id = "new_arclet", title = "Arclet: New…", icon = "plus", run = function(cx) arclets.newArclet(cx) end })
tern.command({ id = "start_all", title = "Arclet: Start all stopped", icon = "play", run = function(cx) arclets.startAll(cx) end })

-- A split asked for while the sidebar has focus splits the tab's content instead.
for _, dir in { "right", "down" } do
	tern.override("split_" .. dir, function(cx)
		local own = ours(cx)
		local focused = cx.session:focused()
		if not focused or not own[focused] then return false end
		local target = firstContent(cx, cx.session:tab_of(focused), own)
		if not target then return false end
		local info = cx.session:pane(target)
		cx.layout:split(target, dir, { cwd = info and info.cwd ~= "" and info.cwd or nil })
		return true
	end)
end

tern.chrome.status(function()
	if ws.waiting > 0 then
		return { { text = ws.waiting .. " waiting", icon = "bell", tone = "accent", command = "plugin." .. PLUGIN .. ".attention" } }
	end
	return nil
end)

-- Events -------------------------------------------------------------------------------------

tern.on("window_start", function(cx)
	followAndDraw(cx)
	arclets.autostart(cx)
end)
for _, name in { "focus", "tab_created", "tab_closed", "pane_created", "pane_closed", "session_ended" } do
	tern.on(name, function(_ev, cx) followAndDraw(cx) end)
end
local waitingShown = 0
for _, name in { "title", "cwd", "command_started", "command_finished", "agent_state", "agent_finished" } do
	tern.on(name, function(_ev, _cx)
		redraw()
		if ws.waiting ~= waitingShown then
			waitingShown = ws.waiting
			pcall(tern.chrome.refresh)
		end
	end)
end

-- A slow poll for what no event reports: git branches, Arclet state, the other tabs' panes.
local function poll(cx)
	if cx then followAndDraw(cx) end
	tern.timer(POLL_MS, poll)
end
tern.timer(POLL_MS, poll)
