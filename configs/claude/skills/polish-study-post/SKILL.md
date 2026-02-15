---
name: polish-study-post
description: Format study blog posts with section hierarchy, author comments, and quotes.
---

# Polish Study Post

Format study blog posts following the established structural patterns. This skill adds study-post-specific formatting on top of generic markdown formatting.

## Absolute Rule: Never Modify Original Text

Inherited from `/polish-post`. The original text must NEVER be changed, reworded, or rephrased. Only markdown formatting may be added around the original text.

## Workflow

1. **Run `/polish-post` first**: Apply generic markdown formatting to the file before applying study-post-specific rules.

2. **Read 2-3 existing posts** in the same category to confirm the current structural patterns are still in use.

3. **Apply study-post structure rules** (see below) to the formatted file.

4. **Show the diff**: Present the changes to the user for review before writing.

5. **Write the result**: After user approval, write the formatted content back to the file.

## Section Structure

Study posts follow this fixed section hierarchy:

```markdown
## はじめに
<!-- Intro: what the author is studying, context -->

## お勉強
<!-- Study URL and opening thoughts about the session -->

### メモ
<!-- Study notes: observations, code examples, quotes -->
<!-- Optional #### subsections for distinct topics within notes -->

## まとめ
<!-- Summary: key takeaways, reflections -->
<!-- End with the next study URL -->
```

- Do not add, remove, or reorder these sections.
- `####` subsections under `### メモ` are optional and author-driven; do not create them.

## Formatting Rules

### Author Comments → `-` List Items

Lines where the author writes their own thoughts, reactions, or observations should be formatted as unordered list items using `-`.

```markdown
- なるほど、何がなるほどかはなぞだが
- ここ大事そうか
```

### Related Sub-thoughts → `  -` Nested List Items

When an author comment is a follow-up or elaboration of the previous comment, indent it as a nested list item (2-space indent).

```markdown
- ここから
  - あー複数の所有権をもてそうって話
  - 真相は謎
```

### Reference/Book Quotes → `>` Block Quotes

Text quoted from the study material (book, documentation, articles) should be formatted as block quotes using `>`.

```markdown
> 値と`List`を指す`Rc<T>`を保持するようになりました
```

### Distinguishing Comments from Quotes

- If the line is the author's own words → `-` list item
- If the line is copied/referenced from the study material → `>` block quote
- When uncertain, leave the line as-is and ask the user
