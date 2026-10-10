--!strict

local lifecycle = require("./lifecycle")

local function open_manager(cx, mode)
	local focused = cx.session:focused()
	local cwd = ""
	for _, pane in cx.session:panes() do
		if pane.pane == focused then
			cwd = pane.cwd or ""
			break
		end
	end
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
	local args = { cwd, mode, tern.json.encode({ sessions = tern.json.array(sessions) }) }
	if cx:new_block("workstreams.manager", args, "beside") == nil then
		cx:toast("error", "Install the Workstreams plugin on this host")
	end
end

tern.command({
	id = "open",
	title = "Workstreams",
	icon = "branch",
	run = function(cx) open_manager(cx, "list") end,
})

tern.command({
	id = "create",
	title = "Create workstream",
	icon = "branch",
	keys = { "ctrl+a>shift+w" },
	run = function(cx) open_manager(cx, "create") end,
})

tern.command({
	id = "pause",
	title = "Pause workstream",
	icon = "pause",
	keys = { "ctrl+a>shift+z" },
	run = function(cx) open_manager(cx, "pause") end,
})

tern.command({
	id = "restore",
	title = "Restore workstream",
	icon = "history",
	run = function(cx) open_manager(cx, "restore") end,
})

tern.command({
	id = "refs",
	title = "Workstream references",
	icon = "link",
	keys = { "ctrl+a>shift+f" },
	run = function(cx) open_manager(cx, "refs") end,
})

local function valid_worktree(data)
	return type(data) == "table" and type(data.branch) == "string" and data.branch ~= ""
		and type(data.path) == "string" and data.path:sub(1, 1) == "/"
end

local function close_form(cx, pane)
	local ok, err = pcall(function() cx.layout:close(pane) end)
	if not ok then
		tern.log.warn("Workstream session changed but the manager stayed open", err)
	end
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

	if act == "created" or act == "focus" then
		if not valid_worktree(data) or (act == "created" and data.mode ~= "git" and data.mode ~= "overlay" and data.mode ~= "existing") then
			cx:toast("error", "Workstream result is invalid")
			return { handled = true }
		end
		local succeeded, err = pcall(function()
			local session = lifecycle.find(cx, data.path, data.branch)
			if session then
				cx.sessions:switch(session)
			else
				cx.sessions:create({ name = data.branch, cwd = data.path })
			end
		end)
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
			local matching_tabs = {}
			for _, tab in cx.session:tabs() do
				if tab.cwd == data.path or (type(tab.cwd) == "string" and tab.cwd:sub(1, #data.path + 1) == data.path .. "/") then
					matching_tabs[tab.session] = true
				end
			end
			local session_id = nil
			for _, session in cx.sessions:list() do
				if session.host == cx.hosts:current().id and session.name == data.branch and matching_tabs[session.id] then
					if session_id ~= nil then error("More than one Tern session matches this worktree") end
					session_id = session.id
				end
			end
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
				ev = "action", id = "main.bridge", act = "restore_complete", value = data.record.path,
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
