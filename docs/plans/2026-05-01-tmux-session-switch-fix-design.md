# Tmux Session Switch Fix Design

## Goal

修复当前 `tmux` session 切换“不生效/不稳定”的问题，并给出一组不依赖 `Ctrl+数字` 扩展按键的稳定切换入口。

## Current State

- 当前配置里有 `Ctrl+1..9` 和 `F1..F5` 的 session 切换绑定。
- 之前为了修复 `Ghostty + tmux + nvim` 粘贴问题，关闭了 `tmux extended-keys`。
- `switch_session_by_index.sh` 还在按 session 名字前缀（如 `2-`）匹配，而不是按当前排序后的第 N 个 session 切换。
- `source-file` 后旧的 `u/e/n/i` 风格 root / prefix 绑定会残留一部分，造成 live 行为和文件不完全一致。

## Root Cause

1. `Ctrl+数字` 在关闭 `extended-keys` 后不再可靠，可能根本不会稳定送达 tmux。
2. `switch_session_by_index.sh` 通过名字前缀匹配，当 session 编号曾出现跳号时，`Ctrl+2` 之类会找不到目标。
3. 旧绑定没有被显式 `unbind`，reload 后 live key table 里会同时存在新旧风格绑定，进一步加重混乱。

## Chosen Approach

1. 让 `switch_session_by_index.sh` 直接调用 `session_manager.py switch`，按排序后的第 N 个 session 切换。
2. 增加一组稳定的 root 绑定：
   - `Option+p` 上一个 session
   - `Option+n` 下一个 session
3. 把 `F1..F9` 全补齐，作为另一组稳定直达入口。
4. 显式 `unbind` 旧的 `u/e/n/i` 时代遗留键位，保证 `source-file` 幂等。

## Verification

- `tmux source-file ~/.tmux.conf` 无报错
- `tmux list-keys` 中有：
  - `M-p switch-client -p`
  - `M-n switch-client -n`
  - `F1..F9` -> `switch_session_by_index.sh`
- `tmux list-keys` 不再残留旧的 root `M-e/M-u/M-i/M-y`
- 文档速查表更新为推荐 `prefix + s`、`Option+p/n`、`F1..F9`
