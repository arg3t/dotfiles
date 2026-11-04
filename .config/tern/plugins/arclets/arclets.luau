-- The Arclets section of the sidebar: state, the `arclet` and `tern remote setup` runs, Tern
-- host connections, profiles and auto-start. window.luau calls init, section, setSection,
-- model, action and autostart; everything here runs in the window, under its 50 ms callback
-- budget, so all slow work is a process whose callback updates state and calls redraw().
local common = require("./common")
local AV = require("./arclets_view")
local M = AV.M

local A = {}

local AUTOSTART = true -- start every stopped Arclet when a Tern window opens
local AUTOSTART_GAP_S = 600 -- window_start runs once per window; skip repeats within this gap
local REFRESH_MS = 60000
local SETUP_POLL_MS = 400

-- `tern remote setup`'s progress lines, in order, after our first step.
local SETUP_STEPS = {
	{ label = "Logging in over SSH", line = "Logging in over SSH" },
	{ label = "Looking around", line = "Looking around" },
	{ label = "Installing Tern", line = "Installing Tern" },
	{ label = "Starting Tern's service", line = "Starting Tern's service" },
	{ label = "Finding the way there", line = "Finding the way there" },
	{ label = "Checking Tern's service" },
	{ label = "Connecting this window" },
}

local hooks = { redraw = function() end, later = function(ms, fn) tern.timer(ms, fn) end }
local S = {
	arclets = {}, -- from `arclet list --json`, by name
	saved = {}, -- Arclet name -> true when `tern remote hosts` lists arclet_<name>.ssh
	busy = {}, -- Arclet name -> what runs on it
	ops = {}, -- id -> op; an op is a create or setup shown as a card
	opOrder = {},
	err = nil,
	at = nil,
	loading = false,
}
local opSeq = 0

local function redraw() hooks.redraw() end

local function alias(name) return "arclet_" .. name .. ".ssh" end

local function nameOfAlias(host) return type(host) == "string" and host:match("^arclet_([a-z0-9-]+)%.ssh$") or nil end

local function refresh()
	if S.loading then return end
	S.loading = true
	redraw()
	local pending = 2
	local function done()
		pending -= 1
		if pending == 0 then
			S.loading, S.at = false, os.time()
			redraw()
		end
	end
	common.arclet({ "list", "--json" }, 60000, function(r)
		local list, err = common.parse_list(r)
		S.err = err
		if list then
			table.sort(list, function(a, b) return a.name < b.name end)
			S.arclets = list
		end
		done()
	end)
	common.cli({ "tern", "remote", "hosts" }, 10000, function(r)
		local saved = {}
		for name in r.stdout:gmatch("\tarclet_([a-z0-9-]+)%.ssh") do saved[name] = true end
		S.saved = saved
		done()
	end)
end

local function poll()
	refresh()
	hooks.later(REFRESH_MS, function() poll() end)
end

local function find(name)
	for _, a in S.arclets do
		if a.name == name then return a end
	end
	return nil
end

local function connectedHost(cx, name)
	for _, h in cx.hosts:list() do
		if h.kind == "remote" and h.state == "connected" and h.name == alias(name) then return h end
	end
	return nil
end

-- A new setup of the same Arclet gets a new address; forget the dead old entries.
local function forgetStale(cx, keep, name)
	for _, h in cx.hosts:list() do
		if h.kind == "remote" and h.name == alias(name) and h.id ~= keep and h.state ~= "connected" then
			pcall(cx.hosts.disconnect, cx.hosts, h.id)
		end
	end
end

-- Ops ----------------------------------------------------------------------------------------

local function newOp(id, title, first, withSetup, note)
	local steps = { { label = first, detail = note } }
	if withSetup then
		for _, s in SETUP_STEPS do table.insert(steps, { label = s.label, line = s.line }) end
	end
	local op = { id = id, title = title, steps = steps, step = 1, finished = false }
	if not S.ops[id] then table.insert(S.opOrder, id) end
	S.ops[id] = op
	return op
end

local function dropOp(id)
	S.ops[id] = nil
	for i, x in S.opOrder do
		if x == id then table.remove(S.opOrder, i) break end
	end
end

local function finish(cx, op, err, title, sub)
	op.finished, op.err = true, err
	if op.name then S.busy[op.name] = nil end
	if err then
		common.notify(cx, "error", "Failed: " .. op.title, err)
	else
		op.step = #op.steps + 1
		if title then common.notify(cx, "success", title, sub) end
		hooks.later(4000, function()
			if S.ops[op.id] == op then dropOp(op.id); redraw() end
		end)
	end
	refresh()
	redraw()
end

-- Reads the whole setup log: a progress line starts a step, an indented line is a note on it.
local function readLog(op, path, first)
	local ok, text = pcall(tern.fs.read, path, 256 * 1024)
	if not ok then return nil end
	local cur = first
	for line in text:gmatch("[^\n]+") do
		local noteText = line:match("^  (%S.*)$") -- `tern remote setup` indents notes by two spaces
		if noteText then
			op.steps[cur].detail = noteText:sub(1, 200)
		else
			for i = first, #op.steps do
				local want = op.steps[i].line
				if want and line:sub(1, #want) == want then cur = i end
			end
		end
	end
	op.step = math.max(op.step, cur)
	return text
end

-- Tern's files on an Arclet can be replaced while its service runs (seen right after an Arclet
-- starts); the service then runs a deleted program and cannot start a session ("the session
-- could not start as …: No such file or directory"), because it starts the session daemon from
-- its own program's path. Restart a service whose program is gone.
local CHECK_SERVICE = 'p=$(systemctl --user show -p MainPID --value tern-remote 2>/dev/null); '
	.. 'case "$(readlink /proc/$p/exe 2>/dev/null)" in '
	.. '*"(deleted)") systemctl --user restart tern-remote && sleep 2 && echo restarted ;; '
	.. '*) echo ok ;; esac'

local function checkService(name, cb: (detail: string, cx: any) -> ())
	common.cli({ "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=20", alias(name), CHECK_SERVICE }, 60000, function(r, c)
		if r.status ~= 0 then
			cb("could not check: " .. common.why(r), c)
		elseif r.stdout:find("restarted", 1, true) then
			cb("restarted it (its program had been replaced)", c)
		else
			cb("running", c)
		end
	end)
end

-- `cx.hosts:add` on the address setup printed. `add` shows the new host; without `go`, the
-- previous host comes back. A session that cannot start gets one service check and retry.
local function connectHost(cx, op, name, go, address, retried)
	op.step = #op.steps
	redraw()
	if not cx then return finish(cx, op, "the window closed before it could connect") end
	local before = cx.hosts:current().id
	local ok, err = pcall(function()
		cx.hosts:add(address):next(function(added, err2, c)
			if (err2 or not added) and not retried and tostring(err2):find("could not start", 1, true) then
				op.step = #op.steps - 1
				redraw()
				return checkService(name, function(detail, c2)
					op.steps[#op.steps - 1].detail = detail
					connectHost(c2, op, name, go, address, true)
				end)
			end
			if err2 or not added then
				return finish(c, op, err2 or "no host")
			end
			if c then
				forgetStale(c, added.id, name)
				if go then c.hosts:switch(added.id) else pcall(c.hosts.switch, c.hosts, before) end
			end
			finish(c, op, nil, (if go then "Connected to " else "Added ") .. alias(name) .. (if go then "" else " as a Tern host"))
		end)
	end)
	if not ok then finish(cx, op, tostring(err)) end
end

-- `tern remote setup` with its output in a log polled for the steps, then the service check,
-- then the connection.
local function runSetup(op, name, go)
	local first = op.step
	local log = tern.plugin.data .. "/setup-" .. name .. ".log"
	pcall(tern.fs.remove, log)
	local running = true
	local function tick()
		if not running then return end
		readLog(op, log, first)
		redraw()
		hooks.later(SETUP_POLL_MS, tick)
	end
	common.cli({ "sh", "-c", 'exec tern remote setup "$1" >"$2" 2>&1', "sh", alias(name), log }, 300000, function(r, cx)
		running = false
		local text = readLog(op, log, first) or ""
		local address = text:match("\nAdded %S+ %(([^)]+)%) to your hosts")
		if r.status ~= 0 or not address then
			local last = (text:gsub("%s+$", "")):match("([^\n]*)$")
			op.steps[op.step].detail = nil
			return finish(cx, op, if r.timed_out then "timed out" else (last ~= "" and last or "tern remote setup failed"))
		end
		op.step = #op.steps - 1
		redraw()
		checkService(name, function(detail, c2)
			op.steps[#op.steps - 1].detail = detail
			connectHost(c2, op, name, go, address)
		end)
	end)
	tick()
end

-- Start the Arclet, then set it up as a Tern host and connect this window.
local function setup(cx, name, go)
	local existing = S.ops[name]
	if existing and not existing.finished then
		return common.notify(cx, "info", "Wait for " .. existing.title)
	end
	local op = newOp(name, "Set up " .. alias(name), "Starting the Arclet", true)
	op.name = name
	S.busy[name] = "setting up…"
	redraw()
	common.arclet({ "resume", name, "--no-connect", "--no-await" }, 600000, function(r, c)
		if r.status ~= 0 then return finish(c, op, common.why(r)) end
		op.step = 2
		redraw()
		runSetup(op, name, go)
	end)
end

-- Click on an Arclet: show its connected host, else set it up (a fresh setup also fixes a
-- saved host whose address changed).
local function go(cx, name)
	local h = connectedHost(cx, name)
	if h then
		forgetStale(cx, h.id, name)
		cx.hosts:switch(h.id)
	else
		setup(cx, name, true)
	end
end

-- Start or stop. A started Arclet whose Tern host is saved but not connected is set up again,
-- so its host comes back with it.
local function toggle(cx, name)
	local a = find(name)
	if not a or S.busy[name] then return end
	local starting = a.state == "STOPPED"
	S.busy[name] = if starting then "starting…" else "stopping…"
	redraw()
	local args = if starting then { "resume", name, "--no-connect", "--no-await" } else { "stop", name }
	common.arclet(args, 600000, function(r, c)
		S.busy[name] = nil
		if r.status ~= 0 then
			common.notify(c, "error", "Could not " .. (if starting then "start " else "stop ") .. name, common.why(r))
		else
			common.notify(c, "success", (if starting then "Started " else "Stopped ") .. name)
			if starting and c and S.saved[name] and not connectedHost(c, name) then setup(c, name, false) end
		end
		refresh()
	end)
end

local function startAll(cx, quiet)
	local n = 0
	for _, a in S.arclets do
		if a.state == "STOPPED" then
			n += 1
			toggle(cx, a.name)
		end
	end
	if n == 0 and not quiet then common.notify(cx, "info", "No stopped Arclets") end
end

local function shell(cx, name)
	local ok, err = pcall(function()
		-- The login shell keeps the tab open after `arclet resume` exits, so errors stay readable.
		cx.hosts:terminal("local", { command = "arclet resume " .. name .. '; exec "$SHELL" -l' })
	end)
	if not ok then common.notify(cx, "error", "Could not open a tab", tostring(err)) end
end

-- `arclet new` with a profile's flags, then (when the profile says so) the setup.
local function create(cx, name, profile)
	local host = profile ~= nil and profile.host
	opSeq += 1
	local id = if name ~= "" then name else "new" .. tostring(opSeq)
	if S.ops[id] and not S.ops[id].finished then return common.notify(cx, "info", "Wait for " .. S.ops[id].title) end
	local label = if name ~= "" then name else "a new Arclet"
	local op = newOp(id, "Create " .. label, "Creating the Arclet", host,
		(if profile then common.describe(profile) .. ". " else "") .. "This can take a few minutes.")
	if name ~= "" then
		op.name = name
		S.busy[name] = "creating…"
	end
	redraw()
	local args = { "new" }
	if name ~= "" then table.insert(args, name) end
	for _, a in { "--no-connect", "--no-await", "--json" } do table.insert(args, a) end
	if profile then
		for _, a in common.profile_args(profile) do table.insert(args, a) end
	end
	common.arclet(args, 900000, function(r, c)
		if r.status ~= 0 then return finish(c, op, common.why(r)) end
		-- With no name given, `arclet` picks one; read it from the JSON when it is there.
		local ok, data = pcall(tern.json.decode, r.stdout)
		local made = ok and type(data) == "table" and ((type(data.arclet) == "table" and data.arclet.name) or data.name) or nil
		local final = if type(made) == "string" and made:match(common.NAME) then made else name
		if not host then
			return finish(c, op, nil, "Created " .. (if final ~= "" then final else "a new Arclet"))
		end
		op.name, op.title = final, "Create " .. final
		S.busy[final] = "setting up…"
		op.step = 2
		redraw()
		runSetup(op, final, false)
	end)
end

-- Pick a profile, then a name.
local function newArclet(cx)
	local profiles, problems = common.load_profiles()
	for _, problem in problems do
		cx:toast("error", problem, "Fix it in " .. tern.plugin.dir .. "/profiles.json")
	end
	local items = {}
	for _, p in profiles do
		table.insert(items, { label = p.name, detail = common.describe(p), current = p.default, profile = p })
	end
	table.insert(items, { label = "arclet defaults", detail = "no profile" })
	cx:pick({ items = items, placeholder = "Profile for the new Arclet", icon = "plus", action = "use" }):next(function(item, _, c)
		if not item or not c then return end
		local p = item.profile
		local host = p ~= nil and p.host
		c:prompt({ placeholder = if host then "Arclet name" else "Arclet name (empty: random)", icon = "plus", action = "create" })
			:next(function(name, _, c2)
				if name == nil or not c2 then return end
				if name == "" and host then
					return c2:toast("error", "Give the Arclet a name", "The profile adds it as a Tern host.")
				end
				if name ~= "" and not name:match(common.NAME) then
					return c2:toast("error", "Bad Arclet name", "Use lowercase letters, digits and -.")
				end
				tern.kv.set("section", "arclets")
				create(c2, name, p)
			end)
	end)
end

-- Public -------------------------------------------------------------------------------------

function A.init(h)
	hooks = h
	poll()
end

function A.section()
	return if tern.kv.get("section") == "arclets" then "arclets" else "workspaces"
end

function A.setSection(section)
	tern.kv.set("section", section)
	if section == "arclets" then refresh() end
end

-- An Arclet host's first session is called "Default"; name it after the Arclet. Once per
-- connected host (until the plugin reloads), so a later rename of yours stays.
local named = {} -- host id -> true once its sessions were looked at
function A.nameSessions(cx)
	local hosts = {}
	for _, h in cx.hosts:list() do
		local n = h.kind == "remote" and h.state == "connected" and not named[h.id] and nameOfAlias(h.name)
		if n then hosts[h.id] = n end
	end
	if next(hosts) == nil then return end
	for _, s in cx.sessions:list() do
		local n = hosts[s.host]
		if n then
			named[s.host] = true
			if s.name == "Default" then
				local ok, err = pcall(cx.sessions.rename, cx.sessions, s.id, n)
				if not ok then tern.log.warn("arclets: cannot rename session", n, err) end
			end
		end
	end
end

-- Plain data for the view (JSON-encodable: the draw diffs its signature).
function A.model(cx)
	local connected = {}
	for _, h in cx.hosts:list() do
		local n = h.kind == "remote" and h.state == "connected" and nameOfAlias(h.name)
		if n then connected[n] = true end
	end
	local rows = {}
	for _, a in S.arclets do
		table.insert(rows, {
			name = a.name, state = a.state, region = a.region, branch = a.branch,
			busy = S.busy[a.name], saved = S.saved[a.name] == true, connected = connected[a.name] == true,
		})
	end
	local ops = {}
	for _, id in S.opOrder do
		local op = S.ops[id]
		local steps = {}
		for i, s in op.steps do
			local status = if i < op.step then "done" elseif i == op.step then (if op.err then "fail" else "run") else "todo"
			table.insert(steps, { label = s.label, detail = if status == "fail" then op.err else s.detail, status = status })
		end
		table.insert(ops, { id = op.id, title = op.title, steps = steps, finished = op.finished, err = op.err })
	end
	return {
		arclets = rows, ops = ops, err = S.err, loading = S.loading,
		at = if S.at then os.date("%H:%M:%S", S.at) else nil,
	}
end

-- A canvas click or menu pick; true when it was ours.
function A.action(cx, act, value, label, node)
	if act == "asec" then
		A.setSection(if value == "arclets" then "arclets" else "workspaces")
	elseif act == "arefresh" then refresh()
	elseif act == "anew" then newArclet(cx)
	elseif act == "astartall" then startAll(cx, false)
	elseif act == "adismiss" then dropOp(value)
	elseif act == "ago" or act == "ahost" or act == "ashell" or act == "atoggle" then
		if not (value or ""):match(common.NAME) then return true end
		if act == "ago" then go(cx, value)
		elseif act == "ahost" then setup(cx, value, false)
		elseif act == "ashell" then shell(cx, value)
		else toggle(cx, value) end
	elseif label == M.new then newArclet(cx)
	elseif label == M.startAll then startAll(cx, false)
	elseif label == M.refresh then refresh()
	elseif label == M.go or label == M.setup or label == M.shell or label == M.start or label == M.stop then
		local name = (node or ""):match("%.ar_([a-z0-9%-]+)")
		if not name or not find(name) then return true end
		if label == M.go then go(cx, name)
		elseif label == M.setup then setup(cx, name, false)
		elseif label == M.shell then shell(cx, name)
		else toggle(cx, name) end
	else
		return false
	end
	redraw()
	return true
end

-- Once per Tern launch (window_start runs per window): start every stopped Arclet. The list
-- comes from its own `arclet list`, since the first refresh may still be running.
function A.autostart(cx)
	if not AUTOSTART then return end
	local now = os.time()
	local last = tern.kv.get("autostart_at")
	if type(last) == "number" and now - last < AUTOSTART_GAP_S then return end
	tern.kv.set("autostart_at", now)
	common.arclet({ "list", "--json" }, 60000, function(r, c)
		local list, err = common.parse_list(r)
		if not list then return common.notify(c, "error", "Could not list Arclets", err) end
		S.arclets = list
		startAll(c, true)
	end)
end

A.newArclet = newArclet
A.startAll = function(cx) startAll(cx, false) end

return A
