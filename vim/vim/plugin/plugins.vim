call plug#begin('~/.vim/plugged')

" Themes
"
Plug 'hzchirs/vim-material'

" Addons
Plug 'scrooloose/nerdtree'
Plug 'yegappan/mru'
Plug 'alvan/vim-closetag'
Plug 'vim-scripts/vim-auto-save'
Plug 'airblade/vim-gitgutter'
"Plug 'ervandew/supertab'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-surround'
Plug 'tmhedberg/matchit'
Plug 'kana/vim-textobj-user'
Plug 'jremmen/vim-ripgrep'
Plug 'blarghmatey/split-expander'
Plug 'farmergreg/vim-lastplace'
Plug 'jlanzarotta/bufexplorer'
Plug 'jeffkreeftmeijer/vim-numbertoggle'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'sheerun/vim-polyglot'
Plug 'M4R7iNP/vim-inky'
Plug 'vim-airline/vim-airline'
Plug 'ycm-core/YouCompleteMe'
Plug 'vim-scripts/indentpython.vim'
Plug 'frazrepo/vim-rainbow'
Plug 'preservim/nerdcommenter'
Plug 'mileszs/ack.vim'
Plug 'yegappan/taglist'
Plug 'ryanoasis/vim-devicons'
Plug 'puremourning/vimspector'
Plug 'lervag/vimtex'
Plug 'gi1242/vim-tex-autoclose'
" Plug 'neoclide/coc.nvim', {'branch': 'release'}

"
" if has('nvim')
"   Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" else
"   Plug 'Shougo/deoplete.nvim'
"   Plug 'roxma/nvim-yarp'
"   Plug 'roxma/vim-hug-neovim-rpc'
" endif
" let g:deoplete#enable_at_startup = 1


" Tmux integration
Plug 'benmills/vimux'
Plug 'christoomey/vim-tmux-navigator'

" File system navigation
Plug 'tpope/vim-eunuch'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Syntax highlighting
" Plug 'vim-ruby/vim-ruby'
Plug 'noscript/cSyntaxAfter'
Plug 'uiiaoo/java-syntax.vim'
Plug 'tpope/vim-endwise'
Plug 'elzr/vim-json'
Plug 'tpope/vim-markdown'
Plug 'vim-scripts/cool.vim'
" Plug 'groenewege/vim-less'
" Plug 'tpope/vim-haml'
" Plug 'pangloss/vim-javascript'
" Plug 'mxw/vim-jsx'
" Plug 'jparise/vim-graphql'
Plug 'leafgarland/typescript-vim'

" Syntax errors
Plug 'vim-syntastic/syntastic'
Plug 'ntpeters/vim-better-whitespace'

" Git support
Plug 'tpope/vim-fugitive'

" Testing
Plug 'janko-m/vim-test'

" Gist
Plug 'mattn/webapi-vim' | Plug 'mattn/gist-vim'

call plug#end()
