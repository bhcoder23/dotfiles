# Flow Doctor And GC Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a diagnostic `flow doctor` command and a safe registry-cleanup `flow gc` command so the workflow stack can explain and prune stale state without risking active worktrees or live tmux windows.

**Architecture:** Extend `tmux/.config/tmux/scripts/flow.py` with reusable health-analysis helpers, a human-readable and JSON doctor view, and a conservative GC path that only touches stale registry entries proven to have no worktree and no live tmux window. Keep `doctor` read-only and make `gc` dry-run by default.

**Tech Stack:** Python 3 CLI, git worktree state, tmux inspection, JSON registry, Markdown docs

---

### Task 1: Save the B design

**Files:**
- Create: `docs/plans/2026-05-03-flow-doctor-gc-design.md`
- Create: `docs/plans/2026-05-03-flow-doctor-gc.md`

**Step 1: Record the chosen doctor/gc shape**

Document:
- doctor command surface
- gc command surface
- issue model
- safe cleanup boundary
- verification target

### Task 2: Add failing tests for health analysis

**Files:**
- Create: `tmux/.config/tmux/scripts/test_flow.py`
- Modify: `tmux/.config/tmux/scripts/flow.py`

**Step 1: Write failing tests for doctor analysis**

Verify:
- orphan workflows get `missing-worktree`
- running workflows with a missing pane get a resume suggestion
- gc candidates only include safe stale entries

**Step 2: Run the targeted unittest suite and confirm red**

Run: `python3 -m unittest tmux/.config/tmux/scripts/test_flow.py -v`

### Task 3: Implement `flow doctor`

**Files:**
- Modify: `tmux/.config/tmux/scripts/flow.py`
- Test: `tmux/.config/tmux/scripts/test_flow.py`

**Step 1: Add health helper functions**

Implement:
- pane liveness checks
- live window metadata snapshot
- workflow issue analysis
- suggestion generation

**Step 2: Add doctor command output**

Implement:
- current repo scope
- `--all`
- `--json`
- nonzero exit when issues exist

**Step 3: Run the unittest suite and confirm green**

Run: `python3 -m unittest tmux/.config/tmux/scripts/test_flow.py -v`

### Task 4: Implement `flow gc`

**Files:**
- Modify: `tmux/.config/tmux/scripts/flow.py`
- Test: `tmux/.config/tmux/scripts/test_flow.py`

**Step 1: Add safe stale-candidate detection**

Only treat entries as GC-safe when:
- worktree path is missing
- tmux window is not alive

**Step 2: Add `gc` command behavior**

Implement:
- current repo scope
- `--all`
- default dry-run
- `--apply` for deletion

**Step 3: Run unittest suite and confirm green**

Run: `python3 -m unittest tmux/.config/tmux/scripts/test_flow.py -v`

### Task 5: Refresh docs

**Files:**
- Modify: `README.md`
- Modify: `docs/tmux-cheatsheet.md`

**Step 1: Document doctor/gc usage**

Add:
- `flow doctor`
- `flow doctor --all`
- `flow gc`
- `flow gc --apply`

Clarify that `gc` is dry-run by default.

### Task 6: Run full B verification

**Files:**
- Verify only

**Step 1: Run Python tests**

Run: `python3 -m unittest tmux/.config/tmux/scripts/test_flow.py -v`

**Step 2: Run syntax verification**

Run: `python3 -m py_compile tmux/.config/tmux/scripts/flow.py`

**Step 3: Run command smoke checks**

Run:
- `~/.local/bin/flow doctor --help`
- `~/.local/bin/flow gc --help`
- `~/.local/bin/flow doctor --all`

Expected:
- commands parse
- doctor prints a meaningful report
- gc reports dry-run candidates without mutating state
