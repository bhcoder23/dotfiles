# Fish FNM PNPM Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `fish` reliably expose `node` and `pnpm` through `fnm`, with Corepack recovery built into shell startup.

**Architecture:** Keep all Node runtime setup in the existing `fish` environment file. Initialize `fnm` with explicit Corepack and version-resolution settings, then activate a version on startup and restore the `pnpm` shim only when needed.

**Tech Stack:** Fish shell, fnm, Corepack, pnpm

---

### Task 1: Document the fish-only Node runtime path

**Files:**
- Create: `docs/plans/2026-03-19-fish-fnm-pnpm-design.md`
- Create: `docs/plans/2026-03-19-fish-fnm-pnpm.md`

**Step 1: Capture the approved design**

Write the design doc describing the chosen `fish + fnm + corepack` approach and why mixed shell managers are being avoided.

**Step 2: Save the execution plan**

Record the exact file to edit, the startup activation behavior, and the verification commands.

### Task 2: Harden fish startup for fnm-managed Node

**Files:**
- Modify: `fish/.config/fish/conf.d/10-env-common.fish`

**Step 1: Configure fnm defaults**

Set `FNM_COREPACK_ENABLED=true` and `FNM_VERSION_FILE_STRATEGY=recursive` before sourcing `fnm env`.

**Step 2: Activate a version during shell startup**

If the current directory contains `.node-version`, `.nvmrc`, or `package.json`, run `fnm use --install-if-missing --silent-if-unchanged`.

If no version is active after initialization, fall back to `fnm use default --install-if-missing --silent-if-unchanged`.

**Step 3: Restore pnpm only when missing**

If `corepack` is available and `pnpm` is missing, run `corepack enable` quietly.

### Task 3: Verify with fresh shells

**Files:**
- Verify: `fish/.config/fish/conf.d/10-env-common.fish`

**Step 1: Check runtime visibility**

Run:

```bash
/opt/homebrew/bin/fish -ic 'command -v node; command -v pnpm; fnm current; echo $FNM_COREPACK_ENABLED; echo $FNM_VERSION_FILE_STRATEGY'
```

Expected:

- `node` resolves to an `fnm_multishells` path
- `pnpm` resolves successfully
- `fnm current` prints the active version
- Corepack and version strategy environment variables match the intended values

**Step 2: Check shell config syntax**

Run:

```bash
/opt/homebrew/bin/fish -n ~/.config/fish/config.fish
/opt/homebrew/bin/fish -n ~/.config/fish/conf.d/10-env-common.fish
```

Expected: no syntax errors
