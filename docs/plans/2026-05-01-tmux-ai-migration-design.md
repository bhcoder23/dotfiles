# Tmux AI Migration Design

## Goal

在现有 `tmux` Stow 包上恢复 `/Users/mason77/test/config/.tmux.conf` 与 `/Users/mason77/test/config/tmux` 中的 AI / agent / opencode 工作流，同时保持当前仓库规范，并确保 `agent-tracker` 或 `opencode` 尚未安装时 `tmux` 仍能正常启动和使用。

## Current State

- `tmux` 基础工作流已经迁入仓库。
- 当前仓库版配置移除了：
  - `agent-tracker` hooks
  - agent palette / watch / unread / notification 绑定
  - opencode pane restart / resurrect 恢复钩子
  - AI 状态栏图标与 pane 标题摘要
- 用户后续会做 `tmux + AI` 开发，希望恢复完整能力。
- 用户当前还没有安装 `opencode`，所以迁移必须是“有依赖就启用，没有依赖就跳过”。

## Chosen Approach

恢复源配置里的 AI 能力，但对所有外部依赖做安全降级：

1. 恢复 `.tmux.conf` 中的 agent/op hooks、快捷键、状态栏图标、restore hook。
2. 补齐源目录里的 AI 脚本和状态脚本到 `tmux/.config/tmux/...`。
3. 对依赖 `agent-tracker`、`opencode`、`jq` 的地方增加保护：
   - 二进制不存在时不报错
   - 快捷键触发时只提示不可用或静默跳过
   - `tmux` 启动、attach、source-file 不因缺依赖失败
4. 保留现有仓库里的兼容修复：
   - `pane-scrollbars` 使用 `set -gq`
   - TPM 初始化做存在性保护
   - 右侧状态栏在没有 agent 时回退到当前的 cost/time 样式

## Scope

### 恢复的能力

- `agent-tracker` hooks：
  - `client-attached`
  - `pane-focus-in`
  - `pane-died`
  - `after-select-window`
  - `client-session-changed`
- AI 快捷键：
  - `prefix + O` 重启当前 opencode pane
  - `M-s` agent palette
  - `M-b` unread toggle
  - `M-w` watch pane
  - `M-m` / `M-M` 跳转 tracker 通知来源
  - `P` 切换通知
- AI 状态展示：
  - session 图标
  - window 图标
  - 右侧 agent status
  - pane 标题中的 opencode summary / question / watching 状态
- resurrect / continuum 恢复脚本

### 恢复的文件

- `tmux/.tmux.conf`
- `tmux/.config/tmux/scripts/open_agent_palette.sh`
- `tmux/.config/tmux/scripts/watch_pane.sh`
- `tmux/.config/tmux/scripts/restart_opencode_pane.sh`
- `tmux/.config/tmux/scripts/post_resurrect_restore.sh`
- `tmux/.config/tmux/scripts/restore_agent_run_panes.py`
- `tmux/.config/tmux/scripts/restore_agent_tracker_mapping.py`
- `tmux/.config/tmux/scripts/resurrect_op_session.sh`
- `tmux/.config/tmux/tmux-status/notes_count.sh`
- `tmux/.config/tmux/tmux-status/session_task_icon.sh`
- `tmux/.config/tmux/tmux-status/window_task_icon.sh`
- `tmux/.config/tmux/tmux-status/tracker_cache.sh`
- `tmux/.config/tmux/tmux-status/mem_usage.sh`
- `tmux/.config/tmux/tmux-status/mem_usage_cache.py`

## Safe Fallback Rules

- `~/.config/agent-tracker/bin/agent` 不存在：
  - hooks 静默跳过
  - `open_agent_palette.sh` 不弹出失败命令，改为 `tmux display-message`
  - 右侧状态栏回退到当前 cost/time
- `op` / `opencode` 不存在：
  - `restart_opencode_pane.sh` 只提示不可用，不向 pane 发送坏命令
  - restore 脚本继续执行其它恢复逻辑
- `jq` 不存在：
  - tracker-based 图标和统计静默跳过
- `tmux refresh-client -S` 在无 client 场景失败：
  - 统一改成 `tmux refresh-client -S 2>/dev/null || true`

## Verification

迁移完成后需要证明：

- `tmux -L dotfiles-ai -f ~/dotfiles/tmux/.tmux.conf new-session -d -s verify` 成功
- `tmux -L dotfiles-ai source-file ~/.tmux.conf` 无报错
- `list-keys` 能看到 AI 相关绑定
- 新增脚本 `bash -n` / `python3 -m py_compile` 通过
- 在未安装 `opencode` / 缺失 `agent-tracker` 时，配置仍可加载
