--!nonstrict
-- The Workspaces section: every Tern session in your order and its tabs, with each tab's
-- branch or folder and its agents' and commands' state, reordering and moving, and the menus.
-- paneState, agentOf and the unseen marks follow Kai (github.com/Yupmoh/tern-plugins, MIT,
-- see LICENSE.kai).
local V = require("./ws_view")
local M = V.M

local W = {}

local GIT_REFRESH_MS = 15000
local HOME = tern.getenv("HOME") or "/"

local hooks = {
	redraw = function() end,
	ours = function(_cx) return {} end, -- our sidebar panes, which every list leaves out
	report = function(_cx, _err) end,
}

local filter = nil -- the filter text, or nil
local moving = nil -- { kind = "ws"|"tab", id, name, host?, ws? } while placing a row
local git = {} -- folder -> { at, inflight, branch }
local lastState = {} -- pane -> state at the last model
local unseen = {} -- pane -> "done" | "failed": finished while you were elsewhere
do
	local saved = tern.kv.get("unseen")
	if type(saved) == "table" then
		for k, v in saved do
			local id = tonumber(k)
			if id then unseen[id] = v end
		end
	end
end
local unseenKey = ""
local order = {} -- session ids in sidebar order, from the last model
local attention = {} -- { ws, pane }, most urgent first
W.waiting = 0

local function records(key)
	local v = tern.kv.get(key)
	return if type(v) == "table" then v else {}
end

local function basename(path)
	return path:match("([^/]+)/*$") or path
end

-- Agent CLIs recognised in plain terminals, by program name.
local AGENTS = {
	omp = true, pi = true, claude = true, codex = true, opencode = true, gemini = true,
	aider = true, amp = true, ["cursor-agent"] = true, crush = true, goose = true,
}

local function agentOf(line)
	for segment in string.gmatch(line, "[^;&|]+") do
		for word in string.gmatch(segment, "%S+") do
			if not string.find(word, "=", 1, true) then
				local name = string.match(word, "([^/]+)$")
				if AGENTS[name] then return name end
				break
			end
		end
	end
	return nil
end

-- A pane's own state: native agent blocks report theirs; agent CLIs in terminals only `busy`.
local function paneState(pane, agents)
	local agent = agents[pane.pane]
	if agent then
		return if agent.state == "waiting_input" then "waiting" else agent.state
	end
	if pane.kind ~= "terminal" and pane.kind ~= "agent" then return "none" end
	if pane.exited then return "exited" end
	local line = pane.running and pane.running.line
	if line and agentOf(line) then return if pane.busy then "working" else "idle" end
	if line then return "running" end
	return "shell"
end

-- What a row shows: the unseen marks win, then live work.
local SHOWN = { waiting = true, working = true, running = true }
local RANK = { waiting = 5, failed = 4, working = 3, done = 2, running = 1 }
local function shown(pane, state)
	return unseen[pane] or (if SHOWN[state] then state else nil)
end
local function worst(a, b)
	if not a then return b end
	if not b then return a end
	return if RANK[b] > RANK[a] then b else a
end

local function paneTitle(pane)
	if pane.title and pane.title ~= "" then return pane.title end
	if pane.running then return pane.running.line end
	if pane.path then return basename(pane.path) end
	return pane.program or pane.kind or "pane"
end

local function leaves(tree, out)
	out = out or {}
	if not tree then return out end
	if tree.pane then table.insert(out, tree.pane) return out end
	leaves(tree[1], out)
	leaves(tree[2], out)
	return out
end

-- A tab's content panes (not our sidebar) in layout order.
local function tabPanes(cx, tab)
	local own = hooks.ours(cx)
	local layout = cx.session:layout(tab)
	local list = {}
	for _, p in leaves(layout and layout.root) do
		if not own[p] then table.insert(list, p) end
	end
	return list
end

local function refreshGit(folder)
	local e = git[folder]
	if e and (e.inflight or tern.now() - e.at < GIT_REFRESH_MS) then return end
	e = e or {}
	e.inflight, e.at = true, tern.now()
	git[folder] = e
	tern.timer(0, function(cx)
		if not cx then e.inflight = false return end
		local ok = pcall(function()
			cx.git:repo(folder):next(function(repo)
				e.inflight = false
				local branch = repo and (repo.branch or (repo.head and repo.head:sub(1, 8))) or nil
				if branch ~= e.branch then e.branch = branch; hooks.redraw() end
			end)
		end)
		if not ok then e.inflight = false end
	end)
end

local function hostLabel(h)
	if not h or h.kind ~= "remote" then return nil end
	return h.name:match("^arclet_([a-z0-9-]+)%.ssh$") or h.name
end

-- Session ids in your order; new ones last, in Tern's order.
local function sessionOrder(cx)
	local rank = {}
	for i, id in records("ws-order") do rank[tostring(id)] = i end
	local list = {}
	for i, s in cx.session:sessions() do table.insert(list, { id = s.id, i = i }) end
	table.sort(list, function(a, b)
		local ra, rb = rank[tostring(a.id)], rank[tostring(b.id)]
		if ra and rb then return ra < rb end
		if ra or rb then return ra ~= nil end
		return a.i < b.i
	end)
	local ids = {}
	for _, x in list do table.insert(ids, x.id) end
	return ids
end

local function notify(cx, kind, title)
	local text = if kind == "done" then "Finished" elseif kind == "failed" then "Command failed" else "Waiting for you"
	pcall(function() cx:toast(if kind == "failed" then "error" else "info", title, text) end)
end

-- Plain data for the view (JSON-encodable: the draw diffs its signature).
function W.model(cx)
	local own = hooks.ours(cx)
	local agents = {}
	for _, a in cx.agents:list() do agents[a.pane] = a end
	local focused = cx.session:focused()
	local focusedTab = focused and cx.session:tab_of(focused)
	local current = cx.sessions:current()

	local hostOf, hosts = {}, {}
	for _, h in cx.hosts:list() do hosts[h.id] = h end
	for _, s in cx.sessions:list() do hostOf[s.id] = hosts[s.host] end
	local tabInfo = {}
	for _, t in cx.session:tabs() do tabInfo[t.id] = t end
	local paneInfo = {}
	for _, p in cx.session:panes() do
		if p.tab and not p.parked and not own[p.pane] then paneInfo[p.pane] = p end
	end

	local open = records("open")
	local byId, waitingList, failedList, doneList = {}, {}, {}, {}
	W.waiting = 0
	local q = filter and filter:lower()
	local function hit(text) return q ~= nil and type(text) == "string" and text:lower():find(q, 1, true) ~= nil end

	for _, s in cx.session:sessions() do
		local h = hostOf[s.id]
		local ws = {
			id = s.id, name = s.name, current = s.id == current.id, locked = s.locked,
			host = hostLabel(h), hostId = h and h.id, tabs = {}, working = 0, blocked = 0,
		}
		local folder
		for _, tabId in s.tabs do
			local info = tabInfo[tabId]
			local tab = { id = tabId, position = info and info.position or 1, current = tabId == focusedTab, panes = 0 }
			local first, cwd = nil, nil
			for _, pid in tabPanes(cx, tabId) do
				local p = paneInfo[pid]
				if p then
					local state = paneState(p, agents)
					local title = paneTitle(p)
					local prev = lastState[pid]
					lastState[pid] = state
					if pid == focused or tab.current then
						unseen[pid] = nil
					elseif prev == "working" and state ~= "working" and state ~= "waiting" then
						unseen[pid] = "done"
						notify(cx, "done", title)
					elseif prev == "running" and state ~= "running" and p.last and p.last.status ~= 0 then
						unseen[pid] = "failed"
						notify(cx, "failed", title)
					elseif prev and prev ~= "waiting" and state == "waiting" then
						notify(cx, "waiting", title)
					end
					local mark = shown(pid, state)
					if state == "waiting" then
						W.waiting += 1
						table.insert(waitingList, { ws = s.id, pane = pid })
					elseif mark == "failed" then table.insert(failedList, { ws = s.id, pane = pid })
					elseif mark == "done" then table.insert(doneList, { ws = s.id, pane = pid }) end
					if mark == "waiting" or mark == "failed" then ws.blocked += 1
					elseif mark == "working" or mark == "running" then ws.working += 1 end
					tab.state = worst(tab.state, mark)
					tab.panes += 1
					tab.agent = tab.agent or agents[pid] ~= nil
					tab.hit = tab.hit or hit(title) or hit(p.program)
					first = first or title
					-- The tab's place: its focused pane's folder, else its first pane's.
					if p.cwd and p.cwd ~= "" and (cwd == nil or (info and info.pane == pid)) then cwd = p.cwd end
				end
			end
			if tab.panes > 0 then
				tab.name = if info and info.name and info.name ~= "" then info.name else first
				folder = folder or cwd
				-- Where the tab works: its git branch on this machine, else its folder's name.
				if cwd then
					if not ws.host then refreshGit(cwd) end
					local branch = not ws.host and git[cwd] and git[cwd].branch
					tab.where = if branch then branch else (if cwd == HOME then "~" else basename(cwd))
					tab.git = branch ~= nil and branch ~= false
				end
				ws.state = worst(ws.state, tab.state)
				table.insert(ws.tabs, tab)
			end
		end
		ws.folder = folder or HOME
		local stored = open[tostring(s.id)]
		ws.open = stored ~= false
		-- Filtering: a session matches by its name or folder, or keeps only its matching tabs.
		local keep = true
		if q then
			if not (hit(ws.name) or hit(ws.folder)) then
				local kept = {}
				for _, t in ws.tabs do
					if hit(t.name) or hit(t.where) or t.hit then table.insert(kept, t) end
				end
				ws.tabs = kept
				keep = #kept > 0
			end
			ws.open = true
		end
		for _, t in ws.tabs do t.hit = nil end
		if keep then byId[s.id] = ws end
	end

	-- Save the unseen marks when they change, dropping panes that no longer exist.
	local keepMarks, parts = {}, {}
	for id, v in unseen do
		if paneInfo[id] then
			keepMarks[tostring(id)] = v
			table.insert(parts, tostring(id) .. v)
		else
			unseen[id] = nil
		end
	end
	table.sort(parts)
	local key = table.concat(parts, ",")
	if key ~= unseenKey then
		unseenKey = key
		tern.kv.set("unseen", if #parts > 0 then keepMarks else nil)
	end

	attention = {}
	for _, list in { waitingList, failedList, doneList } do
		for _, x in list do table.insert(attention, x) end
	end
	local sessions = {}
	order = {}
	for _, id in sessionOrder(cx) do
		if byId[id] then
			table.insert(sessions, byId[id])
			table.insert(order, id)
		end
	end
	return { sessions = sessions, filter = filter, moving = moving }
end

-- Navigation ---------------------------------------------------------------------------------

local function showSession(cx, id)
	if id and cx.sessions:current().id ~= id then cx.sessions:switch(id) end
end

local function reveal(cx, ws, pane)
	showSession(cx, ws)
	if pane and cx.session:pane(pane) then cx.layout:focus(pane) end
end

local function sessionInfo(cx, id)
	for _, s in cx.session:sessions() do
		if s.id == id then return s end
	end
	return nil
end

local function sessionFolder(cx, id)
	local s = sessionInfo(cx, id)
	for _, tab in (s and s.tabs or {}) do
		for _, pid in tabPanes(cx, tab) do
			local p = cx.session:pane(pid)
			if p and p.cwd and p.cwd ~= "" then return p.cwd end
		end
	end
	return HOME
end

local function tabInfoOf(cx, tab)
	for _, t in cx.session:tabs() do
		if t.id == tab then return t end
	end
	return nil
end

local function hostOfSession(cx, id)
	for _, s in cx.sessions:list() do
		if s.id == id then return s.host end
	end
	return nil
end

local function goTab(cx, ws, tab)
	local info = tabInfoOf(cx, tab)
	local panes = tabPanes(cx, tab)
	local target = if info and not hooks.ours(cx)[info.pane] then info.pane else panes[1]
	reveal(cx, ws, target)
end

function W.gotoIndex(cx, i)
	local id = order[i] or sessionOrder(cx)[i]
	if id then showSession(cx, id) end
end

function W.attention(cx)
	local x = attention[1]
	if not x then return cx:toast("info", "Nothing needs you") end
	reveal(cx, x.ws, x.pane)
end

-- Prompts and confirmations -----------------------------------------------------------------

local function ask(cx, opts, fn)
	cx:prompt(opts):next(function(value, _, c)
		if c and value ~= nil then
			local ok, err = pcall(fn, c, value)
			if not ok then hooks.report(c, err) end
			hooks.redraw()
		end
	end)
end

-- Raw closes skip Tern's own "programs are running" check, so ask first.
local function confirm(cx, question, label, fn)
	cx:pick({ placeholder = question, icon = "x", action = "confirm", items = {
		{ label = label, icon = "x", go = true },
		{ label = "Cancel" },
	} }):next(function(item, _, c)
		if c and item and item.go then
			local ok, err = pcall(fn, c)
			if not ok then hooks.report(c, err) end
			hooks.redraw()
		end
	end)
end

local function pickSession(cx, except, fn)
	local host = hostOfSession(cx, except)
	local items = {}
	for _, s in cx.session:sessions() do
		if s.id ~= except and hostOfSession(cx, s.id) == host then table.insert(items, { label = s.name, id = s.id }) end
	end
	if #items == 0 then return cx:toast("info", "No other session on this host") end
	cx:pick({ placeholder = "Move to session", icon = "sidebar", action = "move", items = items }):next(function(item, _, c)
		if c and item then
			local ok, err = pcall(fn, c, item.id)
			if not ok then hooks.report(c, err) end
			hooks.redraw()
		end
	end)
end

-- Moving -------------------------------------------------------------------------------------

local function setOrder(ids) tern.kv.set("ws-order", ids) end

-- Moves session `id` to position `to` (1-based) in the sidebar order.
local function placeSession(cx, id, to)
	local ids = sessionOrder(cx)
	local from = table.find(ids, id)
	if not from then return end
	table.remove(ids, from)
	table.insert(ids, math.clamp(to, 1, #ids + 1), id)
	setOrder(ids)
end

-- Moves a tab (all its panes) to the end of another session, which must be on the same host.
local function tabToSession(cx, tab, ws)
	local panes = tabPanes(cx, tab)
	if #panes == 0 then return end
	local newTab = cx.layout:move_to_new_tab(panes[1], ws, { focus = false })
	for i = 2, #panes do
		if newTab then cx.layout:move_to_tab(panes[i], newTab, { focus = false }) end
	end
end

local function startMove(cx, kind, id)
	if kind == "ws" then
		local s = sessionInfo(cx, id)
		if s then moving = { kind = "ws", id = id, name = s.name } end
	elseif kind == "tab" then
		local info = tabInfoOf(cx, id)
		if info then
			local first = tabPanes(cx, id)[1]
			local p = first and cx.session:pane(first)
			moving = { kind = "tab", id = id, ws = info.session, host = hostOfSession(cx, info.session),
				name = if info.name and info.name ~= "" then info.name elseif p then paneTitle(p) else "tab" }
		end
	end
end

-- A drop slot: "<kind>:<where>" — ws:<before session|0>, tab:<before tab|0>:<session>.
local function drop(cx, value)
	local m = moving
	moving = nil
	if not m then return end
	local kind, a, b = string.match(value or "", "^(%a+):(%d+):?(%d*)$")
	a, b = tonumber(a), tonumber(b)
	if kind ~= m.kind or not a then return end
	if kind == "ws" then
		local ids = sessionOrder(cx)
		local from = table.find(ids, m.id)
		if not from then return end
		table.remove(ids, from)
		local at = if a == 0 then #ids + 1 else table.find(ids, a)
		if at then table.insert(ids, at, m.id); setOrder(ids) end
	elseif kind == "tab" then
		if b and b ~= m.ws then
			tabToSession(cx, m.id, b)
			return
		end
		local tabs = {}
		for _, t in cx.session:tabs() do
			if t.session == m.ws then table.insert(tabs, t) end
		end
		table.sort(tabs, function(x, y) return x.position < y.position end)
		local from, to
		for _, t in tabs do
			if t.id == m.id then from = t.position end
			if t.id == a then to = t.position end
		end
		if not from then return end
		if a == 0 then to = #tabs elseif not to then return elseif from < to then to -= 1 end
		cx.layout:order_tab(m.id, to)
	end
end

-- Folds and the new-session picker -----------------------------------------------------------

local function toggleFold(store, id, default)
	local all = records(store)
	local cur = all[tostring(id)]
	if cur == nil then cur = default end
	all[tostring(id)] = not cur
	tern.kv.set(store, all)
end

local function setAll(cx, open)
	local ws = {}
	for _, s in cx.session:sessions() do ws[tostring(s.id)] = open end
	tern.kv.set("open", ws)
end

local picking = false
local function newSession(cx)
	if cx.hosts:current().kind ~= "local" then
		return ask(cx, { placeholder = "Session name", icon = "plus", action = "create" }, function(c, name)
			c.sessions:create({ name = if name:match("%S") then name else nil })
		end)
	end
	if picking then return end
	picking = true
	local start = tern.kv.get("picker-start")
	if type(start) ~= "string" or not tern.fs.exists(start) then start = HOME end
	local argv = { "/usr/bin/osascript", "-e", "on run argv", "-e",
		'POSIX path of (choose folder with prompt "Choose a folder for the new session" default location (POSIX file (item 1 of argv)))',
		"-e", "end run", start }
	local ok, err = pcall(tern.process.run, argv, { timeout_ms = 30 * 60 * 1000 }, function(r, c)
		picking = false
		if not c or r.status ~= 0 then return end
		local path = (r.stdout or ""):match("^%s*(.-)%s*$"):gsub("/+$", "")
		if path == "" then return end
		tern.kv.set("picker-start", path:match("^(.*)/[^/]+$") or path)
		local ok2, err2 = pcall(function() c.sessions:create({ name = basename(path), cwd = path }) end)
		if not ok2 then hooks.report(c, err2) end
		hooks.redraw()
	end)
	if not ok then picking = false; hooks.report(cx, err) end
end

local function reveal_in_finder(path)
	pcall(tern.process.run, { "/usr/bin/open", path }, { timeout_ms = 10000 }, function() end)
end

-- Actions ------------------------------------------------------------------------------------

local function targetOf(node)
	node = node or ""
	return tonumber(node:match("%.w(%d+)")), tonumber(node:match("%.t(%d+)"))
end

local function menu(cx, label, node)
	local ws, tab = targetOf(node)
	-- Header
	if label == M.newSession then return newSession(cx)
	elseif label == M.expandAll then return setAll(cx, true)
	elseif label == M.collapseAll then return setAll(cx, false)
	elseif label == M.filter then return W.action(cx, "filter", nil)
	end
	-- Tab
	if tab and V.TAB[label] then
		local info = tabInfoOf(cx, tab)
		if not info then return end
		local name = if info.name and info.name ~= "" then info.name else info.title
		if label == M.goTab then goTab(cx, ws, tab)
		elseif label == M.rename then
			ask(cx, { value = name, placeholder = "Tab name (blank resets)", icon = "pen", action = "rename" },
				function(c, v) c.layout:name_tab(tab, v) end)
		elseif label == M.newPaneRight or label == M.newPaneDown then
			local target = tabPanes(cx, tab)[1]
			if target then
				showSession(cx, ws)
				cx.layout:split(target, if label == M.newPaneRight then "right" else "down", { cwd = info.cwd ~= "" and info.cwd or nil })
			end
		elseif label == M.even then cx.layout:even(tab)
		elseif label == M.up then cx.layout:order_tab(tab, math.max(1, info.position - 1))
		elseif label == M.down then cx.layout:order_tab(tab, info.position + 1)
		elseif label == M.move then startMove(cx, "tab", tab)
		elseif label == M.toSession then pickSession(cx, ws, function(c, id) tabToSession(c, tab, id) end)
		elseif label == M.close then
			confirm(cx, "Close tab " .. name .. " and its programs?", "Close tab", function(c)
				for _, pid in tabPanes(c, tab) do c.layout:close(pid) end
			end)
		end
		return
	end
	-- Session
	local s = ws and sessionInfo(cx, ws)
	if not s then return end
	if label == M.switch then showSession(cx, ws)
	elseif label == M.newTab then
		showSession(cx, ws)
		cx.layout:new_tab({ cwd = sessionFolder(cx, ws) })
	elseif label == M.rename then
		ask(cx, { value = s.name, placeholder = "Session name", icon = "pen", action = "rename" },
			function(c, v) if v:match("%S") then c.sessions:rename(ws, v) end end)
	elseif label == M.up then placeSession(cx, ws, (table.find(sessionOrder(cx), ws) or 1) - 1)
	elseif label == M.down then placeSession(cx, ws, (table.find(sessionOrder(cx), ws) or 0) + 1)
	elseif label == M.top then placeSession(cx, ws, 1)
	elseif label == M.move then startMove(cx, "ws", ws)
	elseif label == M.lock then cx.sessions:lock(ws)
	elseif label == M.unlock then cx.sessions:unlock(ws)
	elseif label == M.copyPath then
		local path = sessionFolder(cx, ws)
		cx:copy(path); cx:toast("info", "Path copied", path)
	elseif label == M.finder then reveal_in_finder(sessionFolder(cx, ws))
	elseif label == M.collapseOthers then
		local all = {}
		for _, x in cx.session:sessions() do all[tostring(x.id)] = x.id == ws end
		tern.kv.set("open", all)
	elseif label == M.close then
		confirm(cx, "Close session " .. s.name .. " and all its programs?", "Close session", function(c) c.sessions:close(ws) end)
	end
end

-- A canvas click or menu pick; true when it was ours.
function W.action(cx, act, value, label, node)
	if moving and act ~= "drop" and act ~= "pick" then
		-- While a row is picked up, only a slot places it; any other click cancels.
		moving = nil
	elseif act == "drop" then drop(cx, value)
	elseif act == "pick" then
		local kind, id = string.match(value or "", "^(%a+):(%d+)$")
		if kind then startMove(cx, kind, tonumber(id)) end
	elseif act == "cancelmove" then moving = nil
	elseif act == "fold" then
		local id = string.match(value or "", "^ws:(%d+)$")
		if id then toggleFold("open", id, true) end
	elseif act == "ws" then showSession(cx, tonumber(value))
	elseif act == "wsup" or act == "wsdown" then
		local ws = tonumber(value)
		local at = ws and table.find(sessionOrder(cx), ws)
		if at then placeSession(cx, ws, if act == "wsup" then at - 1 else at + 1) end
	elseif act == "tab" then
		local ws, tab = string.match(value or "", "^(%d+):(%d+)$")
		if tab then goTab(cx, tonumber(ws), tonumber(tab)) end
	elseif act == "newtab" then
		local ws = tonumber(value)
		if ws then
			showSession(cx, ws)
			cx.layout:new_tab({ cwd = sessionFolder(cx, ws) })
		end
	elseif act == "close" then
		local id = string.match(value or "", "^tab:(%d+)$")
		if id then menu(cx, M.close, ".t" .. id) end
	elseif act == "newsession" then newSession(cx)
	elseif act == "filter" then
		ask(cx, { value = filter or "", placeholder = "Filter sessions and tabs", icon = "search", action = "filter" },
			function(_, v)
				local t = v:match("^%s*(.-)%s*$")
				filter = if t ~= "" then t else nil
			end)
	elseif act == "clearfilter" then filter = nil
	elseif V.LABELS[label] then
		local ok, err = pcall(menu, cx, label, node)
		if not ok then hooks.report(cx, err) end
	else
		return false
	end
	hooks.redraw()
	return true
end

function W.init(h)
	hooks = h
end

W.leaves = leaves
return W
