# Tmux Window Close Key Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a direct `prefix + Option+q` shortcut for closing the current tmux window while keeping `Option+q` for pane close and `prefix + &` for confirmed close.

**Architecture:** Make a single focused tmux keybinding change in the prefix table so `M-q` maps to `kill-window` only after the prefix key. Keep the existing root-table `M-q` pane close binding untouched, then update the user-facing cheatsheet to document the distinction clearly.

**Tech Stack:** tmux configuration, Markdown docs

---

### Task 1: Record The Approved Design

**Files:**
- Create: `docs/plans/2026-05-01-tmux-window-close-key-design.md`
- Create: `docs/plans/2026-05-01-tmux-window-close-key.md`

**Step 1: Save the rationale**

Document the new direct window-close key, the preserved pane-close key, and the confirmed fallback path.

### Task 2: Add The Prefix Binding

**Files:**
- Modify: `tmux/.tmux.conf`

**Step 1: Bind direct window close in the prefix table**

Add:

```tmux
bind M-q kill-window
```

while keeping:

```tmux
bind -n M-q kill-pane
```

so the same physical key closes a pane without prefix and a window with prefix.

### Task 3: Update The Cheatsheet

**Files:**
- Modify: `docs/tmux-cheatsheet.md`

**Step 1: Document both close behaviors**

Add entries for:
- `prefix + Option+q` direct close current window
- `prefix + &` confirmed close current window

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
tmux list-keys | rg 'M-q|kill-pane|kill-window'
```

Expected:

- root `M-q` is `kill-pane`
- prefix `M-q` is `kill-window`

**Step 3: Check docs**

Confirm `docs/tmux-cheatsheet.md` mentions the new window close shortcut.
