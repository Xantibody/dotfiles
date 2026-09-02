# GitHub Flavored Markdown for PR and issue bodies

Every construct GitHub renders exists because some shape of information
reads badly as anything else. Pick the construct from the shape, not from
habit: a flat bullet list is what you reach for when you haven't asked what
shape the information has. This file is the catalogue — what each construct
is for, and the misuse that makes it lie.

One thing specific to PR and issue bodies: GitHub renders a single newline
inside a paragraph as a line break there (unlike in `.md` files in the
repo). Japanese does not wrap on its own, so a paragraph is one sentence
per line, and a wall of text is a paragraph that should have been
something else.

## Prose vs. structure

| Shape of the information                                | Construct                        |
| ------------------------------------------------------- | -------------------------------- |
| A line of argument — this, therefore that               | Paragraph (2–3 sentences)        |
| Parallel items with no order                            | Bulleted list, ≤ 3 siblings      |
| Items whose order carries meaning (steps, before→after) | Numbered list                    |
| A group of items that share a name                      | Parent bullet with nested list   |
| Several groups, each with its own items                 | `###` per group inside a section |
| Items that share the same attributes                    | Table                            |
| Things someone will actually tick off                   | Task list                        |
| Supporting material most readers skip                   | `<details>`                      |
| One thing the reader must not miss                      | Alert                            |
| Someone else's words                                    | Blockquote                       |
| Identifiers, commands, paths, output                    | Code                             |
| Relationships between parts                             | Mermaid (see `mermaid.md`)       |

## Headings

`##` are the template's sections; `###` are groups within one. Never skip
a level, never use bold text as a heading, and never put a heading over a
single item — one item is a bullet or a sentence, not a group. A `###`
earns its place when the items beneath it are about the same area of the
change (画面 / core / CI) and another `###` beside it holds a different
area.

## Lists

- **Size**
  - One idea per bullet. A `。` in the middle of a bullet is usually a
    second bullet: 「A を聞く。B を追加」 is two things that happened, and
    a reader counting items counts it as one. A second sentence is fine
    only when it gives the reason for the first.
  - Three siblings per level. A fourth at the same indentation means a
    grouping is hiding — find the axis and show it with nesting,
    numbering, or headings. Exceed three only for true peers with no
    shared axis.
  - Two levels deep at most. Indent nested bullets by two spaces under
    `-`, three under `1.`; a third level means the axis was wrong.
- **Form**
  - Numbers only when order means something. `1.` on unordered items
    invites the reader to look for a sequence that isn't there.
  - Bold the label, not the sentence. `**役割**: 説明` lets the eye pick
    the item; a fully bold bullet is shouting.

## Tables

A table is for items that share attributes — each row is one item, each
column one attribute the reader will compare across rows. Three columns is
comfortable, four is the limit, and a single-column table is a list wearing
a costume. The header row is required for GitHub to render it. Typical
fits: before / after values, option × trade-off, file × why touched,
screenshot pairs. Use `<br/>` for a line break inside a cell; pipes inside
a cell are escaped as `\|`.

## Task lists

`- [ ]` and `- [x]` are a claim about state, and GitHub renders the
progress in the PR list. Use them for things that will be ticked off — a
test plan, manual steps after merge, follow-ups — and never as decoration
on an ordinary list. A checked box says "done and observed"; leave it
unchecked and say why when it isn't.

## Code

- **Inline backticks** for anything the reader might copy or grep:
  identifiers, paths, flags, commands, values. Not for emphasis.
- **Fenced blocks with a language** for multi-line commands, config
  snippets, error output. `text` for output with no syntax; `diff` for a
  before/after of a few lines, with `-`/`+` prefixes so GitHub colours it.
- **Never paraphrase an error.** Paste it verbatim in a block; a summary of
  an error message is the one thing nobody can search for.

## Blockquotes and alerts

A `>` blockquote is for words that are not yours — an issue comment, a
doc, a spec, a commit body being cited. Using it for emphasis makes the
reader look for the person being quoted.

Alerts are blockquotes with a type and GitHub renders them with an icon
and colour:

```markdown
> [!WARNING]
> マージ後に `darwin-rebuild switch` が必要
```

`NOTE` (context), `TIP` (a better way), `IMPORTANT` (needed to succeed),
`WARNING` (risk), `CAUTION` (irreversible). One per body at most; a body
with three alerts has none.

## Collapsible sections

````markdown
<details>
<summary>nix flake check の全出力</summary>

```text
…
```
````

</details>
```

For the long log, the full command output, the list of 40 renamed files —
material that supports a claim but that most readers will take on trust.
The summary line says what is inside and, if it matters, the one-line
conclusion. The blank lines around the inner block are required or the
markdown inside won't render. Never collapse a template section; the core
of the body is not supporting material.

## Links and references

- `#123` links an issue or PR, a bare commit SHA links the commit, and
  `closes #123` in なぜやるか closes the issue on merge. Prefer these to
  full URLs inside the same repo.
- Link text is the title of the target, not "here" or the URL. A URL is
  fine alone on a 資料 line, where the reader expects one.
- To point at code, use a permalink to the line range (press `y` on the
  file view, then select lines); GitHub renders it as an embedded snippet.
  A path with a line number in backticks is the fallback.

## Images

UI changes get a screenshot; before / after pairs go in a two-column table
so they sit side by side. Give each image alt text that says what to look
at, and keep the image after the sentence that explains it, not before.

## What not to use

Horizontal rules (a heading already separates), emoji (they carry no
information a word doesn't), HTML beyond `<details>`, `<br/>` and `<kbd>`
(GitHub strips most of it), footnotes (an aside worth writing belongs in
the sentence or in やらなかったこと), and italics for emphasis (bold the
label instead; italic disappears in Japanese text).
