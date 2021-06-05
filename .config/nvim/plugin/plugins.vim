call plug#begin('~/.local/share/vim/plugged')

" Look & Feel
Plug 'kaicataldo/material.vim'
Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-bufferline'
Plug 'lambdalisue/nerdfont.vim'

" Addons
Plug 'scrooloose/nerdtree'
Plug 'airblade/vim-gitgutter'

Plug 'tpope/vim-surround'
Plug 'jremmen/vim-ripgrep'
Plug 'blarghmatey/split-expander'
Plug 'sheerun/vim-polyglot'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'junegunn/goyo.vim'

Plug 'vim-scripts/indentpython.vim'
Plug 'preservim/nerdcommenter'
Plug 'mileszs/ack.vim'
Plug 'yegappan/taglist'
Plug 'puremourning/vimspector'
Plug 'lervag/vimtex'

Plug 'gu-fan/riv.vim'
Plug 'isene/hyperlist.vim'
Plug 'neomutt/neomutt.vim'
Plug 'VebbNix/lf-vim'

" Tmux integration
Plug 'benmills/vimux'
Plug 'christoomey/vim-tmux-navigator'

" File system navigation
Plug 'junegunn/fzf.vim'

" Syntax highlighting
Plug 'elzr/vim-json'
Plug 'tpope/vim-markdown'
Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'vim-scripts/cool.vim'
Plug 'justinmk/vim-syntax-extra'
Plug 'arrufat/vala.vim'
call plug#end()
