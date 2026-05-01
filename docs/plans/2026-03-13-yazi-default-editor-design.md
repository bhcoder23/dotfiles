# Yazi Default Editor Design

## Goal

Ensure command-line editing defaults to `nvim` across this dotfiles setup, and add a managed Yazi configuration package so opening editable files from Yazi uses the same editor.

## Current State

- This repository is organized as GNU Stow packages rooted from `$HOME`.
- Managed packages currently include `nvim`, `ghostty`, `fish`, `starship`, and `task`.
- There is no `yazi` package in the repository yet.
- `~/.config/yazi` does not currently exist, so there is no user config to migrate.
- Fish loads shared environment from `fish/.config/fish/conf.d/10-env-common.fish`.
- Fish loads helper functions, aliases, and abbreviations from `fish/.config/fish/conf.d/20-commands.fish`.
- Fish interactive startup also sources `fzf --fish` and `starship init fish` from `fish/.config/fish/config.fish`.

## Requirements

- Opening text files from Yazi should use `nvim`, not `vim`.
- Fish should export editor environment variables so CLI tools launched from the shell also default to `nvim`.
- If Yazi config is not already tracked in dotfiles, create and manage it in this repository.
- The repository documentation should reflect the new managed package.

## Options Considered

### 1. Change Fish Only

Set `EDITOR=nvim` and `VISUAL=nvim` in Fish, and rely on Yazi's default text opener using `$EDITOR`.

Pros:
- Smallest change.
- Keeps Yazi aligned with shell defaults automatically.

Cons:
- Leaves no managed Yazi config in dotfiles.
- Makes the Yazi behavior implicit instead of obvious from repo contents.

### 2. Change Fish and Add Minimal Yazi Config

Set `EDITOR=nvim` and `VISUAL=nvim` in Fish, and create a minimal `yazi/.config/yazi/yazi.toml` that explicitly keeps the `edit` opener bound to `$EDITOR`.

Pros:
- Satisfies the requirement to manage Yazi config in dotfiles.
- Keeps one source of truth for editor choice in shell environment.
- Makes Yazi behavior explicit and discoverable.

Cons:
- Slightly more configuration surface than option 1.

### 3. Change Yazi Only

Add Yazi config that directly runs `nvim` for edits, without setting shell editor variables.

Pros:
- Solves the Yazi-specific behavior.

Cons:
- Other shell-driven editor consumers may still use `vim`.
- Splits editor defaults across tools.

## Chosen Approach

Use option 2.

This keeps `nvim` as the shared shell editor via environment variables while also introducing a managed Yazi config package. The Yazi config remains minimal and intentionally mirrors the shell default by using `$EDITOR`.

## Design

### Fish Environment

Add:

```fish
set -gx EDITOR nvim
set -gx VISUAL nvim
```

to the shared Fish environment file so new Fish sessions export the same editor defaults.

### Yazi Package

Create a new Stow package:

```text
yazi/.config/yazi/yazi.toml
```

The file will only define the `edit` opener:

```toml
[opener]
edit = [
  { run = "$EDITOR %s", block = true, for = "unix" },
]
```

This is intentionally minimal. Per the Yazi configuration docs, custom config overrides only the provided keys, so the rest of Yazi's built-in defaults remain intact.

### Documentation

Update `README.md` to:

- list `yazi` as an active package
- show `yazi/.config/yazi/...` in the layout example
- include `yazi` in `stow`, `stow -D`, and `stow -R` examples

## Verification Strategy

- Check Fish syntax remains valid.
- Source the shared Fish environment in a fresh Fish process and confirm `EDITOR` and `VISUAL` resolve to `nvim`.
- Confirm the new `yazi/.config/yazi/yazi.toml` exists and contains the expected opener.
- Dry-run `stow` for the new `yazi` package to confirm the package layout is valid.

## References

- Yazi docs: `yazi.toml` uses `$EDITOR %s` for the default `edit` opener and supports overriding only selected config keys.
- Yazi FAQ: text editing issues on Unix-like systems are commonly resolved by setting `$EDITOR` or explicitly changing the text opener.
