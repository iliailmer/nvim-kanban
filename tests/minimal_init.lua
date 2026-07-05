local plenary_path = os.getenv("PLENARY_PATH") or (os.getenv("HOME") .. "/.local/share/nvim/lazy/plenary.nvim")
vim.opt.runtimepath:append(plenary_path)
vim.opt.runtimepath:append(vim.fn.getcwd())
vim.cmd("runtime plugin/plenary.vim")
