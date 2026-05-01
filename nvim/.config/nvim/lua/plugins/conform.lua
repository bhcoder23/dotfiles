local supported = {
  "graphql",
  "handlebars",
  "markdown",
  "markdown.mdx",
  "yaml",
  "yaml.docker-compose",
  "less",
  "scss",
  "css",
  "html",
}

local fe_supported = {
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "typescript",
  "typescriptreact",
  "vue",
}

return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format()
        end,
        mode = { "n", "x", "v" },
        desc = "Format",
      },
      {
        "<leader>cF",
        function()
          require("conform").format({
            formatters = { "injected" },
          })
        end,
        desc = "Conform format injected langs",
        mode = { "n", "v", "x" },
      },
    },
    opts = {
      format_on_save = function(bufnr)
        if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then
          return
        end
        return {
          lsp_format = "fallback",
          timeout_ms = vim.bo[bufnr].filetype == "go" and 2000 or 500,
        }
      end,
      formatters_by_ft = {
        query = { "format-queries" },
        sql = { "sqlfluff" },
        sh = { "shfmt" },
        go = { "tagalign", "goimports", "gofmt" }, -- golines
        lua = { "stylua" },
        nix = { "nixfmt" },
        rust = { "rustfmt" },
        templ = { "templ" },
        toml = { "taplo" },
        python = { "ruff_format" },
      },
      default_format_opts = {
        timeout_ms = 3000,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
    config = function(_, opts)
      local util = require("conform.util")
      local tagalign_config = vim.fn.stdpath("config") .. "/golangci-tagalign.yml"

      local function has_config(ctx, files)
        return not vim.tbl_isempty(vim.fs.find(files, { path = ctx.dirname, upward = true }))
      end

      opts.formatters = opts.formatters or {}
      opts.formatters.tagalign = {
        command = "golangci-lint",
        args = function()
          return {
            "run",
            "--fix",
            "--enable-only",
            "tagalign",
            "--config",
            tagalign_config,
            "$FILENAME",
          }
        end,
        stdin = false,
        tmpfile_format = "conform.$RANDOM.$FILENAME",
        cwd = util.root_file({
          "go.work",
          "go.mod",
          ".golangci.yml",
          ".golangci.yaml",
          ".golangci.toml",
          ".golangci.json",
        }),
        require_cwd = true,
      }
      opts.formatters.prettier = {
        condition = function(_, ctx)
          return has_config(ctx, {
            ".prettierrc",
            ".prettierrc.json",
            ".prettierrc.yml",
            ".prettierrc.yaml",
            ".prettierrc.js",
            ".prettierrc.cjs",
            ".prettierrc.mjs",
            ".prettierrc.toml",
            "prettier.config.js",
            "prettier.config.cjs",
            "prettier.config.mjs",
          })
        end,
      }
      opts.formatters.biome = {
        condition = function(_, ctx)
          return has_config(ctx, { "biome.json", "biome.jsonc" })
        end,
      }
      opts.formatters.sqlfluff = {
        require_cwd = false,
        args = function(_, ctx)
          if has_config(ctx, { ".sqlfluff", "pep8.ini", "pyproject.toml", "setup.cfg", "tox.ini" }) then
            return { "fix", "-" }
          end
          return { "fix", "--dialect", "ansi", "-" }
        end,
      }

      for _, ft in ipairs(supported) do
        opts.formatters_by_ft[ft] = { "prettier" }
      end

      for _, ft in ipairs(fe_supported) do
        opts.formatters_by_ft[ft] = { "biome", "prettier", stop_after_first = true }
      end

      require("conform").setup(opts)
    end,
  },
}
