local function in_tmux()
  return vim.env.TMUX ~= nil and vim.env.TMUX ~= ""
end

if not in_tmux() then
  return
end

local ok_devicons, devicons = pcall(require, "nvim-web-devicons")

local aug = vim.api.nvim_create_augroup("TmuxRename", { clear = true })

local function shell_escape(s)
  return "'" .. tostring(s):gsub("'", [['"'"']]) .. "'"
end

local function tmux_set_pane_title(title)
  if not in_tmux() then return end
  vim.fn.system("tmux select-pane -T " .. shell_escape(title))
end

local function hostname()
  local uv = vim.uv or vim.loop
  local h = (uv and uv.os_gethostname and uv.os_gethostname()) or vim.env.HOSTNAME
  if h and h ~= "" then return h end
  return (vim.fn.systemlist("hostname")[1] or "unknown-host")
end

local function current_title()
  local full = vim.api.nvim_buf_get_name(0)
  local base = (full == "" and "[No Name]") or vim.fn.fnamemodify(full, ":t")

  local icon = ""
  if ok_devicons then
    local ext = vim.fn.fnamemodify(base, ":e")
    local ico = devicons.get_icon(base, ext, { default = true })
    if ico then icon = ico .. " " end
  end

  -- local tabnr = vim.fn.tabpagenr()
  -- return string.format("%s[%d] %s", icon, tabnr, base)
  return string.format("%s%s", icon, base)
end

local function update_title()
  tmux_set_pane_title(current_title())
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter", "TabEnter", "WinEnter" }, {
  group = aug,
  callback = update_title,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = aug,
  callback = function()
    tmux_set_pane_title(hostname())
  end,
})
