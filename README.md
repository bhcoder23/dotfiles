# dotfiles

Personal config managed with GNU Stow.

## Packages

- `agent-tracker`
- `nvim`
- `ghostty`
- `tmux`
- `zsh`
- `yazi`
- `task`

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

## Usage

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

## Conventions

- Keep only active, intentional config in this repo.
- Do not commit generated logs, backup files, or cache/state files.
- Add a new tool as its own Stow package rooted from `$HOME`.
