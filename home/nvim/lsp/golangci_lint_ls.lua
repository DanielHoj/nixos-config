-- ~/go/bin may not be on nvim's PATH (depends on shell env propagation).
-- Resolve the binaries explicitly: prefer PATH, fall back to ~/go/bin.
local function resolve_go_bin(name)
  local path_bin = vim.fn.exepath(name)
  if path_bin ~= "" then return path_bin end
  return vim.fn.expand("~/go/bin/" .. name)
end

return {
  cmd = { resolve_go_bin("golangci-lint-langserver") },
  filetypes = { "go", "gomod" },
  root_markers = {
    ".golangci.yml",
    ".golangci.yaml",
    ".golangci.toml",
    ".golangci.json",
    "go.work",
    "go.mod",
    ".git",
  },
  init_options = {
    -- Run with the same flags CI uses: `golangci-lint run ./...`
    command = {
      resolve_go_bin("golangci-lint"),
      "run",
      "--output.json.path=stdout",
      "--show-stats=false",
      "--issues-exit-code=1",
    },
  },
}
