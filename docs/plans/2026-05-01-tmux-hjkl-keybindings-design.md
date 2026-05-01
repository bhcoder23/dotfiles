# Tmux HJKL Keybindings Design

## Goal

把当前 `tmux` 里基于 `u/e/n/i` 的方向操作统一成 Vim 风格的 `h/j/k/l`，并把会与新方向键冲突的旧窗口/会话快捷键挪到不冲突的位置。

## Current State

- 当前 pane split、pane move、pane resize、copy-mode 导航仍以 `u/e/n/i` 为主。
- 用户是 Vim 用户，希望方向类操作统一成 `h/j/k/l`。
- 当前还有少量非方向操作占用了 `l` / `L`，包括 window 前后切换、window 交换、session 左右移动。

## Chosen Approach

1. 把方向类主操作改成 `h/j/k/l`：
   - `prefix + h/j/k/l`：按方向分屏
   - `Alt + h/j/k/l`：按方向切 pane
   - `Alt + H/J/K/L`：按方向调整 pane 大小
   - `copy-mode-vi`：恢复/显式绑定 `h/j/k/l`
   - `prefix + H/J/K/L`：按方向构建 layout
2. 把占用 `l` 族键位但不属于 pane 方向的功能迁走：
   - `Alt + ,` / `Alt + .`：前后 window
   - `Alt + <` / `Alt + >`：左右交换 window
   - `prefix + [` / `prefix + ]`：左右移动 session
3. 保留其它非方向快捷键不变，降低迁移成本。

## Verification

- `tmux source-file ~/.tmux.conf` 无报错
- `tmux list-keys` 能看到新的 `h/j/k/l` 绑定
- `tmux list-keys -T copy-mode-vi` 能看到新的 `h/j/k/l` 复制模式绑定
