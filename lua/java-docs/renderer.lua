local M = {}
local util = vim.lsp.util
local config = require("java-docs.config")

---@param lines string[]
---@return string[]
local function format_javadoc(lines)
  local formatted = {}
  local signature = {}
  local description = {}
  local params = {}
  local returns = {}
  local throws = {}
  
  local current_section = "description"
  
  for _, line in ipairs(lines) do
    -- Simple heuristic parsing
    if line:match("^```java") or line:match("^```") then
       -- Skip code block markers for now, or handle signature
       -- JDTLS usually puts signature in the first code block
       if #signature == 0 and #description == 0 then
         current_section = "signature"
       elseif current_section == "signature" then
         current_section = "description"
       end
    elseif current_section == "signature" then
      table.insert(signature, line)
    elseif line:match("^Parameters:") or line:match("^Params:") or line:match("^%*+Parameters:%*+") or line:match("^%*+Params:%*+") then
      current_section = "params"
    elseif line:match("^Returns:") or line:match("^Return:") or line:match("^%*+Returns:%*+") or line:match("^%*+Return:%*+") then
      current_section = "returns"
    elseif line:match("^Throws:") or line:match("^Throw:") or line:match("^%*+Throws:%*+") or line:match("^%*+Throw:%*+") then
      current_section = "throws"
    else
      if current_section == "description" then
        table.insert(description, line)
      elseif current_section == "params" then
        table.insert(params, line)
      elseif current_section == "returns" then
        table.insert(returns, line)
      elseif current_section == "throws" then
        table.insert(throws, line)
      end
    end
  end
  
  -- Reconstruct
  if #signature > 0 then
    table.insert(formatted, "```java")
    vim.list_extend(formatted, signature)
    table.insert(formatted, "```")
    table.insert(formatted, "---") -- Horizontal rule simulation
  end
  
  if #description > 0 then
    vim.list_extend(formatted, description)
  end
  
  if #params > 0 then
    table.insert(formatted, "")
    table.insert(formatted, "**Parameters:**")
    vim.list_extend(formatted, params)
  end
  
  if #returns > 0 then
    table.insert(formatted, "")
    table.insert(formatted, "**Returns:**")
    vim.list_extend(formatted, returns)
  end
  
  if #throws > 0 then
    table.insert(formatted, "")
    table.insert(formatted, "**Throws:**")
    vim.list_extend(formatted, throws)
  end
  
  return formatted
end

M.hover_handler = function(_, result, ctx, _)
  if not (result and result.contents) then
    return
  end
  
  local markdown_lines = util.convert_input_to_markdown_lines(result.contents)
  markdown_lines = util.trim_empty_lines(markdown_lines)
  
  if vim.tbl_isempty(markdown_lines) then
    return
  end

  local formatted_lines = format_javadoc(markdown_lines)
  
  -- Use the plugin's config for the floating window
  return util.open_floating_preview(formatted_lines, "markdown", config.options)
end

return M
