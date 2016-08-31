set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.

Plugin 'pangloss/vim-javascript'

Plugin 'tomlion/vim-solidity'

Plugin 'godlygeek/tabular'

Plugin 'walm/jshint.vim'

Plugin 'Valloric/YouCompleteMe'

Plugin 'Valloric/ListToggle'

Plugin 'scrooloose/syntastic'

Plugin 'marijnh/tern_for_vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line





nnoremap <leader>jd :YcmCompleter GoToDefinitionElseDeclaration<CR>

let g:ycm_global_ycm_extra_conf = '~/.vim/bundle/YouCompleteMe/third_party/ycmd/cpp/ycm/.ycm_extra_conf.py'
"不显示开启vim时检查ycm_extra_conf文件的信息
let g:ycm_confirm_extra_conf = 0
"开启基于tag的补全，可以在这之后添加需要的标签路径
let g:syntastic_always_populate_loc_list = 1
"<leader>
let mapleader=','
"修改对C函数的补全快捷键，默认是CTRL + space
let g:ycm_key_invoke_completion='<F2>'
"开启语义补全
let g:ycm_seed_identifiers_with_syntax= 1
"在注释输入中也能补全
let g:ycm_complete_in_comments = 1
"在字符串输入中也能补全
let g:ycm_complete_in_strings = 1 


if filereadable(expand('%:p<'))
	let g:c_syntax_for_h=1
endif







"自动缩进
set autoindent
""语法高亮
syntax on
""不自动换行
set nowrap
"智能对齐方式
set smartindent
"一个tab是4个字符
set tabstop=4
"按一次tab前进4个字符
set softtabstop=4
"显示行号
set number
"缺省不产生备份文件
set nobackup

set shiftwidth=4

set backspace=indent,eol,start

imap () ()<Left>

imap [] []<Left>

imap {} {}<Left>

imap "" ""<Left>

imap '' ''<Left>

imap <> <><Left>
