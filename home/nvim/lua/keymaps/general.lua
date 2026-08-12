local keymap = vim.keymap

-- General keymaps
keymap.set("n", "<leader>wq", ":wq<CR>", { desc = "Save and quit" })
keymap.set("n", "<leader>qq", ":q!<CR>", { desc = "Force quit" })
keymap.set("n", "<leader>ww", ":w<CR>", { desc = "Save file" })
-- nvim 0.11+ has a built-in `gx` that opens the URL/file under the cursor
-- via the OS handler (xdg-open on Linux). No custom mapping needed.
keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode" })
keymap.set("n", "<space><space>", "<cmd>set nohlsearch<CR>", { desc = "Clear search highlighting" })
keymap.set("n", "<leader><CR>", "o<Esc>", { desc = "Create a new line in normal mode" })
keymap.set("v", "p", '"_dP', { desc = "Paste without overwriting register" })
keymap.set("v", "P", '"_dP', { desc = "Paste without overwriting register" })
keymap.set('t', '<Esc>', [[<C-\><C-n>]], { desc = "Exit terminal mode" })
keymap.set("n", "<A-a>", "ggVG", { desc = "Select entire buffer" })

-- Indent stuff
keymap.set('v', '<', '<gv', { desc = "Indent left and keep selection" })
keymap.set('v', '>', '>gv', { desc = "Indent right and keep selection" })
keymap.set('n', '>', '>>', { desc = "Indent line to the right" })
keymap.set('n', '<', '<<', { desc = "Indent line to the left" })

-- Native diff keymaps
keymap.set("n", "<leader>do", "<cmd>diffget<CR>", { desc = "Diff Obtain" })
keymap.set("n", "<leader>dP", "<cmd>diffput<CR>", { desc = "Diff Put" })
keymap.set("n", "<leader>du", "<cmd>diffupdate<CR>", { desc = "Diff Update" })
keymap.set("n", "<leader>dq", "<cmd>diffoff!<CR>", { desc = "Diff Off" })

-- Quickfix keymaps
keymap.set("n", "<leader>qo", ":copen<CR>", { desc = "Open quickfix list" })
keymap.set("n", "<leader>qf", ":cfirst<CR>", { desc = "Jump to first quickfix list item" })
keymap.set("n", "<leader>qn", ":cnext<CR>", { desc = "Jump to next quickfix list item" })
keymap.set("n", "<leader>qp", ":cprev<CR>", { desc = "Jump to previous quickfix list item" })
keymap.set("n", "<leader>ql", ":clast<CR>", { desc = "Jump to last quickfix list item" })
keymap.set("n", "<leader>qc", ":cclose<CR>", { desc = "Close quickfix list" })

-- lsp keymaps
keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Trigger code actions" })
keymap.set("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Show diagnostics in a floating window" })
keymap.set("n", "<leader>dn", function() vim.diagnostic.jump({ count = 1, float = true }) end,
  { desc = "Jump to next diagnostic" })
keymap.set("n", "<leader>dp", function() vim.diagnostic.jump({ count = -1, float = true }) end,
  { desc = "Jump to previous diagnostic" })


-- Toggle tools
keymap.set("n", "<leader>tl", ":Lazy<CR>", { desc = "Open Lazy.nvim plugin manager" })
keymap.set("n", "<leader>tm", ":Mason<CR>", { desc = "Open Mason.nvim package manager" })

