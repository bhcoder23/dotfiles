# Tmux Extended Keys Paste Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Stop `Cmd+V` from being inserted as an escape sequence in `Ghostty + tmux + nvim` by disabling tmux extended-key handling and making reloads idempotent.

**Architecture:** Apply a focused `tmux` config change: disable `extended-keys`, drop the explicit `extkeys` terminal feature, reset append-only terminal capability options before re-adding true-color support, and treat leaked `M-v` as clipboard paste instead of entering `copy-mode`.

**Tech Stack:** tmux 3.5a, Ghostty on macOS, shell verification commands, repo documentation

---

### Task 1: Record The Final Root Cause

**Files:**
- Create: `docs/plans/2026-05-01-tmux-extkeys-paste-design.md`
- Create: `docs/plans/2026-05-01-tmux-extkeys-paste.md`

**Step 1: Save the approved diagnosis**

Document that Ghostty native bindings alone were insufficient and the remaining issue came from `tmux` extended key handling plus non-idempotent terminal feature appends.

### Task 2: Update The Tmux Config

**Files:**
- Modify: `tmux/.tmux.conf`

**Step 1: Disable extended key passthrough**

Change the server option to:

```tmux
set -s extended-keys off
```

and remove the explicit `xterm*:extkeys` append.

**Step 2: Make reloads idempotent**

Before re-adding true color support, reset the append-only options:

```tmux
set -gu terminal-features
set -as terminal-features ",*256col*:RGB"
set -gu terminal-overrides
set -as terminal-overrides ",*256col*:Tc"
```

**Step 3: Add tmux paste fallback**

Reserve `M-v` for clipboard paste in:

```tmux
bind -n M-v run -b "~/.config/tmux/scripts/paste_from_clipboard.sh"
bind -T copy-mode M-v send-keys -X cancel \; run -b "~/.config/tmux/scripts/paste_from_clipboard.sh"
bind -T copy-mode-vi M-v send-keys -X cancel \; run -b "~/.config/tmux/scripts/paste_from_clipboard.sh"
```

so if `Cmd+V` reaches tmux as `M-v`, it still pastes instead of entering `copy-mode`.

### Task 3: Verify The Fix

**Files:**
- Verify: `tmux/.tmux.conf`

**Step 1: Reload tmux**

Run:

```bash
tmux source-file ~/.tmux.conf
```

Expected:

- no reload errors

**Step 2: Check live options**

Run:

```bash
tmux show -s extended-keys
tmux show -s terminal-features | rg 'extkeys|RGB'
tmux list-keys | rg 'M-v|paste_from_clipboard|copy-mode'
```

Expected:

- `extended-keys` is `off`
- `xterm*:extkeys` is absent
- `*256col*:RGB` is present
- root-table `M-v` points to `paste_from_clipboard.sh`

**Step 3: Confirm repeat reload stays clean**

Run:

```bash
tmux source-file ~/.tmux.conf
tmux show -s terminal-features | rg 'extkeys|RGB'
```

Expected:

- `extkeys` still absent
- `RGB` does not accumulate duplicates

**Step 4: Manual paste test**

In `Ghostty + tmux + nvim`, paste multiline JSON with `Cmd+V`.

Expected:

- formatted text pastes normally
- no raw escape sequences such as `^[[27;5;106~`
