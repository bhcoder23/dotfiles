# Agent Tracker Migration Design

## Goal

把当前已经安装并可运行的 `agent-tracker` 收进 `dotfiles`，变成一个符合仓库规范的 Stow 包，同时保留已经启动的 tracker service 和现有 tmux 集成路径。

## Current State

- `agent-tracker` 源码当前在 `~/.config/agent-tracker`
- `agent` / `tracker-mcp` / `tracker-server` 已构建
- `agent-tracker-server` 已通过 `brew services` 启动
- 仓库里还没有 `agent-tracker` 包
- `tmux` 已经引用 `~/.config/agent-tracker/bin/agent`

## Chosen Approach

1. 新建 `agent-tracker` Stow 包，路径镜像 `$HOME`：
   - `agent-tracker/.config/agent-tracker/...`
   - `agent-tracker/.local/bin/agent`
2. 将当前 `~/.config/agent-tracker` 内容同步进仓库包。
3. 使用忽略规则排除构建产物和运行态文件：
   - `bin/`
   - `run/`
   - `.build/`
4. 把 home 目录下的真实目录替换成 Stow symlink。
5. 验证：
   - `~/.config/agent-tracker` 指向仓库
   - `~/.local/bin/agent` 可执行
   - `agent tracker state` 正常
   - `brew services` 中服务仍为 `started`

## Notes

- `agent-tracker` 不是纯前台工具，它包含：
  - CLI 二进制 `agent`
  - MCP 二进制 `tracker-mcp`
  - 后台服务 `tracker-server`
- 源仓库推荐安装方式就是 build 后交给 `brew services` 管理。
