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

config.enable_tab_bar = true
-- A slim bar with the theme's traffic lights, drawn by WezTerm itself.
-- (GNOME's title bar for X11 windows ignores the theme and stays grey.)
config.window_decorations = 'INTEGRATED_BUTTONS | RESIZE'
config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
config.integrated_title_button_alignment = 'Right'
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 40

-- U+F111 (nf-fa-circle) is 18px in this font, close to the 19px dots of the
-- other windows. It is wider than one cell, so a space follows it (WezTerm
-- lets the glyph spill into the next blank cell).
local function dot(color)
  return wezterm.format { { Foreground = { Color = color } }, { Text = '\u{f111}  ' } }
end
config.tab_bar_style = {
  window_hide = dot '#f9e2af',
  window_hide_hover = dot '#f9e2af',
  window_maximize = dot '#a6e3a1',
  window_maximize_hover = dot '#a6e3a1',
  window_close = dot '#f38ba8',
  window_close_hover = dot '#f38ba8',
}

-- a quiet title on the left instead of a tab
wezterm.on('format-tab-title', function(tab)
  return { { Foreground = { Color = '#6c7086' } }, { Text = '  ' .. tab.active_pane.title .. '  ' } }
end)

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
  tab_bar = {
    background = '#181825',
    active_tab = { bg_color = '#181825', fg_color = '#6c7086' },
    inactive_tab = { bg_color = '#181825', fg_color = '#45475a' },
    inactive_tab_hover = { bg_color = '#181825', fg_color = '#a6adc8' },
    -- the integrated buttons use these backgrounds
    new_tab = { bg_color = '#181825', fg_color = '#6c7086' },
    new_tab_hover = { bg_color = '#181825', fg_color = '#cdd6f4' },
  },
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
