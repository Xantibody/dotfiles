// 段落の途中の改行を指摘する。PR / issue 本文では GitHub が段落内の改行を <br> として描画する
// (repo 内の .md と違う) ので、80 桁で折り返した日本語は文の途中で行が切れて見える。--fix で 1 行に繋ぐ。
// AIDEV-NOTE: 行末 2 スペースと \ の hard break は Markdown の意図した改行なので通す
const NON_ASCII = /[^\x00-\x7f]/;

function reporter(context) {
  const { Syntax, RuleError, report, getSource, fixer, locator } = context;
  return {
    [Syntax.Paragraph](node) {
      const text = getSource(node);
      const re = /([ \t]*)\n[ \t]*/g;
      let m;
      while ((m = re.exec(text)) !== null) {
        const before = text.slice(0, m.index);
        if (m[1].length >= 2 || before.endsWith("\\")) {
          continue;
        }
        const prev = before.slice(-1);
        const next = text.slice(m.index + m[0].length, m.index + m[0].length + 1);
        const glue = NON_ASCII.test(prev) && NON_ASCII.test(next) ? "" : " ";
        const range = [m.index, m.index + m[0].length];
        report(
          node,
          new RuleError(
            "段落の途中で改行しない。PR / issue 本文では GitHub が改行をそのまま描画する",
            {
              padding: locator.range(range),
              fix: fixer.replaceTextRange(range, glue),
            },
          ),
        );
      }
    },
  };
}

module.exports = { linter: reporter, fixer: reporter };
