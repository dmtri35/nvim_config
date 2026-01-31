-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Disable netrw (using Oil instead)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Set leader key before lazy
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup("plugins", {
  change_detection = {
    notify = false,
  },
})

-- General settings
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.cindent = true
vim.opt.mouse = ""
vim.opt.cursorline = true

-- Colorscheme
vim.g.gruvbox_material_better_performance = 1
vim.cmd.colorscheme("gruvbox-material")

-- Line number highlight
vim.api.nvim_set_hl(0, "CursorLine", { bg = "NONE", fg = "NONE" })

-- Keymaps
vim.keymap.set("t", "<esc>", [[<C-\><C-N>]])
vim.keymap.set("n", "<esc>", "<cmd>noh<cr><esc>", { silent = true })

-- Zig settings
vim.g.zig_fmt_autosave = 0
