local uv = vim.uv or vim.loop

local M = {}

M.SOURCE_PATH_SETTING = "org.eclipse.jdt.ls.core.sourcePaths"

local ROOT_MARKERS = { "gradlew", ".git", "mvnw", "pom.xml" }
local STANDARD_MAVEN_DIRS = {
  "src/main/java",
  "src/main/resources",
  "src/test/java",
  "src/test/resources",
  "target/generated-sources/annotations",
  "target/generated-test-sources/test-annotations",
}

local function joinpath(...)
  if vim.fs.joinpath then
    return vim.fs.joinpath(...)
  end
  return table.concat({ ... }, "/")
end

local function path_exists(path)
  return type(path) == "string" and path ~= "" and uv.fs_stat(path) ~= nil
end

local function is_maven_root(root)
  return path_exists(root) and path_exists(joinpath(root, "pom.xml"))
end

local function is_source_path_request(method, params)
  if method ~= "workspace/executeCommand" or type(params) ~= "table" then
    return false
  end

  local settings = params.arguments and params.arguments[2]
  return params.command == "java.project.getSettings"
    and type(settings) == "table"
    and settings[1] == M.SOURCE_PATH_SETTING
end

local function default_root_resolver(bufnr)
  if type(bufnr) == "number" and vim.api.nvim_buf_is_valid(bufnr) then
    return vim.fs.root(bufnr, ROOT_MARKERS)
  end
end

function M.collect_maven_source_paths(root)
  if not is_maven_root(root) then
    return {}
  end

  local paths = {}
  local seen = {}
  local pom_files = vim.fs.find("pom.xml", {
    path = root,
    type = "file",
    limit = math.huge,
  })

  table.sort(pom_files)

  for _, pom_file in ipairs(pom_files) do
    if not pom_file:find("/target/", 1, true) then
      local module_dir = vim.fs.dirname(pom_file)
      for _, dir in ipairs(STANDARD_MAVEN_DIRS) do
        local absolute_dir = joinpath(module_dir, dir)
        if path_exists(absolute_dir) and not seen[absolute_dir] then
          seen[absolute_dir] = true
          paths[#paths + 1] = absolute_dir
        end
      end
    end
  end

  table.sort(paths)

  return paths
end

function M.install(opts)
  opts = opts or {}

  local jdtls_util = opts.jdtls_util
  if not jdtls_util then
    local ok
    ok, jdtls_util = pcall(require, "jdtls.util")
    if not ok then
      return false
    end
  end

  if jdtls_util._dotfiles_maven_source_path_installed then
    return true
  end

  local root_resolver = opts.root_resolver or default_root_resolver
  local original_add_client_methods = jdtls_util.add_client_methods
  local wrapped_clients = {}

  jdtls_util.add_client_methods = function(client)
    local base_client = original_add_client_methods(client)
    local client_key = base_client.id or client.id or tostring(base_client)

    if wrapped_clients[client_key] then
      return wrapped_clients[client_key]
    end

    local wrapped_client = setmetatable({
      request = function(_, method, params, handler, bufnr)
        if is_source_path_request(method, params) then
          local root = root_resolver(bufnr)
          if is_maven_root(root) then
            if handler then
              handler(nil, {
                [M.SOURCE_PATH_SETTING] = M.collect_maven_source_paths(root),
              })
            end
            return true
          end
        end

        return base_client.request(base_client, method, params, handler, bufnr)
      end,
      notify = function(_, ...)
        return base_client.notify(base_client, ...)
      end,
      stop = function(_, ...)
        return base_client.stop(base_client, ...)
      end,
    }, { __index = base_client })

    wrapped_clients[client_key] = wrapped_client

    return wrapped_client
  end

  jdtls_util._dotfiles_maven_source_path_installed = true

  return true
end

return M
