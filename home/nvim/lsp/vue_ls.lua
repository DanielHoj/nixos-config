-- Prefer project-local vue-language-server (version-matched to the
-- project's @vue/language-core). Fall back to global Mason/npm install.
local function vue_ls_cmd()
  local cwd = vim.fn.getcwd()
  local candidates = {
    cwd .. "/node_modules/.bin/vue-language-server",
    cwd .. "/frontend/node_modules/.bin/vue-language-server",
  }
  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then
      return { path, "--stdio" }
    end
  end
  return { "vue-language-server", "--stdio" }
end

local function tsserver_lib()
  -- Use project-local typescript if present so vue-language-server's
  -- embedded language service uses the same TS as ts_ls/vue-tsc.
  local cwd = vim.fn.getcwd()
  local candidates = {
    cwd .. "/node_modules/typescript/lib",
    cwd .. "/frontend/node_modules/typescript/lib",
  }
  for _, path in ipairs(candidates) do
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  return vim.fn.stdpath("data")
      .. "/mason/packages/typescript-language-server/node_modules/typescript/lib"
end

return {
  cmd = vue_ls_cmd(),
  filetypes = { "vue" },
  root_markers = { "package.json", ".git" },
  init_options = {
    typescript = {
      tsdk = tsserver_lib(),
    },
    vue = {
      hybridMode = true,
    },
  },
  settings = {},
  -- In hybrid mode all TS-domain requests should go to ts_ls (via the
  -- @vue/typescript-plugin). vue_ls advertises these capabilities but
  -- hangs on them in 3.2.5, which makes goto-def take minutes because
  -- nvim waits for every attached server to reply. Strip the
  -- capabilities so nvim only asks ts_ls.
  on_attach = function(client, _)
    if not client.server_capabilities then return end
    local caps_to_disable = {
      "definitionProvider",
      "typeDefinitionProvider",
      "referencesProvider",
      "implementationProvider",
      "declarationProvider",
      "renameProvider",
      "documentHighlightProvider",
      "hoverProvider",
      "signatureHelpProvider",
      "completionProvider",
    }
    for _, cap in ipairs(caps_to_disable) do
      client.server_capabilities[cap] = nil
    end
  end,
}
