# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Machine-local configuration

Some settings can be customized per-machine by creating `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    font_size = 22.5
```

### Available variables

| Variable | Default | Used in |
|----------|---------|---------|
| `font_size` | 18 | Alacritty, Ghostty |
