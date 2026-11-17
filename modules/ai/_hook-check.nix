# PreToolUse hook を表で検査する check を組む関数。flake-parts module ではないので `_` 始まりにしている。
# 各行は hook の stdin に渡す入力と、stdout の JSON に `jq -e` で当てる式 (何も出さなければ null に当てる)、
# 期待する exit code (省略時 0)、stderr に当てる bash の正規表現 (省略時は stderr が空であること)。
# 外れた行をすべて出してから落ちる。
#
#   mkHookCheck pkgs {
#     name = "gh-guard";
#     hook = ghGuard;
#     cases = [ { name = "..."; input.tool_input.command = "..."; expect = ". == null"; } ];
#   }
pkgs:
{
  name,
  hook,
  cases,
}:
pkgs.runCommand name
  {
    nativeBuildInputs = [ pkgs.jq ];
    cases = builtins.toJSON cases;
    passAsFile = [ "cases" ];
  }
  ''
    failed=0
    n=$(jq length "$casesPath")
    for ((i = 0; i < n; i++)); do
      row=$(jq -c ".[$i]" "$casesPath")
      case_name=$(jq -r .name <<<"$row")
      expect=$(jq -r .expect <<<"$row")
      want_exit=$(jq -r '.exit // 0' <<<"$row")
      want_stderr=$(jq -r '.stderr // ""' <<<"$row")
      status=0
      jq -c .input <<<"$row" | ${pkgs.lib.getExe hook} >stdout 2>stderr || status=$?
      got=$(cat stdout)
      err=$(cat stderr)
      stderr_ok=1
      if [[ -z $want_stderr ]]; then
        [[ -z $err ]] || stderr_ok=0
      elif ! [[ $err =~ $want_stderr ]]; then
        stderr_ok=0
      fi
      if [[ $status != "$want_exit" ]] || ((stderr_ok == 0)) || ! jq -e "$expect" >/dev/null 2>&1 <<<"''${got:-null}"; then
        failed=1
        echo "FAIL $case_name"
        echo "  expect: $expect, exit $want_exit, stderr ''${want_stderr:-empty}"
        echo "  got:    exit $status, stdout: $got"
        sed 's/^/  stderr: /' stderr
      fi
    done
    ((failed == 0)) || exit 1
    touch $out
  ''
