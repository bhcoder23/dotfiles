# dotfiles

Personal config managed with GNU Stow.

## Packages

Active packages:

- `agent-tracker`
- `nvim`
- `ghostty`
- `tmux`
- `zsh`
- `yazi`
- `task`

Optional / legacy packages:

- `fish`
- `starship`

## Layout

Each package mirrors the target path under `$HOME`.

```text
~/dotfiles/
  agent-tracker/.config/agent-tracker/...
  agent-tracker/.local/bin/agent
  nvim/.config/nvim/...
  ghostty/.config/ghostty/...
  tmux/.tmux.conf
  tmux/.config/tmux/...
  zsh/.zshrc
  zsh/.zprofile
  zsh/.zimrc
  zsh/.config/zsh/...
  yazi/.config/yazi/...
  task/.taskrc
```

## Prerequisites

Recommended userland on macOS:

```bash
brew install stow zsh tmux neovim yazi task fzf fd ripgrep
brew install --cask ghostty
```

## Quick Start

Clone the repo:

```bash
git clone git@github.com:bhcoder23/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Stow the active packages:

```bash
stow -d ~/dotfiles -t ~ agent-tracker nvim ghostty tmux zsh yazi task
```

If you still need the old Fish setup, stow it explicitly:

```bash
stow -d ~/dotfiles -t ~ fish starship
```

Switch the login shell to `zsh`:

```bash
chsh -s /bin/zsh
exec zsh
```

## Stow Commands

Stow all active packages:

```bash
stow -d ~/dotfiles -t ~ agent-tracker nvim ghostty tmux zsh yazi task
```

Unstow all active packages:

```bash
stow -D -d ~/dotfiles -t ~ agent-tracker nvim ghostty tmux zsh yazi task
```

Restow after local conflicts or file moves:

```bash
stow -R -d ~/dotfiles -t ~ agent-tracker nvim ghostty tmux zsh yazi task
```

Build and start `agent-tracker` after stowing:

```bash
~/.config/agent-tracker/install.sh
~/.config/agent-tracker/scripts/install_brew_service.sh
```

## First Run Notes

### Zsh

- `Zim` bootstraps automatically on the first interactive `zsh` launch.
- `fzf` custom widgets and completion are loaded from `zsh/.config/zsh/fzf.zsh`.

### Tmux

- Main config lives at `tmux/.tmux.conf`.
- Prefix is `Ctrl-s`.
- If you want `tmux-resurrect` / `tmux-continuum`, install TPM once:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

- Reload after changes:

```bash
tmux source-file ~/.tmux.conf
```

### Agent Tracker

- Install and start it once after stowing:

```bash
~/.config/agent-tracker/install.sh
~/.config/agent-tracker/scripts/install_brew_service.sh
```

- Verify service state:

```bash
~/.local/bin/agent tracker state
brew services list | rg agent-tracker-server
```

### Neovim

- `lazy.nvim` installs missing plugins automatically on first start.
- Current theme is `Catppuccin Mocha`.

### Ghostty

- Current terminal theme is `Catppuccin Mocha`.
- Reload config with `Cmd-r` or reopen Ghostty.

## Conventions

- Keep only active, intentional config in this repo.
- Do not commit generated logs, backup files, or cache/state files.
- Add a new tool as its own Stow package rooted from `$HOME`.
