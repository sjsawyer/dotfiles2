" Check if the filetype is vimwiki
if !exists("b:current_syntax")
    let b:current_syntax = 'vimwiki'
endif

" Highlight "Question:" as red
syn match vimwikiCustomQuestion /Question:/
hi vimwikiCustomQuestion ctermfg=Red guifg=Red

" Highlight "Answer::" as red
syn match vimwikiCustomAnswer /Answer:/
hi vimwikiCustomAnswer ctermfg=Red guifg=Red

" (shaun): add color to bold/italic text
" NOTE: must use `hi` (not `hi def`) since the plugin's syntax/vimwiki.vim
" already defines these groups with `def`, which no-ops if already set.
hi VimwikiBold term=bold cterm=bold gui=bold guifg=#80a0ff
hi VimwikiItalic term=italic cterm=italic gui=italic guifg=#00cc99
