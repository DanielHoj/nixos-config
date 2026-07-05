{ config, pkgs, lib, ... }:
# tmux ported from ~/dotfiles/tmux/.tmux.conf into native HM.
# Status-bar colors come from Stylix (targets.tmux). Plugins not in nixpkgs
# (ukiyo theme, tmux-line-numbers, agent-indicator) are dropped; ukiyo is
# replaced by the Stylix theme.
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    escapeTime = 0;
    historyLimit = 50000;

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      yank
      tmux-which-key
      {
        plugin = fingers;
        extraConfig = ''
          set -g @fingers-key J
          set -g @fingers-copy-command 'wl-copy'
          set -g @fingers-compact-hints 0
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-processes '~pi'
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];

    extraConfig = ''
      # Window / pane numbering
      setw -g pane-base-index 1
      set -g renumber-windows on

      # Copy mode (vi) -> Wayland clipboard
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"

      # Status bar at top (colors from Stylix)
      set-option -g status-position top
      set -g status-left-length 100
      set -g status-right-length 100

      # Show current command in pane border
      set -g pane-border-status top
      set -g pane-border-format "#{pane_index} #{pane_current_command}"

      # Terminal / color / nvim integration
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-overrides ",xterm-256color:RGB"
      set -g focus-events on
      set -g extended-keys on
      set -g extended-keys-format csi-u

      # Splits open in the same directory
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Pane navigation is Ctrl+hjkl via vim-tmux-navigator (integrates with nvim).
      # (Alt+hjkl pane-nav removed by request.)

      # Window switching (Alt+number)
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5

      # Resize panes with prefix + hjkl
      bind h resize-pane -L 5
      bind j resize-pane -D 5
      bind k resize-pane -U 5
      bind l resize-pane -R 5

      # Swap panes
      bind > swap-pane -D
      bind < swap-pane -U

      # Synchronize panes
      bind S setw synchronize-panes

      # Reload config (HM path)
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Kill session/window/pane
      bind X confirm-before -p "kill-session #S? (y/n)" kill-session
      bind x kill-pane

      # Break pane to new window
      bind b break-pane -d

      # Last session
      bind L switch-client -l

      # Layouts
      bind M-1 select-layout even-horizontal
      bind M-2 select-layout even-vertical
      bind M-3 select-layout main-horizontal
      bind M-4 select-layout main-vertical
      bind M-5 select-layout tiled

      # Preset layouts
      bind D split-window -h -p 30 -c "#{pane_current_path}" \; select-pane -L
      bind T split-window -h -p 50 -c "#{pane_current_path}" \; split-window -v -p 50 -c "#{pane_current_path}" \; select-pane -L
      bind M split-window -h -c "#{pane_current_path}" \; split-window -v -c "#{pane_current_path}" \; select-pane -L \; split-window -v -c "#{pane_current_path}" \; select-layout tiled

      # Popups
      bind g display-popup -E -w 95% -h 95% "lazygit"
      bind H display-popup -E -w 95% -h 95% "btop || htop"
      bind t display-popup -E -w 80% -h 80%

      # sesh session manager
      bind-key "s" run-shell "sesh connect \"$(
          sesh list | fzf-tmux -p 55%,60% \
              --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
              --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
              --bind 'tab:down,btab:up' \
              --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
              --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
              --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' \
              --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
              --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
              --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)'
      )\""
    '';
  };

  home.packages = with pkgs; [ sesh ];
}
