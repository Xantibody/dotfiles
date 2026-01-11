---
name: context7
description: Document reading and context management using context7-mcp MCP server. Use when you need to read project documentation, READMEs, or external documentation files.
---

# Context7 Usage

## Overview

Context7 is a document reading tool accessed via the context7-mcp MCP server. It enables reading and understanding various documentation formats to provide better context for code work.

## When to Use

- Reading project documentation (README.md, CONTRIBUTING.md, etc.)
- Understanding API documentation and specifications
- Accessing framework or library documentation
- Loading project-specific guides and conventions
- Reading technical specifications or requirements documents

## How to Activate

When this skill is invoked, you should:

1. Check if context7-mcp MCP server tools are available
2. If not available, inform the user to temporarily enable it in settings.json:
   ```json
   {
     "model": "sonnet",
     "mcpServers": {
       "context7": {
         "command": "context7-mcp"
       }
     }
   }
   ```
3. Restart Claude Code to load the MCP server
4. Use context7 tools to read documentation as needed

## Best Practices

- Use context7 when existing Read tool is insufficient for documentation
- Load relevant documentation before starting implementation work
- Reference documentation when understanding project architecture or patterns
- Use for external documentation that needs special handling
- Combine with code reading tools for comprehensive understanding
