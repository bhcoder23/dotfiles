vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

opt.relativenumber = true
opt.number = true

-- tabs / indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true
opt.copyindent = true
opt.preserveindent = true
opt.pumheight = 8

opt.wrap = false

opt.ignorecase = true
opt.smartcase = true

opt.cursorline = true

opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

opt.backspace = "indent,eol,start"

opt.clipboard:append("unnamedplus")

opt.splitright = true
opt.splitbelow = true

opt.foldmethod = "marker"
opt.foldmarker = "#pragma region,#pragma endregion"

vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		local bo = vim.bo[args.buf]
		local two_space_filetypes = {
			c = true,
			cpp = true,
			cuda = true,
			objc = true,
			objcpp = true,
		}
		local indent = two_space_filetypes[bo.filetype] and 2 or 4

		bo.tabstop = indent
		bo.shiftwidth = indent
		bo.softtabstop = indent
		bo.expandtab = true
		bo.autoindent = true
		bo.smartindent = true
		bo.copyindent = true
		bo.preserveindent = true
	end,
})

vim.filetype.add({
	extension = {
		gd = "gdscript",
		gdshader = "gdshader",
		gdshaderinc = "gdshaderinc",
		tres = "gdresource",
		tscn = "gdresource",
	},
	filename = {
		["project.godot"] = "godot",
	},
})
