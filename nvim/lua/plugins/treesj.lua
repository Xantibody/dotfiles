return {
  'Wansmer/treesj',
  keys = {
    -- { '<leader>m', '<cmd>TSJToggle<cr>', desc = ' toggle node under cursor (split if one-line and join if multiline)' },
    { '<leader>j', '<cmd>TSJSplit<cr>',  desc = 'split node under cursor' },
    { '<leader>s', '<cmd>TSJJoin<cr>',   desc = 'join node under cursor' },
  },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  }, -- if you install parsers with `nvim-treesitter`
  config = function()
    require(
      'treesj'
    ).setup({ --[[ your config ]] })
  end,
}
