-- Plugins, parsers and language servers come from the pinned Nix closure, not Mason/Lazy downloads.
vim.g.mapleader = " "
vim.g.maplocalleader = " "
require("sauce.options")
require("sauce.keymaps")

require("plugins.cmp")[1].config()
local git = require("plugins.gitsigns")
require("gitsigns").setup(git[1].opts)
require("diffview").setup(git[2].opts)
require("log-highlight").setup({})
require("plugins.lsp")[1].config()

local legacy, treesitter = pcall(require, "nvim-treesitter.configs")
if legacy then
    treesitter.setup({ highlight = { enable = true }, indent = { enable = true }, auto_install = false })
else
    vim.api.nvim_create_autocmd("FileType", {
        callback = function() pcall(vim.treesitter.start) end,
    })
end
pcall(vim.cmd.colorscheme, "one-dark-vivid")
