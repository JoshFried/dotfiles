    let g:ale_linters = {
    \ 'python': ['flake8'], 
    \ 'rust': ['analyzer']}
    " Write this in your vimrc file
    let g:ale_fixers = {
    \ 'python': ['yapf'],
    \ 'rust' : ['rustfmt']
    \ }
    let g:ale_set_loclist = 0
    let g:ale_set_quickfix = 1
    let g:ale_fix_on_save = 1
    let g:ale_disable_lsp = 1
     

    let g:ale_disable_lsp = 1

