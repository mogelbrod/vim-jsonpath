# vim-jsonpath
A Vim plugin which provides ways of navigating JSON document buffers.

* `:JsonPath`:
  Echoes the path to the identifier under the cursor.
* `:JsonPath path.to.prop`:
  Searches the active buffer for the given path, placing the cursor on it if found.

More information is available via `:help jsonpath`.

## Quick Start

```vim
" Install plugin (in this example using vim-plug)
Plug 'mogelbrod/vim-jsonpath'

" Optionally copy path to a named register (* in this case) when calling :JsonPath
let g:jsonpath_register = '*'

" Define mappings for json buffers
au FileType json noremap <buffer> <silent> <leader>d :call jsonpath#echo()<CR>
au FileType json noremap <buffer> <silent> <leader>g :call jsonpath#goto()<CR>
```

### Python support in vim

While not required it is recommended to use a Vim environment with the
`+python3` feature enabled, since the plugin provides a python implementation
that is much faster than the vimscript variant. You can check the availability
using:
```vim
:echo has("python3")
```

## Mappings

Mappings are not provided by default but can easily be added to your `.vimrc`.

* If you only want mappings when working with `.json` files:
  ```vim
  au FileType json noremap <buffer> <silent> <leader>d :call jsonpath#echo()<CR>
  au FileType json noremap <buffer> <silent> <leader>g :call jsonpath#goto()<CR>
  ```

* If you prefer global mappings:
  ```vim
  noremap <buffer> <silent> <leader>d :call jsonpath#echo()<CR>
  noremap <buffer> <silent> <leader>g :call jsonpath#goto()<CR>
  ```

## Configuration

See `:help jsonpath-configuration` for the available configuration options.

## Installation

Use [vim-plug](https://github.com/junegunn/vim-plug),
[Vundle](https://github.com/VundleVim/Vundle.vim),
[pathogen.vim](https://github.com/tpope/vim-pathogen)
or another Vim package manager.

```vim
Plug 'mogelbrod/vim-jsonpath' " example using vim-plug
```
