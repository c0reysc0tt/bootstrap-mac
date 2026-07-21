# bootstrap-mac

One-liner to prep a fresh Mac for dotfiles setup. Installs the prerequisites, configures SSH and git, and optionally clones your config repo.

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/c0reysc0tt/bootstrap-mac/main/bootstrap.sh | zsh
```

## What it does

1. **Xcode Command Line Tools** — installs if not present (provides `git`, compilers)
2. **Homebrew** — installs if not present
3. **gh + fzf** — GitHub CLI (for SSH key upload) and fuzzy finder
4. **SSH key** — generates an ed25519 keypair, configures `~/.ssh/config`, uploads the public key to GitHub via `gh`
5. **Git identity** — prompts for global `user.name` and `user.email`
6. **Config repo** — prompts for a repo URL, clones to `~/.config`, and offers to run `setup.zsh` if one exists

Every step is interactive and skippable. Nothing runs without a prompt.

## After bootstrap

If you cloned a config repo with a `setup.zsh`, the bootstrap will offer to run it. Otherwise:

```bash
~/.config/setup.zsh
```

Need a starting point? Fork [config-example](https://github.com/c0reysc0tt/config-example) and customize it.

## Requirements

- macOS (Apple Silicon or Intel)
- Internet connection
- A GitHub account (for SSH key upload)

## License

MIT
