" autoload/jsonpath.vim
" Author: Victor Hallberg <https://hallberg.cc>

if exists("g:autoloaded_jsonpath")
  finish
endif
let g:autoloaded_jsonpath = 1

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

" Parses the current VIM buffer up until a certain offset/end of file
" while keeping track of the current JSON path (using the `stack` list).
" Can optionally look for the path `search_for` on the way, stopping when found.
function! jsonpath#scan_buffer(search_for, ...) "{{{
  " Parse arguments
  let search_for = a:search_for
  if type(search_for) == v:t_string
    let search_for = split(search_for, escape(g:jsonpath_delimeter, '.\'), 1)
  endif
  let is_searching = !empty(search_for)

  let to_line = get(a:, 1)
  if to_line < 1 || to_line > line('$')
    let to_line = line('$')
  endif

  let to_column = max([0, get(a:, 2)])

  " Parser state
  let stack = []
  let finished = 0
  let parsing_key = 0
  let key = 0
  let quoted = 0
  let escaped = 0
  let actions = []

  try
    let lnr = 1
    while lnr <= to_line "{{{
      let line = getline(lnr)
      let line_length = len(line)
      let cnr = 1

      while cnr <= line_length "{{{
        let char = line[cnr - 1]
        let stack_modified = 0

        if escaped
          let escaped = 0
          if parsing_key
            let key .= s:escapes[char]
          endif

        elseif char ==# '\'
          let escaped = 1

        elseif quoted && char !=# '"'
          if parsing_key
            let key .= char
          endif

        elseif char ==# '"'
          if parsing_key && !quoted
            let key = ''
          endif
          let quoted = quoted ? 0 : 1

        elseif char ==# ':'
          let stack[-1] = key
          let stack_modified = 1
          let parsing_key = 0

        elseif char ==# '{'
          call add(stack, -1)
          let parsing_key = 1

        elseif char ==# '['
          call add(stack, 0)
          let stack_modified = 1
          let parsing_key = 0

        elseif char ==# '}' || char ==# ']'
          call remove(stack, -1)
          let stack_modified = -1

        elseif char ==# ','
          if type(stack[-1]) == v:t_number && stack[-1] >= 0
            let stack[-1] = stack[-1] + 1
            let stack_modified = 1
          else
            let parsing_key = 1
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
          if stack_modified == 1 && is_searching && s:is_equal_lists(stack, search_for)
            return [bufnr('%'), lnr, cnr, 0]
          endif
        endif

        " Abort if end position has been reached
        if !parsing_key && lnr >= to_line && cnr + 1 >= to_column
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

" Attempts to place the cursor on identifier for the given path
function! jsonpath#goto(...) "{{{
  let search_for = get(a:, 1)
  if empty(search_for)
    let search_for = input('Path (using dot notation): ')
    if empty(search_for)
      echo 'Search aborted'
      return
    endif
  endif

  let pos = jsonpath#scan_buffer(search_for)

  if empty(pos)
    echo 'Path not found: ' . search_for
  else
    call setpos('.', pos)
    echo 'Found on line ' . pos[1]
  endif
endfunction "}}}

" Echoes the path of the identifier under the cursor
function! jsonpath#echo() "{{{
  echo 'Parsing buffer...' | redraw
  let path = jsonpath#scan_buffer([], line('.'), col('.'))
  echo len(path) ? 'Path: ' . join(path, g:jsonpath_delimeter) : 'Empty path'
endfunction "}}}

function! jsonpath#copy() "{{{
  echo 'Parsing buffer...' | redraw
  let path = jsonpath#scan_buffer([], line('.'), col('.'))
  let path_str = len(path) ? join(path, g:jsonpath_delimeter) : ''
  if !empty(path_str)
    let @* = path_str
    echo 'Copied ' . path_str
  endif
endfunction "}}}

" Entry point for the :JsonPath command
function! jsonpath#command(input) "{{{
  if empty(a:input)
    call jsonpath#echo()
  else
    call jsonpath#goto(a:input)
  endif
endfunction "}}}

" vim:set et sw=2:
