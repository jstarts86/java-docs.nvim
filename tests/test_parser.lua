-- Add lua directory to path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local M = {}

local function run_test(name, input, expected_contains)
  local renderer = require("java-docs.renderer")
  -- Mock vim.lsp.util for the test environment if needed, or rely on the fact we are running in nvim -l
  -- But renderer uses vim.lsp.util, so we might need to mock it or ensure it's available.
  -- In `nvim -l`, standard vim modules are available.
  
  print("Running test: " .. name)
  local result = renderer.format_javadoc(input)
  
  local result_str = table.concat(result, "\n")
  
  local all_found = true
  for _, expected in ipairs(expected_contains) do
    if not string.find(result_str, expected, 1, true) then
      print("  FAILED: Expected to find '" .. expected .. "'")
      all_found = false
    end
  end
  
  if all_found then
    print("  PASSED")
  else
    print("  Result was:\n" .. result_str)
  end
end

-- Mock config
package.loaded["java-docs.config"] = {
  options = {}
}

-- Test 1: Simple Javadoc
local input1 = {
  "```java",
  "public void testMethod(String arg)",
  "```",
  "Description of the method.",
  "",
  "Params:",
  "arg - the argument",
  "Returns:",
  "nothing"
}

run_test("Simple Javadoc", input1, {
  "```java",
  "public void testMethod(String arg)",
  "Description of the method.",
  "**Parameters:**",
  "- `arg`: the argument", -- Expecting some formatting
  "**Returns:**",
  "nothing"
})

-- Test 2: HTML Tags
local input2 = {
  "```java",
  "void htmlMethod()",
  "```",
  "<p>This is a <b>bold</b> description.</p>",
  "<ul>",
  "<li>Item 1</li>",
  "<li>Item 2</li>",
  "</ul>"
}

run_test("HTML Tags", input2, {
  "This is a **bold** description.",
  "- Item 1",
  "- Item 2"
})

-- Test 3: jdt:// links
local input3 = {
  "Returns an instance of {@link String}."
}
-- Note: jdtls often sends markdown with links like [String](jdt://...)
-- But raw javadoc might have {@link}. Let's assume jdtls has already done some conversion 
-- or we are receiving raw text. 
-- Actually, `textDocument/hover` usually returns Markdown from jdtls.
-- Let's simulate what jdtls sends.
local input3_jdtls = {
  "Returns an instance of [String](jdt://contents/java.base/java.lang/String.class)."
}

run_test("JDT Link Handling", input3_jdtls, {
  "Returns an instance of `String`." -- We want to strip the jdt link and maybe code-ify it
})

-- Test 4: Real World Path Example
local input4 = {
  "A `Path` defines the [getFileName](jdt://contents/java.base/java.nio.file/Path.class?=code-grapher/%5C/Users%5C/john%5C/Library%5C/Java%5C/JavaVirtualMachines%5C/corretto-22.0.2%5C/Contents%5C/Home%5C/lib%5C/jrt-fs.jar%60java.base=/javadoc_location=/https:%5C/%5C/docs.oracle.com%5C/en%5C/java%5C/javase%5C/22%5C/docs%5C/api%5C/=/=/maven.pomderived=/true=/%3Cjava.nio.file%28Path.class#250) method."
}

run_test("Real World Path", input4, {
  "A `Path` defines the `getFileName` method."
})

-- Test 5: Multiple links and Javadoc tags
local input5 = {
  "See {@link String} and {@code int}.",
  "Also <a href='http://example.com'>Example</a>.",
  "<h3>Header</h3>",
  "Check [link1](jdt://foo) and [link2](jdt://bar)."
}

run_test("Complex Tags", input5, {
  "See `String` and `int`.",
  "Also [Example](http://example.com).", -- or just Example
  "### Header",
  "Check `link1` and `link2`."
})
