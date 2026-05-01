# Maven Commands Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add lightweight Maven commands to the existing Java Neovim setup, preferring project wrappers and avoiding a heavy plugin dependency.

**Architecture:** Introduce a shared `utils.maven` helper that builds Maven commands and opens them with `Snacks.terminal`. Register buffer-local commands from Java and `pom.xml` ftplugins so the feature stays local to Maven-related buffers.

**Tech Stack:** Neovim Lua config, `Snacks.terminal`, headless Neovim verification

---

### Task 1: Record The Design

**Files:**
- Create: `docs/plans/2026-03-15-maven-commands-design.md`
- Create: `docs/plans/2026-03-15-maven-commands.md`

**Step 1: Write the design and implementation plan**

Document:

- why this stays as a local helper instead of a plugin
- which commands are added
- how wrapper and settings resolution work

### Task 2: Write The Failing Test

**Files:**
- Create: `nvim/.config/nvim/tests/maven_commands_spec.lua`

**Step 1: Write the headless spec**

The test should assert:

- the helper prefers `mvnw`
- the helper injects Maven settings and `-f pom.xml`
- the helper registers the expected buffer-local user commands

**Step 2: Run it and verify RED**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/maven_commands_spec.lua
```

Expected:

- FAIL because `utils.maven` does not exist yet

### Task 3: Implement The Maven Helper

**Files:**
- Create: `nvim/.config/nvim/lua/utils/maven.lua`
- Modify: `nvim/.config/nvim/ftplugin/java.lua`
- Create: `nvim/.config/nvim/ftplugin/xml.lua`

**Step 1: Add the helper module**

Implement helpers for:

- resolving project root
- preferring `mvnw`
- resolving Maven settings
- building a command array
- opening the command in `Snacks.terminal`

**Step 2: Register buffer-local commands**

Expose commands for Java and `pom.xml` buffers.

### Task 4: Verify Green

**Files:**
- Verify only

**Step 1: Run the Maven spec**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/maven_commands_spec.lua
```

Expected:

- PASS

**Step 2: Review the diff**

Run:

```bash
git diff -- docs/plans/2026-03-15-maven-commands-design.md docs/plans/2026-03-15-maven-commands.md nvim/.config/nvim/lua/utils/maven.lua nvim/.config/nvim/ftplugin/java.lua nvim/.config/nvim/ftplugin/xml.lua nvim/.config/nvim/tests/maven_commands_spec.lua
```

Expected:

- only planned files changed for this task
