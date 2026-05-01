local lspUtil = require("utils.lsp")
local ui = require("core.ui")

return {
  "neovim/nvim-lspconfig",
  event = {
    "BufReadPre",
    "BufNewFile",
  },
  dependencies = {
    "mason-org/mason.nvim",
  },
  config = function()
    local preferred_golangci_bin = vim.fs.normalize(vim.env.HOME .. "/go/bin")
    local preferred_golangci = preferred_golangci_bin .. "/golangci-lint"
    local golangci_cmd = "golangci-lint"
    local golangci_path = vim.env.PATH

    if vim.fn.executable(preferred_golangci) == 1 then
      golangci_cmd = preferred_golangci
      golangci_path = preferred_golangci_bin .. ":" .. vim.env.PATH
    end

    vim.diagnostic.config({
      underline = true,
      update_in_insert = false,
      virtual_text = false,
      virtual_lines = false,
      float = {
        border = vim.g.bordered and "rounded" or "none",
        spacing = 4,
        source = "if_many",
        prefix = "● ",
      },
      severity_sort = true,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = ui.icons.diagnostics.Error,
          [vim.diagnostic.severity.WARN] = ui.icons.diagnostics.Warn,
          [vim.diagnostic.severity.HINT] = ui.icons.diagnostics.Hint,
          [vim.diagnostic.severity.INFO] = ui.icons.diagnostics.Info,
        },
        texthl = {
          [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
          [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
          [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
          [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
          [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
          [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
          [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
        },
      },
    })

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    vim.tbl_deep_extend("force", capabilities, {
      workspace = {
        fileOperations = {
          didRename = true,
          willRename = true,
        },
      },
      textDocument = {
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
      },
    })
    capabilities =
      vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities(capabilities, true))

    vim.lsp.config("*", {
      capabilities = capabilities,
      servers = {
        pyright = {
          before_init = function(_, config)
            -- 自动识别 .venv 虚拟环境
            local venv_path = vim.fn.getcwd() .. "/.venv/bin/python"
            if vim.fn.filereadable(venv_path) then
              config.settings = config.settings or {}
              config.settings.python = config.settings.python or {}
              config.settings.python.pythonPath = venv_path
            end
          end,
          settings = {
            python = {
              analysis = {
                autoImportCompletions = true, -- 开启自动导入
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
              },
            },
          },
        },
      },
    })

    vim.lsp.config("golangci_lint_ls", {
      cmd_env = {
        PATH = golangci_path,
      },
      init_options = {
        command = {
          golangci_cmd,
          "run",
          "--output.text.path=",
          "--output.tab.path=",
          "--output.html.path=",
          "--output.checkstyle.path=",
          "--output.junit-xml.path=",
          "--output.teamcity.path=",
          "--output.sarif.path=",
          "--show-stats=false",
          "--output.json.path=stdout",
        },
      },
    })

    vim.lsp.enable({
      "lua_ls",
      -- "emmylua_ls",
      "copilot",
      "bashls",

      "dockerls",
      "docker_compose_language_service",

      "html",
      "cssls",
      "biome",
      "eslint",
      "vtsls",
      "vuels",

      "gopls",
      "golangci_lint_ls",

      "jsonls",

      "marksman",

      "pyright",
      "ruff",

      "yamlls",

      "taplo",

      "zls",
    })

    local Methods = vim.lsp.protocol.Methods
    -- Sometimes, LSP servers do not register all capabilities at once and might
    -- dynamically come up with things like "oh, we support so and so", so we need to
    -- recall attach so that we have the correct keymaps set up accordingly
    local register_capability = vim.lsp.handlers[Methods.client_registerCapability]
    vim.lsp.handlers[Methods.client_registerCapability] = function(err, res, ctx)
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      if not client then
        return
      end

      lspUtil.on_attach(client, vim.api.nvim_get_current_buf())
      return register_capability(err, res, ctx)
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      desc = "Configure LSP keymaps",
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        assert(client ~= nil, "Client is not available for buffer")

        lspUtil.on_attach(client, args.buf)
      end,
    })
  end,
}
