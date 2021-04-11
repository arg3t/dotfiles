setlocal wrap linebreak nolist

autocmd BufWritePost *.tex :GrammarousCheck --lang=en-GB
