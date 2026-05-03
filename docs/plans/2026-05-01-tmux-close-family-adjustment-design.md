# Tmux Close Family Adjustment Design

## Goal

把当前关闭键位最终收敛成一套更顺手的 `q` 家族：

- `Option+q`：关闭当前 `pane`
- `prefix + q`：关闭当前 `window`
- `prefix + Q`：关闭当前 `session`

## Current State

- 当前已经实现：
  - `Option+q -> kill-pane`
  - `prefix + Option+q -> kill-window`
  - `prefix + Q -> kill-session`
- 用户希望 `window` 关闭再简化一步，不再需要 `Option`，直接用 `prefix + q`。

## Chosen Approach

1. 保留 root `M-q -> kill-pane`。
2. 把 prefix `M-q -> kill-window` 改为 prefix `q -> kill-window`。
3. 保留 prefix `Q -> kill-session`。
4. 更新速查表，让 `pane / window / session` 三层关闭方式一眼可查。

## Verification

- `tmux source-file ~/.tmux.conf` 无报错
- 独立 tmux server 的键表中存在：
  - root `M-q -> kill-pane`
  - prefix `q -> kill-window`
  - prefix `Q -> kill-session`
- `docs/tmux-cheatsheet.md` 已更新为最终键位
