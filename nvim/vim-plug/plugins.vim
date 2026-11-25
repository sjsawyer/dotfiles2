" auto-install vim-plug
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  "autocmd VimEnter * PlugInstall
  "autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/autoload/plugged')

    " Better Syntax Support
    Plug 'sheerun/vim-polyglot'
    " File Explorer
    Plug 'scrooloose/NERDTree'
    " Fancy icons for nerdtree
    Plug 'ryanoasis/vim-devicons'
    "Auto pairs for '(' '[' '{'
    Plug 'jiangmiao/auto-pairs'
    " status bar
    Plug 'vim-airline/vim-airline'
    " solarized theme
    Plug 'ishan9299/nvim-solarized-lua'
    " gruvbox theme
    Plug 'morhetz/gruvbox'
    " vimwiki
    Plug 'vimwiki/vimwiki'
    " Telescope related
    Plug 'nvim-lua/popup.nvim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-telescope/telescope.nvim'
    " Language Server
    " Plug 'neovim/nvim-lspconfig'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    " Snippets for coc
    Plug 'honza/vim-snippets'
    " ctrl p TODO: replace with telescope
    Plug 'kien/ctrlp.vim'
    " Auto indent detection
    Plug 'tpope/vim-sleuth'
    " Ability to pass rg arguments to Telescope
    Plug 'nvim-telescope/telescope-live-grep-args.nvim'
    " git goodness
    Plug 'tpope/vim-fugitive'
    " needed?
    Plug 'nvim-treesitter/nvim-treesitter'


call plug#end()
