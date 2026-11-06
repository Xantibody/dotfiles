-- Twilight: dims everything but the function under the cursor.
require("twilight").setup({
	-- Node types are named by each grammar, so the generic defaults match
	-- almost nothing. Only function-level nodes are listed: twilight expands
	-- to the top-most match, and a class, impl or Nix's file-wide function
	-- would light up the whole file.
	expand = {
		-- Lua
		"function_declaration",
		"function_definition",
		-- Go
		"method_declaration",
		"func_literal",
		-- Rust
		"function_item",
		-- TypeScript / JavaScript
		"method_definition",
		"arrow_function",
	},
})
