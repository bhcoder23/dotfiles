# Tmux + Agent + OpenCode Cheat Sheet

## Core Rules

- Prefix: `Ctrl+s`
- `M-x` means `Option+x` in `Ghostty`
- Preferred paste path in `Ghostty` + `tmux` + `nvim`: `Cmd+v`
- Use `op` / `se` / `opr` instead of bare `opencode` if you want tracker status and notifications
- `session = 项目`，`main window = 主仓库`，`feature window = 独立 worktree workflow`
- `flow` 是 workflow control plane；Git 只负责 worktree，`flow` 负责 start/list/resume/destroy

## Agent Worktrees

### Model

- 主窗口留在真实仓库路径，负责讨论、总览、合并
- 功能窗口使用外部 worktree：`~/worktrees/<repo>/<branch>`
- 功能窗口固定三栏：
  - 左侧：`op`
  - 右上：`lazygit`
  - 右下：shell

### Commands

- 创建 workflow：`flow start "feature/x"`
- 查看当前 repo workflows：`flow list`
- 查看所有 repo workflows：`flow list --all`
- 诊断当前 repo workflows：`flow doctor`
- 诊断所有 workflows：`flow doctor --all`
- 恢复指定 workflow：`flow resume "feature/x"`
- 删除当前 workflow：`flow destroy`
- 删除指定 workflow：`flow destroy "feature/x"`
- 预览清理 stale registry：`flow gc`
- 真正清理 stale registry：`flow gc --apply`

### Safety

- `flow destroy` 只删除当前 feature window 对应的本地 worktree 和本地 branch
- 有未提交改动时会拒绝删除
- 当前 workflow 还有未完成 todos 时会拒绝删除
- 不会删除远端分支
- `flow gc` 默认只 dry-run，只清理“worktree 不存在且 tmux window 不存在”的 stale registry 记录

## Sessions

### Create / Switch / Rename

- New session: `prefix + Ctrl+c`
- New side session from current path: `Option+Shift+s`
- Rename current session: `prefix + .`
- Session chooser: `prefix + s`
- Left / right adjacent session: `Option+p` / `Option+n`（不循环）
- Direct session 1-9: `F1` .. `F9`
- Alternate direct session 1-9: `Ctrl+1` .. `Ctrl+9`
- Move current session left / right in the session bar: `prefix + {` / `prefix + }`

### Close / Inspect

- Close current session: `prefix + Q`

```bash
tmux ls
tmux display-message -p '#S'
tmux kill-session -t =
tmux kill-server
```

## Windows

- New window: `Option+o`
- Rename current window: `prefix + ,`
- Close current window: `prefix + q`
- Previous / next window: `Option+,` / `Option+.`
- Previous / next window with prefix: `prefix + Ctrl+p` / `prefix + Ctrl+n`
- Go to window 1-9: `Option+1` .. `Option+9`
- Move current window to session 1-10: `prefix + 1` .. `prefix + 0`
- Move current window left / right inside current session: `Option+<` / `Option+>`
- Open chooser tree: `prefix + W`

## Panes

### Split / Focus / Close

- Split left / down / up / right: `prefix + h/j/k/l`
- Focus pane left / down / up / right: `Option+h/j/k/l`
- Focus helper panes: `Option+a` left, `Option+g` top-right, `Option+r` bottom-right
- Break current pane into its own window: `Option+Shift+o`
- Close current pane: `Option+q`
- Toggle zoom: `Option+f`

### Resize / Layout

- Resize left / down / up / right: `Option+H/J/K/L`
- Swap pane down / up: `prefix + >` / `prefix + <`
- Toggle layout orientation: `prefix + Space`
- Build layout left / down / up / right: `prefix + H/J/K/L`
- Move pane with chooser: `prefix + S` vertical, `prefix + V` horizontal
- Toggle synchronized input: `prefix + Ctrl+g`

## Copy / Paste

- Paste from macOS clipboard: `Cmd+v`
- Tmux paste fallback: `Option+v`
- Extra paste fallback: `Ctrl+Shift+v`
- Enter copy mode: `prefix + [`
- Paste tmux buffer: `prefix + p`
- List tmux buffers: `prefix + b`

### Copy Mode

- Move: `h/j/k/l`
- Jump: `e`, `H`, `L`, `J`, `K`
- Start selection: `v`
- Rectangle selection: `Ctrl+v`
- Copy to macOS clipboard: `y`
- Copy to end of line: `Y`
- Quit: `q` or `Esc`

## Agent Tracker

### Global Shortcuts

- Open Agent Palette: `Option+s`
- Watch current pane as a long task: `Option+w`
- Jump to latest notified pane: `Option+m`
- Jump back to the source pane: `Option+Shift+m`
- Toggle unread mark on current window: `Option+b`
- Toggle desktop notifications: `prefix + P`

### Agent Palette Entries

- `Workflows`
- `Tracker`
- `Activity Monitor`
- `Paste snippet`
- `Todos`
- `Edit devices`
- `Reload tmux config`
- `Bottom-right status`

### Agent UI Navigation

- Across Agent UI lists, `Ctrl+k` is previous and `Ctrl+j` is next
- Across Agent UI directional movement, `h/l` is left/right and `j/k` is down/up

### Workflow Panel

- Open from palette: `Option+s` → `Workflows`
- Filter list: 直接输入
- Move selection: `Ctrl+k` / `Ctrl+j`
- Create workflow: `Ctrl+a`
- Resume workflow: `Enter` or `Ctrl+r`
- Destroy selected workflow: `Ctrl+d`
- Back to palette: `Esc`

### Tracker Panel

- Move selection: `j/k`
- Open highlighted pane: `Enter`
- Settle highlighted task: `c`
- Delete highlighted task: `Shift+D`
- Back to palette: `Esc`
- Close palette directly: `Alt+s`

### Todos Panel

- Move selection: `j/k`
- Reorder within the same scope: `Ctrl+k` / `Ctrl+j`
- Switch between left / right columns: `h` / `l`
- Toggle left-side window views: `Tab`
- Move todo from global to window scope: `Shift+H`
- Move todo from window to global scope: `Shift+L`
- Jump to the todo target pane/window: `Enter`
- Toggle done: `Space`
- Add todo: `a` or `Alt+a`
- Edit todo: `Shift+E`
- Copy todo text: `y`
- Delete todo: `d`
- Set priority: `1` / `2` / `3`
- Show / hide completed items: `c`
- Close panel: `Esc` or `Alt+s`

### Todo Model

- Left side: current window + all windows
- Right side: global todos
- Status bar shows the current window todo count automatically

### Status Icons

- `⏳` running task or watched command
- `🔔` completed task or unread notification
- `❓` OpenCode is waiting for your reply

## OpenCode

### Shell Commands

- Start OpenCode in current project: `op`
- Start search agent mode: `se`
- Resume the saved OpenCode session for this tmux pane: `opr`

### Tmux Integration

- Restart current OpenCode pane and resume its saved session: `prefix + O`

### Pane Summary

- 这是 pane 级的一行短状态，不是 workflow 文档，也不是 `Todos`
- 形态通常是：`[theme] ↳ now`
- `theme` 表示这块工作整体在干嘛，`now` 表示当前下一步
- 由 Agent 通过 `set_work_summary` 维护，tmux 标题栏会自动显示

## Practical Flows

### Start A New AI Work Session

1. `Option+Shift+s`
2. `prefix + .`
3. `Option+o` if you need another window
4. run `op`
5. `Option+s`

### Start A New Feature Workflow

1. 在主仓库窗口进入项目目录
2. 执行 `flow start "feature/xxx"`
3. 等待自动创建 worktree + window + 三栏布局
4. 在左侧 `op` 干活，在右上 `lazygit` 看变更，在右下跑命令
5. 需要切回时执行 `flow resume "feature/xxx"`
6. 完成后在该功能窗口执行 `flow destroy`

### Watch A Long Command

1. run your command
2. press `Option+w`
3. wait for `🔔`
4. press `Option+m`

### Manage Todos

1. press `Option+s`
2. open `Todos`
3. press `a` to add a todo
4. press `Space` to mark it done
5. press `Shift+H` / `Shift+L` to move between window and global scope

### Close Things Safely

- Close pane: `Option+q`
- Close window: `prefix + q`
- Close session: `prefix + Q`
- Close all tmux sessions: `tmux kill-server`

## Where These Come From

- Main tmux config: `tmux/.tmux.conf`
- Tmux helper scripts: `tmux/.config/tmux/scripts/`
- Agent tracker: `agent-tracker/.config/agent-tracker/`
- OpenCode wrappers: `zsh/.config/zsh/functions/`
