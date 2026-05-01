local function assert_equal(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(
      (message or "values differ")
        .. "\nexpected: "
        .. vim.inspect(expected)
        .. "\nactual: "
        .. vim.inspect(actual)
    )
  end
end

vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/nvim/.config/nvim")

local java_runtime = require("utils.java_runtime")

local runtimes = java_runtime.parse_java_home_lines({
  '    21.0.2 (x86_64) "Oracle Corporation" - "OpenJDK 21.0.2" /Library/Java/JavaVirtualMachines/jdk-21.0.2.jdk/Contents/Home',
  '    17.0.2 (x86_64) "Oracle Corporation" - "Java SE 17.0.2" /Library/Java/JavaVirtualMachines/jdk-17.0.2.jdk/Contents/Home',
  '    1.8.441.07 (arm64) "Oracle Corporation" - "Java" /Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home',
  '    1.8.0_441 (arm64) "Oracle Corporation" - "Java SE 8" /Library/Java/JavaVirtualMachines/jdk-1.8.jdk/Contents/Home',
}, function(path)
  return path ~= "/missing"
end)

assert_equal(runtimes, {
  {
    default = false,
    major = 8,
    name = "JavaSE-1.8",
    path = "/Library/Java/JavaVirtualMachines/jdk-1.8.jdk/Contents/Home",
  },
  {
    default = false,
    major = 17,
    name = "JavaSE-17",
    path = "/Library/Java/JavaVirtualMachines/jdk-17.0.2.jdk/Contents/Home",
  },
  {
    default = true,
    major = 21,
    name = "JavaSE-21",
    path = "/Library/Java/JavaVirtualMachines/jdk-21.0.2.jdk/Contents/Home",
  },
}, "should parse and rank installed runtimes")

assert_equal(
  java_runtime.find_runtime_at_least(runtimes, 21),
  {
    default = true,
    major = 21,
    name = "JavaSE-21",
    path = "/Library/Java/JavaVirtualMachines/jdk-21.0.2.jdk/Contents/Home",
  },
  "should find exact matching runtime"
)

assert_equal(
  java_runtime.find_runtime_at_least(runtimes, 20),
  {
    default = true,
    major = 21,
    name = "JavaSE-21",
    path = "/Library/Java/JavaVirtualMachines/jdk-21.0.2.jdk/Contents/Home",
  },
  "should find the nearest newer runtime"
)

assert_equal(java_runtime.find_runtime_at_least(runtimes, 22), nil, "should return nil when no runtime satisfies the minimum")

assert_equal(java_runtime.get_default_runtime(runtimes), {
  default = true,
  major = 21,
  name = "JavaSE-21",
  path = "/Library/Java/JavaVirtualMachines/jdk-21.0.2.jdk/Contents/Home",
}, "should return the default runtime")

assert_equal(java_runtime.to_jdtls_runtimes(runtimes), {
  {
    default = false,
    name = "JavaSE-1.8",
    path = "/Library/Java/JavaVirtualMachines/jdk-1.8.jdk/Contents/Home",
  },
  {
    default = false,
    name = "JavaSE-17",
    path = "/Library/Java/JavaVirtualMachines/jdk-17.0.2.jdk/Contents/Home",
  },
  {
    default = true,
    name = "JavaSE-21",
    path = "/Library/Java/JavaVirtualMachines/jdk-21.0.2.jdk/Contents/Home",
  },
}, "should format runtimes for jdtls settings")

vim.cmd("qa!")
