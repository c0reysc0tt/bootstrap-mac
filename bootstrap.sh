#!/usr/bin/env zsh
# bootstrap.sh — Prep a fresh Mac for dotfiles setup.
#
# Usage:
#   curl -fsSL https://githubusercontent.com -o bootstrap.sh && zsh bootstrap.sh
#
# What it does:
#   1. Installs Xcode Command Line Tools (provides git)
#   2. Installs Homebrew (Non-interactively using pre-authed sudo)
#   3. Installs gh (GitHub CLI) and fzf
#   4. Generates an SSH key and uploads it via gh web flow (Fixes duplicate key bug)
#   5. Configures global git identity (optional)
#   6. Clones a dotfiles/config repo (optional)

set -e

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║        macOS Bootstrap for Dotfiles          ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Ask for sudo upfront to allow a clean non-interactive Homebrew installation later
echo "==> Authenticating sudo..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ====================
# 1. Xcode CLT
# ====================

if xcode-select -p &>/dev/null; then
  echo "==> Xcode CLT already installed."
else
  echo "==> Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "    Waiting for installation (click Install in the dialog)..."
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  echo "    Done."
fi

# ====================
# 2. Homebrew
# ====================

if command -v brew &>/dev/null; then
  echo "==> Homebrew already installed."
else
  echo "==> Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://githubusercontent.com)"
fi

if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ====================
# 3. gh + fzf
# ====================

echo "==> Installing gh and fzf..."
brew install gh fzf 2>/dev/null || true

# ====================
# 4. SSH key
# ====================

echo ""
read "?==> Generate an SSH key for GitHub? [Y/n] " ssh_reply
if [[ "$ssh_reply" =~ ^[Nn]$ ]]; then
  echo "    Skipping SSH setup."
  uploaded_key=false
else
    DEFAULT_KEY_DIR="$HOME/.ssh/keys"
    DEFAULT_KEY_NAME="github"

    read "?    Key directory [$DEFAULT_KEY_DIR]: " key_dir
    key_dir="${key_dir:-$DEFAULT_KEY_DIR}"

    read "?    Key name [$DEFAULT_KEY_NAME]: " key_name
    key_name="${key_name:-$DEFAULT_KEY_NAME}"

    KEY_PATH="$key_dir/$key_name"
    mkdir -p "$key_dir"
    chmod 700 ~/.ssh

    echo "    Generating SSH keypair at $KEY_PATH..."
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
    chmod 600 "$KEY_PATH"
    chmod 644 "${KEY_PATH}.pub"

    # SSH config
    if [[ ! -f ~/.ssh/config ]]; then
      cat > ~/.ssh/config  "$tmp"
      cat ~/.ssh/config >> "$tmp"
      mv "$tmp" ~/.ssh/config
      chmod 600 ~/.ssh/config
      echo "    Prepended github.com block to ~/.ssh/config."
    fi

    # Upload to GitHub via safe Web Flow authentication
    echo ""
    echo "==> Authenticating with GitHub..."
    if ! gh auth status &>/dev/null; then
      gh auth login -h github.com -w
    fi

    echo "==> Uploading custom SSH key to GitHub..."
    gh ssh-key add "${KEY_PATH}.pub" --title "$(hostname -s) $(date +%Y-%m-%d)"
    gh config set git_protocol ssh
    echo "    SSH key uploaded and gh configured."
    uploaded_key=true
fi

# ====================
# 5. Git identity
# ====================

echo ""
if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
  echo "==> Global git identity already set:"
  echo "      name:  $(git config --global user.name)"
  echo "      email: $(git config --global user.email)"
  read "?    Change it? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    read "?    Name: " git_name
    read "?    Email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    echo "    Updated."
  fi
else
  read "?==> Set up a global git identity? [Y/n] " reply
  if [[ ! "$reply" =~ ^[Nn]$ ]]; then
    read "?    Name: " git_name
    read "?    Email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    echo "    Global git identity set."
  else
    echo "    Skipping — set later with: git config --global user.name/email"
  fi
fi

# ====================
# 6. Clone config repo
# ====================

echo ""
read "?==> Clone a dotfiles/config repo to ~/.config? [Y/n] " clone_reply
if [[ "$clone_reply" =~ ^[Nn]$ ]]; then
  echo "    Skipping."
else
  read "?    Repo URL (SSH or HTTPS): " repo_url
  if [[ -z "$repo_url" ]]; then
    echo "    No URL provided — skipping."
  else
    if [[ -d "$HOME/.config/.git" ]]; then
      echo "    ~/.config is already a git repo — pulling latest..."
      git -C "$HOME/.config" pull
    elif [[ -d "$HOME/.config" ]]; then
      backup="$HOME/temp/config-backup-$(date +%Y%m%d-%H%M%S)"
      echo "    Existing ~/.config found — backing up to $backup"
      mkdir -p "$(dirname "$backup")"
      mv "$HOME/.config" "$backup"
      git clone "$repo_url" "$HOME/.config"
      echo "    Cloned. Restoring untracked app directories from backup..."
      for dir in "$backup"/*/; do
        dirname="$(basename "$dir")"
        if [[ ! -d "$HOME/.config/$dirname" ]] && [[ "$dirname" != ".git" ]]; then
          cp -a "$dir" "$HOME/.config/$dirname"
        fi
      done
    else
      git clone "$repo_url" "$HOME/.config"
    fi
    echo "    Config repo ready at ~/.config"

    # Offer to run setup script if it exists
    if [[ -x "$HOME/.config/setup.zsh" ]]; then
      echo ""
      read "?    Run ~/.config/setup.zsh now? [Y/n] " run_reply
      if [[ ! "$run_reply" =~ ^[Nn]$ ]]; then
        exec "$HOME/.config/setup.zsh" "$@"
      fi
    fi
  fi
fi

# ====================
# Done
# ====================

echo ""
echo "==> Bootstrap complete!"
if [[ "$uploaded_key" == "true" ]]; then
  echo "    SSH key: $KEY_PATH"
fi
echo ""
echo "    Next steps:"
if [[ ! -d "$HOME/.config/.git" ]]; then
  echo "      git clone <your-config-repo> ~/.config"
  echo "      ~/.config/setup.zsh"
else
  echo "      ~/.config/setup.zsh"
fi
echo ""
