#!/bin/zsh
## __   _______ _____ _____
## \ \ / / ____| ____|_   _|
##  \ V /|  _| |  _|   | |
##   | | | |___| |___  | |
##   |_| |_____|_____| |_|
## Yeet's zsh configuration

#zmodload zsh/zprof
eval "$(direnv hook zsh)" >> $XDG_RUNTIME_DIR/direnv
#welcome.sh
fortune -a | cowsay | lolcat
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi



source ${ZDOTDIR}/antidote/antidote.zsh
antidote load

# powerlevel10k theme
source ${ZDOTDIR}/p10k.zsh

# starship
# eval "$(starship init zsh)"

#Autocompletion
autoload -Uz compinit
if [[ -n $XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION ]]; then
  compinit -d $XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION
else
  compinit -C -d $XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION
fi;

[[ ! -d  "$XDG_DATA_HOME"/zsh/history ]] || source  "$XDG_DATA_HOME"/zsh/history
HISTSIZE=100000
SAVEHIST=100000
setopt appendhistory
setopt autocd

fpath=("$XDG_CONFIG_HOME"/zsh/completions $fpath)
autoload -Uz compinit
compinit


source "$XDG_CONFIG_HOME"/zsh/aliases

if [ -f "$XDG_CONFIG_HOME"/zsh/local_aliases ]; then
  source "$XDG_CONFIG_HOME"/zsh/local_aliases
fi

if [ -f "$XDG_CONFIG_HOME"/zsh/secret ]; then
  source "$XDG_CONFIG_HOME"/zsh/secret
fi
source "$XDG_CONFIG_HOME"/zsh/cmds

source "/usr/share/fzf/completion.zsh" 2> /dev/null
source "/usr/share/fzf/key-bindings.zsh"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=241,bold'
export KEYTIMEOUT=5

function x11-clip-wrap-widgets() {
    local copy_or_paste=$1
    shift

    for widget in $@; do
        if [[ $copy_or_paste == "copy" ]]; then
            eval "
            function _x11-clip-wrapped-$widget() {
                zle .$widget
                xclip -in -selection clipboard <<<\$CUTBUFFER
            }
            "
        else
            eval "
            function _x11-clip-wrapped-$widget() {
                CUTBUFFER=\$(xclip -out -selection clipboard)
                zle .$widget
            }
            "
        fi

        zle -N $widget _x11-clip-wrapped-$widget
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

x11-clip-wrap-widgets copy $copy_widgets
x11-clip-wrap-widgets paste  $paste_widgets

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
fi
#zprof
