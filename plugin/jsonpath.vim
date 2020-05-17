" plugin/jsonpath.vim
" Author: Victor Hallberg <https://hallberg.cc>

if exists("g:loaded_jsonpath") || v:version < 700 || &cp
  finish
endif
let g:loaded_jsonpath = 1

if !exists('g:jsonpath_delimeter')
  let g:jsonpath_delimeter = '.'
endif

if !exists('g:jsonpath_use_python')
  let g:jsonpath_use_python = has('python3')
endif

command! -nargs=? JsonPath call jsonpath#command(<q-args>)

" au FileType json noremap <buffer> <silent> <expr> <leader>g jsonpath#goto()
" au FileType json noremap <buffer> <silent> <expr> <leader>p jsonpath#echo()

" vim:set et sw=2:
