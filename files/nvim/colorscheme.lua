-- ~/.wezterm.lua is Catppuccin Mocha (#1e1e2e background, #cdd6f4 text).
-- Same theme in nvim so the editor blends with the rest of the terminal.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      -- Set to true for a see-through nvim like the rest of WezTerm.
      -- Off by default: code over a translucent background tires the eyes
      -- in long sessions.
      transparent_background = false,
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        mason = true,
        native_lsp = { enabled = true },
        snacks = true,
        treesitter = true,
        which_key = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-mocha" },
  },
}
