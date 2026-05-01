# Zsh Zim Migration Design

## Goal

Replace the current `oh-my-zsh + starship` shell setup with a `zsh + Zim` setup based on `/Users/mason77/test/config/zsh`, while keeping the current machine-specific environment working and storing the whole setup in this dotfiles repo as a proper GNU Stow package.

## Current State

- The repo currently manages active tools as separate Stow packages rooted from `$HOME`.
- The current login shell is `zsh`, but the active shell startup still comes from `~/.zshrc` outside the repo.
- The current `~/.zshrc` uses `oh-my-zsh`, `starship`, `pyenv`, `nvm`, and many machine-specific PATH settings.
- The provided `/Users/mason77/test/config/zsh` tree contains the desired user experience:
  - `zim` module/plugin setup
  - `vi` keybindings
  - custom `fzf` widgets and completion
  - shell mappings
  - reusable `functions`
- The provided config also contains stale or foreign details that should not be copied blindly:
  - old PATH entries
  - `/Users/david/...` references
  - bootstrap logic that assumes `~/.zimrc` is not already managed by Stow

## Chosen Approach

Create a new `zsh` Stow package and make it the source of truth for all `zsh` config:

1. Add a new package rooted at:
   - `zsh/.zshrc`
   - `zsh/.zprofile`
   - `zsh/.zimrc`
   - `zsh/.config/zsh/...`
2. Port the modular structure from the provided config into `zsh/.config/zsh`.
3. Replace `oh-my-zsh + starship` with `Zim` startup.
4. Keep current machine-specific environment values that are already known to work:
   - `brew shellenv`
   - Python PATH setup in `~/.zprofile`
   - `pyenv` with `--no-rehash`
   - `nvm`
   - Java / Maven / database-related PATH values
5. Clean imported config so it matches the current machine and repo rules.
6. Activate the package with GNU Stow and verify that interactive `zsh` starts correctly.

## Startup Structure

### `~/.zprofile`

Keep login-shell initialization here:

- `brew shellenv`
- existing Python PATH bootstrap

This remains small and machine-aware.

### `~/.zshrc`

Use a minimal entrypoint that:

- sets `XDG_CONFIG_HOME` if needed
- loads `~/.zim/init.zsh` when available
- sources modular files from `~/.config/zsh`

This keeps the main shell config easy to reason about and aligned with the imported structure.

### `~/.zimrc`

Manage `Zim` modules through a Stow-managed `.zimrc` so the plugin list is versioned in the repo.

### `~/.config/zsh/*`

Store the imported modular config here:

- `env.zsh`
- `aliases.zsh`
- `plugins.zsh`
- `prompt.zsh`
- `vi.zsh`
- `fzf.zsh`
- `completion.zsh`
- `mappings.zsh`
- `tmux.zsh`
- `functions/*`
- `fzf/*`

## Zim Bootstrap

The repo should not commit generated `~/.zim` content.

Instead:

- keep a small bootstrap script in `plugins.zsh`
- if `~/.zim/zimfw.zsh` is missing, install `zimfw` into `~/.zim`
- keep `.zimrc` managed by Stow
- source `~/.zim/init.zsh` from `~/.zshrc`

This preserves the repo rule of storing only intentional config, not downloaded plugin state.

## Migration Rules

### Import Mostly As-Is

Bring over these pieces with minimal behavioral changes:

- `zimrc`
- `aliases.zsh`
- `prompt.zsh`
- `vi.zsh`
- `mappings.zsh`
- `completion.zsh`
- `fzf.zsh`
- `tmux.zsh`
- `functions/*`
- `fzf/*`

### Clean During Import

Adjust these parts during migration:

- remove foreign user paths
- remove obsolete Node / Ruby / Linux-only PATH entries that are not relevant here
- avoid startup logic that rewrites symlinks managed by Stow
- preserve current working environment exports from the existing `~/.zshrc`
- guard optional commands so missing tools do not break shell startup

## Repo Rules

The migration must follow the repo conventions:

- use one new `zsh` package rooted from `$HOME`
- do not commit generated cache/state/plugin directories
- keep changes focused and intentional
- update `README.md` package and Stow usage examples to include `zsh`

## Verification

The migration is complete when:

- `stow -d ~/dotfiles -t ~ zsh` creates the expected links
- `~/.zshrc`, `~/.zprofile`, and `~/.zimrc` come from the repo
- a fresh `zsh` shell starts without `oh-my-zsh` or `starship`
- `pyenv` no longer blocks startup
- imported keybindings and widgets load
- `zsh -n` passes for the managed shell files
