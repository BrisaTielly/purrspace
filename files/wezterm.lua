local wezterm = require 'wezterm'
local config = {}

-- The "Nerd Font" variant is JetBrains Mono plus the icons LazyVim/lualine use.
-- Without it the nvim UI turns into little boxes.
config.font = wezterm.font_with_fallback {
  'JetBrainsMono Nerd Font',
  'JetBrains Mono',
  'DejaVu Sans Mono',
}

config.font_size = 14.0
config.line_height = 1.12

config.window_background_opacity = 0.98
config.text_background_opacity = 1.0

config.enable_tab_bar = false
config.window_decorations = 'RESIZE'

config.window_padding = {
  left = 18,
  right = 18,
  top = 14,
  bottom = 14,
}

config.default_cursor_style = 'SteadyBlock'

-- same mouse cursor as GNOME (on Wayland WezTerm doesn't inherit it)
config.xcursor_theme = 'Bibata-Modern-Ice'
config.xcursor_size = 24

-- Catppuccin Mocha (built into WezTerm), with a pink cursor
config.color_scheme = 'Catppuccin Mocha'
config.colors = {
  cursor_bg = '#f5c2e7',
  cursor_border = '#f5c2e7',
  cursor_fg = '#1e1e2e',
}

config.default_prog = {
  '/usr/bin/tmux',
  'new-session',
  '-A',
  '-s',
  'main',
}

-- Nearly full-screen window with a margin around it.
-- On Wayland set_position is ignored (only the compositor places windows);
-- set_inner_size still works.
local MARGIN = 40

wezterm.on('gui-startup', function(cmd)
  local screen = wezterm.gui.screens().active
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  local gui = window:gui_window()
  gui:set_inner_size(screen.width - MARGIN * 2, screen.height - MARGIN * 2)
  gui:set_position(screen.x + MARGIN, screen.y + MARGIN)
end)

return config
