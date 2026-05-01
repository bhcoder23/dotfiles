# Maven Localleader Keymaps Design

## Goal

Expose Maven actions through buffer-local keymaps without polluting the global leader space.

## Decision

Change `maplocalleader` from space to comma and place Maven actions under `<localleader>m`.

This keeps:

- global `<leader>` mappings unchanged
- Maven actions available from Java and `pom.xml` buffers
- the workflow close to the file being edited instead of requiring a jump to `pom.xml`

## Keymap Set

- `<localleader>mm` → `:Maven`
- `<localleader>mc` → `:MavenCompile`
- `<localleader>mt` → `:MavenTest`
- `<localleader>mp` → `:MavenPackage`
- `<localleader>mi` → `:MavenInstall`
- `<localleader>md` → `:MavenDependencyTree`
- `<localleader>ms` → `:MavenDownloadSources`

## Scope

- update `maplocalleader`
- register Maven keymaps from the shared helper
- attach them in the same places where Maven commands are attached

## Testing

Use a headless spec to verify:

- `maplocalleader` is `,`
- the Maven helper registers the expected keymaps
