local uv = vim.uv or vim.loop

local M = {}

local function path_exists(path)
  return type(path) == "string" and path ~= "" and uv.fs_stat(path) ~= nil
end

local function parse_java_major(version)
  local legacy_major = version:match("^1%.(%d+)")
  if legacy_major then
    return tonumber(legacy_major)
  end
  return tonumber(version:match("^(%d+)"))
end

local function java_runtime_name(major)
  if major == 8 then
    return "JavaSE-1.8"
  end
  return ("JavaSE-%d"):format(major)
end

local function runtime_path_score(path)
  local score = 0
  if path:find("/Library/Java/JavaVirtualMachines/", 1, true) then
    score = score + 2
  end
  if path:find("/Internet Plug-Ins/", 1, true) then
    score = score - 4
  end
  return score
end

local function clone_runtime(runtime)
  if not runtime then
    return nil
  end
  return {
    default = runtime.default == true,
    major = runtime.major,
    name = runtime.name,
    path = runtime.path,
  }
end

local function with_default_runtime(runtimes)
  local default_major = nil
  for _, runtime in ipairs(runtimes) do
    if not default_major or runtime.major > default_major then
      default_major = runtime.major
    end
  end

  local result = {}
  for _, runtime in ipairs(runtimes) do
    result[#result + 1] = {
      default = runtime.major == default_major,
      major = runtime.major,
      name = runtime.name,
      path = runtime.path,
    }
  end

  return result
end

function M.parse_java_home_lines(lines, exists_fn)
  exists_fn = exists_fn or path_exists

  local by_major = {}
  for _, line in ipairs(lines or {}) do
    local version, path = line:match("^%s*([%d%._]+)%s+%b()%s+.-%s+(/.+)$")
    local major = version and parse_java_major(version)
    if major and exists_fn(path) then
      local current = by_major[major]
      if not current or runtime_path_score(path) > runtime_path_score(current.path) then
        by_major[major] = {
          major = major,
          name = java_runtime_name(major),
          path = path,
        }
      end
    end
  end

  local majors = vim.tbl_keys(by_major)
  table.sort(majors)

  local runtimes = {}
  for _, major in ipairs(majors) do
    runtimes[#runtimes + 1] = by_major[major]
  end

  return with_default_runtime(runtimes)
end

function M.discover_runtimes()
  local lines = vim.fn.systemlist({ "/usr/libexec/java_home", "-V" })
  if vim.v.shell_error ~= 0 then
    return {}
  end
  return M.parse_java_home_lines(lines)
end

function M.preferred_runtimes(runtimes, preferred_majors)
  if type(runtimes) ~= "table" or vim.tbl_isempty(runtimes) then
    return {}
  end

  local by_major = {}
  for _, runtime in ipairs(runtimes) do
    by_major[runtime.major] = runtime
  end

  local preferred = {}
  for _, major in ipairs(preferred_majors or {}) do
    local runtime = by_major[major]
    if runtime then
      preferred[#preferred + 1] = {
        major = runtime.major,
        name = runtime.name,
        path = runtime.path,
      }
    end
  end

  if vim.tbl_isempty(preferred) then
    local all = {}
    for _, runtime in ipairs(runtimes) do
      all[#all + 1] = {
        major = runtime.major,
        name = runtime.name,
        path = runtime.path,
      }
    end
    return with_default_runtime(all)
  end

  return with_default_runtime(preferred)
end

function M.get_default_runtime(runtimes)
  for _, runtime in ipairs(runtimes or {}) do
    if runtime.default then
      return clone_runtime(runtime)
    end
  end
  return nil
end

function M.find_runtime_at_least(runtimes, min_major)
  local selected = nil
  for _, runtime in ipairs(runtimes or {}) do
    if runtime.major >= min_major and (not selected or runtime.major < selected.major) then
      selected = runtime
    end
  end
  return clone_runtime(selected)
end

function M.to_jdtls_runtimes(runtimes)
  local result = {}
  for _, runtime in ipairs(runtimes or {}) do
    result[#result + 1] = {
      default = runtime.default == true,
      name = runtime.name,
      path = runtime.path,
    }
  end
  return result
end

function M.java_bin(runtime)
  if not runtime or not runtime.path then
    return nil
  end
  return runtime.path .. "/bin/java"
end

return M
