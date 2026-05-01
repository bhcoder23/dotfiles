return {
  "lewis6991/gitsigns.nvim",
  version = "v0.6", -- 指定稳定版本
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local ok, gitsigns = pcall(require, "gitsigns")
    if ok then
      gitsigns.setup()
    end
  end,
}
