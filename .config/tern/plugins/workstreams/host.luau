--!strict

local ui = tern.ui

local function request_session(state, cx)
	local data = tern.json.encode({ branch = state.branch, path = state.path, mode = state.mode })
	local encoded = data:gsub("[^%w%-%._~]", function(byte)
		return string.format("%%%02X", string.byte(byte))
	end)
	cx:open("tern-workstreams://created/" .. encoded)
end

tern.block.define("create", {
	init = function(cx, args, saved)
		local cwd = args[1] or cx.cwd or ""
		local state = { cwd = cwd, branch = "", path = nil, mode = nil, message = "Enter a branch name.", busy = false }
		if type(saved) == "table" and saved.cwd == cwd and type(saved.branch) == "string" then
			state.branch = saved.branch
			if type(saved.path) == "string" and type(saved.mode) == "string" then
				state.path = saved.path
				state.mode = saved.mode
				state.message = "Worktree ready. Press Enter to open its session."
			end
		end
		cx:frame({ { "focus", "main.branch" } })
		return state
	end,
	view = function(state)
		return {
			main = ui.col({
				ui.text("Create a worktree-backed session"),
				ui.text(state.cwd),
				ui.node("input", {
					key = "branch",
					text = state.branch,
					cursor = #state.branch,
					placeholder = "feature/short-name",
					readonly = state.path ~= nil,
					aria = "Workstream branch",
				}),
				ui.text(state.path or state.message),
				ui.text(state.path and state.message or "Enter: create   Esc: close"),
			}),
		}
	end,
	key = function(state, key, cx)
		if state.busy then
			return false
		end
		if key.name == "escape" then
			cx:exit(0)
			return true
		end
		if key.name == "enter" then
			if state.path ~= nil then
				state.message = "Requesting a session in this window…"
				request_session(state, cx)
				return true
			end
			local branch = state.branch:match("^%s*(.-)%s*$")
			if branch == "" then
				state.message = "Enter a branch name."
				return true
			end
			state.busy = true
			state.message = "Creating the Git worktree…"
			local ok, err = pcall(tern.process.run, {
				"bash", tern.plugin.dir .. "/create.sh", state.cwd, branch,
			}, { timeout_ms = 300000 }, function(result)
				if result.status == 0 then
					local first = result.stdout:find("\0", 1, true)
					local second = first and result.stdout:find("\0", first + 1, true)
					local third = second and result.stdout:find("\0", second + 1, true)
					if first and second and third == #result.stdout then
						local mode = result.stdout:sub(1, first - 1)
						local path = result.stdout:sub(first + 1, second - 1)
						local name = result.stdout:sub(second + 1, third - 1)
						if (mode == "git" or mode == "overlay" or mode == "existing") and path:sub(1, 1) == "/" and name ~= "" then
							state.mode, state.path, state.branch = mode, path, name
							state.busy = false
							state.message = "Worktree ready. Opening its session…"
							cx:render()
							request_session(state, cx)
							return
						end
					end
					state.message = "The creator returned an invalid result. Check the worktree before retrying."
				else
					state.message = result.timed_out and "Creation timed out; check the worktree before retrying."
						or (result.stderr:gsub("%s+$", ""))
					if state.message == "" then
						state.message = "Worktree creation failed; check the worktree before retrying."
					end
				end
				state.busy = false
				cx:render()
			end)
			if not ok then
				state.busy = false
				state.message = tostring(err)
			end
			return true
		end
		if state.path ~= nil then
			return false
		end
		if key.name == "backspace" then
			if state.branch == "" then
				return false
			end
			state.branch = state.branch:sub(1, -2)
		elseif key.text ~= nil and key.text ~= "" and not key.ctrl and not key.alt and not key.meta then
			if key.text:find("[\r\n]") then
				state.message = "Use one line for the branch name."
				return true
			end
			state.branch ..= key.text
		else
			return false
		end
		state.message = "Enter a branch name."
		return true
	end,
	save = function(state)
		return { cwd = state.cwd, branch = state.branch, path = state.path, mode = state.mode }
	end,
})
