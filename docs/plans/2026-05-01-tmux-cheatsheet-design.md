# Tmux Cheatsheet Design

## Goal

为当前这套 `tmux + agent-tracker + opencode` 配置补一份长期可查的速查表，重点覆盖 session 管理、pane / window 操作、Agent 工作流和常用命令。

## Current State

- 现有 README 只说明了 `tmux` 前缀和安装方式。
- 实际快捷键已经较多，且混合了：
  - `tmux` 原生概念
  - 自定义 `hjkl`
  - `agent-tracker`
  - `opencode`
- 用户已经明确表示希望后续直接在仓库里查看，不想每次重新问。

## Chosen Approach

1. 新增独立文档 `docs/tmux-cheatsheet.md`。
2. 按使用场景组织内容，而不是按配置文件顺序罗列。
3. 把“没有快捷键、只能命令行处理”的 session 删除方式也写进去。
4. 在 `README.md` 的 tmux 章节加入入口，方便以后直达。

## Verification

- 仓库中存在 `docs/tmux-cheatsheet.md`
- README 能明确指向这份速查表
- 速查表至少覆盖：
  - session 新建 / 切换 / 重命名 / 删除
  - window / pane
  - copy / paste
  - `agent-tracker`
  - `op` / `se` / `opr`
