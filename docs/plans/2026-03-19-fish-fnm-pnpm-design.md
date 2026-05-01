# Fish FNM PNPM Design

## Goal

Keep `node`, `corepack`, and `pnpm` consistently available in `fish` by using a single startup path based on `fnm`, without depending on legacy `zsh` or `nvm` setup.

## Current State

- `fish` already loads `fnm` from `fish/.config/fish/conf.d/10-env-common.fish`.
- `zsh` still contains separate `nvm` initialization, but the user no longer uses `zsh`.
- `fnm env --use-on-cd` installs a directory-change hook, but the shell startup path is not explicit about:
  - enabling Corepack for future Node installs
  - selecting a version immediately when the shell opens
  - recovering when `pnpm` is missing from the active Node version

## Chosen Approach

Keep `fish` on `fnm`, and make the startup path explicit:

1. Set `FNM_COREPACK_ENABLED=true` so future `fnm`-managed Node installs expose Corepack by default.
2. Set `FNM_VERSION_FILE_STRATEGY=recursive` so nested projects resolve version files from parent directories.
3. Continue sourcing `fnm env --use-on-cd --shell fish`.
4. Run an immediate `fnm use` at shell startup when the current directory looks like a Node project.
5. Fall back to `fnm use default` if no Node version is active.
6. If `corepack` exists but `pnpm` is missing, run `corepack enable` once to restore the shim.

## Rejected Alternatives

### Keep mixed `nvm` and `fnm`

Rejected because it preserves the exact source of confusion: different shells exposing different `node` and `pnpm` binaries.

### Install `pnpm` separately with Homebrew

Rejected because it decouples `pnpm` from the active Node version and makes project-level version management harder to reason about.

## Verification

Use fresh `fish` shells to verify:

- `command -v node`
- `command -v pnpm`
- `fnm current`
- `echo $FNM_COREPACK_ENABLED`
- `echo $FNM_VERSION_FILE_STRATEGY`

The expected result is that `fish` exposes `node` and `pnpm` immediately, with `fnm` still managing version switching.
