" set <leader> to space (do this before code using <Leader> is loaded)
let mapleader = " "

" allow overriding settings per project via existence of local .vimrc
set secure exrc

" enable true color support https://jdhao.github.io/2018/10/19/tmux_nvim_true_color/
set termguicolors


" load plugins (and specify plugins here)
source $HOME/.config/nvim/vim-plug/plugins.vim

" load plugin config modifications (add new configs and override defaults)
runtime! plugin-configs/*.vim


" shaun test
"let g:solarized_termcolors=256
"set t_Co=256

" set color scheme after plugins are loaded
colorscheme solarized
" colorscheme gruvbox
set background=dark

" folds
set foldmethod=indent
set nofoldenable

" (shaun): TRIAL RUN 2023-02-10
" exclude trailing whitespace when, e.g., selecting to end of line
" update: disabled, excludes last char when visually selecting...
" set selection=exclusive

" toggle background via ,bg
map <Leader>bg :let &background = ( &background == "dark"? "light" : "dark")<CR>

" Hilight all search matches
set hlsearch
" Map <C-L> (redraw screen) to also turn off search highlighting until the
" next search
nnoremap <C-L> :nohl<CR><C-L>

" simple surrounding visual selection in quotes, etc.
vmap <Leader>q" c""P
vmap <Leader>q' c''P
vmap <Leader>q( c()P
vmap <Leader>q[ c[]P
vmap <Leader>q{ c{}P
vmap <Leader>q< c<>P
vmap <Leader>q` c``P
vmap <Leader>q_ c__P
vmap <Leader>q* c**P

" change word under cursor to upper case
nnoremap <Leader>uu gUiwe

" move lines in visual selection up or down (https://vim.fandom.com/wiki/Moving_lines_up_or_down)
" Update (2024-02-29): commented out; these tend to conflict with other
"                      things... e.g. J for joining selection
" vnoremap J :m '>+1<CR>gv=gv
" vnoremap K :m '<-2<CR>gv=gv

" When in parenthesis, move following word into parentheses
" e.g. (|)hello => (hello|)
inoremap <M-w> <esc>lxepi

" save (conflicts with Coc symbol search at the moment)
" nmap <Leader>s :w

" highlight as <you are adding> to your search
set incsearch

" start scrolling when you are `n` characters away from top/bottom
set scrolloff=20 " used to be 8

" scroll faster (determine if this is good or not)
set scrolljump=2

" Enable copying to clipboard
set clipboard=unnamed

" Instead of failing a command because of unsaved changes, instead raise a
" dialogue asking if you wish to save changed files.
set confirm

set nu

" lower case insensitive seach, upper case sensitive (require both)
set ignorecase
set smartcase

" Map // to search for visually selected text
vnoremap // y/<C-R>"<CR>

" Global tab defaults
set tabstop=4
set softtabstop=4
set shiftwidth=4

" Use - as part of vim's definition of a word, except for c where it conflicts
" with the arrow operator ->
set iskeyword+=-
au BufNewFile,BufRead *.c set
    \ set iskeyword-=-

" Extension specific (override any plugins)
au BufNewFile,BufRead *.py set
    \ textwidth=79
    \ fileformat=unix
    \ colorcolumn=80
au BufNewFile,BufRead *.java set
    \ textwidth=100
    \ colorcolumn=101
au BufNewFile,BufRead *.rst set
    \ textwidth=80
    \ colorcolumn=81
au BufNewFile,BufRead *.md set
    \ textwidth=80
    \ colorcolumn=81
au BufNewFile,BufRead *.y{,a}ml{,.j2} set
    \ filetype=yaml
    \ tabstop=2
    \ softtabstop=2
    \ shiftwidth=2
au BufNewFile,BufRead COMMIT_EDITMSG set
    \ textwidth=72
    \ colorcolumn=73
au BufNewFile,BufRead *.wiki set
    \ textwidth=120
    \ colorcolumn=121
    \ nowrap
au BufNewFile,BufRead *.sql{,.tftpl} set
    \ filetype=sql

" Function to show all current vim mappings
" https://stackoverflow.com/questions/24842063/how-to-search-in-the-vim-mapping-listing
function! s:ShowMaps()
  let old_reg = getreg("a")          " save the current content of register a
  let old_reg_type = getregtype("a") " save the type of the register as well
try
  redir @a                           " redirect output to register a
  " Get the list of all key mappings silently, satisfy "Press ENTER to continue"
  silent map | call feedkeys("\<CR>")    
  redir END                          " end output redirection
  vnew                               " new buffer in vertical window
  put a                              " put content of register
  " Sort on 4th character column which is the key(s)
  %!sort -k1.4,1.4
finally                              " Execute even if exception is raised
  call setreg("a", old_reg, old_reg_type) " restore register a
endtry
endfunction
com! ShowMaps call s:ShowMaps()      " Enable :ShowMaps to call the function

" nnoremap \m :ShowMaps<CR>            " Map keys to call the function

" Function to remove color codes, e.g., from <proc> | vim -
function! s:RemoveEscapeCodes()
  execute ':%s/\[[0-9;]*m//g'
endfunction
com! RemoveEscapeCodes call s:RemoveEscapeCodes()      " Enable :RemoveEscapeCodes to call the function

" Function to strip trailing whitespace
function! s:StripTrailingWhitespace()
  execute ':%s/\s\+$//g'
endfunction
com! RemoveEscapeCodes call s:StripTrailingWhitespace()      " Enable :RemoveEscapeCodes to call the function
