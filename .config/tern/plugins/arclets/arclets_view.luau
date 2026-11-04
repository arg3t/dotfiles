-- Pure render of the Arclets section: model (from arclets.luau) -> Tern-native nodes.
local ui = tern.ui
local AV = {}

-- Right-click menu labels. Tern reports the label as the action; arclets.luau dispatches on
-- them and finds the Arclet from the row's node path (`.ar_<name>`).
local M = {
	go = "Go to Tern Host", setup = "Set Up as Tern Host", shell = "Open Shell",
	start = "Start Arclet", stop = "Stop Arclet",
	new = "New Arclet…", startAll = "Start All Stopped Arclets", refresh = "Refresh Arclets",
}
AV.M = M

local TONE = { ACTIVE = "success", STOPPED = "muted" }

local function quick(key, icon, action, title)
	return ui.node("icon", { key = key, name = icon, role = "arc.btn", title = title, aria = title, actions = { click = action } })
end

local function note(key, text, tone)
	return ui.node("text", { key = key, role = "arc.note", spans = { ui.span(text, tone or "muted") } })
end

-- Workspaces | Arclets, the switch under both sections' headers.
function AV.sectionBar(section)
	local buttons = {}
	for _, s in { { id = "workspaces", icon = "users", text = "Workspaces" }, { id = "arclets", icon = "server", text = "Arclets" } } do
		table.insert(buttons, ui.node("row", {
			key = s.id, title = s.text, aria = s.text, grow = 1,
			role = if section == s.id then "arc.viewOn" else "arc.view",
			actions = { click = "asec=" .. s.id },
		}, {
			ui.node("icon", { key = "ic", name = s.icon }),
			ui.node("text", { key = "t", text = s.text }),
		}))
	end
	return ui.node("row", { key = "sections", role = "arc.views" }, buttons)
end

function AV.header(model)
	return ui.node("row", { key = "header", role = "arc.header", actions = { menu = { M.new, M.startAll, M.refresh } } }, {
		ui.node("text", { key = "title", text = "ARCLETS", tone = "muted", grow = 1 }),
		if model.loading
			then ui.node("spinner", { key = "refresh", style = "dots", tone = "muted", title = "Refreshing", aria = "Refreshing" })
			else ui.node("icon", { key = "refresh", name = "repeat", tone = "muted", title = "Refresh", aria = "Refresh", actions = { click = "arefresh" } }),
		ui.node("icon", { key = "new", name = "plus", tone = "muted", title = "New Arclet from a profile", aria = "New Arclet", actions = { click = "anew" } }),
	})
end

function AV.arcletMenu(a)
	return { M.go, M.setup, M.shell, if a.state == "STOPPED" then M.start else M.stop }
end

-- One create or setup: its steps with ✓, the running one, and the failed one.
local STEP = {
	done = { icon = "check", tone = "success" },
	run = { icon = "timer", tone = "accent" },
	fail = { icon = "x-circle", tone = "error" },
	todo = { icon = "clock", tone = "muted" },
}
local function opCard(op)
	local items = {}
	for _, step in op.steps do
		local look = STEP[step.status]
		table.insert(items, { label = step.label, detail = step.detail, icon = look.icon, tone = look.tone })
	end
	local body = { ui.list(items) }
	if op.finished then
		table.insert(body, ui.node("item", { key = "dismiss", label = "Dismiss", icon = "x", actions = { click = "adismiss=" .. op.id } }))
	end
	return ui.card({ ui.span(op.title, "strong") }, body, {
		key = "op_" .. op.id, icon = "server",
		meta = if op.err then "failed" elseif op.finished then "done" else "running",
	})
end

local function arcletRow(a)
	local bits = { a.state or "?" }
	if a.region then table.insert(bits, a.region) end
	if a.branch then table.insert(bits, a.branch) end
	local children = {
		ui.node("item", {
			key = "i", grow = 1, label = a.name, detail = a.busy or table.concat(bits, " · "),
			icon = "server", tone = if a.busy then "accent" else (TONE[a.state] or "warning"),
			title = if a.connected then "Click to show its Tern host" else "Click to set it up as a Tern host and show it",
			actions = { click = "ago=" .. a.name, menu = AV.arcletMenu(a) },
		}),
	}
	if a.busy then
		table.insert(children, ui.node("spinner", { key = "st", style = "dots", tone = "accent", title = a.busy, aria = a.busy }))
	elseif a.connected then
		table.insert(children, ui.node("icon", { key = "st", name = "plug", tone = "success", title = "Connected Tern host" }))
	elseif a.saved then
		table.insert(children, ui.node("icon", { key = "st", name = "plug", tone = "muted", title = "Saved Tern host, not connected" }))
	end
	table.insert(children, if a.state == "STOPPED"
		then quick("toggle", "play", "atoggle=" .. a.name, "Start")
		else quick("toggle", "stop", "atoggle=" .. a.name, "Stop"))
	table.insert(children, quick("host", "plug", "ahost=" .. a.name, "Set up as Tern host"))
	table.insert(children, quick("shell", "terminal", "ashell=" .. a.name, "Open shell"))
	return ui.node("row", { key = "ar_" .. a.name, role = "arc.row" }, children)
end

-- The nodes under the header in the Arclets section.
function AV.render(model)
	local nodes = {}
	if model.err then table.insert(nodes, note("err", model.err, "error")) end
	for _, op in model.ops do table.insert(nodes, opCard(op)) end
	local rows = {}
	for _, a in model.arclets do table.insert(rows, arcletRow(a)) end
	if #rows > 0 then
		table.insert(nodes, ui.node("col", { key = "arclets", role = "arc.list" }, rows))
	elseif model.at then
		table.insert(nodes, note("none", "No Arclets yet"))
		table.insert(nodes, ui.node("item", { key = "newone", label = "New Arclet…", icon = "plus", actions = { click = "anew" } }))
	else
		table.insert(nodes, note("none", "Loading Arclets…"))
	end
	if model.at then table.insert(nodes, note("at", "Refreshed " .. model.at)) end
	return nodes
end

return AV
