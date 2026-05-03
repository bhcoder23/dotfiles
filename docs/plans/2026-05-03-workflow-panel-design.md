# Workflow Panel Design

## Goal

把当前 `Start workflow / Resume workflow / Destroy workflow` 三段式入口，收口为一个统一的 `Workflows` 面板，让 workflow 成为一个可搜索、可预览、可直接操作的一等对象。

## Current Problem

当前 palette 首页把 workflow 生命周期拆成多个动作：

- `Start workflow`
- `Resume workflow`
- `Destroy workflow`

这种设计可以工作，但有两个明显问题：

- 信息与动作割裂：用户先选“想做什么”，再进入列表，而不是先看到 workflow 再决定操作
- 列表能力复用不足：搜索、计数、预览已经存在，却只挂在 `Resume workflow` 下

对用户来说，更自然的心智模型不是“我要执行 start / resume / destroy 命令”，而是“我要管理某个 workflow”。

## Approaches

### A. 保持现状

继续保留：

- `Start workflow`
- `Resume workflow`
- `Destroy workflow`

**优点**

- 改动最小
- 不需要重构 workflow 视图语义

**缺点**

- 心智模型偏命令式，不够对象化
- workflow 数量与状态无法作为首页主信息出现
- 搜索和预览能力不能统一复用

### B. 统一为单独的 `Workflows` 面板（Chosen）

首页只保留一个入口：

- `Workflows`

进入后直接显示：

- 左侧 workflow 列表
- 右侧详情预览
- 顶部 filter 输入
- 列表计数与状态

并在列表内直接操作：

- `Ctrl+a`：创建 workflow
- `Enter` / `Ctrl+r`：恢复 workflow
- `Ctrl+d`：删除 workflow（确认）
- `j/k`：移动
- `Esc`：返回 palette

**优点**

- workflow 成为一等对象，操作更集中
- 搜索、预览、计数、状态共用同一套 UI
- 后续扩展 `copy branch` / `reveal path` / `rename` 更自然

**缺点**

- 需要调整现有首页动作结构
- `Start workflow` 从直接动作改成列表内动作，路径多一步

## Chosen Design

采用 **B：统一为单独的 `Workflows` 面板**。

### Palette 首页

首页移除：

- `Start workflow`
- `Resume workflow`
- `Destroy workflow`

改为单入口：

- `Workflows`

其副标题说明为当前 repo 的 workflow 管理入口。

### Workflow 面板

workflow 面板复用当前 `Resume workflow` 页面基础结构，但语义改成完整管理页：

- 标题从 `Resume Workflow` 改成 `Workflows`
- 左侧列表显示 workflow 数量
- 右侧预览显示：branch / status / session / window / worktree path
- 当前 active workflow 继续标识为 `ACTIVE`

### Workflow 操作

在 workflow 列表页中：

- `Enter`：恢复 / 切换到选中的 workflow
- `Ctrl+r`：同 `Enter`
- `Ctrl+a`：进入小 prompt，输入 branch 后创建 workflow
- `Ctrl+d`：对选中的 workflow 做删除确认
- `Esc`：回到 palette 首页

删除确认语义：

- 若选中的是当前 active workflow，也允许销毁，但依然通过既有安全保护
- dirty worktree / open todos 仍拒绝删除

### Filter 语义

保留当前顶部 filter 输入框：

- 打字即过滤
- 按 branch / status / session / worktree path 做模糊匹配
- 支持空格分词

这样既保留现有能力，也让 workflow 数量、搜索与操作集中在一个地方。

### Non-Goals

这次不做：

- workflow rename
- workflow rebuild
- palette 首页直接显示 workflow 数量
- tmux 新增 workflow 专属快捷键

## Verification

验收以这几个场景为主：

1. `Option+s` 首页只看到一个 `Workflows` 入口
2. 进入 `Workflows` 后能看到 workflow 数量与列表
3. `Ctrl+a` 能创建 workflow
4. `Enter` / `Ctrl+r` 能恢复 stopped workflow
5. `Ctrl+d` 能删除选中 workflow，并弹确认
6. 搜索仍然生效
