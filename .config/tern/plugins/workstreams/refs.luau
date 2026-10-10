--!strict

local refs = {}
local inbox = tern.plugin.data .. "/refs-inbox"
local key = "workstream_refs"
local empty = {}
local cache = nil
local cursor = 1

local function store()
	if cache == nil then
		cache = tern.kv.get(key) or {}
		if type(cache) ~= "table" then
			error("workstream_refs must be a map")
		end
	end
	return cache
end

local function checkout(cwd, worktrees)
	local best = nil
	local bestLength = 0
	for _, worktree in ipairs(worktrees) do
		local path = worktree.path
		if type(path) == "string" and path:sub(1, 1) == "/" then
			path = path:gsub("/+$", "")
			if path == "" then path = "/" end
			if (cwd == path or path == "/" or cwd:sub(1, #path + 1) == path .. "/")
				and #path > bestLength then
				best, bestLength = worktree.path, #path
			end
		end
	end
	return best
end

local function valid(row)
	return type(row) == "table"
		and (row.kind == "jira" or row.kind == "pr" or row.kind == "url")
		and type(row.id) == "string" and #row.id > 0 and #row.id <= 2048
		and (row.url == nil or (type(row.url) == "string" and #row.url <= 2048))
		and (row.discovered == nil or (type(row.discovered) == "string" and #row.discovered <= 40))
end

function refs.sync(worktrees)
	if type(worktrees) ~= "table" or #worktrees == 0 or not tern.fs.exists(inbox) then return 0 end
	local names = {}
	for _, name in ipairs(tern.fs.list(inbox)) do
		if name:match("^[0-9a-f%-]+%-%d+%.json$") then
			names[#names + 1] = name
		end
	end
	if #names == 0 then return 0 end
	local state = store()
	local consumed = {}
	local changed = false
	local count = math.min(32, #names)
	for offset = 0, count - 1 do
		local name = names[(cursor + offset - 1) % #names + 1]
		local filename = inbox .. "/" .. name
		local read_ok, data = pcall(tern.fs.read, filename)
		if not read_ok then
			cache = nil -- Earlier files in this batch have not been persisted yet.
			error(data)
		end
		if #data <= 262144 then
			local decode_ok, snapshot = pcall(tern.json.decode, data)
			if decode_ok and type(snapshot) == "table" and type(snapshot.cwd) == "string"
				and snapshot.cwd:sub(1, 1) == "/" and type(snapshot.refs) == "table"
				and #snapshot.refs > 0 and #snapshot.refs <= 128 then
				local path = checkout(snapshot.cwd, worktrees)
				if path ~= nil then
					local good = true
					for _, row in ipairs(snapshot.refs) do
						if not valid(row) then good = false; break end
					end
					if good then
						local records = state[path]
						if records == nil then
							records = {}
							state[path] = records
						end
						for _, row in ipairs(snapshot.refs) do
							local refkey = row.kind .. ":" .. row.id
							local existing = nil
							for _, ref in ipairs(records) do
								if ref.kind .. ":" .. ref.id == refkey then
									existing = ref
									break
								end
							end
							if existing == nil then
								records[#records + 1] = {
									kind = row.kind, id = row.id, url = row.url or "",
									pinned = false, dismissed = false, discovered = row.discovered or "",
								}
								changed = true
							elseif not existing.dismissed and row.url ~= nil and row.url ~= "" and existing.url ~= row.url then
								existing.url = row.url
								changed = true
							end
						end
						consumed[#consumed + 1] = filename
					end
				end
			end
		end
	end
	cursor = (cursor + count - 1) % #names + 1
	if changed then
		local ok, err = pcall(tern.kv.set, key, state)
		if not ok then
			cache = nil
			error(err)
		end
	end
	for _, filename in ipairs(consumed) do
		tern.fs.remove(filename)
	end
	return #consumed
end

function refs.list(path)
	return store()[path] or empty
end

local function update(path, refkey, dismiss)
	local records = store()[path]
	if type(records) ~= "table" then return false end
	for _, ref in ipairs(records) do
		if ref.kind .. ":" .. ref.id == refkey then
			local pinned, dismissed = ref.pinned, ref.dismissed
			if dismiss then
				ref.pinned, ref.dismissed = false, true
			else
				ref.pinned = not ref.pinned
				if ref.pinned then ref.dismissed = false end
			end
			if ref.pinned ~= pinned or ref.dismissed ~= dismissed then
				local ok, err = pcall(tern.kv.set, key, cache)
				if not ok then
					ref.pinned, ref.dismissed = pinned, dismissed
					cache = nil
					error(err)
				end
			end
			return true
		end
	end
	return false
end

function refs.pin(path, refkey)
	return update(path, refkey, false)
end

function refs.dismiss(path, refkey)
	return update(path, refkey, true)
end

return refs
