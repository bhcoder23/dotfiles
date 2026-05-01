# Search Keymap Trim Design

## Context

当前搜索相关键位分成两组：

- `<leader>f`：偏全局 picker / find 入口
- `<leader>s`：偏 search 入口

但实际使用上有一部分重复：

- `<leader>sg` / `<leader>sG` 和 `<leader>f` 体系中的全局搜索入口存在能力重叠
- `<leader>sW` 是较窄且不常用的“当前 buffer 词搜索”

用户希望保留：

- `<leader>f` 作为主入口
- Spring Boot 的专属搜索键位继续保留在 `<leader>s`
- `<leader>s` 只放 `<leader>f` 没有替代的能力

## Goal

让 `which-key` 里的 `+search` 更短、更聚焦，只保留独特功能。

## Options Considered

### 1. 保留现状

优点：

- 不需要迁移使用习惯

缺点：

- `which-key` 展示偏拥挤
- 重复搜索入口过多

### 2. 只删明显重复项

保留：

- `sw` 搜索当前词
- `sr` 搜索替换
- `ss` / `sS` LSP symbol 搜索
- `sb` / `se` Spring 专属搜索

删除：

- `sg`
- `sG`
- `sW`

优点：

- `<leader>s` 仍然保留“搜索补充组”的定位
- 不影响 Spring 和 LSP 的专属能力
- 删除的都是用户已明确判断为重复或低频的项

这是本次采用的方案。

### 3. 把 `<leader>s` 继续缩到只剩 Spring

优点：

- 最极致地收敛

缺点：

- 会丢掉 `sw` / `sr` / `ss` / `sS` 这些明显有独立价值的快捷键
- 不符合“只保留独特能力”的更宽松目标

## Chosen Design

保留这些键位：

- `<leader>sw`：搜索当前词
- `<leader>sr`：搜索替换
- `<leader>ss`：当前文件 LSP symbols
- `<leader>sS`：工作区 LSP symbols
- `<leader>sb`：Spring Beans
- `<leader>se`：Spring Endpoints

删除这些键位：

- `<leader>sg`
- `<leader>sG`
- `<leader>sW`

不改 `<leader>f` 现有入口。

## Verification

做一个最小 headless 验证：

- `snacks/picker.lua` 中不再注册 `sg` / `sG` / `sW`
- `sw` 仍然存在
- Java `ftplugin` 里的 `sb` / `se` 仍然存在
- LSP attach 逻辑里的 `ss` / `sS` 不受影响
