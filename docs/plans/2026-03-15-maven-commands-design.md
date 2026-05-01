# Maven Commands Design

## Goal

Add lightweight Maven support to the current Neovim Java setup without introducing a new heavy plugin layer.

## Decision

Use a small local helper module to:

- prefer the project `mvnw` wrapper when present
- fall back to system `mvn`
- reuse Maven settings from `MAVEN_SETTINGS_XML`, `~/.m2/settings.xml`, or `MAVEN_HOME/conf/settings.xml`
- run commands through `Snacks.terminal`

## Scope

Add buffer-local commands for Java and `pom.xml` buffers:

- `:Maven`
- `:MavenCompile`
- `:MavenTest`
- `:MavenPackage`
- `:MavenInstall`
- `:MavenDependencyTree`
- `:MavenDownloadSources`

## Non-Goals

- no new Maven plugin
- no extra project model or dependency UI
- no new leader-key prefix yet, to avoid conflicts with existing mappings

## Error Handling

If neither `mvnw` nor `mvn` is available, show a clear notification and do nothing.

## Testing

Use a headless Neovim spec to verify:

- command construction prefers `mvnw`
- Maven settings and `pom.xml` targeting are included
- buffer-local user commands are registered
