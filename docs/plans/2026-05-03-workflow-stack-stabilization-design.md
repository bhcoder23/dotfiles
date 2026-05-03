# Workflow Stack Stabilization Design

## Goal

把当前 dotfiles 中已经跑通的 `tmux + flow + agent-tracker + opencode wrappers` 这条主线收敛成一个“可提交、可复用、可验证”的稳定版本。

这次不继续扩新功能，而是优先解决三类问题：

- live 行为和文档不一致
- 当前真正要交付的范围不清晰
- 缺少一眼可执行的验收路径

## Scope Decision

这次采用 **窄范围稳定化**：

只处理当前已经是主工作流一部分的内容：

- `README.md`
- `docs/tmux-cheatsheet.md`
- `tmux/.config/tmux/scripts/flow.py`
- `tmux/.tmux.conf`
- `agent-tracker` palette / tracker 相关当前行为
- `zsh` 中 `op` / `opr` / `se` 相关说明
- 当前这条主线的新设计文档

不处理的内容：

- `nvim` / `ghostty` 等无关配置继续扩展
- 旧的历史设计稿全面翻修
- 新增 `flow doctor` / `flow gc` / notes / multi-agent orchestration

## Why This Scope

当前仓库里已经混有：

- 历史方案的设计文档
- 新的 `flow` / workflow 面板实现
- tracker / opencode / tmux 的联动配置

如果这次做“大扫除式重构”，会把 A 阶段拖得过长，也会让提交边界失控。

因此这次只做：

1. 修真实使用面上的 bug
2. 对齐 README / cheatsheet / 当前设计文档
3. 补最关键的回归测试
4. 形成一条明确的 smoke test 路径

## Chosen Changes

### 1. 修 live bug

优先修真实行为问题，例如：

- palette 中 `Reload tmux config` 指向错误路径
- 文档与当前键位/命令不一致

### 2. 对齐当前使用说明

README 要准确反映：

- active stow packages
- 依赖项（如 `go`、`lazygit`）
- `flow` / `Workflows` / `op` / `opr` / `se` 的真实使用方式

### 3. 收口当前设计文档

只更新这条主线最新的设计/计划文档：

- `flow-control-plane*`
- `workflow-panel*`

目标不是保留设计演进史，而是让最近的文档能代表当前行为。

### 4. 补 smoke verification

形成一组最低限度但可信的验证：

- Go tests for palette behavior
- `python3 -m py_compile` for `flow.py`
- `tmux source-file ~/.tmux.conf`
- 命令级 smoke checks（`flow --help`、wrapper 可解析）

## Non-Goals

这次不做：

- `flow doctor`
- `flow gc`
- workflow notes/context
- multi-agent orchestration
- 历史归档文档全面重写

## Verification

A 阶段验收通过的标准是：

1. README 与 cheatsheet 不再误导当前使用
2. palette 的 workflow 行为与热键有测试覆盖
3. palette reload tmux config 使用正确路径
4. `flow.py`、agent-tracker、tmux reload 全部可通过基本验证
5. 形成可提交的稳定边界
