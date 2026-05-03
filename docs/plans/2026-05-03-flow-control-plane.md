# Flow Control Plane Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the temporary `start-agent` / `destroy-agent` workflow with a unified `flow` control plane that manages git worktrees, tmux windows, registry state, resume, and destroy behavior.

**Architecture:** Keep Git worktrees as the source of truth for code isolation, store workflow lifecycle metadata in `~/.local/state/flow/registry.json`, and route all user-facing workflow operations through a single `flow` executable in `~/.local/bin`. Let tmux remain the UI/layout layer and `agent-tracker` remain the observer/todos layer.

**Tech Stack:** Python 3 CLI, tmux shell integration, git worktree, zsh PATH bin, markdown docs

---

### Task 1: Record The Approved Design

**Files:**
- Create: `docs/plans/2026-05-03-flow-control-plane-design.md`
- Create: `docs/plans/2026-05-03-flow-control-plane.md`

**Step 1: Save the approved control-plane design**

Document:

- `flow` command set
- registry path and fields
- start/list/resume/destroy semantics
- tmux integration boundaries
- verification strategy

### Task 2: Add The `flow` CLI

**Files:**
- Create: `tmux/.config/tmux/scripts/flow.py`
- Create: `zsh/.local/bin/flow`

**Step 1: Add registry and shared helpers**

Implement:

- registry load/save
- current repo common-root detection
- worktree path generation
- tmux state helpers
- window metadata helpers

**Step 2: Add `flow start`**

Implement:

- branch validation
- worktree creation/reuse
- tmux layout creation
- registry record creation/update

**Step 3: Add `flow list`**

Implement:

- current repo filtering
- `--all` support
- `running` / `stopped` / `orphan` status detection

**Step 4: Add `flow resume`**

Implement:

- current repo lookup
- direct window jump
- layout rebuild when window missing
- error when worktree missing

**Step 5: Add `flow destroy`**

Implement:

- current workflow detection
- dirty worktree protection
- open todos protection
- background cleanup when destroying current tmux window
- registry cleanup on success

**Step 6: Verify script syntax**

Run:

```bash
python3 -m py_compile tmux/.config/tmux/scripts/flow.py
bash -n zsh/.local/bin/flow
```

Expected:

- Python compiles
- shell wrapper parses

### Task 3: Remove Old Command Entry Points

**Files:**
- Delete: `zsh/.config/zsh/functions/start-agent.zsh`
- Delete: `zsh/.config/zsh/functions/destroy-agent.zsh`

**Step 1: Remove obsolete shell functions**

Delete old user-facing wrappers so the repo only exposes `flow`.

### Task 4: Update Tmux Bindings

**Files:**
- Modify: `tmux/.tmux.conf`

**Step 1: Repoint workflow bindings**

Update:

- `prefix + A` → `flow start`
- `prefix + X` → `flow destroy`

Keep bindings additive and avoid breaking existing pane/session shortcuts.

### Task 5: Refresh User Documentation

**Files:**
- Modify: `docs/tmux-cheatsheet.md`

**Step 1: Replace old workflow command references**

Update:

- `start-agent` → `flow start`
- `destroy-agent` → `flow destroy`
- add `flow list` / `flow list --all` / `flow resume`
- explain registry-backed control-plane model

### Task 6: Re-stow Updated Files

**Files:**
- Verify only

**Step 1: Restow tmux and zsh packages**

Run:

```bash
stow -R -d ~/dotfiles -t ~ tmux zsh
```

Expected:

- `~/.config/tmux/scripts/flow.py` is linked
- `~/.local/bin/flow` is linked
- old `start-agent` / `destroy-agent` functions are gone

### Task 7: End-To-End Verification

**Files:**
- Verify only

**Step 1: Run syntax verification**

Run:

```bash
python3 -m py_compile tmux/.config/tmux/scripts/flow.py
bash -n zsh/.local/bin/flow
```

Expected:

- no syntax errors

**Step 2: Run isolated tmux integration verification**

Use a temporary tmux socket and disposable git repo to verify:

- `flow start "feature/demo"` creates external worktree and 3-pane window
- `flow list` shows the new workflow as `running`
- `flow destroy` refuses when todos or dirty changes exist
- `flow destroy` succeeds after cleanup

Expected:

- full workflow lifecycle works without touching real projects

**Step 3: Run final config verification**

Run:

```bash
tmux -L dotfiles-flow -f ~/dotfiles/tmux/.tmux.conf new-session -d -s verify
tmux -L dotfiles-flow list-keys | rg 'flow start|flow destroy'
tmux -L dotfiles-flow kill-server
zsh -ic 'whence -w flow'
```

Expected:

- tmux binds point at `flow`
- `flow` resolves on PATH
