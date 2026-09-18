// 箇条書きの行頭句を ` — ` ` – ` ` - ` で本文に繋ぐ書き方を指摘する。
// 「`foo` — 説明」は見出しと本文を 1 行に押し込んだ形で、explain skill の
// 「一つの bullet に一つの主張」に反する。太字ラベルつきの形は ai-writing の
// no-ai-list-formatting が拾うので、ここは太字なしの形だけを見る。書き直しが要るので fix はしない。
const SEPARATOR = /^(?:\[[ xX]\]\s*)?(.{1,60}?)\s+([—–-])\s+/u;

module.exports = function reporter(context) {
  const { Syntax, RuleError, report, getSource, locator } = context;
  return {
    [Syntax.ListItem](node) {
      const paragraph = node.children.find((child) => child.type === Syntax.Paragraph);
      if (!paragraph) {
        return;
      }
      const firstLine = getSource(paragraph).split("\n")[0];
      const m = SEPARATOR.exec(firstLine);
      if (!m) {
        return;
      }
      const index = m[0].lastIndexOf(m[2]);
      report(
        paragraph,
        new RuleError(
          `「${m[1]}」の後ろを「${m[2]}」で区切らず、1 つの文にするか下位の bullet に分ける`,
          {
            padding: locator.range([index, index + m[2].length]),
          },
        ),
      );
    },
  };
};
