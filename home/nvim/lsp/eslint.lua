return {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
  },
  root_markers = {
    "eslint.config.ts",
    "eslint.config.mts",
    "eslint.config.cts",
    "eslint.config.js",
    "eslint.config.mjs",
    "eslint.config.cjs",
    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.cjs",
    ".eslintrc.json",
    "package.json",
    ".git",
  },
  settings = {
    validate = "on",
    useESLintClass = true,
    -- Required for ESLint v9/v10 (flat config only). The bundled
    -- vscode-eslint server (vscode-langservers-extracted 4.10.0) crashes
    -- with "Cannot read properties of undefined (reading 'useFlatConfig')"
    -- if `experimental` is missing from settings.
    experimental = { useFlatConfig = true },
    codeAction = {
      disableRuleComment = { enable = true, location = "separateLine" },
      showDocumentation = { enable = true },
    },
    codeActionOnSave = { enable = false, mode = "all" },
    format = false,
    quiet = false,
    onIgnoredFiles = "off",
    rulesCustomizations = {},
    run = "onType",
    problems = { shortenToSingleLine = false },
    nodePath = "",
    workingDirectory = { mode = "auto" },
  },
}
