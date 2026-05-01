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

local function has_key(specs, lhs)
  for _, item in ipairs(specs or {}) do
    if item[1] == lhs then
      return true
    end
  end
  return false
end

vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/nvim/.config/nvim")

local snacks_picker = require("plugins.snacks.picker")
assert_truthy(has_key(snacks_picker.keys, "<leader>sw"), "expected <leader>sw to exist")
assert_falsy(has_key(snacks_picker.keys, "<leader>sW"), "expected <leader>sW to be removed")
assert_falsy(has_key(snacks_picker.keys, "<leader>sg"), "expected <leader>sg to be removed")
assert_falsy(has_key(snacks_picker.keys, "<leader>sG"), "expected <leader>sG to be removed")

local grug_far = require("plugins.grug-far")
assert_truthy(grug_far.keys and grug_far.keys[1] and grug_far.keys[1][1] == "<leader>sr", "expected <leader>sr to exist")

local captured_maps = {}
local original_keymap_set = vim.keymap.set
vim.keymap.set = function(mode, lhs, rhs, opts)
  captured_maps[#captured_maps + 1] = {
    mode = mode,
    lhs = lhs,
    desc = opts and opts.desc or nil,
  }
end

package.preload["jdtls"] = function()
  return {
    start_or_attach = function() end,
    test_nearest_method = function() end,
    test_class = function() end,
  }
end

package.preload["dap"] = function()
  return {
    run_last = function() end,
  }
end

vim.api.nvim_buf_set_name(0, "/tmp/Test.java")
dofile("nvim/.config/nvim/ftplugin/java.lua")
vim.keymap.set = original_keymap_set

local function captured(lhs)
  for _, map in ipairs(captured_maps) do
    if map.lhs == lhs then
      return true
    end
  end
  return false
end

assert_truthy(captured("<leader>tr"), "expected <leader>tr to exist")
assert_truthy(captured("<leader>tf"), "expected <leader>tf to exist")
assert_truthy(captured("<leader>tl"), "expected <leader>tl to exist")
assert_falsy(captured("<leader>sb"), "expected <leader>sb to be removed")
assert_falsy(captured("<leader>se"), "expected <leader>se to be removed")

vim.cmd("qa!")
