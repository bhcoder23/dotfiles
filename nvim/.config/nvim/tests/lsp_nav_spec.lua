local nav = require("salar.core.lsp_nav")

local function assert_eq(actual, expected, message)
	if actual ~= expected then
		error((message or "assertion failed") .. ": expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
	end
end

do
	local original = vim.lsp.buf.implementation
	local called_opts
	vim.lsp.buf.implementation = function(opts)
		called_opts = opts
	end

	nav.implementation()

	vim.lsp.buf.implementation = original
	assert_eq(called_opts.on_list, nav.open_list, "implementation should use the shared list handler")
end

do
	local original = vim.lsp.buf.type_definition
	local called_opts
	vim.lsp.buf.type_definition = function(opts)
		called_opts = opts
	end

	nav.type_definition()

	vim.lsp.buf.type_definition = original
	assert_eq(called_opts.on_list, nav.open_list, "type_definition should use the shared list handler")
end

do
	local original = vim.lsp.buf.references
	local called_context
	local called_opts
	vim.lsp.buf.references = function(context, opts)
		called_context = context
		called_opts = opts
	end

	nav.references()

	vim.lsp.buf.references = original
	assert_eq(called_context, nil, "references should use the default reference context")
	assert_eq(called_opts.on_list, nav.open_list, "references should use the shared list handler")
end

do
	local original_setqflist = vim.fn.setqflist
	local original_cmd = vim.cmd
	local original_telescope = package.loaded["telescope.builtin"]
	local qflist_payload
	local quickfix_opts
	local commands = {}

	vim.fn.setqflist = function(_, _, payload)
		qflist_payload = payload
	end
	vim.cmd = function(command)
		commands[#commands + 1] = command
	end
	package.loaded["telescope.builtin"] = {
		quickfix = function(opts)
			quickfix_opts = opts
		end,
	}

	nav.open_list({
		title = "LSP Implementations",
		items = {
			{ filename = "a.cc", lnum = 1, col = 1, text = "a" },
			{ filename = "b.cc", lnum = 2, col = 1, text = "b" },
		},
	})

	vim.fn.setqflist = original_setqflist
	vim.cmd = original_cmd
	package.loaded["telescope.builtin"] = original_telescope

	assert_eq(qflist_payload.title, "LSP Implementations", "quickfix title should be preserved")
	assert_eq(#qflist_payload.items, 2, "all locations should be added to quickfix")
	assert_eq(quickfix_opts.prompt_title, "LSP Implementations", "multiple locations should open Telescope quickfix")
	assert_eq(#commands, 0, "Telescope path should not open the raw quickfix window")
end
