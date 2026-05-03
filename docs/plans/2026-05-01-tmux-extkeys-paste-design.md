# Tmux Extended Keys Paste Fix Design

## Goal

修复 `Ghostty + tmux + nvim` 下 `⌘V` 被插入为类似 `^[[27;5;106~` 的转义序列问题，同时让 `tmux` 配置可以被重复 `source` 而不会越积越多。

## Current State

- `ghostty/.config/ghostty/config` 已显式绑定 `super+v=paste_from_clipboard`。
- 用户继续复现到 `⌘V` 粘贴 JSON 时出现原始转义序列。
- `tmux/.tmux.conf` 开启了：
  - `extended-keys on`
  - `terminal-features ... extkeys`
- `tmux` 当前还通过 `set -as` 追加 `terminal-features` / `terminal-overrides`，每次 `source-file` 都会重复追加。

## Root Cause

- `⌘V` 没有作为纯粘贴动作被终端消费，而是以扩展按键序列进入了 `tmux` / `nvim`。
- `tmux` 的 `extended-keys/extkeys` 让这类组合键更容易以转义序列形式透传。
- 同时，`terminal-features` 与 `terminal-overrides` 使用追加模式，在反复 `source` 后会产生重复项，增加调试噪音。

## Chosen Approach

1. 在 `tmux/.tmux.conf` 中关闭 `extended-keys`。
2. 移除对 `xterm*:extkeys` 的显式追加。
3. 在追加 `RGB` / `Tc` 之前先 `unset` 对应选项，保证 `source-file` 幂等。
4. 如果 `Ghostty` 仍把 `⌘V` 漏给 `tmux`，则把 `tmux` 收到的 `M-v` 作为系统剪贴板粘贴兜底，而不是进入 `copy-mode`。
5. 保留现有 `xterm-keys`、真彩色、Ghostty 原生粘贴绑定和其它快捷键体系不变。

## Verification

- `tmux source-file ~/.tmux.conf` 无报错
- `tmux show -s extended-keys` 显示 `off`
- `tmux show -s terminal-features` 不再包含 `xterm*:extkeys`
- `tmux show -s terminal-features` 中 `*256col*:RGB` 不会因重复 `source` 无限增长
- `tmux list-keys` 中 root / `copy-mode` / `copy-mode-vi` 里的 `M-v` 都指向剪贴板粘贴
- 用户在 `tmux + nvim` 中使用 `⌘V` 粘贴多行 JSON，不再出现 `^[[27;5;106~`
