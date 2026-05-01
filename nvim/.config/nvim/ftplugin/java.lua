-- Opt-in only: Java projects are edited in IntelliJ by default.
if vim.env.NVIM_ENABLE_JAVA_LSP ~= "1" then
  return
end

local uv = vim.uv or vim.loop
local java_runtime = require("utils.java_runtime")
local jdtls_source_path = require("utils.jdtls_source_path")

local function path_exists(path)
  return type(path) == "string" and path ~= "" and uv.fs_stat(path) ~= nil
end

local function build_cmd_env(default_runtime_path)
  if not default_runtime_path then
    return nil
  end

  return {
    JAVA_HOME = default_runtime_path,
  }
end

local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local jdtls_config_dir = vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
local jdtls_workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
local lombok_jar = vim.fn.expand("$HOME/.local/share/nvim/mason/share/jdtls/lombok.jar")

local discovered_runtimes = java_runtime.discover_runtimes()
local preferred_runtimes = java_runtime.preferred_runtimes(discovered_runtimes, { 8, 17, 21 })
local runtimes = java_runtime.to_jdtls_runtimes(preferred_runtimes)
local default_runtime = java_runtime.get_default_runtime(preferred_runtimes)
local cmd_env = build_cmd_env(default_runtime and default_runtime.path or nil)
local maven_user_settings = vim.fn.expand("$HOME/.m2/settings.xml")
if not path_exists(maven_user_settings) then
  maven_user_settings = nil
end

local cmd = { vim.fn.exepath("jdtls") }
if path_exists(lombok_jar) then
  cmd[#cmd + 1] = string.format("--jvm-arg=-javaagent:%s", lombok_jar)
end
cmd[#cmd + 1] = "-configuration"
cmd[#cmd + 1] = jdtls_config_dir
cmd[#cmd + 1] = "-data"
cmd[#cmd + 1] = jdtls_workspace_dir

local bundles = {
  vim.fn.expand("$HOME/.local/share/nvim/mason/share/java-debug-adapter/com.microsoft.java.debug.plugin.jar"),
  (table.unpack or unpack)(vim.split(vim.fn.glob("$HOME/.local/share/nvim/mason/share/java-test/*.jar"), "\n", {})),
}

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_extend("force", capabilities, {
  offsetEncoding = { "utf-16" },
})

local java_settings = {
  eclipse = { downloadSources = true },
  configuration = {
    updateBuildConfiguration = "interactive",
    runtimes = runtimes,
  },
  import = {
    maven = {
      enabled = true,
      offline = { enabled = false },
    },
  },
  maven = { downloadSources = true },
  implementationsCodeLens = { enabled = true },
  referencesCodeLens = { enabled = true },
  inlayHints = { parameterNames = { enabled = "all" } },
  signatureHelp = { enabled = true },
  completion = {
    favoriteStaticMembers = {
      "org.hamcrest.MatcherAssert.assertThat",
      "org.hamcrest.Matchers.*",
      "org.hamcrest.CoreMatchers.*",
      "org.junit.jupiter.api.Assertions.*",
      "java.util.Objects.requireNonNull",
      "java.util.Objects.requireNonNullElse",
      "org.mockito.Mockito.*",
    },
  },
  sources = {
    organizeImports = {
      starThreshold = 9999,
      staticStarThreshold = 9999,
    },
  },
}

if maven_user_settings then
  java_settings.configuration.maven = {
    userSettings = maven_user_settings,
  }
end

local config = {
  name = "jdtls",
  cmd = cmd,
  root_dir = vim.fs.root(0, { "gradlew", ".git", "mvnw", "pom.xml" }),
  init_options = {
    bundles = bundles,
  },
  capabilities = capabilities,
  settings = {
    java = java_settings,
  },
}

if cmd_env then
  config.cmd_env = cmd_env
end

local jdtls = require("jdtls")

jdtls_source_path.install()

jdtls.start_or_attach(config, {
  dap = {
    hotcodereplace = "auto",
  },
})

local function map(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, {
    buffer = true,
    desc = desc,
    silent = true,
  })
end

map("<leader>tr", function()
  jdtls.test_nearest_method()
end, "Run Nearest Java Test")

map("<leader>tf", function()
  jdtls.test_class()
end, "Run Java Test Class")

map("<leader>tl", function()
  require("dap").run_last()
end, "Run Last Java Test")
