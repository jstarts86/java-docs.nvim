# java-docs.nvim

A Neovim plugin to render Java documentation (javadocs) in a style similar to IntelliJ IDEA.

## Features

- Enhanced hover documentation for Java.
- IntelliJ-like formatting.
- Seamless integration with `nvim-jdtls`.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "dir": "/path/to/java-docs", -- For local development
  -- "username/java-docs.nvim", -- When published
  config = function()
    require("java-docs").setup({})
  end,
}
```

## Configuration

```lua
require("java-docs").setup({
  border = "rounded", -- "single", "double", "rounded", "solid", "shadow"
  max_width = 80,
  max_height = 20,
})
```
