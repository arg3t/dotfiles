return {
  ensure_installed = { "html", "json", "c", "c++", "css", "bash", "lua", "java", "python", "javascript", "latex", "markdown" },
  sync_install = false,
  auto_install = true,

  ignore_install = { },

  highlight = {
    enable = true,

    additional_vim_regex_highlighting = { "markdown" }
  },
}
