# Spring Boot Runner Design

## Goal

Add lightweight Spring Boot run, restart, and stop actions for Maven projects without adding a new task plugin.

## Scope

- Maven projects only
- buffer-local commands and keymaps for `java` and `pom.xml`
- run, restart, and stop for discovered Spring Boot services
- multi-service support inside one repository

## Non-Goals

- no Gradle support
- no generic task runner
- no extra plugin dependency
- no attempt to infer a single service from the current file when multiple valid services exist

## Service Discovery

The runner discovers candidate services from the current repository by scanning `pom.xml` files under the repository root.

A module is a runnable Spring Boot service when:

- its `pom.xml` contains `spring-boot-maven-plugin`
- its `src/main/java` tree contains a class with `@SpringBootApplication`

The label shown in the selector is:

- module directory name
- plus the detected application class name when available

Example for `rs-jarvis`:

- `jarvis-server (JarvisServerApplication)`
- `jarvis-worker (JarvisWorkerApplication)`

## Execution Model

Preferred command shape:

- `<maven> -pl <module> -am spring-boot:run`

This runs from the nearest aggregator `pom.xml` that declares the service module.

Fallback command shape:

- `<maven> -f <service-module>/pom.xml spring-boot:run`

This is used when no aggregator relation can be proven.

## Runtime Behavior

- `SpringBootRun` / `,mr`
  - always opens a selector
  - if the selected service is already running, show its terminal instead of starting another instance
- `SpringBootRestart` / `,mR`
  - always opens a selector
  - stop the selected running service if present
  - then start a new instance
- `SpringBootStop` / `,mk`
  - always opens a selector
  - stop the selected service if it is running

Different services may run at the same time.
One service keeps only one active instance.

## Terminal Lifecycle

The runner uses `Snacks.terminal` directly with per-run instance ids.

- hiding the window does not stop the service
- explicit stop uses the terminal job id
- each restart creates a fresh terminal identity so exited sessions do not block future runs

## Error Handling

- no service found: notify once
- service not running on stop: notify once
- missing Maven executable: reuse existing Maven helper error

## Testing

Use headless Neovim tests to verify:

- Spring Boot service discovery from temporary Maven projects
- aggregator command generation with `-pl ... -am`
- fallback command generation with `-f pom.xml`
- command and keymap registration for `java` and `pom.xml`
