local renderer = require("java-docs.renderer")

-- Mock vim.lsp.util
vim.lsp = {
  util = {
    convert_input_to_markdown_lines = function(input)
      return vim.split(input, "\n")
    end,
    trim_empty_lines = function(lines)
      return lines
    end,
    open_floating_preview = function(lines, ft, opts)
      print("--- Preview Output ---")
      for _, line in ipairs(lines) do
        print(line)
      end
      print("----------------------")
    end
  }
}

-- Mock config
package.loaded["java-docs.config"] = {
  options = {}
}

-- Test Case 1: Standard Javadoc
local input1 = [[```java
public void test(int a)
```
Description of test.

Parameters:
 a - the integer

Returns:
 nothing
]]

print("Test Case 1:")
renderer.hover_handler(nil, { contents = input1 }, nil, nil)

-- Test Case 2: No params
local input2 = [[```java
public void simple()
```
Just a description.
]]

print("\nTest Case 2:")
renderer.hover_handler(nil, { contents = input2 }, nil, nil)
