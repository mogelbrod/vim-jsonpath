" autoload/jsonpath.vim
" Author: Victor Hallberg <https://hallberg.cc>

if exists('g:autoloaded_jsonpath')
  finish
endif
let g:autoloaded_jsonpath = 1

let s:plugin_dir = expand('<sfile>:p:h:h')

let s:escapes = {
  \ 'b': "\b",
  \ 'f': "\f",
  \ 'n': "\n",
  \ 'r': "\r",
  \ 't': "\t",
  \ '"': "\"",
  \ '\': "\\"}

" Returns true iff the lists A and B are equal after converting all items to strings
" The VimScript built-in == operator can't be used since it does strict comparisons
function s:is_equal_lists(a, b) "{{{
  let length = len(a:a)
  if length != len(a:b)
    return 0
  endif

  let i = 0
  while i < length
    if a:a[i] != a:b[i]
      return 0
    endif
    let i += 1
  endwhile

  return 1
endfunction "}}}

function! s:range_obj(range) "{{{
  let default = {
        \ 'from_line': 1,
        \ 'from_column': 1,
        \ 'to_line': line('$'),
        \ 'to_column': strchars(getline('$')),
        \ }
  if empty(a:range)
    return default
  endif
  return extend(a:range, default)
endfunction "}}}

" Parses the current VIM buffer up until a certain offset/end of file
" while keeping track of the current JSON path (using the `stack` list).
" Can optionally look for the path `search_for` on the way, stopping when found.
" Arguments: (search_for, [to_line=$], [to_column=$], [from_line=1])
function! jsonpath#scan_buffer(search_for, ...) "{{{
  " Parse arguments
  let search_for = a:search_for
  if type(search_for) == v:t_string
    let search_for = split(search_for, escape(g:jsonpath_delimeter, '.\'), 1)
  endif
  let is_searching = !empty(search_for)

  let from_line = max([1, get(a:, 3, 1)])
  let to_column = get(a:, 2, 1)

  let to_line = get(a:, 1, 0)
  if to_line < 1 || to_line > line('$')
    let to_line = line('$')
    let to_column = strchars(getline('$'))
  endif

  if g:jsonpath_use_python
    if has('python3')
      return jsonpath#scan_buffer_python(search_for, to_line, to_column, from_line)
    endif

    echom 'g:jsonpath_use_python set but python not found, falling back to vimscript'
  endif

  return jsonpath#scan_buffer_vimscript(search_for, to_line, to_column, from_line)
endfunction "}}}

function! jsonpath#scan_buffer_vimscript(search_for, to_line, to_column, from_line) "{{{
  let is_searching = !empty(a:search_for)

  " Parser state
  let stack = []
  let finished = 0
  let quoted = 0
  let in_key = 1
  let key = 0
  let escaped = 0
  let actions = []

  try
    let lnr = a:from_line
    while lnr <= a:to_line "{{{
      let line = getline(lnr)
      let line_length = len(line)
      let cnr = 1

      while cnr <= line_length "{{{
        let char = line[cnr - 1]
        let stack_modified = 0

        if escaped
          let escaped = 0
          if quoted && in_key
            let key .= s:escapes[char]
          endif

        elseif char ==# '\'
          let escaped = 1

        elseif quoted
          if char ==# '"'
            let quoted = 0
          elseif in_key
            let key .= char
          endif

        elseif char ==# '"'
          let quoted = 1
          if in_key
            let key = ''
          endif

        elseif char ==# ':'
          " Assume new object if encountering key outside root
          if empty(stack)
            call add(stack, key)
          else
            let stack[-1] = key
          endif
          let stack_modified = 1
          let in_key = 0

        elseif char ==# '{'
          call add(stack, -1)
          let in_key = 1

        elseif char ==# '['
          call add(stack, 0)
          let stack_modified = 1
          let in_key = 0

        elseif char ==# '}' || char ==# ']'
          call remove(stack, -1)
          let stack_modified = -1

        elseif char ==# ','
          if type(stack[-1]) == v:t_number && stack[-1] >= 0
            let stack[-1] = stack[-1] + 1
            let stack_modified = 1
          else
            let in_key = 1
          endif

        endif " end of character handling

        if stack_modified
          call add(actions, {
                \ 'bufnr': bufnr('%'),
                \ 'lnum': lnr,
                \ 'col': cnr + 1,
                \ 'text': char . ' = ' . (stack_modified > 0 ? 'push' : 'pop') . ' => ' . join(stack, g:jsonpath_delimeter)
                \})
          
          " Check if the sought search_for path has been reached?
          if stack_modified == 1 && is_searching && s:is_equal_lists(stack, a:search_for)
            return [bufnr('%'), lnr, cnr, 0]
          endif
        endif

        " Abort if end position has been reached
        if !in_key && lnr >= a:to_line && cnr + 1 >= a:to_column
          let finished = !is_searching " search failed if we reached end
          break
        endif

        let cnr += 1
      endwhile "}}}

      if finished
        break
      endif

      let lnr += 1
    endwhile "}}}

    " Reached desired position in cursor mode
    if finished
      if len(stack) > 0 && stack[-1] == -1
        call remove(stack, -1)
      endif

      call add(actions, {
            \ 'bufnr': bufnr('%'),
            \ 'lnum': lnr,
            \ 'col': cnr,
            \ 'text': join(stack, g:jsonpath_delimeter)
            \})
      return stack
    endif

  " Uncomment these lines to enable debugging {{{

  " catch
    " call add(actions, {
          " \ 'bufnr': bufnr('%'),
          " \ 'lnum': lnr,
          " \ 'col': cnr + 1,
          " \ 'text': '"' . v:exception . '" in ' . v:throwpoint
          " \})
  " finally
    " call setqflist(actions, 'r')
    " copen

  "}}}
  endtry

  " Failure
  return []
endfunction "}}}

function! jsonpath#scan_buffer_python(search_for, to_line, to_column, from_line) "{{{
py3 << EOF
import sys
import vim
sys.path.insert(0, vim.eval('s:plugin_dir'))
import jsonpath

stream = jsonpath.CountingLines(vim.current.buffer)
result = jsonpath.scan_stream(
  stream,
  path=vim.eval('a:search_for'),
  line=int(vim.eval('a:to_line')),
  column=int(vim.eval('a:to_column')),
  from_line=int(vim.eval('a:from_line')),
)
EOF

  let result = py3eval('result')
  if empty(result)
    return []
  elseif !empty(a:search_for)
    return [bufnr('%'), result[0], result[1], 0]
  endif

  return result
endfunction "}}}

" Attempts to place the cursor on identifier for the given path
" Arguments: ([search_for=input], [to_line=$], [to_column=$], [from_line=1])
function! jsonpath#goto(...) "{{{
  let search_for = get(a:, 1)
  if empty(search_for)
    let search_for = input('Path (using dot notation): ')
    if empty(search_for)
      echo 'Search aborted'
      return
    endif
  endif

  let pos = jsonpath#scan_buffer(search_for, get(a:, 2), get(a:, 3), get(a:, 4))

  if empty(pos)
    echo 'Path not found: ' . search_for
  else
    call setpos('.', pos)
    echo 'Found on line ' . pos[1]
  endif
endfunction "}}}

" Echoes the path of the identifier under the cursor
" Arguments: ([from_line=1])
function! jsonpath#echo(...) "{{{
  echo 'Parsing buffer...' | redraw
  let path = jsonpath#scan_buffer([], line('.'), col('.'), get(a:, 1, 1))
  let joined = join(path, g:jsonpath_delimeter)
  if len(path)
    if exists('g:jsonpath_register')
      call setreg(g:jsonpath_register, joined)
    endif
    echo 'Path: ' . joined
  else
    echo 'Empty path'
  endif
endfunction "}}}

" Entry point for the :JsonPath command
function! jsonpath#command(input) range "{{{
  " Restore cursor position saved by the :JsonPath command so that line('.')
  " and col('.') returns the correct values
  if exists('b:jsonpath_view')
    call winrestview(b:jsonpath_view)
    unlet b:jsonpath_view
  endif

  if empty(a:input)
    call jsonpath#echo(a:firstline)
  else
    call jsonpath#goto(a:input, a:lastline, 0, a:firstline)
  endif
endfunction "}}}

" vim:set et sw=2:
