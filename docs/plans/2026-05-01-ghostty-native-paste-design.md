# Ghostty Native Paste Bindings Design

## Goal

把 `Ghostty` 的系统复制/粘贴行为显式绑定为原生剪贴板动作，并额外加上物理按键绑定，避免 `Cmd+V` 在某些布局/键位解析下落不到原生粘贴动作。

## Current State

- 当前 `Ghostty` 已开启 `macos-option-as-alt = true`。
- 在 `tmux + nvim` 中，菜单/点击粘贴正常，但 `⌘V` 曾出现类似 `^[[27;5;106~` 的按键序列。
- 其中一层原因可能是 `Ghostty` 原生粘贴绑定不够显式，因此先把终端侧绑定固定下来。
- 如果显式绑定后仍出现按键序列，则继续排查 `tmux` 的扩展按键配置。

## Chosen Approach

1. 在 `ghostty/.config/ghostty/config` 中显式声明：
   - `super+c=copy_to_clipboard`
   - `super+v=paste_from_clipboard`
   - `super+key_c=copy_to_clipboard`
   - `super+key_v=paste_from_clipboard`
2. 保留现有其它 `Ghostty` 配置不变，避免影响 `tmux`、`nvim`、`Option as Alt` 等行为。
3. 物理按键绑定优先级更高，可绕开某些基于字符的键位匹配差异。
4. 用 `Ghostty` 自身命令确认配置被识别。
5. 若 `⌘V` 仍未被 Ghostty 消费，再在 `tmux` 中为 `M-v` 提供兜底粘贴。

## Verification

- `ghostty +list-keybinds` 能看到 `super+c` / `super+v` / `super+key_c` / `super+key_v`
- `Ghostty` 已明确把 `⌘C` / `⌘V` 作为系统剪贴板动作处理
