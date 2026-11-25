" open automatically when vim starts autocmd vimenter * NERDTree How can I
" open a NERDTree automatically when vim starts up if no files were specified?
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Specific mapping to open nerdtree
map <C-n> :NERDTreeToggle<CR>

" Specific mapping to open nerdtree
map <C-f> :NERDTreeFind<CR>

" Close vim if only window open is nerdtree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" bd will close vim when NERDTree is open which is annoying
command Bd bp\|bd <CR>
