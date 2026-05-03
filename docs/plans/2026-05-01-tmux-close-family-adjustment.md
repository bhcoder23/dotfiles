# Tmux Close Family Adjustment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Simplify the tmux close key family so window close uses `prefix + q` and session close uses `prefix + Q`, while keeping `Option+q` for pane close.

**Architecture:** Keep the root-table `Option+q` pane binding unchanged, move the prefix-table window close binding from `M-q` to plain `q`, preserve `Q` for session close, and update the cheat sheet to reflect the final ergonomic layout.

**Tech Stack:** tmux configuration, Markdown docs

---

### Task 1: Record The Final Design

**Files:**
- Create: `docs/plans/2026-05-01-tmux-close-family-adjustment-design.md`
- Create: `docs/plans/2026-05-01-tmux-close-family-adjustment.md`

**Step 1: Save the final close-key hierarchy**

Document the final pane/window/session close mapping.

### Task 2: Adjust The Prefix Binding

**Files:**
- Modify: `tmux/.tmux.conf`

**Step 1: Move window close to plain prefix q**

Replace:

```tmux
bind M-q kill-window
```

with:

```tmux
bind q kill-window
```

while keeping:

```tmux
bind -n M-q kill-pane
bind Q kill-session
```

### Task 3: Update The Cheatsheet

**Files:**
- Modify: `docs/tmux-cheatsheet.md`

**Step 1: Update close-key references**

Reflect the final `prefix + q` window close shortcut and keep `prefix + Q` for session close.

### Task 4: Verify The Final Mapping

**Files:**
- Verify: `tmux/.tmux.conf`
- Verify: `docs/tmux-cheatsheet.md`

**Step 1: Reload tmux**

Run:

```bash
tmux source-file ~/.tmux.conf
```

Expected:

- no reload errors

**Step 2: Check bindings on an isolated server**

Run:

```bash
tmux -L dotfiles-close-test -f tmux/.tmux.conf new-session -d
tmux -L dotfiles-close-test list-keys | rg 'kill-pane|kill-window|kill-session|M-q| q | Q '
tmux -L dotfiles-close-test kill-server
```

Expected:

- root `M-q` is `kill-pane`
- prefix `q` is `kill-window`
- prefix `Q` is `kill-session`

**Step 3: Check docs**

Confirm `docs/tmux-cheatsheet.md` reflects the final mapping.
