# Setup fzf
# ---------
if [[ ! "$PATH" == */home/yigit/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/home/yigit/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/yigit/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/yigit/.fzf/shell/key-bindings.zsh"
