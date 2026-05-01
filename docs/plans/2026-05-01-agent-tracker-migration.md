# Agent Tracker Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move the installed `agent-tracker` setup into this dotfiles repo as a Stow package without breaking the running tracker service or tmux integration.

**Architecture:** Create an `agent-tracker` package rooted from `$HOME`, sync the current tracked source tree into it, add ignore rules for generated outputs, restow the package onto the home directory, and verify the CLI and brew-managed service still work.

**Tech Stack:** GNU Stow, shell scripts, Go binaries, Homebrew services, repo documentation

---

### Task 1: Record The Approved Design

**Files:**
- Create: `docs/plans/2026-05-01-agent-tracker-migration-design.md`
- Create: `docs/plans/2026-05-01-agent-tracker-migration.md`

**Step 1: Save the approved design**

Document:

- package layout
- artifact ignore policy
- service continuity expectations
- verification commands

### Task 2: Create The Stow Package

**Files:**
- Create: `agent-tracker/.config/agent-tracker/*`
- Create: `agent-tracker/.local/bin/agent`

**Step 1: Sync the current source tree**

Copy the current `~/.config/agent-tracker` contents into `agent-tracker/.config/agent-tracker/`.

**Step 2: Add the shell wrapper**

Copy the `agent` launcher wrapper into `.local/bin`.

### Task 3: Ignore Generated Outputs

**Files:**
- Modify: `.gitignore`

**Step 1: Ignore local build and runtime files**

Ignore:

- `agent-tracker/.config/agent-tracker/bin/`
- `agent-tracker/.config/agent-tracker/run/`
- `agent-tracker/.config/agent-tracker/.build/`

### Task 4: Update Repo Metadata

**Files:**
- Modify: `README.md`

**Step 1: Add the package**

Update:

- package list
- layout example
- stow commands
- post-stow install note for tracker build/service

### Task 5: Restow The Package

**Files:**
- Verify only

**Step 1: Replace the live directory with symlinked package**

Run:

```bash
stow -R -d ~/dotfiles -t ~ agent-tracker
```

Expected:

- `~/.config/agent-tracker` points to repo
- `~/.local/bin/agent` points to repo

### Task 6: Verify CLI And Service

**Files:**
- Verify: `agent-tracker/.config/agent-tracker/*`

**Step 1: Check links**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
for p in [Path.home()/'.config'/'agent-tracker', Path.home()/'.local'/'bin'/'agent']:
    print(f'{p} -> {p.resolve()}')
PY
```

Expected:

- both paths resolve into `~/dotfiles/agent-tracker/...`

**Step 2: Check agent and server**

Run:

```bash
~/.local/bin/agent tracker state
brew services list | rg agent-tracker-server
```

Expected:

- `agent tracker state` returns JSON state
- `agent-tracker-server` remains `started`
