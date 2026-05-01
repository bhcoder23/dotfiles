# JDTLS Maven Source Path Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the retry-based Java source-path workaround with a local Maven-structure-based source-path provider that feeds `nvim-jdtls` without depending on JDTLS project import timing.

**Architecture:** Add a small helper module under `lua/utils/` that discovers standard Maven source directories and intercepts the specific `java.project.getSettings` request for `org.eclipse.jdt.ls.core.sourcePaths`. Keep all unrelated `jdtls` behavior unchanged and simplify `ftplugin/java.lua` by removing the retry and notify filter code.

**Tech Stack:** Neovim Lua config, `mfussenegger/nvim-jdtls`, headless Neovim verification, local filesystem scanning

---

### Task 1: Record The New Design

**Files:**
- Create: `docs/plans/2026-03-15-jdtls-maven-source-path-design.md`
- Create: `docs/plans/2026-03-15-jdtls-maven-source-path.md`

**Step 1: Write the design and implementation plan**

Document:

- why retry-based syncing is being removed
- why request interception is smaller than overriding the whole status handler
- which Maven directories are included
- how verification will prove the request no longer depends on JDTLS timing

### Task 2: Write The Failing Test

**Files:**
- Create: `nvim/.config/nvim/tests/jdtls_source_path_spec.lua`

**Step 1: Write a headless test for local Maven path inference**

The test should:

- create a temporary multi-module Maven tree
- require a new helper module from `lua/utils/jdtls_source_path.lua`
- assert that the helper returns the expected source directories
- assert that intercepted source-path requests do not call the original `client:request`

**Step 2: Run the test and verify RED**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/jdtls_source_path_spec.lua
```

Expected:

- FAIL because `utils.jdtls_source_path` does not exist yet

### Task 3: Implement The Helper And Wire It In

**Files:**
- Create: `nvim/.config/nvim/lua/utils/jdtls_source_path.lua`
- Modify: `nvim/.config/nvim/ftplugin/java.lua`

**Step 1: Implement local Maven discovery**

Add helpers to:

- find `pom.xml` files under a root
- ignore `target/` descendants
- collect the standard Maven source/resource/generated directories that actually exist
- return deterministic absolute paths

**Step 2: Implement the request interceptor**

Add an installer that wraps `jdtls.util.add_client_methods` and intercepts only:

- `workspace/executeCommand`
- `java.project.getSettings`
- `org.eclipse.jdt.ls.core.sourcePaths`

**Step 3: Simplify `ftplugin/java.lua`**

Remove:

- retry constants
- retry loop helpers
- source-path notify filtering
- `on_attach` source-path retry wiring

Add:

- `require("utils.jdtls_source_path").install()`

### Task 4: Verify Green

**Files:**
- Verify only

**Step 1: Run the headless test**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/jdtls_source_path_spec.lua
```

Expected:

- PASS with no Lua assertion failures

**Step 2: Run a real-project probe**

Run a headless Neovim session against:

- `/Users/mason77/workspace/bigdata/rs-jarvis`

Verify:

- no source-path warning/info about `jarvis does not exist`
- Java buffer `'path'` contains Maven source directories from local inference

**Step 3: Review the diff**

Run:

```bash
git diff -- docs/plans/2026-03-15-jdtls-maven-source-path-design.md docs/plans/2026-03-15-jdtls-maven-source-path.md nvim/.config/nvim/lua/utils/jdtls_source_path.lua nvim/.config/nvim/ftplugin/java.lua nvim/.config/nvim/tests/jdtls_source_path_spec.lua
```

Expected:

- only the planned files changed for this task
