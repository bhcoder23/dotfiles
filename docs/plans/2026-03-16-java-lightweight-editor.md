# Java Lightweight Editor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce the Neovim Java setup to jdtls-based editing, testing, and debugging only.

**Architecture:** Keep the existing jdtls runtime and source-path support, but remove Spring Boot and Maven workflow layers from the Java ftplugin and plugin list. Preserve Java test keymaps so the editor still supports fast feedback for normal Java work and practice problems.

**Tech Stack:** Neovim Lua config, nvim-jdtls, Mason tool installation, headless Neovim specs

---

### Task 1: Record The Design

**Files:**
- Create: `docs/plans/2026-03-16-java-lightweight-editor-design.md`
- Create: `docs/plans/2026-03-16-java-lightweight-editor.md`

**Step 1: Write the design and implementation plan**

Document:

- what Java capabilities remain
- what Spring Boot and Maven integrations are removed
- what tests prove the lighter setup

### Task 2: Write The Failing Tests

**Files:**
- Modify: `nvim/.config/nvim/tests/search_keymaps_spec.lua`
- Create: `nvim/.config/nvim/tests/java_lightweight_spec.lua`

**Step 1: Update Java keymap expectations**

Assert:

- `<leader>tr`, `<leader>tf`, `<leader>tl` exist
- `<leader>sb`, `<leader>se` do not exist

**Step 2: Add plugin-level expectations**

Assert:

- `nvim-jdtls` has no Spring Boot dependency
- Mason keeps `jdtls`, `java-debug-adapter`, `java-test`
- Mason does not keep `vscode-spring-boot-tools`

**Step 3: Run tests to verify RED**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/search_keymaps_spec.lua
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/java_lightweight_spec.lua
```

Expected:

- FAIL because Spring Boot keymaps and dependency/tool entries still exist

### Task 3: Remove Spring Boot And Maven Workflow Layers

**Files:**
- Modify: `nvim/.config/nvim/ftplugin/java.lua`
- Modify: `nvim/.config/nvim/lua/plugins/nvim-jdtls.lua`
- Modify: `nvim/.config/nvim/lua/plugins/mason.lua`
- Delete: `nvim/.config/nvim/lua/plugins/spring-boot.lua`
- Delete: `nvim/.config/nvim/lua/utils/spring_boot_runner.lua`
- Delete: `nvim/.config/nvim/lua/utils/maven.lua`
- Delete: `nvim/.config/nvim/ftplugin/xml.lua`
- Delete: `nvim/.config/nvim/tests/spring_boot_runner_spec.lua`
- Delete: `nvim/.config/nvim/tests/maven_keymaps_spec.lua`
- Delete: `nvim/.config/nvim/tests/maven_commands_spec.lua`

**Step 1: Simplify the Java ftplugin**

Keep:

- jdtls setup
- runtime configuration
- source path helper
- Java test keymaps

Remove:

- Maven helper wiring
- Spring Boot runner wiring
- Spring symbol search
- Spring Boot extension bundle loading

**Step 2: Simplify plugin declarations**

Remove Spring Boot plugin definitions and dependencies.

**Step 3: Remove obsolete helper and spec files**

Delete files that are no longer referenced by the lighter Java setup.

### Task 4: Verify Green

**Files:**
- Verify only

**Step 1: Run focused specs**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/search_keymaps_spec.lua
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/java_lightweight_spec.lua
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/java_runtime_spec.lua
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/jdtls_source_path_spec.lua
```

Expected:

- PASS
