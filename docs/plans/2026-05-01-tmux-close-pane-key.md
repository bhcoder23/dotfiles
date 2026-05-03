# Tmux Close Pane Key Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Change direct pane closing in tmux from `Alt+Shift+Q` to `Alt+q` while keeping confirmed close on `prefix + x`.

**Architecture:** Make a single focused keybinding edit in `tmux/.tmux.conf`, document the approved change, and verify the live tmux server reloads with the new root binding present.

**Tech Stack:** tmux 3.5a, shell verification commands, repo documentation

---

### Task 1: Record The Approved Change

**Files:**
- Create: `docs/plans/2026-05-01-tmux-close-pane-key-design.md`
- Create: `docs/plans/2026-05-01-tmux-close-pane-key.md`

**Step 1: Save the approved design**

Document the reason for moving from `M-Q` to `M-q` and the verification commands.

### Task 2: Update The Tmux Binding

**Files:**
- Modify: `tmux/.tmux.conf`

**Step 1: Rebind direct pane close**

Replace:

```tmux
bind -n M-Q kill-pane
```

with:

```tmux
bind -n M-q kill-pane
```

### Task 3: Verify The New Binding

**Files:**
- Verify: `tmux/.tmux.conf`

**Step 1: Reload tmux**

Run:

```bash
tmux source-file ~/.tmux.conf
```

Expected:

- no reload errors

**Step 2: Check the binding table**

Run:

```bash
tmux list-keys | rg 'M-q|M-Q|kill-pane'
```

Expected:

- `M-q kill-pane` exists
- `M-Q kill-pane` is absent
- `prefix + x` still exists
