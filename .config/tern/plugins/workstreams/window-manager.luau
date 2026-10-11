--!strict

local lifecycle = require("./lifecycle")

local pending = {}
local request_host, show_workstreams

local function focused_pane(cx)
	local focused = cx.session:focused()
	for _, pane in cx.session:panes() do
		if pane.pane == focused then return focused, pane.cwd or "" end
	end
	return focused, ""
end

local function open_manager(cx, mode, branch)
	local _, cwd = focused_pane(cx)
	local host = cx.hosts:current()
	local sessions = {}
	local by_id = {}
	for _, session in cx.sessions:list() do
		if session.host == host.id then
			local row = { id = session.id, name = session.name, tabs = {} }
			sessions[#sessions + 1] = row
			by_id[session.id] = row
		end
	end
	for _, tab in cx.session:tabs() do
		local row = by_id[tab.session]
		if row then
			row.tabs[#row.tabs + 1] = { name = tab.name, cwd = tab.cwd, position = tab.position }
		end
	end
	local args = { cwd, mode, tern.json.encode({ sessions = tern.json.array(sessions) }), branch }
	if cx:new_block("workstreams.manager", args, "beside") == nil then
		cx:toast("error", "Install the Workstreams plugin on this host")
	end
end

local function open_picker(cx, mode)
	if not cx.pick then open_manager(cx, mode or "list"); return end
	request_host(cx, "picker", nil, function(data, cx, request)
		show_workstreams(cx, data.items, mode or "list", request.host, request.cwd)
	end)
end

local function prompt_create(cx)
	if not cx.prompt then open_manager(cx, "create"); return end
	cx:prompt({ placeholder = "feature/short-name", icon = "branch", action = "create" }):next(function(branch, err, cx)
		if err then cx:toast("error", "Could not ask for a branch", tostring(err)); return end
		if branch ~= nil then
			local _, cwd = focused_pane(cx)
			local ok, pane = pcall(function()
				return cx.layout:new_tab({ block = "workstreams.manager", args = { cwd, "create", "{}", branch } })
			end)
			if not ok or not pane then
				cx:toast("error", "Could not start workstream creation", if ok then "Install it on this host." else tostring(pane))
			end
		end
	end)
end

tern.command({
	id = "open",
	title = "Workstreams",
	icon = "branch",
	run = function(cx) open_picker(cx) end,
})

tern.command({
	id = "create",
	title = "Create workstream",
	icon = "branch",
	keys = { "ctrl+a>shift+w" },
	run = function(cx) prompt_create(cx) end,
})

tern.command({
	id = "pause",
	title = "Pause workstream",
	icon = "pause",
	keys = { "ctrl+a>shift+z" },
	run = function(cx) open_picker(cx, "pause") end,
})

tern.command({
	id = "restore",
	title = "Restore workstream",
	icon = "history",
	run = function(cx) open_picker(cx, "restore") end,
})

tern.command({
	id = "refs",
	title = "Workstream references",
	icon = "link",
	keys = { "ctrl+a>shift+f" },
	run = function(cx) open_picker(cx, "refs") end,
})

local function valid_worktree(data)
	return type(data) == "table" and type(data.branch) == "string" and data.branch ~= ""
		and type(data.path) == "string" and data.path:sub(1, 1) == "/"
end

local function focus_worktree(cx, item)
	local session = lifecycle.find(cx, item.path, item.branch)
	if session then cx.sessions:switch(session)
	else cx.sessions:create({ name = item.branch, cwd = item.path }) end
end

local function matching_session(cx, item, host)
	local tabs = {}
	for _, tab in cx.session:tabs() do
		if tab.cwd == item.path or (type(tab.cwd) == "string" and tab.cwd:sub(1, #item.path + 1) == item.path .. "/") then
			tabs[tab.session] = true
		end
	end
	local found = nil
	for _, session in cx.sessions:list() do
		if session.host == host and session.name == item.branch and tabs[session.id] then
			if found then error("More than one Tern session matches this workstream") end
			found = session.id
		end
	end
	return found
end

local function close_form(cx, pane)
	local ok, err = pcall(function() cx.layout:close(pane) end)
	if not ok then
		tern.log.warn("Workstream session changed but the manager stayed open", err)
	end
	return ok
end

request_host = function(cx, mode, data, callback)
	local focused, cwd = focused_pane(cx)
	local args = { cwd, mode }
	if data then args[3] = tern.json.encode(data) end
	local ok, pane = pcall(function()
		return cx.layout:new_tab({ block = "workstreams.manager", args = args })
	end)
	if not ok or not pane then
		cx:toast("error", "Could not reach the host Workstreams plugin", if ok then "Install it on this host." else tostring(pane))
		return
	end
	pending[pane] = { host = cx.hosts:current().id, session = cx.sessions:current().id,
		focused = focused, cwd = cwd, kind = data and data.kind, callback = callback }
end

local function same_host(cx, host)
	local ok, current = pcall(function() return cx.hosts:current().id end)
	if ok and current == host then return true end
	cx:toast("error", "Host changed; open Workstreams again")
	return false
end

local show_refs

local function pause_workstream(cx, item, host)
	if not same_host(cx, host) then return end
	local found, session = pcall(matching_session, cx, item, host)
	if not found then cx:toast("error", "Could not choose a session to pause", tostring(session)); return end
	if not session then cx:toast("error", "No active session belongs to this workstream"); return end
	cx:pick({ placeholder = "Pause " .. item.branch .. "?", icon = "pause", action = "confirm", items = {
		{ label = "Pause and close session", detail = "Running programs stop; restore reopens the tabs", confirm = true },
		{ label = "Cancel", confirm = false },
	} }):next(function(choice, err, cx)
		if err then cx:toast("error", "Could not confirm pause", tostring(err)); return end
		if not choice or not choice.confirm or not same_host(cx, host) then return end
		local unchanged, current = pcall(matching_session, cx, item, host)
		if not unchanged or current ~= session then
			cx:toast("error", "Session changed; open Workstreams again")
			return
		end
		local captured, record = pcall(lifecycle.capture, cx, session, item.path)
		if not captured then cx:toast("error", "Could not save session tabs", tostring(record)); return end
		request_host(cx, "rpc", { kind = "pause", path = item.path, branch = item.branch,
			record = record, session_id = session }, function(reply, cx)
			if not same_host(cx, host) then return end
			local unchanged, current = pcall(matching_session, cx, item, host)
			if reply.path ~= item.path or reply.session_id ~= session or not unchanged or current ~= session then
				cx:toast("error", "Snapshot saved, but the session changed and stayed open")
				return
			end
			local closed, close_err = pcall(function()
				local count = 0
				for _, active in cx.sessions:list() do
					if active.host == host then count += 1 end
				end
				if count == 1 then cx.sessions:create() end
				cx.sessions:close(session)
			end)
			if closed then cx:toast("success", "Workstream paused", item.path)
			else cx:toast("error", "Snapshot saved, but the session stayed open", tostring(close_err)) end
		end)
	end)
end

local function restore_workstream(cx, item, host)
	if not same_host(cx, host) then return end
	request_host(cx, "rpc", { kind = "restore", path = item.path }, function(reply, cx)
		if not same_host(cx, host) then return end
		if type(reply.record) ~= "table" or reply.record.path ~= item.path then
			cx:toast("error", "Paused snapshot changed; open Workstreams again")
			return
		end
		local restored, restore_err = pcall(lifecycle.restore, cx, reply.record)
		if not restored then cx:toast("error", "Could not restore workstream", tostring(restore_err)); return end
		request_host(cx, "rpc", { kind = "restored", path = item.path, record = reply.record }, function(_, cx)
			cx:toast("success", "Workstream restored", item.path)
		end)
	end)
end

show_refs = function(cx, item, host)
	if not same_host(cx, host) then return end
	request_host(cx, "rpc", { kind = "refs", path = item.path }, function(reply, cx)
		if type(reply.refs) ~= "table" then cx:toast("error", "Invalid host references"); return end
		local choices = {}
		for _, ref in ipairs(reply.refs) do
			if type(ref) == "table" and not ref.dismissed and type(ref.kind) == "string" and type(ref.id) == "string" then
				choices[#choices + 1] = { label = ref.kind .. ":" .. ref.id .. "  " .. tostring(ref.url or ""),
					detail = ref.pinned and "pinned" or "", icon = "link",
					refkey = ref.kind .. ":" .. ref.id, url = ref.url, pinned = ref.pinned }
			end
		end
		choices[#choices + 1] = { label = "Refresh references", group = "Actions", action = "refresh" }
		cx:pick({ placeholder = "References · " .. item.branch, icon = "link", items = choices }):next(function(ref, err, cx)
			if err then cx:toast("error", "Could not choose a reference", tostring(err)); return end
			if not ref or not same_host(cx, host) then return end
			if ref.action == "refresh" then show_refs(cx, item, host); return end
			local actions = {
				{ label = ref.pinned and "Unpin reference" or "Pin reference", action = "pin" },
				{ label = "Dismiss reference", action = "dismiss" },
				{ label = "Back to references", action = "back" },
			}
			if type(ref.url) == "string" and (ref.url:match("^https?://") or ref.url:match("^file:///")) then
				table.insert(actions, 1, { label = "Open reference", action = "open" })
			end
			cx:pick({ placeholder = ref.refkey, icon = "link", items = actions }):next(function(action, action_err, cx)
				if action_err then cx:toast("error", "Could not choose a reference action", tostring(action_err)); return end
				if not action or not same_host(cx, host) then return end
				if action.action == "open" then cx:open(ref.url)
				elseif action.action == "back" then show_refs(cx, item, host)
				else
					request_host(cx, "rpc", { kind = action.action, path = item.path, refkey = ref.refkey }, function(_, cx)
						show_refs(cx, item, host)
					end)
				end
			end)
		end)
	end)
end


show_workstreams = function(cx, raw, mode, host, cwd)
	if not same_host(cx, host) then return end
	if type(raw) ~= "table" then cx:toast("error", "Invalid host workstream list"); return end
	local worktrees = {}
	for _, row in ipairs(raw) do
		if valid_worktree(row) then
			local session = lifecycle.find(cx, row.path, row.branch)
			local status = row.paused and "paused" or session and "active" or "checkout"
			local terms = type(row.search) == "string" and row.search or ""
			worktrees[#worktrees + 1] = { label = row.branch .. "  [" .. status .. "]  " .. row.path .. "  " .. terms,
				detail = type(row.repo) == "string" and row.repo:match("([^/]+)$") or "",
				group = "Workstreams", icon = "branch", branch = row.branch, path = row.path,
				paused = row.paused, session = session }
		end
	end
	if mode == "refs" and type(cwd) == "string" then
		local focused = nil
		for _, item in ipairs(worktrees) do
			if cwd == item.path or cwd:sub(1, #item.path + 1) == item.path .. "/" then
				if not focused or #item.path > #focused.path then focused = item end
			end
		end
		if focused then show_refs(cx, focused, host); return end
	end
	local items = {}
	for _, item in ipairs(worktrees) do
		if mode == "list" or mode == "refs" or (mode == "pause" and item.session and not item.paused)
			or (mode == "restore" and item.paused) then
			items[#items + 1] = item
		end
	end
	if mode == "list" then
		items[#items + 1] = { label = "Create workstream", group = "Actions", action = "create" }
		items[#items + 1] = { label = "Pause workstream session", group = "Actions", action = "pause" }
		items[#items + 1] = { label = "Restore paused workstream", group = "Actions", action = "restore" }
		items[#items + 1] = { label = "Workstream references", group = "Actions", action = "refs" }
	end
	if #items == 0 then
		cx:toast("info", if mode == "pause" then "No active workstream sessions"
			elseif mode == "restore" then "No paused workstreams" else "No workstreams on this host")
		return
	end
	local placeholder = if mode == "pause" then "Pause workstream"
		elseif mode == "restore" then "Restore workstream"
		elseif mode == "refs" then "Choose workstream references" else "Search workstreams"
	cx:pick({ placeholder = placeholder, icon = "branch", items = items, action = "open" }):next(function(choice, err, cx)
		if err then cx:toast("error", "Could not pick a workstream", tostring(err)); return end
		if not choice or not same_host(cx, host) then return end
		if choice.action == "create" then prompt_create(cx)
		elseif choice.action then show_workstreams(cx, raw, choice.action, host, "")
		elseif mode == "pause" then pause_workstream(cx, choice, host)
		elseif mode == "refs" then show_refs(cx, choice, host)
		elseif mode == "restore" or choice.paused then restore_workstream(cx, choice, host)
		else
			local opened, message = pcall(focus_worktree, cx, choice)
			if opened then cx:toast("success", "Workstream ready", choice.path)
			else cx:toast("error", "Could not open workstream", tostring(message) .. " · " .. choice.path) end
		end
	end)
end


tern.route.link(function(link, cx)
	local act, encoded = link.url:match("^tern%-workstreams://([%w_]+)/(.+)$")
	if not act then
		return nil
	end
	local pane = link.pane and cx.session:pane(link.pane)
	if pane == nil or pane.block ~= "workstreams.manager" then
		cx:toast("error", "The workstream manager is no longer in this session", "Return to it and retry the action.")
		return { handled = true }
	end
	local decoded = encoded:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
	local ok, data = pcall(tern.json.decode, decoded)
	if not ok or type(data) ~= "table" then
		cx:toast("error", "Workstream request is invalid")
		return { handled = true }
	end

	if act == "picker" or act == "reply" then
		local request = pending[link.pane]
		pending[link.pane] = nil
		if not close_form(cx, link.pane) then return { handled = true } end
		if not request or request.host ~= cx.hosts:current().id or request.session ~= cx.sessions:current().id then
			cx:toast("info", "The workstream request expired", "Open it again in this session.")
			return { handled = true }
		end
		if request.focused and cx.session:pane(request.focused) then cx.layout:focus(request.focused) end
		if type(data.error) == "string" then cx:toast("error", "Could not update workstream", data.error); return { handled = true } end
		if act == "reply" and data.kind ~= request.kind then
			cx:toast("error", "Invalid host workstream reply")
			return { handled = true }
		end
		if act == "picker" and type(data.warning) == "string" then cx:toast("info", data.warning) end
		request.callback(data, cx, request)
		return { handled = true }
	end

	if act == "created" or act == "focus" then
		if not valid_worktree(data) or (act == "created" and data.mode ~= "git" and data.mode ~= "overlay" and data.mode ~= "existing") then
			cx:toast("error", "Workstream result is invalid")
			return { handled = true }
		end
		local succeeded, err = pcall(focus_worktree, cx, data)
		if succeeded then
			close_form(cx, link.pane)
			cx:toast("success", "Workstream ready", data.path)
		else
			cx:toast("error", "Worktree is ready; session creation failed", tostring(err) .. " · " .. data.path)
		end
		return { handled = true }
	end

	if act == "pause" then
		if not valid_worktree(data) then
			cx:toast("error", "Pause request is invalid")
			return { handled = true }
		end
		local succeeded, err = pcall(function()
			local session_id = matching_session(cx, data, cx.hosts:current().id)
			if session_id == nil then error("No Tern session belongs to this worktree") end
			local record = lifecycle.capture(cx, session_id, data.path)
			cx.session:event(link.pane, {
				ev = "action", id = "main.bridge", act = "pause_snapshot",
				value = tern.json.encode({ path = data.path, session_id = session_id, record = record }),
			})
		end)
		if not succeeded then cx:toast("error", "Could not pause workstream", tostring(err)) end
		return { handled = true }
	end

	if act == "paused" then
		if type(data.path) ~= "string" or type(data.session_id) ~= "number" then
			cx:toast("error", "Pause confirmation is invalid")
			return { handled = true }
		end
		local succeeded, err = pcall(function()
			local target = nil
			for _, session in cx.sessions:list() do
				if session.id == data.session_id and session.host == cx.hosts:current().id then
					target = session
					break
				end
			end
			if not target then error("Session changed; the saved pause record remains available") end
			local host_sessions = 0
			for _, session in cx.sessions:list() do
				if session.host == target.host then host_sessions += 1 end
			end
			if host_sessions == 1 then
				cx.sessions:create()
			end
			cx.sessions:close(target.id)
		end)
		if not succeeded then
			cx:toast("error", "Pause was saved, but the session stayed open", tostring(err))
		else
			cx:toast("success", "Workstream paused", data.path)
		end
		return { handled = true }
	end

	if act == "restore" then
		if type(data.record) ~= "table" then
			cx:toast("error", "Restore request is invalid")
			return { handled = true }
		end
		local succeeded, err = pcall(function()
			lifecycle.restore(cx, data.record)
			cx.session:event(link.pane, {
				ev = "action", id = "main.bridge", act = "restore_complete",
				value = tern.json.encode({ path = data.record.path, record = data.record }),
			})
		end)
		if not succeeded then
			cx:toast("error", "Could not restore workstream", tostring(err))
		else
			close_form(cx, link.pane)
			cx:toast("success", "Workstream restored", data.record.path)
		end
		return { handled = true }
	end
	return nil
end)
