# Search Keymap Trim Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Trim the `<leader>s` search group so it keeps only unique capabilities while leaving `<leader>f` as the main global search/find entry.

**Architecture:** Remove duplicate search keymaps from the Snacks picker spec while preserving distinct search actions in `grug-far`, LSP attach helpers, and Java-specific Spring keymaps. Add a small headless verification script that inspects registered keys from the relevant modules.

**Tech Stack:** Neovim Lua config, lazy.nvim plugin specs, headless Neovim verification

---

### Task 1: Record The Design

**Files:**
- Create: `docs/plans/2026-03-15-search-keymap-trim-design.md`
- Create: `docs/plans/2026-03-15-search-keymap-trim.md`

**Step 1: Write the design and implementation plan**

Document:

- which keys are considered duplicates
- which unique keys remain under `<leader>s`
- why `<leader>f` stays untouched

### Task 2: Write The Failing Test

**Files:**
- Create: `nvim/.config/nvim/tests/search_keymaps_spec.lua`

**Step 1: Write the headless keymap spec**

The test should assert:

- `<leader>sw` exists in `snacks/picker.lua`
- `<leader>sg`, `<leader>sG`, `<leader>sW` do not exist in `snacks/picker.lua`
- `<leader>sr` exists in `grug-far.lua`
- `<leader>sb` and `<leader>se` are still registered by `ftplugin/java.lua`

**Step 2: Run it and verify RED**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/search_keymaps_spec.lua
```

Expected:

- FAIL before implementation because removed keys are still present

### Task 3: Remove Duplicate Search Keys

**Files:**
- Modify: `nvim/.config/nvim/lua/plugins/snacks/picker.lua`

**Step 1: Delete duplicate entries**

Remove:

- `<leader>sW`
- `<leader>sg`
- `<leader>sG`

Keep:

- `<leader>sw`

### Task 4: Verify Green

**Files:**
- Verify only

**Step 1: Run the keymap spec**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/search_keymaps_spec.lua
```

Expected:

- PASS

**Step 2: Review the diff**

Run:

```bash
git diff -- docs/plans/2026-03-15-search-keymap-trim-design.md docs/plans/2026-03-15-search-keymap-trim.md nvim/.config/nvim/lua/plugins/snacks/picker.lua nvim/.config/nvim/tests/search_keymaps_spec.lua
```

Expected:

- only planned files changed for this task
