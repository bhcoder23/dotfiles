# Flow Control Plane Design

## Goal

在现有 `tmux + git worktree + op + agent-tracker` 工作流上增加一层轻量 control plane，把“功能分支工作区”的生命周期统一收口到一个主命令：

- `flow start`
- `flow list`
- `flow resume`
- `flow destroy`

目标不是替换 Git worktree，而是在保留 Git 原生隔离的前提下，补齐创建、恢复、销毁、状态跟踪和 tmux 布局恢复能力。

## Current Context

- 现有仓库已经有：
  - `tmux` 基础配置与三栏布局
  - `op` / `opr` / `se`
  - `agent-tracker` 的 tracker / todos / 通知
  - 外部 worktree 方案：`~/worktrees/<repo>/<branch>`
- 当前仓库中已经存在一版 `start-agent` / `destroy-agent` 原型，但用户明确要求：
  - 不保留旧命令
  - 统一用一个主命令
  - 主命令不要叫 `agent`，改为 `flow`
- 用户已确认：
  - `session = 项目`
  - `main window = 主仓库`
  - `feature window = 一个 workflow`
  - `feature window` 使用外部 worktree
  - `flow list` 默认当前 repo，支持 `--all`
  - registry 放在 `~/.local/state/flow/registry.json`
  - `flow resume`：window 在就切过去；window 不在就重建；worktree 不在就报错
  - `flow destroy`：dirty worktree / open todos 拒绝删除

## Approaches

### A. 保留当前裸 worktree 命令

只保留：

- `start-agent`
- `destroy-agent`

不做 registry，不做 list / resume / rebuild。

**优点**

- 实现最简单
- 依赖最少

**缺点**

- 没有 control plane
- 无法恢复丢失的 tmux window
- 无法列出 / 管理所有 workflow

### B. 学 `.agents` 模式，放弃 worktree

切换到：

- `<repo>/.agents/<feature>/repo`

这种“受管 repo copy”模式。

**优点**

- 生命周期完全由工具接管
- 更接近 `agent-tracker` 现有 Start agent 逻辑

**缺点**

- 不是 Git 原生 worktree
- 复杂度高
- 与用户已经接受的工作流不一致

### C. Worktree + Control Plane（Chosen）

保留外部 worktree：

- `~/worktrees/<repo>/<branch>`

在其上增加：

- registry
- CLI 生命周期管理
- tmux 布局重建
- todos / tracker 销毁保护

**优点**

- 保留 Git 原生 worktree 的稳定性
- 把 `.agents` 思路里真正有价值的“管理层”拿过来
- 与用户当前已经接受的 tmux/worktree 方案完全一致

**缺点**

- 需要新增一层状态管理
- 需要处理 registry 与 tmux 实际状态的一致性

## Chosen Design

采用 **C：Worktree + Control Plane**。

### Core Model

- `session`：项目级上下文
- `main window`：真实仓库路径 / 主分支 / 管理入口
- `feature window`：某个分支 workflow，对应一个外部 worktree
- `flow`：该 workflow 的 control plane 主命令

### Command Set

主命令统一为 `flow`：

- `flow start "<branch>"`
- `flow list`
- `flow list --all`
- `flow resume "<branch>"`
- `flow destroy`
- `flow destroy "<branch>"`

### Registry

registry 固定放在：

- `~/.local/state/flow/registry.json`

registry 只存运行态元数据，不存业务配置。

每条 workflow 至少记录：

- `repo_root`
- `repo_name`
- `branch`
- `worktree_path`
- `tmux_session_id`
- `tmux_session_name`
- `tmux_window_id`
- `pane_ai`
- `pane_git`
- `pane_run`
- `created_at`
- `updated_at`

这意味着：

- Git 负责代码隔离
- registry 负责工作流状态

### Start Semantics

`flow start "<branch>"`：

1. 确认当前路径处于 Git 仓库
2. 解析 repo common root，而不是 worktree 子路径
3. 生成外部 worktree 路径：
   - `~/worktrees/<repo>/<branch>`
4. 若 workflow 已在 registry 中且 window 仍活着：
   - 直接切回该 window
5. 若 workflow 已存在但 window 不在：
   - 重建 tmux 布局
6. 若 workflow 不存在：
   - 创建 branch
   - 创建 worktree
   - 创建三栏 tmux window
   - 写入 registry

### Layout

feature window 固定布局：

- 左 60%：`op`
- 右上：`lazygit`
- 右下：shell

三者 cwd 都指向该 feature 对应的 worktree。

### List Semantics

`flow list`：

- 默认只列当前 repo 的 workflow
- 不在 Git repo 中时提示使用 `flow list --all`

`flow list --all`：

- 列出所有 repo 的 workflow

输出最少包含：

- repo（仅 `--all`）
- branch
- status（`running` / `stopped` / `orphan`）
- tmux session/window
- worktree path

### Resume Semantics

`flow resume "<branch>"`：

- 默认只在当前 repo 范围内查找
- 若 window 还活着：
  - 直接切过去
- 若 window 不在但 worktree 还在：
  - 重建当前 workflow 的三栏布局
  - 左侧重新拉起 `op`
- 若 worktree 不在：
  - 报错

### Destroy Semantics

`flow destroy`：

- 默认销毁当前 workflow

`flow destroy "<branch>"`：

- 销毁当前 repo 中指定 workflow

安全规则：

- worktree 有未提交修改：拒绝
- 当前 workflow 还有未完成 todos：拒绝
- 删除范围：
  - tmux window
  - 外部 worktree
  - 本地 branch
- 不删除远端 branch

## Tmux Integration

`tmux` 只作为 UI / layout 层，不再承担 workflow 状态来源。

建议保留的入口：

- CLI：`flow start/list/resume/destroy`
- Agent UI：`Option+s` → `Workflows`

`tmux` window options 仍会写入少量元数据，作为当前 window 的快速定位信息：

- `@flow_branch`
- `@flow_worktree`
- `@flow_repo_root`
- `@flow_repo_name`
- `@flow_role`

## Agent Tracker Boundary

本次不重写 `agent-tracker` 的 `.agents` 生命周期方案。

保留使用它的：

- tracker
- todos
- notifications
- activity monitor

暂不直接复用它的：

- `.agents/<feature>/repo`
- Start agent repo-copy 工作流

也就是说：

- `agent-tracker` 负责“观察和辅助”
- `flow` 负责“真正的 workflow 生命周期”

## Error Handling

- 不在 Git repo 中执行 `flow start` / `flow resume` / `flow destroy "<branch>"`：
  - 直接报错
- branch 不合法：
  - 直接报错
- window id 丢失但 worktree 存在：
  - 允许重建
- registry 里有记录但 worktree 已被手工删掉：
  - `status = orphan`
  - `resume` 报错
- `flow destroy` 发生中途失败：
  - 保留 registry 记录，提示用户手工处理

## Verification

由于当前仓库没有针对 tmux / shell workflow 的正式测试框架，本次验证采用：

- `bash -n`
- `python3 -m py_compile`
- 隔离 tmux socket 集成验证
- 临时 Git repo / 临时 worktree 端到端验证

重点证明：

1. `flow start` 能创建 worktree 和 window
2. `flow list` 能正确显示状态
3. `flow resume` 能切回 / 重建
4. `flow destroy` 能执行安全检查并清理

## Non-Goals

- 不实现 `.agents` repo-copy 模式
- 不替换 `agent-tracker` 现有 tracker / todos 系统
- 不处理多 Agent 编排
- 不处理远端分支自动推送/删除
