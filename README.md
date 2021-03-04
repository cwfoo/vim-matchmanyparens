# vim-matchmanyparens
Vim plugin for highlighting matching pairs that enclose the cursor.

![screenshot](screenshot.gif)

Unlike Vim's default matchparen plugin, this plugin:
* Always highlights matching pairs, not only when the cursor is on the opening
  or closing character of the pair.
* Highlights more than one pair at a time.


## Installation
### Installation using Vim's package management
On Unix-like systems:
```sh
mkdir -p ~/.vim/pack/git-plugins/start/
cd ~/.vim/pack/git-plugins/start/
git clone https://github.com/cwfoo/vim-matchmanyparens.git
```

On Windows using the "Git for Windows" Bash terminal:
```sh
mkdir -p ~/vimfiles/pack/git-plugins/start/
cd ~/vimfiles/pack/git-plugins/start/
git clone https://github.com/cwfoo/vim-matchmanyparens.git
```

### Installation using Vundle
You can install this plugin using [Vundle](https://github.com/VundleVim/Vundle.vim)
by adding the following line to your configuration and running `:PluginInstall`:
```vim
Plugin 'cwfoo/vim-matchmanyparens'
```

### Installation using vim-plug
You can install this plugin using [vim-plug](https://github.com/junegunn/vim-plug)
by adding the following line to your configuration and running `:PlugInstall`:
```vim
Plug 'cwfoo/vim-matchmanyparens'
```


## Usage
This is a global plugin that is enabled in all buffers.

As this plugin supersedes Vim's default matchparen plugin, disable matchparen
globally by adding this to your Vim configuration file:
```vim
let g:loaded_matchparen = 1
```

Refer to [doc/vim-matchmanyparens.txt](doc/vim-matchmanyparens.txt) for the
full documentation.


## Commentary
The author started this project because he wanted:
* A replacement for Vim's matchparen plugin that highlights more.
* Something similar to the parentheses highlighting in GNU Guix's
  Reference Manual, and to a lesser extent, the block highlighting in the
  Community Scheme Wiki.

However, after implementing this plugin, the author is sorry to say that he is
unsatisfied with the result: a plugin that makes Vim noticeably less responsive.
Should you use this plugin? Perhaps you should try it.


## License
This project is distributed under the BSD 3-Clause License
(see [LICENSE](LICENSE)).


## Contributing
Bug reports, suggestions, and patches should be submitted on GitHub:
https://github.com/cwfoo/vim-paramotion
