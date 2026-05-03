# Ghostty Native Paste Bindings Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `Ghostty` use explicit native clipboard bindings for `Cmd+C` / `Cmd+V`, including physical key variants for better matching reliability.

**Architecture:** Add explicit `Ghostty` keybinds for native clipboard copy/paste, plus physical key variants (`key_c` / `key_v`), reload the config, and verify Ghostty reports the expected bindings. If `Cmd+V` still leaks into `tmux`, fix that separately in `tmux`.

**Tech Stack:** Ghostty config, shell verification commands, repo documentation

---

### Task 1: Record The Approved Fix

**Files:**
- Create: `docs/plans/2026-05-01-ghostty-native-paste-design.md`
- Create: `docs/plans/2026-05-01-ghostty-native-paste.md`

**Step 1: Save the fix design**

Document the explicit native clipboard bindings, the physical-key fallback, and note that `tmux` may still require a follow-up fix if `Cmd+V` is not consumed.

### Task 2: Update Ghostty Keybinds

**Files:**
- Modify: `ghostty/.config/ghostty/config`

**Step 1: Add native clipboard bindings**

Add:

```text
keybind = super+c=copy_to_clipboard
keybind = super+key_c=copy_to_clipboard
keybind = super+v=paste_from_clipboard
keybind = super+key_v=paste_from_clipboard
```

near the existing macOS keybind declarations.

### Task 3: Verify The Binding

**Files:**
- Verify: `ghostty/.config/ghostty/config`

**Step 1: Inspect configured keybinds**

Run:

```bash
ghostty +list-keybinds | rg 'super\\+c|super\\+v|copy_to_clipboard|paste_from_clipboard'
```

Expected:

- `super+c` / `super+key_c` are bound to clipboard copy
- `super+v` / `super+key_v` are bound to clipboard paste

**Step 2: Reload and test manually**

Reload Ghostty config with `Cmd-r`, then paste multi-line JSON into `tmux + nvim` using `Cmd-v`.

Expected:

- `Ghostty` recognizes the native bindings
- if escape sequences still appear in `tmux + nvim`, continue with a `tmux`-side fix
