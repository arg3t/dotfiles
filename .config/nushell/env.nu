# env.nu — environment setup (runs before config.nu)

# XDG base directories — set defaults if unset
if ($env.XDG_CONFIG_HOME? == null) {
    $env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
}
if ($env.XDG_DATA_HOME? == null) {
    $env.XDG_DATA_HOME = ($env.HOME | path join ".local/share")
}
if ($env.XDG_CACHE_HOME? == null) {
    $env.XDG_CACHE_HOME = ($env.HOME | path join ".cache")
}

# Colored man pages (LESS_TERMCAP env vars consumed by less/man)
$env.LESS_TERMCAP_md = "\u{001b}[01;31m"    # bold red    — headings
$env.LESS_TERMCAP_me = "\u{001b}[0m"        # reset
$env.LESS_TERMCAP_so = "\u{001b}[01;44;33m" # bold yellow on blue — status
$env.LESS_TERMCAP_se = "\u{001b}[0m"        # reset
$env.LESS_TERMCAP_us = "\u{001b}[01;32m"    # bold green  — underlined
$env.LESS_TERMCAP_ue = "\u{001b}[0m"        # reset

# imapfilter config (XDG-compliant path)
$env.IMAPFILTER_CONFIG = ($env.XDG_CONFIG_HOME | path join "imapfilter/config.lua")

# direnv hook — eval (not source) because output is code, not a filename
try { direnv hook nu | save ($nu.cache-dir | path join "direnv-hook.nu") }

# Pre-generate tool init scripts.  source requires parse-time constant paths;
# we write them to $nu.cache-dir here (env.nu runs before config.nu parses).
try { starship init nu | save ($nu.cache-dir | path join "starship-init.nu") }
try { zoxide init nu   | save ($nu.cache-dir | path join "zoxide-init.nu")   }

# Transient prompt — nushell owns this, not starship.
# ^starship prompt --profile=transient runs once here; the rendered ANSI string
# is stored and reused every time nushell collapses a finished prompt line.
$env.TRANSIENT_PROMPT_COMMAND                  = ^starship prompt --profile=transient
$env.TRANSIENT_PROMPT_COMMAND_RIGHT            = ""
$env.TRANSIENT_PROMPT_INDICATOR                = ""
$env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT      = ""
$env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL      = ""
$env.TRANSIENT_PROMPT_MULTILINE_INDICATOR      = ""
