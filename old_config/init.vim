 call plug#begin()
" The default plugin directory will be as follows:
"   - Vim (Linux/macOS): '~/.vim/plugged'
"   - Vim (Windows): '~/vimfiles/plugged'
"   - Neovim (Linux/macOS/Windows): stdpath('data') . '/plugged'
" You can specify a custom plugin directory by passing it as the argument
"   - e.g. `call plug#begin('~/.vim/plugged')`
"   - Avoid using standard Vim directory names like 'plugin'

" Make sure you use single quotes"

" autocompletes
Plug 'p00f/clangd_extensions.nvim'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

" vsnip (snippets)
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'

" lsp
Plug 'neovim/nvim-lspconfig' 
Plug 'ziglang/zig.vim'

" themes
Plug 'dracula/vim', { 'name': 'dracula' }
Plug 'phha/zenburn.nvim'
Plug 'rebelot/kanagawa.nvim'
Plug 'morhetz/gruvbox'
Plug 'sainnhe/gruvbox-material'

" treesitter
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/nvim-treesitter-textobjects'

" telescope
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

" git
Plug 'tpope/vim-fugitive'

" misc fun stuff
Plug 'eandrju/cellular-automaton.nvim'

" Status line
Plug 'nvim-lualine/lualine.nvim'
Plug 'nvim-tree/nvim-web-devicons'

" tree explorer
" Plug 'nvim-tree/nvim-tree.lua'

" oil
Plug 'stevearc/oil.nvim'

" vim api lsp
Plug 'folke/neodev.nvim'

" surround
Plug 'kylechui/nvim-surround'

" copilot
Plug 'github/copilot.vim'

call plug#end()

" Important!!
if has('termguicolors')
  set termguicolors
endif

" For better performance
let g:gruvbox_material_better_performance = 1

" Disabling zig fmt on save
let g:zig_fmt_autosave = 0

colorscheme gruvbox-material

lua require("lsp_config")
lua require("treesitter")
lua require("lualine_setup")
" lua require("nvimtree_setup")
lua require("telescope_setup")

" embed, put default configs here
lua <<EOF
require("oil").setup()
require("nvim-surround").setup()
EOF

" line number highlight
highlight CursorLine cterm=NONE ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
set cursorline

" NvimTree float bg has the same color, similar to default telescope
" highlight NvimTreeNormalFloat guibg=NONE guifg=NONE

" autocmd BufWritePre *.go lua vim.lsp.buf.format()
" autocmd BufWritePre *.go lua goimports(1000)

" line number
set nu
set rnu
set completeopt=menu,menuone,noselect

" general indent
set tabstop=2
set shiftwidth=2
set expandtab
set cindent

" disable mouse
set mouse=

tnoremap <esc> <C-\><C-N>

" press esc disables highlight on /
noremap <silent> <esc> :noh<cr><esc>
