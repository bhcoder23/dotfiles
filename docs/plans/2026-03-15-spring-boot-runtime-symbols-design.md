# Spring Boot Runtime And Symbol Search Design

## Context

当前 `spring-boot.nvim` 已经接入了 `jdtls` 扩展包，并在 Java buffer 中提供：

- `<leader>sb` 查找 Spring Beans
- `<leader>se` 查找 Spring Endpoints

但在真实项目 `rs-jarvis` 中，这两个快捷键打开后是空的。排查后发现这不是单点问题，而是三段链路同时有问题：

1. `spring-boot` language server 使用的是 Neovim 进程的全局 `JAVA_HOME`
2. 当前机器里这个全局 Java 是 JDK 17
3. Mason 安装的 Spring Boot LS jar 需要 Java 21 才能启动

日志中已经确认根因：

- `UnsupportedClassVersionError`
- class file version `65.0`
- JDK 17 只支持到 `61.0`

除此之外，还发现两个次级问题：

- 插件按 `ft = java` 懒加载时，`setup()` 里注册的 `FileType` autocmd 会错过当前第一个 Java buffer
- 我们自定义的默认查询 `@+` / `@/` 在真实项目中不会命中任何 workspace symbols

## Goal

让 Spring 相关快捷键在不同 JDK 版本的 Java 项目里都能稳定可用，同时不把项目运行时硬编码成 JDK 21。

具体要求：

- Boot LS 使用独立的、自动发现的 `21+` JVM
- `jdtls` 仍按项目自己的 Java 运行时工作
- 第一个 Java buffer 就能启动 Boot LS
- `<leader>sb` / `<leader>se` 默认查询打开后就有结果

## Options Considered

### 1. 把 Spring Boot LS 直接写死成 JDK 21

优点：

- 实现最简单

缺点：

- 机器上 JDK 21 路径变化就失效
- 与现有“自动发现 Java 运行时”的风格不一致
- 不能复用到其他机器

### 2. 让 Spring Boot LS 跟随项目 JDK

优点：

- 看起来最“统一”

缺点：

- 项目可能是 JDK 17、11、8
- 但 Boot LS 本身需要 Java 21 才能启动
- 这会把 Boot LS 的可用性绑定到项目 JDK，根本不成立

### 3. 给 Boot LS 单独自动选择本机可用的 `21+` JVM

优点：

- 不干扰项目/JDTLS 的 Java 版本
- 适配多项目、多 JDK 机器
- 只要本机存在 21+，Boot LS 就能稳定起来

缺点：

- 需要把 Java 运行时发现逻辑抽到共享 helper

这是本次采用的方案。

## Chosen Design

新增一个共享模块，例如 `lua/utils/java_runtime.lua`，负责：

- 发现本机已安装的 Java 运行时
- 保留现有 JDTLS 所需的 runtime 列表格式
- 额外提供“查找 `>= N` 的最小可用 runtime”能力

### Runtime Selection

规则如下：

- JDTLS：继续使用当前逻辑里的默认 runtime
- Spring Boot LS：单独选择 `>= 21` 的最小可用 runtime

这样：

- 如果本机有 JDK 21，就用 21
- 如果没有 21 但有 22/23，就用最接近的更高版本
- 如果没有 21+，则保留现状并发出更明确的提示

## Spring Boot Startup

当前 `spring-boot.nvim` 的 `setup()` 通过 `FileType` autocmd 启动 LS，但插件本身是按 `ft` 懒加载的，导致首个 Java buffer 会错过这次 autocmd。

修复方式：

- 在插件 `config` 中执行 `setup(opts)`
- 紧接着对当前 buffer 手动调用一次 `spring_boot.launch.start(...)`

这样：

- 之后的 buffer 继续走插件自己的 autocmd
- 当前已经打开的 Java buffer 也能立即拥有 Boot LS

## Symbol Search Defaults

现有默认查询：

- Beans: `@+`
- Endpoints: `@/`

在真实项目里都没有结果，不应继续保留。

替换为真实能命中的默认查询：

- Beans: `Component`
- Endpoints: `Mapping`

理由：

- `Component` 在真实项目中既能覆盖 `@Component`，也能覆盖一部分 Spring stereotype 相关结果
- `Mapping` 能覆盖 `@RequestMapping`、`@GetMapping`、`@PostMapping` 等 endpoint 相关符号

仍然保留 `fzf-lua` 的 live workspace symbol 交互，用户可以继续在结果基础上细化搜索。

## Verification

验证分三层：

1. 纯 Lua / headless 测试
   - 运行时选择 helper 能正确选出 `21+` JVM
2. Headless Neovim 配置验证
   - 打开第一个 Java buffer 后能看到 `spring-boot` client
3. 真实项目验证
   - `rs-jarvis` 中 `<leader>sb` / `<leader>se` 打开后不再为空
   - `messages` / `lsp.log` 中不再出现 Boot LS 的 `UnsupportedClassVersionError`
