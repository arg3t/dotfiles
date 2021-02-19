function! RunCommand()
    call inputsave()
    let replacement = input('Enter Command: ')
    call inputrestore()
    execute 'call VimuxRunCommand("'.replacement.'")'
endfunction

nnoremap <F5> :call RunCommand()<CR>
nnoremap <F6> :VimuxRunLastCommand<CR>
