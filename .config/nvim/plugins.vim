call plug#begin('~/.local/share/vim/plugged')

" Look & Feel
Plug 'kaicataldo/material.vim'
Plug 'itchyny/lightline.vim'
Plug 'mengelbrecht/lightline-bufferline'
Plug 'kyazdani42/nvim-tree.lua'

" Addons
Plug 'mhinz/vim-signify' " Signs

Plug 'tpope/vim-surround' " Surround pieces of text with symbols
Plug 'jremmen/vim-ripgrep' " Better Grep
" Plug 'blarghmatey/split-expander'
Plug 'sheerun/vim-polyglot' " Language Packs
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neovim/nvim-lspconfig' " LSP!!!
Plug 'junegunn/goyo.vim' " Center writing

" Autocomplete
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'Dosx001/cmp-commit'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'

Plug 'neomutt/neomutt.vim' " Neomuttrc syntex highlighting
Plug 'VebbNix/lf-vim'

" Tmux integration
Plug 'benmills/vimux'
Plug 'christoomey/vim-tmux-navigator'

" File system navigation
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-file-browser.nvim'
Plug 'gnfisher/nvim-telescope-ctags-plus'
Plug 'jreybert/vimagit'

Plug 'ojroques/vim-oscyank' " OCS Yank PLugin for use with Blink Shell

Plug 'folke/which-key.nvim' " Emacs like keybind suggestions

Plug 'ferrine/md-img-paste.vim'

" === Language Servers ===
Plug 'mfussenegger/nvim-jdtls'

" ==== Syntax highlighting ====
Plug 'joelbeedle/pseudo-syntax' " Pseudocode
Plug 'rhysd/vim-wasm' " Web Assembly
Plug 'elzr/vim-json' " JSON
Plug 'tpope/vim-markdown' "Markdown
Plug 'pangloss/vim-javascript' "Javascript
Plug 'leafgarland/typescript-vim' "Typescript
Plug 'vim-scripts/cool.vim' "COOL, Stanford Compiler Course
Plug 'justinmk/vim-syntax-extra' " A bunch of extra languages
Plug 'arrufat/vala.vim' " Vala
Plug 'Shirk/vim-gas' "GAS Assembly

Plug 'nvim-treesitter/nvim-treesitter' 
Plug 'kyazdani42/nvim-web-devicons' " optional, for file icons
Plug 'nicwest/vim-http'

" === Snippets ===
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'

Plug 'rafamadriz/friendly-snippets' " Some snippets for ultisnips
Plug 'folke/zen-mode.nvim'

Plug 'goolord/alpha-nvim' " Welcome screen 
Plug 'onsails/lspkind.nvim' " Completion icons

" Telescope extensions
Plug 'nvim-telescope/telescope-ui-select.nvim'
Plug 'mickael-menu/zk-nvim'
Plug 'folke/trouble.nvim'
Plug 'josa42/nvim-lightline-lsp'
Plug 'willchao612/vim-diagon'
Plug 'tpope/vim-fugitive'
Plug 'lervag/vimtex'

Plug 'mfussenegger/nvim-dap'
call plug#end()

