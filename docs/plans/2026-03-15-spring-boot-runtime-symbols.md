# Spring Boot Runtime And Symbol Search Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Spring Boot support work across mixed-JDK Java projects by starting Boot LS with an automatically selected Java 21+ runtime, starting it for the first Java buffer, and replacing empty default symbol queries with working ones.

**Architecture:** Extract Java runtime discovery into a shared helper so `jdtls` and `spring-boot.nvim` stop diverging. Configure `spring-boot.nvim` with a dedicated Java 21+ command and explicitly start Boot LS for the current buffer after setup. Update Java keymaps to use default workspace-symbol queries that actually match Spring symbols in real projects.

**Tech Stack:** Neovim Lua config, lazy.nvim plugin specs, `JavaHello/spring-boot.nvim`, `mfussenegger/nvim-jdtls`, headless Neovim verification

---

### Task 1: Record The Design

**Files:**
- Create: `docs/plans/2026-03-15-spring-boot-runtime-symbols-design.md`
- Create: `docs/plans/2026-03-15-spring-boot-runtime-symbols.md`

**Step 1: Write the design and implementation plan**

Document:

- why Boot LS must not reuse the project JDK blindly
- why a dedicated 21+ runtime is required
- why the first Java buffer misses Boot LS today
- which default queries replace `@+` / `@/`

### Task 2: Write The Failing Test

**Files:**
- Create: `nvim/.config/nvim/tests/java_runtime_spec.lua`

**Step 1: Write the failing runtime-selection test**

Create a headless Lua test that expects a new helper module to:

- parse discovered Java runtimes
- return the default runtime
- return the nearest runtime satisfying a minimum major version

**Step 2: Run it and verify RED**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/java_runtime_spec.lua
```

Expected:

- FAIL because `utils.java_runtime` does not exist yet

### Task 3: Implement Shared Runtime Discovery

**Files:**
- Create: `nvim/.config/nvim/lua/utils/java_runtime.lua`
- Modify: `nvim/.config/nvim/ftplugin/java.lua`

**Step 1: Move Java runtime discovery into a helper**

Implement helpers for:

- parsing `java_home -V` output
- choosing the default runtime
- choosing the nearest runtime with `major >= min_major`
- formatting runtime entries for JDTLS settings

**Step 2: Rewire `ftplugin/java.lua`**

Replace the local runtime-discovery implementation with calls into the new helper while preserving existing JDTLS behavior.

### Task 4: Fix Spring Boot Startup And Queries

**Files:**
- Modify: `nvim/.config/nvim/lua/plugins/spring-boot.lua`
- Modify: `nvim/.config/nvim/ftplugin/java.lua`

**Step 1: Configure a dedicated Boot LS JVM**

Set `spring-boot.nvim` options so Boot LS uses:

- the nearest installed Java runtime with `major >= 21`

**Step 2: Start Boot LS for the current buffer**

After `setup(opts)`, start Boot LS once for the already-open buffer so the first Java file is not skipped.

**Step 3: Replace default Spring symbol queries**

Change keymaps to use:

- `Component` for Beans
- `Mapping` for Endpoints

### Task 5: Verify Green

**Files:**
- Verify only

**Step 1: Run the runtime helper test**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/java_runtime_spec.lua
```

Expected:

- PASS

**Step 2: Verify Boot LS starts on the first Java buffer**

Run a headless Neovim session opening a Java file in `rs-jarvis` and verify:

- `vim.lsp.get_clients({ name = "spring-boot" })` returns at least one client

**Step 3: Verify symbol queries**

Probe workspace symbols in `rs-jarvis` and verify:

- `Component` returns non-empty results
- `Mapping` returns non-empty results

**Step 4: Review the diff**

Run:

```bash
git diff -- docs/plans/2026-03-15-spring-boot-runtime-symbols-design.md docs/plans/2026-03-15-spring-boot-runtime-symbols.md nvim/.config/nvim/lua/utils/java_runtime.lua nvim/.config/nvim/lua/plugins/spring-boot.lua nvim/.config/nvim/ftplugin/java.lua nvim/.config/nvim/tests/java_runtime_spec.lua
```

Expected:

- only planned files changed for this task
