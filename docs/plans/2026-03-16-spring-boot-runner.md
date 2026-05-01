# Spring Boot Runner Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add lightweight Spring Boot run, restart, and stop support for Maven projects using the existing Neovim tooling stack.

**Architecture:** Create a new `utils.spring_boot_runner` helper that discovers runnable Spring Boot Maven modules, builds Maven run commands through the existing Maven helper, and manages one active terminal per service. Attach buffer-local commands and localleader keymaps in the same places where Maven commands are attached today.

**Tech Stack:** Neovim Lua config, `Snacks.terminal`, existing `utils.maven`, headless Neovim verification

---

### Task 1: Record The Design

**Files:**
- Create: `docs/plans/2026-03-16-spring-boot-runner-design.md`
- Create: `docs/plans/2026-03-16-spring-boot-runner.md`

**Step 1: Write the design and implementation plan**

Document:

- service discovery rules
- command generation rules
- run, restart, and stop behavior
- test boundaries

### Task 2: Write The Failing Test

**Files:**
- Create: `nvim/.config/nvim/tests/spring_boot_runner_spec.lua`

**Step 1: Write the headless spec**

The test should assert:

- the runner discovers Spring Boot Maven services from temporary modules
- aggregator modules use `-pl <module> -am spring-boot:run`
- fallback mode uses `-f <service-pom> spring-boot:run`
- `SpringBootRun`, `SpringBootRestart`, `SpringBootStop` are registered
- `<localleader>mr`, `<localleader>mR`, `<localleader>mk` are registered

**Step 2: Run it and verify RED**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/spring_boot_runner_spec.lua
```

Expected:

- FAIL because `utils.spring_boot_runner` does not exist yet

### Task 3: Implement The Runner

**Files:**
- Create: `nvim/.config/nvim/lua/utils/spring_boot_runner.lua`
- Modify: `nvim/.config/nvim/lua/utils/maven.lua`
- Modify: `nvim/.config/nvim/ftplugin/java.lua`
- Modify: `nvim/.config/nvim/ftplugin/xml.lua`

**Step 1: Add service discovery and command building**

Implement helpers for:

- repository root resolution
- runnable service discovery
- aggregator selection
- run command construction

**Step 2: Add runtime management**

Implement:

- one active instance per service
- show existing terminal on duplicate run
- explicit stop
- restart by stop then fresh run

**Step 3: Register commands and keymaps**

Expose:

- `:SpringBootRun`
- `:SpringBootRestart`
- `:SpringBootStop`
- `<localleader>mr`
- `<localleader>mR`
- `<localleader>mk`

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

**Step 2: Run Maven and Java helper regressions**

Run:

```bash
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/maven_keymaps_spec.lua
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/maven_commands_spec.lua
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/java_runtime_spec.lua
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/jdtls_source_path_spec.lua
nvim --clean -u NONE --headless -l nvim/.config/nvim/tests/search_keymaps_spec.lua
```

Expected:

- PASS
