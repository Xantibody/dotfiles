// 箇条の外の段落は 1 文 1 行で書く。「。」のあとで改行し、文の途中では改行しない。
// PR / issue 本文では GitHub が段落内の改行を <br> として描画する (repo 内の .md と違う) ので、
// 改行の位置がそのまま見た目になる。80 桁の折り返しは文の途中で行が切れて見え、
// 1 行に 2 文を並べると文の切れ目が見えにくい。--fix はどちらも直す。
// 箇条は 1 行のまま。箇条の中で文を重ねる形は osekkai の no-sentence-chain-in-list-item が見る。
// AIDEV-NOTE: 行末 2 スペースと \ の hard break は Markdown の意図した改行なので通す
const NON_ASCII = /[^\x00-\x7f]/;
const SENTENCE_END = /[。！？]$/;
// 「。」のすぐ後ろが閉じ括弧なら、文はまだ括弧の中で続いている
const CLOSING = /^[」』）)"'”’]/;

function reporter(context) {
  const { Syntax, RuleError, report, getSource, fixer, locator } = context;
  let listDepth = 0;

  function reportBreak(node, range, glue, message) {
    report(
      node,
      new RuleError(message, {
        padding: locator.range(range),
        fix: fixer.replaceTextRange(range, glue),
      }),
    );
  }

  return {
    [Syntax.ListItem]() {
      listDepth++;
    },
    [Syntax.ListItemExit]() {
      listDepth--;
    },
    [Syntax.Paragraph](node) {
      const text = getSource(node);
      const inList = listDepth > 0;

      const breaks = /([ \t]*)\n[ \t]*/g;
      let m;
      while ((m = breaks.exec(text)) !== null) {
        const before = text.slice(0, m.index);
        if (m[1].length >= 2 || before.endsWith("\\")) {
          continue;
        }
        if (!inList && SENTENCE_END.test(before)) {
          continue;
        }
        const prev = before.slice(-1);
        const next = text.slice(m.index + m[0].length, m.index + m[0].length + 1);
        const glue = NON_ASCII.test(prev) && NON_ASCII.test(next) ? "" : " ";
        reportBreak(
          node,
          [m.index, m.index + m[0].length],
          glue,
          inList
            ? "箇条の途中で改行しない。PR / issue 本文では GitHub が改行をそのまま描画する"
            : "文の途中で改行しない。改行は「。」のあとだけにする",
        );
      }

      if (inList) {
        return;
      }
      const ends = /[。！？][ \t]*/g;
      while ((m = ends.exec(text)) !== null) {
        const end = m.index + m[0].length;
        const rest = text.slice(end);
        if (rest === "" || rest.startsWith("\n") || CLOSING.test(rest)) {
          continue;
        }
        // the range takes the 「。」 too: a zero-width range is refused by the locator
        reportBreak(node, [m.index, end], `${m[0][0]}\n`, "1 行に 1 文。「。」のあとで改行する");
      }
    },
  };
}

module.exports = { linter: reporter, fixer: reporter };
