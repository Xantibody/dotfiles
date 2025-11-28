# プラグイン初期化設定 (extraPluginsで追加したプラグインのsetup呼び出し)
# NOTE: configを持つextraPluginsはそちらで初期化されるので、ここでは呼ばない
''
  -- nvim-web-devicons (アイコン表示用)
  require("nvim-web-devicons").setup({})

  -- hlchunk
  require("hlchunk").setup({
    chunk = {
      enable = true,
    },
  })

  -- tiny-glimmer
  require("tiny-glimmer").setup({})

  -- in-and-out
  require("in-and-out").setup({
    additional_targets = { '"', '"' },
  })
''
