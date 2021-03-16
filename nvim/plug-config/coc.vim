
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

