return {
  "mrjones2014/smart-splits.nvim",
  keys = {
    { "<A-h>", function() require("smart-splits").resize_left() end, desc = "Resize split to the left" },
    { "<A-j>", function() require("smart-splits").resize_down() end, desc = "Resize split downwards" },
    { "<A-k>", function() require("smart-splits").resize_up() end, desc = "Resize split upwards" },
    { "<A-l>", function() require("smart-splits").resize_right() end, desc = "Resize split to the right" },
    { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move cursor to the left split" },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move cursor to the down split" },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move cursor to the up split" },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move cursor to the right split" },
  },
}
