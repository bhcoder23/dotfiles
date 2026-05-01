# JDTLS Source Path Retry Design

## Context

The Java setup uses `mfussenegger/nvim-jdtls` directly from `ftplugin/java.lua`.

For larger Maven workspaces such as `rs-jarvis`, `nvim-jdtls` triggers `java.project.getSettings` as soon as it receives `ServiceReady`. In practice this can be earlier than the project import finishing. The result is a transient info notification:

- `Couldn't retrieve source path settings. Can't set 'path' (err=jarvis does not exist)`

Manual probing showed that the same command succeeds later, after the import completes.

## Root Cause

The failure is caused by timing, not by a permanently broken project:

- early request: JDTLS returns `jarvis does not exist`
- later request: JDTLS returns valid `org.eclipse.jdt.ls.core.sourcePaths`

The current behavior is therefore a false-negative early probe.

## Chosen Approach

Implement a local compatibility layer in `ftplugin/java.lua`:

- suppress the specific transient info notification emitted by `nvim-jdtls`
- run a local retry loop from `on_attach`
- call `java.project.getSettings` until source paths become available
- set buffer-local `'path'` once the request succeeds
- emit a single warning only if all retries fail

This keeps the fix local to the dotfiles repo and preserves the source-path feature.

## Alternatives Considered

### 1. Silence the message only

This removes noise but loses the original feature if the first request fails.

### 2. Patch upstream `nvim-jdtls`

This would be cleaner in theory, but it means carrying a vendor patch outside the dotfiles repo and makes updates harder.

### 3. Local retry plus targeted filtering

This keeps the feature, avoids vendor patching, and stays fully inside the managed config. This is the recommended approach.

## Implementation Notes

- retry count should cover large Maven imports without waiting forever
- retries should be per-buffer to avoid global state coupling
- notification filtering should only match the known source-path info message
- unrelated notifications must keep flowing normally

## Verification

Use two layers of verification:

- mock-based headless tests to verify retry logic and notification filtering
- real-project probe against `rs-jarvis` to confirm delayed success on an actual large Maven workspace
