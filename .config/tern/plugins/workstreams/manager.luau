--!strict
-- Workstreams live on the pane's host. Only the window half may touch sessions.
local ui = tern.ui
local refs = require("./refs")
local running = setmetatable({}, { __mode = "v" }) -- Tracks live callbacks, not cached worktrees.

local function link(cx, action, data)
	local json = tern.json.encode(data)
	local encoded = json:gsub("[^%w%-%._~]", function(byte)
		return string.format("%%%02X", string.byte(byte))
	end)
	cx:open("tern-workstreams://" .. action .. "/" .. encoded)
end

local function valid_path(path)
	return type(path) == "string" and path:sub(1, 1) == "/" and not path:find("%z")
end

local function valid_record(record, path)
	if type(record) ~= "table" or record.version ~= 1 or record.path ~= path
		or type(record.name) ~= "string" or record.name == ""
		or type(record.tabs) ~= "table" or #record.tabs == 0 then
		return false
	end
	for _, tab in ipairs(record.tabs) do
		if type(tab) ~= "table" or (tab.cwd ~= nil and type(tab.cwd) ~= "string")
			or (tab.name ~= nil and type(tab.name) ~= "string") then
			return false
		end
	end
	return true
end

local function worktree(state, path)
	for _, item in ipairs(state.worktrees) do
		if type(item) == "table" and item.path == path then
			return item
		end
	end
	return nil
end

local function active_session(state, path, item)
	item = item or worktree(state, path)
	if not item then return nil end
	for _, session in ipairs(state.sessions) do
		if type(session) == "table" and type(session.id) == "number"
			and session.name == item.branch and type(session.tabs) == "table" then
			for _, tab in ipairs(session.tabs) do
				if type(tab) == "table" and type(tab.cwd) == "string"
					and (tab.cwd == path or tab.cwd:sub(1, #path + 1) == path .. "/") then
					return session
				end
			end
		end
	end
	return nil
end

local function load(state)
	local ok, worktrees, paused = pcall(function()
		return tern.kv.get("workstreams") or {}, tern.kv.get("paused_workstreams") or {}
	end)
	if not ok then
		state.message = "Could not read host workstreams: " .. tostring(worktrees)
		return false
	end
	if type(worktrees) ~= "table" or type(paused) ~= "table" then
		state.message = "Invalid host workstream storage; nothing was overwritten."
		return false
	end
	state.worktrees, state.paused = worktrees, paused
	local synced, err = pcall(refs.sync, worktrees)
	state.ref_error = if synced then nil else "Could not sync references: " .. tostring(err)
	return true
end

local function alive(state)
	if state.closed or running[state.cx.pane] ~= state then
		return false
	end
	for _, pane in ipairs(tern.pane.list()) do
		if pane.pane == state.cx.pane then
			return true
		end
	end
	return false
end

local function bootstrap(state)
	if state.loading or state.cwd == "" then
		return
	end
	state.loading = true
	state.message = "Discovering worktrees…"
	local ok, err = pcall(tern.process.run, { "git", "-C", state.cwd, "worktree", "list", "--porcelain" },
		{ timeout_ms = 12000 }, function(result)
			if not alive(state) then return end
			state.loading = false
			if result.status ~= 0 then
				state.message = result.timed_out and "Git worktree discovery timed out; press R to retry."
					or (result.stderr:gsub("%s+$", ""))
				if state.message == "" then state.message = "Could not discover Git worktrees; press R to retry." end
				state.cx:render()
				return
			end
			local base = tern.getenv("HERDR_WORKTREES_DIR")
			if base == nil or base == "" then
				local home = tern.getenv("HOME") or ""
				base = home .. "/.herdr/worktrees"
			end
			base = base:gsub("/+$", "")
			if base:sub(1, 1) ~= "/" then
				state.message = "HERDR_WORKTREES_DIR must be an absolute path."
				state.cx:render()
				return
			end
			local blocks = {}
			for block in (result.stdout .. "\n\n"):gmatch("(.-)\n\n") do
				local path = block:match("^worktree ([^\n]+)")
				if path then
					table.insert(blocks, { path = path, branch = block:match("\nbranch refs/heads/([^\n]+)") })
				end
			end
			local root = blocks[1] and blocks[1].path
			if not root then
				state.message = "Git returned no worktrees; press R to retry."
				state.cx:render()
				return
			end
			local known = {}
			for _, item in ipairs(state.worktrees) do
				if type(item) == "table" then known[item.path] = true end
			end
			local fresh = {}
			for _, item in ipairs(blocks) do
				if item.branch and item.path ~= root and item.path:sub(1, #base + 1) == base .. "/"
					and not item.path:sub(#base + 2):match("^%.base%-") and not known[item.path] then
					table.insert(fresh, { path = item.path, branch = item.branch, repo_root = root, mode = "existing" })
					known[item.path] = true
				end
			end
			if #fresh > 0 then
				local saved, save_err = pcall(function()
					local stored = tern.kv.get("workstreams") or tern.json.array()
					if type(stored) ~= "table" then error("invalid workstreams storage") end
					local present = {}
					for _, item in ipairs(stored) do
						if type(item) == "table" then present[item.path] = true end
					end
					for _, item in ipairs(fresh) do
						if not present[item.path] then table.insert(stored, item) end
					end
					tern.kv.set("workstreams", stored)
				end)
				if saved then
					load(state)
				else
					state.message = "Could not register discovered worktrees: " .. tostring(save_err)
				end
			elseif state.message == "Discovering worktrees…" then
				state.message = ""
			end
			state.cx:render()
		end)
	if not ok then
		state.loading = false
		state.message = "Could not start Git discovery: " .. tostring(err)
	end
end

local function create(state)
	if state.busy then return end
	if state.path then
		link(state.cx, "created", { branch = state.branch, path = state.path, mode = state.created_mode })
		state.message = "Requesting a session in this window…"
		return
	end
	if state.cwd == "" then
		state.message = "Focus a terminal in a Git repository first."
		return
	end
	local branch = state.branch:match("^%s*(.-)%s*$")
	if branch == "" then
		state.message = "Enter a branch name."
		return
	end
	state.busy, state.message = true, "Creating the Git worktree…"
	local ok, err = pcall(tern.process.run,
		{ "bash", tern.plugin.dir .. "/create.sh", state.cwd, branch }, { timeout_ms = 300000 },
		function(result)
			local showing = alive(state)
			if not showing and result.status ~= 0 then return end
			state.busy = false
			if result.status ~= 0 then
				state.message = result.timed_out and "Creation timed out; inspect the checkout before retrying."
					or (result.stderr:gsub("%s+$", ""))
				if state.message == "" then state.message = "Creation failed; inspect the checkout before retrying." end
			else
				local mode, path, name, root = result.stdout:match("^([^%z]+)%z([^%z]+)%z([^%z]+)%z([^%z]+)%z$")
				if (mode == "git" or mode == "overlay" or mode == "existing") and valid_path(path)
					and valid_path(root) and name ~= "" then
					local stored, store_err = pcall(function()
						local entries = tern.kv.get("workstreams") or tern.json.array()
						if type(entries) ~= "table" then error("invalid workstreams storage") end
						local found = false
						for i, item in ipairs(entries) do
							if type(item) == "table" and item.path == path then
								entries[i] = { mode = mode, path = path, branch = name, repo_root = root }
								found = true
								break
							end
						end
						if not found then table.insert(entries, { mode = mode, path = path, branch = name, repo_root = root }) end
						tern.kv.set("workstreams", entries)
					end)
					if stored then
						if not showing then return end
						state.path, state.branch, state.created_mode = path, name, mode
						load(state)
						state.message = "Worktree ready. Opening its session…"
						link(state.cx, "created", { branch = name, path = path, mode = mode })
					else
						state.message = "Checkout exists at " .. path .. "; could not save host record: " .. tostring(store_err)
					end
				else
					state.message = "Creator returned an invalid result; inspect the checkout before retrying."
				end
			end
			if showing then state.cx:render() end
		end)
	if not ok then
		state.busy = false
		state.message = "Could not start creator: " .. tostring(err)
	end
end

local function ref_list(path)
	local ok, items = pcall(refs.list, path)
	return if ok and type(items) == "table" then items else {}, if ok then nil else tostring(items)
end

local function rows(state)
	local shown = {}
	if state.mode == "refs" then
		local items, err = ref_list(state.ref_path)
		if err then state.message = "Could not read references: " .. err end
		for _, ref in ipairs(items) do
			if type(ref) == "table" and not ref.dismissed and type(ref.kind) == "string" and type(ref.id) == "string" then
				table.insert(shown, { key = ref.kind .. ":" .. ref.id, ref = ref })
			end
		end
	elseif state.mode == "restore" then
		for path, record in pairs(state.paused) do
			if valid_path(path) and valid_record(record, path) then
				table.insert(shown, { key = path, item = worktree(state, path), record = record })
			end
		end
	else
		local query = state.query:lower()
		for _, item in ipairs(state.worktrees) do
			if type(item) == "table" and valid_path(item.path) and type(item.branch) == "string" and item.branch ~= "" then
				local repo = type(item.repo_root) == "string" and item.repo_root:match("([^/]+)$") or ""
				local session = active_session(state, item.path, item)
				local haystack = table.concat({ item.branch, item.path, repo or "", type(item.repo_root) == "string" and item.repo_root or "", session and session.name or "" }, " "):lower()
				local matches = query == "" or haystack:find(query, 1, true) ~= nil
				if not matches then
					local item_refs = ref_list(item.path)
					for _, ref in ipairs(item_refs) do
						if type(ref) == "table" and not ref.dismissed
							and (tostring(ref.id or "") .. " " .. tostring(ref.kind or "") .. " " .. tostring(ref.url or "")):lower():find(query, 1, true) then
							matches = true
							break
						end
					end
				end
				if matches then
					local record = state.paused[item.path]
					table.insert(shown, { key = item.path, item = item, session = session,
						record = valid_record(record, item.path) and record or nil })
				end
			end
		end
	end
	table.sort(shown, function(a, b) return a.key < b.key end)
	local selected = false
	for _, row in ipairs(shown) do
		if row.key == state.cursor then selected = true; break end
	end
	if not selected then state.cursor = shown[1] and shown[1].key or nil end
	return shown
end

local function selected(state)
	for _, row in ipairs(rows(state)) do
		if row.key == state.cursor then return row end
	end
	return nil
end

local function move(state, delta)
	local list = rows(state)
	if #list == 0 then return end
	for i, row in ipairs(list) do
		if row.key == state.cursor then
			state.cursor = list[math.clamp(i + delta, 1, #list)].key
			return
		end
	end
end

local function enter(state)
	if state.mode == "create" then create(state); return end
	local row = selected(state)
	if not row then return end
	if state.mode == "refs" then
		local url = row.ref.url
		if type(url) == "string" and (url:match("^https?://") or url:match("^file:///")) then
			state.cx:open(url)
		else
			state.message = "This reference has no web or file link to open."
		end
	elseif state.mode == "restore" or row.record then
		local record = row.record
		if valid_record(record, row.key) then
			link(state.cx, "restore", { record = record })
			state.message = "Requesting restore in this window; record stays until confirmed."
		end
	elseif row.item then
		link(state.cx, "focus", { branch = row.item.branch, path = row.item.path })
		state.message = "Requesting this workstream in this window…"
	end
end

return {
	init = function(cx, args, saved)
		local cwd = args[1] or cx.cwd or ""
		local mode = if args[2] == "create" or args[2] == "pause" or args[2] == "restore" or args[2] == "refs" then args[2] else "list"
		local sessions = {}
		if type(args[3]) == "string" then
			local ok, data = pcall(tern.json.decode, args[3])
			if ok and type(data) == "table" and type(data.sessions) == "table" then
				sessions = data.sessions
			end
		end
		local state = {
			cx = cx, cwd = cwd, mode = mode, sessions = sessions, worktrees = {}, paused = {},
			branch = "", path = nil, created_mode = nil, query = "", cursor = nil, ref_path = nil,
			pending_pause = nil, message = "Discovering worktrees…", ref_error = nil,
			loading = false, busy = false, closed = false,
		}
		if type(saved) == "table" and saved.cwd == cwd then
			if type(saved.branch) == "string" then state.branch = saved.branch end
			if type(saved.query) == "string" then state.query = saved.query end
			if type(saved.cursor) == "string" then state.cursor = saved.cursor end
			if valid_path(saved.pending_pause) then state.pending_pause = saved.pending_pause end
			if valid_path(saved.path) and (saved.created_mode == "git" or saved.created_mode == "overlay" or saved.created_mode == "existing") then
				state.path, state.created_mode = saved.path, saved.created_mode
				state.message = "Checkout ready. Press Enter to open its session."
			end
			if saved.mode == "search" or saved.mode == "restore" or saved.mode == "create" then
				state.mode = saved.mode
			elseif saved.mode == "refs" and valid_path(saved.ref_path) then
				state.mode, state.ref_path = "refs", saved.ref_path
			else
				state.query = ""
			end
		end
		running[cx.pane] = state
		local host = tern.getenv("HOSTNAME")
		state.host = host and host ~= "" and host or "selected host"
		if state.host == "selected host" then
			pcall(tern.process.run, { "hostname" }, { timeout_ms = 2000 }, function(result)
				if alive(state) and result.status == 0 then
					local name = result.stdout:gsub("%s+$", "")
					if name ~= "" then state.host = name; cx:render() end
				end
			end)
		end
		local ready = load(state)
		if ready and state.mode == "refs" and state.ref_path == nil then
			for _, item in ipairs(state.worktrees) do
				if type(item) == "table" and valid_path(item.path)
					and (cwd == item.path or cwd:sub(1, #item.path + 1) == item.path .. "/") then
					state.ref_path = item.path
					break
				end
			end
			if state.ref_path == nil then
				state.mode = "list"
				state.message = "Select a workstream and press f for references."
			end
		end
		if cwd == "" then state.message = "Focus a terminal in a Git repository first."
		elseif ready then bootstrap(state) end
		if state.mode == "create" or state.mode == "search" then cx:frame({ { "focus", "main.input" } }) end
		return state
	end,
	title = function(state)
		return "Workstreams · " .. state.mode
	end,
	view = function(state, cx)
		local children = { ui.text({ ui.span("Workstreams  ", "strong"), ui.span(state.host, "muted") }),
			ui.text({ ui.span("cwd  ", "muted"), ui.span(state.cwd ~= "" and state.cwd or "(none)", "path") }) }
		local bridge = ui.text("")
		bridge.p.key = "bridge"
		table.insert(children, bridge)
		if state.mode == "create" or state.mode == "search" then
			local creating = state.mode == "create"
			table.insert(children, ui.node("input", {
				key = "input", text = if creating then state.branch else state.query,
				placeholder = if creating then "feature/short-name" else "Search branches, repos, paths, references",
				readonly = creating and (state.path ~= nil or state.busy),
				aria = if creating then "Workstream branch" else "Search workstreams",
			}))
		end
		if state.mode == "create" then
			table.insert(children, ui.text(state.path or "Create a worktree-backed session in this host"))
		else
			if state.mode == "refs" then
				table.insert(children, ui.text("References · " .. (state.ref_path or "")))
			elseif state.mode == "restore" then
				table.insert(children, ui.text("Paused workstreams · checkout stays on disk"))
			elseif state.mode == "pause" then
				table.insert(children, ui.text({ ui.span("Pause " .. (state.cursor or "") .. "?", "warning"), ui.span("  Sessions close and running programs stop.", "muted") }))
			end
			local list = rows(state)
			local items = {}
			for i, row in ipairs(list) do
				if row.ref then
					local ref = row.ref
					items[i] = { label = ref.kind .. ":" .. ref.id, detail = ref.url or "",
						value = ref.pinned and "★ pinned" or "", tone = ref.pinned and "accent" or nil }
				else
					local item = row.item
					local branch = item and item.branch or row.record.name
					local repo = item and type(item.repo_root) == "string" and item.repo_root:match("([^/]+)$") or ""
					items[i] = { label = branch, detail = (repo or "") .. "  " .. row.key,
						value = row.record and (row.session and "paused · closing" or "paused") or row.session and "active" or "checkout", icon = "git-branch",
						tone = row.record and "warning" or nil }
				end
			end
			local node = ui.list(items)
			for i, row in ipairs(list) do node.c[i].p.key = row.key end
			node.p = { key = "rows", selected = state.cursor and "main.rows." .. state.cursor or nil }
			node.p.max = { lines = math.max(4, math.floor((cx.rows - 7) * 0.72)) }
			node.p.empty = { ui.span(if state.mode == "refs" then "No references yet. Press R to refresh."
				elseif state.mode == "restore" then "No paused sessions on this host."
				elseif state.query ~= "" then "No matches. Press Esc to clear the search."
				else "No workstreams yet. Press n to create one from this repository.", "muted") }
			table.insert(children, node)
		end
		local help = if state.mode == "create" then "Enter create/open  Esc back"
			elseif state.mode == "pause" then "Enter confirm destructive pause  Esc cancel"
			elseif state.mode == "refs" then "Enter open  Space pin  x dismiss  Esc back"
			elseif state.mode == "restore" then "Enter restore  R refresh  Esc back"
			else "↑↓ select  Enter focus/restore  n new  p pause  r restore list  f refs  / search  R refresh  Esc close"
		table.insert(children, ui.text({ ui.span(help, "muted") }))
		if state.loading then table.insert(children, ui.text("Discovering existing Git worktrees…")) end
		if state.busy then table.insert(children, ui.text("Creating on this host…")) end
		if state.message ~= "" then table.insert(children, ui.text({ ui.span(state.message, "warning") })) end
		if state.ref_error then table.insert(children, ui.text({ ui.span(state.ref_error, "warning") })) end
		return { main = ui.col(children) }
	end,
	key = function(state, key, cx)
		if key.name == "escape" then
			if state.busy then state.message = "Creation is running; wait for its result or close this pane."; return true end
			if state.mode == "pause" then state.mode = "list"
			elseif state.mode == "create" or state.mode == "refs" or state.mode == "restore" then state.mode = "list"
			elseif state.mode == "search" then state.mode, state.query = "list", ""
			else state.closed = true; running[cx.pane] = nil; cx:exit(0) end
			state.message = ""
			return true
		end
		if state.busy then return false end
		if state.mode == "create" or state.mode == "search" then
			if key.name == "enter" then enter(state); return true end
			if state.mode == "create" and state.path then return false end
			local field = if state.mode == "create" then "branch" else "query"
			if state.mode == "search" and (key.name == "up" or key.name == "down") then
				move(state, key.name == "up" and -1 or 1)
				return true
			end
			if key.name == "backspace" then
				local text = state[field]
				state[field] = text:sub(1, (text:match(".*()[^\128-\191][\128-\191]*$") or (#text + 1)) - 1)
			elseif key.text and key.text ~= "" and not key.ctrl and not key.alt and not key.meta then
				if key.text:find("[\r\n%z]") then state.message = "Use one line of text."; return true end
				state[field] ..= key.text
			else return false end
			state.message = ""
			return true
		end
		if key.name == "up" or key.name == "down" then move(state, key.name == "up" and -1 or 1); return true end
		if key.name == "enter" then
			if state.mode == "pause" then
				local row = selected(state)
				if row and row.session and not row.record then
					state.pending_pause = row.key
					link(cx, "pause", { path = row.key, branch = row.item.branch })
					state.message = "Requesting a session snapshot; session stays open until saved."
				else state.message = "Select an active session to pause." end
				state.mode = "list"
			else enter(state) end
			return true
		end
		if key.ctrl or key.alt or key.meta then return false end
		if state.mode == "refs" then
			local row = selected(state)
			if not row then return false end
			if key.name == "space" or key.text == " " or key.text == "x" then
				local action = if key.text == "x" then refs.dismiss else refs.pin
				local ok, result = pcall(action, state.ref_path, row.key)
				state.message = if not ok then "Could not update reference: " .. tostring(result)
					elseif not result then "Reference changed; press R to refresh." else ""
				return true
			end
			if key.text == "R" then load(state); return true end
			return false
		end
		if state.mode == "pause" then return false end
		if key.text == "r" then load(state); state.mode, state.cursor = "restore", nil; return true end
		if key.text == "R" then if load(state) then bootstrap(state) end; return true end
		if state.mode == "restore" then return false end
		if key.text == "n" then
			state.mode, state.cursor, state.message = "create", nil, "Enter a branch name."
			state.branch, state.path, state.created_mode = "", nil, nil
			cx:frame({ { "focus", "main.input" } })
			return true
		end
		if key.text == "/" then state.mode, state.query = "search", ""; cx:frame({ { "focus", "main.input" } }); return true end
		local row = selected(state)
		if not row then return false end
		if key.text == "p" then
			if row.record then state.message = "Already paused; press Enter to restore it."
			elseif row.session then state.mode, state.message = "pause", ""
			else state.message = "No matching active session at launch; reopen the manager to refresh sessions." end
			return true
		end
		if key.text == "f" then state.ref_path, state.cursor, state.mode = row.key, nil, "refs"; state.message = ""; return true end
		return false
	end,
	event = function(state, ev, cx)
		if ev.ev == "select" or ev.ev == "activate" then
			local key = type(ev.item) == "string" and ev.item:match("^main%.rows%.(.+)$")
			if key then
				for _, row in ipairs(rows(state)) do
					if row.key == key then
						state.cursor = key
						if ev.ev == "activate" and state.mode ~= "pause" then enter(state) end
						return
					end
				end
			end
			return
		end
		if ev.ev ~= "action" or ev.id ~= "main.bridge" or type(ev.value) ~= "string" then return end
		if ev.act == "pause_snapshot" then
			local ok, payload = pcall(tern.json.decode, ev.value)
			if not ok or type(payload) ~= "table" or not valid_path(payload.path)
				or state.pending_pause ~= payload.path or not worktree(state, payload.path)
				or not valid_record(payload.record, payload.path) then
				state.message = "Invalid pause snapshot; session was not closed."
				return
			end
			local session = active_session(state, payload.path)
			if not session or payload.record.name ~= session.name or payload.session_id ~= session.id then
				state.message = "Session changed; reopen Workstreams before pausing."
				return
			end
			local stored, err = pcall(function()
				local paused = tern.kv.get("paused_workstreams") or {}
				if type(paused) ~= "table" then error("invalid paused records") end
				paused[payload.path] = payload.record
				tern.kv.set("paused_workstreams", paused)
				state.paused = paused
			end)
			if stored then
				state.pending_pause = nil
				state.message = "Snapshot saved; waiting for this window to close the session."
				link(cx, "paused", { path = payload.path, session_id = session.id })
			else
				state.message = "Could not save snapshot; session remains open: " .. tostring(err)
			end
		elseif ev.act == "restore_complete" then
			local path = ev.value
			if not valid_path(path) then state.message = "Invalid restore acknowledgement."; return end
			local stored, err = pcall(function()
				local paused = tern.kv.get("paused_workstreams") or {}
				if type(paused) ~= "table" then error("invalid paused records") end
				if paused[path] == nil then return end
				paused[path] = nil
				tern.kv.set("paused_workstreams", paused)
				state.paused = paused
			end)
			state.message = stored and "Restored session confirmed; paused snapshot cleared."
				or "Session restored but snapshot could not be cleared: " .. tostring(err)
		end
	end,
	save = function(state)
		return { cwd = state.cwd, mode = state.mode, ref_path = state.ref_path, pending_pause = state.pending_pause,
			branch = state.branch, path = state.path, created_mode = state.created_mode,
			query = state.query, cursor = state.cursor }
	end,
}
