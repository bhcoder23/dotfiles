local M = {}

function M.open_list(list)
	local items = list and list.items or {}
	if vim.tbl_isempty(items) then
		return
	end

	local title = list.title or "LSP locations"
	vim.fn.setqflist({}, " ", vim.tbl_extend("force", list, {
		title = title,
		items = items,
	}))

	if #items == 1 then
		vim.cmd("normal! m'")
		vim.cmd("cfirst")
		return
	end

	local ok, telescope = pcall(require, "telescope.builtin")
	if ok then
		telescope.quickfix({ prompt_title = title })
	else
		vim.cmd("botright copen")
	end
end

function M.references()
	vim.lsp.buf.references(nil, { on_list = M.open_list })
end

function M.implementation()
	vim.lsp.buf.implementation({ on_list = M.open_list })
end

function M.type_definition()
	vim.lsp.buf.type_definition({ on_list = M.open_list })
end

function M.incoming_calls()
	vim.lsp.buf.incoming_calls()
end

function M.outgoing_calls()
	vim.lsp.buf.outgoing_calls()
end

return M
