-- True on NixOS, where LSP/DAP binaries are provided by Nix (not Mason).
-- Used to disable Mason-based plugins so they don't try to install FHS
-- binaries that won't run under NixOS's dynamic linker.
return {
  is_nixos = vim.uv.fs_stat("/etc/NIXOS") ~= nil,
}
