--!nonstrict
-- Block `jj.log`: a VisualJJ-like change tree for the repo in the pane's
-- directory (or args[1]). Click selects a change and shows its diff,
-- double-click edits it, right-click shapes it. "Move…" picks a change;
-- the next click on another change rebases it there (Alt: insert after).

local ui = tern.ui

local RS, US = "\x1e", "\x1f"
local POLL_MS = 2000
local MAX_DIFF = 200000
local TEMPLATE = [["\x1e" ++ change_id.shortest(8) ++ "\x1f" ++ commit_id.short(8) ++ "\x1f"
++ description.first_line() ++ "\x1f" ++ author.email().local() ++ "\x1f" ++ bookmarks.join(" ")
++ "\x1f" ++ if(current_working_copy, "@") ++ if(conflict, "c") ++ if(empty, "e") ++ if(immutable, "i")
++ "\x1f" ++ committer.timestamp().ago() ++ "\x1f" ++ tags.join(" ")
++ "\x1f" ++ working_copies.map(|w| w.name()).join(" ") ++ "\n"]]

local function running(pane)
	for _, p in tern.pane.list() do
		if p.pane == pane then
			return true
		end
	end
	return false
end

-- The daemon starts from launchd with a bare PATH (no Nix, Homebrew or cargo bins), so
-- ask the user's login shell for its PATH once and give it to every jj (and the git jj runs).
-- JJ_EDITOR=false: a command that wants an editor fails fast instead of hanging.
local env = nil
local waiting = {}
local SHELLS = { "/bin/zsh", "/bin/bash", "/bin/sh" }
if tern.getenv("SHELL") then
	table.insert(SHELLS, 1, tern.getenv("SHELL"))
end

local function with_env(fn)
	if env then
		return fn()
	end
	table.insert(waiting, fn)
	if #waiting > 1 then
		return
	end
	local function done(path)
		env = { PATH = path, JJ_EDITOR = "false" }
		local queued = waiting
		waiting = {}
		for _, f in queued do
			f()
		end
	end
	for _, shell in SHELLS do
		local started = pcall(tern.process.run, { shell, "-lc", 'printf "\\036%s\\036" "$PATH"' }, { timeout_ms = 10000 }, function(r)
			done(string.match(r.stdout, "\x1e(.-)\x1e") or tern.getenv("PATH") or "")
		end)
		if started then
			return
		end
	end
	done(tern.getenv("PATH") or "")
end

local function jj(state, args, cb)
	local argv = { "jj", "--no-pager", "--color", "never" }
	for _, a in args do
		table.insert(argv, a)
	end
	with_env(function()
		local ok, err = pcall(tern.process.run, argv, { cwd = state.repo, env = env, timeout_ms = 30000 }, cb)
		if not ok then
			cb({ status = 127, stdout = "", stderr = tostring(err) })
		end
	end)
end

-- jj's graph glyphs (forced to the curved style), the CSS segments each one draws, and
-- which glyphs reach the row above or below (to join a node to its lane).
local SEGMENTS = {
	["│"] = { "v" }, ["─"] = { "h" }, ["├"] = { "v", "hr" }, ["┤"] = { "v", "hl" }, ["┼"] = { "v", "h" },
	["┬"] = { "vd", "h" }, ["┴"] = { "vu", "h" }, ["╮"] = { "cld" }, ["╭"] = { "crd" }, ["╯"] = { "cul" },
	["╰"] = { "cur" }, ["~"] = { "el" },
}
local UP = { ["│"] = true, ["├"] = true, ["┤"] = true, ["┼"] = true, ["┴"] = true, ["╯"] = true, ["╰"] = true, ["~"] = true }
local DOWN = { ["│"] = true, ["├"] = true, ["┤"] = true, ["┼"] = true, ["┬"] = true, ["╮"] = true, ["╭"] = true }
-- ponytail: jj.css has position classes for 32 cells (16 lanes); wider graphs pile up at the edge.
local MAX_COLS = 32

local function is_node(g)
	return g ~= nil and g ~= " " and SEGMENTS[g] == nil
end

-- The graph prefix as one string per cell, trailing blanks dropped. On a line without a
-- change (an edge row, "~ (elided revisions)"), text after the glyphs becomes `label`.
local function cells(prefix, graph_only)
	local out, label = {}, nil
	for _, code in utf8.codes(prefix) do
		local g = utf8.char(code)
		if graph_only and label == nil and g ~= " " and SEGMENTS[g] == nil then
			label = ""
		end
		if label then
			label ..= g
		else
			table.insert(out, g)
		end
	end
	while out[#out] == " " do
		table.remove(out)
	end
	return out, label
end

local function parse(out)
	local rows = {}
	for line in string.gmatch(out, "([^\n]*)\n") do
		local at = string.find(line, RS, 1, true)
		if at then
			local f = string.split(string.sub(line, at + 1), US)
			table.insert(rows, {
				cells = cells(string.sub(line, 1, at - 1), false),
				id = f[1],
				commit = f[2],
				desc = f[3],
				author = f[4],
				bookmarks = f[5],
				flags = f[6] or "",
				ago = f[7],
				tags = f[8],
				workspaces = f[9],
			})
		else
			local cs, label = cells(line, true)
			table.insert(rows, { cells = cs, label = label })
		end
	end
	return rows
end

local function find(state, id)
	for _, r in state.rows do
		if r.id == id then
			return r
		end
	end
	return nil
end

-- `jj diff --summary` lines, `M src/a.rs` or `R src/{a => b}.rs`: the status letter,
-- the text as shown, and the path now (renames and copies take the right side).
local function parse_summary(text)
	local files = {}
	for line in string.gmatch(text, "([^\n]*)\n") do
		local status, shown = string.match(line, "^(%u) (.+)$")
		if status then
			local path = string.gsub(string.gsub(shown, "{(.-) => (.-)}", "%2"), "//", "/")
			table.insert(files, { status = status, shown = shown, path = path })
		end
	end
	return files
end

-- Loads the description and changed files of the selected change.
local function load_detail(state, cx)
	local id = state.sel
	if not id then
		state.detail = nil
		return
	end
	jj(state, { "log", "-r", id, "--no-graph", "--summary", "-T", 'description ++ "\\x1e\\n"' }, function(r)
		if not running(cx.pane) or state.sel ~= id then
			return
		end
		if r.status ~= 0 then
			state.detail = { id = id, err = r.stderr }
		else
			local at = string.find(r.stdout, RS, 1, true) or #r.stdout + 1
			state.detail = {
				id = id,
				desc = string.sub(r.stdout, 1, at - 1),
				files = parse_summary(string.sub(r.stdout, at + 2)),
			}
		end
		cx:render()
	end)
end

-- Diff blocks (`jj.diff`), by the pane of the log block that opened them. Both block kinds
-- run in this plugin's one worker, so a log block updates its diff block directly.
local viewers = {}
local pending = {} -- log pane -> target for a diff block that is about to open

local function fileset(path)
	return 'file:"' .. (string.gsub(path, '[\\"]', "\\%0")) .. '"'
end

-- Loads the target file's diff into a diff block. `t.repo` doubles as jj's state.
local function load_viewer(v)
	local t = v.state.target
	if not t then
		return
	end
	jj(t, { "diff", "-r", t.rev, "--git", "--", fileset(t.path) }, function(r)
		if not running(v.cx.pane) or v.state.target ~= t then
			return
		end
		if r.status ~= 0 then
			v.state.err, v.state.diff = r.stderr, nil
		else
			-- Keep the hunks; ui.diff draws the file name from the block's head instead.
			local at = string.find(r.stdout, "\n@@", 1, true)
			local text = if at then string.sub(r.stdout, at + 1) else ""
			-- What git says before the hunks (`rename from e`, `Binary files … differ`).
			local notes = {}
			for line in string.gmatch(string.sub(r.stdout, 1, at or #r.stdout), "([^\n]+)") do
				if not string.match(line, "^diff %-%-git ") and not string.match(line, "^index ")
					and not string.match(line, "^%-%-%- ") and not string.match(line, "^%+%+%+ ") then
					table.insert(notes, line)
				end
			end
			local adds, dels = 0, 0
			for line in string.gmatch(text, "[^\n]+") do
				local sign = string.sub(line, 1, 1)
				if sign == "+" then
					adds += 1
				elseif sign == "-" then
					dels += 1
				end
			end
			-- ponytail: diffs over MAX_DIFF are cut; open the file itself if this bites.
			v.state.cut = #text > MAX_DIFF
			v.state.note = table.concat(notes, "\n")
			v.state.adds, v.state.dels = adds, dels
			v.state.err, v.state.diff = nil, string.sub(text, 1, MAX_DIFF)
		end
		v.cx:render()
	end)
end

-- Shows one file of the selected change in this log block's diff block, opening it if needed.
local function show_file(state, cx, path)
	state.file = path
	local t = { repo = state.repo, rev = state.sel, path = path }
	local v = viewers[cx.pane]
	if v and running(v.cx.pane) then
		v.state.target, v.state.diff, v.state.err = t, nil, nil
		v.cx:render()
		load_viewer(v)
	else
		pending[cx.pane] = t
		cx:open("jjdiff:" .. cx.pane) -- window.luau routes this to a new jj.diff block
	end
end

-- Reads `jj log` (which also snapshots the working copy) and renders only when it changed.
-- ponytail: polls the whole log every POLL_MS; poll `jj op log -n1` first if big repos make it slow.
local function refresh(state, cx)
	if state.loading then
		return
	end
	state.loading = true
	jj(state, { "log", "--config", "ui.graph.style=curved", "-T", TEMPLATE }, function(r)
		state.loading = false
		if not running(cx.pane) then
			return
		end
		local out = if r.status == 0 then r.stdout else nil
		local err = if r.status == 0 then nil else r.stderr
		if out == state.out and err == state.err then
			return
		end
		state.out, state.err = out, err
		state.rows = if out then parse(out) else {}
		if state.sel and not find(state, state.sel) then
			state.sel = nil
		end
		load_detail(state, cx)
		local v = viewers[cx.pane]
		if v and running(v.cx.pane) then
			load_viewer(v)
		end
		cx:render()
	end)
end

-- Runs a mutating jj command, then refreshes. Failures toast jj's message.
local function mutate(state, cx, label, args)
	state.busy = label
	cx:render()
	jj(state, args, function(r)
		state.busy = nil
		if not running(cx.pane) then
			return
		end
		if r.status ~= 0 then
			cx:toast("error", "jj " .. label .. " failed", string.match(r.stderr, "Error: ([^\n]*)") or r.stderr)
		end
		state.out = nil -- force a re-render of the log
		refresh(state, cx)
		cx:render()
	end)
end

-- Runs an interactive jj command (editor, split UI) in a terminal pane below the block,
-- through an interactive login shell so jj gets the user's PATH and $EDITOR.
-- The pane closes itself when jj succeeds; the poll picks up the result.
-- `args` are fixed words and change ids ([a-z0-9]), so joining them needs no quoting.
local function interactive(state, cx, args)
	local argv = {
		tern.getenv("TERN_EXE") or "tern", "split", tostring(cx.pane), "down", "--cwd", state.repo,
		"--", SHELLS[1], "-l", "-i", "-c", "exec jj " .. table.concat(args, " "),
	}
	local ok, err = pcall(tern.process.run, argv, { env = env, timeout_ms = 10000 }, function(r)
		if r.status ~= 0 and running(cx.pane) then
			cx:toast("error", "Could not open a terminal", r.stderr)
		end
	end)
	if not ok then
		cx:toast("error", "Could not open a terminal", tostring(err))
	end
end

local function menu(row)
	local id = row.id
	local frozen = string.find(row.flags, "i", 1, true) ~= nil
	local function item(act, label, extra)
		local it = { id = act .. "=" .. id, label = label }
		for k, v in extra or {} do
			it[k] = v
		end
		return it
	end
	local lock = if frozen then "Immutable" else false
	return {
		{ header = id },
		item("new", "New change here"),
		item("edit", "Edit this change", { disabled = lock }),
		item("describe", "Describe…", { disabled = lock }),
		"-",
		item("squash", "Squash into parent", { disabled = lock }),
		item("split", "Split…", { disabled = lock }),
		item("move", "Move…", { disabled = lock, detail = "Then click the new parent; Alt-click inserts after it" }),
		item("rebase_trunk", "Rebase on trunk", { disabled = lock }),
		item("duplicate", "Duplicate"),
		item("revert", "Revert"),
		"-",
		item("push", "Push (create bookmark)", { disabled = lock }),
		"-",
		item("abandon", "Abandon", { danger = true, disabled = lock }),
		item("abandon_tree", "Abandon with descendants", { danger = true, disabled = lock }),
	}
end

local function has(flags, f)
	return string.find(flags, f, 1, true) ~= nil
end

-- A corner glyph ends a horizontal run (`├─╯`, `╰─┤`): which way the run lies from it,
-- and the elbow class that draws the whole run as one rounded line (jj.css).
local CORNER = { ["╯"] = { -1, "cul" }, ["╮"] = { -1, "cld" }, ["╭"] = { 1, "crd" }, ["╰"] = { 1, "cur" } }
local STUBS = { hr = true, hl = true }

-- One row's graph: each glyph cell becomes positioned line, elbow and dot shapes (jj.css).
-- ponytail: a node right above another node in its lane counts as joined; jj could stack
-- an unrelated head there, which then shows a false edge.
local function graph_box(rows, i, width)
	local row = rows[i]
	local cs = row.cells
	local n = math.min(#cs, MAX_COLS)
	local segs = {} -- cell -> its shapes
	local function seg(c, kind, lane)
		segs[c] = segs[c] or {}
		table.insert(segs[c], ui.el("span", { class = "jj-s jj-" .. kind .. " jj-k" .. (lane % 8) }))
	end
	local covered, bare = {}, {} -- `─` cells an elbow draws; run starts whose stub it draws
	for c = 1, n do
		local corner = CORNER[cs[c]]
		if corner then
			local dir = corner[1]
			local j = c + dir
			while cs[j] == "─" do
				covered[j] = true
				j += dir
			end
			bare[j] = true
			-- The elbow lives in the left cell of the run and spans |c - j| cells.
			seg(math.min(c, j), corner[2] .. " jj-w" .. math.abs(c - j), (c - 1) // 2)
		end
	end
	for c = 1, n do
		local g = cs[c]
		local lane = (c - 1) // 2
		if g == " " or covered[c] or CORNER[g] then
			continue
		elseif SEGMENTS[g] then
			for _, kind in SEGMENTS[g] do
				if not (bare[c] and STUBS[kind]) then
					seg(c, kind, lane)
				end
			end
		else
			local above = rows[i - 1] and rows[i - 1].cells[c]
			local below = rows[i + 1] and rows[i + 1].cells[c]
			if DOWN[above] or is_node(above) then
				seg(c, "vu", lane)
			end
			if UP[below] or is_node(below) then
				seg(c, "vd", lane)
			end
			local f = row.flags or ""
			local look = if has(f, "c") then " jj-conf" elseif has(f, "@") then " jj-wc" elseif has(f, "i") then " jj-imm" else ""
			seg(c, "dot" .. look, lane)
		end
	end
	local kids = {}
	for c = 1, n do
		if segs[c] then
			table.insert(kids, ui.el("span", { class = "jj-c jj-x" .. (c - 1) }, segs[c]))
		end
	end
	return ui.el("div", { class = "jj-g jj-w" .. width }, kids)
end

local function graph_row(state, i, width)
	local row = state.rows[i]
	if not row.id then
		local kids = { graph_box(state.rows, i, width) }
		if row.label then
			table.insert(kids, ui.text({ ui.span(row.label, "dim em") }))
		end
		return ui.el("div", { class = if row.label then "jj-row" else "jj-row jj-thin", key = "g" .. i }, kids)
	end
	local flags = row.flags
	local desc
	if row.desc ~= "" then
		desc = ui.text({ ui.span(row.desc, if has(flags, "@") then "strong" else nil) })
	else
		desc = ui.text({ ui.span(if has(flags, "e") then "(empty)" else "(no description)", "muted em") })
	end
	desc.p.truncate = "end"
	desc.p.grow = 1
	desc.p.min = { w = "14ch" }
	local kids = { graph_box(state.rows, i, width), desc }
	for w in string.gmatch(row.workspaces or "", "%S+") do
		table.insert(kids, ui.badge(w .. "@", "accent"))
	end
	for b in string.gmatch(row.bookmarks or "", "%S+") do
		table.insert(kids, ui.badge(b, "success"))
	end
	for t in string.gmatch(row.tags or "", "%S+") do
		table.insert(kids, ui.badge(t, "info"))
	end
	if has(flags, "c") then
		table.insert(kids, ui.badge("conflict", "error"))
	end
	local meta = ui.text({
		ui.span(row.id, "mono"),
		ui.span("  " .. (if row.author ~= "" then row.author .. " · " else "") .. row.ago, "dim"),
	})
	meta.p.truncate = "end"
	meta.p.shrink = 6
	table.insert(kids, meta)
	return ui.el("div", {
		class = if has(flags, "i") then "jj-row jj-frozen" else "jj-row",
		key = row.id,
		title = row.commit,
		actions = { click = "sel=" .. row.id, dblclick = "edit=" .. row.id, menu = menu(row) },
		mark = if state.moving == row.id then "drop" elseif state.sel == row.id then "pick" else nil,
	}, kids)
end

local STATUS_TONE = { A = "success", M = "warning", D = "error", R = "info", C = "info" }

local function detail_view(state)
	local d = state.detail
	if not state.sel then
		return ui.col({ ui.text({ ui.span("Click a change to see its files.", "muted") }) })
	end
	local row = find(state, state.sel)
	local head = ui.text({
		ui.span(state.sel, "mono accent"),
		ui.span("  " .. (if row then row.commit .. " · " .. row.author .. " · " .. row.ago else ""), "dim"),
	})
	if not d or d.id ~= state.sel then
		return ui.col({ head, ui.node("spinner", { style = "dots" }) })
	end
	if d.err then
		return ui.col({ head, ui.text({ ui.span(d.err, "error") }) })
	end
	local kids = { head }
	if d.desc ~= "" then
		table.insert(kids, ui.md(d.desc))
	end
	if #d.files == 0 then
		table.insert(kids, ui.text({ ui.span("No changes.", "muted") }))
		return ui.col(kids)
	end
	local items = {}
	for i, f in d.files do
		items[i] = { label = { ui.span(f.status, "mono strong " .. (STATUS_TONE[f.status] or "muted")), "  ", ui.span(f.shown, "path") } }
	end
	local list = ui.list(items)
	for i, child in list.c or {} do
		local path = d.files[i].path
		child.p.key = path
		child.p.title = "Click: diff · Double-click: open the file"
		child.p.actions = { click = "file=" .. path, dblclick = "openfile=" .. path }
	end
	-- The detail pane is the split's second child: its id is main.split.1.
	list.p = { key = "files", selected = if state.file then "main.split.1.files." .. state.file else nil }
	table.insert(kids, ui.rule({ ui.span(#d.files .. (if #d.files == 1 then " file" else " files"), "muted") }))
	table.insert(kids, list)
	return ui.col(kids)
end

local function button(text, act, variant)
	return ui.button(text, { size = "sm", variant = variant or "quiet", actions = { click = act } })
end

local MUTATIONS = {
	new = function(id) return "new", { "new", id } end,
	edit = function(id) return "edit", { "edit", id } end,
	squash = function(id) return "squash", { "squash", "-r", id, "--use-destination-message" } end,
	rebase_trunk = function(id) return "rebase", { "rebase", "-s", id, "-o", "trunk()" } end,
	duplicate = function(id) return "duplicate", { "duplicate", id } end,
	revert = function(id) return "revert", { "revert", "-r", id, "-B", "@" } end,
	push = function(id) return "push", { "git", "push", "-c", id } end,
	abandon = function(id) return "abandon", { "abandon", id } end,
	abandon_tree = function(id) return "abandon", { "abandon", id .. "::" } end,
	undo = function() return "undo", { "undo" } end,
	fetch = function() return "fetch", { "git", "fetch" } end,
}

local INTERACTIVE = {
	describe = function(id) return { "describe", "-r", id } end,
	split = function(id) return { "split", "-r", id } end,
}

tern.block.define("log", {
	font = "sans",

	init = function(cx, args, saved)
		local state = {
			repo = (saved and saved.repo) or args[1] or cx.cwd or tern.getenv("HOME"),
			sel = saved and saved.sel,
			rows = {},
		}
		local function tick()
			if not running(cx.pane) then
				return
			end
			refresh(state, cx)
			tern.timer(POLL_MS, tick)
		end
		tick()
		return state
	end,

	title = function(state)
		return "jj · " .. (string.match(state.repo, "([^/]+)/?$") or state.repo)
	end,

	view = function(state, _cx)
		if state.err then
			return {
				main = ui.col({
					ui.text({ ui.span("jj log failed in ", "strong"), ui.path(state.repo) }),
					ui.code(state.err, "text"),
				}),
			}
		end
		local rows = {}
		local width = 1
		for _, row in state.rows do
			width = math.max(width, math.min(#row.cells, MAX_COLS))
		end
		for i in state.rows do
			rows[i] = graph_row(state, i, width)
		end
		local status
		if state.busy then
			status = ui.node("spinner", { style = "dots", label = { ui.span("jj " .. state.busy .. "…", "muted") } })
		elseif state.moving then
			status = ui.text({
				ui.span("Moving ", "muted"),
				ui.span(state.moving, "mono accent"),
				ui.span(": click the new parent (Alt-click: insert after it)", "muted"),
			})
		else
			status = ui.text({ ui.path(state.repo) })
		end
		status.p = status.p or {}
		status.p.grow = 1
		local bar = { status }
		if state.moving then
			table.insert(bar, button("Cancel", "cancel"))
		end
		table.insert(bar, button("Fetch", "fetch"))
		table.insert(bar, button("Undo", "undo"))
		return {
			main = ui.col({
				ui.node("split", { key = "split", sizes = { 0.45, 0.55 }, min = { "30ch", "30ch" }, grow = 1 }, {
					ui.el("div", { class = "jj-graph" }, rows),
					detail_view(state),
				}),
			}),
			dock = ui.col({ ui.row(bar) }),
		}
	end,

	event = function(state, ev, cx)
		if ev.ev ~= "action" then
			return
		end
		local act, id = ev.act, ev.value
		if act == "sel" then
			if state.moving then
				local src = state.moving
				state.moving = nil
				if id ~= src then
					local alt = ev.mods and table.find(ev.mods, "alt")
					mutate(state, cx, "rebase", if alt then { "rebase", "-r", src, "-A", id } else { "rebase", "-s", src, "-o", id })
				end
				return
			end
			if state.sel ~= id then
				state.file = nil
			end
			state.sel = id
			load_detail(state, cx)
		elseif act == "file" then
			show_file(state, cx, id)
		elseif act == "openfile" then
			cx:open(state.repo .. "/" .. id)
		elseif act == "move" then
			state.moving = id
		elseif act == "cancel" then
			state.moving = nil
		elseif INTERACTIVE[act] then
			interactive(state, cx, INTERACTIVE[act](id))
		elseif MUTATIONS[act] then
			local label, args = MUTATIONS[act](id)
			mutate(state, cx, label, args)
		end
	end,

	save = function(state)
		return { repo = state.repo, sel = state.sel }
	end,
})

-- Block `jj.diff`: one file of one change, opened by a log block (args[1] is its pane).
tern.block.define("diff", {
	font = "sans",

	init = function(cx, args, saved)
		local log = tonumber(args[1])
		local state = { target = (saved and saved.target) or (log and pending[log]) }
		local v = { state = state, cx = cx }
		if log then
			pending[log] = nil
			viewers[log] = v
		end
		load_viewer(v)
		return state
	end,

	title = function(state)
		local t = state.target
		return if t then "diff · " .. (string.match(t.path, "([^/]+)$") or t.path) else nil
	end,

	view = function(state, _cx)
		local t = state.target
		if not t then
			return { main = ui.col({ ui.text({ ui.span("Click a file in a jj block.", "muted") }) }) }
		end
		-- "auto" follows Tern's Settings › Edits (inline, or split when the block is wide).
		local stored = tern.kv.get("diff_mode")
		local mode = if stored == "unified" or stored == "split" then stored else nil
		local function choice(label, value)
			return ui.button(label, { on = mode == value, actions = { click = "mode=" .. (value or "auto") } })
		end
		local kids = {
			ui.node("buttons", { key = "end", size = "sm", label = "Diff layout" }, {
				choice("Auto", nil),
				choice("Unified", "unified"),
				choice("Split", "split"),
			}),
		}
		local has_diff = state.diff ~= nil and state.diff ~= ""
		if state.err then
			table.insert(kids, ui.text({ ui.span(state.err, "error") }))
		elseif not state.diff then
			table.insert(kids, ui.node("spinner", { style = "dots" }))
		elseif not has_diff then
			table.insert(kids, ui.text({ ui.span(if (state.note or "") ~= "" then state.note else "No text changes.", "muted") }))
		else
			local d = ui.diff(state.diff, t.path)
			d.p.mode = mode
			table.insert(kids, d)
		end
		local meta = { ui.span("in " .. t.rev, "mono") }
		if has_diff then
			table.insert(meta, 1, ui.span("+" .. state.adds .. " ", "ins num"))
			table.insert(meta, 2, ui.span("−" .. state.dels .. "  ", "del num"))
		end
		if has_diff and (state.note or "") ~= "" then
			table.insert(meta, ui.span("  " .. string.gsub(state.note, "\n", " · "), "muted"))
		end
		local card = ui.card({ ui.span(t.path, "path") }, kids, {
			key = "file",
			icon = "file",
			meta = meta,
			["end"] = "main.file.end",
			inset = has_diff, -- the diff fills the card edge to edge; text keeps the padding
		})
		local main = { card }
		if state.cut then
			table.insert(main, ui.text({ ui.span("Diff cut at " .. MAX_DIFF .. " bytes.", "warning") }))
		end
		return { main = ui.col(main) }
	end,

	event = function(_state, ev, _cx)
		if ev.ev == "action" and ev.act == "mode" then
			tern.kv.set("diff_mode", ev.value)
			-- Other open diff blocks pick the new mode up on their next render.
			for _, v in viewers do
				if running(v.cx.pane) then
					v.cx:render()
				end
			end
		end
	end,

	save = function(state)
		return { target = state.target }
	end,
})
