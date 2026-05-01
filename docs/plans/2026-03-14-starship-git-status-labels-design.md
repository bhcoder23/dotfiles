# Starship Git Status Labels Design

## Goal

Replace visually noisy private-use Nerd Font glyphs in the Starship `git_status` module with stable text labels so the status counts remain readable and aligned under the current terminal font.

## Current State

- The `git_status` module in `starship/.config/starship.toml` uses several Nerd Font private-use icons.
- Under the current `JetBrainsMono Nerd Font` setup, some of these glyphs look cramped or visually inconsistent.
- The user wants a text-based `U/M/S` style instead of icon-based markers.

## Requirement

- Use text labels instead of problematic icons.
- Keep the numeric counts intact and easy to scan.
- Preserve the existing color intent where practical.
- Avoid changing unrelated Starship modules.

## Options Considered

### 1. Replace only `untracked`, `modified`, and `staged`

Pros:
- Smallest possible change.

Cons:
- Leaves other problematic private-use glyphs in the same module.

### 2. Replace all `git_status` icons with text labels

Pros:
- Fully removes the rendering problem from this module.
- Keeps counts legible and consistent.
- Produces stable output across fonts.

Cons:
- Less decorative than icon-based output.

### 3. Replace icons with simpler Unicode symbols

Pros:
- Keeps some visual flair.

Cons:
- Still relies on glyph appearance and fallback behavior.

## Chosen Approach

Use option 2.

The `git_status` module will use text labels:

- `S` for staged
- `M` for modified
- `U` for untracked
- `R` for renamed
- `D` for deleted
- `C` for conflicted
- `T` for stashed
- `A` for ahead
- `B` for behind

The outer summary icon will also be removed so the whole module stays text-only.

## Verification Strategy

- Confirm the current config still contains the icon-based `git_status` strings.
- Replace the strings with text labels.
- Run Starship against a temporary Git repository containing one staged file, one modified file, and one untracked file.
- Verify the rendered `git_status` output shows `S 1`, `U 1`, and `M 1` correctly.
