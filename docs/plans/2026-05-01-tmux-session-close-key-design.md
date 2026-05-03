# Tmux Session Close Key Design

## Goal

给当前 `tmux` 增加一个和现有 `q` 系列一致的“直接关闭当前 session”快捷键，减少每次手打 `tmux kill-session -t =` 的成本。

## Current State

- 当前已经有：
  - `Option+q` 直接关闭当前 `pane`
  - `prefix + Option+q` 直接关闭当前 `window`
  - `prefix + &` 确认关闭当前 `window`
- 关闭当前 `session` 仍然只能走命令行：
  - `tmux kill-session -t =`

## Chosen Approach

1. 新增 `prefix + Q -> kill-session`。
2. 保持现有关闭层级一致：
   - `Option+q` -> pane
   - `prefix + Option+q` -> window
   - `prefix + Q` -> session
3. 不改现有 `Option+q` / `prefix + Option+q`。
4. 更新速查表，把命令和快捷键都写进去。

## Verification

- `tmux source-file ~/.tmux.conf` 无报错
- `tmux list-keys` 中存在 prefix `Q -> kill-session`
- `tmux list-keys` 中仍存在：
  - root `M-q -> kill-pane`
  - prefix `M-q -> kill-window`
- `docs/tmux-cheatsheet.md` 已补充 session 关闭快捷键
