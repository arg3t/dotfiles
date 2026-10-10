-- Workstreams pause/restore snapshot helper.
-- Parent owns confirmation, host-side kv storage, and session close.
-- ponytail: restore tab labels and cwds only; rebuild split layouts from
--   cx.session:layout() if users need exact pane arrangements.

local lifecycle = {}

-- Returns tabs belonging to `session_id` from the full window tab list.
-- cx.session:tabs() returns all tabs in the window; each tab carries its
-- session id so we can filter without a separate per-session call.
local function session_tabs(cx, session_id)
	local out = {}
	for _, tab in ipairs(cx.session:tabs()) do
		if tab.session == session_id then
			table.insert(out, tab)
		end
	end
	return out
end

-- find(cx, path, name) -> session_id?
-- Returns the id of the first session on the current host whose name matches
-- exactly and which has at least one tab whose cwd equals `path`.
-- Returns nil when no match exists (never raises).
function lifecycle.find(cx, path, name)
	local host = cx.hosts:current()
	for _, sess in ipairs(cx.sessions:list()) do
		if sess.host == host.id and sess.name == name then
			for _, tab in ipairs(session_tabs(cx, sess.id)) do
				if tab.cwd == path or (type(tab.cwd) == "string" and tab.cwd:sub(1, #path + 1) == path .. "/") then
					return sess.id
				end
			end
		end
	end
	return nil
end

-- capture(cx, session_id, path) -> record
-- Snapshot the session into a JSON-safe table:
--   { version=1, name, path, tabs={ {name?, cwd?}, … } }
-- Tabs are sorted by their window position. `path` is the worktree checkout
-- root and is stored verbatim for restore fallback.
-- Raises when the session is unknown, belongs to a different host, or has
-- no tabs visible in the current window.
function lifecycle.capture(cx, session_id, path)
	local host = cx.hosts:current()

	local target = nil
	for _, sess in ipairs(cx.sessions:list()) do
		if sess.id == session_id then
			target = sess
			break
		end
	end
	if not target then
		error("capture: session " .. tostring(session_id) .. " not found")
	end
	if target.host ~= host.id then
		error(
			"capture: session " .. tostring(session_id) ..
			" belongs to host " .. tostring(target.host) ..
			", not current host " .. tostring(host.id)
		)
	end

	local tabs = session_tabs(cx, session_id)
	if #tabs == 0 then
		error("capture: session " .. tostring(session_id) .. " has no tabs in this window")
	end

	table.sort(tabs, function(a, b) return a.position < b.position end)

	local tab_records = {}
	for _, tab in ipairs(tabs) do
		table.insert(tab_records, { name = tab.name, cwd = tab.cwd })
	end

	return { version = 1, name = target.name, path = path, tabs = tab_records }
end

-- restore(cx, record) -> session_id
-- Fully validates the record before any mutation, then either switches to an
-- already-matching session or creates a new one on the current host.
--
-- Creation order:
--   1. cx.sessions:create with first tab cwd (falls back to record.path).
--   2. Name the first tab if record carried a name for it.
--   3. For each remaining tab: new_tab → tab_of → name_tab.
--
-- On tab-creation failure the partially-created session is left in place
-- (parent decides what to do); raises with session id and worktree path so
-- the parent can surface a useful message.
-- Never calls cx.sessions:close; that is the parent's responsibility.
function lifecycle.restore(cx, record)
	-- Validate everything before touching the session list.
	if record.version ~= 1 then
		error("restore: unsupported record version " .. tostring(record.version))
	end
	if type(record.name) ~= "string" or record.name == "" then
		error("restore: record.name must be a non-empty string")
	end
	if type(record.path) ~= "string" or record.path:sub(1, 1) ~= "/" then
		error("restore: record.path must be an absolute path, got " .. tostring(record.path))
	end
	if type(record.tabs) ~= "table" or #record.tabs == 0 then
		error("restore: record.tabs must be a non-empty list")
	end
	for i, t in ipairs(record.tabs) do
		if type(t) ~= "table" then
			error("restore: tabs[" .. i .. "] must be a table")
		end
		if t.name ~= nil and type(t.name) ~= "string" then
			error("restore: tabs[" .. i .. "].name must be a string or nil")
		end
		if t.cwd ~= nil and type(t.cwd) ~= "string" then
			error("restore: tabs[" .. i .. "].cwd must be a string or nil")
		end
		if t.cwd ~= nil and t.cwd ~= "" and t.cwd:sub(1, 1) ~= "/" then
			error("restore: tabs[" .. i .. "].cwd must be an absolute path")
		end
	end

	-- If the session already exists with a matching tab, just switch to it.
	local existing = lifecycle.find(cx, record.path, record.name)
	if existing then
		cx.sessions:switch(existing)
		return existing
	end

	-- Create the session; create() switches to it automatically.
	local first_cwd = record.tabs[1].cwd
	if first_cwd == nil or first_cwd == "" then
		first_cwd = record.path
	end
	local created = cx.sessions:create({ name = record.name, cwd = first_cwd })
	local new_id = created.id

	-- Name the first tab when the record stored one.
	if record.tabs[1].name then
		local tabs = session_tabs(cx, new_id)
		if #tabs > 0 then
			table.sort(tabs, function(a, b) return a.position < b.position end)
			cx.layout:name_tab(tabs[1].id, record.tabs[1].name)
		end
	end

	-- Create remaining tabs; stop and raise on failure, leaving the session.
	for i = 2, #record.tabs do
		local t = record.tabs[i]
		local cwd = t.cwd
		if cwd == nil or cwd == "" then
			cwd = record.path
		end
		local ok, err = pcall(function()
			local pane = cx.layout:new_tab({ cwd = cwd })
			if pane == nil then
				error("Tern could not open a tab")
			end
			local tab_id = cx.session:tab_of(pane)
			if tab_id == nil then
				error("Tern could not find the new tab")
			end
			if t.name then
				cx.layout:name_tab(tab_id, t.name)
			end
		end)
		if not ok then
			error(
				"restore: failed creating tab " .. i ..
				" for session " .. tostring(new_id) ..
				" at " .. record.path .. ": " .. tostring(err)
			)
		end
	end

	return new_id
end

return lifecycle
