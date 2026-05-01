# Ghostty Font Feature Cleanup Design

## Goal

Remove the Maple Mono-specific stylistic set flags from Ghostty after switching to JetBrainsMono Nerd Font, while keeping the useful general ligature settings.

## Current State

- Ghostty now uses `JetBrainsMono Nerd Font`.
- The config still contains the previous font feature list:
  - `calt`
  - `liga`
  - `ss02`
  - `ss07`
  - `ss08`
  - `ss10`
  - `ss11`
  - `ss12`
  - `ss17`
  - `ss18`
- These `ssXX` flags were tuned for the earlier Maple Mono setup, not specifically for JetBrains Mono.

## Requirement

- Keep the font family unchanged.
- Do not touch Starship.
- Simplify Ghostty font features so JetBrains Mono is rendered without the inherited stylistic-set overrides.

## Options Considered

### 1. Keep all current font features

Pros:
- No config change.

Cons:
- Keeps font-specific stylistic-set baggage from the previous font.
- Makes debugging text rendering harder.

### 2. Remove only the `ssXX` features and keep `calt`/`liga`

Pros:
- Minimal diff.
- Preserves standard ligature behavior.
- Removes the most likely source of JetBrains Mono rendering inconsistencies.

Cons:
- If a specific stylistic set was intentionally desired, it would need to be re-added explicitly later.

### 3. Remove all font features

Pros:
- Fully neutral baseline.

Cons:
- More aggressive than necessary.
- Disables standard ligatures too.

## Chosen Approach

Use option 2.

Keep:

- `font-feature = calt`
- `font-feature = liga`

Remove:

- `ss02`
- `ss07`
- `ss08`
- `ss10`
- `ss11`
- `ss12`
- `ss17`
- `ss18`

## Verification Strategy

- Confirm the current config still contains the `ssXX` lines before the edit.
- Remove only those lines.
- Verify the resulting config keeps `calt` and `liga` and no longer contains any `ssXX` entries.
- Run `git diff --check` to confirm the patch is clean.
