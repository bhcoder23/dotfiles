# Starship Git Status Labels Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace Starship `git_status` private-use glyphs with readable text labels and verify that the counts still map to the correct Git states.

**Architecture:** This is a focused Starship config cleanup. The implementation updates only the `[git_status]` section in `starship/.config/starship.toml`, replacing icon glyphs with letter labels while keeping the existing count-based status rendering logic intact.

**Tech Stack:** Starship, Git, TOML, Markdown

---

### Task 1: Confirm the Current Module Uses Icon Glyphs

**Files:**
- Verify only

**Step 1: Write the failing check**

Run:

```bash
nl -ba /Users/mason77/dotfiles/starship/.config/starship.toml | sed -n '101,112p'
```

Expected: the block contains icon-based values such as ``, ``, `﮾`, and `﯁`.

### Task 2: Replace the Labels in `git_status`

**Files:**
- Modify: `starship/.config/starship.toml`

**Step 1: Write minimal implementation**

Update the `[git_status]` block so it uses text markers:

- `S` for staged
- `M` for modified
- `U` for untracked
- `R` for renamed
- `D` for deleted
- `C` for conflicted
- `T` for stashed
- `A` for ahead
- `B` for behind

Also remove the outer icon from the `format` line.

**Step 2: Run a config-content check**

Run:

```bash
nl -ba /Users/mason77/dotfiles/starship/.config/starship.toml | sed -n '101,112p'
```

Expected: the block shows text labels and no private-use glyphs.

### Task 3: Verify Rendered Counts Against Real Git State

**Files:**
- Verify only

**Step 1: Create a temporary repo with one staged, one modified, and one untracked file**

Use a temporary Git repo to create controlled states.

**Step 2: Render the Starship module**

Run Starship with:

- `STARSHIP_CONFIG=/Users/mason77/dotfiles/starship/.config/starship.toml`
- current directory set to the temporary repo

Expected: rendered output includes text labels matching the repo state, specifically `S 1`, `U 1`, and `M 1`.

### Task 4: Final Verification

**Files:**
- Verify only

**Step 1: Check patch cleanliness**

Run:

```bash
git diff --check
```

Expected: zero exit.
