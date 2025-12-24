local M = {}
local util = vim.lsp.util
local config = require("java-docs.config")

-- Helper to strip HTML tags and convert to Markdown
local function clean_html(text)
  if not text then return "" end
  
  -- Simple replacements
  text = text:gsub("<b>(.-)</b>", "**%1**")
  text = text:gsub("<strong>(.-)</strong>", "**%1**")
  text = text:gsub("<i>(.-)</i>", "*%1*")
  text = text:gsub("<em>(.-)</em>", "*%1*")
  text = text:gsub("<code>(.-)</code>", "`%1`")
  text = text:gsub("<pre>(.-)</pre>", "\n```java\n%1\n```\n")
  
  -- Lists
  text = text:gsub("<li>", "- ")
  text = text:gsub("</li>", "")
  text = text:gsub("<ul>", "")
  text = text:gsub("</ul>", "")
  
  -- Paragraphs
  text = text:gsub("<p>", "\n\n")
  text = text:gsub("</p>", "")
  text = text:gsub("<br/?>", "\n")
  
  -- Strip remaining tags
  text = text:gsub("<[^>]+>", "")
  
  -- Decode entities (basic ones)
  text = text:gsub("&lt;", "<")
  text = text:gsub("&gt;", ">")
  text = text:gsub("&amp;", "&")
  text = text:gsub("&nbsp;", " ")
  
  return text
end

local function clean_jdt_links(text)
  -- Replace [ClassName](jdt://...) with `ClassName`
  -- Pattern: %[(.-)%]%(jdt://.-%)
  return text:gsub("%[([%w%.]+)%]%(jdt://[^%)]+%)", "`%1`")
end

---@param lines string[]
---@return string[]
function M.format_javadoc(lines)
  local formatted = {}
  local signature = {}
  local description = {}
  local params = {}
  local returns = {}
  local throws = {}
  
  local current_section = "description"
  
  for _, line in ipairs(lines) do
    -- Clean up the line first
    local clean_line = clean_jdt_links(line)
    
    -- Check for code block markers which usually denote signature in JDTLS hover
    if line:match("^```java") or line:match("^```") then
       -- If we haven't captured signature yet, assume this is it
       if #signature == 0 and #description == 0 then
         current_section = "signature"
       elseif current_section == "signature" then
         current_section = "description"
       end
    elseif current_section == "signature" then
      table.insert(signature, line)
    elseif clean_line:match("^Parameters:") or clean_line:match("^Params:") or clean_line:match("^%*+Parameters:%*+") or clean_line:match("^%*+Params:%*+") then
      current_section = "params"
    elseif clean_line:match("^Returns:") or clean_line:match("^Return:") or clean_line:match("^%*+Returns:%*+") or clean_line:match("^%*+Return:%*+") then
      current_section = "returns"
    elseif clean_line:match("^Throws:") or clean_line:match("^Throw:") or clean_line:match("^%*+Throws:%*+") or clean_line:match("^%*+Throw:%*+") then
      current_section = "throws"
    else
      -- Process content based on section
      if current_section == "description" then
        -- Handle HTML in description
        local processed = clean_html(clean_line)
        if processed ~= "" then
          table.insert(description, processed)
        end
      elseif current_section == "params" then
        -- Try to format "paramName - description"
        -- Remove leading bullets if present
        local p_line = clean_line:gsub("^%s*-%s*", ""):gsub("^%s*", "")
        if p_line ~= "" then
            -- Check for "name - desc" or "name desc"
            local name, desc = p_line:match("^(%w+)%s*-%s*(.*)")
            if not name then
                name, desc = p_line:match("^(%w+)%s+(.*)")
            end
            
            if name then
                table.insert(params, "- `" .. name .. "`: " .. clean_html(desc))
            else
                table.insert(params, "- " .. clean_html(p_line))
            end
        end
      elseif current_section == "returns" then
        local r_line = clean_line:gsub("^%s*", "")
        if r_line ~= "" then
            table.insert(returns, clean_html(r_line))
        end
      elseif current_section == "throws" then
        local t_line = clean_line:gsub("^%s*", "")
        if t_line ~= "" then
             table.insert(throws, "- " .. clean_html(t_line))
        end
      end
    end
  end
  
  -- Reconstruct
  if #signature > 0 then
    table.insert(formatted, "```java")
    vim.list_extend(formatted, signature)
    table.insert(formatted, "```")
    table.insert(formatted, "---") 
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

  local formatted_lines = M.format_javadoc(markdown_lines)
  
  -- Use the plugin's config for the floating window
  return util.open_floating_preview(formatted_lines, "markdown", config.options)
end

return M
