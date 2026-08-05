#!/bin/zsh
## __   _______ _____ _____
## \ \ / / ____| ____|_   _|
##  \ V /|  _| |  _|   | |
##   | | | |___| |___  | |
##   |_| |_____|_____| |_|
## Yeet's zsh configuration (sourced by the Home Manager generated .zshrc)
##
## Plugin management, compinit, history, fzf, direnv and zoxide are handled
## declaratively by nix/home/shell.nix. This file is everything personal.

if [ -f "$XDG_CONFIG_HOME"/zsh/secret ]; then
  source "$XDG_CONFIG_HOME"/zsh/secret
fi

# zoxide/fzf/direnv shell hooks. Native HM integration is disabled in
# shell.nix so each hook is timed individually into ~/.cache/zsh-startup.log.
# The `plugins` mark closes the compinit -> autosuggestions/plugins window
# (everything between post_compinit and here) that precedes rc.zsh.
typeset -f _zt_mark >/dev/null && _zt_mark plugins
eval "$(zoxide init zsh)"
typeset -f _zt_mark >/dev/null && _zt_mark zoxide
[[ $options[zle] = on ]] && source <(fzf --zsh)
typeset -f _zt_mark >/dev/null && _zt_mark fzf
eval "$(direnv hook zsh)"
typeset -f _zt_mark >/dev/null && _zt_mark direnv

typeset -f _zt_mark >/dev/null && _zt_mark pre_greet
fortune -a | cowsay | lolcrab
typeset -f _zt_mark >/dev/null && _zt_mark post_greet

# powerlevel10k configuration (theme itself is loaded as an HM plugin)
source ${ZDOTDIR}/p10k.zsh

setopt autocd

fpath=("$XDG_CONFIG_HOME"/zsh/completions $fpath)

source "$XDG_CONFIG_HOME"/zsh/aliases

if [ -f "$XDG_CONFIG_HOME"/zsh/local_aliases ]; then
  source "$XDG_CONFIG_HOME"/zsh/local_aliases
fi

source "$XDG_CONFIG_HOME"/zsh/cmds

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=241,bold'
export KEYTIMEOUT=5

# Sudo Prompt (from the old .profile)
export SUDO_PROMPT="$(printf '\033[38;5;141m\xef\x80\xa3\033[0m Shall you pass?') "

# Clipboard integration for yank/paste widgets
function clip-wrap-widgets() {
    local copy_or_paste=$1
    shift

    for widget in $@; do
        if [[ $copy_or_paste == "copy" ]]; then
            eval "
            function _clip-wrapped-$widget() {
                zle .$widget
                if [[ \$OSTYPE == darwin* ]]; then
                    print -rn -- \$CUTBUFFER | pbcopy
                else
                    wl-copy <<<\$CUTBUFFER
                fi
            }
            "
        else
            eval "
            function _clip-wrapped-$widget() {
                if [[ \$OSTYPE == darwin* ]]; then
                    CUTBUFFER=\$(pbpaste)
                else
                    CUTBUFFER=\$(wl-paste)
                fi
                zle .$widget
            }
            "
        fi

        zle -N $widget _clip-wrapped-$widget
    done
}

# Disable vim mode
bindkey -e

# Ctrl-E sends to vim to edit command Line
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^E" edit-command-line

# Del, End & Home keys
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^A" vi-beginning-of-line

# Better completion
zstyle ':completion:*' matcher-list '' \
  'm:{a-z\-}={A-Z\_}' \
  'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' \
  'r:|?=** m:{a-z\-}={A-Z\_}'


local copy_widgets=(
    vi-yank vi-yank-eol vi-delete vi-backward-kill-word vi-change-whole-line
)

local paste_widgets=(
    vi-put-{before,after}
)

clip-wrap-widgets copy $copy_widgets
clip-wrap-widgets paste  $paste_widgets

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -g -A key

key[Home]="${terminfo[khome]}"
key[End]="${terminfo[kend]}"
key[Insert]="${terminfo[kich1]}"
key[Backspace]="${terminfo[kbs]}"
key[Delete]="${terminfo[kdch1]}"
key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[PageUp]="${terminfo[kpp]}"
key[PageDown]="${terminfo[knp]}"
key[Shift-Tab]="${terminfo[kcbt]}"

# setup key accordingly
[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"       beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"        end-of-line
[[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"     overwrite-mode
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}"  backward-delete-char
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"     delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"         up-line-or-history
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"       down-line-or-history
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"       backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"      forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"     beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"   end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}"  reverse-menu-complete

zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color $realpath'
zstyle ':fzf-tab:*' switch-group ',' '.'

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start { echoti smkx }
	function zle_application_mode_stop { echoti rmkx }
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
	# Disable any leftover terminal mouse reporting before each prompt.
	# A TUI (nvim mouse=a, htop enable_mouse=1) that exits uncleanly can leave
	# mouse mode on; the shell then echoes raw SGR sequences like "0;76;33M".
	function _disable_mouse_report { printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l' }
	add-zle-hook-widget -Uz zle-line-init _disable_mouse_report
fi

typeset -f _zt_mark >/dev/null && _zt_mark post_rc