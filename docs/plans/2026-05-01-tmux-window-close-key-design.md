# Tmux Window Close Key Design

## Goal

给当前 `tmux` 增加一个更顺手的 `window` 关闭快捷键：`prefix + Option+q`，同时保留已有的 pane 关闭键和 tmux 默认的确认式关闭入口。

## Current State

- 当前已经有：
  - `Option+q` 直接关闭当前 `pane`
  - `prefix + &` 使用 tmux 默认确认流程关闭当前 `window`
- 用户希望 `window` 关闭也能复用 `q` 这套肌肉记忆，但要通过 `prefix` 和 pane 关闭区分开。

## Chosen Approach

1. 保留 `Option+q -> kill-pane` 不变。
2. 新增 `prefix + Option+q -> kill-window`。
3. 保留默认 `prefix + &`，作为带确认的安全入口。
4. 更新速查表，明确区分 pane / window / session 的关闭方式。

## Verification

- `tmux source-file ~/.tmux.conf` 无报错
- `tmux list-keys` 中同时存在：
  - root `M-q kill-pane`
  - prefix `M-q kill-window`
- `docs/tmux-cheatsheet.md` 已写明新的 window 关闭键
