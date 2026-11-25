" don't enable autopairs in vim files (really annoying with using quotes for
" comments)

au BufRead *.vim let b:autopairs_enabled = 0

" fix f string quotes for python
au FileType python let b:AutoPairs = AutoPairsDefine({"f'" : "'", "r'" : "'", "b'" : "'"})
