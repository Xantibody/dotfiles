# PLaMo's local translation CLI. nvfetcher tracks its releases in _sources/.
final: prev:
let
  sources = final.callPackage ../_sources/generated.nix { };
  py = final.python3Packages;

  # AIDEV-NOTE: plamo-translate imports mcp.server.fastmcp and pins mcp<2. nixpkgs
  # ships mcp 2, which removed that module (FastMCP became MCPServer), so the CLI
  # gets its own mcp 1.x here instead of the shared one.
  mcp1 = py.mcp.overridePythonAttrs (_old: rec {
    version = "1.30.0";
    src = prev.fetchFromGitHub {
      owner = "modelcontextprotocol";
      repo = "python-sdk";
      tag = "v${version}";
      hash = "sha256-EkmTqsK+vBJcURuwFkhtNJMFgtzgw/7Cd+Fpav4P/ko=";
    };
    dependencies =
      with py;
      [
        anyio
        httpx
        httpx-sse
        jsonschema
        pydantic
        pydantic-settings
        pyjwt
        python-multipart
        sse-starlette
        starlette
        typing-extensions
        typing-inspection
        uvicorn
      ]
      ++ pyjwt.optional-dependencies.crypto;
    # The test suite tracks nixpkgs' mcp 2 and does not match the 1.x tree.
    doCheck = false;
  });
in
{
  plamo-translate = py.buildPythonApplication {
    inherit (sources.plamo-translate) pname version src;
    pyproject = true;

    build-system = [ py.hatchling ];

    dependencies =
      (with py; [
        httpx
        huggingface-hub
        transformers
      ])
      ++ [ mcp1 ]
      ++ mcp1.optional-dependencies.cli;

    # AIDEV-NOTE: runs on llama.cpp, not MLX. nixpkgs builds mlx without Metal
    # (the metal compiler is closed source), so the MLX backend would decode on
    # the CPU; nixpkgs' llama-server has Metal. Without mlx installed the CLI
    # picks llama.cpp on its own, and mlx-lm 0.32's refusal to load PLaMo 2
    # checkpoints (upstream pins <0.32) never comes into play.
    pythonRemoveDeps = [
      "mlx-lm"
      "numba"
    ];
    makeWrapperArgs = [
      "--set-default"
      "PLAMO_TRANSLATE_CLI_LLAMA_SERVER"
      "${final.llama-cpp}/bin/llama-server"
    ];

    nativeCheckInputs = [
      py.jinja2
      py.pytestCheckHook
    ];

    # The test set upstream CI runs against its mock server, without the model.
    enabledTestPaths = [
      "tests/test_cli.py"
      "tests/test_llama_cpp.py"
      "tests/test_warning_filters.py"
      "tests/test_model_selection.py"
      "tests/test_streaming.py"
      "tests/test_mlx_release.py"
    ];
    env.PLAMO_TRANSLATE_CLI_USE_MOCK_SERVER = "1";
    # The CLI tests spawn the installed plamo-translate by name.
    preCheck = ''
      export HOME=$TMPDIR
      export PATH=$out/bin:$PATH
    '';
    __darwinAllowLocalNetworking = true;

    pythonImportsCheck = [ "plamo_translate" ];

    meta = {
      description = "Local translation CLI powered by PLaMo translation models";
      homepage = "https://github.com/pfnet/plamo-translate-cli";
      # The CLI is Apache-2.0; the model it downloads is under the PLaMo Community License.
      license = prev.lib.licenses.asl20;
      mainProgram = "plamo-translate";
    };
  };
}
