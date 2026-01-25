require("lualine").setup {
  tabline = {
    lualine_a = {
      {
        'tabs',
        mode = 2,
        max_length = vim.o.columns,
        use_mode_colors = true,
        fmt = function(name, context)
          -- Show + if buffer is modified in tab
          local buflist = vim.fn.tabpagebuflist(context.tabnr)
          local winnr = vim.fn.tabpagewinnr(context.tabnr)
          local bufnr = buflist[winnr]
          local mod = vim.fn.getbufvar(bufnr, '&mod')

          return name .. (mod == 1 and ' +' or '')
        end
      }
    }
  },
  sections = {
    lualine_c = {
      {
        'filename',
        newfile_status = true,
        path = 1,
      }
    },
  },
  options = {
    theme = "gruvbox-material",
  }
}
