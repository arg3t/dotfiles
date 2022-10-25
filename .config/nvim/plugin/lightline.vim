let g:lightline = {
\   'colorscheme': 'material_vim',
\   'active': {
\       'right': [ [ 'lineinfo' ], [ 'percent' ], [ 'fileformat', 'fileencoding', 'filetype' ] ],
\       'left': [ [ 'mode', 'paste' ], [ 'lsp_status' ], [ 'readonly', 'filename' ], [  'lsp_info', 'lsp_hints', 'lsp_errors', 'lsp_warnings', 'lsp_ok' ] ],
\   },
\   'component_function': { },
\   'tabline': {
\     'left': [ ['buffers'] ],
\     'right': [ ],
\   },
\   'component_expand': {
\     'buffers': 'lightline#bufferline#buffers',
\   },
\   'component_type': {
\     'buffers': 'tabsel',
\   }
\ }


function! WordCount()
    let currentmode = mode()
    if !exists("g:lastmode_wc")
        let g:lastmode_wc = currentmode
    endif
    " if we modify file, open a new buffer, be in visual ever, or switch modes
    " since last run, we recompute.
    if &modified || !exists("b:wordcount") || currentmode =~? '\c.*v' || currentmode != g:lastmode_wc
        let g:lastmode_wc = currentmode
        let l:old_position = getpos('.')
        let l:old_status = v:statusmsg
        execute "silent normal g\<c-g>"
        if v:statusmsg == "--No lines in buffer--"
            let b:wordcount = 0
        else
            let s:split_wc = split(v:statusmsg)
            if index(s:split_wc, "Selected") < 0
                let b:wordcount = str2nr(s:split_wc[11])
            else
                let b:wordcount = str2nr(s:split_wc[5])
            endif
            let v:statusmsg = l:old_status
        endif
        call setpos('.', l:old_position)
        return b:wordcount
    else
        return b:wordcount
    endif
endfunction

let g:lightline#trailing_whitespace#indicator = ''

call lightline#lsp#register()
