call plug#begin('~/.local/share/vim/plugged')

" Look & Feel
Plug 'kaicataldo/material.vim'
Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-bufferline'
Plug 'lambdalisue/nerdfont.vim'

" Addons
Plug 'scrooloose/nerdtree'
Plug 'alvan/vim-closetag'
Plug 'vim-scripts/vim-auto-save'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-bundler'
" Plug 'tpope/vim-endwise'
Plug 'tpope/vim-surround'
Plug 'tmhedberg/matchit'
Plug 'kana/vim-textobj-user'
Plug 'jremmen/vim-ripgrep'
Plug 'blarghmatey/split-expander'
Plug 'farmergreg/vim-lastplace'
Plug 'jlanzarotta/bufexplorer'
Plug 'jeffkreeftmeijer/vim-numbertoggle'
Plug 'rhysd/vim-grammarous'
Plug 'chrisbra/NrrwRgn'
Plug 'robertbasic/vim-hugo-helper'
"Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'sheerun/vim-polyglot'
Plug 'M4R7iNP/vim-inky'
" Plug 'ycm-core/YouCompleteMe', { 'do': './install.py' }
Plug 'neoclide/coc.nvim', {'branch': 'release'}

Plug 'vim-scripts/indentpython.vim'
Plug 'frazrepo/vim-rainbow'
Plug 'preservim/nerdcommenter'
Plug 'mileszs/ack.vim'
Plug 'yegappan/taglist'
Plug 'puremourning/vimspector'
Plug 'lervag/vimtex'
" Plug 'wakatime/vim-wakatime'
Plug 'gu-fan/riv.vim'
Plug 'gu-fan/InstantRst'
Plug 'prettier/vim-prettier', { 'do': 'yarn install' }
Plug 'isene/hyperlist.vim'
Plug 'neomutt/neomutt.vim'
Plug 'VebbNix/lf-vim'

" Tmux integration
Plug 'benmills/vimux'
Plug 'christoomey/vim-tmux-navigator'

" File system navigation
Plug 'tpope/vim-eunuch'
Plug 'junegunn/fzf.vim'

" Syntax highlighting
" Plug 'vim-ruby/vim-ruby'
Plug 'noscript/cSyntaxAfter'
Plug 'uiiaoo/java-syntax.vim'
Plug 'elzr/vim-json'
Plug 'tpope/vim-markdown'
Plug 'vim-scripts/cool.vim'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
" Plug 'groenewege/vim-less'
Plug 'leafgarland/typescript-vim'
Plug 'arrufat/vala.vim'

" Syntax errors
" Plug 'vim-syntastic/syntastic'
Plug 'dense-analysis/ale'
Plug 'ntpeters/vim-better-whitespace'

" Git support
Plug 'tpope/vim-fugitive'

" Testing
Plug 'janko-m/vim-test'

" Gist
Plug 'mattn/webapi-vim' | Plug 'mattn/gist-vim'

call plug#end()
