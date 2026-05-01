# Maven Localleader Keymaps Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add buffer-local Maven keymaps under `<localleader>m` and make localleader distinct from the global leader.

**Architecture:** Keep Maven command execution in `utils.maven` and add a small keymap registration layer there. Change `maplocalleader` to comma so `<localleader>` stops colliding with the existing space leader mappings.

**Tech Stack:** Neovim Lua config, buffer-local keymaps, headless Neovim verification

---

### Task 1: Record The Design

**Files:**
- Create: `docs/plans/2026-03-15-maven-localleader-keymaps-design.md`
- Create: `docs/plans/2026-03-15-maven-localleader-keymaps.md`

**Step 1: Write the design and implementation plan**

Document:

- why localleader must diverge from leader
- which keymaps are added
- why the mappings stay buffer-local

### Task 2: Write The Failing Test

**Files:**
- Create: `nvim/.config/nvim/tests/maven_keymaps_spec.lua`

**Step 1: Write the headless spec**

The test should assert:

- `vim.g.maplocalleader` becomes `,`
- the Maven helper registers all expected `<localleader>m...` mappings

**Step 2: Run it and verify RED**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/maven_keymaps_spec.lua
```

Expected:

- FAIL before implementation because localleader is still space and Maven keymaps are missing

### Task 3: Implement Localleader Maven Keymaps

**Files:**
- Modify: `nvim/.config/nvim/lua/core/options.lua`
- Modify: `nvim/.config/nvim/lua/utils/maven.lua`
- Modify: `nvim/.config/nvim/ftplugin/java.lua`
- Modify: `nvim/.config/nvim/ftplugin/xml.lua`

**Step 1: Change localleader**

Set:

- `vim.g.maplocalleader = ","`

**Step 2: Add Maven keymap registration**

Expose buffer-local mappings for the Maven commands.

**Step 3: Attach the mappings**

Register Maven keymaps where Maven commands are already attached.

### Task 4: Verify Green

**Files:**
- Verify only

**Step 1: Run the new keymap spec**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/maven_keymaps_spec.lua
```

Expected:

- PASS

**Step 2: Run the existing Maven command spec**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/maven_commands_spec.lua
```

Expected:

- PASS
