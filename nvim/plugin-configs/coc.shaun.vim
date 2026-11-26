let g:coc_node_resolver = "hello"

nnoremap <C-H> :CocCommand document.toggleInlayHint<CR>

" Extensions coc installs automatically if missing (fresh setup).
let g:coc_global_extensions = ['coc-clangd', 'coc-go', 'coc-json', 'coc-pyright', 'coc-rust-analyzer', 'coc-snippets']
