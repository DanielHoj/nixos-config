-- Resolve @vue/typescript-plugin from the project's node_modules first
-- so version matches @vue/language-core (mismatch causes slow goto-def
-- via cross-version IR shims). Falls back to the global install.
local function find_vue_ts_plugin()
  local cwd = vim.fn.getcwd()
  local candidates = {
    cwd .. "/node_modules/@vue/typescript-plugin",
    cwd .. "/frontend/node_modules/@vue/typescript-plugin",
  }
  for _, path in ipairs(candidates) do
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  return vim.fn.trim(vim.fn.system("npm root -g")) .. "/@vue/typescript-plugin"
end

return {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
  },
  root_markers = {
    "package.json",
    "tsconfig.json",
    "jsconfig.json",
    ".git",
  },
  init_options = {
    plugins = {
      {
        name = "@vue/typescript-plugin",
        location = find_vue_ts_plugin(),
        languages = { "vue" },
      },
    },
  },
  single_file_support = true,
}
