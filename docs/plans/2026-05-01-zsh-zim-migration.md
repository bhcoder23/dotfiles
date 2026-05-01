# Zsh Zim Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move the approved `zsh + Zim` setup into this dotfiles repo as a Stow package, replace `oh-my-zsh + starship`, and keep the current machine-specific environment working.

**Architecture:** Add a new `zsh` package that mirrors `$HOME`, keep `.zprofile` small, use `.zshrc` as a modular entrypoint into `~/.config/zsh`, import the desired `Zim`-based UX files from `/Users/mason77/test/config/zsh`, and clean them to match the current machine and repo rules.

**Tech Stack:** GNU Stow, `zsh`, Zim, shell scripts, repo documentation

---

### Task 1: Record The Approved Design

**Files:**
- Create: `docs/plans/2026-05-01-zsh-zim-migration-design.md`
- Create: `docs/plans/2026-05-01-zsh-zim-migration.md`

**Step 1: Save the approved design**

Document:

- target package layout
- `zshrc` / `zprofile` / `zimrc` responsibilities
- imported modules
- cleanup rules
- verification strategy

### Task 2: Create The Zsh Stow Package

**Files:**
- Create: `zsh/.zprofile`
- Create: `zsh/.zshrc`
- Create: `zsh/.zimrc`
- Create: `zsh/.config/zsh/env.zsh`
- Create: `zsh/.config/zsh/aliases.zsh`
- Create: `zsh/.config/zsh/plugins.zsh`
- Create: `zsh/.config/zsh/prompt.zsh`
- Create: `zsh/.config/zsh/vi.zsh`
- Create: `zsh/.config/zsh/fzf.zsh`
- Create: `zsh/.config/zsh/completion.zsh`
- Create: `zsh/.config/zsh/mappings.zsh`
- Create: `zsh/.config/zsh/tmux.zsh`
- Create: `zsh/.config/zsh/functions/*`
- Create: `zsh/.config/zsh/fzf/*`

**Step 1: Add the package root files**

Create Stow-managed versions of:

- `.zprofile`
- `.zshrc`
- `.zimrc`

**Step 2: Add the modular config tree**

Copy the desired modular structure into `zsh/.config/zsh`, keeping filenames consistent with the approved design.

### Task 3: Clean Imported Config For This Machine

**Files:**
- Modify: `zsh/.config/zsh/env.zsh`
- Modify: `zsh/.config/zsh/plugins.zsh`
- Modify: `zsh/.zshrc`

**Step 1: Keep working machine-specific environment**

Preserve the current working exports for:

- `pyenv`
- `nvm`
- Java
- Maven
- PostgreSQL / SQLite / OpenLDAP / MySQL client
- local bin paths

**Step 2: Remove stale or foreign values**

Remove:

- `/Users/david/...`
- obsolete package-manager paths
- symlink-rewriting logic for `.zimrc`

**Step 3: Make optional tooling safe**

Guard optional commands or sourced files so shell startup does not fail when a tool is absent.

### Task 4: Update Repo Metadata

**Files:**
- Modify: `README.md`
- Modify: `.gitignore`

**Step 1: Document the new package**

Update package lists and `stow` examples to include `zsh`.

**Step 2: Ignore generated shell/plugin artifacts if needed**

Add ignore rules only for generated files that could appear during use and do not belong in the repo.

### Task 5: Activate The New Package

**Files:**
- Verify only

**Step 1: Stow the new package**

Run:

```bash
stow -d ~/dotfiles -t ~ zsh
```

Expected:

- repo-managed links exist for `~/.zshrc`, `~/.zprofile`, `~/.zimrc`, and `~/.config/zsh`

**Step 2: Bootstrap Zim if missing**

Run the configured bootstrap path once so `~/.zim/init.zsh` exists.

Expected:

- `~/.zim` exists locally
- repo files remain the source of truth

### Task 6: Verify Interactive Startup

**Files:**
- Verify: `zsh/.zshrc`
- Verify: `zsh/.zprofile`
- Verify: `zsh/.zimrc`
- Verify: `zsh/.config/zsh/*.zsh`

**Step 1: Check shell syntax**

Run:

```bash
zsh -n ~/.zshrc
zsh -n ~/.zprofile
for f in ~/.config/zsh/*.zsh ~/.config/zsh/functions/*.zsh; do zsh -n "$f"; done
```

Expected:

- no syntax errors

**Step 2: Check interactive startup**

Run:

```bash
TERM=xterm-256color /bin/zsh -lic 'echo shell=$0; echo ZIM_HOME=${ZIM_HOME:-unset}; bindkey "^G"; bindkey "^R"; command -v pyenv; command -v nvm >/dev/null 2>&1 || true'
```

Expected:

- `shell=/bin/zsh`
- interactive shell starts without `oh-my-zsh` or `starship` output
- imported keybindings are loaded
- `pyenv` resolves successfully
