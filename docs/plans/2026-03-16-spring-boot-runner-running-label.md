# Spring Boot Runner Running Label Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prefix running Spring Boot services with `●` in the selector.

**Architecture:** Keep the existing base label unchanged on the service record and add a small display helper that computes the selector text from service metadata plus runner state. Use the active service registry as the source of truth for the running indicator.

**Tech Stack:** Neovim Lua config, existing Spring Boot runner helper, headless Neovim verification

---

### Task 1: Record The Design

**Files:**
- Create: `docs/plans/2026-03-16-spring-boot-runner-running-label-design.md`
- Create: `docs/plans/2026-03-16-spring-boot-runner-running-label.md`

**Step 1: Write the design and implementation plan**

Document:

- running prefix format
- state source
- testing scope

### Task 2: Write The Failing Test

**Files:**
- Modify: `nvim/.config/nvim/tests/spring_boot_runner_spec.lua`

**Step 1: Extend the headless spec**

The test should assert:

- base display label is unchanged for idle services
- running services are shown with `● ` prefix

**Step 2: Run it and verify RED**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/spring_boot_runner_spec.lua
```

Expected:

- FAIL because the runner does not yet compute a running-aware display label

### Task 3: Implement Running Display

**Files:**
- Modify: `nvim/.config/nvim/lua/utils/spring_boot_runner.lua`

**Step 1: Add a display helper**

Compute selector labels from:

- service metadata
- runner active state

**Step 2: Mark active services**

Track running state on service records so the display helper can mark active services reliably.

### Task 4: Verify Green

**Files:**
- Verify only

**Step 1: Run the Spring Boot runner spec**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/spring_boot_runner_spec.lua
```

Expected:

- PASS
