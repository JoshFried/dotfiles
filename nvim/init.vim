let g:polyglot_disabled = ['markdown']
call plug#begin('~/.vim/plugged')
    " Plugin Section
        Plug 'RRethy/vim-illuminate'
        Plug 'Xuyuanp/nerdtree-git-plugin'
        Plug 'airblade/vim-gitgutter'
        Plug 'dense-analysis/ale'
        Plug 'kevinhwang91/rnvimr', {'do': 'make sync'}
        Plug 'leafgarland/typescript-vim'
        Plug 'liuchengxu/vim-which-key'
        Plug 'liuchengxu/vista.vim'
        Plug 'machakann/vim-sandwich'
        Plug 'mbbill/undotree'
        Plug 'mg979/vim-visual-multi', {'branch': 'master'}
        Plug 'mhinz/vim-startify'
        Plug 'morhetz/gruvbox'
        Plug 'neoclide/coc.nvim', {'branch': 'release'}
        Plug 'noahfrederick/vim-composer'     
        Plug 'noahfrederick/vim-laravel'
        Plug 'nvim-lua/plenary.nvim'
        Plug 'nvim-lua/popup.nvim'
        Plug 'nvim-lua/telescope.nvim'
        Plug 'nvim-telescope/telescope-fzy-native.nvim'
        Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
        Plug 'pangloss/vim-javascript'
        Plug 'peitalin/vim-jsx-typescript'
        Plug 'preservim/nerdcommenter'
        Plug 'puremourning/vimspector'
        Plug 'rust-lang/rust.vim'
        Plug 'ryanoasis/vim-devicons'
        Plug 'sainnhe/gruvbox-material'
        Plug 'scrooloose/nerdtree'
        Plug 'styled-components/vim-styled-components', { 'branch': 'main' }
        Plug 'szw/vim-maximizer'
        Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
        Plug 'tpope/vim-fugitive'
        Plug 'tpope/vim-projectionist'        
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
    source $HOME/.config/nvim/plug-config/vimspector.vim
    source $HOME/.config/nvim/plug-config/nerd-commenter.vim
    source $HOME/.config/nvim/plug-config/nerd-git-status.vim
    source $HOME/.config/nvim/plug-config/telescope.vim 

    lua require'nvim-treesitter.configs'.setup {ensure_installed = "all",  highlight = { enable = true } }


    let g:user_emmet_expandabbr_key = '<C-a>,'
    nmap <C-n> :NERDTreeToggle %<CR>

    let g:airline_powerline_fonts = 1
   
    map <C-s> :source ~/.config/nvim/init.vim<CR>
    
    inoremap <expr> <C-j> pumvisible() ? "\<C-n>" : "\<C-j>"
    inoremap <expr> <C-k> pumvisible() ? "\<C-p>" : "\<C-k>"
    " Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
    " Coc only does snippet and additional edit on confirm.
    inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>" 
    
    " undotree"
    nnoremap <F5> :UndotreeToggle<CR>

    "move line up/down"
    nnoremap <A-j> :m .+1<CR>==
    nnoremap <A-k> :m .-2<CR>==
    

    let g:vim_jsx_pretty_colorful_config = 1
    let g:prettier#autoformat = 0 
    autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.yaml,*.html, PrettierAsync

    let g:python3_host_prog = '/usr/bin/python3'
  
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
