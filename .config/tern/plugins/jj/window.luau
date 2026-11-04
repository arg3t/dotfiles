--!nonstrict
-- A host block can't open another block itself, so the log block opens the link
-- `jjdiff:<log pane>`; this route turns it into a `jj.diff` block beside the log.
tern.route.link(function(link, _cx)
	local pane = string.match(link.url, "^jjdiff:(%d+)$")
	if pane then
		return { block = "jj.diff", args = { pane } }
	end
	return nil
end)
