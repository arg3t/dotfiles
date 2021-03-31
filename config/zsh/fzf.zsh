# Setup fzf
# ---------
if [[ ! "$PATH" == */home/yigit/.local/share/fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/home/yigit/.local/share/fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/yigit/.local/share/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/yigit/.local/share/fzf/shell/key-bindings.zsh"
