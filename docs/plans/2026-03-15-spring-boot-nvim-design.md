# Spring Boot Nvim Design

## Context

The current Neovim setup uses `lazy.nvim` for plugin management and starts Java support from `ftplugin/java.lua` via `nvim-jdtls`. Java runtime discovery, Maven selection, DAP bundles, and Java test keymaps already live there.

The goal is to add Spring Boot language support without replacing the existing `jdtls` workflow or restructuring the Java setup.

## Chosen Approach

Use `JavaHello/spring-boot.nvim` as an additive integration on top of the existing `nvim-jdtls` setup.

This means:

- install and configure `spring-boot.nvim` with `lazy.nvim`
- ensure Mason installs `vscode-spring-boot-tools`
- extend `jdtls` bundles with `require("spring_boot").java_extensions()`
- keep the current JDK, Maven, DAP, and Java test behavior unchanged
- add a small set of Spring-specific keymaps that do not conflict with existing mappings

## Rejected Alternatives

### Minimal plugin-only install

Only adding the plugin and Mason package would leave the main Spring Boot Java features unavailable in `jdtls`, because the extension jars would not be injected into the Java LSP startup path.

### Full Java config refactor

Moving Java startup out of `ftplugin/java.lua` and into a dedicated plugin config would be structurally cleaner, but it would increase the change surface and regression risk for a small feature request.

## Loading Strategy

`spring-boot.nvim` should be available before `ftplugin/java.lua` asks for `require("spring_boot").java_extensions()`.

To make that reliable:

- add a dedicated plugin spec for `JavaHello/spring-boot.nvim`
- make `mfussenegger/nvim-jdtls` depend on that plugin
- keep Spring Boot LS autocmd-based startup enabled for `java`, `yaml`, and `jproperties`

## Keymap Design

The existing `<leader>` layout already uses:

- `<leader>c` for code actions
- `<leader>t` for tests
- `<leader>s` for search

Spring discovery actions fit best under `<leader>s`, because the underlying implementation uses LSP workspace symbol search.

Chosen mappings:

- `<leader>sb` for Spring Beans
- `<leader>se` for Spring Endpoints

Both mappings will call `fzf-lua` live workspace symbol search with Spring Tools query prefixes:

- Bean query prefix: `@+`
- Endpoint query prefix: `@/`

This preserves the existing search mental model and avoids overlapping with current code or test keymaps.

## Error Handling

- If `spring-boot.nvim` is unavailable, Java startup should continue without failing.
- If `fzf-lua` is unavailable at runtime, fall back to a plain notification instead of throwing an error.
- If Spring Boot LS jars are not installed yet, the plugin's own warning behavior is acceptable and should remain intact.

## Verification

Because this is Neovim configuration rather than application logic, verification will use headless startup and runtime inspection instead of classic TDD:

- `nvim --headless` to confirm the config loads
- inspect lazy specs to confirm the plugin is registered
- inspect Java buffer keymaps to confirm Spring mappings exist
- inspect Mason ensure-installed list to confirm `vscode-spring-boot-tools` is managed
