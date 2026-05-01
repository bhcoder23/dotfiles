local function write_file(path, content)
  local file = assert(io.open(path, "w"))
  file:write(content or "")
  file:close()
end

local function mkdir(path)
  vim.fn.mkdir(path, "p")
end

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

local root = vim.fn.tempname()
mkdir(root)
mkdir(root .. "/module-a")
mkdir(root .. "/module-b")
mkdir(root .. "/target/generated-test-sources/ignored")

write_file(root .. "/pom.xml", "<project/>")
write_file(root .. "/module-a/pom.xml", "<project/>")
write_file(root .. "/module-b/pom.xml", "<project/>")
write_file(root .. "/target/generated-test-sources/ignored/pom.xml", "<project/>")

mkdir(root .. "/module-a/src/main/java/com/example")
mkdir(root .. "/module-a/src/test/java/com/example")
mkdir(root .. "/module-a/target/generated-sources/annotations/com/example")
mkdir(root .. "/module-b/src/main/java/com/example")
mkdir(root .. "/module-b/src/main/resources")

local helper = require("utils.jdtls_source_path")

local expected_paths = {
  root .. "/module-a/src/main/java",
  root .. "/module-a/src/test/java",
  root .. "/module-a/target/generated-sources/annotations",
  root .. "/module-b/src/main/java",
  root .. "/module-b/src/main/resources",
}

assert_equal(helper.collect_maven_source_paths(root), expected_paths, "should collect standard Maven source paths")

local forwarded = 0
local util = {
  add_client_methods = function(client)
    return client
  end,
}

helper.install({
  jdtls_util = util,
  root_resolver = function()
    return root
  end,
})

local wrapped = util.add_client_methods({
  request = function(_, method, params, handler)
    forwarded = forwarded + 1
    if handler then
      handler(nil, { passthrough = { method = method, params = params } })
    end
  end,
})

local source_settings
wrapped:request("workspace/executeCommand", {
  command = "java.project.getSettings",
  arguments = {
    "file://" .. root .. "/module-a/src/main/java/com/example/App.java",
    {
      helper.SOURCE_PATH_SETTING,
    },
  },
}, function(err, settings)
  assert(err == nil, "source path interception should not error")
  source_settings = settings
end, 0)

assert_equal(forwarded, 0, "source path request should not be forwarded to JDTLS")
assert_equal(
  source_settings[helper.SOURCE_PATH_SETTING],
  expected_paths,
  "source path request should use local Maven discovery"
)

wrapped:request("workspace/executeCommand", {
  command = "java.project.getSettings",
  arguments = {
    "file://" .. root .. "/module-a/src/main/java/com/example/App.java",
    {
      "org.eclipse.jdt.ls.core.vm.location",
    },
  },
}, function(err, response)
  assert(err == nil, "unrelated request should passthrough")
  assert(response.passthrough ~= nil, "passthrough response should come from original client")
end, 0)

assert_equal(forwarded, 1, "unrelated request should still be forwarded")

vim.cmd("qa!")
