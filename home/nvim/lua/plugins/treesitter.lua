-- nvim-treesitter `main` branch is used purely as a parser manager.
-- Highlights/indent come from Neovim's built-in `vim.treesitter` (0.11+).
-- The legacy `master` branch is frozen and incompatible with nvim 0.12.

local parsers = {
  "c",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "javascript",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "nix",
  "python",
  "query",
  "rust",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "vue",
  "yaml",
}

-- Filetype map: tree-sitter language → filetypes we want to treesitter-enable.
-- (Keys mostly match parser names; vue/markdown/etc. need explicit mappings.)
local ft_to_lang = {
  c = { "c" },
  go = { "go" },
  gomod = { "gomod" },
  gosum = { "gosum" },
  gowork = { "gowork" },
  javascript = { "javascript", "javascriptreact" },
  json = { "json", "jsonc" },
  lua = { "lua" },
  markdown = { "markdown" },
  nix = { "nix" },
  python = { "python" },
  query = { "query" },
  rust = { "rust" },
  tsx = { "typescriptreact" },
  typescript = { "typescript" },
  vim = { "vim" },
  vimdoc = { "help" },
  vue = { "vue" },
  yaml = { "yaml" },
}

local highlight_filetypes = {}
for _, fts in pairs(ft_to_lang) do
  vim.list_extend(highlight_filetypes, fts)
end

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    require("nvim-treesitter").install(parsers)

    local group = vim.api.nvim_create_augroup("Me3csTreesitter", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = highlight_filetypes,
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })

    -- Use nvim-treesitter's indentexpr where available.
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = highlight_filetypes,
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
