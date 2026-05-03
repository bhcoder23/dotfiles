# Tmux Session Switch Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make tmux session switching reliable after disabling extended keys, and align the live bindings with the documented hjkl-based setup.

**Architecture:** Fix the numeric switch helper to use the authoritative session ordering logic in `session_manager.py`, add reliable non-`Ctrl+digit` bindings for previous/next session navigation, explicitly unbind old legacy keys so reloads become idempotent, then update the user-facing cheatsheet.

**Tech Stack:** tmux config, shell helper script, Markdown docs

---

### Task 1: Record The Root Cause

**Files:**
- Create: `docs/plans/2026-05-01-tmux-session-switch-fix-design.md`
- Create: `docs/plans/2026-05-01-tmux-session-switch-fix.md`

**Step 1: Save the diagnosis**

Document the relationship between disabled extended keys, brittle prefix-based session matching, and stale live keybindings after reload.

### Task 2: Fix Numeric Session Switching

**Files:**
- Modify: `tmux/.config/tmux/scripts/switch_session_by_index.sh`

**Step 1: Delegate to the canonical session manager**

Replace name-prefix matching with `session_manager.py switch` so session selection uses ordered session positions instead of literal `N-` prefixes.

### Task 3: Add Reliable Session Navigation Keys

**Files:**
- Modify: `tmux/.tmux.conf`

**Step 1: Add stable previous/next session bindings**

Bind:

```tmux
bind -n M-p switch-client -p
bind -n M-n switch-client -n
```

**Step 2: Complete direct F-key switching**

Add `F6..F9` bindings to match the existing `F1..F5`.

**Step 3: Clean stale legacy bindings**

Explicitly `unbind` old `u/e/n/i`-era leftover root and prefix keys so `tmux source-file` matches the current file contents.

### Task 4: Update The Cheatsheet

**Files:**
- Modify: `docs/tmux-cheatsheet.md`

**Step 1: Update session switching guidance**

Recommend:
- `prefix + s`
- `Option+p / Option+n`
- `F1..F9`

and avoid presenting `Ctrl+1..9` as the primary path.

### Task 5: Verify The Fix

**Files:**
- Verify: `tmux/.tmux.conf`
- Verify: `tmux/.config/tmux/scripts/switch_session_by_index.sh`
- Verify: `docs/tmux-cheatsheet.md`

**Step 1: Reload tmux**

Run:

```bash
tmux source-file ~/.tmux.conf
```

**Step 2: Check key bindings**

Run:

```bash
tmux list-keys | rg 'M-p|M-n|F[1-9]|switch_session_by_index|M-e|M-u|M-i|M-y'
```

Expected:

- `M-p` and `M-n` exist for session switching
- `F1..F9` exist
- legacy root leftovers are absent

**Step 3: Check docs**

Confirm `docs/tmux-cheatsheet.md` matches the new recommended session workflow.
