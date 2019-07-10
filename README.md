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
au FileType json noremap <buffer> <silent> <expr> <leader>p jsonpath#echo()
au FileType json noremap <buffer> <silent> <expr> <leader>g jsonpath#goto()
```

## Mappings

Mappings are not provided by default but can easily be added to your `.vimrc`.

* If you only want mappings when working with `.json` files:
  ```vim
  au FileType json noremap <buffer> <silent> <expr> <leader>p jsonpath#echo()
  au FileType json noremap <buffer> <silent> <expr> <leader>g jsonpath#goto()
  ```

* If you want global mappings:
  ```vim
  noremap <silent> <expr> <leader>p jsonpath#echo()
  noremap <silent> <expr> <leader>g jsonpath#goto()
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
