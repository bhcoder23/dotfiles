vim.g.mapleader = " "

local keymap = vim.keymap
local lsp_nav = require("salar.core.lsp_nav")

keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode" })

keymap.set("n", "<C-u>", "<C-u>zz")
keymap.set("n", "<C-d>", "<C-d>zz")

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase height" })
keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease height" })
keymap.set("n", "<C-Left>", ":vertical resize -4<CR>", { desc = "Narrower" })
keymap.set("n", "<C-Right>", ":vertical resize +4<CR>", { desc = "Wider" })

-- buffer management
keymap.set("n", "H", "<cmd>BufferLineCyclePrev<CR>", { desc = "Go to previous buffer" })
keymap.set("n", "L", "<cmd>BufferLineCycleNext<CR>", { desc = "Go to next buffer" })
keymap.set("n", "<leader>x", "<cmd>bdelete<CR>", { desc = "Close current buffer" })
keymap.set("n", "<leader>n", "<cmd>tabnew<CR>", { desc = "New tab" })
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- file explorer
keymap.set("n", "<C-n>", "<cmd>Ex<CR>", { desc = "Open file explorer" })

vim.keymap.set("n", "<leader>ci", lsp_nav.incoming_calls, { desc = "Show LSP incoming calls" })
vim.keymap.set("n", "<leader>co", lsp_nav.outgoing_calls, { desc = "Show LSP outgoing calls" })
vim.keymap.set("n", "<leader>ch", lsp_nav.implementation, { desc = "Show LSP implementations" })
vim.keymap.set("n", "<leader>cu", lsp_nav.references, { desc = "Show LSP references" })

keymap.set("n", "<leader>ts", "<cmd>Theme<CR>", { desc = "Select theme" })
keymap.set("n", "<leader>tn", "<cmd>ThemeNext<CR>", { desc = "Next theme" })
keymap.set("n", "<leader>tp", "<cmd>ThemePrev<CR>", { desc = "Previous theme" })
