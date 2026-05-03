# Tmux Cheatsheet Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a durable tmux cheat sheet to this dotfiles repo so session management, AI integration, and daily pane/window operations are easy to look up later.

**Architecture:** Create one human-facing reference document under `docs/`, then add a short README link near the tmux setup section so the document becomes the obvious lookup target. Keep the content aligned with the current live keybindings and shell wrappers rather than inventing new behavior.

**Tech Stack:** Markdown docs, tmux config, zsh wrapper functions

---

### Task 1: Record The Documentation Change

**Files:**
- Create: `docs/plans/2026-05-01-tmux-cheatsheet-design.md`
- Create: `docs/plans/2026-05-01-tmux-cheatsheet.md`

**Step 1: Save the rationale**

Document why a dedicated cheatsheet is needed and what topics it must cover.

### Task 2: Add The Cheatsheet

**Files:**
- Create: `docs/tmux-cheatsheet.md`

**Step 1: Write the session management section**

Cover session create, switch, rename, and delete flows.

**Step 2: Write the window and pane section**

Cover the current `hjkl`, zoom, layout, and move bindings.

**Step 3: Write the AI section**

Cover `agent-tracker` actions, status icons, and `op` / `se` / `opr`.

### Task 3: Add A README Entry Point

**Files:**
- Modify: `README.md`

**Step 1: Link the cheatsheet from the tmux section**

Add a short pointer so the user can quickly find the new reference later.

### Task 4: Verify The Content

**Files:**
- Verify: `docs/tmux-cheatsheet.md`
- Verify: `README.md`

**Step 1: Check the docs exist**

Confirm the new cheatsheet and plan files are present.

**Step 2: Check the README link**

Confirm the README mentions the cheatsheet in the tmux section.
