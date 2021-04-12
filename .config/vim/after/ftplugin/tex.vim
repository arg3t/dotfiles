setlocal wrap linebreak nolist

" Only run LanguageTool between % GRAMMAROUS % tags
map <leader>G magg:/% GRAMMAROUS %<CR>jVnk:GrammarousCheck<CR>:noh<CR>`a
