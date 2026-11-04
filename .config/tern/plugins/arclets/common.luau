--!strict
-- `arclet` and `tern` CLI helpers and profiles.json, for arclets.luau.

local M = {}

M.NAME = "^[a-z0-9][a-z0-9-]*$" -- Arclet names go into commands and node keys, so allow only these
local VALUE = "^[a-z0-9][a-z0-9-]*$" -- repos and arch in profiles.json

-- Tern's GUI PATH may lack these folders; "$@" passes the arguments without quoting.
function M.cli(args: { string }, timeout_ms: number, cb: (r: any, cx: any) -> ())
	local argv = { "/bin/sh", "-c", 'PATH="$HOME/.local/bin:/usr/local/bin:$PATH" exec "$@"', "sh" }
	for _, a in args do
		table.insert(argv, a)
	end
	local ok, err = pcall(tern.process.run, argv, { timeout_ms = timeout_ms }, cb)
	if not ok then
		tern.log.error("arclets: cannot run " .. args[1], err)
	end
end

function M.arclet(args: { string }, timeout_ms: number, cb: (r: any, cx: any) -> ())
	M.cli({ "arclet", "--quiet", table.unpack(args) }, timeout_ms, cb)
end

function M.why(r): string
	if r.timed_out then
		return "timed out"
	end
	local text = if r.stderr ~= "" then r.stderr else r.stdout
	return (text:gsub("%s+$", "")):sub(-300)
end

-- A Tern toast in the windows of `cx`. Callbacks may have no `cx` (a closed window).
function M.notify(cx: any, level: "success" | "info" | "error", title: string, sub: string?)
	if cx then
		pcall(function()
			cx:toast(level, title, sub)
		end)
	end
end

-- `arclet list --json` output → arclets with valid names, or nil and the reason.
function M.parse_list(r): ({ any }?, string?)
	if r.status ~= 0 then
		return nil, M.why(r)
	end
	local ok, data = pcall(tern.json.decode, r.stdout)
	if not ok or type(data) ~= "table" or type(data.arclets) ~= "table" then
		return nil, "arclet list printed unexpected output"
	end
	local valid = {}
	for _, a in data.arclets do
		if type(a.name) == "string" and a.name:match(M.NAME) then
			table.insert(valid, a)
		end
	end
	return valid, nil
end

export type Profile = {
	name: string,
	primary: string,
	repos: { string },
	arch: string?,
	host: boolean,
	default: boolean,
}

local function value(v: any): boolean
	return type(v) == "string" and v:match(VALUE) ~= nil
end

-- profiles.json → valid profiles (the default first, then by name) and a list of problems.
function M.load_profiles(): ({ Profile }, { string })
	local path = tern.plugin.dir .. "/profiles.json"
	if not tern.fs.exists(path) then
		return {}, {}
	end
	local ok, data = pcall(function()
		return tern.json.decode(tern.fs.read(path, 64 * 1024))
	end)
	if not ok or type(data) ~= "table" or type(data.profiles) ~= "table" then
		return {}, { "profiles.json: " .. (if ok then "needs a \"profiles\" object" else tostring(data)) }
	end
	local profiles: { Profile } = {}
	local problems = {}
	for name, p in data.profiles do
		local repos = if type(p) == "table" and p.repos ~= nil then p.repos else {}
		local good = type(name) == "string"
			and name:match(M.NAME) ~= nil
			and type(p) == "table"
			and value(p.primary)
			and type(repos) == "table"
			and (p.arch == nil or value(p.arch))
			and (p.host == nil or type(p.host) == "boolean")
		if good then
			for _, r in repos do
				good = good and value(r)
			end
		end
		if good then
			table.insert(profiles, {
				name = name,
				primary = p.primary,
				repos = repos,
				arch = p.arch,
				host = p.host == true,
				default = name == data.default,
			})
		else
			table.insert(problems, `profiles.json: skipped profile "{tostring(name)}"`)
		end
	end
	table.sort(profiles, function(a, b)
		if a.default ~= b.default then
			return a.default
		end
		return a.name < b.name
	end)
	return profiles, problems
end

-- The `arclet new` flags of a profile: arch, then the primary repository first. The region is
-- `arclet`'s own default (`~/.arca/region`).
function M.profile_args(p: Profile): { string }
	local args = {}
	if p.arch then
		table.insert(args, "--arch")
		table.insert(args, p.arch)
	end
	local seen = {}
	for _, r in { p.primary, table.unpack(p.repos) } do
		if not seen[r] then
			seen[r] = true
			table.insert(args, "--repo")
			table.insert(args, r)
		end
	end
	return args
end

function M.describe(p: Profile): string
	local repos = { p.primary }
	for _, r in p.repos do
		if r ~= p.primary then
			table.insert(repos, r)
		end
	end
	local parts = { p.arch or "x86", table.concat(repos, " + ") }
	if p.host then
		table.insert(parts, "Tern host")
	end
	return table.concat(parts, " · ")
end

return M
