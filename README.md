# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Machine-local configuration

Some settings can be customized per-machine by creating `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    alacritty_font_size = 22.5
    ghostty_font_size = 22
    ghostty_adjust_cell_height = 1
```

### Available variables

| Variable | Default | Used in |
|----------|---------|---------|
| `alacritty_font_size` | 18 | Alacritty |
| `ghostty_font_size` | 18 | Ghostty |
| `ghostty_adjust_cell_height` | 0 | Ghostty |
