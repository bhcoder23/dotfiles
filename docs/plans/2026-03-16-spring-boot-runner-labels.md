# Spring Boot Runner Labels Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enrich Spring Boot runner selector entries with module name, main class, application name, and port.

**Architecture:** Extend `utils.spring_boot_runner` to read lightweight service metadata from standard Spring Boot resource files and fold that metadata into the service record label used by the selector. Keep the implementation text-based and limited to the keys already needed for display.

**Tech Stack:** Neovim Lua config, existing Spring Boot runner helper, headless Neovim verification

---

### Task 1: Record The Design

**Files:**
- Create: `docs/plans/2026-03-16-spring-boot-runner-labels-design.md`
- Create: `docs/plans/2026-03-16-spring-boot-runner-labels.md`

**Step 1: Write the design and implementation plan**

Document:

- label format
- metadata extraction rules
- fallback behavior

### Task 2: Write The Failing Test

**Files:**
- Modify: `nvim/.config/nvim/tests/spring_boot_runner_spec.lua`

**Step 1: Extend the headless spec**

The test should assert:

- application name is extracted from Spring Boot resource files
- port is extracted from Spring Boot resource files
- the final selector label includes module name, main class, application name, and port

**Step 2: Run it and verify RED**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/spring_boot_runner_spec.lua
```

Expected:

- FAIL because the runner does not expose the richer metadata yet

### Task 3: Implement Label Metadata

**Files:**
- Modify: `nvim/.config/nvim/lua/utils/spring_boot_runner.lua`

**Step 1: Extract metadata**

Add lightweight extraction for:

- `spring.application.name`
- `server.port`

**Step 2: Build richer labels**

Update service records so the selector shows:

- `module-name | MainClass | application-name | :port`

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

**Step 2: Run related regressions**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/maven_keymaps_spec.lua
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/maven_commands_spec.lua
```

Expected:

- PASS
