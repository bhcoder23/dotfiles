# Tmux Session Close Key Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a direct tmux shortcut for closing the current session while preserving the existing pane and window close shortcuts.

**Architecture:** Extend the current `q`-family close hierarchy by binding `prefix + Q` to `kill-session`, leaving `Option+q` and `prefix + Option+q` unchanged. Update the cheat sheet so the user can discover the new shortcut later without reopening the config.

**Tech Stack:** tmux configuration, Markdown docs

---

### Task 1: Record The Approved Design

**Files:**
- Create: `docs/plans/2026-05-01-tmux-session-close-key-design.md`
- Create: `docs/plans/2026-05-01-tmux-session-close-key.md`

**Step 1: Save the rationale**

Document the new session close shortcut and its relationship to the existing pane/window close shortcuts.

### Task 2: Add The Prefix Binding

**Files:**
- Modify: `tmux/.tmux.conf`

**Step 1: Bind direct session close in the prefix table**

Add:

```tmux
bind Q kill-session
```

while keeping:

```tmux
bind -n M-q kill-pane
bind M-q kill-window
```

### Task 3: Update The Cheatsheet

**Files:**
- Modify: `docs/tmux-cheatsheet.md`

**Step 1: Document the new session close shortcut**

Add `prefix + Q` to the session deletion section and the safety summary.

### Task 4: Verify The Binding

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

**Step 2: Check key tables**

Run:

```bash
tmux list-keys | rg 'kill-pane|kill-window|kill-session|M-q| Q '
```

Expected:

- root `M-q` is `kill-pane`
- prefix `M-q` is `kill-window`
- prefix `Q` is `kill-session`

**Step 3: Check docs**

Confirm `docs/tmux-cheatsheet.md` mentions the new session close shortcut.
