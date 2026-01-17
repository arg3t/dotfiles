M = { 'chomosuke/typst-preview.nvim' }
M.ft = 'typst'
M.version = '1.*'
M.opts = {
  open_cmd = 'firefox --no-remote -P typst --name typstff --new-window --kiosk "%s"'
}
return M
