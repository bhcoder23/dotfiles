# Java Lightweight Editor Design

## Goal

Keep Neovim focused on lightweight Java editing:

- code navigation
- completion and diagnostics
- simple Java debugging
- Java unit test execution

Move Spring Boot development and Maven workflow back to IDEA or the shell.

## Keep

- `jdtls` for Java LSP features
- `java-debug-adapter` for debugging support
- `java-test` so existing Java test keymaps continue to work
- runtime discovery and `jdtls` source path helpers

## Remove

- Spring Boot language server integration
- Spring Boot run/restart/stop commands and keymaps
- Spring symbol search keymaps
- Maven commands and localleader keymaps in Neovim
- XML `pom.xml`-specific command registration

## Resulting Java Keymaps

Keep only the Java test and debug-adjacent mappings:

- `<leader>tr`
- `<leader>tf`
- `<leader>tl`

## Plugin Scope

Keep Java tooling installation limited to:

- `jdtls`
- `java-debug-adapter`
- `java-test`

Remove:

- `vscode-spring-boot-tools`
- `spring-boot.nvim`

## Testing

Verify:

- Java ftplugin still registers `<leader>tr`, `<leader>tf`, `<leader>tl`
- Java ftplugin no longer registers `<leader>sb`, `<leader>se`
- Mason no longer ensures Spring Boot tools
- `nvim-jdtls` no longer depends on `spring-boot.nvim`
