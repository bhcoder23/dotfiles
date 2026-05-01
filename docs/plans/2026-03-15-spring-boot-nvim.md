# Spring Boot Nvim Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Spring Boot language support to the existing Java Neovim setup while preserving the current `nvim-jdtls` workflow and adding non-conflicting Spring search keymaps.

**Architecture:** Keep Java startup in `ftplugin/java.lua`, wire `spring-boot.nvim` into the existing `jdtls` bundle list, and register a dedicated plugin spec so Spring Boot LS also starts for `application.yml` and `application.properties`. Use `fzf-lua` live workspace symbol queries for Spring Beans and Endpoints.

**Tech Stack:** Neovim Lua config, `lazy.nvim`, `mfussenegger/nvim-jdtls`, `JavaHello/spring-boot.nvim`, `mason.nvim`, `ibhagwan/fzf-lua`

---

### Task 1: Register Spring Boot Plugin

**Files:**
- Create: `nvim/.config/nvim/lua/plugins/spring-boot.lua`
- Modify: `nvim/.config/nvim/lua/plugins/nvim-jdtls.lua`

**Step 1: Write the failing test**

Use a runtime smoke check that should fail before the plugin spec exists:

```bash
nvim --headless '+lua local p=require("lazy.core.config").plugins["spring-boot.nvim"]; assert(p, "missing spring-boot.nvim lazy spec")' +qa
```

**Step 2: Run test to verify it fails**

Run the command above.
Expected: assertion failure for missing `spring-boot.nvim` spec.

**Step 3: Write minimal implementation**

Create a dedicated lazy spec for `JavaHello/spring-boot.nvim` with:

- `name = "spring-boot.nvim"`
- `ft = { "java", "yaml", "jproperties" }`
- `opts = {}`

Update `nvim-jdtls` spec so it depends on `spring-boot.nvim`.

**Step 4: Run test to verify it passes**

Run:

```bash
nvim --headless '+lua local p=require("lazy.core.config").plugins["spring-boot.nvim"]; assert(p and p.name=="spring-boot.nvim")' +qa
```

Expected: exit code `0`.

### Task 2: Ensure Mason Installs Spring Boot LS

**Files:**
- Modify: `nvim/.config/nvim/lua/plugins/mason.lua`

**Step 1: Write the failing test**

```bash
nvim --headless '+lua local tools=require("lazy.core.config").plugins["mason.nvim"].opts.ensure_installed; local found=false; for _,tool in ipairs(tools) do if tool=="vscode-spring-boot-tools" then found=true end end; assert(found, "missing vscode-spring-boot-tools")' +qa
```

**Step 2: Run test to verify it fails**

Run the command above.
Expected: assertion failure for missing `vscode-spring-boot-tools`.

**Step 3: Write minimal implementation**

Add `vscode-spring-boot-tools` to Mason's `ensure_installed` list near the Java tooling entries.

**Step 4: Run test to verify it passes**

Run the same headless command.
Expected: exit code `0`.

### Task 3: Wire Spring Boot Extensions into Java LSP Startup

**Files:**
- Modify: `nvim/.config/nvim/ftplugin/java.lua`

**Step 1: Write the failing test**

Use a static check that should fail before the bundle extension is added:

```bash
rg -n 'spring_boot\\.java_extensions|spring_boot\"\\)\\.java_extensions|require\\(\"spring_boot\"\\)\\.java_extensions' nvim/.config/nvim/ftplugin/java.lua
```

**Step 2: Run test to verify it fails**

Run the command above.
Expected: no matches.

**Step 3: Write minimal implementation**

Update `ftplugin/java.lua` to:

- safely require `spring_boot`
- append `spring_boot.java_extensions()` into `config.init_options.bundles`
- keep existing Java debug and test bundles
- avoid breaking Java startup if the plugin is unavailable

**Step 4: Run test to verify it passes**

Run the same `rg` command.
Expected: matches showing Spring Boot bundle integration.

### Task 4: Add Non-Conflicting Spring Search Keymaps

**Files:**
- Modify: `nvim/.config/nvim/ftplugin/java.lua`

**Step 1: Write the failing test**

Use runtime keymap inspection:

```bash
nvim --headless '+lua vim.cmd("edit Test.java"); vim.bo.filetype="java"; local maps=vim.api.nvim_buf_get_keymap(0,"n"); local found={sb=false,se=false}; for _,m in ipairs(maps) do if m.lhs=="<leader>sb" then found.sb=true end; if m.lhs=="<leader>se" then found.se=true end end; assert(found.sb and found.se, "missing spring keymaps")' +qa
```

**Step 2: Run test to verify it fails**

Run the command above.
Expected: assertion failure for missing Spring keymaps.

**Step 3: Write minimal implementation**

Add buffer-local mappings:

- `<leader>sb` -> `fzf-lua` live workspace symbols with `lsp_query = "@+"`
- `<leader>se` -> `fzf-lua` live workspace symbols with `lsp_query = "@/"`

**Step 4: Run test to verify it passes**

Run a runtime inspection command for buffer-local mappings in a Java buffer.
Expected: both mappings are present with Spring descriptions.

### Task 5: Final Verification

**Files:**
- Verify only

**Step 1: Run headless config load**

Run:

```bash
nvim --headless +qa
```

Expected: exit code `0`.

**Step 2: Run targeted runtime assertions**

Run:

```bash
nvim --headless '+lua local lazy=require("lazy.core.config").plugins; assert(lazy["spring-boot.nvim"]); assert(lazy["mason.nvim"]);' +qa
```

Then run:

```bash
nvim --headless '+lua vim.cmd("edit Test.java"); vim.bo.filetype="java"; local maps=vim.api.nvim_buf_get_keymap(0,"n"); local ok=false; for _,m in ipairs(maps) do if m.lhs=="<leader>sb" and m.desc=="Spring Beans" then ok=true end end; assert(ok, "missing Spring Beans mapping")' +qa
```

Expected: both commands exit `0`.

**Step 3: Review diffs**

Run:

```bash
git diff -- docs/plans/2026-03-15-spring-boot-nvim-design.md docs/plans/2026-03-15-spring-boot-nvim.md nvim/.config/nvim/lua/plugins/spring-boot.lua nvim/.config/nvim/lua/plugins/nvim-jdtls.lua nvim/.config/nvim/lua/plugins/mason.lua nvim/.config/nvim/ftplugin/java.lua
```

Expected: only the planned files are changed for this task.
