return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim",                   opts = {} },
	},
	config = function()
		local lspconfig = require("lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local lsp_nav = require("salar.core.lsp_nav")
		local keymap = vim.keymap
		local qt_clangd_flag_pattern = "^Unknown argument:%s*['\"]?%-mno%-direct%-extern%-access['\"]?"
		local go_filetypes = {
			go = true,
			gomod = true,
			gowork = true,
			gotmpl = true,
		}

		local function is_go_filetype(filetype)
			return go_filetypes[filetype] == true
		end

		local function set_buffer_from_formatter(bufnr, output)
			local lines = vim.split(output, "\n", { plain = true })
			if lines[#lines] == "" then
				table.remove(lines, #lines)
			end

			local view
			if vim.api.nvim_get_current_buf() == bufnr then
				view = vim.fn.winsaveview()
			end

			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

			if view and vim.api.nvim_get_current_buf() == bufnr then
				vim.fn.winrestview(view)
			end
		end

		local function goimports_buffer(bufnr)
			if vim.fn.executable("goimports") == 0 then
				return false
			end

			local path = vim.api.nvim_buf_get_name(bufnr)
			if path == "" then
				return false
			end

			local input = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
			if vim.bo[bufnr].endofline then
				input = input .. "\n"
			end

			local output = vim.fn.system({ "goimports", "-srcdir", path }, input)
			if vim.v.shell_error ~= 0 then
				vim.notify(output, vim.log.levels.WARN, { title = "goimports" })
				return false
			end

			set_buffer_from_formatter(bufnr, output)
			return true
		end

		local function format_go_buffer(bufnr)
			if goimports_buffer(bufnr) then
				return
			end

			local ok, conform = pcall(require, "conform")
			if ok then
				conform.format({
					bufnr = bufnr,
					async = false,
					lsp_format = "fallback",
					timeout_ms = 3000,
				})
			else
				vim.lsp.buf.format({
					bufnr = bufnr,
					async = false,
					filter = function(client)
						return client.name == "gopls"
					end,
				})
			end
		end

		local default_publish_diagnostics = vim.lsp.handlers["textDocument/publishDiagnostics"]
		vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
			local client = ctx and vim.lsp.get_client_by_id(ctx.client_id)
			if client and client.name == "clangd" and result and result.diagnostics then
				result = vim.deepcopy(result)
				result.diagnostics = vim.tbl_filter(function(diagnostic)
					local message = diagnostic.message or ""
					return not message:match(qt_clangd_flag_pattern)
				end, result.diagnostics)
			end

			return default_publish_diagnostics(err, result, ctx, config)
		end

		local ignored_gopls_log_patterns = {
			"no completions found:.*context canceled",
			"no completions found:.*no package metadata",
			"getting file .- for InlayHint: no package metadata",
		}

		local default_log_message = vim.lsp.handlers["window/logMessage"]
		vim.lsp.handlers["window/logMessage"] = function(err, result, ctx, config)
			local client = ctx and vim.lsp.get_client_by_id(ctx.client_id)
			local message = result and result.message or ""

			if client and client.name == "gopls" then
				for _, pattern in ipairs(ignored_gopls_log_patterns) do
					if message:match(pattern) then
						return
					end
				end
			end

			return default_log_message(err, result, ctx, config)
		end


		-- setup keymaps when LSP attaches
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }

				local client = vim.lsp.get_client_by_id(ev.data.client_id)
				if client and client.server_capabilities.semanticTokensProvider then
					client.server_capabilities.semanticTokensProvider = nil
				end

				opts.desc = "Show LSP references"
				keymap.set("n", "gR", lsp_nav.references, opts)

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Go to definition"
				keymap.set("n", "gd", vim.lsp.buf.definition, opts)

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", lsp_nav.implementation, opts)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", lsp_nav.type_definition, opts)

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

				opts.desc = "Show documentation under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)

				opts.desc = "Organize imports"
				keymap.set("n", "<leader>oi", function()
					if is_go_filetype(vim.bo[ev.buf].filetype) then
						format_go_buffer(ev.buf)
						return
					end

					vim.lsp.buf.code_action({
						context = { only = { "source.organizeImports" } },
						apply = true,
					})
				end, opts)

				opts.desc = "Toggle inlay hints"
				keymap.set("n", "<leader>uh", function()
					local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
					vim.lsp.inlay_hint.enable(not enabled, { bufnr = ev.buf })
				end, opts)

				-- Enable inlay hints if supported
				local client = vim.lsp.get_client_by_id(ev.data.client_id)
				local ft = vim.bo[ev.buf].filetype
				local path = vim.api.nvim_buf_get_name(ev.buf)
				-- Keep Go hints manual; gopls is noisy while new files lack package metadata.
				local disable_inlay_hints =
					vim.tbl_contains({ "c", "cpp", "objc", "objcpp" }, ft)
					or is_go_filetype(ft)
					or path:match("%.h$")
					or path:match("%.hh$")
					or path:match("%.hpp$")
					or path:match("%.hxx$")
					or path:match("%.inl$")

				if client and client.server_capabilities.inlayHintProvider and not disable_inlay_hints then
					vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
				end
			end,
		})

		-- LSP completion capabilities
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- inline diagnostics (virtual text)
		vim.diagnostic.config({
			virtual_text = {
				prefix = "●",
				spacing = 2,
			},
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰠠 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},
			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})

		-- ============================
		-- Language servers
		-- ============================

		-- TypeScript / TSX
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- ============================
		-- TypeScript / TSX (NEW API)
		-- ============================
		vim.lsp.config("ts_ls", {
			capabilities = capabilities,
			filetypes = {
				"typescript",
				"typescriptreact",
				"javascript",
				"javascriptreact",
			},
		})

		vim.lsp.enable("ts_ls")

		-- ============================
		-- Clang
		-- ============================
		vim.lsp.config("clangd", {
			capabilities = capabilities,
			cmd = {
				"/usr/bin/clangd",
				"--background-index",
				"--clang-tidy",
				"--query-driver=/usr/bin/c++,/usr/bin/g++",
			},
			init_options = {
				fallbackFlags = {
					"-std=c++20",
				},
			},
		})
		vim.lsp.enable("clangd")

		-- ============================
		-- Go
		-- ============================
		vim.lsp.config("gopls", {
			capabilities = capabilities,
			cmd = { "gopls" },
			filetypes = { "go", "gomod", "gowork", "gotmpl" },
			root_markers = { "go.work", "go.mod", ".git" },
			settings = {
				gopls = {
					completeUnimported = true,
					usePlaceholders = true,
					gofumpt = true,
					staticcheck = true,
					analyses = {
						unusedparams = true,
						unusedwrite = true,
					},
					hints = {
						assignVariableTypes = true,
						compositeLiteralFields = true,
						compositeLiteralTypes = true,
						constantValues = true,
						functionTypeParameters = true,
						parameterNames = true,
						rangeVariableTypes = true,
					},
				},
			},
		})
		vim.lsp.enable("gopls")

		-- ============================
		-- Lua
		-- ============================
		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						checkThirdParty = false,
						library = vim.api.nvim_get_runtime_file("", true),
					},
					completion = {
						callSnippet = "Replace",
					},
				},
			},
		})
			vim.lsp.enable("lua_ls")

			-- auto-format on save
			vim.api.nvim_create_autocmd("BufWritePre", {
				callback = function(ev)
					local ft = vim.bo[ev.buf].filetype
					local cpp_like = vim.tbl_contains({ "c", "cpp", "objc", "objcpp" }, ft)
					local go_like = is_go_filetype(ft)

					-- Typst uses typstyle (not LSP)
					if ft == "typst" then
						require("conform").format({ bufnr = ev.buf })
						return
					end

					if go_like then
						format_go_buffer(ev.buf)
						return
					end

					if not cpp_like then
						return
					end

					require("conform").format({
						bufnr = ev.buf,
						async = false,
						lsp_format = "never",
						timeout_ms = 3000,
					})
				end,
			})
		-- ============================
		-- Rust
		-- ============================
		vim.lsp.config("rust_analyzer", {
			capabilities = capabilities,
			settings = {
				["rust-analyzer"] = {
					inlayHints = {
						typeHints = { enable = true },

						parameterHints = { enable = false },
						chainingHints = { enable = false },
						bindingModeHints = { enable = false },
						closureReturnTypeHints = { enable = "never" },
						lifetimeElisionHints = { enable = "never" },
						reborrowHints = { enable = false },
						closingBraceHints = { enable = false },
					},
				},
			},
		})

		vim.lsp.enable("rust_analyzer")

		-- ============================
		-- Typst
		-- ============================
		vim.lsp.config("tinymist", {
			cmd = { "tinymist" },
			filetypes = { "typst" },
			root_markers = { ".git" },
			capabilities = capabilities,
		})

		vim.lsp.enable("tinymist")

		-- ============================
		-- Haskell
		-- ============================
		if vim.fn.executable("haskell-language-server-wrapper") == 1 then
			vim.lsp.config("hls", {
				capabilities = capabilities,
				cmd = { "haskell-language-server-wrapper", "--lsp" },
				filetypes = { "haskell", "lhaskell", "cabal" },
				root_markers = { "hie.yaml", "stack.yaml", "cabal.project", "package.yaml", "*.cabal", ".git" },
			})

			vim.lsp.enable("hls")
		end

		-- ============================
		-- Godot / GDScript
		-- ============================
		vim.lsp.config("gdscript", {
			capabilities = capabilities,
		})

		vim.lsp.enable("gdscript")

		if vim.fn.executable("gdshader-lsp") == 1 then
			vim.lsp.config("gdshader_lsp", {
				capabilities = capabilities,
			})

			vim.lsp.enable("gdshader_lsp")
		end
	end,


}
