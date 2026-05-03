# Flow Doctor And GC Design

## Goal

为当前 `flow` control plane 增加一层“自检与清理”能力，让 workflow 生命周期不仅能创建/恢复/销毁，还能回答：

- 现在哪些 workflow 是健康的
- 哪些 workflow 已经坏掉了
- 哪些 registry 记录只是垃圾，可以安全清掉

## Current Context

当前 `flow` 已经具备：

- `start`
- `list`
- `resume`
- `destroy`

并且已经能区分基础状态：

- `running`
- `stopped`
- `orphan`

但它还缺两件事：

- 一个明确的诊断入口，告诉用户“哪里有问题、怎么修”
- 一个安全的垃圾清理入口，避免 registry 越积越脏

## Approaches

### A. 只加 `flow doctor`

只提供诊断，不提供清理。

**优点**

- 风险最低
- 行为最容易解释

**缺点**

- 用户还是要手工清 stale registry
- 诊断和修复脱节

### B. `flow doctor` + 安全 `flow gc`（Chosen）

提供两层能力：

- `flow doctor`：检查并给出建议
- `flow gc`：只清理“确定安全”的 stale registry 记录

并坚持：

- `doctor` 不改状态
- `gc` 默认 dry-run
- `gc --apply` 才真正删除

**优点**

- 诊断与治理闭环完整
- 风险仍然可控
- 非常适合 dotfiles 这种长期演进环境

**缺点**

- 需要定义“安全可删”的边界
- 需要维护一套 issue/suggestion 模型

### C. 直接做自动修复

让 `flow doctor` 检查完后自动修 session / pane / registry。

**优点**

- 表面上最省事

**缺点**

- 太容易误修
- 在 tmux / worktree / todos 三方状态下不可控
- 不适合作为第一版

## Chosen Design

采用 **B：`flow doctor` + 安全 `flow gc`**。

### `flow doctor`

命令形态：

- `flow doctor`
- `flow doctor --all`
- `flow doctor --json`

默认行为：

- 当前 repo 范围
- 输出人类可读表格
- 有问题时返回非零退出码

每个 workflow 至少检查：

- worktree 是否存在
- tmux window 是否还活着
- tmux session 目标是否仍可用于 resume
- `pane_ai` / `pane_git` / `pane_run` 是否仍然有效
- live window metadata 与 registry 是否一致
- worktree 是否 dirty

输出字段建议包括：

- repo
- branch
- status
- health
- issues
- suggested fix

### Issue Model

第一版 issue 类型控制在最小集合：

- `missing-worktree`
- `missing-window`
- `missing-session`
- `missing-pane-ai`
- `missing-pane-git`
- `missing-pane-run`
- `window-metadata-mismatch`
- `dirty-worktree`

其中：

- `dirty-worktree` 属于提醒，不等于损坏
- `missing-worktree` + window 不存在，是最典型的 stale entry

### Suggestion Model

第一版建议保持直接：

- `flow resume "<branch>"`
- `flow destroy "<branch>"`
- `flow gc --apply`
- `restore worktree manually`
- `resume from the target tmux session`

`doctor` 的价值不是自动修，而是给出“下一步最短路径”。

### `flow gc`

命令形态：

- `flow gc`
- `flow gc --all`
- `flow gc --apply`

默认行为：

- dry-run
- 只打印将清理哪些记录

真正执行必须加：

- `--apply`

第一版只清理“安全 stale registry”：

- worktree 不存在
- tmux window 不存在

也就是：

- 不删 live window
- 不删 existing worktree
- 不碰远端 branch
- 不碰 dirty worktree

### Scope Boundaries

第一版不做：

- 自动修 pane 布局
- 自动改 session 绑定
- 自动删除 local branch
- 自动恢复 worktree
- palette UI 集成

先把 CLI 做稳，再考虑把 doctor 接进 `Workflows` 面板。

## Verification

这一阶段验收通过的标准是：

1. `flow doctor` 能识别当前 repo 和 `--all`
2. `flow doctor --json` 输出稳定结构
3. `flow doctor` 能对 orphan/stopped/pane-missing 给出正确建议
4. `flow gc` 默认只 dry-run
5. `flow gc --apply` 只删安全 stale registry 记录
6. `flow list` / `resume` / `destroy` 的既有语义不被破坏
