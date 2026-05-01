local function assert_truthy(value, message)
  if not value then
    error(message or "expected truthy value")
  end
end

local function assert_falsy(value, message)
  if value then
    error(message or "expected falsy value")
  end
end

local function contains(sequence, target)
  for _, value in ipairs(sequence or {}) do
    if value == target then
      return true
    end
  end
  return false
end

local function path_exists(path)
  local uv = vim.uv or vim.loop
  return uv.fs_stat(path) ~= nil
end

vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/nvim/.config/nvim")

local jdtls_plugin = require("plugins.nvim-jdtls")[1]
assert_falsy(
  contains(jdtls_plugin.dependencies or {}, "spring-boot.nvim"),
  "expected nvim-jdtls plugin to not depend on spring-boot.nvim"
)

local mason = require("plugins.mason")
local ensure_installed = mason.opts.ensure_installed or {}
assert_truthy(contains(ensure_installed, "jdtls"), "expected jdtls to stay installed")
assert_truthy(contains(ensure_installed, "java-debug-adapter"), "expected java-debug-adapter to stay installed")
assert_truthy(contains(ensure_installed, "java-test"), "expected java-test to stay installed")
assert_falsy(contains(ensure_installed, "vscode-spring-boot-tools"), "expected Spring Boot tools to be removed")

assert_falsy(pcall(require, "plugins.spring-boot"), "expected spring-boot plugin module to be removed")
assert_falsy(
  path_exists(vim.fn.getcwd() .. "/nvim/.config/nvim/ftplugin/xml.lua"),
  "expected pom.xml-specific xml ftplugin to be removed"
)
assert_falsy(
  path_exists(vim.fn.getcwd() .. "/nvim/.config/nvim/lua/utils/spring_boot_runner.lua"),
  "expected spring boot runner helper to be removed"
)
assert_falsy(
  path_exists(vim.fn.getcwd() .. "/nvim/.config/nvim/lua/utils/maven.lua"),
  "expected Maven helper to be removed"
)

vim.cmd("qa!")
