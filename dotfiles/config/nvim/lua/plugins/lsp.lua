return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local servers = require("sauce.generated").servers

            local caps = require("cmp_nvim_lsp").default_capabilities()

            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(ev)
                    local b = ev.buf
                    local function m(lhs, fn, desc)
                        vim.keymap.set("n", lhs, fn, { buffer = b, desc = desc })
                    end
                    m("gd", vim.lsp.buf.definition, "LSP: definition")
                    m("gr", vim.lsp.buf.references, "LSP: references")
                    m("K", vim.lsp.buf.hover, "LSP: hover")
                    m("<leader>rn", vim.lsp.buf.rename, "LSP: rename")
                    m("<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
                    m("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Diagnostic: prev")
                    m("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Diagnostic: next")
                end,
            })

            local overrides = {
                lua_ls = { settings = { Lua = { diagnostics = { globals = { "vim" } } } } },
            }

            for _, name in ipairs(servers) do
                local cfg = vim.tbl_deep_extend("force", { capabilities = caps }, overrides[name] or {})
                vim.lsp.config(name, cfg)
                vim.lsp.enable(name)
            end
        end,
    },
}
