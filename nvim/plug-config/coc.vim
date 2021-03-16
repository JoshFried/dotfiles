
let g:airline_powerline_fonts = 1
nnoremap <silent> <leader> :WhichKey '<Space>'<CR>
nmap <A-1> :NERDTreeToggle % <CR>  
vmap <silent> <C-_> <Plug>NERDCommenterToggle

nmap <silent> <C-_> <Plug>NERDCommenterToggle

" Remap keys for applying codeAction to the current line.
nmap <leader>ac  <Plug>(coc-codeaction)
vmap <leader>a <Plug>(coc-codeaction-selected)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" GoTo code navigation. 
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <F2> <Plug>(coc-rename)
nnoremap <silent> <leader>a  :<C-u>CocList diagnostics<CR>

let g:coc_global_extensions = ['coc-rust-analyzer', 'coc-phpls', 'coc-emmet', 'coc-jedi', 'coc-pairs',  'coc-css', 'coc-html', 'coc-json', 'coc-prettier', 'coc-tsserver']


"vista"
" How each level is indented and what to prepend.
" This could make the display more compact or more spacious.
" e.g., more compact: ["▸ ", ""]
" Note: this option only works the LSP executives, doesn't work for `:Vista ctags`.
map <silent> <F12> :Vista coc<CR>
let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]
let g:vista_executive_for = {
    \ 'cpp' : 'coc',
    \ 'java' : 'coc',
    \ 'python' : 'coc',
    \ 'rust' : 'coc',
    \ 'javascript' : 'coc',
    \ 'typescript' : 'coc',
    \ }
let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]
" let g:vista_icon_indent = ["▸", '']
let g:vista#renderer#enable_icon = 1
let g:vista_sidebar_width = 50
