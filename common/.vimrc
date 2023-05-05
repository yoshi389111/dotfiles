
set expandtab
set tabstop=8
set shiftwidth=2

autocmd FileType make setlocal noexpandtab tabstop=4 softtabstop=0 shiftwidth=4

set list
set listchars=tab:→_,eol:↲,trail:·,extends:»,precedes:«,nbsp:⌷
hi NonText ctermbg=NONE ctermfg=59 guibg=NONE guifg=NONE
hi SpecialKey ctermbg=NONE ctermfg=59 guibg=NONE guifg=NONE

nmap <Esc><Esc> :nohl<CR>
