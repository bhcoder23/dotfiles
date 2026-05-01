# Ghostty i3 Keymap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace Ghostty's redundant split navigation and resize bindings with a single clean i3-style `super+alt+h/j/k/l` scheme while keeping the existing macOS-friendly window and tab shortcuts.

**Architecture:** Keep Ghostty defaults for window, tab, split creation, tab switching, and split zoom. Override only the split movement and split resize layer by unbinding Ghostty's default bracket and arrow-based split bindings, then define one consistent home-row navigation and resize layer.

**Tech Stack:** Ghostty config, Ghostty CLI validation commands

---

### Task 1: Record the target keymap

**Files:**
- Modify: `/Users/mason77/.config/ghostty/config`
- Verify: Ghostty runtime defaults via `ghostty +list-keybinds`

**Step 1: Confirm the default bindings that will remain**

Run: `ghostty +list-keybinds | rg 'super\\+(n|t|alt\\+w|shift\\+w|d|shift\\+d|shift\\+enter|digit_[1-9])'`
Expected: shows the default window, tab, split creation, zoom, and tab index shortcuts.

**Step 2: Confirm the default bindings that will be removed**

Run: `ghostty +list-keybinds | rg 'super\\+(\\[|\\]|alt\\+arrow_(up|down|left|right)|ctrl\\+arrow_(up|down|left|right))'`
Expected: shows the default previous/next split navigation plus arrow-based split navigation and resize shortcuts.

### Task 2: Replace redundant split bindings with the approved i3-style layer

**Files:**
- Modify: `/Users/mason77/.config/ghostty/config`

**Step 1: Append the split keymap block**

Add this block to `/Users/mason77/.config/ghostty/config`:

```ini
# i3-style pane navigation and resize
keybind = super+[=unbind
keybind = super+]=unbind
keybind = super+alt+arrow_up=unbind
keybind = super+alt+arrow_down=unbind
keybind = super+alt+arrow_left=unbind
keybind = super+alt+arrow_right=unbind
keybind = super+ctrl+arrow_up=unbind
keybind = super+ctrl+arrow_down=unbind
keybind = super+ctrl+arrow_left=unbind
keybind = super+ctrl+arrow_right=unbind

keybind = super+alt+h=goto_split:left
keybind = super+alt+j=goto_split:down
keybind = super+alt+k=goto_split:up
keybind = super+alt+l=goto_split:right

keybind = super+alt+shift+h=resize_split:left,10
keybind = super+alt+shift+j=resize_split:down,10
keybind = super+alt+shift+k=resize_split:up,10
keybind = super+alt+shift+l=resize_split:right,10
```

**Step 2: Keep existing non-redundant custom bindings intact**

Retain these existing custom bindings:

```ini
keybind = super+i=inspector:toggle
keybind = super+r=reload_config
```

Expected: only one pane navigation/resize scheme remains in the config.

### Task 3: Validate the final result

**Files:**
- Verify: `/Users/mason77/.config/ghostty/config`

**Step 1: Validate Ghostty config syntax**

Run: `ghostty +validate-config`
Expected: exit code 0 and no config errors.

**Step 2: Inspect effective keybindings**

Run: `ghostty +list-keybinds | rg 'super\\+(\\[|\\]|alt\\+arrow_(up|down|left|right)|ctrl\\+arrow_(up|down|left|right)|alt\\+[hjkl]|alt\\+shift\\+[hjkl])'`
Expected: the removed triggers appear as `unbind`, and the new `h/j/k/l` split navigation and resize bindings appear with the correct actions.

**Step 3: Reload Ghostty**

Run inside Ghostty: `super+r`
Expected: Ghostty reloads the config and the new keymap takes effect without restart.
