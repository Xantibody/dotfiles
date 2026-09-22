// 見出しの直後に同じ深さ以下の見出しか文書の末尾が来る、中身の無い節を指摘する。
// PR / issue のテンプレを埋められなかった節は消すのが規則で、「特になし」も空扱いにする。
// AIDEV-NOTE: azu/textlint-rule-no-empty-section は 2017 年で止まり lock も無いので、同じ判定を自前で持つ
const PLACEHOLDER = /^(特になし|なし|N\/A|none|TBD)[。.]?$/i;

module.exports = function reporter(context) {
  const { Syntax, RuleError, report, getSource } = context;
  return {
    [Syntax.Document](node) {
      const children = node.children;
      children.forEach((child, i) => {
        if (child.type !== Syntax.Header) {
          return;
        }
        const next = children[i + 1];
        const isEmpty =
          next === undefined ||
          (next.type === Syntax.Header && next.depth <= child.depth) ||
          (next.type === Syntax.Paragraph && PLACEHOLDER.test(getSource(next).trim()));
        if (isEmpty) {
          report(child, new RuleError("中身の無い節を残さない。埋められない節は見出しごと消す"));
        }
      });
    },
  };
};
