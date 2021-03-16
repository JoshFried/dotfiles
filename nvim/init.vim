let g:polyglot_disabled = ['markdown']
call plug#begin('~/.vim/plugged')
    " Plugin Section
        Plug 'RRethy/vim-illuminate'
        Plug 'Xuyuanp/nerdtree-git-plugin'
        Plug 'airblade/vim-gitgutter'
        Plug 'arzg/vim-rust-syntax-ext'
        Plug 'dense-analysis/ale'
        Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
        Plug 'justinmk/vim-sneak'
        Plug 'kevinhwang91/rnvimr', {'do': 'make sync'}
        Plug 'leafgarland/typescript-vim'
        Plug 'liuchengxu/vim-which-key'
        Plug 'liuchengxu/vista.vim'
        Plug 'mbbill/undotree'
        Plug 'mg979/vim-visual-multi', {'branch': 'master'}
        Plug 'mhinz/vim-startify'
        Plug 'morhetz/gruvbox'
        Plug 'neoclide/coc.nvim', {'branch': 'release'}
        Plug 'noahfrederick/vim-composer'     
        Plug 'noahfrederick/vim-laravel'
        Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
        Plug 'pangloss/vim-javascript'
        Plug 'peitalin/vim-jsx-typescript'
        Plug 'puremourning/vimspector'
        Plug 'rust-lang/rust.vim'
        Plug 'ryanoasis/vim-devicons'
        Plug 'sainnhe/gruvbox-material'
        Plug 'scrooloose/nerdcommenter'
        Plug 'scrooloose/nerdtree'
        Plug 'sheerun/vim-polyglot'
        Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
        Plug 'szw/vim-maximizer'
        Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
        Plug 'tpope/vim-fugitive'
        Plug 'tpope/vim-projectionist'        
        Plug 'tpope/vim-surround'
        Plug 'tpope/vim-vinegar'
        Plug 'unblevable/quick-scope'
        Plug 'vim-airline/vim-airline'
        Plug 'vim-airline/vim-airline-themes'
        Plug 'wakatime/vim-wakatime'
     call plug#end()
    
    if (has('termguicolors'))
        set termguicolors
    endif
  
    "Vim surround mappings"
    " let g:surround_no_mappings = 1
    nmap <leader> as <Plug>Csurround
    let mapleader = " "
    source $HOME/.config/nvim/plug-config/sneak.vim
    source $HOME/.config/nvim/plug-config/quickscope.vim
    source $HOME/.config/nvim/keys/which-key.vim
    source $HOME/.config/nvim/plug-config/ale.vim
    source $HOME/.config/nvim/plug-config/coc.vim
    source $HOME/.config/nvim/plug-config/start-settings.vim
    lua require'nvim-treesitter.configs'.setup {ensure_installed = "all",  highlight = { enable = true } }


    let g:user_emmet_expandabbr_key = '<C-a>,'
    nmap <C-n> :NERDTreeToggle %<CR>

    nnoremap <C-p> :FZF <CR>
    let g:fzf_action = {
    \ 'ctrl-t': 'tab split',
    \ 'ctrl-s': 'split',
    \ 'ctrl-v': 'vsplit'
    \}
    let g:airline_powerline_fonts = 1
     let g:ale_disable_lsp = 1

    map <C-s> :source ~/.config/nvim/init.vim<CR>
    
    let g:coc_global_extensions = ['coc-rust-analyzer', 'coc-phpls', 'coc-emmet', 'coc-jedi', 'coc-pairs',  'coc-css', 'coc-html', 'coc-json', 'coc-prettier', 'coc-tsserver']
    inoremap <expr> <C-j> pumvisible() ? "\<C-n>" : "\<C-j>"
    inoremap <expr> <C-k> pumvisible() ? "\<C-p>" : "\<C-k>"
    " Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
    " Coc only does snippet and additional edit on confirm.
    inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>" 
    
    nnoremap <F5> :UndotreeToggle<CR>

    "move line up/down"
    nnoremap <A-j> :m .+1<CR>==
    nnoremap <A-k> :m .-2<CR>==
    let g:vim_jsx_pretty_colorful_config = 1
    let g:prettier#autoformat = 0 
    autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.yaml,*.html, PrettierAsync

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

colorscheme gruvbox
set number
set cursorline
set expandtab
set nu
set shiftwidth=4
set relativenumber
set splitbelow
set splitright
set hidden
set t_Co=256
set smarttab
set smartindent
set laststatus=0
set background=dark
set nobackup
set nowritebackup
set clipboard=unnamedplus
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
set mouse=a
" syntax enable
set showmatch
set wildmenu
set autoindent
filetype plugin on
" Config Section
