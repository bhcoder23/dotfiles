# Ghostty JetBrainsMono Nerd Font Design

## Goal

Switch the Ghostty terminal font from Maple Mono Normal NF CN to JetBrainsMono Nerd Font without changing Starship symbols or other terminal appearance settings.

## Current State

- Ghostty is configured in `ghostty/.config/ghostty/config`.
- The active font family for regular, bold, italic, and bold italic text is `Maple Mono Normal NF CN`.
- Starship is configured separately and should remain unchanged.
- The local system already has multiple installed JetBrains Mono Nerd Font families, including `JetBrainsMono Nerd Font`, `JetBrainsMono Nerd Font Mono`, and `JetBrainsMono Nerd Font Propo`.

## Requirement

- Use `JetBrainsMono Nerd Font` directly in Ghostty.
- Do not modify Starship.
- Keep the rest of the Ghostty styling unchanged.

## Options Considered

### 1. Use `JetBrainsMono Nerd Font`

Pros:
- Matches the requested family name.
- Preserves Nerd Font glyph coverage for Starship and CLI tooling.
- Keeps proportional behavior disabled because this is the standard non-Propo family.

Cons:
- May render CJK text less naturally than the current CN-tuned Maple Mono setup.

### 2. Use `JetBrainsMono Nerd Font Mono`

Pros:
- Explicitly monospaced Nerd Font variant.
- Often preferred when terminals are sensitive to width handling.

Cons:
- Not the exact family name requested.
- Usually unnecessary when the standard Nerd Font family already works.

### 3. Use `JetBrainsMono Nerd Font Propo`

Pros:
- Can look visually smoother for prose-heavy content.

Cons:
- Proportional variant is a bad fit for terminal alignment.

## Chosen Approach

Use `JetBrainsMono Nerd Font` for all four Ghostty font-family declarations.

This is the closest match to the requested change, preserves Nerd Font coverage, and minimizes the diff by leaving size, style, ligature features, cursor settings, padding, and Starship untouched.

## Verification Strategy

- Confirm the exact family is installed locally.
- Update only the `font-family*` keys in `ghostty/.config/ghostty/config`.
- Verify the file contains the new family name on all four lines.
- Check the config has no trailing-whitespace or patch-formatting issues.
- User performs the final visual inspection in Ghostty after reload.
