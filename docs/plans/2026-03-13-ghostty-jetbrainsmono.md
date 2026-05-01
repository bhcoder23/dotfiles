# Ghostty JetBrainsMono Nerd Font Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Change Ghostty to use `JetBrainsMono Nerd Font` while leaving Starship and the rest of the terminal styling unchanged.

**Architecture:** This is a single-file config change in Ghostty. The implementation updates only the four `font-family` declarations so the selected installed family is used consistently across regular, bold, italic, and bold italic text.

**Tech Stack:** Ghostty config, Nerd Fonts, Markdown

---

### Task 1: Verify the Requested Font Family Exists Locally

**Files:**
- Verify only

**Step 1: Write the failing check**

Run:

```bash
find "$HOME/Library/Fonts" /Library/Fonts /System/Library/Fonts/Supplemental -maxdepth 2 2>/dev/null | rg 'JetBrainsMonoNerdFont-Regular|JetBrainsMono Nerd Font'
```

Expected: this would fail only if the family were not installed.

**Step 2: Verify the environment**

Run the command and confirm at least one regular `JetBrainsMono Nerd Font` face is present.

### Task 2: Update Ghostty Font Families

**Files:**
- Modify: `ghostty/.config/ghostty/config`

**Step 1: Write the failing check**

Run:

```bash
rg -n 'Maple Mono Normal NF CN|JetBrainsMono Nerd Font' /Users/mason77/dotfiles/ghostty/.config/ghostty/config
```

Expected: only Maple Mono lines are present before the edit.

**Step 2: Write minimal implementation**

Replace:

```text
font-family = "Maple Mono Normal NF CN"
font-family-bold = "Maple Mono Normal NF CN"
font-family-italic = "Maple Mono Normal NF CN"
font-family-bold-italic = "Maple Mono Normal NF CN"
```

with:

```text
font-family = "JetBrainsMono Nerd Font"
font-family-bold = "JetBrainsMono Nerd Font"
font-family-italic = "JetBrainsMono Nerd Font"
font-family-bold-italic = "JetBrainsMono Nerd Font"
```

**Step 3: Run the check again**

Run:

```bash
rg -n 'Maple Mono Normal NF CN|JetBrainsMono Nerd Font' /Users/mason77/dotfiles/ghostty/.config/ghostty/config
```

Expected: no Maple Mono lines remain and four JetBrainsMono Nerd Font lines exist.

### Task 3: Final Verification

**Files:**
- Verify only

**Step 1: Check patch cleanliness**

Run:

```bash
git diff --check
```

Expected: zero exit.

**Step 2: Confirm resulting file content**

Run:

```bash
nl -ba /Users/mason77/dotfiles/ghostty/.config/ghostty/config | sed -n '1,20p'
```

Expected: the first font section shows `JetBrainsMono Nerd Font` on all four family lines.

**Step 3: Manual visual check**

Reload Ghostty config or reopen Ghostty.

Expected: prompt icons remain available and the terminal text uses JetBrainsMono Nerd Font.
