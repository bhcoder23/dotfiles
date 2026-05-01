# Spring Boot Runner Labels Design

## Goal

Make the Spring Boot service selector more informative by showing module name, main class, application name, and port.

## Display Format

The selector label format is:

- `module-name | MainClass | application-name | :port`

Example:

- `jarvis-server | JarvisServerApplication | jarvis-server | :8080`
- `jarvis-worker | JarvisWorkerApplication | jarvis-worker | :8081`

## Metadata Extraction

Metadata is extracted from the runnable service module only.

Files checked in order:

- `src/main/resources/application.yml`
- `src/main/resources/application.yaml`
- `src/main/resources/application.properties`

The runner reads only simple top-level Spring Boot config values:

- `spring.application.name`
- `server.port`

No full YAML parser is introduced. Lightweight text extraction is sufficient for the intended selector display.

## Fallback Rules

- missing application name: show module name
- missing port: show `:?`
- missing main class: service is not considered runnable anyway

## Non-Goals

- profile-aware config merging
- environment variable substitution
- parsing arbitrary nested YAML structures beyond the required keys

## Testing

Extend the existing Spring Boot runner headless spec to verify:

- application name extraction
- port extraction
- final selector label format
