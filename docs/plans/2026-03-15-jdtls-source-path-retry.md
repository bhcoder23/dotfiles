# JDTLS Source Path Retry Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Preserve JDTLS source-path setup for large Java workspaces by retrying `java.project.getSettings` until project import completes, while removing the transient false-negative info notification.

**Architecture:** Keep the fix inside `ftplugin/java.lua`. Add a small retry helper that requests `org.eclipse.jdt.ls.core.sourcePaths` from the attached JDTLS client and sets buffer-local `'path'` once available. Filter only the known transient `nvim-jdtls` info notification and keep a final warning if retries exhaust.

**Tech Stack:** Neovim Lua config, `mfussenegger/nvim-jdtls`, buffer-local editor options, headless Neovim verification

---

### Task 1: Add Design Docs

**Files:**
- Create: `docs/plans/2026-03-15-jdtls-source-path-retry-design.md`
- Create: `docs/plans/2026-03-15-jdtls-source-path-retry.md`

**Step 1: Write the design and plan**

Document:

- root cause
- local retry approach
- alternatives considered
- verification strategy

### Task 2: Write Failing Test

**Files:**
- Test: `nvim/.config/nvim/ftplugin/java.lua`

**Step 1: Write the failing behavioral probe**

Run a mock-based headless check that expects Java config to install a retry-capable `on_attach` hook:

```bash
nvim --clean -u NONE --headless '+lua vim.keymap.set=function() end; package.preload["jdtls"]=function() return { start_or_attach=function(cfg) _G.cfg=cfg end, test_nearest_method=function() end, test_class=function() end } end; package.preload["spring_boot"]=function() return { java_extensions=function() return {} end } end; package.preload["dap"]=function() return { run_last=function() end } end; dofile("nvim/.config/nvim/ftplugin/java.lua"); assert(type(_G.cfg.on_attach)=="function", "missing source-path retry on_attach")' +qa
```

**Step 2: Run it and verify RED**

Expected: fail before implementation because `config.on_attach` does not exist.

### Task 3: Implement Local Retry

**Files:**
- Modify: `nvim/.config/nvim/ftplugin/java.lua`

**Step 1: Add helpers**

Implement helpers for:

- formatting returned source paths into `'path'`
- retrying `java.project.getSettings`
- guarding against duplicate retry loops per buffer
- filtering the known transient info notification

**Step 2: Wire into JDTLS config**

Attach the retry logic through `config.on_attach`, preserving any prior `on_attach`.

**Step 3: Keep scope minimal**

Do not patch files under `~/.local/share/nvim/lazy`.

### Task 4: Verify GREEN

**Files:**
- Verify only

**Step 1: Run mock behavioral test**

Run a headless test with mocked `client:request` behavior:

- first requests fail with `jarvis does not exist`
- later request returns valid source paths
- resulting `'path'` is set
- targeted source-path info notification is filtered

**Step 2: Run real-project probe**

Run a headless probe against:

- `/Users/mason77/workspace/bigdata/rs-jarvis`

Expected:

- no transient source-path info notification
- source paths become available after import finishes

**Step 3: Review diff**

Run:

```bash
git diff -- docs/plans/2026-03-15-jdtls-source-path-retry-design.md docs/plans/2026-03-15-jdtls-source-path-retry.md nvim/.config/nvim/ftplugin/java.lua
```

Expected: only planned files changed.
