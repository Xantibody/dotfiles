# Claude Code の PreToolUse hook (Bash 向け)。
# ruleset・branch protection・contents・merges・refs を書き換える gh api と、gh pr merge の
# --admin / --auto に permissionDecision "ask" を返し、ユーザーの確認を 1 回挟む。それ以外は何も出さない。
# agent はユーザーの admin トークンで動くので、gh api -X PUT .../contents/<path> は git push の
# deny を迂回して main に直接書け、ruleset の bypass もそのまま効く。
set -euo pipefail

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")

# 前置きの wrapper と sh -c。rtk hook が gh を rtk gh に書き換えるので rtk もここに入る。
# verify-gate は check skill が検査の前に置く `verify-gate run --`
wrappers=" rtk env command builtin exec nohup sudo doas nice time timeout xargs eval bash sh zsh dash ksh verify-gate "

# 書き込みを確認したい REST の endpoint。repos/<o>/<r>/ や orgs/<o>/ の後ろに来る
endpoint_re='(^|/)(rulesets|protection|contents|merges|git/refs|pulls/[^/]+/merge)(/|\?|$)'
# graphql で同じことをする mutation
mutation_re='createCommitOnBranch|(create|update|delete)Ref|updateRefs|BranchProtectionRule|Ruleset|mergePullRequest|enablePullRequestAutoMerge'

# api の引数から method を読み、endpoint が当たれば理由を返す。
# method は -X / --method、無ければ -f / -F / --input の有無で gh と同じく暗黙の POST とみなす
check_api() {
  local method="" body=0 endpoint=""
  while (($#)); do
    case $1 in
    -X | --method)
      method=${2:-}
      shift
      ;;
    -X*) method=${1#-X} ;;
    --method=*) method=${1#--method=} ;;
    -f | -F | --field | --raw-field | --input)
      body=1
      shift
      ;;
    -f* | -F* | --field=* | --raw-field=* | --input=*) body=1 ;;
    -H | --header | -q | --jq | -t | --template | --hostname | --cache | -p | --preview) shift ;;
    -*) ;;
    # quote を外した後なので -H 'Accept: x' の値も位置引数に見える。当たる最初のものを endpoint とする
    *) [[ -n $endpoint || ! $1 =~ $endpoint_re ]] || endpoint=$1 ;;
    esac
    (($#)) && shift
  done
  if [[ -z $method ]]; then
    method=GET
    ((body)) && method=POST
  fi
  method=${method^^}
  [[ $method != GET && $method != HEAD ]] || return 0
  if [[ $endpoint =~ $endpoint_re ]]; then
    echo "gh api $method $endpoint"
  fi
}

# 1 つの断片 (区切り記号の間) を見て、確認が要れば理由を出す
check_segment() {
  local -a t=("$@")
  # GH_TOKEN=... gh のような前置きの代入を飛ばす
  while ((${#t[@]})) && [[ ${t[0]} == *=* ]]; do
    t=("${t[@]:1}")
  done
  ((${#t[@]})) || return 0
  if [[ ${t[0]##*/} != gh ]]; then
    # wrapper の後ろなら、最初に出てくる gh から見る
    [[ $wrappers == *" ${t[0]##*/} "* ]] || return 0
    while ((${#t[@]})) && [[ ${t[0]##*/} != gh ]]; do
      t=("${t[@]:1}")
    done
    ((${#t[@]})) || return 0
  fi
  case ${t[1]:-} in
  api)
    if [[ ${t[2]:-} == graphql ]]; then
      [[ ${t[*]} =~ mutation && ${t[*]} =~ $mutation_re ]] && echo "gh api graphql ${BASH_REMATCH[0]}"
      return 0
    fi
    check_api "${t[@]:2}"
    ;;
  pr)
    [[ ${t[2]:-} == merge ]] || return 0
    local a
    for a in "${t[@]:3}"; do
      case $a in
      --admin | --admin=* | --auto | --auto=*)
        echo "gh pr merge ${a%%=*}"
        return 0
        ;;
      esac
    done
    ;;
  esac
}

# 区切り記号で切った断片ごとに見る。quote は外すだけで解釈しない。
# AIDEV-NOTE: 確認を挟む hook なので構文解析はせず、取りこぼすより余計に聞く方へ倒す。deny 専用の rat hook deny には ask を混ぜない
reason=""
while IFS= read -r seg; do
  seg=${seg//[\'\"]/}
  read -ra words <<<"$seg"
  reason=$(check_segment "${words[@]}")
  [[ -z $reason ]] || break
done <<<"${cmd//[;&|()\`]/$'\n'}"
[[ -n $reason ]] || exit 0

jq -n --arg reason "gh-guard: $reason changes repository protection or writes to a branch without a push. Ask the user to confirm." \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$reason}}'
