# JDTLS Maven Source Path Design

## Context

`nvim-jdtls` 会在 `ServiceReady` 时主动调用 `java.project.getSettings` 获取 `org.eclipse.jdt.ls.core.sourcePaths`，然后设置 Java buffer 的 `'path'`。

在大型 Maven 项目里，这个请求经常早于项目导入完成，最终表现为：

- `Couldn't retrieve source path settings. Can't set 'path' (err=jarvis does not exist)`

之前的本地补救方案是继续重试这条命令，但这仍然建立在 JDTLS 导入时序之上。用户已经明确拒绝“靠重试等项目就绪”的方案。

## Goal

让 Java buffer 的 `'path'` 在标准 Maven 项目中完全由本地目录结构推导，不再依赖 JDTLS 何时完成导入。

具体要求：

- 不再增加任何重试逻辑
- 标准 Maven 多模块项目开箱可用
- 保留 `nvim-jdtls` 既有的 `'path'` 设置入口，避免大面积重写启动逻辑
- 非 Maven 项目仍然走上游默认行为

## Options Considered

### 1. 在 `on_attach` 里直接设置 `'path'`

优点：

- 实现简单
- 完全绕开 JDTLS source-path 请求

缺点：

- `nvim-jdtls` 上游仍然会在 `ServiceReady` 时触发一次 `java.project.getSettings`
- 那条 info/warn 依旧可能出现，等于没有真正解决噪音源头

### 2. 覆盖 `nvim-jdtls` 的 `language/status` handler

优点：

- 可以彻底接管 `ServiceReady` 行为

缺点：

- 需要复制更多上游逻辑
- 后续插件升级时更脆弱

### 3. 拦截 `java.project.getSettings` 的 sourcePaths 请求

优点：

- 只改一处窄接口
- 上游仍然负责在正确时机把 `'path'` 写回 buffer
- 本地可以直接返回标准 Maven 目录，不依赖 JDTLS 导入状态

缺点：

- 需要对 `jdtls.util.add_client_methods` 做一次本地包装

这是本次采用的方案。

## Chosen Design

新增一个本地工具模块，例如 `lua/utils/jdtls_source_path.lua`，负责两件事：

1. 根据 Maven 目录结构收集 source paths
2. 安装对 `jdtls.util.add_client_methods` 的窄范围包装

### Maven Source Path Discovery

对当前项目根目录执行本地扫描：

- 找出根目录下所有 `pom.xml`
- 忽略 `target/` 下的 `pom.xml`
- 对每个模块目录收集存在的标准路径

收集路径列表：

- `src/main/java`
- `src/main/resources`
- `src/test/java`
- `src/test/resources`
- `target/generated-sources/annotations`
- `target/generated-test-sources/test-annotations`

返回绝对路径列表，交给 `nvim-jdtls` 现有逻辑继续格式化为 `:h`/`gf` 可用的 `'path'`。

### JDTLS Request Interception

包装后的 `client:request(...)` 只拦截这一类请求：

- method: `workspace/executeCommand`
- command: `java.project.getSettings`
- setting: `org.eclipse.jdt.ls.core.sourcePaths`

命中时：

- 如果当前 root 是 Maven 项目，则直接回调本地推导出的 source paths
- 不再把请求转发给 JDTLS

未命中时：

- 继续调用原始 `client:request(...)`

这样 `nvim-jdtls` 的 `ServiceReady` 处理仍然生效，但数据来源改成了本地文件系统，而不是远端语言服务器状态。

## Error Handling

- 非 Maven root：直接回退到原始 JDTLS 行为
- Maven root 但未找到标准源码目录：返回空列表，不做额外重试或通知
- 重复安装包装：通过全局标记避免多次包裹

## Verification

分两层验证：

1. headless 测试
   - 多模块 Maven 树能推导出预期 source paths
   - sourcePaths 请求不会转发给原始 `client:request`
   - 非 sourcePaths 请求仍然透传
2. 真实项目验证
   - 在 `rs-jarvis` 中打开 Java 文件
   - 不再出现 `jarvis does not exist` 的 source-path 消息
   - `gf` / `'path'` 依赖的跳转行为仍可用
