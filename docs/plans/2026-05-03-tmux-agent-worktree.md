# Tmux Agent Worktree Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a fully automated tmux + git worktree workflow so `start-agent <branch>` creates an isolated feature window with `op`/`lazygit`/shell panes, and `destroy-agent -y` safely tears it down.

**Architecture:** Keep command entry thin in `zsh` functions and centralize behavior in tmux helper scripts. Persist workflow metadata on tmux window options so cleanup and future integrations do not rely on fragile window-name parsing. Use external worktrees under `~/worktrees/<repo>/<branch>`.

**Tech Stack:** zsh functions, tmux shell scripts, git worktree, tmux window options, markdown docs

---

### Task 1: Add Shared Worktree Helpers

**Files:**
- Create: `tmux/.config/tmux/scripts/agent_workspace_common.sh`

**Step 1: Write helper functions**

Add helpers for:

- git repo root detection
- repo name detection
- branch name validation
- worktree path generation
- tmux window option getters/setters
- safe shell command escaping

**Step 2: Verify shell syntax**

Run: `bash -n tmux/.config/tmux/scripts/agent_workspace_common.sh`

Expected: no syntax errors

### Task 2: Add Start Script

**Files:**
- Create: `tmux/.config/tmux/scripts/start_agent_workspace.sh`

**Step 1: Implement repo and branch checks**

Support:

- running inside a git repo
- refusing empty/invalid branch names
- reusing existing local branch if present

**Step 2: Implement worktree creation**

Support:

- `~/worktrees/<repo>/<branch>`
- creating the branch if missing
- reusing existing worktree path if already present

**Step 3: Implement tmux window creation**

Support:

- reuse existing current session
- create/select window named after the branch
- write window metadata:
  - `@agent_branch`
  - `@agent_worktree`
  - `@agent_repo_root`
  - `@agent_repo_name`
  - `@agent_role`

**Step 4: Implement pane layout and commands**

Create three panes:

- left: auto-run `op` if available, else login shell
- right top: auto-run `lazygit` if available, else login shell
- right bottom: login shell

All panes use the worktree path.

**Step 5: Verify shell syntax**

Run: `bash -n tmux/.config/tmux/scripts/start_agent_workspace.sh`

Expected: no syntax errors

### Task 3: Add Destroy Script

**Files:**
- Create: `tmux/.config/tmux/scripts/destroy_agent_workspace.sh`

**Step 1: Resolve current workflow metadata**

Read:

- current window id
- `@agent_branch`
- `@agent_worktree`
- `@agent_repo_root`
- `@agent_role`

Reject if current window is not a managed feature window.

**Step 2: Add safety checks**

Reject destroy when:

- worktree path missing
- worktree has uncommitted changes
- branch missing
- branch still used by another worktree

**Step 3: Implement cleanup**

Perform:

- optional confirmation unless `-y`
- `tmux kill-window`
- `git worktree remove`
- `git branch -D`

Do not touch remote branches.

**Step 4: Verify shell syntax**

Run: `bash -n tmux/.config/tmux/scripts/destroy_agent_workspace.sh`

Expected: no syntax errors

### Task 4: Add Zsh Entrypoints

**Files:**
- Create: `zsh/.config/zsh/functions/start-agent.zsh`
- Create: `zsh/.config/zsh/functions/destroy-agent.zsh`

**Step 1: Add thin function wrappers**

Wrap the tmux scripts so users can run:

- `start-agent <branch>`
- `destroy-agent [-y]`

from interactive shells without remembering full script paths.

**Step 2: Verify shell syntax**

Run:

```bash
bash -n tmux/.config/tmux/scripts/*.sh
zsh -n zsh/.config/zsh/functions/start-agent.zsh
zsh -n zsh/.config/zsh/functions/destroy-agent.zsh
```

Expected: no syntax errors

### Task 5: Add Optional Tmux Shortcuts

**Files:**
- Modify: `tmux/.tmux.conf`

**Step 1: Add creation and destroy prompts**

Add prefix bindings that run command prompts for:

- create feature workflow
- destroy current feature workflow

Keep them additive and avoid conflicting with existing keymaps.

**Step 2: Verify tmux config parsing**

Run:

```bash
tmux -L dotfiles-agent -f ~/dotfiles/tmux/.tmux.conf new-session -d -s verify
tmux -L dotfiles-agent list-keys | rg 'start_agent_workspace|destroy_agent_workspace'
tmux -L dotfiles-agent kill-server
```

Expected:

- tmux starts successfully
- new bindings are present

### Task 6: Update Cheat Sheet

**Files:**
- Modify: `docs/tmux-cheatsheet.md`

**Step 1: Document new workflow**

Add:

- workspace model
- `start-agent` / `destroy-agent`
- feature window layout
- cleanup expectations
- main-vs-feature usage guidance

### Task 7: Validate End-To-End

**Files:**
- Verify only

**Step 1: Run syntax verification**

Run:

```bash
bash -n tmux/.config/tmux/scripts/*.sh
zsh -n zsh/.config/zsh/functions/*.zsh
```

Expected: no syntax errors

**Step 2: Run isolated tmux integration verification**

Use a temporary tmux socket and a disposable git repo to verify:

- `start-agent demo-branch` creates the external worktree
- branch window opens with the expected 3-pane layout
- metadata is stored on the window
- `destroy-agent -y` removes the window, worktree, and local branch

Expected: workflow creates and destroys cleanly
