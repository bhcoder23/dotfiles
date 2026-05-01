# Spring Boot Runner Running Label Design

## Goal

Highlight already running Spring Boot services in the selector so they are immediately distinguishable.

## Display Rule

When a service is running, its selector label is prefixed with:

- `● `

Examples:

- `● jarvis-server | JarvisServerApplication | jarvis-server | :8080`
- `jarvis-worker | JarvisWorkerApplication | jarvis-worker | :8081`

## Scope

- selector display only
- no change to the underlying base label format
- no new commands or keymaps

## State Source

The runner already keeps one record per active service.

The selector should treat a service as running when its stored record is marked running or still has a live terminal job.

## Testing

Extend the Spring Boot runner headless spec to verify:

- default label remains unchanged
- running services gain the `● ` prefix
