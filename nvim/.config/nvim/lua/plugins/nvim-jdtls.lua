return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    enabled = vim.env.NVIM_ENABLE_JAVA_LSP == "1",
    config = function() end,
  },
}
