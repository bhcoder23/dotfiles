# Workflow Panel Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the split workflow actions in the tmux agent palette with a single workflow management panel that lists, filters, previews, creates, resumes, and destroys workflows.

**Architecture:** Reuse the existing workflow registry and Bubble Tea workflow list view, but change the palette entry model from three separate actions to one `Workflows` action. Keep workflow mutations routed through the existing `flow` CLI semantics so the palette remains a thin UI layer.

**Tech Stack:** Go Bubble Tea palette UI, Python `flow` CLI, tmux integration, markdown cheatsheet

---

### Task 1: Save the approved design

**Files:**
- Create: `docs/plans/2026-05-03-workflow-panel-design.md`
- Create: `docs/plans/2026-05-03-workflow-panel.md`

**Step 1: Record the chosen UX**

Document:
- one `Workflows` palette entry
- workflow list panel actions
- create/resume/destroy interactions
- search/filter semantics
- non-goals and verification

### Task 2: Add palette workflow-manager semantics

**Files:**
- Modify: `agent-tracker/.config/agent-tracker/cmd/agent/palette.go`
- Modify: `agent-tracker/.config/agent-tracker/cmd/agent/palette_bubbletea.go`
- Test: `agent-tracker/.config/agent-tracker/cmd/agent/palette_bubbletea_test.go`

**Step 1: Write a failing test for palette actions**

Verify the action list exposes `Workflows` instead of separate start/resume/destroy entries.

**Step 2: Run the targeted Go test and confirm red**

Run: `go test ./cmd/agent -run TestPaletteWorkflowActions`

**Step 3: Implement the minimal action changes**

Update:
- action enum / titles / subtitles
- workflow panel open action
- in-panel create/resume/destroy handling

**Step 4: Run the targeted Go test and confirm green**

Run: `go test ./cmd/agent -run TestPaletteWorkflowActions`

### Task 3: Refine workflow panel behavior

**Files:**
- Modify: `agent-tracker/.config/agent-tracker/cmd/agent/palette_bubbletea.go`
- Test: `agent-tracker/.config/agent-tracker/cmd/agent/palette_bubbletea_test.go`

**Step 1: Write a failing test for workflow key handling**

Verify:
- `Ctrl+r` resumes selected workflow
- `Ctrl+a` opens start prompt
- `Ctrl+d` opens destroy confirm for selected workflow

**Step 2: Run the targeted Go test and confirm red**

Run: `go test ./cmd/agent -run 'TestPaletteWorkflow(Actions|Keys)'`

**Step 3: Implement minimal key handling and selected-workflow context**

Ensure destroy acts on the selected workflow, not only the current active one.

**Step 4: Run the targeted Go test and confirm green**

Run: `go test ./cmd/agent -run 'TestPaletteWorkflow(Actions|Keys)'`

### Task 4: Refresh palette copy and docs

**Files:**
- Modify: `docs/tmux-cheatsheet.md`

**Step 1: Update cheatsheet terminology**

Replace:
- `Start workflow`
- `Resume workflow`
- `Destroy workflow`

With:
- `Workflows`
- in-panel `Ctrl+a / Enter / Ctrl+r / Ctrl+d` operations

### Task 5: Rebuild and verify

**Files:**
- Verify only

**Step 1: Run Go tests**

Run: `go test ./cmd/agent`

**Step 2: Rebuild/install the palette binary**

Run: `bash install.sh`

**Step 3: Reload tmux config if needed**

Run: `tmux source-file ~/.tmux.conf`

**Step 4: Manual verification**

Check:
- `Option+s` 首页只剩 `Workflows`
- workflow 列表显示数量
- `Ctrl+a / Enter / Ctrl+r / Ctrl+d` 生效
