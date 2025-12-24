local M = {}
local config = require("java-docs.config")
local renderer = require("java-docs.renderer")

function M.setup(options)
  config.setup(options)
  
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("java-docs-lsp-attach", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "jdtls" then
        -- Define a custom handler that formats the content then delegates
        client.handlers["textDocument/hover"] = function(err, result, ctx, config)
          if result and result.contents then
            local util = vim.lsp.util
            local markdown_lines = util.convert_input_to_markdown_lines(result.contents)
            markdown_lines = util.trim_empty_lines(markdown_lines)
            
            if not vim.tbl_isempty(markdown_lines) then
              local formatted = renderer.format_javadoc(markdown_lines)
              -- Update result with formatted content
              result.contents = {
                kind = "markdown",
                value = table.concat(formatted, "\n")
              }
            end
          end
          
          -- Delegate to the global handler (Noice, or default)
          -- We use pcall just in case, though it should exist
          local global_handler = vim.lsp.handlers["textDocument/hover"]
          if global_handler then
            global_handler(err, result, ctx, config)
          else
            -- Fallback if no global handler (unlikely)
            vim.lsp.util.open_floating_preview(result.contents, "markdown", config)
          end
        end
        
        vim.notify("java-docs: Attached to jdtls with Noice integration", vim.log.levels.INFO)
      end
    end,
  })
end

return M
