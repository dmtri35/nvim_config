return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      -- Try to install parsers using the new API
      local ok, install = pcall(require, "nvim-treesitter.install")
      if ok then
        install.prefer_git = false
        -- Ensure parsers are installed
        local parsers = { "cpp", "lua", "go", "c", "python", "bash", "rust", "zig" }
        for _, parser in ipairs(parsers) do
          pcall(function()
            install.ensure_installed(parser)
          end)
        end
      end

      -- Enable treesitter highlighting
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
}
