# Workflow Stack Stabilization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Stabilize the current workflow stack in this dotfiles repo so the shipped README, cheatsheet, tmux palette behavior, and verification steps all match the real day-to-day setup.

**Architecture:** Keep the current `flow + tmux + agent-tracker + opencode wrappers` implementation intact, but tighten the shipped surface: fix live-path bugs, align active docs with actual behavior, and add just enough tests to prevent regressions in the workflow palette.

**Tech Stack:** Go Bubble Tea palette UI, Python `flow` CLI, tmux config/scripts, zsh wrapper functions, Markdown docs

---

### Task 1: Save the stabilization design

**Files:**
- Create: `docs/plans/2026-05-03-workflow-stack-stabilization-design.md`
- Create: `docs/plans/2026-05-03-workflow-stack-stabilization.md`

**Step 1: Record the chosen A-scope boundary**

Document:
- narrow stabilization scope
- live bugfixes only
- active-doc alignment
- verification boundary

### Task 2: Fix live workflow-surface bugs

**Files:**
- Modify: `agent-tracker/.config/agent-tracker/cmd/agent/palette_bubbletea.go`
- Test: `agent-tracker/.config/agent-tracker/cmd/agent/palette_bubbletea_test.go`

**Step 1: Write a failing test for tmux reload path**

Verify the palette reload action targets `~/.tmux.conf`, not `~/.config/.tmux.conf`.

**Step 2: Run the targeted Go test and confirm red**

Run: `go test ./cmd/agent -run TestPaletteReloadTmuxConfigUsesHomeTmuxConf`

**Step 3: Implement the minimal fix**

Update the reload subtitle and execution path.

**Step 4: Run the targeted Go test and confirm green**

Run: `go test ./cmd/agent -run TestPaletteReloadTmuxConfigUsesHomeTmuxConf`

### Task 3: Align shipped docs with current behavior

**Files:**
- Modify: `README.md`
- Modify: `docs/tmux-cheatsheet.md`
- Modify: `docs/plans/2026-05-03-flow-control-plane-design.md`
- Modify: `docs/plans/2026-05-03-flow-control-plane.md`
- Modify: `docs/plans/2026-05-03-workflow-panel-design.md`
- Modify: `docs/plans/2026-05-03-workflow-panel.md`

**Step 1: Update active package and dependency docs**

Ensure README reflects:
- `opencode` is active
- `go` and `lazygit` are needed
- flow/workflow stack usage is current

**Step 2: Update current workflow docs**

Ensure the current design/plan docs reflect shipped behavior:
- no `flow rebuild`
- no old `start-agent` / `destroy-agent` public interface
- workflow panel uses `Ctrl+a / Enter / Ctrl+r / Ctrl+d`

### Task 4: Add an explicit smoke-check path

**Files:**
- Modify: `README.md`

**Step 1: Document the minimum verification routine**

Add a compact section that verifies:
- `flow`
- `op` / `opr` / `se`
- tmux config reload
- tracker install/build expectations

### Task 5: Run the stabilization verification

**Files:**
- Verify only

**Step 1: Run focused Go tests**

Run: `go test ./cmd/agent`

**Step 2: Run Python syntax verification**

Run: `python3 -m py_compile tmux/.config/tmux/scripts/flow.py`

**Step 3: Rebuild agent-tracker**

Run: `bash install.sh`

**Step 4: Reload tmux config**

Run: `tmux source-file ~/.tmux.conf`

**Step 5: Run command smoke checks**

Run:
- `~/.local/bin/flow --help`
- `zsh -ic 'whence -w flow op opr se'`
