# Tmux Close Pane Key Design

## Goal

把当前 `tmux` 的“直接关闭当前 pane”快捷键从 `⌥⇧Q` 改成更顺手、更稳定的 `⌥q`，同时保留 `prefix + x` 作为带确认的关闭方式。

## Current State

- 当前直接关闭 pane 的绑定是 `M-Q`。
- 在 `Ghostty + macOS + option-as-alt` 组合下，`⌥⇧Q` 的实际输入体验不稳定。
- 用户高频使用关闭 pane，希望更简单可靠。

## Chosen Approach

1. 将 `tmux/.tmux.conf` 中的 root 绑定从 `M-Q` 改为 `M-q`。
2. 保留默认的 `prefix + x` 确认关闭，避免误操作时没有退路。
3. 不改其它窗口/pane 键位，保持变更最小。

## Verification

- `tmux source-file ~/.tmux.conf` 无报错
- `tmux list-keys` 能看到 `M-q kill-pane`
- `tmux list-keys` 不再显示 `M-Q kill-pane`
