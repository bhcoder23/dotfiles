return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			c = { "clang-format" },
			cpp = { "clang-format" },
			objc = { "clang-format" },
			objcpp = { "clang-format" },
			gdscript = { "gdscript-formatter", "gdformat" },
			go = { "goimports", "gofmt" },
			gomod = { "gofmt" },
			gowork = { "gofmt" },
		},
		formatters = {
			["clang-format"] = {
				command = "xcrun",
				args = function(_, ctx)
					local filename = ctx.filename or vim.api.nvim_buf_get_name(ctx.buf)
					local dir = vim.fs.dirname(filename)
					local has_project_style = dir
						and vim.fs.find({ ".clang-format", "_clang-format" }, { path = dir, upward = true })[1]

					local style = has_project_style
						and "file"
						or "{BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never, AccessModifierOffset: -4}"

					return { "clang-format", "-style=" .. style, "-assume-filename", "$FILENAME" }
				end,
			},
		},
	},
}
