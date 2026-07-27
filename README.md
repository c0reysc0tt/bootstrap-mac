# bootstrap-mac

Prep a fresh Mac for your dotfiles setup.

## Usage

Run the following one-liner to download and launch the bootstrap installer using local file arguments (which keeps standard input open for prompts):

```bash
curl -fsSL https://githubusercontent.com -o bootstrap.sh && zsh bootstrap.sh
```

## What it does

1. **Xcode Command Line Tools:** Installs required developer toolkits (provides native `git`).
2. **Homebrew:** Configures the Mac package manager silently.
3. **Core Utilites:** Sets up GitHub CLI (`gh`) and `fzf`.
4. **SSH Authentication:** Confirms/creates a dedicated GitHub identity file and binds it cleanly to your GitHub profile via the web flow.
5. **Git Configurations:** Sets global identity parameters.
6. **Dotfiles Repository:** Offers to sync down your custom `~/.config` workspace directly.
