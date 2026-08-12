return {
  "sindrets/diffview.nvim",
  cmd = {
    "DiffviewClose",
    "DiffviewFileHistory",
    "DiffviewFocusFiles",
    "DiffviewLog",
    "DiffviewOpen",
    "DiffviewRefresh",
    "DiffviewToggleFiles",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>gv", "<cmd>DiffviewOpen<CR>", desc = "Diffview Open" },
    {
      "<leader>gV",
      function()
        vim.ui.input({ prompt = "Diffview base: ", default = "main" }, function(base)
          if base and base ~= "" then
            vim.cmd("DiffviewOpen " .. vim.fn.fnameescape(base) .. "...HEAD")
          end
        end)
      end,
      desc = "Diffview Open Base...HEAD",
    },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "Diffview File History" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Diffview Repo History" },
    { "<leader>gq", "<cmd>DiffviewClose<CR>", desc = "Diffview Close" },
  },
  opts = {
    enhanced_diff_hl = true,
    view = {
      default = {
        layout = "diff2_horizontal",
      },
      merge_tool = {
        layout = "diff3_mixed",
      },
      file_history = {
        layout = "diff2_horizontal",
      },
    },
  },
}
