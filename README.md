# vim-jsonpath
A Vim plugin which provides ways of navigating JSON document buffers.

* `:JsonPath`:
  Echoes the path to the identifier under the cursor.
* `:JsonPath path.to.prop`:
  Searches the active buffer for the given path, placing the cursor on it if found.

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

## Installation

Use [Vundle](https://github.com/VundleVim/Vundle.vim),
[pathogen.vim](https://github.com/tpope/vim-pathogen) or another Vim package
manager.
