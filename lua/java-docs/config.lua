local M = {}

M.defaults = {
  border = "rounded",
  max_width = 80,
  max_height = 20,
}

M.options = {}

function M.setup(options)
  M.options = vim.tbl_deep_extend("force", M.defaults, options or {})
end

return M
