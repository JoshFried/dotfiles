call plug#begin('~/.vim/plugged')
    " Plugin Section
        Plug 'dracula/vim'
        Plug 'ryanoasis/vim-devicons'
        Plug 'neoclide/coc.nvim', {'branch': 'release'}
        Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
        Plug 'leafgarland/typescript-vim'
        Plug 'peitalin/vim-jsx-typescript'
        Plug 'yuezk/vim-js'
        Plug 'maxmellon/vim-jsx-pretty'
        Plug 'tpope/vim-surround'
        Plug 'HerringtonDarkholme/yats.vim'
        Plug 'vim-airline/vim-airline'
        Plug 'vim-airline/vim-airline-themes'       
        Plug 'morhetz/gruvbox'
        Plug 'tasn/vim-tsx'
        Plug 'sainnhe/gruvbox-material'
        Plug 'airblade/vim-gitgutter'
        Plug 'tpope/vim-fugitive'
        Plug 'scrooloose/nerdtree'
        Plug 'Xuyuanp/nerdtree-git-plugin'
        Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
        Plug 'rust-lang/rust.vim'
        Plug 'tpope/vim-fugitive'
        Plug 'liuchengxu/vim-which-key'
        Plug 'wakatime/vim-wakatime'
        Plug 'arzg/vim-rust-syntax-ext'
        Plug 'lifepillar/pgsql.vim'
        Plug 'tpope/vim-vinegar'
        Plug 'liuchengxu/vista.vim'
        Plug 'scrooloose/nerdcommenter'
        Plug 'dense-analysis/ale'
        Plug 'mbbill/undotree'
        Plug 'sheerun/vim-polyglot'
    call plug#end()
    
    if (has('termguicolors'))
        set termguicolors
    endif
   
    "Vim surround mappings"
    " let g:surround_no_mappings = 1
    nmap <leader> as <Plug>Csurround

    let mapleader = " "

    let g:sql_type_default = 'pgsql'
    let b:sql_type_override='pgsql' | set ft=sql
    let g:user_emmet_expandabbr_key = '<C-a>,'
    nmap <C-n> :NERDTreeToggle %<CR>

    nnoremap <C-p> :FZF <CR>
    let g:fzf_action = {
    \ 'ctrl-t': 'tab split',
    \ 'ctrl-s': 'split',
    \ 'ctrl-v': 'vsplit'
    \}
    let g:airline_powerline_fonts = 1
    nnoremap <silent> <leader> :WhichKey '<Space>'<CR>
    
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
    nnoremap <silent> <space>a  :<C-u>CocList diagnostics<CR>

    let b:ale_linters = {
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

    map <C-s> :source ~/.config/nvim/init.vim<CR>
    " Show all diagnostics

    " open new split panes to right and below
    set splitright
    set splitbelow
    " turn terminal to normal mode with escape
    tnoremap <Esc> <C-\><C-n>
    " start terminal in insert mode
    au BufEnter * if &buftype == 'terminal' | :startinsert | endif
    " open terminal on ctrl+n
    let g:coc_global_extensions = ['coc-emmet', 'coc-jedi', 'coc-pairs',  'coc-css', 'coc-html', 'coc-json', 'coc-prettier', 'coc-tsserver']
    inoremap <expr> <C-j> pumvisible() ? "\<C-n>" : "\<C-j>"
    inoremap <expr> <C-k> pumvisible() ? "\<C-p>" : "\<C-k>"
    " Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
    " Coc only does snippet and additional edit on confirm.
    inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>" 
    
    nnoremap <F5> :UndotreeToggle<CR>

    "move line up/down"
    nnoremap <A-j> :m .+1<CR>==
    nnoremap <A-k> :m .-2<CR>==

    let g:prettier#autoformat = 0 
    autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.yaml,*.html PrettierAsync, *.rs

    let g:NERDTreeGitStatusIndicatorMapCustom = {
    \ "Modified"  : "✹",
    \ "Staged"    : "✚",
    \ "Untracked" : "✭",
    \ "Renamed"   : "➜",
    \ "Unmerged"  : "═",
    \ "Deleted"   : "✖",
    \ "Dirty"     : "✗",
    \ "Clean"     : "✔︎",
    \ 'Ignored'   : '☒',
    \ "Unknown"   : "?"
    \ }

    let g:gitgutter_sign_added = '✚'
    let g:gitgutter_sign_modified = '✹'
    let g:gitgutter_sign_removed = '-'
    let g:gitgutter_sign_removed_first_line = '-'
    let g:gitgutter_sign_modified_removed = '-'
    let g:python3_host_prog = '/usr/bin/python3'

    let g:NERDCreateDefaultMappings = 1
    " Add spaces after comment delimiters by default
    let g:NERDSpaceDelims = 1
    " Use compact syntax for prettified multi-line comments
    let g:NERDCompactSexyComs = 1
    " Align line-wise comment delimiters flush left instead of following code indentation
    let g:NERDDefaultAlign = 'left'
    " Set a language to use its alternate delimiters by default
    let g:NERDAltDelims_java = 1
    " Add your own custom formats or override the defaults
    let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }
    " Allow commenting and inverting empty lines (useful when commenting a region)
    let g:NERDCommentEmptyLines = 1
    " Enable trimming of trailing whitespace when uncommenting
    let g:NERDTrimTrailingWhitespace = 1
    " Enable NERDCommenterToggle to check all selected lines is commented or not 
    let g:NERDToggleCheckAllLines = 1

   

    nnoremap <silent> K :call <SID>show_documentation()<CR>
    function! s:show_documentation()
      if (index(['vim','help'], &filetype) >= 0)
        execute 'h '.expand('<cword>')
      else
        call CocAction('doHover')
      endif
    endfunction


    fun! TrimWhitespace()
        let l:save = winsaveview()
        keeppatterns %s/\s\+$//e
        call winrestview(l:save)
    endfun

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
    
    "colour scheme"
    let g:gruvbox_contrast_soft = 1
    let g:gruvbox_bold = 0

syntax enable
colorscheme gruvbox
set number
set cursorline
set expandtab
set nu
set shiftwidth=4
set relativenumber
set hidden
set nowrap
set incsearch
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set scrolloff=8
set signcolumn=yes
set colorcolumn=80
set ai
set tabstop=1
set hls is
set ls=2
syntax enable 
set showmatch
set wildmenu
set autoindent
filetype plugin on
" Config Section
