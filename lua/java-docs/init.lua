local M = {}
local config = require("java-docs.config")
local renderer = require("java-docs.renderer")

function M.setup(options)
  config.setup(options)
  
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "jdtls" then
        -- Override the hover handler for this client instance
        client.handlers["textDocument/hover"] = renderer.hover_handler
        -- vim.notify("java-docs attached to jdtls", vim.log.levels.INFO)
      end
    end,
  })
end

return M
