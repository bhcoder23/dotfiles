# Tmux Agent Worktree Workflow Design

## Goal

在现有 `tmux` / `zsh` / `opencode` / `agent-tracker` 体系上，补上一套“按分支创建独立 AI 工作区”的自动化工作流，让用户可以把：

- `session` 当成项目
- `window` 当成功能分支 / workflow
- `worktree` 当成隔离开发目录

并且进入 window 后就直接得到可工作的三栏布局。

## Current Context

- 现有仓库已经有稳定的 `tmux` 基础配置、pane/layout 脚本、`op`/`opr`/`se` 封装、`agent-tracker` 集成和速查文档。
- 用户已经确认：
  - `session = repo/project`
  - `window = workflow / feature branch`
  - worktree 放在仓库外部
  - 默认自动打开左侧 `op`
  - 布局参考现有截图：左大右双栏
- 本次先做基础工作流自动化，不处理多 Agent 编排。

## Approaches

### A. 全自动命令式工作流（Chosen）

提供两个命令：

- `start-agent <branch>`
- `destroy-agent [-y]`

由脚本自动处理：

- 创建 / 复用分支
- 创建 worktree
- 创建 tmux window
- 搭出固定布局
- 自动启动 `op` / `lazygit` / shell

**优点**

- 最贴近用户预期，几乎零手动步骤
- 最适合 tmux + AI 常态化开发
- 能与现有 tracker / op 工作流自然接上

**缺点**

- 需要脚本持有更多状态与安全检查

### B. 半自动工作流

只负责创建 branch + worktree + window，`op` 和 `lazygit` 由用户手动开。

**优点**

- 实现简单
- 出错面小

**缺点**

- 使用时割裂
- 每次还要补手工步骤

### C. 只做 tmux 模板，不碰 git worktree

只给固定 pane 布局和命令模板，分支 / worktree 用户手工管理。

**优点**

- 风险最低

**缺点**

- 失去“workflow 隔离”的核心价值
- 不满足本次目标

## Chosen Design

采用 **A：全自动命令式工作流**。

### Workspace Model

- `session`：项目级上下文，对应真实仓库
- `main window`：真实仓库路径，停在主分支，负责总览、讨论、git 操作
- `feature window`：某个功能分支，对应一个独立外部 worktree

### Worktree Location

统一使用：

`~/worktrees/<repo>/<branch>`

原因：

- 避免在项目内出现 worktree 嵌套
- 不会污染主仓库 `git status`
- 与后续 `superpowers` / 其它 workflow 工具更容易隔离

### Start Flow

命令：

`start-agent <branch>`

行为：

1. 检查当前目录是否在 git 仓库内
2. 定位 repo root 与 repo 名称
3. 生成 worktree 路径 `~/worktrees/<repo>/<branch>`
4. 如果本地 branch 不存在：
   - 从当前 HEAD 创建 branch
5. 如果 worktree 不存在：
   - 创建对应 worktree
6. 在当前 tmux session 中创建同名 window
7. 将新 window 布局为：
   - 左：`op`
   - 右上：`lazygit`
   - 右下：shell
8. 三个 pane 的 cwd 都是 worktree 路径
9. 结束时默认选中左侧 `op` pane

### Destroy Flow

命令：

`destroy-agent [-y]`

行为：

1. 从当前 window 的元数据推断：
   - 分支名
   - worktree 路径
   - repo root
2. 若 worktree 有未提交修改，则拒绝删除
3. 若当前 branch 仍被其它 worktree 使用，则拒绝删除
4. 无 `-y` 时给出确认提示
5. 关闭对应 tmux window
6. 删除该 worktree
7. 删除本地 branch
8. 不碰远端分支

### State Tracking

为避免靠 window 名推断所有信息，脚本会给 feature window 写 tmux window options：

- `@agent_branch`
- `@agent_worktree`
- `@agent_repo_root`
- `@agent_repo_name`
- `@agent_role=feature`

`main window` 则不写这些 feature 元数据。

这样后续：

- `destroy-agent`
- 状态展示
- 速查/扩展

都能稳定复用。

## Shell Entry Strategy

命令入口放在 `zsh/.config/zsh/functions/`，风格与现有：

- `op`
- `opr`
- `se`

保持一致。

推荐新增：

- `start-agent`
- `destroy-agent`

函数本身只做薄封装，真正逻辑放在：

- `tmux/.config/tmux/scripts/start_agent_workspace.sh`
- `tmux/.config/tmux/scripts/destroy_agent_workspace.sh`

这样：

- tmux 内外都能调脚本
- 逻辑集中
- 后续若要做 tmux prompt / palette 接入更容易

## Layout Details

feature window 固定三栏：

- 左侧约 60%：`op`
- 右上：`lazygit`
- 右下：shell

选择这个布局的原因：

- 左侧 AI 面板最大，适合持续对话
- 右上随时看 git diff / stage / commit
- 右下用于构建、测试、临时命令

三个 pane 都使用 worktree 路径，而不是主仓库路径。

## Safety Rules

- 当前不在 git 仓库中：直接失败
- 分支名为空或非法：直接失败
- worktree 已存在且 window 也存在：直接切换过去，不重复创建
- `op` 不存在：左侧 pane 保持 shell，并提示手动安装或手动执行
- `lazygit` 不存在：右上 pane 保持 shell
- 删除时若存在未提交修改：拒绝删除并提示先处理
- 删除时不删除远端分支

## Verification

实现完成后至少验证：

1. `bash -n` 检查新增/修改脚本
2. `tmux -L <socket>` 隔离环境下创建测试 session
3. 在测试仓库中运行 `start-agent <branch>`：
   - worktree 创建成功
   - window 创建成功
   - pane 布局正确
   - window 元数据写入成功
4. 运行 `destroy-agent -y`：
   - window 删除成功
   - worktree 删除成功
   - branch 删除成功
5. 更新 `docs/tmux-cheatsheet.md`

## Non-Goals

- 不做多 Agent 编排
- 不改 `superpowers` 工作流
- 不做远端分支自动推送/删除
- 不在本次加入复杂状态栏图标逻辑
