# Tmux HJKL Keybindings Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Convert tmux directional bindings from `u/e/n/i` to Vim-style `h/j/k/l` while preserving the user's broader workflow.

**Architecture:** Update `tmux/.tmux.conf` in one focused pass, moving all pane-direction bindings to `h/j/k/l`, relocating conflicting window/session bindings, and verifying the config with `tmux` key listing commands.

**Tech Stack:** tmux 3.5a, shell verification commands, repo documentation

---

### Task 1: Record The Approved Mapping

**Files:**
- Create: `docs/plans/2026-05-01-tmux-hjkl-keybindings-design.md`
- Create: `docs/plans/2026-05-01-tmux-hjkl-keybindings.md`

**Step 1: Save the approved direction model**

Document the new `h/j/k/l` mapping and the replacement keys for conflicting window/session actions.

### Task 2: Update Tmux Bindings

**Files:**
- Modify: `tmux/.tmux.conf`

**Step 1: Rebind pane actions**

Move split, pane focus, pane resize, and layout builder directions to `h/j/k/l`.

**Step 2: Rebind copy mode**

Make `copy-mode-vi` use `h/j/k/l` again, with `e` for word-end movement.

**Step 3: Relocate conflicting bindings**

Move:

- previous/next window to `Alt+,` / `Alt+.`
- swap window left/right to `Alt+<` / `Alt+>`
- move session left/right to `prefix + [` / `prefix + ]`

### Task 3: Verify The New Keymap

**Files:**
- Verify: `tmux/.tmux.conf`

**Step 1: Reload the config**

Run:

```bash
tmux source-file ~/.tmux.conf
```

Expected:

- no parse or option errors

**Step 2: Verify key bindings**

Run:

```bash
tmux list-keys | rg 'bind(-key)? .*M-h|bind(-key)? .*M-j|bind(-key)? .*M-k|bind(-key)? .*M-l|bind(-key)? .*M-H|bind(-key)? .*M-J|bind(-key)? .*M-K|bind(-key)? .*M-L|bind(-key)? .*M-,|bind(-key)? .*M-\\.|bind(-key)? .*M-<|bind(-key)? .*M->|bind(-key)? .* \\[|bind(-key)? .* \\]'
tmux list-keys -T copy-mode-vi | rg ' h | j | k | l | e '
```

Expected:

- new directional bindings are present
- copy mode no longer depends on `u/e/n/i`
