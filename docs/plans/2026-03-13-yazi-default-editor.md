# Yazi Default Editor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `nvim` the default shell editor in Fish, add a managed Yazi config package, and document the new package in the dotfiles repo.

**Architecture:** Keep the editor choice centralized in Fish environment variables, and make Yazi consume that shared default through a minimal `yazi.toml`. Add the new package to the Stow documentation so repo structure stays discoverable and reproducible.

**Tech Stack:** Fish shell, Yazi, GNU Stow, Markdown, TOML

---

### Task 1: Add Shared Editor Defaults to Fish

**Files:**
- Modify: `fish/.config/fish/conf.d/10-env-common.fish`

**Step 1: Write the failing check**

Run:

```bash
fish -c 'source /Users/mason77/dotfiles/fish/.config/fish/conf.d/10-env-common.fish; test "$EDITOR" = "nvim"; and test "$VISUAL" = "nvim"'
```

Expected: non-zero exit because `EDITOR` and `VISUAL` are not set to `nvim` yet.

**Step 2: Write minimal implementation**

Add:

```fish
set -gx EDITOR nvim
set -gx VISUAL nvim
```

near the general shared environment setup in `fish/.config/fish/conf.d/10-env-common.fish`.

**Step 3: Run the check again**

Run:

```bash
fish -c 'source /Users/mason77/dotfiles/fish/.config/fish/conf.d/10-env-common.fish; test "$EDITOR" = "nvim"; and test "$VISUAL" = "nvim"'
```

Expected: zero exit.

### Task 2: Add a Managed Yazi Package

**Files:**
- Create: `yazi/.config/yazi/yazi.toml`

**Step 1: Write the failing check**

Run:

```bash
test -f /Users/mason77/dotfiles/yazi/.config/yazi/yazi.toml
```

Expected: non-zero exit because the file does not exist yet.

**Step 2: Write minimal implementation**

Create `yazi/.config/yazi/yazi.toml` with:

```toml
[opener]
edit = [
  { run = "$EDITOR %s", block = true, for = "unix" },
]
```

**Step 3: Run the check again**

Run:

```bash
test -f /Users/mason77/dotfiles/yazi/.config/yazi/yazi.toml
rg -n 'run = "\\$EDITOR %s"' /Users/mason77/dotfiles/yazi/.config/yazi/yazi.toml
```

Expected: file exists and `rg` finds the `edit` opener.

### Task 3: Update Stow Documentation

**Files:**
- Modify: `README.md`

**Step 1: Write the failing check**

Run:

```bash
rg -n '\byazi\b' /Users/mason77/dotfiles/README.md
```

Expected: no matches.

**Step 2: Write minimal implementation**

Update `README.md` to:

- add `yazi` to the package list
- add `yazi/.config/yazi/...` to the layout example
- add `yazi` to all example `stow` commands

**Step 3: Run the check again**

Run:

```bash
rg -n '\byazi\b' /Users/mason77/dotfiles/README.md
```

Expected: matches for package list, layout example, and command examples.

### Task 4: Verify Integrated Behavior

**Files:**
- Verify only

**Step 1: Check Fish syntax**

Run:

```bash
fish -n /Users/mason77/dotfiles/fish/.config/fish/config.fish
fish -n /Users/mason77/dotfiles/fish/.config/fish/conf.d/10-env-common.fish
fish -n /Users/mason77/dotfiles/fish/.config/fish/conf.d/20-commands.fish
```

Expected: zero exit for all files.

**Step 2: Check exported editor values**

Run:

```bash
fish -c 'source /Users/mason77/dotfiles/fish/.config/fish/conf.d/10-env-common.fish; printf "%s\n%s\n" "$EDITOR" "$VISUAL"'
```

Expected:

```text
nvim
nvim
```

**Step 3: Check Stow package shape**

Run:

```bash
stow -n -d /Users/mason77/dotfiles -t "$HOME" yazi
```

Expected: zero exit and no errors.

**Step 4: Manual behavior check**

Start Yazi from a Fish session after restowing the package and open a text file.

Expected: Yazi launches `nvim` for editable text files.
