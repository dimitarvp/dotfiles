# Rules for this repository

This repository is PUBLIC on GitHub and, at the same time, the owner's private dotfiles
workbench. Everything committed here is world-readable, forever, git history included.

## Before every commit and every push

- Read the whole staged diff (`git diff --cached`) and check every line for private content:
  credentials in any form (passwords, password hashes, tokens, keys, cookies), home-network
  facts (LAN and WAN addresses, MAC addresses, interface names, router models and addresses,
  ISP resolvers, VPN layouts), server layouts (backup paths, dataset names, runbooks), employer
  and work references (paths, hostnames, key names), personal data.
- Private content goes in encrypted. `chezmoi add --encrypt <target>` produces an
  `encrypted_….age` source file (age via rage, identity `~/.ssh/dotfiles`). Edit such a file
  with `chezmoi decrypt` and `chezmoi encrypt`, never with `chezmoi edit` in a headless shell.
- Directories that chezmoi ignores (`the-server/`, and `adguard/` off the server role) are still
  public content; the ignore list controls deployment, not visibility.
- A file that must stay a readable template keeps its private values in an encrypted file it
  reads at apply time.
- When in doubt, do not commit. Ask the owner.

## Repository mechanics

- `.chezmoiignore` lists what chezmoi must not deploy into `$HOME`. `AGENTS.md`, `CLAUDE.md`,
  `README.md` and `the-server/` are in it; a new top-level file goes there too.
- Edit source files here, never the rendered copies in `$HOME`. Apply with
  `(umask 022; chezmoi apply …)`.
- Shell files: `shfmt` before the first run and before committing; skip `.tmpl` files.
- Commits: subject up to 50 characters, lowercase, the what only, body wrapped at 72, no
  trailers or attribution of any kind.
