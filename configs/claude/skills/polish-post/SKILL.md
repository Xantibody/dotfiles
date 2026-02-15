---
name: polish-post
description: Format rough memos into clean markdown for blog posts.
---

# Polish Post

Format rough memos into clean, well-structured markdown suitable for blog posts.

## Absolute Rule: Never Modify Original Text

**The original text must NEVER be changed, reworded, or rephrased. Only markdown formatting may be added around the original text.**

This is the most important rule of this skill. Markdown syntax (`` ` ``, `>`, `-`, `#`, etc.) may be **added** to the text, but the words themselves must remain exactly as the author wrote them.

### Example

Original memo:

```
Error handling in Go
You can compare wrapped errors using errors.Is
err := doSomething()
if errors.Is(err, ErrNotFound) {
    return nil
}
Handy
```

OK (markdown formatting added, original text preserved):

```markdown
## Error handling in Go

You can compare wrapped errors using `errors.Is`

​```go
err := doSomething()
if errors.Is(err, ErrNotFound) {
    return nil
}
​```

Handy
```

NG (original text modified):

```
Best practices for error handling in Go   ← wording changed
You can compare wrapped errors by using... ← "using" changed to "by using"
```

## Workflow

1. **Ask which file to process**: Use AskUserQuestion to ask the user which markdown file they want to polish. If the user provides a file path as an argument, use that instead of asking.

2. **Read the file**: Read the specified file to understand its content.

3. **Format the markdown**: Apply the formatting rules below to clean up the content.

4. **Show the diff**: Present the changes to the user for review before writing.

5. **Write the result**: After user approval, write the formatted content back to the file.

## Formatting Rules

### Block Quotes

- Ensure `>` block quotes have proper spacing: `> text` (space after `>`)
- Nested block quotes should be properly formatted: `> > text`
- Multi-line block quotes should have `>` on each line, including blank lines (`>`)

### Lists

- Unordered lists should use `-` with a single space: `- item`
- Nested lists should be indented with 2 spaces per level
- Ensure blank lines before and after list blocks for proper rendering
- Ordered lists should use `1.` format with a space: `1. item`

### Code

- Inline code should use single backticks: `` `code` ``
- Code blocks should use triple backticks with a language identifier when possible:
  ````
  ```language
  code
  ```
  ````
- Fix unclosed or mismatched backticks
- If a language is obvious from context but missing, add it (e.g., `bash`, `go`, `nix`, `javascript`, `typescript`)

### Headings

- Ensure space after `#`: `# Heading` not `#Heading`
- Ensure blank line before and after headings
- Do not change the heading hierarchy chosen by the author

### Links and Images

- Fix broken markdown link syntax: `[text](url)`
- Fix broken image syntax: `![alt](url)`

### General Cleanup

- Remove trailing whitespace
- Ensure file ends with a single newline
- Normalize multiple consecutive blank lines to a single blank line
- Preserve frontmatter (YAML between `---` fences) as-is
