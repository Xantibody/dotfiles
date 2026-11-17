# Claude Code 以外の AI エージェント CLI と、それらが引く MCP サーバ。
# codex には Claude と同じ指示書 (configs/agents/AGENTS.md) と同じ skill (my.skills) を渡す。
# Claude Code は ~/.agents/ を読まないので、skill dir は agent ごとに 1 本ずつ並べる。
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;
  # Bash の git push と rm -rf を、語順や前置きの wrapper に関係なく止める PreToolUse hook。
  # 入出力が Claude と codex で同形なので 1 本を両方に当てる。Claude は settings.json が名前で呼ぶ
  # AIDEV-NOTE: permissions.deny は先頭一致で git -C <dir> push と rm -fr を通した (#127)。deny に形を足す案は wrapper や bash -c の数だけ増えるので採らない
  mkDenyHook =
    pkgs:
    pkgs.buildGoModule {
      pname = "deny-hook";
      version = "0.1.0";
      src = ./deny-hook;
      vendorHash = "sha256-96W+NipSuAERDcT5peWDkU96OmH4C1a5Yd38YaV/+8E=";
      meta.mainProgram = "deny-hook";
    };
  share =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        inputs.mcp-servers-nix.overlays.default
        # claude.nix と同じく上流の lock で組んだ packages を差す。理由はそちらの AIDEV-NOTE
        (final: _: { llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}; })
      ];
      home-manager.sharedModules = [ hm.agents ];

      # codex の宣言分はシステム層に置く。codex は CLI > project > profile > user > cloud >
      # /etc/codex/config.toml > builtin の順に重ねるので、ここに書けば user 層と衝突しない。
      # AIDEV-NOTE: ~/.codex/config.toml は置かない。codex が trust / plugins を書き込み、symlink は起動時に実体で置き換える (openai/codex#6646)
      # command は絶対パス。Codex app が spawn する MCP には shell の PATH が届かない
      environment.etc."codex/config.toml".text = ''
        [mcp_servers.ck]
        command = "${pkgs.llm-agents.ck}/bin/ck"
        args = ["--serve"]

        [mcp_servers.codegraph]
        command = "${pkgs.llm-agents.codegraph}/bin/codegraph"
        args = ["serve", "--mcp"]
      '';
    };
in
{
  flake.modules.homeManager.agents =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        context7-mcp
        # agent が引くツール。hook / MCP の配線は Claude 側が configs/agents/settings.json と
        # mcp-defaults、codex 側が /etc/codex/config.toml
        llm-agents.rtk # Bash 出力を圧縮する proxy。Claude では PreToolUse hook が前置する
        llm-agents.ck # 意味検索の grep。`ck --sem`、MCP は `ck --serve`
        llm-agents.codegraph # コードのシンボルと呼び出しのグラフ。MCP は `codegraph serve --mcp`
        (mkDenyHook pkgs) # git push と rm -rf を止める hook。Claude は settings.json が登録する
      ];

      home.file = {
        ".codex/AGENTS.md".source = ../../configs/agents/AGENTS.md;
        # rtk の hook。rtk に codex 用の処理は無いが、codex の PreToolUse は stdin
        # (tool_name "Bash", tool_input.command) も出力 (hookSpecificOutput.updatedInput) も
        # Claude Code と同形なので、Claude 用をそのまま当てている。効かなければ消す。
        # rtk 公式の codex 対応は AGENTS.md に「常に rtk を前置」と書かせる方式で、
        # `rtk test -d` のような誤用で壊れる (rtk-ai/rtk#1237)
        ".codex/hooks.json".text = builtins.toJSON {
          hooks.PreToolUse = [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "${pkgs.llm-agents.rtk}/bin/rtk hook claude";
                }
              ];
            }
          ];
        };
      }
      // lib.mapAttrs' (
        name: src: lib.nameValuePair ".agents/skills/${name}" { source = src; }
      ) config.my.skills;

      # codex には plan mode がないので ccp 相当は置いていない。--sandbox read-only は
      # 「書けない」だけで計画を出す挙動ではなく、同じ p を当てると cc 側と誤解を生む
      my.shell.abbr = {
        cx = {
          cmd = "codex";
          desc = "Codex CLI";
        };
        cxr = {
          cmd = "codex resume";
          desc = "セッション再開。引数なしはピッカー、--last で直近";
        };
        cxA = {
          cmd = "codex --approve-for-me";
          desc = "承認を auto_review に委ねる。sandbox は workspace-write 固定";
        };
      };
    };

  # go test は buildGoModule の checkPhase が回す
  perSystem =
    { pkgs, ... }:
    {
      checks.deny-hook = mkDenyHook pkgs;
    };

  flake.modules.darwin.agents = share;
  flake.modules.nixos.agents = share;
}
