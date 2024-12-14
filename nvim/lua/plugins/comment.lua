-- add this to your lua/plugins.lua, lua/plugins/init.lua,  or the file you keep your other plugins:
return {
  'numToStr/Comment.nvim',
  keys = {
    {
      '<C-/>',
      "<cmd>lua require('Comment.api').toggle.linewise.current()<CR><Esc>A",
      mode = { 'n', 'i' },
      desc = 'comment out line',
    },
  },
  opts = {
    -- add any options here
  }
}
