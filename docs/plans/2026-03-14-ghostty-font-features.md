# Ghostty Font Feature Cleanup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the inherited `ssXX` font-feature flags from Ghostty while keeping `calt` and `liga`.

**Architecture:** This is a single-file Ghostty config cleanup. The implementation removes only stylistic-set feature flags that came from the previous font choice and leaves font family, size, weights, and all other terminal settings untouched.

**Tech Stack:** Ghostty config, Markdown

---

### Task 1: Confirm the Current Feature Block Needs Cleanup

**Files:**
- Verify only

**Step 1: Write the failing check**

Run:

```bash
rg -n 'font-feature = ss(02|07|08|10|11|12|17|18)' /Users/mason77/dotfiles/ghostty/.config/ghostty/config
```

Expected: matches are present before the edit.

### Task 2: Remove the `ssXX` Features

**Files:**
- Modify: `ghostty/.config/ghostty/config`

**Step 1: Write minimal implementation**

Delete the `font-feature` lines for:

- `ss02`
- `ss07`
- `ss08`
- `ss10`
- `ss11`
- `ss12`
- `ss17`
- `ss18`

Leave these lines intact:

```text
font-feature = calt
font-feature = liga
```

**Step 2: Run verification**

Run:

```bash
rg -n 'font-feature = (calt|liga|ss02|ss07|ss08|ss10|ss11|ss12|ss17|ss18)' /Users/mason77/dotfiles/ghostty/.config/ghostty/config
```

Expected: only `calt` and `liga` remain.

### Task 3: Final Verification

**Files:**
- Verify only

**Step 1: Check patch cleanliness**

Run:

```bash
git diff --check
```

Expected: zero exit.

**Step 2: Confirm the final config block**

Run:

```bash
nl -ba /Users/mason77/dotfiles/ghostty/.config/ghostty/config | sed -n '15,28p'
```

Expected: the block shows `calt` and `liga` only.
