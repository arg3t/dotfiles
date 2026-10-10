--!strict

tern.command({
	id = "create",
	title = "Create workstream",
	icon = "branch",
	keys = { "ctrl+a>shift+w" },
	run = function(cx)
		local focused = cx.session:focused()
		local cwd = nil
		for _, pane in cx.session:panes() do
			if pane.pane == focused then
				cwd = pane.cwd
				break
			end
		end
		if cwd == nil or cwd == "" then
			cx:toast("error", "Focus a terminal in a Git repository first")
			return
		end
		if cx:new_block("workstreams.create", { cwd }, "beside") == nil then
			cx:toast("error", "Install the Workstreams plugin on this host")
		end
	end,
})

tern.route.link(function(link, cx)
	local encoded = link.url:match("^tern%-workstreams://created/(.+)$")
	if encoded == nil then
		return nil
	end
	local pane = link.pane and cx.session:pane(link.pane)
	if pane == nil or pane.block ~= "workstreams.create" then
		cx:toast("error", "Worktree ready, but the creation pane is no longer here", "Return to its session and press Enter to retry.")
		return { handled = true }
	end
	local decoded = encoded:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
	local ok, data = pcall(tern.json.decode, decoded)
	if not ok or type(data) ~= "table" or type(data.branch) ~= "string" or data.branch == ""
		or type(data.path) ~= "string" or data.path:sub(1, 1) ~= "/"
		or (data.mode ~= "git" and data.mode ~= "overlay" and data.mode ~= "existing") then
		cx:toast("error", "Workstream result is invalid", "The worktree was not removed.")
		return { handled = true }
	end
	local created, err = pcall(function()
		local sessions = {}
		for _, session in cx.sessions:list() do
			sessions[session.id] = session
		end
		for _, tab in cx.session:tabs() do
			local session = sessions[tab.session]
			if tab.cwd == data.path and session ~= nil and session.name == data.branch then
				cx.sessions:switch(session.id)
				return
			end
		end
		cx.sessions:create({ name = data.branch, cwd = data.path })
	end)
	if not created then
		cx:toast("error", "Worktree created; session creation failed", tostring(err) .. " · " .. data.path)
		return { handled = true }
	end
	local closed, close_err = pcall(function()
		cx.layout:close(link.pane)
	end)
	if not closed then
		tern.log.warn("Workstream session opened but its form stayed open", close_err)
	end
	cx:toast("success", "Workstream ready (" .. data.mode .. ")", data.path)
	return { handled = true }
end)
